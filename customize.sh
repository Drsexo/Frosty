#!/system/bin/sh
# FROSTY - GMS Freezer / Battery Saver
# Author: Drsexo (GitHub)

TIMEOUT=30
module_path="/data/adb/modules/Frosty"

COLS=$(stty size 2>/dev/null | awk '{print $2}')
case "$COLS" in ''|*[!0-9]*) COLS=40 ;; esac
[ "$COLS" -gt 54 ] && COLS=54; [ "$COLS" -lt 20 ] && COLS=40

_iw=$((COLS - 4))
LINE="" _i=0
while [ $_i -lt $_iw ]; do
  LINE="${LINE}─"
  _i=$((_i + 1))
done
SEP="  $LINE"
BOX_TOP="  ┌${LINE}┐"
BOX_BOT="  └${LINE}┘"
unset _i _iw

# Timeout fallback
if ! command -v timeout >/dev/null 2>&1; then
  timeout() { shift; "$@"; }
fi

# Getevent check
HAS_GETEVENT=1
if ! command -v getevent >/dev/null 2>&1; then
  HAS_GETEVENT=0
fi

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
  ui_print ""
}

print_section() {
  local text="$1"
  local ascii_len=$(printf '%s' "$text" | sed 's/[^[:print:]]//g' | wc -c)
  local total_bytes=$(printf '%s' "$text" | wc -c)
  local emoji_bytes=$(( total_bytes - ascii_len ))
  local emoji_count=$(( emoji_bytes / 3 ))
  [ "$emoji_count" -lt 0 ] && emoji_count=0
  local display_width=$(( ascii_len + emoji_count * 2 ))

  local total_pad=$(( COLS - display_width ))
  [ "$total_pad" -lt 0 ] && total_pad=0
  local left_pad=$(( total_pad / 2 ))

  local lpad="" _p=0
  while [ $_p -lt $left_pad ]; do lpad="${lpad} "; _p=$((_p+1)); done

  ui_print ""
  ui_print "$BOX_TOP"
  ui_print "${lpad}${text}"
  ui_print "$BOX_BOT"
}

# Permissions
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/frosty.sh" 0 0 0755
set_perm "$MODPATH/gms_doze.sh" 0 0 0755
set_perm "$MODPATH/deep_doze.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
mkdir -p "$MODPATH/config"
mkdir -p "$MODPATH/logs"

# GMS check
if ! pm list packages 2>/dev/null | grep -q "com.google.android.gms"; then
  ui_print ""
  ui_print "  ⚠️  Google Play Services not found!"
  ui_print "  GMS freezing and doze features will not work."
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
INSTALL_LANG="en"  # default

# Only offer a choice if detected language is supported and not English
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
  ui_print ""
  ui_print "$BOX_TOP"
  ui_print "  $_LANG_FLAG  $_LANG_NAME detected"
  ui_print "$BOX_BOT"
  ui_print ""
  ui_print "  ⬆️ Vol UP   = Use $_LANG_NAME"
  ui_print "  ⬇️ Vol DOWN = Keep English 🇬🇧"
  ui_print "  ⏱️ ${TIMEOUT}s timeout → English"
  ui_print ""

  _chosen_lang="en"
  if [ "$HAS_GETEVENT" -eq 0 ]; then
    ui_print "  → English (auto - no getevent)"
  else
    while :; do
      _ev=$(timeout "$TIMEOUT" getevent -qlc 1 2>/dev/null)
      _ec=$?
      if [ "$_ec" -eq 124 ] || [ "$_ec" -eq 143 ]; then
        ui_print "  → 🇬🇧 English (timeout)"
        _chosen_lang="en"
        break
      fi
      if echo "$_ev" | grep -q "KEY_VOLUMEUP.*DOWN"; then
        ui_print "  → $_LANG_FLAG $_LANG_NAME ✅"
        _chosen_lang="$_LANG"
        break
      fi
      if echo "$_ev" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
        ui_print "  → 🇬🇧 English ✅"
        _chosen_lang="en"
        break
      fi
    done
  fi
  INSTALL_LANG="$_chosen_lang"
fi

