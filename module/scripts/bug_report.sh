REPORT_DIR="/storage/emulated/0/Frosty/Logs"

_root_type() {
  if [ -d /data/adb/magisk ] && command -v magisk >/dev/null 2>&1; then
    echo "Magisk"
  elif [ -n "$(getprop ro.kernelsu.version 2>/dev/null)" ] || [ -d /data/adb/ksu ] || command -v ksud >/dev/null 2>&1; then
    echo "KernelSU"
  elif [ -d /data/adb/ap ]; then
    echo "APatch"
  else
    echo "unknown"
  fi
}

_rom_info() {
  local _v
  _v=$(getprop ro.miui.ui.version.name 2>/dev/null)
  if [ -n "$_v" ]; then echo "MIUI/HyperOS $_v"; return; fi
  _v=$(getprop ro.lineage.version 2>/dev/null)
  if [ -n "$_v" ]; then echo "LineageOS $_v"; return; fi
  _v=$(getprop ro.build.version.oplusrom 2>/dev/null)
  [ -z "$_v" ] && _v=$(getprop ro.oplus.version 2>/dev/null)
  if [ -n "$_v" ]; then echo "ColorOS/OxygenOS $_v"; return; fi
  _v=$(getprop ro.build.version.oneui 2>/dev/null)
  if [ -n "$_v" ]; then echo "One UI $_v"; return; fi
  _v=$(getprop ro.pixelexperience.version 2>/dev/null)
  if [ -n "$_v" ]; then echo "Pixel Experience $_v"; return; fi
  echo "$(getprop ro.build.display.id 2>/dev/null) ($(getprop ro.build.tags 2>/dev/null))"
}

_battery_status() {
  case "$1" in
    1) echo "Unknown" ;;
    2) echo "Charging" ;;
    3) echo "Discharging" ;;
    4) echo "Not charging" ;;
    5) echo "Full" ;;
    *) echo "$1" ;;
  esac
}

_battery_health() {
  case "$1" in
    1) echo "Unknown" ;;
    2) echo "Good" ;;
    3) echo "Overheat" ;;
    4) echo "Dead" ;;
    5) echo "Over voltage" ;;
    6) echo "Failure" ;;
    7) echo "Cold" ;;
    *) echo "$1" ;;
  esac
}

_dump_list_or_none() {
  local _content
  _content=$(grep -v '^#\|^$' "$1" 2>/dev/null)
  if [ -n "$_content" ]; then
    printf '%s\n' "$_content"
  else
    echo "(none)"
  fi
}

