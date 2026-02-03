#!/system/bin/sh
# 🧊 FROSTY - Deep Doze Enforcer
# Aggressive battery optimization for ALL apps
# Based on DeepDoze Enforcer concepts

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
DEEP_DOZE_LOG="$LOGDIR/deep_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
WHITELIST_FILE="$MODDIR/config/doze_whitelist.txt"

# Initialize
mkdir -p "$LOGDIR"

log_deep() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEEP_DOZE_LOG"
}

# Load preferences
ENABLE_DEEP_DOZE=0
DEEP_DOZE_LEVEL="moderate"
[ -f "$USER_PREFS" ] && . "$USER_PREFS"


# WHITELIST MANAGEMENT
generate_whitelist() {
  # Create default whitelist if not exists
  if [ ! -f "$WHITELIST_FILE" ]; then
    cat > "$WHITELIST_FILE" << 'EOF'
# 🧊 FROSTY - Deep Doze Whitelist
# Apps listed here will NOT be restricted by Deep Doze
# Add one package name per line
# Lines starting with # are comments


# SYSTEM CRITICAL - DO NOT REMOVE
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

# PHONE & DIALER
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
com.asus.dialer
com.huawei.dialer
com.sonymobile.android.dialer

# SMS & MESSAGING
com.android.mms
com.android.messaging
com.google.android.apps.messaging
com.samsung.android.messaging
com.sec.android.app.samsungmessages
com.oneplus.mms
com.miui.mms
com.oppo.mms
com.coloros.mms
com.asus.message
com.huawei.mms
com.sonymobile.android.messaging

# ALARM & CLOCK
com.android.deskclock
com.google.android.deskclock
com.sec.android.app.clockpackage
com.samsung.android.app.clockpackage
com.samsung.android.alarm
com.oneplus.deskclock
com.miui.clock
com.miui.alarmclock
com.oppo.clock
com.coloros.alarmclock
com.asus.alarmclock
com.huawei.deskclock
com.sonymobile.android.alarm

# CONTACTS
com.android.contacts
com.google.android.contacts
com.samsung.android.contacts
com.sec.android.app.contacts
com.oneplus.contacts
com.miui.contacts
com.oppo.contacts
com.coloros.contacts

# KEYBOARDS
com.android.inputmethod.latin
com.google.android.inputmethod.latin
com.samsung.android.honeyboard
com.sec.android.inputmethod
com.touchtype.swiftkey
com.google.android.inputmethod.korean
com.google.android.inputmethod.japanese
com.google.android.inputmethod.pinyin

# EMERGENCY & SAFETY
com.android.emergency
com.google.android.apps.safetyhub
com.samsung.android.emergencymode
com.miui.sos


# USER APPS - Add your important apps below

# com.whatsapp
# org.telegram.messenger
# your.banking.app
# com.example

EOF
    log_deep "[INFO] Created default whitelist at $WHITELIST_FILE"
  fi
}

is_whitelisted() {
  local pkg="$1"
  
  # Check built-in system critical (always whitelist)
  case "$pkg" in
    android|com.android.systemui|com.android.phone|com.android.settings|com.android.shell)
      return 0 ;;
    com.android.providers.*|com.android.inputmethod.*)
      return 0 ;;
  esac
  
  # Check whitelist file
  if [ -f "$WHITELIST_FILE" ]; then
    grep -q "^${pkg}$" "$WHITELIST_FILE" 2>/dev/null && return 0
  fi
  
  return 1
}

is_system_app() {
  local pkg="$1"
  pm path "$pkg" 2>/dev/null | grep -q "^package:/system" && return 0
  pm path "$pkg" 2>/dev/null | grep -q "^package:/product" && return 0
  pm path "$pkg" 2>/dev/null | grep -q "^package:/vendor" && return 0
  return 1
}


# AGGRESSIVE DOZE CONSTANTS
apply_doze_constants() {
  log_deep ""
  log_deep "━━━ Aggressive Doze Constants ━━━"
  
  # Nuclear doze constants - instant idle, maximum sleep durations
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
  
  if settings put global device_idle_constants "$constants" 2>/dev/null; then
    log_deep "[OK]   Doze constants applied (instant idle)"
  else
    log_deep "[FAIL] Could not apply doze constants"
  fi
  
  # Force enable doze
  dumpsys deviceidle enable all 2>/dev/null
  log_deep "[OK]   DeviceIdle enabled"
  
  # App standby settings
  settings put global app_standby_enabled 1 2>/dev/null
  settings put global forced_app_standby_enabled 1 2>/dev/null
  settings put global app_auto_restriction_enabled true 2>/dev/null
  settings put global adaptive_battery_management_enabled 1 2>/dev/null
  log_deep "[OK]   App standby enabled"
}

