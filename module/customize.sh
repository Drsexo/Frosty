#!/system/bin/sh
# Frosty - GMS Freezer / Battery Saver
# Author: Drsexo (GitHub)

if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
  export MODULE_HOT_INSTALL_REQUEST="true"
fi

TIMEOUT=30

if ! command -v timeout >/dev/null 2>&1; then
  timeout() {
    local _dur="$1"; shift
    "$@" &
    local _cpid=$!
    (
      sleep "$_dur"
      kill -TERM "$_cpid" 2>/dev/null
      sleep 1
      kill -0 "$_cpid" 2>/dev/null && kill -KILL "$_cpid" 2>/dev/null
    ) &
    local _wpid=$!
    wait "$_cpid" 2>/dev/null
    local _rc=$?
    kill "$_wpid" 2>/dev/null
    return "$_rc"
  }
fi

HAS_GETEVENT=1
if ! command -v getevent >/dev/null 2>&1; then
  HAS_GETEVENT=0
fi

_wait_vol_key() {
  local _budget="$1" _deadline _now _chunk _ev
  _deadline=$(( $(date +%s) + _budget ))
  while true; do
    _now=$(date +%s)
    _chunk=$(( _deadline - _now ))
    [ "$_chunk" -le 0 ] && { echo timeout; return 0; }
    [ "$_chunk" -gt 2 ] && _chunk=2
    _ev=$(timeout "$_chunk" getevent -qlc 1 2>/dev/null)
    case "$_ev" in
      *KEY_VOLUMEUP*DOWN*)   echo up;   return 0 ;;
      *KEY_VOLUMEDOWN*DOWN*) echo down; return 0 ;;
    esac
  done
}

print_banner() {
  ui_print ""
  ui_print "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⡀⠀⣠⡆⠀⠀⠀⠀⠀⠀⠀⠀⣤⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠈⢻⣿⠋⠀⠀⠀⠀⠀⢸⣧⠀⢀⣾⣦⣤⣤⣄⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⢿⡇⠀⣶⠀⠀⠺⣦⣼⣧⣴⡿⠀⠀⠀⠀⠀⢻⣦⣾⣛⠉⠉⠉⠁⠀⠀"
  ui_print "⠀⠀⢶⣶⣤⣼⣧⣰⣏⠀⠀⠀⠈⠹⣿⠋⠀⠀⠀⠀⠀⢀⣾⠟⠛⠛⠻⠿⠂⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⢠⣬⣿⣿⣿⡀⢀⡄⢠⣤⣿⣤⡦⠀⢿⣄⣴⣟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠀⠀⢈⣿⣿⣇⠀⠙⣿⠋⠀⠀⣨⡿⠟⠛⠃⠀⠀⠀⢀⣶⠀⣠⡀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⢠⡀⠀⠀⠀⠀⠈⠙⢷⣤⣿⡆⢀⣴⠟⠀⠀⠀⣠⡟⠀⢀⣾⢃⣴⠟⠁⠀"
  ui_print "⠰⣦⡀⠀⠘⢿⣄⠀⢰⣦⣀⣀⣀⣹⣿⣷⣿⣷⣤⣴⡶⢾⣿⣷⡾⢿⣿⡟⠿⣶⣄⠀"
  ui_print "⠀⠈⣿⣷⣶⣶⣿⣿⠿⢿⣿⠟⠋⣹⣿⡟⠻⣿⣄⠀⠀⠀⠈⠙⠀⠀⠙⢿⣦⠀⠙⠁"
  ui_print "⠰⠾⠋⠀⠀⣾⠟⠁⠀⣾⡁⢀⣴⠟⠸⣧⠀⠈⠻⣷⣶⣤⡤⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⣀⠀⠀⠈⣻⣿⣿⠀⠀⣿⠀⠀⠀⢸⡟⠻⣦⣄⣀⣠⣤⣄⡀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠙⠛⢻⣾⡟⠉⠃⠀⣠⣿⣄⠀⠀⠈⠁⠀⢸⣿⢿⣿⡷⠾⠃⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⢶⣶⣦⣶⡟⢿⠃⠀⠀⠚⠋⢻⡟⠗⠀⠀⠀⠀⠘⠿⠀⢿⡄⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⢨⡿⠀⠈⠀⠀⠀⠀⠀⣸⣧⡀⠀⠀⠀⠀⠀⠀⠀⠘⠁⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⢀⣴⠿⣿⡿⢶⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠟⠀⠀⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
  ui_print ""
  ui_print "        _______  ____  ____________  __"
  ui_print "       / __/ _ \/ __ \/ __/_  __/\ \/ /"
  ui_print "      / _// , _/ /_/ /\ \  / /    \  / "
  ui_print "     /_/ /_/|_|\____/___/ /_/     /_/  "
  ui_print ""
  ui_print "        ❆  Freeze your battery drain  ❆"
}

