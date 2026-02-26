#!/system/bin/sh
# 🧊 FROSTY - GMS Doze Handler

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

LOGDIR="$MODDIR/logs"
DOZE_LOG="$LOGDIR/gms_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"

mkdir -p "$LOGDIR"

log_doze() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DOZE_LOG"; }

ENABLE_GMS_DOZE=0
DISABLE_LOCATION=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

GMS_PKG="com.google.android.gms"
GMS_ADMIN1="$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver"
GMS_ADMIN2="$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"

get_user_ids() {
  # Use pm list users, fallback to ls /data/user
  pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+' || ls /data/user 2>/dev/null
}

apply() {
  echo "Frosty GMS Doze - APPLY $(date '+%Y-%m-%d %H:%M:%S')" > "$DOZE_LOG"

  if [ "$ENABLE_GMS_DOZE" != "1" ]; then
    log_doze "[SKIP] GMS Doze disabled by user"
    echo "  💤 GMS Doze: SKIPPED"
    return 0
  fi

  log_doze "Applying GMS Doze..."
  log_doze "[OK] XML overlays active"

  # Disable device admin receivers per user
  admin_count=0
  for user_id in $(get_user_ids); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm disable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK] Disabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      fi
    done
  done
  log_doze "Disabled $admin_count device admin receiver(s)"

  # Remove GMS from deviceidle whitelist
  dumpsys deviceidle whitelist -$GMS_PKG >/dev/null 2>&1
  log_doze "[OK] Removed $GMS_PKG from deviceidle whitelist"

  # Verify
  whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "$GMS_PKG")
  if [ -z "$whitelist_check" ]; then
    log_doze "[OK] GMS optimized (not in whitelist)"
    is_optimized="YES"
  else
    log_doze "[WARN] GMS still in whitelist"
    is_optimized="NO"
  fi

  echo ""
  echo "  💤 GMS DOZE: APPLIED"
  echo "  Device admins disabled: $admin_count"
  echo "  GMS optimized: $is_optimized"
  echo ""
}

revert() {
  echo "Frosty GMS Doze - REVERT $(date '+%Y-%m-%d %H:%M:%S')" > "$DOZE_LOG"

  log_doze "Reverting GMS Doze..."

  dumpsys deviceidle whitelist +$GMS_PKG >/dev/null 2>&1
  log_doze "[OK] Added $GMS_PKG to deviceidle whitelist"

  admin_count=0
  for user_id in $(get_user_ids); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm enable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK] Enabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      fi
    done
  done
  log_doze "Re-enabled $admin_count device admin receiver(s)"
  log_doze "Reboot recommended for full XML overlay removal"

  echo ""
  echo "  🔥 GMS DOZE: REVERTED"
  echo "  Device admins re-enabled: $admin_count"
  echo "  Reboot to fully remove XML patches"
  echo ""
}

status() {
  whitelist_check=$(dumpsys deviceidle whitelist 2>/dev/null | grep "$GMS_PKG")
  [ -z "$whitelist_check" ] && is_optimized="YES" || is_optimized="NO"
  xml_count=$(find "$MODDIR/system" -type f -name "*.xml" 2>/dev/null | wc -l)

  echo ""
  echo "  💤 GMS Doze Status"
  echo "  Enabled: $([ "$ENABLE_GMS_DOZE" = "1" ] && echo "YES" || echo "NO")"
  echo "  GMS optimized: $is_optimized"
  echo "  Patched XMLs: $xml_count"
  echo ""
}

case "$1" in
  apply|freeze) apply ;;
  revert|stock) revert ;;
  status) status ;;
  *) echo "Usage: gms_doze.sh [apply|revert|status]" ;;
esac

exit 0