revert_doze_constants() {
  log_deep ""
  log_deep "━━━ Reverting Doze Constants ━━━"
  
  # Delete custom constants (restores defaults)
  settings delete global device_idle_constants 2>/dev/null
  log_deep "[OK]   Doze constants reverted to default"
}


# APP RESTRICTIONS (MODERATE + MAXIMUM)
restrict_apps_moderate() {
  log_deep ""
  log_deep "━━━ App Restrictions (Moderate) ━━━"
  
  local count=0
  local skipped=0
  
  # Get all third-party packages
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    
    # Skip whitelisted
    if is_whitelisted "$pkg"; then
      skipped=$((skipped + 1))
      continue
    fi
    
    # Deny RUN_IN_BACKGROUND
    appops set "$pkg" RUN_IN_BACKGROUND deny 2>/dev/null
    
    # Set to restricted standby bucket
    am set-standby-bucket "$pkg" restricted 2>/dev/null
    
    # Make inactive
    am set-inactive "$pkg" true 2>/dev/null
    
    count=$((count + 1))
  done
  
  log_deep "[OK]   Restricted $count apps (skipped $skipped whitelisted)"
}

restrict_apps_maximum() {
  log_deep ""
  log_deep "━━━ App Restrictions (Maximum) ━━━"
  
  local count=0
  local skipped=0
  
  # Get all third-party packages
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    
    # Skip whitelisted
    if is_whitelisted "$pkg"; then
      skipped=$((skipped + 1))
      continue
    fi
    
    # Deny RUN_IN_BACKGROUND
    appops set "$pkg" RUN_IN_BACKGROUND deny 2>/dev/null
    
    # Deny WAKE_LOCK (Maximum only)
    appops set "$pkg" WAKE_LOCK deny 2>/dev/null
    
    # Set to restricted standby bucket
    am set-standby-bucket "$pkg" restricted 2>/dev/null
    
    # Make inactive
    am set-inactive "$pkg" true 2>/dev/null
    
    count=$((count + 1))
  done
  
  log_deep "[OK]   Restricted $count apps with WAKE_LOCK deny (skipped $skipped)"
}

unrestrict_apps() {
  log_deep ""
  log_deep "━━━ Removing App Restrictions ━━━"
  
  local count=0
  
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    
    # Allow RUN_IN_BACKGROUND
    appops set "$pkg" RUN_IN_BACKGROUND allow 2>/dev/null
    
    # Allow WAKE_LOCK
    appops set "$pkg" WAKE_LOCK allow 2>/dev/null
    
    # Set to active bucket
    am set-standby-bucket "$pkg" active 2>/dev/null
    
    # Make active
    am set-inactive "$pkg" false 2>/dev/null
    
    count=$((count + 1))
  done
  
  log_deep "[OK]   Unrestricted $count apps"
}


# NETWORK LOCKDOWN (MAXIMUM ONLY)
network_lockdown() {
  log_deep ""
  log_deep "━━━ Network Lockdown ━━━"
  
  # Disable background scanning
  settings put global wifi_scan_always_enabled 0 2>/dev/null
  settings put global wifi_wakeup_enabled 0 2>/dev/null
  settings put global ble_scan_always_enabled 0 2>/dev/null
  settings put global wifi_networks_available_notification_on 0 2>/dev/null
  log_deep "[OK]   WiFi/BLE scanning disabled"
  
  # Disable network recommendations
  settings put global network_scoring_ui_enabled 0 2>/dev/null
  settings put global network_recommendations_enabled 0 2>/dev/null
  log_deep "[OK]   Network recommendations disabled"
  
  # Mobile data always on = off
  settings put global mobile_data_always_on 0 2>/dev/null
  log_deep "[OK]   Mobile data always-on disabled"
}

network_restore() {
  log_deep ""
  log_deep "━━━ Network Restore ━━━"
  
  settings put global wifi_scan_always_enabled 1 2>/dev/null
  settings put global wifi_wakeup_enabled 1 2>/dev/null
  settings put global ble_scan_always_enabled 1 2>/dev/null
  settings put global wifi_networks_available_notification_on 1 2>/dev/null
  settings put global network_scoring_ui_enabled 1 2>/dev/null
  settings put global network_recommendations_enabled 1 2>/dev/null
  settings put global mobile_data_always_on 1 2>/dev/null
  
  log_deep "[OK]   Network settings restored"
}


