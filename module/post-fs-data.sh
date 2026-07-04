#!/system/bin/sh
# Frosty - Post-FS-Data

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

[ -f "$MODDIR/config/user_prefs" ] && . "$MODDIR/config/user_prefs"

_DIXML="/data/system/deviceidle.xml"

_OVERLAYS="$MODDIR/config/doze_xml_overlays.txt"
if [ -f "$_OVERLAYS" ]; then
  while IFS= read -r _src; do
    case "$_src" in '#'*|'') continue ;; esac
    [ -f "$_src" ] || continue
    [ -s "$_src" ] || continue
    grep -q '</' "$_src" 2>/dev/null || continue
    _dst="${_src#$MODDIR}"
    case "$_dst" in
      /product/*|/vendor/*|/odm/*|/system_ext/*|\
      /my_product/*|/my_heytap/*|/my_region/*|/my_bigball/*|/my_carrier/*|\
      /my_company/*|/my_engineering/*|/my_manifest/*|/my_preload/*|\
      /my_reserve/*|/my_stock/*|/india/*) ;;
      *) [ ! -f "$_dst" ] && _dst="${_dst#/system}" ;;
    esac
    [ ! -f "$_dst" ] && continue
    _ctx=$(stat -c %C "$_dst" 2>/dev/null)
    [ -n "$_ctx" ] && chcon "$_ctx" "$_src" 2>/dev/null
    mount --bind "$_src" "$_dst" 2>/dev/null
  done < "$_OVERLAYS"
fi
unset _OVERLAYS _src _dst _ctx

_CAD_PATCHES="$MODDIR/config/doze_patches.txt"

if [ -f "$_DIXML" ] && grep -q '<un-wl ' "$_DIXML" 2>/dev/null; then
  sed -i '/<un-wl /d' "$_DIXML"
  restorecon "$_DIXML" 2>/dev/null
fi

if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ] && [ -f "$_CAD_PATCHES" ] && [ -f "$_DIXML" ]; then
  _cad_pkgs=$(sed 's/###.*//;s/#.*//;s/[[:space:]]//g' "$_CAD_PATCHES" 2>/dev/null | grep -v '^$')
  if [ -n "$_cad_pkgs" ]; then
    _tmp="${_DIXML}.cad.tmp"
    cp -af "$_DIXML" "$_tmp" 2>/dev/null

    for _pkg in $_cad_pkgs; do
      _esc=$(printf '%s' "$_pkg" | sed 's/\./\\./g')
      sed -i "/<wl n=\"$_esc\"/d" "$_tmp" 2>/dev/null
    done
    unset _esc
    sed -i '/<\/config>/d' "$_tmp"

    {
      for _pkg in $_cad_pkgs; do
        echo "<un-wl n=\"$_pkg\" />"
      done
      echo "</config>"
    } >> "$_tmp"

    if grep -q '</config>' "$_tmp" 2>/dev/null; then
      mv -f "$_tmp" "$_DIXML"
      restorecon "$_DIXML" 2>/dev/null
    fi
    rm -f "$_tmp" 2>/dev/null
  fi
fi

unset _DIXML _CAD_PATCHES _cad_pkgs _pkg _tmp

_set_prop() {
  if command -v resetprop >/dev/null 2>&1; then
    resetprop -n "$1" "$2"
  else
    setprop "$1" "$2" 2>/dev/null
  fi
}

if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then
  _set_prop disableBlurs true
  _set_prop enable_blurs_on_windows 0
  _set_prop ro.launcher.blur.appLaunch 0
  _set_prop ro.sf.blurs_are_expensive 0
  _set_prop ro.surface_flinger.supports_background_blur 0
fi

INITDIR="$MODDIR/system/etc/init"
BINDIR="$MODDIR/system/bin"

if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  _set_prop tombstoned.max_tombstone_count 0
  _set_prop tombstoned.max_anr_count 0
  _set_prop ro.lmk.debug false
  _set_prop ro.lmk.log_stats false
  _set_prop dalvik.vm.dex2oat-minidebuginfo false
  _set_prop dalvik.vm.minidebuginfo false
  _set_prop sys.wifitracing.started 0
  _set_prop persist.vendor.wifienhancelog 0

  mkdir -p "$INITDIR" "$BINDIR"

  for rc in atrace atrace_userdebug bugreport dmesgd \
            dumpstate logcat logcatd logd logtagd lpdumpd \
            traced traced_perf traced_probes traceur; do
    : > "$INITDIR/${rc}.rc"
  done

  for bin in atrace bugreport bugreport_procdump bugreportz \
            diag_socket_log dmabuf_dump dmesgd \
            dumpstate i2cdump log logcat logcatd logd logger logname \
            logpersist.cat logpersist.start logpersist.stop logwrapper \
            lpdump lpdumpd notify_traceur.sh tcpdump traced \
            traced_perf traced_probes tracepath tracepath6 traceroute6; do
    printf '#!/system/bin/sh\nexit 0\n' > "$BINDIR/$bin"
    chmod 755 "$BINDIR/$bin"
  done
else
  rm -rf "$INITDIR" "$BINDIR"
  rmdir "$MODDIR/system/etc" 2>/dev/null
  rmdir "$MODDIR/system" 2>/dev/null
fi
unset INITDIR BINDIR ENABLE_BLUR_DISABLE ENABLE_LOG_KILLING ENABLE_CUSTOM_APP_DOZE