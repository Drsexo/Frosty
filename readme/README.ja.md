<div align="center">

# 🧊 FROSTY

### GMS無効化＆バッテリーセーバー

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[機能](#機能) • [インストール](#インストール) • [使い方](#使い方) • [GMSカテゴリー](#gmsカテゴリー) • [FAQ](#よくある質問-faq)

---

[🇬🇧 English](https://github.com/Drsexo/Frosty) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
🇯🇵 日本語 • [🇸🇦 العربية](README.ar.md)

</div>

## 概要

Frostyは、GMSサービスの凍結、システム全体のDoze機能の強化、画面オフ時の動作の自動化により、バッテリー寿命を最適化します。すべての設定はWebUIから行えます。

## 機能

- **GMSの凍結**: 8つのカテゴリーにわたってGMSサービスを無効化します。
- **アプリDoze**: AndroidのDoze省電力除外リストから任意のアプリを削除します。GMSもここで選択でき、従来の専用GMS Dozeスイッチの代わりとなります。
- **ディープDoze**: すべてのアプリに対して積極的なバックグラウンド制限を行います (中程度 / 最大)。
- **画面オフ時の最適化**: 画面オフ後、設定した遅延時間で選択した接続 (Wi-Fi、Bluetooth、データ、位置情報) を自動的に無効にし、キャッシュされたアプリをクリアします。ロック解除時にすべて復元されます。
- **Googleトラッキングをブロック**: GMSアナリティクス、Clearcutテレメトリ、Phenotypeポーリング、および広告トラッキングを無効にします。
- **カーネル調整**: スケジューラ、VM、ネットワーク、デバッグの最適化。
- **RAMオプティマイザー**: プロセス制限、メモリの圧縮、およびzramの動作を調整します。
- **システムプロパティ**: デバッグプロパティを無効にしてRAMとバッテリーを節約します。
- **ログの停止**: バッテリーを消費するログとデバッグプロセスを停止します。
- **バッテリーセーバーチューナー**: Androidに組み込まれているバッテリーセーバーがアクティブになった際の動作をカスタマイズします。

## インストール

**要件:** Android 9以上、Magisk 20.4+ / KernelSU / APatch、Google Play 開発者サービス (GMS)

1. [Releases](https://github.com/Drsexo/Frosty/releases) からダウンロードします。
2. Rootマネージャー経由でインストールします。
3. 再起動します。
4. WebUIを開いて機能を有効にします。

> [!NOTE]
> Magiskユーザーは、[WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases)を使用してWebUIにアクセスできます。

## 使い方

RootマネージャーからWebUIを開きます：

- **システム調整**: カーネル調整、システムプロパティ、ブラー無効化、ログの停止、トラッキングのブロック。
- **Doze**: アプリピッカー付きの「アプリDoze」、レベル選択とホワイトリストエディタ付きの「ディープDoze」。
- **画面オフ時の最適化**: 接続ごとのスイッチ、遅延タイマー、ロック解除時の復元。
- **GMSカテゴリー**: GMSサービスの個々のグループを凍結します。
- **バッテリーセーバーチューナー**: バッテリーセーバーの動作を細かく調整します。
- **インポート / エクスポート**: すべての構成をバックアップおよび復元します。

## GMSカテゴリー

#### 安全に無効化可能
| カテゴリー | 影響 |
|----------|--------|
| 📊 **テレメトリ** | なし。広告、アナリティクス、トラッキングを停止します。 |
| 🔄 **バックグラウンド** | 自動アップデートが遅れる場合があります。 |

#### 機能が損なわれる可能性あり
| カテゴリー | 影響を受ける機能 |
|----------|-------------|
| 📍 **位置情報** | マップ、ナビゲーション、デバイスを探す、現在地の共有 |
| 📡 **接続性** | Chromecast、クイック共有、ファストペアリング |
| ☁️ **クラウド** | Googleサインイン、自動入力、パスワード、バックアップ |
| 💳 **支払い** | Google Pay、NFCタッチ決済 |
| ⌚ **ウェアラブル** | Wear OS、Google Fit、フィットネストラッキング |
| 🎮 **ゲーム** | Play ゲームの実績、リーダーボード、クラウドセーブ |

## ディープDoze レベル

| 機能 | 中程度 | 最大 |
|---------|:--------:|:-------:|
| 積極的なDoze定数 | ✅ | ✅ |
| App Standby Buckets (まれ) | ✅ | ✅ |
| 画面オフ時のWakelockキラー | ✅ | ✅ |
| WAKE_LOCKの拒否 | ❌ | ✅ |

## よくある質問 (FAQ)

**Q: 通知が遅れるのはなぜですか？**  
A: アプリDozeとディープDozeはバックグラウンド活動を制限します。メッセージアプリをWebUIのディープDozeホワイトリストに追加してください。

**Q: GMS Dozeはどこへ行きましたか？**  
A: 現在は「アプリDoze」の一部です。アプリDozeピッカーを開き、GMSを選択してください。統合されたUIで同じ効果が得られます。

**Q: Google Play 開発者サービスがなくても機能しますか？**  
A: カーネル調整、システムプロパティ、ブラー無効化、ログの停止、RAMオプティマイザー、およびディープDozeはすべて機能します。GMS機能は当然GMSを必要とします。

**Q: インストール後にデフォルトで有効になっているものはありますか？**  
A: いいえ。デフォルトではすべてオフになっています。必要なものだけを有効にしてください。

## クレジット

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)

## ライセンス

**GPL v3** の下でライセンスされています。[LICENSE](LICENSE) を参照してください。  
**Frosty** という名前は公式リリース専用に予約されています。フォーク(派生版)では異なる名前を使用し、非公式であることを明記する必要があります。原作者は、非公式バージョンまたは変更されたバージョンによって生じた損害について一切の責任を負いません。
