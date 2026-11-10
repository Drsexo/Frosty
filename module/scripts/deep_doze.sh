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
RESTRICTED_FILE="$MODDIR/tmp/deep_doze_restricted.txt"
APPLIED_FILE="$MODDIR/tmp/deep_doze_applied.txt"
MIGRATED_FILE="$MODDIR/tmp/deep_doze_lockcycle"
SETTINGS_BACKUP="$MODDIR/backup/deep_doze_settings.txt"

ENABLE_DEEP_DOZE=0
DEEP_DOZE_LEVEL="minimum"
DEEP_DOZE_ALWAYS=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

mkdir -p "$LOGDIR" "$MODDIR/tmp"
log_deep() { echo "[$(date '+%H:%M:%S')] $1" >> "$DEEP_DOZE_LOG"; }

. "$MODDIR/scripts/monitor_common.sh"
. "$MODDIR/scripts/core.sh"

ensure_whitelist() {
  if [ ! -s "$WHITELIST_FILE" ]; then
    {
      echo "# Frosty - Doze Whitelist"
      echo "# Apps listed here are excluded from Deep Doze restrictions."
      echo "# Add package names one per line. Lines starting with # are comments."
      echo ""
      echo "# Notification-critical"
      echo "com.google.android.gms"
      echo "com.google.android.gsf"
    } > "$WHITELIST_FILE"
    log_deep "Recreated whitelist with GMS and GSF defaults"
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

_ANDROID_EXEMPT=""

_in_set() { printf '%s\n' "$2" | grep -qxF "$1"; }

_load_android_exempt() {
  _ANDROID_EXEMPT=$(dumpsys deviceidle whitelist 2>/dev/null | grep -E '^(system-excidle|system|user),' | cut -d, -f2)
}

_wl_packages() {
  {
    [ -f "$WHITELIST_FILE" ] && sed 's/#.*//;s/[[:space:]]//g' "$WHITELIST_FILE"
    printf '%s\n' "$_DEF_DIALER" "$_DEF_SMS" "$_DEF_IME" "$_DEF_HOME"
  } | grep -v '^$' | sort -u | while read -r _w; do
    _valid_pkg "$_w" || continue
    case "$_w" in
      android|com.android.systemui|com.android.phone|com.android.settings|com.android.shell) continue ;;
    esac
    echo "$_w"
  done
}

_op_mode() {
  local _m
  _m=$(appops get "$1" "$2" 2>/dev/null | head -n 1 | sed -n 's/^[A-Z_]*: \([a-z_]*\).*/\1/p')
  echo "${_m:-default}"
}

_bucket_num() {
  case "$1" in
    exempted|EXEMPTED) echo 5 ;;
    active|ACTIVE) echo 10 ;;
    working_set|WORKING_SET) echo 20 ;;
    frequent|FREQUENT) echo 30 ;;
    rare|RARE) echo 40 ;;
    restricted|RESTRICTED) echo 45 ;;
    never|NEVER) echo 50 ;;
    ''|*[!0-9]*) echo "" ;;
    *) echo "$1" ;;
  esac
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
  [ -n "$_ANDROID_EXEMPT" ] && _in_set "$pkg" "$_ANDROID_EXEMPT" && return 0
  [ -f "$WHITELIST_FILE" ] && sed 's/#.*//;s/[[:space:]]//g' "$WHITELIST_FILE" | grep -qxF "$pkg" 2>/dev/null && return 0
  return 1
}

_backup_setting() {
  grep -q "^$1=" "$SETTINGS_BACKUP" 2>/dev/null && return
  mkdir -p "$MODDIR/backup"
  printf '%s=%s\n' "$1" "$(settings get global "$1" 2>/dev/null)" >> "$SETTINGS_BACKUP"
}

_restore_setting() {
  local _v
  _v=$(grep "^$1=" "$SETTINGS_BACKUP" 2>/dev/null | cut -d= -f2-)
  if [ -n "$_v" ] && [ "$_v" != "null" ]; then
    settings put global "$1" "$_v" >/dev/null 2>&1
  else
    settings delete global "$1" >/dev/null 2>&1
  fi
}

