<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Fitur](#-fitur) •[📦 Instalasi](#-instalasi) • [📖 Penggunaan](#-penggunaan) •[🧊 Kategori GMS](#-kategori-gms) • [❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • 🇮🇩 Indonesia  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Ikhtisar

Frosty mengoptimalkan masa pakai baterai dengan membekukan komponen Google Mobile Services (GMS) secara selektif dan menerapkan peningkatan mode hemat daya (Doze) di seluruh sistem. Semuanya dikonfigurasi melalui WebUI setelah instalasi.

## ✨ Fitur

- **Pembekuan GMS**: Menonaktifkan layanan GMS yang dibagi dalam 8 kategori dengan kontrol terperinci.
- **GMS Doze**: Menghapus GMS dari daftar pengecualian (Whitelist) hemat daya.
- **Deep Doze**: Pembatasan aktivitas latar belakang yang sangat agresif untuk semua aplikasi (Sedang / Maksimum).
- **Tweak Kernel**: Optimasi pada penjadwal (Scheduler), mesin virtual (VM), dan jaringan.
- **Pengoptimal RAM**: Menyesuaikan batas proses dan pengaturan memori sysfs.
- **Kill Logs**: Menghentikan proses pencatatan log di latar belakang untuk menghemat baterai dan RAM.
- **System Props**: Menonaktifkan properti debugging untuk membebaskan lebih banyak RAM.
- **Penyesuaian Penghemat Baterai**: Sesuaikan fungsi mode penghemat baterai Android, kontrol penundaan cadangan, penonaktifan sensor, perilaku GPS, penghemat data, dan lainnya. Pengaturan ini hanya akan memiliki efek yang terlihat saat penghemat baterai Android AKTIF.
- **Konfigurasi Langsung**: Kontrol penuh secara real-time melalui WebUI.

## 📦 Instalasi

**Persyaratan:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services.

1. Unduh modul dari halaman[Releases](https://github.com/Drsexo/Frosty/releases).
2. Instal melalui manajer root Anda.
3. Reboot perangkat.
4. Buka WebUI untuk mengaktifkan fitur — semuanya **DINONAKTIFKAN** secara default.

> [!NOTE]
> Pengguna Magisk dapat menggunakan aplikasi[WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) untuk mengakses WebUI.

## 📖 Penggunaan

Buka WebUI dari manajer root Anda. Anda akan menemukan:

- **Optimasi Sistem (System Tweaks)** — Aktifkan Tweak Kernel, System Props, nonaktifkan Blur, dan aktifkan Kill Logs.
- **GMS Doze / Deep Doze** — Mengonfigurasi tingkat agresivitas mode Doze.
- **Kategori GMS** — Membekukan grup layanan GMS secara individual.
- **Whitelist** — Melindungi aplikasi penting Anda dari pembatasan Deep Doze.
- **Impor / Ekspor** — Menyimpan cadangan dan memulihkan konfigurasi Anda.

## 🧊 Kategori GMS

#### Aman untuk dinonaktifkan
| Kategori | Dampak |
|----------|--------|
| 📊 **Telemetri** | Tidak ada. Menghentikan iklan, analitik, dan pelacakan oleh Google. |
| 🔄 **Latar Belakang** | Pembaruan aplikasi otomatis mungkin tertunda. |

#### Yang akan berhenti berfungsi
| Kategori | Fitur yang terdampak |
|----------|---------------------|
| 📍 **Lokasi** | Google Maps, navigasi GPS, Temukan Perangkat Saya. |
| 📡 **Konektivitas** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Cloud** | Login Google, isi otomatis (Autofill), kata sandi, dan cadangan. |
| 💳 **Pembayaran** | Google Pay, pembayaran via NFC. |
| ⌚ **Wearable** | Wear OS, Google Fit, pelacakan kebugaran. |
| 🎮 **Game** | Pencapaian Google Play Games, papan peringkat, penyimpanan cloud. |

## 🔋 Level Deep Doze

| Fitur | Sedang | Maksimum |
|-------|:------:|:--------:|
| Konstanta Doze yang Agresif | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Tolak RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (Saat Layar Mati) | ✅ | ✅ |
| Tolak WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |

## 🚀 Pengoptimal RAM

Menyesuaikan manajer proses dan subsistem memori Android berdasarkan total RAM perangkat Anda.  
Juga mengaktifkan USAP pool untuk peluncuran awal aplikasi (cold boot) yang lebih cepat dan menerapkan tweak sysfs (`swappiness`, `page-cluster`). Semua nilai dicadangkan dan dipulihkan sepenuhnya saat dinonaktifkan.

## ⚙️ Penyesuaian Penghemat Baterai

Mengonfigurasi apa yang dilakukan mode penghemat baterai bawaan Android saat aktif.

| Opsi | Deskripsi |
|--------|-------------|
| **Penghemat Data** | Membatasi data latar belakang untuk sebagian besar aplikasi |
| **Pemicu Suara** | Menonaktifkan deteksi kata kunci (misal "Hey Google") |
| **Cadangan Penuh** | Menunda pencadangan penuh perangkat |
| **Cadangan Data** | Menunda pencadangan nilai-kunci (pengaturan aplikasi) |
| **Paksa Standby** | Langsung menempatkan semua aplikasi latar belakang ke mode standby |
| **Pemeriksaan Latar** | Menerapkan pemeriksaan proses latar belakang yang lebih ketat |
| **Sensor** | Menonaktifkan sensor opsional di latar belakang |
| **Mode GPS** | Mengontrol akses lokasi saat penghemat baterai aktif |

## ❓ FAQ (Pertanyaan yang Sering Diajukan)

**T: Mengapa notifikasi saya masuk terlambat?**
J: GMS Doze dan Deep Doze sangat membatasi aktivitas latar belakang. Pastikan Anda menambahkan aplikasi pesan instan ke Whitelist.

**T: Apakah modul ini berfungsi tanpa Google Play Services?**
J: Ya. Tweak Kernel, System Props, Nonaktifkan Blur, Kill Logs, dan Deep Doze akan tetap berfungsi tanpa GMS.

## 📝 Whitelist Doze

Edit daftar tersebut melalui WebUI atau langsung di file `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Tambahkan aplikasi pesan, aplikasi perbankan, dan alarm Anda di sini agar tidak melewatkan notifikasi penting.

## 🙏 Kredit

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
- **s1m** — [SaverTuner](https://codeberg.org/s1m/savertuner)