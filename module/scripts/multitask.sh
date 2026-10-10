MT_KEYFILE="$MODDIR/tmp/mt_keys.txt"
MT_BASE="$MODDIR/backup/mt_base.txt"
_MT_LEGACY_KEYFILE="$MODDIR/tmp/multitask_keys.txt"

_revert_multitask_keys() {
  rm -f "$_MT_LEGACY_KEYFILE" "$MT_BASE"
  [ -f "$MT_KEYFILE" ] || return 1
  while IFS= read -r _mtkey; do
    [ -z "$_mtkey" ] && continue
    _devcfg_restore activity_manager "$_mtkey"
  done < "$MT_KEYFILE"
  rm -f "$MT_KEYFILE"
  cmd activity memory-factor reset >/dev/null 2>&1 || cmd activity memory-factor set 0 >/dev/null 2>&1
  return 0
}

apply_multitasking() {
  local _tier="$1" _mult
  case "$_tier" in
    performance) _mult=125 ;;
    balanced)    _mult=100 ;;
    powersaving) _mult=75  ;;
    *) echo '{"status":"error","message":"invalid tier"}'; return 1 ;;
  esac

  rm -f "$_MT_LEGACY_KEYFILE"
  mkdir -p "$MODDIR/tmp" "$MODDIR/backup"
  : > "$MT_KEYFILE"
  local _tmp="$MODDIR/tmp/_am_settings.tmp"
  dumpsys activity settings 2>/dev/null | grep -iE 'cached' > "$_tmp"

  local _count=0 _key _val _base _new
  while IFS= read -r _line; do
    _key=$(printf '%s' "$_line" | cut -d= -f1 | tr -d '[:space:]')
    case "$_key" in ''|*[!a-z_]*) continue ;; esac
    _val=$(printf '%s' "$_line" | cut -d= -f2 | grep -oE '^[0-9]+')
    [ -z "$_val" ] && continue
    _base=$(grep "^${_key}=" "$MT_BASE" 2>/dev/null | cut -d= -f2)
    if [ -z "$_base" ]; then
      _base="$_val"
      printf '%s=%s\n' "$_key" "$_val" >> "$MT_BASE"
    fi
    _new=$(( _base * _mult / 100 ))
    _devcfg_backup activity_manager "$_key"
    if device_config put activity_manager "$_key" "$_new" >/dev/null 2>&1; then
      echo "$_key" >> "$MT_KEYFILE"
      _count=$((_count + 1))
    fi
  done < "$_tmp"
  rm -f "$_tmp"

  case "$_tier" in
    performance) cmd activity memory-factor set 0 2>/dev/null ;;
    balanced)    cmd activity memory-factor set 1 2>/dev/null ;;
    powersaving) cmd activity memory-factor set 2 2>/dev/null ;;
  esac

  log_mt "[OK] Multitasking profile: $_tier ($_count keys)"
  echo "{\"status\":\"ok\",\"applied\":$_count}"
}

revert_multitasking() {
  _revert_multitask_keys
  log_mt "[OK] Multitasking profile reverted"
  echo '{"status":"ok"}'
}
