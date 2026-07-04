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
  if [ ! -f "$BSS_BACKUP" ]; then
    mkdir -p "$(dirname "$BSS_BACKUP")"
    {
      printf 'low_power=%s\n' "$(settings get global low_power 2>/dev/null)"
      printf 'low_power_sticky=%s\n' "$(settings get global low_power_sticky 2>/dev/null)"
    } > "$BSS_BACKUP"
  fi
  settings put global low_power 1 2>/dev/null
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
  local _lp _lps
  _lp=$(grep '^low_power=' "$BSS_BACKUP" 2>/dev/null | cut -d= -f2)
  _lps=$(grep '^low_power_sticky=' "$BSS_BACKUP" 2>/dev/null | cut -d= -f2)
  if [ -n "$_lps" ] && [ "$_lps" != "null" ]; then
    settings put global low_power_sticky "$_lps" 2>/dev/null
  else
    settings put global low_power_sticky 0 2>/dev/null
  fi
  if [ -n "$_lp" ] && [ "$_lp" != "null" ]; then
    settings put global low_power "$_lp" 2>/dev/null
  else
    settings put global low_power 0 2>/dev/null
  fi
  rm -f "$BSS_BACKUP"
  echo "Frosty v${MODVER:-?} - Battery Saver - $(date '+%Y-%m-%d %H:%M:%S')" > "$BS_LOG"
  echo "[$(date '+%H:%M:%S')] [OK] Reverted" >> "$BS_LOG"
  echo '{"status":"ok"}'
}