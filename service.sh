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
  sh "$MODDIR/frosty.sh" apply_kernel >/dev/null 2>&1
  log_boot "Kernel tweaks applied"
else
  log_boot "Kernel tweaks SKIPPED"
fi

if [ "$ENABLE_RAM_OPTIMIZER" = "1" ]; then
  log_boot "Applying RAM optimizer..."
  sh "$MODDIR/frosty.sh" ram_optimizer >/dev/null 2>&1
  log_boot "RAM optimizer applied"
else
  log_boot "RAM optimizer SKIPPED"
fi

if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  log_boot "Killing log processes..."
  sh "$MODDIR/frosty.sh" kill_logs >/dev/null 2>&1
  log_boot "Log processes killed"
else
  log_boot "Log killing SKIPPED"
fi

if [ "$ENABLE_KILL_TRACKING" = "1" ]; then
  log_boot "Blocking Google tracking..."
  sh "$MODDIR/frosty.sh" kill_tracking >/dev/null 2>&1
  log_boot "Google tracking blocked"
else
  log_boot "Kill tracking SKIPPED"
fi

has_frozen_cats=0
for _cat in DISABLE_TELEMETRY DISABLE_BACKGROUND DISABLE_LOCATION DISABLE_CONNECTIVITY DISABLE_CLOUD DISABLE_PAYMENTS DISABLE_WEARABLES DISABLE_GAMES; do
  eval _val=\$$_cat
  [ "$_val" = "1" ] && { has_frozen_cats=1; break; }
done
if [ "$has_frozen_cats" = "1" ]; then
  log_boot "GMS categories enabled - applying freeze..."
  sh "$MODDIR/frosty.sh" freeze >/dev/null 2>&1
else
  log_boot "No GMS categories enabled, skipping GMS freeze"
fi

if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ]; then
  log_boot "Applying App Doze..."
  chmod +x "$MODDIR/app_doze.sh"
  "$MODDIR/app_doze.sh" apply >/dev/null 2>&1
  log_boot "App Doze applied"
else
  log_boot "App Doze SKIPPED"
fi

if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
  log_boot "Applying Deep Doze..."
  chmod +x "$MODDIR/deep_doze.sh"
  "$MODDIR/deep_doze.sh" freeze >/dev/null 2>&1
  log_boot "Deep Doze applied"
else
  log_boot "Deep Doze SKIPPED"
fi

if [ "$ENABLE_BATTERY_SAVER" = "1" ]; then
  log_boot "Applying Battery Saver Tuner..."
  sh "$MODDIR/frosty.sh" bss_apply >/dev/null 2>&1
  log_boot "Battery Saver applied"
else
  log_boot "Battery Saver SKIPPED"
fi

if [ "$ENABLE_SCREEN_OFF_OPT" = "1" ]; then
  log_boot "Starting Screen Off Optimization..."
  chmod +x "$MODDIR/screen_off_opt.sh"
  "$MODDIR/screen_off_opt.sh" start >/dev/null 2>&1
  log_boot "Screen Off Optimization monitor started"
else
  log_boot "Screen Off Optimization SKIPPED"
fi

log_boot "Boot complete at $(date '+%Y-%m-%d %H:%M:%S')"
exit 0