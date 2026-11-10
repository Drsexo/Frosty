#!/system/bin/sh
# Frosty - Post-FS-Data

MODDIR="${0%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

[ -f "$MODDIR/config/user_prefs" ] && . "$MODDIR/config/user_prefs"

_DIXML="/data/system/deviceidle.xml"
_BLOCKED=" android com.android.systemui com.android.phone com.android.settings com.android.shell com.android.bluetooth com.android.nfc "

_OVERLAYS="$MODDIR/config/doze_xml_overlays.txt"
_STAMP="$MODDIR/backup/overlays.build"
_BAKDIR="$MODDIR/backup/overlays"
_PENDING="$MODDIR/tmp/cad_boot_pending"
_FAILS="$MODDIR/tmp/cad_boot_fail"
_PFLOG="$MODDIR/logs/post_fs_data.log"
mkdir -p "$MODDIR/logs" "$MODDIR/tmp"
echo "Frosty post-fs-data - $(date '+%Y-%m-%d %H:%M:%S')" > "$_PFLOG"
_FP=$(getprop ro.build.fingerprint 2>/dev/null)
_stale=0
[ -n "$_FP" ] && [ -f "$_STAMP" ] && [ "$(cat "$_STAMP" 2>/dev/null)" != "$_FP" ] && _stale=1
_safe=0
if [ -f "$_PENDING" ]; then
  _n=$(( $(cat "$_FAILS" 2>/dev/null || echo 0) + 1 ))
  echo "$_n" > "$_FAILS"
  _safe=1
  [ "$_n" -ge 2 ] && : > "$MODDIR/tmp/cad_xml_off"
  echo "previous boot did not finish, count $_n" >> "$_PFLOG"
fi
[ -f "$MODDIR/tmp/cad_xml_off" ] && _safe=1
: > "$_PENDING"
rm -f "$MODDIR/tmp/cad_session_built"
if [ -f "$_OVERLAYS" ]; then
  while IFS= read -r _src; do
    case "$_src" in '#'*|'') continue ;; esac
    _rel="${_src#$MODDIR/}"
    _bak="$_BAKDIR/$_rel"
    if [ "$_stale" = "1" ]; then
      rm -f "$_src"
      echo "dropped (build changed): $_rel" >> "$_PFLOG"
      continue
    fi
    if [ "$_safe" = "1" ]; then
      rm -f "$_src"
      echo "dropped (safe mode): $_rel" >> "$_PFLOG"
      continue
    fi
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
    if [ ! -f "$_bak" ]; then
      rm -f "$_src" "$_bak.sum"
      echo "dropped (no original backup): $_rel" >> "$_PFLOG"
      continue
    fi
    if [ -f "$_bak.sum" ] && [ "$(cksum < "$_src" 2>/dev/null)" != "$(cat "$_bak.sum" 2>/dev/null)" ]; then
      rm -f "$_src" "$_bak.sum"
      echo "dropped (overlay checksum mismatch): $_rel" >> "$_PFLOG"
      continue
    fi
    if ! cmp -s "$_bak" "$_dst" && ! cmp -s "$_src" "$_dst"; then
      rm -f "$_src" "$_bak" "$_bak.sum"
      echo "dropped (system file changed): $_rel" >> "$_PFLOG"
      continue
    fi
    _ctx=$(stat -c %C "$_dst" 2>/dev/null)
    [ -n "$_ctx" ] && chcon "$_ctx" "$_src" 2>/dev/null
    if mount --bind "$_src" "$_dst" 2>/dev/null; then
      echo "mounted: $_rel" >> "$_PFLOG"
    else
      echo "mount failed: $_rel" >> "$_PFLOG"
    fi
  done < "$_OVERLAYS"
fi
unset _OVERLAYS _src _dst _ctx _BAKDIR _PENDING _FAILS _safe _n _rel _bak

_CAD_PATCHES="$MODDIR/config/doze_patches.txt"
_UNWL_MANIFEST="$MODDIR/tmp/cad_unwl.txt"
mkdir -p "$MODDIR/tmp"

