#!/system/bin/sh
# Frosty - Screen Off Optimization daemon

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
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
# Migration from SOO_KILL_CACHE/SOO_CACHE_DELAY
[ "${SOO_KILL_CACHE:-0}" = "1" ] && [ "$SOO_RAM_CLEAN_MODE" = "off" ] && SOO_RAM_CLEAN_MODE=safe
: "${SOO_RAM_CLEAN_DELAY:=${SOO_CACHE_DELAY:-5}}"

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

_disable_connections() {
  rm -f "$DISABLED_FILE"

  if [ "$SOO_KILL_WIFI" = "1" ] && _wifi_is_on; then
    svc wifi disable 2>/dev/null
    echo "wifi" >> "$DISABLED_FILE"
    log_soo "[OK] Wi-Fi disabled"
  fi

  if [ "$SOO_KILL_BT" = "1" ] && _bt_is_on; then
    if _media_active; then
      log_soo "[SKIP] Bluetooth - media playback active"
    else
      svc bluetooth disable 2>/dev/null
      echo "bt" >> "$DISABLED_FILE"
      log_soo "[OK] Bluetooth disabled"
    fi
  fi

  if [ "$SOO_KILL_DATA" = "1" ] && _data_is_on; then
    if _is_tethering; then
      log_soo "[SKIP] Mobile data - tethering active"
    else
      svc data disable 2>/dev/null
      echo "data" >> "$DISABLED_FILE"
      log_soo "[OK] Mobile data disabled"
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
  rm -f "$DISABLED_FILE"
  [ -z "$_what" ] && return

  log_soo "Restoring: $(echo "$_what" | tr '\n' ' ')"

  {
    echo "$_what" | grep -q "^wifi$" && \
      svc wifi enable 2>/dev/null && log_soo "[OK] Wi-Fi restored"
  } &
  {
    echo "$_what" | grep -q "^bt$" && \
      svc bluetooth enable 2>/dev/null && log_soo "[OK] Bluetooth restored"
  } &
  {
    echo "$_what" | grep -q "^data$" && \
      svc data enable 2>/dev/null && log_soo "[OK] Mobile data restored"
  } &
  {
    local _loc
    _loc=$(echo "$_what" | grep "^location:" | cut -d: -f2)
    if [ -n "$_loc" ]; then
      settings put secure location_mode "$_loc" 2>/dev/null
      am broadcast -a android.location.MODE_CHANGED_ACTION \
        --ei android.location.extra.LOCATION_MODE "$_loc" \
        >/dev/null 2>&1
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
            grep -v "^sensors$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null && \
              mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null || true
          fi
          if grep -q "^panel_lpm$" "$DISABLED_FILE" 2>/dev/null; then
            settings put global display_panel_lpm 0 2>/dev/null
            grep -v "^panel_lpm$" "$DISABLED_FILE" > "${DISABLED_FILE}.tmp" 2>/dev/null && \
              mv -f "${DISABLED_FILE}.tmp" "$DISABLED_FILE" 2>/dev/null || true
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
      sh "$MODDIR/frosty.sh" ram_clean_silent "$SOO_RAM_CLEAN_MODE" &
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