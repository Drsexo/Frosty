#!/system/bin/sh
# Frosty - Deep Doze

_d="${0%/*}"
[ -z "$_d" ] && _d="/data/adb/modules/Frosty/scripts"
MODDIR="${_d%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
unset _d
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
DEEP_DOZE_LOG="$LOGDIR/deep_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
WHITELIST_FILE="$MODDIR/config/doze_whitelist.txt"
MONITOR_PID_FILE="$MODDIR/tmp/screen_monitor.pid"
MONITOR_LOCKDIR="$MODDIR/tmp/screen_monitor.lock"
EVENT_PIPE="$MODDIR/tmp/deep_doze_events.fifo"

ENABLE_DEEP_DOZE=0
DEEP_DOZE_LEVEL="moderate"
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

mkdir -p "$LOGDIR" "$MODDIR/tmp"
log_deep() { echo "[$(date '+%H:%M:%S')] $1" >> "$DEEP_DOZE_LOG"; }

. "$MODDIR/scripts/monitor_common.sh"

ensure_whitelist() {
  if [ ! -f "$WHITELIST_FILE" ]; then
    echo "# Frosty - Doze Whitelist" > "$WHITELIST_FILE"
    echo "# Apps listed here are excluded from Deep Doze restrictions." >> "$WHITELIST_FILE"
    echo "# Add package names one per line. Lines starting with # are comments." >> "$WHITELIST_FILE"
    echo "" >> "$WHITELIST_FILE"
    log_deep "Created empty whitelist"
  fi
}

_DEF_DIALER=""
_DEF_SMS=""
_DEF_IME=""
_DEF_HOME=""

_refresh_defaults() {
  _DEF_DIALER=$(cmd telecom get-default-dialer 2>/dev/null)
  [ "$_DEF_DIALER" = "null" ] && _DEF_DIALER=""
  _DEF_SMS=$(settings get secure sms_default_application 2>/dev/null)
  [ "$_DEF_SMS" = "null" ] && _DEF_SMS=""
  _DEF_IME=$(settings get secure default_input_method 2>/dev/null | sed 's#/.*##')
  [ "$_DEF_IME" = "null" ] && _DEF_IME=""
  _DEF_HOME=$(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>/dev/null | grep / | tail -1 | sed 's#/.*##')
}

is_whitelisted() {
  local pkg="$1"
  case "$pkg" in
    android|com.android.systemui|com.android.phone|com.android.settings|com.android.shell)
      return 0 ;;
  esac
  [ -n "$_DEF_DIALER" ] && [ "$pkg" = "$_DEF_DIALER" ] && return 0
  [ -n "$_DEF_SMS" ] && [ "$pkg" = "$_DEF_SMS" ] && return 0
  [ -n "$_DEF_IME" ] && [ "$pkg" = "$_DEF_IME" ] && return 0
  [ -n "$_DEF_HOME" ] && [ "$pkg" = "$_DEF_HOME" ] && return 0
  [ -f "$WHITELIST_FILE" ] && sed 's/#.*//;s/[[:space:]]//g' "$WHITELIST_FILE" | grep -qx "$pkg" 2>/dev/null && return 0
  return 1
}

apply_doze_constants() {
  log_deep "Applying doze constants ($DEEP_DOZE_LEVEL)..."

  case "$DEEP_DOZE_LEVEL" in
    maximum)
      local constants="light_after_inactive_to=0,light_pre_idle_to=5000,light_idle_to=3600000,light_max_idle_to=43200000,inactive_to=0,sensing_to=0,motion_inactive_to=0,idle_after_inactive_to=0,idle_to=21600000,max_idle_to=172800000,quick_doze_delay_to=5000"
      ;;
    minimum)
      local constants="light_after_inactive_to=600000,light_pre_idle_to=600000,light_idle_to=300000,light_max_idle_to=900000,inactive_to=1800000,sensing_to=0,motion_inactive_to=0,idle_after_inactive_to=0,idle_to=1200000,max_idle_to=3600000,quick_doze_delay_to=600000"
      ;;
    *)
      local constants="light_after_inactive_to=300000,light_pre_idle_to=300000,light_idle_to=900000,light_max_idle_to=1800000,inactive_to=1800000,sensing_to=0,motion_inactive_to=0,idle_after_inactive_to=0,idle_to=3600000,max_idle_to=7200000,quick_doze_delay_to=300000"
      ;;
  esac

  settings put global device_idle_constants "$constants" >/dev/null 2>&1
  dumpsys deviceidle enable all 2>/dev/null
  settings put global app_standby_enabled 1 >/dev/null 2>&1
  settings put global adaptive_battery_management_enabled 1 >/dev/null 2>&1
}

