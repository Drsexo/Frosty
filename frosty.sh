#!/system/bin/sh
# 🧊 FROSTY - Main service handler
# Handles Frozen/Stock mode toggling with detailed logging

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
SERVICES_LOG="$LOGDIR/services.log"
ACTION_LOG="$LOGDIR/action.log"
STATE_FILE="$MODDIR/config/state"
GMS_LIST="$MODDIR/config/gms_services.txt"
USER_PREFS="$MODDIR/config/user_prefs"

# Initialize
mkdir -p "$LOGDIR" "$MODDIR/config"

log_service() {
  echo "$1" >> "$SERVICES_LOG"
}

log_action() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ACTION_LOG"
}

# Load preferences (1=enabled, 0=disabled)
load_prefs() {
  if [ -f "$USER_PREFS" ]; then
    . "$USER_PREFS"
  else
    log_action "WARNING: User preferences not found, using defaults"
    ENABLE_KERNEL_TWEAKS=1
    ENABLE_BLUR_DISABLE=0
    ENABLE_LOG_KILLING=1
    ENABLE_GMS_DOZE=0
    ENABLE_DEEP_DOZE=0
    DEEP_DOZE_LEVEL="moderate"
    DISABLE_TELEMETRY=1
    DISABLE_BACKGROUND=1
    DISABLE_LOCATION=0
    DISABLE_CONNECTIVITY=0
    DISABLE_CLOUD=0
    DISABLE_PAYMENTS=0
    DISABLE_WEARABLES=0
    DISABLE_GAMES=0
  fi
}

load_prefs

# Helper Functions
get_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo "frozen"
  fi
}

set_state() {
  echo "$1" > "$STATE_FILE"
  chmod 644 "$STATE_FILE"
}

should_disable_category() {
  local category="$1"
  case "$category" in
    telemetry)    [ "$DISABLE_TELEMETRY" = "1" ] && return 0 ;;
    background)   [ "$DISABLE_BACKGROUND" = "1" ] && return 0 ;;
    location)     [ "$DISABLE_LOCATION" = "1" ] && return 0 ;;
    connectivity) [ "$DISABLE_CONNECTIVITY" = "1" ] && return 0 ;;
    cloud)        [ "$DISABLE_CLOUD" = "1" ] && return 0 ;;
    payments)     [ "$DISABLE_PAYMENTS" = "1" ] && return 0 ;;
    wearables)    [ "$DISABLE_WEARABLES" = "1" ] && return 0 ;;
    games)        [ "$DISABLE_GAMES" = "1" ] && return 0 ;;
  esac
  return 1
}

# Volume key selection with timeout
get_user_choice() {
  local timeout="${1:-10}"
  local start=$(date +%s)
  
  while true; do
    local now=$(date +%s)
    local elapsed=$((now - start))
    
    if [ $elapsed -ge $timeout ]; then
      echo "timeout"
      return
    fi
    
    if command -v getevent >/dev/null 2>&1; then
      local event=$(timeout 1 getevent -qlc 1 2>/dev/null)
      if echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"; then
        echo "up"
        return
      elif echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
        echo "down"
        return
      fi
    fi
    
    sleep 0.1
  done
}

# Print separator
print_sep() {
  echo "═════════════════════════════════════════════"
}

# Print menu header
print_header() {
  echo ""
  print_sep
  echo "  $1"
  print_sep
  echo ""
}

# Save user preferences to file
save_prefs() {
  cat > "$USER_PREFS" << EOF
# Frosty User Preferences
# Generated: $(date)
# System Tweaks (1=enabled, 0=disabled)
ENABLE_KERNEL_TWEAKS=$ENABLE_KERNEL_TWEAKS
ENABLE_BLUR_DISABLE=$ENABLE_BLUR_DISABLE
ENABLE_LOG_KILLING=$ENABLE_LOG_KILLING
ENABLE_GMS_DOZE=$ENABLE_GMS_DOZE
ENABLE_DEEP_DOZE=$ENABLE_DEEP_DOZE
DEEP_DOZE_LEVEL=$DEEP_DOZE_LEVEL
DISABLE_TELEMETRY=$DISABLE_TELEMETRY
DISABLE_BACKGROUND=$DISABLE_BACKGROUND
DISABLE_LOCATION=$DISABLE_LOCATION
DISABLE_CONNECTIVITY=$DISABLE_CONNECTIVITY
DISABLE_CLOUD=$DISABLE_CLOUD
DISABLE_PAYMENTS=$DISABLE_PAYMENTS
DISABLE_WEARABLES=$DISABLE_WEARABLES
DISABLE_GAMES=$DISABLE_GAMES
EOF
  chmod 644 "$USER_PREFS"
  log_action "User preferences saved"
}

