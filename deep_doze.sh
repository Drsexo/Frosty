#!/system/bin/sh
# 🧊 FROSTY - Deep Doze Enforcer
# Aggressive battery optimization for ALL apps

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
DEEP_DOZE_LOG="$LOGDIR/deep_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
WHITELIST_FILE="$MODDIR/config/doze_whitelist.txt"
MONITOR_PID_FILE="$MODDIR/tmp/screen_monitor.pid"

mkdir -p "$LOGDIR" "$MODDIR/tmp"

log_deep() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEEP_DOZE_LOG"; }

ENABLE_DEEP_DOZE=0
DEEP_DOZE_LEVEL="moderate"
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

generate_whitelist() {
  [ -f "$WHITELIST_FILE" ] && return
  cat > "$WHITELIST_FILE" << 'EOF'
# Frosty Deep Doze Whitelist
# One package per line, # for comments

# System Critical
android
com.android.systemui
com.android.settings
com.android.shell
com.android.providers.settings
com.android.providers.contacts
com.android.providers.telephony
com.android.providers.calendar
com.android.providers.downloads
com.android.providers.media
com.android.keychain
com.android.packageinstaller
com.android.permissioncontroller
com.android.networkstack
com.android.captiveportallogin

# Phone & Dialer
com.android.phone
com.android.server.telecom
com.android.dialer
com.google.android.dialer
com.samsung.android.dialer
com.samsung.android.incallui
com.sec.android.app.telephonyui
com.oneplus.dialer
com.miui.phone
com.miui.voip
com.oppo.dialer
com.coloros.phonemanager
com.huawei.dialer

# SMS & Messaging
com.android.mms
com.android.messaging
com.google.android.apps.messaging
com.samsung.android.messaging
com.oneplus.mms
com.miui.mms
com.oppo.mms
com.huawei.mms

# Alarm & Clock
com.android.deskclock
com.google.android.deskclock
com.sec.android.app.clockpackage
com.samsung.android.app.clockpackage
com.samsung.android.alarm
com.oneplus.deskclock
com.miui.clock
com.oppo.clock
com.huawei.deskclock

# Contacts
com.android.contacts
com.google.android.contacts
com.samsung.android.contacts

# Keyboards
com.android.inputmethod.latin
com.google.android.inputmethod.latin
com.samsung.android.honeyboard
com.touchtype.swiftkey

# Emergency
com.android.emergency
com.google.android.apps.safetyhub

# User Apps - Add your important apps below
# com.whatsapp
# org.telegram.messenger
EOF
  log_deep "Created default whitelist"
}

is_whitelisted() {
  local pkg="$1"
  case "$pkg" in
    android|com.android.systemui|com.android.phone|com.android.settings|com.android.shell)
      return 0 ;;
    com.android.providers.*|com.android.inputmethod.*)
      return 0 ;;
  esac

  if [ -f "$WHITELIST_FILE" ]; then
    sed 's/#.*//;s/[[:space:]]//g' "$WHITELIST_FILE" | grep -qx "$pkg" 2>/dev/null && return 0
  fi
  return 1
}

apply_doze_constants() {
  log_deep "Applying doze constants ($DEEP_DOZE_LEVEL)..."

  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    # Ultra-aggressive: instant doze entry, long idle periods
    local constants="light_after_inactive_to=0"
    constants="$constants,light_pre_idle_to=5000"
    constants="$constants,light_idle_to=3600000"
    constants="$constants,light_max_idle_to=43200000"
    constants="$constants,inactive_to=0"
    constants="$constants,sensing_to=0"
    constants="$constants,motion_inactive_to=0"
    constants="$constants,idle_after_inactive_to=0"
    constants="$constants,idle_to=21600000"
    constants="$constants,max_idle_to=172800000"
    constants="$constants,quick_doze_delay_to=5000"
    constants="$constants,min_time_to_alarm=300000"
  else
    # Moderate: reasonable delays, balanced battery/functionality
    local constants="light_after_inactive_to=300000"
    constants="$constants,light_pre_idle_to=300000"
    constants="$constants,light_idle_to=900000"
    constants="$constants,light_max_idle_to=1800000"
    constants="$constants,inactive_to=1800000"
    constants="$constants,sensing_to=0"
    constants="$constants,motion_inactive_to=0"
    constants="$constants,idle_after_inactive_to=0"
    constants="$constants,idle_to=3600000"
    constants="$constants,max_idle_to=7200000"
    constants="$constants,quick_doze_delay_to=300000"
  fi

  settings put global device_idle_constants "$constants" 2>/dev/null && \
    log_deep "[OK] Doze constants applied ($DEEP_DOZE_LEVEL)" || log_deep "[FAIL] Doze constants"

  dumpsys deviceidle enable all 2>/dev/null
  settings put global app_standby_enabled 1 2>/dev/null
  settings put global forced_app_standby_enabled 1 2>/dev/null
  settings put global app_auto_restriction_enabled true 2>/dev/null
  settings put global adaptive_battery_management_enabled 1 2>/dev/null
  log_deep "[OK] App standby enabled"
}