print_section() {
  ui_print ""
  ui_print "── $1 ──"
}

# Permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/scripts/frosty.sh" 0 0 0755
set_perm "$MODPATH/scripts/screen_off_opt.sh" 0 0 0755
set_perm "$MODPATH/scripts/deep_doze.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/scripts/app_doze.sh" 0 0 0755
mkdir -p "$MODPATH/config"
mkdir -p "$MODPATH/logs"

# GMS check
if ! pm list packages 2>/dev/null | grep -qx 'package:com.google.android.gms'; then
  ui_print ""
  ui_print "⚠️ Google Play Services not found"
  ui_print "GMS freezing and doze won't work"
  ui_print ""
fi

print_banner

# Language Selection
_detect_lang() {
  local loc
  loc=$(getprop persist.sys.locale 2>/dev/null)
  [ -z "$loc" ] && loc=$(getprop ro.product.locale 2>/dev/null)
  [ -z "$loc" ] && loc=$(getprop persist.sys.language 2>/dev/null)
  echo "$loc" | cut -d'-' -f1 | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]'
}

_LANG=$(_detect_lang)
INSTALL_LANG="en"

case "$_LANG" in
  fr) _LANG_FLAG="🇫🇷"; _LANG_NAME="Français" ;;
  de) _LANG_FLAG="🇩🇪"; _LANG_NAME="Deutsch" ;;
  pl) _LANG_FLAG="🇵🇱"; _LANG_NAME="Polski" ;;
  it) _LANG_FLAG="🇮🇹"; _LANG_NAME="Italiano" ;;
  es) _LANG_FLAG="🇪🇸"; _LANG_NAME="Español" ;;
  pt) _LANG_FLAG="🇧🇷"; _LANG_NAME="Português" ;;
  tr) _LANG_FLAG="🇹🇷"; _LANG_NAME="Türkçe" ;;
  id) _LANG_FLAG="🇮🇩"; _LANG_NAME="Indonesia" ;;
  ru) _LANG_FLAG="🇷🇺"; _LANG_NAME="Русский" ;;
  uk) _LANG_FLAG="🇺🇦"; _LANG_NAME="Українська" ;;
  zh) _LANG_FLAG="🇨🇳"; _LANG_NAME="中文" ;;
  ja) _LANG_FLAG="🇯🇵"; _LANG_NAME="日本語" ;;
  ar) _LANG_FLAG="🇸🇦"; _LANG_NAME="العربية" ;;
  *)  _LANG_FLAG="";  _LANG_NAME="" ;;
esac

if [ -n "$_LANG_NAME" ]; then
  print_section "$_LANG_FLAG $_LANG_NAME detected"
  ui_print "⬆️ Vol UP = Use $_LANG_NAME"
  ui_print "⬇️ Vol DOWN = Keep English 🇬🇧"
  ui_print "⏱️ ${TIMEOUT}s timeout → English"

  _chosen_lang="en"
  if [ "$HAS_GETEVENT" -eq 0 ]; then
    ui_print "→ English (auto)"
  else
    case "$(_wait_vol_key "$TIMEOUT")" in
      up)   ui_print "→ $_LANG_FLAG $_LANG_NAME ✅"; _chosen_lang="$_LANG" ;;
      down) ui_print "→ 🇬🇧 English ✅"; _chosen_lang="en" ;;
      *)    ui_print "→ 🇬🇧 English (timeout)"; _chosen_lang="en" ;;
    esac
  fi
  INSTALL_LANG="$_chosen_lang"
