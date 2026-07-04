kill_logs() {
  local k=0
  for svc in logcat logcatd tcpdump cnss_diag traced traced_perf traced_probes \
             idd-logreader idd-logreadermain aplogd vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    pid=$(pidof "$svc" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill -9 "$pid" 2>/dev/null
      k=$((k + 1))
    fi
  done
  logcat -c 2>/dev/null
  dmesg -c >/dev/null 2>&1
  if [ -f /sys/kernel/tracing/tracing_on ]; then
    if [ ! -f "$LOGS_BACKUP" ]; then
      mkdir -p "$(dirname "$LOGS_BACKUP")"
      printf 'tracing_on=%s\n' "$(cat /sys/kernel/tracing/tracing_on 2>/dev/null)" > "$LOGS_BACKUP"
    fi
    echo 0 > /sys/kernel/tracing/tracing_on 2>/dev/null
  fi

  cmd activity logging disable-text >/dev/null 2>&1
  cmd autofill set log_level off >/dev/null 2>&1
  cmd display ab-logging-disable >/dev/null 2>&1
  cmd display dmd-logging-disable >/dev/null 2>&1
  cmd display dwb-logging-disable >/dev/null 2>&1
  cmd input_method tracing stop >/dev/null 2>&1
  cmd statusbar tracing stop >/dev/null 2>&1
  for _wl in $(dumpsys window 2>/dev/null | grep -E "^  (Proto|Logcat):" | sed 's/^  .*://'); do
    cmd window logging disable "$_wl" 2>/dev/null
    cmd window logging disable-text "$_wl" 2>/dev/null
  done
  cmd window logging disable >/dev/null 2>&1
  cmd window logging disable-text >/dev/null 2>&1
  cmd window tracing size 0 >/dev/null 2>&1
  cmd voiceinteraction set-debug-hotword-logging false 2>/dev/null
  cmd wifi set-verbose-logging disabled -l 0 >/dev/null 2>&1
  _devcfg_backup interaction_jank_monitor enabled
  _devcfg_backup interaction_jank_monitor trace_threshold_frame_time_millis
  device_config put interaction_jank_monitor enabled false >/dev/null 2>&1
  device_config put interaction_jank_monitor trace_threshold_frame_time_millis -1 >/dev/null 2>&1
  settings put global netstats_enabled 0 >/dev/null 2>&1
  logcat -G 64k 2>/dev/null

  settings put global battery_stats_constants "track_cpu_times_by_proc_state=false,track_cpu_active_cluster_time=false,read_binary_cpu_time=false,kernel_uid_readers_throttle_time=2000,external_stats_collection_rate_limit_ms=1200000,battery_level_collection_delay_ms=600000,procstate_change_collection_delay_ms=120000,max_history_files=1,max_history_buffer_kb=512,battery_charged_delay_ms=1800000,phone_on_external_stats_collection=false,reset_while_plugged_in_minimum_duration_hours=24" 2>/dev/null

  (
    for tag in $(cat "$DROPBOX_TAGS" 2>/dev/null); do
      content call --uri content://settings/global --method PUT_value \
        --arg "dropbox:$tag" --extra value:s:disabled 2>/dev/null >/dev/null &
    done
    wait
  ) &

  settings put global netstats_poll_interval 60000 >/dev/null 2>&1
  settings put global netstats_persist_threshold 2097152 >/dev/null 2>&1
  settings put global netstats_global_alert_bytes 2097152 >/dev/null 2>&1
  settings put global wifi_scan_throttle_enabled 1 >/dev/null 2>&1
  settings put global wifi_scan_always_enabled 0 >/dev/null 2>&1

  dmesg -n 1 2>/dev/null
  echo 1 > /proc/sys/kernel/printk_ratelimit 2>/dev/null
  echo 1 > /proc/sys/kernel/printk_ratelimit_burst 2>/dev/null

  _devcfg_backup activity_manager disable_app_profiler_pss_profiling
  _devcfg_backup activity_manager activity_start_pss_defer
  device_config put activity_manager disable_app_profiler_pss_profiling true >/dev/null 2>&1
  device_config put activity_manager activity_start_pss_defer 300000 >/dev/null 2>&1

  echo "{\"status\":\"ok\",\"killed\":$k}"
}

revert_kill_logs() {
  if [ -f /sys/kernel/tracing/tracing_on ]; then
    local _trv
    _trv=$(grep '^tracing_on=' "$LOGS_BACKUP" 2>/dev/null | cut -d= -f2)
    echo "${_trv:-1}" > /sys/kernel/tracing/tracing_on 2>/dev/null
  fi
  rm -f "$LOGS_BACKUP"
  (
    for tag in $(cat "$DROPBOX_TAGS" 2>/dev/null); do
      content call --uri content://settings/global --method DELETE_value \
        --arg "dropbox:$tag" 2>/dev/null >/dev/null &
    done
    wait
  ) &

  settings delete global battery_stats_constants 2>/dev/null

  settings delete global netstats_poll_interval >/dev/null 2>&1
  settings delete global netstats_persist_threshold >/dev/null 2>&1
  settings delete global netstats_global_alert_bytes >/dev/null 2>&1

  settings delete global wifi_scan_throttle_enabled >/dev/null 2>&1
  settings delete global wifi_scan_always_enabled >/dev/null 2>&1

  dmesg -n 7 2>/dev/null
  echo 5 > /proc/sys/kernel/printk_ratelimit 2>/dev/null
  echo 10 > /proc/sys/kernel/printk_ratelimit_burst 2>/dev/null

  _devcfg_restore activity_manager disable_app_profiler_pss_profiling
  _devcfg_restore activity_manager activity_start_pss_defer

  _devcfg_restore interaction_jank_monitor enabled
  _devcfg_restore interaction_jank_monitor trace_threshold_frame_time_millis
  settings delete global netstats_enabled >/dev/null 2>&1
  logcat -G 256k 2>/dev/null

  echo '{"status":"ok"}'
}