#!/system/bin/sh
# Frosty - Main Service Handler

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
SERVICES_LOG="$LOGDIR/services.log"
RAM_LOG="$LOGDIR/ram.log"
TWEAKS_LOG="$LOGDIR/kernel_tweaks.log"
PROPS_LOG="$LOGDIR/props.log"
BS_LOG="$LOGDIR/battery_saver.log"
SOO_LOG="$LOGDIR/screen_off_opt.log"
GMS_LIST="$MODDIR/config/gms_services.txt"
USER_PREFS="$MODDIR/config/user_prefs"
KERNEL_TWEAKS="$MODDIR/config/kernel_tweaks.txt"
KERNEL_BACKUP="$MODDIR/backup/kernel_values.txt"
RAM_TWEAKS="$MODDIR/config/ram_tweaks.txt"
RAM_BACKUP="$MODDIR/backup/ram_values.txt"
SYSPROP="$MODDIR/system.prop"
SYSPROP_OLD="$MODDIR/system.prop.old"

mkdir -p "$LOGDIR" "$MODDIR/config"
log_service() { echo "$1" >> "$SERVICES_LOG"; }
log_ram()     { echo "[$(date '+%H:%M:%S')] $1" >> "$RAM_LOG"; }
log_tweak()   { echo "$1" >> "$TWEAKS_LOG"; }
log_props()   { echo "[$(date '+%H:%M:%S')] $1" >> "$PROPS_LOG"; }

load_prefs() {
  if [ -f "$USER_PREFS" ]; then
    . "$USER_PREFS"
  fi
}

should_disable_category() {
  case "$1" in
    background)   [ "$DISABLE_BACKGROUND" = "1" ] ;;
    telemetry)    [ "$DISABLE_TELEMETRY" = "1" ] ;;
    location)     [ "$DISABLE_LOCATION" = "1" ] ;;
    connectivity) [ "$DISABLE_CONNECTIVITY" = "1" ] ;;
    cloud)        [ "$DISABLE_CLOUD" = "1" ] ;;
    payments)     [ "$DISABLE_PAYMENTS" = "1" ] ;;
    wearables)    [ "$DISABLE_WEARABLES" = "1" ] ;;
    games)        [ "$DISABLE_GAMES" = "1" ] ;;
    *) return 1 ;;
  esac
}

load_prefs

apply_system_props() {
  if [ "$ENABLE_SYSTEM_PROPS" = "1" ]; then
    if [ -f "$SYSPROP_OLD" ]; then
      mv "$SYSPROP_OLD" "$SYSPROP"
    fi
    echo "Frosty v${MODVER:-?} - Props - $(date '+%Y-%m-%d %H:%M:%S')" > "$PROPS_LOG"
    if [ -f "$SYSPROP" ]; then
      local pc=$(grep -c '^[^#]' "$SYSPROP" 2>/dev/null || echo "0")
      log_props "[OK] system.prop ENABLED - $pc props, reboot for effect"
    else
      log_props "[WARN] system.prop ENABLED but file missing"
    fi
    echo '{"status":"ok","action":"enabled"}'
  else
    if [ -f "$SYSPROP" ]; then
      mv "$SYSPROP" "$SYSPROP_OLD"
    fi
    echo "Frosty v${MODVER:-?} - Props - $(date '+%Y-%m-%d %H:%M:%S')" > "$PROPS_LOG"
    log_props "[OK] system.prop DISABLED, reboot for effect"
    echo '{"status":"ok","action":"disabled"}'
  fi
}

freeze_services() {
  echo "Frosty v${MODVER:-?} - Services (FREEZE) - $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  [ ! -f "$GMS_LIST" ] && { echo "ERROR: Service list not found"; return 1; }

  local current_category="" count_ok=0 count_fail=0 count_skip=0 count_enabled=0

  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in ''|'#'*) continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    [ -z "$category" ] && continue

    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      _cap_f=$(printf '%s' "$current_category" | cut -c1 | tr 'a-z' 'A-Z')
      _cap_r=$(printf '%s' "$current_category" | cut -c2-)
      log_service "# ${_cap_f}${_cap_r}"
    fi

    if should_disable_category "$category"; then
      if pm disable "$service" >/dev/null 2>&1; then
        log_service "[OK] $service"
        count_ok=$((count_ok + 1))
      else
        log_service "[FAIL] $service"
        count_fail=$((count_fail + 1))
      fi
    else
      if pm enable "$service" >/dev/null 2>&1; then
        log_service "[ENABLE] $service"
        count_enabled=$((count_enabled + 1))
      else
        log_service "[SKIP] $service"
        count_skip=$((count_skip + 1))
      fi
    fi
  done < "$GMS_LIST"

  log_service ""
  log_service "Summary: $count_ok disabled, $count_enabled re-enabled, $count_fail failed, $count_skip skipped"
  echo "  Disabled: $count_ok  Re-enabled: $count_enabled  Failed: $count_fail"
}

stock_services() {
  echo "Frosty v${MODVER:-?} - Services (STOCK) - $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  [ ! -f "$GMS_LIST" ] && { echo "ERROR: Service list not found"; return 1; }

  local current_category="" count_ok=0 count_fail=0

  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in ''|'#'*) continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    [ -z "$category" ] && continue

    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      _cap_f=$(printf '%s' "$current_category" | cut -c1 | tr 'a-z' 'A-Z')
      _cap_r=$(printf '%s' "$current_category" | cut -c2-)
      log_service "# ${_cap_f}${_cap_r}"
    fi

    if pm enable "$service" >/dev/null 2>&1; then
      log_service "[OK] $service"
      count_ok=$((count_ok + 1))
    else
      log_service "[FAIL] $service"
      count_fail=$((count_fail + 1))
    fi
  done < "$GMS_LIST"

  log_service ""
  log_service "Summary: $count_ok re-enabled, $count_fail failed"
  echo "  Re-enabled: $count_ok  Failed: $count_fail"
}

