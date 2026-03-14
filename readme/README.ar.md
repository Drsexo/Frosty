<div align="center">

# 🧊 FROSTY

### أداة تجميد GMS وتوفير البطارية

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ المزايا](#-المزايا) • [📦 التثبيت](#-التثبيت) • [📖 الاستخدام](#-الاستخدام) • [🧊 فئات GMS](#-فئات-gms) • [❓ الأسئلة الشائعة](#-الأسئلة-الشائعة)

---
[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • 🇸🇦 العربية

</div>

## نظرة عامة

يقوم Frosty بتحسين عمر البطارية من خلال تجميد مكوّنات خدمات جوجل للجوّال (GMS) بشكل انتقائي وتطبيق تحسينات وضع توفير الطاقة (Doze) على مستوى النظام بالكامل. يتم تكوين كل شيء من خلال واجهة WebUI بعد التثبيت.

## ✨ المزايا

- **تجميد GMS**: تعطيل خدمات GMS عبر 8 فئات مع تحكم دقيق
- **GMS Doze**: إزالة خدمات GMS من القائمة البيضاء لتوفير الطاقة (Whitelist)
- **Deep Doze**: قيود خلفية صارمة على جميع التطبيقات (معتدل/أقصى)
- **تعديلات الكيرنل (Kernel)**: تحسينات المجدول (Scheduler) والذاكرة الوهمية (VM) والشبكة
- **مُحسّن الذاكرة (RAM)**: يضبط حدود العمليات وإعدادات ذاكرة sysfs
- **إيقاف السجلات (Kill Logs)**: إيقاف عمليات التسجيل التي تستنزف البطارية في الخلفية
- **خصائص النظام (System Props)**: تعطيل خصائص التصحيح (Debug) لتوفير الرام (RAM)
- **مُحسّن توفير البطارية (Battery Saver Tuner)**: خصّص ما يفعله وضع توفير البطارية في Android، وتحكم في تأجيل النسخ الاحتياطي، وتعطيل المستشعرات، وسلوك الـ GPS، وتوفير البيانات، والمزيد. هذه الإعدادات لا تأخذ مفعولها إلا عند تشغيل وضع توفير البطارية في النظام.
- **تحكم مباشر**: تحكم كامل عبر واجهة WebUI مع إمكانية التبديل الفوري

## 📦 التثبيت

**المتطلبات:** إصدار Android 9+، أحدث إصدار من Magisk (20.4+) / KernelSU / APatch، خدمات Google Play.

1. حمّل الإضافة من صفحة [الإصدارات (Releases)](https://github.com/Drsexo/Frosty/releases)
2. قم بتثبيتها عبر تطبيق إدارة الروت الخاص بك
3. أعد تشغيل الجهاز
4. افتح واجهة WebUI لتفعيل الميزات — كل شيء يكون **مُعطلاً** افتراضياً

> [!NOTE]
> يمكن لمستخدمي Magisk استخدام تطبيق [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) للوصول إلى الواجهة.

## 📖 الاستخدام

افتح واجهة WebUI من مدير الروت الخاص بك. ستجد:

- **تعديلات النظام (System Tweaks)** — تشغيل تعديلات الكيرنل، خصائص النظام، إيقاف الضبابية، إيقاف السجلات
- **GMS Doze / Deep Doze** — ضبط مستوى الحدة لوضع Doze
- **فئات GMS** — تجميد مجموعات خدمات GMS بشكل فردي
- **القائمة البيضاء (Whitelist)** — استثناء التطبيقات لحمايتها من الـ Deep Doze
- **استيراد / تصدير** — حفظ واسترجاع إعداداتك

## 🧊 فئات GMS

#### آمن للتعطيل
| الفئة | التأثير |
|-------|---------|
| 📊 **القياس عن بُعد (Telemetry)** | لا يوجد. يوقف الإعلانات، تحليلات الاستخدام والتتبع. |
| 🔄 **الخلفية (Background)** | قد تتأخر التحديثات التلقائية. |

#### ميزات قد تتوقف
| الفئة | الميزات المتأثرة |
|-------|---------------|
| 📍 **الموقع (Location)** | الخرائط، الملاحة، العثور على جهازي، مشاركة الموقع |
| 📡 **الاتصال (Connectivity)** | Chromecast، Quick Share، Fast Pair |
| ☁️ **السحابة (Cloud)** | تسجيل الدخول بجوجل، الإكمال التلقائي، كلمات المرور، النسخ الاحتياطي |
| 💳 **المدفوعات (Payments)** | Google Pay، الدفع عبر NFC |
| ⌚ **الأجهزة القابلة للارتداء** | Wear OS، Google Fit، تتبع اللياقة |
| 🎮 **الألعاب (Games)** | إنجازات Play Games، لوحات الصدارة، الحفظ السحابي |

## 🔋 مستويات Deep Doze

| الميزة | معتدل | أقصى |
|--------|:-----:|:----:|
| ثوابت Doze صارمة | ✅ | ✅ |
| مجموعات انتظار التطبيقات (App Standby Buckets) | ✅ | ✅ |
| رفض RUN_IN_BACKGROUND | ✅ | ✅ |
| خمول عميق مع إطفاء الشاشة (Deep Idle) | ✅ | ✅ |
| إيقاف WAKE_LOCK | ❌ | ✅ |
| إيقاف الـ Wakelocks (Wakelock Killer) | ❌ | ✅ |

## 🚀 مُحسّن الذاكرة (RAM)

يضبط مدير عمليات Android ونظام الذاكرة الفرعي بناءً على إجمالي الذاكرة العشوائية (RAM) لجهازك.  
كما يُفعّل تجمع USAP (USAP pool) لتسريع فتح التطبيقات من الصفر (Cold app launches) ويُطبّق تعديلات sysfs (`swappiness`, `page-cluster`). يتم الاحتفاظ بنسخة احتياطية من جميع القيم واستعادتها بالكامل عند التعطيل.

## ⚙️ مُحسّن توفير البطارية

يقوم بتكوين ما يفعله وضع توفير البطارية المدمج في Android عند تنشيطه.

| الخيار | الوصف |
|--------|-------------|
| **توفير البيانات (Data Saver)** | تقييد بيانات الخلفية لمعظم التطبيقات |
| **اكتشاف الصوت (Sound Trigger)** | تعطيل اكتشاف الكلمات الساخنة (مثل "Hey Google") |
| **النسخ الاحتياطي الكامل** | تأجيل النسخ الاحتياطي الكامل للجهاز |
| **نسخ البيانات والإعدادات** | تأجيل النسخ الاحتياطي لبيانات وإعدادات التطبيقات (Key-value) |
| **فرض وضع الاستعداد** | وضع جميع تطبيقات الخلفية في وضع الاستعداد فوراً |
| **فحص الخلفية** | فرض فحوصات وقيود أكثر صرامة على عمليات الخلفية |
| **المستشعرات** | تعطيل المستشعرات الاختيارية في الخلفية |
| **وضع الـ GPS** | التحكم في الوصول إلى الموقع أثناء تنشيط توفير البطارية |

## ❓ الأسئلة الشائعة

**س: لماذا تتأخر الإشعارات في جهازي؟**  
ج: وضع GMS Doze و Deep Doze يقيّدان نشاط الخلفية. أضف تطبيقات المراسلة الخاصة بك إلى القائمة البيضاء (Whitelist).

**س: هل تعمل الإضافة بدون خدمات Google Play؟**  
ج: نعم، تعديلات الكيرنل، خصائص النظام (System Props)، إيقاف الضبابية، إيقاف السجلات، ووضع Deep Doze ستعمل بشكل طبيعي. فقط ميزات GMS تتطلب وجود خدمات جوجل.

## 📝 القائمة البيضاء لـ Doze

قم بتعديلها عبر واجهة WebUI أو مباشرةً عبر الملف `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
أضف تطبيقات المراسلة، البنوك، والمنبّهات لتجنب فقدان الإشعارات.

## 🙏 شكر وتقدير

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)