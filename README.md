<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

</div>

## Overview

Frosty optimizes battery life by selectively freezing Google Mobile Services (GMS) components and applying system-wide doze enhancements. Choose exactly which features to keep or disable.

Based on [GhostGMS](https://github.com/kaushikieeee/GhostGMS) by kaushikieeee.

## Features

- **GMS Freezing**: Disable GMS services across 8 categories with granular control  
- **GMS Doze**: Remove GMS from power-save whitelists so Android can optimize it  
- **Deep Doze**: Aggressive background restrictions for all apps (Moderate/Maximum)  
- **Kernel Tweaks**: Scheduler, VM, network, and debug optimizations  
- **Log Killing**: Stop battery-draining log/debug processes  
- **Live Configuration**: Using WebUI or Action button  

## Installation

**Requirements:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services

1. Download from [Releases](https://github.com/Drsexo/Frosty/releases)
2. Install via root manager
3. Configure with volume keys during installation
4. Reboot

## GMS Categories

#### Safe to Disable
| Category | Impact |
|----------|--------|
| 📊 **Telemetry** | None. Stops ads, analytics, tracking. |
| 🔄 **Background** | Auto-updates may be delayed. |

#### May Break Features
| Category | What Breaks |
|----------|-------------|
| 📍 **Location** | Maps, navigation, Find My Device, location sharing |
| 📡 **Connectivity** | Chromecast, Quick Share, Fast Pair |
| ☁️ **Cloud** | Google Sign-in, Autofill, passwords, backup |
| 💳 **Payments** | Google Pay, NFC tap-to-pay |
| ⌚ **Wearables** | Wear OS, Google Fit, fitness tracking |
| 🎮 **Games** | Play Games achievements, leaderboards, cloud saves |

## Deep Doze Levels

| Feature | Moderate | Maximum |
|---------|:--------:|:-------:|
| Aggressive Doze Constants | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Deny RUN_IN_BACKGROUND | ✅ | ✅ |
| Screen-off Deep Idle | ✅ | ✅ |
| Deny WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |
| Alarm Restrictions | ❌ | ✅ |

## Configuring options

**During Installation:** Use Vol Up / Vol Down to configure each option.

**After Installation:**
- **Action Button**: Toggle Frozen ↔ Stock
- **WebUI**: Live toggles, whitelist editor, activity log
> Note: Magisk users can use [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases)

## Doze Whitelist

Edit `/config/doze_whitelist.txt` or use the WebUI whitelist editor to exclude apps from Deep Doze restrictions.  
Add messaging, banking, and alarm apps to prevent missed notifications.

## Credits

- **kaushikieeee** - [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** - [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** - [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** - [GMS Component Disable Script](https://t.me/MoZoiDStack/137)