freeze_category() {
  local target="$1" count=0 fail=0
  [ ! -f "$GMS_LIST" ] && { echo '{"status":"error","message":"gms_services.txt not found"}'; return; }

  local _jobs_tmp="/data/local/tmp/frosty_jobs_$$"
  : > "$_jobs_tmp"

  while IFS='|' read -r svc cat || [ -n "$svc" ]; do
    case "$svc" in ''|'#'*) continue ;; esac
    svc=$(echo "$svc" | tr -d " ")
    cat=$(echo "$cat" | tr -d " ")
    [ "$cat" = "$target" ] || continue
    if pm disable "$svc" >/dev/null 2>&1; then
      count=$((count + 1))
      printf '%s\n' "$(printf '%s' "$svc" | cut -d/ -f1)" >> "$_jobs_tmp"
    else
      fail=$((fail + 1))
    fi
  done < "$GMS_LIST"

  sort -u "$_jobs_tmp" 2>/dev/null | while IFS= read -r _pkg; do
    [ -n "$_pkg" ] && cmd jobscheduler cancel -u 0 "$_pkg" >/dev/null 2>&1
  done
  rm -f "$_jobs_tmp"

  echo "{\"status\":\"ok\",\"disabled\":$count,\"failed\":$fail}"
}

unfreeze_category() {
  local target="$1" count=0 fail=0
  [ ! -f "$GMS_LIST" ] && { echo '{"status":"error","message":"gms_services.txt not found"}'; return; }

  while IFS='|' read -r svc cat || [ -n "$svc" ]; do
    case "$svc" in ''|'#'*) continue ;; esac
    svc=$(echo "$svc" | tr -d " ")
    cat=$(echo "$cat" | tr -d " ")
    [ "$cat" = "$target" ] || continue
    if pm enable "$svc" >/dev/null 2>&1; then
      count=$((count + 1))
    else
      fail=$((fail + 1))
    fi
  done < "$GMS_LIST"
  echo "{\"status\":\"ok\",\"enabled\":$count,\"failed\":$fail}"
}

backup_settings() {
  local dir="/storage/emulated/0/Frosty"
  mkdir -p "$dir" 2>/dev/null || { echo "ERROR: Cannot write to /storage/emulated/0/Frosty"; return 1; }
  local ts=$(date '+%Y%m%d_%H%M%S')
  local out="$dir/frosty_$ts.json"

  load_prefs
  local wl_b64=""
  [ -f "$MODDIR/config/doze_whitelist.txt" ] && wl_b64=$(base64 < "$MODDIR/config/doze_whitelist.txt" | tr -d '\n')
  local patches_b64=""
  [ -f "$MODDIR/config/doze_patches.txt" ] && patches_b64=$(base64 < "$MODDIR/config/doze_patches.txt" | tr -d '\n')

  cat > "$out" << ENDJSON
{
  "version": "${MODVER:-unknown}",
  "exported": "$ts",
  "prefs": {
    "ENABLE_KERNEL_TWEAKS": ${ENABLE_KERNEL_TWEAKS:-0},
    "ENABLE_RAM_OPTIMIZER": ${ENABLE_RAM_OPTIMIZER:-0},
    "ENABLE_SYSTEM_PROPS": ${ENABLE_SYSTEM_PROPS:-0},
    "ENABLE_BLUR_DISABLE": ${ENABLE_BLUR_DISABLE:-0},
    "ENABLE_LOG_KILLING": ${ENABLE_LOG_KILLING:-0},
    "ENABLE_KILL_TRACKING": ${ENABLE_KILL_TRACKING:-0},
    "ENABLE_DEEP_DOZE": ${ENABLE_DEEP_DOZE:-0},
    "DEEP_DOZE_LEVEL": "${DEEP_DOZE_LEVEL:-moderate}",
    "ENABLE_BATTERY_SAVER": ${ENABLE_BATTERY_SAVER:-0},
    "BSS_SOUNDTRIGGER_DISABLED": ${BSS_SOUNDTRIGGER_DISABLED:-0},
    "BSS_FULLBACKUP_DEFERRED": ${BSS_FULLBACKUP_DEFERRED:-0},
    "BSS_KEYVALUEBACKUP_DEFERRED": ${BSS_KEYVALUEBACKUP_DEFERRED:-0},
    "BSS_FORCE_STANDBY": ${BSS_FORCE_STANDBY:-0},
    "BSS_FORCE_BG_CHECK": ${BSS_FORCE_BG_CHECK:-0},
    "BSS_SENSORS_DISABLED": ${BSS_SENSORS_DISABLED:-0},
    "BSS_GPS_MODE": ${BSS_GPS_MODE:-0},
    "BSS_DATASAVER": ${BSS_DATASAVER:-0},
    "DISABLE_TELEMETRY": ${DISABLE_TELEMETRY:-0},
    "DISABLE_BACKGROUND": ${DISABLE_BACKGROUND:-0},
    "DISABLE_LOCATION": ${DISABLE_LOCATION:-0},
    "DISABLE_CONNECTIVITY": ${DISABLE_CONNECTIVITY:-0},
    "DISABLE_CLOUD": ${DISABLE_CLOUD:-0},
    "DISABLE_PAYMENTS": ${DISABLE_PAYMENTS:-0},
    "DISABLE_WEARABLES": ${DISABLE_WEARABLES:-0},
    "DISABLE_GAMES": ${DISABLE_GAMES:-0},
    "ENABLE_CUSTOM_APP_DOZE": ${ENABLE_CUSTOM_APP_DOZE:-0},
    "ENABLE_SCREEN_OFF_OPT": ${ENABLE_SCREEN_OFF_OPT:-0},
    "SOO_KILL_WIFI": ${SOO_KILL_WIFI:-0},
    "SOO_KILL_BT": ${SOO_KILL_BT:-0},
    "SOO_KILL_DATA": ${SOO_KILL_DATA:-0},
    "SOO_KILL_LOCATION": ${SOO_KILL_LOCATION:-0},
    "SOO_CONN_DELAY": ${SOO_CONN_DELAY:-5},
    "SOO_RESTORE_ON_UNLOCK": ${SOO_RESTORE_ON_UNLOCK:-1},
    "SOO_KILL_CACHE": ${SOO_KILL_CACHE:-0},
    "SOO_CACHE_DELAY": ${SOO_CACHE_DELAY:-5}
  },
  "whitelist_b64": "$wl_b64",
  "patches_b64": "$patches_b64"
}
ENDJSON
  echo "$out"
}

