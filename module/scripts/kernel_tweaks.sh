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

  local last_section="" section="" count=0 fail=0 skip=0
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
  for pattern in debug_mask log_level debug_level enable_event_log; do
    for dpath in $(find /sys/ -maxdepth 4 -type f -name "$pattern" 2>/dev/null | head -20); do
      if ! grep -qF "=$dpath" "$KERNEL_BACKUP" 2>/dev/null; then
        printf '%s=%s=%s\n' "$(basename "$dpath")" "$(cat "$dpath" 2>/dev/null)" "$dpath" >> "$KERNEL_BACKUP"
      fi
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
        _actual=$(cat "$_tcp_cc" 2>/dev/null)
        log_tweak ""
        log_tweak "# TCP CONGESTION"
        if [ "$_actual" = "$_algo" ]; then
          log_tweak "[OK] tcp_congestion_control: $_old_cc -> $_algo"
          count=$((count + 1))
        else
          log_tweak "[WARN] tcp_congestion_control write failed (got: ${_actual:-empty})"
        fi
        break ;;
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
      if ! grep -q "^read_ahead_kb_${dev}=" "$KERNEL_BACKUP" 2>/dev/null; then
        printf 'read_ahead_kb_%s=%s=%s\n' "$dev" "$(cat "$queue/read_ahead_kb" 2>/dev/null)"           "$queue/read_ahead_kb" >> "$KERNEL_BACKUP"
      fi
      printf '128\n' > "$queue/read_ahead_kb" 2>/dev/null && io_count=$((io_count + 1))
    fi
    if [ -f "$queue/iostats" ]; then
      if ! grep -q "^iostats_${dev}=" "$KERNEL_BACKUP" 2>/dev/null; then
        printf 'iostats_%s=%s=%s\n' "$dev" "$(cat "$queue/iostats" 2>/dev/null)"           "$queue/iostats" >> "$KERNEL_BACKUP"
      fi
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