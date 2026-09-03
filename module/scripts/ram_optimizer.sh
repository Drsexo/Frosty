_lmk_kernel_type() {
  if [ -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    echo classic_lmk
  elif [ -f /proc/pressure/memory ]; then
    echo psi_lmkd
  else
    echo legacy_lmkd
  fi
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
    _devcfg_backup runtime_native usap_pool_enabled
    if device_config put runtime_native usap_pool_enabled true >/dev/null 2>&1; then
      log_ram "[OK] usap_pool_enabled = true"
      kcount=$((kcount + 1))
    else
      log_ram "[FAIL] usap_pool_enabled"
      kfail=$((kfail + 1))
    fi
  fi

  _devcfg_backup activity_manager use_compaction
  if device_config put activity_manager use_compaction true >/dev/null 2>&1; then
    log_ram "[OK] use_compaction = true"
    kcount=$((kcount + 1))
  fi

  _devcfg_backup activity_manager_native_boot use_freezer
  if device_config put activity_manager_native_boot use_freezer true >/dev/null 2>&1; then
    log_ram "[OK] use_freezer = true"
    kcount=$((kcount + 1))
  fi

  _devcfg_backup alarm_manager save_battery_on_idle
  if device_config put alarm_manager save_battery_on_idle true >/dev/null 2>&1; then
    log_ram "[OK] alarm save_battery_on_idle = true"
    kcount=$((kcount + 1))
  fi

  log_ram "[OK] RAM: $((${total_kb:-0} / 1024))MB - $kcount applied, $kfail failed"
  if [ -d /sys/block/zram0 ]; then
    local _z=/sys/block/zram0 _dev=/dev/block/zram0
    local _streams; _streams=$(nproc 2>/dev/null || echo 4)
    if ! grep -q "^max_comp_streams=" "$RAM_BACKUP" 2>/dev/null; then
      printf 'max_comp_streams=%s=/sys/block/zram0/max_comp_streams\n' \
        "$(cat "$_z/max_comp_streams" 2>/dev/null)" >> "$RAM_BACKUP"
    fi
    if ! grep -q "^comp_algorithm=" "$RAM_BACKUP" 2>/dev/null; then
      printf 'comp_algorithm=%s=/sys/block/zram0/comp_algorithm\n' \
        "$(cat "$_z/comp_algorithm" 2>/dev/null | sed -n 's/.*\[\([a-z0-9-]*\)\].*/\1/p')" >> "$RAM_BACKUP"
    fi
    if ! grep -q "^disksize=" "$RAM_BACKUP" 2>/dev/null; then
      printf 'disksize=%s=/sys/block/zram0/disksize\n' \
        "$(cat "$_z/disksize" 2>/dev/null)" >> "$RAM_BACKUP"
    fi
    local _sup _best="" _cur
    _sup=$(cat "$_z/comp_algorithm" 2>/dev/null | tr -d '[]')
    _cur=$(cat "$_z/comp_algorithm" 2>/dev/null | sed -n 's/.*\[\([a-z0-9-]*\)\].*/\1/p')
    for _a in lz4 zstd lz4hc lzo-rle lzo deflate; do
      echo "$_sup" | grep -qw "$_a" && { _best=$_a; break; }
    done
    [ -z "$_best" ] && _best="lz4"
    if [ "$_cur" = "$_best" ]; then
      printf '%s\n' "$_streams" > "$_z/max_comp_streams" 2>/dev/null
      log_ram "[OK] ZRAM: algo=$_best streams=$_streams"
    elif [ -b "$_dev" ] && timeout 15 swapoff "$_dev" 2>/dev/null; then
      local _ds; _ds=$(cat "$_z/disksize" 2>/dev/null)
      printf '1\n' > "$_z/reset" 2>/dev/null
      printf '%s\n' "$_best" > "$_z/comp_algorithm" 2>/dev/null
      printf '%s\n' "$_streams" > "$_z/max_comp_streams" 2>/dev/null
      printf '%s\n' "${_ds:-0}" > "$_z/disksize" 2>/dev/null
      mkswap "$_dev" >/dev/null 2>&1
      swapon -p 32767 "$_dev" 2>/dev/null || swapon "$_dev" 2>/dev/null
      log_ram "[OK] ZRAM: algo $_cur→$_best streams=$_streams"
    else
      printf '%s\n' "$_streams" > "$_z/max_comp_streams" 2>/dev/null
      log_ram "[OK] ZRAM: algo=$_cur (active, skipped) streams=$_streams"
    fi
    [ "$_best" = "zstd" ] && printf '0\n' > /proc/sys/vm/page-cluster 2>/dev/null
    kcount=$((kcount + 1))
  fi

  if [ -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    local _lmk=/sys/module/lowmemorykiller/parameters/minfree
    if ! grep -q "^minfree=" "$RAM_BACKUP" 2>/dev/null; then
      printf 'minfree=%s=/sys/module/lowmemorykiller/parameters/minfree\n' \
        "$(cat "$_lmk" 2>/dev/null)" >> "$RAM_BACKUP"
    fi
    local _p=$(( total_kb / 4 ))
    local _f1 _f2 _f3 _f4 _f5 _f6
    if [ "${RAM_OPT_LEVEL:-moderate}" = "maximum" ]; then
      _f1=$(( _p * 25 / 1000 )); _f2=$(( _p * 3 / 100 ));  _f3=$(( _p * 4 / 100 ))
      _f4=$(( _p * 5 / 100 ));   _f5=$(( _p * 6 / 100 ));  _f6=$(( _p * 8 / 100 ))
    else
      _f1=$(( _p * 15 / 1000 )); _f2=$(( _p / 50 ));        _f3=$(( _p * 25 / 1000 ))
      _f4=$(( _p * 3 / 100 ));   _f5=$(( _p * 35 / 1000 )); _f6=$(( _p / 20 ))
    fi
    printf '%s,%s,%s,%s,%s,%s\n' \
      "$((_f1/4))" "$((_f2/4))" "$((_f3/4))" "$((_f4/4))" "$((_f5/4))" "$((_f6/4))" \
      > "$_lmk" 2>/dev/null && {
      log_ram "[OK] LMK minfree set ($(( total_kb / 1024 ))MB device, $RAM_OPT_LEVEL, thresholds ${_f1}-${_f6}KB)"
      kcount=$((kcount + 1))
    }
  fi

  local _lmk_kernel
  _lmk_kernel=$(_lmk_kernel_type)

  if [ "$_lmk_kernel" != "classic_lmk" ]; then
    mkdir -p "$MODDIR/backup"
    for _lp in ro.lmk.low ro.lmk.medium ro.lmk.critical ro.lmk.use_psi \
               ro.lmk.psi_partial_stall_ms ro.lmk.psi_complete_stall_ms \
               ro.lmk.thrashing_limit ro.lmk.swap_util_max ro.lmk.kill_heaviest_task; do
      grep -q "^${_lp}=" "$LMKD_BACKUP" 2>/dev/null && continue
      printf '%s=%s\n' "$_lp" "$(getprop "$_lp" 2>/dev/null)" >> "$LMKD_BACKUP"
    done

    if ! command -v resetprop >/dev/null 2>&1; then
      log_ram "[WARN] resetprop unavailable - LMKD ro.lmk.* properties need a reboot to take effect on this root solution"
    fi

    if [ "${RAM_OPT_LEVEL:-moderate}" = "maximum" ]; then
      _set_prop ro.lmk.low 900
      _set_prop ro.lmk.medium 600
    else
      _set_prop ro.lmk.low 1001
      _set_prop ro.lmk.medium 900
    fi
    _set_prop ro.lmk.critical 0

    if [ "$_lmk_kernel" = "psi_lmkd" ]; then
      _set_prop ro.lmk.use_psi true
      if [ "${RAM_OPT_LEVEL:-moderate}" = "maximum" ]; then
        _set_prop ro.lmk.psi_partial_stall_ms 70
        _set_prop ro.lmk.psi_complete_stall_ms 500
        _set_prop ro.lmk.thrashing_limit 60
        _set_prop ro.lmk.swap_util_max 80
        _set_prop ro.lmk.kill_heaviest_task true
      else
        _set_prop ro.lmk.psi_partial_stall_ms 200
        _set_prop ro.lmk.psi_complete_stall_ms 800
        _set_prop ro.lmk.thrashing_limit 100
        _set_prop ro.lmk.swap_util_max 100
        _set_prop ro.lmk.kill_heaviest_task false
      fi
    else
      _set_prop ro.lmk.use_psi false
    fi

    if ! _set_prop lmkd.reinit 1 2>/dev/null; then
      local _lmkd_pid
      _lmkd_pid=$(pidof lmkd 2>/dev/null)
      if [ -n "$_lmkd_pid" ]; then
        kill -HUP "$_lmkd_pid" 2>/dev/null
      else
        stop lmkd 2>/dev/null
        start lmkd 2>/dev/null
      fi
    fi

    log_ram "[OK] LMKD ($_lmk_kernel) tuned for $RAM_OPT_LEVEL"
    kcount=$((kcount + 1))
  fi

  local _vr=0
  for _node in \
    /sys/module/process_reclaim/parameters/enable_process_reclaim \
    /sys/kernel/mi_reclaim/enable \
    /sys/kernel/mi_reclaim/greclaim_enable \
    /sys/kernel/low_free/low_free_enable \
    /sys/module/memplus_core/parameters/memory_plus_enabled \
    /proc/sys/vm/memory_plus \
    /sys/module/perfmgr/parameters/perfmgr_enable \
    /sys/module/opchain/parameters/opchain_enable; do
    [ -f "$_node" ] || continue
    local _vname="${_node##*/}"
    if ! grep -q "^${_vname}=" "$RAM_BACKUP" 2>/dev/null; then
      printf '%s=%s=%s\n' "$_vname" "$(cat "$_node" 2>/dev/null)" "$_node" >> "$RAM_BACKUP"
    fi
    printf '0\n' > "$_node" 2>/dev/null && _vr=$((_vr + 1))
  done
  [ "$_vr" -gt 0 ] && log_ram "[OK] Vendor reclaim disabled ($_vr nodes)"

  echo '{"status":"ok"}'
}

_revert_multitask_keys() {
  local _mtkeyfile="$MODDIR/tmp/multitask_keys.txt"
  [ -f "$_mtkeyfile" ] || return 1
  while IFS= read -r _mtkey; do
    [ -z "$_mtkey" ] && continue
    _devcfg_restore activity_manager "$_mtkey"
  done < "$_mtkeyfile"
  rm -f "$_mtkeyfile"
  cmd activity memory-factor set 1 >/dev/null 2>&1
  return 0
}

revert_ram_optimizer() {
  echo "Frosty v${MODVER:-?} - RAM (revert) - $(date '+%Y-%m-%d %H:%M:%S')" > "$RAM_LOG"
  log_ram "Reverting RAM optimizer..."

  local _zram_partial=0

  if [ -f "$RAM_BACKUP" ]; then
    local kcount=0 _zram_algo="" _zram_streams="" _zram_disksize=""
    while IFS= read -r line; do
      case "$line" in ''|'#'*) continue ;; esac
      local val path _rest
      path="${line##*=}"
      _rest="${line%=*}"
      val="${_rest#*=}"
      case "$path" in
        */zram0/comp_algorithm)   _zram_algo="$val";    continue ;;
        */zram0/disksize)         _zram_disksize="$val"; continue ;;
        */zram0/max_comp_streams) _zram_streams="$val";  continue ;;
      esac
      [ ! -f "$path" ] && continue
      chmod +w "$path" 2>/dev/null
      printf '%s\n' "$val" > "$path" 2>/dev/null && kcount=$((kcount + 1))
    done < "$RAM_BACKUP"

    if [ -d /sys/block/zram0 ] && [ -n "$_zram_algo" ]; then
      local _z=/sys/block/zram0 _dev=/dev/block/zram0
      local _cur_algo
      _cur_algo=$(cat "$_z/comp_algorithm" 2>/dev/null | sed -n 's/.*\[\([a-z0-9-]*\)\].*/\1/p')
      if [ "$_cur_algo" != "$_zram_algo" ] && [ -b "$_dev" ]; then
        if timeout 15 swapoff "$_dev" 2>/dev/null; then
          printf '1\n' > "$_z/reset" 2>/dev/null
          printf '%s\n' "$_zram_algo" > "$_z/comp_algorithm" 2>/dev/null
          [ -n "$_zram_streams" ] && printf '%s\n' "$_zram_streams" > "$_z/max_comp_streams" 2>/dev/null
          [ -n "$_zram_disksize" ] && printf '%s\n' "$_zram_disksize" > "$_z/disksize" 2>/dev/null
          mkswap "$_dev" >/dev/null 2>&1
          swapon -p 32767 "$_dev" 2>/dev/null || swapon "$_dev" 2>/dev/null
          log_ram "[OK] ZRAM: algo restored $_cur_algo→$_zram_algo"
          kcount=$((kcount + 1))
        else
          log_ram "[WARN] ZRAM: swapoff failed, algo not restored"
          _zram_partial=1
        fi
      elif [ "$_cur_algo" = "$_zram_algo" ] && [ -n "$_zram_streams" ]; then
        printf '%s\n' "$_zram_streams" > "$_z/max_comp_streams" 2>/dev/null && kcount=$((kcount + 1))
      fi
    fi

    rm -f "$RAM_BACKUP"
    log_ram "[OK] RAM values restored ($kcount)"
  else
    log_ram "No RAM backup found"
  fi

  if [ -f "$LMKD_BACKUP" ]; then
    while IFS= read -r _line; do
      case "$_line" in ''|'#'*) continue ;; esac
      local _pname _pval
      _pname=$(printf '%s' "$_line" | cut -d= -f1)
      _pval=$(printf '%s' "$_line" | cut -d= -f2-)
      if [ -n "$_pval" ]; then
        _set_prop "$_pname" "$_pval"
      else
        _del_prop "$_pname"
      fi
    done < "$LMKD_BACKUP"
    rm -f "$LMKD_BACKUP"
    if ! _set_prop lmkd.reinit 1 2>/dev/null; then
      local _lp
      _lp=$(pidof lmkd 2>/dev/null)
      [ -n "$_lp" ] && kill -HUP "$_lp" 2>/dev/null
    fi
    log_ram "[OK] LMKD props restored"
  fi

  _devcfg_restore runtime_native usap_pool_enabled
  _devcfg_restore activity_manager use_compaction
  _devcfg_restore activity_manager_native_boot use_freezer
  _devcfg_restore alarm_manager save_battery_on_idle

  if _revert_multitask_keys; then
    log_ram "[OK] Multitasking profile reverted"
  fi

  log_ram "[OK] RAM optimizer reverted"
  if [ "$_zram_partial" = "1" ]; then
    echo "{\"status\":\"partial\",\"message\":\"ZRAM busy, algorithm not restored - retry later or reboot\"}"
  else
    echo "{\"status\":\"ok\"}"
  fi
}

