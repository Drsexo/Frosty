apply_battery_saver() {
  local sdk=$(getprop ro.build.version.sdk 2>/dev/null)
  local constants
  if [ "${sdk:-0}" -ge 32 ]; then
    constants="advertise_is_enabled=true"
    constants="$constants,enable_datasaver=$(_bool ${BSS_DATASAVER:-0})"
    constants="$constants,soundtrigger_mode=$(( ${BSS_SOUNDTRIGGER_DISABLED:-0} * 2 ))"
    constants="$constants,defer_full_backup=$(_bool $BSS_FULLBACKUP_DEFERRED)"
    constants="$constants,defer_keyvalue_backup=$(_bool $BSS_KEYVALUEBACKUP_DEFERRED)"
    constants="$constants,force_all_apps_standby=$(_bool $BSS_FORCE_STANDBY)"
    constants="$constants,force_background_check=$(_bool $BSS_FORCE_BG_CHECK)"
    constants="$constants,disable_optional_sensors=$(_bool $BSS_SENSORS_DISABLED)"
    constants="$constants,location_mode=${BSS_GPS_MODE:-0}"
  else
    constants="advertise_is_enabled=true"
    constants="$constants,datasaver_disabled=$(_bool $((1 - ${BSS_DATASAVER:-0})))"
    constants="$constants,soundtrigger_disabled=$(_bool $BSS_SOUNDTRIGGER_DISABLED)"
    constants="$constants,fullbackup_deferred=$(_bool $BSS_FULLBACKUP_DEFERRED)"
    constants="$constants,keyvaluebackup_deferred=$(_bool $BSS_KEYVALUEBACKUP_DEFERRED)"
    constants="$constants,force_all_apps_standby=$(_bool $BSS_FORCE_STANDBY)"
    constants="$constants,force_background_check=$(_bool $BSS_FORCE_BG_CHECK)"
    constants="$constants,optional_sensors_disabled=$(_bool $BSS_SENSORS_DISABLED)"
    constants="$constants,gps_mode=${BSS_GPS_MODE:-0}"
  fi
  mkdir -p "$(dirname "$BSS_BACKUP")"
  grep -q '^battery_saver_constants=' "$BSS_BACKUP" 2>/dev/null || \
    printf 'battery_saver_constants=%s\n' "$(settings get global battery_saver_constants 2>/dev/null)" >> "$BSS_BACKUP"
  settings put global battery_saver_constants "$constants" >/dev/null 2>&1

  if [ "$BSS_MAX_REFRESH" = "1" ]; then
    local _maxfps
    _maxfps=$(dumpsys display 2>/dev/null | grep -Eo 'fps=[^.]+' | cut -f2 -d= | sort -n | tail -n1)
    if [ -n "$_maxfps" ]; then
      if ! grep -q '^peak_refresh_rate=' "$BSS_BACKUP" 2>/dev/null; then
        printf 'peak_refresh_rate=%s\n' "$(settings get global peak_refresh_rate 2>/dev/null)" >> "$BSS_BACKUP"
        printf 'min_refresh_rate=%s\n' "$(settings get global min_refresh_rate 2>/dev/null)" >> "$BSS_BACKUP"
      fi
      settings put global peak_refresh_rate "$_maxfps" >/dev/null 2>&1
      settings put global min_refresh_rate "$_maxfps" >/dev/null 2>&1
    fi
  else
    _restore_refresh_rate
  fi

  echo "Frosty v${MODVER:-?} - Battery Saver - $(date '+%Y-%m-%d %H:%M:%S')" > "$BS_LOG"
  {
    echo "[$(date '+%H:%M:%S')] [OK] Applied:"
    echo "$constants" | tr ',' '\n' | while IFS= read -r _entry; do
      echo "  $_entry"
    done
  } >> "$BS_LOG"
  echo '{"status":"ok"}'
}

_restore_refresh_rate() {
  local _prr _mrr
  _prr=$(grep '^peak_refresh_rate=' "$BSS_BACKUP" 2>/dev/null | cut -d= -f2-)
  _mrr=$(grep '^min_refresh_rate=' "$BSS_BACKUP" 2>/dev/null | cut -d= -f2-)
  if [ -n "$_prr" ]; then
    if [ "$_prr" != "null" ]; then
      settings put global peak_refresh_rate "$_prr" >/dev/null 2>&1
    else
      settings delete global peak_refresh_rate >/dev/null 2>&1
    fi
  fi
  if [ -n "$_mrr" ]; then
    if [ "$_mrr" != "null" ]; then
      settings put global min_refresh_rate "$_mrr" >/dev/null 2>&1
    else
      settings delete global min_refresh_rate >/dev/null 2>&1
    fi
  fi
  [ -f "$BSS_BACKUP" ] && sed -i -e '/^peak_refresh_rate=/d' -e '/^min_refresh_rate=/d' "$BSS_BACKUP"
}

revert_battery_saver() {
  local _bsc
  _bsc=$(grep '^battery_saver_constants=' "$BSS_BACKUP" 2>/dev/null | cut -d= -f2-)
  if [ -n "$_bsc" ] && [ "$_bsc" != "null" ]; then
    settings put global battery_saver_constants "$_bsc" >/dev/null 2>&1
  else
    settings delete global battery_saver_constants >/dev/null 2>&1
  fi
  _restore_refresh_rate

  rm -f "$BSS_BACKUP"
  echo "Frosty v${MODVER:-?} - Battery Saver - $(date '+%Y-%m-%d %H:%M:%S')" > "$BS_LOG"
  echo "[$(date '+%H:%M:%S')] [OK] Reverted" >> "$BS_LOG"
  echo '{"status":"ok"}'
}