# Log device info
log_device_info() {
  log_service "Device: $(getprop ro.product.model) ($(getprop ro.product.device))"
  log_service "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
  log_service "Kernel: $(uname -r)"
  log_service ""
}

# INTERACTIVE MENU SYSTEM
interactive_menu() {
  local current=$(get_state)
  
  log_action "Interactive menu opened (current state: $current)"
  
  print_header "🧊 FROSTY - Configuration Menu"
  
  echo "  Current State: $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo ""
  echo "  🔼 Vol+ = ⚙️ CUSTOMIZE (Configure all options)"
  echo "  🔽 Vol- = 🔥 STOCK (Revert all changes)"
  echo ""
  echo "  Waiting for input (15s timeout)..."
  echo ""
  
  local choice=$(get_user_choice 15)
  
  case "$choice" in
    up)
      log_action "User selected: CUSTOMIZE"
      run_customization_wizard
      ;;
    down)
      log_action "User selected: STOCK (revert all)"
      echo "  Reverting all changes..."
      stock_services
      ;;
    timeout)
      log_action "Timeout - no action taken"
      echo "  ⏱️ Timeout - no changes made"
      echo ""
      ;;
  esac
}

run_customization_wizard() {
  echo ""
  echo "  Starting configuration wizard..."
  echo ""
  sleep 1
  
  # SYSTEM TWEAKS
  print_header "⚙️ SYSTEM TWEAKS"
  
  # Kernel Tweaks
  echo "  🔧 Kernel Tweaks"
  echo "     (Scheduler, VM, Network optimizations)"
  echo ""
  echo "     Current: $([ "$ENABLE_KERNEL_TWEAKS" = "1" ] && echo "✅ ENABLED" || echo "❌ DISABLED")"
  echo ""
  echo "  🔼 Vol+ = ENABLE  |  🔽 Vol- = DISABLE"
  echo ""
  
  local choice=$(get_user_choice 10)
  case "$choice" in
    up) ENABLE_KERNEL_TWEAKS=1; echo "  → ENABLED ✅" ;;
    down) ENABLE_KERNEL_TWEAKS=0; echo "  → DISABLED ❌" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Blur Disable
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  🎨 UI Blur Disable"
  echo "     (Reduce GPU load by disabling blur effects)"
  echo ""
  echo "     Current: $([ "$ENABLE_BLUR_DISABLE" = "1" ] && echo "✅ ENABLED" || echo "❌ DISABLED")"
  echo ""
  echo "  🔼 Vol+ = ENABLE  |  🔽 Vol- = DISABLE"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) ENABLE_BLUR_DISABLE=1; echo "  → ENABLED ✅" ;;
    down) ENABLE_BLUR_DISABLE=0; echo "  → DISABLED ❌" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Log Killing
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  📝 Log Process Killing"
  echo "     (Stop logcat, logd, traced, etc.)"
  echo ""
  echo "     Current: $([ "$ENABLE_LOG_KILLING" = "1" ] && echo "✅ ENABLED" || echo "❌ DISABLED")"
  echo ""
  echo "  🔼 Vol+ = ENABLE  |  🔽 Vol- = DISABLE"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) ENABLE_LOG_KILLING=1; echo "  → ENABLED ✅" ;;
    down) ENABLE_LOG_KILLING=0; echo "  → DISABLED ❌" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # DEEP DOZE
  print_header "🔋 DEEP DOZE"
  
  echo "  Deep system-wide doze for ALL apps"
  echo "  (Aggressive battery optimization)"
  echo ""
  echo "  Current: $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "✅ ENABLED ($DEEP_DOZE_LEVEL)" || echo "❌ DISABLED")"
  echo ""
  echo "  🔼 Vol+ = ENABLE  |  🔽 Vol- = DISABLE"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up)
      ENABLE_DEEP_DOZE=1
      echo "  → ENABLED ✅"
      echo ""
      sleep 0.5
      
      # Deep Doze Level
      echo "  ─────────────────────────────────────────"
      echo ""
      echo "  📊 Deep Doze Level"
      echo ""
      echo "  MAXIMUM: 💀"
      echo "    • All MODERATE features +"
      echo "    • Deny WAKE_LOCK"
      echo "    • Network lockdown"
      echo "    • Sensor freeze"
      echo "    • Wakelock killer"
      echo "    • Alarm restrictions"
      echo ""
      echo "  MODERATE: ⚡️"
      echo "    • Aggressive doze constants"
      echo "    • App standby restrictions"
      echo "    • Deny RUN_IN_BACKGROUND"
      echo ""
      echo "  Current: $DEEP_DOZE_LEVEL"
      echo ""
      echo "  🔼 Vol+ = MAXIMUM 💀 |  🔽 Vol- = MODERATE ⚡️"
      echo ""
      
      choice=$(get_user_choice 10)
      case "$choice" in
        up) DEEP_DOZE_LEVEL="maximum"; echo "  → MAXIMUM 💀" ;;
        down) DEEP_DOZE_LEVEL="moderate"; echo "  → MODERATE ⚡" ;;
        *) 
          if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
            echo "  → Keeping: 💀 maximum"
          else
            echo "  → Keeping: ⚡ moderate"
          fi
          ;;
      esac
      ;;
    down)
      ENABLE_DEEP_DOZE=0
      echo "  → DISABLED ❌"
      ;;
    *)
      echo "  → Keeping current setting"
      ;;
  esac
  sleep 0.5
  
  # GMS DOZE
  print_header "💤 GMS DOZE"
  
  echo "  Allow Android to optimize GMS battery"
  echo "  (Removes GMS from doze whitelist)"
  echo ""
  echo "  May slightly delay notifications"
  echo ""
  echo "  Current: $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "✅ ENABLED" || echo "❌ DISABLED")"
  echo ""
  echo "  🔼 Vol+ = ENABLE  |  🔽 Vol- = DISABLE"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) ENABLE_GMS_DOZE=1; echo "  → ENABLED ✅" ;;
    down) ENABLE_GMS_DOZE=0; echo "  → DISABLED ❌" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # GMS CATEGORIES
  print_header "🧊 GMS SERVICE CATEGORIES"
  
  echo "  Choose which GMS services to FREEZE"
  echo "  (🧊 = Freeze, 🔥 = Keep enabled)"
  echo ""
  sleep 0.5
  
  # Telemetry
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  📊 TELEMETRY"
  echo "     Ads, Analytics, Tracking, Check-in"
  echo "     (Safe to freeze - just stops data collection)"
  echo ""
  echo "     Current: $([ "$DISABLE_TELEMETRY" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_TELEMETRY=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_TELEMETRY=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Background
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  🔄 BACKGROUND"
  echo "     Updates, Chimera, MDM services"
  echo "     (Safe - may delay auto-updates)"
  echo ""
  echo "     Current: $([ "$DISABLE_BACKGROUND" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_BACKGROUND=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_BACKGROUND=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Location
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  📍 LOCATION"
  echo "     GPS, Fused Location, Geofence"
  echo "     BREAKS: Maps, Navigation, Find My Device!"
  echo ""
  echo "     Current: $([ "$DISABLE_LOCATION" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_LOCATION=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_LOCATION=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Connectivity
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  📡 CONNECTIVITY"
  echo "     Cast, Nearby, Quick Share, Fast Pair"
  echo "     BREAKS: Chromecast, file sharing!"
  echo ""
  echo "     Current: $([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_CONNECTIVITY=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_CONNECTIVITY=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Cloud
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  ☁️  CLOUD"
  echo "     Auth, Sync, Backup, Smart Lock"
  echo "     BREAKS: Google Sign-in, backups!"
  echo ""
  echo "     Current: $([ "$DISABLE_CLOUD" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_CLOUD=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_CLOUD=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Payments
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  💳 PAYMENTS"
  echo "     Google Pay, Wallet, Tap-and-Pay"
  echo "     BREAKS: NFC payments!"
  echo ""
  echo "     Current: $([ "$DISABLE_PAYMENTS" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_PAYMENTS=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_PAYMENTS=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Wearables
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  ⌚ WEARABLES"
  echo "     Wear OS, Google Fit, Health tracking"
  echo "     BREAKS: Smartwatch sync, fitness apps!"
  echo ""
  echo "     Current: $([ "$DISABLE_WEARABLES" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_WEARABLES=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_WEARABLES=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # Games
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  🎮 GAMES"
  echo "     Play Games, Achievements, Cloud saves"
  echo "     BREAKS: Game progress sync!"
  echo ""
  echo "     Current: $([ "$DISABLE_GAMES" = "1" ] && echo "🧊 FROZEN" || echo "🔥 ENABLED")"
  echo ""
  echo "  🔼 Vol+ = 🧊 FREEZE  |  🔽 Vol- = 🔥 KEEP"
  echo ""
  
  choice=$(get_user_choice 10)
  case "$choice" in
    up) DISABLE_GAMES=1; echo "  → 🧊 FROZEN" ;;
    down) DISABLE_GAMES=0; echo "  → 🔥 KEEP ENABLED" ;;
    *) echo "  → Keeping current setting" ;;
  esac
  sleep 0.5
  
  # SUMMARY & APPLY
  print_header "📋 CONFIGURATION SUMMARY"
  
  echo "  System Tweaks:"
  echo "    Kernel Tweaks:  $([ "$ENABLE_KERNEL_TWEAKS" = "1" ] && echo "✅" || echo "❌")"
  echo "    Blur Disable:   $([ "$ENABLE_BLUR_DISABLE" = "1" ] && echo "✅" || echo "❌")"
  echo "    Log Killing:    $([ "$ENABLE_LOG_KILLING" = "1" ] && echo "✅" || echo "❌")"
  echo ""
  echo "  Doze Settings:"
  echo "    Deep Doze:      $([ "$ENABLE_DEEP_DOZE" = "1" ] && { [ "$DEEP_DOZE_LEVEL" = "maximum" ] && echo "💀 maximum" || echo "⚡ moderate"; } || echo "❌")"
  echo "    GMS Doze:       $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "💤" || echo "❌")"
  echo ""
  echo "  GMS Categories (🧊=Freeze 🔥=Keep):"
  echo "    Telemetry:    $([ "$DISABLE_TELEMETRY" = "1" ] && echo "🧊" || echo "🔥")  Background:   $([ "$DISABLE_BACKGROUND" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Location:     $([ "$DISABLE_LOCATION" = "1" ] && echo "🧊" || echo "🔥")  Connectivity: $([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Cloud:        $([ "$DISABLE_CLOUD" = "1" ] && echo "🧊" || echo "🔥")  Payments:     $([ "$DISABLE_PAYMENTS" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Wearables:    $([ "$DISABLE_WEARABLES" = "1" ] && echo "🧊" || echo "🔥")  Games:        $([ "$DISABLE_GAMES" = "1" ] && echo "🧊" || echo "🔥")"
  echo ""
  echo "  ─────────────────────────────────────────"
  echo ""
  echo "  🔼 Vol+ = ✅ APPLY SETTINGS"
  echo "  🔽 Vol- = ❌ CANCEL (discard changes)"
  echo ""
  echo "  Waiting for confirmation (15s)..."
  echo ""
  
  choice=$(get_user_choice 15)
  
  case "$choice" in
    up)
      log_action "User confirmed: Applying new settings"
      echo "  Saving configuration..."
      save_prefs
      echo "  Applying changes..."
      echo ""
      freeze_services
      ;;
    down|timeout)
      log_action "User cancelled customization"
      echo ""
      echo "  ❌ Cancelled - no changes made"
      echo ""
      # Reload original prefs
      load_prefs
      ;;
  esac
}

