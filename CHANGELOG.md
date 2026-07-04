# Changelog
## I am not responsible for any unofficial or tampered versions of my module distributed outside this repository.

## [4.3] - 2026-07-04
### App Doze
- **Fixed App Doze re-patching on every boot due to wrong checks**. (thanks to @xizt159 for the report and fix)
### Screen Off Optimization
- **Fixed Wi-Fi/BT/data restore silently failing on some setups** (`svc` path resolution).
- **`_disable_connections()` now checks the actual result before logging success**.
- **Cleaned up "Restoring" log line formatting**.
### GMS Services
- **`unfreeze_services()` fallback no longer re-enables ROM-disabled services accidentally**.
### Kill Logs / RAM Optimizer
- **`device_config` overrides now backed up and restored properly on revert**.
### Battery Saver
- **Stopped forcing Battery Saver to stay active while charging**.
### Uninstall
- **`device_config` revert updated to match**.
- **Fixed two Kill Logs `device_config` keys never reverted on uninstall**.
### Misc
- **Fixed a silent no-op in file-rewrite cleanup helpers** (last-entry-removed edge case).

## [4.2] - 2026-07-01
### Deep Doze
- **Fixed screen-ON poll window after wake**: Monitor now polls every 5 seconds instead of waiting up to 180 seconds.
- **Maximum level now uses the `restricted` bucket**: Moderate stays on `rare`, maximum moves to `restricted`, giving the two levels a real behavioral difference.
- **Skip recently-active apps in `restrict_apps()`**: `WORKING_SET` apps are now excluded from bucket restriction alongside `ACTIVE` ones. This fixes the multitasking page-refresh symptom.
- **Re-force deep idle after wakelock kill**: `_stepdeep()` is now called after each wakelock-killer run in the monitor loop.
### Battery Saver
- **Snapshot and restore `low_power` state**: Original `low_power`, `low_power_sticky`, and `low_power_sticky_auto_disable_enabled` values are saved before applying and restored on revert.
### Screen Off Optimization
- **Added 1-minute delay option**: Both the connection-off and RAM clean delay dropdowns now include a 1-minute option.
- **State file deleted after restore, not before**: If killed mid-restore, the partially-restored state is now recoverable.
### Kill Logs
- **DropBox tag list moved to `config/dropbox_tags.txt`**: Was duplicated verbatim in both kill and revert functions.
- **Removed duplicate Wi-Fi verbose logging call**.
### Kill Tracking
- **Revert uses `settings delete` instead of forcing values to `1`**.
### Kernel Tweaks
- **Fixed debug mask pattern matching too broadly**.
- **`tracing_on` removed from debug-mask zeroing loop**: Owned by Kill Logs with proper snapshot/restore; removing it from kernel tweaks eliminates the conflict.
- **Debug mask nodes are now backed up before zeroing**: `revert_kernel()` can now restore them.
### RAM Optimizer
- **Added LMKD/PSI support**: Detects classic LMK vs PSI-capable LMKD vs legacy LMKD and tunes `ro.lmk.*` props accordingly.
- **Added RAM Cleaner Whitelist**: Apps in the whitelist are skipped by aggressive and extreme mode.
- **Extreme mode no longer force-stops system packages**: `android`, `com.android.*`, and `android.process.*` are now skipped.
### App Doze
- **`deviceidle.xml` write is now atomic**: Changed from `cat >` (truncate-then-write) to `mv -f`.
- **XML overlay matching no longer uses an unbounded regex**: Replaced with `_xml_has_any_pkg()`, a per-package short-circuit helper.
- **Package name matching uses fixed-string grep**: Dots in package names are regex wildcards; switched to `grep -qFx` throughout.
### Uninstall
- **`frozen_services.txt` preserved through uninstall**.
- **GMS UID extraction is now robust**: Fixed malformed UID on ROMs with extra fields on the `userId=` line.
### WebUI
- **Fixed RAM Whitelist toggles being no-ops**: Each row had both a per-row and a container click listener, firing the toggle twice and cancelling itself out.
- **Modal `transition:none` moved from inline style to CSS**.
### Misc and code compatibility
- **`post-fs-data.sh` property setting falls back to `setprop`** on environments without `resetprop`.
- **Tracking revert uses `settings delete`** to restore system defaults rather than forcing hardcoded values.
- **Whitelist file restore is guarded against empty backups**: Importing a backup where App Doze or RAM whitelist files were empty no longer wipes the current lists.
- **`service.sh` category check no longer uses `eval`**.
- **Unified log timestamp format** across all `log_*` functions.
### Refactored
- **`frosty.sh` split into `scripts/`**: Replaced the 1500 lines backend with an 80 lines dispatcher and 12 focused subscripts. All feature scripts are moved to `scripts/` alongside them.


