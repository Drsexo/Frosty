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

<div align="center">
<img src="images/pl.png" width="600">
</div>

## Przegląd

Frosty optymalizuje czas pracy baterii poprzez zamrażanie usług GMS, stosowanie ulepszeń trybu Doze w całym systemie i automatyzację zachowania po wyłączeniu ekranu. Skonfiguruj wszystko przez WebUI.

## Funkcje

- **Zamrażanie GMS**: Wyłącz usługi GMS w 8 kategoriach.
- **App Doze**: Usuń dowolną aplikację z listy wykluczeń z oszczędzania energii Android Doze. GMS można tu również wybrać, zastępując stary dedykowany przełącznik GMS Doze.
- **Deep Doze**: Ograniczenia w tle dla wszystkich aplikacji, gdy urządzenie jest zablokowane (Minimum / Umiarkowane / Maksymalne)
- **Optymalizacja Wyłączonego Ekranu**: Wyłącza wybrane połączenia (Wi-Fi, Bluetooth, dane, NFC, lokalizacja, czujniki, tryb niskiego zużycia panelu) i opcjonalnie uruchamia czyszczenie RAM po tym, jak urządzenie pozostało zablokowane przez konfigurowalne opóźnienie, przywraca po odblokowaniu
- **Wyłącz śledzenie Google**: Wyłącza analitykę GMS, telemetrię Clearcut, odpytywanie Phenotype i śledzenie reklam.
- **Modyfikacje Jądra (Kernel Tweaks)**: Optymalizacje harmonogramu (scheduler), maszyny wirtualnej (VM), sieci i debugowania.
- **Optymalizator RAM**: Automatyczne strojenie ZRAM, progi LMK/LMKD/PSI, wyłączanie reclaim OEM, parametry pamięci VM (Umiarkowane / Maksymalne), konfigurowalne czyszczenie RAM.
- **System Props**: Wyłącz właściwości debugowania, aby oszczędzać RAM i baterię.
- **Kasowanie Logów**: Zatrzymaj procesy logowania i debugowania, które zużywają baterię.
- **Dostrajanie Oszczędzania Baterii**: Dostosuj, co robi wbudowane oszczędzanie baterii Androida, gdy jest aktywne.

## Instalacja

**Wymagania:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Usługi Google Play (GMS)