revert_doze_constants() {
  settings delete global device_idle_constants >/dev/null 2>&1
  dumpsys deviceidle enable 2>/dev/null
  settings delete global app_standby_enabled >/dev/null 2>&1
  settings delete global adaptive_battery_management_enabled >/dev/null 2>&1
}

_supports_restricted_bucket() {
  local _sdk
  _sdk=$(getprop ro.build.version.sdk 2>/dev/null); _sdk="${_sdk%%[!0-9]*}"
  [ -n "$_sdk" ] && [ "$_sdk" -ge 30 ] 2>/dev/null
}

restrict_apps() {
  local level="$1"
  log_deep "Restricting apps ($level)..."
  local count=0 skip=0
  local _has_restricted=1
  _supports_restricted_bucket || _has_restricted=0
  if [ "$level" = "maximum" ] && [ "$_has_restricted" = "0" ]; then
    log_deep "[WARN] restricted standby bucket needs Android 11+ (API 30) - using rare bucket instead"
  fi

  _refresh_defaults

  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue

    local cur
    cur=$(am get-standby-bucket "$pkg" 2>/dev/null | tail -1 | tr -d '[:space:]')
    case "$cur" in
      10|20|active|ACTIVE|working_set|WORKING_SET) skip=$((skip + 1)); continue ;;
    esac

    case "$level" in
      maximum)
        if [ "$_has_restricted" = "1" ]; then
          am set-standby-bucket "$pkg" restricted 2>/dev/null
        else
          am set-standby-bucket "$pkg" rare 2>/dev/null
        fi
        appops set "$pkg" WAKE_LOCK deny 2>/dev/null
        ;;
      minimum)
        am set-standby-bucket "$pkg" frequent 2>/dev/null
        ;;
      *)
        am set-standby-bucket "$pkg" rare 2>/dev/null
        ;;
    esac

    count=$((count + 1))
  done
  case "$level" in
    maximum) log_deep "[OK] Restricted $count apps to $([ "$_has_restricted" = "1" ] && echo restricted || echo rare) bucket (skipped $skip active/recent)" ;;
    minimum) log_deep "[OK] Restricted $count apps to frequent bucket (skipped $skip active/recent)" ;;
    *)       log_deep "[OK] Restricted $count apps to rare bucket (skipped $skip active/recent)" ;;
  esac
}

unrestrict_apps() {
  local count=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    appops set "$pkg" WAKE_LOCK allow 2>/dev/null
    appops set "$pkg" RUN_ANY_IN_BACKGROUND default 2>/dev/null
    am set-standby-bucket "$pkg" active 2>/dev/null
    am set-inactive "$pkg" false 2>/dev/null
    count=$((count + 1))
  done
  log_deep "[OK] Unrestricted $count apps"
}

_is_protected_wakelock_tag() {
  case "$1" in
    *[Aa]larm*|*[Nn]otification*|*Fcm*|*FCM*|*[Pp]ush*|*SyncManager*|*NetworkStack*)
      return 0 ;;
  esac
  return 1
}

kill_wakelocks() {
  local killed=0
  local tmpfile="$MODDIR/tmp/wakelocks.txt"
  local procfile="$MODDIR/tmp/processes.txt"
  dumpsys power 2>/dev/null | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" > "$tmpfile"
  dumpsys activity processes 2>/dev/null > "$procfile"

  _refresh_defaults

  while IFS= read -r line; do
    local tag
    tag=$(echo "$line" | grep -oE '"[^"]*"' | head -1 | tr -d '"')
    [ -n "$tag" ] && _is_protected_wakelock_tag "$tag" && continue

    local pkg
    pkg=$(echo "$line" | grep -o "ws=WorkSource{[^}]*}" | \
          grep -oE "[a-z][a-zA-Z0-9_.]+\.[a-zA-Z0-9_.]+" | head -1)
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue

    local proc_state
    proc_state=$(grep -A5 "packageList=.*$pkg" "$procfile" | grep -oE "procState=[A-Z_]+" | head -1 | cut -d= -f2)
    case "$proc_state" in
      TOP|BOUND_TOP|BOUND_FG_SERVICE|FG_SERVICE) continue ;;
    esac

    am kill "$pkg" 2>/dev/null && killed=$((killed + 1))
  done < "$tmpfile"
  rm -f "$tmpfile" "$procfile"
  log_deep "[OK] Killed $killed wakelock holders"
}

