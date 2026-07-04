should_disable_category() {
case "$1" in
    background)   [ "$DISABLE_BACKGROUND" = "1" ] ;;
    telemetry)    [ "$DISABLE_TELEMETRY" = "1" ] ;;
    location)     [ "$DISABLE_LOCATION" = "1" ] ;;
    connectivity) [ "$DISABLE_CONNECTIVITY" = "1" ] ;;
    cloud)        [ "$DISABLE_CLOUD" = "1" ] ;;
    payments)     [ "$DISABLE_PAYMENTS" = "1" ] ;;
    wearables)    [ "$DISABLE_WEARABLES" = "1" ] ;;
    games)        [ "$DISABLE_GAMES" = "1" ] ;;
    *) return 1 ;;
  esac
}


freeze_services() {
  echo "Frosty v${MODVER:-?} - Services (FREEZE) - $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  [ ! -f "$GMS_LIST" ] && { echo "ERROR: Service list not found"; return 1; }

  local _frozen_file="$MODDIR/tmp/frozen_services.txt"
  local _prev_frozen=""
  [ -f "$_frozen_file" ] && _prev_frozen=$(cat "$_frozen_file" 2>/dev/null)
  > "$_frozen_file" 2>/dev/null || true

  local current_category="" count_ok=0 count_fail=0

  while IFS='|' read -r service category || [ -n "$service" ]; do
    case "$service" in ''|'#'*) continue ;; esac
    service=$(echo "$service" | tr -d ' ')
    category=$(echo "$category" | tr -d ' ')
    [ -z "$category" ] && continue

    if [ "$category" != "$current_category" ]; then
      current_category="$category"
      log_service ""
      _cap_f=$(printf '%s' "$current_category" | cut -c1 | tr 'a-z' 'A-Z')
      _cap_r=$(printf '%s' "$current_category" | cut -c2-)
      log_service "# ${_cap_f}${_cap_r}"
    fi

    if should_disable_category "$category"; then
      local _svc_pkg; _svc_pkg=$(printf '%s' "$service" | cut -d/ -f1)
      if pm list packages --user 0 -d 2>/dev/null | grep -Fx "package:$_svc_pkg" >/dev/null 2>&1; then
        if printf '%s\n' "$_prev_frozen" | grep -Fx "$service" >/dev/null 2>&1; then
          printf '%s\n' "$service" >> "$_frozen_file"
          log_service "[OK] $service (re-tracked)"
          count_ok=$((count_ok + 1))
        else
          log_service "[SKIP] $service (pre-disabled by ROM)"
        fi
        continue
      fi
      if pm disable "$service" >/dev/null 2>&1; then
        printf '%s\n' "$service" >> "$_frozen_file"
        log_service "[OK] $service"
        count_ok=$((count_ok + 1))
      else
        log_service "[FAIL] $service"
        count_fail=$((count_fail + 1))
      fi
    fi
  done < "$GMS_LIST"

  log_service ""
  log_service "Summary: $count_ok disabled, $count_fail failed"
  echo "  Disabled: $count_ok  Re-enabled: 0  Failed: $count_fail"
}

unfreeze_services() {
  echo "Frosty v${MODVER:-?} - Services (STOCK) - $(date '+%Y-%m-%d %H:%M:%S')" > "$SERVICES_LOG"
  [ ! -f "$GMS_LIST" ] && { echo "ERROR: Service list not found"; return 1; }

  local _frozen_file="$MODDIR/tmp/frozen_services.txt"
  local current_category="" count_ok=0 count_fail=0

  if [ -f "$_frozen_file" ]; then
    log_service "Restoring from tracking file..."
    while IFS= read -r service; do
      case "$service" in ''|'#'*) continue ;; esac
      if pm enable "$service" >/dev/null 2>&1; then
        log_service "[OK] $service"
        count_ok=$((count_ok + 1))
      else
        log_service "[FAIL] $service"
        count_fail=$((count_fail + 1))
      fi
    done < "$_frozen_file"
    rm -f "$_frozen_file"
  else
    log_service "No tracking file - using full service list..."
    while IFS='|' read -r service category || [ -n "$service" ]; do
      case "$service" in ''|'#'*) continue ;; esac
      service=$(echo "$service" | tr -d ' ')
      category=$(echo "$category" | tr -d ' ')
      [ -z "$category" ] && continue
      if [ "$category" != "$current_category" ]; then
        current_category="$category"
        log_service ""
        _cap_f=$(printf '%s' "$current_category" | cut -c1 | tr 'a-z' 'A-Z')
        _cap_r=$(printf '%s' "$current_category" | cut -c2-)
        log_service "# ${_cap_f}${_cap_r}"
      fi
      local _svc_pkg; _svc_pkg=$(printf '%s' "$service" | cut -d/ -f1)
      if pm list packages --user 0 -d 2>/dev/null | grep -Fx "package:$_svc_pkg" >/dev/null 2>&1; then
        log_service "[SKIP] $service (disabled by ROM, not re-enabling)"
        continue
      fi
      if pm enable "$service" >/dev/null 2>&1; then
        log_service "[OK] $service"
        count_ok=$((count_ok + 1))
      else
        log_service "[FAIL] $service"
        count_fail=$((count_fail + 1))
      fi
    done < "$GMS_LIST"
  fi

  log_service ""
  log_service "Summary: $count_ok re-enabled, $count_fail failed"
  echo "  Re-enabled: $count_ok  Failed: $count_fail"
}

