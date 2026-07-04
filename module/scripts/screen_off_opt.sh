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

DISABLED_FILE="$MODDIR/tmp/soo_disabled"

ENABLE_SCREEN_OFF_OPT=0
SOO_KILL_WIFI=0
SOO_KILL_BT=0
SOO_KILL_DATA=0
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

_is_locked() {
  local _trust
  _trust=$(dumpsys trust 2>/dev/null | grep -m1 "Keyguard showing")
  case "$_trust" in
    *true*)  return 0 ;;
    *false*) return 1 ;;
  esac
  dumpsys window policy 2>/dev/null | \
    grep -qE "isKeyguardShowing=true|mShowingLockscreen=true" && return 0
  dumpsys activity activities 2>/dev/null | \
    grep -qm1 "mKeyguardShowing=true" && return 0
  return 1
}

_wifi_is_on() {
  [ "$(settings get global wifi_on 2>/dev/null)" = "1" ] || \
  dumpsys wifi 2>/dev/null | grep -qim1 "wi-fi is enabled"
}
_bt_is_on() {
  [ "$(settings get global bluetooth_on 2>/dev/null)" = "1" ] || \
  dumpsys bluetooth_manager 2>/dev/null | grep -qm1 "^enabled: true"
}
_media_active()   { dumpsys media_session 2>/dev/null | grep -qm1 "state=PlaybackState {state=3"; }
_data_is_on()     { [ "$(settings get global mobile_data 2>/dev/null)" = "1" ]; }
_location_mode()  {
  local m
  m=$(settings get secure location_mode 2>/dev/null)
  case "$m" in 1|2|3|4|5) echo "$m" ;; *) echo "0" ;; esac
}

_disable_sensors() {
  settings put global sensors_off 1 2>/dev/null
  echo "sensors" >> "$DISABLED_FILE"
  log_soo "[OK] Sensors disabled"
}

_restore_sensors() {
  settings put global sensors_off 0 2>/dev/null
  log_soo "[OK] Sensors restored"
}

