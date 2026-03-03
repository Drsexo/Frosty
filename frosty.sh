#!/system/bin/sh
# FROSTY - Main service handler

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
SERVICES_LOG="$LOGDIR/services.log"
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

load_prefs() {
  if [ -f "$USER_PREFS" ]; then
    . "$USER_PREFS"
  else
    ENABLE_KERNEL_TWEAKS=0; ENABLE_BLUR_DISABLE=0; ENABLE_LOG_KILLING=0
    ENABLE_SYSTEM_PROPS=0
    ENABLE_GMS_DOZE=0; ENABLE_DEEP_DOZE=0; DEEP_DOZE_LEVEL="moderate"
    DISABLE_TELEMETRY=0; DISABLE_BACKGROUND=0; DISABLE_LOCATION=0
    DISABLE_CONNECTIVITY=0; DISABLE_CLOUD=0; DISABLE_PAYMENTS=0
    DISABLE_WEARABLES=0; DISABLE_GAMES=0
  fi
}

load_prefs

should_disable_category() {
  case "$1" in
    background)   [ "$DISABLE_BACKGROUND" = "1" ] ;;
    telemetry)    [ "$DISABLE_TELEMETRY" = "1" ] ;;
    location)     [ "$DISABLE_LOCATION" = "1" ] ;;
    connectivity)    [ "$DISABLE_CONNECTIVITY" = "1" ] ;;
    cloud)    [ "$DISABLE_CLOUD" = "1" ] ;;
    payments)     [ "$DISABLE_PAYMENTS" = "1" ] ;;
    wearables)    [ "$DISABLE_WEARABLES" = "1" ] ;;
    games)    [ "$DISABLE_GAMES" = "1" ] ;;
    *) return 1 ;;
  esac
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
}

# Toggle system.prop
apply_system_props() {
  if [ "$ENABLE_SYSTEM_PROPS" = "1" ]; then
    if [ -f "$SYSPROP_OLD" ]; then
      mv "$SYSPROP_OLD" "$SYSPROP"
    fi
  else
    if [ -f "$SYSPROP" ]; then
      mv "$SYSPROP" "$SYSPROP_OLD"
    fi
  fi
}

freeze_services() {
  echo "Frosty Services - FREEZE $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  log_service "Device: $(getprop ro.product.model) Android $(getprop ro.build.version.release)"
  log_service ""

  if [ ! -f "$GMS_LIST" ]; then
      echo "ERROR: Service list not found! Reinstall"
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

  echo ""
  echo "  🧊 GMS FROZEN"
  echo "  Disabled: $count_ok  Re-enabled: $count_enabled  Failed: $count_fail"
  echo ""

  # Apply GMS Doze
  if [ "$ENABLE_GMS_DOZE" = "1" ]; then
    chmod +x "$MODDIR/gms_doze.sh"
    "$MODDIR/gms_doze.sh" apply
  fi

  # Apply Deep Doze
  if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
    chmod +x "$MODDIR/deep_doze.sh"
    "$MODDIR/deep_doze.sh" freeze
  fi

  # Kill log processes
  if [ "$ENABLE_LOG_KILLING" = "1" ]; then
    for svc in logcat logcatd logd tcpdump cnss_diag statsd traced; do
      pid=$(pidof "$svc" 2>/dev/null)
      [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null
    done
    logcat -c 2>/dev/null
    echo "  📝 Logs killed"
  fi
}

stock_services() {
  echo "Frosty Services - STOCK $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  log_service "Device: $(getprop ro.product.model) Android $(getprop ro.build.version.release)"
  log_service ""

  if [ ! -f "$GMS_LIST" ]; then
      echo "ERROR: Service list not found! Reinstall"
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

  echo ""
  echo "  🔥 GMS REVERTED TO STOCK"
  echo "  Re-enabled: $count_ok  Failed: $count_fail"
  echo ""

  # Restore kernel values from backup
  if [ -f "$KERNEL_BACKUP" ]; then
    echo "  Restoring kernel values..."
    local kcount=0
    while IFS= read -r line; do
      case "$line" in \#*|"") continue ;; esac
      name=$(echo "$line" | cut -d= -f1)
      val=$(echo "$line"  | cut -d= -f2)
      path=$(echo "$line" | cut -d= -f3-)
      [ -z "$path" ] && continue
      if [ -f "$path" ]; then
        chmod +w "$path" 2>/dev/null
        echo "$val" > "$path" 2>/dev/null && kcount=$((kcount + 1))
      fi
    done < "$KERNEL_BACKUP"
    echo "  ✓ Kernel values restored ($kcount)"
  else
    echo "  Kernel tweaks: revert takes effect on next reboot"
  fi

  # Revert GMS Doze
  chmod +x "$MODDIR/gms_doze.sh"
  "$MODDIR/gms_doze.sh" revert

  # Revert Deep Doze
  chmod +x "$MODDIR/deep_doze.sh"
  "$MODDIR/deep_doze.sh" stock
}

backup_settings() {
  local dir="/storage/emulated/0/Frosty"
  mkdir -p "$dir" 2>/dev/null || { echo "ERROR: Cannot write to /storage/emulated/0/Frosty — grant storage permission"; return 1; }
  local ts=$(date '+%Y%m%d_%H%M%S')
  local out="$dir/frosty_$ts.json"
  local modver; modver=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)
  [ -z "$modver" ] && modver="unknown"
  . "$MODDIR/config/user_prefs"
  local wl_b64=""
  if [ -f "$MODDIR/config/doze_whitelist.txt" ]; then
    wl_b64=$(base64 < "$MODDIR/config/doze_whitelist.txt" | tr -d '\n')
  fi
  cat > "$out" << ENDJSON
{
  "version": "$modver",
  "exported": "$ts",
  "prefs": {
    "ENABLE_KERNEL_TWEAKS": $ENABLE_KERNEL_TWEAKS,
    "ENABLE_SYSTEM_PROPS": $ENABLE_SYSTEM_PROPS,
    "ENABLE_BLUR_DISABLE": $ENABLE_BLUR_DISABLE,
    "ENABLE_LOG_KILLING": $ENABLE_LOG_KILLING,
    "ENABLE_GMS_DOZE": $ENABLE_GMS_DOZE,
    "ENABLE_DEEP_DOZE": $ENABLE_DEEP_DOZE,
    "DEEP_DOZE_LEVEL": "$DEEP_DOZE_LEVEL",
    "DISABLE_TELEMETRY": $DISABLE_TELEMETRY,
    "DISABLE_BACKGROUND": $DISABLE_BACKGROUND,
    "DISABLE_LOCATION": $DISABLE_LOCATION,
    "DISABLE_CONNECTIVITY": $DISABLE_CONNECTIVITY,
    "DISABLE_CLOUD": $DISABLE_CLOUD,
    "DISABLE_PAYMENTS": $DISABLE_PAYMENTS,
    "DISABLE_WEARABLES": $DISABLE_WEARABLES,
    "DISABLE_GAMES": $DISABLE_GAMES
  },
  "whitelist_b64": "$wl_b64"
}
ENDJSON
  echo "$out"
}

