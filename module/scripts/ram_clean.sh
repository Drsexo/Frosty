_rc_log() {
  printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >> "$_RAM_CLEAN_LOG"
}

_find_caller_pkg() {
  local _pkg="" _uid _pid _ppid

  _pid=$$
  while [ "$_pid" -gt 1 ] 2>/dev/null; do
    _uid=$(awk '/^Uid:/{print $2}' "/proc/$_pid/status" 2>/dev/null)
    if [ -n "$_uid" ] && [ "$_uid" -ge 10000 ] 2>/dev/null; then
      _pkg=$(pm list packages --uid "$_uid" 2>/dev/null | head -1 | cut -d: -f2)
      [ -n "$_pkg" ] && { echo "$_pkg"; return 0; }
    fi
    _ppid=$(awk '/^PPid:/{print $2}' "/proc/$_pid/status" 2>/dev/null)
    [ "$_ppid" = "$_pid" ] && break
    _pid=$_ppid
  done

  _pkg=$(dumpsys activity activities 2>/dev/null |
    grep -m1 -E 'mResumedActivity|topResumedActivity' |
    sed -n 's/.*{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | tr -d ' \r')
  [ -n "$_pkg" ] && { echo "$_pkg"; return 0; }

  _pkg=$(dumpsys window windows 2>/dev/null |
    grep -m1 -E 'mCurrentFocus|mFocusedWindow' |
    sed -n 's/.*{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | tr -d ' \r')
  [ -n "$_pkg" ] && { echo "$_pkg"; return 0; }

  return 1
}

_ram_clean_worker() {
  local mode="$1" exclude="$2"
  local _count=0 _skip=0

  local _mem_before _mem_before_mb
  _mem_before=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null)
  _mem_before_mb=$(( ${_mem_before:-0} / 1024 ))

  printf 'Frosty v%s - RAM Cleaner [%s] - %s\n' \
    "${MODVER:-?}" "$(printf '%s' "$mode" | tr 'a-z' 'A-Z')" \
    "$(date '+%Y-%m-%d %H:%M:%S')" > "$_RAM_CLEAN_LOG"
  _rc_log "Memory before: ${_mem_before_mb} MB available"

  local _fg=""
  if [ "$mode" = "aggressive" ] || [ "$mode" = "extreme" ]; then
    _fg=$(_find_caller_pkg)
  fi

  _rc_log "Syncing and dropping page cache..."
  sync
  echo 3 > /proc/sys/vm/drop_caches 2>/dev/null

  case "$mode" in
    safe)
      _rc_log "Releasing cached background processes..."
      am kill-all 2>/dev/null
      _rc_log "[OK] Background processes released"
      sync
      echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
      if [ -f /proc/sys/vm/compact_memory ]; then
        _rc_log "Compacting memory..."
        echo 1 > /proc/sys/vm/compact_memory 2>/dev/null
        _rc_log "[OK] Memory compacted"
      fi
      [ -f /sys/block/zram0/compact ] && echo 1 > /sys/block/zram0/compact 2>/dev/null
      ;;
    aggressive)
      _rc_log "Force-stopping 3rd-party apps..."
      for _pkg in $(pm list packages -3 --user 0 2>/dev/null | \
          cut -d: -f2 | tr -d '\r' | sort); do
        [ -n "$_fg" ]     && [ "$_pkg" = "$_fg" ]     && { _skip=$((_skip+1)); continue; }
        [ -n "$exclude" ] && [ "$_pkg" = "$exclude" ] && { _skip=$((_skip+1)); continue; }
        grep -qFx "$_pkg" "$RAM_WL_FILE" 2>/dev/null    && { _skip=$((_skip+1)); continue; }
        am force-stop "$_pkg" 2>/dev/null
        _count=$((_count+1))
      done
      _rc_log "[OK] Force-stopped $_count apps${_skip:+ ($_skip protected)}"
      sync
      echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
      if [ -f /proc/sys/vm/compact_memory ]; then
        _rc_log "Compacting memory..."
        echo 1 > /proc/sys/vm/compact_memory 2>/dev/null
        _rc_log "[OK] Memory compacted"
      fi
      [ -f /sys/block/zram0/compact ] && echo 1 > /sys/block/zram0/compact 2>/dev/null
      ;;
    extreme)
      local _home _excl="com.android.systemui com.android.phone android.process.acore"
      _home=$(cmd package resolve-activity --brief \
        -a android.intent.action.MAIN \
        -c android.intent.category.HOME 2>/dev/null | tail -1 | cut -d/ -f1 | tr -d '\r')
      [ -n "$_home" ]   && _excl="$_excl $_home"
      [ -n "$_fg" ]     && _excl="$_excl $_fg"
      [ -n "$exclude" ] && _excl="$_excl $exclude"
      [ -f "$RAM_WL_FILE" ] && _excl="$_excl $(grep -v '^#' "$RAM_WL_FILE" 2>/dev/null | tr '\n' ' ')"
      _rc_log "Force-stopping all packages..."
      for _pkg in $(pm list packages --user 0 2>/dev/null | \
          cut -d: -f2 | tr -d '\r' | sort); do
        case "$_pkg" in android|com.android.*|android.process.*) _skip=$((_skip+1)); continue ;; esac
        local _blocked=0
        for _ex in $_excl; do
          [ "$_pkg" = "$_ex" ] && { _blocked=1; break; }
        done
        [ "$_blocked" = "1" ] && { _skip=$((_skip+1)); continue; }
        am force-stop "$_pkg" 2>/dev/null
        _count=$((_count+1))
      done
      _rc_log "[OK] Force-stopped $_count apps${_skip:+ ($_skip protected)}"
      sync
      echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
      if [ -f /proc/sys/vm/compact_memory ]; then
        _rc_log "Compacting memory..."
        echo 1 > /proc/sys/vm/compact_memory 2>/dev/null
        _rc_log "[OK] Memory compacted"
      fi
      [ -f /sys/block/zram0/compact ] && echo 1 > /sys/block/zram0/compact 2>/dev/null
      ;;
  esac

  local _mem_after _mem_after_mb _freed_mb=0
  _mem_after=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null)
  _mem_after_mb=$(( ${_mem_after:-0} / 1024 ))
  [ -n "$_mem_before" ] && [ -n "$_mem_after" ] && \
    _freed_mb=$(( (_mem_after - _mem_before) / 1024 ))
  _rc_log "[OK] Memory after: ${_mem_after_mb} MB available (+${_freed_mb} MB)"
  _rc_log "Done"

  printf '{"running":false,"apps":%s,"freed":%s}\n' "$_count" "$_freed_mb" > "${_RAM_CLEAN_STATUS}.tmp"
  mv -f "${_RAM_CLEAN_STATUS}.tmp" "$_RAM_CLEAN_STATUS"
  rm -f "$_RAM_CLEAN_PID"
}