# Translation helper, returns localised string for current INSTALL_LANG, falls back to English.
s() {
  local key="$1"
  local log_path="$module_path/logs/"
  case "${INSTALL_LANG}:${key}" in

    # EXISTING CONFIG
    fr:cfg_detected)  echo "♻️  Configuration existante détectée !" ;;
    de:cfg_detected)  echo "♻️  Bestehende Konfiguration erkannt!" ;;
    pl:cfg_detected)  echo "♻️  Wykryto istniejącą konfigurację!" ;;
    it:cfg_detected)  echo "♻️  Configurazione esistente rilevata!" ;;
    es:cfg_detected)  echo "♻️  ¡Configuración existente detectada!" ;;
    pt:cfg_detected)  echo "♻️  Configuração existente detectada!" ;;
    tr:cfg_detected)  echo "♻️  Mevcut yapılandırma tespit edildi!" ;;
    id:cfg_detected)  echo "♻️  Konfigurasi saat ini terdeteksi!" ;;
    ru:cfg_detected)  echo "♻️  Обнаружена существующая конфигурация!" ;;
    uk:cfg_detected)  echo "♻️  Виявлено наявну конфігурацію!" ;;
    zh:cfg_detected)  echo "♻️  检测到现有配置！" ;;
    ja:cfg_detected)  echo "♻️  既存の設定が見つかりました！" ;;
    ar:cfg_detected)  echo "♻️  تم اكتشاف إعدادات محفوظة!" ;;
     *:cfg_detected)  echo "♻️  Existing configuration detected!" ;;

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
     *:cfg_vol_keep)  echo "  ⬆️ Vol UP     = Keep existing config & whitelist" ;;

    fr:cfg_vol_reset) echo "  ⬇️ Vol BAS    = Réinit. (tout désactivé)" ;;
    de:cfg_vol_reset) echo "  ⬇️ Vol RUNTER = Zurücksetzen (alles aus)" ;;
    pl:cfg_vol_reset) echo "  ⬇️ Vol DÓŁ    = Resetuj (wszystko wył.)" ;;
    it:cfg_vol_reset) echo "  ⬇️ Vol GIÙ    = Ripristina (tutto off)" ;;
    es:cfg_vol_reset) echo "  ⬇️ Vol ABAJO  = Restablecer (todo off)" ;;
    pt:cfg_vol_reset) echo "  ⬇️ Vol BAIXO  = Redefinir (tudo off)" ;;
    tr:cfg_vol_reset) echo "  ⬇️ Ses AŞAĞI  = Sıfırla (her şey kapalı)" ;;
    id:cfg_vol_reset) echo "  ⬇️ Vol BAWAH  = Reset (semua nonaktif)" ;;
    ru:cfg_vol_reset) echo "  ⬇️ Гром -     = Сброс (всё отключено)" ;;
    uk:cfg_vol_reset) echo "  ⬇️ Гучн. -    = Скидання (все вимкнено)" ;;
    zh:cfg_vol_reset) echo "  ⬇️ 音量下      = 重置 (全部关闭)" ;;
    ja:cfg_vol_reset) echo "  ⬇️ 音量DOWN    = リセット (すべてオフ)" ;;
    ar:cfg_vol_reset) echo "  ⬇️ خفض الصوت  = استعادة الافتراضي (معطل)" ;;
     *:cfg_vol_reset) echo "  ⬇️ Vol DOWN   = Reset to defaults (everything off)" ;;

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
     *:cfg_timeout)   echo "  ⏱️ ${TIMEOUT}s timeout → keeps existing" ;;

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
     *:cfg_kept)      echo "  → Keeping existing config ✅" ;;

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
     *:cfg_reset)     echo "  → Resetting to defaults ⚙️" ;;

    # SAVE CONFIG
    fr:save_title)    echo "💾  Sauvegarde de la Configuration" ;;
    de:save_title)    echo "💾  Konfiguration speichern" ;;
    pl:save_title)    echo "💾  Zapisywanie konfiguracji" ;;
    it:save_title)    echo "💾  Salvataggio configurazione" ;;
    es:save_title)    echo "💾  Guardando Configuración" ;;
    pt:save_title)    echo "💾  Salvando Configuração" ;;
    tr:save_title)    echo "💾  Yapılandırma Kaydediliyor" ;;
    id:save_title)    echo "💾  Menyimpan Konfigurasi" ;;
    ru:save_title)    echo "💾  Сохранение конфигурации" ;;
    uk:save_title)    echo "💾  Збереження конфігурації" ;;
    zh:save_title)    echo "💾  保存配置" ;;
    ja:save_title)    echo "💾  設定を保存" ;;
    ar:save_title)    echo "💾  حفظ الإعدادات" ;;
     *:save_title)    echo "💾  Saving Configuration" ;;

    fr:save_kept)     echo "  ✓ Configuration existante conservée" ;;
    de:save_kept)     echo "  ✓ Bestehende Konfiguration beibehalten" ;;
    pl:save_kept)     echo "  ✓ Istniejąca konfiguracja zachowana" ;;
    it:save_kept)     echo "  ✓ Configurazione esistente mantenuta" ;;
    es:save_kept)     echo "  ✓ Configuración existente conservada" ;;
    pt:save_kept)     echo "  ✓ Configuração existente mantida" ;;
    tr:save_kept)     echo "  ✓ Mevcut yapılandırma korundu" ;;
    id:save_kept)     echo "  ✓ Konfigurasi yang ada dipertahankan" ;;
    ru:save_kept)     echo "  ✓ Существующая конфигурация сохранена" ;;
    uk:save_kept)     echo "  ✓ Наявну конфігурацію збережено" ;;
    zh:save_kept)     echo "  ✓ 已保留现有配置" ;;
    ja:save_kept)     echo "  ✓ 既存の設定を保持しました" ;;
    ar:save_kept)     echo "  ✓ تم الاحتفاظ بالإعدادات الحالية" ;;
     *:save_kept)     echo "  ✓ Existing configuration kept" ;;

    fr:save_wl)       echo "  ↩ Whitelist Doze préservée" ;;
    de:save_wl)       echo "  ↩ Doze-Whitelist beibehalten" ;;
    pl:save_wl)       echo "  ↩ Biała lista Doze zachowana" ;;
    it:save_wl)       echo "  ↩ Whitelist Doze preservata" ;;
    es:save_wl)       echo "  ↩ Lista blanca Doze preservada" ;;
    pt:save_wl)       echo "  ↩ Lista branca Doze preservada" ;;
    tr:save_wl)       echo "  ↩ Doze beyaz listesi korundu" ;;
    id:save_wl)       echo "  ↩ Daftar putih Doze dipertahankan" ;;
    ru:save_wl)       echo "  ↩ Белый список Doze сохранён" ;;
    uk:save_wl)       echo "  ↩ Білий список Doze збережено" ;;
    zh:save_wl)       echo "  ↩ Doze 白名单已保留" ;;
    ja:save_wl)       echo "  ↩ Doze ホワイトリストを保持" ;;
    ar:save_wl)       echo "  ↩ تم الاحتفاظ بالقائمة البيضاء (Whitelist)" ;;
     *:save_wl)       echo "  ↩ Doze whitelist preserved" ;;

    fr:save_default)  echo "  ✓ Config par défaut appliquée (tout désactivé)" ;;
    de:save_default)  echo "  ✓ Standardkonfiguration angewendet (alles aus)" ;;
    pl:save_default)  echo "  ✓ Konfiguracja domyślna (wszystko wyłączone)" ;;
    it:save_default)  echo "  ✓ Config predefinita applicata (tutto off)" ;;
    es:save_default)  echo "  ✓ Configuración por defecto (todo desactivado)" ;;
    pt:save_default)  echo "  ✓ Configuração padrão aplicada (tudo off)" ;;
    tr:save_default)  echo "  ✓ Varsayılan yapılandırma uygulandı (hepsi kapalı)" ;;
    id:save_default)  echo "  ✓ Konfigurasi default diterapkan (semua nonaktif)" ;;
    ru:save_default)  echo "  ✓ Применена конфигурация по умолчанию (всё выкл.)" ;;
    uk:save_default)  echo "  ✓ Застосовано типову конфігурацію (все вимк.)" ;;
    zh:save_default)  echo "  ✓ 已应用默认配置（全部关闭）" ;;
    ja:save_default)  echo "  ✓ デフォルト設定を適用（すべてオフ）" ;;
    ar:save_default)  echo "  ✓ تم تطبيق الإعداد الافتراضي (كل شيء معطل)" ;;
     *:save_default)  echo "  ✓ Default config applied (everything off)" ;;

    # WHAT IS AVAILABLE
    fr:avail_title)   echo "📋  Disponible dans la WebUI" ;;
    de:avail_title)   echo "📋  In der WebUI verfügbar" ;;
    pl:avail_title)   echo "📋  Dostępne w WebUI" ;;
    it:avail_title)   echo "📋  Disponibile nella WebUI" ;;
    es:avail_title)   echo "📋  Disponible en la WebUI" ;;
    pt:avail_title)   echo "📋  Disponível na WebUI" ;;
    tr:avail_title)   echo "📋  WebUI'de Mevcut" ;;
    id:avail_title)   echo "📋  Tersedia di WebUI" ;;
    ru:avail_title)   echo "📋  Доступно в WebUI" ;;
    uk:avail_title)   echo "📋  Доступно у WebUI" ;;
    zh:avail_title)   echo "📋  WebUI 中可用" ;;
    ja:avail_title)   echo "📋  WebUI で使用可能" ;;
    ar:avail_title)   echo "📋  الميزات المتاحة في WebUI" ;;
     *:avail_title)   echo "📋  What's Available in WebUI" ;;

    fr:avail_tweaks)  echo "  ⚙️  Optimisations Système" ;;
    de:avail_tweaks)  echo "  ⚙️  System-Tweaks" ;;
    pl:avail_tweaks)  echo "  ⚙️  Tweaki Systemu" ;;
    it:avail_tweaks)  echo "  ⚙️  Ottimizzazioni Sistema" ;;
    es:avail_tweaks)  echo "  ⚙️  Ajustes del Sistema" ;;
    pt:avail_tweaks)  echo "  ⚙️  Otimizações do Sistema" ;;
    tr:avail_tweaks)  echo "  ⚙️  Sistem İyileştirmeleri" ;;
    id:avail_tweaks)  echo "  ⚙️  Optimasi Sistem" ;;
    ru:avail_tweaks)  echo "  ⚙️  Системные твики" ;;
    uk:avail_tweaks)  echo "  ⚙️  Системні налаштування" ;;
    zh:avail_tweaks)  echo "  ⚙️  系统优化 (System Tweaks)" ;;
    ja:avail_tweaks)  echo "  ⚙️  システム最適化" ;;
    ar:avail_tweaks)  echo "  ⚙️  تعديلات النظام (System Tweaks)" ;;
     *:avail_tweaks)  echo "  ⚙️  System Tweaks" ;;

    fr:avail_cats)    echo "  🧊 Catégories GMS" ;;
    de:avail_cats)    echo "  🧊 GMS-Kategorien" ;;
    pl:avail_cats)    echo "  🧊 Kategorie GMS" ;;
    it:avail_cats)    echo "  🧊 Categorie GMS" ;;
    es:avail_cats)    echo "  🧊 Categorías GMS" ;;
    pt:avail_cats)    echo "  🧊 Categorias GMS" ;;
    tr:avail_cats)    echo "  🧊 GMS Kategorileri" ;;
    id:avail_cats)    echo "  🧊 Kategori GMS" ;;
    ru:avail_cats)    echo "  🧊 Категории GMS" ;;
    uk:avail_cats)    echo "  🧊 Категорії GMS" ;;
    zh:avail_cats)    echo "  🧊 GMS 分类" ;;
    ja:avail_cats)    echo "  🧊 GMS カテゴリ" ;;
    ar:avail_cats)    echo "  🧊 فئات GMS" ;;
     *:avail_cats)    echo "  🧊 GMS Categories" ;;

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
     *:done_title)    echo "✅  Installation Complete" ;;

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
     *:done_reboot)   echo "  🔄 Reboot your device" ;;

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
     *:done_webui)    echo "  ⚙️  Open WebUI in your root manager to enable" ;;

    fr:done_off)      echo "     (tout commence DÉSACTIVÉ par défaut)" ;;
    de:done_off)      echo "     (alles startet DEAKTIVIERT standardmäßig)" ;;
    pl:done_off)      echo "     (domyślnie wszystko jest WYŁĄCZONE)" ;;
    it:done_off)      echo "     (tutto parte DISATTIVATO di default)" ;;
    es:done_off)      echo "     (todo comienza DESACTIVADO por defecto)" ;;
    pt:done_off)      echo "     (tudo começa DESATIVADO por padrão)" ;;
    tr:done_off)      echo "     (varsayılan olarak her şey KAPALI başlar)" ;;
    id:done_off)      echo "     (semuanya DINONAKTIFKAN secara default)" ;;
    ru:done_off)      echo "     (по умолчанию всё ОТКЛЮЧЕНО)" ;;
    uk:done_off)      echo "     (за замовчуванням усе ВИМКНЕНО)" ;;
    zh:done_off)      echo "     （默认情况下所有功能均为关闭状态）" ;;
    ja:done_off)      echo "     （デフォルトではすべてオフになっています）" ;;
    ar:done_off)      echo "     (كل شيء معطل افتراضياً)" ;;
     *:done_off)      echo "     features, everything starts OFF by default" ;;

    fr:done_logs)     echo "  📄 Journaux : $log_path" ;;
    de:done_logs)     echo "  📄 Logs: $log_path" ;;
    pl:done_logs)     echo "  📄 Logi: $log_path" ;;
    it:done_logs)     echo "  📄 Log: $log_path" ;;
    es:done_logs)     echo "  📄 Registros: $log_path" ;;
    pt:done_logs)     echo "  📄 Logs: $log_path" ;;
    tr:done_logs)     echo "  📄 Günlükler: $log_path" ;;
    id:done_logs)     echo "  📄 Log: $log_path" ;;
    ru:done_logs)     echo "  📄 Логи: $log_path" ;;
    uk:done_logs)     echo "  📄 Логи: $log_path" ;;
    zh:done_logs)     echo "  📄 日志: $log_path" ;;
    ja:done_logs)     echo "  📄 ログ: $log_path" ;;
    ar:done_logs)     echo "  📄 السجلات: $log_path" ;;
     *:done_logs)     echo "  📄 Logs: $log_path" ;;

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
     *:stay_frosty)   echo "❆  Stay Frosty!  ❆" ;;

    # TWEAK ITEM NAMES
    fr:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    de:avail_kernel)      echo "🔧 Kernel-Tweaks" ;;
    pl:avail_kernel)      echo "🔧 Tweaki Jądra" ;;
    it:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    es:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    pt:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    tr:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    id:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    ru:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    uk:avail_kernel)      echo "🔧 Kernel Tweaks" ;;
    zh:avail_kernel)      echo "🔧 内核调优 (Kernel Tweaks)" ;;
    ja:avail_kernel)      echo "🔧 カーネル調整 (Kernel Tweaks)" ;;
    ar:avail_kernel)      echo "🔧 تعديلات الكيرنل (Kernel Tweaks)" ;;
     *:avail_kernel)      echo "🔧 Kernel Tweaks" ;;

    fr:avail_kernel_desc) echo "    Optimisations Scheduler, VM et réseau" ;;
    de:avail_kernel_desc) echo "    Scheduler, VM & Netzwerkoptimierungen" ;;
    pl:avail_kernel_desc) echo "    Optymalizacje Scheduler, VM i sieci" ;;
    it:avail_kernel_desc) echo "    Ottimizzazioni Scheduler, VM e rete" ;;
    es:avail_kernel_desc) echo "    Optimizaciones Scheduler, VM y red" ;;
    pt:avail_kernel_desc) echo "    Otimizações Scheduler, VM e rede" ;;
    tr:avail_kernel_desc) echo "    Zamanlayıcı, VM ve ağ optimizasyonları" ;;
    id:avail_kernel_desc) echo "    Optimasi Scheduler, VM, & jaringan" ;;
    ru:avail_kernel_desc) echo "    Оптимизация планировщика, VM и сети" ;;
    uk:avail_kernel_desc) echo "    Оптимізація планувальника, VM та мережі" ;;
    zh:avail_kernel_desc) echo "    调度器 (Scheduler)、VM 和网络优化" ;;
    ja:avail_kernel_desc) echo "    スケジューラ、VM、ネットワーク最適化" ;;
    ar:avail_kernel_desc) echo "    تحسينات المجدول (Scheduler) والذاكرة والشبكة" ;;
     *:avail_kernel_desc) echo "    Scheduler, VM & network optimizations" ;;

    fr:avail_sysprops)    echo "⚙️  System Props" ;;
    de:avail_sysprops)    echo "⚙️  System Props" ;;
    pl:avail_sysprops)    echo "⚙️  System Props" ;;
    it:avail_sysprops)    echo "⚙️  System Props" ;;
    es:avail_sysprops)    echo "⚙️  System Props" ;;
    pt:avail_sysprops)    echo "⚙️  System Props" ;;
    tr:avail_sysprops)    echo "⚙️  System Props" ;;
    id:avail_sysprops)    echo "⚙️  System Props" ;;
    ru:avail_sysprops)    echo "⚙️  System Props" ;;
    uk:avail_sysprops)    echo "⚙️  System Props" ;;
    zh:avail_sysprops)    echo "⚙️  系统属性 (System Props)" ;;
    ja:avail_sysprops)    echo "⚙️  システムプロパティ (System Props)" ;;
    ar:avail_sysprops)    echo "⚙️  خصائص النظام (System Props)" ;;
     *:avail_sysprops)    echo "⚙️  System Props" ;;

    fr:avail_sysprops_desc) echo "    Désactive les logs de debug, sauve la RAM" ;;
    de:avail_sysprops_desc) echo "    Deaktiviert Debug-Logs, spart RAM" ;;
    pl:avail_sysprops_desc) echo "    Wyłącza logi debugowania, oszczędza RAM" ;;
    it:avail_sysprops_desc) echo "    Disabilita log di debug, risparmia RAM" ;;
    es:avail_sysprops_desc) echo "    Desactiva logs de debug, ahorra RAM" ;;
    pt:avail_sysprops_desc) echo "    Desativa logs de debug, economiza RAM" ;;
    tr:avail_sysprops_desc) echo "    Debug loglarını kapatır, RAM tasarrufu" ;;
    id:avail_sysprops_desc) echo "    Mematikan debug log, menghemat RAM" ;;
    ru:avail_sysprops_desc) echo "    Отключает отладочные логи, экономит RAM" ;;
    uk:avail_sysprops_desc) echo "    Вимикає журнали налагодження, економить RAM" ;;
    zh:avail_sysprops_desc) echo "    禁用调试日志记录以节省 RAM" ;;
    ja:avail_sysprops_desc) echo "    デバッグログを無効化し、RAMを節約" ;;
    ar:avail_sysprops_desc) echo "    يعطل سجلات التصحيح لتوفير RAM" ;;
     *:avail_sysprops_desc) echo "    Disables debug logging, saves RAM" ;;

    fr:avail_ram)         echo "🚀 Optimiseur de RAM" ;;
    de:avail_ram)         echo "🚀 RAM-Optimierer" ;;
    pl:avail_ram)         echo "🚀 Optymalizator RAM" ;;
    it:avail_ram)         echo "🚀 Ottimizzatore RAM" ;;
    es:avail_ram)         echo "🚀 Optimizador de RAM" ;;
    pt:avail_ram)         echo "🚀 Otimizador de RAM" ;;
    tr:avail_ram)         echo "🚀 RAM Optimize Edici" ;;
    id:avail_ram)         echo "🚀 Pengoptimal RAM" ;;
    ru:avail_ram)         echo "🚀 Оптимизатор RAM" ;;
    uk:avail_ram)         echo "🚀 Оптимізатор RAM" ;;
    zh:avail_ram)         echo "🚀 RAM 优化器 (RAM Optimizer)" ;;
    ja:avail_ram)         echo "🚀 RAM オプティマイザ (RAM Optimizer)" ;;
    ar:avail_ram)         echo "🚀 مُحسّن الذاكرة (RAM Optimizer)" ;;
     *:avail_ram)         echo "🚀 RAM Optimizer" ;;

    fr:avail_ram_desc)    echo "    Limite le cache et les apps vides, ajuste le zram" ;;
    de:avail_ram_desc)    echo "    Begrenzt Cache-Prozesse, optimiert zram-Swap" ;;
    pl:avail_ram_desc)    echo "    Ogranicza cache i puste procesy, dostraja zram" ;;
    it:avail_ram_desc)    echo "    Limita i processi in cache, ottimizza lo zram" ;;
    es:avail_ram_desc)    echo "    Limita procesos en caché, ajusta zram swap" ;;
    pt:avail_ram_desc)    echo "    Limita processos em cache, ajusta swap do zram" ;;
    tr:avail_ram_desc)    echo "    Önbelleği ve boş işlemleri sınırlar, zram ayarlar" ;;
    id:avail_ram_desc)    echo "    Batasi proses cache/kosong, optimalkan swap zram" ;;
    ru:avail_ram_desc)    echo "    Ограничивает кэш и пустые процессы, тюнинг zram" ;;
    uk:avail_ram_desc)    echo "    Обмежує кеш та порожні процеси, налаштовує zram" ;;
    zh:avail_ram_desc)    echo "    限制缓存与空后台进程，调整 zram 以释放 RAM" ;;
    ja:avail_ram_desc)    echo "    キャッシュや空プロセスを制限、zramを調整しRAM確保" ;;
    ar:avail_ram_desc)    echo "    يحد عمليات الخلفية ويضبط zram لتوفير مساحة RAM" ;;
     *:avail_ram_desc)    echo "    Limits cached/empty apps, tunes zram for more RAM" ;;

    fr:avail_blur)        echo "🎨 Désactiver le flou (Blur)" ;;
    de:avail_blur)        echo "🎨 Blur (Unschärfe) deaktivieren" ;;
    pl:avail_blur)        echo "🎨 Disable Blur (Wyłącz rozmycie)" ;;
    it:avail_blur)        echo "🎨 Disable Blur (No sfocatura)" ;;
    es:avail_blur)        echo "🎨 Disable Blur (Sin desenfoque)" ;;
    pt:avail_blur)        echo "🎨 Disable Blur (Sem desfoque)" ;;
    tr:avail_blur)        echo "🎨 Disable Blur (Bulanıklığı Kapat)" ;;
    id:avail_blur)        echo "🎨 Disable Blur (Nonaktifkan Blur)" ;;
    ru:avail_blur)        echo "🎨 Disable Blur (Отключить размытие)" ;;
    uk:avail_blur)        echo "🎨 Disable Blur (Вимкнути розмиття)" ;;
    zh:avail_blur)        echo "🎨 Disable Blur (禁用模糊)" ;;
    ja:avail_blur)        echo "🎨 Disable Blur (ブラー無効化)" ;;
    ar:avail_blur)        echo "🎨 Disable Blur (تعطيل الضبابية)" ;;
     *:avail_blur)        echo "🎨 Disable Blur" ;;

    fr:avail_blur_desc)   echo "    Réduit la charge GPU (appareils faibles)" ;;
    de:avail_blur_desc)   echo "    Reduziert GPU-Last auf schwachen Geräten" ;;
    pl:avail_blur_desc)   echo "    Zmniejsza obciążenie GPU" ;;
    it:avail_blur_desc)   echo "    Riduce il carico GPU su dispositivi lenti" ;;
    es:avail_blur_desc)   echo "    Reduce la carga gráfica (GPU)" ;;
    pt:avail_blur_desc)   echo "    Reduz a carga da GPU em aparelhos fracos" ;;
    tr:avail_blur_desc)   echo "    Düşük cihazlarda GPU yükünü azaltır" ;;
    id:avail_blur_desc)   echo "    Mengurangi beban GPU di perangkat lemah" ;;
    ru:avail_blur_desc)   echo "    Снижает нагрузку на GPU" ;;
    uk:avail_blur_desc)   echo "    Зменшує навантаження на GPU" ;;
    zh:avail_blur_desc)   echo "    降低低配设备的 GPU 负载" ;;
    ja:avail_blur_desc)   echo "    低スペック端末の GPU 負荷を軽減" ;;
    ar:avail_blur_desc)   echo "    يقلل حمل GPU على الأجهزة الضعيفة" ;;
     *:avail_blur_desc)   echo "    Reduces GPU load on weaker devices" ;;

    fr:avail_logs)        echo "📝 Kill Logs" ;;
    de:avail_logs)        echo "📝 Kill Logs" ;;
    pl:avail_logs)        echo "📝 Kill Logs" ;;
    it:avail_logs)        echo "📝 Kill Logs" ;;
    es:avail_logs)        echo "📝 Kill Logs" ;;
    pt:avail_logs)        echo "📝 Kill Logs" ;;
    tr:avail_logs)        echo "📝 Kill Logs" ;;
    id:avail_logs)        echo "📝 Kill Logs" ;;
    ru:avail_logs)        echo "📝 Kill Logs (Остановка логов)" ;;
    uk:avail_logs)        echo "📝 Kill Logs (Зупинка логів)" ;;
    zh:avail_logs)        echo "📝 Kill Logs (终止日志)" ;;
    ja:avail_logs)        echo "📝 Kill Logs (ログ停止)" ;;
    ar:avail_logs)        echo "📝 Kill Logs (إيقاف السجلات)" ;;
     *:avail_logs)        echo "📝 Log Killing" ;;

    fr:avail_logs_desc)   echo "    Arrête les processus de logs en arrière-plan" ;;
    de:avail_logs_desc)   echo "    Stoppt Hintergrund-Logger" ;;
    pl:avail_logs_desc)   echo "    Zatrzymuje procesy logowania w tle" ;;
    it:avail_logs_desc)   echo "    Ferma i processi di log in background" ;;
    es:avail_logs_desc)   echo "    Detiene los loggers en segundo plano" ;;
    pt:avail_logs_desc)   echo "    Interrompe os loggers em segundo plano" ;;
    tr:avail_logs_desc)   echo "    Arka plan log/kayıt süreçlerini durdurur" ;;
    id:avail_logs_desc)   echo "    Menghentikan proses log di latar belakang" ;;
    ru:avail_logs_desc)   echo "    Останавливает фоновые процессы логирования" ;;
    uk:avail_logs_desc)   echo "    Зупиняє фонові процеси логування" ;;
    zh:avail_logs_desc)   echo "    停止后台日志记录进程" ;;
    ja:avail_logs_desc)   echo "    バックグラウンドのログプロセスを停止" ;;
    ar:avail_logs_desc)   echo "    يوقف عمليات التسجيل في الخلفية" ;;
     *:avail_logs_desc)   echo "    Stops background loggers" ;;

    fr:avail_gms_doze)    echo "💤 GMS Doze" ;;
    de:avail_gms_doze)    echo "💤 GMS Doze" ;;
    pl:avail_gms_doze)    echo "💤 GMS Doze" ;;
    it:avail_gms_doze)    echo "💤 GMS Doze" ;;
    es:avail_gms_doze)    echo "💤 GMS Doze" ;;
    pt:avail_gms_doze)    echo "💤 GMS Doze" ;;
    tr:avail_gms_doze)    echo "💤 GMS Doze" ;;
    id:avail_gms_doze)    echo "💤 GMS Doze" ;;
    ru:avail_gms_doze)    echo "💤 GMS Doze" ;;
    uk:avail_gms_doze)    echo "💤 GMS Doze" ;;
    zh:avail_gms_doze)    echo "💤 GMS Doze" ;;
    ja:avail_gms_doze)    echo "💤 GMS Doze" ;;
    ar:avail_gms_doze)    echo "💤 GMS Doze" ;;
     *:avail_gms_doze)    echo "💤 GMS Doze" ;;

    fr:avail_gms_doze_desc) echo "    Android optimise la batterie des GMS" ;;
    de:avail_gms_doze_desc) echo "    System optimiert den GMS-Akkuverbrauch" ;;
    pl:avail_gms_doze_desc) echo "    System optymalizuje zużycie baterii GMS" ;;
    it:avail_gms_doze_desc) echo "    Il sistema ottimizza la batteria dei GMS" ;;
    es:avail_gms_doze_desc) echo "    El sistema optimiza la batería de GMS" ;;
    pt:avail_gms_doze_desc) echo "    O sistema otimiza a bateria do GMS" ;;
    tr:avail_gms_doze_desc) echo "    Sistem GMS pil tüketimini optimize eder" ;;
    id:avail_gms_doze_desc) echo "    Sistem mengoptimalkan baterai GMS" ;;
    ru:avail_gms_doze_desc) echo "    Система оптимизирует расход батареи GMS" ;;
    uk:avail_gms_doze_desc) echo "    Система оптимізує витрату батареї GMS" ;;
    zh:avail_gms_doze_desc) echo "    允许系统优化 GMS 电池消耗" ;;
    ja:avail_gms_doze_desc) echo "    システムが GMS のバッテリー消費を最適化" ;;
    ar:avail_gms_doze_desc) echo "    يسمح للنظام بتحسين استهلاك بطارية GMS" ;;
     *:avail_gms_doze_desc) echo "    Android optimizes GMS battery usage" ;;

    fr:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    de:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    pl:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    it:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    es:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    pt:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    tr:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    id:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    ru:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    uk:avail_deep_doze)   echo "🔋 Deep Doze" ;;
    zh:avail_deep_doze)   echo "🔋 Deep Doze (深度休眠)" ;;
    ja:avail_deep_doze)   echo "🔋 Deep Doze (ディープスリープ)" ;;
    ar:avail_deep_doze)   echo "🔋 وضع Deep Doze" ;;
     *:avail_deep_doze)   echo "🔋 Deep Doze" ;;

    fr:avail_deep_doze_desc) echo "    Restrictions agressives en arrière-plan" ;;
    de:avail_deep_doze_desc) echo "    Aggressive Hintergrundbeschränkungen" ;;
    pl:avail_deep_doze_desc) echo "    Agresywne ograniczenia tła dla aplikacji" ;;
    it:avail_deep_doze_desc) echo "    Restrizioni aggressive in background" ;;
    es:avail_deep_doze_desc) echo "    Restricciones agresivas en segundo plano" ;;
    pt:avail_deep_doze_desc) echo "    Restrições agressivas em segundo plano" ;;
    tr:avail_deep_doze_desc) echo "    Tüm uygulamalar için agresif kısıtlamalar" ;;
    id:avail_deep_doze_desc) echo "    Pembatasan latar belakang yang sangat ketat" ;;
    ru:avail_deep_doze_desc) echo "    Очень агрессивные фоновые ограничения" ;;
    uk:avail_deep_doze_desc) echo "    Дуже агресивні фонові обмеження" ;;
    zh:avail_deep_doze_desc) echo "    对所有应用实施极其激进的后台限制" ;;
    ja:avail_deep_doze_desc) echo "    非常に強力なバックグラウンド制限" ;;
    ar:avail_deep_doze_desc) echo "    قيود صارمة جداً على نشاط الخلفية" ;;
     *:avail_deep_doze_desc) echo "    Aggressive background restrictions" ;;

    # GMS CATEGORY DESCRIPTIONS
    fr:avail_telemetry)   echo "📊 Télémétrie" ;;
    de:avail_telemetry)   echo "📊 Telemetrie" ;;
    pl:avail_telemetry)   echo "📊 Telemetria" ;;
    it:avail_telemetry)   echo "📊 Telemetria" ;;
    es:avail_telemetry)   echo "📊 Telemetría" ;;
    pt:avail_telemetry)   echo "📊 Telemetria" ;;
    tr:avail_telemetry)   echo "📊 Telemetri" ;;
    id:avail_telemetry)   echo "📊 Telemetri" ;;
    ru:avail_telemetry)   echo "📊 Телеметрия" ;;
    uk:avail_telemetry)   echo "📊 Телеметрія" ;;
    zh:avail_telemetry)   echo "📊 遥测 (Telemetry)" ;;
    ja:avail_telemetry)   echo "📊 テレメトリ (Telemetry)" ;;
    ar:avail_telemetry)   echo "📊 القياس عن بُعد (Telemetry)" ;;
     *:avail_telemetry)   echo "📊 Telemetry" ;;

    fr:avail_telemetry_tag)  echo "    Publicités, analytics, pistage (sûr)" ;;
    de:avail_telemetry_tag)  echo "    Werbung, Analytics, Tracking (sicher)" ;;
    pl:avail_telemetry_tag)  echo "    Reklamy, analityka, śledzenie (bezpieczne)" ;;
    it:avail_telemetry_tag)  echo "    Pubblicità, analytics, tracciamento (sicuro)" ;;
    es:avail_telemetry_tag)  echo "    Anuncios, estadísticas, rastreo (seguro)" ;;
    pt:avail_telemetry_tag)  echo "    Anúncios, estatísticas, rastreio (seguro)" ;;
    tr:avail_telemetry_tag)  echo "    Reklamlar, analizler, izleme (güvenli)" ;;
    id:avail_telemetry_tag)  echo "    Iklan, analitik, pelacakan (aman)" ;;
    ru:avail_telemetry_tag)  echo "    Реклама, аналитика, отслеживание (безопасно)" ;;
    uk:avail_telemetry_tag)  echo "    Реклама, аналітика, відстеження (безпечно)" ;;
    zh:avail_telemetry_tag)  echo "    广告、数据分析和追踪（安全禁用）" ;;
    ja:avail_telemetry_tag)  echo "    広告、分析、追跡（安全に無効化可能）" ;;
    ar:avail_telemetry_tag)  echo "    الإعلانات، التحليلات، التتبع (آمن)" ;;
     *:avail_telemetry_tag)  echo "    Ads, analytics (safe)" ;;

    fr:avail_background)  echo "🔄 Arrière-plan" ;;
    de:avail_background)  echo "🔄 Hintergrund" ;;
    pl:avail_background)  echo "🔄 Tło" ;;
    it:avail_background)  echo "🔄 Background" ;;
    es:avail_background)  echo "🔄 Segundo Plano" ;;
    pt:avail_background)  echo "🔄 Segundo plano" ;;
    tr:avail_background)  echo "🔄 Arka Plan" ;;
    id:avail_background)  echo "🔄 Latar Belakang" ;;
    ru:avail_background)  echo "🔄 Фон" ;;
    uk:avail_background)  echo "🔄 Фон" ;;
    zh:avail_background)  echo "🔄 后台 (Background)" ;;
    ja:avail_background)  echo "🔄 バックグラウンド (Background)" ;;
    ar:avail_background)  echo "🔄 الخلفية (Background)" ;;
     *:avail_background)  echo "🔄 Background" ;;

    fr:avail_background_tag) echo "    Mises à jour auto, synchro MDM (sûr)" ;;
    de:avail_background_tag) echo "    Auto-Updates, MDM-Sync (sicher)" ;;
    pl:avail_background_tag) echo "    Aktualizacje w tle, MDM (bezpieczne)" ;;
    it:avail_background_tag) echo "    Aggiornamenti in background, MDM (sicuro)" ;;
    es:avail_background_tag) echo "    Actualizaciones en segundo plano, MDM (seguro)" ;;
    pt:avail_background_tag) echo "    Atualizações automáticas, MDM (seguro)" ;;
    tr:avail_background_tag) echo "    Arka plan güncellemeleri, MDM (güvenli)" ;;
    id:avail_background_tag) echo "    Pembaruan otomatis, sinkronisasi (aman)" ;;
    ru:avail_background_tag) echo "    Фоновые обновления, MDM (безопасно)" ;;
    uk:avail_background_tag) echo "    Фонові оновлення, MDM (безпечно)" ;;
    zh:avail_background_tag) echo "    应用自动更新、MDM（安全禁用）" ;;
    ja:avail_background_tag) echo "    自動更新、MDM（安全に無効化可能）" ;;
    ar:avail_background_tag) echo "    التحديثات التلقائية (آمن)" ;;
     *:avail_background_tag) echo "    Auto-updates, font sync (safe)" ;;

    fr:avail_location)    echo "📍 Localisation" ;;
    de:avail_location)    echo "📍 Standort" ;;
    pl:avail_location)    echo "📍 Lokalizacja" ;;
    it:avail_location)    echo "📍 Posizione" ;;
    es:avail_location)    echo "📍 Ubicación" ;;
    pt:avail_location)    echo "📍 Localização" ;;
    tr:avail_location)    echo "📍 Konum" ;;
    id:avail_location)    echo "📍 Lokasi" ;;
    ru:avail_location)    echo "📍 Местоположение" ;;
    uk:avail_location)    echo "📍 Місцезнаходження" ;;
    zh:avail_location)    echo "📍 位置 (Location)" ;;
    ja:avail_location)    echo "📍 位置情報 (Location)" ;;
    ar:avail_location)    echo "📍 الموقع (Location)" ;;
     *:avail_location)    echo "📍 Location" ;;

    fr:avail_location_tag) echo "    Désactive Maps, GPS, Localiser mon appareil" ;;
    de:avail_location_tag) echo "    Deaktiviert Maps, GPS, Gerät finden" ;;
    pl:avail_location_tag) echo "    Psuje Google Maps, GPS, Znajdź urządzenie" ;;
    it:avail_location_tag) echo "    Disabilita Maps, GPS, Trova il mio dispositivo" ;;
    es:avail_location_tag) echo "    Desactiva Maps, GPS, Encontrar mi dispositivo" ;;
    pt:avail_location_tag) echo "    Desativa Maps, GPS, Encontre Meu Dispositivo" ;;
    tr:avail_location_tag) echo "    Maps, GPS ve Cihazımı Bul çalışmaz" ;;
    id:avail_location_tag) echo "    Mematikan Maps, GPS, Temukan Perangkat" ;;
    ru:avail_location_tag) echo "    Отключает Maps, GPS, Найти устройство" ;;
    uk:avail_location_tag) echo "    Вимикає Maps, GPS, Знайти пристрій" ;;
    zh:avail_location_tag) echo "    将禁用 Google 地图、GPS 及查找设备" ;;
    ja:avail_location_tag) echo "    Google マップ、GPS、デバイスを探すが無効化" ;;
    ar:avail_location_tag) echo "    يوقف الخرائط، GPS، العثور على جهازي" ;;
     *:avail_location_tag) echo "    Breaks Maps, GPS, Find My Device" ;;

    fr:avail_connectivity) echo "📡 Connectivité" ;;
    de:avail_connectivity) echo "📡 Konnektivität" ;;
    pl:avail_connectivity) echo "📡 Łączność" ;;
    it:avail_connectivity) echo "📡 Connettività" ;;
    es:avail_connectivity) echo "📡 Conectividad" ;;
    pt:avail_connectivity) echo "📡 Conectividade" ;;
    tr:avail_connectivity) echo "📡 Bağlantı" ;;
    id:avail_connectivity) echo "📡 Konektivitas" ;;
    ru:avail_connectivity) echo "📡 Связь" ;;
    uk:avail_connectivity) echo "📡 Зв'язок" ;;
    zh:avail_connectivity) echo "📡 连接 (Connectivity)" ;;
    ja:avail_connectivity) echo "📡 接続 (Connectivity)" ;;
    ar:avail_connectivity) echo "📡 الاتصال (Connectivity)" ;;
     *:avail_connectivity) echo "📡 Connectivity" ;;

    fr:avail_connectivity_tag) echo "    Désactive Cast, Quick Share, Fast Pair" ;;
    de:avail_connectivity_tag) echo "    Deaktiviert Cast, Quick Share, Fast Pair" ;;
    pl:avail_connectivity_tag) echo "    Psuje Cast, Quick Share, Fast Pair" ;;
    it:avail_connectivity_tag) echo "    Disabilita Cast, Quick Share, Fast Pair" ;;
    es:avail_connectivity_tag) echo "    Desactiva Cast, Quick Share, Fast Pair" ;;
    pt:avail_connectivity_tag) echo "    Desativa Cast, Quick Share, Fast Pair" ;;
    tr:avail_connectivity_tag) echo "    Chromecast, Quick Share, Fast Pair çalışmaz" ;;
    id:avail_connectivity_tag) echo "    Mematikan Cast, Quick Share, Fast Pair" ;;
    ru:avail_connectivity_tag) echo "    Отключает Cast, Quick Share, Fast Pair" ;;
    uk:avail_connectivity_tag) echo "    Вимикає Cast, Quick Share, Fast Pair" ;;
    zh:avail_connectivity_tag) echo "    将禁用 Chromecast、快速分享及快速配对" ;;
    ja:avail_connectivity_tag) echo "    Chromecast、クイック共有、Fast Pairが無効化" ;;
    ar:avail_connectivity_tag) echo "    يوقف Cast، مشاركة سريعة، Fast Pair" ;;
     *:avail_connectivity_tag) echo "    Breaks Cast, Quick Share, Fast Pair" ;;

    fr:avail_cloud)       echo "☁️  Cloud" ;;
    de:avail_cloud)       echo "☁️  Cloud" ;;
    pl:avail_cloud)       echo "☁️  Chmura" ;;
    it:avail_cloud)       echo "☁️  Cloud" ;;
    es:avail_cloud)       echo "☁️  Nube" ;;
    pt:avail_cloud)       echo "☁️  Nuvem" ;;
    tr:avail_cloud)       echo "☁️  Bulut" ;;
    id:avail_cloud)       echo "☁️  Cloud" ;;
    ru:avail_cloud)       echo "☁️  Облако" ;;
    uk:avail_cloud)       echo "☁️  Хмара" ;;
    zh:avail_cloud)       echo "☁️  云端 (Cloud)" ;;
    ja:avail_cloud)       echo "☁️  クラウド (Cloud)" ;;
    ar:avail_cloud)       echo "☁️  السحابة (Cloud)" ;;
     *:avail_cloud)       echo "☁️  Cloud" ;;

    fr:avail_cloud_tag)   echo "    Désactive Connexion Google, Autofill, Backups" ;;
    de:avail_cloud_tag)   echo "    Deaktiviert Google-Login, Autofill, Backups" ;;
    pl:avail_cloud_tag)   echo "    Psuje logowanie Google, hasła, kopie zapasowe" ;;
    it:avail_cloud_tag)   echo "    Disabilita Accesso Google, Autofill, Backup" ;;
    es:avail_cloud_tag)   echo "    Desactiva inicio de sesión, contraseñas, backups" ;;
    pt:avail_cloud_tag)   echo "    Desativa Login do Google, senhas e backups" ;;
    tr:avail_cloud_tag)   echo "    Google Girişi, şifreler ve yedeklemeler çalışmaz" ;;
    id:avail_cloud_tag)   echo "    Mematikan Login, Isi Otomatis, Cadangan" ;;
    ru:avail_cloud_tag)   echo "    Отключает вход в Google, автозаполнение, бэкапы" ;;
    uk:avail_cloud_tag)   echo "    Вимикає вхід в Google, автозаповнення, бекапи" ;;
    zh:avail_cloud_tag)   echo "    将禁用 Google 登录、自动填充及备份" ;;
    ja:avail_cloud_tag)   echo "    Google ログイン、自動入力、バックアップが無効化" ;;
    ar:avail_cloud_tag)   echo "    يوقف تسجيل الدخول، الملء التلقائي، النسخ" ;;
     *:avail_cloud_tag)   echo "    Breaks Sign-in, Autofill, Passwords" ;;

    fr:avail_payments)    echo "💳 Paiements" ;;
    de:avail_payments)    echo "💳 Zahlungen" ;;
    pl:avail_payments)    echo "💳 Płatności" ;;
    it:avail_payments)    echo "💳 Pagamenti" ;;
    es:avail_payments)    echo "💳 Pagos" ;;
    pt:avail_payments)    echo "💳 Pagamentos" ;;
    tr:avail_payments)    echo "💳 Ödemeler" ;;
    id:avail_payments)    echo "💳 Pembayaran" ;;
    ru:avail_payments)    echo "💳 Платежи" ;;
    uk:avail_payments)    echo "💳 Платежі" ;;
    zh:avail_payments)    echo "💳 支付 (Payments)" ;;
    ja:avail_payments)    echo "💳 決済 (Payments)" ;;
    ar:avail_payments)    echo "💳 المدفوعات (Payments)" ;;
     *:avail_payments)    echo "💳 Payments" ;;

    fr:avail_payments_tag) echo "    Désactive Google Pay, paiements NFC" ;;
    de:avail_payments_tag) echo "    Deaktiviert Google Pay, NFC-Zahlungen" ;;
    pl:avail_payments_tag) echo "    Psuje Google Pay, płatności NFC" ;;
    it:avail_payments_tag) echo "    Disabilita Google Pay, pagamenti NFC" ;;
    es:avail_payments_tag) echo "    Desactiva Google Pay, pagos por NFC" ;;
    pt:avail_payments_tag) echo "    Desativa Google Pay e pagamentos por NFC" ;;
    tr:avail_payments_tag) echo "    Google Pay ve NFC temassız ödemeler çalışmaz" ;;
    id:avail_payments_tag) echo "    Mematikan Google Pay, pembayaran NFC" ;;
    ru:avail_payments_tag) echo "    Отключает Google Pay и NFC-оплату" ;;
    uk:avail_payments_tag) echo "    Вимикає Google Pay та NFC-оплату" ;;
    zh:avail_payments_tag) echo "    将禁用 Google Pay 及 NFC 非接触式支付" ;;
    ja:avail_payments_tag) echo "    Google Pay、NFC コンタクトレス決済が無効化" ;;
    ar:avail_payments_tag) echo "    يوقف Google Pay والدفع عبر NFC" ;;
     *:avail_payments_tag) echo "    Breaks Google Pay, NFC tap-to-pay" ;;

    fr:avail_wearables)   echo "⌚ Wearables" ;;
    de:avail_wearables)   echo "⌚ Wearables" ;;
    pl:avail_wearables)   echo "⌚ Urządzenia noszone" ;;
    it:avail_wearables)   echo "⌚ Wearables" ;;
    es:avail_wearables)   echo "⌚ Wearables" ;;
    pt:avail_wearables)   echo "⌚ Wearables" ;;
    tr:avail_wearables)   echo "⌚ Giyilebilir Cihazlar" ;;
    id:avail_wearables)   echo "⌚ Wearables" ;;
    ru:avail_wearables)   echo "⌚ Носимые устройства" ;;
    uk:avail_wearables)   echo "⌚ Носимі пристрої" ;;
    zh:avail_wearables)   echo "⌚ 穿戴设备 (Wearables)" ;;
    ja:avail_wearables)   echo "⌚ ウェアラブル (Wearables)" ;;
    ar:avail_wearables)   echo "⌚ الأجهزة القابلة للارتداء" ;;
     *:avail_wearables)   echo "⌚ Wearables" ;;

    fr:avail_wearables_tag) echo "    Désactive Wear OS, Google Fit" ;;
    de:avail_wearables_tag) echo "    Deaktiviert Wear OS, Google Fit" ;;
    pl:avail_wearables_tag) echo "    Psuje Wear OS, Google Fit" ;;
    it:avail_wearables_tag) echo "    Disabilita Wear OS, Google Fit" ;;
    es:avail_wearables_tag) echo "    Desactiva Wear OS, Google Fit" ;;
    pt:avail_wearables_tag) echo "    Desativa Wear OS, Google Fit" ;;
    tr:avail_wearables_tag) echo "    Wear OS ve Google Fit çalışmaz" ;;
    id:avail_wearables_tag) echo "    Mematikan Wear OS, Google Fit" ;;
    ru:avail_wearables_tag) echo "    Отключает Wear OS и Google Fit" ;;
    uk:avail_wearables_tag) echo "    Вимикає Wear OS та Google Fit" ;;
    zh:avail_wearables_tag) echo "    将禁用 Wear OS 和 Google Fit 健身追踪" ;;
    ja:avail_wearables_tag) echo "    Wear OS、Google Fit フィットネス追跡が無効化" ;;
    ar:avail_wearables_tag) echo "    يوقف Wear OS وتتبع Google Fit" ;;
     *:avail_wearables_tag) echo "    Breaks Wear OS, Google Fit" ;;

    fr:avail_games)       echo "🎮 Jeux" ;;
    de:avail_games)       echo "🎮 Spiele" ;;
    pl:avail_games)       echo "🎮 Gry" ;;
    it:avail_games)       echo "🎮 Giochi" ;;
    es:avail_games)       echo "🎮 Juegos" ;;
    pt:avail_games)       echo "🎮 Jogos" ;;
    tr:avail_games)       echo "🎮 Oyunlar" ;;
    id:avail_games)       echo "🎮 Game" ;;
    ru:avail_games)       echo "🎮 Игры" ;;
    uk:avail_games)       echo "🎮 Ігри" ;;
    zh:avail_games)       echo "🎮 游戏 (Games)" ;;
    ja:avail_games)       echo "🎮 ゲーム (Games)" ;;
    ar:avail_games)       echo "🎮 الألعاب (Games)" ;;
     *:avail_games)       echo "🎮 Games" ;;

    fr:avail_games_tag)   echo "    Désactive Play Games, sauvegardes cloud" ;;
    de:avail_games_tag)   echo "    Deaktiviert Play Games, Cloud-Speicherstände" ;;
    pl:avail_games_tag)   echo "    Psuje Play Games, zapisy w chmurze" ;;
    it:avail_games_tag)   echo "    Disabilita Play Games, salvataggi cloud" ;;
    es:avail_games_tag)   echo "    Desactiva Play Games, guardado en la nube" ;;
    pt:avail_games_tag)   echo "    Desativa Play Games, saves na nuvem" ;;
    tr:avail_games_tag)   echo "    Play Games başarıları ve bulut kayıtları çalışmaz" ;;
    id:avail_games_tag)   echo "    Mematikan Play Games, simpanan cloud" ;;
    ru:avail_games_tag)   echo "    Отключает Play Games и облачные сохранения" ;;
    uk:avail_games_tag)   echo "    Вимикає Play Games та хмарні збереження" ;;
    zh:avail_games_tag)   echo "    将禁用 Play 游戏成就及云存档同步" ;;
    ja:avail_games_tag)   echo "    Play ゲーム実績、クラウドセーブが無効化" ;;
    ar:avail_games_tag)   echo "    يوقف إنجازات Play Games والحفظ السحابي" ;;
     *:avail_games_tag)   echo "    Breaks Play Games, cloud saves" ;;

  esac
}

