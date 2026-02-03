<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

*Maximum battery optimization through intelligent Google Mobile Services management*

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Total downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Categories](#-gms-categories) • [FAQ](#-faq)

</div>

## 📖 Overview

**Frosty** is an advanced Magisk/KernelSU/APatch module that optimizes your Android device by selectively freezing unnecessary Google Mobile Services (GMS) components and enabling deep battery optimization.

Unlike other optimizers, Frosty gives you **granular control** over which service categories to disable, allowing you to balance battery savings with functionality.

**Based on the work of [GhostGMS](https://github.com/kaushikieeee/GhostGMS)**

### Why Frosty?

- 🔋 **Massive Battery Savings** - Disable power-hungry GMS services that run 24/7
- 💤 **Doze Integration** - Force Android to optimize all apps including GMS to improve battery
- 🎯 **Selective Control** - Choose exactly which features to keep or freeze
- ⚡ **Kernel Optimizations** - Optional scheduler, VM, and network tweaks
- 🔄 **Fully Reversible** - Toggle between Frozen and Stock modes instantly
- 📊 **Detailed Logging** - Know exactly what's happening on your device


## ✨ Features

### 🧊 GMS Service Freezing
Disable Google services organized into 8 logical categories:
- **Telemetry** - Ads, analytics, tracking (safe to disable)
- **Background** - Updates, background sync (safe to disable)
- **Location** - GPS, geofencing, activity recognition
- **Connectivity** - Chromecast, Quick Share, Nearby
- **Cloud** - Backup, sync, authentication
- **Payments** - Google Pay, Wallet, NFC
- **Wearables** - Wear OS, Google Fit
- **Games** - Play Games achievements, cloud saves

### 💤 GMS Doze
Based on [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze) by gloeyisk:
- **XML Patching** - Removes GMS from power-save whitelists
- **DeviceIdle Integration** - Allows Android Doze to optimize GMS
- **Conflict Resolution** - Patches other modules that whitelist GMS
- **Toggleable** - Enable/disable with the action button

### 🔋 Deep Doze
Based on [DeepDoze enforcer](https://github.com/Azyrn/DeepDoze-Enforcer) by Azyrn:
- **Deep Sleep Enforcement** - Forces the device into deep sleep immediately when the screen locks.
- **Background Restrictions** - Blocks apps from running in the background to stop battery-draining loops.
- **WAKE_LOCK Denial** - Denies WAKE_LOCK permissions to block useless CPU-heavy wakelocks.

### ⚡ System Optimizations
- **Kernel Tweaks** - Scheduler, VM, and network optimizations
- **Blur Disable** - Reduce GPU load by disabling UI blur effects
- **Log Killing** - Stop battery-draining log processes (logcat, traced, etc.)
- **Empty RC Files** - Overlay system init scripts to prevent debug daemons

### 📱 User Experience
- **Volume Key Selection** - Easy installation choices
- **Action Button Toggle** - Switch modes from root manager
- **Comprehensive Logs** - Detailed logs in `/data/adb/modules/Frosty/logs/`
- **Status Report** - Quick status check via terminal
- **Clean Uninstall** - Complete reversal of all changes


## 📥 Installation

### Requirements
- Android 9.0+ (API 28+)
- Magisk 20.4+ / KernelSU / APatch
- Google Play Services installed

### Steps

1. **Download** the latest release from [Releases](https://github.com/Drsexo/Frosty/releases)

2. **Install** via your root manager:
   - Magisk: Modules → Install from storage
   - KernelSU: Module → Install
   - APatch: Module → Install

3. **Configure** during installation:
   - Use **Volume Up** = YES / FREEZE
   - Use **Volume Down** = NO / SKIP   

4. **Reboot** to apply changes


## 🎮 Usage

### During Installation

You'll be prompted to configure:

**System Tweaks:**
| Option | Description | Default |
|--------|-------------|---------|
| 🔧 Kernel Tweaks | Scheduler, VM, network optimizations | YES |
| 🎨 Blur Disable | Disable UI blur effects | NO |
| 📝 Log Killing | Kill logging processes | YES |

**System Tweaks:**
| Option | Description | Default |
|--------|-------------|---------|
| 🔧 Kernel Tweaks | Scheduler, VM, network optimizations | YES |
| 🎨 Blur Disable | Disable UI blur effects | NO |
| 📝 Log Killing | Kill logging processes | YES |

**Deep Doze levels:**
| Feature | MODERATE |  MAXIMUM |
| :-------------------------- | :------: | :------: |
| Aggressive Doze Constants | ✅ |     ✅ |
| App Standby Buckets (restricted) | ✅ | ✅ |
| Appops: Deny `RUN_IN_BACKGROUND` | ✅ | ✅ |
| Appops: Deny `WAKE_LOCK` | ❌ | ✅ |
| Network Lockdown (disable sync/push) | ❌ | ✅ |
| Sensor Freeze (stop sensor-triggered wakeups) | ❌ | ✅ |
| Wakelock Killer (force-stop persistent wakelocks) | ❌ | ✅ |
| Alarm Restrictions | ❌ | ✅ (safe) |

**GMS Doze:**
| Option | Description | Default |
|--------|-------------|---------|
| 💤 GMS Doze | Enable GMS battery optimization | YES |
| 🗑️ Clear GMS Cache | Fix delayed notifications | NO |

**GMS Categories:**
| Category | What it affects | Default |
|----------|-----------------|---------|
| 📊 Telemetry | Ads, tracking, analytics | FREEZE |
| 🔄 Background | Updates, sync services | FREEZE |
| 📍 Location | Maps, navigation, geofence | FREEZE |
| 📡 Connectivity | Cast, Quick Share, Nearby | FREEZE |
| ☁️ Cloud | Sign-in, backup, autofill | FREEZE |
| 💳 Payments | Google Pay, NFC payments | FREEZE |
| ⌚ Wearables | Wear OS, Google Fit | FREEZE |
| 🎮 Games | Play Games, achievements | FREEZE |

### After Installation

**Toggle Modes (Action Button):**
1. Open your root manager (Magisk/KernelSU/APatch)
2. Find Frosty module
3. Tap the action/execute button
4. Press **Vol+** for 🧊 Frozen or **Vol-** for 🔥 Stock


## 📂 Log Files

All logs are stored in `/data/adb/modules/Frosty/logs/`:

| File | Contents |
|------|----------|
| `boot.log` | Boot sequence events |
| `services.log` | GMS service freeze/enable results |
| `tweaks.log` | Kernel tweaks applied |
| `doze.log` | GMS Doze operations |
| `action.log` | Action button history |


## 🧊 GMS Categories

### Safe to Disable
| Category | Services | Impact |
|----------|----------|--------|
| **Telemetry** | Ads, Analytics, Clearcut, Tron | None - just stops tracking |
| **Background** | Chimera, Updates, MDM | May delay app updates |

### May Break Features
| Category | Services | What Breaks |
|----------|----------|-------------|
| **Location** | Fused Location, Geofence | Maps, Navigation, Find My Device |
| **Connectivity** | Cast, Nearby, Quick Share | Chromecast, file sharing |
| **Cloud** | Auth, Backup, Sync | Google Sign-in, backups |
| **Payments** | Tap and Pay, Wallet | Google Pay, NFC payments |
| **Wearables** | Fitness, Wearable | Smartwatch sync, Google Fit |
| **Games** | Play Games | Achievements, cloud saves |


## ❓ FAQ

### Q: My notifications are delayed after enabling GMS Doze
**A:** This is expected. GMS Doze allows Android to optimize GMS battery usage, which may slightly delay push notifications. If this is a problem: **disable GMS Doze during installation**.

### Q: Google Maps doesn't work
**A:** You froze the Location category. Use the action button to switch to Stock mode, or reinstall and skip the Location category.

### Q: Can I change settings after installation?
**A:** Yes! Simply reinstall the module and make different choices. Or use the action button to toggle between Frozen and Stock modes.

### Q: How do I know it's working?
**A:** Check the log files.

### Q: What's the difference between Frozen and Stock mode?
| Mode | Services | Doze | Kernel Tweaks |
|------|----------|----------|---------------|
| 🧊 Frozen | Disabled per config | Active | Applied |
| 🔥 Stock | All enabled | Inactive | Reverted after reboot |


## 📜 Credits

- **kaushikieeee** - [GhostGMS](https://github.com/kaushikieeee/GhostGMS) - Good base
- **gloeyisk** - [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze) - GMS Doze implementation
- **MoZoiD** - [GMS Component Disable Script](https://t.me/MoZoiDStack/137) - Few unique services
- **Azyrn** - [DeepDoze enforcer](https://github.com/Azyrn/DeepDoze-Enforcer) - Force doze concept