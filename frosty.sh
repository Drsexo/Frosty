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
if [ -f "$USER_PREFS" ]; then
  . "$USER_PREFS"
else
  log_action "WARNING: User preferences not found, using defaults"
  DISABLE_TELEMETRY=1
  DISABLE_BACKGROUND=1
  DISABLE_LOCATION=0
  DISABLE_CONNECTIVITY=0
  DISABLE_CLOUD=0
  DISABLE_PAYMENTS=0
  DISABLE_WEARABLES=0
  DISABLE_GAMES=0
  ENABLE_GMS_DOZE=0
fi

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

get_user_choice() {
  local timeout=10
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
        echo "frozen"
        return
      elif echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
        echo "stock"
        return
      fi
    fi
    
    sleep 0.3
  done
}

# Log device info
log_device_info() {
  log_service "Device: $(getprop ro.product.model) ($(getprop ro.product.device))"
  log_service "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
  log_service "Kernel: $(uname -r)"
  log_service ""
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
  echo "═════════════════════════════════════"
  echo "  🧊 FROSTY: FROZEN MODE ACTIVATED"
  echo ""
  echo "  Disabled: $count_ok services"
  echo "  Skipped:  $count_skip (kept enabled per config)"
  echo "  Failed:   $count_fail (service may not exist)"
  echo ""
  echo "  📄 Details: $SERVICES_LOG"
  echo "═════════════════════════════════════"
  echo ""
  
  # Apply GMS Doze
  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    chmod +x "$MODDIR/doze.sh" 2>/dev/null
    "$MODDIR/doze.sh" freeze
  fi
}

# STOCK MODE
stock_services() {
  log_action "Entering STOCK mode"
  
  echo "═════════════════════════════════════" > "$SERVICES_LOG"
  echo "🔥 FROSTY Services Log - STOCK (Enable) Operation" >> "$SERVICES_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SERVICES_LOG"
  echo "═════════════════════════════════════" >> "$SERVICES_LOG"
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
  echo "═════════════════════════════════════"
  echo "  🔥 FROSTY: STOCK MODE ACTIVATED"
  echo ""
  echo "  Re-enabled: $count_ok services"
  echo "  Failed:     $count_fail"
  echo ""
  echo "  ⚠️  Kernel tweaks require REBOOT to revert!"
  echo ""
  echo "  📄 Details: $SERVICES_LOG"
  echo "═════════════════════════════════════"
  echo ""
  
  # Revert GMS Doze
  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    chmod +x "$MODDIR/doze.sh" 2>/dev/null
    "$MODDIR/doze.sh" stock
  fi
}

# TOGGLE MODE
toggle() {
  local current=$(get_state)
  
  log_action "Action button pressed (current state: $current)"
  
  echo ""
  echo "═════════════════════════════════════"
  echo "  🧊 FROSTY - Mode Toggle"
  echo ""
  echo "  Current: $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo "═════════════════════════════════════"
  echo ""
  echo "  🔼 Vol+ = 🧊 FROZEN (Disable services)"
  echo "  🔽 Vol- = 🔥 STOCK  (Enable services)"
  echo ""
  echo "  Waiting for input (10s timeout)..."
  echo ""
  
  local choice=$(get_user_choice)
  
  case "$choice" in
    frozen)
      log_action "User selected: FROZEN"
      echo "  Please wait..."
      freeze_services
      ;;
    stock)
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
  echo "═════════════════════════════════════"
  echo "  🧊 FROSTY Status"
  echo "═════════════════════════════════════"
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
  echo "  GMS Doze: $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "💤 Enabled" || echo "❌ Disabled")"
  echo ""
  echo "  Logs: $LOGDIR/"
  echo "═════════════════════════════════════"
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
  
  echo ""
  echo "═════════════════════════════════════"
  echo "  🧊 FROSTY STATUS REPORT"
  echo "═════════════════════════════════════"
  echo ""
  echo "  State:    $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo "  Battery:  ${battery}%"
  echo "  Uptime:   $uptime_str"
  echo ""
  echo "  ─────────────────────────────────────"
  echo "  Services"
  echo "  ─────────────────────────────────────"
  echo "  Disabled: $disabled_count"
  echo "  Skipped:  $skipped_count"
  echo "  Failed:   $failed_count"
  echo ""
  echo "  ─────────────────────────────────────"
  echo "  GMS Doze"
  echo "  ─────────────────────────────────────"
  echo "  Enabled:  $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "Yes" || echo "No")"
  echo "  Active:   $gms_doze_active"
  echo ""
  echo "  ─────────────────────────────────────"
  echo "  Categories (🧊=Frozen  🔥=Active)"
  echo "  ─────────────────────────────────────"
  echo "  $([ "$DISABLE_TELEMETRY" = "1" ] && echo "🧊" || echo "🔥") Telemetry      $([ "$DISABLE_BACKGROUND" = "1" ] && echo "🧊" || echo "🔥") Background"
  echo "  $([ "$DISABLE_LOCATION" = "1" ] && echo "🧊" || echo "🔥") Location       $([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "🧊" || echo "🔥") Connectivity"
  echo "  $([ "$DISABLE_CLOUD" = "1" ] && echo "🧊" || echo "🔥") Cloud          $([ "$DISABLE_PAYMENTS" = "1" ] && echo "🧊" || echo "🔥") Payments"
  echo "  $([ "$DISABLE_WEARABLES" = "1" ] && echo "🧊" || echo "🔥") Wearables      $([ "$DISABLE_GAMES" = "1" ] && echo "🧊" || echo "🔥") Games"
  echo ""
  echo "  ─────────────────────────────────────"
  echo "  Device"
  echo "  ─────────────────────────────────────"
  echo "  $(getprop ro.product.model)"
  echo "  Android $(getprop ro.build.version.release)"
  echo ""
  echo "═════════════════════════════════════"
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
  toggle|"")
    toggle
    ;;
  status)
    status
    ;;
  report)
    report
    ;;
  *)
    echo "Usage: frosty.sh [freeze|stock|toggle|status|report]"
    ;;
esac

exit 0