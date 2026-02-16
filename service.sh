#!/system/bin/sh
# 🧊 FROSTY - Service script
# Applies kernel tweaks and initializes GMS freezing on boot

MODDIR="${0%/*}"
LOGDIR="$MODDIR/logs"
BACKUP_DIR="$MODDIR/backup"
mkdir -p "$LOGDIR" "$BACKUP_DIR"
BOOT_LOG="$LOGDIR/boot.log"
TWEAKS_LOG="$LOGDIR/tweaks.log"
KERNEL_BACKUP="$BACKUP_DIR/kernel_values.txt"

# timeout fallback
if ! command -v timeout >/dev/null 2>&1; then
  timeout() { shift; "$@"; }
fi

# Log rotation (single .old)
for log in "$LOGDIR"/*.log; do
  [ -f "$log" ] || continue
  size=$(wc -c < "$log" 2>/dev/null)
  size=${size:-0}
  [ "$size" -gt 102400 ] && mv "$log" "${log}.old"
done

log_boot() { echo "[$(date '+%H:%M:%S')] $1" >> "$BOOT_LOG"; }
log_tweak() { echo "$1" >> "$TWEAKS_LOG"; }

echo "Frosty Boot - $(date '+%Y-%m-%d %H:%M:%S')" > "$BOOT_LOG"
echo "Frosty Tweaks - $(date '+%Y-%m-%d %H:%M:%S')" > "$TWEAKS_LOG"

# Wait for boot (same timeout as gloeyisk: 100s)
until [ "$(getprop sys.boot_completed)" = "1" ] && [ -d /sdcard ]; do
  sleep 5
done
sleep 10
log_boot "Boot initialized"

# Wait for GMS
gms_wait=0
while ! pidof com.google.android.gms >/dev/null 2>&1; do
  sleep 2
  gms_wait=$((gms_wait + 2))
  [ $gms_wait -ge 60 ] && break
done
log_boot "GMS ready"

# Device info
log_boot "Device: $(getprop ro.product.model)"
log_boot "Android: $(getprop ro.build.version.release) SDK$(getprop ro.build.version.sdk)"

mkdir -p "$MODDIR/config"

# Load preferences
if [ ! -f "$MODDIR/config/user_prefs" ]; then
  cat > "$MODDIR/config/user_prefs" << EOF
ENABLE_KERNEL_TWEAKS=1
ENABLE_BLUR_DISABLE=0
ENABLE_LOG_KILLING=1
ENABLE_GMS_DOZE=1
ENABLE_DEEP_DOZE=1
DEEP_DOZE_LEVEL=moderate
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

[ ! -f "$MODDIR/config/state" ] && echo "frozen" > "$MODDIR/config/state"

write_val() {
  local file="$1" value="$2" name="$3"
  [ ! -f "$file" ] && { log_tweak "[SKIP] $name"; return 1; }
  chmod +w "$file" 2>/dev/null
  if echo "$value" > "$file" 2>/dev/null; then
    log_tweak "[OK] $name = $value"
  else
    log_tweak "[FAIL] $name"
  fi
}

# Backup current kernel values before tweaking
backup_kernel() {
  log_boot "Backing up kernel values..."
  echo "# Kernel Backup - $(date '+%Y-%m-%d %H:%M:%S')" > "$KERNEL_BACKUP"

  for pair in \
    "perf_cpu_time_max_percent:/proc/sys/kernel/perf_cpu_time_max_percent" \
    "sched_autogroup_enabled:/proc/sys/kernel/sched_autogroup_enabled" \
    "sched_child_runs_first:/proc/sys/kernel/sched_child_runs_first" \
    "sched_tunable_scaling:/proc/sys/kernel/sched_tunable_scaling" \
    "sched_latency_ns:/proc/sys/kernel/sched_latency_ns" \
    "sched_min_granularity_ns:/proc/sys/kernel/sched_min_granularity_ns" \
    "sched_wakeup_granularity_ns:/proc/sys/kernel/sched_wakeup_granularity_ns" \
    "sched_migration_cost_ns:/proc/sys/kernel/sched_migration_cost_ns" \
    "sched_min_task_util_for_colocation:/proc/sys/kernel/sched_min_task_util_for_colocation" \
    "sched_nr_migrate:/proc/sys/kernel/sched_nr_migrate" \
    "sched_schedstats:/proc/sys/kernel/sched_schedstats" \
    "panic:/proc/sys/kernel/panic" \
    "panic_on_oops:/proc/sys/kernel/panic_on_oops" \
    "vm_panic_on_oom:/proc/sys/vm/panic_on_oom" \
    "timer_migration:/proc/sys/kernel/timer_migration" \
    "printk_devkmsg:/proc/sys/kernel/printk_devkmsg" \
    "printk:/proc/sys/kernel/printk" \
    "dirty_background_ratio:/proc/sys/vm/dirty_background_ratio" \
    "dirty_ratio:/proc/sys/vm/dirty_ratio" \
    "dirty_expire_centisecs:/proc/sys/vm/dirty_expire_centisecs" \
    "dirty_writeback_centisecs:/proc/sys/vm/dirty_writeback_centisecs" \
    "page_cluster:/proc/sys/vm/page-cluster" \
    "stat_interval:/proc/sys/vm/stat_interval" \
    "swappiness:/proc/sys/vm/swappiness" \
    "vfs_cache_pressure:/proc/sys/vm/vfs_cache_pressure" \
    "oom_dump_tasks:/proc/sys/vm/oom_dump_tasks" \
    "block_dump:/proc/sys/vm/block_dump" \
    "tcp_ecn:/proc/sys/net/ipv4/tcp_ecn" \
    "tcp_fastopen:/proc/sys/net/ipv4/tcp_fastopen" \
    "tcp_syncookies:/proc/sys/net/ipv4/tcp_syncookies" \
    "tcp_no_metrics_save:/proc/sys/net/ipv4/tcp_no_metrics_save" \
    "exception_trace:/proc/sys/debug/exception-trace" \
    "read_wakeup_threshold:/proc/sys/kernel/random/read_wakeup_threshold" \
    "write_wakeup_threshold:/proc/sys/kernel/random/write_wakeup_threshold" \
    "printk_ratelimit:/proc/sys/kernel/printk_ratelimit" \
    "printk_ratelimit_burst:/proc/sys/kernel/printk_ratelimit_burst"; do

    name="${pair%%:*}"
    path="${pair#*:}"
    if [ -f "$path" ]; then
      val=$(cat "$path" 2>/dev/null)
      echo "$name=$val=$path" >> "$KERNEL_BACKUP"
    fi
  done

  log_boot "Kernel backup saved"
}

# Kernel tweaks
if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
  log_boot "Applying kernel tweaks..."
  backup_kernel

  SCHED_PERIOD="$((5 * 1000 * 1000))"
  SCHED_TASKS="5"

  log_tweak ""
  log_tweak "SCHEDULER"
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
  log_tweak "PANIC"
  write_val /proc/sys/kernel/panic 0 "kernel.panic"
  write_val /proc/sys/kernel/panic_on_oops 0 "kernel.panic_on_oops"
  write_val /proc/sys/vm/panic_on_oom 0 "vm.panic_on_oom"

  log_tweak ""
  log_tweak "TIMER & PRINTK"
  write_val /proc/sys/kernel/timer_migration 0 "timer_migration"
  write_val /proc/sys/kernel/printk_devkmsg off "printk_devkmsg"
  echo "0 0 0 0" > /proc/sys/kernel/printk 2>/dev/null

  log_tweak ""
  log_tweak "VM"
  write_val /proc/sys/vm/dirty_background_ratio 2 "dirty_background_ratio"
  write_val /proc/sys/vm/dirty_ratio 5 "dirty_ratio"
  write_val /proc/sys/vm/dirty_expire_centisecs 500 "dirty_expire_centisecs"
  write_val /proc/sys/vm/dirty_writeback_centisecs 500 "dirty_writeback_centisecs"
  write_val /proc/sys/vm/stat_interval 10 "stat_interval"
  write_val /proc/sys/vm/vfs_cache_pressure 100 "vfs_cache_pressure"
  write_val /proc/sys/vm/oom_dump_tasks 0 "oom_dump_tasks"
  write_val /proc/sys/vm/block_dump 0 "block_dump"

  log_tweak ""
  log_tweak "NETWORK"
  write_val /proc/sys/net/ipv4/tcp_ecn 1 "tcp_ecn"
  write_val /proc/sys/net/ipv4/tcp_fastopen 3 "tcp_fastopen"
  write_val /proc/sys/net/ipv4/tcp_syncookies 1 "tcp_syncookies"
  write_val /proc/sys/net/ipv4/tcp_no_metrics_save 1 "tcp_no_metrics_save"

  log_tweak ""
  log_tweak "DEBUG"
  write_val /proc/sys/debug/exception-trace 0 "exception-trace"

  log_tweak ""
  log_tweak "ENTROPY"
  write_val /proc/sys/kernel/random/read_wakeup_threshold 256 "read_wakeup_threshold"
  write_val /proc/sys/kernel/random/write_wakeup_threshold 320 "write_wakeup_threshold"

  log_tweak ""
  log_tweak "PRINTK RATELIMIT"
  write_val /proc/sys/kernel/printk_ratelimit 1 "printk_ratelimit"
  write_val /proc/sys/kernel/printk_ratelimit_burst 5 "printk_ratelimit_burst"

  log_tweak ""
  log_tweak "SCHED FEATURES"
  if [ -f "/sys/kernel/debug/sched_features" ]; then
    echo "NEXT_BUDDY" > /sys/kernel/debug/sched_features 2>/dev/null
    echo "NO_TTWU_QUEUE" > /sys/kernel/debug/sched_features 2>/dev/null
  fi

  log_tweak ""
  log_tweak "STUNE"
  if [ -d "/dev/stune/" ]; then
    write_val /dev/stune/top-app/schedtune.prefer_idle 0 "top-app.prefer_idle"
    write_val /dev/stune/top-app/schedtune.boost 0 "top-app.boost"
  fi

  log_tweak ""
  log_tweak "RAMDUMPS"
  write_val /sys/module/subsystem_restart/parameters/enable_mini_ramdumps 0 "mini_ramdumps"
  write_val /sys/module/subsystem_restart/parameters/enable_ramdumps 0 "ramdumps"

  log_tweak ""
  log_tweak "DEBUG MASKS"
  debug_count=0
  for pattern in debug_mask log_level debug_level enable_event_log tracing_on; do
    for path in $(find /sys/ -maxdepth 4 -type f -name "*${pattern}*" 2>/dev/null | head -20); do
      if write_val "$path" 0 "$(basename "$path")"; then
        debug_count=$((debug_count + 1))
      fi
    done
  done
  log_tweak "Disabled $debug_count debug masks"
  log_boot "Kernel tweaks applied"
else
  log_boot "Kernel tweaks SKIPPED"
fi

# Kill log processes
if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  log_boot "Killing log processes..."
  for svc in logcat logcatd logd tcpdump cnss_diag statsd traced idd-logreader idd-logreadermain dumpstate aplogd vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    pid=$(pidof "$svc" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill -15 "$pid" 2>/dev/null
      sleep 0.5
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi
  done
  logcat -c 2>/dev/null
  dmesg -c >/dev/null 2>&1
  log_boot "Log processes killed"
else
  log_boot "Log killing SKIPPED"
fi

# Apply GMS freezing (includes GMS Doze apply and Deep Doze)
log_boot "Applying GMS freezing..."
chmod +x "$MODDIR/frosty.sh"
"$MODDIR/frosty.sh" freeze

log_boot "Boot complete at $(date '+%Y-%m-%d %H:%M:%S')"

exit 0