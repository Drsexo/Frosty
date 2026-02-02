#!/system/bin/sh
# 🧊 FROSTY - Service script
# Applies kernel tweaks and initializes GMS freezing on boot

MODDIR="${0%/*}"
LOGDIR="$MODDIR/logs"

mkdir -p "$LOGDIR"

BOOT_LOG="$LOGDIR/boot.log"
TWEAKS_LOG="$LOGDIR/tweaks.log"

# LOG ROTATION
rotate_logs() {
  local max_size=102400  # 100KB
  for log in "$LOGDIR"/*.log; do
    [ -f "$log" ] || continue
    local size=$(stat -c%s "$log" 2>/dev/null || echo 0)
    if [ "$size" -gt "$max_size" ]; then
      mv "$log" "${log}.old"
    fi
  done
}

rotate_logs

# INITIALIZE LOGS
echo "═════════════════════════════════════" > "$BOOT_LOG"
echo "🧊 FROSTY Boot Log - $(date '+%Y-%m-%d %H:%M:%S')" >> "$BOOT_LOG"
echo "═════════════════════════════════════" >> "$BOOT_LOG"

echo "═════════════════════════════════════" > "$TWEAKS_LOG"
echo "🧊 FROSTY Tweaks Log - $(date '+%Y-%m-%d %H:%M:%S')" >> "$TWEAKS_LOG"
echo "═════════════════════════════════════" >> "$TWEAKS_LOG"

log_boot() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$BOOT_LOG"
}

log_tweak() {
  echo "$1" >> "$TWEAKS_LOG"
}

# WAIT FOR BOOT COMPLETION
wait_for_boot() {
  local timeout=120
  local elapsed=0
  
  log_boot "Waiting for system boot..."
  
  while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
    elapsed=$((elapsed + 2))
    if [ $elapsed -ge $timeout ]; then
      log_boot "[WARN] Boot timeout reached ($timeout s), proceeding anyway"
      break
    fi
  done
  
  # Additional delay for services to stabilize
  sleep 5
  log_boot "System boot detected (waited ${elapsed}s + 5s stabilization)"
}

wait_for_boot

# DEVICE INFO
log_boot ""
log_boot "Device: $(getprop ro.product.model) ($(getprop ro.product.device))"
log_boot "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
log_boot "Kernel: $(uname -r)"
log_boot ""

mkdir -p "$MODDIR/config"

# LOAD USER PREFERENCES
if [ ! -f "$MODDIR/config/user_prefs" ]; then
  log_boot "[WARN] user_prefs not found, creating defaults..."
  cat > "$MODDIR/config/user_prefs" << EOF
# Frosty User Preferences (Default)
# Logic: 1 = Enabled/Freeze, 0 = Disabled/Skip

ENABLE_KERNEL_TWEAKS=1
ENABLE_BLUR_DISABLE=0
ENABLE_LOG_KILLING=1
ENABLE_GMS_DOZE=1
CLEAR_GMS_CACHE=0
DISABLE_TELEMETRY=1
DISABLE_BACKGROUND=1
DISABLE_LOCATION=0
DISABLE_CONNECTIVITY=0
DISABLE_CLOUD=0
DISABLE_PAYMENTS=0
DISABLE_WEARABLES=0
DISABLE_GAMES=0
EOF
fi

. "$MODDIR/config/user_prefs"

log_boot "User preferences loaded"
log_boot " - Kernel Tweaks: $([ "$ENABLE_KERNEL_TWEAKS" = "1" ] && echo "ENABLED" || echo "DISABLED")"
log_boot " - Blur Disable:  $([ "$ENABLE_BLUR_DISABLE" = "1" ] && echo "ENABLED" || echo "DISABLED")"
log_boot " - Log Killing:   $([ "$ENABLE_LOG_KILLING" = "1" ] && echo "ENABLED" || echo "DISABLED")"
log_boot " - GMS Doze:      $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "ENABLED" || echo "DISABLED")"

[ ! -f "$MODDIR/config/state" ] && echo "frozen" > "$MODDIR/config/state"

# HELPER FUNCTION
write_val() {
  local file="$1"
  local value="$2"
  local name="$3"
  
  if [ ! -f "$file" ]; then
    log_tweak "[SKIP] $name - file not found"
    return 1
  fi
  
  local current=$(cat "$file" 2>/dev/null)
  if [ "$current" = "$value" ]; then
    log_tweak "[OK]   $name = $value (already set)"
    return 0
  fi
  
  chmod +w "$file" 2>/dev/null
  if echo "$value" > "$file" 2>/dev/null; then
    log_tweak "[OK]   $name = $value"
    return 0
  else
    log_tweak "[FAIL] $name - write failed"
    return 1
  fi
}

# KERNEL TWEAKS
if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
  log_boot "Applying kernel tweaks..."
  log_tweak ""
  log_tweak "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log_tweak "KERNEL TWEAKS"
  log_tweak "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  SCHED_PERIOD="$((5 * 1000 * 1000))"
  SCHED_TASKS="5"

  log_tweak ""
  log_tweak "[SCHEDULER]"
  write_val /proc/sys/kernel/perf_cpu_time_max_percent 2 "perf_cpu_time_max_percent"
  write_val /proc/sys/kernel/sched_autogroup_enabled 1 "sched_autogroup_enabled"
  write_val /proc/sys/kernel/sched_child_runs_first 0 "sched_child_runs_first"
  write_val /proc/sys/kernel/sched_tunable_scaling 0 "sched_tunable_scaling"
  write_val /proc/sys/kernel/sched_latency_ns "$SCHED_PERIOD" "sched_latency_ns"
  write_val /proc/sys/kernel/sched_min_granularity_ns "$((SCHED_PERIOD / SCHED_TASKS))" "sched_min_granularity_ns"
  write_val /proc/sys/kernel/sched_wakeup_granularity_ns "$((SCHED_PERIOD / 2))" "sched_wakeup_granularity_ns"
  write_val /proc/sys/kernel/sched_migration_cost_ns 5000000 "sched_migration_cost_ns"
  write_val /proc/sys/kernel/sched_min_task_util_for_colocation 0 "sched_min_task_util_for_colocation"
  write_val /proc/sys/kernel/sched_nr_migrate 256 "sched_nr_migrate"
  write_val /proc/sys/kernel/sched_schedstats 0 "sched_schedstats"
  
  log_tweak ""
  log_tweak "[PANIC SETTINGS]"
  write_val /proc/sys/kernel/panic 0 "kernel.panic"
  write_val /proc/sys/kernel/panic_on_oops 0 "kernel.panic_on_oops"
  write_val /proc/sys/vm/panic_on_oom 0 "vm.panic_on_oom"
  
  log_tweak ""
  log_tweak "[TIMER & PRINTK]"
  write_val /proc/sys/kernel/timer_migration 0 "timer_migration"
  write_val /proc/sys/kernel/printk_devkmsg off "printk_devkmsg"
  echo "0 0 0 0" > /proc/sys/kernel/printk 2>/dev/null && log_tweak "[OK]   printk = 0 0 0 0" || log_tweak "[FAIL] printk"
  
  log_tweak ""
  log_tweak "[VIRTUAL MEMORY]"
  write_val /proc/sys/vm/dirty_background_ratio 2 "dirty_background_ratio"
  write_val /proc/sys/vm/dirty_ratio 5 "dirty_ratio"
  write_val /proc/sys/vm/dirty_expire_centisecs 500 "dirty_expire_centisecs"
  write_val /proc/sys/vm/dirty_writeback_centisecs 500 "dirty_writeback_centisecs"
  write_val /proc/sys/vm/page-cluster 0 "page-cluster"
  write_val /proc/sys/vm/stat_interval 10 "stat_interval"
  write_val /proc/sys/vm/swappiness 100 "swappiness"
  write_val /proc/sys/vm/vfs_cache_pressure 100 "vfs_cache_pressure"
  write_val /proc/sys/vm/oom_dump_tasks 0 "oom_dump_tasks"
  write_val /proc/sys/vm/block_dump 0 "block_dump"
  
  log_tweak ""
  log_tweak "[NETWORK]"
  write_val /proc/sys/net/ipv4/tcp_ecn 1 "tcp_ecn"
  write_val /proc/sys/net/ipv4/tcp_fastopen 3 "tcp_fastopen"
  write_val /proc/sys/net/ipv4/tcp_syncookies 1 "tcp_syncookies"
  write_val /proc/sys/net/ipv4/tcp_no_metrics_save 1 "tcp_no_metrics_save"
  
  log_tweak ""
  log_tweak "[DEBUG]"
  write_val /proc/sys/debug/exception-trace 0 "exception-trace"
  
  log_tweak ""
  log_tweak "[SCHED FEATURES]"
  if [ -f "/sys/kernel/debug/sched_features" ]; then
    echo "NEXT_BUDDY" > /sys/kernel/debug/sched_features 2>/dev/null && log_tweak "[OK]   NEXT_BUDDY" || log_tweak "[FAIL] NEXT_BUDDY"
    echo "NO_TTWU_QUEUE" > /sys/kernel/debug/sched_features 2>/dev/null && log_tweak "[OK]   NO_TTWU_QUEUE" || log_tweak "[FAIL] NO_TTWU_QUEUE"
  else
    log_tweak "[SKIP] sched_features - not accessible"
  fi
  
  log_tweak ""
  log_tweak "[STUNE]"
  if [ -d "/dev/stune/" ]; then
    write_val /dev/stune/top-app/schedtune.prefer_idle 0 "top-app.prefer_idle"
    write_val /dev/stune/top-app/schedtune.boost 0 "top-app.boost"
  else
    log_tweak "[SKIP] stune - not available"
  fi
  
  log_tweak ""
  log_tweak "[MMC CRC]"
  write_val /sys/module/mmc_core/parameters/crc 0 "mmc_crc"
  write_val /sys/module/mmc_core/parameters/use_spi_crc 0 "mmc_spi_crc"
  
  log_tweak ""
  log_tweak "[RAMDUMPS]"
  write_val /sys/module/subsystem_restart/parameters/enable_mini_ramdumps 0 "mini_ramdumps"
  write_val /sys/module/subsystem_restart/parameters/enable_ramdumps 0 "ramdumps"
  
  log_tweak ""
  log_tweak "[DEBUG MASKS]"
  debug_count=0
  for pattern in debug_mask log_level debug_level enable_event_log tracing_on; do
    for path in $(find /sys/ -maxdepth 4 -type f -name "*${pattern}*" 2>/dev/null | head -20); do
      if write_val "$path" 0 "$(basename $path)"; then
        debug_count=$((debug_count + 1))
      fi
    done
  done
  log_tweak "[INFO] Disabled $debug_count debug masks"
  
  log_boot "Kernel tweaks applied (see tweaks.log)"
else
  log_boot "Kernel tweaks SKIPPED (user preference)"
  log_tweak ""
  log_tweak "[SKIPPED] Kernel tweaks disabled by user"
fi

# KILL LOG PROCESSES
log_tweak ""
log_tweak "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_tweak "LOG PROCESS KILLING"
log_tweak "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  log_boot "Killing log processes..."
  log_tweak ""
  
  for SERVICE in logcat logcatd logd tcpdump cnss_diag statsd traced idd-logreader idd-logreadermain stats dumpstate aplogd vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    pid=$(pidof "$SERVICE" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill -15 "$pid" 2>/dev/null
      sleep 1
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null
        log_tweak "[KILL] $SERVICE (PID $pid) - force killed"
      else
        log_tweak "[KILL] $SERVICE (PID $pid) - terminated"
      fi
    else
      log_tweak "[SKIP] $SERVICE - not running"
    fi
  done
  
  log_tweak ""
  logcat -c 2>/dev/null && log_tweak "[OK]   Logcat buffer cleared" || log_tweak "[FAIL] Logcat buffer clear"
  dmesg -c >/dev/null 2>&1 && log_tweak "[OK]   Dmesg buffer cleared" || log_tweak "[FAIL] Dmesg buffer clear"
  
  log_boot "Log processes killed (see tweaks.log)"
else
  log_boot "Log killing SKIPPED (user preference)"
  log_tweak ""
  log_tweak "[SKIPPED] Log killing disabled by user"
fi

# APPLY GMS FREEZING
log_boot ""
log_boot "Applying GMS service freezing..."

chmod +x "$MODDIR/frosty.sh" 2>/dev/null
"$MODDIR/frosty.sh" freeze

log_boot "GMS freezing complete (see services.log)"

# COMPLETION
log_boot ""
log_boot "═════════════════════════════════════"
log_boot "Boot sequence completed at $(date '+%Y-%m-%d %H:%M:%S')"
log_boot "═════════════════════════════════════"

log_tweak ""
log_tweak "═════════════════════════════════════"
log_tweak "Tweaks completed at $(date '+%Y-%m-%d %H:%M:%S')"
log_tweak "═════════════════════════════════════"

exit 0