# SENSOR FREEZE (MAXIMUM ONLY)
freeze_sensors() {
  log_deep ""
  log_deep "━━━ Sensor Freeze ━━━"
  
  local count=0
  
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    
    appops set "$pkg" BODY_SENSORS deny 2>/dev/null
    appops set "$pkg" ACTIVITY_RECOGNITION deny 2>/dev/null
    appops set "$pkg" HIGH_SAMPLING_RATE_SENSORS deny 2>/dev/null
    
    count=$((count + 1))
  done
  
  settings put global sensors_suspend_enabled 1 2>/dev/null
  
  log_deep "[OK]   Sensors frozen for $count apps"
}

unfreeze_sensors() {
  log_deep ""
  log_deep "━━━ Sensor Unfreeze ━━━"
  
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    
    appops set "$pkg" BODY_SENSORS allow 2>/dev/null
    appops set "$pkg" ACTIVITY_RECOGNITION allow 2>/dev/null
    appops set "$pkg" HIGH_SAMPLING_RATE_SENSORS allow 2>/dev/null
  done
  
  settings put global sensors_suspend_enabled 0 2>/dev/null
  
  log_deep "[OK]   Sensors unfrozen"
}


# WAKELOCK KILLER (MAXIMUM ONLY)
kill_wakelocks() {
  log_deep ""
  log_deep "━━━ Wakelock Killer ━━━"
  
  local killed=0
  
  # Parse active wakelocks from power service
  dumpsys power 2>/dev/null | grep -E "PARTIAL_WAKE_LOCK|FULL_WAKE_LOCK" | while read -r line; do
    pkg=$(echo "$line" | grep -oE "packageName=[^ ]+" | cut -d= -f2 | tr -d ',')
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    
    # Force stop the wakelock holder
    am force-stop "$pkg" 2>/dev/null && {
      log_deep "[KILL] $pkg (holding wakelock)"
      killed=$((killed + 1))
    }
  done
  
  log_deep "[OK]   Wakelock killer complete"
}


# ALARM RESTRICTIONS (MAXIMUM ONLY - Safe for system alarms)
restrict_alarms() {
  log_deep ""
  log_deep "━━━ Alarm Restrictions ━━━"
  
  local count=0
  
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    is_whitelisted "$pkg" && continue
    
    appops set "$pkg" SCHEDULE_EXACT_ALARM deny 2>/dev/null
    appops set "$pkg" USE_EXACT_ALARM deny 2>/dev/null
    
    count=$((count + 1))
  done
  
  log_deep "[OK]   Alarm restrictions applied to $count apps"
  log_deep "[INFO] System alarm apps are protected via whitelist"
}

unrestrict_alarms() {
  log_deep ""
  log_deep "━━━ Removing Alarm Restrictions ━━━"
  
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    [ -z "$pkg" ] && continue
    
    appops set "$pkg" SCHEDULE_EXACT_ALARM allow 2>/dev/null
    appops set "$pkg" USE_EXACT_ALARM allow 2>/dev/null
  done
  
  log_deep "[OK]   Alarm restrictions removed"
}


