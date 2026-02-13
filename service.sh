#!/system/bin/sh
# 🧊 FROSTY - Service script (con Backup y Restauración del Kernel)
# Applies tweaks with backup/restore functionality

MODDIR="${0%/*}"
LOGDIR="$MODDIR/logs"
BACKUP_DIR="$MODDIR/backups"
mkdir -p "$LOGDIR" "$BACKUP_DIR"
BOOT_LOG="$LOGDIR/boot.log"
TWEAKS_LOG="$LOGDIR/tweaks.log"
ERROR_LOG="$LOGDIR/service_errors.log"
KERNEL_BACKUP="$BACKUP_DIR/kernel_backup.txt"

# --- Funciones de Seguridad y Logging ---
log_boot() {
  echo "[$(date '+%H:%M:%S')] $1" >> "$BOOT_LOG"
}

log_tweak() {
  echo "$1" >> "$TWEAKS_LOG"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$ERROR_LOG"
  log_boot "[ERROR] $1"
}

show_error_notification() {
  local title="Frosty Service Error"
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

# --- Función para escribir valores ---
write_val() {
  local file="$1" value="$2" name="$3"
  [ ! -f "$file" ] && { log_tweak "[SKIP] $name (archivo no existe)"; return 1; }
  chmod +w "$file" 2>/dev/null
  if echo "$value" > "$file" 2>/dev/null; then
    log_tweak "[OK] $name = $value"
  else
    # Ignorar errores conocidos en kernels GKI
    if [ "$name" = "sched_autogroup_enabled" ] || [ "$name" = "minfree" ]; then
      log_tweak "[INFO] $name ya está optimizado por el kernel GKI (ignorado)"
    else
      log_tweak "[FAIL] $name"
      log_error "Failed to write $name to $file"
    fi
  fi
}

# --- Función para hacer backup del kernel ---
backup_kernel_values() {
  log_boot "Haciendo backup de los valores originales del kernel..."
  echo "# Kernel Backup - $(date '+%Y-%m-%d %H:%M:%S')" > "$KERNEL_BACKUP"
  echo "# Valores originales del kernel GKI optimizado" >> "$KERNEL_BACKUP"

  # Backup de parámetros del scheduler
  echo "sched_autogroup_enabled=$(cat /proc/sys/kernel/sched_autogroup_enabled 2>/dev/null)" >> "$KERNEL_BACKUP"
  echo "sched_latency_ns=$(cat /proc/sys/kernel/sched_latency_ns 2>/dev/null)" >> "$KERNEL_BACKUP"
  echo "sched_min_granularity_ns=$(cat /proc/sys/kernel/sched_min_granularity_ns 2>/dev/null)" >> "$KERNEL_BACKUP"

  # Backup de parámetros de memoria (VM)
  echo "dirty_ratio=$(cat /proc/sys/vm/dirty_ratio 2>/dev/null)" >> "$KERNEL_BACKUP"
  echo "swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null)" >> "$KERNEL_BACKUP"
  echo "vfs_cache_pressure=$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null)" >> "$KERNEL_BACKUP"

  # Backup de parámetros de red
  echo "tcp_ecn=$(cat /proc/sys/net/ipv4/tcp_ecn 2>/dev/null)" >> "$KERNEL_BACKUP"
  echo "tcp_fastopen=$(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null)" >> "$KERNEL_BACKUP"

  # Backup de parámetros de depuración
  echo "printk=$(cat /proc/sys/kernel/printk 2>/dev/null)" >> "$KERNEL_BACKUP"

  log_boot "[OK] Backup del kernel guardado en $KERNEL_BACKUP"
}

# --- Función para restaurar valores del kernel ---
restore_kernel_values() {
  if [ ! -f "$KERNEL_BACKUP" ]; then
    log_error "No se encontró el backup del kernel en $KERNEL_BACKUP"
    return 1
  fi

  log_boot "Restaurando valores originales del kernel desde $KERNEL_BACKUP..."
  while IFS='=' read -r param value; do
    [ -z "$param" ] || [ "${param:0:1}" = "#" ] && continue
    case "$param" in
      sched_autogroup_enabled) write_val /proc/sys/kernel/sched_autogroup_enabled "$value" "sched_autogroup_enabled" ;;
      sched_latency_ns) write_val /proc/sys/kernel/sched_latency_ns "$value" "sched_latency_ns" ;;
      sched_min_granularity_ns) write_val /proc/sys/kernel/sched_min_granularity_ns "$value" "sched_min_granularity_ns" ;;
      dirty_ratio) write_val /proc/sys/vm/dirty_ratio "$value" "dirty_ratio" ;;
      swappiness) write_val /proc/sys/vm/swappiness "$value" "swappiness" ;;
      vfs_cache_pressure) write_val /proc/sys/vm/vfs_cache_pressure "$value" "vfs_cache_pressure" ;;
      tcp_ecn) write_val /proc/sys/net/ipv4/tcp_ecn "$value" "tcp_ecn" ;;
      tcp_fastopen) write_val /proc/sys/net/ipv4/tcp_fastopen "$value" "tcp_fastopen" ;;
      printk) echo "$value" > /proc/sys/kernel/printk ;;
      *) log_boot "[SKIP] Parámetro desconocido: $param" ;;
    esac
  done < "$KERNEL_BACKUP"
  log_boot "[OK] Valores del kernel restaurados desde backup"
}