# FREEZE MODE
freeze_services() {
  log_action "Entering FROZEN mode"
  
  echo "═════════════════════════════════════" > "$SERVICES_LOG"
  echo "🧊 FROSTY Services Log - FREEZE Operation" >> "$SERVICES_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SERVICES_LOG"
  echo "═════════════════════════════════════" >> "$SERVICES_LOG"
  echo "" >> "$SERVICES_LOG"
  
  log_device_info
  
  # Log user preferences
  log_service "User Preferences:"
  log_service "  Telemetry:    $([ "$DISABLE_TELEMETRY" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Background:   $([ "$DISABLE_BACKGROUND" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Location:     $([ "$DISABLE_LOCATION" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Connectivity: $([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Cloud:        $([ "$DISABLE_CLOUD" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Payments:     $([ "$DISABLE_PAYMENTS" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Wearables:    $([ "$DISABLE_WEARABLES" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service "  Games:        $([ "$DISABLE_GAMES" = "1" ] && echo "FREEZE" || echo "keep")"
  log_service ""
  
  if [ ! -f "$GMS_LIST" ]; then
    log_action "ERROR: gms_services.txt not found at $GMS_LIST"
    log_service "[ERROR] gms_services.txt not found at $GMS_LIST"
    echo "ERROR: Service list not found!"
    return 1
  fi
  
  local current_category=""
  local count_ok=0
  local count_fail=0
  local count_skip=0
  
  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in
      \#*) 
        if echo "$service" | grep -q "^# ═"; then
          log_service ""
          log_service "$service"
        fi
        continue 
        ;;
      "") continue ;;
    esac
    
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    
    [ -z "$category" ] && continue
    
    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      log_service "━━━ $category ━━━"
    fi
    
    if should_disable_category "$category"; then
      if pm disable "$service" >/dev/null 2>&1; then
        log_service "[OK]   $service"
        count_ok=$((count_ok + 1))
      else
        log_service "[FAIL] $service"
        count_fail=$((count_fail + 1))
      fi
    else
      log_service "[SKIP] $service (category kept enabled)"
      count_skip=$((count_skip + 1))
    fi
  done < "$GMS_LIST"
  
  set_state "frozen"
  
  log_service ""
  log_service "═════════════════════════════════════"
  log_service "SUMMARY"
  log_service "═════════════════════════════════════"
  log_service "  Disabled:  $count_ok"
  log_service "  Skipped:   $count_skip (category kept enabled)"
  log_service "  Failed:    $count_fail (service may not exist)"
  log_service "  Total:     $((count_ok + count_skip + count_fail))"
  log_service ""
  log_service "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  log_service "═════════════════════════════════════"
  
  log_action "FROZEN: $count_ok disabled, $count_skip skipped, $count_fail failed"
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🧊 FROSTY: FROZEN MODE ACTIVATED"
  echo ""
  echo "  Disabled: $count_ok services"
  echo "  Skipped:  $count_skip (kept enabled per config)"
  echo "  Failed:   $count_fail (service may not exist)"
  echo ""
  echo "  📄 Details: $SERVICES_LOG"
  echo "═════════════════════════════════════════════"
  echo ""
  
  # Apply GMS Doze
  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    chmod +x "$MODDIR/gms_doze.sh" 2>/dev/null
    "$MODDIR/gms_doze.sh" freeze
  else
    echo "  💤 GMS Doze: SKIPPED (disabled in config)"
    echo ""
  fi
  
  # Apply Deep Doze
  if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
    chmod +x "$MODDIR/deep_doze.sh" 2>/dev/null
    "$MODDIR/deep_doze.sh" freeze
  else
    echo "  🔋 Deep Doze: SKIPPED (disabled in config)"
    echo ""
  fi
  
  # Apply kernel tweaks if enabled
  if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
    echo "  ⚙️  Kernel Tweaks: Applied (see boot.log for details)"
    echo ""
  fi
  
  # Kill logs if enabled
  if [ "$ENABLE_LOG_KILLING" = "1" ]; then
    for SERVICE in logcat logcatd logd tcpdump cnss_diag statsd traced; do
      pid=$(pidof "$SERVICE" 2>/dev/null)
      [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null
    done
    echo "  📝 Log processes: Killed"
    echo ""
  fi
  
  print_sep
  echo ""
}