1. Pobierz z [Releases](https://github.com/Drsexo/Frosty/releases).
2. Zainstaluj przez swój menedżer root.
3. Uruchom ponownie (Reboot).
4. Otwórz WebUI, aby włączyć funkcje.

> [!NOTE]
> Użytkownicy Magisk mogą użyć [KsuWebUI](https://github.com/KOWX712/KsuWebUIStandalone/releases) / [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases), aby uzyskać dostęp do WebUI.

> [!NOTE]
> W KernelSU/APatch Frosty żąda instalacji na gorąco. Jeśli Twój menedżer to obsługuje, odśwież WebUI po instalacji zamiast ponownie uruchamiać. Uruchom ponownie, jeśli coś wygląda nie tak. Magisk zawsze wymaga ponownego uruchomienia.


## Użytkowanie

Otwórz WebUI ze swojego menedżera root:

- **Modyfikacje Systemu**: Modyfikacje jądra, system props, wyłączenie rozmycia, kasowanie logów, wyłączenie śledzenia, optymalizator i czyszczenie RAM.
- **Doze**: App Doze z wyborem apek, Deep Doze z wyborem poziomu i edytorem białej listy.
- **Optymalizacja Wyłączonego Ekranu**: Przełączniki dla poszczególnych połączeń, opóźnienia, przywracanie po odblokowaniu.
- **Kategorie GMS**: Zamrażaj poszczególne grupy usług GMS, lub użyj Włącz wszystkie / Wyłącz wszystkie, aby masowo przetworzyć te, które nie są jeszcze w pożądanym stanie.
- **Dostrajanie Oszczędzania Baterii**: Precyzyjne dostrajanie zachowania trybu oszczędzania baterii.
- **Import / Eksport**: Kopia zapasowa i przywracanie pełnej konfiguracji.

## Kategorie GMS

#### Bezpieczne do wyłączenia
| Kategoria | Wpływ |
|----------|--------|
| 📊 **Telemetria** | Brak. Zatrzymuje reklamy, analitykę, śledzenie. |
| 🔄 **Działanie w tle** | Automatyczne aktualizacje mogą być opóźnione. |

#### Może zakłócić funkcje
| Kategoria | Zakłócone funkcje |
|----------|-------------|
| 📍 **Lokalizacja** | Mapy, nawigacja, Znajdź moje urządzenie, udostępnianie lokalizacji |
| 📡 **Łączność** | Chromecast, Quick Share, Szybkie parowanie |
| ☁️ **Chmura** | Logowanie Google, Autouzupełnianie, hasła, kopie zapasowe |
| 💳 **Płatności** | Google Pay, płatności zbliżeniowe NFC |
| ⌚ **Urządzenia noszone** | Wear OS, Google Fit, śledzenie aktywności |
| 🎮 **Gry** | Osiągnięcia Play Games, tabele wyników, zapisy w chmurze |

## Poziomy Deep Doze

Wszystkie poziomy przepisują stałe Doze i włączają politykę flex-idle JobScheduler na Androidzie 13+, gdzie system to obsługuje. **Minimum** to najłagodniejszy poziom: krótsze timeouty Doze i bucket standby `frequent`, bez zabójcy wakelocków, bez odmowy `WAKE_LOCK` i bez ograniczeń czujników. **Umiarkowane** i **Maksymalne** uruchamiają zabójcę wakelocków po 5 minutach blokady urządzenia i wymuszają IDLE w tym momencie; po tych 5 minutach aplikacje przechodzą do bucketu `rare` (Umiarkowane) lub `restricted` (Maksymalne), a odblokowanie je przywraca. Ograniczenia następują za stanem blokady, nie stanem ekranu: sprawdzenie czasu lub rzucenie okiem na wyświetlacz ambient nic nie resetuje, tylko odblokowanie. **Maksymalne** dodatkowo odmawia `WAKE_LOCK` dla ograniczonych aplikacji, blokuje dostęp do czujników (w tym podnieś-do-wybudzenia) dla każdej aplikacji z wyjątkiem domyślnego dialera podczas gdy urządzenie jest zablokowane i ekran jest wyłączony (przywracane podczas połączeń i gdy ekran się włącza), i zabija wakelocki natychmiast przy zastosowaniu.

## Optymalizator RAM

Automatycznie stroi kompresję ZRAM, progi LMK / LMKD / PSI, węzły reclaim OEM i parametry pamięci VM. **Maksymalne** skaluje wagi LMK o ~50-70% w górę i używa bardziej proaktywnych progów LMKD/PSI. Profil wielozadaniowości (Wydajność / Zrównoważony / Oszczędzanie energii) osobno kontroluje, ile aplikacji w tle ActivityManager utrzymuje gotowych do natychmiastowego wznowienia.
## FAQ

**P: Dlaczego moje powiadomienia są opóźnione?**  
O: App Doze i Deep Doze ograniczają aktywność w tle. Dodaj swoje komunikatory do białej listy Deep Doze w WebUI.


**P: Co się stanie, jeśli wyłączę moduł w menedżerze zamiast wyłączyć funkcje?**  
O: Frosty przestaje działać przy następnym uruchomieniu, ale ustawienia, które już zapisał (stałe Doze, buckety standby, app ops, ustawienia systemowe) pozostają aktywne, a jego monitory działają dalej do ponownego uruchomienia. Najpierw wyłącz funkcje w WebUI, a potem wyłącz moduł. Usunięcie modułu uruchamia przywrócenie odinstalowania Frosty przy następnym uruchomieniu.

**P: Gdzie podziało się GMS Doze?**  
O: Jest to teraz część App Doze. Otwórz okno wyboru App Doze i wybierz GMS – ten sam efekt, ujednolicony interfejs.

**P: Czy to działa bez Usług Google Play?**  
O: Modyfikacje jądra, System Props, Wyłączenie Rozmycia, Kasowanie Logów, Optymalizator i Czyszczenie RAM, oraz Deep Doze działają bez GMS. Funkcje GMS wymagają GMS.

**P: Czy po instalacji cokolwiek jest włączone?**  
O: Nie. Domyślnie wszystko jest wyłączone. Włącz tylko to, czego potrzebujesz.

## Kredyty

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Skrypt wyłączający komponenty GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)
- [xizt159](https://github.com/xizt159) za wiele wysokiej jakości wkładów

## Licencja

Licencja **GPL v3**, zobacz [LICENSE](LICENSE).  
Nazwa **Frosty** jest zarezerwowana wyłącznie dla oficjalnych wydań. Forki muszą używać innej nazwy i wyraźnie zaznaczać, że są nieoficjalne. Oryginalny autor nie ponosi odpowiedzialności za szkody spowodowane przez nieoficjalne lub zmodyfikowane wersje.
