BACKUP_DIR="/storage/emulated/0/Frosty"

_confine_to_backup_dir() {
  local _f="$1"
  case "$_f" in
    */../*|../*|*/..) return 1 ;;
  esac
  if command -v realpath >/dev/null 2>&1; then
    _f=$(realpath "$_f" 2>/dev/null) || return 1
  fi
  case "$_f" in
    "$BACKUP_DIR"/*) return 0 ;;
    *) return 1 ;;
  esac
}

backup_settings() {
  local dir="$BACKUP_DIR"
  mkdir -p "$dir" 2>/dev/null || { echo "ERROR: Cannot write to $dir"; return 1; }
  local ts=$(date '+%Y%m%d_%H%M%S')
  local out="$dir/frosty_$ts.json"

  load_prefs
  local wl_b64=""
  [ -f "$MODDIR/config/doze_whitelist.txt" ] && wl_b64=$(base64 < "$MODDIR/config/doze_whitelist.txt" | tr -d '\n')
  local patches_b64=""
  [ -f "$MODDIR/config/doze_patches.txt" ] && patches_b64=$(base64 < "$MODDIR/config/doze_patches.txt" | tr -d '\n')
  local ram_wl_b64=""
  [ -f "$RAM_WL_FILE" ] && ram_wl_b64=$(base64 < "$RAM_WL_FILE" | tr -d '\n')

  cat > "$out" << ENDJSON
{
  "version": "${MODVER:-unknown}",
  "schema": 2,
  "exported": "$ts",
  "prefs": {
    "ENABLE_KERNEL_TWEAKS": ${ENABLE_KERNEL_TWEAKS:-0},
    "ENABLE_RAM_OPTIMIZER": ${ENABLE_RAM_OPTIMIZER:-0},
    "MULTITASK_ENABLED": ${MULTITASK_ENABLED:-0},
    "MULTITASK_PROFILE": "${MULTITASK_PROFILE:-balanced}",
    "ENABLE_SYSTEM_PROPS": ${ENABLE_SYSTEM_PROPS:-0},
    "ENABLE_BLUR_DISABLE": ${ENABLE_BLUR_DISABLE:-0},
    "ENABLE_LOG_KILLING": ${ENABLE_LOG_KILLING:-0},
    "ENABLE_KILL_TRACKING": ${ENABLE_KILL_TRACKING:-0},
    "ENABLE_DEEP_DOZE": ${ENABLE_DEEP_DOZE:-0},
    "DEEP_DOZE_LEVEL": "${DEEP_DOZE_LEVEL:-minimum}",
    "DEEP_DOZE_ALWAYS": ${DEEP_DOZE_ALWAYS:-0},
    "RAM_OPT_LEVEL": "${RAM_OPT_LEVEL:-moderate}",
    "ENABLE_BATTERY_SAVER": ${ENABLE_BATTERY_SAVER:-0},
    "BSS_SOUNDTRIGGER_DISABLED": ${BSS_SOUNDTRIGGER_DISABLED:-0},
    "BSS_FULLBACKUP_DEFERRED": ${BSS_FULLBACKUP_DEFERRED:-0},
    "BSS_KEYVALUEBACKUP_DEFERRED": ${BSS_KEYVALUEBACKUP_DEFERRED:-0},
    "BSS_FORCE_STANDBY": ${BSS_FORCE_STANDBY:-0},
    "BSS_FORCE_BG_CHECK": ${BSS_FORCE_BG_CHECK:-0},
    "BSS_SENSORS_DISABLED": ${BSS_SENSORS_DISABLED:-0},
    "BSS_GPS_MODE": ${BSS_GPS_MODE:-0},
    "BSS_DATASAVER": ${BSS_DATASAVER:-0},
    "BSS_MAX_REFRESH": ${BSS_MAX_REFRESH:-0},
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
    "SOO_KILL_NFC": ${SOO_KILL_NFC:-0},
    "SOO_KILL_LOCATION": ${SOO_KILL_LOCATION:-0},
    "SOO_CONN_DELAY": ${SOO_CONN_DELAY:-5},
    "SOO_RESTORE_ON_UNLOCK": ${SOO_RESTORE_ON_UNLOCK:-1},
    "SOO_RAM_CLEAN_MODE": "${SOO_RAM_CLEAN_MODE:-off}",
    "SOO_RAM_CLEAN_DELAY": ${SOO_RAM_CLEAN_DELAY:-5},
    "SOO_KILL_SENSORS": ${SOO_KILL_SENSORS:-0},
    "SOO_KILL_PANEL_LPM": ${SOO_KILL_PANEL_LPM:-0},
    "WEBUI_THEME": "${WEBUI_THEME:-stock}"
  },
  "whitelist_b64": "$wl_b64",
  "patches_b64": "$patches_b64",
  "ram_wl_b64": "$ram_wl_b64"
}
ENDJSON
  echo "$out"
}

_valid_enum() {
  local _val="$1"; shift
  local _opt
  for _opt in "$@"; do
    [ "$_val" = "$_opt" ] && return 0
  done
  return 1
}

_pkg_lines() {
  base64 -d 2>/dev/null | grep -E '^[[:space:]]*(#.*)?$|^[[:space:]]*[A-Za-z][A-Za-z0-9_.]*[[:space:]]*$' | grep -v '^[[:space:]#]*$'
}

restore_lists() {
  local file="$1" _pair _key _dst _data _clean
  for _pair in whitelist_b64:doze_whitelist.txt patches_b64:doze_patches.txt ram_wl_b64:ram_clean_whitelist.txt; do
    _key="${_pair%%:*}"
    _dst="$MODDIR/config/${_pair#*:}"
    grep -q "\"$_key\"" "$file" || continue
    _data=$(grep "\"$_key\"" "$file" | sed 's/.*: *"//;s/".*//')
    if [ -z "$_data" ]; then
      : > "$_dst"
      continue
    fi
    _clean=$(printf '%s' "$_data" | _pkg_lines)
    [ -n "$_clean" ] || continue
    printf '%s\n' "$_clean" > "${_dst}.tmp" && mv -f "${_dst}.tmp" "$_dst"
  done
}

