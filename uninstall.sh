#!/system/bin/sh
# 🧊 FROSTY - Uninstall Script
# Reverts ALL changes made by the module


MODDIR="${0%/*}"
TEMP_DIR="/data/local/tmp/frosty_uninstall"
mkdir -p "$TEMP_DIR"

[ -f "$MODDIR/config/gms_services.txt" ] && cp -f "$MODDIR/config/gms_services.txt" "$TEMP_DIR/"
[ -f "$MODDIR/config/user_prefs" ] && cp -f "$MODDIR/config/user_prefs" "$TEMP_DIR/"

cat > "/data/adb/frosty_uninstall_runner.sh" << 'UNINSTALL_EOF'
#!/system/bin/sh

LOGFILE="/data/local/tmp/frosty_uninstall.log"
TEMP_DIR="/data/local/tmp/frosty_uninstall"
GMS_LIST="$TEMP_DIR/gms_services.txt"
USER_PREFS="$TEMP_DIR/user_prefs"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"; }
echo "Frosty uninstall started $(date)" > "$LOGFILE"

until [ -d "/sdcard/" ]; do sleep 1; done
sleep 5

# Revert settings
log "Reverting settings..."
settings delete global phenotype__debug_bypass_phenotype 2>/dev/null
settings delete global phenotype_boot_count 2>/dev/null
settings delete global phenotype_flags 2>/dev/null

# Revert resetprop
log "Reverting resetprop..."
for prop in tombstoned.max_tombstone_count ro.lmk.debug ro.lmk.log_stats \
  dalvik.vm.dex2oat-minidebuginfo dalvik.vm.minidebuginfo \
  disableBlurs enable_blurs_on_windows ro.launcher.blur.appLaunch \
  ro.sf.blurs_are_expensive ro.surface_flinger.supports_background_blur; do
  resetprop --delete "$prop" 2>/dev/null
done

ENABLE_GMS_DOZE=0
ENABLE_DEEP_DOZE=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

# Revert GMS Doze
if [ "$ENABLE_GMS_DOZE" = "1" ]; then
  log "Reverting GMS Doze..."
  dumpsys deviceidle whitelist +com.google.android.gms >/dev/null 2>&1
  GMS_PKG="com.google.android.gms"
  for user_id in $(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+'); do
    pm enable --user "$user_id" "$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver" >/dev/null 2>&1
    pm enable --user "$user_id" "$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver" >/dev/null 2>&1
  done
  log "GMS Doze reverted"
fi

# Revert Deep Doze
if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
  log "Reverting Deep Doze..."
  settings delete global device_idle_constants 2>/dev/null
  settings put global forced_app_standby_enabled 0 2>/dev/null

  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    appops set "$pkg" RUN_IN_BACKGROUND allow 2>/dev/null
    appops set "$pkg" WAKE_LOCK allow 2>/dev/null
    appops set "$pkg" SCHEDULE_EXACT_ALARM allow 2>/dev/null
    appops set "$pkg" USE_EXACT_ALARM allow 2>/dev/null
    am set-standby-bucket "$pkg" active 2>/dev/null
    am set-inactive "$pkg" false 2>/dev/null
  done

  dumpsys deviceidle unforce 2>/dev/null

  # Kill screen monitor if running
  [ -f "/data/adb/modules/Frosty/tmp/screen_monitor.pid" ] && \
    kill $(cat "/data/adb/modules/Frosty/tmp/screen_monitor.pid") 2>/dev/null
  log "Deep Doze reverted"
fi

# Re-enable GMS services
if [ -f "$GMS_LIST" ]; then
  log "Re-enabling GMS services..."
  count=0
  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in \#*|"") continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    pm enable "$service" >/dev/null 2>&1 && count=$((count + 1))
  done < "$GMS_LIST"
  log "Re-enabled $count services"
fi

log "UNINSTALL COMPLETE - Please reboot"

rm -rf "$TEMP_DIR"
sleep 10
rm -f "/data/adb/frosty_uninstall_runner.sh"

UNINSTALL_EOF

chmod +x "/data/adb/frosty_uninstall_runner.sh"
nohup sh "/data/adb/frosty_uninstall_runner.sh" >/dev/null 2>&1 &