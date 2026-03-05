#!/system/bin/sh
# FROSTY - Service script

MODDIR="${0%/*}"
LOGDIR="$MODDIR/logs"
BACKUP_DIR="$MODDIR/backup"
mkdir -p "$LOGDIR" "$BACKUP_DIR"
BOOT_LOG="$LOGDIR/boot.log"
TWEAKS_LOG="$LOGDIR/tweaks.log"
PROPS_LOG="$LOGDIR/props.log"
RAM_LOG="$LOGDIR/ram.log"
KERNEL_BACKUP="$BACKUP_DIR/kernel_values.txt"
KERNEL_TWEAKS="$MODDIR/config/kernel_tweaks.txt"
RAM_BACKUP="$BACKUP_DIR/ram_values.txt"
RAM_TWEAKS="$MODDIR/config/ram_tweaks.txt"

# Timeout fallback
if ! command -v timeout >/dev/null 2>&1; then
  timeout() { shift; "$@"; }
fi

# Log rotation
for log in "$LOGDIR"/*.log; do
  [ -f "$log" ] || continue
  size=$(wc -c < "$log" 2>/dev/null)
  size=${size:-0}
  [ "$size" -gt 102400 ] && mv "$log" "${log}.old"
done

log_boot()  { echo "[$(date '+%H:%M:%S')] $1" >> "$BOOT_LOG"; }
log_tweak() { echo "$1" >> "$TWEAKS_LOG"; }
log_props() { echo "[$(date '+%H:%M:%S')] $1" >> "$PROPS_LOG"; }
log_ram()   { echo "$1" >> "$RAM_LOG"; }

echo "Frosty Boot - $(date '+%Y-%m-%d %H:%M:%S')" > "$BOOT_LOG"
echo "Frosty Tweaks - $(date '+%Y-%m-%d %H:%M:%S')" > "$TWEAKS_LOG"
echo "Frosty Props - $(date '+%Y-%m-%d %H:%M:%S')" > "$PROPS_LOG"
echo "Frosty RAM - $(date '+%Y-%m-%d %H:%M:%S')" > "$RAM_LOG"

# Wait for boot
until [ "$(getprop sys.boot_completed)" = "1" ] && [ -d /sdcard ]; do
  sleep 5
done
sleep 10
log_boot "Boot initialized"

# Device info
log_boot "Device: $(getprop ro.product.model)"
log_boot "Android: $(getprop ro.build.version.release) SDK$(getprop ro.build.version.sdk)"

mkdir -p "$MODDIR/config"

# Load preferences (default everything is off)
. "$MODDIR/config/user_prefs" 2>/dev/null || true

# System props status
SYSPROP="$MODDIR/system.prop"
SYSPROP_OLD="$MODDIR/system.prop.old"

log_props "Device: $(getprop ro.product.model) Android $(getprop ro.build.version.release)"
log_props ""

if [ "$ENABLE_SYSTEM_PROPS" = "1" ]; then
  if [ -f "$SYSPROP" ]; then
    PROP_COUNT=$(grep -c '^[^#]' "$SYSPROP" 2>/dev/null || echo "0")
    log_props "[OK] system.prop is ACTIVE — $PROP_COUNT props loaded at boot"
    log_boot "System props: ACTIVE ($PROP_COUNT props)"
  else
    log_props "[WARN] ENABLE_SYSTEM_PROPS=1 but system.prop is missing"
    log_boot "System props: WARNING — file missing despite being enabled"
  fi
else
  if [ -f "$SYSPROP_OLD" ]; then
    log_props "[OFF] system.prop is DISABLED (system.prop.old present)"
    log_boot "System props: DISABLED (.old present)"
  else
    log_props "[OFF] system.prop is DISABLED (no .old file found)"
    log_boot "System props: DISABLED"
  fi
fi

log_props ""

write_val() {
  local file="$1" value="$2" name="$3"
  [ ! -f "$file" ] && { log_tweak "[SKIP] $name"; return 1; }
  chmod +w "$file" 2>/dev/null
  if echo "$value" > "$file" 2>/dev/null; then
    log_tweak "[OK] $name = $value"
    return 0
  else
    log_tweak "[FAIL] $name"
    return 1
  fi
}

# Back up current kernel values before tweaking.
backup_kernel() {
  log_boot "Backing up kernel values..."
  echo "# Kernel Backup - $(date '+%Y-%m-%d %H:%M:%S')" > "$KERNEL_BACKUP"

  if [ ! -f "$KERNEL_TWEAKS" ]; then
    log_boot "WARNING: kernel_tweaks.txt not found, skipping backup"
    return
  fi

  while IFS= read -r line; do
    case "$line" in '#'*|'') continue ;; esac
    path="${line%%|*}"
    path=$(echo "$path" | tr -d ' ')
    [ -z "$path" ] || [ ! -f "$path" ] && continue
    name=$(basename "$path")
    val=$(cat "$path" 2>/dev/null)
    echo "$name=$val=$path" >> "$KERNEL_BACKUP"
  done < "$KERNEL_TWEAKS"

  log_boot "Kernel backup saved"
}

# Back up current RAM sysfs values before tweaking.
backup_ram() {
  log_boot "Backing up RAM sysfs values..."
  echo "# RAM Backup - $(date '+%Y-%m-%d %H:%M:%S')" > "$RAM_BACKUP"

  if [ ! -f "$RAM_TWEAKS" ]; then
    log_boot "WARNING: ram_tweaks.txt not found, skipping RAM backup"
    return
  fi

  while IFS= read -r line; do
    case "$line" in '#'*|'') continue ;; esac
    path="${line%%|*}"
    path=$(echo "$path" | tr -d ' ')
    [ -z "$path" ] || [ ! -f "$path" ] && continue
    name=$(basename "$path")
    val=$(cat "$path" 2>/dev/null)
    echo "$name=$val=$path" >> "$RAM_BACKUP"
  done < "$RAM_TWEAKS"

  log_boot "RAM backup saved"
}

# Apply all tweaks from kernel_tweaks.txt.
apply_kernel_tweaks() {
  if [ ! -f "$KERNEL_TWEAKS" ]; then
    log_boot "ERROR: kernel_tweaks.txt not found at $KERNEL_TWEAKS, reinstall"
    return 1
  fi

  local last_section="" count_ok=0 count_fail=0 count_skip=0

  while IFS= read -r line; do
    case "$line" in
      '# '*)
        # Section header comment — print to tweaks log
        section=$(echo "$line" | sed 's/^# ── *//;s/ *─*$//')
        if [ "$section" != "$last_section" ]; then
          last_section="$section"
          log_tweak ""
          log_tweak "$section"
        fi
        continue
        ;;
      '#'*|'') continue ;;
    esac

    path="${line%%|*}"
    value="${line#*|}"
    path=$(echo "$path" | tr -d ' ')
    [ -z "$path" ] || [ -z "$value" ] && continue
    name=$(basename "$path")

    if write_val "$path" "$value" "$name"; then
      count_ok=$((count_ok + 1))
    else
      [ ! -f "$path" ] && count_skip=$((count_skip + 1)) || count_fail=$((count_fail + 1))
    fi
  done < "$KERNEL_TWEAKS"

  # Dynamic debug masks
  log_tweak ""
  log_tweak "DEBUG MASKS (dynamic)"
  local debug_count=0
  for pattern in debug_mask log_level debug_level enable_event_log tracing_on; do
    for dpath in $(find /sys/ -maxdepth 4 -type f -name "*${pattern}*" 2>/dev/null | head -20); do
      if write_val "$dpath" 0 "$(basename "$dpath")"; then
        debug_count=$((debug_count + 1))
      fi
    done
  done
  log_tweak "Disabled $debug_count debug masks"

  log_boot "Kernel tweaks applied (ok=$count_ok skip=$count_skip fail=$count_fail)"
}

