#!/system/bin/sh
# 🧊 FROSTY - Main service handler

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
SERVICES_LOG="$LOGDIR/services.log"
ACTION_LOG="$LOGDIR/action.log"
STATE_FILE="$MODDIR/config/state"
GMS_LIST="$MODDIR/config/gms_services.txt"
USER_PREFS="$MODDIR/config/user_prefs"
KERNEL_BACKUP="$MODDIR/backup/kernel_values.txt"
SYSPROP="$MODDIR/system.prop"
SYSPROP_OLD="$MODDIR/system.prop.old"

mkdir -p "$LOGDIR" "$MODDIR/config"

# Timeout fallback
if ! command -v timeout >/dev/null 2>&1; then
  timeout() { shift; "$@"; }
fi

# Dynamic separator width
COLS=$(stty size 2>/dev/null | awk '{print $2}')
case "$COLS" in ''|*[!0-9]*) COLS=40 ;; esac
[ "$COLS" -gt 54 ] && COLS=54
[ "$COLS" -lt 20 ] && COLS=40

_iw=$((COLS - 4))
LINE="" _i=0
while [ $_i -lt $_iw ]; do
  LINE="${LINE}─"
  _i=$((_i + 1))
done
SEP="  $LINE"
BOX_TOP="  ┌${LINE}┐"
BOX_BOT="  └${LINE}┘"
unset _i _iw

log_service() { echo "$1" >> "$SERVICES_LOG"; }
log_action()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$ACTION_LOG"; }

load_prefs() {
  if [ -f "$USER_PREFS" ]; then
    . "$USER_PREFS"
  else
    log_action "WARNING: User preferences not found, using defaults"
    ENABLE_KERNEL_TWEAKS=1; ENABLE_BLUR_DISABLE=0; ENABLE_LOG_KILLING=1
    ENABLE_SYSTEM_PROPS=1
    ENABLE_GMS_DOZE=1; ENABLE_DEEP_DOZE=1; DEEP_DOZE_LEVEL="moderate"
    DISABLE_TELEMETRY=1; DISABLE_BACKGROUND=1; DISABLE_LOCATION=0
    DISABLE_CONNECTIVITY=0; DISABLE_CLOUD=0; DISABLE_PAYMENTS=0
    DISABLE_WEARABLES=0; DISABLE_GAMES=0
  fi
}

load_prefs

get_state() { [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "frozen"; }
set_state()  { echo "$1" > "$STATE_FILE"; chmod 644 "$STATE_FILE"; }

should_disable_category() {
  case "$1" in
    telemetry)    [ "$DISABLE_TELEMETRY" = "1" ] ;;
    background)   [ "$DISABLE_BACKGROUND" = "1" ] ;;
    location)     [ "$DISABLE_LOCATION" = "1" ] ;;
    connectivity) [ "$DISABLE_CONNECTIVITY" = "1" ] ;;
    cloud)        [ "$DISABLE_CLOUD" = "1" ] ;;
    payments)     [ "$DISABLE_PAYMENTS" = "1" ] ;;
    wearables)    [ "$DISABLE_WEARABLES" = "1" ] ;;
    games)        [ "$DISABLE_GAMES" = "1" ] ;;
    *) return 1 ;;
  esac
}

get_user_choice() {
  local timeout_val="${1:-10}"
  local start=$(date +%s)
  while true; do
    local elapsed=$(( $(date +%s) - start ))
    [ $elapsed -ge $timeout_val ] && { echo "timeout"; return; }
    if command -v getevent >/dev/null 2>&1; then
      local event=$(timeout 1 getevent -qlc 1 2>/dev/null)
      echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"   && { echo "up";   return; }
      echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN" && { echo "down"; return; }
    else
      echo "timeout"; return
    fi
    sleep 0.1
  done
}

save_prefs() {
  cat > "$USER_PREFS" << EOF
ENABLE_KERNEL_TWEAKS=$ENABLE_KERNEL_TWEAKS
ENABLE_SYSTEM_PROPS=$ENABLE_SYSTEM_PROPS
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
  log_action "Preferences saved"
}

# Toggle system.prop
apply_system_props() {
  if [ "$ENABLE_SYSTEM_PROPS" = "1" ]; then
    if [ -f "$SYSPROP_OLD" ]; then
      rm -f "$SYSPROP_OLD"
      log_action "System props: deleted .old — module file active on next boot"
    elif [ -f "$SYSPROP" ]; then
      log_action "System props: already active"
    else
      log_action "System props: WARNING — system.prop not found"
    fi
  else
    if [ -f "$SYSPROP" ]; then
      mv "$SYSPROP" "$SYSPROP_OLD"
      log_action "System props: renamed to .old — disabled on next boot"
    elif [ -f "$SYSPROP_OLD" ]; then
      log_action "System props: already disabled"
    else
      log_action "System props: WARNING — system.prop not found"
    fi
  fi
}