revert_doze_constants() {
  settings delete global device_idle_constants 2>/dev/null
  log_deep "[OK] Doze constants reverted"
}

restrict_apps_moderate() {
  log_deep "Restricting apps (moderate)..."
  local count=0 skipped=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    if is_whitelisted "$pkg"; then
      skipped=$((skipped + 1))
      continue
    fi
    appops set "$pkg" RUN_IN_BACKGROUND deny 2>/dev/null
    am set-standby-bucket "$pkg" restricted 2>/dev/null
    am set-inactive "$pkg" true 2>/dev/null
    count=$((count + 1))
  done
  log_deep "[OK] Restricted $count apps (skipped $skipped)"
}

restrict_apps_maximum() {
  log_deep "Restricting apps (maximum)..."
  local count=0 skipped=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    if is_whitelisted "$pkg"; then
      skipped=$((skipped + 1))
      continue
    fi
    appops set "$pkg" RUN_IN_BACKGROUND deny 2>/dev/null
    appops set "$pkg" WAKE_LOCK deny 2>/dev/null
    am set-standby-bucket "$pkg" restricted 2>/dev/null
    am set-inactive "$pkg" true 2>/dev/null
    count=$((count + 1))
  done
  log_deep "[OK] Restricted $count apps (skipped $skipped)"
}

unrestrict_apps() {
  log_deep "Removing restrictions..."
  local count=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    appops set "$pkg" RUN_IN_BACKGROUND allow 2>/dev/null
    appops set "$pkg" WAKE_LOCK allow 2>/dev/null
    am set-standby-bucket "$pkg" active 2>/dev/null
    am set-inactive "$pkg" false 2>/dev/null
    count=$((count + 1))
  done
  log_deep "[OK] Unrestricted $count apps"
}

kill_wakelocks() {
  log_deep "Killing wakelocks..."
  local killed=0
  local tmpfile="$MODDIR/tmp/wakelocks.txt"
  dumpsys power 2>/dev/null | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" > "$tmpfile"
  while read -r line; do
    local pkg=$(echo "$line" | grep -oE "packageName=[^ ]+" | cut -d= -f2 | tr -d ',')
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    am force-stop "$pkg" 2>/dev/null && killed=$((killed + 1))
  done < "$tmpfile"
  rm -f "$tmpfile"
  log_deep "[OK] Killed $killed wakelock holders"
}

restrict_alarms() {
  log_deep "Restricting alarms..."
  local count=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    appops set "$pkg" SCHEDULE_EXACT_ALARM deny 2>/dev/null
    appops set "$pkg" USE_EXACT_ALARM deny 2>/dev/null
    count=$((count + 1))
  done
  log_deep "[OK] Alarms restricted for $count apps"
}

unrestrict_alarms() {
  log_deep "Removing alarm restrictions..."
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    appops set "$pkg" SCHEDULE_EXACT_ALARM allow 2>/dev/null
    appops set "$pkg" USE_EXACT_ALARM allow 2>/dev/null
  done
  log_deep "[OK] Alarms unrestricted"
}