if [ -f "$_DIXML" ] && grep -q '<un-wl ' "$_DIXML" 2>/dev/null; then
  if [ -f "$_UNWL_MANIFEST" ]; then
    while IFS= read -r _old; do
      [ -z "$_old" ] && continue
      _esc=$(printf '%s' "$_old" | sed 's/\./\\./g')
      sed -i "/<un-wl n=\"$_esc\"/d" "$_DIXML" 2>/dev/null
    done < "$_UNWL_MANIFEST"
  else
    sed -i '/<un-wl /d' "$_DIXML"
  fi
  restorecon "$_DIXML" 2>/dev/null
fi

if [ "$ENABLE_CUSTOM_APP_DOZE" = "1" ] && [ -f "$_CAD_PATCHES" ] && [ -f "$_DIXML" ]; then
  _keep=""
  for _pkg in $(sed 's/#.*//;s/[[:space:]]//g' "$_CAD_PATCHES" 2>/dev/null | grep -v '^$'); do
    grep -qxF "$_pkg" "$MODDIR/tmp/cad_missing.txt" 2>/dev/null && continue
    case "$_BLOCKED" in *" $_pkg "*) ;; *) _keep="$_keep $_pkg" ;; esac
  done
  _cad_pkgs="$_keep"
  echo "un-wl packages:$_cad_pkgs" >> "$_PFLOG"
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
    printf '%s\n' $_cad_pkgs > "$_UNWL_MANIFEST" 2>/dev/null
  else
    : > "$_UNWL_MANIFEST" 2>/dev/null
  fi
else
  : > "$_UNWL_MANIFEST" 2>/dev/null
fi

unset _DIXML _CAD_PATCHES _cad_pkgs _pkg _tmp _keep _BLOCKED _STAMP _FP _stale _UNWL_MANIFEST _old _esc _PFLOG

_set_prop() {
  if command -v resetprop >/dev/null 2>&1; then
    resetprop "$1" "$2"
    return $?
  fi
  case "$1" in
    ro.*) setprop "$1" "$2" 2>/dev/null; return 1 ;;
  esac
  setprop "$1" "$2" 2>/dev/null
}

LOGDIR="$MODDIR/logs"
POSTFS_LOG="$LOGDIR/postfs.log"
mkdir -p "$LOGDIR"
log_postfs() { echo "[$(date '+%H:%M:%S')] $1" >> "$POSTFS_LOG"; }

if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then
  _set_prop disableBlurs 1
  _set_prop enable_blurs_on_windows 0
  if command -v resetprop >/dev/null 2>&1; then
    _set_prop ro.launcher.blur.appLaunch 0
    _set_prop ro.sf.blurs_are_expensive 1
    _set_prop ro.surface_flinger.supports_background_blur 0
  else
    log_postfs "[WARN] Blur Disable: resetprop unavailable, ro.* blur props not applied (KSU/APatch limitation)"
  fi
fi

INITDIR="$MODDIR/system/etc/init"
BINDIR="$MODDIR/system/bin"

if [ "$ENABLE_LOG_KILLING" = "1" ]; then
  _set_prop tombstoned.max_tombstone_count 0
  _set_prop tombstoned.max_anr_count 0
  if command -v resetprop >/dev/null 2>&1; then
    _set_prop ro.lmk.debug false
    _set_prop ro.lmk.log_stats false
  else
    log_postfs "[WARN] Log Killing: resetprop unavailable, ro.lmk.debug/ro.lmk.log_stats not applied (KSU/APatch limitation)"
  fi
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
            logpersist.cat logpersist.start logpersist.stop \
            lpdump lpdumpd notify_traceur.sh tcpdump traced \
            traced_perf traced_probes tracepath tracepath6 traceroute6; do
    [ -e "/system/bin/$bin" ] || continue
    printf '#!/system/bin/sh\nexit 0\n' > "$BINDIR/$bin"
    chmod 755 "$BINDIR/$bin"
  done
else
  rm -rf "$INITDIR" "$BINDIR"
  rmdir "$MODDIR/system/etc" 2>/dev/null
  rmdir "$MODDIR/system" 2>/dev/null
fi
unset INITDIR BINDIR ENABLE_BLUR_DISABLE ENABLE_LOG_KILLING ENABLE_CUSTOM_APP_DOZE