interactive_menu() {
  local current=$(get_state)
  log_action "Menu opened (state: $current)"

  echo ""
  echo "  🧊 FROSTY - Configuration Menu"
  echo ""
  echo "  Current: $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo ""
  echo "  Vol+ = ⚙️ CUSTOMIZE"
  echo "  Vol- = 🔥 STOCK (Revert all)"
  echo ""
  echo "  If it crashes try configuring it during installation"
  echo ""

  local choice=$(get_user_choice 15)
  case "$choice" in
    up)      log_action "CUSTOMIZE"; run_customization_wizard ;;
    down)    log_action "STOCK";     stock_services ;;
    timeout) echo "  ⏱️ Timeout"; echo "" ;;
  esac
}

prompt_toggle() {
  local label="$1" current="$2" desc="$3"
  echo "  $label"
  [ -n "$desc" ] && echo "    $desc"
  echo "  Current: $current"
  echo "  Vol+ = ENABLE  |  Vol- = DISABLE"
  echo ""
}

run_customization_wizard() {
  echo "  Starting configuration..."
  echo ""
  sleep 1

  prompt_toggle "🔧 Kernel Tweaks" "$([ "$ENABLE_KERNEL_TWEAKS" = "1" ] && echo "✅" || echo "❌")" "Speeds up task switching, reduces CPU wakeups"
  case $(get_user_choice 10) in
    up)   ENABLE_KERNEL_TWEAKS=1; echo "  → ✅" ;;
    down) ENABLE_KERNEL_TWEAKS=0; echo "  → ❌" ;;
    *)    echo "  → Keeping" ;;
  esac
  sleep 0.5; echo ""

  prompt_toggle "⚙️  System Props" "$([ "$ENABLE_SYSTEM_PROPS" = "1" ] && echo "✅" || echo "❌")" "Disables debug logging, saves battery & RAM"
  case $(get_user_choice 10) in
    up)   ENABLE_SYSTEM_PROPS=1; echo "  → ✅" ;;
    down) ENABLE_SYSTEM_PROPS=0; echo "  → ❌" ;;
    *)    echo "  → Keeping" ;;
  esac
  sleep 0.5; echo ""

  prompt_toggle "🎨 UI Blur Disable" "$([ "$ENABLE_BLUR_DISABLE" = "1" ] && echo "✅" || echo "❌")" "Reduces GPU load, smoother on weaker devices"
  case $(get_user_choice 10) in
    up)   ENABLE_BLUR_DISABLE=1; echo "  → ✅" ;;
    down) ENABLE_BLUR_DISABLE=0; echo "  → ❌" ;;
    *)    echo "  → Keeping" ;;
  esac
  sleep 0.5; echo ""

  prompt_toggle "📝 Log Process Killing" "$([ "$ENABLE_LOG_KILLING" = "1" ] && echo "✅" || echo "❌")" "Stops background loggers, frees RAM"
  case $(get_user_choice 10) in
    up)   ENABLE_LOG_KILLING=1; echo "  → ✅" ;;
    down) ENABLE_LOG_KILLING=0; echo "  → ❌" ;;
    *)    echo "  → Keeping" ;;
  esac
  sleep 0.5; echo ""

  prompt_toggle "🔋 Deep Doze" "$([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "✅ $DEEP_DOZE_LEVEL" || echo "❌")" "Restricts background activity for all apps"
  case $(get_user_choice 10) in
    up)
      ENABLE_DEEP_DOZE=1; echo "  → ✅"
      echo ""
      echo "  Level: Vol+ = MAXIMUM 💀 | Vol- = MODERATE ⚡"
      echo ""
      case $(get_user_choice 10) in
        up)   DEEP_DOZE_LEVEL="maximum";  echo "  → MAXIMUM 💀" ;;
        down) DEEP_DOZE_LEVEL="moderate"; echo "  → MODERATE ⚡" ;;
        *)    echo "  → Keeping: $DEEP_DOZE_LEVEL" ;;
      esac
      ;;
    down) ENABLE_DEEP_DOZE=0; echo "  → ❌" ;;
    *)    echo "  → Keeping" ;;
  esac
  sleep 0.5; echo ""

  prompt_toggle "💤 GMS Doze" "$([ "$ENABLE_GMS_DOZE" = "1" ] && echo "✅" || echo "❌")" "Lets Android optimize GMS battery usage · May delay notifications"
  case $(get_user_choice 10) in
    up)   ENABLE_GMS_DOZE=1; echo "  → ✅" ;;
    down) ENABLE_GMS_DOZE=0; echo "  → ❌" ;;
    *)    echo "  → Keeping" ;;
  esac
  sleep 0.5; echo ""

  echo "  🧊 GMS CATEGORIES (Vol+ = Freeze | Vol- = Keep)"
  echo ""

  while IFS=: read -r _id cat_label cat_var; do
    eval "current_val=\$$cat_var"
    echo "$SEP"
    echo "  $cat_label"
    echo "  Current: $([ "$current_val" = "1" ] && echo "🧊" || echo "🔥")"
    echo ""
    case $(get_user_choice 10) in
      up)   eval "$cat_var=1"; echo "  → 🧊 FREEZE" ;;
      down) eval "$cat_var=0"; echo "  → 🔥 KEEP" ;;
      *)    echo "  → Keeping" ;;
    esac
    sleep 0.5; echo ""
  done << 'CATEGORIES'
