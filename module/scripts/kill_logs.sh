_backup_global_setting() {
  local _key="$1" _marker="gs:${1}="
  grep -q "^${_marker}" "$LOGS_BACKUP" 2>/dev/null && return
  printf '%s%s\n' "$_marker" "$(settings get global "$_key" 2>/dev/null)" >> "$LOGS_BACKUP"
}

_restore_global_setting() {
  local _key="$1" _marker="gs:${1}=" _val
  _val=$(grep "^${_marker}" "$LOGS_BACKUP" 2>/dev/null | cut -d= -f2-)
  if [ -z "$_val" ] || [ "$_val" = "null" ]; then
    settings delete global "$_key" >/dev/null 2>&1
  else
    settings put global "$_key" "$_val" >/dev/null 2>&1
  fi
}

kill_logs() {
  local k=0
  mkdir -p "$(dirname "$LOGS_BACKUP")"
  for svc in logcat logcatd tcpdump cnss_diag traced traced_perf traced_probes \
             idd-logreader idd-logreadermain aplogd vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    for pid in $(pidof "$svc" 2>/dev/null); do
      grep -qsx "$pid" "$MODDIR"/tmp/*.pid.feed && continue
      kill -9 "$pid" 2>/dev/null && k=$((k + 1))
    done
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
    cmd window logging disable "$_wl" >/dev/null 2>&1
    cmd window logging disable-text "$_wl" >/dev/null 2>&1
  done
  cmd window logging disable >/dev/null 2>&1
  cmd window logging disable-text >/dev/null 2>&1
  cmd window tracing size 0 >/dev/null 2>&1
  cmd voiceinteraction set-debug-hotword-logging false >/dev/null 2>&1
  cmd wifi set-verbose-logging disabled -l 0 >/dev/null 2>&1
  _devcfg_backup interaction_jank_monitor enabled
  _devcfg_backup interaction_jank_monitor trace_threshold_frame_time_millis
  device_config put interaction_jank_monitor enabled false >/dev/null 2>&1
  device_config put interaction_jank_monitor trace_threshold_frame_time_millis -1 >/dev/null 2>&1
  _backup_global_setting netstats_enabled
  settings put global netstats_enabled 0 >/dev/null 2>&1
  logcat -G 64k 2>/dev/null

  _backup_global_setting battery_stats_constants
  settings put global battery_stats_constants "track_cpu_times_by_proc_state=false,track_cpu_active_cluster_time=false,read_binary_cpu_time=false,kernel_uid_readers_throttle_time=2000,external_stats_collection_rate_limit_ms=1200000,battery_level_collection_delay_ms=600000,procstate_change_collection_delay_ms=120000,max_history_files=1,max_history_buffer_kb=512,battery_charged_delay_ms=1800000,phone_on_external_stats_collection=false,reset_while_plugged_in_minimum_duration_hours=24" >/dev/null 2>&1

  for tag in $(cat "$DROPBOX_TAGS" 2>/dev/null); do
    _backup_global_setting "dropbox:$tag"
    settings put global "dropbox:$tag" disabled >/dev/null 2>&1 &
  done
  wait

  _backup_global_setting netstats_poll_interval
  _backup_global_setting netstats_persist_threshold
  _backup_global_setting netstats_global_alert_bytes
  _backup_global_setting wifi_scan_throttle_enabled
  _backup_global_setting wifi_scan_always_enabled
  settings put global netstats_poll_interval 60000 >/dev/null 2>&1
  settings put global netstats_persist_threshold 2097152 >/dev/null 2>&1
  settings put global netstats_global_alert_bytes 2097152 >/dev/null 2>&1
  settings put global wifi_scan_throttle_enabled 1 >/dev/null 2>&1
  settings put global wifi_scan_always_enabled 0 >/dev/null 2>&1

  if [ "${ENABLE_KERNEL_TWEAKS:-0}" != "1" ]; then
    if [ ! -f "$LOGS_BACKUP" ] || ! grep -q '^console_loglevel=' "$LOGS_BACKUP" 2>/dev/null; then
      printf 'console_loglevel=%s\n' "$(awk '{print $1}' /proc/sys/kernel/printk 2>/dev/null)" >> "$LOGS_BACKUP"
    fi
    dmesg -n 1 2>/dev/null
  fi
  grep -q '^printk_ratelimit=' "$LOGS_BACKUP" 2>/dev/null || \
    printf 'printk_ratelimit=%s\n' "$(cat /proc/sys/kernel/printk_ratelimit 2>/dev/null)" >> "$LOGS_BACKUP"
  grep -q '^printk_ratelimit_burst=' "$LOGS_BACKUP" 2>/dev/null || \
    printf 'printk_ratelimit_burst=%s\n' "$(cat /proc/sys/kernel/printk_ratelimit_burst 2>/dev/null)" >> "$LOGS_BACKUP"
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
    [ -n "$_trv" ] && echo "$_trv" > /sys/kernel/tracing/tracing_on 2>/dev/null
  fi

  (
    for tag in $(cat "$DROPBOX_TAGS" 2>/dev/null); do
      _restore_global_setting "dropbox:$tag" &
    done
    wait
  ) &

  _restore_global_setting battery_stats_constants
  _restore_global_setting netstats_poll_interval
  _restore_global_setting netstats_persist_threshold
  _restore_global_setting netstats_global_alert_bytes
  _restore_global_setting wifi_scan_throttle_enabled
  _restore_global_setting wifi_scan_always_enabled

  local _clv _prl _prb
  _clv=$(grep '^console_loglevel=' "$LOGS_BACKUP" 2>/dev/null | cut -d= -f2)
  _prl=$(grep '^printk_ratelimit=' "$LOGS_BACKUP" 2>/dev/null | cut -d= -f2)
  _prb=$(grep '^printk_ratelimit_burst=' "$LOGS_BACKUP" 2>/dev/null | cut -d= -f2)
  dmesg -n "${_clv:-7}" 2>/dev/null
  echo "${_prl:-5}" > /proc/sys/kernel/printk_ratelimit 2>/dev/null
  echo "${_prb:-10}" > /proc/sys/kernel/printk_ratelimit_burst 2>/dev/null

  _devcfg_restore activity_manager disable_app_profiler_pss_profiling
  _devcfg_restore activity_manager activity_start_pss_defer

  _devcfg_restore interaction_jank_monitor enabled
  _devcfg_restore interaction_jank_monitor trace_threshold_frame_time_millis
  _restore_global_setting netstats_enabled
  logcat -G 256k 2>/dev/null

  rm -f "$LOGS_BACKUP"
  echo '{"status":"ok"}'
}