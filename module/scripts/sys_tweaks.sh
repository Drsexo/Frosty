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
    _set_prop disableBlurs true
    _set_prop enable_blurs_on_windows 0
    _set_prop ro.launcher.blur.appLaunch 0
    _set_prop ro.sf.blurs_are_expensive 0
    _set_prop ro.surface_flinger.supports_background_blur 0
    echo '{"status":"ok","blur":"disabled","message":"Reboot for full effect"}'
  else
    _del_prop disableBlurs
    _del_prop enable_blurs_on_windows
    _del_prop ro.launcher.blur.appLaunch
    _del_prop ro.sf.blurs_are_expensive
    _del_prop ro.surface_flinger.supports_background_blur
    echo '{"status":"ok","blur":"enabled","message":"Reboot for full effect"}'
  fi
}