# STOCK MODE
stock_services() {
  log_action "Entering STOCK mode"
  
  echo "═════════════════════════════════════════════" > "$SERVICES_LOG"
  echo "🔥 FROSTY Services Log - STOCK (Enable) Operation" >> "$SERVICES_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SERVICES_LOG"
  echo "═════════════════════════════════════════════" >> "$SERVICES_LOG"
  echo "" >> "$SERVICES_LOG"
  
  log_device_info
  
  if [ ! -f "$GMS_LIST" ]; then
    log_action "ERROR: gms_services.txt not found at $GMS_LIST"
    log_service "[ERROR] gms_services.txt not found at $GMS_LIST"
    echo "ERROR: Service list not found!"
    return 1
  fi
  
  local current_category=""
  local count_ok=0
  local count_fail=0
  
  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in
      \#*) 
        if echo "$service" | grep -q "^# ═"; then
          log_service ""
          log_service "$service"
        fi
        continue 
        ;;
      "") continue ;;
    esac
    
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    
    [ -z "$category" ] && continue
    
    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      log_service "━━━ $category ━━━"
    fi
    
    if pm enable "$service" >/dev/null 2>&1; then
      log_service "[OK]   $service"
      count_ok=$((count_ok + 1))
    else
      log_service "[FAIL] $service"
      count_fail=$((count_fail + 1))
    fi
  done < "$GMS_LIST"
  
  set_state "stock"
  
  log_service ""
  log_service "═════════════════════════════════════"
  log_service "SUMMARY"
  log_service "═════════════════════════════════════"
  log_service "  Enabled:  $count_ok"
  log_service "  Failed:   $count_fail"
  log_service ""
  log_service "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  log_service "═════════════════════════════════════"
  
  log_action "STOCK: $count_ok enabled, $count_fail failed"
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🔥 FROSTY: STOCK MODE ACTIVATED"
  echo ""
  echo "  Re-enabled: $count_ok services"
  echo "  Failed:     $count_fail"
  echo ""
  echo "  ⚠️  Kernel tweaks require REBOOT to revert!"
  echo ""
  echo "  📄 Details: $SERVICES_LOG"
  echo "═════════════════════════════════════════════"
  echo ""
  
  # Revert GMS Doze
  chmod +x "$MODDIR/gms_doze.sh" 2>/dev/null
  "$MODDIR/gms_doze.sh" stock
  
  # Revert Deep Doze
  chmod +x "$MODDIR/deep_doze.sh" 2>/dev/null
  "$MODDIR/deep_doze.sh" stock
}

