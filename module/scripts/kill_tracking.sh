kill_tracking() {
  settings put global gmscorestat_enabled 0 >/dev/null 2>&1
  settings put global play_store_panel_logging_enabled 0 >/dev/null 2>&1
  settings put global clearcut_enabled 0 >/dev/null 2>&1
  settings put global clearcut_events 0 >/dev/null 2>&1
  settings put global clearcut_gcm 0 >/dev/null 2>&1
  settings put global phenotype__debug_bypass_phenotype 1 >/dev/null 2>&1
  settings put global phenotype_boot_count 99 >/dev/null 2>&1
  settings put global phenotype_flags "disable_log_upload=1,disable_log_for_missing_debug_id=1" >/dev/null 2>&1
  settings put global ga_collection_enabled 0 >/dev/null 2>&1
  settings put global analytics_enabled 0 >/dev/null 2>&1
  settings put global uploading_enabled 0 >/dev/null 2>&1
  settings put global bug_report_in_power_menu 0 >/dev/null 2>&1
  settings put global usage_stats_enabled 0 >/dev/null 2>&1
  settings put global usagestats_collection_enabled 0 >/dev/null 2>&1
  settings put global network_watchlist_enabled 0 >/dev/null 2>&1
  settings put global limit_ad_tracking 1 >/dev/null 2>&1
  settings put global tron_enabled 0 >/dev/null 2>&1
  settings put global gms_checkin_timeout_min 120 >/dev/null 2>&1

  local _gms_uid
  _gms_uid=$(dumpsys package com.google.android.gms 2>/dev/null \
    | grep -m1 "userId=" | grep -o 'userId=[0-9]*' | cut -d= -f2)
  [ -n "$_gms_uid" ] && cmd netpolicy add restrict-background-blacklist "$_gms_uid" >/dev/null 2>&1

  settings put global binder_calls_stats \
    "sampling_interval=600000000,detailed_tracking=disable,enabled=false,upload_data=false" >/dev/null 2>&1

  echo '{"status":"ok"}'
}

revert_kill_tracking() {
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
  settings delete global gms_checkin_timeout_min >/dev/null 2>&1

  local _gms_uid
  _gms_uid=$(dumpsys package com.google.android.gms 2>/dev/null \
    | grep -m1 "userId=" | grep -o 'userId=[0-9]*' | cut -d= -f2)
  [ -n "$_gms_uid" ] && cmd netpolicy remove restrict-background-blacklist "$_gms_uid" >/dev/null 2>&1

  settings delete global binder_calls_stats >/dev/null 2>&1

  echo '{"status":"ok"}'
}