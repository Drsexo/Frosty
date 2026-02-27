#!/system/bin/sh
# FROSTY - GMS Freezer / Battery Saver
# Author: Drsexo (GitHub)

TIMEOUT=30

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

# Timeout fallback
if ! command -v timeout >/dev/null 2>&1; then
  timeout() { shift; "$@"; }
fi

# Getevent check
HAS_GETEVENT=1
if ! command -v getevent >/dev/null 2>&1; then
  HAS_GETEVENT=0
fi

print_banner() {
  ui_print ""
  ui_print "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⡀⠀⣠⡆⠀⠀⠀⠀⠀⠀⠀⠀⣤⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠈⢻⣿⠋⠀⠀⠀⠀⠀⢸⣧⠀⢀⣾⣦⣤⣤⣄⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⢿⡇⠀⣶⠀⠀⠺⣦⣼⣧⣴⡿⠀⠀⠀⠀⠀⢻⣦⣾⣛⠉⠉⠉⠁⠀⠀"
  ui_print "⠀⠀⢶⣶⣤⣼⣧⣰⣏⠀⠀⠀⠈⠹⣿⠋⠀⠀⠀⠀⠀⢀⣾⠟⠛⠛⠻⠿⠂⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⢠⣬⣿⣿⣿⡀⢀⡄⢠⣤⣿⣤⡦⠀⢿⣄⣴⣟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠀⠀⢈⣿⣿⣇⠀⠙⣿⠋⠀⠀⣨⡿⠟⠛⠃⠀⠀⠀⢀⣶⠀⣠⡀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⢠⡀⠀⠀⠀⠀⠈⠙⢷⣤⣿⡆⢀⣴⠟⠀⠀⠀⣠⡟⠀⢀⣾⢃⣴⠟⠁⠀"
  ui_print "⠰⣦⡀⠀⠘⢿⣄⠀⢰⣦⣀⣀⣀⣹⣿⣷⣿⣷⣤⣴⡶⢾⣿⣷⡾⢿⣿⡟⠿⣶⣄⠀"
  ui_print "⠀⠈⣿⣷⣶⣶⣿⣿⠿⢿⣿⠟⠋⣹⣿⡟⠻⣿⣄⠀⠀⠀⠈⠙⠀⠀⠙⢿⣦⠀⠙⠁"
  ui_print "⠰⠾⠋⠀⠀⣾⠟⠁⠀⣾⡁⢀⣴⠟⠸⣧⠀⠈⠻⣷⣶⣤⡤⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⣀⠀⠀⠈⣻⣿⣿⠀⠀⣿⠀⠀⠀⢸⡟⠻⣦⣄⣀⣠⣤⣄⡀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠙⠛⢻⣾⡟⠉⠃⠀⣠⣿⣄⠀⠀⠈⠁⠀⢸⣿⢿⣿⡷⠾⠃⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⢶⣶⣦⣶⡟⢿⠃⠀⠀⠚⠋⢻⡟⠗⠀⠀⠀⠀⠘⠿⠀⢿⡄⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⢨⡿⠀⠈⠀⠀⠀⠀⠀⣸⣧⡀⠀⠀⠀⠀⠀⠀⠀⠘⠁⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⢀⣴⠿⣿⡿⢶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠟⠀⠀⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print ""
  ui_print "        _______  ____  ____________  __"
  ui_print "       / __/ _ \/ __ \/ __/_  __/\ \/ /"
  ui_print "      / _// , _/ /_/ /\ \  / /    \  / "
  ui_print "     /_/ /_/|_|\____/___/ /_/     /_/  "
  ui_print ""
  ui_print "        ❆  Freeze your battery drain  ❆"
  ui_print ""
}

print_section() {
  local text="$1"
  local ascii_len=$(printf '%s' "$text" | sed 's/[^[:print:]]//g' | wc -c)
  local total_bytes=$(printf '%s' "$text" | wc -c)
  local emoji_bytes=$(( total_bytes - ascii_len ))
  local emoji_count=$(( emoji_bytes / 3 ))
  [ "$emoji_count" -lt 0 ] && emoji_count=0
  local display_width=$(( ascii_len + emoji_count * 2 ))

  local total_pad=$(( COLS - display_width ))
  [ "$total_pad" -lt 0 ] && total_pad=0
  local left_pad=$(( total_pad / 2 ))

  local lpad="" _p=0
  while [ $_p -lt $left_pad ]; do lpad="${lpad} "; _p=$((_p+1)); done

  ui_print ""
  ui_print "$BOX_TOP"
  ui_print "${lpad}${text}"
  ui_print "$BOX_BOT"
}

