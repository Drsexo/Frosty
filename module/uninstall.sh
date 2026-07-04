#!/system/bin/sh
# Frosty - Uninstallation Handler

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

TEMP_DIR="/data/local/tmp/frosty_uninstall"
mkdir -p "$TEMP_DIR"

[ -f "$MODDIR/config/gms_services.txt" ] && cp -f "$MODDIR/config/gms_services.txt" "$TEMP_DIR/"
[ -f "$MODDIR/config/user_prefs" ]       && cp -f "$MODDIR/config/user_prefs"       "$TEMP_DIR/"
[ -f "$MODDIR/config/doze_patches.txt" ] && cp -f "$MODDIR/config/doze_patches.txt" "$TEMP_DIR/"
[ -f "$MODDIR/tmp/frozen_services.txt" ] && cp -f "$MODDIR/tmp/frozen_services.txt" "$TEMP_DIR/"
[ -f "$MODDIR/backup/logs_values.txt" ]  && cp -f "$MODDIR/backup/logs_values.txt"  "$TEMP_DIR/"
[ -f "$MODDIR/backup/lmkd_values.txt" ]  && cp -f "$MODDIR/backup/lmkd_values.txt"  "$TEMP_DIR/"
[ -f "$MODDIR/backup/bss_values.txt" ]   && cp -f "$MODDIR/backup/bss_values.txt"   "$TEMP_DIR/"
[ -f "$MODDIR/config/dropbox_tags.txt" ] && cp -f "$MODDIR/config/dropbox_tags.txt" "$TEMP_DIR/"
[ -f "$MODDIR/backup/devcfg_values.txt" ] && cp -f "$MODDIR/backup/devcfg_values.txt" "$TEMP_DIR/"

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
MODDIR="/data/adb/modules/Frosty"

_set_prop() {
  command -v resetprop >/dev/null 2>&1 && resetprop "$1" "$2" || setprop "$1" "$2" 2>/dev/null
}
_del_prop() {
  command -v resetprop >/dev/null 2>&1 && resetprop --delete "$1" 2>/dev/null || true
}
DEVCFG_BACKUP="$TEMP_DIR/devcfg_values.txt"
_devcfg_restore() {
  local _ns="$1" _key="$2" _orig
  _orig=$(grep -F "${_ns}.${_key}=" "$DEVCFG_BACKUP" 2>/dev/null | cut -d= -f2-)
  if [ -n "$_orig" ] && [ "$_orig" != "null" ]; then
    device_config put "$_ns" "$_key" "$_orig" 2>/dev/null
  else
    device_config delete "$_ns" "$_key" 2>/dev/null
  fi
}

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
  _del_prop "$prop"
done

LOGS_BACKUP="$TEMP_DIR/logs_values.txt"
if [ -f /sys/kernel/tracing/tracing_on ]; then
  _trv=$(grep '^tracing_on=' "$LOGS_BACKUP" 2>/dev/null | cut -d= -f2)
  echo "${_trv:-1}" > /sys/kernel/tracing/tracing_on 2>/dev/null
fi
rm -f "$LOGS_BACKUP"

# Revert RAM optimizer
log "Reverting RAM optimizer..."
content call --uri content://settings/config --method DELETE_value \
  --arg runtime_native/usap_pool_enabled >/dev/null 2>&1
_devcfg_restore activity_manager use_compaction
_devcfg_restore activity_manager_native_boot use_freezer
_devcfg_restore alarm_manager save_battery_on_idle

LMKD_BACKUP="$TEMP_DIR/lmkd_values.txt"
if [ -f "$LMKD_BACKUP" ]; then
  while IFS= read -r _line; do
    case "$_line" in ''|'#'*) continue ;; esac
    _pname=$(printf '%s' "$_line" | cut -d= -f1)
    _pval=$(printf '%s' "$_line" | cut -d= -f2-)
    if [ -n "$_pval" ]; then
      _set_prop "$_pname" "$_pval"
    else
      _del_prop "$_pname"
    fi
  done < "$LMKD_BACKUP"
  rm -f "$LMKD_BACKUP"
  _set_prop lmkd.reinit 1 2>/dev/null || { _lp=$(pidof lmkd 2>/dev/null); [ -n "$_lp" ] && kill -HUP "$_lp" 2>/dev/null; }
fi

# Revert Kill Logs device_config
log "Reverting Kill Logs device_config..."
_devcfg_restore activity_manager disable_app_profiler_pss_profiling
_devcfg_restore activity_manager activity_start_pss_defer
_devcfg_restore interaction_jank_monitor enabled
_devcfg_restore interaction_jank_monitor trace_threshold_frame_time_millis

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
    cmd deviceidle sys-whitelist +"$pkg" >/dev/null 2>&1
    cmd deviceidle except-idle-whitelist +"$pkg" >/dev/null 2>&1
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
      sensors)    settings put global sensors_off 0 2>/dev/null ;;
      panel_lpm)  settings put global display_panel_lpm 0 2>/dev/null ;;
    esac
  done < "$SOO_STATE"
  rm -f "$SOO_STATE"
