#!/system/bin/sh
# Frosty - Screen Off Optimization daemon

_d="${0%/*}"
[ -z "$_d" ] && _d="/data/adb/modules/Frosty/scripts"
MODDIR="${_d%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
unset _d
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
SOO_LOG="$LOGDIR/screen_off_opt.log"
USER_PREFS="$MODDIR/config/user_prefs"
PID_FILE="$MODDIR/tmp/soo_monitor.pid"
MONITOR_LOCKDIR="$MODDIR/tmp/soo_monitor.lock"
EVENT_PIPE="$MODDIR/tmp/soo_events.fifo"

DISABLED_FILE="$MODDIR/tmp/soo_disabled"
SENSOR_IDLE_FILE="$MODDIR/tmp/soo_sensor_idle.txt"

ENABLE_SCREEN_OFF_OPT=0
SOO_KILL_WIFI=0
SOO_KILL_BT=0
SOO_KILL_DATA=0
SOO_KILL_NFC=0
SOO_KILL_LOCATION=0
SOO_KILL_SENSORS=0
SOO_KILL_PANEL_LPM=0
SOO_CONN_DELAY=5
SOO_RESTORE_ON_UNLOCK=1
SOO_RAM_CLEAN_MODE=off
SOO_RAM_CLEAN_DELAY=5

[ -f "$USER_PREFS" ] && . "$USER_PREFS"

mkdir -p "$LOGDIR" "$MODDIR/tmp"
log_soo() { echo "[$(date '+%H:%M:%S')] $1" >> "$SOO_LOG"; }

. "$MODDIR/scripts/monitor_common.sh"

_get_screen_state() {
  local s
  s=$(dumpsys display 2>/dev/null | grep -m1 "mScreenState=" | cut -d= -f2)
  [ -n "$s" ] && { echo "$s"; return; }
  s=$(dumpsys display 2>/dev/null | grep -m1 "Display Power: state=" | sed 's/.*state=//;s/ .*//')
  [ -n "$s" ] && { echo "$s"; return; }
  local w
  w=$(dumpsys power 2>/dev/null | grep -m1 "mWakefulness=" | cut -d= -f2 | tr -d ' ')
  case "$w" in Awake) echo "ON" ;; Asleep|Dozing|Dreaming) echo "OFF" ;; esac
}

_wifi_is_on() {
  [ "$(settings get global wifi_on 2>/dev/null)" = "1" ] || \
  dumpsys wifi 2>/dev/null | grep -qim1 "wi-fi is enabled"
}
_bt_is_on() {
  [ "$(settings get global bluetooth_on 2>/dev/null)" = "1" ] || \
  dumpsys bluetooth_manager 2>/dev/null | grep -qm1 "^enabled: true"
}
_media_active() {
  dumpsys media_session 2>/dev/null | grep -qEm1 "state=PlaybackState \{state=(3|4|5|6|8|9|10)" && return 0
  dumpsys audio 2>/dev/null | grep -qm1 "state:started"
}
_data_is_on() {
  local _v
  _v=$(settings get global mobile_data1 2>/dev/null)
  if [ -n "$_v" ] && [ "$_v" != "null" ]; then
    [ "$_v" = "1" ]
    return $?
  fi
  [ "$(settings get global mobile_data 2>/dev/null)" = "1" ]
}
_nfc_is_on() {
  local _v
  _v=$(settings get secure nfc_on 2>/dev/null)
  [ "$_v" = "1" ] && return 0
  _v=$(settings get global nfc_on 2>/dev/null)
  [ "$_v" = "1" ] && return 0
  dumpsys nfc 2>/dev/null | grep -qiEm1 "mState: on|mstate=on"
}
_location_mode()  {
  local m
  m=$(settings get secure location_mode 2>/dev/null)
  case "$m" in 1|2|3|4|5) echo "$m" ;; *) echo "0" ;; esac
}
_is_tethering() {
  [ "$(settings get global tether_on 2>/dev/null)" = "1" ] && return 0
  dumpsys tethering 2>/dev/null | grep -qEm1 " - TetheredState" && return 0
  dumpsys connectivity 2>/dev/null | grep -qEm1 " - TetheredState"
}
_guard_reason() {
  case "$1" in
    wifi|data) _call_active && { echo "a call"; return 0; }
               _is_tethering && { echo "tethering"; return 0; } ;;
    bt)        _call_active && { echo "a call"; return 0; }
               _media_active && { echo "media playback"; return 0; } ;;
  esac
  return 1
}

