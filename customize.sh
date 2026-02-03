# 🧊 FROSTY - GMS Freezer / Battery Saver
# Author: Drsexo (GitHub)

# Variables
TIMEOUT=30

# UI Functions
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
  local title="$1"
  local top="┌────────────────────────────────────────────┐"
  local bot="└────────────────────────────────────────────┘"
  local pad=0
  case "$title" in
    "⚙️  System Tweaks")           pad=19 ;;
    "💤  GMS Doze")                pad=21 ;;
    "🔋  Deep Doze")               pad=21 ;;
    "🧊  GMS Service Categories")  pad=15 ;;
    "💾  Saving Configuration")    pad=16 ;;
    "📋  Summary")                 pad=21 ;;
    "✅  Installation Complete")   pad=16 ;;
    "❆  Stay Frosty!  ❆")         pad=18 ;;
    *)                            pad=15 ;;
  esac
  ui_print ""
  ui_print "$top"
  ui_print "$(printf '%*s' "$pad" '')${title}"
  ui_print "$bot"
}

choose_tweak() {
  local prompt="$1"
  local default="$2"

  ui_print ""
  ui_print "  $prompt"

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
  ui_print "  ────────────────────────────────────────────"
  ui_print "  $category"
  ui_print "  $description"
  [ -n "$warning" ] && ui_print "  $warning"
  ui_print "  ────────────────────────────────────────────"

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

# Set Permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/frosty.sh" 0 0 0755
set_perm "$MODPATH/gms_doze.sh" 0 0 0755
set_perm "$MODPATH/deep_doze.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
if [ -d "$MODPATH/system/bin" ]; then
  set_perm_recursive "$MODPATH/system/bin" 0 0 0755 0755
fi
mkdir -p "$MODPATH/config"
mkdir -p "$MODPATH/logs"

# Show Banner
print_banner

# SYSTEM TWEAKS SECTION
print_section "⚙️  System Tweaks"
ui_print ""
ui_print "  ⬆️ Vol UP = YES  |  ⬇️ Vol DOWN = NO"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
ui_print ""
choose_tweak "🔧 Apply Kernel Tweaks? (Scheduler, VM, Network)" "YES"
ENABLE_KERNEL_TWEAKS=$?
choose_tweak "🎨 Disable UI Blur? (Saves GPU, may affect visuals)" "NO"
ENABLE_BLUR_DISABLE=$?
choose_tweak "📝 Kill Log Processes? (logcat, logd, traced, etc.)" "YES"
ENABLE_LOG_KILLING=$?

# GMS DOZE SECTION
print_section "💤  GMS Doze"
ui_print ""
ui_print "  Based on Universal GMS Doze by gloeyisk"
ui_print "  Patches system XMLs to allow GMS battery optimization"
ui_print ""
ui_print "  ⬆️ Vol UP = YES  |  ⬇️ Vol DOWN = NO"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
ui_print ""
choose_tweak "💤 Enable GMS Doze?" "YES"
ENABLE_GMS_DOZE=$?

# GMS Doze XML Patching
if [ "$ENABLE_GMS_DOZE" -eq 1 ]; then
  ui_print ""
  ui_print "  Patching system XML files..."

  GMS0="\"com.google.android.gms\""
  STR1="allow-in-power-save package=$GMS0"
  STR2="allow-in-data-usage-save package=$GMS0"
  STR3="allow-unthrottled-location package=$GMS0"
  STR4="allow-ignore-location-settings package=$GMS0"

  PATCHED_COUNT=0

  TMPFILE="$MODPATH/found_xmls.tmp"
  : > "$TMPFILE"

  for DIR in /system /vendor /system_ext /product /odm; do
    [ ! -d "$DIR" ] && continue
    find "$DIR" -type f -iname "*.xml" 2>/dev/null | while read -r FILE; do
      if grep -q "com.google.android.gms" "$FILE" 2>/dev/null; then
        if grep -qE "allow-in-power-save|allow-in-data-usage-save|allow-unthrottled-location|allow-ignore-location-settings" "$FILE" 2>/dev/null; then
          echo "$FILE" >> "$TMPFILE"
        fi
      fi
    done
  done

  if [ -s "$TMPFILE" ]; then
    while IFS= read -r XMLFILE; do
      [ -z "$XMLFILE" ] && continue
      [ ! -f "$XMLFILE" ] && continue

      OVERLAY="$MODPATH$XMLFILE"
      mkdir -p "$(dirname "$OVERLAY")"
      cp -af "$XMLFILE" "$OVERLAY"

      sed -i "/$STR1/d" "$OVERLAY"
      sed -i "/$STR2/d" "$OVERLAY"
      sed -i "/$STR3/d" "$OVERLAY"
      sed -i "/$STR4/d" "$OVERLAY"

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

  ui_print ""
  ui_print "  Clearing GMS cache..."
  cd /data/data
  find . -type f -name '*gms*' -delete 2>/dev/null
  ui_print "  ✓ GMS cache cleared"
fi

# DEEP DOZE SECTION
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
  ui_print "  ────────────────────────────────────────────"
  ui_print "  Choose Aggressiveness Level:"
  ui_print ""
  ui_print "  💀 MAXIMUM (Max savings, may affect some apps)"
  ui_print "     - All Moderate features PLUS:"
  ui_print "     - Deny WAKE_LOCK"
  ui_print "     - Network lockdown"
  ui_print "     - Sensor freeze"
  ui_print "     - Wakelock killer"
  ui_print "     - Alarm restrictions"
  ui_print ""
  ui_print "  ⚡ MODERATE (Recommended for daily use)"
  ui_print "     - Aggressive doze constants"
  ui_print "     - App standby restrictions"
  ui_print "     - Deny RUN_IN_BACKGROUND"
  ui_print "  ────────────────────────────────────────────"

  choose_level "Select level:"
  DEEP_DOZE_LEVEL="$CHOSEN_LEVEL"
  unset CHOSEN_LEVEL
fi

# GMS SERVICE CATEGORIES SECTION
ui_print ""
print_section "🧊  GMS Service Categories"
ui_print ""
ui_print "  ⬆️ Vol UP = FREEZE  |  ⬇️ Vol DOWN = SKIP"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
choose_gms "📊 TELEMETRY" "Ads, Tracking, Analytics" "Safe to disable. Stops Google data collection." "FREEZE"
DISABLE_TELEMETRY=$?
choose_gms "🔄 BACKGROUND" "Updates, Background Services" "Safe to disable. May delay auto-updates." "FREEZE"
DISABLE_BACKGROUND=$?
choose_gms "📍 LOCATION" "GPS, Geofence, Activity Recognition" "BREAKS: Maps, Navigation, Find My Device!" "FREEZE"
DISABLE_LOCATION=$?
choose_gms "📡 CONNECTIVITY" "Cast, Quick Share, Nearby" "BREAKS: Chromecast, Quick Share, Fast Pair!" "FREEZE"
DISABLE_CONNECTIVITY=$?
choose_gms "☁️ CLOUD" "Auth, Sync, Backup, Security" "May affect Google Sign-in, Autofill, Backups" "FREEZE"
DISABLE_CLOUD=$?
choose_gms "💳 PAYMENTS" "Google Pay, Wallet, NFC Payments" "BREAKS: Google Pay, NFC tap-to-pay!" "FREEZE"
DISABLE_PAYMENTS=$?
choose_gms "⌚ WEARABLES" "Wear OS, Google Fit, Health" "BREAKS: Smartwatch sync, Fitness tracking!" "FREEZE"
DISABLE_WEARABLES=$?
choose_gms "🎮 GAMES" "Play Games, Achievements, Cloud Saves" "BREAKS: Play Games achievements, leaderboards!" "FREEZE"
DISABLE_GAMES=$?

# SAVE CONFIGURATION
print_section "💾  Saving Configuration"
cat > "$MODPATH/config/user_prefs" << EOF
# Frosty User Preferences
# Generated: $(date)
# System Tweaks (1=enabled, 0=disabled)
ENABLE_KERNEL_TWEAKS=$ENABLE_KERNEL_TWEAKS
ENABLE_BLUR_DISABLE=$ENABLE_BLUR_DISABLE
ENABLE_LOG_KILLING=$ENABLE_LOG_KILLING
# GMS Doze (1=enabled, 0=disabled)
ENABLE_GMS_DOZE=$ENABLE_GMS_DOZE
# Deep Doze (1=enabled, 0=disabled)
ENABLE_DEEP_DOZE=$ENABLE_DEEP_DOZE
DEEP_DOZE_LEVEL=$DEEP_DOZE_LEVEL
# GMS Categories (1=freeze, 0=keep enabled)
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

# SUMMARY
print_section "📋  Summary"
ui_print ""
ui_print "  System Tweaks:"
[ "$ENABLE_KERNEL_TWEAKS" -eq 1 ] && ui_print "    ✅ Kernel Tweaks" || ui_print "    ❌ Kernel Tweaks"
[ "$ENABLE_BLUR_DISABLE" -eq 1 ] && ui_print "    ✅ Blur Disable" || ui_print "    ❌ Blur Disable"
[ "$ENABLE_LOG_KILLING" -eq 1 ] && ui_print "    ✅ Log Killing" || ui_print "    ❌ Log Killing"
ui_print ""
ui_print "  GMS Doze:"
if [ "$ENABLE_GMS_DOZE" -eq 1 ]; then
  ui_print "    💤 Enabled (cache cleared)"
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

# FINAL NOTES
print_section "✅  Installation Complete"
ui_print ""
ui_print "  🔄 Reboot to apply changes"
ui_print ""
ui_print "  💡 Use ACTION BUTTON in root manager to toggle"
ui_print "     between 🧊 Frozen and 🔥 Stock modes"
ui_print ""
ui_print "  📝 Edit whitelist: /data/adb/modules/Frosty/config/"
ui_print "     doze_whitelist.txt"
ui_print ""
ui_print "  ⚠️  If issues occur → Action Button → Stock"
ui_print ""
ui_print "  📄 Logs: /data/adb/modules/Frosty/logs/"
ui_print ""
print_section "❆  Stay Frosty!  ❆"
ui_print ""

# Cleanup repo files
rm -rf "$MODPATH/README.md" "$MODPATH/LICENSE" "$MODPATH/CHANGELOG.md" "$MODPATH/update.json" "$MODPATH"/.git*