restore_settings() {
  local file="$1"
  [ ! -f "$file" ] && { echo "ERROR: File not found"; return 1; }

  pi()  { grep "\"$1\"" "$file" | grep -o '[0-9]*' | head -1; }
  ps_() { grep "\"$1\"" "$file" | sed 's/.*: *"//;s/".*//' | head -1; }

  local ram_opt=$(pi ENABLE_RAM_OPTIMIZER);         [ -z "$ram_opt" ] && ram_opt=0
  local ker_twe=$(pi ENABLE_KERNEL_TWEAKS);         [ -z "$ker_twe" ] && ker_twe=0
  local sys_pro=$(pi ENABLE_SYSTEM_PROPS);          [ -z "$sys_pro" ] && sys_pro=0
  local blu_dis=$(pi ENABLE_BLUR_DISABLE);          [ -z "$blu_dis" ] && blu_dis=0
  local log_kil=$(pi ENABLE_LOG_KILLING);           [ -z "$log_kil" ] && log_kil=0
  local kil_tra=$(pi ENABLE_KILL_TRACKING);         [ -z "$kil_tra" ] && kil_tra=0
  local dep_doz=$(pi ENABLE_DEEP_DOZE);             [ -z "$dep_doz" ] && dep_doz=0
  local dep_lvl=$(ps_ DEEP_DOZE_LEVEL);             [ -z "$dep_lvl" ] && dep_lvl="moderate"
  local bss_ena=$(pi ENABLE_BATTERY_SAVER);         [ -z "$bss_ena" ] && bss_ena=0
  local bss_snd=$(pi BSS_SOUNDTRIGGER_DISABLED);    [ -z "$bss_snd" ] && bss_snd=1
  local bss_fbu=$(pi BSS_FULLBACKUP_DEFERRED);      [ -z "$bss_fbu" ] && bss_fbu=1
  local bss_kbu=$(pi BSS_KEYVALUEBACKUP_DEFERRED);  [ -z "$bss_kbu" ] && bss_kbu=1
  local bss_fsb=$(pi BSS_FORCE_STANDBY);            [ -z "$bss_fsb" ] && bss_fsb=0
  local bss_fbg=$(pi BSS_FORCE_BG_CHECK);           [ -z "$bss_fbg" ] && bss_fbg=0
  local bss_sen=$(pi BSS_SENSORS_DISABLED);         [ -z "$bss_sen" ] && bss_sen=1
  local bss_gps=$(pi BSS_GPS_MODE);                 [ -z "$bss_gps" ] && bss_gps=0
  local bss_dat=$(pi BSS_DATASAVER);                [ -z "$bss_dat" ] && bss_dat=0
  local dis_tel=$(pi DISABLE_TELEMETRY);            [ -z "$dis_tel" ] && dis_tel=0
  local dis_bac=$(pi DISABLE_BACKGROUND);           [ -z "$dis_bac" ] && dis_bac=0
  local dis_loc=$(pi DISABLE_LOCATION);             [ -z "$dis_loc" ] && dis_loc=0
  local dis_con=$(pi DISABLE_CONNECTIVITY);         [ -z "$dis_con" ] && dis_con=0
  local dis_clo=$(pi DISABLE_CLOUD);                [ -z "$dis_clo" ] && dis_clo=0
  local dis_pay=$(pi DISABLE_PAYMENTS);             [ -z "$dis_pay" ] && dis_pay=0
  local dis_wea=$(pi DISABLE_WEARABLES);            [ -z "$dis_wea" ] && dis_wea=0
  local dis_gam=$(pi DISABLE_GAMES);                [ -z "$dis_gam" ] && dis_gam=0
  local cad_ena=$(pi ENABLE_CUSTOM_APP_DOZE);       [ -z "$cad_ena" ] && cad_ena=0
  local soo_ena=$(pi ENABLE_SCREEN_OFF_OPT);        [ -z "$soo_ena" ] && soo_ena=0
  local soo_wifi=$(pi SOO_KILL_WIFI);               [ -z "$soo_wifi" ] && soo_wifi=0
  local soo_bt=$(pi SOO_KILL_BT);                   [ -z "$soo_bt" ]   && soo_bt=0
  local soo_data=$(pi SOO_KILL_DATA);               [ -z "$soo_data" ] && soo_data=0
  local soo_loc=$(pi SOO_KILL_LOCATION);            [ -z "$soo_loc" ]  && soo_loc=0
  local soo_cdel=$(pi SOO_CONN_DELAY);              [ -z "$soo_cdel" ] && soo_cdel=5
  local soo_rest=$(pi SOO_RESTORE_ON_UNLOCK);       [ -z "$soo_rest" ] && soo_rest=1
  local soo_cache=$(pi SOO_KILL_CACHE);             [ -z "$soo_cache" ] && soo_cache=0
  local soo_cdel2=$(pi SOO_CACHE_DELAY);            [ -z "$soo_cdel2" ] && soo_cdel2=5

  cat > "$MODDIR/config/user_prefs" << ENDPREFS
ENABLE_RAM_OPTIMIZER=$ram_opt
ENABLE_KERNEL_TWEAKS=$ker_twe
ENABLE_SYSTEM_PROPS=$sys_pro
ENABLE_BLUR_DISABLE=$blu_dis
ENABLE_LOG_KILLING=$log_kil
ENABLE_KILL_TRACKING=$kil_tra
ENABLE_DEEP_DOZE=$dep_doz
DEEP_DOZE_LEVEL=$dep_lvl
ENABLE_BATTERY_SAVER=$bss_ena
BSS_SOUNDTRIGGER_DISABLED=$bss_snd
BSS_FULLBACKUP_DEFERRED=$bss_fbu
BSS_KEYVALUEBACKUP_DEFERRED=$bss_kbu
BSS_FORCE_STANDBY=$bss_fsb
BSS_FORCE_BG_CHECK=$bss_fbg
BSS_SENSORS_DISABLED=$bss_sen
BSS_GPS_MODE=$bss_gps
BSS_DATASAVER=$bss_dat
DISABLE_TELEMETRY=$dis_tel
DISABLE_BACKGROUND=$dis_bac
DISABLE_LOCATION=$dis_loc
DISABLE_CONNECTIVITY=$dis_con
DISABLE_CLOUD=$dis_clo
DISABLE_PAYMENTS=$dis_pay
DISABLE_WEARABLES=$dis_wea
DISABLE_GAMES=$dis_gam
ENABLE_CUSTOM_APP_DOZE=$cad_ena
ENABLE_SCREEN_OFF_OPT=$soo_ena
SOO_KILL_WIFI=$soo_wifi
SOO_KILL_BT=$soo_bt
SOO_KILL_DATA=$soo_data
SOO_KILL_LOCATION=$soo_loc
SOO_CONN_DELAY=$soo_cdel
SOO_RESTORE_ON_UNLOCK=$soo_rest
SOO_KILL_CACHE=$soo_cache
SOO_CACHE_DELAY=$soo_cdel2
ENDPREFS

  local b64_data=$(grep '"whitelist_b64"' "$file" | sed 's/.*: *"//;s/".*//')
  if [ -n "$b64_data" ]; then
    printf '%s' "$b64_data" | base64 -d > "$MODDIR/config/doze_whitelist.txt"
  fi
  local patches_data=$(grep '"patches_b64"' "$file" | sed 's/.*: *"//;s/".*//')
  if [ -n "$patches_data" ]; then
    printf '%s' "$patches_data" | base64 -d > "$MODDIR/config/doze_patches.txt"
  fi
  echo "OK"
}