choose_tweak() {
  local prompt="$1"
  local default="$2"
  local desc="$3"

  ui_print ""
  ui_print "  $prompt"
  [ -n "$desc" ] && ui_print "    $desc"

  if [ "$HAS_GETEVENT" -eq 0 ]; then
    if [ "$default" = "YES" ]; then
      ui_print "  → ENABLED ✅ (auto - no getevent)"
      return 1
    else
      ui_print "  → SKIPPED ❌ (auto - no getevent)"
      return 0
    fi
  fi

  while :; do
    event=$(timeout "$TIMEOUT" getevent -qlc 1 2>/dev/null)
    code=$?

    if [ "$code" -eq 124 ] || [ "$code" -eq 143 ]; then
      if [ "$default" = "YES" ]; then
        ui_print "  → ENABLED ✅ (timeout)"
        return 1
      else
        ui_print "  → SKIPPED ❌ (timeout)"
        return 0
      fi
    fi

    if echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"; then
      ui_print "  → ENABLED ✅"
      return 1
    fi

    if echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
      ui_print "  → SKIPPED ❌"
      return 0
    fi
  done
}

choose_level() {
  local prompt="$1"
  CHOSEN_LEVEL="moderate"

  ui_print ""
  ui_print "  $prompt"
  ui_print "  ⬆️ Vol UP = Maximum 💀  |  ⬇️ Vol DOWN = Moderate ⚡️"
  ui_print "  ⏱️ ${TIMEOUT}s timeout - defaults to Moderate"

  if [ "$HAS_GETEVENT" -eq 0 ]; then
    ui_print "  → MODERATE ⚡ (auto - no getevent)"
    CHOSEN_LEVEL="moderate"
    return 0
  fi

  while :; do
    event=$(timeout "$TIMEOUT" getevent -qlc 1 2>/dev/null)
    code=$?

    if [ "$code" -eq 124 ] || [ "$code" -eq 143 ]; then
      ui_print "  → MODERATE ⚡ (timeout - recommended)"
      CHOSEN_LEVEL="moderate"
      return 0
    fi

    if echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"; then
      ui_print "  → MAXIMUM 💀"
      CHOSEN_LEVEL="maximum"
      return 1
    fi

    if echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
      ui_print "  → MODERATE ⚡"
      CHOSEN_LEVEL="moderate"
      return 0
    fi
  done
}

choose_gms() {
  local category="$1"
  local description="$2"
  local warning="$3"
  local default="$4"

  ui_print ""
  ui_print "$SEP"
  ui_print "  $category"
  ui_print "  $description"
  [ -n "$warning" ] && ui_print "  $warning"
  ui_print "$SEP"

  if [ "$HAS_GETEVENT" -eq 0 ]; then
    if [ "$default" = "FREEZE" ]; then
      ui_print "  → FROZEN 🧊 (auto - no getevent)"
      return 1
    else
      ui_print "  → SKIPPED ❌ (auto - no getevent)"
      return 0
    fi
  fi

  while :; do
    event=$(timeout "$TIMEOUT" getevent -qlc 1 2>/dev/null)
    code=$?

    if [ "$code" -eq 124 ] || [ "$code" -eq 143 ]; then
      if [ "$default" = "FREEZE" ]; then
        ui_print "  → FROZEN 🧊 (timeout)"
        return 1
      else
        ui_print "  → SKIPPED ❌ (timeout)"
        return 0
      fi
    fi

    if echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"; then
      ui_print "  → FROZEN 🧊"
      return 1
    fi

    if echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
      ui_print "  → SKIPPED ❌"
      return 0
    fi
  done
}

# Permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/frosty.sh" 0 0 0755
set_perm "$MODPATH/gms_doze.sh" 0 0 0755
set_perm "$MODPATH/deep_doze.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
mkdir -p "$MODPATH/config"
mkdir -p "$MODPATH/logs"

# GMS check
if ! pm list packages 2>/dev/null | grep -q "com.google.android.gms"; then
  ui_print ""
  ui_print "  ⚠️  Google Play Services not found!"
  ui_print "  GMS freezing and doze features will not work."
  ui_print ""
fi

print_banner

