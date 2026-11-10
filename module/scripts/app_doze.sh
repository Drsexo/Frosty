#!/system/bin/sh
# Frosty - App Doze

_d="${0%/*}"
[ -z "$_d" ] && _d="/data/adb/modules/Frosty/scripts"
MODDIR="${_d%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
unset _d
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)
. "$MODDIR/scripts/core.sh"

LOGDIR="$MODDIR/logs"
APP_DOZE_LOG="$LOGDIR/app_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
PATCHES_FILE="$MODDIR/config/doze_patches.txt"
OVERLAYS_FILE="$MODDIR/config/doze_xml_overlays.txt"
BACKUP_DIR="$MODDIR/backup/overlays"
INSTALLED_FILE="$MODDIR/tmp/cad_installed.txt"
MISSING_FILE="$MODDIR/tmp/cad_missing.txt"
SESSION_FILE="$MODDIR/tmp/cad_session_built"
XML_OFF_FILE="$MODDIR/tmp/cad_xml_off"
BUILD_STAMP="$MODDIR/backup/overlays.build"
WL_ORIG_FILE="$MODDIR/tmp/cad_orig_wl.txt"

GMS_PKG="com.google.android.gms"
GMS_ADMIN1="$GMS_PKG/$GMS_PKG.auth.managed.admin.DeviceAdminReceiver"
GMS_ADMIN2="$GMS_PKG/$GMS_PKG.mdm.receivers.MdmDeviceAdminReceiver"

_PARTITION_ROOTS="
  /india /my_bigball /my_carrier /my_company /my_engineering /my_heytap
  /my_manifest /my_preload /my_product /my_region /my_reserve /my_stock
  /odm /product /system /system_ext /vendor
  /system/odm /system/product /system/system_ext /system/vendor
"

_BLOCKED="android com.android.systemui com.android.phone com.android.settings \
          com.android.shell com.android.bluetooth com.android.nfc"

ENABLE_CUSTOM_APP_DOZE=0
[ -f "$USER_PREFS" ] && . "$USER_PREFS"

mkdir -p "$LOGDIR" "$MODDIR/tmp"
log_app() { echo "[$(date '+%H:%M:%S')] $1" >> "$APP_DOZE_LOG"; }

_is_blocked() {
  local pkg="$1"
  for b in $_BLOCKED; do [ "$pkg" = "$b" ] && return 0; done
  return 1
}

_refresh_installed() {
  local _t="${INSTALLED_FILE}.tmp"
  pm list packages -u 2>/dev/null | sed -n 's/^package://p' | tr -d '\r' > "$_t"
  if [ "$(grep -c '' "$_t")" -ge 20 ]; then
    mv -f "$_t" "$INSTALLED_FILE"
  else
    rm -f "$_t" "$INSTALLED_FILE"
  fi
}

_is_present() {
  [ -s "$INSTALLED_FILE" ] || return 0
  grep -qxF "$1" "$INSTALLED_FILE"
}

_note_missing() {
  : > "$MISSING_FILE"
  [ -s "$INSTALLED_FILE" ] || return 0
  [ -f "$PATCHES_FILE" ] || return 0
  local _p
  for _p in $(sed 's/#.*//;s/[[:space:]]//g' "$PATCHES_FILE" | grep -v '^$' | sort -u); do
    _is_blocked "$_p" && continue
    if ! grep -qxF "$_p" "$INSTALLED_FILE"; then
      echo "$_p" >> "$MISSING_FILE"
      log_app "[SKIP] $_p is not installed (renamed or removed)"
    fi
  done
}

_load_packages() {
  _load_packages_raw | while IFS= read -r _p; do
    _is_present "$_p" && echo "$_p"
  done
}

_valid_overlay() {
  local _src="$1" _out="$2" _ranges="$3" _n_src _n_out _removed _bal
  [ -s "$_out" ] && grep -q '</' "$_out" 2>/dev/null || return 1
  _n_src=$(grep -c '' "$_src")
  _n_out=$(grep -c '' "$_out")
  _removed=$(printf '%s\n' "$_ranges" | awk -F'[,d]' 'NF>1 && $1!="" { if ($2=="") n+=1; else n+=$2-$1+1 } END { print n+0 }')
  [ $((_n_src - _n_out)) -eq "$_removed" ] || return 1
  [ "$(head -n1 "$_src")" = "$(head -n1 "$_out")" ] || return 1
  [ "$(tail -n1 "$_src")" = "$(tail -n1 "$_out")" ] || return 1
  if [ -n "$_ranges" ]; then
    _bal=$(sed -n "$(printf '%s' "$_ranges" | sed 's/d$/p/' | tr '\n' ';')" "$_src" | awk '{ o+=gsub(/<[A-Za-z]/,"&"); s+=gsub(/\/>/,"&"); c+=gsub(/<\//,"&") } END { print o-s-c }')
    [ "${_bal:-1}" -eq 0 ] || return 1
    sed "$(printf '%s' "$_ranges" | tr '\n' ';')" "$_src" > "${_out}.chk"
  else
    cp "$_src" "${_out}.chk"
  fi
  cmp -s "${_out}.chk" "$_out"
  _bal=$?
  rm -f "${_out}.chk"
  return $_bal
}