list_backups() {
  local dir="/storage/emulated/0/Frosty"
  [ ! -d "$dir" ] && { echo "[]"; return; }
  local files=$(ls -t "$dir"/frosty_*.json 2>/dev/null)
  [ -z "$files" ] && { echo "[]"; return; }
  printf '['
  local first=1
  for f in $files; do
    [ "$first" -eq 1 ] && first=0 || printf ','
    local _name
    _name=$(basename "$f" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"name":"%s","path":"%s"}' "$_name" "$f"
  done
  printf ']\n'
}

share_backup() {
  local file="$1"
  [ ! -f "$file" ] && { echo "ERROR: not found"; return 1; }
  local pub="/data/local/tmp/$(basename "$file")"
  cp -f "$file" "$pub" && chmod 644 "$pub"
  echo "$pub"
}

apply_ram_optimizer() {
  echo "Frosty v${MODVER:-?} - RAM (apply) - $(date '+%Y-%m-%d %H:%M:%S')" > "$RAM_LOG"
  log_ram "Applying RAM optimizer..."
  mkdir -p "$MODDIR/backup"

  if [ ! -f "$RAM_BACKUP" ] && [ -f "$RAM_TWEAKS" ]; then
    printf "# RAM Backup - $(date)\n" > "$RAM_BACKUP"
    while IFS= read -r _line; do
      case "$_line" in ''|'#'*) continue ;; esac
      _path=$(printf '%s' "$_line" | cut -d'|' -f1 | tr -d ' ')
      [ ! -f "$_path" ] && continue
      printf "%s=%s=%s\n" "$(basename "$_path")" "$(cat "$_path" 2>/dev/null)" "$_path" >> "$RAM_BACKUP"
    done < "$RAM_TWEAKS"
    log_ram "[OK] RAM backup saved"
  fi

  local kcount=0 kfail=0

  if [ -f "$RAM_TWEAKS" ]; then
    while IFS= read -r _line; do
      case "$_line" in ''|'#'*) continue ;; esac
      _path=$(printf '%s' "$_line" | cut -d'|' -f1 | tr -d ' ')
      _val=$(printf '%s' "$_line" | cut -d'|' -f2-)
      [ ! -f "$_path" ] && continue
      local _old=$(cat "$_path" 2>/dev/null)
      chmod +w "$_path" 2>/dev/null
      if printf '%s\n' "$_val" > "$_path" 2>/dev/null; then
        log_ram "[OK] $(basename "$_path"): $_old -> $_val"
        kcount=$((kcount + 1))
      else
        log_ram "[FAIL] $(basename "$_path")"
        kfail=$((kfail + 1))
      fi
    done < "$RAM_TWEAKS"
  fi

  local total_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
  local extra_free
  if [ "${total_kb:-0}" -ge 7340032 ]; then
    extra_free=24576
  elif [ "${total_kb:-0}" -ge 5242880 ]; then
    extra_free=16384
  elif [ "${total_kb:-0}" -ge 3145728 ]; then
    extra_free=12288
  else
    extra_free=8192
  fi

  if [ -f /proc/sys/vm/extra_free_kbytes ]; then
    if ! grep -q "^extra_free_kbytes=" "$RAM_BACKUP" 2>/dev/null; then
      printf 'extra_free_kbytes=%s=/proc/sys/vm/extra_free_kbytes\n' "$(cat /proc/sys/vm/extra_free_kbytes 2>/dev/null)" >> "$RAM_BACKUP"
    fi
    local _old_efk=$(cat /proc/sys/vm/extra_free_kbytes 2>/dev/null)
    if printf '%s\n' "$extra_free" > /proc/sys/vm/extra_free_kbytes 2>/dev/null; then
      log_ram "[OK] extra_free_kbytes: $_old_efk -> $extra_free"
      kcount=$((kcount + 1))
    else
      log_ram "[FAIL] extra_free_kbytes"
      kfail=$((kfail + 1))
    fi
  fi

  local sdk=$(getprop ro.build.version.sdk 2>/dev/null)
  if [ "${sdk:-0}" -ge 30 ] 2>/dev/null; then
    if content call --uri content://settings/config --method PUT_value \
      --arg runtime_native/usap_pool_enabled --extra value:s:true 2>/dev/null >/dev/null; then
      log_ram "[OK] usap_pool_enabled = true"
      kcount=$((kcount + 1))
    else
      log_ram "[FAIL] usap_pool_enabled"
      kfail=$((kfail + 1))
    fi
  fi

  if device_config put activity_manager use_compaction true 2>/dev/null; then
    log_ram "[OK] use_compaction = true"
    kcount=$((kcount + 1))
  fi

  if device_config put activity_manager_native_boot use_freezer true 2>/dev/null; then
    log_ram "[OK] use_freezer = true"
    kcount=$((kcount + 1))
  fi

  if device_config put alarm_manager save_battery_on_idle true 2>/dev/null; then
    log_ram "[OK] alarm save_battery_on_idle = true"
    kcount=$((kcount + 1))
  fi

  log_ram "[OK] RAM: $((${total_kb:-0} / 1024))MB - $kcount applied, $kfail failed"
  echo '{"status":"ok"}'
}