restore_settings() {
  local file="$1"
  [ ! -f "$file" ] && { echo "ERROR: File not found"; return 1; }
  _confine_to_backup_dir "$file" || { echo "ERROR: File must be inside $BACKUP_DIR"; return 1; }
  { grep -q '"version"' "$file" && grep -q '"prefs"' "$file"; } || { echo "ERROR: Not a Frosty backup file"; return 1; }

  pi()  { grep "\"$1\":" "$file" | grep -o '[0-9]*' | head -1; }
  ps_() { grep "\"$1\":" "$file" | sed 's/.*: *"//;s/".*//' | head -1; }

  local schema; schema=$(pi schema); [ -z "$schema" ] && schema=1
  [ "$schema" -le 2 ] || { echo "ERROR: Backup schema $schema is newer than this module supports"; return 1; }

  local ram_opt=$(pi ENABLE_RAM_OPTIMIZER);         [ -z "$ram_opt" ] && ram_opt=0
  local ram_lvl=$(ps_ RAM_OPT_LEVEL)
  _valid_enum "$ram_lvl" moderate maximum || ram_lvl="moderate"
  local mt_ena=$(pi MULTITASK_ENABLED);             [ -z "$mt_ena" ] && mt_ena=0
  local mt_prof=$(ps_ MULTITASK_PROFILE)
  [ -z "$mt_prof" ] && mt_prof=$(ps_ RAM_MULTITASK_PROFILE)
  _valid_enum "$mt_prof" performance balanced powersaving || mt_prof="balanced"
  local ker_twe=$(pi ENABLE_KERNEL_TWEAKS);         [ -z "$ker_twe" ] && ker_twe=0
  local sys_pro=$(pi ENABLE_SYSTEM_PROPS);          [ -z "$sys_pro" ] && sys_pro=0
  local blu_dis=$(pi ENABLE_BLUR_DISABLE);          [ -z "$blu_dis" ] && blu_dis=0
  local log_kil=$(pi ENABLE_LOG_KILLING);           [ -z "$log_kil" ] && log_kil=0
  local kil_tra=$(pi ENABLE_KILL_TRACKING);         [ -z "$kil_tra" ] && kil_tra=0
  local dep_doz=$(pi ENABLE_DEEP_DOZE);             [ -z "$dep_doz" ] && dep_doz=0
  local dep_lvl=$(ps_ DEEP_DOZE_LEVEL)
  _valid_enum "$dep_lvl" minimum moderate maximum || dep_lvl="minimum"
  local dep_alw=$(pi DEEP_DOZE_ALWAYS);              [ -z "$dep_alw" ] && dep_alw=0
  local bss_ena=$(pi ENABLE_BATTERY_SAVER);         [ -z "$bss_ena" ] && bss_ena=0
  local bss_snd=$(pi BSS_SOUNDTRIGGER_DISABLED);    [ -z "$bss_snd" ] && bss_snd=0
  local bss_fbu=$(pi BSS_FULLBACKUP_DEFERRED);      [ -z "$bss_fbu" ] && bss_fbu=0
  local bss_kbu=$(pi BSS_KEYVALUEBACKUP_DEFERRED);  [ -z "$bss_kbu" ] && bss_kbu=0
  local bss_fsb=$(pi BSS_FORCE_STANDBY);            [ -z "$bss_fsb" ] && bss_fsb=0
  local bss_fbg=$(pi BSS_FORCE_BG_CHECK);           [ -z "$bss_fbg" ] && bss_fbg=0
  local bss_sen=$(pi BSS_SENSORS_DISABLED);         [ -z "$bss_sen" ] && bss_sen=0
  local bss_gps=$(pi BSS_GPS_MODE);                 [ -z "$bss_gps" ] && bss_gps=0
  case "$bss_gps" in 0|1|2|3|4) ;; *) bss_gps=0 ;; esac
  local bss_dat=$(pi BSS_DATASAVER);                [ -z "$bss_dat" ] && bss_dat=0
  local bss_mrf=$(pi BSS_MAX_REFRESH);              [ -z "$bss_mrf" ] && bss_mrf=0
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
  local soo_nfc=$(pi SOO_KILL_NFC);                 [ -z "$soo_nfc" ]  && soo_nfc=0
  local soo_loc=$(pi SOO_KILL_LOCATION);            [ -z "$soo_loc" ]  && soo_loc=0
  local soo_cdel=$(pi SOO_CONN_DELAY);              [ -z "$soo_cdel" ] && soo_cdel=5
  local soo_rest=$(pi SOO_RESTORE_ON_UNLOCK);       [ -z "$soo_rest" ] && soo_rest=1
  local soo_rcm; soo_rcm=$(ps_ SOO_RAM_CLEAN_MODE)
  if [ -z "$soo_rcm" ]; then
    [ "$(pi SOO_KILL_CACHE)" = "1" ] && soo_rcm="safe" || soo_rcm="off"
  fi
  _valid_enum "$soo_rcm" off safe aggressive extreme || soo_rcm="off"
  local soo_rcd; soo_rcd=$(pi SOO_RAM_CLEAN_DELAY)
  [ -z "$soo_rcd" ] && { soo_rcd=$(pi SOO_CACHE_DELAY); [ -z "$soo_rcd" ] && soo_rcd=5; }
  [ "${#soo_cdel}" -gt 3 ] && soo_cdel=120
  [ "${#soo_rcd}" -gt 3 ] && soo_rcd=120
  local soo_sensors=$(pi SOO_KILL_SENSORS);          [ -z "$soo_sensors" ] && soo_sensors=0
  local soo_panel_lpm=$(pi SOO_KILL_PANEL_LPM);      [ -z "$soo_panel_lpm" ] && soo_panel_lpm=0
  local wl_theme; wl_theme=$(ps_ WEBUI_THEME)
  _valid_enum "$wl_theme" stock comic retro terminal handheld || wl_theme=""

  local legacy_gms_doze=$(pi ENABLE_GMS_DOZE)
  if [ "$legacy_gms_doze" = "1" ] && [ "$cad_ena" != "1" ]; then
    cad_ena=1
  fi

  restore_lists "$file"
  if [ "$sys_pro" = "1" ]; then
    [ -f "$SYSPROP_OLD" ] && mv -f "$SYSPROP_OLD" "$SYSPROP"
  else
    [ -f "$SYSPROP" ] && mv -f "$SYSPROP" "$SYSPROP_OLD"
  fi

  if [ "$legacy_gms_doze" = "1" ]; then
    mkdir -p "$MODDIR/config"
    grep -qFx "com.google.android.gms" "$MODDIR/config/doze_patches.txt" 2>/dev/null || \
      echo "com.google.android.gms" >> "$MODDIR/config/doze_patches.txt"
  fi

  cat > "$MODDIR/config/user_prefs.tmp" << ENDPREFS