fi

# Revert Battery Saver
log "Reverting Battery Saver..."
settings delete global battery_saver_constants 2>/dev/null
BSS_BACKUP="$TEMP_DIR/bss_values.txt"
if [ -f "$BSS_BACKUP" ]; then
  _lp=$(grep '^low_power=' "$BSS_BACKUP" | cut -d= -f2)
  _lps=$(grep '^low_power_sticky=' "$BSS_BACKUP" | cut -d= -f2)
  if [ -n "$_lps" ] && [ "$_lps" != "null" ]; then settings put global low_power_sticky "$_lps" 2>/dev/null; else settings put global low_power_sticky 0 2>/dev/null; fi
  if [ -n "$_lp" ] && [ "$_lp" != "null" ]; then settings put global low_power "$_lp" 2>/dev/null; else settings put global low_power 0 2>/dev/null; fi
  rm -f "$BSS_BACKUP"
else
  settings put global low_power_sticky 0 2>/dev/null
  settings put global low_power 0 2>/dev/null
fi

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
dumpsys sensorservice enable 2>/dev/null
dumpsys deviceidle unforce 2>/dev/null

# Revert DropBox
log "Reverting DropBox..."
DROPBOX_TAGS="$TEMP_DIR/dropbox_tags.txt"
for tag in $(cat "$DROPBOX_TAGS" 2>/dev/null); do
  content call --uri content://settings/global --method DELETE_value \
    --arg "dropbox:$tag" 2>/dev/null >/dev/null
done
settings delete global battery_stats_constants 2>/dev/null

# Revert NetworkStats and WiFi scan
log "Reverting NetworkStats..."
settings delete global netstats_poll_interval 2>/dev/null
settings delete global netstats_persist_threshold 2>/dev/null
settings delete global netstats_global_alert_bytes 2>/dev/null
settings delete global wifi_scan_throttle_enabled 2>/dev/null
settings delete global wifi_scan_always_enabled 2>/dev/null

# Revert Kill Tracking netpolicy for GMS
_gms_uid=$(dumpsys package com.google.android.gms 2>/dev/null | grep -m1 "userId=" | grep -o 'userId=[0-9]*' | cut -d= -f2)
[ -n "$_gms_uid" ] && cmd netpolicy remove restrict-background-blacklist "$_gms_uid" 2>/dev/null

# Revert Google tracking
log "Reverting Google tracking..."
settings delete global gmscorestat_enabled >/dev/null 2>&1
settings delete global play_store_panel_logging_enabled >/dev/null 2>&1
settings delete global clearcut_enabled >/dev/null 2>&1
settings delete global clearcut_events >/dev/null 2>&1
settings delete global clearcut_gcm >/dev/null 2>&1
settings delete global phenotype__debug_bypass_phenotype >/dev/null 2>&1
settings delete global phenotype_boot_count >/dev/null 2>&1
settings delete global phenotype_flags >/dev/null 2>&1
settings delete global ga_collection_enabled >/dev/null 2>&1
settings delete global analytics_enabled >/dev/null 2>&1
settings delete global uploading_enabled >/dev/null 2>&1
settings delete global bug_report_in_power_menu >/dev/null 2>&1
settings delete global usage_stats_enabled >/dev/null 2>&1
settings delete global usagestats_collection_enabled >/dev/null 2>&1
settings delete global network_watchlist_enabled >/dev/null 2>&1
settings delete global limit_ad_tracking >/dev/null 2>&1
settings delete global tron_enabled >/dev/null 2>&1
settings delete global gms_checkin_timeout_min 2>/dev/null
settings delete global binder_calls_stats 2>/dev/null

# Re-enable GMS services
_frozen_file="$TEMP_DIR/frozen_services.txt"
if [ -f "$_frozen_file" ]; then
  log "Re-enabling GMS services from tracking file..."
  count=0
  while IFS= read -r service; do
    case "$service" in '#'*|'') continue ;; esac
    pm enable "$service" >/dev/null 2>&1 && count=$((count + 1))
  done < "$_frozen_file"
  rm -f "$_frozen_file"
  log "Re-enabled $count services"
elif [ -f "$GMS_LIST" ]; then
  log "Re-enabling GMS services from full list..."
  count=0
  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in '#'*|'') continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    pm enable "$service" >/dev/null 2>&1 && count=$((count + 1))
  done < "$GMS_LIST"
  log "Re-enabled $count services"
fi

rm -f "$MODDIR/tmp/ram_clean.log" "$MODDIR/tmp/ram_clean.pid" "$MODDIR/tmp/ram_clean_status.json"
log "UNINSTALL COMPLETE - reboot recommended"
rm -rf "$TEMP_DIR"
sleep 5
rm -f "/data/adb/frosty_uninstall_runner.sh"

UNINSTALL_EOF

chmod +x "/data/adb/frosty_uninstall_runner.sh"
nohup sh "/data/adb/frosty_uninstall_runner.sh" >/dev/null 2>&1 &