# --- Función para verificar optimizaciones del kernel ---
check_kernel_optimizations() {
  log_boot "Verificando optimizaciones del kernel GKI..."
  KERNEL_OPTIMIZED=0

  # Verificar swappiness
  local swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null)
  if [ "$swappiness" -eq 100 ]; then
    log_boot "[INFO] swappiness ya está optimizado ($swappiness)"
    KERNEL_OPTIMIZED=1
  fi

  # Verificar sched_autogroup_enabled
  local autogroup=$(cat /proc/sys/kernel/sched_autogroup_enabled 2>/dev/null)
  if [ -n "$swappiness" ] && [ "$swappiness" -eq 100 ]; then
    log_boot "[INFO] sched_autogroup_enabled ya está optimizado ($autogroup)"
    KERNEL_OPTIMIZED=1
  fi

  # Verificar printk (depuración)
  local printk=$(cat /proc/sys/kernel/printk 2>/dev/null)
  if [ "$printk" = "0 0 0 0" ]; then
    log_boot "[INFO] printk ya está optimizado ($printk)"
    KERNEL_OPTIMIZED=1
  fi

  if [ "$KERNEL_OPTIMIZED" = "1" ]; then
    log_boot "[INFO] El kernel GKI ya está optimizado. Haciendo backup antes de aplicar tweaks..."
    backup_kernel_values
    return 1
  else
    log_boot "[INFO] Aplicando tweaks del módulo..."
    backup_kernel_values  # Hacer backup de todos modos
    return 0
  fi
}

# --- Inicio del Script ---
echo "Frosty Boot - $(date '+%Y-%m-%d %H:%M:%S')" > "$BOOT_LOG"
echo "Frosty Tweaks - $(date '+%Y-%m-%d %H:%M:%S')" > "$TWEAKS_LOG"
check_root

# Log rotation
for log in "$LOGDIR"/*.log; do
  [ -f "$log" ] || continue
  size=$(stat -c%s "$log" 2>/dev/null || echo 0)
  [ "$size" -gt 102400 ] && mv "$log" "${log}.old"
done

# Wait for boot
timeout=120
elapsed=0
log_boot "Waiting for boot completion..."
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
  elapsed=$((elapsed + 2))
  [ $elapsed -ge $timeout ] && break
done
sleep 30
log_boot "Boot initialized"

# Wait for GMS
gms_wait=0
log_boot "Waiting for GMS..."
while ! pidof com.google.android.gms >/dev/null 2>&1; do
  sleep 2
  gms_wait=$((gms_wait + 2))
  [ $gms_wait -ge 60 ] && break
done
log_boot "GMS ready"

# Device info
log_boot "Device: $(getprop ro.product.model)"
log_boot "Android: $(getprop ro.build.version.release) SDK$(getprop ro.build.version.sdk)"

mkdir -p "$MODDIR/config"

# Load preferences
if [ ! -f "$MODDIR/config/user_prefs" ]; then
  log_boot "Creating default user_prefs..."
  cat > "$MODDIR/config/user_prefs" << EOF
ENABLE_KERNEL_TWEAKS=1
ENABLE_BLUR_DISABLE=0
ENABLE_LOG_KILLING=1
ENABLE_GMS_DOZE=1
ENABLE_DEEP_DOZE=1
DEEP_DOZE_LEVEL=moderate
DISABLE_TELEMETRY=1
DISABLE_BACKGROUND=1
DISABLE_LOCATION=0
DISABLE_CONNECTIVITY=0
DISABLE_CLOUD=0
DISABLE_PAYMENTS=0
DISABLE_WEARABLES=0
DISABLE_GAMES=0
EOF
fi
. "$MODDIR/config/user_prefs" || log_error "Failed to load user_prefs"

[ ! -f "$MODDIR/config/state" ] && echo "frozen" > "$MODDIR/config/state"

# --- Kernel tweaks (con backup) ---
if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
  if check_kernel_optimizations; then
    log_boot "Aplicando tweaks no conflictivos..."

    # Solo aplicar tweaks seguros (ej: red)
    log_tweak ""
    log_tweak "NETWORK (no conflictivo)"
    write_val /proc/sys/net/ipv4/tcp_ecn 1 "tcp_ecn"
    write_val /proc/sys/net/ipv4/tcp_fastopen 3 "tcp_fastopen"

    # Verificar antes de modificar swappiness
    current_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null)
    if [ "$current_swappiness" -ne 100 ]; then
      write_val /proc/sys/vm/swappiness 100 "swappiness"
    else
      log_tweak "[INFO] swappiness ya optimizado ($current_swappiness)"
    fi

    log_boot "[OK] Kernel tweaks aplicados (con backup)"
  else
    log_boot "El kernel GKI ya está optimizado. Saltando tweaks duplicados."
  fi
else
  log_boot "Kernel tweaks SKIPPED"
fi

# --- Kill log processes ---
if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  log_boot "Killing log processes..."
  for svc in logcat logcatd logd tcpdump cnss_diag statsd traced idd-logreader idd-logreadermain dumpstate aplogd vendor.tcpdump vendor.cnss_diag; do
    pid=$(pidof "$svc" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill -15 "$pid" 2>/dev/null
      sleep 0.5
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
      log_boot "Killed $svc (PID $pid)"
    fi
  done
  logcat -c 2>/dev/null
  dmesg -c >/dev/null 2>&1
  log_boot "Log processes killed"
else
  log_boot "Log killing SKIPPED"
fi

# --- Apply GMS freezing ---
log_boot "Applying GMS freezing..."
if [ -f "$MODDIR/frosty.sh" ]; then
  chmod +x "$MODDIR/frosty.sh"
  if ! "$MODDIR/frosty.sh" freeze >> "$BOOT_LOG" 2>&1; then
    log_error "Failed to apply GMS freezing"
    show_error_notification "Failed to apply GMS freezing. Check logs."
  fi
else
  log_error "frosty.sh not found"
  show_error_notification "frosty.sh not found. GMS freezing skipped."
fi

log_boot "Boot complete at $(date '+%Y-%m-%d %H:%M:%S')"

exit 0