# Existing config detection
EXISTING_PREFS="$module_path/config/user_prefs"
EXISTING_WHITELIST="$module_path/config/doze_whitelist.txt"
USE_EXISTING=0

if [ -f "$EXISTING_PREFS" ]; then
  ui_print ""
  ui_print "$BOX_TOP"
  ui_print "  $(s cfg_detected)"
  ui_print "$BOX_BOT"
  ui_print ""
  ui_print "$(s cfg_vol_keep)"
  ui_print "$(s cfg_vol_reset)"
  ui_print "$(s cfg_timeout)"
  ui_print ""

  if [ "$HAS_GETEVENT" -eq 0 ]; then
    ui_print "$(s cfg_kept) (auto - no getevent)"
    USE_EXISTING=1
  else
    while :; do
      event=$(timeout "$TIMEOUT" getevent -qlc 1 2>/dev/null)
      code=$?
      if [ "$code" -eq 124 ] || [ "$code" -eq 143 ]; then
        ui_print "$(s cfg_kept) (timeout)"
        USE_EXISTING=1
        break
      fi
      if echo "$event" | grep -q "KEY_VOLUMEUP.*DOWN"; then
        ui_print "$(s cfg_kept)"
        USE_EXISTING=1
        break
      fi
      if echo "$event" | grep -q "KEY_VOLUMEDOWN.*DOWN"; then
        ui_print "$(s cfg_reset)"
        USE_EXISTING=0
        break
      fi
    done
  fi
