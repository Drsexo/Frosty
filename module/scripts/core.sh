#!/system/bin/sh
# Shared infrastructure for frosty.sh subscripts.

MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
SERVICES_LOG="$LOGDIR/services.log"
RAM_LOG="$LOGDIR/ram.log"
TWEAKS_LOG="$LOGDIR/kernel_tweaks.log"
PROPS_LOG="$LOGDIR/props.log"
BS_LOG="$LOGDIR/battery_saver.log"

GMS_LIST="$MODDIR/config/gms_services.txt"
USER_PREFS="$MODDIR/config/user_prefs"
KERNEL_TWEAKS="$MODDIR/config/kernel_tweaks.txt"
KERNEL_BACKUP="$MODDIR/backup/kernel_values.txt"
RAM_TWEAKS="$MODDIR/config/ram_tweaks.txt"
RAM_BACKUP="$MODDIR/backup/ram_values.txt"
LOGS_BACKUP="$MODDIR/backup/logs_values.txt"
BSS_BACKUP="$MODDIR/backup/bss_values.txt"
LMKD_BACKUP="$MODDIR/backup/lmkd_values.txt"
DEVCFG_BACKUP="$MODDIR/backup/devcfg_values.txt"
DROPBOX_TAGS="$MODDIR/config/dropbox_tags.txt"
RAM_WL_FILE="$MODDIR/config/ram_clean_whitelist.txt"
_RAM_CLEAN_LOG="$LOGDIR/ram_clean.log"
_RAM_CLEAN_PID="$MODDIR/tmp/ram_clean.pid"
_RAM_CLEAN_STATUS="$MODDIR/tmp/ram_clean_status.json"
SYSPROP="$MODDIR/system.prop"
SYSPROP_OLD="$MODDIR/system.prop.old"

mkdir -p "$LOGDIR" "$MODDIR/config" "$MODDIR/tmp" "$MODDIR/backup"

log_service() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "$SERVICES_LOG"; }
log_ram()     { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "$RAM_LOG"; }
log_tweak()   { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "$TWEAKS_LOG"; }
log_props()   { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "$PROPS_LOG"; }
log_bss()     { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$1" >> "$BS_LOG"; }

load_prefs() { [ -f "$USER_PREFS" ] && . "$USER_PREFS"; }

_bool() { [ "$1" = "1" ] && echo "true" || echo "false"; }

_set_prop() {
  if command -v resetprop >/dev/null 2>&1; then
    resetprop "$1" "$2"
  else
    setprop "$1" "$2" 2>/dev/null
  fi
}

_del_prop() {
  command -v resetprop >/dev/null 2>&1 && resetprop --delete "$1" 2>/dev/null || true
}

_devcfg_backup() {
  local _ns="$1" _key="$2"
  grep -qF "${_ns}.${_key}=" "$DEVCFG_BACKUP" 2>/dev/null && return
  local _cur
  _cur=$(device_config get "$_ns" "$_key" 2>/dev/null)
  mkdir -p "$(dirname "$DEVCFG_BACKUP")"
  printf '%s.%s=%s\n' "$_ns" "$_key" "$_cur" >> "$DEVCFG_BACKUP"
}

_devcfg_restore() {
  local _ns="$1" _key="$2"
  local _orig
  _orig=$(grep -F "${_ns}.${_key}=" "$DEVCFG_BACKUP" 2>/dev/null | cut -d= -f2-)
  if [ -n "$_orig" ] && [ "$_orig" != "null" ]; then
    device_config put "$_ns" "$_key" "$_orig" 2>/dev/null
  else
    device_config delete "$_ns" "$_key" 2>/dev/null
  fi
  if [ -f "$DEVCFG_BACKUP" ]; then
    grep -vF "${_ns}.${_key}=" "$DEVCFG_BACKUP" > "${DEVCFG_BACKUP}.tmp" 2>/dev/null
    mv -f "${DEVCFG_BACKUP}.tmp" "$DEVCFG_BACKUP" 2>/dev/null
  fi
}

get_fg_pkg() {
  local _pkg
  _pkg=$(dumpsys activity activities 2>/dev/null \
    | grep -m1 "mResumedActivity\|topResumedActivity" \
    | sed -n 's/.*{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | tr -d ' ')
  if [ -z "$_pkg" ]; then
    _pkg=$(dumpsys window windows 2>/dev/null \
      | grep -m1 "mCurrentFocus\|mFocusedWindow" \
      | sed -n 's/.*{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | tr -d ' ')
  fi
  printf '{"pkg":"%s"}\n' "${_pkg:-}"
}