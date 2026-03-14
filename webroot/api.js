// FROSTY - KSU WebUI API Layer

var API = (function () {
  'use strict';

  var MODDIR      = '/data/adb/modules/Frosty';
  var PREFS       = MODDIR + '/config/user_prefs';
  var WHITELIST   = MODDIR + '/config/doze_whitelist.txt';
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
    var raw = await runStrict(cmd);
    try { return JSON.parse(raw); }
    catch (e) { throw new Error('Bad JSON: ' + raw.substring(0, 120)); }
  }

  function esc(s) { return String(s).replace(/'/g, "'\\''"); }

  // ── Preference maps ──

  var PREF_MAP = {
    kernel_tweaks:   'ENABLE_KERNEL_TWEAKS',
    system_props:    'ENABLE_SYSTEM_PROPS',
    blur_disable:    'ENABLE_BLUR_DISABLE',
    log_killing:     'ENABLE_LOG_KILLING',
    kill_tracking:   'ENABLE_KILL_TRACKING',
    ram_optimizer:   'ENABLE_RAM_OPTIMIZER',
    gms_doze:        'ENABLE_GMS_DOZE',
    deep_doze:       'ENABLE_DEEP_DOZE',
    deep_doze_level: 'DEEP_DOZE_LEVEL',
    battery_saver:              'ENABLE_BATTERY_SAVER',
    bss_soundtrigger_disabled:  'BSS_SOUNDTRIGGER_DISABLED',
    bss_fullbackup_deferred:    'BSS_FULLBACKUP_DEFERRED',
    bss_keyvaluebackup_deferred:'BSS_KEYVALUEBACKUP_DEFERRED',
    bss_force_standby:          'BSS_FORCE_STANDBY',
    bss_force_bg_check:         'BSS_FORCE_BG_CHECK',
    bss_sensors_disabled:       'BSS_SENSORS_DISABLED',
    bss_gps_mode:               'BSS_GPS_MODE',
    bss_datasaver:              'BSS_DATASAVER'
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
    var prefRaw  = await run('cat ' + PREFS + ' 2>/dev/null');

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
      bss_soundtrigger_disabled: 1, bss_fullbackup_deferred: 1, bss_keyvaluebackup_deferred: 1, bss_sensors_disabled: 1
    };
    var prefs = {};
    for (var pk in PREF_MAP) {
      var envKey = PREF_MAP[pk];
      if (pk === 'deep_doze_level') { prefs[pk] = vals[envKey] || 'moderate'; }
      else if (BSS_DEFAULT_1[pk] !== undefined) { prefs[pk] = vals[envKey] !== undefined && vals[envKey] !== '' ? parseInt(vals[envKey]) : 1; }
      else prefs[pk] = parseInt(vals[envKey]) || 0;
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
    var cmd = "if grep -q '^" + envKey + "=' '" + PREFS + "' 2>/dev/null; then " +
      "sed -i 's|^" + envKey + "=.*|" + envKey + "=" + esc(val) + "|' '" + PREFS + "'; " +
      "else echo '" + envKey + "=" + esc(val) + "' >> '" + PREFS + "'; fi";

    await run(cmd);
    return { status: 'ok' };
  }

  // ── Actions ──

  async function applyFreeze() {
    var raw = await run('sh ' + MODDIR + '/frosty.sh freeze 2>&1');
    appendLog('Freeze applied via WebUI');
    return parseOutput(raw, 'freeze');
  }

  async function applyStock() {
    var raw = await run('sh ' + MODDIR + '/frosty.sh stock 2>&1');
    appendLog('Stock reverted via WebUI');
    return parseOutput(raw, 'stock');
  }

  function parseOutput(raw, mode) {
    if (mode === 'freeze') {
      var m = raw.match(/Disabled:\s*(\d+).*?Re-enabled:\s*(\d+).*?Failed:\s*(\d+)/);
      return {
        status: 'ok',
        disabled: m ? parseInt(m[1]) : 0,
        enabled:  m ? parseInt(m[2]) : 0,
        failed:   m ? parseInt(m[3]) : 0,
        raw: raw
      };
    } else {
      var m2 = raw.match(/Re-enabled:\s*(\d+).*?Failed:\s*(\d+)/);
      return {
        status:  'ok',
        enabled: m2 ? parseInt(m2[1]) : 0,
        failed:  m2 ? parseInt(m2[2]) : 0,
        raw: raw
      };
    }
  }

  // ── Category immediate apply/revert ──

  async function freezeCategory(category) {
    return await runJSON('sh ' + MODDIR + '/frosty.sh freeze_category \'' + esc(category) + '\' 2>/dev/null');
  }
  async function unfreezeCategory(category) {
    return await runJSON('sh ' + MODDIR + '/frosty.sh unfreeze_category \'' + esc(category) + '\' 2>/dev/null');
  }

  // ── GMS Doze ──

  async function applyGmsDoze() {
    await run('sh ' + MODDIR + '/gms_doze.sh apply 2>&1');
    return { status: 'ok' };
  }

  async function revertGmsDoze() {
    await run('sh ' + MODDIR + '/gms_doze.sh revert 2>&1');
    return { status: 'ok' };
  }

  // ── Deep Doze ──

  async function applyDeepDoze() {
    await run('sh ' + MODDIR + '/deep_doze.sh freeze 2>&1');
    return { status: 'ok' };
  }

  async function revertDeepDoze() {
    await run('sh ' + MODDIR + '/deep_doze.sh stock 2>&1');
    return { status: 'ok' };
  }

  // ── RAM Optimizer ──

  async function applyRamOptimizer() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh ram_optimizer 2>/dev/null');
  }

  async function revertRamOptimizer() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh ram_restore 2>/dev/null');
  }

  // ── Kernel Tweaks ──

  async function applyKernelTweaks() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh apply_kernel 2>/dev/null');
  }

  async function revertKernelTweaks() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh revert_kernel 2>/dev/null');
  }

  // ── Blur ──

  async function applyBlur() {
    var cmd = '. "' + PREFS + '"; ' +
      'if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then ' +
      'resetprop -n disableBlurs true; resetprop -n enable_blurs_on_windows 0; ' +
      'resetprop -n ro.launcher.blur.appLaunch 0; resetprop -n ro.sf.blurs_are_expensive 0; ' +
      'resetprop -n ro.surface_flinger.supports_background_blur 0; ' +
      'echo "{\\"status\\":\\"ok\\",\\"blur\\":\\"disabled\\",\\"message\\":\\"Reboot for full effect\\"}"; ' +
      'else ' +
      'resetprop --delete disableBlurs 2>/dev/null; resetprop --delete enable_blurs_on_windows 2>/dev/null; ' +
      'resetprop --delete ro.launcher.blur.appLaunch 2>/dev/null; resetprop --delete ro.sf.blurs_are_expensive 2>/dev/null; ' +
      'resetprop --delete ro.surface_flinger.supports_background_blur 2>/dev/null; ' +
      'echo "{\\"status\\":\\"ok\\",\\"blur\\":\\"enabled\\",\\"message\\":\\"Reboot for full effect\\"}"; fi';
    return await runJSON(cmd);
  }

  // ── Battery Saver ──

  async function applyBatterySaver() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh bss_apply 2>/dev/null');
  }

  async function revertBatterySaver() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh bss_revert 2>/dev/null');
  }

  // ── Log Killing ──

  async function killLogs() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh kill_logs 2>/dev/null');
  }

  // ── Kill Tracking ──

  async function applyKillTracking() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh kill_tracking 2>/dev/null');
  }

  async function revertKillTracking() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh revert_tracking 2>/dev/null');
  }

  // ── System Props toggle ──

  async function toggleSystemProps() {
    return await runJSON('sh ' + MODDIR + '/frosty.sh apply_sysprops 2>/dev/null');
  }

  // ── Whitelist ──

  async function ensureWhitelist() {
    await exec('mkdir -p "' + MODDIR + '/config"; [ -f "' + WHITELIST + '" ] || touch "' + WHITELIST + '"');
  }

  async function getWhitelist() {
    await ensureWhitelist();
    var cmd = 'installed=$(pm list packages 2>/dev/null | cut -d: -f2); ' +
      'while IFS= read -r line; do ' +
      'pkg=$(echo "$line" | sed "s/#.*//;s/[[:space:]]//g"); ' +
      '[ -z "$pkg" ] && continue; ' +
      'echo "$installed" | grep -qx "$pkg" && echo "$pkg"; ' +
      'done < "' + WHITELIST + '"';
    var raw = await run(cmd);
    var pkgs = raw ? raw.split('\n').filter(function (l) { return l.trim(); }) : [];
    return { status: 'ok', packages: pkgs };
  }

  async function addWhitelist(pkg) {
    await ensureWhitelist();
    var safePkg = esc(pkg);
    var cmd = 'grep -qx "' + safePkg + '" "' + WHITELIST + '" 2>/dev/null || echo "' + safePkg + '" >> "' + WHITELIST + '"';
    await run(cmd);
    return { status: 'ok' };
  }

  async function removeWhitelist(pkg) {
    await ensureWhitelist();
    var escaped = esc(pkg).replace(/\./g, '\\.');
    await exec('sed -i "/^' + escaped + '$/d" "' + WHITELIST + '"');
    return { status: 'ok' };
  }

  // ── Logs ──

  function appendLog(msg) {
    var safeMsg = String(msg).replace(/['"\\`$]/g, '').substring(0, 200);
    exec('echo "[$(date +"%Y-%m-%d %H:%M:%S")] [webui] ' + safeMsg + '" >> "' + LOG_DIR + '/action.log"');
  }

  // ── Native KSU APIs ──

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

  async function listBackups() {
    var raw = await run('sh ' + MODDIR + '/frosty.sh list_backups 2>&1');
    try { return JSON.parse(raw.trim()); } catch(e) { return []; }
  }

  async function exportSettings() {
    var path = await runStrict('sh ' + MODDIR + '/frosty.sh export 2>&1');
    return path.trim();
  }

  async function importSettings(filePath) {
    var result = await run('sh ' + MODDIR + '/frosty.sh import "' + filePath + '" 2>&1');
    return result.trim() === 'OK';
  }

  async function shareBackup(filePath) {
    await run('sh ' + MODDIR + '/frosty.sh share_backup "' + filePath + '" 2>&1');
  }

  return {
    MODDIR,
    available, exec, run,
    getPrefs, setPref,
    applyFreeze, applyStock,
    freezeCategory, unfreezeCategory,
    applyGmsDoze, revertGmsDoze,
    applyDeepDoze, revertDeepDoze,
    applyBatterySaver, revertBatterySaver,
    applyRamOptimizer, revertRamOptimizer,
    applyKernelTweaks, revertKernelTweaks,
    applyBlur, killLogs, applyKillTracking, revertKillTracking, toggleSystemProps,
    getWhitelist, addWhitelist, removeWhitelist,
    appendLog,
    nativeListPackages, nativeGetPackagesInfo,
    listBackups, exportSettings, importSettings, shareBackup
  };
})();
