#!/system/bin/sh
# Frosty - GMS Freezer / Battery Saver
# Author: Drsexo (GitHub)

TIMEOUT=30

COLS=$(stty size 2>/dev/null | awk '{print $2}')
case "$COLS" in ''|*[!0-9]*) COLS=40 ;; esac
[ "$COLS" -gt 54 ] && COLS=54; [ "$COLS" -lt 20 ] && COLS=40

_iw=$((COLS - 4))
LINE="" _i=0
while [ $_i -lt $_iw ]; do
  LINE="${LINE}─"
  _i=$((_i + 1))
done
BOX_TOP="  ┌${LINE}┐"
BOX_BOT="  └${LINE}┘"
unset _i _iw

if ! command -v timeout >/dev/null 2>&1; then
  timeout() { shift; "$@"; }
fi

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
  local nbytes nbytes_ascii len
  nbytes=$(printf '%s' "$text" | wc -c)
  nbytes_ascii=$(printf '%s' "$text" | LC_ALL=C tr -cd '[:print:]' | wc -c)
  local overhead=$(( nbytes - nbytes_ascii ))
  len=$(( nbytes_ascii + overhead / 2 ))
  [ "$len" -le 0 ] && len=${#text}
  local inner=$((COLS - 4))
  local offset=$(( (inner - len) / 2 ))
  [ "$offset" -lt 0 ] && offset=0
  local pad=$((offset + 3))
  local lpad="" _p=0
  while [ $_p -lt $pad ]; do lpad="${lpad} "; _p=$((_p+1)); done
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
set_perm "$MODPATH/screen_off_opt.sh" 0 0 0755
set_perm "$MODPATH/deep_doze.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/app_doze.sh" 0 0 0755
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
  print_section "$_LANG_FLAG  $_LANG_NAME detected"
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

s() {
  local key="$1"
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

    fr:done_logs)     echo "  📄 Journaux : $MODPATH/logs/" ;;
    de:done_logs)     echo "  📄 Logs: $MODPATH/logs/" ;;
    pl:done_logs)     echo "  📄 Logi: $MODPATH/logs/" ;;
    it:done_logs)     echo "  📄 Log: $MODPATH/logs/" ;;
    es:done_logs)     echo "  📄 Registros: $MODPATH/logs/" ;;
    pt:done_logs)     echo "  📄 Logs: $MODPATH/logs/" ;;
    tr:done_logs)     echo "  📄 Günlükler: $MODPATH/logs/" ;;
    id:done_logs)     echo "  📄 Log: $MODPATH/logs/" ;;
    ru:done_logs)     echo "  📄 Логи: $MODPATH/logs/" ;;
    uk:done_logs)     echo "  📄 Логи: $MODPATH/logs/" ;;
    zh:done_logs)     echo "  📄 日志: $MODPATH/logs/" ;;
    ja:done_logs)     echo "  📄 ログ: $MODPATH/logs/" ;;
    ar:done_logs)     echo "  📄 السجلات: $MODPATH/logs/" ;;
     *:done_logs)     echo "  📄 Logs: $MODPATH/logs/" ;;

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

    fr:upgrade_warn_title)  echo "  ⚠️  Mise à jour majeure - Installation propre recommandée" ;;
    de:upgrade_warn_title)  echo "  ⚠️  Großes Update - Neuinstallation empfohlen" ;;
    pl:upgrade_warn_title)  echo "  ⚠️  Duża aktualizacja - Zalecana czysta instalacja" ;;
    it:upgrade_warn_title)  echo "  ⚠️  Aggiornamento importante - Consigliata installazione pulita" ;;
    es:upgrade_warn_title)  echo "  ⚠️  Actualización importante - Se recomienda instalación limpia" ;;
    pt:upgrade_warn_title)  echo "  ⚠️  Atualização importante - Instalação limpa recomendada" ;;
    tr:upgrade_warn_title)  echo "  ⚠️  Büyük Güncelleme - Temiz kurulum önerilir" ;;
    id:upgrade_warn_title)  echo "  ⚠️  Pembaruan Besar - Instalasi bersih disarankan" ;;
    ru:upgrade_warn_title)  echo "  ⚠️  Крупное обновление - Рекомендуется чистая установка" ;;
    uk:upgrade_warn_title)  echo "  ⚠️  Велике оновлення - Рекомендується чиста установка" ;;
    zh:upgrade_warn_title)  echo "  ⚠️  重大更新 - 建议执行全新安装" ;;
    ja:upgrade_warn_title)  echo "  ⚠️  大型アップデート - クリーンインストールを推奨" ;;
    ar:upgrade_warn_title)  echo "  ⚠️  تحديث كبير - يُنصح بتثبيت نظيف (من الصفر)" ;;
     *:upgrade_warn_title)  echo "  ⚠️  Major Update - Clean Install Recommended" ;;

    fr:upgrade_warn_line1)  echo "  Cette version inclut des changements de code importants." ;;
    de:upgrade_warn_line1)  echo "  Diese Version enthält umfangreiche Code-Änderungen." ;;
    pl:upgrade_warn_line1)  echo "  Ta wersja zawiera znaczące zmiany w kodzie." ;;
    it:upgrade_warn_line1)  echo "  Questa versione include modifiche significative al codice." ;;
    es:upgrade_warn_line1)  echo "  Esta versión incluye cambios significativos en el código." ;;
    pt:upgrade_warn_line1)  echo "  Esta versão inclui mudanças significativas no código." ;;
    tr:upgrade_warn_line1)  echo "  Bu sürüm önemli kod değişiklikleri içermektedir." ;;
    id:upgrade_warn_line1)  echo "  Versi ini mencakup perubahan kode yang signifikan." ;;
    ru:upgrade_warn_line1)  echo "  Эта версия включает значительные изменения в коде." ;;
    uk:upgrade_warn_line1)  echo "  Ця версія містить значні зміни в коді." ;;
    zh:upgrade_warn_line1)  echo "  此版本包含大量的底层代码更改。" ;;
    ja:upgrade_warn_line1)  echo "  このバージョンには大幅なコード変更が含まれています。" ;;
    ar:upgrade_warn_line1)  echo "  يتضمن هذا الإصدار تغييرات جذرية في الأكواد." ;;
     *:upgrade_warn_line1)  echo "  This version includes significant code changes." ;;

    fr:upgrade_warn_line2)  echo "  Si vous rencontrez des problèmes après la mise à jour :" ;;
    de:upgrade_warn_line2)  echo "  Falls nach dem Update Probleme auftreten:" ;;
    pl:upgrade_warn_line2)  echo "  Jeśli po aktualizacji wystąpią problemy:" ;;
    it:upgrade_warn_line2)  echo "  Se riscontri problemi dopo l'aggiornamento:" ;;
    es:upgrade_warn_line2)  echo "  Si experimentas problemas después de actualizar:" ;;
    pt:upgrade_warn_line2)  echo "  Se você enfrentar problemas após a atualização:" ;;
    tr:upgrade_warn_line2)  echo "  Güncelleme sonrasında sorun yaşarsanız:" ;;
    id:upgrade_warn_line2)  echo "  Jika Anda mengalami masalah setelah memperbarui:" ;;
    ru:upgrade_warn_line2)  echo "  Если после обновления возникнут проблемы:" ;;
    uk:upgrade_warn_line2)  echo "  Якщо після оновлення виникнуть проблеми:" ;;
    zh:upgrade_warn_line2)  echo "  如果在更新后遇到任何问题：" ;;
    ja:upgrade_warn_line2)  echo "  アップデート後に問題が発生した場合：" ;;
    ar:upgrade_warn_line2)  echo "  إذا واجهت أي مشاكل بعد التحديث:" ;;
     *:upgrade_warn_line2)  echo "  If you experience issues after updating:" ;;

    fr:upgrade_warn_line3)  echo "  Désinstaller -> Redémarrer -> Réinstaller proprement" ;;
    de:upgrade_warn_line3)  echo "  Deinstallieren -> Neustart -> Neu installieren" ;;
    pl:upgrade_warn_line3)  echo "  Odinstaluj -> Uruchom ponownie -> Zainstaluj na nowo" ;;
    it:upgrade_warn_line3)  echo "  Disinstalla -> Riavvia -> Installa da zero" ;;
    es:upgrade_warn_line3)  echo "  Desinstalar -> Reiniciar -> Instalar desde cero" ;;
    pt:upgrade_warn_line3)  echo "  Desinstalar -> Reiniciar -> Instalar do zero" ;;
    tr:upgrade_warn_line3)  echo "  Kaldır -> Yeniden başlat -> Sıfırdan kur" ;;
    id:upgrade_warn_line3)  echo "  Hapus -> Restart -> Instal dari awal" ;;
    ru:upgrade_warn_line3)  echo "  Удалить -> Перезагрузить -> Установить начисто" ;;
    uk:upgrade_warn_line3)  echo "  Видалити -> Перезавантажити -> Встановити начисто" ;;
    zh:upgrade_warn_line3)  echo "  卸载 -> 重启 -> 重新安装" ;;
    ja:upgrade_warn_line3)  echo "  アンインストール -> 再起動 -> 新規インストール" ;;
    ar:upgrade_warn_line3)  echo "  إلغاء التثبيت -> إعادة التشغيل -> تثبيت من جديد" ;;
     *:upgrade_warn_line3)  echo "  Uninstall -> Reboot -> Install fresh" ;;

  esac
}

