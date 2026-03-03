<div align="center">

# 🧊 FROSTY

### Congelador GMS y Ahorrador de Batería

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Características](#-características) • [📦 Instalación](#-instalación) • [📖 Uso](#-uso) • [🧊 Categorías GMS](#-categorías-gms) • [❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • 🇪🇸 Español  
[🇧🇷 Português (BR)](README.pt-BR.md) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Descripción

Frosty optimiza la duración de la batería congelando selectivamente los componentes de Google Mobile Services (GMS) y aplicando mejoras de ahorro de energía en todo el sistema. Todo se configura a través de la interfaz WebUI después de la instalación.

## ✨ Características

- **Congelación GMS**: Desactiva servicios GMS divididos en 8 categorías con control granular.
- **GMS Doze**: Elimina a GMS de las listas blancas (Whitelist) de ahorro de energía.
- **Deep Doze**: Restricciones muy agresivas en segundo plano para todas las aplicaciones (Moderado / Máximo).
- **Kernel Tweaks**: Optimizaciones en el planificador (Scheduler), red y máquina virtual (VM).
- **Kill Logs**: Detiene los procesos de registro (logging) en segundo plano que consumen batería y memoria.
- **System Props**: Desactiva propiedades de depuración para ahorrar memoria RAM.
- **Configuración en Vivo**: Control total mediante la WebUI con interruptores en tiempo real.

## 📦 Instalación

**Requisitos:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services.

1. Descarga el módulo desde la página de [Releases](https://github.com/Drsexo/Frosty/releases).
2. Instálalo mediante tu gestor root.
3. Reinicia tu dispositivo.
4. Abre la WebUI para activar las funciones — todo comienza **DESACTIVADO** por defecto.

> [!NOTE]
> Los usuarios de Magisk pueden usar la aplicación [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) para acceder a la WebUI.

## 📖 Uso

Abre la WebUI desde tu gestor root. Encontrarás:

- **Ajustes del Sistema (System Tweaks)** — Activa Kernel Tweaks, System Props, desactiva el desenfoque (Blur) y elimina logs (Kill Logs).
- **GMS Doze / Deep Doze** — Configura el nivel de agresividad del ahorro de energía Doze.
- **Categorías GMS** — Congela grupos de servicios de GMS individualmente.
- **Lista Blanca (Whitelist)** — Protege tus aplicaciones importantes del Deep Doze.
- **Importar / Exportar** — Guarda una copia de seguridad y restaura tu configuración.

## 🧊 Categorías GMS

#### Seguras para desactivar
| Categoría | Impacto |
|-----------|---------|
| 📊 **Telemetría** | Ninguno. Detiene publicidad, estadísticas y rastreo de Google. |
| 🔄 **Segundo Plano** | Las actualizaciones automáticas pueden sufrir retrasos. |

#### Qué dejará de funcionar
| Categoría | Funciones afectadas |
|-----------|--------------------|
| 📍 **Ubicación** | Google Maps, navegación GPS, Encontrar mi dispositivo. |
| 📡 **Conectividad** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Nube** | Inicio de sesión en Google, autocompletado de contraseñas, copias de seguridad. |
| 💳 **Pagos** | Google Pay, pagos inalámbricos por NFC. |
| ⌚ **Wearables** | Wear OS, Google Fit, seguimiento de actividad. |
| 🎮 **Juegos** | Logros de Google Play Games, tablas de clasificación, guardado en la nube. |

## 🔋 Niveles de Deep Doze

| Función | Moderado | Máximo |
|---------|:--------:|:------:|
| Constantes Doze agresivas | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Bloquear RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (Con pantalla apagada) | ✅ | ✅ |
| Bloquear WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |
| Restricciones estrictas en Alarmas | ❌ | ✅ |

## ❓ FAQ (Preguntas Frecuentes)

**P: ¿Por qué mis notificaciones llegan con retraso?**
R: GMS Doze y Deep Doze restringen masivamente la actividad en segundo plano. Agrega tus aplicaciones de mensajería a la Lista Blanca (Whitelist).

**P: ¿El módulo funciona sin Google Play Services?**
R: Sí. Los Kernel Tweaks, System Props, la desactivación del Blur, Kill Logs y el Deep Doze seguirán funcionando sin GMS.

## 📝 Lista Blanca de Doze (Whitelist)

Edita la lista a través de la WebUI o directamente en `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Añade tus aplicaciones de mensajería, bancos y alarmas para evitar perder notificaciones cruciales.

## 🙏 Créditos

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
