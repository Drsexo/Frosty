<div align="center">

# 🧊 FROSTY

### Zamrażarka GMS i Oszczędzacz Baterii

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Funkcje](#funkcje) • [Instalacja](#instalacja) • [Użytkowanie](#użytkowanie) • [Kategorie](#kategorie-gms) • [FAQ](#faq)

---

[🇬🇧 English](https://github.com/Drsexo/Frosty) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
🇵🇱 Polski • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Przegląd

Frosty optymalizuje czas pracy baterii poprzez zamrażanie usług GMS, stosowanie ulepszeń trybu doze w całym systemie i automatyzację zachowania po wyłączeniu ekranu. Skonfiguruj wszystko przez WebUI.

## Funkcje

- **Zamrażanie GMS**: Wyłącz usługi GMS w 8 kategoriach.
- **Usypianie aplikacji (App Doze)**: Usuń dowolną aplikację z listy wykluczeń z oszczędzania energii Android Doze. GMS można tu również wybrać, zastępując stary dedykowany przełącznik GMS Doze.
- **Głębokie Usypianie (Deep Doze)**: Agresywne restrykcje w tle dla wszystkich aplikacji (Umiarkowane / Maksymalne).
- **Optymalizacja Wyłączonego Ekranu**: Automatycznie wyłącza wybrane połączenia (Wi-Fi, Bluetooth, dane, lokalizacja) i czyści aplikacje w pamięci podręcznej po konfigurowalnym opóźnieniu po wyłączeniu ekranu, a następnie przywraca wszystko po odblokowaniu.
- **Zablokuj śledzenie Google**: Wyłącza analitykę GMS, telemetrię Clearcut, odpytywanie Phenotype i śledzenie reklam.
- **Modyfikacje Jądra (Kernel Tweaks)**: Optymalizacje harmonogramu (scheduler), maszyny wirtualnej (VM), sieci i debugowania.
- **Optymalizator RAM**: Dostraja limity procesów, kompresję pamięci i zachowanie zram.
- **Właściwości Systemu (System Props)**: Wyłącz właściwości debugowania, aby oszczędzać RAM i baterię.
- **Zabijanie Logów**: Zatrzymaj procesy logowania i debugowania, które zużywają baterię.
- **Dostrajanie Oszczędzania Baterii**: Dostosuj, co robi wbudowane oszczędzanie baterii Androida, gdy jest aktywne.

## Instalacja

**Wymagania:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Usługi Google Play (GMS)

1. Pobierz z [Releases](https://github.com/Drsexo/Frosty/releases).
2. Zainstaluj przez swój menedżer root.
3. Uruchom ponownie (Reboot).
4. Otwórz WebUI, aby włączyć funkcje.

> [!NOTE]
> Użytkownicy Magisk mogą użyć [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases), aby uzyskać dostęp do WebUI.

## Użytkowanie

Otwórz WebUI ze swojego menedżera root:

- **Modyfikacje Systemu**: Modyfikacje jądra, właściwości systemu, wyłączenie rozmycia, zabijanie logów, blokada śledzenia.
- **Doze**: Usypianie aplikacji z wyborem apek, Głębokie Usypianie z wyborem poziomu i edytorem białej listy.
- **Optymalizacja Wyłączonego Ekranu**: Przełączniki dla poszczególnych połączeń, opóźnienia, przywracanie po odblokowaniu.
- **Kategorie GMS**: Zamrażaj poszczególne grupy usług GMS.
- **Dostrajanie Oszczędzania Baterii**: Precyzyjne dostrajanie zachowania trybu oszczędzania baterii.
- **Import / Eksport**: Kopia zapasowa i przywracanie pełnej konfiguracji.

## Kategorie GMS

#### Bezpieczne do wyłączenia
| Kategoria | Wpływ |
|----------|--------|
| 📊 **Telemetria** | Brak. Zatrzymuje reklamy, analitykę, śledzenie. |
| 🔄 **Działanie w tle** | Automatyczne aktualizacje mogą być opóźnione. |

#### Może zepsuć funkcje
| Kategoria | Co się psuje |
|----------|-------------|
| 📍 **Lokalizacja** | Mapy, nawigacja, Znajdź moje urządzenie, udostępnianie lokalizacji |
| 📡 **Łączność** | Chromecast, Quick Share, Szybkie parowanie |
| ☁️ **Chmura** | Logowanie Google, Autouzupełnianie, hasła, kopie zapasowe |
| 💳 **Płatności** | Google Pay, płatności zbliżeniowe NFC |
| ⌚ **Urządzenia noszone** | Wear OS, Google Fit, śledzenie aktywności |
| 🎮 **Gry** | Osiągnięcia Play Games, tabele wyników, zapisy w chmurze |

## Poziomy Deep Doze

| Funkcja | Umiarkowane | Maksymalne |
|---------|:--------:|:-------:|
| Agresywne stałe Doze | ✅ | ✅ |
| Koszyki gotowości aplikacji (rzadko) | ✅ | ✅ |
| Zabijanie Wakelocków (ekran wył.) | ✅ | ✅ |
| Odmowa WAKE_LOCK | ❌ | ✅ |

## FAQ

**P: Dlaczego moje powiadomienia są opóźnione?**  
O: Usypianie Aplikacji i Deep Doze ograniczają aktywność w tle. Dodaj swoje komunikatory do białej listy Deep Doze w WebUI.

**P: Gdzie podziało się GMS Doze?**  
O: Jest to teraz część Usypiania Aplikacji (App Doze). Otwórz okno wyboru App Doze i wybierz GMS – ten sam efekt, ujednolicony interfejs.

**P: Czy to działa bez Usług Google Play?**  
O: Modyfikacje jądra, Właściwości Systemu, Wyłączenie Rozmycia, Zabijanie Logów, Optymalizator RAM i Deep Doze działają bez GMS. Funkcje GMS wymagają GMS.

**P: Czy po instalacji cokolwiek jest włączone?**  
O: Nie. Domyślnie wszystko jest wyłączone. Włącz tylko to, czego potrzebujesz.

## Kredyty

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Skrypt wyłączający komponenty GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)

## Licencja

Licencja **GPL v3**, zobacz [LICENSE](LICENSE).  
Nazwa **Frosty** jest zarezerwowana wyłącznie dla oficjalnych wydań. Forki muszą używać innej nazwy i wyraźnie zaznaczać, że są nieoficjalne. Oryginalny autor nie ponosi odpowiedzialności za szkody spowodowane przez nieoficjalne lub zmodyfikowane wersje.