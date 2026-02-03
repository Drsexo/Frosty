#!/system/bin/sh
# 🧊 FROSTY - GMS Doze Handler
# Handles GMS battery optimization with detailed logging

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
DOZE_LOG="$LOGDIR/gms_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"

# Initialize
mkdir -p "$LOGDIR"

log_doze() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DOZE_LOG"
}

# Load preferences
ENABLE_GMS_DOZE=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

# GMS Package and Components
GMS_PKG="com.google.android.gms"
GMS_ADMIN1="$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver"
GMS_ADMIN2="$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"

# FREEZE DOZE - Enable battery optimization for GMS
freeze_doze() {
  echo "═════════════════════════════════════" > "$DOZE_LOG"
  echo "💤 FROSTY Doze Log - FREEZE Operation" >> "$DOZE_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$DOZE_LOG"
  echo "Based on Universal GMS Doze by gloeyisk" >> "$DOZE_LOG"
  echo "═════════════════════════════════════" >> "$DOZE_LOG"
  echo "" >> "$DOZE_LOG"
  
  if [ "$ENABLE_GMS_DOZE" != "1" ]; then
    log_doze "[SKIP] GMS Doze disabled by user preference"
    echo ""
    echo "  💤 GMS Doze: SKIPPED (disabled in config)"
    echo ""
    return 0
  fi
  
  log_doze "[INFO] Enabling GMS battery optimization..."
  
  # Step 1: Patch conflicting module XMLs
  log_doze ""
  log_doze "━━━ Patching Conflicting Modules ━━━"
  
  patched_mods=0
  
  # Use temp file to avoid subshell variable scope issues
  TEMP_XML="$MODDIR/tmp_conflict_xml.txt"
  find /data/adb/modules -type f -name "*.xml" 2>/dev/null | grep -v "$MODDIR" > "$TEMP_XML"
  
  while read -r xml_file; do
    [ -z "$xml_file" ] && continue
    [ ! -f "$xml_file" ] && continue
    
    # Check if file contains GMS whitelist entries
    if grep -q "com.google.android.gms" "$xml_file" 2>/dev/null; then
      if grep -qE "allow-in-power-save|allow-in-data-usage-save|allow-unthrottled-location|allow-ignore-location-settings" "$xml_file" 2>/dev/null; then
        mod_name=$(echo "$xml_file" | cut -d'/' -f5)
        
        # Patch the file
        sed -i '/allow-in-power-save.*com.google.android.gms/d' "$xml_file" 2>/dev/null
        sed -i '/allow-in-data-usage-save.*com.google.android.gms/d' "$xml_file" 2>/dev/null
        sed -i '/allow-unthrottled-location.*com.google.android.gms/d' "$xml_file" 2>/dev/null
        sed -i '/allow-ignore-location-settings.*com.google.android.gms/d' "$xml_file" 2>/dev/null
        
        log_doze "[OK]   Patched: $mod_name - $xml_file"
        patched_mods=$((patched_mods + 1))
      fi
    fi
  done < "$TEMP_XML"
  
  rm -f "$TEMP_XML"
  log_doze "[INFO] Patched $patched_mods conflicting module XML(s)"
  
  # Step 2: Remove GMS from deviceidle whitelist
  log_doze ""
  log_doze "━━━ DeviceIdle Whitelist ━━━"
  
  if dumpsys deviceidle whitelist -$GMS_PKG >/dev/null 2>&1; then
    log_doze "[OK]   Removed $GMS_PKG from deviceidle whitelist"
  else
    log_doze "[FAIL] Could not modify deviceidle whitelist"
  fi
  
  # Step 3: Disable Device Admin Receivers (per user)
  log_doze ""
  log_doze "━━━ Device Admin Receivers ━━━"
  
  admin_count=0
  
  for user_id in $(ls /data/user 2>/dev/null); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm disable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK]   Disabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      fi
    done
  done
  
  log_doze "[INFO] Disabled $admin_count device admin receiver(s)"
  
  # Step 4: Verify optimization 
  log_doze ""
  log_doze "━━━ Verification ━━━"
  
  whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "$GMS_PKG")
  
  if [ -z "$whitelist_check" ]; then
    log_doze "[OK]   GMS is NOT in deviceidle whitelist (optimized)"
    is_optimized="YES"
  else
    log_doze "[WARN] GMS still appears in whitelist: $whitelist_check"
    is_optimized="NO"
  fi
  
  # Summary  
  log_doze ""
  log_doze "═════════════════════════════════════"
  log_doze "SUMMARY"
  log_doze "═════════════════════════════════════"
  log_doze "  Conflicting XMLs patched: $patched_mods"
  log_doze "  Device admins disabled:   $admin_count"
  log_doze "  GMS optimized:            $is_optimized"
  log_doze ""
  log_doze "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  log_doze "═════════════════════════════════════"
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  💤 GMS DOZE: ENABLED"
  echo ""
  echo "  Conflicting modules patched: $patched_mods"
  echo "  Device admins disabled: $admin_count"
  echo "  GMS optimized: $is_optimized"
  echo ""
  echo "  📄 Details: $DOZE_LOG"
  echo "═════════════════════════════════════════════"
  echo ""
}

