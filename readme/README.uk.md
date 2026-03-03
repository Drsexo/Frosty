<div align="center">

# 🧊 FROSTY

### GMS Freezer та Економія батареї

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Можливості](#-можливості) • [📦 Встановлення](#-встановлення) • [📖 Використання](#-використання) • [🧊 Категорії GMS](#-категорії-gms) •[❓ Часті запитання](#-часті-запитання)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • 🇺🇦 Українська • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Огляд

Frosty оптимізує час роботи від батареї, вибірково заморожуючи компоненти Google Mobile Services (GMS) та застосовуючи системні покращення режиму сну (Doze). Усе налаштовується через WebUI після встановлення.

## ✨ Можливості

- **Заморозка GMS**: Вимкнення служб GMS у 8 категоріях із можливістю детального контролю.
- **GMS Doze**: Видалення GMS із системних білих списків (Whitelist) енергозбереження.
- **Deep Doze (Глибокий сон)**: Дуже агресивні фонові обмеження для всіх застосунків (Помірний / Максимальний режим).
- **Kernel Tweaks**: Оптимізація планувальника (Scheduler), віртуальної пам'яті (VM) та мережі.
- **Kill Logs**: Зупинка фонових процесів логування для економії батареї та оперативної пам'яті.
- **System Props**: Вимкнення властивостей налагодження (debug) для економії RAM.
- **Налаштування в реальному часі**: Повне управління модулем через WebUI.

## 📦 Встановлення

**Вимоги:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Сервіси Google Play.

1. Завантажте модуль зі сторінки [Releases](https://github.com/Drsexo/Frosty/releases).
2. Встановіть його через ваш root-менеджер.
3. Перезавантажте пристрій.
4. Відкрийте WebUI для увімкнення функцій — за замовчуванням усе **ВИМКНЕНО**.

> [!NOTE]
> Користувачі Magisk можуть використовувати застосунок [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) для доступу до інтерфейсу WebUI.

## 📖 Використання

Відкрийте WebUI з вашого root-менеджера. Ви знайдете:

- **Системні налаштування (System Tweaks)** — Увімкнення твіків ядра, System Props, вимкнення розмиття (Blur), зупинка логів (Kill Logs).
- **GMS Doze / Deep Doze** — Налаштування агресивності режиму сну.
- **Категорії GMS** — Вибіркова заморозка груп служб GMS.
- **Білий список (Whitelist)** — Захист важливих застосунків від жорстких обмежень Deep Doze.
- **Імпорт / Експорт** — Збереження та відновлення вашої конфігурації.

## 🧊 Категорії GMS

#### Безпечно для вимкнення
| Категорія | Вплив |
|-----------|-------|
| 📊 **Телеметрія** | Жодного. Зупиняє рекламу, аналітику та стеження від Google. |
| 🔄 **Фон** | Автоматичні оновлення застосунків можуть надходити із затримкою. |

#### Що перестане працювати
| Категорія | Функції, на які вплине |
|-----------|------------------------|
| 📍 **Місцезнаходження** | Google Карти, GPS-навігація, функція «Знайти пристрій». |
| 📡 **Підключення** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Хмара** | Вхід через Google, автозаповнення паролів, резервне копіювання. |
| 💳 **Платежі** | Google Pay, безконтактна оплата по NFC. |
| ⌚ **Носимі пристрої** | Wear OS, Google Fit, відстеження фітнес-активності. |
| 🎮 **Ігри** | Досягнення в Google Play Games, таблиці лідерів, хмарні збереження. |

## 🔋 Рівні Deep Doze

| Функція | Помірний | Максимальний |
|---------|:--------:|:------------:|
| Агресивні константи Doze | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Блокувати RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (При вимкненому екрані) | ✅ | ✅ |
| Блокувати WAKE_LOCK | ❌ | ✅ |
| Блокувальник Wakelock (Wakelock Killer)| ❌ | ✅ |
| Суворі обмеження будильників | ❌ | ✅ |

## ❓ Часті запитання (FAQ)

**П: Чому мої сповіщення надходять із затримкою?**
В: Режими GMS Doze та Deep Doze сильно обмежують фонову активність. Обов'язково додайте ваші месенджери до Білого списку (Whitelist).

**П: Чи працює цей модуль без сервісів Google Play?**
В: Так. Kernel Tweaks, System Props, вимкнення розмиття, Kill Logs та Deep Doze працюватимуть без GMS.

## 📝 Білий список Doze (Whitelist)

Редагуйте список через WebUI або безпосередньо у файлі `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Додайте сюди ваші месенджери, банківські застосунки та будильники, щоб не пропустити важливі сповіщення.

## 🙏 Кредити

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
