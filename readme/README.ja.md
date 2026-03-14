<div align="center">

# 🧊 FROSTY

### GMS 凍結＆バッテリー節約

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ 機能](#-機能) • [📦 インストール](#-インストール) • [📖 使い方](#-使い方) • [🧊 GMS カテゴリ](#-gms-カテゴリ) • [❓ よくある質問](#-よくある質問)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
🇯🇵 日本語 • [🇸🇦 العربية](README.ar.md)

</div>

## 概要

Frosty は、Google モバイルサービス (GMS) コンポーネントを選択的に凍結し、システム全体に Doze（省電力モード）の強化を適用することでバッテリー寿命を最適化します。インストール後は、すべて WebUI 経由で設定します。

## ✨ 機能

- **GMS 凍結**：GMS サービスを 8 つのカテゴリに分け、きめ細かく制御・無効化。
- **GMS Doze**：GMS をバッテリー最適化の除外リスト（ホワイトリスト）から削除。
- **ディープスリープ (Deep Doze)**：すべてのアプリに対して極めて強力なバックグラウンド制限を適用（中程度 / 最大）。
- **カーネル調整 (Kernel Tweaks)**：スケジューラ (Scheduler)、仮想メモリ (VM)、ネットワークの最適化。
- **RAM オプティマイザ**: プロセス制限と sysfs メモリ設定を調整します。
- **ログ停止 (Kill Logs)**：バッテリーと RAM を消費するバックグラウンドのログプロセスを強制停止。
- **システムプロパティ (System Props)**：デバッグ用プロパティを無効化し、RAM をさらに節約。
- **バッテリーセーバーチューナー**: Android のバッテリーセーバーモードの動作をカスタマイズし、バックアップの延期、センサーの無効化、GPS の動作、データセーバーなどを制御します。これらの設定は、Android のバッテリーセーバーが「オン」のときにのみ機能します。
- **リアルタイム設定**：WebUI のスイッチ操作により、リアルタイムで完全に制御可能。

## 📦 インストール

**必須要件:** Android 9 以上、最新の Magisk (20.4+) / KernelSU / APatch、Google Play 開発者サービス。

1. [Releases ページ](https://github.com/Drsexo/Frosty/releases) からモジュールをダウンロードします。
2. ご利用の Root マネージャー経由でインストールします。
3. デバイスを再起動します。
4. WebUI を開いて機能を有効化します — デフォルトではすべて **オフ** になっています。

> [!NOTE]
> Magisk ユーザーは、[WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) アプリを使用して WebUI にアクセスできます。

## 📖 使い方

Root マネージャーから WebUI を開きます。以下の機能があります：

- **システム調整 (System Tweaks)** — カーネル調整、システムプロパティ、ブラーの無効化、ログ停止をオンにします。
- **GMS Doze / ディープスリープ** — Doze モードの制限レベルを設定します。
- **GMS カテゴリ** — GMS サービスのグループを個別に凍結します。
- **ホワイトリスト (Whitelist)** — 重要なアプリをディープスリープの強力な制限から保護します。
- **インポート / エクスポート** — 設定のバックアップと復元を行います。

## 🧊 GMS カテゴリ

#### 安全に無効化可能
| カテゴリ | 影響 |
|----------|------|
| 📊 **テレメトリ (Telemetry)** | なし。広告、分析、Google による追跡をブロックします。 |
| 🔄 **バックグラウンド** | アプリの自動更新が遅れる場合があります。 |

#### 動作しなくなる機能
| カテゴリ | 影響を受ける機能 |
|----------|------------------|
| 📍 **位置情報 (Location)** | Google マップ、GPS ナビ、デバイスを探す。 |
| 📡 **接続 (Connectivity)** | Chromecast、クイック共有 (Quick Share)、ファストペアリング。 |
| ☁️ **クラウド (Cloud)** | Google ログイン、パスワードの自動入力、バックアップ。 |
| 💳 **決済 (Payments)** | Google Pay、NFC コンタクトレス決済。 |
| ⌚ **ウェアラブル** | Wear OS、Google Fit、フィットネス追跡。 |
| 🎮 **ゲーム (Games)** | Google Play ゲームの実績、リーダーボード、クラウドセーブ。 |

## 🔋 ディープスリープ (Deep Doze) レベル

| 機能 | 中程度 | 最大 |
|------|:------:|:----:|
| 強力な Doze 定数 | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| RUN_IN_BACKGROUND を拒否 | ✅ | ✅ |
| 画面オフ時のディープアイドル | ✅ | ✅ |
| WAKE_LOCK を拒否 | ❌ | ✅ |
| Wakelock ブロッカー | ❌ | ✅ |

## 🚀 RAM オプティマイザ

デバイスの合計 RAM に基づいて、Android のプロセスマネージャーとメモリサブシステムを調整します。  
また、アプリのコールドスタートを高速化するために USAP プールを有効化し、sysfs 調整（`swappiness`、`page-cluster`）を適用します。すべての値はバックアップされ、無効化時に完全に復元されます。

## ⚙️ バッテリーセーバーチューナー

Android 内蔵のバッテリーセーバーモードが有効な場合の動作を設定します。

| オプション | 説明 |
|--------|-------------|
| **データセーバー** | ほとんどのアプリのバックグラウンドデータ通信を制限します |
| **音声検出 (Sound Trigger)** | ホットワード検出（「OK Google」など）を無効にします |
| **完全バックアップ** | デバイスの完全バックアップを延期します |
| **データバックアップ** | Key-Value（アプリ設定など）のバックアップを延期します |
| **スタンバイを強制** | すべてのバックグラウンドアプリを即座にスタンバイ状態にします |
| **バックグラウンドチェック** | バックグラウンドプロセスに対してより厳格なチェックを適用します |
| **センサー** | バックグラウンドで不要なセンサーを無効にします |
| **GPS モード** | バッテリーセーバー有効時の位置情報へのアクセスを制御します |

## ❓ よくある質問 (FAQ)

**Q: 通知が遅れて届くのはなぜですか？**  
A: GMS Doze とディープスリープにより、バックグラウンドでの活動が大幅に制限されるためです。メッセージアプリ（LINE など）は必ずホワイトリストに追加してください。

**Q: このモジュールは Google Play 開発者サービスがなくても動作しますか？**  
A: はい。カーネル調整、システムプロパティ、ブラー無効化、ログ停止、ディープスリープは GMS なしでも動作します。

## 📝 Doze ホワイトリスト (Whitelist)

WebUI 上でリストを編集するか、`/data/adb/modules/Frosty/config/doze_whitelist.txt` を直接編集してください。  
重要な通知を見逃さないように、メッセージアプリ、銀行アプリ、アラームアプリをここに追加してください。

## 🙏 クレジット

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)