_disable_sensors() {
  _call_active && return 1
  local _dialer _pkg _n=0
  if ! { cmd sensorservice set-uid-state android active && cmd sensorservice reset-uid-state android; } >/dev/null 2>&1; then
    log_soo "[SKIP] Per-app sensor control is not available on this device"
    return 1
  fi
  _dialer=$(_default_dialer)
  for _pkg in $(pm list packages -3 2>/dev/null | sed -n 's/^package://p'); do
    [ "$_pkg" = "$_dialer" ] && continue
    echo "$_pkg" >> "$SENSOR_IDLE_FILE"
    cmd sensorservice set-uid-state "$_pkg" idle >/dev/null 2>&1 && _n=$((_n + 1))
  done
  echo "sensors" >> "$DISABLED_FILE"
  log_soo "[OK] Sensor access blocked for $_n apps (system sensors untouched)"
}

_restore_sensors() {
  local _pkg _n=0
  if [ -f "$SENSOR_IDLE_FILE" ]; then
    for _pkg in $(sort -u "$SENSOR_IDLE_FILE"); do
      cmd sensorservice reset-uid-state "$_pkg" >/dev/null 2>&1 && _n=$((_n + 1))
    done
    rm -f "$SENSOR_IDLE_FILE"
  fi
  log_soo "[OK] Sensor access restored for $_n apps"
}

_release_sensors() {
  grep -q "^sensors$" "$DISABLED_FILE" 2>/dev/null || return 0
  _call_active || ! _is_locked || return 0
  _restore_sensors
  grep -v "^sensors$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
  mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
}

_svc_toggle() {
  local _svc="$1" _verb="$2" _label="$3"
  local _e _rc
  _e=$(/system/bin/svc "$_svc" "$_verb" 2>&1); _rc=$?
  if [ "$_rc" = "0" ]; then
    if [ "$_verb" = "enable" ]; then
      log_soo "[OK] $_label restored"
    else
      log_soo "[OK] $_label disabled"
    fi
  else
    _e=$(printf '%s' "$_e" | tr '\n' ' ')
    log_soo "[FAIL] $_label $_verb rc=$_rc $_e"
  fi
  return "$_rc"
}

_soo_manage_conn() {
  local _tag="$1" _svcname="$2" _pref="$3" _is_on_fn="$4" _label="$5" _why

  [ "$_pref" != "1" ] && { echo settled; return; }

  if grep -q "^${_tag}$" "$DISABLED_FILE" 2>/dev/null; then
    _why=$(_guard_reason "$_tag")
    [ -z "$_why" ] && { echo settled; return; }
    _svc_toggle "$_svcname" enable "$_label" || { echo pending; return; }
    grep -v "^${_tag}$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
    mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
    log_soo "[OK] $_label restored - $_why active"
    echo pending
    return
  fi

  "$_is_on_fn" || { echo settled; return; }

  _why=$(_guard_reason "$_tag")
  if [ -n "$_why" ]; then
    log_soo "[SKIP] $_label - $_why active, will re-check"
    echo pending
  else
    _svc_toggle "$_svcname" disable "$_label" && echo "$_tag" >> "$DISABLED_FILE"
    echo settled
  fi
}

_panel_lpm_on() {
  local _prev
  _prev=$(settings get global display_panel_lpm 2>/dev/null)
  case "$_prev" in 0|1) ;; *) _prev=0 ;; esac
  settings put global display_panel_lpm 1 >/dev/null 2>&1
  echo "panel_lpm:$_prev" >> "$DISABLED_FILE"
}

_panel_lpm_restore() {
  local _prev
  _prev=$(printf '%s\n' "$1" | grep -m1 '^panel_lpm' | cut -d: -f2)
  settings put global display_panel_lpm "${_prev:-0}" >/dev/null 2>&1
}

