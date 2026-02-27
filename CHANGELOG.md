# Changelog
All notable changes to this project will be documented in this file.

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