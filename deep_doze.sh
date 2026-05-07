#!/system/bin/sh
# Frosty - Deep Doze

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
DEEP_DOZE_LOG="$LOGDIR/deep_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
WHITELIST_FILE="$MODDIR/config/doze_whitelist.txt"
MONITOR_PID_FILE="$MODDIR/tmp/screen_monitor.pid"

ENABLE_DEEP_DOZE=0
DEEP_DOZE_LEVEL="moderate"
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

mkdir -p "$LOGDIR" "$MODDIR/tmp"
log_deep() { echo "[$(date '+%H:%M:%S')] $1" >> "$DEEP_DOZE_LOG"; }

ensure_whitelist() {
  if [ ! -f "$WHITELIST_FILE" ]; then
    echo "# Frosty - Doze Whitelist" > "$WHITELIST_FILE"
    echo "# Apps listed here are excluded from Deep Doze restrictions." >> "$WHITELIST_FILE"
    echo "# Add package names one per line. Lines starting with # are comments." >> "$WHITELIST_FILE"
    echo "" >> "$WHITELIST_FILE"
    log_deep "Created empty whitelist"
  fi
}

is_whitelisted() {
  local pkg="$1"
  case "$pkg" in
    android|com.android.systemui|com.android.phone|com.android.settings|com.android.shell)
      return 0 ;;
  esac
  [ -f "$WHITELIST_FILE" ] && sed 's/#.*//;s/[[:space:]]//g' "$WHITELIST_FILE" | grep -qx "$pkg" 2>/dev/null && return 0
  return 1
}

apply_doze_constants() {
  log_deep "Applying doze constants ($DEEP_DOZE_LEVEL)..."

  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    local constants="light_after_inactive_to=0,light_pre_idle_to=5000,light_idle_to=3600000,light_max_idle_to=43200000,inactive_to=0,sensing_to=0,motion_inactive_to=0,idle_after_inactive_to=0,idle_to=21600000,max_idle_to=172800000,quick_doze_delay_to=5000"
  else
    local constants="light_after_inactive_to=300000,light_pre_idle_to=300000,light_idle_to=900000,light_max_idle_to=1800000,inactive_to=1800000,sensing_to=0,motion_inactive_to=0,idle_after_inactive_to=0,idle_to=3600000,max_idle_to=7200000,quick_doze_delay_to=300000"
  fi

  settings put global device_idle_constants "$constants" 2>/dev/null
  dumpsys deviceidle enable all 2>/dev/null
  settings put global app_standby_enabled 1 2>/dev/null
  settings put global adaptive_battery_management_enabled 1 2>/dev/null
}

revert_doze_constants() {
  settings delete global device_idle_constants 2>/dev/null
  dumpsys deviceidle enable 2>/dev/null
  settings delete global app_standby_enabled 2>/dev/null
  settings delete global adaptive_battery_management_enabled 2>/dev/null
}

restrict_apps() {
  local level="$1"
  log_deep "Restricting apps ($level)..."
  local count=0 skip=0

  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue

    # Skip apps currently in the foreground
    local cur
    cur=$(am get-standby-bucket "$pkg" 2>/dev/null | tail -1 | tr -d '[:space:]')
    case "$cur" in
      5|active|ACTIVE) skip=$((skip + 1)); continue ;;
    esac

    # rare bucket: Android significantly throttles background jobs, alarms, and network access.
    am set-standby-bucket "$pkg" rare 2>/dev/null

    # maximum only: also deny wakelocks so apps cannot prevent deep sleep
    [ "$level" = "maximum" ] && appops set "$pkg" WAKE_LOCK deny 2>/dev/null

    count=$((count + 1))
  done
  log_deep "[OK] Restricted $count apps to rare bucket (skipped $skip active)"
}

unrestrict_apps() {
  local count=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    appops set "$pkg" WAKE_LOCK allow 2>/dev/null
    am set-standby-bucket "$pkg" active 2>/dev/null
    am set-inactive "$pkg" false 2>/dev/null
    count=$((count + 1))
  done
  log_deep "[OK] Unrestricted $count apps"
}

