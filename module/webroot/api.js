// FROSTY - KSU WebUI API Layer

var API = (function () {
  'use strict';

  var MODDIR      = '/data/adb/modules/Frosty';
  var PREFS       = MODDIR + '/config/user_prefs';
  var LOG_DIR     = MODDIR + '/logs';

  var cbCounter = 0;

  function uid() { return 'cb_' + Date.now() + '_' + (cbCounter++); }

  function available() {
    return typeof ksu !== 'undefined' && typeof ksu.exec === 'function';
  }

  function exec(cmd, opts) {
    return new Promise(function (resolve, reject) {
      var name = uid();
      window[name] = function (errno, stdout, stderr) {
        delete window[name];
        resolve({ errno: errno, stdout: stdout || '', stderr: stderr || '' });
      };
      try {
        ksu.exec(cmd, JSON.stringify(opts || {}), name);
      } catch (e) {
        delete window[name];
        reject(e);
      }
    });
  }

  async function run(cmd) {
    var r = await exec(cmd);
    return (r.stdout || '').trim();
  }

  async function runStrict(cmd) {
    var r = await exec(cmd);
    if (r.errno !== 0) throw new Error(r.stderr || 'exit ' + r.errno);
    return (r.stdout || '').trim();
  }

  async function runJSON(cmd) {
    var r = await exec(cmd);
    var raw = (r.stdout || '').trim();
    if (r.errno !== 0 && !raw) {
      throw new Error('exit ' + r.errno + (r.stderr ? ': ' + r.stderr.substring(0, 200) : ''));
    }
    try { return JSON.parse(raw); }
    catch (e) { throw new Error('Bad JSON: ' + raw.substring(0, 120) + (r.stderr ? ' | stderr: ' + r.stderr.substring(0, 100) : '')); }
  }

  function esc(s) { return String(s).replace(/'/g, "'\\''"); }
  function escSed(s) { return String(s).replace(/[\\|&]/g, '\\$&'); }

  var PREF_MAP = {
    kernel_tweaks:   'ENABLE_KERNEL_TWEAKS',
    system_props:    'ENABLE_SYSTEM_PROPS',
    blur_disable:    'ENABLE_BLUR_DISABLE',
    log_killing:     'ENABLE_LOG_KILLING',
    kill_tracking:   'ENABLE_KILL_TRACKING',
    ram_optimizer:   'ENABLE_RAM_OPTIMIZER',
    deep_doze:       'ENABLE_DEEP_DOZE',
    deep_doze_level: 'DEEP_DOZE_LEVEL',
    ram_optimizer_level: 'RAM_OPT_LEVEL',
    battery_saver:              'ENABLE_BATTERY_SAVER',
    bss_soundtrigger_disabled:  'BSS_SOUNDTRIGGER_DISABLED',
    bss_fullbackup_deferred:    'BSS_FULLBACKUP_DEFERRED',
    bss_keyvaluebackup_deferred:'BSS_KEYVALUEBACKUP_DEFERRED',
    bss_force_standby:          'BSS_FORCE_STANDBY',
    bss_force_bg_check:         'BSS_FORCE_BG_CHECK',
    bss_sensors_disabled:       'BSS_SENSORS_DISABLED',
    bss_gps_mode:               'BSS_GPS_MODE',
    bss_datasaver:              'BSS_DATASAVER',
    custom_app_doze:            'ENABLE_CUSTOM_APP_DOZE',
    screen_off_opt:             'ENABLE_SCREEN_OFF_OPT',
    soo_kill_wifi:              'SOO_KILL_WIFI',
    soo_kill_bt:                'SOO_KILL_BT',
    soo_kill_data:              'SOO_KILL_DATA',
    soo_kill_location:          'SOO_KILL_LOCATION',
    soo_conn_delay:            'SOO_CONN_DELAY',
    soo_restore_on_unlock:      'SOO_RESTORE_ON_UNLOCK',
    soo_ram_clean_mode:         'SOO_RAM_CLEAN_MODE',
    soo_ram_clean_delay:        'SOO_RAM_CLEAN_DELAY',
    soo_kill_sensors:           'SOO_KILL_SENSORS',
    soo_kill_panel_lpm:         'SOO_KILL_PANEL_LPM'
  };
  var CAT_MAP = {
    telemetry:    'DISABLE_TELEMETRY',
    background:   'DISABLE_BACKGROUND',
    location:     'DISABLE_LOCATION',
    connectivity: 'DISABLE_CONNECTIVITY',
    cloud:        'DISABLE_CLOUD',
    payments:     'DISABLE_PAYMENTS',
    wearables:    'DISABLE_WEARABLES',
    games:        'DISABLE_GAMES'
  };

  async function getPrefs() {
    var prefRaw = await run('cat ' + PREFS + ' 2>/dev/null');

    var vals = {};
    if (prefRaw) {
      prefRaw.split('\n').forEach(function (line) {
        var eq = line.indexOf('=');
        if (eq > 0) {
          var k = line.substring(0, eq).trim();
          var v = line.substring(eq + 1).trim();
          if (k) vals[k] = v;
        }
      });
    }

    var BSS_DEFAULT_1 = {
      bss_soundtrigger_disabled: 0, bss_fullbackup_deferred: 0, bss_keyvaluebackup_deferred: 0, bss_sensors_disabled: 0
    };
    var SOO_DEFAULTS = {
      soo_restore_on_unlock: 1, soo_conn_delay: 5, soo_ram_clean_delay: 5
    };
    var prefs = {};
    for (var pk in PREF_MAP) {
      var envKey = PREF_MAP[pk];
      if (pk === 'deep_doze_level') {
        prefs[pk] = vals[envKey] || 'moderate';
      } else if (pk === 'ram_optimizer_level') {
        prefs[pk] = vals[envKey] || 'moderate';
      } else if (pk === 'soo_ram_clean_mode') {
        prefs[pk] = vals[envKey] || 'off';
      } else if (BSS_DEFAULT_1[pk] !== undefined) {
        prefs[pk] = vals[envKey] !== undefined && vals[envKey] !== '' ? parseInt(vals[envKey]) : 0;
      } else if (SOO_DEFAULTS[pk] !== undefined) {
        prefs[pk] = vals[envKey] !== undefined && vals[envKey] !== '' ? parseInt(vals[envKey]) : SOO_DEFAULTS[pk];
      } else {
        prefs[pk] = parseInt(vals[envKey]) || 0;
      }
    }

    var cats = {};
    for (var ck in CAT_MAP) {
      cats[ck] = parseInt(vals[CAT_MAP[ck]]) || 0;
    }

    return { prefs: prefs, categories: cats };
  }

  async function setPref(key, value) {
    var envKey = PREF_MAP[key] || CAT_MAP[key];
    if (!envKey) return { status: 'error', message: 'Unknown key: ' + key };

    var val = String(value);
    var sedVal = esc(escSed(val));
    var cmd = "if grep -q '^" + envKey + "=' '" + PREFS + "' 2>/dev/null; then " +
      "sed -i 's|^" + envKey + "=.*|" + envKey + "=" + sedVal + "|' '" + PREFS + "'; " +
      "else echo '" + envKey + "=" + esc(val) + "' >> '" + PREFS + "'; fi";

    await run(cmd);
    return { status: 'ok' };
  }

  async function applyKernelTweaks() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_kernel 2>/dev/null');
  }

  async function revertKernelTweaks() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_kernel 2>/dev/null');
  }

  async function toggleSystemProps() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_sysprops 2>/dev/null');
  }

  async function applyRamOptimizer() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_ram 2>/dev/null');
  }

  async function revertRamOptimizer() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_ram 2>/dev/null');
  }

  async function killLogs() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_logs 2>/dev/null');
  }

  async function revertKillLogs() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_logs 2>/dev/null');
  }

  async function applyKillTracking() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_tracking 2>/dev/null');
  }

  async function revertKillTracking() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_tracking 2>/dev/null');
  }

  async function applyBatterySaver() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_bss 2>/dev/null');
  }

  async function revertBatterySaver() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_bss 2>/dev/null');
  }

  async function applyBlur() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_blur 2>/dev/null');
  }

  async function applyFreeze() {
    var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh freeze 2>&1');
    appendLog('Freeze applied via WebUI');
    return parseOutput(raw, 'freeze');
  }

  async function applyStock() {
    var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh stock 2>&1');
    appendLog('Stock reverted via WebUI');
    return parseOutput(raw, 'stock');
  }

  function parseOutput(raw, mode) {
    var m, m2;
    if (mode === 'freeze') {
      m = raw.match(/Disabled:\s*(\d+)[\s\S]*?Re-enabled:\s*(\d+)[\s\S]*?Failed:\s*(\d+)/);
      return {
        status: 'ok',
        disabled: m ? parseInt(m[1]) : 0,
        enabled:  m ? parseInt(m[2]) : 0,
        failed:   m ? parseInt(m[3]) : 0,
        raw: raw
      };
    } else {
      m2 = raw.match(/Re-enabled:\s*(\d+)[\s\S]*?Failed:\s*(\d+)/);
      return {
        status:  'ok',
        enabled: m2 ? parseInt(m2[1]) : 0,
        failed:  m2 ? parseInt(m2[2]) : 0,
        raw: raw
      };
    }
  }

  async function freezeCategory(category) {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh freeze_category \'' + esc(category) + '\' 2>/dev/null');
  }

  async function unfreezeCategory(category) {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh unfreeze_category \'' + esc(category) + '\' 2>/dev/null');
  }

  async function applyDeepDoze() {
    await run('sh ' + MODDIR + '/scripts/deep_doze.sh freeze 2>&1');
    return { status: 'ok' };
  }

  async function revertDeepDoze() {
    await run('sh ' + MODDIR + '/scripts/deep_doze.sh stock 2>&1');
    return { status: 'ok' };
  }

  async function applyCustomAppDoze() {
    await run('sh ' + MODDIR + '/scripts/app_doze.sh apply 2>&1');
    return { status: 'ok' };
  }

  async function revertCustomAppDoze() {
    await run('sh ' + MODDIR + '/scripts/app_doze.sh revert 2>&1');
    return { status: 'ok' };
  }

  async function getCustomDozeList() {
    var raw = await run('sh ' + MODDIR + '/scripts/app_doze.sh list 2>/dev/null');
    try { return JSON.parse(raw); } catch(e) { return { status: 'ok', packages: [] }; }
  }

  async function addCustomDoze(pkg) {
    return await runJSON('sh ' + MODDIR + '/scripts/app_doze.sh add \'' + esc(pkg) + '\' 2>/dev/null');
  }

  async function removeCustomDoze(pkg) {
    return await runJSON('sh ' + MODDIR + '/scripts/app_doze.sh remove \'' + esc(pkg) + '\' 2>/dev/null');
  }

  async function getNotOptimizedApps() {
    var raw = await run('sh ' + MODDIR + '/scripts/app_doze.sh scan 2>/dev/null');
    var pkgs = raw ? raw.split('\n').filter(function(l) { return l.trim(); }) : [];
    return { status: 'ok', packages: pkgs };
  }

  async function checkCadNeedsReboot() {
    var result = await run(
      '[ -f "' + MODDIR + '/tmp/cad_needs_reboot" ] && echo "1" || echo "0"'
    );
    return result.trim() === '1';
  }

  async function applyScreenOffOpt() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_soo 2>/dev/null');
  }

  async function revertScreenOffOpt() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_soo 2>/dev/null');
  }

  async function getWhitelist() {
    var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh list_wl 2>/dev/null');
    try { return JSON.parse(raw); } catch(e) { return { status: 'ok', packages: [] }; }
  }

  async function addWhitelist(pkg) {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh add_wl \'' + esc(pkg) + '\' 2>/dev/null');
  }

  async function removeWhitelist(pkg) {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh remove_wl \'' + esc(pkg) + '\' 2>/dev/null');
  }

  async function getRamWhitelist() {
    var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh list_ram_wl 2>/dev/null');
    try { return JSON.parse(raw); } catch(e) { return { status: 'ok', packages: [] }; }
  }

  async function addRamWhitelist(pkg) {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh add_ram_wl \'' + esc(pkg) + '\' 2>/dev/null');
  }

  async function removeRamWhitelist(pkg) {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh remove_ram_wl \'' + esc(pkg) + '\' 2>/dev/null');
  }

  async function listBackups() {
    var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh list_backups 2>&1');
    try { return JSON.parse(raw.trim()); } catch(e) { return []; }
  }

  async function exportSettings() {
    var path = await runStrict('sh ' + MODDIR + '/scripts/frosty.sh export 2>&1');
    return path.trim();
  }

  async function importSettings(filePath) {
    var result = await run("sh '" + MODDIR + "/scripts/frosty.sh' import '" + esc(filePath) + "' 2>&1");
    return result.trim() === 'OK';
  }

  async function shareBackup(filePath) {
    await run("sh '" + MODDIR + "/scripts/frosty.sh' share_backup '" + esc(filePath) + "' 2>&1");
  }

  async function ramClean(mode, exclude) {
    var ex = exclude ? ' \'' + esc(exclude) + '\'' : '';
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh ram_clean \'' + esc(mode) + '\'' + ex + ' 2>/dev/null');
  }

  async function ramCleanPoll() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh ram_clean_poll 2>/dev/null');
  }

  async function getFgPkg() {
    return await runJSON('sh ' + MODDIR + '/scripts/frosty.sh get_fg_pkg 2>/dev/null');
  }

  function appendLog(msg) {
    var safeMsg = String(msg).replace(/[\r\n]/g, ' ').replace(/'/g, "'\\''" ).substring(0, 200);
    exec("printf '[%s] [webui] %s\\n' \"$(date +'%Y-%m-%d %H:%M:%S')\" '" + safeMsg + "' >> \"" + LOG_DIR + "/action.log\"");
  }

  function nativeListPackages(type) {
    try { return JSON.parse(ksu.listPackages(type || 'user')); }
    catch (e) { return []; }
  }

  function nativeGetPackagesInfo(pkgs) {
    try {
      var arg = typeof pkgs === 'string' ? pkgs : JSON.stringify(pkgs);
      return JSON.parse(ksu.getPackagesInfo(arg));
    } catch (e) { return []; }
  }

  return {
    MODDIR,
    available, exec, run,
    getPrefs, setPref,
    applyKernelTweaks, revertKernelTweaks,
    toggleSystemProps,
    applyRamOptimizer, revertRamOptimizer,
    killLogs, revertKillLogs,
    applyKillTracking, revertKillTracking,
    applyBatterySaver, revertBatterySaver,
    applyBlur, applyFreeze, applyStock, freezeCategory, unfreezeCategory,
    applyDeepDoze, revertDeepDoze,
    applyCustomAppDoze, revertCustomAppDoze, getCustomDozeList,
    addCustomDoze, removeCustomDoze, getNotOptimizedApps, checkCadNeedsReboot,
    applyScreenOffOpt, revertScreenOffOpt,
    getWhitelist, addWhitelist, removeWhitelist,
    getRamWhitelist, addRamWhitelist, removeRamWhitelist,
    listBackups, exportSettings, importSettings, shareBackup,
    appendLog, nativeListPackages, nativeGetPackagesInfo,
    ramClean, ramCleanPoll, getFgPkg
  };

})();