freeze_category() {
  local target="$1" count=0 fail=0
  [ ! -f "$GMS_LIST" ] && { echo '{"status":"error","message":"gms_services.txt not found"}'; return; }

  local _frozen_file="$MODDIR/tmp/frozen_services.txt"
  local _jobs_tmp="/data/local/tmp/frosty_jobs_$$"
  : > "$_jobs_tmp"
  mkdir -p "$MODDIR/tmp"

  while IFS='|' read -r svc cat || [ -n "$svc" ]; do
    case "$svc" in ''|'#'*) continue ;; esac
    svc=$(echo "$svc" | tr -d " ")
    cat=$(echo "$cat" | tr -d " ")
    [ "$cat" = "$target" ] || continue
    local _svc_pkg; _svc_pkg=$(printf '%s' "$svc" | cut -d/ -f1)
    if pm list packages --user 0 -d 2>/dev/null | grep -Fx "package:$_svc_pkg" >/dev/null 2>&1; then
      continue
    fi
    if pm disable "$svc" >/dev/null 2>&1; then
      count=$((count + 1))
      printf '%s\n' "$svc" >> "$_frozen_file"
      printf '%s\n' "$_svc_pkg" >> "$_jobs_tmp"
    else
      fail=$((fail + 1))
    fi
  done < "$GMS_LIST"

  sort -u "$_jobs_tmp" 2>/dev/null | while IFS= read -r _pkg; do
    [ -n "$_pkg" ] && cmd jobscheduler cancel -u 0 "$_pkg" >/dev/null 2>&1
  done
  rm -f "$_jobs_tmp"

  echo "{\"status\":\"ok\",\"disabled\":$count,\"failed\":$fail}"
}

unfreeze_category() {
  local target="$1" count=0 fail=0
  [ ! -f "$GMS_LIST" ] && { echo '{"status":"error","message":"gms_services.txt not found"}'; return; }

  local _frozen_file="$MODDIR/tmp/frozen_services.txt"
  local _use_tracking=0
  [ -f "$_frozen_file" ] && _use_tracking=1

  while IFS='|' read -r svc cat || [ -n "$svc" ]; do
    case "$svc" in ''|'#'*) continue ;; esac
    svc=$(echo "$svc" | tr -d " ")
    cat=$(echo "$cat" | tr -d " ")
    [ "$cat" = "$target" ] || continue
    if [ "$_use_tracking" = "1" ] && ! grep -qFx "$svc" "$_frozen_file" 2>/dev/null; then
      continue
    fi
    if pm enable "$svc" >/dev/null 2>&1; then
      count=$((count + 1))
    else
      fail=$((fail + 1))
    fi
  done < "$GMS_LIST"

  if [ "$_use_tracking" = "1" ]; then
    local _svcs_tmp="/data/local/tmp/frosty_svcs_$$"
    grep "|${target}$" "$GMS_LIST" 2>/dev/null | cut -d'|' -f1 | tr -d ' ' > "$_svcs_tmp"
    if [ -s "$_svcs_tmp" ]; then
      local _ftmp="${_frozen_file}.tmp"
      grep -vFxf "$_svcs_tmp" "$_frozen_file" > "$_ftmp" 2>/dev/null
      mv -f "$_ftmp" "$_frozen_file" 2>/dev/null
    fi
    rm -f "$_svcs_tmp"
  fi

  echo "{\"status\":\"ok\",\"enabled\":$count,\"failed\":$fail}"
}