stop_screen_monitor() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    local pid=$(cat "$MONITOR_PID_FILE")
    kill "$pid" 2>/dev/null
    rm -f "$MONITOR_PID_FILE"
    log_deep "[OK] Screen monitor stopped (PID $pid)"
  fi
}

start_screen_monitor() {
  stop_screen_monitor
  log_deep "Starting screen-off monitor (5min delay)..."
  (
    trap 'exit 0' TERM INT
    while true; do
      # Check screen state with fallback
      screen_state=$(dumpsys display 2>/dev/null | grep -m1 "mScreenState=" | cut -d= -f2)
      if [ -z "$screen_state" ]; then
        sleep 120
        continue
      fi

      if [ "$screen_state" = "ON" ]; then
        sleep 60
        continue
      fi

      # Screen is off, wait 5 minutes
      log_deep "Screen off detected, waiting 5 minutes..."
      sleep 300

      # Re-check before forcing idle
      screen_state=$(dumpsys display 2>/dev/null | grep -m1 "mScreenState=" | cut -d= -f2)
      if [ "$screen_state" != "ON" ]; then
        dumpsys deviceidle force-idle deep 2>/dev/null
        log_deep "[OK] Forced deep idle"
      else
        log_deep "Screen back on, skipping"
      fi

      # Wait for screen on before next cycle
      while true; do
        screen_state=$(dumpsys display 2>/dev/null | grep -m1 "mScreenState=" | cut -d= -f2)
        [ "$screen_state" = "ON" ] && break
        sleep 120
      done
      log_deep "Screen on, monitor re-armed"
    done
  ) &
  echo $! > "$MONITOR_PID_FILE"
  log_deep "[OK] Monitor started (PID $!)"
}

freeze_deep_doze() {
  echo "Frosty Deep Doze - FREEZE $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"

  if [ "$ENABLE_DEEP_DOZE" != "1" ]; then
    log_deep "[SKIP] Deep Doze disabled"
    echo "  🔋 Deep Doze: SKIPPED"
    return 0
  fi

  log_deep "Enabling Deep Doze ($DEEP_DOZE_LEVEL)..."
  generate_whitelist
  apply_doze_constants

  case "$DEEP_DOZE_LEVEL" in
    maximum)
      restrict_apps_maximum
      kill_wakelocks
      restrict_alarms
      ;;
    *)
      restrict_apps_moderate
      ;;
  esac

  start_screen_monitor

  echo ""
  echo "  🔋 DEEP DOZE: ENABLED ($DEEP_DOZE_LEVEL)"
  echo "  Screen-off monitor active (5min delay)"
  echo ""
}

stock_deep_doze() {
  echo "Frosty Deep Doze - STOCK $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  log_deep "Disabling Deep Doze..."

  revert_doze_constants
  unrestrict_apps
  unrestrict_alarms
  stop_screen_monitor

  dumpsys deviceidle unforce 2>/dev/null
  log_deep "[OK] Device idle unforced"

  echo ""
  echo "  🔥 DEEP DOZE: DISABLED"
  echo ""
}

status() {
  local doze_state=$(dumpsys deviceidle 2>/dev/null | grep -m1 "mState=" | cut -d= -f2)
  local restricted=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    appops get "$pkg" RUN_IN_BACKGROUND 2>/dev/null | grep -q "deny" && restricted=$((restricted + 1))
  done
  local monitor_running="NO"
  [ -f "$MONITOR_PID_FILE" ] && kill -0 $(cat "$MONITOR_PID_FILE") 2>/dev/null && monitor_running="YES"

  echo ""
  echo "  🔋 Deep Doze Status"
  echo "  Enabled: $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "YES" || echo "NO")"
  echo "  Level: $DEEP_DOZE_LEVEL"
  echo "  Doze state: $doze_state"
  echo "  Apps restricted: $restricted"
  echo "  Screen monitor: $monitor_running"
  echo ""
}

case "$1" in
  freeze) freeze_deep_doze ;;
  stock) stock_deep_doze ;;
  status) status ;;
  *) echo "Usage: deep_doze.sh [freeze|stock|status]" ;;
esac

exit 0