#!/system/bin/sh
# 🧊 FROSTY - GMS Doze Handler
# Handles GMS battery optimization with detailed logging


MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
DOZE_LOG="$LOGDIR/gms_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"

mkdir -p "$LOGDIR"

log_doze() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DOZE_LOG"; }

ENABLE_GMS_DOZE=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

GMS_PKG="com.google.android.gms"
GMS_ADMIN1="$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver"
GMS_ADMIN2="$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"

freeze_doze() {
  echo "Frosty GMS Doze - FREEZE $(date '+%Y-%m-%d %H:%M:%S')" > "$DOZE_LOG"

  if [ "$ENABLE_GMS_DOZE" != "1" ]; then
    log_doze "[SKIP] GMS Doze disabled"
    echo "  💤 GMS Doze: SKIPPED"
    return 0
  fi

  log_doze "Enabling GMS battery optimization..."

  # XML overlays are handled at install time and by post-fs-data.sh
  log_doze "[OK] XML overlays active (applied at install)"

  # Remove from deviceidle whitelist
  if dumpsys deviceidle whitelist -$GMS_PKG >/dev/null 2>&1; then
    log_doze "[OK] Removed $GMS_PKG from deviceidle whitelist"
  else
    log_doze "[FAIL] Could not modify deviceidle whitelist"
  fi

  # Disable device admin receivers per user
  admin_count=0
  for user_id in $(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+'); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm disable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK] Disabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      fi
    done
  done
  log_doze "Disabled $admin_count device admin receiver(s)"

  # Verify
  whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "$GMS_PKG")
  if [ -z "$whitelist_check" ]; then
    log_doze "[OK] GMS NOT in whitelist (verified)"
    is_optimized="YES"
  else
    log_doze "[WARN] GMS still in whitelist"
    is_optimized="NO"
  fi

  echo ""
  echo "  💤 GMS DOZE: ENABLED"
  echo "  Device admins disabled: $admin_count"
  echo "  GMS optimized: $is_optimized"
  echo ""
}

stock_doze() {
  echo "Frosty GMS Doze - STOCK $(date '+%Y-%m-%d %H:%M:%S')" > "$DOZE_LOG"

  log_doze "Disabling GMS battery optimization..."

  # Re-add to whitelist
  if dumpsys deviceidle whitelist +$GMS_PKG >/dev/null 2>&1; then
    log_doze "[OK] Added $GMS_PKG to deviceidle whitelist"
  else
    log_doze "[FAIL] Could not modify deviceidle whitelist"
  fi

  # Re-enable device admin receivers
  admin_count=0
  for user_id in $(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+'); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm enable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK] Enabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      fi
    done
  done

  log_doze "Re-enabled $admin_count device admin receiver(s)"
  log_doze "Reboot recommended for XML overlay removal"

  echo ""
  echo "  🔥 GMS DOZE: DISABLED"
  echo "  Device admins re-enabled: $admin_count"
  echo "  Reboot recommended for full effect"
  echo ""
}

status() {
  whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "$GMS_PKG")
  [ -z "$whitelist_check" ] && is_optimized="YES" || is_optimized="NO"
  xml_count=$(find "$MODDIR/system" -type f -name "*.xml" 2>/dev/null | wc -l)

  echo ""
  echo "  💤 GMS Doze Status"
  echo "  Enabled: $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "YES" || echo "NO")"
  echo "  Optimized: $is_optimized"
  echo "  Patched XMLs: $xml_count"
  echo ""
}

case "$1" in
  freeze) freeze_doze ;;
  stock) stock_doze ;;
  status) status ;;
  *) echo "Usage: gms_doze.sh [freeze|stock|status]" ;;
esac

exit 0