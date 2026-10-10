#!/system/bin/sh
# Frosty - shared lock/screen monitor daemon helpers

_screen_asleep() {
  local _w
  _w=$(dumpsys power 2>/dev/null | grep -m1 "mWakefulness=" | cut -d= -f2 | tr -d ' ')
  case "$_w" in
    Asleep|Dozing|Dreaming) return 0 ;;
  esac
  return 1
}

_lockscreen_disabled() {
  case "${_LS_DISABLED:-}" in
    1) return 0 ;;
    0) return 1 ;;
  esac
  case "$(cmd lock_settings get-disabled --user 0 2>/dev/null)" in
    true|True|TRUE) _LS_DISABLED=1; return 0 ;;
  esac
  _LS_DISABLED=0
  return 1
}

_locked_without_keyguard() {
  _lockscreen_disabled && _screen_asleep
}

_is_locked() {
  local _trust
  _trust=$(dumpsys trust 2>/dev/null | grep -m1 "Keyguard showing")
  case "$_trust" in
    *true*)  return 0 ;;
    *false*) _locked_without_keyguard; return $? ;;
  esac

  local _wp
  _wp=$(dumpsys window policy 2>/dev/null | \
    grep -E "isKeyguardShowing=(true|false)|mShowingLockscreen=(true|false)" | head -1)
  case "$_wp" in
    *=true*)  return 0 ;;
    *=false*) _locked_without_keyguard; return $? ;;
  esac

  local _aa
  _aa=$(dumpsys activity activities 2>/dev/null | grep -m1 "mKeyguardShowing=")
  case "$_aa" in
    *mKeyguardShowing=true*)  return 0 ;;
    *mKeyguardShowing=false*) _locked_without_keyguard; return $? ;;
  esac

  _screen_asleep
}

_call_active() {
  local _mode
  _mode=$(dumpsys audio 2>/dev/null | grep -m1 "mMode=" | sed 's/.*mMode=//;s/[, ].*//')
  case "$_mode" in
    MODE_IN_CALL|MODE_IN_COMMUNICATION|MODE_RINGTONE)
      local _since_file="$MODDIR/tmp/call_since" _now _since
      _now=$(date +%s)
      if [ -f "$_since_file" ]; then
        _since=$(cat "$_since_file" 2>/dev/null)
        if [ -n "$_since" ] && [ $((_now - _since)) -gt 10800 ]; then
          return 1
        fi
      else
        echo "$_now" > "$_since_file"
      fi
      return 0
      ;;
  esac
  rm -f "$MODDIR/tmp/call_since" 2>/dev/null
  return 1
}

_sensors_restrict() {
  local _allow
  _allow=$(cmd telecom get-default-dialer 2>/dev/null)
  case "$_allow" in ''|null|*[!A-Za-z0-9_.]*) _allow="com.android.phone" ;; esac
  dumpsys sensorservice restrict "$_allow" >/dev/null 2>&1
}

_sensors_enable() {
  dumpsys sensorservice enable >/dev/null 2>&1
}

_logcat_is_stub() {
  case "$(head -c 2 "$(command -v logcat)" 2>/dev/null)" in '#!') return 0 ;; esac
  return 1
}

_init_event_pipe() {
  event_fd=0
  command -v mkfifo >/dev/null 2>&1 || return
  command -v logcat >/dev/null 2>&1 || return
  _logcat_is_stub && return
  rm -f "$EVENT_PIPE" 2>/dev/null
  mkfifo "$EVENT_PIPE" 2>/dev/null || return
  exec 3<>"$EVENT_PIPE" 2>/dev/null || { rm -f "$EVENT_PIPE"; return; }
  event_fd=1
}

_is_frosty_pid() {
  [ -n "$1" ] && tr '\0' ' ' 2>/dev/null < "/proc/$1/cmdline" | grep -qE '/Frosty/scripts/|screen_toggled'
}

_start_feed() {
  [ "$event_fd" = 1 ] || return
  [ -n "$feed_pid" ] && kill -0 "$feed_pid" 2>/dev/null && return
  logcat -b events -T 1 -s screen_toggled >&3 2>/dev/null &
  feed_pid=$!
  [ -n "$_MONITOR_PIDFILE" ] && echo "$feed_pid" > "${_MONITOR_PIDFILE}.feed" 2>/dev/null
}

_wait_event() {
  local _timeout="$1"
  local _line
  if [ "$event_fd" = 1 ]; then
    if [ -z "$feed_pid" ] || ! kill -0 "$feed_pid" 2>/dev/null; then
      feed_fails=$((feed_fails + 1))
      if [ "$feed_fails" -le 5 ]; then
        _start_feed
      else
        event_fd=0
      fi
    fi
  fi
  if [ "$event_fd" = 1 ] && [ -n "$feed_pid" ]; then
    read -r -t "$_timeout" _line <&3 2>/dev/null && feed_fails=0
    return 0
  fi
  sleep "$_timeout"
  return 0
}

_stop_monitor_daemon() {
  local _pidfile="$1" _lockdir="$2" _pipe="$3"
  local _feedfile="${_pidfile}.feed" _pid _i
  if [ -f "$_feedfile" ]; then
    _pid=$(cat "$_feedfile" 2>/dev/null)
    _is_frosty_pid "$_pid" && kill "$_pid" 2>/dev/null
    rm -f "$_feedfile"
  fi
  if [ -f "$_pidfile" ]; then
    _pid=$(cat "$_pidfile" 2>/dev/null)
    if _is_frosty_pid "$_pid"; then
      kill "$_pid" 2>/dev/null
      _i=0
      while [ "$_i" -lt 10 ] && kill -0 "$_pid" 2>/dev/null; do
        sleep 1
        _i=$((_i + 1))
      done
      kill -0 "$_pid" 2>/dev/null && kill -9 "$_pid" 2>/dev/null
    fi
    rm -f "$_pidfile"
  fi
  rm -f "$_pipe"
  rmdir "$_lockdir" 2>/dev/null
}