_load_packages_raw() {
  [ ! -f "$PATCHES_FILE" ] && return
  sed 's/#.*//;s/[[:space:]]//g' "$PATCHES_FILE" | grep -v '^$' | sort -u | while IFS= read -r _p; do
    _is_blocked "$_p" || echo "$_p"
  done
}

_load_grep() {
  local pkgs
  pkgs=$(_load_packages)
  local _grep pat esc_pkg
  for pkg in $pkgs; do
    pat=""
    esc_pkg=$(printf '%s' "$pkg" | sed 's/\./\\./g')
    if [ "$pkg" = "$GMS_PKG" ]; then
      pat="<(allow-in-power-save|allow-in-data-usage-save)[^>]*\"$esc_pkg\"[^>]*/>"
    fi
    pat="${pat:+$pat|}<wl[^>]*>[[:space:]]*${esc_pkg}[[:space:]]*</wl>"
    _grep="${_grep:+$_grep|}$pat"
  done
  echo "$_grep"
}

_get_user_ids() {
  local _ids
  _ids=$(pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+')
  [ -z "$_ids" ] && _ids=$(ls /data/user 2>/dev/null)
  [ -z "$_ids" ] && _ids="0"
  echo "$_ids"
}

_migrate_stale_lists() {
  for _stale in "$MODDIR/config/gms_overlays.txt" "$MODDIR/config/cad_overlays.txt"; do
    [ -f "$_stale" ] || continue
    while IFS= read -r _f || [ -n "$_f" ]; do
      case "$_f" in '#'*|'') continue ;; esac
      rm -f "$_f"
    done < "$_stale"
    rm -f "$_stale"
  done
}

_remove_overlays() {
  if [ -f "$OVERLAYS_FILE" ]; then
    while IFS= read -r _f || [ -n "$_f" ]; do
      case "$_f" in '#'*|'') continue ;; esac
      rm -f "$_f" "${_f}.tmp"
    done < "$OVERLAYS_FILE"
    rm -f "$OVERLAYS_FILE"
  fi
  for _root in system product vendor odm system_ext \
               my_product my_heytap my_region my_bigball my_carrier \
               my_company my_engineering my_manifest my_preload \
               my_reserve my_stock india; do
    [ -d "$MODDIR/$_root" ] && find "$MODDIR/$_root" -type d -empty -delete >/dev/null 2>&1
  done
}

_unit_matches() {
  local _text="$1" _grep="$2"
  [ -n "$_text" ] && [ -n "$_grep" ] || return 1
  printf '%s' "$_text" | grep -qE "$_grep" && return 0
  return 1
}

_xml_has_any_pkg() {
  local _xml="$1" _grep="$2"
  [ -n "$_xml" ] && [ -n "$_grep" ] || return 1
  tr -d '\r' < "$_xml" | tr '\n' ' ' | grep -qE "$_grep" && return 0
  return 1
}

_build_strip_ranges() {
  local _src="$1" _grep="$2" _line _buf="" _start=0 _lineno=0 _tagcount
  while IFS= read -r _line || [ -n "$_line" ]; do
    _lineno=$((_lineno + 1))
    if printf '%s\n' "$_line" | grep -qE '^[[:space:]]*</?[a-z][a-zA-Z0-9_]*'; then
      if [ -n "$_buf" ] && _unit_matches "$_buf" "$_grep"; then
        _tagcount=$(printf '%s' "$_buf" | grep -oE '<[a-zA-Z]' | wc -l)
        if [ "$_tagcount" -gt 1 ]; then
          log_app "[WARN] Skipped removal (multiple tags on one line): $_src:$_start"
        elif [ "$_start" -eq $((_lineno - 1)) ]; then
          echo "${_start}d"
        else
          echo "${_start},$((_lineno - 1))d"
        fi
      fi
      _buf="$_line"
      _start=$_lineno
    else
      _buf="$_buf $_line"
    fi
  done < "$_src"
  if [ -n "$_buf" ] && _unit_matches "$_buf" "$_grep"; then
    _tagcount=$(printf '%s' "$_buf" | grep -oE '<[a-zA-Z]' | wc -l)
    if [ "$_tagcount" -gt 1 ]; then
      log_app "[WARN] Skipped removal (multiple tags on one line): $_src:$_start"
    elif [ "$_start" -eq "$_lineno" ]; then
      echo "${_start}d"
    else
      echo "${_start},${_lineno}d"
    fi
  fi
}

