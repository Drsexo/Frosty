# Changelog

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