ENABLE_RAM_OPTIMIZER=$ram_opt
RAM_OPT_LEVEL=$ram_lvl
MULTITASK_ENABLED=$mt_ena
MULTITASK_PROFILE=$mt_prof
ENABLE_KERNEL_TWEAKS=$ker_twe
ENABLE_SYSTEM_PROPS=$sys_pro
ENABLE_BLUR_DISABLE=$blu_dis
ENABLE_LOG_KILLING=$log_kil
ENABLE_KILL_TRACKING=$kil_tra
ENABLE_DEEP_DOZE=$dep_doz
DEEP_DOZE_LEVEL=$dep_lvl
DEEP_DOZE_ALWAYS=$dep_alw
ENABLE_BATTERY_SAVER=$bss_ena
BSS_SOUNDTRIGGER_DISABLED=$bss_snd
BSS_FULLBACKUP_DEFERRED=$bss_fbu
BSS_KEYVALUEBACKUP_DEFERRED=$bss_kbu
BSS_FORCE_STANDBY=$bss_fsb
BSS_FORCE_BG_CHECK=$bss_fbg
BSS_SENSORS_DISABLED=$bss_sen
BSS_GPS_MODE=$bss_gps
BSS_DATASAVER=$bss_dat
BSS_MAX_REFRESH=$bss_mrf
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
SOO_KILL_NFC=$soo_nfc
SOO_KILL_LOCATION=$soo_loc
SOO_CONN_DELAY=$soo_cdel
SOO_RESTORE_ON_UNLOCK=$soo_rest
SOO_RAM_CLEAN_MODE=$soo_rcm
SOO_RAM_CLEAN_DELAY=$soo_rcd
SOO_KILL_SENSORS=$soo_sensors
SOO_KILL_PANEL_LPM=$soo_panel_lpm
ENDPREFS
  if [ -n "$wl_theme" ]; then
    echo "WEBUI_THEME=$wl_theme" >> "$MODDIR/config/user_prefs.tmp"
  else
    grep '^WEBUI_THEME=' "$MODDIR/config/user_prefs" >> "$MODDIR/config/user_prefs.tmp" 2>/dev/null
  fi
  mv -f "$MODDIR/config/user_prefs.tmp" "$MODDIR/config/user_prefs"
  rm -f "$MODDIR/tmp/applied"

  echo "OK"
}

list_backups() {
  [ -d "$BACKUP_DIR" ] || { echo "[]"; return; }
  printf '['
  ls -t "$BACKUP_DIR"/frosty_*.json 2>/dev/null | {
    local _first=1 _f _n _p
    while IFS= read -r _f; do
      [ "$_first" -eq 1 ] && _first=0 || printf ','
      _n=$(basename "$_f" | sed 's/\\/\\\\/g; s/"/\\"/g')
      _p=$(printf '%s' "$_f" | sed 's/\\/\\\\/g; s/"/\\"/g')
      printf '{"name":"%s","path":"%s"}' "$_n" "$_p"
    done
  }
  printf ']\n'
}
