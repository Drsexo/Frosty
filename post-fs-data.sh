#!/system/bin/sh
# Frosty - Post-FS-Data

MODDIR="${0%/*}"
[ -f "$MODDIR/config/user_prefs" ] && . "$MODDIR/config/user_prefs"

# Resetprop tweaks
resetprop -n tombstoned.max_tombstone_count 0
resetprop -n ro.lmk.debug false
resetprop -n ro.lmk.log_stats false
resetprop -n dalvik.vm.dex2oat-minidebuginfo false
resetprop -n dalvik.vm.minidebuginfo false

if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then
  resetprop -n disableBlurs true
  resetprop -n enable_blurs_on_windows 0
  resetprop -n ro.launcher.blur.appLaunch 0
  resetprop -n ro.sf.blurs_are_expensive 0
  resetprop -n ro.surface_flinger.supports_background_blur 0
fi

# GMS Doze - patch conflicting modules on every boot
if [ "$ENABLE_GMS_DOZE" = "1" ]; then
  STR1='allow-in-power-save package="com.google.android.gms"'
  STR2='allow-in-data-usage-save package="com.google.android.gms"'
  STR3='allow-unthrottled-location package="com.google.android.gms"'
  STR4='allow-ignore-location-settings package="com.google.android.gms"'

  find /data/adb/modules -type f -name "*.xml" 2>/dev/null | while IFS= read -r xml; do
    case "$xml" in "$MODDIR"*) continue ;; esac
    if grep -qF "$STR1" "$xml" 2>/dev/null || grep -qF "$STR2" "$xml" 2>/dev/null || \
       grep -qF "$STR3" "$xml" 2>/dev/null || grep -qF "$STR4" "$xml" 2>/dev/null; then
      # Always remove power-save entries
      sed -i "/$STR1/d;/$STR2/d" "$xml"
      # Only remove location entries if user froze location
      if [ "$DISABLE_LOCATION" = "1" ]; then
        sed -i "/$STR3/d;/$STR4/d" "$xml"
      fi
    fi
  done
fi