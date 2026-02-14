#!/system/bin/sh
# 🧊 FROSTY - Deep Doze Enforcer (Optimizado para reducir consumo de batería)
# Aggressive battery optimization for ALL apps

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/FrostyEnhanced"

LOGDIR="$MODDIR/logs"
DEEP_DOZE_LOG="$LOGDIR/deep_doze.log"
ERROR_LOG="$LOGDIR/deep_doze_errors.log"
USER_PREFS="$MODDIR/config/user_prefs"
WHITELIST_FILE="$MODDIR/config/doze_whitelist.txt"
MONITOR_PID_FILE="$MODDIR/tmp/screen_monitor.pid"
WATCHDOG_PID_FILE="$MODDIR/tmp/watchdog.pid"

mkdir -p "$LOGDIR" "$MODDIR/tmp"

# --- Funciones de Seguridad y Logging ---
log_deep() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEEP_DOZE_LOG"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
  log_deep "[ERROR] $1"
}

show_error_notification() {
  local title="Frosty Deep Doze Error"
  local message="$1"
  su -c "cmd notification post -S bigtext -t '$title' 'Frosty Module' '$message'" 2>/dev/null
  log_error "$message"
}

disable_module_safely() {
  local reason="$1"
  show_error_notification "$reason"
  echo "stock" > "$MODDIR/config/state"
  stock_deep_doze
  exit 1
}

check_root() {
  if ! su -c "echo 'root check'" >/dev/null 2>&1; then
    disable_module_safely "No root access."
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Watchdog para monitorear GPS y temperatura ---
start_watchdog() {
  stop_watchdog
  log_deep "Starting watchdog..."
  (
    while true; do
      sleep 300 # Cada 5 minutos
      local gps_status=$(dumpsys location | grep -c "GpsLocationProvider")
      local cpu_temp=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -nr | head -1)
      cpu_temp=$((cpu_temp / 1000))

      if [ "$gps_status" -eq 0 ] && [ "$DISABLE_LOCATION" -ne 1 ]; then
        log_error "[WATCHDOG] GPS no disponible y LOCATION no congelado. Revertiendo..."
        disable_module_safely "GPS no funciona correctamente. Módulo desactivado."
        break
      fi

      if [ "$cpu_temp" -gt 50 ]; then
        log_error "[WATCHDOG] Temperatura alta ($cpu_temp°C). Revertiendo..."
        disable_module_safely "Temperatura crítica detectada ($cpu_temp°C). Módulo desactivado."
        break
      fi
    done
  ) &
  echo $! > "$WATCHDOG_PID_FILE"
  log_deep "[OK] Watchdog started (PID $!)"
}

stop_watchdog() {
  if [ -f "$WATCHDOG_PID_FILE" ]; then
    local pid=$(cat "$WATCHDOG_PID_FILE")
    kill "$pid" 2>/dev/null
    rm -f "$WATCHDOG_PID_FILE"
    log_deep "[OK] Watchdog stopped (PID $pid)"
  fi
}

# --- Funciones para manejar wakelocks ---
kill_non_essential_wakelocks() {
  log_deep "Killing non-essential wakelocks..."
  local killed=0
  local tmpfile="$MODDIR/tmp/wakelocks.txt"
  dumpsys power | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" > "$tmpfile"
  while read -r line; do
    local pkg=$(echo "$line" | grep -oE "packageName=[^ ]+" | cut -d= -f2 | tr -d ',')
    [ -z "$pkg" ] && continue
    if is_whitelisted "$pkg"; then
      log_deep "Skipping whitelisted wakelock: $pkg"
      continue
    fi
    if echo "$line" | grep -qE "SCREEN_BRIGHT_WAKE_LOCK|AutomaticOnOffKeepaliveTracker|sched_latency_data_alarm|report_power_statistic"; then
      if am force-stop "$pkg" 2>/dev/null; then
        killed=$((killed + 1))
        log_deep "Killed non-essential wakelock: $pkg"
      else
        log_error "Failed to force-stop $pkg"
      fi
    fi
  done < "$tmpfile"
  rm -f "$tmpfile"
  log_deep "[OK] Killed $killed non-essential wakelocks"
}

# --- Funciones para manejar alarmas ---
restrict_non_essential_alarms() {
  log_deep "Restricting non-essential alarms..."
  local restricted=0
  local alarm_pkgs=(
    "com.whatsapp"
    "com.google.android.gms"
    "com.miui.securitycenter"
    "com.android.settings"
  )
  for pkg in "${alarm_pkgs[@]}"; do
    if ! is_whitelisted "$pkg"; then
      if appops set "$pkg" SCHEDULE_EXACT_ALARM deny 2>/dev/null; then
        restricted=$((restricted + 1))
        log_deep "Restricted SCHEDULE_EXACT_ALARM for $pkg"
      fi
      if appops set "$pkg" USE_EXACT_ALARM deny 2>/dev/null; then
        log_deep "Restricted USE_EXACT_ALARM for $pkg"
      fi
    fi
  done
  log_deep "[OK] Restricted alarms for $restricted packages"
}