apply_doze_constants() {
  log_deep "Applying doze constants ($DEEP_DOZE_LEVEL)..."
  _backup_setting device_idle_constants
  _backup_setting app_standby_enabled
  _backup_setting adaptive_battery_management_enabled

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

  local _kv _key _val _chk
  for _kv in $(printf '%s' "$constants" | tr ',' ' '); do
    _key="${_kv%%=*}"
    _val="${_kv#*=}"
    _devcfg_backup device_idle "$_key"
    device_config put device_idle "$_key" "$_val" >/dev/null 2>&1
  done
  if command -v device_config >/dev/null 2>&1; then
    _chk="${constants#*,inactive_to=}"
    _chk="${_chk%%,*}"
    [ "$(device_config get device_idle inactive_to 2>/dev/null)" = "$_chk" ] || \
      log_deep "[WARN] device_idle flags did not stick (ignored or overridden by the ROM)"
  fi

  dumpsys deviceidle enable all 2>/dev/null
  settings put global app_standby_enabled 1 >/dev/null 2>&1
  settings put global adaptive_battery_management_enabled 1 >/dev/null 2>&1
}

revert_doze_constants() {
  _restore_setting device_idle_constants
  dumpsys deviceidle enable 2>/dev/null
  _restore_setting app_standby_enabled
  _restore_setting adaptive_battery_management_enabled
  rm -f "$SETTINGS_BACKUP"

  local _key
  for _key in light_after_inactive_to light_pre_idle_to light_idle_to light_max_idle_to \
              inactive_to sensing_to motion_inactive_to idle_after_inactive_to \
              idle_to max_idle_to quick_doze_delay_to; do
    _devcfg_restore device_idle "$_key"
  done
}

_supports_restricted_bucket() {
  local _sdk
  _sdk=$(getprop ro.build.version.sdk 2>/dev/null); _sdk="${_sdk%%[!0-9]*}"
  [ -n "$_sdk" ] && [ "$_sdk" -ge 30 ] 2>/dev/null
}

_restrict_pkg() {
  local pkg="$1"
  case "$pkg" in
    android|com.android.systemui|com.android.phone|com.android.settings|com.android.shell)
      return 0 ;;
  esac
  local _has_restricted=1
  _supports_restricted_bucket || _has_restricted=0
  case "$DEEP_DOZE_LEVEL" in
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
}

_unrestrict_pkg() {
  local pkg="$1" bucket="$2"
  appops set "$pkg" WAKE_LOCK default 2>/dev/null
  am set-standby-bucket "$pkg" "${bucket:-active}" 2>/dev/null
  am set-inactive "$pkg" false 2>/dev/null
}

_record_restricted() {
  awk -v p="$1" '$1==p{f=1} END{exit !f}' "$RESTRICTED_FILE" 2>/dev/null && return 0
  printf '%s %s\n' "$1" "$2" >> "$RESTRICTED_FILE"
}

_applied_bucket() {
  case "$DEEP_DOZE_LEVEL" in
    maximum) _supports_restricted_bucket && echo restricted || echo rare ;;
    minimum) echo frequent ;;
    *) echo rare ;;
  esac
}

_record_applied() {
  awk -v p="$1" '$1==p{f=1} END{exit !f}' "$APPLIED_FILE" 2>/dev/null && return 0
  printf '%s %s %s\n' "$1" "$2" "$3" >> "$APPLIED_FILE"
}

_restore_pkg() {
  local pkg="$1" bucket="$2" rec abucket owl cur
  rec=$(awk -v p="$pkg" '$1==p{print; exit}' "$APPLIED_FILE" 2>/dev/null)
  if [ -z "$rec" ]; then
    _unrestrict_pkg "$pkg" "$bucket"
    return
  fi
  abucket=$(echo "$rec" | cut -d' ' -f2)
  owl=$(echo "$rec" | cut -d' ' -f3)
  cur=$(_bucket_num "$(am get-standby-bucket "$pkg" 2>/dev/null | tail -1 | tr -d '[:space:]')")
  if [ -z "$cur" ] || [ "$cur" = "$(_bucket_num "$abucket")" ]; then
    am set-standby-bucket "$pkg" "${bucket:-active}" 2>/dev/null
  else
    log_deep "[SKIP] $pkg bucket changed since Frosty set it, left as is"
  fi
  if [ -n "$owl" ] && [ "$(_op_mode "$pkg" WAKE_LOCK)" = "deny" ]; then
    case "$owl" in
      allow|ignore|deny|foreground|errored) appops set "$pkg" WAKE_LOCK "$owl" 2>/dev/null ;;
      *) appops set "$pkg" WAKE_LOCK default 2>/dev/null ;;
    esac
  fi
}

