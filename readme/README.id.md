<div align="center">

# 🧊 FROSTY

### Pembeku GMS & Penghemat Baterai

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Fitur](#fitur) • [Instalasi](#instalasi) • [Penggunaan](#penggunaan) • [Kategori](#kategori-gms) • [FAQ](#faq)

---

[🇬🇧 English](https://github.com/Drsexo/Frosty) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
[🇧🇷 Português](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • 🇮🇩 Indonesia  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Gambaran Umum

Frosty mengoptimalkan masa pakai baterai dengan membekukan layanan GMS, menerapkan peningkatan doze di seluruh sistem, dan mengotomatiskan perilaku saat layar mati. Konfigurasikan semuanya melalui WebUI.

## Fitur

- **Pembekuan GMS**: Nonaktifkan layanan GMS di 8 kategori.
- **Doze Aplikasi (App Doze)**: Hapus aplikasi apa pun dari daftar pengecualian penghematan daya Doze Android. GMS juga dapat dipilih di sini, menggantikan tombol khusus GMS Doze yang lama.
- **Deep Doze**: Pembatasan latar belakang yang agresif untuk semua aplikasi (Moderat / Maksimum).
- **Pengoptimalan Layar Mati**: Secara otomatis menonaktifkan koneksi tertentu (Wi-Fi, Bluetooth, data, lokasi) dan membersihkan aplikasi dalam cache setelah penundaan layar mati yang dapat dikonfigurasi, lalu memulihkan semuanya saat tidak terkunci.
- **Blokir Pelacakan Google**: Menonaktifkan analitik GMS, telemetri Clearcut, polling Phenotype, dan pelacakan iklan.
- **Penyesuaian Kernel**: Optimalisasi penjadwal (scheduler), VM, jaringan, dan debug.
- **Pengoptimal RAM**: Menyesuaikan batas proses, pemadatan memori, dan perilaku zram.
- **System Props**: Menonaktifkan properti debug untuk menghemat RAM dan baterai.
- **Matikan Log**: Menghentikan proses log dan debug yang menguras baterai.
- **Penyetel Penghemat Baterai**: Menyesuaikan apa yang dilakukan penghemat baterai bawaan Android saat aktif.

## Instalasi

**Persyaratan:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Layanan Google Play (GMS)

1. Unduh dari [Releases](https://github.com/Drsexo/Frosty/releases).
2. Instal melalui root manager Anda.
3. Mulai ulang (Reboot).
4. Buka WebUI untuk mengaktifkan fitur.

> [!NOTE]
> Pengguna Magisk dapat menggunakan [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) untuk mengakses WebUI.

## Penggunaan

Buka WebUI dari root manager Anda:

- **Penyesuaian Sistem**: penyesuaian kernel, system props, nonaktifkan blur, matikan log, blokir pelacakan.
- **Doze**: Doze Aplikasi dengan pemilih aplikasi, Deep Doze dengan pemilih level dan editor daftar putih (whitelist).
- **Pengoptimalan Layar Mati**: tombol per koneksi, timer penundaan, pulihkan saat tidak terkunci.
- **Kategori GMS**: bekukan setiap kelompok layanan GMS.
- **Penyetel Penghemat Baterai**: sesuaikan perilaku penghemat baterai.
- **Impor / Ekspor**: cadangkan dan pulihkan konfigurasi lengkap Anda.

## Kategori GMS

#### Aman untuk Dinonaktifkan
| Kategori | Dampak |
|----------|--------|
| 📊 **Telemetri** | Tidak ada. Menghentikan iklan, analitik, pelacakan. |
| 🔄 **Latar Belakang** | Pembaruan otomatis mungkin tertunda. |

#### Dapat Merusak Fitur
| Kategori | Apa yang Rusak |
|----------|-------------|
| 📍 **Lokasi** | Maps, navigasi, Temukan Perangkat Saya, berbagi lokasi |
| 📡 **Konektivitas** | Chromecast, Quick Share, Fast Pair |
| ☁️ **Cloud** | Login Google, Isi Otomatis, kata sandi, pencadangan |
| 💳 **Pembayaran** | Google Pay, pembayaran tanpa sentuh NFC |
| ⌚ **Wearables** | Wear OS, Google Fit, pelacak kebugaran |
| 🎮 **Game** | Pencapaian Play Game, papan peringkat, penyimpanan cloud |

## Tingkat Deep Doze

| Fitur | Moderat | Maksimum |
|---------|:--------:|:-------:|
| Konstanta Doze Agresif | ✅ | ✅ |
| App Standby Buckets (jarang) | ✅ | ✅ |
| Pembunuh Wakelock (layar mati) | ✅ | ✅ |
| Tolak WAKE_LOCK | ❌ | ✅ |

## FAQ

**T: Mengapa notifikasi saya tertunda?**  
J: Doze Aplikasi dan Deep Doze membatasi aktivitas latar belakang. Tambahkan aplikasi pesan Anda ke daftar putih Deep Doze di WebUI.

**T: Ke mana perginya GMS Doze?**  
J: Sekarang ini adalah bagian dari Doze Aplikasi (App Doze). Buka pemilih Doze Aplikasi dan pilih GMS, efeknya sama, hanya saja antarmukanya disatukan.

**T: Apakah ini berfungsi tanpa Layanan Google Play?**  
J: Penyesuaian Kernel, System Props, Nonaktifkan Blur, Matikan Log, Pengoptimal RAM, dan Deep Doze semuanya tetap berfungsi. Fitur GMS tentu saja memerlukan GMS.

**T: Apakah ada yang diaktifkan setelah instalasi?**  
J: Tidak. Semuanya dimatikan secara default. Aktifkan hanya fitur yang Anda butuhkan.

## Kredit

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Skrip Menonaktifkan Komponen GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)

## Lisensi

Dilisensikan di bawah **GPL v3** lihat [LICENSE](LICENSE).  
Nama **Frosty** hanya diperuntukkan bagi rilis resmi. Fork harus menggunakan nama yang berbeda dan dengan jelas menyatakan bahwa itu tidak resmi. Penulis asli tidak bertanggung jawab atas kerusakan yang disebabkan oleh versi tidak resmi atau versi yang dimodifikasi.
