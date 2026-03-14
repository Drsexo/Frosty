<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Categories](#-gms-categories) • [FAQ](#-faq)

---

🇬🇧 English • [🇫🇷 Français](readme/README.fr.md) • [🇩🇪 Deutsch](readme/README.de.md)  
[🇵🇱 Polski](readme/README.pl.md) • [🇮🇹 Italiano](readme/README.it.md) • [🇪🇸 Español](readme/README.es.md)  
[🇧🇷 Português](readme/README.pt-BR.md) • [🇹🇷 Türkçe](readme/README.tr.md) • [🇮🇩 Indonesia](readme/README.id.md)  
[🇷🇺 Русский](readme/README.ru.md) • [🇺🇦 Українська](readme/README.uk.md) • [🇨🇳 中文](readme/README.zh-CN.md)  
[🇯🇵 日本語](readme/README.ja.md) • [🇸🇦 العربية](readme/README.ar.md)

</div>

## Overview

Frosty optimizes battery life by selectively freezing Google Mobile Services (GMS) components and applying system-wide doze enhancements. Configure everything through the WebUI after installation.

## ✨ Features

- **GMS Freezing**: Disable GMS services across 8 categories with granular control
- **GMS Doze**: Remove GMS from power-save whitelists so Android can optimize it
- **Deep Doze**: Aggressive background restrictions for all apps (Moderate/Maximum)
- **Kernel Tweaks**: Scheduler, VM, network, and debug optimizations
- **RAM Optimizer**: Tunes process limits and sysfs memory settings
- **Log Killing**: Stop battery-draining log/debug processes
- **System Props**: Disable debug properties to save RAM and battery
- **Battery Saver Tuner**: Customize what Android's battery saver mode does, control backup deferral, sensor disabling, GPS behavior, data saver, and more. They only have visible effect when Android battery saver is ON
- **Live Configuration**: Full control via WebUI with real-time toggles

## 📦 Installation

**Requirements:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services

1. Download from [Releases](https://github.com/Drsexo/Frosty/releases)
2. Install via your root manager
3. Reboot
4. Open WebUI to enable features — everything starts **OFF** by default

> [!NOTE]
> Magisk users can use [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) to access the WebUI.

## 📖 Usage

Open the WebUI from your root manager. You'll find:

- **System Tweaks** — toggle kernel tweaks, system props, blur disable, log killing
- **GMS Doze / Deep Doze** — configure doze aggressiveness
- **GMS Categories** — freeze individual GMS service groups
- **Whitelist Editor** — protect apps from Deep Doze
- **Import / Export** — back up and restore your configuration

## 🧊 GMS Categories

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

## 🔋 Deep Doze Levels

| Feature | Moderate | Maximum |
|---------|:--------:|:-------:|
| Aggressive Doze Constants | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Screen-off Deep Idle | ✅ | ✅ |
| Deny WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |

## 🚀 RAM Optimizer

Tunes Android's process manager and memory subsystem based on your device's total RAM.  
Also enables the USAP pool for faster cold app launches and applies sysfs tweaks (`swappiness`, `page-cluster`). All values are backed up and fully restored on disable.

## ⚙️ Battery Saver Tuner

Configures what Android's built-in battery saver mode does when active. 

| Option | Description |
|--------|-------------|
| **Data Saver** | Restrict background data for most apps |
| **Sound Trigger** | Disable hotword detection (e.g. "Hey Google") |
| **Full Backup** | Defer full device backups |
| **Key/Value Backup** | Defer key-value backups |
| **Force Standby** | Put all background apps in standby immediately |
| **Background Check** | Enforce stricter background process checks |
| **Sensors** | Disable optional sensors in background |
| **GPS Mode** | Control location access when battery saver is active |

## ❓ FAQ

**Q: Why are my notifications delayed?**  
A: GMS Doze and Deep Doze restrict background activity. Add your messaging apps to the whitelist.

**Q: Does this work without Google Play Services?**  
A: Kernel Tweaks, System Props, Blur Disable, Log Killing, and Deep Doze will work. GMS features require GMS.


## 📝 Doze Whitelist

Edit via WebUI or directly at `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Add messaging, banking, and alarm apps to prevent missed notifications.

## 🙏 Credits

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)