<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Funzionalità](#-funzionalità) • [📦 Installazione](#-installazione) • [📖 Utilizzo](#-utilizzo) • [🧊 Categorie GMS](#-categorie-gms) • [❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • 🇮🇹 Italiano • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Panoramica

Frosty ottimizza la durata della batteria congelando selettivamente i componenti dei Google Mobile Services (GMS) e applicando miglioramenti al sistema di risparmio energetico Doze a livello di sistema. Tutto si configura tramite la WebUI dopo l'installazione.

## ✨ Funzionalità

- **GMS Freezer**: Disabilita i servizi GMS divisi in 8 categorie con controllo granulare.
- **GMS Doze**: Rimuove i GMS dalle whitelist (liste di esclusione) del risparmio energetico.
- **Deep Doze**: Restrizioni aggressive in background per tutte le app (Moderato / Massimo).
- **Kernel Tweaks**: Ottimizzazioni per Scheduler, VM e rete.
- **Kill Logs**: Ferma i processi di registrazione in background che consumano batteria e RAM.
- **System Props**: Disabilita le proprietà di debug per risparmiare ulteriore RAM.
- **Configurazione Live**: Controllo completo in tempo reale tramite WebUI.

## 📦 Installazione

**Requisiti:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services.

1. Scarica il modulo dalla pagina [Releases](https://github.com/Drsexo/Frosty/releases).
2. Installalo tramite il tuo gestore root.
3. Riavvia il dispositivo.
4. Apri la WebUI per abilitare le funzionalità — tutto parte **DISATTIVATO** di default.

> [!NOTE]
> Gli utenti Magisk possono usare l'app [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) per accedere alla WebUI.

## 📖 Utilizzo

Apri la WebUI dal tuo gestore root. Troverai:

- **Ottimizzazioni Sistema (System Tweaks)** — Attiva Kernel Tweaks, System Props, disabilita il Blur e attiva Kill Logs.
- **GMS Doze / Deep Doze** — Configura l'aggressività del risparmio energetico.
- **Categorie GMS** — Congela singolarmente i gruppi di servizi GMS.
- **Whitelist** — Proteggi le tue app più importanti dalle restrizioni del Deep Doze.
- **Importa / Esporta** — Salva e ripristina la tua configurazione.

## 🧊 Categorie GMS

#### Sicure da disabilitare
| Categoria | Impatto |
|-----------|---------|
| 📊 **Telemetria** | Nessuno. Blocca pubblicità, analytics e tracciamento. |
| 🔄 **Background** | Gli aggiornamenti automatici potrebbero essere ritardati. |

#### Funzionalità compromesse
| Categoria | Cosa smetterà di funzionare |
|-----------|-----------------------------|
| 📍 **Posizione** | Google Maps, navigazione GPS, Trova il mio dispositivo. |
| 📡 **Connettività** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Cloud** | Accesso Google, compilazione automatica, password, backup. |
| 💳 **Pagamenti** | Google Pay, pagamenti NFC. |
| ⌚ **Wearables** | Wear OS, Google Fit, tracciamento fitness. |
| 🎮 **Giochi** | Obiettivi Play Games, classifiche, salvataggi in cloud. |

## 🔋 Livelli Deep Doze

| Funzionalità | Moderato | Massimo |
|--------------|:--------:|:-------:|
| Costanti Doze aggressive | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Nega RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle a schermo spento | ✅ | ✅ |
| Nega WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |
| Restrizioni rigide per allarmi | ❌ | ✅ |

## ❓ FAQ (Domande Frequenti)

**D: Perché le mie notifiche arrivano in ritardo?**
R: GMS Doze e Deep Doze limitano pesantemente l'attività in background. Aggiungi le tue app di messaggistica alla Whitelist.

**D: Questo modulo funziona senza i Google Play Services?**
R: Sì. Kernel Tweaks, System Props, Disable Blur, Kill Logs e Deep Doze funzioneranno senza GMS.

## 📝 Whitelist Doze

Modificala tramite la WebUI o direttamente nel file `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Aggiungi le tue app di messaggistica, banche e sveglie per non perdere notifiche cruciali.

## 🙏 Crediti

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
