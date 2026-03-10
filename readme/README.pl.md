<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)[✨ Funkcje](#-funkcje) • [📦 Instalacja](#-instalacja) •[📖 Użytkowanie](#-użytkowanie) • [🧊 Kategorie GMS](#-kategorie-gms) •[❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md) • 🇵🇱 Polski  
[🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md) • [🇧🇷 Português (BR)](README.pt-BR.md)  
[🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md) • [🇷🇺 Русский](README.ru.md)  
[🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Opis

Frosty optymalizuje czas pracy baterii poprzez selektywne zamrażanie komponentów Google Mobile Services (GMS) i zastosowanie systemowych ulepszeń oszczędzania energii w trybie Doze. Konfiguracja odbywa się w pełni przez WebUI po instalacji.

## ✨ Funkcje

- **Zamrażanie GMS**: Wyłącza usługi GMS w 8 kategoriach, z precyzyjną kontrolą.
- **GMS Doze**: Usuwa GMS z białej listy (Whitelist) oszczędzania energii.
- **Deep Doze**: Bardzo agresywne ograniczenia działania w tle dla wszystkich aplikacji (Umiarkowane / Maksymalne).
- **Tweaki Kernel**: Optymalizacje harmonogramu, pamięci wirtualnej (VM) oraz sieci.
- **Optymalizator RAM**: Dostraja limity procesów i ustawienia pamięci sysfs.  
- **Kill Logs**: Zatrzymuje logowanie (zapisywanie dzienników) w tle, zwalniając baterię i RAM.
- **System Props**: Wyłącza właściwości debugowania systemu, aby oszczędzać pamięć RAM.
- **Tuner Oszczędzania Baterii**: Dostosuj działanie trybu oszczędzania baterii w Androidzie, kontroluj odraczanie kopii zapasowych, wyłączanie czujników, zachowanie GPS, oszczędzanie danych i więcej. Ustawienia te przynoszą zauważalny efekt tylko wtedy, gdy oszczędzanie baterii w Androidzie jest WŁĄCZONE.
- **Konfiguracja na żywo**: Pełna kontrola w czasie rzeczywistym poprzez panel WebUI.

## 📦 Instalacja

**Wymagania:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Usługi Google Play (GMS).

1. Pobierz moduł ze strony [Releases](https://github.com/Drsexo/Frosty/releases).
2. Zainstaluj go przez swój menedżer root (Magisk/KernelSU itp.).
3. Uruchom urządzenie ponownie.
4. Otwórz WebUI, aby włączyć wybrane funkcje — domyślnie wszystko jest **WYŁĄCZONE**.

> [!NOTE]
> Użytkownicy Magiska mogą użyć aplikacji [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) aby uzyskać dostęp do panelu WebUI.

## 📖 Użytkowanie

Otwórz WebUI z menedżera root. Znajdziesz tam:

- **Poprawki Systemu (System Tweaks)** — Włącz Tweaki Kernel, System Props, wyłącz efekt Blur oraz użyj Kill Logs.
- **GMS Doze / Deep Doze** — Skonfiguruj poziom agresywności oszczędzania energii w uśpieniu (Doze).
- **Kategorie GMS** — Zamrażaj grupy usług GMS osobno.
- **Biała lista (Whitelist)** — Chroń swoje najważniejsze aplikacje przed ograniczeniami Deep Doze.
- **Import / Eksport** — Zrób kopię zapasową i przywróć swoje ustawienia.

## 🧊 Kategorie GMS

#### Bezpieczne do wyłączenia
| Kategoria | Wpływ |
|-----------|-------|
| 📊 **Telemetria** | Żaden. Zatrzymuje reklamy, analitykę i śledzenie Google. |
| 🔄 **Tło (Background)** | Automatyczne aktualizacje aplikacji mogą ulec opóźnieniu. |

#### Co przestanie działać
| Kategoria | Wpływ na funkcje |
|-----------|------------------|
| 📍 **Lokalizacja** | Google Maps, nawigacja GPS, funkcja "Znajdź moje urządzenie". |
| 📡 **Łączność** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Chmura (Cloud)** | Logowanie kontem Google, autouzupełnianie haseł, kopie zapasowe. |
| 💳 **Płatności** | Google Pay, płatności zbliżeniowe NFC. |
| ⌚ **Urządzenia noszone** | Wear OS, Google Fit, monitorowanie kondycji. |
| 🎮 **Gry** | Osiągnięcia w Google Play Games, rankingi, zapisy w chmurze. |

## 🔋 Poziomy Deep Doze

| Funkcja | Umiarkowane | Maksymalne |
|---------|:-----------:|:----------:|
| Agresywne stałe Doze | ✅ | ✅ |
| Koszyki oczekiwania aplikacji (App Standby Buckets)| ✅ | ✅ |
| Blokada RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (Przy zgaszonym ekranie) | ✅ | ✅ |
| Blokada WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |

## 🚀 Optymalizator RAM

Dostraja menedżera procesów Androida i podsystem pamięci na podstawie całkowitej pamięci RAM urządzenia.  
Włącza również pulę USAP w celu szybszego zimnego startu aplikacji i stosuje tweaki sysfs (`swappiness`, `page-cluster`). Wszystkie wartości są zapisywane i w pełni przywracane po wyłączeniu.

## ⚙️ Tuner Oszczędzania Baterii

Konfiguruje zachowanie wbudowanego w Androida trybu oszczędzania baterii, gdy jest on aktywny.

| Opcja | Opis |
|--------|-------------|
| **Oszczędzanie danych** | Ogranicza zużycie danych w tle dla większości aplikacji |
| **Wykrywanie mowy** | Wyłącza nasłuchiwanie słów kluczowych (np. "Hej Google") |
| **Pełna kopia zapasowa** | Odracza pełne kopie zapasowe urządzenia |
| **Kopia danych (Key/Value)** | Odracza kopie zapasowe ustawień aplikacji |
| **Wymuś uśpienie** | Natychmiast przełącza wszystkie aplikacje w tle w tryb uśpienia |
| **Sprawdzanie tła** | Wymusza bardziej rygorystyczne kontrole procesów w tle |
| **Czujniki** | Wyłącza opcjonalne czujniki działające w tle |
| **Tryb GPS** | Kontroluje dostęp do lokalizacji, gdy oszczędzanie baterii jest włączone |

## ❓ FAQ (Często zadawane pytania)

**P: Dlaczego moje powiadomienia przychodzą z opóźnieniem?**
O: GMS Doze i Deep Doze drastycznie ograniczają aktywność w tle. Dodaj swoje aplikacje komunikatorów do Białej listy (Whitelist).

**P: Czy ten moduł działa bez Usług Google Play (GMS)?**
O: Tak. Tweaki Kernel, System Props, Wyłączanie Blur, Kill Logs i Deep Doze będą działać bez GMS.

## 📝 Biała lista Doze (Whitelist)

Edytuj listę bezpośrednio w WebUI lub w pliku `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Dodaj do niej swoje komunikatory, aplikacje bankowe oraz budziki, by nie pominąć krytycznych powiadomień.

## 🙏 Kredyty

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)