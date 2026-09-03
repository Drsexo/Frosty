apply_system_props() {
  if [ "$ENABLE_SYSTEM_PROPS" = "1" ]; then
    if [ -f "$SYSPROP_OLD" ]; then
      mv "$SYSPROP_OLD" "$SYSPROP"
    fi
    echo "Frosty v${MODVER:-?} - Props - $(date '+%Y-%m-%d %H:%M:%S')" > "$PROPS_LOG"
    if [ -f "$SYSPROP" ]; then
      local pc=$(grep -c '^[^#]' "$SYSPROP" 2>/dev/null || echo "0")
      log_props "[OK] system.prop ENABLED - $pc props, reboot for effect"
    else
      log_props "[WARN] system.prop ENABLED but file missing"
    fi
    echo '{"status":"ok","action":"enabled"}'
  else
    if [ -f "$SYSPROP" ]; then
      mv "$SYSPROP" "$SYSPROP_OLD"
    fi
    echo "Frosty v${MODVER:-?} - Props - $(date '+%Y-%m-%d %H:%M:%S')" > "$PROPS_LOG"
    log_props "[OK] system.prop DISABLED, reboot for effect"
    echo '{"status":"ok","action":"disabled"}'
  fi
}

apply_blur() {
  if [ "$ENABLE_BLUR_DISABLE" = "1" ]; then
    local _partial=0
    local _sdk
    _sdk=$(getprop ro.build.version.sdk 2>/dev/null)

    _set_prop disableBlurs 1
    _set_prop disableBackgroundBlur 1
    _set_prop enable_blurs_on_windows 0
    _set_prop windowBlurBehindEnabled false
    _set_prop windowBlurBehindRadius 0
    _set_prop sys.use_frost_effect 0

    _set_prop ro.launcher.blur.appLaunch 0 || _partial=1
    _set_prop ro.sf.blurs_are_expensive 1 || _partial=1
    _set_prop ro.surface_flinger.force_disable_blur 1 || _partial=1
    _set_prop ro.surface_flinger.supports_background_blur 0 || _partial=1
    _set_prop ro.miui.has_blur 0 || _partial=1
    _set_prop ro.miui.has_real_blur 0 || _partial=1
    _set_prop ro.miui.backdrop_sampling_enabled 0 || _partial=1

    for _pv in \
      persist.sys.sf.disable_blurs=1 \
      persist.sys.background_blur_supported=0 \
      persist.sys.background_blur_status_default=0 \
      persist.sys.background_blur_version=0 \
      persist.sys.add_blurnoise_supported=0 \
      persist.sys.enable_third_blur=0 \
      persist.sys.dynamic_blur_enabled=0 \
      persist.sysui.miui_blur_enabled=0 \
      persist.miui.ui.optimize_blur=0 \
      persist.sys.oneplus.blur.enabled=0 \
      persist.sys.oplus.ui.blur=0 \
      persist.sys.oppo.blur.enable=0 \
      persist.sys.samsung.blur.disable=1 \
      persist.perf.wm_static_blur=false \
      persist.sys.static_blur_mode=true \
      persist.vendor.sf.blur.type=none \
      persist.sys.disable_blur_view=true \
      persist.meizu.gpu_blur=0 \
      persist.sys.force_no_blur=0 \
      persist.sys.disable_glass_blur=true \
    ; do
      _set_prop "${_pv%%=*}" "${_pv#*=}"
    done

    if [ "${_sdk:-0}" -ge 29 ]; then
      cmd window disable-blur 1 >/dev/null 2>&1
    else
      cmd wm disable-blur 1 >/dev/null 2>&1
    fi

    if [ "$_partial" = "1" ]; then
      echo '{"status":"ok","blur":"partial","message":"Some properties need Magisk/resetprop or a reboot to apply"}'
    else
      echo '{"status":"ok","blur":"disabled","message":"Reboot for full effect"}'
    fi
  else
    local _sdk
    _sdk=$(getprop ro.build.version.sdk 2>/dev/null)

    _del_prop disableBlurs
    _del_prop disableBackgroundBlur
    _del_prop enable_blurs_on_windows
    _del_prop windowBlurBehindEnabled
    _del_prop windowBlurBehindRadius
    _del_prop sys.use_frost_effect
    _del_prop ro.launcher.blur.appLaunch
    _del_prop ro.sf.blurs_are_expensive
    _del_prop ro.surface_flinger.force_disable_blur
    _del_prop ro.surface_flinger.supports_background_blur
    _del_prop ro.miui.has_blur
    _del_prop ro.miui.has_real_blur
    _del_prop ro.miui.backdrop_sampling_enabled

    for _p in \
      persist.sys.sf.disable_blurs \
      persist.sys.background_blur_supported \
      persist.sys.background_blur_status_default \
      persist.sys.background_blur_version \
      persist.sys.add_blurnoise_supported \
      persist.sys.enable_third_blur \
      persist.sys.dynamic_blur_enabled \
      persist.sysui.miui_blur_enabled \
      persist.miui.ui.optimize_blur \
      persist.sys.oneplus.blur.enabled \
      persist.sys.oplus.ui.blur \
      persist.sys.oppo.blur.enable \
      persist.sys.samsung.blur.disable \
      persist.perf.wm_static_blur \
      persist.sys.static_blur_mode \
      persist.vendor.sf.blur.type \
      persist.sys.disable_blur_view \
      persist.meizu.gpu_blur \
      persist.sys.force_no_blur \
      persist.sys.disable_glass_blur \
    ; do
      _del_prop "$_p"
    done

    if [ "${_sdk:-0}" -ge 29 ]; then
      cmd window disable-blur 0 >/dev/null 2>&1
    else
      cmd wm disable-blur 0 >/dev/null 2>&1
    fi

    echo '{"status":"ok","blur":"enabled","message":"Reboot for full effect"}'
  fi
}