#!/system/bin/sh
# Frosty - shared lock/screen monitor daemon helpers

_is_locked() {
  local _trust
  _trust=$(dumpsys trust 2>/dev/null | grep -m1 "Keyguard showing")
  case "$_trust" in
    *true*)  return 0 ;;
    *false*) return 1 ;;
  esac

  local _wp
  _wp=$(dumpsys window policy 2>/dev/null | \
    grep -E "isKeyguardShowing=(true|false)|mShowingLockscreen=(true|false)" | head -1)
  case "$_wp" in
    *=true*)  return 0 ;;
    *=false*) return 1 ;;
  esac

  local _aa
  _aa=$(dumpsys activity activities 2>/dev/null | grep -m1 "mKeyguardShowing=")
  case "$_aa" in
    *mKeyguardShowing=true*)  return 0 ;;
    *mKeyguardShowing=false*) return 1 ;;
  esac

  local _w
  _w=$(dumpsys power 2>/dev/null | grep -m1 "mWakefulness=" | cut -d= -f2 | tr -d ' ')
  case "$_w" in
    Asleep|Dozing|Dreaming) return 0 ;;
    *) return 1 ;;
  esac
}

_init_event_pipe() {
  event_fd=0
  command -v mkfifo >/dev/null 2>&1 || return
  command -v logcat >/dev/null 2>&1 || return
  rm -f "$EVENT_PIPE" 2>/dev/null
  mkfifo "$EVENT_PIPE" 2>/dev/null || return
  exec 3<>"$EVENT_PIPE" 2>/dev/null || { rm -f "$EVENT_PIPE"; return; }
  event_fd=1
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
    read -r -t "$_timeout" _line <&3 2>/dev/null
    return 0
  fi
  sleep "$_timeout"
  return 0
}

_stop_monitor_daemon() {
  local _pidfile="$1" _lockdir="$2" _pipe="$3"
  local _feedfile="${_pidfile}.feed"
  if [ -f "$_feedfile" ]; then
    local _fpid
    _fpid=$(cat "$_feedfile" 2>/dev/null)
    [ -n "$_fpid" ] && kill "$_fpid" 2>/dev/null
    rm -f "$_feedfile"
  fi
  if [ -f "$_pidfile" ]; then
    local _pid _i
    _pid=$(cat "$_pidfile" 2>/dev/null)
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
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