revert_ram_optimizer() {
  echo "Frosty v${MODVER:-?} - RAM (revert) - $(date '+%Y-%m-%d %H:%M:%S')" > "$RAM_LOG"
  log_ram "Reverting RAM optimizer..."

  if [ -f "$RAM_BACKUP" ]; then
    local kcount=0
    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue ;; esac
      val=$(echo "$line" | cut -d= -f2)
      path=$(echo "$line" | cut -d= -f3-)
      [ ! -f "$path" ] && continue
      chmod +w "$path" 2>/dev/null
      printf '%s\n' "$val" > "$path" 2>/dev/null && kcount=$((kcount + 1))
    done < "$RAM_BACKUP"
    rm -f "$RAM_BACKUP"
    log_ram "[OK] RAM values restored ($kcount)"
  else
    log_ram "No RAM backup found"
  fi

  content call --uri content://settings/config --method DELETE_value \
    --arg runtime_native/usap_pool_enabled >/dev/null 2>&1

  device_config delete activity_manager use_compaction 2>/dev/null
  device_config delete activity_manager_native_boot use_freezer 2>/dev/null
  device_config delete alarm_manager save_battery_on_idle 2>/dev/null

  log_ram "[OK] RAM optimizer reverted"
  echo "{\"status\":\"ok\"}"
}