generate_bug_report() {
  mkdir -p "$REPORT_DIR"
  local _ts _out
  _ts=$(date '+%Y%m%d_%H%M%S')
  _out="$REPORT_DIR/frosty_bugreport_$_ts.txt"

  {
    echo "Frosty Bug Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Module version: ${MODVER:-unknown}"
    echo "Root: $(_root_type)"
    echo ""
    echo ""

    echo "=== Device ==="
    echo "Model: $(getprop ro.product.model 2>/dev/null)"
    echo "Manufacturer: $(getprop ro.product.manufacturer 2>/dev/null)"
    echo "Android: $(getprop ro.build.version.release 2>/dev/null) (SDK $(getprop ro.build.version.sdk 2>/dev/null))"
    echo "ROM: $(_rom_info)"
    echo "Build: $(getprop ro.build.display.id 2>/dev/null)"
    echo "Fingerprint: $(getprop ro.build.fingerprint 2>/dev/null)"
    echo "ABI: $(getprop ro.product.cpu.abi 2>/dev/null)"
    echo "Kernel: $(uname -r 2>/dev/null)"
    echo "Total RAM: $(awk '/MemTotal/{printf "%.1f GB\n", $2/1048576}' /proc/meminfo 2>/dev/null)"
    echo ""
    echo ""

    echo "=== Installed root modules ==="
    local _found_module=0
    for _m in /data/adb/modules/*/; do
      [ -f "$_m/module.prop" ] || continue
      _found_module=1
      local _id _ver _vc _dis
      _id=$(grep '^id=' "$_m/module.prop" 2>/dev/null | cut -d= -f2)
      _ver=$(grep '^version=' "$_m/module.prop" 2>/dev/null | cut -d= -f2)
      _vc=$(grep '^versionCode=' "$_m/module.prop" 2>/dev/null | cut -d= -f2)
      _dis=""
      [ -f "$_m/disable" ] && _dis=" [disabled]"
      [ -f "$_m/remove" ] && _dis="$_dis [pending removal]"
      echo "$_id $_ver ($_vc)$_dis"
    done
    [ "$_found_module" = "0" ] && echo "(none found)"
    echo ""
    echo ""

    echo "=== Battery ==="
    local _bstatus _bhealth
    _bstatus=$(dumpsys battery 2>/dev/null | grep -m1 "status:" | grep -oE '[0-9]+')
    _bhealth=$(dumpsys battery 2>/dev/null | grep -m1 "health:" | grep -oE '[0-9]+')
    echo "Status: $(_battery_status "${_bstatus:-0}")"
    echo "Health: $(_battery_health "${_bhealth:-0}")"
    dumpsys battery 2>/dev/null | grep -E "level:|temperature:|technology:"
    echo ""
    echo ""

    echo "=== Frosty config ==="
    if [ -f "$MODDIR/config/user_prefs" ]; then
      cat "$MODDIR/config/user_prefs" 2>/dev/null
    else
      echo "(user_prefs not found)"
    fi
    echo ""
    echo ""

    echo "=== Doze whitelist (user-added apps) ==="
    _dump_list_or_none "$MODDIR/config/doze_whitelist.txt"
    echo ""
    echo ""

    echo "=== App Doze patch list ==="
    _dump_list_or_none "$MODDIR/config/doze_patches.txt"
    echo ""
    echo ""

    echo "=== RAM Clean whitelist ==="
    _dump_list_or_none "$MODDIR/config/ram_clean_whitelist.txt"
    echo ""
    echo ""

    echo "=== Frozen GMS services ==="
    if [ -s "$MODDIR/tmp/frozen_services.txt" ]; then
      cat "$MODDIR/tmp/frozen_services.txt" 2>/dev/null
    else
      echo "(none - GMS Freezing may not have been applied yet)"
    fi
    echo ""
    echo ""

    echo "=== Live system state ==="
    echo "device_idle_constants: $(settings get global device_idle_constants 2>/dev/null)"
    echo "battery_saver_constants: $(settings get global battery_saver_constants 2>/dev/null)"
    echo "low_power: $(settings get global low_power 2>/dev/null)"
    dumpsys deviceidle 2>/dev/null | grep -E "mState=|mLightState=" 2>/dev/null
    echo "ZRAM disksize: $(cat /sys/block/zram0/disksize 2>/dev/null)"
    echo "ZRAM comp_algorithm: $(cat /sys/block/zram0/comp_algorithm 2>/dev/null)"
    echo ""
    echo ""

    echo "=== Frosty logs ==="
    local _found_log=0
    for _f in $(find "$LOGDIR" -maxdepth 1 -name "*.log" -type f 2>/dev/null | sort); do
      [ -f "$_f" ] || continue
      _found_log=1
      echo "--- $(basename "$_f") ---"
      cat "$_f" 2>/dev/null
      echo ""
      echo ""
    done
    [ "$_found_log" = "0" ] && echo "(no logs found - features may not have been applied yet)"

  } > "$_out" 2>&1

  local _name
  _name=$(basename "$_out")
  echo "{\"status\":\"ok\",\"path\":\"$_out\",\"name\":\"$_name\"}"
}

list_bug_reports() {
  [ ! -d "$REPORT_DIR" ] && { echo "[]"; return; }
  local _files
  _files=$(ls -t "$REPORT_DIR"/frosty_bugreport_*.txt 2>/dev/null)
  [ -z "$_files" ] && { echo "[]"; return; }
  printf '['
  local _first=1 _f _name
  for _f in $_files; do
    [ "$_first" -eq 1 ] && _first=0 || printf ','
    _name=$(basename "$_f" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '{"name":"%s","path":"%s"}' "$_name" "$_f"
  done
  printf ']\n'
}
