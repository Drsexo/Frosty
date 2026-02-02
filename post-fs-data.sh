#!/system/bin/sh
# 🧊 FROSTY - Post-FS-Data Script
# Applies early boot tweaks via resetprop
# Patches conflicting module XMLs for GMS Doze

MODDIR="${0%/*}"

[ -f "$MODDIR/config/user_prefs" ] && . "$MODDIR/config/user_prefs"

# RESETPROP TWEAKS

# Tombstoned
resetprop -n tombstoned.max_tombstone_count 0

# Low Memory Killer Debug
resetprop -n ro.lmk.debug false
resetprop -n ro.lmk.log_stats false

# Dalvik Optimizations
resetprop -n dalvik.vm.check-dex-sum false
resetprop -n dalvik.vm.checkjni false
resetprop -n dalvik.vm.dex2oat-minidebuginfo false
resetprop -n dalvik.vm.minidebuginfo false
resetprop -n dalvik.vm.verify-bytecode false

# Blur Disable
if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then
  resetprop -n disableBlurs true
  resetprop -n enable_blurs_on_windows 0
  resetprop -n ro.launcher.blur.appLaunch 0
  resetprop -n ro.sf.blurs_are_expensive 0
  resetprop -n ro.surface_flinger.supports_background_blur 0
fi

# GMS DOZE - PATCH CONFLICTING MODULE XMLS
if [ "$ENABLE_GMS_DOZE" = "1" ]; then
  GMS_PKG="\"com.google.android.gms\""
  STR1="allow-in-power-save package=$GMS_PKG"
  STR2="allow-in-data-usage-save package=$GMS_PKG"
  STR3="allow-unthrottled-location package=$GMS_PKG"
  STR4="allow-ignore-location-settings package=$GMS_PKG"
  
  # Find and patch conflicting module XMLs
  find /data/adb/modules -type f -name "*.xml" 2>/dev/null | while IFS= read -r xml_file; do
    # Skip our own module
    case "$xml_file" in
      "$MODDIR"*) continue ;;
    esac
    
    if grep -qE "$STR1|$STR2|$STR3|$STR4" "$xml_file" 2>/dev/null; then
      sed -i "/$STR1/d;/$STR2/d;/$STR3/d;/$STR4/d" "$xml_file" 2>/dev/null
    fi
  done
fi