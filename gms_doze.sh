#!/system/bin/sh
# 🧊 FROSTY - GMS Doze Handler (Optimizado para sh)
# Handles GMS battery optimization with detailed logging and safety checks

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/FrostyEnhanced"

LOGDIR="$MODDIR/logs"
DOZE_LOG="$LOGDIR/gms_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
ERROR_LOG="$LOGDIR/gms_doze_errors.log"

mkdir -p "$LOGDIR"

# --- Funciones de Seguridad y Logging ---
log_doze() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DOZE_LOG"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
  log_doze "[ERROR] $1"
}

show_error_notification() {
  local title="Frosty GMS Doze Error"
  local message="$1"
  su -c "cmd notification post -S bigtext -t '$title' 'Frosty Module' '$message'" 2>/dev/null
  log_error "$message"
}

disable_module_safely() {
  local reason="$1"
  show_error_notification "$reason"
  echo "stock" > "$MODDIR/config/state"
  exit 1
}

check_root() {
  if ! su -c "echo 'root check'" >/dev/null 2>&1; then
    disable_module_safely "No root access."
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# --- Verificar si el usuario quiere desactivar la localización ---
should_disable_location() {
  if [ "$DISABLE_LOCATION" != "1" ]; then
    log_doze "[INFO] El usuario NO ha desactivado la localización. Excluyendo servicios de ubicación de la optimización."
    return 1  # No desactivar localización
  else
    log_doze "[INFO] El usuario HA desactivado la localización. Aplicando optimizaciones."
    return 0  # Desactivar localización
  fi
}

# --- Funciones para Excluir Servicios de Ubicación ---
exclude_location_services() {
  for service in \
    "com.google.android.gms"; do
    if dumpsys deviceidle whitelist +"$service" >/dev/null 2>&1; then
      log_doze "[OK] Excluido de la optimización: $service"
    else
      log_error "No se pudo excluir: $service"
    fi
  done
}

# --- Limitar consumo de GMS en segundo plano ---
limit_gms_background() {
  log_doze "Limiting GMS background activity..."
  su -c "appops set com.google.android.gms RUN_IN_BACKGROUND ignore" 2>/dev/null
  su -c "appops set com.google.android.gms WAKE_LOCK ignore" 2>/dev/null
  su -c "dumpsys battery unforce-allow com.google.android.gms" 2>/dev/null
  log_doze "[OK] GMS background activity limited"
}

# --- Aplicar Lista Blanca ---
apply_whitelist() {
  log_doze "Aplicando lista blanca..."

  # --- YouTube ---
  for service in \
    com.google.android.youtube \
    com.google.android.apps.youtube.music \
    com.google.android.youtube.tv
  do
    if ! dumpsys deviceidle whitelist | grep -q "$service"; then
      log_doze "[OK] Añadiendo YouTube a la lista blanca: $service"
      dumpsys deviceidle whitelist +"$service" >> "$DOZE_LOG" 2>&1
    fi
  done

  # --- Servicios críticos de ubicación ---
  for service in \
    com.google.android.gms \
    com.xiaomi.location.fused \
    com.miui.location.fused
  do
    if ! dumpsys deviceidle whitelist | grep -q "$service"; then
      log_doze "[OK] Añadiendo servicio crítico de ubicación: $service"
      dumpsys deviceidle whitelist +"$service" >> "$DOZE_LOG" 2>&1
    fi
  done

  # --- Archivo externo ---
  if [ -f "$MODDIR/config/doze_whitelist.txt" ]; then
    while IFS= read -r package; do
      # Saltar líneas vacías o comentarios
      case "$package" in
        ""|\#*) continue ;;
      esac

      if ! dumpsys deviceidle whitelist | grep -q "$package"; then
        log_doze "[OK] Añadido desde archivo: $package"
        dumpsys deviceidle whitelist +"$package" >> "$DOZE_LOG" 2>&1
      fi
    done < "$MODDIR/config/doze_whitelist.txt"
  else
    log_error "No se encontró el archivo doze_whitelist.txt"
  fi
}

# --- Inicio del Script ---
check_root
[ -f "$USER_PREFS" ] && . "$USER_PREFS" || log_error "Could not load user preferences."

GMS_PKG="com.google.android.gms"
GMS_ADMIN1="$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver"
GMS_ADMIN2="$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"

# --- Funciones Principales ---
freeze_doze() {
  echo "Frosty GMS Doze - FREEZE $(date '+%Y-%m-%d %H:%M:%S')" > "$DOZE_LOG"

  if [ "$ENABLE_GMS_DOZE" != "1" ]; then
    log_doze "[SKIP] GMS Doze disabled"
    echo "  💤 GMS Doze: SKIPPED"
    return 0
  fi

  log_doze "Enabling GMS battery optimization..."
  apply_whitelist  # Aplicar lista blanca
  limit_gms_background  # Limitar consumo de GMS en segundo plano

  # Verificar si el usuario quiere desactivar la localización
  if should_disable_location; then
    exclude_location_services  # Excluir servicios de ubicación solo si el usuario lo permitió
  else
    log_doze "[INFO] Saltando optimización de servicios de ubicación (configuración del usuario)."
  fi

  # Remove from deviceidle whitelist
  if dumpsys deviceidle whitelist -"$GMS_PKG" >/dev/null 2>&1; then
    log_doze "[OK] Removed $GMS_PKG from deviceidle whitelist"
  else
    log_error "Could not modify deviceidle whitelist"
  fi

  # Disable device admin receivers per user
  admin_count=0
  for user_id in $(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+'); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm disable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK] Disabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      else
        log_error "Failed to disable $admin (user $user_id)"
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
    log_error "GMS still in whitelist after removal attempt"
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
  if dumpsys deviceidle whitelist +"$GMS_PKG" >/dev/null 2>&1; then
    log_doze "[OK] Added $GMS_PKG to deviceidle whitelist"
  else
    log_error "Could not modify deviceidle whitelist"
  fi

  # Re-enable device admin receivers
  admin_count=0
  for user_id in $(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+'); do
    for admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
      if pm enable --user "$user_id" "$admin" >/dev/null 2>&1; then
        log_doze "[OK] Enabled: $admin (user $user_id)"
        admin_count=$((admin_count + 1))
      else
        log_error "Failed to enable $admin (user $user_id)"
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

# --- Ejecución ---
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
    echo "Usage: gms_doze.sh [freeze|stock|status]"
    exit 1
    ;;
esac

exit 0