# Upgrade warning - shown when a previous installation is detected
INSTALLED_PROP="/data/adb/modules/$MODID/module.prop"
if [ -f "$INSTALLED_PROP" ]; then
  _installed_vc=$(grep "^versionCode=" "$INSTALLED_PROP" 2>/dev/null | cut -d= -f2)
  if [ -n "$_installed_vc" ] && [ "$_installed_vc" -le 37 ] 2>/dev/null; then
    ui_print "$(s upgrade_warn_title)"
    ui_print ""
    ui_print "$(s upgrade_warn_line1)"
    ui_print "$(s upgrade_warn_line2)"
    ui_print "$(s upgrade_warn_line3)"
    ui_print ""
    sleep 3
  fi
fi

# Existing config detection
EXISTING_PREFS="/data/adb/modules/$MODID/config/user_prefs"
EXISTING_WHITELIST="/data/adb/modules/$MODID/config/doze_whitelist.txt"
EXISTING_PATCHES="/data/adb/modules/$MODID/config/doze_patches.txt"
USE_EXISTING=0

if [ -f "$EXISTING_PREFS" ]; then
  print_section "$(s cfg_detected)"
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
  cp -f "$EXISTING_PREFS" "$MODPATH/config/user_prefs"
  ui_print ""
  ui_print "$(s save_kept)"
  if [ -f "$EXISTING_WHITELIST" ]; then
    cp -f "$EXISTING_WHITELIST" "$MODPATH/config/doze_whitelist.txt"
    ui_print "$(s save_wl)"
  fi
  if [ -f "$EXISTING_PATCHES" ]; then
    cp -f "$EXISTING_PATCHES" "$MODPATH/config/doze_patches.txt"
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
  ui_print ""
  ui_print "$(s save_default)"
  SYSPROP="$MODPATH/system.prop"
  SYSPROP_OLD="$MODPATH/system.prop.old"
  [ -f "$SYSPROP" ] && mv "$SYSPROP" "$SYSPROP_OLD"
fi

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