1:📊 TELEMETRY (Ads, Analytics):DISABLE_TELEMETRY
2:🔄 BACKGROUND (Updates, Font sync, MDM):DISABLE_BACKGROUND
3:📍 LOCATION (GPS - BREAKS Maps!):DISABLE_LOCATION
4:📡 CONNECTIVITY (Cast, Quick Share):DISABLE_CONNECTIVITY
5:☁️  CLOUD (Auth, Autofill - BREAKS Sign-in!):DISABLE_CLOUD
6:💳 PAYMENTS (Google Pay):DISABLE_PAYMENTS
7:⌚ WEARABLES (Wear OS, Fit):DISABLE_WEARABLES
8:🎮 GAMES (Play Games):DISABLE_GAMES
CATEGORIES

  echo "  📋 SUMMARY"
  echo "  Kernel: $([ "$ENABLE_KERNEL_TWEAKS" = "1" ] && echo "✅" || echo "❌")  Props: $([ "$ENABLE_SYSTEM_PROPS" = "1" ] && echo "✅" || echo "❌")  Blur: $([ "$ENABLE_BLUR_DISABLE" = "1" ] && echo "✅" || echo "❌")  Logs: $([ "$ENABLE_LOG_KILLING" = "1" ] && echo "✅" || echo "❌")"
  echo "  Deep Doze: $([ "$ENABLE_DEEP_DOZE" = "1" ] && echo "$DEEP_DOZE_LEVEL" || echo "❌")  GMS Doze: $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "💤" || echo "❌")"
  echo "  Telemetry:$([ "$DISABLE_TELEMETRY" = "1" ] && echo "🧊" || echo "🔥") Background:$([ "$DISABLE_BACKGROUND" = "1" ] && echo "🧊" || echo "🔥") Location:$([ "$DISABLE_LOCATION" = "1" ] && echo "🧊" || echo "🔥") Connectivity:$([ "$DISABLE_CONNECTIVITY" = "1" ] && echo "🧊" || echo "🔥")"
  echo "  Cloud:$([ "$DISABLE_CLOUD" = "1" ] && echo "🧊" || echo "🔥") Payments:$([ "$DISABLE_PAYMENTS" = "1" ] && echo "🧊" || echo "🔥") Wearables:$([ "$DISABLE_WEARABLES" = "1" ] && echo "🧊" || echo "🔥") Games:$([ "$DISABLE_GAMES" = "1" ] && echo "🧊" || echo "🔥")"
  echo ""
  echo "  Vol+ = APPLY  |  Vol- = CANCEL"
  echo ""

  case $(get_user_choice 15) in
    up)
      log_action "Applying settings"
      save_prefs
      apply_system_props
      freeze_services
      ;;
    *)
      log_action "Cancelled"
      echo "  ❌ Cancelled"
      echo ""
      load_prefs
      ;;
  esac
}

