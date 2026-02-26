#!/system/bin/sh
# 🧊 FROSTY - Post-FS-Data

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
  STR1='allow-in-power-save package="com.google.android.gms"'
  STR2='allow-in-data-usage-save package="com.google.android.gms"'
  STR3='allow-unthrottled-location package="com.google.android.gms"'
  STR4='allow-ignore-location-settings package="com.google.android.gms"'

  find /data/adb/modules -type f -name "*.xml" 2>/dev/null | while IFS= read -r xml; do
    case "$xml" in "$MODDIR"*) continue ;; esac
    if grep -qF "$STR1" "$xml" 2>/dev/null || grep -qF "$STR2" "$xml" 2>/dev/null || \
       grep -qF "$STR3" "$xml" 2>/dev/null || grep -qF "$STR4" "$xml" 2>/dev/null; then
      grep -vF "$STR1" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      grep -vF "$STR2" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      grep -vF "$STR3" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
      grep -vF "$STR4" "$xml" > "$xml.tmp" && mv "$xml.tmp" "$xml"
    fi
  done
fi

# RC overlays and bin stubs for log killing
INITDIR="$MODDIR/system/etc/init"
BINDIR="$MODDIR/system/bin"

if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  mkdir -p "$INITDIR"
  for rc in atrace atrace_userdebug bugreport debuggerd debuggerd64 dmesgd \
            dumpstate logcat logcatd logd logtagd lpdumpd tombstoned \
            traced_perf traced_probes traceur; do
    [ ! -f "$INITDIR/${rc}.rc" ] && : > "$INITDIR/${rc}.rc"
  done

  mkdir -p "$BINDIR"
  for bin in atrace bugreport bugreport_procdump bugreportz crash_dump32 \
            crash_dump64 debuggerd diag_socket_log dmabuf_dump dmesg dmesgd \
            dumpstate i2cdump log logcat logcatd logd logger logname \
            logpersist.cat logpersist.start logpersist.stop logwrapper \
            lpdump lpdumpd notify_traceur.sh tcpdump tombstoned traced \
            traced_perf traced_probes tracepath tracepath6 traceroute6; do
    if [ ! -f "$BINDIR/$bin" ]; then
      : > "$BINDIR/$bin"
      chmod 755 "$BINDIR/$bin"
    fi
  done
else
  if [ -d "$INITDIR" ]; then
    rm -f "$INITDIR"/*.rc
    rmdir "$INITDIR" 2>/dev/null
  fi
  if [ -d "$BINDIR" ]; then
    rm -f "$BINDIR"/*
    rmdir "$BINDIR" 2>/dev/null
  fi
  rmdir "$MODDIR/system/etc" 2>/dev/null
  [ -d "$MODDIR/system" ] && [ -z "$(ls -A "$MODDIR/system" 2>/dev/null)" ] && rmdir "$MODDIR/system" 2>/dev/null
fi