_step_connections() {
  local wifi_r bt_r data_r nfc_r

  wifi_r=$(_soo_manage_conn wifi wifi "$SOO_KILL_WIFI" _wifi_is_on "Wi-Fi")
  bt_r=$(_soo_manage_conn bt bluetooth "$SOO_KILL_BT" _bt_is_on "Bluetooth")
  data_r=$(_soo_manage_conn data data "$SOO_KILL_DATA" _data_is_on "Mobile data")
  nfc_r=$(_soo_manage_conn nfc nfc "$SOO_KILL_NFC" _nfc_is_on "NFC")

  if [ "$SOO_KILL_LOCATION" = "1" ] && ! grep -q "^location:" "$DISABLED_FILE" 2>/dev/null; then
    local _mode
    _mode=$(_location_mode)
    if [ "$_mode" != "0" ]; then
      settings put secure location_mode 0 >/dev/null 2>&1
      echo "location:$_mode" >> "$DISABLED_FILE"
      log_soo "[OK] Location disabled (was mode $_mode)"
    fi
  fi

  if [ "$SOO_KILL_SENSORS" = "1" ]; then
    if ! grep -q "^sensors$" "$DISABLED_FILE" 2>/dev/null; then
      _disable_sensors
    elif _call_active; then
      _restore_sensors
      grep -v "^sensors$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
      mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
    fi
  fi

  if [ "$SOO_KILL_PANEL_LPM" = "1" ] && ! grep -q "^panel_lpm" "$DISABLED_FILE" 2>/dev/null; then
    _panel_lpm_on
    log_soo "[OK] Panel LPM enabled"
  fi

  case "$wifi_r$bt_r$data_r$nfc_r" in
    *pending*) echo pending ;;
    *) echo settled ;;
  esac
}

_restore_connections() {
  [ -f "$DISABLED_FILE" ] || return
  local _what _fail="${DISABLED_FILE}.fail"
  _what=$(cat "$DISABLED_FILE")
  [ -z "$_what" ] && { rm -f "$DISABLED_FILE"; return; }

  local _list
  _list=$(echo "$_what" | sed 's/^location:.*/location/' | tr '\n' ',' | sed 's/,$//;s/,/, /g')
  log_soo "Restoring: $_list"

  : > "$_fail"
  {
    echo "$_what" | grep -q "^wifi$" && { _svc_toggle wifi enable "Wi-Fi" || echo wifi >> "$_fail"; }
  } &
  {
    echo "$_what" | grep -q "^bt$" && { _svc_toggle bluetooth enable "Bluetooth" || echo bt >> "$_fail"; }
  } &
  {
    echo "$_what" | grep -q "^data$" && { _svc_toggle data enable "Mobile data" || echo data >> "$_fail"; }
  } &
  {
    echo "$_what" | grep -q "^nfc$" && { _svc_toggle nfc enable "NFC" || echo nfc >> "$_fail"; }
  } &
  {
    local _loc
    _loc=$(echo "$_what" | grep "^location:" | cut -d: -f2)
    if [ -n "$_loc" ]; then
      settings put secure location_mode "$_loc" >/dev/null 2>&1
      log_soo "[OK] Location restored (mode $_loc)"
    fi
  } &
  {
    echo "$_what" | grep -q "^sensors$" && _restore_sensors
  } &
  {
    echo "$_what" | grep -q "^panel_lpm" && \
      _panel_lpm_restore "$_what" && log_soo "[OK] Panel LPM disabled"
  } &
  wait

  if [ -s "$_fail" ]; then
    mv -f "$_fail" "$DISABLED_FILE"
  else
    rm -f "$DISABLED_FILE" "$_fail"
  fi
}

_rearm_display_restrictions() {
  [ "$SOO_KILL_SENSORS" = "1" ] && ! grep -q "^sensors$" "$DISABLED_FILE" 2>/dev/null && _disable_sensors
  if [ "$SOO_KILL_PANEL_LPM" = "1" ] && ! grep -q "^panel_lpm" "$DISABLED_FILE" 2>/dev/null; then
    _panel_lpm_on
    log_soo "[OK] Panel LPM re-armed (still locked)"
  fi
}