# Kernel tweaks
if [ "$ENABLE_KERNEL_TWEAKS" = "1" ]; then
  log_boot "Applying kernel tweaks..."
  backup_kernel
  apply_kernel_tweaks
else
  log_boot "Kernel tweaks SKIPPED"
fi

# RAM Optimizer
if [ "$ENABLE_RAM_OPTIMIZER" = "1" ]; then
  log_boot "Applying RAM optimizer..."
  backup_ram
  sh "$MODDIR/frosty.sh" ram_optimizer >> "$RAM_LOG" 2>/dev/null
else
  log_boot "RAM optimizer SKIPPED"
fi

# Kill log processes
if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  log_boot "Killing log processes..."
  for svc in logcat logcatd logd tcpdump cnss_diag statsd traced idd-logreader idd-logreadermain dumpstate aplogd vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    pid=$(pidof "$svc" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill -15 "$pid" 2>/dev/null
      sleep 0.5
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi
  done
  logcat -c 2>/dev/null
  dmesg -c >/dev/null 2>&1
  log_boot "Log processes killed"
else
  log_boot "Log killing SKIPPED"
fi

# Apply GMS freezing if any category is enabled
has_frozen_cats=0
for _cat in DISABLE_TELEMETRY DISABLE_BACKGROUND DISABLE_LOCATION DISABLE_CONNECTIVITY \
            DISABLE_CLOUD DISABLE_PAYMENTS DISABLE_WEARABLES DISABLE_GAMES; do
  eval _val=\$$_cat
  [ "$_val" = "1" ] && { has_frozen_cats=1; break; }
done
if [ "$has_frozen_cats" = "1" ]; then
  log_boot "GMS categories enabled — applying freeze..."
  chmod +x "$MODDIR/frosty.sh"
  "$MODDIR/frosty.sh" freeze
else
  log_boot "No GMS categories enabled, skipping GMS freeze"
fi

# GMS Doze
if [ "$ENABLE_GMS_DOZE" = "1" ]; then
  log_boot "Applying GMS Doze..."
  chmod +x "$MODDIR/gms_doze.sh"
  "$MODDIR/gms_doze.sh" apply
else
  log_boot "GMS Doze SKIPPED"
fi

# Deep Doze
if [ "$ENABLE_DEEP_DOZE" = "1" ]; then
  log_boot "Applying Deep Doze..."
  chmod +x "$MODDIR/deep_doze.sh"
  "$MODDIR/deep_doze.sh" freeze
else
  log_boot "Deep Doze SKIPPED"
fi

log_boot "Boot complete at $(date '+%Y-%m-%d %H:%M:%S')"

exit 0