_clean_pkg() {
  local pkg="$1" mode bucket changed=1
  mode=$(_op_mode "$pkg" WAKE_LOCK)
  case "$mode" in
    default|allow) ;;
    *)
      appops set "$pkg" WAKE_LOCK default 2>/dev/null
      log_deep "[OK] $pkg: WAKE_LOCK was $mode, reset to default"
      changed=0
      ;;
  esac
  bucket=$(_bucket_num "$(am get-standby-bucket "$pkg" 2>/dev/null | tail -1 | tr -d '[:space:]')")
  case "$bucket" in
    45|50)
      am set-standby-bucket "$pkg" active 2>/dev/null
      log_deep "[OK] $pkg: standby bucket $bucket reset to active"
      changed=0
      ;;
  esac
  case "$(am get-inactive "$pkg" 2>/dev/null)" in
    *Idle=true*)
      am set-inactive "$pkg" false 2>/dev/null
      log_deep "[OK] $pkg: inactive state cleared"
      changed=0
      ;;
  esac
  return $changed
}

clean_whitelisted_apps() {
  local _installed _p _n=0
  _refresh_defaults
  _installed=$(pm list packages 2>/dev/null | sed 's/^package://')
  for _p in $(_wl_packages); do
    _in_set "$_p" "$_installed" || continue
    _clean_pkg "$_p" && _n=$((_n + 1))
  done
  log_deep "[OK] Whitelisted apps checked ($_n had leftover restrictions)"
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
  _load_android_exempt
  local _abucket
  _abucket=$(_applied_bucket)

  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue

    local cur
    cur=$(am get-standby-bucket "$pkg" 2>/dev/null | tail -1 | tr -d '[:space:]')
    case "$cur" in
      10|20|active|ACTIVE|working_set|WORKING_SET) skip=$((skip + 1)); continue ;;
    esac
    case "$cur" in *[!A-Za-z0-9_]*) cur="" ;; esac

    local _owl=""
    [ "$DEEP_DOZE_LEVEL" = "maximum" ] && _owl=$(_op_mode "$pkg" WAKE_LOCK)
    _restrict_pkg "$pkg"
    _record_restricted "$pkg" "$cur"
    _record_applied "$pkg" "$_abucket" "$_owl"
    count=$((count + 1))
  done
  case "$level" in
    maximum) log_deep "[OK] Restricted $count apps to $([ "$_has_restricted" = "1" ] && echo restricted || echo rare) bucket (skipped $skip active/recent)" ;;
    minimum) log_deep "[OK] Restricted $count apps to frequent bucket (skipped $skip active/recent)" ;;
    *)       log_deep "[OK] Restricted $count apps to rare bucket (skipped $skip active/recent)" ;;
  esac
}

unrestrict_manifest() {
  [ -f "$RESTRICTED_FILE" ] || return 0
  local count=0 pkg bucket _list
  _list=$(awk '!seen[$1]++' "$RESTRICTED_FILE")
  while read -r pkg bucket; do
    [ -n "$pkg" ] || continue
    _restore_pkg "$pkg" "$bucket"
    count=$((count + 1))
  done <<EOF
$_list
EOF
  rm -f "$RESTRICTED_FILE" "$APPLIED_FILE"
  log_deep "[OK] Unrestricted $count apps"
}

unrestrict_apps() {
  local count=0 pkg
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    appops set "$pkg" RUN_ANY_IN_BACKGROUND default 2>/dev/null
    _unrestrict_pkg "$pkg"
    count=$((count + 1))
  done
  log_deep "[OK] Unrestricted $count apps"
}

_is_protected_wakelock_tag() {
  local _tag
  _tag=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$_tag" in
    *alarm*|*notification*|*fcm*|*push*|*syncmanager*|*networkstack*)
      return 0 ;;
  esac
  return 1
}