# LEGACY TOGGLE (for backwards compatibility)
toggle() {
  local current=$(get_state)
  
  log_action "Action button pressed (current state: $current)"
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🧊 FROSTY - Mode Toggle"
  echo ""
  echo "  Current: $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo "═════════════════════════════════════════════"
  echo ""
  echo "  🔼 Vol+ = 🧊 FROZEN (Apply optimization)"
  echo "  🔽 Vol- = 🔥 STOCK   (Revert changes)"
  echo ""
  echo "  Waiting for input (10s timeout)..."
  echo ""
  
  local choice=$(get_user_choice 10)
  
  case "$choice" in
    up)
      log_action "User selected: FROZEN"
      echo "  Please wait..."
      freeze_services
      ;;
    down)
      log_action "User selected: STOCK"
      echo "  Please wait..."
      stock_services
      ;;
    timeout)
      log_action "Timeout - no action taken"
      echo "  ⏱️ Timeout - no changes made"
      echo ""
      ;;
  esac
}

# STATUS
status() {
  local current=$(get_state)
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🧊 FROSTY Status"
  echo "═════════════════════════════════════════════"
  echo ""
  echo "  State: $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo ""
  echo "  GMS Categories:"
  echo "    Telemetry:    $([ "$DISABLE_TELEMETRY" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Background:   $([ "$DISABLE_BACKGROUND" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Location:     $([ "$DISABLE_LOCATION" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Connectivity: $([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Cloud:        $([ "$DISABLE_CLOUD" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Payments:     $([ "$DISABLE_PAYMENTS" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Wearables:    $([ "$DISABLE_WEARABLES" = "1" ] && echo "🧊" || echo "🔥")"
  echo "    Games:        $([ "$DISABLE_GAMES" = "1" ] && echo "🧊" || echo "🔥")"
  echo ""
  echo "  GMS Doze:  $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "💤 Enabled" || echo "❌ Disabled")"
  echo "  Deep Doze: $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "🔋 $DEEP_DOZE_LEVEL" || echo "❌ Disabled")"
  echo ""
  echo "  Logs: $LOGDIR/"
  echo "═════════════════════════════════════════════"
  echo ""
}

