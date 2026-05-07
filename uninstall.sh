#!/system/bin/sh
# Frosty - Delayed Uninstallation Handler

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

TEMP_DIR="/data/local/tmp/frosty_uninstall"
mkdir -p "$TEMP_DIR"

[ -f "$MODDIR/config/gms_services.txt" ] && cp -f "$MODDIR/config/gms_services.txt" "$TEMP_DIR/"
[ -f "$MODDIR/config/user_prefs" ]       && cp -f "$MODDIR/config/user_prefs"       "$TEMP_DIR/"
[ -f "$MODDIR/config/doze_patches.txt" ] && cp -f "$MODDIR/config/doze_patches.txt" "$TEMP_DIR/"

# Kill Deep Doze screen monitor
if [ -f "$MODDIR/tmp/screen_monitor.pid" ]; then
  monitor_pid=$(cat "$MODDIR/tmp/screen_monitor.pid" 2>/dev/null)
  [ -n "$monitor_pid" ] && kill "$monitor_pid" 2>/dev/null
fi

# Kill Screen-Off Opt monitor
if [ -f "$MODDIR/tmp/soo_monitor.pid" ]; then
  soo_pid=$(cat "$MODDIR/tmp/soo_monitor.pid" 2>/dev/null)
  [ -n "$soo_pid" ] && kill "$soo_pid" 2>/dev/null
fi

cat > "/data/adb/frosty_uninstall_runner.sh" << 'UNINSTALL_EOF'
#!/system/bin/sh

LOGFILE="/data/local/tmp/frosty_uninstall.log"
TEMP_DIR="/data/local/tmp/frosty_uninstall"
GMS_LIST="$TEMP_DIR/gms_services.txt"
USER_PREFS="$TEMP_DIR/user_prefs"
GMS_PKG="com.google.android.gms"
DEVICEIDLE_XML="/data/system/deviceidle.xml"

log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOGFILE"; }
echo "Frosty uninstall - $(date)" > "$LOGFILE"

sleep 10
[ ! -d "$TEMP_DIR" ] && exit 1
until [ -d "/sdcard/" ]; do sleep 1; done
sleep 5

# Revert resetprop
log "Reverting resetprop..."
for prop in tombstoned.max_tombstone_count tombstoned.max_anr_count ro.lmk.debug ro.lmk.log_stats \
            dalvik.vm.dex2oat-minidebuginfo dalvik.vm.minidebuginfo \
            disableBlurs enable_blurs_on_windows ro.launcher.blur.appLaunch \
            ro.sf.blurs_are_expensive ro.surface_flinger.supports_background_blur \
            persist.traced.enable; do
  resetprop --delete "$prop" 2>/dev/null
done

# Revert RAM optimizer
log "Reverting RAM optimizer..."
content call --uri content://settings/config --method DELETE_value \
  --arg runtime_native/usap_pool_enabled >/dev/null 2>&1
device_config delete activity_manager use_compaction 2>/dev/null
device_config delete activity_manager_native_boot use_freezer 2>/dev/null
device_config delete alarm_manager save_battery_on_idle 2>/dev/null

# Revert Kill Logs device_config
log "Reverting Kill Logs device_config..."
device_config delete activity_manager disable_app_profiler_pss_profiling 2>/dev/null
device_config delete activity_manager activity_start_pss_defer 2>/dev/null

# Revert App Doze (including GMS if it was in the list)
log "Reverting App Doze..."
if [ -f "$DEVICEIDLE_XML" ]; then
  sed -i "/<un-wl /d" "$DEVICEIDLE_XML"
  restorecon "$DEVICEIDLE_XML" 2>/dev/null
fi

cmd deviceidle sys-whitelist +"$GMS_PKG" >/dev/null 2>&1
dumpsys deviceidle whitelist +"$GMS_PKG" >/dev/null 2>&1

user_ids=$(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+' || ls /data/user 2>/dev/null)
for user_id in $user_ids; do
  pm enable --user "$user_id" "$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver" >/dev/null 2>&1
  pm enable --user "$user_id" "$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"   >/dev/null 2>&1
done

PATCHES_FILE="$TEMP_DIR/doze_patches.txt"
if [ -f "$PATCHES_FILE" ]; then
  while IFS= read -r pkg; do
    case "$pkg" in ''|'#'*|'###'*) continue ;; esac
    pkg=$(echo "$pkg" | tr -d ' ')
    [ -z "$pkg" ] && continue
    dumpsys deviceidle whitelist +"$pkg" >/dev/null 2>&1
    cmd appops set "$pkg" IGNORE_BATTERY_OPTIMIZATIONS default 2>/dev/null
  done < "$PATCHES_FILE"
fi

# Remove XML overlays (unified list from app_doze.sh)
XML_OVERLAYS="/data/adb/modules/Frosty/config/doze_xml_overlays.txt"
if [ -f "$XML_OVERLAYS" ]; then
  while IFS= read -r file; do
    case "$file" in '#'*|'') continue ;; esac
    [ -f "$file" ] && rm -f "$file"
  done < "$XML_OVERLAYS"
  rm -f "$XML_OVERLAYS"