_overlays_stale() {
  local _build
  _build=$(getprop ro.build.fingerprint 2>/dev/null)
  [ -n "$_build" ] || return 1
  mkdir -p "$(dirname "$BUILD_STAMP")"
  if [ ! -f "$BUILD_STAMP" ]; then
    printf '%s\n' "$_build" > "$BUILD_STAMP"
    return 1
  fi
  [ "$(cat "$BUILD_STAMP" 2>/dev/null)" = "$_build" ] && return 1
  printf '%s\n' "$_build" > "$BUILD_STAMP"
  return 0
}

_backup_original() {
  local _real="$1" _rel="$2"
  local _backup_file="$BACKUP_DIR/$_rel"
  [ -f "$_backup_file" ] && return 0
  mkdir -p "$(dirname "$_backup_file")"
  cp -af "$_real" "$_backup_file" 2>/dev/null
}

_apply_xml_overlays() {
  _migrate_stale_lists

  local grep_pat
  grep_pat=$(_load_grep)

  local _reboot_file="$MODDIR/tmp/cad_needs_reboot"
  rm -f "$_reboot_file"

  if [ "$ENABLE_CUSTOM_APP_DOZE" != "1" ] || [ -z "$grep_pat" ]; then
    _remove_overlays
    return 0
  fi

  if _overlays_stale; then
    log_app "[INFO] System build changed - dropping overlays built from the old build"
    _remove_overlays
    rm -rf "$BACKUP_DIR"
    : > "$_reboot_file"
    return 0
  fi

  if [ -f "$XML_OFF_FILE" ]; then
    log_app "[WARN] XML overlays are off after repeated unfinished boots, toggle App Doze to retry"
    _remove_overlays
    return 0
  fi
  local count=0 scanned=0 _seen=""
  local _keep_tmp="$MODDIR/tmp/cad_keep_$$"
  mkdir -p "$MODDIR/tmp"
  : > "$_keep_tmp"

  for _base in $_PARTITION_ROOTS; do
    [ -d "$_base" ] || continue
    for _dir in "$_base/etc" "$_base/oplus" "$_base/oppo"; do
      [ -d "$_dir" ] || continue
      for _xml in $(find "$_dir" -maxdepth 2 -type f -name "*.xml" 2>/dev/null); do
        local _real
        _real=$(readlink -f "$_xml" 2>/dev/null); [ -z "$_real" ] && _real="$_xml"
        case "$_seen" in *"|$_real|"*) continue ;; esac
        _seen="${_seen}|$_real|"
        scanned=$((scanned + 1))

        local _rel="${_real#/}"
        case "$_rel" in
          system/product/*)    _rel="product/${_rel#system/product/}" ;;
          system/system_ext/*) _rel="system_ext/${_rel#system/system_ext/}" ;;
          system/vendor/*)     _rel="vendor/${_rel#system/vendor/}" ;;
          system/odm/*)        _rel="odm/${_rel#system/odm/}" ;;
        esac
        case "$_rel" in
          system/*|product/*|vendor/*|odm/*|system_ext/*) ;;
          my_product/*|my_heytap/*|my_region/*|my_bigball/*|my_carrier/*|\
          my_company/*|my_engineering/*|my_manifest/*|my_preload/*|\
          my_reserve/*|my_stock/*|india/*) ;;
          *) _rel="system/$_rel" ;;
        esac

        if [ ! -f "$SESSION_FILE" ] && [ -f "$BACKUP_DIR/$_rel" ] \
       && ! cmp -s "$_real" "$BACKUP_DIR/$_rel" \
       && ! { [ -f "$MODDIR/$_rel" ] && cmp -s "$_real" "$MODDIR/$_rel"; }; then
      log_app "[INFO] System file changed since it was backed up, refreshing: $_rel"
      rm -f "$BACKUP_DIR/$_rel" "$BACKUP_DIR/$_rel.sum" "$MODDIR/$_rel"
    fi
    local _src_file="$_real"
        [ -f "$BACKUP_DIR/$_rel" ] && _src_file="$BACKUP_DIR/$_rel"

        _xml_has_any_pkg "$_src_file" "$grep_pat" || continue

        _backup_original "$_real" "$_rel"
        [ -f "$BACKUP_DIR/$_rel" ] && _src_file="$BACKUP_DIR/$_rel"

        local _dest="$MODDIR/$_rel"
        mkdir -p "$(dirname "$_dest")"
        local _tmp="${_dest}.tmp"
        local _ranges
        _ranges=$(_build_strip_ranges "$_src_file" "$grep_pat")
        if [ -n "$_ranges" ]; then
          sed "$(printf '%s' "$_ranges" | tr '\n' ';')" "$_src_file" > "$_tmp" 2>/dev/null
        else
          cp -af "$_src_file" "$_tmp" 2>/dev/null
        fi
        if _valid_overlay "$_src_file" "$_tmp" "$_ranges"; then
          if [ ! -f "$_dest" ] || ! cmp -s "$_tmp" "$_dest"; then
            mv -f "$_tmp" "$_dest"
            count=$((count + 1))
          else
            rm -f "$_tmp"
          fi
          cksum < "$_dest" > "$BACKUP_DIR/$_rel.sum" 2>/dev/null
      printf '%s\n' "$_dest" >> "$_keep_tmp"
        else
          rm -f "$_tmp"
          log_app "[WARN] Skipped overlay - failed XML validation: $(basename "$_dest")"
        fi
      done
    done
  done

  if [ -f "$OVERLAYS_FILE" ]; then
    while IFS= read -r _old || [ -n "$_old" ]; do
      case "$_old" in ''|'#'*) continue ;; esac
      grep -qxF "$_old" "$_keep_tmp" || rm -f "$_old" "${_old}.tmp"
    done < "$OVERLAYS_FILE"
  fi
  mv -f "$_keep_tmp" "$OVERLAYS_FILE"
  for _root in system product vendor odm system_ext \
               my_product my_heytap my_region my_bigball my_carrier \
               my_company my_engineering my_manifest my_preload \
               my_reserve my_stock india; do
    [ -d "$MODDIR/$_root" ] && find "$MODDIR/$_root" -type d -empty -delete >/dev/null 2>&1
  done

  : > "$SESSION_FILE"
  if [ "$count" -gt 0 ]; then
    mkdir -p "$(dirname "$_reboot_file")"
    : > "$_reboot_file" 2>/dev/null
  fi
}

scan() {
  local _tmp_inst="$MODDIR/tmp/scan_inst.tmp"
  local _tmp_cand="$MODDIR/tmp/scan_cand.tmp"
  local _tmp_xmls="$MODDIR/tmp/scan_xmls.tmp"
  local _tmp_hits="$MODDIR/tmp/scan_hits.tmp"

  trap "rm -f '$_tmp_inst' '$_tmp_cand' '$_tmp_xmls' '$_tmp_hits'" EXIT
  trap 'exit 1' TERM INT HUP

  pm list packages 2>/dev/null | cut -d: -f2 | sort > "$_tmp_inst"
  if [ ! -s "$_tmp_inst" ]; then
    rm -f "$_tmp_inst" "$_tmp_cand" "$_tmp_xmls" "$_tmp_hits"
    return
  fi

  {
    for _base in $_PARTITION_ROOTS; do
      [ -d "$_base" ] || continue
      for _dir in "$_base/etc" "$_base/oplus" "$_base/oppo"; do
        [ -d "$_dir" ] || continue
        find "$_dir" -maxdepth 2 -type f -name "*.xml" 2>/dev/null
      done
    done
    [ -d /apex ] && find /apex -maxdepth 5 -type f -name "*.xml" \
      \( -path "*/etc/sysconfig/*" -o -path "*/etc/permissions/*" \) 2>/dev/null
  } | xargs readlink -f 2>/dev/null | sort -u > "$_tmp_xmls"

  {
    dumpsys deviceidle 2>/dev/null \
      | grep -E '^    [a-z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$' \
      | tr -d ' '

    cmd appops query-op IGNORE_BATTERY_OPTIMIZATIONS allow 2>/dev/null \
      | grep -oE '[a-z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+'

    if [ -s "$_tmp_xmls" ]; then
      xargs grep -lE 'allow-in-power-save|<wl[^/]' < "$_tmp_xmls" 2>/dev/null > "$_tmp_hits"
      if [ -s "$_tmp_hits" ]; then
        xargs grep -oE 'package="[^"]*"|>[[:space:]]*[a-z][a-zA-Z0-9_.]+\.[a-zA-Z0-9_.]+[[:space:]]*<' < "$_tmp_hits" 2>/dev/null \
          | grep -oE '[a-z][a-zA-Z0-9_.]+\.[a-zA-Z0-9_.]+'
      fi
    fi
  } | sort -u > "$_tmp_cand"

  grep -xFf "$_tmp_inst" "$_tmp_cand" 2>/dev/null
  rm -f "$_tmp_inst" "$_tmp_cand" "$_tmp_xmls" "$_tmp_hits"
}

_snapshot_wl() {
  local _pkg="$1" _t _dump
  touch "$WL_ORIG_FILE"
  _dump=$(dumpsys deviceidle whitelist 2>/dev/null)
  for _t in user system-excidle; do
    printf '%s\n' "$_dump" | awk -F, -v t="$_t" -v p="$_pkg" '$1==t && $2==p {f=1} END {exit !f}' || continue
    grep -qFx "$_t $_pkg" "$WL_ORIG_FILE" || echo "$_t $_pkg" >> "$WL_ORIG_FILE"
  done
}

_was_in_wl() {
  [ ! -f "$WL_ORIG_FILE" ] || grep -qFx "$1 $2" "$WL_ORIG_FILE"
}

_apply_pkg() {
  local pkg="$1"
  _is_blocked "$pkg" && return 0

  _snapshot_wl "$pkg"
  local tiers=""

  dumpsys deviceidle whitelist -"$pkg" >/dev/null 2>&1
  tiers="${tiers} user-wl"

  local sys_out
  sys_out=$(cmd deviceidle sys-whitelist -"$pkg" 2>&1)
  case "$sys_out" in *[Uu]nknown*|*[Ee]rror*) ;; *) tiers="${tiers} sys-wl" ;; esac

  cmd deviceidle except-idle-whitelist -"$pkg" >/dev/null 2>&1
  tiers="${tiers} except-idle-wl"

  cmd appops set "$pkg" IGNORE_BATTERY_OPTIMIZATIONS ignore 2>/dev/null && \
    tiers="${tiers} appops"

  local admin_count=0
  for _uid in $(_get_user_ids); do
    cmd jobscheduler cancel --user "$_uid" "$pkg" >/dev/null 2>&1
    am set-inactive --user "$_uid" "$pkg" true 2>/dev/null

    if [ "$pkg" = "$GMS_PKG" ]; then
      for _admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
        pm disable --user "$_uid" "$_admin" >/dev/null 2>&1 && \
          admin_count=$((admin_count + 1))
      done
    fi
  done
  tiers="${tiers} jobs inactive"
  [ "$admin_count" -gt 0 ] && tiers="${tiers} gms-admin"
  [ "$pkg" = "$GMS_PKG" ] && { am start-service -n "$GMS_PKG/.checkin.CheckinService" >/dev/null 2>&1 || true; }

  log_app "[OK] $pkg - applied to:$tiers"
}

apply() {
  echo "Frosty v${MODVER:-?} - App Doze (APPLY) - $(date '+%Y-%m-%d %H:%M:%S')" > "$APP_DOZE_LOG"
  [ "$ENABLE_CUSTOM_APP_DOZE" != "1" ] && { log_app "[SKIP] App Doze disabled"; return 0; }

  local pkgs
  _refresh_installed
  _note_missing
  pkgs=$(_load_packages)
  if [ -z "$pkgs" ]; then
    log_app "[INFO] No packages configured"
    return 0
  fi

  log_app "Configured packages:"
  for pkg in $pkgs; do log_app "  $pkg"; done
  log_app ""

  log_app "Updating XML overlays..."
  _apply_xml_overlays
  log_app "[OK] XML overlay step complete"
  log_app ""

  local count=0 skip=0
  for pkg in $pkgs; do
    if _is_blocked "$pkg"; then
      log_app "[SKIP] $pkg - blocked package"
      skip=$((skip + 1))
      continue
    fi
    _apply_pkg "$pkg"
    count=$((count + 1))
  done

  log_app ""
  log_app "Summary: $count optimized, $skip skipped"
}

_restore_pkg() {
  local pkg="$1"
  _is_blocked "$pkg" && return 0

  _was_in_wl user "$pkg" && dumpsys deviceidle whitelist +"$pkg" >/dev/null 2>&1
  cmd deviceidle sys-whitelist +"$pkg" >/dev/null 2>&1
  _was_in_wl system-excidle "$pkg" && cmd deviceidle except-idle-whitelist +"$pkg" >/dev/null 2>&1
  cmd appops set "$pkg" IGNORE_BATTERY_OPTIMIZATIONS default >/dev/null 2>&1
  [ -f "$WL_ORIG_FILE" ] && sed -i "/^[a-z-]* $(printf '%s' "$pkg" | sed 's/\./\\./g')$/d" "$WL_ORIG_FILE"

  for _uid in $(_get_user_ids); do
    am set-inactive --user "$_uid" "$pkg" false 2>/dev/null

    if [ "$pkg" = "$GMS_PKG" ]; then
      for _admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
        [ "$_admin" = "$GMS_ADMIN2" ] && [ "${DISABLE_BACKGROUND:-0}" = "1" ] && continue
        pm enable --user "$_uid" "$_admin" >/dev/null 2>&1
      done
    fi
  done
}

revert() {
  rm -f "$XML_OFF_FILE" "$MODDIR/tmp/cad_boot_fail" "$SESSION_FILE"
  echo "Frosty v${MODVER:-?} - App Doze (REVERT) - $(date '+%Y-%m-%d %H:%M:%S')" > "$APP_DOZE_LOG"

  log_app "Removing XML overlays..."
  _remove_overlays
  log_app "[OK] XML overlay step complete"

  local pkgs
  _refresh_installed
  pkgs=$(_load_packages)
  if [ -z "$pkgs" ]; then
    log_app "[INFO] No packages configured"
    return 0
  fi

  local count=0
  for pkg in $pkgs; do
    _is_blocked "$pkg" && continue
    _restore_pkg "$pkg"
    log_app "[OK] Restored: $pkg"
    count=$((count + 1))
  done

  log_app ""
  log_app "Summary: $count packages restored - reboot for XML overlay removal"
}

list_pkgs() {
  [ -f "$PATCHES_FILE" ] || { echo '{"status":"ok","packages":[]}'; return; }
  local pkgs out="" first=1
  pkgs=$(sed 's/#.*//;s/[[:space:]]//g' "$PATCHES_FILE" | grep -v '^$')
  while IFS= read -r p || [ -n "$p" ]; do
    [ -z "$p" ] && continue
    _valid_pkg "$p" || continue
    [ "$first" = "1" ] && first=0 || out="${out},"
    out="${out}\"${p}\""
  done <<EOF