kill_wakelocks() {
  local killed=0 _uidmap _killed_pkgs=""
  local tmpfile="$MODDIR/tmp/wakelocks.txt"
  local procfile="$MODDIR/tmp/processes.txt"
  dumpsys power 2>/dev/null | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" > "$tmpfile"
  dumpsys activity processes 2>/dev/null > "$procfile"
  _uidmap=$(pm list packages -U -3 2>/dev/null | sed -n 's/^package:\([^ ]*\) uid:\([0-9]*\).*/\2 \1/p')

  _refresh_defaults
  _load_android_exempt

  while IFS= read -r line; do
    local tag
    tag=$(printf '%s' "$line" | sed -n "s/^[^']*'\([^']*\)'.*/\1/p")
    [ -n "$tag" ] && _is_protected_wakelock_tag "$tag" && continue

    local pkg uid
    pkg=$(printf '%s' "$line" | grep -o "ws=WorkSource{[^}]*}" | \
          grep -oE "[a-z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+" | head -1)
    if [ -z "$pkg" ]; then
      uid=$(printf '%s' "$line" | sed -n 's/.*(uid=\([0-9]*\).*/\1/p')
      [ -n "$uid" ] && pkg=$(printf '%s\n' "$_uidmap" | awk -v u="$uid" '$1==u{print $2; exit}')
    fi
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    case "$_killed_pkgs" in *" $pkg "*) continue ;; esac

    local proc_state
    proc_state=$(awk -v p="$pkg" 'index($0, "packageList=") && index($0, p) { c = 6 } c > 0 { print; c-- }' "$procfile" | grep -oE "procState=[A-Z_]+" | head -1 | cut -d= -f2)
    case "$proc_state" in
      TOP|BOUND_TOP|BOUND_FG_SERVICE|FG_SERVICE) continue ;;
    esac

    am kill "$pkg" 2>/dev/null && { killed=$((killed + 1)); _killed_pkgs="$_killed_pkgs $pkg "; }
  done < "$tmpfile"
  rm -f "$tmpfile" "$procfile"
  log_deep "[OK] Killed $killed wakelock holders"
}

_apply_sensor_state() {
  if ! _screen_asleep || _call_active; then
    if [ "$_sensor_state" != "enabled" ]; then
      _sensors_enable
      _sensor_state="enabled"
      log_deep "[OK] Sensor access restored"
    fi
  else
    if [ "$_sensor_state" != "restricted" ]; then
      _sensors_restrict
      _sensor_state="restricted"
      log_deep "[OK] Sensor access restricted"
    fi
  fi
}

_wait_while_locked() {
  local _remain="$1" _sensor_aware="$2"
  local _deadline _chunk _now
  _deadline=$(( $(date +%s) + _remain ))
  [ "$_sensor_aware" = "1" ] && _apply_sensor_state
  while true; do
    _now=$(date +%s)
    _remain=$(( _deadline - _now ))
    [ "$_remain" -le 0 ] && return 1
    _chunk=15
    [ "$_chunk" -gt "$_remain" ] && _chunk="$_remain"
    _wait_event "$_chunk"
    [ "$_sensor_aware" = "1" ] && _apply_sensor_state
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
  local _mon_always="$DEEP_DOZE_ALWAYS"
  (
    trap 'kill -0 "$feed_pid" 2>/dev/null && kill "$feed_pid" 2>/dev/null; rm -f "$EVENT_PIPE"; rmdir "$MONITOR_LOCKDIR" 2>/dev/null; exit 0' TERM INT

    _MONITOR_PIDFILE="$MONITOR_PID_FILE"
    event_fd=0
    feed_pid=""
    feed_fails=0
    _init_event_pipe
    _start_feed
    _sensors_enable
    _sensor_state="enabled"

    local _idle_wait=90
    while true; do
      if ! _is_locked; then
        [ "$_mon_always" = "1" ] && _stepdeep
        _wait_event "$_idle_wait"
        if [ "$event_fd" != "1" ]; then
          [ "$_idle_wait" -lt 180 ] && _idle_wait=$((_idle_wait + 30))
        else
          _idle_wait=90
        fi
        continue
      fi
      _idle_wait=90

      log_deep "Locked - wakelock killer armed (5min)"
      local _sensor_aware=0
      [ "$_mon_level" = "maximum" ] && _sensor_aware=1

      if _wait_while_locked 300 "$_sensor_aware"; then
        log_deep "Unlocked before wakelock killer fired"
      else
        log_deep "Running wakelock killer..."
        kill_wakelocks
        restrict_apps "$_mon_level"
        _stepdeep
        [ "$_sensor_aware" = "1" ] && _apply_sensor_state
        while _is_locked; do
          _wait_event 15
          [ "$_sensor_aware" = "1" ] && _apply_sensor_state
        done
      fi
      if [ "$_mon_always" != "1" ]; then
        dumpsys deviceidle unforce 2>/dev/null
        unrestrict_manifest
      fi

      if [ "$_sensor_aware" = "1" ] && [ "$_sensor_state" != "enabled" ]; then
        _sensors_enable
        _sensor_state="enabled"
        log_deep "[OK] Sensor access restored"
      fi
      log_deep "Unlocked - monitor re-armed"
    done
  ) >/dev/null 2>&1 </dev/null &
  echo $! > "$MONITOR_PID_FILE"
  log_deep "[OK] Screen monitor started (PID $!)"
}

