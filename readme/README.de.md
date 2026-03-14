<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Funktionen](#-funktionen) • [📦 Installation](#-installation) • [📖 Verwendung](#-verwendung) •[🧊 GMS-Kategorien](#-gms-kategorien) • [❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • 🇩🇪 Deutsch  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Übersicht

Frosty optimiert die Akkulaufzeit durch das selektive Einfrieren von Google Mobile Services (GMS)-Komponenten sowie durch systemweite Verbesserungen des Doze-Modus. Nach der Installation wird alles über die WebUI konfiguriert.

## ✨ Funktionen

- **GMS-Einfrieren**: Deaktivierung von GMS-Diensten in 8 Kategorien mit granularer Kontrolle.
- **GMS Doze**: Entfernt GMS aus der Energiespar-Whitelist (Ausnahmeliste).
- **Deep Doze**: Aggressive Hintergrundbeschränkungen für alle Apps (Moderat / Maximum).
- **Kernel-Tweaks**: Optimierungen für Scheduler, VM und Netzwerk.
- **RAM-Optimierer**: Passt Prozesslimits und sysfs-Speichereinstellungen an.
- **Kill Logs**: Stoppt akku- und RAM-fressende Protokollierungsdienste im Hintergrund.
- **System Props**: Deaktiviert Debug-Eigenschaften, um zusätzlichen RAM freizugeben.
- **Energiespar-Tuner**: Passe das Verhalten des Android-Energiesparmodus an, steuere die Verzögerung von Backups, die Deaktivierung von Sensoren, das GPS-Verhalten, den Datensparmodus und mehr. Diese Einstellungen sind nur wirksam, wenn der Android-Energiesparmodus AKTIVIERT ist.
- **Live-Konfiguration**: Vollständige Kontrolle in Echtzeit über die WebUI.

## 📦 Installation

**Voraussetzungen:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play-Dienste.

1. Lade das Modul von der[Releases-Seite](https://github.com/Drsexo/Frosty/releases) herunter.
2. Installiere es über deinen Root-Manager.
3. Starte das Gerät neu.
4. Öffne die WebUI, um die gewünschten Funktionen zu aktivieren — standardmäßig ist alles **DEAKTIVIERT**.

> [!NOTE]
> Magisk-Nutzer können die App [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) verwenden, um auf die WebUI zuzugreifen.

## 📖 Verwendung

Öffne die WebUI über deinen Root-Manager. Dort findest du:

- **System-Tweaks** — Kernel-Tweaks, System Props, Blur-Deaktivierung und Kill Logs aktivieren.
- **GMS Doze / Deep Doze** — Einstellen der Aggressivität des Doze-Modus.
- **GMS-Kategorien** — Gezieltes Einfrieren einzelner Gruppen von GMS-Diensten.
- **Whitelist** — Schützt wichtige Apps vor den strikten Deep Doze-Regeln.
- **Import / Export** — Sichern und Wiederherstellen deiner Konfiguration.

## 🧊 GMS-Kategorien

#### Sicher zu deaktivieren
| Kategorie | Auswirkung |
|-----------|------------|
| 📊 **Telemetrie** | Keine. Stoppt Werbung, Analytics und das Tracking durch Google. |
| 🔄 **Hintergrund** | Automatische Updates können verzögert werden. |

#### Was nicht mehr funktioniert
| Kategorie | Betroffene Funktionen |
|-----------|----------------------|
| 📍 **Standort** | Google Maps, GPS-Navigation, „Gerät finden“. |
| 📡 **Konnektivität** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Cloud** | Google-Anmeldung, Autofill für Passwörter, Backups. |
| 💳 **Zahlungen** | Google Pay, NFC-Zahlungen. |
| ⌚ **Wearables** | Wear OS, Google Fit, Fitness-Tracking. |
| 🎮 **Spiele** | Google Play Games Erfolge, Bestenlisten, Cloud-Speicher. |

## 🔋 Deep Doze Stufen

| Funktion | Moderat | Maximum |
|----------|:-------:|:-------:|
| Aggressive Doze-Konstanten | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| RUN_IN_BACKGROUND blockieren | ✅ | ✅ |
| Deep Idle bei ausgeschaltetem Bildschirm | ✅ | ✅ |
| WAKE_LOCK blockieren | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |
| Strikte Alarm-Einschränkungen | ❌ | ✅ |

## 🚀 RAM-Optimierer

Passt den Android-Prozessmanager und das Speicher-Subsystem basierend auf dem gesamten RAM deines Geräts an.  
Aktiviert außerdem den USAP-Pool für schnellere App-Kaltstarts und wendet sysfs-Tweaks an (`swappiness`, `page-cluster`). Alle Werte werden gesichert und bei Deaktivierung vollständig wiederhergestellt.

## ⚙️ Energiespar-Tuner

Konfiguriert das Verhalten des integrierten Android-Energiesparmodus, wenn dieser aktiv ist.

| Option | Beschreibung |
|--------|-------------|
| **Datensparmodus** | Beschränkt Hintergrunddaten für die meisten Apps |
| **Sprachaktivierung** | Deaktiviert die Hotword-Erkennung (z. B. "Hey Google") |
| **Vollständiges Backup** | Verschiebt vollständige Geräte-Backups |
| **Daten-Backup** | Verschiebt Key-Value-Backups (App-Einstellungen) |
| **App-Standby erzwingen** | Versetzt alle Hintergrund-Apps sofort in den Standby-Modus |
| **Hintergrundprüfung** | Erzwingt strengere Prüfungen für Hintergrundprozesse |
| **Sensoren** | Deaktiviert optionale Sensoren im Hintergrund |
| **GPS-Modus** | Steuert den Standortzugriff bei aktivem Energiesparmodus |

## ❓ FAQ (Häufige Fragen)

**F: Warum erhalte ich meine Benachrichtigungen verzögert?**  
A: GMS Doze und Deep Doze schränken die Hintergrundaktivität massiv ein. Füge deine Messenger-Apps unbedingt zur Whitelist hinzu.

**F: Funktioniert dieses Modul auch ohne Google Play-Dienste?**  
A: Ja. Die Kernel-Tweaks, System Props, Blur-Deaktivierung, Kill Logs und Deep Doze funktionieren problemlos auch ohne GMS.

## 📝 Doze-Whitelist

Bearbeite die Liste über die WebUI oder direkt in `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Füge deine Messenger-, Banking- und Wecker-Apps hinzu, um keine wichtigen Benachrichtigungen zu verpassen.

## 🙏 Credits

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)