freeze_services() {
  log_action "FREEZE mode"
  echo "Frosty Services - FREEZE $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  log_service "Device: $(getprop ro.product.model) Android $(getprop ro.build.version.release)"
  log_service ""

  if [ ! -f "$GMS_LIST" ]; then
    log_action "ERROR: gms_services.txt not found"
    echo "ERROR: Service list not found!"
    return 1
  fi

  local current_category="" count_ok=0 count_fail=0 count_skip=0 count_enabled=0

  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in \#*|"") continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    [ -z "$category" ] && continue

    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      log_service "--- $category ---"
    fi

    if should_disable_category "$category"; then
      if pm disable "$service" >/dev/null 2>&1; then
        log_service "[OK] $service"
        count_ok=$((count_ok + 1))
      else
        log_service "[FAIL] $service"
        count_fail=$((count_fail + 1))
      fi
    else
      if pm enable "$service" >/dev/null 2>&1; then
        log_service "[ENABLE] $service"
        count_enabled=$((count_enabled + 1))
      else
        log_service "[SKIP] $service"
        count_skip=$((count_skip + 1))
      fi
    fi
  done < "$GMS_LIST"

  set_state "frozen"
  log_action "FROZEN: $count_ok disabled, $count_enabled re-enabled, $count_skip skipped, $count_fail failed"

  echo ""
  echo "  🧊 FROZEN MODE"
  echo "  Disabled: $count_ok  Re-enabled: $count_enabled  Failed: $count_fail"
  echo ""

  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    chmod +x "$MODDIR/gms_doze.sh"
    "$MODDIR/gms_doze.sh" apply
  fi

  if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
    chmod +x "$MODDIR/deep_doze.sh"
    "$MODDIR/deep_doze.sh" freeze
  fi

  if [ "$ENABLE_LOG_KILLING" = "1" ]; then
    for svc in logcat logcatd logd tcpdump cnss_diag statsd traced; do
      pid=$(pidof "$svc" 2>/dev/null)
      [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null
    done
    echo "  📝 Logs killed"
  fi

  echo ""
}

stock_services() {
  log_action "STOCK mode"
  echo "Frosty Services - STOCK $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  log_service "Device: $(getprop ro.product.model) Android $(getprop ro.build.version.release)"
  log_service ""

  if [ ! -f "$GMS_LIST" ]; then
    log_action "ERROR: gms_services.txt not found"
    echo "ERROR: Service list not found!"
    return 1
  fi

  local current_category="" count_ok=0 count_fail=0

  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in \#*|"") continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    [ -z "$category" ] && continue

    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      log_service "--- $category ---"
    fi

    if pm enable "$service" >/dev/null 2>&1; then
      log_service "[OK] $service"
      count_ok=$((count_ok + 1))
    else
      log_service "[FAIL] $service"
      count_fail=$((count_fail + 1))
    fi
  done < "$GMS_LIST"

  set_state "stock"
  log_action "STOCK: $count_ok enabled, $count_fail failed"

  echo ""
  echo "  🔥 STOCK MODE"
  echo "  Re-enabled: $count_ok  Failed: $count_fail"
  echo ""

  # Restore kernel values
  if [ -f "$KERNEL_BACKUP" ]; then
    echo "  Restoring kernel values..."
    local kcount=0
    while IFS= read -r line; do
      case "$line" in \#*|"") continue ;; esac
      name=$(echo "$line" | cut -d= -f1)
      val=$(echo "$line" | cut -d= -f2)
      path=$(echo "$line" | cut -d= -f3-)
      [ -z "$path" ] && continue
      if [ -f "$path" ]; then
        chmod +w "$path" 2>/dev/null
        echo "$val" > "$path" 2>/dev/null && kcount=$((kcount + 1))
      fi
    done < "$KERNEL_BACKUP"
    echo "  ✓ Kernel values restored ($kcount)"
    log_action "Kernel values restored from backup ($kcount values)"
  else
    echo "  Kernel tweaks revert on reboot"
  fi

  # Revert GMS Doze
  chmod +x "$MODDIR/gms_doze.sh"
  "$MODDIR/gms_doze.sh" revert

  # Revert Deep Doze
  chmod +x "$MODDIR/deep_doze.sh"
  "$MODDIR/deep_doze.sh" stock
}

toggle() {
  local current=$(get_state)
  log_action "Toggle (state: $current)"

  echo ""
  echo "  🧊 FROSTY - Mode Toggle"
  echo "  Current: $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo ""
  echo "  Vol+ = 🧊 FROZEN  |  Vol- = 🔥 STOCK"
  echo ""

  case $(get_user_choice 10) in
    up)      freeze_services ;;
    down)    stock_services ;;
    timeout) echo "  ⏱️ Timeout"; echo "" ;;
  esac
}

status() {
  local current=$(get_state)
  local props_status
  if [ -f "$SYSPROP" ]; then
    props_status="✅ active"
  elif [ -f "$SYSPROP_OLD" ]; then
    props_status="❌ disabled"
  else
    props_status="⚠️  missing"
  fi

  echo ""
  echo "  🧊 FROSTY Status"
  echo "  State:      $([ "$current" = "frozen" ] && echo "🧊 FROZEN" || echo "🔥 STOCK")"
  echo "  GMS Doze:   $([ "$ENABLE_GMS_DOZE" = "1" ]      && echo "💤" || echo "❌")"
  echo "  Deep Doze:  $([ "$ENABLE_DEEP_DOZE" = "1" ]     && echo "🔋 $DEEP_DOZE_LEVEL" || echo "❌")"
  echo "  Sys Props:  $props_status"
  echo ""
}

case "$1" in
  freeze)           freeze_services ;;
  stock)            stock_services ;;
  toggle)           toggle ;;
  interactive|"")   interactive_menu ;;
  status)           status ;;
  apply_sysprops)   apply_system_props ;;
  *)                echo "Usage: frosty.sh [freeze|stock|toggle|interactive|status|apply_sysprops]" ;;
esac

exit 0
