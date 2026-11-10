<div align="center">

# 🧊 FROSTY

### Congelador de GMS & Economizador de Bateria

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Recursos](#recursos) • [Instalação](#instalação) • [Uso](#uso) • [Categorias](#categorias-gms) • [FAQ](#faq)

---

[🇬🇧 English](https://github.com/Drsexo/Frosty) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
🇧🇷 Português • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

<div align="center">
<img src="images/pt-BR.png" width="600">
</div>

## Visão Geral

O Frosty otimiza a duração da bateria congelando os serviços do GMS, aplicando melhorias do Doze em todo o sistema e automatizando o comportamento com a tela desligada. Configure tudo através da WebUI.

## Recursos

- **Congelamento do GMS**: Desative os serviços do GMS em 8 categorias.
- **App Doze**: Remova qualquer aplicativo da lista de isenção de economia de energia do Doze do Android. O GMS também pode ser selecionado aqui, substituindo o antigo botão dedicado GMS Doze.
- **Deep Doze**: Restrições em segundo plano para todos os apps enquanto o dispositivo está bloqueado (Mínimo / Moderado / Máximo)
- **Otimização de Tela Desligada**: Desativa as conexões selecionadas (Wi-Fi, Bluetooth, dados, NFC, localização, sensores, modo de baixo consumo do painel) e executa opcionalmente o limpador de RAM após o dispositivo ficar bloqueado por um atraso configurável, restaura ao desbloquear
- **Desativar Rastreamento do Google**: Desativa as análises do GMS, a telemetria Clearcut, as pesquisas Phenotype e o rastreamento de anúncios.
- **Ajustes do Kernel**: Otimizações de agendamento (scheduler), VM, rede e depuração.
- **Otimizador de RAM**: Autoajuste de ZRAM, limiares LMK/LMKD/PSI, desativação de reclaim OEM, parâmetros de memória VM (Moderado / Máximo), limpador de RAM configurável.
- **Props do Sistema**: Desative as propriedades de depuração para economizar RAM e bateria.
- **Encerramento de Logs**: Pare processos de log e depuração que esgotam a bateria.
- **Afinador de Economia de Bateria**: Personalize o que a economia de bateria integrada do Android faz quando ativa.

## Instalação

**Requisitos:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services (GMS)

1. Baixe em [Releases](https://github.com/Drsexo/Frosty/releases).
2. Instale via o seu gerenciador root.
3. Reinicie.
4. Abra a WebUI para habilitar os recursos.

> [!NOTE]
> Usuários do Magisk podem usar a [KsuWebUI](https://github.com/KOWX712/KsuWebUIStandalone/releases) / [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) para acessar a WebUI.

> [!NOTE]
> No KernelSU/APatch, o Frosty solicita uma instalação a quente. Se o seu gerenciador suportar, atualize a WebUI após instalar em vez de reiniciar. Reinicie se algo parecer estranho. Magisk sempre exige reinício.


## Uso

Abra a WebUI do seu gerenciador root:

- **Ajustes do Sistema**: ajustes do kernel, props do sistema, desativar desfoque, encerramento de logs, desativação de rastreamento, otimizador e limpador de RAM.
- **Doze**: App Doze com seletor de aplicativos, Deep Doze com seletor de nível e editor de lista branca.
- **Otimização de Tela Desligada**: interruptores por conexão, cronômetros de atraso, restaurar ao desbloquear.
- **Categorias do GMS**: congele grupos individuais de serviços do GMS, ou use Ativar todas / Desativar todas para processar em lote as que ainda não estão no estado desejado.
- **Afinador de Economia de Bateria**: ajuste fino do comportamento de economia de bateria.
- **Importar / Exportar**: faça backup e restaure toda a sua configuração.

## Categorias do GMS

#### Seguro para desativar
| Categoria | Impacto |
|----------|--------|
| 📊 **Telemetria** | Nenhum. Para anúncios, análises e rastreamento. |
| 🔄 **Segundo Plano** | As atualizações automáticas podem sofrer atrasos. |

#### Pode afetar funcionalidades
| Categoria | Funcionalidades afetadas |
|----------|-------------|
| 📍 **Localização** | Maps, navegação, Encontre meu Dispositivo, compartilhamento de localização |
| 📡 **Conectividade** | Chromecast, Quick Share, Fast Pair |
| ☁️ **Nuvem** | Login do Google, Preenchimento automático, senhas, backups |
| 💳 **Pagamentos** | Google Pay, pagamento por aproximação NFC |
| ⌚ **Vestíveis** | Wear OS, Google Fit, rastreamento fitness |
| 🎮 **Jogos** | Conquistas do Play Games, placares, salvamento na nuvem |

## Níveis do Deep Doze

Todos os níveis reescrevem as constantes Doze e ativam a política flex-idle do JobScheduler no Android 13+ onde o sistema suporta. **Mínimo** é o nível mais suave: timeouts Doze mais curtos e o bucket de standby `frequent`, sem matador de wakelocks, sem negação de `WAKE_LOCK` e sem restrição de sensores. **Moderado** e **Máximo** executam um matador de wakelocks após 5 minutos de bloqueio do dispositivo e forçam IDLE nesse ponto; após esses 5 minutos os apps movem para o bucket `rare` (Moderado) ou `restricted` (Máximo), e desbloquear os restaura. As restrições seguem o estado de bloqueio, não o estado da tela: verificar as horas ou olhar a tela ambiente não reinicia nada, apenas desbloquear o faz. **Máximo** adicionalmente nega `WAKE_LOCK` para apps restritos, bloqueia acesso a sensores (incluindo levantar-para-acordar) para todos os apps exceto o discador padrão enquanto o dispositivo está bloqueado e a tela está desligada (restaurado durante chamadas e quando a tela liga), e mata wakelocks imediatamente ao aplicar.

## Otimizador de RAM

Autoajusta a compressão ZRAM, os limiares LMK / LMKD / PSI, os nós de reclaim OEM e os parâmetros de memória VM. **Máximo** escala os pesos LMK em ~50-70% para cima e usa limiares LMKD/PSI mais proativos. O Perfil de multitarefa (Desempenho / Equilibrado / Economia de energia) controla separadamente quantos aplicativos em segundo plano o ActivityManager mantém prontos para retomar instantaneamente.
## FAQ

**P: Por que minhas notificações estão atrasadas?**  
R: O App Doze e o Deep Doze restringem a atividade em segundo plano. Adicione seus aplicativos de mensagens à lista branca do Deep Doze na WebUI.


**P: O que acontece se eu desativar o módulo no gerenciador em vez de desligar os recursos?**  
R: O Frosty para de funcionar no próxima reinicialização, mas as configurações que já escreveu (constantes Doze, buckets de standby, app ops, configurações do sistema) permanecem ativas e seus monitores continuam funcionando até você reiniciar. Desligue os recursos na WebUI primeiro, depois desative o módulo. Remover o módulo executa a reversão de desinstalação do Frosty na próxima reinicialização.

**P: Para onde foi o GMS Doze?**  
R: Agora faz parte do App Doze. Abra o seletor do App Doze e selecione o GMS, o mesmo efeito, mas em uma interface unificada.

**P: Isso funciona sem o Google Play Services?**  
R: Ajustes do Kernel, Props do Sistema, Desativar Desfoque, Encerramento de Logs, Otimizador e Limpador de RAM, e Deep Doze funcionam todos. Os recursos do GMS exigem o GMS.

**P: Algo está ativado após a instalação?**  
R: Não. Tudo está desligado por padrão. Ative apenas o que você precisa.

## Créditos

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Script de desativação de componentes do GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)
- [xizt158](https://github.com/xizt159) por muitas contribuições de qualidade

## Licença

Licenciado sob **GPL v3**, veja [LICENSE](LICENSE).  
O nome **Frosty** é reservado apenas para versões oficiais. Forks devem usar um nome diferente e indicar claramente que não são oficiais. O autor original não assume qualquer responsabilidade por danos causados por versões não oficiais ou modificadas.
<div align="center">

# 🧊 FROSTY

### Congelador de GMS & Economizador de Bateria

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B0FF.svg)](https://github.com/topjohnwu/Magisk)
[![KernelSU](https://img.shields.io/badge/KernelSU-Supported-green.svg)](https://github.com/tiann/KernelSU)
[![APatch](https://img.shields.io/badge/APatch-Supported-orange.svg)](https://github.com/bmax121/APatch)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
![Downloads](https://img.shields.io/github/downloads/Drsexo/Frosty/total)

[Recursos](#recursos) • [Instalação](#instalação) • [Uso](#uso) • [Categorias](#categorias-gms) • [FAQ](#faq)

---

[🇬🇧 English](https://github.com/Drsexo/Frosty) • [🇫🇷 Français](README.fr.md) • [🇩🇪 Deutsch](README.de.md)  
[🇵🇱 Polski](README.pl.md) • [🇮🇹 Italiano](README.it.md) • [🇪🇸 Español](README.es.md)  
🇧🇷 Português • [🇹🇷 Türkçe](README.tr.md) • [🇮🇩 Indonesia](README.id.md)  
[🇷🇺 Русский](README.ru.md) • [🇺🇦 Українська](README.uk.md) • [🇨🇳 中文](README.zh-CN.md)  
[🇯🇵 日本語](README.ja.md) • [🇸🇦 العربية](README.ar.md)

</div>

<div align="center">
<img src="images/pt-BR.png" width="600">
</div>

## Visão Geral

O Frosty otimiza a duração da bateria congelando os serviços do GMS, aplicando melhorias do Doze em todo o sistema e automatizando o comportamento com a tela desligada. Configure tudo através da WebUI.

## Recursos

- **Congelamento do GMS**: Desative os serviços do GMS em 8 categorias.
- **App Doze**: Remova qualquer aplicativo da lista de isenção de economia de energia do Doze do Android. O GMS também pode ser selecionado aqui, substituindo o antigo botão dedicado GMS Doze.
- **Deep Doze**: Restrições em segundo plano para todos os apps enquanto o dispositivo está bloqueado (Mínimo / Moderado / Máximo)
- **Otimização de Tela Desligada**: Desativa as conexões selecionadas (Wi-Fi, Bluetooth, dados, NFC, localização, sensores, modo de baixo consumo do painel) e executa opcionalmente o limpador de RAM após o dispositivo ficar bloqueado por um atraso configurável, restaura ao desbloquear
- **Desativar Rastreamento do Google**: Desativa as análises do GMS, a telemetria Clearcut, as pesquisas Phenotype e o rastreamento de anúncios.
- **Ajustes do Kernel**: Otimizações de agendamento (scheduler), VM, rede e depuração.
- **Otimizador de RAM**: Autoajuste de ZRAM, limiares LMK/LMKD/PSI, desativação de reclaim OEM, parâmetros de memória VM (Moderado / Máximo), limpador de RAM configurável.
- **Props do Sistema**: Desative as propriedades de depuração para economizar RAM e bateria.
- **Encerramento de Logs**: Pare processos de log e depuração que esgotam a bateria.
- **Afinador de Economia de Bateria**: Personalize o que a economia de bateria integrada do Android faz quando ativa.

## Instalação

**Requisitos:** Android 9+, Magisk 20.4+ / KernelSU / APatch, Google Play Services (GMS)

1. Baixe em [Releases](https://github.com/Drsexo/Frosty/releases).
2. Instale via o seu gerenciador root.
3. Reinicie.
4. Abra a WebUI para habilitar os recursos.

> [!NOTE]
> Usuários do Magisk podem usar a [KsuWebUI](https://github.com/KOWX712/KsuWebUIStandalone/releases) / [WebUI-X](https://github.com/MMRLApp/WebUI-X-Portable/releases) para acessar a WebUI.

> [!NOTE]
> No KernelSU/APatch, o Frosty solicita uma instalação a quente. Se o seu gerenciador suportar, atualize a WebUI após instalar em vez de reiniciar. Reinicie se algo parecer estranho. Magisk sempre exige reinício.


## Uso

Abra a WebUI do seu gerenciador root:

- **Ajustes do Sistema**: ajustes do kernel, props do sistema, desativar desfoque, encerramento de logs, desativação de rastreamento, otimizador e limpador de RAM.
- **Doze**: App Doze com seletor de aplicativos, Deep Doze com seletor de nível e editor de lista branca.
- **Otimização de Tela Desligada**: interruptores por conexão, cronômetros de atraso, restaurar ao desbloquear.
- **Categorias do GMS**: congele grupos individuais de serviços do GMS, ou use Ativar todas / Desativar todas para processar em lote as que ainda não estão no estado desejado.
- **Afinador de Economia de Bateria**: ajuste fino do comportamento de economia de bateria.
- **Importar / Exportar**: faça backup e restaure toda a sua configuração.

## Categorias do GMS

#### Seguro para desativar
| Categoria | Impacto |
|----------|--------|
| 📊 **Telemetria** | Nenhum. Para anúncios, análises e rastreamento. |
| 🔄 **Segundo Plano** | As atualizações automáticas podem sofrer atrasos. |

#### Pode afetar funcionalidades
| Categoria | Funcionalidades afetadas |
|----------|-------------|
| 📍 **Localização** | Maps, navegação, Encontre meu Dispositivo, compartilhamento de localização |
| 📡 **Conectividade** | Chromecast, Quick Share, Fast Pair |
| ☁️ **Nuvem** | Login do Google, Preenchimento automático, senhas, backups |
| 💳 **Pagamentos** | Google Pay, pagamento por aproximação NFC |
| ⌚ **Vestíveis** | Wear OS, Google Fit, rastreamento fitness |
| 🎮 **Jogos** | Conquistas do Play Games, placares, salvamento na nuvem |

## Níveis do Deep Doze

Todos os níveis reescrevem as constantes Doze e ativam a política flex-idle do JobScheduler no Android 14+ onde o sistema suporta. **Mínimo** é o nível mais suave: timeouts Doze mais curtos e o bucket de standby `frequent`, sem matador de wakelocks, sem negação de `WAKE_LOCK` e sem restrição de sensores. **Moderado** e **Máximo** forçam IDLE enquanto o dispositivo está bloqueado e executam um matador de wakelocks após 5 minutos de bloqueio; após esses 5 minutos os apps movem para o bucket `rare` (Moderado) ou `restricted` (Máximo), e desbloquear os restaura. As restrições seguem o estado de bloqueio, não o estado da tela: verificar as horas ou olhar a tela ambiente não reinicia nada, apenas desbloquear o faz. **Máximo** adicionalmente nega `WAKE_LOCK` para apps restritos, bloqueia acesso a sensores (incluindo levantar-para-acordar) para todos os apps exceto o discador padrão enquanto bloqueado (restaurado durante chamadas e ao desbloquear), e mata wakelocks imediatamente ao aplicar.

## Otimizador de RAM

Autoajusta a compressão ZRAM, os limiares LMK / LMKD / PSI, os nós de reclaim OEM e os parâmetros de memória VM. **Máximo** escala os pesos LMK em ~50-70% para cima e usa limiares LMKD/PSI mais proativos. O Perfil de multitarefa (Desempenho / Equilibrado / Economia de energia) controla separadamente quantos aplicativos em segundo plano o ActivityManager mantém prontos para retomar instantaneamente.
## FAQ

**P: Por que minhas notificações estão atrasadas?**  
R: O App Doze e o Deep Doze restringem a atividade em segundo plano. Adicione seus aplicativos de mensagens à lista branca do Deep Doze na WebUI.


**P: O que acontece se eu desativar o módulo no gerenciador em vez de desligar os recursos?**  
R: O Frosty para de funcionar no próxima reinicialização, mas as configurações que já escreveu (constantes Doze, buckets de standby, app ops, configurações do sistema) permanecem ativas e seus monitores continuam funcionando até você reiniciar. Desligue os recursos na WebUI primeiro, depois desative o módulo. Remover o módulo executa a reversão de desinstalação do Frosty na próxima reinicialização.

**P: Para onde foi o GMS Doze?**  
R: Agora faz parte do App Doze. Abra o seletor do App Doze e selecione o GMS, o mesmo efeito, mas em uma interface unificada.

**P: Isso funciona sem o Google Play Services?**  
R: Ajustes do Kernel, Props do Sistema, Desativar Desfoque, Encerramento de Logs, Otimizador e Limpador de RAM, e Deep Doze funcionam todos. Os recursos do GMS exigem o GMS.

**P: Algo está ativado após a instalação?**  
R: Não. Tudo está desligado por padrão. Ative apenas o que você precisa.

## Créditos

- **kaushikieeee** [GhostGMS](https://github.com/kaushikieeee/GhostGMS)
- **gloeyisk** [Universal GMS Doze](https://github.com/gloeyisk/universal-gms-doze)
- **Azyrn** [DeepDoze Enforcer](https://github.com/Azyrn/DeepDoze-Enforcer)
- **MoZoiD** [Script de desativação de componentes do GMS](https://t.me/MoZoiDStack/137)
- **s1m** [SaverTuner](https://codeberg.org/s1m/savertuner)
- [xizt159](https://github.com/xizt159) por muitas contribuições de qualidade

## Licença

Licenciado sob **GPL v3**, veja [LICENSE](LICENSE).  
O nome **Frosty** é reservado apenas para versões oficiais. Forks devem usar um nome diferente e indicar claramente que não são oficiais. O autor original não assume qualquer responsabilidade por danos causados por versões não oficiais ou modificadas.
