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

<div align="center">
<img src="readme/images/en.png" width="600">
</div>

## Overview

Frosty optimizes battery life by freezing GMS services, applying system-wide doze enhancements, and automating screen-off behavior. Configure everything through the WebUI.

## Features

- **GMS Freezing**: Disable GMS services across 8 categories
- **App Doze**: Remove any app from Android's Doze power-save exemption list. GMS is selectable here too, replacing the old dedicated GMS Doze toggle
- **Deep Doze**: Aggressive background restrictions for all apps (Moderate / Maximum)
- **Screen Off Optimization**: Disable selected connections (Wi-Fi, Bluetooth, data, location) and optionally run the RAM cleaner after a configurable screen-off delay, restores on unlock
- **Kill Google Tracking**: Disables GMS analytics, Clearcut telemetry, Phenotype polling, and ad tracking
- **Kernel Tweaks**: Scheduler, VM, network, and debug optimizations
- **RAM Optimizer**: ZRAM auto-tuning, LMK/LMKD/PSI thresholds, OEM reclaim disabling, VM memory params (Moderate / Maximum), configurable RAM Cleaner, Multitasking Profile (Performance / Balanced / Power Saving)
- **System Props**: Disable debug properties to save RAM and battery
- **Log Killing**: Stop battery-draining log and debug processes
- **Battery Saver Tuner**: Customize what Android's built-in battery saver does when active, including an option to keep max refresh rate while it's on

## Installation

**Requirements:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services

1. Download from [Releases](https://github.com/Drsexo/Frosty/releases)
2. Install via your root manager
3. Reboot
4. Open the WebUI to enable features

> [!NOTE]
> Magisk users can use [KsuWebUI](https://github.com/KOWX712/KsuWebUIStandalone/releases) / [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) to access the WebUI.

> [!NOTE]
> On KernelSU/APatch, Frosty requests a hot install. If your manager supports it, refresh the WebUI after installing instead of rebooting. Reboot if anything looks off. Magisk always requires a reboot.

## Usage

Open the WebUI from your root manager:

- **System Tweaks**: kernel tweaks, system props, blur disable, log killing, tracking block, RAM optimizer and cleaner
- **Doze**: App Doze with app picker, Deep Doze with level selector and whitelist editor
- **Screen Off Optimization**: per-connection toggles, delay timers, restore on unlock
- **GMS Categories**: freeze individual GMS service groups, or use Enable all / Disable all to batch the ones not already in the state you want
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

Both levels rewrite Doze constants, force IDLE while the device is locked, run a 5-min wakelock killer once it's been locked that long, and enable JobScheduler flex-idle on Android 13+. Restrictions follow lock state, not screen state: checking the time or glancing at ambient display doesn't reset anything, only unlocking does. **Maximum** additionally uses the `restricted` standby bucket (Moderate uses `rare`), denies `WAKE_LOCK`, disables the motion sensor while locked, and kills wakelocks immediately on apply.

## RAM Optimizer

Auto-tunes ZRAM compression, LMK / LMKD / PSI thresholds, OEM reclaim nodes, and VM memory params. **Maximum** scales LMK weights up ~60-70% and uses more proactive LMKD/PSI thresholds. Multitasking Profile (Performance / Balanced / Power Saving) separately controls how many background apps ActivityManager keeps ready to resume instantly.

## FAQ

**Q: Why are my notifications delayed?**  
A: App Doze and Deep Doze restrict background activity. GMS/Firebase itself is whitelisted by default so push delivery stays intact, but third-party messaging apps still need to be added to the Deep Doze whitelist in the WebUI.

**Q: Where did GMS Doze go?**  
A: It's now part of App Doze. Open the App Doze picker and select GMS, same effect, unified interface.

**Q: Does this work without Google Play Services?**  
A: Kernel Tweaks, System Props, Blur Disable, Log Killing, RAM Optimizer and Cleaner, and Deep Doze all work. GMS features require GMS.

**Q: Is anything enabled after install?**  
A: No. Everything is off by default. Enable only what you need.

## Credits

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)
- [xizt158](https://github.com/xizt159) for many quality contributions

## License

Licensed under **GPL v3** see [LICENSE](LICENSE).  
The name **Frosty** is reserved for official releases only. Forks must use a different name and clearly state they are unofficial. The original author takes no responsibility for damage caused by unofficial or modified versions.
