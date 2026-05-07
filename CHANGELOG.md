# Changelog
## I am not responsible for any unofficial or tampered versions of my module distributed outside this repository.

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