fi

# Revert Screen Off Optimization connection state if left disabled
SOO_STATE="/data/adb/modules/Frosty/tmp/soo_disabled"
if [ -f "$SOO_STATE" ]; then
  log "Restoring Screen Off Optimization connection state..."
  while IFS= read -r line; do
    case "$line" in
      wifi)       svc wifi enable 2>/dev/null ;;
      bt)         svc bluetooth enable 2>/dev/null ;;
      data)       svc data enable 2>/dev/null ;;
      location:*) settings put secure location_mode "${line#location:}" 2>/dev/null ;;
    esac
  done < "$SOO_STATE"
  rm -f "$SOO_STATE"
fi

# Revert Battery Saver
log "Reverting Battery Saver..."
settings delete global battery_saver_constants 2>/dev/null
settings put global low_power_sticky 0 2>/dev/null
settings put global low_power_sticky_auto_disable_enabled 1 2>/dev/null
settings put global low_power 0 2>/dev/null

# Revert Deep Doze
log "Reverting Deep Doze..."
settings delete global device_idle_constants 2>/dev/null
settings delete global app_standby_enabled 2>/dev/null
settings delete global adaptive_battery_management_enabled 2>/dev/null

for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
  appops set "$pkg" WAKE_LOCK allow 2>/dev/null
  am set-standby-bucket "$pkg" active 2>/dev/null
  am set-inactive "$pkg" false 2>/dev/null
done
dumpsys deviceidle unforce 2>/dev/null

# Revert DropBox
log "Reverting DropBox..."
for tag in dumpsys:procstats dumpsys:usagestats procstats usagestats \
           data_app_wtf keymaster system_server_wtf system_app_strictmode \
           system_app_wtf system_server_strictmode data_app_strictmode \
           netstats data_app_anr data_app_crash system_server_anr \
           system_server_watchdog system_server_crash system_server_native_crash \
           system_server_lowmem system_app_crash system_app_anr storage_trim \
           SYSTEM_AUDIT SYSTEM_BOOT SYSTEM_LAST_KMSG system_app_native_crash \
           SYSTEM_TOMBSTONE SYSTEM_TOMBSTONE_PROTO data_app_native_crash \
           SYSTEM_RESTART; do
  content call --uri content://settings/global --method DELETE_value \
    --arg "dropbox:$tag" 2>/dev/null >/dev/null
done
settings delete global battery_stats_constants 2>/dev/null

# Revert NetworkStats and WiFi scan
log "Reverting NetworkStats..."
settings delete global netstats_poll_interval 2>/dev/null
settings delete global netstats_persist_threshold 2>/dev/null
settings delete global netstats_global_alert_bytes 2>/dev/null
settings put global wifi_scan_throttle_enabled 1 2>/dev/null
settings put global wifi_scan_always_enabled 1 2>/dev/null

# Revert Google tracking
log "Reverting Google tracking..."
settings put global gmscorestat_enabled 1 >/dev/null 2>&1
settings put global play_store_panel_logging_enabled 1 >/dev/null 2>&1
settings put global clearcut_enabled 1 >/dev/null 2>&1
settings put global clearcut_events 1 >/dev/null 2>&1
settings put global clearcut_gcm 1 >/dev/null 2>&1
settings delete global phenotype__debug_bypass_phenotype >/dev/null 2>&1
settings delete global phenotype_boot_count >/dev/null 2>&1
settings delete global phenotype_flags >/dev/null 2>&1
settings put global ga_collection_enabled 1 >/dev/null 2>&1
settings put global analytics_enabled 1 >/dev/null 2>&1
settings put global uploading_enabled 1 >/dev/null 2>&1
settings put global bug_report_in_power_menu 1 >/dev/null 2>&1
settings put global usage_stats_enabled 1 >/dev/null 2>&1
settings put global usagestats_collection_enabled 1 >/dev/null 2>&1
settings put global network_watchlist_enabled 1 >/dev/null 2>&1
settings put global limit_ad_tracking 0 >/dev/null 2>&1
settings put global tron_enabled 1 >/dev/null 2>&1

# Re-enable GMS services
if [ -f "$GMS_LIST" ]; then
  log "Re-enabling GMS services..."
  count=0
  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in '#'*|'') continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    pm enable "$service" >/dev/null 2>&1 && count=$((count + 1))
  done < "$GMS_LIST"
  log "Re-enabled $count services"
fi

log "UNINSTALL COMPLETE - reboot recommended"
rm -rf "$TEMP_DIR"
sleep 5
rm -f "/data/adb/frosty_uninstall_runner.sh"

UNINSTALL_EOF

chmod +x "/data/adb/frosty_uninstall_runner.sh"
nohup sh "/data/adb/frosty_uninstall_runner.sh" >/dev/null 2>&1 &