stop_screen_monitor() {
  _stop_monitor_daemon "$MONITOR_PID_FILE" "$MONITOR_LOCKDIR" "$EVENT_PIPE"
  _sensors_enable
}

_stepdeep() {
  if ! dumpsys deviceidle force-idle deep 2>/dev/null; then
    for _i in 1 2 3 4; do cmd deviceidle step deep 2>/dev/null; done
  fi
}

_jobsched_flex() {
  local _sdk
  _sdk=$(getprop ro.build.version.sdk 2>/dev/null); _sdk="${_sdk%%[!0-9]*}"
  [ -n "$_sdk" ] && [ "$_sdk" -ge 33 ] 2>/dev/null || return 0
  cmd jobscheduler help 2>/dev/null | grep -q 'flex-policy' || return 0
  case "$1" in
    freeze) cmd jobscheduler enable-flex-policy --option idle 2>/dev/null ;;
    stock)  cmd jobscheduler reset-flex-policy 2>/dev/null ;;
  esac
  return 0
}

freeze_deep_doze() {
  echo "Frosty v${MODVER:-?} - Deep Doze (FREEZE) - $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  [ "$ENABLE_DEEP_DOZE" != "1" ] && return 0

  local _legacy=0
  if [ ! -f "$MIGRATED_FILE" ]; then
    { [ -s "$RESTRICTED_FILE" ] || [ -f "$SETTINGS_BACKUP" ] || [ -f "$MODDIR/tmp/deep_doze_allow.txt" ]; } && _legacy=1
  fi

  ensure_whitelist
  unrestrict_manifest
  if [ ! -f "$MIGRATED_FILE" ]; then
    [ "$_legacy" = "1" ] && unrestrict_apps
    : > "$MIGRATED_FILE"
  fi
  apply_doze_constants
  clean_whitelisted_apps
  [ "$DEEP_DOZE_LEVEL" = "minimum" ] && restrict_apps "$DEEP_DOZE_LEVEL"

  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    kill_wakelocks
  fi
  if [ "$DEEP_DOZE_LEVEL" = "minimum" ]; then
    stop_screen_monitor
    dumpsys deviceidle unforce 2>/dev/null
  else
    start_screen_monitor
    if [ "$DEEP_DOZE_ALWAYS" = "1" ] || _is_locked; then
      _stepdeep
    fi
  fi
  _jobsched_flex freeze
}

stock_deep_doze() {
  echo "Frosty v${MODVER:-?} - Deep Doze (STOCK) - $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  local _legacy=0
  if [ ! -f "$MIGRATED_FILE" ]; then
    { [ -s "$RESTRICTED_FILE" ] || [ -f "$SETTINGS_BACKUP" ] || [ -f "$MODDIR/tmp/deep_doze_allow.txt" ]; } && _legacy=1
  fi
  revert_doze_constants
  unrestrict_manifest
  [ "$_legacy" = "1" ] && unrestrict_apps
  stop_screen_monitor
  dumpsys deviceidle unforce 2>/dev/null
  _jobsched_flex stock
}

case "$1" in
  freeze) freeze_deep_doze ;;
  stock)  stock_deep_doze ;;
  restrict_pkg)
    if [ -n "$2" ]; then
      if [ "$DEEP_DOZE_LEVEL" = "minimum" ] || [ "$DEEP_DOZE_ALWAYS" = "1" ]; then
        _refresh_defaults
        _prev=$(am get-standby-bucket "$2" 2>/dev/null | tail -1 | tr -d '[:space:]')
        case "$_prev" in *[!A-Za-z0-9_]*) _prev="" ;; esac
        _restrict_pkg "$2"
        _record_restricted "$2" "$_prev"
        log_deep "[OK] $2 restricted (removed from whitelist)"
      else
        log_deep "[OK] $2 removed from whitelist, restricted on the next lock cycle"
      fi
    fi
    ;;
  unrestrict_pkg)
    [ -n "$2" ] && { _unrestrict_pkg "$2"; _clean_pkg "$2"; log_deep "[OK] $2 unrestricted (added to whitelist)"; }
    ;;
esac
exit $?