_wait_while_locked() {
  local _remain="$1"
  local _deadline _chunk _now
  _deadline=$(( $(date +%s) + _remain ))
  while true; do
    _now=$(date +%s)
    _remain=$(( _deadline - _now ))
    [ "$_remain" -le 0 ] && return 1
    _chunk=15
    [ "$_chunk" -gt "$_remain" ] && _chunk="$_remain"
    _wait_event "$_chunk"
    _is_locked || return 0
  done
}

start_screen_monitor() {
  stop_screen_monitor
  if ! mkdir "$MONITOR_LOCKDIR" 2>/dev/null; then
    log_deep "[WARN] Monitor lock busy, skipping start"
    return
  fi
  local _mon_level="$DEEP_DOZE_LEVEL"
  (
    trap 'kill -0 "$feed_pid" 2>/dev/null && kill "$feed_pid" 2>/dev/null; rm -f "$EVENT_PIPE"; rmdir "$MONITOR_LOCKDIR" 2>/dev/null; exit 0' TERM INT

    _MONITOR_PIDFILE="$MONITOR_PID_FILE"
    event_fd=0
    feed_pid=""
    feed_fails=0
    _init_event_pipe
    _start_feed

    local _idle_wait=90
    while true; do
      if ! _is_locked; then
        _wait_event "$_idle_wait"
        if [ "$event_fd" != "1" ]; then
          [ "$_idle_wait" -lt 180 ] && _idle_wait=$((_idle_wait + 30))
        else
          _idle_wait=90
        fi
        continue
      fi
      _idle_wait=90

      if [ "$_mon_level" = "minimum" ]; then
        log_deep "Locked - no wakelock killer at minimum level"
        while _is_locked; do
          _wait_event 15
        done
        log_deep "Unlocked - monitor re-armed"
        continue
      fi

      log_deep "Locked - wakelock killer armed (5min)"
      if [ "$_mon_level" = "maximum" ]; then
        dumpsys sensorservice disable 2>/dev/null
        log_deep "[OK] Sensor service disabled"
      fi

      if _wait_while_locked 300; then
        log_deep "Unlocked before wakelock killer fired"
      else
        log_deep "Running wakelock killer..."
        kill_wakelocks
        _stepdeep
        while _is_locked; do
          _wait_event 15
        done
      fi

      if [ "$_mon_level" = "maximum" ]; then
        dumpsys sensorservice enable 2>/dev/null
        log_deep "[OK] Sensor service re-enabled"
      fi
      log_deep "Unlocked - monitor re-armed"
    done
  ) &
  echo $! > "$MONITOR_PID_FILE"
  log_deep "[OK] Screen monitor started (PID $!)"
}

stop_screen_monitor() {
  _stop_monitor_daemon "$MONITOR_PID_FILE" "$MONITOR_LOCKDIR" "$EVENT_PIPE"
  dumpsys sensorservice enable 2>/dev/null
}

_stepdeep() {
  if ! dumpsys deviceidle force-idle deep 2>/dev/null; then
    for _i in 1 2 3 4; do cmd deviceidle step deep 2>/dev/null; done
  fi
}

_jobsched_flex() {
  local _sdk
  _sdk=$(getprop ro.build.version.sdk 2>/dev/null); _sdk="${_sdk%%[!0-9]*}"
  [ -n "$_sdk" ] && [ "$_sdk" -ge 33 ] 2>/dev/null || return
  case "$1" in
    freeze) cmd jobscheduler enable-flex-policy --option idle 2>/dev/null ;;
    stock)  cmd jobscheduler reset-flex-policy 2>/dev/null ;;
  esac
}

freeze_deep_doze() {
  echo "Frosty v${MODVER:-?} - Deep Doze (FREEZE) - $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  [ "$ENABLE_DEEP_DOZE" != "1" ] && return 0

  ensure_whitelist
  apply_doze_constants
  restrict_apps "$DEEP_DOZE_LEVEL"

  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    kill_wakelocks
  fi
  start_screen_monitor
  _is_locked && _stepdeep
  _jobsched_flex freeze
}

stock_deep_doze() {
  echo "Frosty v${MODVER:-?} - Deep Doze (STOCK) - $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  revert_doze_constants
  unrestrict_apps
  stop_screen_monitor
  dumpsys deviceidle unforce 2>/dev/null
  _jobsched_flex stock
}

case "$1" in
  freeze) freeze_deep_doze ;;
  stock)  stock_deep_doze ;;
esac
exit 0