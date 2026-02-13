#!/system/bin/sh
# 🧊 FROSTY - GMS Freezer / Battery Saver
# Author: Drsexo (GitHub)
# Optimized & Secured byKevyn

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

# --- Funciones de Seguridad y Notificación ---
show_error_notification() {
  local title="$1"
  local message="$2"
  su -c "cmd notification post -S bigtext -t '$title' 'Frosty Module' '$message'" 2>/dev/null
  ui_print "  ❌ ERROR: $message"
  ui_print "  🔔 Notificación enviada al usuario."
}

disable_module_safely() {
  local reason="$1"
  show_error_notification "Frosty Module Desactivado" "$reason"
  echo "stock" > "$MODPATH/config/state"
  if [ -f "$MODPATH/deep_doze.sh" ]; then
    sh "$MODPATH/deep_doze.sh" stock >> "$MODPATH/logs/emergency_revert.log" 2>&1
  fi
  ui_print "  ⚠️  Módulo desactivado por seguridad: $reason"
  ui_print "  📄 Revisa los logs en $MODPATH/logs/"
  exit 1
}

check_root() {
  if ! su -c "echo 'root check'" >/dev/null 2>&1; then
    disable_module_safely "No se tienen permisos de root."
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

check_critical_environment() {
  if ! command_exists "su"; then
    disable_module_safely "Comando 'su' no disponible."
  fi
  if ! command_exists "getevent"; then
    disable_module_safely "Comando 'getevent' no disponible."
  fi
  if ! command_exists "settings"; then
    disable_module_safely "Comando 'settings' no disponible."
  fi
}

# --- Funciones de UI ---
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
  ui_print ""
  ui_print "$BOX_TOP"
  ui_print "    $1"
  ui_print "$BOX_BOT"
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
  ui_print "$SEP"
  ui_print "  $category"
  ui_print "  $description"
  [ -n "$warning" ] && ui_print "  $warning"
  ui_print "$SEP"

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

# --- Permisos ---
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

# --- Crear doze_whitelist.txt ---
cat > "$MODPATH/config/doze_whitelist.txt" << EOF
# Lista blanca de aplicaciones y servicios que no deben ser optimizados
com.bancomer.mbanking
com.google.android.gms.location.fused.FusedLocationService
com.google.android.gms.location.internal.server.GoogleLocationService
com.google.android.gms.location.reporting.service.ReportingAndroidService
EOF
chmod 644 "$MODPATH/config/doze_whitelist.txt"
ui_print "  ✓ doze_whitelist.txt creado"


# --- Inicio del Script ---
print_banner
check_root
check_critical_environment

# --- System Tweaks ---
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

# --- GMS Doze ---
print_section "💤  GMS Doze"
ui_print ""
ui_print "  Patches system XMLs to allow GMS battery optimization"
ui_print ""
ui_print "  ⬆️ Vol UP = YES  |  ⬇️ Vol DOWN = NO"
ui_print "  ⏱️ ${TIMEOUT}s timeout"
ui_print ""
choose_tweak "💤 Enable GMS Doze?" "YES"
ENABLE_GMS_DOZE=$?

if [ "$ENABLE_GMS_DOZE" -eq 1 ]; then
  ui_print ""
  ui_print "  Patching system XML files..."

  GMS0="\"com.google.android.gms\""

  SYS_STR1="allow-in-power-save package=$GMS0"
  SYS_STR2="allow-in-data-usage-save package=$GMS0"

  MOD_STR1="allow-in-power-save package=$GMS0"
  MOD_STR2="allow-in-data-usage-save package=$GMS0"
  MOD_STR3="allow-unthrottled-location package=$GMS0"
  MOD_STR4="allow-ignore-location-settings package=$GMS0"

  PATCHED_COUNT=0
  TMPFILE="$MODPATH/found_xmls.tmp"
  : > "$TMPFILE"

  for DIR in /system /vendor /system_ext /product /odm; do
    [ ! -d "$DIR" ] && continue
    find "$DIR" -type f -iname "*.xml" 2>/dev/null | while read -r FILE; do
      if grep -qE "$SYS_STR1|$SYS_STR2" "$FILE" 2>/dev/null; then
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
        show_error_notification "Frosty Error" "Failed to copy $XMLFILE"
        continue
      fi
      sed -i "/$SYS_STR1/d;/$SYS_STR2/d" "$OVERLAY" || show_error_notification "Frosty Error" "Failed to patch $XMLFILE"

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
  else
    ui_print ""
    ui_print "  ✓ Patched $PATCHED_COUNT XML file(s)"
  fi

  ui_print ""
  ui_print "  Checking for conflicting modules..."
  MOD_PATCHED=0
  for xml in $(find /data/adb/modules -type f -name "*.xml" 2>/dev/null); do
    case "$xml" in "$MODPATH"*) continue ;; esac
    if grep -qE "$MOD_STR1|$MOD_STR2|$MOD_STR3|$MOD_STR4" "$xml" 2>/dev/null; then
      sed -i "/$MOD_STR1/d;/$MOD_STR2/d;/$MOD_STR3/d;/$MOD_STR4/d" "$xml" || show_error_notification "Frosty Error" "Failed to patch conflicting module XML"
      MOD_PATCHED=$((MOD_PATCHED + 1))
    fi
  done
  [ "$MOD_PATCHED" -gt 0 ] && ui_print "  ✓ Patched $MOD_PATCHED conflicting module XML(s)"

  ui_print ""
  ui_print "  Clearing GMS cache..."
  cd /data/data
  find . -type f -name '*gms*' -delete 2>/dev/null || show_error_notification "Frosty Error" "Failed to clear GMS cache"
  ui_print "  ✓ GMS cache cleared"
fi

# --- Deep Doze ---
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

# --- GMS Categories ---
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
choose_gms "☁️ CLOUD" "Auth, Sync, Backup, Check-in, Security" "May affect Google Sign-in, Autofill, Passwords" "FREEZE"
DISABLE_CLOUD=$?
choose_gms "💳 PAYMENTS" "Google Pay, Wallet, NFC Payments" "BREAKS: Google Pay, NFC tap-to-pay!" "FREEZE"
DISABLE_PAYMENTS=$?
choose_gms "⌚ WEARABLES" "Wear OS, Google Fit, Health" "BREAKS: Smartwatch sync, Fitness tracking!" "FREEZE"
DISABLE_WEARABLES=$?
choose_gms "🎮 GAMES" "Play Games, Achievements, Cloud Saves" "BREAKS: Play Games achievements, leaderboards!" "FREEZE"
DISABLE_GAMES=$?

# --- Save Configuration ---
print_section "💾  Saving Configuration"
cat > "$MODPATH/config/user_prefs" << EOF
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

echo "frozen" > "$MODPATH/config/state"
ui_print ""
ui_print "  ✓ Configuration saved"

if [ "$ENABLE_LOG_KILLING" -ne 1 ]; then
  rm -rf "$MODPATH/system/etc/init"
fi

# --- Summary ---
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

rm -rf "$MODPATH/README.md" "$MODPATH/LICENSE" "$MODPATH/CHANGELOG.md" "$MODPATH/update.json" "$MODPATH"/.git*
