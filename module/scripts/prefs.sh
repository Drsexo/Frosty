_list_pkg_file() {
  local file="$1" installed line pkg first=1
  [ -f "$file" ] || { echo '{"status":"ok","packages":[]}'; return; }
  installed=$(pm list packages 2>/dev/null | cut -d: -f2)
  printf '{"status":"ok","packages":['
  while IFS= read -r line; do
    pkg=$(printf '%s' "$line" | sed 's/#.*//;s/[[:space:]]//g')
    [ -z "$pkg" ] && continue
    printf '%s\n' "$installed" | grep -qFx "$pkg" || continue
    [ "$first" = "1" ] && first=0 || printf ','
    printf '"%s"' "$pkg"
  done < "$file"
  printf ']}\n'
}

_add_pkg_line() {
  local file="$1" pkg="$2"
  _valid_pkg "$pkg" || return 1
  mkdir -p "$MODDIR/config"
  [ -f "$file" ] || touch "$file"
  grep -qFx "$pkg" "$file" 2>/dev/null || echo "$pkg" >> "$file"
}

_remove_pkg_line() {
  local file="$1" pkg="$2" escaped
  _valid_pkg "$pkg" || return 1
  [ -f "$file" ] || return 0
  escaped=$(printf '%s' "$pkg" | sed 's/[][\.*^$\/]/\\&/g')
  sed -i "/^${escaped}$/d" "$file"
}

_file_state() { [ -f "$1" ] && echo 1 || echo 0; }

_pid_state() {
  local _p
  _p=$(cat "$1" 2>/dev/null)
  [ -n "$_p" ] && kill -0 "$_p" 2>/dev/null && echo 1 || echo 0
}

apply_soo() {
  chmod +x "$MODDIR/scripts/screen_off_opt.sh" 2>/dev/null
  sh "$MODDIR/scripts/screen_off_opt.sh" start 2>/dev/null
  if [ "$(_pid_state "$MODDIR/tmp/soo_monitor.pid")" = "1" ]; then
    echo '{"status":"ok"}'
  else
    echo '{"status":"error"}'
  fi
}

revert_soo() {
  sh "$MODDIR/scripts/screen_off_opt.sh" stop 2>/dev/null
  echo '{"status":"ok"}'
}

list_wl()     { _list_pkg_file "$MODDIR/config/doze_whitelist.txt"; }
list_ram_wl() { _list_pkg_file "$RAM_WL_FILE"; }

add_to_wl() {
  _add_pkg_line "$MODDIR/config/doze_whitelist.txt" "$1" || { echo '{"status":"error"}'; return; }
  [ "$ENABLE_DEEP_DOZE" = "1" ] && sh "$MODDIR/scripts/deep_doze.sh" unrestrict_pkg "$1" >/dev/null 2>&1
  echo '{"status":"ok"}'
}

remove_from_wl() {
  _remove_pkg_line "$MODDIR/config/doze_whitelist.txt" "$1" || { echo '{"status":"error"}'; return; }
  [ "$ENABLE_DEEP_DOZE" = "1" ] && sh "$MODDIR/scripts/deep_doze.sh" restrict_pkg "$1" >/dev/null 2>&1
  echo '{"status":"ok"}'
}

add_to_ram_wl() {
  _add_pkg_line "$RAM_WL_FILE" "$1" || { echo '{"status":"error"}'; return; }
  echo '{"status":"ok"}'
}

remove_from_ram_wl() {
  _remove_pkg_line "$RAM_WL_FILE" "$1" || { echo '{"status":"error"}'; return; }
  echo '{"status":"ok"}'
}

feature_state() {
  printf '{"status":"ok","applied":%s,"kernel_tweaks":%s,"ram_optimizer":%s,"multitask_enabled":%s,"log_killing":%s,"kill_tracking":%s,"deep_doze":%s,"screen_off_opt":%s,"battery_saver":%s}\n' \
    "$(_file_state "$MODDIR/tmp/applied")" \
    "$(_file_state "$KERNEL_BACKUP")" \
    "$(_file_state "$RAM_BACKUP")" \
    "$(_file_state "$MODDIR/tmp/mt_keys.txt")" \
    "$(_file_state "$LOGS_BACKUP")" \
    "$(_file_state "$MODDIR/backup/kill_tracking.txt")" \
    "$(_file_state "$MODDIR/backup/deep_doze_settings.txt")" \
    "$(_pid_state "$MODDIR/tmp/soo_monitor.pid")" \
    "$(_file_state "$BSS_BACKUP")"
}
