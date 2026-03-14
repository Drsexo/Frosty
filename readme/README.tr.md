<div align="center">

# 🧊 FROSTY

### GMS Freezer & Pil Tasarrufu

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Özellikler](#-özellikler) • [📦 Kurulum](#-kurulum) • [📖 Kullanım](#-kullanım) • [🧊 GMS Kategorileri](#-gms-kategorileri) • [❓ SSS](#-sss)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • 🇹🇷 Türkçe • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Genel Bakış

Frosty, Google Mobil Hizmetleri (GMS) bileşenlerini seçici bir şekilde dondurarak ve sistem geneline çok daha iyi uyku/güç tasarrufu (Doze) özellikleri entegre ederek pil ömrünü optimize eder. Kurulum sonrası her şey WebUI üzerinden yapılandırılır.

## ✨ Özellikler

- **GMS Dondurma**: GMS servislerini, hassas kontrol sağlamak üzere 8 kategoriye bölerek devre dışı bırakır.
- **GMS Doze**: GMS'yi sistemin pil tasarrufu beyaz listesinden (Whitelist) çıkartır.
- **Deep Doze**: Tüm uygulamalar için oldukça agresif arka plan kısıtlamaları (Orta / Maksimum seviye).
- **Kernel Tweaks**: Zamanlayıcı (Scheduler), sanal bellek (VM) ve ağ optimizasyonları içerir.
- **RAM Optimize Edici**: Süreç sınırlarını ve sysfs bellek ayarlarını düzenler.
- **Kill Logs (Logları Durdurma)**: Pil ve RAM tüketen arka plan log/kayıt süreçlerini zorla durdurur.
- **System Props**: RAM tasarrufu yapmak adına gereksiz hata ayıklama (debug) özelliklerini kapatır.
- **Pil Tasarrufu Ayarlayıcı (Tuner)**: Android'in pil tasarrufu modunun neler yapacağını özelleştirin; yedekleme erteleme, sensör devre dışı bırakma, GPS davranışı, veri tasarrufu ve daha fazlasını kontrol edin. Bunlar yalnızca Android pil tasarrufu AÇIK olduğunda gözle görülür bir etki gösterir.
- **Canlı Yapılandırma**: WebUI üzerinden her şeyi gerçek zamanlı (anında) kontrol edin.

## 📦 Kurulum

**Gereksinimler:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Hizmetleri.

1.[Releases (Sürümler)](https://github.com/Drsexo/Frosty/releases) sayfasından indirin.
2. Kullandığınız Root yöneticisi üzerinden yükleyin.
3. Cihazınızı yeniden başlatın.
4. Özellikleri aktifleştirmek için WebUI'yi açın — varsayılan olarak her şey **KAPALI** gelir.

> [!NOTE]
> Magisk kullanıcıları WebUI arayüzüne erişmek için [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) uygulamasını kullanabilirler.

## 📖 Kullanım

WebUI arayüzünü root yöneticinizden açın. Şunları bulacaksınız:

- **Sistem İyileştirmeleri (System Tweaks)** — Kernel Tweaks, System Props, Blur kapatma ve Kill Logs seçeneklerini aktifleştirin.
- **GMS Doze / Deep Doze** — Doze pil tasarrufunun agresifliğini yapılandırın.
- **GMS Kategorileri** — GMS hizmet gruplarını teker teker, kontrollü bir şekilde dondurun.
- **Beyaz Liste (Whitelist)** — Deep Doze'un kısıtlamalarından etkilenmemesi için önemli uygulamalarınızı koruyun.
- **İçe / Dışa Aktar** — Konfigürasyonunuzu yedekleyin ve geri yükleyin.

## 🧊 GMS Kategorileri

#### Devre Dışı Bırakması Güvenli
| Kategori | Etki |
|----------|------|
| 📊 **Telemetri** | Herhangi bir bozulma yapmaz. Reklamları, analizleri ve izlemeyi durdurur. |
| 🔄 **Arka Plan** | Otomatik güncellemeler gecikebilir. |

#### Bozulacak / Etkilenen Özellikler
| Kategori | Çalışmayı Durduracak Şeyler |
|----------|----------------------------|
| 📍 **Konum** | Google Haritalar, GPS Navigasyon, Cihazımı Bul. |
| 📡 **Bağlantı** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Bulut (Cloud)** | Google hesabı ile giriş, otomatik parola tamamlama, yedeklemeler. |
| 💳 **Ödemeler** | Google Pay, NFC ile ödemeler. |
| ⌚ **Giyilebilir Cihazlar**| Wear OS, Google Fit, fitness izleme. |
| 🎮 **Oyunlar** | Play Oyunlar (Games) başarımları, liderlik tabloları ve bulut kayıtları. |

## 🔋 Deep Doze Seviyeleri

| Özellik | Orta | Maksimum |
|---------|:----:|:--------:|
| Agresif Doze Sabitleri | ✅ | ✅ |
| Uygulama Bekleme Grupları (App Standby Buckets)| ✅ | ✅ |
| RUN_IN_BACKGROUND İzni Engelleme | ✅ | ✅ |
| Deep Idle (Ekran kapalıyken derin uyku)| ✅ | ✅ |
| WAKE_LOCK İzni Engelleme | ❌ | ✅ |
| Wakelock Killer (Wakelock durdurucu) | ❌ | ✅ |

## 🚀 RAM Optimize Edici

Cihazınızın toplam RAM miktarına göre Android'in süreç yöneticisini ve bellek alt sistemini ayarlar.  
Ayrıca daha hızlı soğuk uygulama başlatmaları (cold launch) için USAP havuzunu etkinleştirir ve sysfs ayarlarını (`swappiness`, `page-cluster`) uygular. Tüm değerler yedeklenir ve devre dışı bırakıldığında tamamen geri yüklenir.

## ⚙️ Pil Tasarrufu Ayarlayıcı

Android'in yerleşik pil tasarrufu modunun etkinleştirildiğinde ne yapacağını yapılandırır.

| Seçenek | Açıklama |
|--------|-------------|
| **Veri Tasarrufu** | Çoğu uygulama için arka plan verilerini kısıtlar |
| **Sesli Uyanma** | Sesli komut algılamasını devre dışı bırakır (ör. "Hey Google") |
| **Tam Yedekleme** | Cihazın tam yedekleme işlemlerini erteler |
| **Veri Yedeklemesi** | Uygulama ayarları (Key/Value) yedeklemelerini erteler |
| **Beklemeyi Zorla** | Tüm arka plan uygulamalarını anında bekleme (standby) moduna geçirir |
| **Arka Plan Denetimi** | Arka plan işlemlerine daha sıkı kısıtlamalar uygular |
| **Sensörler** | Arka planda kritik olmayan sensörleri devre dışı bırakır |
| **GPS Modu** | Pil tasarrufu etkinken konum erişimini kontrol eder |

## ❓ SSS (Sıkça Sorulan Sorular)

**S: Bildirimlerim neden gecikmeli geliyor?**  
C: GMS Doze ve Deep Doze arka plan işlemlerini büyük ölçüde kısıtlar. Lütfen mesajlaşma ve WhatsApp gibi uygulamalarınızı Beyaz Listeye (Whitelist) ekleyin.

**S: Google Play Hizmetleri olmadan da çalışır mı?**  
C: Evet. Kernel Tweaks, System Props, Blur devre dışı bırakma, Kill Logs ve Deep Doze özellikleri GMS olmadan da çalışır.

## 📝 Doze Beyaz Listesi (Whitelist)

Beyaz listeyi WebUI üzerinden veya `/data/adb/modules/Frosty/config/doze_whitelist.txt` dosyası üzerinden düzenleyebilirsiniz.  
Bildirimleri kaçırmamak için kritik banka, alarm ve mesajlaşma uygulamalarını listeye mutlaka ekleyin.

## 🙏 Krediler / Teşekkürler

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)