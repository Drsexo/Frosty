#!/system/bin/sh
# Frosty - Main dispatcher

SCRIPTS="${0%/*}"
[ -z "$SCRIPTS" ] && SCRIPTS="/data/adb/modules/Frosty/scripts"
MODDIR="${SCRIPTS%/*}"
[ -z "$MODDIR" ] && MODDIR="/data/adb/modules/Frosty"

. "$SCRIPTS/core.sh"
load_prefs

cmd="$1"; shift

case "$cmd" in
  apply_kernel|revert_kernel)
    . "$SCRIPTS/kernel_tweaks.sh"
    case "$cmd" in
      apply_kernel)  apply_kernel ;;
      revert_kernel) revert_kernel ;;
    esac ;;

  apply_ram|revert_ram)
    . "$SCRIPTS/ram_optimizer.sh"
    case "$cmd" in
      apply_ram)  apply_ram_optimizer ;;
      revert_ram) revert_ram_optimizer ;;
    esac ;;

  apply_sysprops|apply_blur)
    . "$SCRIPTS/sys_tweaks.sh"
    case "$cmd" in
      apply_sysprops) apply_system_props ;;
      apply_blur)     apply_blur ;;
    esac ;;

  apply_bss|revert_bss)
    . "$SCRIPTS/battery_saver.sh"
    case "$cmd" in
      apply_bss)  apply_battery_saver ;;
      revert_bss) revert_battery_saver ;;
    esac ;;

  kill_logs|revert_logs)
    . "$SCRIPTS/kill_logs.sh"
    case "$cmd" in
      kill_logs)   kill_logs ;;
      revert_logs) revert_kill_logs ;;
    esac ;;

  kill_tracking|revert_tracking)
    . "$SCRIPTS/kill_tracking.sh"
    case "$cmd" in
      kill_tracking)   kill_tracking ;;
      revert_tracking) revert_kill_tracking ;;
    esac ;;

  freeze|stock|freeze_category|unfreeze_category|list_frozen|list_gms)
    . "$SCRIPTS/gms_freeze.sh"
    case "$cmd" in
      freeze)             freeze_services ;;
      stock)              unfreeze_services ;;
      freeze_category)    freeze_category "$1" ;;
      unfreeze_category)  unfreeze_category "$1" ;;
      list_frozen)        list_frozen_services ;;
      list_gms)           list_gms_services ;;
    esac ;;

  ram_clean|ram_clean_poll|ram_clean_silent)
    . "$SCRIPTS/ram_clean.sh"
    case "$cmd" in
      ram_clean)        ram_clean "$1" "$2" ;;
      ram_clean_poll)   ram_clean_poll ;;
      ram_clean_silent) ram_clean_silent "$1" ;;
    esac ;;

  get_fg_pkg)
    get_fg_pkg ;;

  list_wl|add_wl|remove_wl|list_ram_wl|add_ram_wl|remove_ram_wl|apply_soo|revert_soo)
    . "$SCRIPTS/prefs.sh"
    case "$cmd" in
      list_wl)       list_wl ;;
      add_wl)        add_to_wl "$1" ;;
      remove_wl)     remove_from_wl "$1" ;;
      list_ram_wl)   list_ram_wl ;;
      add_ram_wl)    add_to_ram_wl "$1" ;;
      remove_ram_wl) remove_from_ram_wl "$1" ;;
      apply_soo)     apply_soo ;;
      revert_soo)    revert_soo ;;
    esac ;;

  export|import|list_backups|share_backup)
    . "$SCRIPTS/io.sh"
    case "$cmd" in
      export)       backup_settings ;;
      import)       restore_settings "$1" ;;
      list_backups) list_backups ;;
      share_backup) share_backup "$1" ;;
    esac ;;

  *)
    echo '{"status":"error","message":"unknown action"}'; exit 1 ;;
esac
exit 0