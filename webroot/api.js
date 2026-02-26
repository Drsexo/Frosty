// 🧊 FROSTY - KSU WebUI API Layer

var API = (function () {
  'use strict';

  var MODDIR = '/data/adb/modules/Frosty';
  var PREFS = MODDIR + '/config/user_prefs';
  var STATE = MODDIR + '/config/state';
  var GMS_LIST = MODDIR + '/config/gms_services.txt';
  var WHITELIST = MODDIR + '/config/doze_whitelist.txt';
  var LOG_DIR = MODDIR + '/logs';

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
    blur_disable:    'ENABLE_BLUR_DISABLE',
    log_killing:     'ENABLE_LOG_KILLING',
    gms_doze:        'ENABLE_GMS_DOZE',
    deep_doze:       'ENABLE_DEEP_DOZE',
    deep_doze_level: 'DEEP_DOZE_LEVEL'
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
    var stateRaw = await run('cat ' + STATE + ' 2>/dev/null');

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

    var prefs = {};
    for (var pk in PREF_MAP) {
      var envKey = PREF_MAP[pk];
      if (pk === 'deep_doze_level') prefs[pk] = vals[envKey] || 'moderate';
      else prefs[pk] = parseInt(vals[envKey]) || 0;
    }

    var cats = {};
    for (var ck in CAT_MAP) {
      cats[ck] = parseInt(vals[CAT_MAP[ck]]) || 0;
    }

    return { prefs: prefs, categories: cats, state: stateRaw || 'unknown' };
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
        enabled: m ? parseInt(m[2]) : 0,
        failed: m ? parseInt(m[3]) : 0,
        raw: raw
      };
    } else {
      var m2 = raw.match(/Re-enabled:\s*(\d+).*?Failed:\s*(\d+)/);
      return {
        status: 'ok',
        enabled: m2 ? parseInt(m2[1]) : 0,
        failed: m2 ? parseInt(m2[2]) : 0,
        raw: raw
      };
    }
  }

  // ── Category immediate apply/revert ──

  async function freezeCategory(category) {
    var cmd = 'count=0; fail=0; ' +
      'while IFS="|" read -r svc cat || [ -n "$svc" ]; do ' +
      'case "$svc" in \\#*|"") continue;; esac; ' +
      'svc=$(echo "$svc" | tr -d " "); cat=$(echo "$cat" | tr -d " "); ' +
      '[ "$cat" = "' + esc(category) + '" ] || continue; ' +
      'if pm disable "$svc" >/dev/null 2>&1; then count=$((count+1)); else fail=$((fail+1)); fi; ' +
      'done < ' + GMS_LIST + '; ' +
      'echo "{\\"status\\":\\"ok\\",\\"disabled\\":$count,\\"failed\\":$fail}"';
    return await runJSON(cmd);
  }

  async function unfreezeCategory(category) {
    var cmd = 'count=0; fail=0; ' +
      'while IFS="|" read -r svc cat || [ -n "$svc" ]; do ' +
      'case "$svc" in \\#*|"") continue;; esac; ' +
      'svc=$(echo "$svc" | tr -d " "); cat=$(echo "$cat" | tr -d " "); ' +
      '[ "$cat" = "' + esc(category) + '" ] || continue; ' +
      'if pm enable "$svc" >/dev/null 2>&1; then count=$((count+1)); else fail=$((fail+1)); fi; ' +
      'done < ' + GMS_LIST + '; ' +
      'echo "{\\"status\\":\\"ok\\",\\"enabled\\":$count,\\"failed\\":$fail}"';
    return await runJSON(cmd);
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

  // ── Kernel Tweaks ──

  async function applyTweaks() {
    var backup = MODDIR + '/backup/kernel_values.txt';

    // Create backup of current values if none exists
    await run(
      'mkdir -p "' + MODDIR + '/backup"; ' +
      'if [ ! -f "' + backup + '" ]; then ' +
      'echo "# Kernel Backup - $(date)" > "' + backup + '"; ' +
      'for pair in ' +
      '"perf_cpu_time_max_percent:/proc/sys/kernel/perf_cpu_time_max_percent" ' +
      '"sched_autogroup_enabled:/proc/sys/kernel/sched_autogroup_enabled" ' +
      '"sched_child_runs_first:/proc/sys/kernel/sched_child_runs_first" ' +
      '"sched_tunable_scaling:/proc/sys/kernel/sched_tunable_scaling" ' +
      '"sched_latency_ns:/proc/sys/kernel/sched_latency_ns" ' +
      '"sched_min_granularity_ns:/proc/sys/kernel/sched_min_granularity_ns" ' +
      '"sched_wakeup_granularity_ns:/proc/sys/kernel/sched_wakeup_granularity_ns" ' +
      '"sched_migration_cost_ns:/proc/sys/kernel/sched_migration_cost_ns" ' +
      '"sched_min_task_util_for_colocation:/proc/sys/kernel/sched_min_task_util_for_colocation" ' +
      '"sched_nr_migrate:/proc/sys/kernel/sched_nr_migrate" ' +
      '"sched_schedstats:/proc/sys/kernel/sched_schedstats" ' +
      '"panic:/proc/sys/kernel/panic" ' +
      '"panic_on_oops:/proc/sys/kernel/panic_on_oops" ' +
      '"vm_panic_on_oom:/proc/sys/vm/panic_on_oom" ' +
      '"timer_migration:/proc/sys/kernel/timer_migration" ' +
      '"printk_devkmsg:/proc/sys/kernel/printk_devkmsg" ' +
      '"printk:/proc/sys/kernel/printk" ' +
      '"dirty_background_ratio:/proc/sys/vm/dirty_background_ratio" ' +
      '"dirty_ratio:/proc/sys/vm/dirty_ratio" ' +
      '"dirty_expire_centisecs:/proc/sys/vm/dirty_expire_centisecs" ' +
      '"dirty_writeback_centisecs:/proc/sys/vm/dirty_writeback_centisecs" ' +
      '"stat_interval:/proc/sys/vm/stat_interval" ' +
      '"vfs_cache_pressure:/proc/sys/vm/vfs_cache_pressure" ' +
      '"oom_dump_tasks:/proc/sys/vm/oom_dump_tasks" ' +
      '"block_dump:/proc/sys/vm/block_dump" ' +
      '"tcp_ecn:/proc/sys/net/ipv4/tcp_ecn" ' +
      '"tcp_fastopen:/proc/sys/net/ipv4/tcp_fastopen" ' +
      '"tcp_syncookies:/proc/sys/net/ipv4/tcp_syncookies" ' +
      '"tcp_no_metrics_save:/proc/sys/net/ipv4/tcp_no_metrics_save" ' +
      '"exception_trace:/proc/sys/debug/exception-trace" ' +
      '"read_wakeup_threshold:/proc/sys/kernel/random/read_wakeup_threshold" ' +
      '"write_wakeup_threshold:/proc/sys/kernel/random/write_wakeup_threshold" ' +
      '"printk_ratelimit:/proc/sys/kernel/printk_ratelimit" ' +
      '"printk_ratelimit_burst:/proc/sys/kernel/printk_ratelimit_burst"; do ' +
      'name="${pair%%:*}"; path="${pair#*:}"; ' +
      '[ -f "$path" ] && echo "$name=$(cat "$path" 2>/dev/null)=$path" >> "' + backup + '"; ' +
      'done; fi'
    );

    // Apply tweaks
    var cmd = 'count=0; fail=0; ' +
      'w() { [ ! -f "$1" ] && return; chmod +w "$1" 2>/dev/null; echo "$2" > "$1" 2>/dev/null && count=$((count+1)) || fail=$((fail+1)); }; ' +
      'SP=$((5*1000*1000)); ' +
      'w /proc/sys/kernel/perf_cpu_time_max_percent 2; ' +
      'w /proc/sys/kernel/sched_autogroup_enabled 1; ' +
      'w /proc/sys/kernel/sched_child_runs_first 0; ' +
      'w /proc/sys/kernel/sched_tunable_scaling 0; ' +
      'w /proc/sys/kernel/sched_latency_ns $SP; ' +
      'w /proc/sys/kernel/sched_min_granularity_ns $((SP/5)); ' +
      'w /proc/sys/kernel/sched_wakeup_granularity_ns $((SP/2)); ' +
      'w /proc/sys/kernel/sched_migration_cost_ns 5000000; ' +
      'w /proc/sys/kernel/sched_min_task_util_for_colocation 0; ' +
      'w /proc/sys/kernel/sched_nr_migrate 256; ' +
      'w /proc/sys/kernel/sched_schedstats 0; ' +
      'w /proc/sys/kernel/panic 0; ' +
      'w /proc/sys/kernel/panic_on_oops 0; ' +
      'w /proc/sys/vm/panic_on_oom 0; ' +
      'w /proc/sys/kernel/timer_migration 0; ' +
      'w /proc/sys/kernel/printk "0 0 0 0"; ' +
      'w /proc/sys/vm/dirty_background_ratio 2; ' +
      'w /proc/sys/vm/dirty_ratio 5; ' +
      'w /proc/sys/vm/dirty_expire_centisecs 500; ' +
      'w /proc/sys/vm/dirty_writeback_centisecs 500; ' +
      'w /proc/sys/vm/stat_interval 10; ' +
      'w /proc/sys/vm/vfs_cache_pressure 100; ' +
      'w /proc/sys/vm/oom_dump_tasks 0; ' +
      'w /proc/sys/vm/block_dump 0; ' +
      'w /proc/sys/net/ipv4/tcp_ecn 1; ' +
      'w /proc/sys/net/ipv4/tcp_fastopen 3; ' +
      'w /proc/sys/net/ipv4/tcp_syncookies 1; ' +
      'w /proc/sys/net/ipv4/tcp_no_metrics_save 1; ' +
      'w /proc/sys/debug/exception-trace 0; ' +
      'w /proc/sys/kernel/random/read_wakeup_threshold 256; ' +
      'w /proc/sys/kernel/random/write_wakeup_threshold 320; ' +
      'w /proc/sys/kernel/printk_ratelimit 1; ' +
      'w /proc/sys/kernel/printk_ratelimit_burst 5; ' +
      'echo "{\\"status\\":\\"ok\\",\\"applied\\":$count,\\"failed\\":$fail}"';
    return await runJSON(cmd);
  }

  async function revertTweaks() {
    var backup = MODDIR + '/backup/kernel_values.txt';
    var cmd = 'count=0; ' +
      'if [ -f "' + backup + '" ]; then ' +
      'while IFS= read -r line; do ' +
      'case "$line" in \\#*|"") continue;; esac; ' +
      'name=$(echo "$line" | cut -d= -f1); ' +
      'val=$(echo "$line" | cut -d= -f2); ' +
      'path=$(echo "$line" | cut -d= -f3-); ' +
      '[ -z "$path" ] && continue; ' +
      '[ -f "$path" ] || continue; ' +
      'chmod +w "$path" 2>/dev/null; ' +
      'echo "$val" > "$path" 2>/dev/null && count=$((count+1)); ' +
      'done < "' + backup + '"; ' +
      'echo "{\\"status\\":\\"ok\\",\\"restored\\":$count}"; ' +
      'else echo "{\\"status\\":\\"ok\\",\\"restored\\":0}"; fi';
    return await runJSON(cmd);
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

  // ── Log Killing ──

  async function killLogs() {
    var cmd = 'k=0; for s in logcat logcatd logd tcpdump cnss_diag statsd traced; do ' +
      'pid=$(pidof "$s" 2>/dev/null); [ -n "$pid" ] && kill -9 $pid 2>/dev/null && k=$((k+1)); done; ' +
      'logcat -c 2>/dev/null; ' +
      'echo "{\\"status\\":\\"ok\\",\\"killed\\":$k}"';
    return await runJSON(cmd);
  }

  // ── Regenerate system files (.rc overlays) ──

  async function regenerateSystemFiles() {
    var cmd = '. "' + PREFS + '"; ' +
      'INITDIR="' + MODDIR + '/system/etc/init"; ' +
      'BINDIR="' + MODDIR + '/system/bin"; ' +
      'if [ "$ENABLE_LOG_KILLING" = "1" ]; then ' +
      '  mkdir -p "$INITDIR"; ' +
      '  for rc in atrace atrace_userdebug bugreport debuggerd debuggerd64 dmesgd dumpstate logcat logcatd logd logtagd lpdumpd tombstoned traced_perf traced_probes traceur; do ' +
      '    [ ! -f "$INITDIR/${rc}.rc" ] && : > "$INITDIR/${rc}.rc"; ' +
      '  done; ' +
      '  mkdir -p "$BINDIR"; ' +
      '  for bin in atrace bugreport bugreport_procdump bugreportz crash_dump32 crash_dump64 debuggerd diag_socket_log dmabuf_dump dmesg dmesgd dumpstate i2cdump log logcat logcatd logd logger logname logpersist.cat logpersist.start logpersist.stop logwrapper lpdump lpdumpd notify_traceur.sh tcpdump tombstoned traced traced_perf traced_probes tracepath tracepath6 traceroute6; do ' +
      '    [ ! -f "$BINDIR/$bin" ] && : > "$BINDIR/$bin" && chmod 755 "$BINDIR/$bin"; ' +
      '  done; ' +
      '  echo "{\\"status\\":\\"ok\\",\\"action\\":\\"created\\",\\"reboot\\":true}"; ' +
      'else ' +
      '  rm -f "$INITDIR"/*.rc 2>/dev/null; ' +
      '  rmdir "$INITDIR" 2>/dev/null; ' +
      '  rm -f "$BINDIR"/* 2>/dev/null; ' +
      '  rmdir "$BINDIR" 2>/dev/null; ' +
      '  rmdir "' + MODDIR + '/system/etc" 2>/dev/null; ' +
      '  echo "{\\"status\\":\\"ok\\",\\"action\\":\\"removed\\",\\"reboot\\":true}"; ' +
      'fi';
    return await runJSON(cmd);
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

  return {
    available: available,
    exec: exec,
    run: run,
    getPrefs: getPrefs,
    setPref: setPref,
    applyFreeze: applyFreeze,
    applyStock: applyStock,
    freezeCategory: freezeCategory,
    unfreezeCategory: unfreezeCategory,
    applyGmsDoze: applyGmsDoze,
    revertGmsDoze: revertGmsDoze,
    applyDeepDoze: applyDeepDoze,
    revertDeepDoze: revertDeepDoze,
    applyTweaks: applyTweaks,
    revertTweaks: revertTweaks,
    applyBlur: applyBlur,
    killLogs: killLogs,
    getWhitelist: getWhitelist,
    addWhitelist: addWhitelist,
    removeWhitelist: removeWhitelist,
    appendLog: appendLog,
    nativeListPackages: nativeListPackages,
    nativeGetPackagesInfo: nativeGetPackagesInfo
  };
})();