$pkgs
EOF
  printf '{"status":"ok","packages":[%s]}\n' "$out"
}

add_pkg() {
  local pkg="$1"
  _valid_pkg "$pkg" || { echo '{"status":"error"}'; return; }
  mkdir -p "$MODDIR/config"
  if [ ! -f "$PATCHES_FILE" ]; then
    { echo "# Frosty - App Doze"
      echo "# Apps listed here are removed from the Doze power-save whitelist."
      echo "# Add package names one per line. Lines starting with # are comments."
      echo ""
    } > "$PATCHES_FILE"
  fi
  grep -qFx "$pkg" "$PATCHES_FILE" 2>/dev/null || echo "$pkg" >> "$PATCHES_FILE"
  if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ]; then
    _apply_pkg "$pkg"
    log_app "[OK] Added to list and applied: $pkg"
  fi
  echo '{"status":"ok"}'
}

remove_pkg() {
  local pkg="$1"
  _valid_pkg "$pkg" || { echo '{"status":"error"}'; return; }
  [ -f "$PATCHES_FILE" ] || { echo '{"status":"ok"}'; return; }

  if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ]; then
    _restore_pkg "$pkg"
    log_app "[OK] Removed from list and restored: $pkg"
  else
    log_app "[OK] Removed from list: $pkg"
  fi

  local escaped
  escaped=$(printf '%s' "$pkg" | sed 's/[][\.*^$\/]/\\&/g')
  sed -i "/^${escaped}$/d" "$PATCHES_FILE"
  echo '{"status":"ok"}'
}

case "$1" in
  apply)   apply ;;
  revert)  revert ;;
  scan)    scan ;;
  list)    list_pkgs ;;
  add)     add_pkg "$2" ;;
  remove)  remove_pkg "$2" ;;
  *) echo "Usage: $0 {apply|revert|scan|list|add|remove}"; exit 1 ;;
esac
exit $?