apply_kernel() {
  if [ ! -f "$KERNEL_TWEAKS" ]; then
    echo '{"status":"error","message":"kernel_tweaks.txt not found"}'
    return
  fi

  echo "Frosty v${MODVER:-?} - Tweaks (apply) - $(date '+%Y-%m-%d %H:%M:%S')" > "$TWEAKS_LOG"

  if [ ! -f "$KERNEL_BACKUP" ]; then
    mkdir -p "$MODDIR/backup"
    printf "# Kernel Backup - $(date)\n" > "$KERNEL_BACKUP"
    while IFS= read -r _line; do
      case "$_line" in ''|'#'*) continue ;; esac
      _path=$(printf '%s' "$_line" | cut -d'|' -f1 | tr -d ' ')
      [ ! -e "$_path" ] && continue
      printf "%s=%s=%s\n" "$(basename "$_path")" "$(cat "$_path" 2>/dev/null)" "$_path" >> "$KERNEL_BACKUP"
    done < "$KERNEL_TWEAKS"
  fi

  local last_section="" count=0 fail=0 skip=0
  while IFS= read -r _line; do
    case "$_line" in
      '# '*)
        case "$_line" in *[a-z]*) continue ;; esac
        section=$(echo "$_line" | sed 's/^# //')
        if [ "$section" != "$last_section" ]; then
          last_section="$section"
          log_tweak ""
          log_tweak "# $section"
        fi
        continue
        ;;
      '#'*|'') continue ;;
    esac

    _path=$(printf '%s' "$_line" | cut -d'|' -f1 | tr -d ' ')
    _val=$(printf '%s' "$_line" | cut -d'|' -f2-)
    [ -z "$_path" ] || [ -z "$_val" ] && continue
    _name=$(basename "$_path")

    if [ ! -e "$_path" ]; then
      log_tweak "[SKIP] $_name (not found)"
      skip=$((skip + 1))
      continue
    fi

    _old=$(cat "$_path" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')
    chmod +w "$_path" 2>/dev/null
    if printf '%s\n' "$_val" > "$_path" 2>/dev/null; then
      if [ "$_old" = "$_val" ]; then
        log_tweak "[OK] $_name = $_val (unchanged)"
      else
        log_tweak "[OK] $_name: $_old -> $_val"
      fi
      count=$((count + 1))
    else
      log_tweak "[FAIL] $_name"
      fail=$((fail + 1))
    fi
  done < "$KERNEL_TWEAKS"

  log_tweak ""
  log_tweak "# DEBUG MASKS (dynamic)"
  local debug_count=0
  for pattern in debug_mask log_level debug_level enable_event_log tracing_on; do
    for dpath in $(find /sys/ -maxdepth 4 -type f -name "*${pattern}*" 2>/dev/null | head -20); do
      chmod +w "$dpath" 2>/dev/null
      printf '0\n' > "$dpath" 2>/dev/null && debug_count=$((debug_count + 1))
    done
  done
  log_tweak "Disabled $debug_count debug masks"

  _tcp_cc=/proc/sys/net/ipv4/tcp_congestion_control
  _tcp_av=/proc/sys/net/ipv4/tcp_available_congestion_control
  if [ -f "$_tcp_cc" ] && [ -f "$_tcp_av" ]; then
    if ! grep -q "^tcp_congestion_control=" "$KERNEL_BACKUP" 2>/dev/null; then
      printf 'tcp_congestion_control=%s=%s\n' "$(cat "$_tcp_cc" 2>/dev/null)" "$_tcp_cc" >> "$KERNEL_BACKUP"
    fi
    _avail=$(cat "$_tcp_av" 2>/dev/null)
    _old_cc=$(cat "$_tcp_cc" 2>/dev/null)
    for _algo in bbr3 bbr2 bbrplus bbr westwood cubic; do
      case "$_avail" in *"$_algo"*)
        printf '%s\n' "$_algo" > "$_tcp_cc" 2>/dev/null
        log_tweak ""
        log_tweak "# TCP CONGESTION"
        log_tweak "[OK] tcp_congestion_control: $_old_cc -> $_algo"
        count=$((count + 1)); break ;;
      esac
    done
  fi

  log_tweak ""
  log_tweak "# BLOCK I/O (dynamic)"
  local io_count=0
  for queue in /sys/block/*/queue; do
    [ -d "$queue" ] || continue
    local dev
    dev=$(echo "$queue" | cut -d/ -f4)
    case "$dev" in ram*|loop*|zram*) continue ;; esac
    if [ -f "$queue/read_ahead_kb" ]; then
      printf '128\n' > "$queue/read_ahead_kb" 2>/dev/null && io_count=$((io_count + 1))
    fi
    if [ -f "$queue/iostats" ]; then
      printf '0\n' > "$queue/iostats" 2>/dev/null && io_count=$((io_count + 1))
    fi
  done
  log_tweak "Applied $io_count block I/O tweaks"

  log_tweak ""
  log_tweak "# TCP EXTRAS (dynamic)"
  for _path_val in \
    "/proc/sys/net/ipv4/tcp_slow_start_after_idle|0" \
    "/proc/sys/net/ipv4/tcp_fastopen|3"; do
    local _p _v
    _p=$(printf '%s' "$_path_val" | cut -d'|' -f1)
    _v=$(printf '%s' "$_path_val" | cut -d'|' -f2)
    [ -f "$_p" ] || continue
    if ! grep -q "^$(basename "$_p")=" "$KERNEL_BACKUP" 2>/dev/null; then
      printf '%s=%s=%s\n' "$(basename "$_p")" "$(cat "$_p" 2>/dev/null)" "$_p" >> "$KERNEL_BACKUP"
    fi
    local _old_v
    _old_v=$(cat "$_p" 2>/dev/null)
    if printf '%s\n' "$_v" > "$_p" 2>/dev/null; then
      log_tweak "[OK] $(basename "$_p"): $_old_v -> $_v"
      count=$((count + 1))
    fi
  done

  echo "{\"status\":\"ok\",\"applied\":$count,\"failed\":$fail,\"skipped\":$skip,\"debug_masks\":$debug_count}"
}

revert_kernel() {
  echo "Frosty v${MODVER:-?} - Tweaks (revert) - $(date '+%Y-%m-%d %H:%M:%S')" > "$TWEAKS_LOG"

  local count=0
  if [ -f "$KERNEL_BACKUP" ]; then
    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue ;; esac
      name=$(echo "$line" | cut -d= -f1)
      val=$(echo "$line" | cut -d= -f2)
      path=$(echo "$line" | cut -d= -f3-)
      [ ! -e "$path" ] && continue
      _cur=$(cat "$path" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')
      chmod +w "$path" 2>/dev/null
      if printf '%s\n' "$val" > "$path" 2>/dev/null; then
        log_tweak "[OK] $name: $_cur -> $val (restored)"
        count=$((count + 1))
      else
        log_tweak "[FAIL] $name"
      fi
    done < "$KERNEL_BACKUP"
    rm -f "$KERNEL_BACKUP"
  fi
  log_tweak ""
  log_tweak "Restored $count kernel values"
  echo "{\"status\":\"ok\",\"restored\":$count}"
}

_bool() { [ "$1" = "1" ] && echo "true" || echo "false"; }

apply_battery_saver() {
  local sdk=$(getprop ro.build.version.sdk 2>/dev/null)
  local constants
  if [ "${sdk:-0}" -ge 32 ]; then
    constants="advertise_is_enabled=true"
    constants="$constants,enable_datasaver=$(_bool ${BSS_DATASAVER:-0})"
    constants="$constants,disable_soundtrigger=$(_bool $BSS_SOUNDTRIGGER_DISABLED)"
    constants="$constants,defer_full_backup=$(_bool $BSS_FULLBACKUP_DEFERRED)"
    constants="$constants,defer_keyvalue_backup=$(_bool $BSS_KEYVALUEBACKUP_DEFERRED)"
    constants="$constants,force_all_apps_standby=$(_bool $BSS_FORCE_STANDBY)"
    constants="$constants,force_background_check=$(_bool $BSS_FORCE_BG_CHECK)"
    constants="$constants,disable_optional_sensors=$(_bool $BSS_SENSORS_DISABLED)"
    constants="$constants,location_mode=$BSS_GPS_MODE"
  else
    constants="advertise_is_enabled=true"
    constants="$constants,datasaver_disabled=$(_bool $((1 - ${BSS_DATASAVER:-0})))"
    constants="$constants,soundtrigger_disabled=$(_bool $BSS_SOUNDTRIGGER_DISABLED)"
    constants="$constants,fullbackup_deferred=$(_bool $BSS_FULLBACKUP_DEFERRED)"
    constants="$constants,keyvaluebackup_deferred=$(_bool $BSS_KEYVALUEBACKUP_DEFERRED)"
    constants="$constants,force_all_apps_standby=$(_bool $BSS_FORCE_STANDBY)"
    constants="$constants,force_background_check=$(_bool $BSS_FORCE_BG_CHECK)"
    constants="$constants,optional_sensors_disabled=$(_bool $BSS_SENSORS_DISABLED)"
    constants="$constants,gps_mode=$BSS_GPS_MODE"
  fi
  settings put global battery_saver_constants "$constants" 2>/dev/null
  settings put global low_power 1 2>/dev/null
  settings put global low_power_sticky_auto_disable_enabled 0 2>/dev/null
  settings put global low_power_sticky 1 2>/dev/null

  echo "Frosty v${MODVER:-?} - Battery Saver - $(date '+%Y-%m-%d %H:%M:%S')" > "$BS_LOG"
  {
    echo "[$(date '+%H:%M:%S')] [OK] Applied:"
    echo "$constants" | tr ',' '\n' | while IFS= read -r _entry; do
      echo "  $_entry"
    done
  } >> "$BS_LOG"
  echo '{"status":"ok"}'
}

revert_battery_saver() {
  settings delete global battery_saver_constants >/dev/null 2>&1
  settings put global low_power_sticky 0 2>/dev/null
  settings put global low_power_sticky_auto_disable_enabled 1 2>/dev/null
  settings put global low_power 0 2>/dev/null
  echo "Frosty v${MODVER:-?} - Battery Saver - $(date '+%Y-%m-%d %H:%M:%S')" > "$BS_LOG"
  echo "[$(date '+%H:%M:%S')] [OK] Reverted" >> "$BS_LOG"
  echo '{"status":"ok"}'
}

kill_logs() {
  local k=0
  for svc in logcat logcatd tcpdump cnss_diag traced traced_perf traced_probes \
             idd-logreader idd-logreadermain aplogd vendor.tcpdump vendor_tcpdump vendor.cnss_diag; do
    pid=$(pidof "$svc" 2>/dev/null)
    if [ -n "$pid" ]; then
      kill -9 "$pid" 2>/dev/null
      k=$((k + 1))
    fi
  done
  logcat -c 2>/dev/null
  dmesg -c >/dev/null 2>&1
  echo 0 > /sys/kernel/tracing/tracing_on 2>/dev/null

  cmd activity logging disable-text >/dev/null 2>&1
  cmd autofill set log_level off >/dev/null 2>&1
  cmd display ab-logging-disable >/dev/null 2>&1
  cmd display dmd-logging-disable >/dev/null 2>&1
  cmd display dwb-logging-disable >/dev/null 2>&1
  cmd input_method tracing stop >/dev/null 2>&1
  cmd statusbar tracing stop >/dev/null 2>&1
  cmd wifi set-verbose-logging disabled >/dev/null 2>&1
  cmd window logging disable >/dev/null 2>&1
  cmd window logging disable-text >/dev/null 2>&1
  cmd window tracing size 0 >/dev/null 2>&1

  settings put global battery_stats_constants "track_cpu_active_cluster_time=false,kernel_uid_readers_throttle_time=2000,external_stats_collection_rate_limit_ms=1200000,battery_level_collection_delay_ms=600000,procstate_change_collection_delay_ms=120000,max_history_files=1,max_history_buffer_kb=512,battery_charged_delay_ms=1800000,phone_on_external_stats_collection=false,reset_while_plugged_in_minimum_duration_hours=24" 2>/dev/null

  (
    for tag in dumpsys:procstats dumpsys:usagestats procstats usagestats \
               data_app_wtf keymaster system_server_wtf system_app_strictmode \
               system_app_wtf system_server_strictmode data_app_strictmode \
               netstats data_app_anr data_app_crash system_server_anr \
               system_server_watchdog system_server_crash system_server_native_crash \
               system_server_lowmem system_app_crash system_app_anr storage_trim \
               SYSTEM_AUDIT SYSTEM_BOOT SYSTEM_LAST_KMSG system_app_native_crash \
               SYSTEM_TOMBSTONE SYSTEM_TOMBSTONE_PROTO data_app_native_crash \
               SYSTEM_RESTART; do
      content call --uri content://settings/global --method PUT_value \
        --arg "dropbox:$tag" --extra value:s:disabled 2>/dev/null >/dev/null &
    done
    wait
  ) &

  settings put global netstats_poll_interval 60000 >/dev/null 2>&1
  settings put global netstats_persist_threshold 2097152 >/dev/null 2>&1
  settings put global netstats_global_alert_bytes 2097152 >/dev/null 2>&1
  settings put global wifi_scan_throttle_enabled 1 >/dev/null 2>&1
  settings put global wifi_scan_always_enabled 0 >/dev/null 2>&1

  dmesg -n 1 2>/dev/null
  echo 1 > /proc/sys/kernel/printk_ratelimit 2>/dev/null
  echo 1 > /proc/sys/kernel/printk_ratelimit_burst 2>/dev/null

  device_config put activity_manager disable_app_profiler_pss_profiling true 2>/dev/null
  device_config put activity_manager activity_start_pss_defer 300000 2>/dev/null

  echo "{\"status\":\"ok\",\"killed\":$k}"
}

revert_kill_logs() {
  (
    for tag in dumpsys:procstats dumpsys:usagestats procstats usagestats \
               data_app_wtf keymaster system_server_wtf system_app_strictmode \
               system_app_wtf system_server_strictmode data_app_strictmode \
               netstats data_app_anr data_app_crash system_server_anr \
               system_server_watchdog system_server_crash system_server_native_crash \
               system_server_lowmem system_app_crash system_app_anr storage_trim \
               SYSTEM_AUDIT SYSTEM_BOOT SYSTEM_LAST_KMSG system_app_native_crash \
               SYSTEM_TOMBSTONE SYSTEM_TOMBSTONE_PROTO data_app_native_crash \
               SYSTEM_RESTART; do
      content call --uri content://settings/global --method DELETE_value \
        --arg "dropbox:$tag" 2>/dev/null >/dev/null &
    done
    wait
  ) &

  settings delete global battery_stats_constants 2>/dev/null

  settings delete global netstats_poll_interval >/dev/null 2>&1
  settings delete global netstats_persist_threshold >/dev/null 2>&1
  settings delete global netstats_global_alert_bytes >/dev/null 2>&1

  settings delete global wifi_scan_throttle_enabled >/dev/null 2>&1
  settings delete global wifi_scan_always_enabled >/dev/null 2>&1

  echo 0 > /proc/sys/kernel/printk_ratelimit 2>/dev/null
  echo 10 > /proc/sys/kernel/printk_ratelimit_burst 2>/dev/null

  echo 1 > /sys/kernel/tracing/tracing_on 2>/dev/null

  device_config delete activity_manager disable_app_profiler_pss_profiling 2>/dev/null
  device_config delete activity_manager activity_start_pss_defer 2>/dev/null

  cmd wifi set-verbose-logging enabled >/dev/null 2>&1

  echo '{"status":"ok"}'
}

kill_tracking() {
  settings put global gmscorestat_enabled 0 >/dev/null 2>&1
  settings put global play_store_panel_logging_enabled 0 >/dev/null 2>&1
  settings put global clearcut_enabled 0 >/dev/null 2>&1
  settings put global clearcut_events 0 >/dev/null 2>&1
  settings put global clearcut_gcm 0 >/dev/null 2>&1
  settings put global phenotype__debug_bypass_phenotype 1 >/dev/null 2>&1
  settings put global phenotype_boot_count 99 >/dev/null 2>&1
  settings put global phenotype_flags "disable_log_upload=1,disable_log_for_missing_debug_id=1" >/dev/null 2>&1
  settings put global ga_collection_enabled 0 >/dev/null 2>&1
  settings put global analytics_enabled 0 >/dev/null 2>&1
  settings put global uploading_enabled 0 >/dev/null 2>&1
  settings put global bug_report_in_power_menu 0 >/dev/null 2>&1
  settings put global usage_stats_enabled 0 >/dev/null 2>&1
  settings put global usagestats_collection_enabled 0 >/dev/null 2>&1
  settings put global network_watchlist_enabled 0 >/dev/null 2>&1
  settings put global limit_ad_tracking 1 >/dev/null 2>&1
  settings put global tron_enabled 0 >/dev/null 2>&1
  settings put global gms_checkin_timeout_min 120 >/dev/null 2>&1

  local _gms_uid
  _gms_uid=$(dumpsys package com.google.android.gms 2>/dev/null \
    | grep -m1 "userId=" | grep -o 'userId=[0-9]*' | cut -d= -f2)
  [ -n "$_gms_uid" ] && cmd netpolicy add restrict-background-blacklist "$_gms_uid" >/dev/null 2>&1

  echo '{"status":"ok"}'
}

revert_tracking() {
  settings put global gmscorestat_enabled 1 >/dev/null 2>&1
  settings put global play_store_panel_logging_enabled 1 >/dev/null 2>&1
  settings put global clearcut_enabled 1 >/dev/null 2>&1
  settings put global clearcut_events 1 >/dev/null 2>&1
  settings put global clearcut_gcm 1 >/dev/null 2>&1
  settings delete global phenotype__debug_bypass_phenotype >/dev/null 2>&1
  settings delete global phenotype_boot_count >/dev/null 2>&1
  settings delete global phenotype_flags >/dev/null 2>&1
  settings put global ga_collection_enabled 1 >/dev/null 2>&1
  settings put global analytics_enabled 1 >/dev/null 2>&1
  settings put global uploading_enabled 1 >/dev/null 2>&1
  settings put global bug_report_in_power_menu 1 >/dev/null 2>&1
  settings put global usage_stats_enabled 1 >/dev/null 2>&1
  settings put global usagestats_collection_enabled 1 >/dev/null 2>&1
  settings put global network_watchlist_enabled 1 >/dev/null 2>&1
  settings put global limit_ad_tracking 0 >/dev/null 2>&1
  settings put global tron_enabled 1 >/dev/null 2>&1
  settings delete global gms_checkin_timeout_min >/dev/null 2>&1

  local _gms_uid
  _gms_uid=$(dumpsys package com.google.android.gms 2>/dev/null \
    | grep -m1 "userId=" | grep -o 'userId=[0-9]*' | cut -d= -f2)
  [ -n "$_gms_uid" ] && cmd netpolicy remove restrict-background-blacklist "$_gms_uid" >/dev/null 2>&1

  echo '{"status":"ok"}'
}

wl_list() {
  local wl="$MODDIR/config/doze_whitelist.txt"
  [ -f "$wl" ] || { echo '{"status":"ok","packages":[]}'; return; }
  local installed
  installed=$(pm list packages 2>/dev/null | cut -d: -f2)
  printf '{"status":"ok","packages":['
  local first=1
  while IFS= read -r line; do
    local pkg
    pkg=$(echo "$line" | sed 's/#.*//;s/[[:space:]]//g')
    [ -z "$pkg" ] && continue
    echo "$installed" | grep -qx "$pkg" || continue
    [ "$first" = "1" ] && first=0 || printf ','
    printf '"%s"' "$pkg"
  done < "$wl"
  printf ']}\n'
}

