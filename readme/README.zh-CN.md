<div align="center">

# 🧊 FROSTY

### GMS 冻结与省电模块

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ 功能](#-功能) • [📦 安装](#-安装) • [📖 使用方法](#-使用方法) •[🧊 GMS 分类](#-gms-分类) • [❓ 常见问题](#-常见问题)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • 🇨🇳 中文  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## 概述

Frosty 通过选择性冻结 Google 移动服务（GMS）组件并应用系统级 Doze 省电增强，来优化您的电池续航。安装后，一切都可以通过 WebUI 进行配置。

## ✨ 功能

- **GMS 冻结**：将 GMS 服务划分为 8 个类别，提供精细的禁用控制。
- **GMS Doze**：将 GMS 从系统省电白名单（Whitelist）中移除。
- **深度休眠 (Deep Doze)**：对所有应用实施极其激进的后台限制（适中 / 最大模式）。
- **内核调优 (Kernel Tweaks)**：调度器 (Scheduler)、虚拟机 (VM) 和网络优化。
- **RAM 优化器**：调整进程限制和 sysfs 内存设置。
- **终止日志 (Kill Logs)**：停止耗电且占用 RAM 的后台日志记录进程。
- **系统属性 (System Props)**：禁用系统调试属性以节省更多的 RAM。
- **省电模式调优 (Battery Saver Tuner)**：自定义 Android 省电模式的行为，控制备份推迟、传感器禁用、GPS 行为、流量节省等。这些设置仅在 Android 系统的省电模式开启时才会生效。
- **实时配置**：通过 WebUI 上的开关实现实时生效的完全控制。

## 📦 安装

**要求:** Android 9+，最新版 Magisk (20.4+) / KernelSU / APatch，Google Play 服务。

1. 从 [Releases 页面](https://github.com/Drsexo/Frosty/releases) 下载模块。
2. 通过您的 Root 管理器进行安装。
3. 重启设备。
4. 打开 WebUI 启用所需功能 —— 默认情况下所有功能均为**关闭**状态。

> [!NOTE]
> Magisk 用户可以使用 [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) 应用程序来访问 WebUI 界面。

## 📖 使用方法

从您的 Root 管理器中打开 WebUI。您会发现：

- **系统优化 (System Tweaks)** — 启用内核调优 (Kernel Tweaks)、系统属性 (System Props)、禁用模糊 (Blur) 以及终止日志 (Kill Logs)。
- **GMS Doze / Deep Doze** — 配置 Doze 省电模式的激进程度。
- **GMS 分类** — 逐个组别地冻结 GMS 服务。
- **白名单 (Whitelist)** — 保护重要应用免受深度休眠 (Deep Doze) 的限制。
- **导入 / 导出** — 备份和恢复您的配置。

## 🧊 GMS 分类

#### 安全禁用
| 分类 | 影响 |
|------|------|
| 📊 **遥测 (Telemetry)** | 无。阻止 Google 广告、数据分析和追踪。 |
| 🔄 **后台 (Background)** | 应用自动更新可能会出现延迟。 |

#### 将会失效的功能
| 分类 | 受到影响的功能 |
|------|----------------|
| 📍 **位置 (Location)** | 谷歌地图、GPS 导航、查找我的设备。 |
| 📡 **连接 (Connectivity)** | Chromecast、快速分享 (Quick Share)、快速配对 (Fast Pair)。 |
| ☁️ **云端 (Cloud)** | Google 账号登录、密码自动填充、备份。 |
| 💳 **支付 (Payments)** | Google Pay、NFC 非接触式支付。 |
| ⌚ **穿戴设备 (Wearables)** | Wear OS、Google Fit、健身追踪。 |
| 🎮 **游戏 (Games)** | Google Play 游戏成就、排行榜、云存档。 |

## 🔋 深度休眠 (Deep Doze) 级别

| 功能 | 适中 | 最大 |
|------|:----:|:----:|
| 激进的 Doze 常量 | ✅ | ✅ |
| App Standby Buckets (应用待机群组) | ✅ | ✅ |
| 拒绝 RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (熄屏时深度空闲) | ✅ | ✅ |
| 拒绝 WAKE_LOCK (唤醒锁) | ❌ | ✅ |
| Wakelock 拦截 (Wakelock Killer) | ❌ | ✅ |

## 🚀 RAM 优化器

根据您设备的总 RAM 容量，调整 Android 的进程管理器和内存子系统。  
此外，还会启用 USAP 进程池以加快应用的冷启动速度，并应用 sysfs 内存调优（`swappiness`、`page-cluster`）。在禁用该功能时，所有值都会从备份中完全恢复。

## ⚙️ 省电模式调优

配置 Android 内置省电模式处于激活状态时的具体行为。

| 选项 | 描述 |
|--------|-------------|
| **流量节省 (Data Saver)** | 限制大多数应用的后台数据使用 |
| **语音唤醒 (Sound Trigger)** | 禁用唤醒词检测（例如 "Hey Google"） |
| **完整备份 (Full Backup)** | 推迟设备的完整备份 |
| **数据备份 (Key/Value Backup)** | 推迟应用设置和键值数据的备份 |
| **强制待机 (Force Standby)** | 立即将所有后台应用置于待机状态 |
| **后台检查 (Background Check)** | 对后台进程执行更严格的运行检查 |
| **传感器 (Sensors)** | 在后台禁用非关键的传感器 |
| **定位模式 (GPS Mode)** | 控制省电模式激活时的位置访问权限 |

## ❓ 常见问题 (FAQ)

**问：为什么我的通知延迟了？**  
答：GMS Doze 和深度休眠 (Deep Doze) 会大幅限制后台活动。请务必将您的即时通讯应用添加到白名单 (Whitelist) 中。

**问：此模块在没有 Google Play 服务的情况下能工作吗？**  
答：可以。内核调优、系统属性、禁用模糊、终止日志和深度休眠在没有 GMS 的情况下依然有效。

## 📝 Doze 白名单 (Whitelist)

通过 WebUI 或直接修改 `/data/adb/modules/Frosty/config/doze_whitelist.txt` 文件来编辑列表。  
请将微信、QQ、银行类应用和闹钟添加至此，以防错过关键通知。

## 🙏 鸣谢

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)