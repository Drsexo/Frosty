# Changelog
All notable changes to this project will be documented in this file.

---

# 🚀 Frosty v[3.0] — HyperOS, Smart Kernel & GPS Overhaul - 2026-02-13

## 🔥 Major Improvements

### ✅ Official HyperOS Support
- Automatic detection of HyperOS / MIUI 14+.
- Protection for Xiaomi critical services (location, connectivity, wearables).
- Adjusted Doze timings to avoid conflicts with HyperOS power management.

### 🧠 Smart GKI Kernel Optimisation
- Automatic kernel backup before applying tweaks.
- Conflict detection (skips tweaks if already optimised).
- New `frosty.sh stock` restore mode.
- Safe governor check before applying `schedutil`.

### 🔋 Battery & Thermal Optimisation
- Non-essential wakelock cleanup.
- Repetitive alarm restrictions (GMS, WhatsApp, MIUI).
- Faster Doze entry through adjusted `device_idle_constants`.

---

## 📂 GMS Category System Rework
- Location services protection when `DISABLE_LOCATION=0`.
- Smart category detection with `should_disable_category()`.
- Deep Doze level awareness (`moderate` / `maximum`).
- Reorganised whitelist with clear user app section.
- Better support for:
  - Payments (Google Pay / NFC)
  - Wear OS / Google Fit
  - Quick Share / Nearby Share
  - Xiaomi services (HyperOS compatibility)

---

# 📍 GPS Optimisation for HyperOS / MIUI

### 🔄 Intelligent `gps.conf` Replacement
- Detects if already optimised (avoids unnecessary overwrite).
- Automatic backup before modification.
- Based on [ianhughes74](https://xdaforums-com.translate.goog/t/magisk-module-step-by-step-definitive-gps-solution-global.3695769/?_x_tr_sl=auto&_x_tr_tl=es&_x_tr_hl=es-419&_x_tr_pto=tc):
  - XTRA 3.0 over HTTPS
  - SUPL 3.0 global servers
  - Global NTP pools
  - HyperOS default compatibility

### 🎯 GPS Improvements
- Faster satellite lock.
- Better urban positioning accuracy.
- Reduced battery drain.
- Full compatibility with GPS Locker and banking apps.

### 📜 Detailed Logging
- Logs replacement decisions.
- Includes contributor credits.

---

# 💥 Why 3.0 Makes Sense
Because this release:

- Changes kernel behaviour logic
- Rewrites GMS handling
- Introduces category intelligence
- Adds HyperOS native support
- Overhauls GPS handling safely
- Refactors scripts structurally


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