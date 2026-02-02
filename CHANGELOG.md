# Changelog
All notable changes to this project will be documented in this file.

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