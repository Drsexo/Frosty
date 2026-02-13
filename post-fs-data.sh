#!/system/bin/sh
# 🧊 FROSTY - Post-FS-Data Script (Optimized)
# Applies system properties, tweaks, and optimizations at boot

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
LOGDIR="$MODDIR/logs"
POSTFS_LOG="$LOGDIR/postfs.log"
ERROR_LOG="$LOGDIR/postfs_errors.log"

mkdir -p "$LOGDIR"

# --- Logging Functions ---
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$POSTFS_LOG"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"; log "[ERROR] $1"; }

# --- Safety Checks ---
check_root() {
  if ! su -c "echo 'root check'" >/dev/null 2>&1; then
    log_error "No root access. Exiting."
    exit 1
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Load User Preferences ---
load_prefs() {
  if [ -f "$MODDIR/config/user_prefs" ]; then
    . "$MODDIR/config/user_prefs"
    log "User preferences loaded"
  else
    log_error "User preferences not found, using defaults"
    ENABLE_BLUR_DISABLE=0
    ENABLE_GMS_DOZE=0
    ENABLE_KERNEL_TWEAKS=1
  fi
}

# --- Resetprop Tweaks ---
apply_resetprop_tweaks() {
  log "Applying resetprop tweaks..."
  resetprop -n tombstoned.max_tombstone_count 0 || log_error "Failed to set tombstoned.max_tombstone_count"
  resetprop -n ro.lmk.debug false || log_error "Failed to set ro.lmk.debug"
  resetprop -n ro.lmk.log_stats false || log_error "Failed to set ro.lmk.log_stats"
  resetprop -n dalvik.vm.dex2oat-minidebuginfo false || log_error "Failed to set dalvik.vm.dex2oat-minidebuginfo"
  resetprop -n dalvik.vm.minidebuginfo false || log_error "Failed to set dalvik.vm.minidebuginfo"
  log "[OK] Resetprop tweaks applied"
}

# --- Blur Effects ---
disable_blur_effects() {
  if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then
    log "Disabling blur effects..."
    resetprop -n disableBlurs true || log_error "Failed to set disableBlurs"
    resetprop -n enable_blurs_on_windows 0 || log_error "Failed to set enable_blurs_on_windows"
    resetprop -n ro.launcher.blur.appLaunch 0 || log_error "Failed to set ro.launcher.blur.appLaunch"
    resetprop -n ro.sf.blurs_are_expensive 0 || log_error "Failed to set ro.sf.blurs_are_expensive"
    resetprop -n ro.surface_flinger.supports_background_blur 0 || log_error "Failed to set ro.surface_flinger.supports_background_blur"
    log "[OK] Blur effects disabled"
  fi
}

# --- GMS Doze ---
disable_gms_battery_exemptions() {
  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    log "Disabling GMS battery exemptions..."
    local GMS0="\"com.google.android.gms\""
    local STR1="allow-in-power-save package=$GMS0"
    local STR2="allow-in-data-usage-save package=$GMS0"
    local STR3="allow-unthrottled-location package=$GMS0"
    local STR4="allow-ignore-location-settings package=$GMS0"

    find /data/adb/modules -type f -name "*.xml" 2>/dev/null | while IFS= read -r xml; do
      case "$xml" in "$MODDIR"*) continue ;; esac
      if grep -qE "$STR1|$STR2|$STR3|$STR4" "$xml" 2>/dev/null; then
        sed -i "/$STR1/d;/$STR2/d;/$STR3/d;/$STR4/d" "$xml" || log_error "Failed to edit $xml"
        log "[OK] Cleaned GMS exemptions in $xml"
      fi
    done
    log "[OK] GMS battery exemptions disabled"
  fi
}

# --- Kernel Tweaks ---
apply_kernel_tweaks() {
  if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
    log "Applying kernel tweaks..."
    # VM Tweaks
    echo "10" > /proc/sys/vm/dirty_ratio || log_error "Failed to set dirty_ratio"
    echo "5" > /proc/sys/vm/dirty_background_ratio || log_error "Failed to set dirty_background_ratio"
    echo "1000" > /proc/sys/vm/dirty_expire_centisecs || log_error "Failed to set dirty_expire_centisecs"
    echo "500" > /proc/sys/vm/dirty_writeback_centisecs || log_error "Failed to set dirty_writeback_centisecs"
    # Scheduler Tweaks
    echo "1" > /proc/sys/kernel/sched_child_runs_first || log_error "Failed to set sched_child_runs_first"
    echo "1" > /proc/sys/kernel/sched_autogroup_enabled || log_error "Failed to set sched_autogroup_enabled"
    # Low Memory Killer
    echo "18432,23040,27648,32256,36864,46080" > /sys/module/lowmemorykiller/parameters/minfree || log_error "Failed to set minfree"
    log "[OK] Kernel tweaks applied"
  fi
}

# --- Main ---
load_prefs
apply_resetprop_tweaks
disable_blur_effects
apply_kernel_tweaks

log "Post-FS-Data script completed"
exit 0