fi

# Save Configuration
print_section "$(s save_title)"
mkdir -p "$MODPATH/config"

if [ "$USE_EXISTING" -eq 1 ]; then
  # Copy existing prefs
  cp -f "$EXISTING_PREFS" "$MODPATH/config/user_prefs"
  ui_print ""
  ui_print "$(s save_kept)"
  # Restore existing whitelist if present
  if [ -f "$EXISTING_WHITELIST" ]; then
    cp -f "$EXISTING_WHITELIST" "$MODPATH/config/doze_whitelist.txt"
    ui_print "$(s save_wl)"
  fi
  # Restore system.prop state to match existing pref
  . "$MODPATH/config/user_prefs"
  SYSPROP="$MODPATH/system.prop"
  SYSPROP_OLD="$MODPATH/system.prop.old"
  if [ "${ENABLE_SYSTEM_PROPS:-0}" -eq 1 ]; then
    [ -f "$SYSPROP_OLD" ] && mv "$SYSPROP_OLD" "$SYSPROP"
  else
    [ -f "$SYSPROP" ] && mv "$SYSPROP" "$SYSPROP_OLD"
  fi
else
  # Fresh install and reset
  ui_print ""
  ui_print "$(s save_default)"
  SYSPROP="$MODPATH/system.prop"
  SYSPROP_OLD="$MODPATH/system.prop.old"
  [ -f "$SYSPROP" ] && mv "$SYSPROP" "$SYSPROP_OLD"
