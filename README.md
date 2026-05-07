<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Categories](#gms-categories) • [FAQ](#faq)

---

🇬🇧 English • [🇫🇷 Français](readme/README.fr.md) • [🇩🇪 Deutsch](readme/README.de.md)  
[🇵🇱 Polski](readme/README.pl.md) • [🇮🇹 Italiano](readme/README.it.md) • [🇪🇸 Español](readme/README.es.md)  
[🇧🇷 Português](readme/README.pt-BR.md) • [🇹🇷 Türkçe](readme/README.tr.md) • [🇮🇩 Indonesia](readme/README.id.md)  
[🇷🇺 Русский](readme/README.ru.md) • [🇺🇦 Українська](readme/README.uk.md) • [🇨🇳 中文](readme/README.zh-CN.md)  
[🇯🇵 日本語](readme/README.ja.md) • [🇸🇦 العربية](readme/README.ar.md)

</div>

## Overview

Frosty optimizes battery life by freezing GMS services, applying system-wide doze enhancements, and automating screen-off behavior. Configure everything through the WebUI.

## Features

- **GMS Freezing**: Disable GMS services across 8 categories
- **App Doze**: Remove any app from Android's Doze power-save exemption list. GMS is selectable here too, replacing the old dedicated GMS Doze toggle
- **Deep Doze**: Aggressive background restrictions for all apps (Moderate / Maximum)
- **Screen Off Optimization**: Automatically disables selected connections (Wi-Fi, Bluetooth, data, location) and clears cached apps after a configurable screen-off delay, then restores everything on unlock
- **Kill Google Tracking**: Disables GMS analytics, Clearcut telemetry, Phenotype polling, and ad tracking
- **Kernel Tweaks**: Scheduler, VM, network, and debug optimizations
- **RAM Optimizer**: Tunes process limits, memory compaction, and zram behavior
- **System Props**: Disable debug properties to save RAM and battery
- **Log Killing**: Stop battery-draining log and debug processes
- **Battery Saver Tuner**: Customize what Android's built-in battery saver does when active

## Installation

**Requirements:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services

1. Download from [Releases](https://github.com/Drsexo/Frosty/releases)
2. Install via your root manager
3. Reboot
4. Open the WebUI to enable features

> [!NOTE]
> Magisk users can use [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) to access the WebUI.

## Usage

Open the WebUI from your root manager:

- **System Tweaks**: kernel tweaks, system props, blur disable, log killing, tracking block
- **Doze**: App Doze with app picker, Deep Doze with level selector and whitelist editor
- **Screen Off Optimization**: per-connection toggles, delay timers, restore on unlock
- **GMS Categories**: freeze individual GMS service groups
- **Battery Saver Tuner**: fine-tune battery saver behavior
- **Import / Export**: back up and restore your full configuration

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
| App Standby Buckets (rare) | ✅ | ✅ |
| Screen-off Wakelock Killer | ✅ | ✅ |
| Deny WAKE_LOCK | ❌ | ✅ |

## FAQ

**Q: Why are my notifications delayed?**  
A: App Doze and Deep Doze restrict background activity. Add your messaging apps to the Deep Doze whitelist in the WebUI.

**Q: Where did GMS Doze go?**  
A: It's now part of App Doze. Open the App Doze picker and select GMS, same effect, unified interface.

**Q: Does this work without Google Play Services?**  
A: Kernel Tweaks, System Props, Blur Disable, Log Killing, RAM Optimizer, and Deep Doze all work. GMS features require GMS.

**Q: Is anything enabled after install?**  
A: No. Everything is off by default. Enable only what you need.

## Credits

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)

## License

Licensed under **GPL v3** see [LICENSE](LICENSE).  
The name **Frosty** is reserved for official releases only. Forks must use a different name and clearly state they are unofficial. The original author takes no responsibility for damage caused by unofficial or modified versions.