fi

_s() {
  local key="$1"
  case "${INSTALL_LANG}:${key}" in

    # EXISTING CONFIG
    fr:cfg_detected)  echo "♻️ Config existante détectée" ;;
    de:cfg_detected)  echo "♻️ Bestehende Konfig erkannt" ;;
    pl:cfg_detected)  echo "♻️ Wykryto istniejący config" ;;
    it:cfg_detected)  echo "♻️ Config esistente rilevata" ;;
    es:cfg_detected)  echo "♻️ Config existente detectada" ;;
    pt:cfg_detected)  echo "♻️ Config existente detectada" ;;
    tr:cfg_detected)  echo "♻️ Mevcut yapılandırma tespit edildi" ;;
    id:cfg_detected)  echo "♻️ Konfigurasi saat ini terdeteksi" ;;
    ru:cfg_detected)  echo "♻️ Обнаружен существующий конфиг" ;;
    uk:cfg_detected)  echo "♻️ Виявлено наявний конфіг" ;;
    zh:cfg_detected)  echo "♻️ 检测到现有配置" ;;
    ja:cfg_detected)  echo "♻️ 既存の設定を検出" ;;
    ar:cfg_detected)  echo "♻️ تم اكتشاف إعدادات محفوظة" ;;
     *:cfg_detected)  echo "♻️ Existing config detected" ;;

    fr:cfg_vol_keep)  echo "  ⬆️ Vol HAUT   = Garder config & whitelist" ;;
    de:cfg_vol_keep)  echo "  ⬆️ Vol HOCH   = Konfig & Whitelist behalten" ;;
    pl:cfg_vol_keep)  echo "  ⬆️ Vol GÓRA   = Zachowaj config i whitelistę" ;;
    it:cfg_vol_keep)  echo "  ⬆️ Vol SU     = Mantieni config & whitelist" ;;
    es:cfg_vol_keep)  echo "  ⬆️ Vol ARRIBA = Mantener config y whitelist" ;;
    pt:cfg_vol_keep)  echo "  ⬆️ Vol CIMA   = Manter config e whitelist" ;;
    tr:cfg_vol_keep)  echo "  ⬆️ Ses YUKARI = Ayarları ve Whitelist'i koru" ;;
    id:cfg_vol_keep)  echo "  ⬆️ Vol ATAS   = Simpan config & whitelist" ;;
    ru:cfg_vol_keep)  echo "  ⬆️ Гром +     = Оставить конфиг и Whitelist" ;;
    uk:cfg_vol_keep)  echo "  ⬆️ Гучн. +    = Зберегти конфіг та Whitelist" ;;
    zh:cfg_vol_keep)  echo "  ⬆️ 音量上      = 保留配置和白名单" ;;
    ja:cfg_vol_keep)  echo "  ⬆️ 音量UP      = 設定とホワイトリストを保持" ;;
    ar:cfg_vol_keep)  echo "  ⬆️ رفع الصوت   = الإبقاء على الإعدادات والقائمة" ;;
     *:cfg_vol_keep)  echo "⬆️ Vol UP = Keep config & whitelist" ;;

    fr:cfg_vol_reset) echo "⬇️ Vol BAS = Réinit. valeurs par défaut" ;;
    de:cfg_vol_reset) echo "⬇️ Vol RUNTER = Auf Standard zurücksetzen" ;;
    pl:cfg_vol_reset) echo "⬇️ Vol DÓŁ = Resetuj do domyślnych" ;;
    it:cfg_vol_reset) echo "⬇️ Vol GIÙ = Ripristina valori predefiniti" ;;
    es:cfg_vol_reset) echo "⬇️ Vol ABAJO = Restablecer valores por defecto" ;;
    pt:cfg_vol_reset) echo "⬇️ Vol BAIXO = Redefinir padrões" ;;
    tr:cfg_vol_reset) echo "⬇️ Ses AŞAĞI = Varsayılanlara sıfırla" ;;
    id:cfg_vol_reset) echo "⬇️ Vol BAWAH = Reset ke default" ;;
    ru:cfg_vol_reset) echo "⬇️ Гром - = Сбросить настройки" ;;
    uk:cfg_vol_reset) echo "⬇️ Гучн. - = Скинути налаштування" ;;
    zh:cfg_vol_reset) echo "⬇️ 音量下键 = 恢复默认设置" ;;
    ja:cfg_vol_reset) echo "⬇️ 音量DOWN = デフォルトに戻す" ;;
    ar:cfg_vol_reset) echo "⬇️ خفض الصوت = استعادة الافتراضي" ;;
     *:cfg_vol_reset) echo "⬇️ Vol DOWN = Reset to defaults" ;;

    fr:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → conserve la configuration" ;;
    de:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → behält Konfiguration" ;;
    pl:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → zachowuje konfigurację" ;;
    it:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → mantiene configurazione" ;;
    es:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → conserva la configuración" ;;
    pt:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → mantém a configuração" ;;
    tr:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → mevcut ayarları korur" ;;
    id:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → pertahankan konfigurasi" ;;
    ru:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → сохраняет конфигурацию" ;;
    uk:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → зберігає конфігурацію" ;;
    zh:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → 自动保留配置" ;;
    ja:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s → 既存の設定を保持" ;;
    ar:cfg_timeout)   echo "  ⏱️ مهلة ${TIMEOUT} ثانية → الاحتفاظ بالإعدادات" ;;
     *:cfg_timeout)   echo "⏱️ ${TIMEOUT}s timeout → keeps existing" ;;

    fr:cfg_kept)      echo "  → Configuration existante conservée ✅" ;;
    de:cfg_kept)      echo "  → Bestehende Konfiguration beibehalten ✅" ;;
    pl:cfg_kept)      echo "  → Istniejąca konfiguracja zachowana ✅" ;;
    it:cfg_kept)      echo "  → Configurazione esistente mantenuta ✅" ;;
    es:cfg_kept)      echo "  → Configuración existente conservada ✅" ;;
    pt:cfg_kept)      echo "  → Configuração existente mantida ✅" ;;
    tr:cfg_kept)      echo "  → Mevcut yapılandırma korundu ✅" ;;
    id:cfg_kept)      echo "  → Konfigurasi saat ini dipertahankan ✅" ;;
    ru:cfg_kept)      echo "  → Текущая конфигурация сохранена ✅" ;;
    uk:cfg_kept)      echo "  → Поточна конфігурація збережена ✅" ;;
    zh:cfg_kept)      echo "  → 已保留现有配置 ✅" ;;
    ja:cfg_kept)      echo "  → 既存の設定を保持しました ✅" ;;
    ar:cfg_kept)      echo "  → تم الاحتفاظ بالإعدادات الحالية ✅" ;;
     *:cfg_kept)      echo "→ Keeping existing config ✅" ;;

    fr:cfg_reset)     echo "  → Réinitialisation aux valeurs par défaut ⚙️" ;;
    de:cfg_reset)     echo "  → Auf Standardwerte zurückgesetzt ⚙️" ;;
    pl:cfg_reset)     echo "  → Zresetowano do ustawień domyślnych ⚙️" ;;
    it:cfg_reset)     echo "  → Ripristinato ai valori predefiniti ⚙️" ;;
    es:cfg_reset)     echo "  → Restableciendo valores por defecto ⚙️" ;;
    pt:cfg_reset)     echo "  → Redefinindo para os padrões ⚙️" ;;
    tr:cfg_reset)     echo "  → Varsayılan ayarlara sıfırlandı ⚙️" ;;
    id:cfg_reset)     echo "  → Mengembalikan ke default ⚙️" ;;
    ru:cfg_reset)     echo "  → Сброс до настроек по умолчанию ⚙️" ;;
    uk:cfg_reset)     echo "  → Скидання до типових налаштувань ⚙️" ;;
    zh:cfg_reset)     echo "  → 已重置为默认设置 ⚙️" ;;
    ja:cfg_reset)     echo "  → デフォルト設定にリセットしました ⚙️" ;;
    ar:cfg_reset)     echo "  → استعادة الوضع الافتراضي ⚙️" ;;
     *:cfg_reset)     echo "→ Resetting to defaults ⚙️" ;;

    # INSTALLATION COMPLETE
    fr:done_title)    echo "✅  Installation Terminée" ;;
    de:done_title)    echo "✅  Installation Abgeschlossen" ;;
    pl:done_title)    echo "✅  Instalacja Zakończona" ;;
    it:done_title)    echo "✅  Installazione Completata" ;;
    es:done_title)    echo "✅  Instalación Completada" ;;
    pt:done_title)    echo "✅  Instalação Concluída" ;;
    tr:done_title)    echo "✅  Kurulum Tamamlandı" ;;
    id:done_title)    echo "✅  Instalasi Selesai" ;;
    ru:done_title)    echo "✅  Установка Завершена" ;;
    uk:done_title)    echo "✅  Встановлення Завершено" ;;
    zh:done_title)    echo "✅  安装完成" ;;
    ja:done_title)    echo "✅  インストール完了" ;;
    ar:done_title)    echo "✅  اكتمل التثبيت" ;;
     *:done_title)    echo "✅ Installation Complete" ;;

    fr:done_reboot)   echo "  🔄 Redémarrez votre appareil" ;;
    de:done_reboot)   echo "  🔄 Gerät neu starten" ;;
    pl:done_reboot)   echo "  🔄 Uruchom ponownie urządzenie" ;;
    it:done_reboot)   echo "  🔄 Riavvia il dispositivo" ;;
    es:done_reboot)   echo "  🔄 Reinicia tu dispositivo" ;;
    pt:done_reboot)   echo "  🔄 Reinicie seu dispositivo" ;;
    tr:done_reboot)   echo "  🔄 Cihazı yeniden başlat" ;;
    id:done_reboot)   echo "  🔄 Restart perangkat Anda" ;;
    ru:done_reboot)   echo "  🔄 Перезагрузите устройство" ;;
    uk:done_reboot)   echo "  🔄 Перезавантажте пристрій" ;;
    zh:done_reboot)   echo "  🔄 重启设备" ;;
    ja:done_reboot)   echo "  🔄 デバイスを再起動" ;;
    ar:done_reboot)   echo "  🔄 أعد تشغيل جهازك" ;;
     *:done_reboot)   echo "🔄 Reboot your device" ;;

    fr:done_hotinstall)      echo "  ⚡ Installation à chaud demandée (KSU/APatch)" ;;
    de:done_hotinstall)      echo "  ⚡ Hot-Install angefordert (KSU/APatch)" ;;
    pl:done_hotinstall)      echo "  ⚡ Zażądano instalacji na gorąco (KSU/APatch)" ;;
    it:done_hotinstall)      echo "  ⚡ Installazione a caldo richiesta (KSU/APatch)" ;;
    es:done_hotinstall)      echo "  ⚡ Instalación en caliente solicitada (KSU/APatch)" ;;
    pt:done_hotinstall)      echo "  ⚡ Instalação a quente solicitada (KSU/APatch)" ;;
    tr:done_hotinstall)      echo "  ⚡ Sıcak kurulum istendi (KSU/APatch)" ;;
    id:done_hotinstall)      echo "  ⚡ Instalasi panas diminta (KSU/APatch)" ;;
    ru:done_hotinstall)      echo "  ⚡ Запрошена горячая установка (KSU/APatch)" ;;
    uk:done_hotinstall)      echo "  ⚡ Запрошено гаряче встановлення (KSU/APatch)" ;;
    zh:done_hotinstall)      echo "  ⚡ 已请求热安装 (KSU/APatch)" ;;
    ja:done_hotinstall)      echo "  ⚡ ホットインストールが要求されました (KSU/APatch)" ;;
    ar:done_hotinstall)      echo "  ⚡ تم طلب التثبيت الساخن (KSU/APatch)" ;;
     *:done_hotinstall)      echo "⚡ Hot install requested (KSU/APatch)" ;;

    fr:done_hotinstall_note)      echo "Actualisez la WebUI, redémarrez si anormal" ;;
    de:done_hotinstall_note)      echo "WebUI aktualisieren, bei Auffälligkeiten neu starten" ;;
    pl:done_hotinstall_note)      echo "Odśwież WebUI, uruchom ponownie jeśli coś nie tak" ;;
    it:done_hotinstall_note)      echo "Aggiorna la WebUI, riavvia se qualcosa non va" ;;
    es:done_hotinstall_note)      echo "Actualiza la WebUI, reinicia si algo se ve raro" ;;
    pt:done_hotinstall_note)      echo "Atualize a WebUI, reinicie se algo parecer estranho" ;;
    tr:done_hotinstall_note)      echo "WebUI'yi yenileyin, sorun görürseniz yeniden başlatın" ;;
    id:done_hotinstall_note)      echo "Muat ulang WebUI, mulai ulang jika ada yang tidak beres" ;;
    ru:done_hotinstall_note)      echo "Обновите WebUI, перезагрузите если что-то не так" ;;
    uk:done_hotinstall_note)      echo "Оновіть WebUI, перезавантажте якщо щось не так" ;;
    zh:done_hotinstall_note)      echo "刷新 WebUI，如有异常请重启" ;;
    ja:done_hotinstall_note)      echo "WebUI を再読み込み、異常があれば再起動" ;;
    ar:done_hotinstall_note)      echo "حدّث WebUI، أعد التشغيل إذا بدا غير طبيعي" ;;
     *:done_hotinstall_note)      echo "Refresh WebUI, reboot if it looks off" ;;

    fr:done_webui)    echo "  ⚙️  Ouvrez la WebUI pour activer les fonctionnalités" ;;
    de:done_webui)    echo "  ⚙️  Öffne die WebUI, um Funktionen zu aktivieren" ;;
    pl:done_webui)    echo "  ⚙️  Otwórz WebUI, aby aktywować funkcje" ;;
    it:done_webui)    echo "  ⚙️  Apri la WebUI per abilitare le funzionalità" ;;
    es:done_webui)    echo "  ⚙️  Abre la WebUI para activar las funciones" ;;
    pt:done_webui)    echo "  ⚙️  Abra a WebUI para ativar os recursos" ;;
    tr:done_webui)    echo "  ⚙️  Özellikleri açmak için WebUI'yi kullanın" ;;
    id:done_webui)    echo "  ⚙️  Buka WebUI untuk mengaktifkan fitur" ;;
    ru:done_webui)    echo "  ⚙️  Откройте WebUI для включения функций модуля" ;;
    uk:done_webui)    echo "  ⚙️  Відкрийте WebUI для увімкнення функцій модуля" ;;
    zh:done_webui)    echo "  ⚙️  请打开 WebUI 启用所需的模块功能" ;;
    ja:done_webui)    echo "  ⚙️  WebUI を開いて機能を有効化してください" ;;
    ar:done_webui)    echo "  ⚙️  افتح واجهة WebUI لتفعيل الميزات" ;;
     *:done_webui)    echo "⚙️ Open the WebUI to enable" ;;

    fr:done_off)      echo "(tout DÉSACTIVÉ par défaut)" ;;
    de:done_off)      echo "(standardmäßig alles AUS)" ;;
    pl:done_off)      echo "     (domyślnie wszystko jest WYŁĄCZONE)" ;;
    it:done_off)      echo "(tutto DISATTIVATO di default)" ;;
    es:done_off)      echo "(todo DESACTIVADO por defecto)" ;;
    pt:done_off)      echo "(tudo DESATIVADO por padrão)" ;;
    tr:done_off)      echo "(varsayılan olarak hepsi KAPALI)" ;;
    id:done_off)      echo "(semua NONAKTIF secara default)" ;;
    ru:done_off)      echo "     (по умолчанию всё ОТКЛЮЧЕНО)" ;;
    uk:done_off)      echo "     (за замовчуванням усе ВИМКНЕНО)" ;;
    zh:done_off)      echo "（默认全部关闭）" ;;
    ja:done_off)      echo "（デフォルトですべてオフ）" ;;
    ar:done_off)      echo "     (كل شيء معطل افتراضياً)" ;;
     *:done_off)      echo "features (all OFF by default)" ;;

    fr:stay_frosty)   echo "❆  Reste au frais !  ❆" ;;
    de:stay_frosty)   echo "❆  Bleib cool!  ❆" ;;
    pl:stay_frosty)   echo "❆  Bądź Frosty!  ❆" ;;
    it:stay_frosty)   echo "❆  Resta Frosty!  ❆" ;;
    es:stay_frosty)   echo "❆  ¡Quédate Frosty!  ❆" ;;
    pt:stay_frosty)   echo "❆  Fique Frosty!  ❆" ;;
    tr:stay_frosty)   echo "❆  Frosty kal!  ❆" ;;
    id:stay_frosty)   echo "❆  Tetap Frosty!  ❆" ;;
    ru:stay_frosty)   echo "❆  Оставайся Frosty!  ❆" ;;
    uk:stay_frosty)   echo "❆  Залишайся Frosty!  ❆" ;;
    zh:stay_frosty)   echo "❆  保持凉爽！  ❆" ;;
    ja:stay_frosty)   echo "❆  Stay Frosty!  ❆" ;;
    ar:stay_frosty)   echo "❆  Stay Frosty!  ❆" ;;
     *:stay_frosty)   echo "❆ Stay Frosty! ❆" ;;

  esac
}

