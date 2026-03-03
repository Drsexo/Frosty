<div align="center">

# 🧊 FROSTY

### GMS Freezer & Battery Saver

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[✨ Recursos](#-recursos) •[📦 Instalação](#-instalação) • [📖 Uso](#-uso) •[🧊 Categorias GMS](#-categorias-gms) • [❓ FAQ](#-faq)

---

[🇬🇧 English](../README.md) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
🇧🇷 Português (BR) • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

## Visão Geral

O Frosty otimiza a duração da bateria congelando seletivamente componentes do Google Mobile Services (GMS) e aplicando melhorias no modo Doze em todo o sistema. Tudo é configurado através da interface WebUI após a instalação.

## ✨ Recursos

- **Congelamento GMS**: Desativa os serviços do GMS divididos em 8 categorias com controle granular.
- **GMS Doze**: Remove o GMS das listas brancas (Whitelist) de economia de energia.
- **Deep Doze**: Restrições em segundo plano altamente agressivas para todos os aplicativos (Moderado / Máximo).
- **Kernel Tweaks**: Otimizações no escalonador (Scheduler), rede e máquina virtual (VM).
- **Kill Logs**: Interrompe processos de log em segundo plano para economizar bateria e memória RAM.
- **System Props**: Desativa propriedades de depuração (debug) para economizar ainda mais RAM.
- **Configuração Ao Vivo**: Controle total em tempo real através da WebUI.

## 📦 Instalação

**Requisitos:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services.

1. Baixe o módulo na página de [Releases](https://github.com/Drsexo/Frosty/releases).
2. Instale usando o seu gerenciador root.
3. Reinicie o dispositivo.
4. Abra a WebUI para ativar os recursos — tudo começa **DESATIVADO** por padrão.

>[!NOTE]
> Usuários do Magisk podem utilizar o aplicativo [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) para acessar a WebUI.

## 📖 Uso

Abra a WebUI pelo seu gerenciador root. Você encontrará:

- **Otimizações do Sistema (System Tweaks)** — Ative Kernel Tweaks, System Props, desative o Blur e ative Kill Logs.
- **GMS Doze / Deep Doze** — Configure o nível de agressividade do modo de economia de bateria (Doze).
- **Categorias GMS** — Congele os grupos de serviços GMS individualmente.
- **Lista Branca (Whitelist)** — Proteja seus aplicativos importantes das restrições do Deep Doze.
- **Importar / Exportar** — Salve um backup e restaure suas configurações.

## 🧊 Categorias GMS

#### Seguras para desativar
| Categoria | Impacto |
|-----------|---------|
| 📊 **Telemetria** | Nenhum. Interrompe publicidade, análises estatísticas e rastreamento. |
| 🔄 **Segundo Plano** | As atualizações automáticas podem sofrer atrasos. |

#### O que deixará de funcionar
| Categoria | Funcionalidades afetadas |
|-----------|-------------------------|
| 📍 **Localização** | Google Maps, navegação GPS, Encontre Meu Dispositivo. |
| 📡 **Conectividade** | Chromecast, Quick Share, Fast Pair. |
| ☁️ **Nuvem** | Login do Google, preenchimento automático, senhas e backups. |
| 💳 **Pagamentos** | Google Pay, pagamentos via NFC. |
| ⌚ **Wearables** | Wear OS, Google Fit, rastreamento de fitness. |
| 🎮 **Jogos** | Conquistas do Google Play Games, placares, salvamento em nuvem. |

## 🔋 Níveis de Deep Doze

| Recurso | Moderado | Máximo |
|---------|:--------:|:------:|
| Constantes Doze agressivas | ✅ | ✅ |
| App Standby Buckets | ✅ | ✅ |
| Bloquear RUN_IN_BACKGROUND | ✅ | ✅ |
| Deep Idle (Tela Desligada) | ✅ | ✅ |
| Bloquear WAKE_LOCK | ❌ | ✅ |
| Wakelock Killer | ❌ | ✅ |
| Restrições rigorosas em Alarmes| ❌ | ✅ |

## ❓ FAQ (Perguntas Frequentes)

**P: Por que minhas notificações estão chegando com atraso?**
R: O GMS Doze e o Deep Doze restringem massivamente a atividade em segundo plano. Adicione seus aplicativos de mensagens à Lista Branca (Whitelist).

**P: O módulo funciona sem o Google Play Services?**
R: Sim. Os Kernel Tweaks, System Props, Disable Blur, Kill Logs e Deep Doze funcionarão mesmo sem o GMS.

## 📝 Lista Branca do Doze (Whitelist)

Edite a lista através da WebUI ou diretamente no arquivo `/data/adb/modules/Frosty/config/doze_whitelist.txt`.  
Adicione seus aplicativos de mensagens, bancos e alarmes para evitar a perda de notificações cruciais.

## 🙏 Créditos

- **kaushikieeee** — [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** — [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** — [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** — [GMS Component Disable Script](https://t.me/MoZoiDStack/137)
