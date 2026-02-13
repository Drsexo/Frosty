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
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Load User Preferences ---
load_prefs() {
  if [ ! -f "$MODDIR/config/user_prefs" ]; then
    log_error "user_prefs no existe. Creando con valores por defecto..."
    mkdir -p "$MODDIR/config"
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
    chmod 644 "$MODDIR/config/user_prefs"
  fi
  if ! . "$MODDIR/config/user_prefs"; then
    log_error "Error al cargar user_prefs. Usando valores por defecto."
    ENABLE_KERNEL_TWEAKS=1
    ENABLE_BLUR_DISABLE=0
    ENABLE_LOG_KILLING=1
    ENABLE_GMS_DOZE=0
    DISABLE_LOCATION=0
  fi
  log "Preferencias del usuario cargadas:"
  log "  Kernel Tweaks: $ENABLE_KERNEL_TWEAKS"
  log "  GMS Doze: $ENABLE_GMS_DOZE"
  log "  Blur Disable: $ENABLE_BLUR_DISABLE"
  log "  Location Disabled: $DISABLE_LOCATION"
  log "  Deep Doze: $ENABLE_DEEP_DOZE ($DEEP_DOZE_LEVEL)"
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