_is_tethering() {
  [ "$(settings get global tether_on 2>/dev/null)" = "1" ] && return 0
  dumpsys connectivity 2>/dev/null | grep -qim1 "TetheredState\|tethering.*true" && return 0
  return 1
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

_disable_connections() {
  rm -f "$DISABLED_FILE"

  if [ "$SOO_KILL_WIFI" = "1" ] && _wifi_is_on; then
    _svc_toggle wifi disable "Wi-Fi" && echo "wifi" >> "$DISABLED_FILE"
  fi

  if [ "$SOO_KILL_BT" = "1" ] && _bt_is_on; then
    if _media_active; then
      log_soo "[SKIP] Bluetooth - media playback active"
    else
      _svc_toggle bluetooth disable "Bluetooth" && echo "bt" >> "$DISABLED_FILE"
    fi
  fi

  if [ "$SOO_KILL_DATA" = "1" ] && _data_is_on; then
    if _is_tethering; then
      log_soo "[SKIP] Mobile data - tethering active"
    else
      _svc_toggle data disable "Mobile data" && echo "data" >> "$DISABLED_FILE"
    fi
  fi

  if [ "$SOO_KILL_LOCATION" = "1" ]; then
    local _mode
    _mode=$(_location_mode)
    if [ "$_mode" != "0" ]; then
      settings put secure location_mode 0 2>/dev/null
      echo "location:$_mode" >> "$DISABLED_FILE"
      log_soo "[OK] Location disabled (was mode $_mode)"
    fi
  fi

  if [ "$SOO_KILL_SENSORS" = "1" ]; then
    _disable_sensors
  fi

  if [ "$SOO_KILL_PANEL_LPM" = "1" ]; then
    settings put global display_panel_lpm 1 2>/dev/null
    echo "panel_lpm" >> "$DISABLED_FILE"
    log_soo "[OK] Panel LPM enabled"
  fi

  [ -f "$DISABLED_FILE" ] || log_soo "[INFO] No connections were on - nothing disabled"
}

_restore_connections() {
  [ -f "$DISABLED_FILE" ] || return
  local _what
  _what=$(cat "$DISABLED_FILE")
  [ -z "$_what" ] && { rm -f "$DISABLED_FILE"; return; }

  local _list
  _list=$(echo "$_what" | sed 's/^location:.*/location/' | tr '\n' ',' | sed 's/,$//;s/,/, /g')
  log_soo "Restoring: $_list"

  {
    echo "$_what" | grep -q "^wifi$" && _svc_toggle wifi enable "Wi-Fi"
  } &
  {
    echo "$_what" | grep -q "^bt$" && _svc_toggle bluetooth enable "Bluetooth"
  } &
  {
    echo "$_what" | grep -q "^data$" && _svc_toggle data enable "Mobile data"
  } &
  {
    local _loc
    _loc=$(echo "$_what" | grep "^location:" | cut -d: -f2)
    if [ -n "$_loc" ]; then
      settings put secure location_mode "$_loc" 2>/dev/null
      log_soo "[OK] Location restored (mode $_loc)"
    fi
  } &
  {
    echo "$_what" | grep -q "^sensors$" && _restore_sensors
  } &
  {
    echo "$_what" | grep -q "^panel_lpm$" && \
      settings put global display_panel_lpm 0 2>/dev/null && log_soo "[OK] Panel LPM disabled"
  } &
  wait
  rm -f "$DISABLED_FILE"
}


_monitor_loop() {
  trap 'exit 0' TERM INT

  local screen_was_off=0 off_since=0
  local conn_done=0 cache_done=0

  while true; do
    local screen
    screen=$(_get_screen_state)

    if [ "$screen" = "ON" ] || [ -z "$screen" ]; then
      if [ "$screen_was_off" = "1" ]; then
        if [ -f "$DISABLED_FILE" ]; then
          if grep -q "^sensors$" "$DISABLED_FILE" 2>/dev/null; then
            _restore_sensors
            grep -v "^sensors$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
            mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
          fi
          if grep -q "^panel_lpm$" "$DISABLED_FILE" 2>/dev/null; then
            settings put global display_panel_lpm 0 2>/dev/null
            grep -v "^panel_lpm$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null
            mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null
            log_soo "[OK] Panel LPM disabled"
          fi
        fi
        if [ "$SOO_RESTORE_ON_UNLOCK" = "1" ] && [ -f "$DISABLED_FILE" ]; then
          sleep 1
          if ! _is_locked; then
            log_soo "Unlocked - restoring"
            _restore_connections
            screen_was_off=0; conn_done=0; cache_done=0; off_since=0
            sleep 15; continue
          fi
          sleep 1; continue
        else
          rm -f "$DISABLED_FILE"
          screen_was_off=0; conn_done=0; cache_done=0; off_since=0
        fi
      fi
      sleep 15
      continue
    fi

    local now
    now=$(date +%s)

    if [ "$screen_was_off" = "0" ]; then
      screen_was_off=1
      off_since=$now
      conn_done=0; cache_done=0
      log_soo "Screen off - conn=${SOO_CONN_DELAY}m clean=${SOO_RAM_CLEAN_DELAY}m[${SOO_RAM_CLEAN_MODE}]"
    fi

    local elapsed=$(( now - off_since ))

    if [ "$conn_done" = "0" ] && \
       [ "$(( SOO_KILL_WIFI + SOO_KILL_BT + SOO_KILL_DATA + SOO_KILL_LOCATION + SOO_KILL_SENSORS + SOO_KILL_PANEL_LPM ))" -gt 0 ] && \
       [ "$elapsed" -ge "$(( SOO_CONN_DELAY * 60 ))" ]; then
      log_soo "Connections delay reached (${elapsed}s)"
      _disable_connections
      conn_done=1
    fi

    if [ "$SOO_RAM_CLEAN_MODE" != "off" ] && [ -n "$SOO_RAM_CLEAN_MODE" ] && \
       [ "$cache_done" = "0" ] && [ "$elapsed" -ge "$(( SOO_RAM_CLEAN_DELAY * 60 ))" ]; then
      log_soo "RAM clean delay reached (${elapsed}s) mode=$SOO_RAM_CLEAN_MODE"
      sh "$MODDIR/scripts/frosty.sh" ram_clean_silent "$SOO_RAM_CLEAN_MODE" &
      cache_done=1
    fi

    local all_done=1
    if [ "$(( SOO_KILL_WIFI + SOO_KILL_BT + SOO_KILL_DATA + SOO_KILL_LOCATION + SOO_KILL_SENSORS + SOO_KILL_PANEL_LPM ))" -gt 0 ] && [ "$conn_done" = "0" ]; then all_done=0; fi
    if [ "$SOO_RAM_CLEAN_MODE" != "off" ] && [ -n "$SOO_RAM_CLEAN_MODE" ] && [ "$cache_done" = "0" ]; then all_done=0; fi

    if [ "$all_done" = "1" ]; then
      sleep 5
    else
      sleep 3
    fi
  done
}

start() {
  stop
  echo "Frosty v${MODVER:-?} - Screen Off Optimization (START) - $(date '+%Y-%m-%d %H:%M:%S')" > "$SOO_LOG"
  [ "$ENABLE_SCREEN_OFF_OPT" != "1" ] && { log_soo "[SKIP] disabled"; return 0; }

  _monitor_loop &
  echo "$!" > "$PID_FILE"
  log_soo "[OK] PID=$(cat "$PID_FILE")"
  log_soo "wifi=$SOO_KILL_WIFI bt=$SOO_KILL_BT data=$SOO_KILL_DATA location=$SOO_KILL_LOCATION sensors=$SOO_KILL_SENSORS panel_lpm=$SOO_KILL_PANEL_LPM conn_delay=${SOO_CONN_DELAY}m"
  log_soo "ram_clean_mode=$SOO_RAM_CLEAN_MODE clean_delay=${SOO_RAM_CLEAN_DELAY}m"
  log_soo "restore_on_unlock=$SOO_RESTORE_ON_UNLOCK"
}

stop() {
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null && kill "$pid" 2>/dev/null && log_soo "[OK] Stopped PID $pid"
    rm -f "$PID_FILE"
  fi
  [ -f "$DISABLED_FILE" ] && { log_soo "Restoring on stop..."; _restore_connections; }
}

case "$1" in
  start) start ;;
  stop)  stop  ;;
  *) echo "Usage: $0 {start|stop}"; exit 1 ;;
esac
exit 0