# FREEZE - Enable Deep Doze
freeze_deep_doze() {
  echo "═════════════════════════════════════" > "$DEEP_DOZE_LOG"
  echo "🔋 FROSTY Deep Doze Log - FREEZE Operation" >> "$DEEP_DOZE_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$DEEP_DOZE_LOG"
  echo "Level: $DEEP_DOZE_LEVEL" >> "$DEEP_DOZE_LOG"
  echo "═════════════════════════════════════" >> "$DEEP_DOZE_LOG"
  echo "" >> "$DEEP_DOZE_LOG"
  
  if [ "$ENABLE_DEEP_DOZE" != "1" ]; then
    log_deep "[SKIP] Deep Doze disabled by user preference"
    echo ""
    echo "  🔋 Deep Doze: SKIPPED (disabled in config)"
    echo ""
    return 0
  fi
  
  log_deep "[INFO] Enabling Deep Doze ($DEEP_DOZE_LEVEL mode)..."
  
  # Generate whitelist if needed
  generate_whitelist
  
  # Always apply (both levels)
  apply_doze_constants
  
  # Level-specific restrictions
  case "$DEEP_DOZE_LEVEL" in
    maximum)
      restrict_apps_maximum
      network_lockdown
      freeze_sensors
      kill_wakelocks
      restrict_alarms
      ;;
    moderate|*)
      restrict_apps_moderate
      ;;
  esac
  
  # Force deep doze immediately
  dumpsys deviceidle force-idle deep 2>/dev/null
  log_deep "[OK]   Forced deep idle"
  
  # Summary
  log_deep ""
  log_deep "═════════════════════════════════════"
  log_deep "SUMMARY"
  log_deep "═════════════════════════════════════"
  log_deep "  Level: $DEEP_DOZE_LEVEL"
  log_deep "  Doze constants: AGGRESSIVE"
  log_deep "  App restrictions: ENABLED"
  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    log_deep "  Wakelock deny: YES"
    log_deep "  Network lockdown: YES"
    log_deep "  Sensor freeze: YES"
    log_deep "  Alarm restrictions: YES"
  else
    log_deep "  Wakelock deny: NO"
    log_deep "  Network lockdown: NO"
    log_deep "  Sensor freeze: NO"
    log_deep "  Alarm restrictions: NO"
  fi
  log_deep ""
  log_deep "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  log_deep "═════════════════════════════════════"
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🔋 DEEP DOZE: ENABLED ($DEEP_DOZE_LEVEL)"
  echo ""
  echo "  All third-party apps restricted"
  echo "  Aggressive doze constants applied"
  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    echo "  Network lockdown: ACTIVE"
    echo "  Wakelock killer: ACTIVE"
  fi
  echo ""
  echo "  📄 Details: $DEEP_DOZE_LOG"
  echo "═════════════════════════════════════════════"
  echo ""
}


# STOCK - Disable Deep Doze
stock_deep_doze() {
  echo "═════════════════════════════════════" > "$DEEP_DOZE_LOG"
  echo "🔥 FROSTY Deep Doze Log - STOCK Operation" >> "$DEEP_DOZE_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$DEEP_DOZE_LOG"
  echo "═════════════════════════════════════" >> "$DEEP_DOZE_LOG"
  echo "" >> "$DEEP_DOZE_LOG"
  
  log_deep "[INFO] Disabling Deep Doze (restoring stock)..."
  
  # Revert all
  revert_doze_constants
  unrestrict_apps
  network_restore
  unfreeze_sensors
  unrestrict_alarms
  
  # Exit forced doze
  dumpsys deviceidle unforce 2>/dev/null
  log_deep "[OK]   Unforced device idle"
  
  # Summary
  log_deep ""
  log_deep "═════════════════════════════════════"
  log_deep "SUMMARY"
  log_deep "═════════════════════════════════════"
  log_deep "  Doze constants: DEFAULT"
  log_deep "  App restrictions: REMOVED"
  log_deep "  Network: RESTORED"
  log_deep "  Sensors: UNFROZEN"
  log_deep ""
  log_deep "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  log_deep "═════════════════════════════════════"
  
  echo ""
  echo "═════════════════════════════════════"
  echo "  🔥 DEEP DOZE: DISABLED (Stock Mode)"
  echo ""
  echo "  All apps unrestricted"
  echo "  Doze constants reverted"
  echo "  Network settings restored"
  echo ""
  echo "  📄 Details: $DEEP_DOZE_LOG"
  echo "═════════════════════════════════════"
  echo ""
}


# STATUS
status() {
  # Check current doze state
  local doze_state=$(dumpsys deviceidle 2>/dev/null | grep -m1 "mState=" | cut -d= -f2)
  
  # Count restricted apps
  local restricted_count=0
  for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
    local state=$(appops get "$pkg" RUN_IN_BACKGROUND 2>/dev/null | grep -o "deny")
    [ "$state" = "deny" ] && restricted_count=$((restricted_count + 1))
  done
  
  echo ""
  echo "═════════════════════════════════════"
  echo "  🔋 Deep Doze Status"
  echo "═════════════════════════════════════"
  echo ""
  echo "  Enabled in config: $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "YES" || echo "NO")"
  echo "  Level: $DEEP_DOZE_LEVEL"
  echo "  Doze state: $doze_state"
  echo "  Apps restricted: $restricted_count"
  echo ""
  echo "  📄 Log: $DEEP_DOZE_LOG"
  echo "  📝 Whitelist: $WHITELIST_FILE"
  echo "═════════════════════════════════════"
  echo ""
}

# MAIN
case "$1" in
  freeze)
    freeze_deep_doze
    ;;
  stock)
    stock_deep_doze
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: deep_doze.sh [freeze|stock|status]"
    ;;
esac

exit 0