# System Tweaks
print_section "⚙️  System Tweaks"
ui_print ""
ui_print "  ⬆️ Vol UP = YES  |  ⬇️ Vol DOWN = NO"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
ui_print ""
choose_tweak "🔧 Apply Kernel Tweaks?" "YES" "Speeds up task switching, reduces CPU wakeups"
ENABLE_KERNEL_TWEAKS=$?
choose_tweak "⚙️  Apply System Props?" "YES" "Disables debug logging, saves battery & RAM"
ENABLE_SYSTEM_PROPS=$?
choose_tweak "🎨 Disable UI Blur?" "NO" "Reduces GPU load, smoother on weaker devices"
ENABLE_BLUR_DISABLE=$?
choose_tweak "📝 Kill Log Processes?" "YES" "Stops background loggers, frees RAM"
ENABLE_LOG_KILLING=$?

# GMS Doze
print_section "💤  GMS Doze"
ui_print ""
ui_print "  Removes GMS from power-save whitelists"
ui_print "  ⚠️  May delay notifications"
ui_print ""
ui_print "  ⬆️ Vol UP = YES  |  ⬇️ Vol DOWN = NO"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
ui_print ""
choose_tweak "💤 Enable GMS Doze?" "YES"
ENABLE_GMS_DOZE=$?