# REPORT
report() {
  local current=$(get_state)
  local disabled_count=$(grep -c "^\[OK\]" "$SERVICES_LOG" 2>/dev/null || echo 0)
  local skipped_count=$(grep -c "^\[SKIP\]" "$SERVICES_LOG" 2>/dev/null || echo 0)
  local failed_count=$(grep -c "^\[FAIL\]" "$SERVICES_LOG" 2>/dev/null || echo 0)
  local battery=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "N/A")
  local uptime_sec=$(cat /proc/uptime 2>/dev/null | cut -d' ' -f1 | cut -d'.' -f1)
  
  # Calculate human-readable uptime
  local uptime_str="N/A"
  if [ -n "$uptime_sec" ] && [ "$uptime_sec" -gt 0 ]; then
    local days=$((uptime_sec / 86400))
    local hours=$(((uptime_sec % 86400) / 3600))
    local mins=$(((uptime_sec % 3600) / 60))
    if [ $days -gt 0 ]; then
      uptime_str="${days}d ${hours}h ${mins}m"
    elif [ $hours -gt 0 ]; then
      uptime_str="${hours}h ${mins}m"
    else
      uptime_str="${mins}m"
    fi
  fi
  
  # Check GMS Doze status
  local gms_doze_active="No"
  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    local whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "com.google.android.gms")
    [ -z "$whitelist_check" ] && gms_doze_active="Yes"
  fi
  
  # Check Deep Doze restricted apps count
  local deep_doze_restricted=0
  if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
    for pkg in $(pm list packages -3 2>/dev/null | cut -d: -f2); do
      local state=$(appops get "$pkg" RUN_IN_BACKGROUND 2>/dev/null | grep -o "deny")
      [ "$state" = "deny" ] && deep_doze_restricted=$((deep_doze_restricted + 1))
    done
  fi
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🧊 FROSTY STATUS REPORT"
  echo "═════════════════════════════════════════════"
  echo ""
  echo "  State:    $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo "  Battery:  ${battery}%"
  echo "  Uptime:   $uptime_str"
  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  GMS Services"
  echo "  ─────────────────────────────────────────────"
  echo "  Disabled: $disabled_count"
  echo "  Skipped:  $skipped_count"
  echo "  Failed:   $failed_count"
  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  GMS Doze"
  echo "  ─────────────────────────────────────────────"
  echo "  Enabled:  $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "Yes" || echo "No")"
  echo "  Active:   $gms_doze_active"
  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  Deep Doze"
  echo "  ─────────────────────────────────────────────"
  echo "  Enabled:  $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "Yes" || echo "No")"
  echo "  Level:    $DEEP_DOZE_LEVEL"
  echo "  Apps restricted: $deep_doze_restricted"
  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  Categories (🧊=Frozen  🔥=Active)"
  echo "  ─────────────────────────────────────────────"
  echo "  $([ "$DISABLE_TELEMETRY" = "1" ] && echo "🧊" || echo "🔥") Telemetry      $([ "$DISABLE_BACKGROUND" = "1" ] && echo "🧊" || echo "🔥") Background"
  echo "  $([ "$DISABLE_LOCATION" = "1" ] && echo "🧊" || echo "🔥") Location       $([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "🧊" || echo "🔥") Connectivity"
  echo "  $([ "$DISABLE_CLOUD" = "1" ] && echo "🧊" || echo "🔥") Cloud          $([ "$DISABLE_PAYMENTS" = "1" ] && echo "🧊" || echo "🔥") Payments"
  echo "  $([ "$DISABLE_WEARABLES" = "1" ] && echo "🧊" || echo "🔥") Wearables      $([ "$DISABLE_GAMES" = "1" ] && echo "🧊" || echo "🔥") Games"
  echo ""
  echo "  ─────────────────────────────────────────────"
  echo "  Device"
  echo "  ─────────────────────────────────────────────"
  echo "  $(getprop ro.product.model)"
  echo "  Android $(getprop ro.build.version.release)"
  echo ""
  echo "═════════════════════════════════════════════"
  echo ""
}

# MAIN
case "$1" in
  freeze)
    freeze_services
    ;;
  stock)
    stock_services
    ;;
  toggle)
    toggle
    ;;
  interactive|"")
    interactive_menu
    ;;
  status)
    status
    ;;
  report)
    report
    ;;
  *)
    echo "Usage: frosty.sh [freeze|stock|toggle|interactive|status|report]"
    ;;
esac

exit 0