s() { _s "$1" | sed 's/^ *//; s/  */ /g'; }

stop_old_monitors() {
  local _old="/data/adb/modules/$MODID"
  [ -d "$_old/tmp" ] || return 0
  . "$MODPATH/scripts/monitor_common.sh"
  [ -f "$_old/scripts/screen_off_opt.sh" ] && sh "$_old/scripts/screen_off_opt.sh" stop >/dev/null 2>&1
  _stop_monitor_daemon "$_old/tmp/screen_monitor.pid" "$_old/tmp/screen_monitor.lock" "$_old/tmp/deep_doze_events.fifo"
  dumpsys deviceidle unforce >/dev/null 2>&1
  _sensors_enable
}

carry_old_state() {
  local _old="/data/adb/modules/$MODID" _f
  mkdir -p "$MODPATH/backup" "$MODPATH/tmp"
  [ -d "$_old/backup" ] && cp -a "$_old/backup/." "$MODPATH/backup/" 2>/dev/null
  for _f in soo_disabled frozen_services.txt mt_keys.txt deep_doze_restricted.txt deep_doze_lockcycle deep_doze_allow.txt cad_unwl.txt cad_orig_wl.txt; do
    [ -f "$_old/tmp/$_f" ] && cp -f "$_old/tmp/$_f" "$MODPATH/tmp/"
  done
}

