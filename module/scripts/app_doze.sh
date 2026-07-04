#!/system/bin/sh
# Frosty - App Doze 

_d="${0%/*}"
[ -z "$_d" ] && _d="/data/adb/modules/Frosty/scripts"
MODDIR="${_d%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"
unset _d
MODVER=$(grep "^version=" "$MODDIR/module.prop" 2>/dev/null | cut -d= -f2)

LOGDIR="$MODDIR/logs"
APP_DOZE_LOG="$LOGDIR/app_doze.log"
USER_PREFS="$MODDIR/config/user_prefs"
PATCHES_FILE="$MODDIR/config/doze_patches.txt"
OVERLAYS_FILE="$MODDIR/config/doze_xml_overlays.txt"

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

mkdir -p "$LOGDIR"
log_app() { echo "[$(date '+%H:%M:%S')] $1" >> "$APP_DOZE_LOG"; }

_is_blocked() {
  local pkg="$1"
  for b in $_BLOCKED; do [ "$pkg" = "$b" ] && return 0; done
  return 1
}

_load_packages() {
  [ ! -f "$PATCHES_FILE" ] && return
  sed 's/###.*//;s/#.*//;s/[[:space:]]//g' "$PATCHES_FILE" | grep -v '^$' | sort
}

_get_user_ids() {
  pm list users 2>/dev/null | grep -oE 'UserInfo\{[0-9]+' | grep -oE '[0-9]+' || ls /data/user 2>/dev/null
}

_migrate_stale_lists() {
  for _stale in "$MODDIR/config/gms_overlays.txt" "$MODDIR/config/cad_overlays.txt"; do
    [ -f "$_stale" ] || continue
    while IFS= read -r _f; do
      case "$_f" in '#'*|'') continue ;; esac
      [ -f "$_f" ] && rm -f "$_f"
    done < "$_stale"
    rm -f "$_stale"
  done
}

_remove_overlays() {
  if [ -f "$OVERLAYS_FILE" ]; then
    while IFS= read -r _f; do
      case "$_f" in '#'*|'') continue ;; esac
      [ -f "$_f" ] && rm -f "$_f"
      rm -f "${_f}.tmp" 2>/dev/null
    done < "$OVERLAYS_FILE"
    rm -f "$OVERLAYS_FILE"
  fi
  for _root in system product vendor odm system_ext \
               my_product my_heytap my_region my_bigball my_carrier \
               my_company my_engineering my_manifest my_preload \
               my_reserve my_stock india; do
    [ -d "$MODDIR/$_root" ] && find "$MODDIR/$_root" -type d -empty -delete 2>/dev/null
  done
}

_xml_has_any_pkg() {
  local _xml="$1" _pkg _e
  while IFS= read -r _pkg; do
    case "$_pkg" in '#'*|'') continue ;; esac
    _e=$(printf '%s' "$_pkg" | sed 's/\./\\./g')
    if [ "$_pkg" = "$GMS_PKG" ]; then
      grep -qE "allow-in-power-save[^>]*${_e}|allow-in-data-usage-save[^>]*${_e}|<wl[^>]*>[[:space:]]*${_e}[[:space:]]*</wl>" \
        "$_xml" 2>/dev/null && return 0
    else
      grep -qE "<wl[^>]*>[[:space:]]*${_e}[[:space:]]*</wl>" \
        "$_xml" 2>/dev/null && return 0
    fi
  done < "$PATCHES_FILE"
  return 1
}