ram_clean() {
  local mode="$1" exclude="$2"
  case "$mode" in safe|aggressive|extreme) ;;
    *) printf '{"status":"error","msg":"invalid mode"}\n'; return 1 ;;
  esac
  if [ -f "$_RAM_CLEAN_PID" ]; then
    local _pid; _pid=$(cat "$_RAM_CLEAN_PID" 2>/dev/null)
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
      printf '{"status":"busy"}\n'; return
    fi
    rm -f "$_RAM_CLEAN_PID"
  fi
  mkdir -p "$MODDIR/tmp"
  _ram_clean_worker "$mode" "$exclude" &
  printf '%s\n' "$!" > "$_RAM_CLEAN_PID"
  printf '{"status":"started"}\n'
}

ram_clean_silent() {
  local mode="$1"
  case "$mode" in safe|aggressive|extreme) ;;
    off|"") return 0 ;; *) return 1 ;;
  esac
  if [ -f "$_RAM_CLEAN_PID" ]; then
    local _pid; _pid=$(cat "$_RAM_CLEAN_PID" 2>/dev/null)
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
      return 0
    fi
    rm -f "$_RAM_CLEAN_PID"
  fi
  mkdir -p "$MODDIR/tmp"
  _ram_clean_worker "$mode" ""
}

ram_clean_poll() {
  local _running=false _apps=0 _freed=0
  if [ -f "$_RAM_CLEAN_PID" ]; then
    local _pid; _pid=$(cat "$_RAM_CLEAN_PID" 2>/dev/null)
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then
      _running=true
    else
      rm -f "$_RAM_CLEAN_PID"
    fi
  fi
  if [ "$_running" = "false" ] && [ -f "$_RAM_CLEAN_STATUS" ]; then
    cat "$_RAM_CLEAN_STATUS"
    return
  fi
  if [ "$_running" = "false" ] && [ -f "$_RAM_CLEAN_LOG" ]; then
    _apps=$(grep -oE 'Force-stopped [0-9]+ apps' "$_RAM_CLEAN_LOG" 2>/dev/null |       tail -1 | grep -oE '[0-9]+' | head -1)
    _freed=$(grep 'Memory after:' "$_RAM_CLEAN_LOG" 2>/dev/null |       grep -oE '\+[0-9]+' | tr -d '+')
    : "${_apps:=0}" "${_freed:=0}"
  fi
  printf '{"running":%s,"apps":%s,"freed":%s}\n' "$_running" "$_apps" "$_freed"
}

get_fg_pkg() {
  local _pkg=""
  _pkg=$(dumpsys activity activities 2>/dev/null | \
    grep -m1 "mResumedActivity\|topResumedActivity" | \
    sed -n 's/.*{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | tr -d ' ')
  if [ -z "$_pkg" ]; then
    _pkg=$(dumpsys window windows 2>/dev/null | \
      grep -m1 "mCurrentFocus\|mFocusedWindow" | \
      sed -n 's/.*{[^ ]* [^ ]* \([^/]*\)\/.*/\1/p' | tr -d ' ')
  fi
  printf '{"pkg":"%s"}\n' "${_pkg:-}"
}