wl_add() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  local wl="$MODDIR/config/doze_whitelist.txt"
  mkdir -p "$MODDIR/config"
  [ -f "$wl" ] || touch "$wl"
  grep -qx "$pkg" "$wl" 2>/dev/null || echo "$pkg" >> "$wl"
  echo '{"status":"ok"}'
}

wl_remove() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  local wl="$MODDIR/config/doze_whitelist.txt"
  [ -f "$wl" ] || { echo '{"status":"ok"}'; return; }
  local escaped
  escaped=$(printf '%s' "$pkg" | sed 's/\./\\./g')
  sed -i "/^${escaped}$/d" "$wl"
  echo '{"status":"ok"}'
}

# Screen-Off Optimization
soo_apply() {
  chmod +x "$MODDIR/screen_off_opt.sh" 2>/dev/null
  sh "$MODDIR/screen_off_opt.sh" start 2>/dev/null
  echo '{"status":"ok"}'
}

soo_revert() {
  sh "$MODDIR/screen_off_opt.sh" stop 2>/dev/null
  echo '{"status":"ok"}'
}

case "$1" in
  freeze)             freeze_services ;;
  stock)              stock_services ;;
  apply_sysprops)     apply_system_props ;;
  apply_kernel)       apply_kernel ;;
  revert_kernel)      revert_kernel ;;
  freeze_category)    freeze_category "$2" ;;
  unfreeze_category)  unfreeze_category "$2" ;;
  ram_optimizer)      apply_ram_optimizer ;;
  ram_restore)        revert_ram_optimizer ;;
  bss_apply)          apply_battery_saver ;;
  bss_revert)         revert_battery_saver ;;
  kill_logs)          kill_logs ;;
  revert_kill_logs)   revert_kill_logs ;;
  kill_tracking)      kill_tracking ;;
  revert_tracking)    revert_tracking ;;
  export)             backup_settings ;;
  import)             restore_settings "$2" ;;
  list_backups)       list_backups ;;
  share_backup)       share_backup "$2" ;;
  wl_list)            wl_list ;;
  wl_add)             wl_add "$2" ;;
  wl_remove)          wl_remove "$2" ;;
  soo_apply)          soo_apply ;;
  soo_revert)         soo_revert ;;
  *)  echo '{"status":"error","message":"unknown action"}'; exit 1 ;;
esac
exit 0