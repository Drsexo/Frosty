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

<div align="center">
<img src="images/it.png" width="600">
</div>

## Panoramica

Frosty ottimizza la durata della batteria congelando i servizi GMS, applicando miglioramenti di Doze a livello di sistema e automatizzando il comportamento a schermo spento. Configura tutto tramite la WebUI.

## Funzionalità

- **Congelamento GMS**: Disabilita i servizi GMS in 8 categorie.
- **App Doze**: Rimuove qualsiasi app dall'elenco delle eccezioni del risparmio energetico Doze di Android. Anche i GMS possono essere selezionati qui, sostituendo il vecchio interruttore dedicato GMS Doze.
- **Deep Doze**: Restrizioni aggressive in background per tutte le app (Moderato / Massimo).
- **Ottimizzazione Schermo Spento**: Disabilita le connessioni selezionate (Wi-Fi, Bluetooth, dati, posizione) ed esegue opzionalmente la pulizia RAM dopo un ritardo configurabile di spegnimento schermo, ripristina tutto allo sblocco.
- **Disabilita Tracciamento Google**: Disabilita l'analisi GMS, la telemetria Clearcut, il polling Phenotype e il tracciamento degli annunci.
- **Tweak del Kernel**: Ottimizzazioni per scheduler, VM, rete e debug.
- **Ottimizzatore RAM**: Auto-tuning ZRAM, soglie LMK/LMKD/PSI, disabilitazione reclaim OEM, parametri memoria VM (Moderato / Massimo), pulitore RAM configurabile, Profilo multitasking (Prestazioni / Bilanciato / Risparmio energetico)
- **Proprietà di Sistema**: Disabilita le proprietà di debug per risparmiare RAM e batteria.
- **Terminazione Log**: Arresta i processi di log e di debug che consumano batteria.
- **Ottimizzatore Risparmio Energetico**: Personalizza il comportamento del risparmio energetico integrato di Android quando è attivo, inclusa un'opzione per mantenere la frequenza di aggiornamento massima quando è attivo.

## Installazione

**Requisiti:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services (GMS)

1. Scarica da [Releases](https://github.com/Drsexo/Frosty/releases).
2. Installa tramite il tuo gestore root.
3. Riavvia.
4. Apri la WebUI per abilitare le funzionalità.

> [!NOTE]
> Gli utenti Magisk possono utilizzare [KsuWebUI](https://github.com/KOWX712/KsuWebUIStandalone/releases) / [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) per accedere alla WebUI.

> [!NOTE]
> Su KernelSU/APatch, Frosty richiede un'installazione a caldo. Se il tuo gestore la supporta, aggiorna la WebUI dopo l'installazione invece di riavviare. Riavvia se qualcosa sembra anomalo. Magisk richiede sempre un riavvio.


## Utilizzo

Apri la WebUI dal tuo gestore root:

- **Tweak di Sistema**: tweak del kernel, proprietà di sistema, disabilitazione sfocatura, terminazione log, disabilitazione tracciamento, ottimizzatore e pulitore RAM.
- **Doze**: App Doze con selettore app, Deep Doze con selettore di livello e editor di whitelist.
- **Ottimizzazione Schermo Spento**: interruttori per connessione, timer di ritardo, ripristino allo sblocco.
- **Categorie GMS**: congela i singoli gruppi di servizi GMS, oppure usa Abilita tutte / Disabilita tutte per elaborare in batch quelle non già nello stato desiderato.
- **Ottimizzatore Risparmio Energetico**: affina il comportamento del risparmio energetico.
- **Importa / Esporta**: fai il backup e ripristina l'intera configurazione.

## Categorie GMS

#### Sicuro da disabilitare
| Categoria | Impatto |
|----------|--------|
| 📊 **Telemetria** | Nessuno. Ferma pubblicità, analisi, tracciamento. |
| 🔄 **Background** | Gli aggiornamenti automatici potrebbero essere ritardati. |

#### Potrebbe compromettere funzionalità
| Categoria | Funzionalità compromesse |
|----------|-------------|
| 📍 **Posizione** | Maps, navigazione, Trova il mio dispositivo, condivisione posizione |
| 📡 **Connettività** | Chromecast, Quick Share, Fast Pair |
| ☁️ **Cloud** | Accesso Google, Autofill, password, backup |
| 💳 **Pagamenti** | Google Pay, pagamento contactless NFC |
| ⌚ **Indossabili** | Wear OS, Google Fit, tracciamento fitness |
| 🎮 **Giochi** | Obiettivi Play Giochi, classifiche, salvataggi in cloud |

## Livelli Deep Doze

Entrambi i livelli riscrivono le costanti Doze, forzano IDLE mentre il dispositivo è bloccato, eseguono un killer di wakelock dopo 5 minuti di blocco, e attivano la policy flex-idle di JobScheduler su Android 13+. Le restrizioni seguono lo stato di blocco, non lo stato dello schermo: controllare l'ora o guardare il display ambient non resetta nulla, solo lo sblocco lo fa. **Massimo** usa inoltre il bucket di standby `restricted` (Moderato usa `rare`), nega `WAKE_LOCK`, disabilita il sensore di movimento mentre è bloccato, e termina i wakelock immediatamente all'applicazione.

## Ottimizzatore RAM

Auto-tiene la compressione ZRAM, le soglie LMK / LMKD / PSI, i nodi di reclaim OEM e i parametri di memoria VM. **Massimo** scala i pesi LMK di ~60-70% verso l'alto e usa soglie LMKD/PSI più proattive. Il Profilo multitasking (Prestazioni / Bilanciato / Risparmio energetico) controlla separatamente quante app in background l'ActivityManager mantiene pronte per riprendere istantaneamente.
## FAQ

**D: Perché le mie notifiche sono in ritardo?**  
R: App Doze e Deep Doze limitano l'attività in background. Aggiungi le tue app di messaggistica alla whitelist di Deep Doze nella WebUI. GMS/Firebase stesso è in whitelist per impostazione predefinita, quindi la consegna push resta intatta, ma le app di messaggistica di terze parti devono comunque essere aggiunte alla whitelist di Deep Doze nella WebUI.

**D: Dov'è finito GMS Doze?**  
R: Ora fa parte di App Doze. Apri il selettore di App Doze e seleziona GMS: stesso effetto, interfaccia unificata.

**D: Funziona senza Google Play Services?**  
R: I Tweak del Kernel, le Proprietà di Sistema, la Disabilitazione Sfocatura, la Terminazione Log, l'Ottimizzatore e Pulitore RAM, e Deep Doze funzionano tutti. Le funzionalità GMS richiedono i GMS.

**D: C'è qualcosa di abilitato dopo l'installazione?**  
R: No. Tutto è spento per impostazione predefinita. Abilita solo ciò di cui hai bisogno.

## Crediti

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Script di disabilitazione componenti GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)
- [xizt158](https://github.com/xizt159) per molti contributi di qualità

## Licenza

Licenza **GPL v3** vedi [LICENSE](LICENSE).  
Il nome **Frosty** è riservato solo alle versioni ufficiali. I fork devono usare un nome diverso e dichiarare chiaramente che non sono ufficiali. L'autore originale non si assume alcuna responsabilità per danni causati da versioni non ufficiali o modificate.