revert_old_install() {
  local _old="/data/adb/modules/$MODID/scripts" _c
  [ -f "$_old/frosty.sh" ] || return 0
  for _c in stock revert_kernel revert_ram revert_multitask revert_logs revert_tracking revert_bss; do
    sh "$_old/frosty.sh" "$_c" >/dev/null 2>&1
  done
  sh "$_old/app_doze.sh" revert >/dev/null 2>&1
  sh "$_old/deep_doze.sh" stock >/dev/null 2>&1
}

backfill_prefs() {
  local _defaults="$1" _line _key
  while IFS= read -r _line; do
    _key="${_line%%=*}"
    [ -n "$_key" ] || continue
    grep -q "^${_key}=" "$MODPATH/config/user_prefs" 2>/dev/null || echo "$_line" >> "$MODPATH/config/user_prefs"
  done < "$_defaults"
}

# Existing config detection
EXISTING_PREFS="/data/adb/modules/$MODID/config/user_prefs"
EXISTING_WHITELIST="/data/adb/modules/$MODID/config/doze_whitelist.txt"
EXISTING_PATCHES="/data/adb/modules/$MODID/config/doze_patches.txt"
EXISTING_RAM_WL="/data/adb/modules/$MODID/config/ram_clean_whitelist.txt"
USE_EXISTING=0