# --- Funciones Principales ---
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

# Location Services (whitelisted if DISABLE_LOCATION=0)
com.google.android.gms.location
com.google.android.location

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
    com.google.android.gms.location*|com.google.android.location*|com.xiaomi.location*|com.miui.location*)
      [ "$DISABLE_LOCATION" -ne 1 ] && return 0 ;;
  esac
  [ -f "$WHITELIST_FILE" ] && grep -q "^${pkg}$" "$WHITELIST_FILE" 2>/dev/null && return 0
  return 1
}

apply_doze_constants() {
  log_deep "Applying aggressive doze constants..."

  local constants="light_after_inactive_to=300000"  # 5 min
  constants="$constants,light_pre_idle_to=300000"
  constants="$constants,light_idle_to=900000"       # 15 min
  constants="$constants,light_max_idle_to=1800000"  # 30 min
  constants="$constants,inactive_to=1800000"
  constants="$constants,sensing_to=0"
  constants="$constants,motion_inactive_to=0"
  constants="$constants,idle_after_inactive_to=0"
  constants="$constants,idle_to=3600000"            # 1 hour
  constants="$constants,max_idle_to=7200000"        # 2 hours
  constants="$constants,quick_doze_delay_to=300000" # 5 min

  # Ensure doze framework is enabled
  dumpsys deviceidle enable all >/dev/null 2>&1 || log_error "Failed to enable deviceidle"

  settings put global app_standby_enabled 1 2>/dev/null || log_error "Failed to enable app_standby"
  settings put global forced_app_standby_enabled 1 2>/dev/null || log_error "Failed to enable forced_app_standby"
  settings put global adaptive_battery_management_enabled 1 2>/dev/null || log_error "Failed to enable adaptive_battery"

  # Apply constants
  if ! settings put global device_idle_constants "$constants" 2>/dev/null; then
    log_error "Failed to apply doze constants"
    return 1
  fi

  log_deep "[OK] Aggressive doze constants applied"
  return 0
}

revert_doze_constants() {
  settings delete global device_idle_constants 2>/dev/null && \
    log_deep "[OK] Doze constants reverted" || log_error "Failed to revert doze constants"
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
    if ! appops set "$pkg" RUN_IN_BACKGROUND deny 2>/dev/null; then
      log_error "Failed to restrict RUN_IN_BACKGROUND for $pkg"
    fi
    if ! am set-standby-bucket "$pkg" restricted 2>/dev/null; then
      log_error "Failed to set standby bucket for $pkg"
    fi
    if ! am set-inactive "$pkg" true 2>/dev/null; then
      log_error "Failed to set inactive for $pkg"
    fi
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
    if ! appops set "$pkg" RUN_IN_BACKGROUND deny 2>/dev/null; then
      log_error "Failed to restrict RUN_IN_BACKGROUND for $pkg"
    fi
    if ! appops set "$pkg" WAKE_LOCK deny 2>/dev/null; then
      log_error "Failed to restrict WAKE_LOCK for $pkg"
    fi
    if ! am set-standby-bucket "$pkg" restricted 2>/dev/null; then
      log_error "Failed to set standby bucket for $pkg"
    fi
    if ! am set-inactive "$pkg" true 2>/dev/null; then
      log_error "Failed to set inactive for $pkg"
    fi
    count=$((count + 1))
  done
  log_deep "[OK] Restricted $count apps (skipped $skipped)"
}

unrestrict_apps() {
  log_deep "Removing restrictions..."
  local count=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    if ! appops set "$pkg" RUN_IN_BACKGROUND allow 2>/dev/null; then
      log_error "Failed to unrestrict RUN_IN_BACKGROUND for $pkg"
    fi
    if ! appops set "$pkg" WAKE_LOCK allow 2>/dev/null; then
      log_error "Failed to unrestrict WAKE_LOCK for $pkg"
    fi
    if ! am set-standby-bucket "$pkg" active 2>/dev/null; then
      log_error "Failed to set active standby bucket for $pkg"
    fi
    if ! am set-inactive "$pkg" false 2>/dev/null; then
      log_error "Failed to set active for $pkg"
    fi
    count=$((count + 1))
  done
  log_deep "[OK] Unrestricted $count apps"
}

