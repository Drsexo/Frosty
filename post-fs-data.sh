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

# GMS Doze
if [ "$ENABLE_GMS_DOZE" = "1" ]; then
  GMS0="\"com.google.android.gms\""
  STR1="allow-in-power-save package=$GMS0"
  STR2="allow-in-data-usage-save package=$GMS0"
  STR3="allow-unthrottled-location package=$GMS0"
  STR4="allow-ignore-location-settings package=$GMS0"

  find /data/adb/modules -type f -name "*.xml" 2>/dev/null | while IFS= read -r xml; do
    case "$xml" in "$MODDIR"*) continue ;; esac
    if grep -qE "$STR1|$STR2|$STR3|$STR4" "$xml" 2>/dev/null; then
      sed -i "/$STR1/d;/$STR2/d;/$STR3/d;/$STR4/d" "$xml"
    fi
  done
fi