apply_multitasking() {
  local _tier="$1" _mult _keyfile="$MODDIR/tmp/multitask_keys.txt"
  case "$_tier" in
    performance) _mult=125 ;;
    balanced)    _mult=100 ;;
    powersaving) _mult=75  ;;
    *) echo '{"status":"error","message":"invalid tier"}'; return 1 ;;
  esac

  mkdir -p "$MODDIR/tmp"
  : > "$_keyfile"
  local _tmp="$MODDIR/tmp/_am_settings.tmp"
  dumpsys activity settings 2>/dev/null | grep -iE 'cached' > "$_tmp"

  local _count=0 _key _val _new
  while IFS= read -r _line; do
    _key=$(printf '%s' "$_line" | cut -d= -f1)
    _val=$(printf '%s' "$_line" | cut -d= -f2 | grep -oE '^[0-9]+')
    [ -z "$_val" ] && continue
    _new=$(( _val * _mult / 100 ))
    _devcfg_backup activity_manager "$_key"
    if device_config put activity_manager "$_key" "$_new" >/dev/null 2>&1; then
      echo "$_key" >> "$_keyfile"
      _count=$((_count + 1))
    fi
  done < "$_tmp"
  rm -f "$_tmp"

  case "$_tier" in
    performance) cmd activity memory-factor set 0 2>/dev/null ;;
    balanced)    cmd activity memory-factor set 1 2>/dev/null ;;
    powersaving) cmd activity memory-factor set 2 2>/dev/null ;;
  esac

  log_ram "[OK] Multitasking profile: $_tier ($_count keys)"
  echo "{\"status\":\"ok\",\"applied\":$_count}"
}

revert_multitasking() {
  _revert_multitask_keys
  log_ram "[OK] Multitasking profile reverted"
  echo '{"status":"ok"}'
}