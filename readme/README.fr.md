<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Fonctionnalités](#-fonctionnalités) • [📦 Installation](#-installation) • [📖 Utilisation](#-utilisation) •[🧊 Catégories GMS](#-catégories-gms) • [❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • 🇫🇷 Français • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Présentation

Frosty optimise l'autonomie de la batterie en gelant sélectivement les composants Google Mobile Services (GMS) et en appliquant des améliorations globales du mode Doze. Tout se configure via l'interface WebUI après l'installation.

## ✨ Fonctionnalités

- **Gel GMS** : Désactivez les services GMS répartis en 8 catégories avec un contrôle granulaire.
- **GMS Doze** : Retire les GMS des listes blanches (Whitelist) d'économie d'énergie.
- **Deep Doze** : Restrictions d'arrière-plan très agressives pour toutes les applications (Modéré/Maximum).
- **Kernel Tweaks** : Optimisations de l'ordonnanceur (Scheduler), de la VM et du réseau.
- **Kill Logs** : Arrêt des processus de journalisation en arrière-plan (économise la batterie et la RAM).
- **System Props** : Désactive les propriétés de débogage pour économiser la RAM.
- **Configuration en direct** : Contrôle total via WebUI avec des interrupteurs en temps réel.

## 📦 Installation

**Prérequis :** Android 9+, Magisk 20.4+ / KernelSU / APatch, Services Google Play.

1. Téléchargez le module depuis les [Releases](https://github.com/Drsexo/Frosty/releases).
2. Installez-le via votre gestionnaire root.
3. Redémarrez votre appareil.
4. Ouvrez la WebUI pour activer les fonctionnalités — tout est **DÉSACTIVÉ** par défaut.

> [!NOTE]
> Les utilisateurs de Magisk peuvent utiliser [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) pour accéder à l'interface WebUI.

## 📖 Utilisation

Ouvrez la WebUI depuis votre gestionnaire root :

- **Tweaks Système** — Activez les Tweaks du noyau, System Props, désactivez le flou, arrêtez les logs (Kill Logs).
- **GMS Doze / Deep Doze** — Configurez l'agressivité du mode Doze.
- **Catégories GMS** — Gelez les groupes de services GMS individuellement.
- **Whitelist** — Protégez vos applications importantes du mode Deep Doze.
- **Import / Export** — Sauvegardez et restaurez votre configuration.

## 🧊 Catégories GMS

#### Sûr à désactiver
| Catégorie | Impact |
|-----------|--------|
| 📊 **Télémétrie** | Aucun. Arrête les publicités, les analytics et le pistage. |
| 🔄 **Arrière-plan** | Les mises à jour automatiques peuvent être retardées. |

#### Fonctions impactées
| Catégorie | Ce qui ne fonctionnera plus |
|-----------|-----------------------------|
| 📍 **Localisation** | Maps, GPS, navigation, Localiser mon appareil. |
| 📡 **Connectivité** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Cloud** | Connexion Google, saisie automatique, mots de passe, sauvegardes. |
| 💳 **Paiements** | Google Pay, paiements sans contact NFC. |
| ⌚ **Wearables** | Wear OS, Google Fit, suivi d'activité. |
| 🎮 **Jeux** | Google Play Jeux (succès, classements, sauvegardes cloud). |

## 🔋 Niveaux de Deep Doze

| Fonctionnalité | Modéré | Maximum |
|----------------|:------:|:-------:|
| Constantes Doze agressives | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Refuser RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (Écran éteint) | ✅ | ✅ |
| Refuser WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |
| Restrictions des alarmes | ❌ | ✅ |

## ❓ FAQ

**Q : Pourquoi mes notifications sont-elles retardées ?**
R : GMS Doze et Deep Doze restreignent massivement l'activité en arrière-plan. Ajoutez vos applications de messagerie à la Whitelist.

**Q : Frosty fonctionne-t-il sans les Services Google Play ?**
R : Oui. Les Kernel Tweaks, System Props, la désactivation du flou, le Kill Logs et le Deep Doze fonctionneront sans GMS.

## 📝 Whitelist Doze

Éditez la liste via la WebUI ou directement dans `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Ajoutez vos applications de messagerie, banques et alarmes pour éviter de manquer des notifications cruciales.

## 🙏 Crédits

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
