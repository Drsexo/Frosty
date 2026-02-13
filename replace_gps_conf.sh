#!/system/bin/sh
# 🧊 FROSTY - GPS Conf Replacer (Versión Final)
# Reemplaza gps.conf con manejo de errores mejorado

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
LOGDIR="$MODDIR/logs"
GPS_LOG="$LOGDIR/gps_replace.log"
GPS_CONF_SRC="$MODDIR/system/etc/gps.conf"

mkdir -p "$LOGDIR"

log_gps() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$GPS_LOG"
}

# --- Rutas posibles para gps.conf ---
GPS_CONF_PATHS="/vendor/etc/gps.conf /system/vendor/etc/gps.conf"

# --- Hacer backup (opcional, no bloquear el proceso si falla) ---
backup_gps_conf() {
  local path="$1"
  if [ -f "$path" ]; then
    local backup="${path}.bak"
    if cp -f "$path" "$backup" 2>/dev/null; then
      log_gps "[OK] Backup de $path guardado en $backup"
      chmod 644 "$backup" 2>/dev/null
    else
      log_gps "[WARNING] No se pudo hacer backup de $path (continuando sin backup)"
    fi
  fi
}

# --- Reemplazar con magisk --copy (si falla cp normal) ---
replace_gps_conf() {
  local path="$1"
  backup_gps_conf "$path"

  # Intento 1: cp normal
  if cp -f "$GPS_CONF_SRC" "$path" 2>/dev/null; then
    chmod 644 "$path"
    chown root:root "$path" 2>/dev/null
    restorecon "$path" 2>/dev/null
    log_gps "[OK] gps.conf reemplazado en $path (cp normal)"
    return 0
  fi

  # Intento 2: magisk --copy (si está disponible)
  if command -v magisk >/dev/null; then
    if magisk --copy "$GPS_CONF_SRC" "$path" 2>/dev/null; then
      chmod 644 "$path"
      log_gps "[OK] gps.conf reemplazado en $path (magisk --copy)"
      return 0
    else
      log_gps "[ERROR] magisk --copy falló para $path"
    fi
  else
    log_gps "[WARNING] magisk no disponible para copiar $path"
  fi

  # Intento 3: dd (último recurso)
  if dd if="$GPS_CONF_SRC" of="$path" 2>/dev/null; then
    chmod 644 "$path"
    restorecon "$path" 2>/dev/null
    log_gps "[OK] gps.conf reemplazado en $path (dd)"
    return 0
  else
    log_gps "[ERROR] No se pudo reemplazar $path (todos los métodos fallaron)"
    return 1
  fi
}

# --- Reemplazar en todas las rutas ---
replace_gps_conf_all() {
  local replaced=0
  for path in $GPS_CONF_PATHS; do
    if [ -f "$path" ]; then
      log_gps "[INFO] Encontrado gps.conf en $path"
      if replace_gps_conf "$path"; then
        replaced=$((replaced + 1))
      fi
    else
      log_gps "[INFO] $path no existe. Saltando..."
    fi
  done
  if [ "$replaced" -gt 0 ]; then
    log_gps "[OK] $replaced archivos gps.conf reemplazados correctamente."
  else
    log_gps "[ERROR] No se pudo reemplazar gps.conf en ninguna ruta."
  fi
}

# --- Verificar si el archivo ya está optimizado ---
is_already_optimized() {
  for path in $GPS_CONF_PATHS; do
    if [ -f "$path" ] && grep -q "XTRA_VERSION_CHECK=3" "$path" 2>/dev/null; then
      log_gps "[INFO] gps.conf ya está optimizado en $path. No se requiere reemplazo."
      return 0
    fi
  done
  return 1
}

# --- Ejecutar ---
echo "Frosty GPS Conf Replacer - $(date '+%Y-%m-%d %H:%M:%S')" > "$GPS_LOG"
log_gps "Iniciando reemplazo de gps.conf..."
if is_already_optimized; then
  log_gps "[INFO] gps.conf ya está optimizado. Saltando reemplazo."
else
  replace_gps_conf_all
fi
log_gps "[OK] Proceso completado."