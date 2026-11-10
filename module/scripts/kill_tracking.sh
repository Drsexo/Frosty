_KT_BACKUP="$MODDIR/backup/kill_tracking.txt"
_KT_NETPOL_MARK="$MODDIR/backup/kt_netpolicy_cleared"

_clear_legacy_blacklist() {
  [ -f "$_KT_NETPOL_MARK" ] && return 0
  local _uid
  _uid=$(dumpsys package com.google.android.gms 2>/dev/null \
    | grep -m1 "userId=" | grep -o 'userId=[0-9]*' | cut -d= -f2)
  [ -n "$_uid" ] && cmd netpolicy remove restrict-background-blacklist "$_uid" >/dev/null 2>&1
  mkdir -p "$MODDIR/backup"
  : > "$_KT_NETPOL_MARK"
}

_kt_settings() {
  cat <<'KT_EOF'
gmscorestat_enabled|0
play_store_panel_logging_enabled|0
clearcut_enabled|0
clearcut_events|0
clearcut_gcm|0
phenotype__debug_bypass_phenotype|1
phenotype_boot_count|99
phenotype_flags|disable_log_upload=1,disable_log_for_missing_debug_id=1
ga_collection_enabled|0
analytics_enabled|0
uploading_enabled|0
bugreport_in_power_menu|0
usage_stats_enabled|0
usagestats_collection_enabled|0
network_watchlist_enabled|0
limit_ad_tracking|1
tron_enabled|0
gms_checkin_timeout_min|120
binder_calls_stats|sampling_interval=600000000,detailed_tracking=disable,enabled=false,upload_data=false
KT_EOF
}

kill_tracking() {
  local _key _val _legacy=0
  mkdir -p "$MODDIR/backup"
  [ -f "$_KT_BACKUP" ] && ! grep -q '^schema=2$' "$_KT_BACKUP" && _legacy=1

  while IFS='|' read -r _key _val; do
    [ -n "$_key" ] || continue
    if ! grep -q "^${_key}=" "$_KT_BACKUP" 2>/dev/null; then
      if [ "$_legacy" = "1" ] && [ "$_key" != "limit_ad_tracking" ]; then
        printf '%s=null\n' "$_key" >> "$_KT_BACKUP"
      else
        printf '%s=%s\n' "$_key" "$(settings get global "$_key" 2>/dev/null)" >> "$_KT_BACKUP"
      fi
    fi
    settings put global "$_key" "$_val" >/dev/null 2>&1
  done <<KT_LOOP
$(_kt_settings)
KT_LOOP
  grep -q '^schema=2$' "$_KT_BACKUP" 2>/dev/null || echo 'schema=2' >> "$_KT_BACKUP"

  settings delete global bug_report_in_power_menu >/dev/null 2>&1
  [ "$_legacy" = "1" ] && _clear_legacy_blacklist

  echo '{"status":"ok"}'
}

revert_kill_tracking() {
  local _key _val _legacy=0
  [ -f "$_KT_BACKUP" ] && ! grep -q '^schema=2$' "$_KT_BACKUP" && _legacy=1
  while IFS='|' read -r _key _; do
    [ -n "$_key" ] || continue
    _val=$(grep "^${_key}=" "$_KT_BACKUP" 2>/dev/null | cut -d= -f2-)
    if [ -n "$_val" ] && [ "$_val" != "null" ]; then
      settings put global "$_key" "$_val" >/dev/null 2>&1
    else
      settings delete global "$_key" >/dev/null 2>&1
    fi
  done <<KT_LOOP
$(_kt_settings)
KT_LOOP
  rm -f "$_KT_BACKUP"
  settings delete global bug_report_in_power_menu >/dev/null 2>&1
  [ "$_legacy" = "1" ] && _clear_legacy_blacklist

  echo '{"status":"ok"}'
}