kill_wakelocks() {
  local killed=0
  local tmpfile="$MODDIR/tmp/wakelocks.txt"
  local procfile="$MODDIR/tmp/processes.txt"
  trap 'rm -f "$tmpfile" "$procfile"' EXIT TERM
  dumpsys power 2>/dev/null | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" > "$tmpfile"
  dumpsys activity processes 2>/dev/null > "$procfile"

  while IFS= read -r line; do
    local pkg
    pkg=$(echo "$line" | grep -oE "packageName=[^ ]+" | cut -d= -f2 | tr -d ',')
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue

    local proc_state
    proc_state=$(grep -A2 "packageList=.*$pkg" "$procfile" | grep -oE "procState=[A-Z_]+" | head -1 | cut -d= -f2)
    case "$proc_state" in
      TOP|BOUND_TOP|BOUND_FG_SERVICE|FG_SERVICE) continue ;;
    esac

    am force-stop "$pkg" 2>/dev/null && killed=$((killed + 1))
  done < "$tmpfile"
  rm -f "$tmpfile" "$procfile"
  log_deep "[OK] Killed $killed wakelock holders"
}

unrestrict_alarms() {
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    appops set "$pkg" SCHEDULE_EXACT_ALARM allow 2>/dev/null
    appops set "$pkg" USE_EXACT_ALARM allow 2>/dev/null
  done
  log_deep "[OK] Alarms unrestricted"
}

get_screen_state() {
  # Try dumpsys display first (more reliable on most ROMs)
  local state
  state=$(dumpsys display 2>/dev/null | grep -m1 "mScreenState=" | cut -d= -f2)
  [ -n "$state" ] && { echo "$state"; return; }

  state=$(dumpsys display 2>/dev/null | grep -m1 "Display Power: state=" | sed 's/.*state=//;s/ .*//')
  [ -n "$state" ] && { echo "$state"; return; }

  # Fallback: power wakefulness
  local wake
  wake=$(dumpsys power 2>/dev/null | grep -m1 "mWakefulness=" | cut -d= -f2 | tr -d ' ')
  case "$wake" in
    Awake) echo "ON" ;;
    Asleep|Dozing|Dreaming) echo "OFF" ;;
  esac
}

start_screen_monitor() {
  stop_screen_monitor
  (
    trap 'exit 0' TERM INT
    while true; do
      local state
      state=$(get_screen_state)

      if [ "$state" = "ON" ] || [ -z "$state" ]; then
        sleep 90
        continue
      fi

      # Screen is off - wait 5 minutes then kill background wakelock holders
      log_deep "Screen off - wakelock killer armed (5min)"
      sleep 300

      if [ "$(get_screen_state)" != "ON" ]; then
        log_deep "Running wakelock killer..."
        kill_wakelocks
      fi

      # Wait until screen turns back on before re-arming
      while [ "$(get_screen_state)" != "ON" ]; do
        sleep 180
      done
      log_deep "Screen on - monitor re-armed"
    done
  ) &
  echo $! > "$MONITOR_PID_FILE"
  log_deep "[OK] Screen monitor started (PID $!)"
}

stop_screen_monitor() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    local pid
    pid=$(cat "$MONITOR_PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null
    fi
    rm -f "$MONITOR_PID_FILE"
  fi
}

freeze_deep_doze() {
  echo "Frosty v${MODVER:-?} - Deep Doze (FREEZE) - $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  [ "$ENABLE_DEEP_DOZE" != "1" ] && return 0

  ensure_whitelist
  apply_doze_constants
  restrict_apps "$DEEP_DOZE_LEVEL"

  # Screen monitor runs on BOTH levels: after 5 minutes screen-off it kills background wakelock holders.
  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    kill_wakelocks
  fi
  start_screen_monitor
}

stock_deep_doze() {
  echo "Frosty v${MODVER:-?} - Deep Doze (STOCK) - $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  revert_doze_constants
  unrestrict_apps
  unrestrict_alarms
  stop_screen_monitor
  dumpsys deviceidle unforce 2>/dev/null
}

case "$1" in
  freeze) freeze_deep_doze ;;
  stock)  stock_deep_doze ;;
esac
exit 0
