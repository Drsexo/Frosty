apply_soo() {
  chmod +x "$MODDIR/scripts/screen_off_opt.sh" 2>/dev/null
  sh "$MODDIR/scripts/screen_off_opt.sh" start 2>/dev/null
  echo '{"status":"ok"}'
}

revert_soo() {
  sh "$MODDIR/scripts/screen_off_opt.sh" stop 2>/dev/null
  echo '{"status":"ok"}'
}

list_wl() {
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
    echo "$installed" | grep -qFx "$pkg" || continue
    [ "$first" = "1" ] && first=0 || printf ','
    printf '"%s"' "$pkg"
  done < "$wl"
  printf ']}\n'
}

add_to_wl() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  local wl="$MODDIR/config/doze_whitelist.txt"
  mkdir -p "$MODDIR/config"
  [ -f "$wl" ] || touch "$wl"
  grep -qFx "$pkg" "$wl" 2>/dev/null || echo "$pkg" >> "$wl"
  echo '{"status":"ok"}'
}

remove_from_wl() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  local wl="$MODDIR/config/doze_whitelist.txt"
  [ -f "$wl" ] || { echo '{"status":"ok"}'; return; }
  local escaped
  escaped=$(printf '%s' "$pkg" | sed 's/\./\\./g')
  sed -i "/^${escaped}$/d" "$wl"
  echo '{"status":"ok"}'
}

list_ram_wl() {
  [ -f "$RAM_WL_FILE" ] || { echo '{"status":"ok","packages":[]}'; return; }
  local installed
  installed=$(pm list packages 2>/dev/null | cut -d: -f2)
  printf '{"status":"ok","packages":['
  local first=1
  while IFS= read -r line; do
    local pkg
    pkg=$(echo "$line" | sed 's/#.*//;s/[[:space:]]//g')
    [ -z "$pkg" ] && continue
    echo "$installed" | grep -qFx "$pkg" || continue
    [ "$first" = "1" ] && first=0 || printf ','
    printf '"%s"' "$pkg"
  done < "$RAM_WL_FILE"
  printf ']}\n'
}

add_to_ram_wl() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  mkdir -p "$MODDIR/config"
  [ -f "$RAM_WL_FILE" ] || touch "$RAM_WL_FILE"
  grep -qFx "$pkg" "$RAM_WL_FILE" 2>/dev/null || echo "$pkg" >> "$RAM_WL_FILE"
  echo '{"status":"ok"}'
}

remove_from_ram_wl() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  [ -f "$RAM_WL_FILE" ] || { echo '{"status":"ok"}'; return; }
  local escaped
  escaped=$(printf '%s' "$pkg" | sed 's/\./\\./g')
  sed -i "/^${escaped}$/d" "$RAM_WL_FILE"
  echo '{"status":"ok"}'
}