_forget_reenabled() {
  local _entry _tag _fn
  [ -f "$DISABLED_FILE" ] || return 0
  for _entry in wifi:_wifi_is_on bt:_bt_is_on data:_data_is_on nfc:_nfc_is_on; do
    _tag="${_entry%%:*}"
    _fn="${_entry#*:}"
    grep -q "^${_tag}$" "$DISABLED_FILE" 2>/dev/null || continue
    "$_fn" || continue
    grep -v "^${_tag}$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
    mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
    log_soo "[INFO] $_tag re-enabled by the user, re-arming"
  done
  if grep -q "^location:" "$DISABLED_FILE" 2>/dev/null && [ "$(_location_mode)" != "0" ]; then
    grep -v "^location:" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
    mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
    log_soo "[INFO] location re-enabled by the user, re-arming"
  fi
}

_monitor_loop() {
  trap 'kill -0 "$feed_pid" 2>/dev/null && kill "$feed_pid" 2>/dev/null; rm -f "$EVENT_PIPE"; rmdir "$MONITOR_LOCKDIR" 2>/dev/null; exit 0' TERM INT

  local was_locked=0 locked_since=0
  local conn_started=0 conn_settled=0 cache_done=0
  local was_screen_on=0

  _MONITOR_PIDFILE="$PID_FILE"
  event_fd=0
  feed_pid=""
  feed_fails=0
  _init_event_pipe
  _start_feed

  local _idle_wait=15
  while true; do
    local screen
    screen=$(_get_screen_state)

    if [ "$screen" = "ON" ] && [ -f "$DISABLED_FILE" ]; then
      was_screen_on=1
      _release_sensors
      if grep -q "^panel_lpm" "$DISABLED_FILE" 2>/dev/null; then
        _panel_lpm_restore "$(cat "$DISABLED_FILE")"
        grep -v "^panel_lpm" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
        mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
        log_soo "[OK] Panel LPM disabled"
      fi
    elif [ "$screen" != "ON" ] && [ "$was_screen_on" = "1" ]; then
      was_screen_on=0
      if _is_locked && [ "$conn_started" = "1" ]; then
        _rearm_display_restrictions
      fi
    fi

    if ! _is_locked; then
      if [ "$cache_done" = "1" ] && [ -f "$MODDIR/tmp/ram_clean.pid" ]; then
        kill "$(cat "$MODDIR/tmp/ram_clean.pid" 2>/dev/null)" 2>/dev/null
        rm -f "$MODDIR/tmp/ram_clean.pid"
      fi
      if [ "$SOO_RESTORE_ON_UNLOCK" = "1" ] && [ -s "$DISABLED_FILE" ]; then
        log_soo "Unlocked - restoring"
        _restore_connections
      fi
      was_locked=0; conn_started=0; conn_settled=0; cache_done=0; locked_since=0
      _wait_event "$_idle_wait"
      if [ "$event_fd" != "1" ]; then
        [ "$_idle_wait" -lt 60 ] && _idle_wait=$((_idle_wait + 15))
      else
        _idle_wait=15
      fi
      continue
    fi
    _idle_wait=15

    local now
    now=$(date +%s)

    if [ "$was_locked" = "0" ]; then
      was_locked=1
      locked_since=$now
      conn_started=0; conn_settled=0; cache_done=0
      [ "$SOO_RESTORE_ON_UNLOCK" = "1" ] || _forget_reenabled
      log_soo "Locked - conn=${SOO_CONN_DELAY}m clean=${SOO_RAM_CLEAN_DELAY}m[${SOO_RAM_CLEAN_MODE}]"
    fi

    local elapsed=$(( now - locked_since ))
    local _any_conn_feature="$(( SOO_KILL_WIFI + SOO_KILL_BT + SOO_KILL_DATA + SOO_KILL_NFC + SOO_KILL_LOCATION + SOO_KILL_SENSORS + SOO_KILL_PANEL_LPM ))"

    if [ "$_any_conn_feature" -gt 0 ] && [ "$elapsed" -ge "$(( SOO_CONN_DELAY * 60 ))" ]; then
      if [ "$conn_started" = "0" ]; then
        log_soo "Connections delay reached (${elapsed}s)"
        conn_started=1
      fi
      if [ "$(_step_connections)" = "settled" ]; then
        conn_settled=1
      else
        conn_settled=0
      fi
    fi

    if [ "$SOO_RAM_CLEAN_MODE" != "off" ] && [ -n "$SOO_RAM_CLEAN_MODE" ] && \
       [ "$cache_done" = "0" ] && [ "$elapsed" -ge "$(( SOO_RAM_CLEAN_DELAY * 60 ))" ]; then
      log_soo "RAM clean delay reached (${elapsed}s) mode=$SOO_RAM_CLEAN_MODE"
      sh "$MODDIR/scripts/frosty.sh" ram_clean_silent "$SOO_RAM_CLEAN_MODE" &
      cache_done=1
    fi

    local all_done=1
    [ "$_any_conn_feature" -gt 0 ] && { [ "$conn_started" = "0" ] || [ "$conn_settled" = "0" ]; } && all_done=0
    if [ "$SOO_RAM_CLEAN_MODE" != "off" ] && [ -n "$SOO_RAM_CLEAN_MODE" ] && [ "$cache_done" = "0" ]; then all_done=0; fi

    local _wait=5 _rem _clean_rem
    [ "$event_fd" = "1" ] && _wait=30
    if [ "$all_done" = "0" ]; then
      if [ "$conn_started" = "1" ] && [ "$conn_settled" = "0" ]; then
        _wait=60
      else
        _rem=$_wait
        if [ "$conn_started" = "0" ] && [ "$_any_conn_feature" -gt 0 ]; then
          _rem=$(( SOO_CONN_DELAY * 60 - elapsed ))
        fi
        if [ "$SOO_RAM_CLEAN_MODE" != "off" ] && [ -n "$SOO_RAM_CLEAN_MODE" ] && [ "$cache_done" = "0" ]; then
          _clean_rem=$(( SOO_RAM_CLEAN_DELAY * 60 - elapsed ))
          [ "$_clean_rem" -lt "$_rem" ] && _rem=$_clean_rem
        fi
        [ "$_rem" -lt "$_wait" ] && _wait=$_rem
      fi
    fi
    [ "$_wait" -lt 1 ] && _wait=1
    _wait_event "$_wait"
  done
}