if [ -f "$EXISTING_PREFS" ]; then
  print_section "$(s cfg_detected)"
  ui_print "$(s cfg_vol_keep)"
  ui_print "$(s cfg_vol_reset)"
  ui_print "$(s cfg_timeout)"

  if [ "$HAS_GETEVENT" -eq 0 ]; then
    ui_print "$(s cfg_kept) (auto)"
    USE_EXISTING=1
  else
    case "$(_wait_vol_key "$TIMEOUT")" in
      up)   ui_print "$(s cfg_kept)";           USE_EXISTING=1 ;;
      down) ui_print "$(s cfg_reset)";          USE_EXISTING=0 ;;
      *)    ui_print "$(s cfg_kept) (timeout)"; USE_EXISTING=1 ;;
    esac
  fi
fi

stop_old_monitors

mkdir -p "$MODPATH/config"

if [ "$USE_EXISTING" -eq 1 ]; then
  carry_old_state
  cp -f "$MODPATH/config/user_prefs" "$MODPATH/config/user_prefs.defaults"
  cp -f "$EXISTING_PREFS" "$MODPATH/config/user_prefs"
  if grep -q '^RAM_MULTITASK_PROFILE=' "$MODPATH/config/user_prefs" 2>/dev/null && \
     ! grep -q '^MULTITASK_PROFILE=' "$MODPATH/config/user_prefs" 2>/dev/null; then
    sed -i 's/^RAM_MULTITASK_PROFILE=/MULTITASK_PROFILE=/' "$MODPATH/config/user_prefs"
  fi
  backfill_prefs "$MODPATH/config/user_prefs.defaults"
  rm -f "$MODPATH/config/user_prefs.defaults"
  _legacy_gms_doze=0
  if grep -q '^ENABLE_GMS_DOZE=1' "$MODPATH/config/user_prefs" 2>/dev/null; then
    _legacy_gms_doze=1
    sed -i 's/^ENABLE_CUSTOM_APP_DOZE=.*/ENABLE_CUSTOM_APP_DOZE=1/' "$MODPATH/config/user_prefs"
  fi
  sed -i '/^ENABLE_GMS_DOZE=/d' "$MODPATH/config/user_prefs"
  if [ -f "$EXISTING_WHITELIST" ]; then
    cp -f "$EXISTING_WHITELIST" "$MODPATH/config/doze_whitelist.txt"
  fi
  if [ -f "$EXISTING_PATCHES" ]; then
    cp -f "$EXISTING_PATCHES" "$MODPATH/config/doze_patches.txt"
  fi
  if [ "$_legacy_gms_doze" -eq 1 ]; then
    grep -qFx "com.google.android.gms" "$MODPATH/config/doze_patches.txt" 2>/dev/null || \
      echo "com.google.android.gms" >> "$MODPATH/config/doze_patches.txt"
  fi
  if [ -f "$EXISTING_RAM_WL" ]; then
    cp -f "$EXISTING_RAM_WL" "$MODPATH/config/ram_clean_whitelist.txt"
  fi
  . "$MODPATH/config/user_prefs"
  SYSPROP="$MODPATH/system.prop"
  SYSPROP_OLD="$MODPATH/system.prop.old"
  if [ "${ENABLE_SYSTEM_PROPS:-0}" -eq 1 ]; then
    [ -f "$SYSPROP_OLD" ] && mv "$SYSPROP_OLD" "$SYSPROP"
  else
    [ -f "$SYSPROP" ] && mv "$SYSPROP" "$SYSPROP_OLD"
  fi
else
  revert_old_install
  SYSPROP="$MODPATH/system.prop"
  SYSPROP_OLD="$MODPATH/system.prop.old"
  [ -f "$SYSPROP" ] && mv "$SYSPROP" "$SYSPROP_OLD"
fi

print_section "$(s done_title)"
if [ "$KSU" = "true" ] || [ "$APATCH" = "true" ]; then
  ui_print "$(s done_hotinstall)"
  ui_print "$(s done_hotinstall_note)"
else
  ui_print "$(s done_reboot)"
fi
ui_print "$(s done_webui) $(s done_off)"
print_section "$(s stay_frosty)"
ui_print ""

rm -rf "$MODPATH/README.md" "$MODPATH/readme" "$MODPATH/LICENSE" "$MODPATH/CHANGELOG.md" "$MODPATH/update.json" "$MODPATH"/.git*