kill_wakelocks() {
  log_deep "Killing wakelocks..."
  local killed=0
  local tmpfile="$MODDIR/tmp/wakelocks.txt"
  dumpsys power | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" > "$tmpfile"
  while read -r line; do
    local pkg=$(echo "$line" | grep -oE "packageName=[^ ]+" | cut -d= -f2 | tr -d ',')
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    if am force-stop "$pkg" 2>/dev/null; then
      killed=$((killed + 1))
    else
      log_error "Failed to force-stop $pkg"
    fi
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
    if ! appops set "$pkg" SCHEDULE_EXACT_ALARM deny 2>/dev/null; then
      log_error "Failed to restrict SCHEDULE_EXACT_ALARM for $pkg"
    fi
    if ! appops set "$pkg" USE_EXACT_ALARM deny 2>/dev/null; then
      log_error "Failed to restrict USE_EXACT_ALARM for $pkg"
    fi
    count=$((count + 1))
  done
  log_deep "[OK] Alarms restricted for $count apps"
}

unrestrict_alarms() {
  log_deep "Removing alarm restrictions..."
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    if ! appops set "$pkg" SCHEDULE_EXACT_ALARM allow 2>/dev/null; then
      log_error "Failed to unrestrict SCHEDULE_EXACT_ALARM for $pkg"
    fi
    if ! appops set "$pkg" USE_EXACT_ALARM allow 2>/dev/null; then
      log_error "Failed to unrestrict USE_EXACT_ALARM for $pkg"
    fi
  done
  log_deep "[OK] Alarms unrestricted"
}

stop_screen_monitor() {
  if [ -f "$MONITOR_PID_FILE" ]; then
    local pid=$(cat "$MONITOR_PID_FILE")
    kill "$pid" 2>/dev/null && rm -f "$MONITOR_PID_FILE" && log_deep "[OK] Screen monitor stopped (PID $pid)"
  fi
}

start_screen_monitor() {
  stop_screen_monitor
  log_deep "Starting screen-off monitor (5min delay)..."
  (
    while true; do
      sleep 60 # Espera 1 minuto entre checks
      if ! dumpsys display 2>/dev/null | grep -q "mScreenState=ON"; then
        log_deep "Screen off, waiting 5 minutes..."
        sleep 300
        if ! dumpsys display 2>/dev/null | grep -q "mScreenState=ON"; then
          if ! dumpsys deviceidle force-idle deep 2>/dev/null; then
            log_error "Failed to force deep idle"
          else
            log_deep "[OK] Forced deep idle"
          fi
        else
          log_deep "Screen back on, skipping"
        fi
      fi
    done
  ) &
  echo $! > "$MONITOR_PID_FILE"
  log_deep "[OK] Monitor started (PID $!)"
}

freeze_deep_doze() {
  echo "Frosty Deep Doze - FREEZE $(date '+%Y-%m-%d %H:%M:%S')" > "$DEEP_DOZE_LOG"
  check_root

  if [ "$ENABLE_DEEP_DOZE" != "1" ]; then
    log_deep "[SKIP] Deep Doze disabled"
    echo "  🔋 Deep Doze: SKIPPED"
    return 0
  fi

  log_deep "Enabling Deep Doze ($DEEP_DOZE_LEVEL)..."
  generate_whitelist
  apply_doze_constants || disable_module_safely "Failed to apply doze constants."

  case "$DEEP_DOZE_LEVEL" in
    maximum)
      restrict_apps_maximum
      kill_wakelocks
      restrict_non_essential_alarms
      kill_non_essential_wakelocks
      ;;
    *)
      restrict_apps_moderate
      kill_non_essential_wakelocks
      ;;
  esac

  start_screen_monitor
  start_watchdog

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
  stop_watchdog

  if ! dumpsys deviceidle unforce 2>/dev/null; then
    log_error "Failed to unforce device idle"
  else
    log_deep "[OK] Device idle unforced"
  fi

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
  local watchdog_running="NO"
  [ -f "$WATCHDOG_PID_FILE" ] && kill -0 $(cat "$WATCHDOG_PID_FILE") 2>/dev/null && watchdog_running="YES"

  echo ""
  echo "  🔋 Deep Doze Status"
  echo "  Enabled: $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "YES" || echo "NO")"
  echo "  Level: $DEEP_DOZE_LEVEL"
  echo "  Doze state: $doze_state"
  echo "  Apps restricted: $restricted"
  echo "  Screen monitor: $monitor_running"
  echo "  Watchdog: $watchdog_running"
  echo ""
}

case "$1" in
  freeze) freeze_deep_doze ;;
  stock) stock_deep_doze ;;
  status) status ;;
  *) echo "Usage: deep_doze.sh [freeze|stock|status]" ;;
esac

exit 0