# STOCK DOZE - Disable battery optimization for GMS
stock_doze() {
  echo "═════════════════════════════════════════════" > "$DOZE_LOG"
  echo "🔥 FROSTY Doze Log - STOCK Operation" >> "$DOZE_LOG"
  echo "Started: $(date '+%Y-%m-%d %H:%M:%S')" >> "$DOZE_LOG"
  echo "═════════════════════════════════════════════" >> "$DOZE_LOG"
  echo "" >> "$DOZE_LOG"
  
  log_doze "[INFO] Disabling GMS battery optimization (restoring stock)..."
  
  # Step 1: Remove patched XML overlays from module
  log_doze ""
  log_doze "━━━ Removing XML Patches ━━━"
  
  xml_removed=0
  
  # Use temp file approach
  TEMP_XML="$MODDIR/tmp_remove_xml.txt"
  find "$MODDIR/system" -type f -name "*.xml" 2>/dev/null > "$TEMP_XML"
  
  while read -r xml_file; do
    [ -z "$xml_file" ] && continue
    [ ! -f "$xml_file" ] && continue
    
    if rm -f "$xml_file" 2>/dev/null; then
      log_doze "[OK]   Removed: $xml_file"
      xml_removed=$((xml_removed + 1))
      
      # Clean up empty directories
      dir=$(dirname "$xml_file")
      while [ "$dir" != "$MODDIR/system" ] && [ -d "$dir" ]; do
        rmdir "$dir" 2>/dev/null || break
        dir=$(dirname "$dir")
      done
    else
      log_doze "[FAIL] Could not remove: $xml_file"
    fi
  done < "$TEMP_XML"
  
  rm -f "$TEMP_XML"
  log_doze "[INFO] Removed $xml_removed patched XML file(s)"
  
  # Step 2: Re-add GMS to deviceidle whitelist  
  log_doze ""
  log_doze "━━━ DeviceIdle Whitelist ━━━"
  
  if dumpsys deviceidle whitelist +$GMS_PKG >/dev/null 2>&1; then
    log_doze "[OK]   Added $GMS_PKG to deviceidle whitelist"
  else
    log_doze "[FAIL] Could not modify deviceidle whitelist"
  fi
  
  # Step 3: Re-enable Device Admin Receivers (per user)
  log_doze ""
  log_doze "━━━ Device Admin Receivers ━━━"
  
  admin_count=0
  
  for user_id in $(ls /data/user 2>/dev/null); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm enable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK]   Enabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      fi
    done
  done
  
  log_doze "[INFO] Enabled $admin_count device admin receiver(s)"
  
  # Summary
  log_doze ""
  log_doze "═════════════════════════════════════"
  log_doze "SUMMARY"
  log_doze "═════════════════════════════════════"
  log_doze "  XML patches removed:       $xml_removed"
  log_doze "  GMS re-added to whitelist: YES"
  log_doze "  Device admins re-enabled:  $admin_count"
  log_doze ""
  log_doze "Completed: $(date '+%Y-%m-%d %H:%M:%S')"
  log_doze "═════════════════════════════════════"
  
  echo ""
  echo "═════════════════════════════════════════════"
  echo "  🔥 GMS DOZE: DISABLED (Stock Mode)"
  echo ""
  echo "  XML patches removed: $xml_removed"
  echo "  Device admins re-enabled: $admin_count"
  echo ""
  echo "  ⚠️  Reboot recommended for full effect"
  echo ""
  echo "  📄 Details: $DOZE_LOG"
  echo "═════════════════════════════════════════════"
  echo ""
}

# STATUS - Check GMS Doze status
status() {
  whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "$GMS_PKG")
  
  if [ -z "$whitelist_check" ]; then
    is_optimized="YES"
  else
    is_optimized="NO"
  fi
  
  # Count patched XMLs
  xml_count=$(find "$MODDIR/system" -type f -name "*.xml" 2>/dev/null | wc -l)
  
  echo ""
  echo "═════════════════════════════════════"
  echo "  💤 GMS Doze Status"
  echo "═════════════════════════════════════"
  echo ""
  echo "  Enabled in config: $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "YES" || echo "NO")"
  echo "  GMS optimized:     $is_optimized"
  echo "  Patched XMLs:      $xml_count"
  echo ""
  
  if [ -n "$whitelist_check" ]; then
    echo "  Whitelist entry:"
    echo "    $whitelist_check"
    echo ""
  fi
  
  echo "  📄 Log: $DOZE_LOG"
  echo "═════════════════════════════════════"
  echo ""
}

# MAIN
case "$1" in
  freeze)
    freeze_doze
    ;;
  stock)
    stock_doze
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: doze.sh [freeze|stock|status]"
    ;;
esac

exit 0