## [4.1] - 2026-06-11
### App Doze: Bug Fixes
- **Fixed XML overlays resetting every other reboot**: `_apply_xml_overlays()` was unconditionally calling `_remove_overlays()` before scanning partitions. After a reboot, the overlay files are bind-mounted by `post-fs-data.sh`, so the mounted (already-patched) XMLs are what get scanned. No unpatched entries are found, no new overlays are created, and the next reboot has nothing to mount. The fix defers `_remove_overlays()` until an unpatched XML is actually found during the scan, so already-correct overlays are left untouched. (@xizt159)
- **Fixed Play Store breaking on OnePlus/Oppo devices when added to App Doze**: Non-GMS packages were having their `allow-in-power-save` sysconfig entries removed. These entries grant Play Store permission to perform background work at the framework layer. Removing them stopped downloads and updates from starting. Non-GMS packages now only have `<wl>` entries patched, leaving `allow-in-power-save` intact.
- **Fixed `*_needs_reboot` flags not being cleared before a re-apply**: Flags are now cleared at the start of every `_apply_xml_overlays()` call and only re-set if new overlays are actually created.
- **Fixed App Doze scan missing `<wl>` text-content entries**: The WebUI candidate scan only grepped for `allow-in-power-save package=` attributes. Apps whose only sysconfig exemption is a `<wl>com.package</wl>` text-content entry were not listed as candidates. Both formats are now detected.
- **Fixed `app_doze.sh` `revert()` calling `_apply_xml_overlays()` instead of `_remove_overlays()`**: The revert path always intends to remove overlays. It now calls `_remove_overlays()` directly.
- **Fixed `scan()` in `app_doze.sh` using `trap ... RETURN`**: `RETURN` is not a valid trap signal in POSIX sh. Tmp files leaked on every call. Replaced with explicit `rm -f` at both exit points.
- **Fixed `uninstall.sh` not fully restoring App Doze custom package whitelist**: The uninstall runner now calls `cmd deviceidle sys-whitelist +` and `cmd deviceidle except-idle-whitelist +` in addition to `dumpsys deviceidle whitelist +` and `cmd appops set ... default`, matching what `app_doze.sh revert()` does.
- **Fixed `scan()` temp files leaking on exit**: Added `trap 'rm -f ...' EXIT` so `scan_inst.tmp` and `scan_cand.tmp` are always cleaned up regardless of how the function exits.
### Deep Doze: New Features and Improvements
- **`force-idle deep` replaces stepped state machine**: `_stepdeep()` now calls `dumpsys deviceidle force-idle deep` which jumps directly to IDLE state, bypassing INACTIVE → IDLE_PENDING → SENSING → LOCATING. Falls back to the 4-step loop on ROMs that don't support `force-idle`.
- **Forced doze stepping**: After deep doze settings are applied, `cmd deviceidle step deep` is called four times immediately. This advances the device idle state machine in seconds rather than waiting 30-90 minutes for the natural transition. Battery savings from deep idle kick in right away. The effect is automatically undone when the screen turns on.
- **Motion sensor disabled in Maximum mode**: The main reason EnforceDoze keeps doze active longer than standard approaches is that it disables the motion sensor service that Android's doze state machine uses to detect user movement and exit IDLE. Added `dumpsys sensorservice disable` to the screen monitor on screen-off when level is Maximum, and `dumpsys sensorservice enable` on screen-on. `stock_deep_doze()` also calls enable as a safety net in case the module is reverted while the screen is off.
- **JobScheduler flex policy (Android 13+)**: `cmd jobscheduler enable-flex-policy --option idle` is applied on API 33+ devices. This makes background jobs with leeway prefer running during device-idle windows instead of firing at arbitrary times. Reverted via `reset-flex-policy` when deep doze is stocked.
- **Fixed `kill_wakelocks()` being a complete no-op**: The function extracted package names using `grep -oE "packageName=[^ ]+"` on `dumpsys power` wakelock output. That field does not exist in wakelock lines, the package is in the `ws=WorkSource{uid package.name}` field. Every iteration hit `[ -z "$pkg" ] && continue` and nothing was ever killed. Fixed to parse from the WorkSource field.
- **Fixed `kill_wakelocks()` proc state detection failing on some ROMs**: `grep -A2` was used to find the `procState=` field in `dumpsys activity processes` output. On ROMs where fields are spaced differently the state was missed and processes were force-stopped regardless. Widened to `grep -A5`.
- **Screen state check before `force-idle`**:`_stepdeep()` now only fires when the screen is already off. Toggling Deep Doze on from the WebUI while actively using the device no longer forces the system into idle momentarily.
- **Removed orphaned `unrestrict_alarms()` call and function**: `restrict_alarms()` was removed in v3.4 but its counterpart remained in `stock_deep_doze()`, looping over all third-party packages and resetting alarm appops on every revert. Removed the call and the now-unused function.
### Screen Off Optimization: New Features and Fixes
- **Replaced "Clear cached apps" toggle** (`SOO_KILL_CACHE`) with a **RAM clean mode selector** (`SOO_RAM_CLEAN_MODE`: `off`, `safe`, `aggressive`, `extreme`). Config key `SOO_CACHE_DELAY` renamed to `SOO_RAM_CLEAN_DELAY`. Existing installs with `SOO_KILL_CACHE=1` are automatically migrated to `SOO_RAM_CLEAN_MODE=safe` on first load. The SOO path calls `frosty.sh ram_clean_silent $mode`, no code duplication with the WebUI cleaner.
- **New option: Disable Sensors**: Disables all device sensors (accelerometer, gyroscope, step counter, pedometer, etc.) using Android's `sensors_off` mode.
- **New option: Panel LPM**: Enables the display panel hardware low-power mode (`display_panel_lpm 1`) when the screen turns off, reducing power draw during brief wake-ups. Restored immediately on screen-on.
- **Fixed a rare instance where restore-on-unlock was firing without the user unlocking on some ROMs**
- **Fixed unlock restore delay of up to 30 seconds**: When all scheduled tasks were complete, the screen-state poll interval was 30 seconds. Reduced to 5 seconds.
- **Fixed Wi-Fi and Bluetooth state detection across ROM variants**: Detection now uses `settings get global wifi_on` / `bluetooth_on` as the primary check, with `dumpsys` as fallback for ROMs that report state differently.
- **Fixed `_restore_connections()` unnecessary `location_mode 0` intermediate write**: Location was already 0 from the screen-off disable step. The intermediate set-to-0 + `sleep 1` added a pointless delay before the actual restore. Removed.
- **Tethering check before disabling mobile data**: SOO no longer disables mobile data when USB tethering, Wi-Fi hotspot, or Bluetooth tethering is active, preventing disconnection of tethered clients.
### Kill Logs: Bug Fixes and Additions
- **Fixed `revert_kill_logs()` setting `printk_ratelimit` to `0`**: Setting to `0` disables rate limiting entirely. Corrected to `5`, the Android default.
- **Fixed `revert_kill_logs()` unconditionally re-enabling `tracing_on`**: ftrace tracing is off by default on production Android. Re-enabling it on revert was incorrect. Line removed.
- **Fixed `printk_ratelimit` and `printk_ratelimit_burst` conflict between `kernel_tweaks.txt` and `kill_logs()`**: Both entries removed from `kernel_tweaks.txt`. Log suppression belongs exclusively to Kill Logs, which sets both to `1`.
- Dynamic window logging discovery via `dumpsys window` (replaces single static call)
- `cmd voiceinteraction set-debug-hotword-logging false`
- `cmd wifi set-verbose-logging disabled -l 0` (broader ROM compatibility)
- `device_config put interaction_jank_monitor enabled false` + `trace_threshold_frame_time_millis -1` (reverted via `device_config delete` on disable)
- `settings put global netstats_enabled 0` (reverted via `settings delete` on disable)
- `logcat -G 64k` before clearing (reverted to `256k` on disable)
### Kill Tracking: New Tweaks and Fixes
- **`binder_calls_stats` disabled**: Sets `enabled=false`, `detailed_tracking=disable`, `upload_data=false`, and extends the sampling interval. Reduces Android framework stats collection overhead. Reverted via `settings delete` in `revert_tracking()`.
- **`battery_stats_constants` extended**: Two previously missing fields (`track_cpu_times_by_proc_state=false`, `read_binary_cpu_time=false`) added to the existing constants string in `kill_logs()`.
- **Fixed `uninstall.sh` not reverting Kill Tracking netpolicy restriction**: `kill_tracking()` adds the GMS UID to `restrict-background-blacklist`. `uninstall.sh` now looks up the GMS UID and calls `cmd netpolicy remove restrict-background-blacklist` during cleanup.
### GMS Services: Fixes
- **Fixed `freeze_services()` and `unfreeze_services()` re-enabling ROM-pre-disabled services**: When running at boot with some categories enabled, the function was calling `pm enable` on non-selected categories, incorrectly re-enabling services the ROM itself had disabled. `freeze_services()` now checks `pm list packages --user 0 -d` before disabling each service. Services already disabled by the ROM are skipped and not tracked. A `tmp/frozen_services.txt` file records only the services Frosty actually disabled. `unfreeze_services()` uses this file so only Frosty-disabled services are re-enabled, with a full-list fallback for existing installs. `uninstall.sh` uses the same tracking file.
- **Fixed `freeze_services()` dead variables `count_skip` and `count_enabled`**: Both were declared but never modified. Summary log simplified to disabled/failed counts only. The `echo` line retains `Re-enabled: 0` for `parseOutput` regex compatibility.
- **Fixed `freeze_category()` not guarding ROM-pre-disabled services**: Per-category freeze from the WebUI never applied the ROM-pre-disabled check. Services already disabled by the ROM could be tracked and later re-enabled by `unfreeze_category()`. Fixed to apply the same guard and append only Frosty-disabled services to `frozen_services.txt`.
### Kernel Tweaks: Fixes
- **TCP congestion control write is now verified**: After writing the preferred algorithm, the value is read back. A mismatch logs a warning instead of silently claiming success.
- **Fixed `apply_kernel()` leaking `section` variable to script scope**: Added to local declarations.
- **Fixed block I/O tweaks not backed up to `kernel_values.txt`**: `read_ahead_kb` and `iostats` for each block device were written without saving original values. On `revert_kernel`, those values were never restored. Originals are now backed up per-device before writing, following the same `name=value=path` format as TCP extras.
### RAM Optimizer: Major Overhaul and Fixes
- **ZRAM compression algorithm auto-selection and revert fix**: Reads `/sys/block/zram0/comp_algorithm` to get the list of algorithms the kernel actually supports, then selects the best available from a priority chain: `lz4 → zstd → lz4hc → lzo-rle → lzo → deflate`. If the running algorithm already matches the best available, only `max_comp_streams` is updated. Otherwise, if the device allows a `swapoff`, ZRAM is reset, reconfigured with the new algorithm and original disksize, and re-mounted as swap. Falls back gracefully if the device is actively swapping and cannot be taken offline. Additionally, `revert_ram_optimizer()` now correctly intercepts `comp_algorithm`, `disksize`, and `max_comp_streams` entries from the restore loop and runs the required `swapoff → reset → restore → mkswap → swapon` sequence when the algorithm differs.
- **`max_comp_streams = nproc`**: ZRAM compression thread count is now set to the CPU core count instead of the kernel default, improving throughput on multi-core devices.
- **`page_cluster` auto-mode**: Automatically set to `0` when zstd is selected (zstd's variable-length blocks misalign with cluster reads), stays at `1` from `ram_tweaks.txt` for all other algorithms.
- **LMK minfree proportional thresholds**: Calculates and writes six OOM kill thresholds scaled proportionally to the device's total RAM (1.5%, 2%, 2.5%, 3%, 3.5%, 5% of total pages). Applies only when the kernel LMK node `/sys/module/lowmemorykiller/parameters/minfree` exists; silently no-ops on LMKD devices. Backed up and restored on revert.
- **Vendor reclaim disabling and backup fix**: Best-effort writes `0` to eight OEM-specific aggressive background reclaim nodes: Qualcomm process_reclaim, Xiaomi mi_reclaim + greclaim + low_free + memplus, MediaTek perfmgr, OnePlus opchain. Each node fires only if present on the device. OEM reclaim nodes are now also backed up to `RAM_BACKUP` in `name=value=path` format before being modified, ensuring they are correctly restored on revert.
- **Interactive RAM Cleaner** added to the RAM Optimizer card. A button opens a modal with three presets: Safe, Aggressive, Extreme. The modal shows real-time progress: the close button and backdrop tap are locked while cleaning is in progress, and re-enabled when done.
### Config Files: Restructuring
- **VM memory params separated from kernel tweaks**: `dirty_background_ratio`, `dirty_ratio`, `dirty_expire_centisecs`, `dirty_writeback_centisecs`, `stat_interval`, `vfs_cache_pressure`, and `oom_dump_tasks` have been moved from `kernel_tweaks.txt` to `ram_tweaks.txt`. Users who disable the RAM Optimizer no longer lose these VM tunables from the kernel tweaks scope. `kernel_tweaks.txt` now focuses exclusively on scheduler, panic, timer, entropy, TCP, and hardware parameters.
- **New VM params in `ram_tweaks.txt`**: `overcommit_memory=1` (always overcommit, standard Android behavior made explicit), `overcommit_ratio=75`, `watermark_scale_factor=100` (1% of total pages between min/low watermarks for more aggressive reclaim triggering), `watermark_boost_factor=0` (disables watermark boost, eliminates spurious compaction wakeups), `nr_hugepages=0` (disables Transparent Huge Pages; on mobile they waste memory and cause allocation stalls).
### system.prop
- **Fixed `db.log.slow_query_threshold` value**: Changed to `-1` (disables slow query logging per Android's `>= 0` threshold check). Previous value of `0` caused every query to be logged as slow.
### General Bug Fixes
- **Fixed `max_comp_streams` and LMK `minfree` backup entries being silently unrestorable**: Both were saved as `path=value` (two fields) instead of the `name=value=path` three-field format that the restore loop expects. The path field was always empty, so every restore attempt was skipped silently. Format corrected.
- **Fixed `restore_settings()` defaulting BSS options to `1` on import of old backups**: When a backup JSON was missing `BSS_SOUNDTRIGGER_DISABLED`, `BSS_FULLBACKUP_DEFERRED`, `BSS_KEYVALUEBACKUP_DEFERRED`, or `BSS_SENSORS_DISABLED`, the fallback was `1`. Default is now `0` to match `config/user_prefs`. Same fix applied in `api.js` `getPrefs()`.
- **Fixed `wifi_scan_always_enabled` forced to `1` on uninstall**: Changed to `settings delete` to restore the system default.
- **Fixed `gms_checkin_timeout_min` and `binder_calls_stats` not reverted on uninstall**: Both keys set by Kill Tracking were missing from the uninstall runner's cleanup block.
### Code Organisation
- **`frosty.sh` function order**: All 28 functions reorganised to match the logical `user_prefs` order: helpers → kernel → sysprops → RAM → logs → tracking → battery saver → GMS freeze/unfreeze → SOO → whitelist → backup/restore.
- **`api.js` function order**: All async and sync API functions reorganised to the same logical order as `frosty.sh`, with `uid`/`available`/`exec` foundational helpers placed first to prevent IIFE reference errors.
- **Naming consistency**: Functions and case entries renamed to a uniform `verb_noun` pattern.
- **`app_doze.sh` reboot file**: `doze_xml_needs_reboot` and `cad_needs_reboot` consolidated into a single `$_reboot_file` variable pointing to `cad_needs_reboot`. Removes the redundant second flag file.
- Config file comment cleanup and note additions.
> Thanks again to @xizt159 for the help with many changes and suggestions.

## [4.0] - 2026-05-07
Clean install recommended if upgrading from v3.7 or earlier. Many scripts and configs were restructured.
### New Feature: Screen Off Optimization
Automatically disables selected connections (Wi-Fi, Bluetooth, mobile data, and location) and clears recent background apps after the screen has been off for a configurable delay, then restores everything the moment you unlock. Each connection can be toggled independently. Only the ones that were actually on at screen-off time are ever disabled
### GMS Doze: Merged into App Doze
GMS doze has been removed, it is now treated as a regular App Doze package, select GMS in the App Doze list to get the same effect. Users upgrading from v3.7 who had GMS Doze enabled need to add GMS to the App Doze list manually once.
### App Doze: Improvements
- **Apps scanning rewritten for faster execution**: Typical scan time reduced from 10-30 seconds to 1-3 seconds on devices with large sysconfig directories.
- **Rare bootloop fix**: The previous approach modified the file in place. If interrupted mid-write by an OOM kill or storage hiccup, a half-written overlay would be registered and bind-mounted at next boot, causing PackageManager to fail parsing it resulting in a bootloop. Fixed by writing to a `.tmp` file, validating its integrity and closing-tag, and only moving it into place on success. A failed validation skips the overlay entirely and logs a warning, the original system file is used instead. Also added an XML sanity check before mounting any overlay in `post-fs-data.sh`.
### GMS Improvements
- **Kill Google Tracking now also restricts GMS background data** at the network policy layer via `cmd netpolicy`, operating below the app level where GMS cannot bypass it. 
- **Kill Google Tracking now extends GMS check-in interval** from ~60 to 120 minutes, reducing background wake-up frequency.
- **GMS category freeze now cancels pending JobScheduler jobs** immediately after disabling services, preventing one last job fire before the system acknowledges the disabled state.
### system.prop Fixes
- **Fixed `persist.ims.disableQXDMLogs=0`**: Which was leaving QXDM logs enabled. Corrected to `1`.
- **Fixed `persist.ims.disableIMSLogs=0`**: Same inverted boolean. Corrected to `1`.
- **Fixed `sdm.debug.disable_skip_validate=1`**: `disable_skip_validate=1` forces full frame validation on every frame, increasing GPU work. Corrected to `0` to allow the driver to skip validation when safe.
- **Removed `ro.config.knox` and `ro.config.tima` props** which were causing bootloops on some Samsung devices  with hardware-enforced Knox.
- **Removed `security.mdpp` and `sdm.debug.*` props**: these weren't widely compatible with different socs, meaningless at best.
### Kernel Tweaks: New Dynamic Sections
- **Block I/O tuning**: Added dynamic loop over all non-RAM/loop/zram block devices. Sets `read_ahead_kb=128` (reduces wasteful speculative prefetch on flash storage which has near-zero seek latency) and `iostats=0` (disables per-device I/O statistics collection overhead).
- **TCP extras**: Added `tcp_slow_start_after_idle=0` (prevents TCP connections from restarting slow-start congestion control after idle periods) and `tcp_fastopen=3` (enables TCP Fast Open client+server, reducing round-trips for reconnecting to known servers). Both backed up and restored via the kernel backup file.
### Bug Fixes
- **Fixed `revert_battery_saver()` setting `low_power_sticky_auto_disable_enabled` to `0`**: Android's default is `1` (battery saver auto-disables when charger is plugged in). Setting it to `0` on revert meant battery saver could stay on permanently after the feature was toggled off. Fixed to restore the default value of `1`.
- **Fixed `revert_doze_constants()` actively disabling Doze instead of restoring stock**: `dumpsys deviceidle disable` turns Doze completely off, and `settings put global app_standby_enabled 0` disables Android's entire app standby bucket system. Both are worse than stock behavior. Any user who toggled Deep Doze off ended up with worse battery than an unmodified device. Fixed to `dumpsys deviceidle enable` and `settings delete` to restore Android defaults.
- **Fixed `revert()` in `app_doze.sh` missing two whitelist tier restorations**: `apply()` removes packages from three tiers (user whitelist, sys-whitelist, except-idle-whitelist) but `revert()` only restored the user tier. Packages stayed partially de-whitelisted until the next boot. Added `cmd deviceidle sys-whitelist +` and `cmd deviceidle except-idle-whitelist +`.
- **Fixed `list_pkgs()` subshell variable mutation producing malformed JSON**: `echo "$pkgs" | while read` creates a subshell where `first=0` never propagates back, so every package was missing its preceding comma, producing `["pkg1""pkg2"]` instead of `["pkg1","pkg2"]`. Fixed using a heredoc which runs the loop in the current shell.
- **Fixed `post-fs-data.sh` CAD bind-mount case pattern whitespace**: Spaces embedded in the pipe-separated case pattern made the OEM partition paths literal matches that never fired. CAD XML overlays were silently not bind-mounted on Oppo/Realme/OnePlus custom partition devices.
- **Fixed `post-fs-data.sh` CAD `deviceidle.xml` patch not atomic**: The loop removed `</config>` and re-added it once per package. If killed between the sed removal and the echo, the XML was left without a closing tag. All `<un-wl>` entries and `</config>` are now written in a single grouped operation.
- **Fixed `deep_doze.sh` `ensure_whitelist()` `echo ""` writing to stdout**: The blank separator line was output to stdout instead of being appended to `$WHITELIST_FILE`. Any caller capturing `ensure_whitelist` output would receive a spurious blank line.
- **Fixed `frosty.sh` dispatcher silently succeeding on unknown actions**: Unknown command now returns `{"status":"error","message":"unknown action"}` and exits 1 instead of silently exiting 0.
- **Fixed `kill_wakelocks()` temp files leaking on TERM signal**: Added `trap 'rm -f "$tmpfile" "$procfile"' EXIT TERM` so temp files are cleaned even when the process is killed mid-execution.
- **Fixed `post-fs-data.sh` Kill Logs cleanup leaving stale overlays**: `rmdir` silently fails on non-empty directories, leaving `$MODDIR/system/bin/` in place, causing Magisk to remount the stub directory over `/system/bin/` on every subsequent reboot. Fixed to `rm -rf`.
- **Fixed `uninstall.sh` duplicate GMS Doze + App Doze revert blocks**: Two separate sections were reverting GMS separately from the rest of App Doze. Merged into a single "Revert App Doze" block that handles all packages including GMS.
- **App Doze selected apps in WebUI now shown at the top of the list**: The app picker now sorts selected packages to the top with a separator, matching the existing behavior of the Deep Doze whitelist. Previously selected apps were scattered throughout the alphabetical list.
- **`DEEP_DOZE_LEVEL` quoting unified**: `frosty.sh` `restore_settings` and `api.js` `setPref` now both write unquoted values, eliminating the inconsistency.
- **Fixed Kill Logs not correctly reverting everything when disabled**.
- **Fixed the WebUI clipping through Android status bar and navigation bar in some OEMs**.

## [3.7] - 2026-04-15
### New Feature: Custom App Doze
Remove any app from Android's Doze power-save exemption list, the same mechanism GMS Doze uses for GMS, now available for any package.
- **Toggle + app picker in WebUI**: Shows only apps currently bypassing battery optimization (i.e. actually present in the Doze whitelist). Apps already handled by GMS Doze are blocked from being added here to avoid conflicts.
- **`post-fs-data.sh` patching**: `<wl>` entries are removed and `<un-wl>` entries injected into `deviceidle.xml` before `system_server` starts, so the framework never exempts the selected apps on boot. Disabling the feature automatically cleans up all injected entries.
- **Runtime apply**: `app_doze.sh` removes selected packages from all three whitelist tiers (`dumpsys deviceidle whitelist`, `cmd deviceidle sys-whitelist`, `except-idle-whitelist`) and clears any persistent `<wl>` entries from `deviceidle.xml`.
- **Safety blocklist**: `com.google.android.gms` and core system packages are silently blocked with a visible warning in the UI - GMS is handled by its own dedicated toggle.
- **Fully integrated with Import/Export**: `doze_patches.txt` is base64-encoded into the backup JSON alongside the whitelist and restored on import.
- **Preserved on reinstall**: `doze_patches.txt` is backed up and restored automatically during module updates, same as the Doze whitelist.
### Deep Doze: Fixes
- **Fixed `moderate` mode effectiveness**: Bucket was regressed from `rare` to `frequent` in the previous refactor. `frequent` barely restricts background work. Both levels now use `rare` bucket.
- **Fixed screen monitor not running in `moderate` mode**: The wakelock killer via screen monitor was only started in `maximum` mode. `moderate` had no active overnight cleanup at all. Screen monitor now starts for both levels. Behavior: 5 minutes after screen-off, background apps holding wakelocks are force-stopped. Screen-on resumes normal multitasking without any intervention.
- **Restored `get_screen_state()` display fallback**: The `dumpsys display mScreenState=` and `Display Power: state=` detection paths were removed in the previous refactor, leaving only `dumpsys power mWakefulness=` which is less reliable on some ROMs. All three detection methods are now present in priority order.
- **WAKE_LOCK deny remains maximum-only**: Moderate mode restricts background activity via standby buckets and the screen monitor without denying wakelocks, preserving more graceful multitasking behavior.
### RAM Optimizer: New device_config Tweaks
- **`activity_manager use_compaction true`**: Enables Android's built-in memory compaction. Background app memory pages are compacted in-place rather than evicting the app, improving resume speed under memory pressure. On by default on Pixel hardware.
- **`activity_manager_native_boot use_freezer true`**: Enables the cgroup freezer for background apps. Frozen processes use zero CPU, state is preserved for instant resume. More efficient than priority adjustment.
- **`alarm_manager save_battery_on_idle true`**: Batches non-critical alarms more aggressively during idle, reducing unnecessary wakeups.
### Kill Logs: New device_config Tweaks
- **`activity_manager disable_app_profiler_pss_profiling true`**: Disables PSS memory sampling triggered by ActivityManagerService on every app launch. Eliminates a CPU spike at startup with no user-visible effect.
- **`activity_manager activity_start_pss_defer 300000`**: Defers remaining PSS collection 5 minutes post-launch. 
### WebUI Improvements: 
- Implemented back navigation support matching [KernelSU-Next commit 2cd86fb](https://github.com/KernelSU-Next/KernelSU-Next/commit/2cd86fb790bad40c365cd5e85fb95feb0b79f844).
- **Fixed language not loaded when KSU API is unavailable**: Language is now initialized first so the error displays correctly in the user's language.
### GMS Doze: Critical Fixes
- **Fixed overlay files for `product/`, `vendor/`, `odm/`, `system_ext/` stored at wrong path**: Now stored directly at `$MODDIR/<partition>/...` instead of `$MODDIR/system/<partition>/...`.
- **Fixed GMS doze undoing itself sometimes on boot**: `post-fs-data.sh` cleanup code now correctly placed in the `else` branch.
- **Fixed `remove_xml()` leaving empty directories behind for non-system partitions**.
- Fixed the XML overlay counter in GMS Doze status logging counting blank lines and comment lines as valid overlays.
### Other Changes and Fixes
- **Fixed kernel tweak log headers missing `#` prefix**.
- **Fixed kernel tweak variable typo `$_line` vs `$line` in `service.sh`**: Removed duplicate implementation; `service.sh` now delegates to `frosty.sh apply_kernel`.
- **Fixed whitelist icon caching**: `img.dataset.pkg` was never set; added binding plus `onload`/`onerror` handlers.
- **Fixed whitelist `IntersectionObserver` leaking after modal close**.
- **Fixed Kill Logs causing SELinux audit wakeups**: Empty stub files replaced with valid shell scripts.
- **Fixed BSS modal placed after `<script>` tags in `index.html`**.
- **Removed 100+ lines of duplicate code from `service.sh`**.
- **Fixed Deep Doze wakelock killer running `dumpsys activity processes` per-package**: Now dumped once before the loop.
- **Safer screen monitor PID handling**: `kill -0` check before sending signal.
- **Removed swappiness and process limit overrides from RAM Optimizer**: Conflicts with OEM LMK/ZRAM tuning.
- **TCP keepalive tuning**: Reduces dead connection detection from ~2.2 hours to ~12 minutes.
- **inotify limits raised**: `max_user_watches` to 262144, `max_user_instances` to 512.
- **Kernel log audit suppression**: `dmesg -n 1` and printk rate limiting in `kill_logs()`.
- **`MODVER` now read before any filesystem operations in all scripts**.
- **Variable declarations consolidated at file top in `service.sh`**.
- **Execution order corrected in `deep_doze.sh`**.
- **Removed "What's Available" section in installer**.

## [3.6] - 2026-03-21
### GMS Doze: Rework
The previous implementation was only doing the runtime half. The patched XML overlay files were never actually being mounted, meaning GMS was re-added to `system-excidle` on every reboot by the framework reading the original unmodified sysconfig XMLs. The feature appeared to work but had no persistent effect. #9
- **Improved XML patching**: searches the correct partitions for XMLs containing GMS power-save exemption entries,. Deduplicates via symlink resolution. Partition-aware overlay placement prevents bootloops on devices where `/product` is a separate mount point. Conflicting XML entries from other installed modules are also patched at early boot.
- **Early sysconfig bind mount**: patched XMLs are now bind-mounted in `post-fs-data.sh`, before `system_server` starts.
- **`deviceidle.xml` manipulation**: removes `<wl>` entries, injects `<un-wl>`, and cleans up malformed entries from previous versions. Secondary verification pass ensures changes took effect.
- **Runtime whitelist removal**: `sys-whitelist` and `except-idle-whitelist` called alongside `dumpsys deviceidle whitelist` to cover all tiers.
- **Improved status logging**: each whitelist tier checked individually with a final verdict: fully optimized, effectively dozed (`system-excidle` cosmetic, deep doze still active), or unstable.
### Bug Fixes
- Fixed rare black screen on wake when Kill Logs is enabled: `crash_dump32/64`, `debuggerd`, and `debuggerd64` were being stubbed out, breaking the native crash handler chain. Also removed `dmesg` and `logwrapper` which are init/service dependencies.
- Fixed RAM optimizer aggressively killing background apps: static `max_cached_processes` overrides conflict with lmkd on Android 10+ which uses PSI pressure metrics dynamically. Overrides removed; lmkd now manages process limits as intended. Stale keys from older versions are cleaned up automatically on next apply.
- Fixed RAM backup recording already-tweaked swappiness/extra_free_kbytes values when called from WebUI after service.sh already applied them at boot.
- Fixed `uninstall.sh` leaving GMS doze traces in `deviceidle.xml` after module removal.
- Fixed Force Reapply silently skipping Kill Google Tracking even when enabled.
- Fixed Kill Logs reboot warning tag showing hardcoded English on non-English locales.
- Fixed whitelist showing empty on KSU builds that don't support `nativeListPackages`. Also changed fallback to `pm list packages` so system apps are included. #10
- Fixed whitelist modal shrinking while searching to match visible content.
- Adjusted and cleaned up kernel tweaks, RAM tweaks, and system props. Removed redundant and duplicate entries, reorganized values into their correct files, and adjusted several values based on real-world testing.

## [3.5] - 2026-03-14
### New Feature: Kill Google Tracking
A new dedicated toggle that suppresses GMS analytics and telemetry at the **application layer**, complementing the existing service freezing which works at the process layer. Blocks: Clearcut telemetry pipeline, Phenotype config polling and log upload, GMS core stats, Play Store panel logging, Google Analytics and upload scheduler, ad tracking (returns all-zeros advertising ID), Tron internal metrics, usage stats collection, and the network watchlist background cross-referencing. All settings are fully reverted on toggle-off and on uninstall.
### Kernel Tweaks: New Additions & Corrections
- **Less unnecessary background CPU activity**: Added three new tweaks that reduce unnecessary kernel activity when the device is idle. Such as: dirty page writeback, proactive background memory compaction, NMI watchdog timer interrupt.
- **Corrected conflicting values**: Duplicates removed and values unified in the correct place.
### Kill Logs: Reduced Background Drain
- **NetworkStats polling reduced**: for less background activity and wakelock when the screen is off.
- **WiFi background scanning suppressed**: Stops WiFi from scanning for networks in the background when the screen is off.
- Fixed settings backup exporting two values with a malformed number format instead of a clean `0` or `1`.

## [3.4] - 2026-03-10
### New feature: Battery Saver Tuner!
Configure exactly what Android's battery saver mode does when it's active. Individual toggles for: background data (data saver), hotword detection, backups, force standby, background checks, sensors, and GPS behavior. These only take effect when battery saver is on.
### WebUI + Backend
- Dead `GMS_LIST`, `SYSPROP`, `SYSPROP_OLD` variables removed, no longer referenced.
- Renamed `applyTweaks` / `revertTweaks` / `.log-copy-btn` to `applyKernelTweaks` / `revertKernelTweaks` / `.log-action-btn` for more accurate naming.
- Fixed Enable All / Revert All not applying RAM Optimizer in rare cases.
- Fixed some shell errors being silently swallowed instead of reported.
- `max-height: 50vh` added to `.hdr-banner` to fix the overflow on small screens. Also added **`object-position: center` to `.hdr-banner-img` to fix the banner image cropping from the top.
### Bug Fixes
- Removed hardcoded `/data/adb/modules/Frosty` paths from different shell files and WebUI backend.
- Removed `restrict_alarms()` and `force-idle deep` from maximum level of Deep Doze since they were delaying alarm triggers in some cases.
- Fixed disabling Deep Doze not reverting some settings.
- Changed the standby bucket restricted → rare for better multitasking.
- Swappiness and `extra_free_kbytes` are no longer hardcoded in  `ram_tweaks.txt`, they're now handled by tiered logic in `apply_ram_optimizer()` based on actual device RAM for more general compatibility.
- Adjusted `watermark_scale_factor` to fix the aggressive RAM killing for bigger apps. 
- Added TCP Congestion Control selection which picks the best available network algorithm in order: `bbr3 → bbr2 → bbrplus → bbr → westwood → cubic`. Original algorithm backed up and restored on revert.
- And many more code cleanup for better readability.

## [3.3] - 2026-03-07
### WebUI
- Restyled Deep Doze level buttons.
- Progress display fixed for Enable All / Revert All / Reapply Settings.
- Fixed Enable All / Revert all ignoring RAM Optimizer.
- Improved whitelist selection menu.
### Shell / Backend
- **Kernel Tweaks**: `%%|*` parsing fixed, which was causing every kernel tweak path and value to parse as empty, hence the 0/0 applied counter that appeared in the activity log.
- Fixed hardcoded functions both in WebUI and shell files, causing some operations to unnecessarily apply twice. Made `frosty.sh` the main backend.
- Removed some old dead variables from WebUI.
- Fixed Deep Doze always enabling data saver.
- **General improvements to logs**: Better headers and separators format, added summary to GMS services log.
- And many more code cleanup and fixes.

## [3.2] - 2026-03-05
### Improved RAM Optimizer
- **Android process management**: Caps cached background processes at 10 and empty (dead-weight) processes at 5 via `device_config`. Empty processes are now evicted after 30 seconds instead of the default 30 minutes.
- **USAP pool**: Pre-forks Zygote processes at boot so cold app launches start faster.
- **Added new RAM tweaks with proper backup/restore**: 
`swappiness=100` (pushes stale anonymous pages to zram sooner)
`page-cluster=0` (disables pointless swap readahead on zram devices)
`watermark_scale_factor=30` (kernel reclaims memory proactively before stalls occur)
`extra_free_kbytes=8192` (LMKD starts evicting cached apps slightly earlier; skipped silently if the path does not exist on the kernel).
- **Proper backup/restore**: Mirrors the kernel tweaks pattern exactly. Actual pre-Frosty sysfs values are saved to `backup/ram_values.txt` on first enable and restored on revert.
### New Tracing Nuking
- **`traced` RC stub was missing**: `traced` was already stubbed as a binary in `post-fs-data.sh` but its init RC override was absent, meaning the Perfetto main daemon could still be started by init before the binary stub took effect. RC entry added.
- **`persist.traced.enable=0`** added to `system.prop` to disable Perfetto at the framework level as a belt-and-suspenders measure alongside the binary/RC stubs.
- **`traced_perf` and `traced_probes`** added to the runtime kill loop in `frosty.sh` so all three Perfetto daemons are killed immediately when Log Killing is toggled on from the WebUI.
### Log Killing: DropBox Categories
- **25 Android DropBox diagnostic categories** are now disabled when Log Killing is enabled. This disables system-level crash and diagnostic log collector that accumulates dumps in `/data/system/dropbox/` continuously. 
- **`tombstoned.max_anr_count=0`** added alongside the existing `tombstoned.max_tombstone_count=0`. This caps the ANR trace counter for `/data/anr/` separately from the tombstones counter.
- **Qualcomm Wi-Fi trace logging disabled**: `sys.wifitracing.started=0` and `persist.vendor.wifienhancelog=0` added unconditionally (no-ops on non-Qualcomm devices).

## [3.1] - 2026-03-04
- **Added NEW Ram Optimizer**: It sets `max_cached_processes=10` via both cmd device_config and settings put (for more android versions compatibility), plus enables USAP pool for faster cold launches. Revert deletes both keys, returning to system defaults with no residual state.
- **GMS Services**: 10 new telemetry entries added: GoogleHelpService, PhenotypeOperationService, PhResetService, HerrevadAndroidService, UdcService, UdcMddService, FocusAndroidService, stats.DropBoxEntryAddedService, gms.location.nearby.direct.service.NearbyDirectService, com.google.mainline.telemetry.
- **Deep Doze**: no longer spawns a background subshell if the last one is killed mid-sleep.
- **GMS Doze**: no longer patches other conflicting XML files from other modules, will only cause issues if kept.
- **WebUI Visual Overhaul**: cleaner style with better vibrant colors.

## [3.0] - 2026-03-03
### Module Internationalization
- **14 languages support**: The entire module and WebUI are now fully translated, supporting English, French, German, Polish, Italian, Spanish, Portuguese (BR), Turkish, Indonesian, Russian, Ukrainian, Chinese Simplified, Japanese, and Arabic.
- **Auto language detection**: The UI detects your device locale during installation and prompts you to use the detected language or stay on English. All subsequent output is printed in the chosen language. A language picker in the WebUI lets you override the detected language at any time from the menu.
### WebUI New Features and Fixes
- **Force Reapply Settings button**: Re-applies every currently enabled setting in one tap.
- **Import / Export**: Back up your current configuration to a JSON file in `/sdcard/Frosty` and restore it later.
- **About dialog**: Displays module version, description, and credits inline in the WebUI.
- **system.prop deletion bug**: The System Props toggle was calling `rm` on `system.prop.old` instead of `mv`, permanently destroying the file on enable. Fixed to always use `mv` in both directions so the file is never lost.
### Misc
- **No more setup wizard**: The installer no longer prompts you for anything during setup. All 14 volume-key interactions have been removed. Everything is configured in WebUI after reboot instead.
-**Kernel tweaks are no longer hardcoded**: They are now stored in `kernel_tweaks.txt` for better maintainability.
- **Removed `action.sh`**: Configuration is now done through the WebUI. Magisk users can use [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases).
- And many more internal fixes for a more robust and clean code.

## [2.5] - 2026-02-28
### Installation QoL:
- **Config detection**: Reinstalling now detects an existing configuration and lets you keep it, skipping the full setup flow.
- **Whitelist preservation**: Doze whitelist is backed up and restored automatically on update.
### WebUI Improvements:
- **Scrollbar removed**: Page scrollbar is now fully hidden for a cleaner look.
- **Pull to refresh**: Fixed incorrectly triggering while scrolling inside the whitelist editor.
- **Whitelist icon loading**: Icons now pre-load further ahead and decode off the main thread, significantly reducing blank icons when scrolling fast.
- **Action buttons**: Freeze All / Revert All redesigned to be more compact with bolder text.
- **Added version badge**: Header now displays the current installed module version.
- **Interaction polish**: Text selection disabled on header, icons, and buttons to prevent accidental highlight on tap (thanks again @xizt159 for the fix!). 
> [!NOTE]
> **Magisk users can use [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases)**

## [2.4] - 2026-02-27
- **WebUI overhaul**: Adopted KSU dynamic color system so the UI now follows your device's Material You wallpaper palette. With much better fluidity now.
- **System Props are now optional**: user is prompted during installation and can toggle them via WebUI or action button. With update safe detection and better logging.
- **Installation improvements**: All tweak descriptions rewritten to describe user facing effects rather than technical internals.

## [2.3] - 2026-02-26
- **Added KSU v3 WebUI**: Full configuration interface with live toggles, immediate apply/revert for all settings, Deep Doze whitelist editor with session activity log. Magisk users can use [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases).
- **Cloud category adjustment**: Now holds all the critical API broker services that can affect Autofill, Smart Lock, and Google Sign-in. Defaulting to SKIP for more overall usability.
- **Background and Wearables categories fixes**: moved some services where they logically belong.
- **Screen monitor polling intervals increased**: 90s when screen on (was 60s), 180s for fallback/waiting (was 120s). Reduces CPU wakeups.
- Wakelock killer now checks process state before force stopping it, to avoid disrupting foreground apps like music, navigation. With better fallback for other roms.
- Moved RC overlays and bin stubs to `post-fs-data.sh` for more robust early-stage work. They are now created following user's choice, log killing is easily reverted on reboot.
- Kernel values are backed up on every boot instead of being skipped if a backup already exists, ensuring restore always reflects pre-tweak values from the current session.
- **Reworked `system.prop` tweaks**.
- **Many more fixes and adjustments to improve overall functionality**.

## [2.2] - 2026-02-16
- **GPS fix**: GMS Doze is now location-aware, when Location category is skipped, GMS stays in the deviceidle whitelist so Fused Location Provider can serve GPS to apps. XML patches still reduce battery drain without breaking location. Also fixed action button not re-enabling its services.
- **Deep Doze protects GMS when location is active**: GMS is automatically whitelisted from background restrictions when user chose not to freeze location.
- **GMS cache clearing**: Improved behavior. Now only clears GMS's own cache and code_cache directories.
- **Harmful system.prop entries removed**
- **XML patching**: Now uses fixed string matching (`grep -F`) instead of fragile regex with embedded quotes.
- **Whitelist matching**: Comments, trailing whitespace, and inline comments in `doze_whitelist.txt` are now properly stripped before matching.
- **Doze constants**: Split to two presets: Moderate and Maximum.
- **Kernel backup/restore**: All kernel values are backed up before tweaking. Stock mode via action button now instantly restores original values instead of requiring a reboot.
- **Screen monitor hardened**: Falls back to longer sleep intervals when display service is unavailable instead of rapid-cycling. Better clean shutdown.
- And many more fixes.

## [2.1] - 2026-02-10
- Fixed some functions like sync, password manager, GPS not working properly even when their categories were skipped
- GMS doze now uses proper XML overlay patching
- Reorganized gms categories for better functionality
- Removed redundant tweaks
- Empty RC file overlays are now properly applied when log killing is enabled

## [2.0] - 2026-02-03
- Implement system-wide dozing for all apps.
- Added more props and kernel tweaks.
- Reworked action button and overhauled scripts.

## [1.0] **Initial release** - 2026-02-02
- Added **GMS Doze Integration** based on [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze) by gloeyisk. Patches system XMLs to allow Android Doze to optimize GMS battery usage.

- Reorganized Google services categories:
  • 📊 Telemetry (Ads, Analytics, Tracking)
  • 🔄 Background (Updates, Chimera, MDM)
  • 📍 Location (GPS, Geofence, Activity Recognition)
  • 📡 Connectivity (Cast, Quick Share, Nearby)
  • ☁️ Cloud (Auth, Sync, Backup)
  • 💳 Payments (Google Pay, Wallet, NFC)
  • ⌚ Wearables (Wear OS, Google Fit)
  • 🎮 Games (Play Games, Achievements)

- Overhauled system tweaks:
  • Kernel optimizations (Scheduler, VM, Network)
  • UI Blur disable option
  • Log process killing (logcat, logd, traced, etc.)
  • Empty RC file overlays for debug daemons

- Added action button to toggle between Frozen and Stock modes
- Improved logging with better error handling throughout all scripts.
- Cleaner uninstall process with proper restoration of changes.
