#!/system/bin/sh
# 🧊 FROSTY - Uninstall Script
# Reverts ALL changes made by the module

MODDIR="${0%/*}"

# BACKUP FILES BEFORE MODULE REMOVAL
TEMP_DIR="/data/local/tmp/frosty_uninstall"
mkdir -p "$TEMP_DIR"

# Copy gms_services.txt
if [ -f "$MODDIR/config/gms_services.txt" ]; then
  cp -f "$MODDIR/config/gms_services.txt" "$TEMP_DIR/gms_services.txt"
fi

# Copy user_prefs to check if doze was enabled
if [ -f "$MODDIR/config/user_prefs" ]; then
  cp -f "$MODDIR/config/user_prefs" "$TEMP_DIR/user_prefs"
fi

# Verify copy succeeded
if [ ! -f "$TEMP_DIR/gms_services.txt" ]; then
  echo "WARNING: Failed to backup gms_services.txt" >&2
fi

# CREATE BACKGROUND UNINSTALL SCRIPT
cat > "/data/adb/frosty_uninstall_runner.sh" << 'UNINSTALL_EOF'
#!/system/bin/sh

LOGFILE="/data/local/tmp/frosty_uninstall.log"
TEMP_DIR="/data/local/tmp/frosty_uninstall"
GMS_LIST="$TEMP_DIR/gms_services.txt"
USER_PREFS="$TEMP_DIR/user_prefs"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Frosty uninstall started" > "$LOGFILE"

# Wait for sdcard/system to be ready
until [ -d "/sdcard/" ]; do
  sleep 1
done
sleep 5

# REVERSE SYSTEM SETTINGS
log "Reversing system settings..."

settings put global gmscorestat_enabled 1 2>/dev/null
settings put global play_store_panel_logging_enabled 1 2>/dev/null
settings put global clearcut_events 1 2>/dev/null
settings put global clearcut_gcm 1 2>/dev/null
settings delete global phenotype__debug_bypass_phenotype 2>/dev/null
settings delete global phenotype_boot_count 2>/dev/null
settings delete global phenotype_flags 2>/dev/null
settings put global ga_collection_enabled 1 2>/dev/null
settings put global clearcut_enabled 1 2>/dev/null
settings put global analytics_enabled 1 2>/dev/null
settings put global uploading_enabled 1 2>/dev/null
settings put global bug_report_in_power_menu 1 2>/dev/null
settings put global usage_stats_enabled 1 2>/dev/null
settings put global usagestats_collection_enabled 1 2>/dev/null

log "System settings reverted"

# REVERSE RESETPROP CHANGES
log "Reversing resetprop changes..."

resetprop --delete tombstoned.max_tombstone_count 2>/dev/null
resetprop --delete ro.lmk.debug 2>/dev/null
resetprop --delete ro.lmk.log_stats 2>/dev/null
resetprop --delete dalvik.vm.check-dex-sum 2>/dev/null
resetprop --delete dalvik.vm.checkjni 2>/dev/null
resetprop --delete dalvik.vm.dex2oat-minidebuginfo 2>/dev/null
resetprop --delete dalvik.vm.minidebuginfo 2>/dev/null
resetprop --delete dalvik.vm.verify-bytecode 2>/dev/null
resetprop --delete disableBlurs 2>/dev/null
resetprop --delete enable_blurs_on_windows 2>/dev/null
resetprop --delete ro.launcher.blur.appLaunch 2>/dev/null
resetprop --delete ro.sf.blurs_are_expensive 2>/dev/null
resetprop --delete ro.surface_flinger.supports_background_blur 2>/dev/null

log "resetprop changes reverted"

# REVERSE GMS DOZE
log "Reversing GMS Doze..."

# Load user prefs to check if doze was enabled
ENABLE_GMS_DOZE=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

if [ "$ENABLE_GMS_DOZE" = "1" ]; then
  # Re-add GMS to deviceidle whitelist
  dumpsys deviceidle whitelist +com.google.android.gms >/dev/null 2>&1
  log "GMS re-added to deviceidle whitelist"
  
  # Re-enable device admin receivers
  GMS_PKG="com.google.android.gms"
  GMS_ADMIN1="$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver"
  GMS_ADMIN2="$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"
  
  for user_id in $(ls /data/user 2>/dev/null); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      pm enable --user "$user_id" "$admin" >/dev/null 2>&1
    done
  done
  log "Device admin receivers re-enabled"
fi

# RE-ENABLE ALL GMS SERVICES
log "Re-enabling all GMS services..."

if [ -f "$GMS_LIST" ]; then
  count=0
  failed=0
  
  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in
      \#*|"") continue ;;
    esac
    
    service=$(echo "$service" | tr -d ' ')
    
    if pm enable "$service" >/dev/null 2>&1; then
      count=$((count + 1))
    else
      failed=$((failed + 1))
    fi
  done < "$GMS_LIST"
  
  log "Re-enabled $count services ($failed failed/not found)"
else
  log "WARNING: gms_services.txt not found, cannot re-enable services automatically"
fi

# CLEANUP
log ""
log "═════════════════════════════════════"
log "UNINSTALL COMPLETE"
log "═════════════════════════════════════"
log ""
log "Immediately reverted:"
log "  - System settings (analytics, logging)"
log "  - Resetprop properties"
log "  - Disabled GMS services"
log "  - GMS Doze (if enabled)"
log ""
log "What reverts after reboot:"
log "  - System.prop tweaks"
log "  - Kernel tweaks"
log "  - Logging daemons"
log "  - GMS doze XML patches"
log ""
log "PLEASE REBOOT YOUR DEVICE!"

# Cleanup temp files
rm -rf "$TEMP_DIR"
sleep 10
rm -f "/data/adb/frosty_uninstall_runner.sh"

UNINSTALL_EOF

chmod +x "/data/adb/frosty_uninstall_runner.sh"
nohup sh "/data/adb/frosty_uninstall_runner.sh" >/dev/null 2>&1 &