start() {
  stop
  echo "Frosty v${MODVER:-?} - Screen Off Optimization (START) - $(date '+%Y-%m-%d %H:%M:%S')" > "$SOO_LOG"
  [ "$ENABLE_SCREEN_OFF_OPT" != "1" ] && { log_soo "[SKIP] disabled"; return 0; }

  if ! mkdir "$MONITOR_LOCKDIR" 2>/dev/null; then
    log_soo "[WARN] Monitor lock busy, skipping start"
    return 0
  fi

  _monitor_loop &
  echo "$!" > "$PID_FILE"
  log_soo "[OK] PID=$(cat "$PID_FILE")"
  log_soo "wifi=$SOO_KILL_WIFI bt=$SOO_KILL_BT data=$SOO_KILL_DATA nfc=$SOO_KILL_NFC location=$SOO_KILL_LOCATION sensors=$SOO_KILL_SENSORS panel_lpm=$SOO_KILL_PANEL_LPM conn_delay=${SOO_CONN_DELAY}m"
  log_soo "ram_clean_mode=$SOO_RAM_CLEAN_MODE clean_delay=${SOO_RAM_CLEAN_DELAY}m"
  log_soo "restore_on_unlock=$SOO_RESTORE_ON_UNLOCK"
}

stop() {
  local _was_running=0
  [ -f "$PID_FILE" ] && _was_running=1
  _stop_monitor_daemon "$PID_FILE" "$MONITOR_LOCKDIR" "$EVENT_PIPE"
  [ "$_was_running" = "1" ] && log_soo "[OK] Stopped"
  [ -f "$DISABLED_FILE" ] && { log_soo "Restoring on stop..."; _restore_connections; }
  return 0
}

case "$1" in
  start) start ;;
  stop)  stop  ;;
  *) echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
exit $?