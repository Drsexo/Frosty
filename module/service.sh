#!/system/bin/sh
# Frosty - Late Boot Execution

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
BOOT_LOG="$LOGDIR/boot.log"
PROPS_LOG="$LOGDIR/props.log"
SYSPROP="$MODDIR/system.prop"
SYSPROP_OLD="$MODDIR/system.prop.old"

mkdir -p "$LOGDIR"
log_boot()  { echo "[$(date '+%H:%M:%S')] $1" >> "$BOOT_LOG"; }
log_props() { echo "[$(date '+%H:%M:%S')] $1" >> "$PROPS_LOG"; }

for log in "$LOGDIR"/*.log; do
  [ -f "$log" ] || continue
  size=$(wc -c < "$log" 2>/dev/null)
  size=${size:-0}
  [ "$size" -gt 102400 ] && mv "$log" "${log}.old"
done

echo "Frosty v${MODVER:-?} - Boot - $(date '+%Y-%m-%d %H:%M:%S')" > "$BOOT_LOG"
echo "Frosty v${MODVER:-?} - Props - $(date '+%Y-%m-%d %H:%M:%S')" > "$PROPS_LOG"

until [ "$(getprop sys.boot_completed)" = "1" ] && [ -d /sdcard ]; do sleep 5; done
sleep 10
log_boot "Boot initialized"

mkdir -p "$MODDIR/config"
. "$MODDIR/config/user_prefs" 2>/dev/null || true

if [ "$ENABLE_SYSTEM_PROPS" = "1" ]; then
  if [ -f "$SYSPROP" ]; then
    PROP_COUNT=$(grep -c '^[^#]' "$SYSPROP" 2>/dev/null || echo "0")
    log_props "[OK] system.prop is ACTIVE - $PROP_COUNT props loaded at boot"
    log_boot "System props: ACTIVE ($PROP_COUNT props)"
  else
    log_props "[WARN] ENABLE_SYSTEM_PROPS=1 but system.prop is missing"
    log_boot "System props: WARNING - file missing despite being enabled"
  fi
else
  if [ -f "$SYSPROP_OLD" ]; then
    log_props "[OFF] system.prop is DISABLED (system.prop.old present)"
    log_boot "System props: DISABLED (.old present)"
  else
    log_props "[OFF] system.prop is DISABLED (no .old file found)"
    log_boot "System props: DISABLED"
  fi
fi

if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
  log_boot "Applying kernel tweaks..."
  if sh "$MODDIR/scripts/frosty.sh" apply_kernel >/dev/null 2>&1; then
    log_boot "Kernel tweaks applied"
  else
    log_boot "[WARN] Kernel tweaks failed"
  fi
else
  log_boot "Kernel tweaks SKIPPED"
fi

if [ "$ENABLE_RAM_OPTIMIZER" = "1" ]; then
  log_boot "Applying RAM optimizer..."
  if sh "$MODDIR/scripts/frosty.sh" apply_ram >/dev/null 2>&1; then
    log_boot "RAM optimizer applied"
  else
    log_boot "[WARN] RAM optimizer failed"
  fi
else
  log_boot "RAM optimizer SKIPPED"
fi

if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  log_boot "Killing log processes..."
  if sh "$MODDIR/scripts/frosty.sh" kill_logs >/dev/null 2>&1; then
    log_boot "Log processes killed"
  else
    log_boot "[WARN] Log killing failed"
  fi
else
  log_boot "Log killing SKIPPED"
fi

if [ "$ENABLE_KILL_TRACKING" = "1" ]; then
  log_boot "Blocking Google tracking..."
  if sh "$MODDIR/scripts/frosty.sh" kill_tracking >/dev/null 2>&1; then
    log_boot "Google tracking blocked"
  else
    log_boot "[WARN] Kill tracking failed"
  fi
else
  log_boot "Kill tracking SKIPPED"
fi

has_frozen_cats=0
if [ "${DISABLE_TELEMETRY:-0}"    = "1" ] ||    [ "${DISABLE_BACKGROUND:-0}"   = "1" ] ||    [ "${DISABLE_LOCATION:-0}"     = "1" ] ||    [ "${DISABLE_CONNECTIVITY:-0}" = "1" ] ||    [ "${DISABLE_CLOUD:-0}"        = "1" ] ||    [ "${DISABLE_PAYMENTS:-0}"     = "1" ] ||    [ "${DISABLE_WEARABLES:-0}"    = "1" ] ||    [ "${DISABLE_GAMES:-0}"        = "1" ]; then
  has_frozen_cats=1
fi
if [ "$has_frozen_cats" = "1" ]; then
  log_boot "GMS categories enabled - applying freeze..."
  if sh "$MODDIR/scripts/frosty.sh" freeze >/dev/null 2>&1; then
    log_boot "GMS freeze applied"
  else
    log_boot "[WARN] GMS freeze failed"
  fi
else
  log_boot "No GMS categories enabled, skipping GMS freeze"
fi

if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ]; then
  log_boot "Applying App Doze..."
  if sh "$MODDIR/scripts/app_doze.sh" apply >/dev/null 2>&1; then
    log_boot "App Doze applied"
  else
    log_boot "[WARN] App Doze failed"
  fi
else
  log_boot "App Doze SKIPPED"
fi

if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
  log_boot "Applying Deep Doze..."
  if sh "$MODDIR/scripts/deep_doze.sh" freeze >/dev/null 2>&1; then
    log_boot "Deep Doze applied"
  else
    log_boot "[WARN] Deep Doze failed"
  fi
else
  log_boot "Deep Doze SKIPPED"
fi

if [ "$ENABLE_BATTERY_SAVER" = "1" ]; then
  log_boot "Applying Battery Saver Tuner..."
  if sh "$MODDIR/scripts/frosty.sh" apply_bss >/dev/null 2>&1; then
    log_boot "Battery Saver applied"
  else
    log_boot "[WARN] Battery Saver failed"
  fi
else
  log_boot "Battery Saver SKIPPED"
fi

if [ "$ENABLE_SCREEN_OFF_OPT" = "1" ]; then
  log_boot "Starting Screen Off Optimization..."
  if sh "$MODDIR/scripts/screen_off_opt.sh" start >/dev/null 2>&1; then
    log_boot "Screen Off Optimization monitor started"
  else
    log_boot "[WARN] Screen Off Optimization failed to start"
  fi
else
  log_boot "Screen Off Optimization SKIPPED"
fi

log_boot "Boot complete at $(date '+%Y-%m-%d %H:%M:%S')"

for _rbt in "$MODDIR/tmp/"*_needs_reboot; do
  [ -f "$_rbt" ] && { log_boot "Please reboot to apply all changes"; break; }
done
unset _rbt
exit 0