restore_settings() {
  local file="$1"
  [ -z "$file" ] && { echo "ERROR: No file specified"; exit 1; }
  [ ! -f "$file" ] && { echo "ERROR: Not found: $file"; exit 1; }

  pi() { grep "\"$1\"" "$file" | grep -o '[0-9]*' | head -1; }
  ps_() { grep "\"$1\"" "$file" | sed 's/.*: *"//;s/".*//' | head -1; }

  local dl; dl=$(ps_ DEEP_DOZE_LEVEL); [ -z "$dl" ] && dl="moderate"

  cat > "$MODDIR/config/user_prefs" << ENDPREFS
ENABLE_KERNEL_TWEAKS=$(pi ENABLE_KERNEL_TWEAKS)
ENABLE_SYSTEM_PROPS=$(pi ENABLE_SYSTEM_PROPS)
ENABLE_BLUR_DISABLE=$(pi ENABLE_BLUR_DISABLE)
ENABLE_LOG_KILLING=$(pi ENABLE_LOG_KILLING)
ENABLE_GMS_DOZE=$(pi ENABLE_GMS_DOZE)
ENABLE_DEEP_DOZE=$(pi ENABLE_DEEP_DOZE)
DEEP_DOZE_LEVEL=$dl
DISABLE_TELEMETRY=$(pi DISABLE_TELEMETRY)
DISABLE_BACKGROUND=$(pi DISABLE_BACKGROUND)
DISABLE_LOCATION=$(pi DISABLE_LOCATION)
DISABLE_CONNECTIVITY=$(pi DISABLE_CONNECTIVITY)
DISABLE_CLOUD=$(pi DISABLE_CLOUD)
DISABLE_PAYMENTS=$(pi DISABLE_PAYMENTS)
DISABLE_WEARABLES=$(pi DISABLE_WEARABLES)
DISABLE_GAMES=$(pi DISABLE_GAMES)
ENDPREFS

  local wl_file="$MODDIR/config/doze_whitelist.txt"
  local b64_data=$(grep '"whitelist_b64"' "$file" | sed 's/.*: *"//;s/".*//')
  
  if [ -n "$b64_data" ]; then
    echo "$b64_data" | base64 -d > "$wl_file"
  else
    printf '# Frosty Deep Doze Whitelist - restored %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "$wl_file"
    grep '"whitelist":' "$file" | sed 's/.*"whitelist": *\[//;s/\].*//' | tr ',' '\n' | tr -d '"' | grep -v '^$' >> "$wl_file"
  fi

  echo "OK"
}

list_backups() {
  local dir="/storage/emulated/0/Frosty"
  [ ! -d "$dir" ] && { echo "[]"; return; }
  local files; files=$(ls -t "$dir"/frosty_*.json 2>/dev/null)
  [ -z "$files" ] && { echo "[]"; return; }
  printf '['
  local first=1
  for f in $files; do
    local name; name=$(basename "$f")
    [ "$first" -eq 1 ] && first=0 || printf ','
    printf '{"name":"%s","path":"%s"}' "$name" "$f"
  done
  printf ']\n'
}

share_backup() {
  local file="$1"
  [ ! -f "$file" ] && { echo "ERROR: not found"; return 1; }
  local name; name=$(basename "$file")
  local pub="/data/local/tmp/$name"
  cp "$file" "$pub" && chmod 644 "$pub"
  am start -a android.intent.action.SEND \
    --eu android.intent.extra.STREAM "file://$pub" \
    --et android.intent.extra.SUBJECT "$name" \
    -t application/json \
    -f 0x10000001 2>/dev/null
  echo "$pub"
}

case "$1" in
  freeze)           freeze_services ;;
  stock)            stock_services ;;
  apply_sysprops)   apply_system_props ;;
  export)           backup_settings ;;
  import)           restore_settings "$2" ;;
  list_backups)     list_backups ;;
  share)            share_backup "$2" ;;
  *)                echo "Usage: frosty.sh [freeze|stock|apply_sysprops|export|import|list_backups|share]" ;;
esac

exit 0