_apply_xml_overlays() {
  _migrate_stale_lists

  local pkgs sed_pat="" any=0
  pkgs=$(_load_packages)

  if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ] && [ -n "$pkgs" ]; then
    for _pkg in $pkgs; do
      [ -z "$_pkg" ] && continue
      local _e
      _e=$(echo "$_pkg" | sed 's/\./\\./g')
      if [ "$_pkg" = "$GMS_PKG" ]; then
          sed_pat="${sed_pat}/allow-in-power-save[^>]*${_e}[^>]*>/d;/allow-in-data-usage-save[^>]*${_e}[^>]*>/d;/<wl[^>]*>[[:space:]]*${_e}[[:space:]]*<\/wl>/d;"
      else
          sed_pat="${sed_pat}/<wl[^>]*>[[:space:]]*${_e}[[:space:]]*<\/wl>/d;"
      fi
      any=1
    done
  fi

  _reboot_file="$MODDIR/tmp/cad_needs_reboot"

  rm -f "$_reboot_file" 2>/dev/null

  if [ "$any" -eq 0 ]; then
    _remove_overlays
    return 0
  fi

  local count=0 scanned=0 _seen="" _cleared=false
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
        _xml_has_any_pkg "$_real" || continue

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

        if [ "$_cleared" != "true" ]; then
          [ -f "$OVERLAYS_FILE" ] && log_app "[INFO] Found unpatched XML(s) - removing existing overlays"
          _remove_overlays
          _cleared=true
        fi

        local _dest="$MODDIR/$_rel"
        mkdir -p "$(dirname "$_dest")"
        local _tmp="${_dest}.tmp"
        if cp -af "$_real" "$_tmp" 2>/dev/null; then
          sed -i "$sed_pat" "$_tmp"
          if [ -s "$_tmp" ] && grep -q '</' "$_tmp" 2>/dev/null; then
            mv -f "$_tmp" "$_dest"
            echo "$_dest" >> "$OVERLAYS_FILE"
            count=$((count + 1))
          else
            rm -f "$_tmp"
            log_app "[WARN] Skipped overlay - failed XML validation: $(basename "$_dest")"
          fi
        fi
      done
    done
  done

  if [ "$count" -gt 0 ]; then
    mkdir -p "$(dirname "$_reboot_file")"
    touch "$_reboot_file" 2>/dev/null
  fi
}

scan() {
  local _tmp_inst="$MODDIR/tmp/scan_inst.tmp"
  local _tmp_cand="$MODDIR/tmp/scan_cand.tmp"

  pm list packages 2>/dev/null | cut -d: -f2 | sort > "$_tmp_inst"
  if [ ! -s "$_tmp_inst" ]; then
    rm -f "$_tmp_inst" "$_tmp_cand"
    return
  fi

  {
    dumpsys deviceidle 2>/dev/null \
      | grep -E '^    [a-z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$' \
      | tr -d ' '

    cmd appops query-op IGNORE_BATTERY_OPTIMIZATIONS allow 2>/dev/null \
      | grep -oE '[a-z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+'

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
    } | xargs readlink -f 2>/dev/null | sort -u \
      | xargs grep -lE 'allow-in-power-save|<wl[^/]' 2>/dev/null \
      | xargs grep -oE 'package="[^"]*"|>[[:space:]]*[a-z][a-zA-Z0-9_.]+\.[a-zA-Z0-9_.]+[[:space:]]*<' 2>/dev/null \
      | grep -oE '[a-z][a-zA-Z0-9_.]+\.[a-zA-Z0-9_.]+'

  } | sort -u > "$_tmp_cand"

  grep -xFf "$_tmp_inst" "$_tmp_cand"
  rm -f "$_tmp_inst" "$_tmp_cand"
}

