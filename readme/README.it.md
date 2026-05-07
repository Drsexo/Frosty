<div align="center">

# 🧊 FROSTY

### Congelatore GMS e Risparmio Energetico

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Funzionalità](#funzionalità) • [Installazione](#installazione) • [Utilizzo](#utilizzo) • [Categorie](#categorie-gms) • [FAQ](#faq)

---

[🇬🇧 English](https://github.com/Drsexo/Frosty) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • 🇮🇹 Italiano • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Panoramica

Frosty ottimizza la durata della batteria congelando i servizi GMS, applicando miglioramenti di doze a livello di sistema e automatizzando il comportamento a schermo spento. Configura tutto tramite la WebUI.

## Funzionalità

- **Congelamento GMS**: Disabilita i servizi GMS in 8 categorie.
- **App Doze**: Rimuove qualsiasi app dall'elenco delle eccezioni del risparmio energetico Doze di Android. Anche i GMS possono essere selezionati qui, sostituendo il vecchio interruttore dedicato GMS Doze.
- **Deep Doze**: Restrizioni aggressive in background per tutte le app (Moderato / Massimo).
- **Ottimizzazione Schermo Spento**: Disabilita automaticamente le connessioni selezionate (Wi-Fi, Bluetooth, dati, posizione) e svuota le app in cache dopo un ritardo configurabile allo spegnimento dello schermo, quindi ripristina tutto allo sblocco.
- **Blocca Tracciamento Google**: Disabilita l'analisi GMS, la telemetria Clearcut, il polling Phenotype e il tracciamento degli annunci.
- **Tweak del Kernel**: Ottimizzazioni per scheduler, VM, rete e debug.
- **Ottimizzatore RAM**: Regola i limiti dei processi, la compattazione della memoria e il comportamento di zram.
- **Proprietà di Sistema**: Disabilita le proprietà di debug per risparmiare RAM e batteria.
- **Terminazione Log**: Arresta i processi di log e di debug che consumano batteria.
- **Ottimizzatore Risparmio Energetico**: Personalizza il comportamento del risparmio energetico integrato di Android quando è attivo.

## Installazione

**Requisiti:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services (GMS)

1. Scarica da [Releases](https://github.com/Drsexo/Frosty/releases).
2. Installa tramite il tuo gestore root.
3. Riavvia.
4. Apri la WebUI per abilitare le funzionalità.

> [!NOTE]
> Gli utenti Magisk possono utilizzare [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) per accedere alla WebUI.

## Utilizzo

Apri la WebUI dal tuo gestore root:

- **Tweak di Sistema**: tweak del kernel, proprietà di sistema, disabilitazione sfocatura, terminazione log, blocco tracciamento.
- **Doze**: App Doze con selettore app, Deep Doze con selettore di livello e editor di whitelist.
- **Ottimizzazione Schermo Spento**: interruttori per connessione, timer di ritardo, ripristino allo sblocco.
- **Categorie GMS**: congela i singoli gruppi di servizi GMS.
- **Ottimizzatore Risparmio Energetico**: affina il comportamento del risparmio energetico.
- **Importa / Esporta**: fai il backup e ripristina l'intera configurazione.

## Categorie GMS

#### Sicuro da disabilitare
| Categoria | Impatto |
|----------|--------|
| 📊 **Telemetria** | Nessuno. Ferma pubblicità, analisi, tracciamento. |
| 🔄 **Background** | Gli aggiornamenti automatici potrebbero essere ritardati. |

#### Potrebbe interrompere funzionalità
| Categoria | Cosa si interrompe |
|----------|-------------|
| 📍 **Posizione** | Maps, navigazione, Trova il mio dispositivo, condivisione posizione |
| 📡 **Connettività** | Chromecast, Quick Share, Fast Pair |
| ☁️ **Cloud** | Accesso Google, Autofill, password, backup |
| 💳 **Pagamenti** | Google Pay, pagamento contactless NFC |
| ⌚ **Indossabili** | Wear OS, Google Fit, tracciamento fitness |
| 🎮 **Giochi** | Obiettivi Play Giochi, classifiche, salvataggi in cloud |

## Livelli Deep Doze

| Funzionalità | Moderato | Massimo |
|---------|:--------:|:-------:|
| Costanti Doze Aggressive | ✅ | ✅ |
| App Standby Buckets (raro) | ✅ | ✅ |
| Killer di Wakelock (schermo spento) | ✅ | ✅ |
| Nega WAKE_LOCK | ❌ | ✅ |

## FAQ

**D: Perché le mie notifiche sono in ritardo?**  
R: App Doze e Deep Doze limitano l'attività in background. Aggiungi le tue app di messaggistica alla whitelist di Deep Doze nella WebUI.

**D: Dov'è finito GMS Doze?**  
R: Ora fa parte di App Doze. Apri il selettore di App Doze e seleziona GMS: stesso effetto, interfaccia unificata.

**D: Funziona senza Google Play Services?**  
R: I Tweak del Kernel, le Proprietà di Sistema, la Disabilitazione Sfocatura, la Terminazione Log, l'Ottimizzatore RAM e Deep Doze funzionano tutti. Le funzionalità GMS richiedono i GMS.

**D: C'è qualcosa di abilitato dopo l'installazione?**  
R: No. Tutto è spento per impostazione predefinita. Abilita solo ciò di cui hai bisogno.

## Crediti

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Script di disabilitazione componenti GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)

## Licenza

Licenza **GPL v3** vedi [LICENSE](LICENSE).  
Il nome **Frosty** è riservato solo alle versioni ufficiali. I fork devono usare un nome diverso e dichiarare chiaramente che non sono ufficiali. L'autore originale non si assume alcuna responsabilità per danni causati da versioni non ufficiali o modificate.