if [ "$ENABLE_GMS_DOZE" -eq 1 ]; then
  ui_print ""
  ui_print "  Patching system XML files..."

  GMS_STR1='allow-in-power-save package="com.google.android.gms"'
  GMS_STR2='allow-in-data-usage-save package="com.google.android.gms"'
  GMS_STR3='allow-unthrottled-location package="com.google.android.gms"'
  GMS_STR4='allow-ignore-location-settings package="com.google.android.gms"'

  PATCHED_COUNT=0
  TMPFILE="$MODPATH/found_xmls.tmp"
  : > "$TMPFILE"

  for DIR in /system /vendor /system_ext /product /odm; do
    [ ! -d "$DIR" ] && continue
    find "$DIR" -type f -iname "*.xml" 2>/dev/null | while read -r FILE; do
      if grep -qF "$GMS_STR1" "$FILE" 2>/dev/null || grep -qF "$GMS_STR2" "$FILE" 2>/dev/null || \
         grep -qF "$GMS_STR3" "$FILE" 2>/dev/null || grep -qF "$GMS_STR4" "$FILE" 2>/dev/null; then
        echo "$FILE" >> "$TMPFILE"
      fi
    done
  done

  if [ -s "$TMPFILE" ]; then
    while IFS= read -r XMLFILE; do
      [ -z "$XMLFILE" ] && continue
      [ ! -f "$XMLFILE" ] && continue

      OVERLAY="$MODPATH$XMLFILE"
      mkdir -p "$(dirname "$OVERLAY")"
      if ! cp -af "$XMLFILE" "$OVERLAY"; then
        ui_print "    ✗ Failed to copy: $XMLFILE"
        continue
      fi

      grep -vF "$GMS_STR1" "$OVERLAY" > "$OVERLAY.tmp" && mv "$OVERLAY.tmp" "$OVERLAY"
      grep -vF "$GMS_STR2" "$OVERLAY" > "$OVERLAY.tmp" && mv "$OVERLAY.tmp" "$OVERLAY"
      grep -vF "$GMS_STR3" "$OVERLAY" > "$OVERLAY.tmp" && mv "$OVERLAY.tmp" "$OVERLAY"
      grep -vF "$GMS_STR4" "$OVERLAY" > "$OVERLAY.tmp" && mv "$OVERLAY.tmp" "$OVERLAY"

      ui_print "    ✓ Patched: $XMLFILE"
      PATCHED_COUNT=$((PATCHED_COUNT + 1))
    done < "$TMPFILE"
  fi

  rm -f "$TMPFILE"

  for SUBDIR in product vendor system_ext odm; do
    if [ -d "$MODPATH/$SUBDIR" ]; then
      mkdir -p "$MODPATH/system/$SUBDIR"
      cp -rf "$MODPATH/$SUBDIR"/* "$MODPATH/system/$SUBDIR"/ 2>/dev/null
      rm -rf "$MODPATH/$SUBDIR"
    fi
  done

  if [ "$PATCHED_COUNT" -eq 0 ]; then
    ui_print ""
    ui_print "  ℹ️ No XML files needed patching"
    ui_print "  (GMS may already be optimizable on this ROM)"
  else
    ui_print ""
    ui_print "  ✓ Patched $PATCHED_COUNT XML file(s)"
  fi

  # Patch conflicting module XMLs
  ui_print ""
  ui_print "  Checking for conflicting modules..."
  MOD_PATCHED=0
  for xml in $(find /data/adb/modules -type f -name "*.xml" 2>/dev/null); do
    case "$xml" in "$MODPATH"*) continue ;; esac
    if grep -qF "$GMS_STR1" "$xml" 2>/dev/null || grep -qF "$GMS_STR2" "$xml" 2>/dev/null || \
       grep -qF "$GMS_STR3" "$xml" 2>/dev/null || grep -qF "$GMS_STR4" "$xml" 2>/dev/null; then
      grep -vF "$GMS_STR1" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      grep -vF "$GMS_STR2" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      grep -vF "$GMS_STR3" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      grep -vF "$GMS_STR4" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      MOD_PATCHED=$((MOD_PATCHED + 1))
    fi
  done
  [ "$MOD_PATCHED" -gt 0 ] && ui_print "  ✓ Patched $MOD_PATCHED conflicting module XML(s)"

  # Clear GMS cache
  ui_print ""
  ui_print "  Clearing GMS cache..."
  rm -rf /data/data/com.google.android.gms/cache/* 2>/dev/null
  rm -rf /data/data/com.google.android.gms/code_cache/* 2>/dev/null
  ui_print "  ✓ GMS cache cleared"
fi

# Deep Doze
print_section "🔋  Deep Doze"
ui_print ""
ui_print "  Aggressive battery optimization for ALL apps"
ui_print "  Restricts background activity"
ui_print ""
ui_print "  ⬆️ Vol UP = YES  |  ⬇️ Vol DOWN = NO"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
ui_print ""
choose_tweak "🔋 Enable Deep Doze?" "YES"
ENABLE_DEEP_DOZE=$?
DEEP_DOZE_LEVEL="moderate"
if [ "$ENABLE_DEEP_DOZE" -eq 1 ]; then
  ui_print ""
  ui_print "$SEP"
  ui_print "  Choose Aggressiveness Level:"
  ui_print ""
  ui_print "  💀 MAXIMUM (Max savings, may affect some apps)"
  ui_print "     - All Moderate features PLUS:"
  ui_print "     - Deny WAKE_LOCK"
  ui_print "     - Wakelock killer"
  ui_print "     - Alarm restrictions"
  ui_print ""
  ui_print "  ⚡ MODERATE (Recommended for daily use)"
  ui_print "     - Aggressive doze constants"
  ui_print "     - App standby restrictions"
  ui_print "     - Deny RUN_IN_BACKGROUND"
  ui_print "$SEP"

  choose_level "Select level:"
  DEEP_DOZE_LEVEL="$CHOSEN_LEVEL"
  unset CHOSEN_LEVEL
fi

# GMS Categories
ui_print ""
print_section "🧊  GMS Service Categories"
ui_print ""
ui_print "  ⬆️ Vol UP = FREEZE  |  ⬇️ Vol DOWN = SKIP"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
choose_gms "📊 TELEMETRY" "Ads, Tracking, Analytics" "Safe to disable. Stops Google data collection." "FREEZE"
DISABLE_TELEMETRY=$?
choose_gms "🔄 BACKGROUND" "Updates, Font sync, MDM" "Safe to disable. May delay auto-updates." "FREEZE"
DISABLE_BACKGROUND=$?
choose_gms "📍 LOCATION" "GPS, Geofence, Activity Recognition" "BREAKS: Maps, Navigation, Find My Device!" "FREEZE"
DISABLE_LOCATION=$?
choose_gms "📡 CONNECTIVITY" "Cast, Quick Share, Nearby" "BREAKS: Chromecast, Quick Share, Fast Pair!" "FREEZE"
DISABLE_CONNECTIVITY=$?
choose_gms "☁️ CLOUD" "Auth, Sync, Backup, Autofill, Security" "BREAKS: Google Sign-in, Autofill, Passwords!" "SKIP"
DISABLE_CLOUD=$?
choose_gms "💳 PAYMENTS" "Google Pay, Wallet, NFC Payments" "BREAKS: Google Pay, NFC tap-to-pay!" "FREEZE"
DISABLE_PAYMENTS=$?
choose_gms "⌚ WEARABLES" "Wear OS, Google Fit, Health" "BREAKS: Smartwatch sync, Fitness tracking!" "FREEZE"
DISABLE_WEARABLES=$?
choose_gms "🎮 GAMES" "Play Games, Achievements, Cloud Saves" "BREAKS: Play Games achievements, leaderboards!" "FREEZE"
DISABLE_GAMES=$?

# Save Configuration
print_section "💾  Saving Configuration"
cat > "$MODPATH/config/user_prefs" << EOF
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

echo "frozen" > "$MODPATH/config/state"
ui_print ""
ui_print "  ✓ Configuration saved"

# Preserve existing doze whitelist on updates
WHITELIST="$MODPATH/config/doze_whitelist.txt"
EXISTING_WHITELIST="/data/adb/modules/Frosty/config/doze_whitelist.txt"
if [ -f "$EXISTING_WHITELIST" ]; then
  cp -f "$EXISTING_WHITELIST" "$WHITELIST"
  ui_print "  ↩ Doze whitelist preserved"
elif [ ! -f "$WHITELIST" ]; then
  touch "$WHITELIST"
fi

# System.prop update safety
SYSPROP="$MODPATH/system.prop"
SYSPROP_OLD="$MODPATH/system.prop.old"
if [ "$ENABLE_SYSTEM_PROPS" -eq 1 ]; then
  rm -f "$SYSPROP_OLD" 2>/dev/null
  ui_print "  ✓ system.prop active"
else
  if [ -f "$SYSPROP" ]; then
    mv "$SYSPROP" "$SYSPROP_OLD"
    ui_print "  ✓ system.prop disabled (renamed to .old)"
  fi
fi

# Summary
print_section "📋  Summary"
ui_print ""
ui_print "  System Tweaks:"
[ "$ENABLE_KERNEL_TWEAKS" -eq 1 ] && ui_print "    ✅ Kernel Tweaks"     || ui_print "    ❌ Kernel Tweaks"
[ "$ENABLE_SYSTEM_PROPS" -eq 1 ]  && ui_print "    ✅ System Props"     || ui_print "    ❌ System Props"
[ "$ENABLE_BLUR_DISABLE" -eq 1 ]  && ui_print "    ✅ Blur Disable"      || ui_print "    ❌ Blur Disable"
[ "$ENABLE_LOG_KILLING" -eq 1 ]   && ui_print "    ✅ Log Killing"       || ui_print "    ❌ Log Killing"
ui_print ""
ui_print "  GMS Doze:"
if [ "$ENABLE_GMS_DOZE" -eq 1 ]; then
  ui_print "    💤 Enabled"
else
  ui_print "    ❌ Disabled"
fi
ui_print ""
ui_print "  Deep Doze:"
if [ "$ENABLE_DEEP_DOZE" -eq 1 ]; then
  if [ "$DEEP_DOZE_LEVEL" = "maximum" ]; then
    ui_print "    🔋 Maximum (aggressive)"
  else
    ui_print "    🔋 Moderate (balanced)"
  fi
else
  ui_print "    ❌ Disabled"
fi
ui_print ""
ui_print "  GMS Categories:"
[ "$DISABLE_TELEMETRY" -eq 1 ] && ui_print "    🧊 Telemetry" || ui_print "    ❌ Telemetry"
[ "$DISABLE_BACKGROUND" -eq 1 ] && ui_print "    🧊 Background" || ui_print "    ❌ Background"
[ "$DISABLE_LOCATION" -eq 1 ] && ui_print "    🧊 Location" || ui_print "    ❌ Location"
[ "$DISABLE_CONNECTIVITY" -eq 1 ] && ui_print "    🧊 Connectivity" || ui_print "    ❌ Connectivity"
[ "$DISABLE_CLOUD" -eq 1 ] && ui_print "    🧊 Cloud" || ui_print "    ❌ Cloud"
[ "$DISABLE_PAYMENTS" -eq 1 ] && ui_print "    🧊 Payments" || ui_print "    ❌ Payments"
[ "$DISABLE_WEARABLES" -eq 1 ] && ui_print "    🧊 Wearables" || ui_print "    ❌ Wearables"
[ "$DISABLE_GAMES" -eq 1 ] && ui_print "    🧊 Games" || ui_print "    ❌ Games"
ui_print ""
ui_print "  🧊 = Frozen  |  💤 = GMS Dozed  |  🔋 = Deep Dozed"

print_section "✅  Installation Complete"
ui_print ""
ui_print "  🔄 Reboot to apply changes"
ui_print ""
ui_print "  💡 Use Action / WebUI button in root manager to"
ui_print "   toggle between 🧊 Frozen and 🔥 Stock modes"
ui_print ""
ui_print "  📝 Edit whitelist: /config/doze_whitelist.txt"
ui_print "   Or using WebUI"
ui_print ""
ui_print "  ⚠️  If issues occur change to Stock mode"
ui_print ""
ui_print "  📄 Logs: /data/adb/modules/Frosty/logs/"
ui_print ""
print_section "❆  Stay Frosty!  ❆"
ui_print ""

rm -rf "$MODPATH/README.md" "$MODPATH/LICENSE" "$MODPATH/CHANGELOG.md" "$MODPATH/update.json" "$MODPATH"/.git*