apply() {
  echo "Frosty v${MODVER:-?} - App Doze (APPLY) - $(date '+%Y-%m-%d %H:%M:%S')" > "$APP_DOZE_LOG"
  mkdir -p "$MODDIR/tmp"
  [ "$ENABLE_CUSTOM_APP_DOZE" != "1" ] && { log_app "[SKIP] App Doze disabled"; return 0; }

  local pkgs
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

    local tiers=""

    dumpsys deviceidle whitelist -"$pkg" >/dev/null 2>&1
    tiers="${tiers} user-wl"

    local sys_out
    sys_out=$(cmd deviceidle sys-whitelist -"$pkg" 2>&1)
    case "$sys_out" in *[Uu]nknown*|*[Ee]rror*) ;; *) tiers="${tiers} sys-wl" ;; esac

    cmd deviceidle except-idle-whitelist -"$pkg" >/dev/null 2>&1
    tiers="${tiers} except-idle-wl"

    if [ -f /data/system/deviceidle.xml ] && \
       grep -q "<wl n=\"$pkg\"" /data/system/deviceidle.xml 2>/dev/null; then
      sed -i "/<wl n=\"$pkg\"/d" /data/system/deviceidle.xml
      restorecon /data/system/deviceidle.xml 2>/dev/null
      tiers="${tiers} xml-wl"
    fi

    cmd appops set "$pkg" IGNORE_BATTERY_OPTIMIZATIONS ignore 2>/dev/null && \
      tiers="${tiers} appops"

    if [ "$pkg" = "$GMS_PKG" ]; then
      local admin_count=0
      for _uid in $(_get_user_ids); do
        for _admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
          pm disable --user "$_uid" "$_admin" >/dev/null 2>&1 && \
            admin_count=$((admin_count + 1))
        done
      done
      [ "$admin_count" -gt 0 ] && tiers="${tiers} gms-admin"
      am start-service -n "$GMS_PKG/.checkin.CheckinService" >/dev/null 2>&1 || true
    fi

    log_app "[OK] $pkg - applied to:$tiers"
    count=$((count + 1))
  done

  log_app ""
  log_app "Summary: $count optimized, $skip skipped"
}

revert() {
  echo "Frosty v${MODVER:-?} - App Doze (REVERT) - $(date '+%Y-%m-%d %H:%M:%S')" > "$APP_DOZE_LOG"

  log_app "Removing XML overlays..."
  _remove_overlays
  log_app "[OK] XML overlay step complete"

  local pkgs
  pkgs=$(_load_packages)
  if [ -z "$pkgs" ]; then
    log_app "[INFO] No packages configured"
    return 0
  fi

  local count=0
  for pkg in $pkgs; do
    _is_blocked "$pkg" && continue
    dumpsys deviceidle whitelist +"$pkg" >/dev/null 2>&1
    cmd deviceidle sys-whitelist +"$pkg" >/dev/null 2>&1
    cmd deviceidle except-idle-whitelist +"$pkg" >/dev/null 2>&1
    cmd appops set "$pkg" IGNORE_BATTERY_OPTIMIZATIONS default 2>/dev/null

    if [ "$pkg" = "$GMS_PKG" ]; then
      for _uid in $(_get_user_ids); do
        for _admin in "$GMS_ADMIN1" "$GMS_ADMIN2"; do
          pm enable --user "$_uid" "$_admin" >/dev/null 2>&1
        done
      done
    fi

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
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    [ "$first" = "1" ] && first=0 || out="${out},"
    out="${out}\"${p}\""
  done <<EOF
$pkgs
EOF
  printf '{"status":"ok","packages":[%s]}\n' "$out"
}

add_pkg() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  mkdir -p "$MODDIR/config"
  if [ ! -f "$PATCHES_FILE" ]; then
    { echo "# Frosty - App Doze"
      echo "# Apps listed here are removed from the Doze power-save whitelist."
      echo "# Add package names one per line. Lines starting with # are comments."
      echo ""
    } > "$PATCHES_FILE"
  fi
  grep -qFx "$pkg" "$PATCHES_FILE" 2>/dev/null || echo "$pkg" >> "$PATCHES_FILE"
  echo '{"status":"ok"}'
}

remove_pkg() {
  local pkg="$1"
  [ -z "$pkg" ] && { echo '{"status":"error"}'; return; }
  [ -f "$PATCHES_FILE" ] || { echo '{"status":"ok"}'; return; }
  local escaped
  escaped=$(printf '%s' "$pkg" | sed 's/\./\\./g')
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
exit 0