fi

print_section "$(s avail_title)"
ui_print ""
ui_print "$(s avail_tweaks)"
ui_print "$SEP"
ui_print "    $(s avail_kernel)"
ui_print "$(s avail_kernel_desc)"
ui_print ""
ui_print "    $(s avail_sysprops)"
ui_print "$(s avail_sysprops_desc)"
ui_print ""
ui_print "    $(s avail_ram)"
ui_print "$(s avail_ram_desc)"
ui_print ""
ui_print "    $(s avail_blur)"
ui_print "$(s avail_blur_desc)"
ui_print ""
ui_print "    $(s avail_logs)"
ui_print "$(s avail_logs_desc)"
ui_print ""
ui_print "    $(s avail_gms_doze)"
ui_print "$(s avail_gms_doze_desc)"
ui_print ""
ui_print "    $(s avail_deep_doze)"
ui_print "$(s avail_deep_doze_desc)"
ui_print "$SEP"
ui_print ""
ui_print "$(s avail_cats)"
ui_print "$SEP"
ui_print "    $(s avail_telemetry)"
ui_print "$(s avail_telemetry_tag)"
ui_print ""
ui_print "    $(s avail_background)"
ui_print "$(s avail_background_tag)"
ui_print ""
ui_print "    $(s avail_location)"
ui_print "$(s avail_location_tag)"
ui_print ""
ui_print "    $(s avail_connectivity)"
ui_print "$(s avail_connectivity_tag)"
ui_print ""
ui_print "    $(s avail_cloud)"
ui_print "$(s avail_cloud_tag)"
ui_print ""
ui_print "    $(s avail_payments)"
ui_print "$(s avail_payments_tag)"
ui_print ""
ui_print "    $(s avail_wearables)"
ui_print "$(s avail_wearables_tag)"
ui_print ""
ui_print "    $(s avail_games)"
ui_print "$(s avail_games_tag)"
ui_print "$SEP"

print_section "$(s done_title)"
ui_print ""
ui_print "$(s done_reboot)"
ui_print "$(s done_webui)"
ui_print "$(s done_off)"
ui_print "$(s done_logs)"
ui_print ""
print_section "$(s stay_frosty)"
ui_print ""

rm -rf "$MODPATH/README.md" "$MODPATH/readme" "$MODPATH/LICENSE" "$MODPATH/CHANGELOG.md" "$MODPATH/update.json" "$MODPATH"/.git*
