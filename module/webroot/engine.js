// Frosty WebUI Engine - shared behavior core for all redesign skins
// Keeps the exact backend contract of the original WebUI (api.js/app.js, Frosty 4.4)

var FX = (function () {
  'use strict';

  var MODDIR = '/data/adb/modules/Frosty';
  var PREFS  = MODDIR + '/config/user_prefs';
  var LOG_DIR = MODDIR + '/logs';

  var state = { prefs: {}, categories: {} };
  var busy = false;
  var pollTimer = null;
  var logs = [];
  var cbCounter = 0;
  var hooks = { render: [], view: [], log: [], ready: [] };
  var modalStack = [];
  var historyPushCount = 0;
  var currentView = null;

  // ── skin registry ──

  var SKINS = {};
  var _skinResolved = false, _skin = null;

  function registerSkin(id, def) { SKINS[id] = def || {}; }

  function currentSkinId() { return document.body.getAttribute('data-fx-skin') || 'stock'; }

  function activeSkin() {
    if (!_skinResolved) { _skin = SKINS[currentSkinId()] || null; _skinResolved = true; }
    return _skin;
  }

  // ── bridge ──

  function ksuAvailable() {
    return typeof ksu !== 'undefined' && typeof ksu.exec === 'function';
  }

  var demo = !ksuAvailable();

  function uid() { return 'cb_' + Date.now() + '_' + (cbCounter++); }

  var EXEC_TIMEOUT_MS = 600000;

  function exec(cmd, opts) {
    return new Promise(function (resolve, reject) {
      if (demo) { resolve(demoExec(cmd)); return; }
      var name = uid();
      var timer = setTimeout(function () {
        delete window[name];
        reject(new Error('exec timeout'));
      }, EXEC_TIMEOUT_MS);
      window[name] = function (errno, stdout, stderr) {
        clearTimeout(timer);
        delete window[name];
        resolve({ errno: errno, stdout: stdout || '', stderr: stderr || '' });
      };
      try {
        ksu.exec(cmd, JSON.stringify(opts || {}), name);
      } catch (e) {
        clearTimeout(timer);
        delete window[name];
        reject(e);
      }
    });
  }

  async function run(cmd) {
    var r = await exec(cmd);
    return (r.stdout || '').trim();
  }

  async function runStrict(cmd) {
    var r = await exec(cmd);
    if (r.errno !== 0) throw new Error(r.stderr || 'exit ' + r.errno);
    return (r.stdout || '').trim();
  }

  async function runJSON(cmd) {
    var r = await exec(cmd);
    var raw = (r.stdout || '').trim();
    if (r.errno !== 0 && !raw) {
      throw new Error('exit ' + r.errno + (r.stderr ? ': ' + r.stderr.substring(0, 200) : ''));
    }
    try { return JSON.parse(raw); }
    catch (e) { throw new Error('Bad JSON: ' + raw.substring(0, 120)); }
  }

  function esc(s) { return String(s).replace(/'/g, "'\\''"); }
  function escSed(s) { return String(s).replace(/[\\|&]/g, '\\$&'); }

  // ── demo bridge (browser preview, no root) ──

  var DEMO_PKGS = [
    'com.google.android.gms', 'com.google.android.gsf', 'com.android.vending',
    'com.google.android.googlequicksearchbox', 'com.google.android.apps.photos',
    'com.google.android.youtube', 'com.google.android.apps.maps', 'com.google.android.gm',
    'com.google.android.apps.messaging', 'com.google.android.dialer',
    'com.whatsapp', 'com.facebook.katana', 'com.instagram.android',
    'com.spotify.music', 'org.telegram.messenger', 'com.discord',
    'com.twitter.android', 'com.reddit.frontpage', 'com.amazon.mShop.android.shopping',
    'com.netflix.mediaclient', 'com.paypal.android.p2pmobile', 'com.skype.raider',
    'com.snapchat.android', 'com.spotify.music.dogfood', 'org.mozilla.firefox',
    'com.brave.browser', 'com.termux', 'com.sync.TODO_APP', 'mark.via.gp'
  ];

  function demoPrefsText() {
    var saved = {};
    try { saved = JSON.parse(localStorage.getItem('frosty_demo_prefs') || '{}'); } catch (e) {}
    var base = {
      ENABLE_KERNEL_TWEAKS: 1, ENABLE_SYSTEM_PROPS: 0, ENABLE_BLUR_DISABLE: 0,
      ENABLE_LOG_KILLING: 0, ENABLE_KILL_TRACKING: 1, ENABLE_RAM_OPTIMIZER: 1,
      MULTITASK_ENABLED: 1,
      ENABLE_DEEP_DOZE: 1, DEEP_DOZE_LEVEL: 'moderate', RAM_OPT_LEVEL: 'moderate',
      MULTITASK_PROFILE: 'balanced', ENABLE_BATTERY_SAVER: 0,
      BSS_SOUNDTRIGGER_DISABLED: 0, BSS_FULLBACKUP_DEFERRED: 0, BSS_KEYVALUEBACKUP_DEFERRED: 0,
      BSS_FORCE_STANDBY: 0, BSS_FORCE_BG_CHECK: 0, BSS_SENSORS_DISABLED: 0, BSS_GPS_MODE: 0,
      BSS_DATASAVER: 0, BSS_MAX_REFRESH: 0,
      ENABLE_CUSTOM_APP_DOZE: 0, ENABLE_SCREEN_OFF_OPT: 0,
      SOO_KILL_WIFI: 0, SOO_KILL_BT: 0, SOO_KILL_DATA: 0, SOO_KILL_LOCATION: 0,
      SOO_KILL_SENSORS: 0, SOO_KILL_PANEL_LPM: 0, SOO_CONN_DELAY: 5,
      SOO_RESTORE_ON_UNLOCK: 1, SOO_RAM_CLEAN_MODE: 'off', SOO_RAM_CLEAN_DELAY: 5,
      DISABLE_TELEMETRY: 1, DISABLE_BACKGROUND: 1, DISABLE_LOCATION: 0,
      DISABLE_CONNECTIVITY: 0, DISABLE_CLOUD: 0, DISABLE_PAYMENTS: 0,
      DISABLE_WEARABLES: 0, DISABLE_GAMES: 0
    };
    for (var k in saved) base[k] = saved[k];
    return Object.keys(base).map(function (k) { return k + '=' + base[k]; }).join('\n');
  }

  function demoExec(cmd) {
    var out = '', errno = 0;
    if (cmd.indexOf('cat ' + PREFS) === 0) {
      out = demoPrefsText();
    } else if (cmd.indexOf('module.prop') !== -1) {
      out = 'id=Frosty\nname=Frosty\nversion=demo\nauthor=Drsexo\ndescription=Demo preview mode - no root bridge detected';
    } else if (cmd === 'sh ' + MODDIR + '/scripts/frosty.sh list_wl 2>/dev/null') {
      out = '{"status":"ok","packages":[]}';
    } else if (cmd.indexOf('list_ram_wl') !== -1) {
      out = '{"status":"ok","packages":[]}';
    } else if (cmd.indexOf('app_doze.sh list') !== -1) {
      out = '{"status":"ok","packages":[]}';
    } else if (cmd.indexOf('app_doze.sh scan') !== -1) {
      out = DEMO_PKGS.slice(0, 12).join('\n');
    } else if (cmd.indexOf('list_backups') !== -1) {
      out = '[{"name":"frosty_20260829_101530.json","path":"' + MODDIR + '/backups/frosty_20260829_101530.json"},{"name":"frosty_20260701_220001.json","path":"' + MODDIR + '/backups/frosty_20260701_220001.json"}]';
    } else if (cmd.indexOf('list_bug_reports') !== -1) {
      out = '[{"name":"frosty_bug_20260830_2115.log","path":"' + MODDIR + '/logs/frosty_bug_20260830_2115.log"}]';
    } else if (cmd.indexOf(' && echo OK;') !== -1) {
      out = 'OK';
    } else if (cmd.indexOf('frosty.sh export') !== -1) {
      out = MODDIR + '/backups/frosty_20260903_120000.json';
    } else if (cmd.indexOf('frosty.sh freeze ') !== -1 || (cmd.indexOf('frosty.sh freeze') !== -1)) {
      out = 'Disabled: 42\nRe-enabled: 0\nFailed: 0';
    } else if (cmd.indexOf('frosty.sh stock') !== -1) {
      out = 'Re-enabled: 42\nFailed: 0';
    } else if (cmd.indexOf('ram_clean_poll') !== -1) {
      out = '{"running":false,"apps":23,"freed":1184}';
    } else if (cmd.indexOf('ram_clean ') !== -1) {
      out = '{"status":"started"}';
    } else if (cmd.indexOf('cad_needs_reboot') !== -1) {
      out = '0';
    } else if (cmd.indexOf('add_wl') !== -1 || cmd.indexOf('remove_wl') !== -1 ||
               cmd.indexOf('add_ram_wl') !== -1 || cmd.indexOf('remove_ram_wl') !== -1 ||
               cmd.indexOf('app_doze.sh add') !== -1 || cmd.indexOf('app_doze.sh remove') !== -1) {
      out = '{"status":"ok"}';
    } else if (cmd.indexOf('frosty.sh import') !== -1) {
      out = 'OK';
    } else if (cmd.indexOf('sed -i') !== -1 || cmd.indexOf(">> '" + PREFS + "'") !== -1) {
      try {
        var m = cmd.match(/echo '([A-Z_]+)=([^']*)' >>/) ||
                cmd.match(/sed -i 's\|\^([A-Z_]+)=\.\*\|\1=([^|]*)\|'/) ||
                cmd.match(/([A-Z_]+)=([^']*)'/);
        if (m) {
          var sp = JSON.parse(localStorage.getItem('frosty_demo_prefs') || '{}');
          sp[m[1]] = m[2];
          localStorage.setItem('frosty_demo_prefs', JSON.stringify(sp));
        }
      } catch (e) {}
      out = '';
    } else {
      out = '{"status":"ok","applied":6,"restored":0,"failed":0,"skipped":0,"killed":7}';
    }
    return { errno: errno, stdout: out, stderr: '' };
  }

  // ── prefs schema (identical to original api.js) ──

  var PREF_MAP = {
    kernel_tweaks:   'ENABLE_KERNEL_TWEAKS',
    system_props:    'ENABLE_SYSTEM_PROPS',
    blur_disable:    'ENABLE_BLUR_DISABLE',
    log_killing:     'ENABLE_LOG_KILLING',
    kill_tracking:   'ENABLE_KILL_TRACKING',
    ram_optimizer:   'ENABLE_RAM_OPTIMIZER',
    multitask_enabled: 'MULTITASK_ENABLED',
    deep_doze:       'ENABLE_DEEP_DOZE',
    deep_doze_level: 'DEEP_DOZE_LEVEL',
    deep_doze_always: 'DEEP_DOZE_ALWAYS',
    ram_optimizer_level: 'RAM_OPT_LEVEL',
    battery_saver:              'ENABLE_BATTERY_SAVER',
    bss_soundtrigger_disabled:  'BSS_SOUNDTRIGGER_DISABLED',
    bss_fullbackup_deferred:    'BSS_FULLBACKUP_DEFERRED',
    bss_keyvaluebackup_deferred:'BSS_KEYVALUEBACKUP_DEFERRED',
    bss_force_standby:          'BSS_FORCE_STANDBY',
    bss_force_bg_check:         'BSS_FORCE_BG_CHECK',
    bss_sensors_disabled:       'BSS_SENSORS_DISABLED',
    bss_gps_mode:               'BSS_GPS_MODE',
    bss_datasaver:              'BSS_DATASAVER',
    bss_max_refresh:            'BSS_MAX_REFRESH',
    multitask_profile:          'MULTITASK_PROFILE',
    custom_app_doze:            'ENABLE_CUSTOM_APP_DOZE',
    screen_off_opt:             'ENABLE_SCREEN_OFF_OPT',
    soo_kill_wifi:              'SOO_KILL_WIFI',
    soo_kill_bt:                'SOO_KILL_BT',
    soo_kill_data:              'SOO_KILL_DATA',
    soo_kill_nfc:               'SOO_KILL_NFC',
    soo_kill_location:          'SOO_KILL_LOCATION',
    soo_conn_delay:             'SOO_CONN_DELAY',
    soo_restore_on_unlock:      'SOO_RESTORE_ON_UNLOCK',
    soo_ram_clean_mode:         'SOO_RAM_CLEAN_MODE',
    soo_ram_clean_delay:        'SOO_RAM_CLEAN_DELAY',
    soo_kill_sensors:           'SOO_KILL_SENSORS',
    soo_kill_panel_lpm:         'SOO_KILL_PANEL_LPM',
    webui_theme:                'WEBUI_THEME'
  };
  var CAT_MAP = {
    telemetry:    'DISABLE_TELEMETRY',
    background:   'DISABLE_BACKGROUND',
    location:     'DISABLE_LOCATION',
    connectivity: 'DISABLE_CONNECTIVITY',
    cloud:        'DISABLE_CLOUD',
    payments:     'DISABLE_PAYMENTS',
    wearables:    'DISABLE_WEARABLES',
    games:        'DISABLE_GAMES'
  };
  var ENUM_VALUES = {
    deep_doze_level:       ['minimum', 'moderate', 'maximum'],
    ram_optimizer_level:   ['moderate', 'maximum'],
    multitask_profile: ['performance', 'balanced', 'powersaving'],
    soo_ram_clean_mode:    ['off', 'safe', 'aggressive', 'extreme'],
    webui_theme:           ['stock', 'comic', 'retro', 'terminal', 'handheld']
  };

  async function getPrefs() {
    var prefRaw = await run('cat ' + PREFS + ' 2>/dev/null');
    var vals = {};
    if (prefRaw) {
      prefRaw.split('\n').forEach(function (line) {
        var eq = line.indexOf('=');
        if (eq > 0) {
          var k = line.substring(0, eq).trim();
          var v = line.substring(eq + 1).trim();
          if (k) vals[k] = v;
        }
      });
    }
    var BSS_DEFAULT_0 = {
      bss_soundtrigger_disabled: 0, bss_fullbackup_deferred: 0,
      bss_keyvaluebackup_deferred: 0, bss_sensors_disabled: 0
    };
    var SOO_DEFAULTS = { soo_restore_on_unlock: 1, soo_conn_delay: 5, soo_ram_clean_delay: 5 };
    var ENUM_DEFAULTS = {
      deep_doze_level: 'minimum', ram_optimizer_level: 'moderate',
      multitask_profile: 'balanced', soo_ram_clean_mode: 'off', webui_theme: 'stock'
    };
    var prefs = {};
    for (var pk in PREF_MAP) {
      var envKey = PREF_MAP[pk];
      if (pk === 'webui_theme') {
        prefs[pk] = ENUM_VALUES.webui_theme.indexOf(vals[envKey]) !== -1 ? vals[envKey] : 'stock';
      } else if (ENUM_VALUES[pk]) {
        prefs[pk] = ENUM_VALUES[pk].indexOf(vals[envKey]) !== -1 ? vals[envKey] : ENUM_DEFAULTS[pk];
      } else if (BSS_DEFAULT_0[pk] !== undefined) {
        prefs[pk] = vals[envKey] !== undefined && vals[envKey] !== '' ? parseInt(vals[envKey]) : 0;
      } else if (SOO_DEFAULTS[pk] !== undefined) {
        prefs[pk] = vals[envKey] !== undefined && vals[envKey] !== '' ? parseInt(vals[envKey]) : SOO_DEFAULTS[pk];
      } else {
        prefs[pk] = parseInt(vals[envKey]) || 0;
      }
    }
    var cats = {};
    for (var ck in CAT_MAP) cats[ck] = parseInt(vals[CAT_MAP[ck]]) || 0;
    return { prefs: prefs, categories: cats };
  }

  async function setPref(key, value) {
    var envKey = PREF_MAP[key] || CAT_MAP[key];
    if (!envKey) return { status: 'error', message: 'Unknown key: ' + key };
    var val = String(value);
    if (ENUM_VALUES[key]) {
      if (ENUM_VALUES[key].indexOf(val) === -1) return { status: 'error', message: 'Invalid value for ' + key };
    } else if (!/^-?[0-9]+$/.test(val)) {
      return { status: 'error', message: 'Invalid value for ' + key };
    }
    var sedVal = esc(escSed(val));
    var cmd = "if grep -q '^" + envKey + "=' '" + PREFS + "' 2>/dev/null; then " +
      "sed -i 's|^" + envKey + "=.*|" + envKey + "=" + sedVal + "|' '" + PREFS + "'; " +
      "else echo '" + envKey + "=" + esc(val) + "' >> '" + PREFS + "'; fi";
    await run(cmd);
    return { status: 'ok' };
  }

  function appendLog(msg) {
    var safeMsg = String(msg).replace(/[\r\n]/g, ' ').replace(/'/g, "'\\''").substring(0, 200);
    exec("printf '[%s] [webui] %s\\n' \"$(date +'%Y-%m-%d %H:%M:%S')\" '" + safeMsg + "' >> \"" + LOG_DIR + "/action.log\"");
  }

  // ── i18n (identical mechanism to original app.js) ──

  var _strings = {};
  var _enStrings = {};
  var _lang = 'en';
  var RTL_LANGS = ['ar'];

  function t(key) { return _strings[key] || _enStrings[key] || key; }

  function tf(key) {
    var s = t(key);
    var args = arguments;
    return s.replace(/{(\d+)}/g, function (_, i) {
      return args[parseInt(i) + 1] !== undefined ? args[parseInt(i) + 1] : '';
    });
  }

  var _TKEY_MAP = {
    kernel_tweaks: 'tgl_kernel', system_props: 'tgl_sysprops',
    blur_disable: 'tgl_blur', log_killing: 'tgl_logs',
    kill_tracking: 'tgl_tracking', ram_optimizer: 'tgl_ram_optimizer',
    multitask_enabled: 'multitask_title',
    deep_doze: 'tgl_deep_doze', battery_saver: 'tgl_bss',
    deep_doze_always: 'tgl_deep_doze_always',
    custom_app_doze: 'tgl_cad', screen_off_opt: 'tgl_soo',
    telemetry: 'cat_telemetry', background: 'cat_background',
    location: 'cat_location', connectivity: 'cat_connectivity',
    cloud: 'cat_cloud', payments: 'cat_payments',
    wearables: 'cat_wearables', games: 'cat_games'
  };
  function tkey(k) { return t(_TKEY_MAP[k] || k); }

  function applyStrings() {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      if (_strings[key]) el.textContent = _strings[key];
    });
    document.querySelectorAll('[data-i18n-ph]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-ph');
      if (_strings[key]) el.placeholder = _strings[key];
    });
    document.querySelectorAll('[data-i18n-aria]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-aria');
      if (_strings[key]) el.setAttribute('aria-label', _strings[key]);
    });
    document.documentElement.lang = _lang;
    document.documentElement.dir = RTL_LANGS.indexOf(_lang) !== -1 ? 'rtl' : 'ltr';
  }

  async function loadLang(code) {
    try {
      var resp = await fetch('locales/strings/' + code + '.xml');
      if (!resp.ok) throw new Error('not found');
      var doc = new DOMParser().parseFromString(await resp.text(), 'application/xml');
      var map = {};
      doc.querySelectorAll('string').forEach(function (node) {
        map[node.getAttribute('name')] = node.textContent;
      });
      _strings = map;
      _lang = code;
      if (code === 'en') {
        _enStrings = map;
      } else if (!Object.keys(_enStrings).length) {
        try {
          var enR = await fetch('locales/strings/en.xml');
          if (enR.ok) {
            var enDoc = new DOMParser().parseFromString(await enR.text(), 'application/xml');
            _enStrings = {};
            enDoc.querySelectorAll('string').forEach(function (n) {
              _enStrings[n.getAttribute('name')] = n.textContent;
            });
          }
        } catch (ef) {}
      }
      applyStrings();
      try { localStorage.setItem('frosty_lang', code); } catch (e) {}
    } catch (e) {
      if (code !== 'en') await loadLang('en');
    }
  }

  async function initLang() {
    var saved;
    try { saved = localStorage.getItem('frosty_lang'); } catch (e) {}
    var navFull = (navigator.language || 'en');
    var navShort = navFull.split('-')[0];
    var supported = ['en','fr','de','pl','it','es','pt-BR','tr','id','ru','uk','zh-CN','ja','ar'];
    var detected = supported.find(function (c) { return c === navFull; }) ||
                   supported.find(function (c) { return c.split('-')[0] === navShort; }) ||
                   'en';
    await loadLang(saved || detected);
    if (!saved && detected !== 'en') {
      var match = LANGUAGES.find(function (l) { return l[0] === detected; });
      if (match) showLangConfirm(detected, match[1], match[2]);
    }
  }

  var LANGUAGES = [];

  function showLangConfirm(code, flag, fullName) {
    var HEADERS = {
      fr: 'Langue détectée', de: 'Sprache erkannt', pl: 'Wykryto język',
      it: 'Lingua rilevata', es: 'Idioma detectado', 'pt-BR': 'Idioma detectado',
      tr: 'Dil algılandı', id: 'Bahasa terdeteksi', ru: 'Обнаружен язык',
      uk: 'Виявлено мову', 'zh-CN': '检测到语言', ja: '言語を検出しました', ar: 'تم اكتشاف اللغة'
    };
    var QUESTIONS = {
      fr: 'Voulez-vous utiliser cette langue ?', de: 'Möchten Sie diese Sprache verwenden?',
      pl: 'Chcesz używać tego języka?', it: 'Vuoi usare questa lingua?',
      es: '¿Deseas usar este idioma?', 'pt-BR': 'Deseja usar este idioma?',
      tr: 'Bu dili kullanmak ister misiniz?', id: 'Ingin menggunakan bahasa ini?',
      ru: 'Использовать этот язык?', uk: 'Бажаєте використовувати цю мову?',
      'zh-CN': '是否使用这种语言？', ja: 'この言語を使用しますか？', ar: 'هل تريد استخدام هذه اللغة؟'
    };
    var card = el('div', 'fx-modal-card fx-langconfirm', null,
      el('div', 'fx-lcflag', null, flag) +
      el('div', 'fx-lchead', null, HEADERS[code] || 'Detected language') +
      el('div', 'fx-lcname', null, fullName) +
      el('div', 'fx-lcquestion', null, QUESTIONS[code] || 'Would you like to use this language?') +
      '<div class="fx-lcbtns">' +
        '<button class="fx-btn fx-btn-primary" data-lc="keep">' + flag + ' ' + fullName + '</button>' +
        '<button class="fx-btn" data-lc="en">English</button>' +
      '</div>');
    var backdrop = el('div', 'fx-modal fx-open fx-centered', { id: 'fx-m-langconfirm' }, card);
    document.body.appendChild(backdrop);
    function close() { backdrop.remove(); }
    backdrop.querySelector('[data-lc="keep"]').onclick = function () {
      close();
      try { localStorage.setItem('frosty_lang', code); } catch (e) {}
    };
    backdrop.querySelector('[data-lc="en"]').onclick = function () {
      close();
      loadLang('en');
    };
  }

  // ── dom helpers ──

  function el(tag, cls, attrs, inner) {
    var n = document.createElement(tag);
    if (cls) n.className = cls;
    if (attrs) for (var k in attrs) n.setAttribute(k, attrs[k]);
    if (inner !== undefined && inner !== null) n.innerHTML = inner;
    return n;
  }

  function $(sel) { return document.querySelector(sel); }
  function $all(sel) { return Array.prototype.slice.call(document.querySelectorAll(sel)); }

  function svg(path, size, stroke) {
    return '<svg viewBox="0 0 24 24" width="' + (size || 18) + '" height="' + (size || 18) + '" fill="' + (stroke ? 'none' : 'currentColor') + '"' +
      (stroke ? ' stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"' : '') +
      ' aria-hidden="true"><path d="' + path + '"/></svg>';
  }
  var ICO = {
    check: 'M4 12.5L9.5 18L20 6',
    x: 'M6 6l12 12M18 6L6 18',
    info: 'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z',
    import: 'M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zm-7 14-5-5 1.41-1.41L11 13.17V7h2v6.17l2.59-2.58L17 12l-5 5z',
    del: 'M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zm2.46-7.12 1.41-1.41L12 12.59l2.12-2.12 1.41 1.41L13.41 14l2.12 2.12-1.41 1.41L12 15.41l-2.12 2.12-1.41-1.41L10.59 14l-2.13-2.12zM15.5 4l-1-1h-5l-1 1H5v2h14V4z',
    rename: 'M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z',
    bug: 'M12 7a3 3 0 1 0 0 6 3 3 0 0 0 0-6z',
    gh: 'M12 2a10 10 0 0 0-3.16 19.49c.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.45-1.16-1.11-1.47-1.11-1.47-.9-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.9 1.52 2.34 1.08 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.94 0-1.1.39-1.99 1.03-2.69-.1-.25-.45-1.27.1-2.64 0 0 .84-.27 2.75 1.02a9.58 9.58 0 0 1 5 0c1.91-1.31 2.75-1.02 2.75-1.02.55 1.37.2 2.39.1 2.64.64.7 1.03 1.6 1.03 2.69 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85V21c0 .27.18.58.69.48A10 10 0 0 0 12 2z'
  };

  // ── ui primitives: toast, loading, log ──

  var toastWrap = null;

  function ensureChrome() {
    if (!document.getElementById('fx-toasts')) {
      toastWrap = el('div', null, { id: 'fx-toasts', role: 'status', 'aria-live': 'polite' });
      document.body.appendChild(toastWrap);
      var st = el('style');
      st.textContent =
        '#fx-toasts{position:fixed;top:calc(12px + var(--fx-safe-top,0px));left:50%;transform:translateX(-50%);z-index:9999;display:flex;flex-direction:column;align-items:center;gap:6px;pointer-events:none;width:min(92vw,420px)}' +
        ':where(.fx-toast){pointer-events:auto;display:flex;align-items:center;gap:8px;padding:10px 14px;border-radius:10px;font:600 13px/1.3 system-ui,sans-serif;opacity:0;transform:translateY(-8px);transition:opacity .18s ease,transform .18s ease;background:#222;color:#eee;border:1px solid rgba(255,255,255,.12)}' +
        '.fx-toast.show{opacity:1;transform:none}' +
        ':where(.fx-toast.ok){color:#6fe08f}:where(.fx-toast.err){color:#ff7676}:where(.fx-toast.warn){color:#e5a940}:where(.fx-toast.info){color:#eee}' +
        ':where(#fx-loading){position:fixed;inset:0;z-index:10000;display:none;align-items:center;justify-content:center;background:var(--fx-loading-dim,rgba(0,0,0,.45))}' +
        '#fx-loading.open{display:flex}' +
        '#fx-loading.fx-reset *,#fx-loading.fx-reset *::before,#fx-loading.fx-reset *::after{animation:none!important}' +
        ':where(.fx-loadcard){display:flex;flex-direction:column;align-items:center;gap:12px;padding:26px 34px;border-radius:14px;background:var(--fx-loading-bg,#1b1d20);color:var(--fx-loading-fg,#eee);min-width:190px}' +
        ':where(.fx-spin){width:26px;height:26px;border-radius:50%;border:3px solid rgba(255,255,255,.15);border-top-color:var(--fx-accent,#4da3ff);animation:fxspin .8s linear infinite}' +
        '@keyframes fxspin{to{transform:rotate(360deg)}}' +
        ':where(.fx-loadtxt){font:600 12.5px/1.35 system-ui,sans-serif;text-align:center}' +
        ':where(.fx-modal){position:fixed;inset:0;z-index:5000;display:none;align-items:flex-end;justify-content:center;background:var(--fx-modal-dim,rgba(0,0,0,.5))}' +
        '.fx-modal.fx-open{display:flex}' +
        '.fx-modal.fx-centered{align-items:center}' +
        ':where(.fx-modal-card){display:flex;flex-direction:column;width:min(100vw,560px);max-height:86vh;background:var(--fx-modal-bg,#181a1d);color:var(--fx-modal-fg,#eee);border-radius:16px 16px 0 0;overflow:hidden}' +
        '.fx-modal.fx-centered .fx-modal-card{border-radius:16px}' +
        '@media(min-width:600px){.fx-modal{align-items:center}.fx-modal-card{border-radius:16px}}' +
        ':where(.fx-modal-head){display:flex;align-items:center;justify-content:space-between;gap:10px;padding:16px 18px 10px;font:700 15px/1.2 system-ui,sans-serif}' +
        ':where(.fx-x){border:0;background:transparent;color:inherit;opacity:.6;padding:6px;cursor:pointer;display:flex}' +
        ':where(.fx-modal-body){padding:4px 18px 18px;overflow-y:auto;flex:1}' +
        ':where(.fx-notice){display:flex;gap:8px;padding:10px 12px;margin:8px 0;border-radius:10px;font:500 12px/1.45 system-ui,sans-serif;opacity:.85;background:var(--fx-notice-bg,rgba(120,120,120,.14))}' +
        ':where(.fx-btn){border:0;border-radius:10px;padding:10px 16px;font:700 13px/1 system-ui,sans-serif;cursor:pointer;background:var(--fx-btn-bg,rgba(128,128,128,.2));color:inherit}' +
        ':where(.fx-btn-primary){background:var(--fx-accent,#4da3ff);color:var(--fx-accent-fg,#08131f)}' +
        ':where(.fx-emptystate){padding:26px 10px;text-align:center;opacity:.55;font:600 13px/1.4 system-ui,sans-serif}' +
        ':where(.fx-ptr){position:fixed;top:calc(10px + var(--fx-safe-top,0px));left:50%;transform:translateX(-50%);z-index:400;opacity:0;pointer-events:none;color:var(--fx-accent,#4da3ff);display:flex}' +
        ':where([data-fx-switch]){display:flex;align-items:center;flex:none}' +
        ':where(.fx-switch){position:relative;display:inline-flex;flex:none}' +
        ':where(.fx-switch input){position:absolute;opacity:0;inset:0;margin:0;cursor:pointer}' +
        ':where(.fx-swtrack){display:block;width:44px;height:26px;border-radius:13px;background:var(--fx-sw-off,rgba(128,128,128,.4));position:relative;transition:background .15s ease}' +
        ':where(.fx-swknob){position:absolute;top:3px;inset-inline-start:3px;width:20px;height:20px;border-radius:50%;background:#fff;transition:transform .15s ease}' +
        ':where(.fx-switch input:checked) .fx-swtrack{background:var(--fx-accent,#4da3ff)}' +
        ':where(.fx-switch input:checked) .fx-swknob{transform:translateX(18px)}' +
        'html[dir=rtl] .fx-switch input:checked .fx-swknob{transform:translateX(-18px)}' +
        ':where(.fx-langbtn){position:relative}' +
        ':where(.fx-langcur)::after{content:"\\2713";margin-inline-start:auto;font-weight:900;padding-inline-end:56px}' +
        '.fx-langbtn .fx-flag{position:absolute;inset-inline-end:10px;top:50%;width:42px;height:30px;transform:translateY(-50%);opacity:var(--fx-flag-op,.18);pointer-events:none;border-radius:3px}' +
        '.fx-flag-en{background-color:#012169;background-image:linear-gradient(0deg,transparent 39%,#C8102E 39% 61%,transparent 61%),linear-gradient(90deg,transparent 39%,#C8102E 39% 61%,transparent 61%),linear-gradient(0deg,transparent 36%,#fff 36% 64%,transparent 64%),linear-gradient(90deg,transparent 36%,#fff 36% 64%,transparent 64%),linear-gradient(45deg,transparent 44%,#C8102E 44% 56%,transparent 56%),linear-gradient(-45deg,transparent 44%,#C8102E 44% 56%,transparent 56%),linear-gradient(45deg,transparent 41%,#fff 41% 59%,transparent 59%),linear-gradient(-45deg,transparent 41%,#fff 41% 59%,transparent 59%)}' +
        '.fx-flag-fr{background-image:linear-gradient(90deg,#002395 0 33.3%,#fff 33.3% 66.7%,#ED2939 66.7% 100%)}' +
        '.fx-flag-de{background-image:linear-gradient(180deg,#000 0 33.3%,#DD0000 33.3% 66.7%,#FFCE00 66.7% 100%)}' +
        '.fx-flag-pl{background-image:linear-gradient(180deg,#fff 0 50%,#DC143C 50% 100%)}' +
        '.fx-flag-it{background-image:linear-gradient(90deg,#009246 0 33.3%,#fff 33.3% 66.7%,#CE2B37 66.7% 100%)}' +
        '.fx-flag-es{background-image:linear-gradient(180deg,#AA151B 0 25%,#F1BF00 25% 75%,#AA151B 75% 100%)}' +
        '.fx-flag-pt-br{background-color:#009C3B;background-image:radial-gradient(circle at 50% 50%,#002776 0 21%,#FEDF00 21% 31%,transparent 31%)}' +
        '.fx-flag-tr{background-color:#E30A17;background-image:radial-gradient(circle at 77% 45%,#fff 0 7%,transparent 7%),radial-gradient(circle at 61% 50%,#E30A17 0 25%,transparent 25%),radial-gradient(circle at 54% 50%,#fff 0 31%,transparent 31%)}' +
        '.fx-flag-id{background-image:linear-gradient(180deg,#CE1126 0 50%,#fff 50% 100%)}' +
        '.fx-flag-ru{background-image:linear-gradient(180deg,#fff 0 33.3%,#0039A6 33.3% 66.7%,#D52B1E 66.7% 100%)}' +
        '.fx-flag-uk{background-image:linear-gradient(180deg,#005BBB 0 50%,#FFD500 50% 100%)}' +
        '.fx-flag-zh-cn{background-color:#DE2910;background-image:radial-gradient(circle at 25% 45%,#FFDE00 0 12%,transparent 12%),radial-gradient(circle at 44% 25%,#FFDE00 0 4.5%,transparent 4.5%),radial-gradient(circle at 53% 37%,#FFDE00 0 4.5%,transparent 4.5%),radial-gradient(circle at 53% 55%,#FFDE00 0 4.5%,transparent 4.5%),radial-gradient(circle at 44% 68%,#FFDE00 0 4.5%,transparent 4.5%)}' +
        '.fx-flag-ja{background-color:#fff;background-image:radial-gradient(circle at 50% 50%,#BC002D 0 28%,transparent 28%)}' +
        '.fx-flag-ar{background-color:#006C35;overflow:hidden}' +
        '.fx-flag-ar::before{content:\'\u0644\u0627 \u0625\u0644\u0647 \u0625\u0644\u0627 \u0627\u0644\u0644\u0647 \u0645\u062d\u0645\u062f \u0631\u0633\u0648\u0644 \u0627\u0644\u0644\u0647\';display:block;width:100%;padding-top:18%;font:700 5.2px/1 \'Noto Naskh Arabic\',\'Noto Sans Arabic\',\'DejaVu Sans\',system-ui,sans-serif;color:#FFFFFF;text-align:center;white-space:nowrap;overflow:hidden}' +
        '.fx-flag-ar::after{content:\'\';display:block;width:62%;height:2px;background:#FFFFFF;margin:14% auto 0}';
      document.head.appendChild(st);
    }
  }

  function toast(msg, type) {
    ensureChrome();
    var tEl = el('div', 'fx-toast ' + (type || 'info'), null, esc0(msg));
    toastWrap.appendChild(tEl);
    requestAnimationFrame(function () { tEl.classList.add('show'); });
    setTimeout(function () {
      tEl.classList.remove('show');
      setTimeout(function () { tEl.remove(); }, 250);
    }, 2200);
  }

  function esc0(s) {
    var d = document.createElement('span');
    d.textContent = String(s);
    return d.innerHTML;
  }

  var loadingEl = null, loadingTxt = null;

  function ensureLoading() {
    ensureChrome();
    if (!loadingEl) {
      loadingEl = el('div', null, { id: 'fx-loading' });
      var card = el('div', 'fx-loadcard', null,
        '<div class="fx-spin"></div><div class="fx-loadtxt" id="fx-loading-txt"></div>');
      loadingEl.appendChild(card);
      document.body.appendChild(loadingEl);
      loadingTxt = loadingEl.querySelector('#fx-loading-txt');
      var skin = activeSkin();
      if (skin && skin.buildLoading) skin.buildLoading(card);
    }
  }
  function restartLoadingAnims() {
    if (!loadingEl || !loadingEl.classList.contains('open')) return;
    loadingEl.classList.add('fx-reset');
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        loadingEl.classList.remove('fx-reset');
      });
    });
  }
  function showLoading(txt) {
    ensureLoading();
    loadingTxt.textContent = txt || t('loading_default');
    loadingEl.classList.add('open');
    restartLoadingAnims();
    var skin = activeSkin();
    if (skin && skin.onLoadingOpen) skin.onLoadingOpen(loadingEl);
    try { document.dispatchEvent(new CustomEvent('fx-loading-open')); } catch (e) {}
  }
  function updateLoading(txt) { if (loadingTxt) loadingTxt.textContent = txt || ''; }
  function hideLoading() {
    if (loadingEl) loadingEl.classList.remove('open');
    var skin = activeSkin();
    if (skin && skin.onLoadingClose) skin.onLoadingClose(loadingEl);
    try { document.dispatchEvent(new CustomEvent('fx-loading-close')); } catch (e) {}
  }

  // ── activity log ──

  function log(msg, type) {
    var row = { ts: new Date().toLocaleTimeString(), msg: msg, type: type || 'info' };
    logs.push(row);
    if (logs.length > 300) logs.shift();
    $all('[data-fx-log]').forEach(function (box) {
      box.appendChild(el('div', 'fx-logline ' + row.type, null,
        '<span class="fx-logts">' + row.ts + '</span><span class="fx-logmsg">' + esc0(row.msg) + '</span>'));
      box.scrollTop = box.scrollHeight;
    });
    hooks.log.forEach(function (fn) { fn(row); });
  }
  function logAction(msg, type) { log(msg, type || 'ok'); }

  // ── state loading and render ──

  async function loadPrefs() {
    try {
      var r = await getPrefs();
      state.prefs = r.prefs;
      state.categories = r.categories;
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
  }

  function counts() {
    var p = state.prefs || {}, c = state.categories || {};
    var groups = {
      tweaks: ['kernel_tweaks', 'system_props', 'ram_optimizer', 'multitask_enabled', 'blur_disable', 'log_killing', 'kill_tracking'],
      doze: ['custom_app_doze', 'deep_doze', 'battery_saver', 'screen_off_opt'],
      gms: ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games']
    };
    var res = { tweaks: 0, doze: 0, gms: 0, total: 0 };
    groups.tweaks.forEach(function (k) { if (p[k]) res.tweaks++; });
    groups.doze.forEach(function (k) { if (p[k]) res.doze++; });
    groups.gms.forEach(function (k) { if (c[k]) res.gms++; });
    res.total = res.tweaks + res.doze + res.gms;
    return res;
  }

  var PILL_KEYS = {
    tweaks: [['kernel_tweaks', 'pill_kernel'], ['system_props', 'pill_props'], ['ram_optimizer', 'pill_ram'],
             ['multitask_enabled', 'pill_multitask'], ['blur_disable', 'pill_blur'], ['log_killing', 'pill_logs'], ['kill_tracking', 'pill_tracking']],
    doze: [['deep_doze', 'pill_deep_doze'], ['custom_app_doze', 'pill_app_doze'],
           ['battery_saver', 'pill_batt_saver'], ['screen_off_opt', 'pill_screen_off']],
    gms: [['telemetry', 'pill_telemetry'], ['background', 'pill_background'], ['location', 'pill_location'],
          ['connectivity', 'pill_connectivity'], ['cloud', 'pill_cloud'], ['payments', 'pill_payments'],
          ['wearables', 'pill_wearables'], ['games', 'pill_games']]
  };

  function render() {
    var p = state.prefs || {}, c = state.categories || {};
    var cn = counts();

    document.documentElement.style.setProperty('--fx-kpi', cn.total);
    document.documentElement.style.setProperty('--fx-kpi-pct', (cn.total / 19 * 100).toFixed(1) + '%');

    $all('[data-fx-toggle]').forEach(function (row) {
      var key = row.getAttribute('data-fx-toggle');
      var input = row.querySelector('input');
      if (input) { input.checked = !!p[key]; input.setAttribute('aria-label', tkey(key)); }
      row.classList.toggle('fx-on', !!p[key]);
    });
    $all('[data-fx-cat]').forEach(function (row) {
      var key = row.getAttribute('data-fx-cat');
      var input = row.querySelector('input');
      if (input) { input.checked = !!c[key]; input.setAttribute('aria-label', tkey(key)); }
      row.classList.toggle('fx-on', !!c[key]);
    });

    $all('[data-fx-levelgroup]').forEach(function (group) {
      var key = group.getAttribute('data-fx-levelgroup');
      var cur = p[key];
      group.querySelectorAll('[data-fx-level]').forEach(function (btn) {
        var on = btn.getAttribute('data-fx-level') === cur;
        btn.classList.toggle('fx-lvl-on', on);
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
      });
    });

    $all('[data-fx-extra]').forEach(function (box) {
      var parent = box.getAttribute('data-fx-extra');
      box.classList.toggle('fx-open', !!p[parent]);
      box.style.maxHeight = p[parent] ? 'none' : '0';
    });

    $all('[data-fx-kpi]').forEach(function (n) { n.textContent = cn.total; });
    $all('[data-fx-count]').forEach(function (n) {
      var g = n.getAttribute('data-fx-count');
      n.textContent = tf('status_count', cn[g], g === 'tweaks' ? 7 : g === 'doze' ? 4 : 8);
    });
    $all('[data-fx-ratio]').forEach(function (n) {
      var g = n.getAttribute('data-fx-ratio');
      n.textContent = cn[g] + '/' + (g === 'total' ? 19 : g === 'tweaks' ? 7 : g === 'doze' ? 4 : 8);
    });
    $all('[data-fx-pills]').forEach(function (n) {
      var g = n.getAttribute('data-fx-pills');
      var src = g === 'gms' ? c : p;
      n.innerHTML = PILL_KEYS[g].map(function (item) {
        return '<span class="fx-pill' + (src[item[0]] ? ' fx-pill-on' : '') + '">' + esc0(t(item[1])) + '</span>';
      }).join('');
    });

    updatePickerCounts();
    hooks.render.forEach(function (fn) { fn(state); });
  }

  function updatePickerCounts() {
    var map = { wl: wlPkgs, ramwl: ramwlPkgs, cad: cadPkgs };
    $all('[data-fx-picker-count]').forEach(function (n) {
      var list = map[n.getAttribute('data-fx-picker-count')];
      if (list) n.textContent = list.length;
    });
  }

  // ── feature actions (faithful port of original togglePref logic) ──

  function fmtKey(k) {
    return k.replace(/_/g, ' ').replace(/\b\w/g, function (c) { return c.toUpperCase(); });
  }

  async function togglePref(key) {
    if (busy) return;
    var current = state.prefs[key] || 0;
    var nv = current ? 0 : 1;
    busy = true;
    showLoading((nv ? t('loading_enabling') : t('loading_disabling')) + ' ' +
      (key === 'multitask_enabled' ? t('multitask_title') : fmtKey(key)) + '...');
    try {
      var res = await setPref(key, nv);
      if (res.status !== 'ok') { toast(res.message || t('toast_error'), 'err'); hideLoading(); busy = false; return; }

      if (key === 'kernel_tweaks') {
        if (nv) {
          updateLoading(t('loading_applying_kernel'));
          var r = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_kernel 2>/dev/null');
          if (r.status === 'ok') logAction(tf('log_kernel_applied', r.applied, r.failed, r.skipped || 0), r.failed > 0 ? 'warn' : 'ok');
        } else {
          updateLoading(t('loading_reverting_kernel'));
          var r2 = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_kernel 2>/dev/null');
          if (r2.status === 'ok') logAction(tf('log_kernel_restored', r2.restored), 'ok');
        }
      } else if (key === 'blur_disable') {
        updateLoading(t('loading_applying_blur'));
        var rb = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_blur 2>/dev/null');
        if (rb.status === 'ok') {
          logAction(tf('log_blur_state', t(rb.blur === 'enabled' ? 'word_enabled' : 'word_disabled')), 'ok');
          if (rb.message) log(t('log_reboot_effect'), 'warn');
        }
      } else if (key === 'log_killing') {
        if (nv) {
          updateLoading(t('loading_killing_logs'));
          var rl = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_logs 2>/dev/null');
          if (rl.status === 'ok') logAction(tf('log_killed_logs', rl.killed), 'ok');
        } else {
          updateLoading(t('loading_reverting_logs'));
          await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_logs 2>/dev/null');
          logAction(t('log_logs_reverted'), 'ok');
        }
        log(t('log_reboot_effect'), 'warn');
      } else if (key === 'kill_tracking') {
        if (nv) {
          updateLoading(t('loading_applying_tracking'));
          var rt = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_tracking 2>/dev/null');
          if (rt.status === 'ok') logAction(t('log_tracking_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_tracking'));
          var rt2 = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_tracking 2>/dev/null');
          if (rt2.status === 'ok') logAction(t('log_tracking_reverted'), 'ok');
        }
      } else if (key === 'system_props') {
        updateLoading(nv ? t('loading_applying_sysprops') : t('loading_disabling_sysprops'));
        var rsp = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_sysprops 2>/dev/null');
        if (rsp.status === 'ok') logAction(t(nv ? 'log_sysprops_enabled' : 'log_sysprops_disabled'), 'ok');
        else logAction(tf('log_sysprops_failed', rsp.message || ''), 'err');
        log(t('log_reboot_effect'), 'warn');
      } else if (key === 'screen_off_opt') {
        if (nv) {
          updateLoading(t('loading_applying_soo'));
          await run('sh ' + MODDIR + '/scripts/frosty.sh apply_soo 2>&1');
          logAction(t('log_soo_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_soo'));
          await run('sh ' + MODDIR + '/scripts/frosty.sh revert_soo 2>&1');
          logAction(t('log_soo_reverted'), 'ok');
        }
      } else if (key === 'deep_doze') {
        if (nv) {
          updateLoading(t('loading_applying_deep_doze'));
          await run('sh ' + MODDIR + '/scripts/deep_doze.sh freeze 2>&1');
          logAction(t('log_deep_doze_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_deep_doze'));
          await run('sh ' + MODDIR + '/scripts/deep_doze.sh stock 2>&1');
          logAction(t('log_deep_doze_reverted'), 'ok');
        }
      } else if (key === 'deep_doze_always') {
        logAction(tf('log_deep_doze_always', t(nv ? 'word_enabled' : 'word_disabled')), 'ok');
        if (state.prefs.deep_doze) {
          updateLoading(t('loading_reapplying_deep'));
          await run('sh ' + MODDIR + '/scripts/deep_doze.sh freeze 2>&1');
        }
      } else if (key === 'ram_optimizer') {
        if (nv) {
          updateLoading(t('loading_applying_ram'));
          await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_ram 2>/dev/null');
          logAction(t('log_ram_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_ram'));
          await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_ram 2>/dev/null');
          logAction(t('log_ram_reverted'), 'ok');
        }
      } else if (key === 'multitask_enabled') {
        if (nv) {
          updateLoading(t('loading_applying_mt'));
          var tier = state.prefs.multitask_profile || 'balanced';
          var rmt = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_multitask ' + tier + ' 2>/dev/null');
          if (rmt.status === 'ok') logAction(tf('log_mt_enabled', tier), 'ok');
          else logAction(t('toast_error'), 'err');
        } else {
          updateLoading(t('loading_reverting_mt'));
          await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_multitask 2>/dev/null');
          logAction(t('log_mt_reverted'), 'ok');
        }
      } else if (key === 'custom_app_doze') {
        if (nv) {
          updateLoading(t('loading_applying_cad'));
          await run('sh ' + MODDIR + '/scripts/app_doze.sh apply 2>&1');
          logAction(t('log_cad_applied'), 'ok');
          var cadReboot = await run('[ -f "' + MODDIR + '/tmp/cad_needs_reboot" ] && echo "1" || echo "0"');
          if (cadReboot.trim() === '1') log(t('log_reboot_effect'), 'warn');
        } else {
          updateLoading(t('loading_reverting_cad'));
          await run('sh ' + MODDIR + '/scripts/app_doze.sh revert 2>&1');
          logAction(t('log_cad_reverted'), 'ok');
          log(t('log_reboot_effect'), 'warn');
        }
      } else if (key === 'battery_saver') {
        if (nv) {
          updateLoading(t('loading_applying_bss'));
          await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_bss 2>/dev/null');
          logAction(t('log_bss_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_bss'));
          await runJSON('sh ' + MODDIR + '/scripts/frosty.sh revert_bss 2>/dev/null');
          logAction(t('log_bss_reverted'), 'ok');
        }
      }

      toast(tkey(key) + ': ' + (nv ? t('toast_on') : t('toast_off')), 'ok');
      state.prefs[key] = nv;
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
      await loadPrefs();
    }
    hideLoading();
    busy = false;
  }

  async function toggleCategory(cat) {
    if (busy) return;
    var current = state.categories[cat] || 0;
    var nv = current ? 0 : 1;
    busy = true;
    showLoading((nv ? t('loading_freezing') : t('loading_unfreezing')) + ' ' + fmtKey(cat) + '...');
    try {
      var res = await setPref(cat, nv);
      if (res.status !== 'ok') { toast(res.message || t('toast_error'), 'err'); hideLoading(); busy = false; return; }
      if (nv) {
        var fr = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh freeze_category \'' + esc(cat) + '\' 2>/dev/null');
        if (fr.status === 'ok') {
          logAction(tf('log_cat_frozen', tkey(cat), fr.disabled, fr.failed), fr.failed > 0 ? 'warn' : 'ok');
          toast(tkey(cat) + ' ' + t('toast_cat_frozen'), 'ok');
        } else {
          await setPref(cat, current);
          toast(t('toast_error'), 'err');
          hideLoading(); busy = false; return;
        }
      } else {
        var uf = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh unfreeze_category \'' + esc(cat) + '\' 2>/dev/null');
        if (uf.status === 'ok') {
          logAction(tf('log_cat_restored', tkey(cat), uf.enabled, uf.failed), uf.failed > 0 ? 'warn' : 'ok');
          toast(tkey(cat) + ' ' + t('toast_cat_restored'), 'ok');
        } else {
          await setPref(cat, current);
          toast(t('toast_error'), 'err');
          hideLoading(); busy = false; return;
        }
      }
      state.categories[cat] = nv;
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      await loadPrefs();
    }
    hideLoading();
    busy = false;
  }

  async function toggleAllCategories(targetOn) {
    if (busy) return;
    var cats = Object.keys(CAT_MAP);
    var c = state.categories || {};
    var pending = cats.filter(function (cat) { return !!c[cat] !== targetOn; });
    if (pending.length === 0) {
      toast(t(targetOn ? 'toast_cats_already_on' : 'toast_cats_already_off'), 'info');
      return;
    }
    busy = true;
    showLoading(t(targetOn ? 'loading_enabling_all_cats' : 'loading_disabling_all_cats'));
    var okCount = 0, failCount = 0;
    for (var i = 0; i < pending.length; i++) {
      var cat = pending[i];
      updateLoading(tf('loading_cat_progress', tkey(cat), i + 1, pending.length));
      try {
        var res = await setPref(cat, targetOn ? 1 : 0);
        if (res.status !== 'ok') { failCount++; continue; }
        var r = targetOn
          ? await runJSON('sh ' + MODDIR + '/scripts/frosty.sh freeze_category \'' + esc(cat) + '\' 2>/dev/null')
          : await runJSON('sh ' + MODDIR + '/scripts/frosty.sh unfreeze_category \'' + esc(cat) + '\' 2>/dev/null');
        if (r.status === 'ok') { state.categories[cat] = targetOn ? 1 : 0; okCount++; }
        else failCount++;
      } catch (e) { failCount++; }
    }
    logAction(tf(targetOn ? 'log_cats_all_enabled' : 'log_cats_all_disabled', okCount, failCount), failCount > 0 ? 'warn' : 'ok');
    toast(tf(targetOn ? 'toast_cats_enabled_n' : 'toast_cats_disabled_n', okCount), failCount > 0 ? 'warn' : 'ok');
    render();
    hideLoading();
    busy = false;
  }

  async function setLevel(key, level, opts) {
    if (busy) return;
    if (state.prefs[key] === level) return;
    busy = true;
    showLoading(t('loading_setting_level'));
    try {
      var res = await setPref(key, level);
      if (res.status === 'ok') {
        if (opts && opts.logKey) logAction(tf(opts.logKey, level), 'info');
        if (opts && opts.reapplyPref && state.prefs[opts.reapplyPref]) {
          updateLoading(t(opts.reapplyLoading || 'loading_reapplying'));
          await run(opts.reapplyCmd);
          logAction(t(opts.reapplyLog || 'log_reapply_start'), 'ok');
        }
        state.prefs[key] = level;
        render();
      }
    } catch (e) { toast(t('toast_error'), 'err'); }
    hideLoading();
    busy = false;
  }

  function setDozeLevel(level) {
    return setLevel('deep_doze_level', level, {
      logKey: 'log_deep_doze_level',
      reapplyPref: 'deep_doze',
      reapplyLoading: 'loading_reapplying_deep', reapplyLog: 'log_deep_doze_reapplied',
      reapplyCmd: 'sh ' + MODDIR + '/scripts/deep_doze.sh freeze 2>&1'
    });
  }
  function setRamLevel(level) {
    return setLevel('ram_optimizer_level', level, {
      logKey: 'log_ram_opt_level',
      reapplyPref: 'ram_optimizer',
      reapplyLoading: 'loading_reapplying_ram', reapplyLog: 'log_ram_opt_reapplied',
      reapplyCmd: 'sh ' + MODDIR + '/scripts/frosty.sh apply_ram 2>/dev/null'
    });
  }
  function setMultitaskProfile(tier) {
    return setLevel('multitask_profile', tier, {
      logKey: 'log_multitask_profile',
      reapplyPref: 'multitask_enabled',
      reapplyLoading: 'loading_applying_mt', reapplyLog: 'log_mt_reapplied',
      reapplyCmd: 'sh ' + MODDIR + '/scripts/frosty.sh apply_multitask ' + tier + ' 2>/dev/null'
    });
  }

  function yieldFrame() {
    return new Promise(function (r) { requestAnimationFrame(function () { setTimeout(r, 0); }); });
  }

  async function applyFreeze() {
    if (busy) return;
    busy = true;
    var rp = state.prefs || {};

    var _steps = ['loading_applying_kernel', 'loading_applying_ram', 'loading_applying_mt',
      'loading_applying_sysprops', 'loading_applying_blur', 'loading_killing_logs',
      'loading_applying_tracking', 'loading_freezing_services', 'loading_applying_cad',
      'loading_applying_deep_doze', 'loading_applying_bss', 'loading_applying_soo'];
    var _total = _steps.length, _cur = 0;
    function stepLoad(key) {
      _cur++;
      updateLoading('[' + _cur + '/' + _total + '] ' + t(key));
      return yieldFrame();
    }
    async function forceOn(key) {
      if (rp[key] !== 1) { await setPref(key, 1); rp[key] = 1; }
    }

    showLoading(t('loading_enabling_all'));
    logAction(t('log_freeze_all'), 'info');
    try {
      await yieldFrame();

      await forceOn('kernel_tweaks');
      await stepLoad('loading_applying_kernel');
      var rk = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_kernel 2>/dev/null');
      if (rk.status === 'ok') logAction(tf('log_kernel_applied', rk.applied, rk.failed, rk.skipped || 0), rk.failed > 0 ? 'warn' : 'ok');

      await forceOn('ram_optimizer');
      await stepLoad('loading_applying_ram');
      await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_ram 2>/dev/null');
      logAction(t('log_ram_applied'), 'ok');

      await forceOn('multitask_enabled');
      await stepLoad('loading_applying_mt');
      var mtTier = rp.multitask_profile || 'balanced';
      await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_multitask ' + mtTier + ' 2>/dev/null');
      logAction(tf('log_mt_enabled', mtTier), 'ok');

      await forceOn('system_props');
      await stepLoad('loading_applying_sysprops');
      var rsp = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_sysprops 2>/dev/null');
      if (rsp.status === 'ok') logAction(t('log_sysprops_enabled'), 'ok');
      else logAction(tf('log_sysprops_failed', rsp.message || ''), 'err');

      await forceOn('blur_disable');
      await stepLoad('loading_applying_blur');
      var rb = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_blur 2>/dev/null');
      if (rb.status === 'ok') logAction(tf('log_blur_state', t('word_disabled')), 'ok');

      await forceOn('log_killing');
      await stepLoad('loading_killing_logs');
      var rl = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_logs 2>/dev/null');
      if (rl.status === 'ok') logAction(tf('log_killed_logs', rl.killed), 'ok');

      await forceOn('kill_tracking');
      await stepLoad('loading_applying_tracking');
      var rtr = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_tracking 2>/dev/null');
      if (rtr.status === 'ok') logAction(t('log_tracking_applied'), 'ok');

      await stepLoad('loading_freezing_services');
      var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh freeze 2>&1');
      appendLog('Freeze applied via WebUI');
      var m = raw.match(/Disabled:\s*(\d+)[\s\S]*?Re-enabled:\s*(\d+)[\s\S]*?Failed:\s*(\d+)/);
      logAction(tf('log_gms_frozen', m ? parseInt(m[1]) : 0, m ? parseInt(m[2]) : 0, m ? parseInt(m[3]) : 0), (m && parseInt(m[3]) > 0) ? 'warn' : 'ok');

      await forceOn('custom_app_doze');
      await stepLoad('loading_applying_cad');
      await run('sh ' + MODDIR + '/scripts/app_doze.sh apply 2>&1');
      logAction(t('log_cad_applied'), 'ok');
      var cadReboot = await run('[ -f "' + MODDIR + '/tmp/cad_needs_reboot" ] && echo "1" || echo "0"');
      if (cadReboot.trim() === '1') log(t('log_reboot_effect'), 'warn');

      await forceOn('deep_doze');
      await stepLoad('loading_applying_deep_doze');
      await run('sh ' + MODDIR + '/scripts/deep_doze.sh freeze 2>&1');
      logAction(t('log_deep_doze_applied'), 'ok');

      await forceOn('battery_saver');
      await stepLoad('loading_applying_bss');
      await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_bss 2>/dev/null');
      logAction(t('log_bss_applied'), 'ok');

      await forceOn('screen_off_opt');
      await stepLoad('loading_applying_soo');
      await run('sh ' + MODDIR + '/scripts/frosty.sh apply_soo 2>&1');
      logAction(t('log_soo_applied'), 'ok');

      await run(': > "' + MODDIR + '/tmp/applied"');
      toast(t('toast_frozen'), 'ok');
      log(t('log_reboot_effect'), 'warn');
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
    }
    hideLoading();
    busy = false;
  }

  function revertTable() {
    var sc = MODDIR + '/scripts/';
    return [
      ['screen_off_opt',    'sh ' + sc + 'frosty.sh revert_soo 2>&1'],
      ['deep_doze',         'sh ' + sc + 'deep_doze.sh stock 2>&1'],
      ['battery_saver',     'sh ' + sc + 'frosty.sh revert_bss 2>/dev/null'],
      ['custom_app_doze',   'sh ' + sc + 'app_doze.sh revert 2>&1'],
      ['kill_tracking',     'sh ' + sc + 'frosty.sh revert_tracking 2>/dev/null'],
      ['log_killing',       'sh ' + sc + 'frosty.sh revert_logs 2>/dev/null'],
      ['blur_disable',      'sh ' + sc + 'frosty.sh apply_blur 2>/dev/null'],
      ['system_props',      'sh ' + sc + 'frosty.sh apply_sysprops 2>/dev/null'],
      ['multitask_enabled', 'sh ' + sc + 'frosty.sh revert_multitask 2>/dev/null'],
      ['ram_optimizer',     'sh ' + sc + 'frosty.sh revert_ram 2>/dev/null'],
      ['kernel_tweaks',     'sh ' + sc + 'frosty.sh revert_kernel 2>/dev/null']
    ];
  }

  async function revertDisabled(before) {
    var now = state.prefs || {}, nc = state.categories || {};
    var cmds = revertTable().filter(function (e) { return before.prefs[e[0]] && !now[e[0]]; });
    for (var i = 0; i < cmds.length; i++) await run(cmds[i][1]);
    for (var ck in CAT_MAP) {
      if (before.cats[ck] && !nc[ck]) {
        await run('sh ' + MODDIR + '/scripts/frosty.sh unfreeze_category ' + ck + ' 2>&1');
      }
    }
  }

  async function applyStock() {
    if (busy) return;
    busy = true;
    showLoading(t('loading_reverting_all'));
    logAction(t('log_reverting_all'), 'info');
    var rp = state.prefs || {}, rc = state.categories || {};
    var scripts = MODDIR + '/scripts/';
    var reverts = revertTable().filter(function (e) { return rp[e[0]]; });
    var j = 0, stockDone = false;
    try {
      await yieldFrame();
      for (var i = 0; i < reverts.length; i++) await setPref(reverts[i][0], 0);
      for (var ck in CAT_MAP) if (rc[ck]) await setPref(ck, 0);
      for (j = 0; j < reverts.length; j++) await run(reverts[j][1]);
      var raw = await run('sh ' + scripts + 'frosty.sh stock 2>&1');
      stockDone = true;
      appendLog('Stock reverted via WebUI');
      var m = raw.match(/Re-enabled:\s*(\d+)[\s\S]*?Failed:\s*(\d+)/);
      logAction(tf('log_gms_restored', m ? parseInt(m[1]) : 0, m ? parseInt(m[2]) : 0), (m && parseInt(m[2]) > 0) ? 'warn' : 'ok');
      toast(t('toast_stocked'), 'ok');
      log(t('log_reboot_effect'), 'warn');
      await loadPrefs();
    } catch (e) {
      for (var k = j; k < reverts.length; k++) await setPref(reverts[k][0], 1);
      if (!stockDone) for (var ck2 in CAT_MAP) if (rc[ck2]) await setPref(ck2, 1);
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
      await loadPrefs();
    }
    hideLoading();
    busy = false;
  }

  async function reapply() {
    if (busy) return;
    var rp = state.prefs || {}, rc = state.categories || {};
    var hasAnyCat = Object.keys(rc).some(function (k) { return rc[k] === 1; });
    var hasAny = counts().total > 0;
    if (!hasAny) { toast(t('toast_nothing_to_apply'), 'info'); return; }
    busy = true;

    var _steps = [];
    if (rp.kernel_tweaks) _steps.push('loading_applying_kernel');
    if (rp.ram_optimizer) _steps.push('loading_applying_ram');
    if (rp.multitask_enabled) _steps.push('loading_applying_mt');
    if (rp.system_props) _steps.push('loading_applying_sysprops');
    if (rp.blur_disable) _steps.push('loading_applying_blur');
    if (rp.log_killing) _steps.push('loading_killing_logs');
    if (rp.kill_tracking) _steps.push('loading_applying_tracking');
    if (hasAnyCat) _steps.push('loading_freezing_services');
    if (rp.custom_app_doze) _steps.push('loading_applying_cad');
    if (rp.deep_doze) _steps.push('loading_applying_deep_doze');
    if (rp.battery_saver) _steps.push('loading_applying_bss');
    if (rp.screen_off_opt) _steps.push('loading_applying_soo');
    var _total = _steps.length, _cur = 0;

    function stepLoad(key) {
      _cur++;
      updateLoading('[' + _cur + '/' + _total + '] ' + t(key));
      return yieldFrame();
    }

    showLoading(t('loading_reapplying'));
    logAction(t('log_reapply_start'), 'info');
    try {
      if (rp.kernel_tweaks) {
        await stepLoad('loading_applying_kernel');
        var rk = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_kernel 2>/dev/null');
        if (rk.status === 'ok') logAction(tf('log_kernel_applied', rk.applied, rk.failed, rk.skipped || 0), rk.failed > 0 ? 'warn' : 'ok');
      }
      if (rp.ram_optimizer) {
        await stepLoad('loading_applying_ram');
        await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_ram 2>/dev/null');
        logAction(t('log_ram_applied'), 'ok');
      }
      if (rp.multitask_enabled) {
        await stepLoad('loading_applying_mt');
        await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_multitask ' + (rp.multitask_profile || 'balanced') + ' 2>/dev/null');
        logAction(tf('log_mt_enabled', rp.multitask_profile || 'balanced'), 'ok');
      }
      if (rp.system_props) {
        await stepLoad('loading_applying_sysprops');
        var rsp = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_sysprops 2>/dev/null');
        if (rsp.status === 'ok') logAction(t('log_sysprops_enabled'), 'ok');
        else logAction(tf('log_sysprops_failed', rsp.message || ''), 'err');
      }
      if (rp.blur_disable) {
        await stepLoad('loading_applying_blur');
        var rb = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_blur 2>/dev/null');
        if (rb.status === 'ok') logAction(tf('log_blur_state', t('word_disabled')), 'ok');
      }
      if (rp.log_killing) {
        await stepLoad('loading_killing_logs');
        var rl = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_logs 2>/dev/null');
        if (rl.status === 'ok') logAction(tf('log_killed_logs', rl.killed), 'ok');
      }
      if (rp.kill_tracking) {
        await stepLoad('loading_applying_tracking');
        var rtr = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh kill_tracking 2>/dev/null');
        if (rtr.status === 'ok') logAction(t('log_tracking_applied'), 'ok');
      }
      if (hasAnyCat) {
        await stepLoad('loading_freezing_services');
        var raw = await run('sh ' + MODDIR + '/scripts/frosty.sh freeze 2>&1');
        var m = raw.match(/Disabled:\s*(\d+)[\s\S]*?Re-enabled:\s*(\d+)[\s\S]*?Failed:\s*(\d+)/);
        logAction(tf('log_gms_frozen', m ? parseInt(m[1]) : 0, m ? parseInt(m[2]) : 0, m ? parseInt(m[3]) : 0), (m && parseInt(m[3]) > 0) ? 'warn' : 'ok');
      }
      if (rp.custom_app_doze) {
        await stepLoad('loading_applying_cad');
        await run('sh ' + MODDIR + '/scripts/app_doze.sh apply 2>&1');
        logAction(t('log_cad_applied'), 'ok');
        var cadReboot = await run('[ -f "' + MODDIR + '/tmp/cad_needs_reboot" ] && echo "1" || echo "0"');
        if (cadReboot.trim() === '1') log(t('log_reboot_effect'), 'warn');
      }
      if (rp.deep_doze) {
        await stepLoad('loading_applying_deep_doze');
        await run('sh ' + MODDIR + '/scripts/deep_doze.sh freeze 2>&1');
        logAction(t('log_deep_doze_applied'), 'ok');
      }
      if (rp.battery_saver) {
        await stepLoad('loading_applying_bss');
        await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_bss 2>/dev/null');
        logAction(t('log_bss_applied'), 'ok');
      }
      if (rp.screen_off_opt) {
        await stepLoad('loading_applying_soo');
        await run('sh ' + MODDIR + '/scripts/frosty.sh apply_soo 2>&1');
        logAction(t('log_soo_applied'), 'ok');
      }
      await run(': > ' + MODDIR + '/tmp/applied');
      toast(t('toast_reapplied'), 'ok');
      log(t('log_reboot_effect'), 'warn');
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
    }
    hideLoading();
    busy = false;
  }

  // ── modal system with history ──

  function anyModalOpen() {
    return modalStack.length > 0;
  }

  function openModal(node, opts) {
    ensureChrome();
    opts = opts || {};
    if (!node.parentNode) { document.body.appendChild(node); applyStrings(); updatePickerCounts(); }
    node.classList.add('fx-open');
    modalStack.push(node);
    if (!opts.quiet) {
      try { history.pushState({ fxModal: true }, ''); historyPushCount++; } catch (e) {}
    }
  }

  function closeModal(node) {
    var i = modalStack.indexOf(node);
    if (i !== -1) modalStack.splice(i, 1);
    node.classList.remove('fx-open');
    if (node.dataset.fxDynamic === '1') {
      setTimeout(function () { node.remove(); }, 30);
    }
  }

  function closeTopModal() {
    if (!modalStack.length) return false;
    var top = modalStack[modalStack.length - 1];
    var closer = top.querySelector('[data-fx-modal-close]');
    if (closer && !top.dataset.fxDynamic) closer.click();
    else closeModal(top);
    return true;
  }

  function modalShell(id, titleKey, bodyNode, opts) {
    opts = opts || {};
    var wrap = el('div', 'fx-modal' + (opts.centered ? ' fx-centered' : ''), { id: id });
    var card = el('div', 'fx-modal-card', { role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': id + '-title' });
    var head = el('div', 'fx-modal-head', null,
      '<h3 id="' + id + '-title" data-i18n="' + titleKey + '">' + esc0(t(titleKey)) + '</h3>' +
      '<button class="fx-x" data-fx-modal-close data-i18n-aria="close" aria-label="' + esc0(t('close')) + '">' + svg(ICO.x, 16, true) + '</button>');
    card.appendChild(head);
    var body = el('div', 'fx-modal-body');
    if (bodyNode) body.appendChild(bodyNode);
    card.appendChild(body);
    wrap.appendChild(card);
    wrap.addEventListener('click', function (e) {
      if (e.target === wrap && !opts.locked) closeModal(wrap);
    });
    return wrap;
  }

  // ── app picker component (wl / ramwl / cad) ──

  var wlPkgs = [], ramwlPkgs = [], cadPkgs = [];
  var allApps = null;

  var CAD_BLOCKED = {
    android: 1, 'com.android.systemui': 1, 'com.android.phone': 1,
    'com.android.settings': 1, 'com.android.shell': 1,
    'com.android.bluetooth': 1, 'com.android.nfc': 1
  };

  function resolvePkgInfo(pkgs) {
    var infoMap = {};
    if (demo || typeof ksu === 'undefined' || typeof ksu.getPackagesInfo !== 'function') return infoMap;
    var CHUNK = 40;
    for (var c = 0; c < pkgs.length; c += CHUNK) {
      try {
        var infos = JSON.parse(ksu.getPackagesInfo(JSON.stringify(pkgs.slice(c, c + CHUNK))));
        for (var k = 0; k < infos.length; k++) {
          if (infos[k].appLabel) infoMap[infos[k].packageName] = infos[k].appLabel;
        }
      } catch (e) {}
    }
    return infoMap;
  }

  async function loadAllApps() {
    if (allApps) return allApps;
    var list = [];
    if (!demo && typeof ksu !== 'undefined' && typeof ksu.listPackages === 'function') {
      try {
        var userPkgs = JSON.parse(ksu.listPackages('user'));
        var sysPkgs = JSON.parse(ksu.listPackages('system'));
        var seen = {};
        function add(arr, sys) {
          for (var i = 0; i < arr.length; i++) {
            if (!seen[arr[i]]) { seen[arr[i]] = 1; list.push({ pkg: arr[i], system: sys }); }
          }
        }
        add(userPkgs, false);
        add(sysPkgs, true);
      } catch (e) { list = []; }
    }
    if (demo) {
      list = DEMO_PKGS.map(function (p, i) {
        return { pkg: p, system: i === 0 || p.indexOf('com.android.') === 0, label: null };
      });
    }
    if (!list.length) {
      try {
        var raw = await run('pm list packages 2>/dev/null | cut -d: -f2 | sort');
        list = raw.split('\n').filter(function (l) { return l.trim(); }).map(function (p) {
          return { pkg: p.trim(), system: false };
        });
      } catch (e2) { list = []; }
    }
    var infoMap = resolvePkgInfo(list.map(function (a) { return a.pkg; }));
    allApps = list.map(function (a) {
      return { pkg: a.pkg, label: infoMap[a.pkg] || a.pkg, system: a.system };
    }).filter(function (a) { return a.pkg; });
    allApps.sort(function (a, b) { return a.label.toLowerCase().localeCompare(b.label.toLowerCase()); });
    return allApps;
  }

  function makePicker(cfg) {
    var wrap = el('div', 'fx-modal', { id: 'fx-m-' + cfg.id, 'data-fx-dynamic': '0' });
    var card = el('div', 'fx-modal-card fx-picker-card');
    var head = el('div', 'fx-modal-head', null,
      '<h3 data-i18n="' + cfg.titleKey + '">' + esc0(t(cfg.titleKey)) + '</h3>' +
      '<button class="fx-x" data-fx-modal-close data-i18n-aria="close" aria-label="' + esc0(t('close')) + '">' + svg(ICO.x, 16, true) + '</button>');
    var body = el('div', 'fx-modal-body fx-picker');

    var notice = el('div', 'fx-notice', null, svg(ICO.info, 15) + '<span data-i18n="' + cfg.noticeKey + '">' + esc0(t(cfg.noticeKey)) + '</span>');
    var controls = el('div', 'fx-picker-controls');
    var search = el('input', 'fx-search', { type: 'text', placeholder: t('wl_search') });
    search.setAttribute('data-i18n-ph', cfg.searchKey || 'wl_search');
    controls.appendChild(search);
    if (cfg.sysToggle) {
      var sysLabel = el('label', 'fx-syscheck', null,
        '<input type="checkbox" class="fx-sysin"><span data-i18n="wl_system">' + esc0(t('wl_system')) + '</span>');
      controls.appendChild(sysLabel);
    }
    var listEl = el('div', 'fx-applist');
    body.appendChild(notice);
    body.appendChild(controls);
    body.appendChild(listEl);
    card.appendChild(head);
    card.appendChild(body);
    wrap.appendChild(card);

    var filtered = [], rendered = 0, searching = false, searchTimer = null;
    var selected = cfg.getSelected();
    var iconObserver = null;

    wrap.addEventListener('click', function (e) {
      if (e.target === wrap) { closeModal(wrap); }
      var row = e.target.closest ? e.target.closest('.fx-approw') : null;
      if (row && !row.classList.contains('fx-blocked')) {
        var pkg = row.dataset.pkg;
        var on = selected.indexOf(pkg) === -1;
        row.classList.toggle('fx-checked', on);
        row.setAttribute('aria-checked', on ? 'true' : 'false');
        cfg.toggle(pkg, on).then(function (ok) {
          if (ok) {
            var at = selected.indexOf(pkg);
            if (on && at === -1) selected.push(pkg);
            else if (!on && at !== -1) selected.splice(at, 1);
            updatePickerCounts();
          } else {
            row.classList.toggle('fx-checked', !on);
          }
        });
      }
    });

    wrap.addEventListener('keydown', function (e) {
      if ((e.key === 'Enter' || e.key === ' ') && e.target.classList && e.target.classList.contains('fx-approw')) {
        e.preventDefault();
        e.target.click();
      }
    });

    search.addEventListener('input', function () {
      if (searchTimer) clearTimeout(searchTimer);
      searchTimer = setTimeout(function () { applyFilter(); render(true); }, 150);
    });
    if (cfg.sysToggle) {
      wrap.querySelector('.fx-sysin').addEventListener('change', function () {
        applyFilter();
        render(true);
      });
    }

    function applyFilter() {
      var q = search.value.toLowerCase();
      var showSys = cfg.sysToggle ? wrap.querySelector('.fx-sysin').checked : false;
      var src = cfg.listScope === 'scan' ? scanCache : (allApps || []);
      filtered = src.filter(function (a) {
        if (cfg.listScope === 'scan') return !q || a.toLowerCase().indexOf(q) !== -1;
        if (!showSys && a.system) return false;
        if (q) return a.label.toLowerCase().indexOf(q) !== -1 || a.pkg.toLowerCase().indexOf(q) !== -1;
        return true;
      });
      if (cfg.listScope !== 'scan') {
        var checked = [], unchecked = [];
        filtered.forEach(function (a) {
          if (selected.indexOf(a.pkg) !== -1) checked.push(a);
          else unchecked.push(a);
        });
        filtered = checked.concat(unchecked);
      }
    }

    function monogram(pkg) {
      var parts = pkg.replace(/\./g, ' ').split(' ');
      var s = '';
      for (var i = 0; i < parts.length && s.length < 2; i++) {
        if (parts[i]) s += parts[i][0].toUpperCase();
      }
      return s || '?';
    }

    function render(reset) {
      if (reset) { rendered = 0; listEl.innerHTML = ''; listEl.scrollTop = 0; }
      if (!filtered.length) {
        listEl.innerHTML = '<div class="fx-emptystate">' + esc0(t(cfg.emptyKey || 'wl_empty')) + '</div>';
        return;
      }
      var end = Math.min(rendered + 40, filtered.length);
      var frag = document.createDocumentFragment();
      for (var i = rendered; i < end; i++) {
        var pkg, label, isSel, blocked = false, sys = false, known = null;
        if (cfg.listScope === 'scan') {
          pkg = filtered[i];
          known = (allApps || []).find(function (a) { return a.pkg === pkg; });
          label = known ? known.label : pkg;
          isSel = selected.indexOf(pkg) !== -1;
          blocked = !!CAD_BLOCKED[pkg];
        } else {
          pkg = filtered[i].pkg;
          label = filtered[i].label;
          sys = filtered[i].system;
          isSel = selected.indexOf(pkg) !== -1;
        }
        var useMono = cfg.listScope === 'scan' && !known;
        var row = el('div', 'fx-approw' + (isSel ? ' fx-checked' : '') + (blocked ? ' fx-blocked' : ''), { 'data-pkg': pkg, role: 'checkbox', 'aria-checked': isSel ? 'true' : 'false', tabindex: blocked ? '-1' : '0' },
          '<span class="fx-appico' + (useMono ? ' fx-mono' : '') + '" data-icon="' + esc0(pkg) + '">' + (useMono ? monogram(pkg) : '') + '</span>' +
          '<span class="fx-appinfo"><span class="fx-appname">' + esc0(label) + '</span>' +
          (label !== pkg ? '<span class="fx-apppkg">' + esc0(pkg) + '</span>' : '<span class="fx-apppkg">' + esc0(pkg) + '</span>') + '</span>' +
          (blocked
            ? '<span class="fx-appwarn" title="' + esc0(t('cad_warn_system')) + '" aria-label="' + esc0(t('cad_warn_system')) + '">' + svg(ICO.info, 14) + '</span>'
            : '<span class="fx-appchk">' + svg(ICO.check, 14, true) + '</span>'));
        frag.appendChild(row);
      }
      listEl.appendChild(frag);
      rendered = end;
      if (!demo && typeof ksu !== 'undefined') {
        var imgs = listEl.querySelectorAll('.fx-appico[data-icon]:not([data-obs]):not(.fx-mono)');
        if (!iconObserver) {
          iconObserver = new IntersectionObserver(function (entries) {
            for (var k = 0; k < entries.length; k++) {
              if (entries[k].isIntersecting) {
                var span = entries[k].target;
                var img = document.createElement('img');
                img.className = 'fx-appimg';
                img.decoding = 'async';
                img.src = 'ksu://icon/' + span.dataset.icon;
                img.onerror = function () { this.remove(); };
                span.textContent = '';
                span.appendChild(img);
                iconObserver.unobserve(span);
              }
            }
          }, { root: listEl, rootMargin: '500px 0px' });
        }
        for (var j = 0; j < imgs.length; j++) {
          imgs[j].setAttribute('data-obs', '1');
          iconObserver.observe(imgs[j]);
        }
      } else {
        var monos = listEl.querySelectorAll('.fx-appico:not([data-mon])');
        for (var m = 0; m < monos.length; m++) {
          monos[m].setAttribute('data-mon', '1');
          if (!monos[m].textContent) monos[m].textContent = monogram(monos[m].dataset.icon);
        }
      }
    }

    listEl.addEventListener('scroll', function () {
      if (listEl.scrollTop + listEl.clientHeight >= listEl.scrollHeight - 300) {
        if (rendered < filtered.length) render(false);
      }
    }, { passive: true });

    function open() {
      listEl.innerHTML = '<div class="fx-emptystate">' + esc0(t(cfg.loadingKey || 'wl_loading')) + '</div>';
      selected = cfg.getSelected();
      openModal(wrap);
      cfg.load().then(function () {
        applyFilter();
        render(true);
      });
    }

    wrap._open = open;
    return wrap;
  }

  function setInPlace(arr, items) {
    arr.length = 0;
    if (items) for (var i = 0; i < items.length; i++) arr.push(items[i]);
  }

  var scanCache = [];

  var pickers = {
    wl: makePicker({
      id: 'wl', titleKey: 'wl_title', noticeKey: 'wl_notice', sysToggle: true, listScope: 'all',
      loadingKey: 'wl_loading', emptyKey: 'wl_empty',
      getSelected: function () { return wlPkgs; },
      load: function () {
        var self = this;
        var jobs = [loadAllApps()];
        jobs.push(runJSON('sh ' + MODDIR + '/scripts/frosty.sh list_wl 2>/dev/null').then(function (r) {
          setInPlace(wlPkgs, r.packages);
        }).catch(function () { setInPlace(wlPkgs, []); }));
        return Promise.all(jobs);
      },
      toggle: function (pkg, on) {
        return runJSON('sh ' + MODDIR + '/scripts/frosty.sh ' + (on ? 'add_wl' : 'remove_wl') + ' \'' + esc(pkg) + '\' 2>/dev/null')
          .then(function (r) { return r.status === 'ok'; })
          .catch(function () { return false; });
      }
    }),
    ramwl: makePicker({
      id: 'ramwl', titleKey: 'ram_wl_title', noticeKey: 'ram_wl_notice', sysToggle: true, listScope: 'all',
      loadingKey: 'wl_loading', emptyKey: 'wl_empty',
      getSelected: function () { return ramwlPkgs; },
      load: function () {
        var jobs = [loadAllApps()];
        jobs.push(runJSON('sh ' + MODDIR + '/scripts/frosty.sh list_ram_wl 2>/dev/null').then(function (r) {
          setInPlace(ramwlPkgs, r.packages);
        }).catch(function () { setInPlace(ramwlPkgs, []); }));
        return Promise.all(jobs);
      },
      toggle: function (pkg, on) {
        return runJSON('sh ' + MODDIR + '/scripts/frosty.sh ' + (on ? 'add_ram_wl' : 'remove_ram_wl') + ' \'' + esc(pkg) + '\' 2>/dev/null')
          .then(function (r) { return r.status === 'ok'; })
          .catch(function () { return false; });
      }
    }),
    cad: makePicker({
      id: 'cad', titleKey: 'cad_title', noticeKey: 'cad_notice', sysToggle: false, listScope: 'scan',
      loadingKey: 'cad_loading', emptyKey: 'cad_empty',
      getSelected: function () { return cadPkgs; },
      load: function () {
        var jobs = [loadAllApps()];
        jobs.push(runJSON('sh ' + MODDIR + '/scripts/app_doze.sh list 2>/dev/null').then(function (r) {
          setInPlace(cadPkgs, r.packages);
        }).catch(function () { setInPlace(cadPkgs, []); }));
        jobs.push(run('sh ' + MODDIR + '/scripts/app_doze.sh scan 2>/dev/null').then(function (raw) {
          scanCache = raw ? raw.split('\n').filter(function (l) { return l.trim(); }) : [];
        }).catch(function () { scanCache = []; }));
        return Promise.all(jobs);
      },
      toggle: function (pkg, on) {
        return runJSON('sh ' + MODDIR + '/scripts/app_doze.sh ' + (on ? 'add' : 'remove') + ' \'' + esc(pkg) + '\' 2>/dev/null')
          .then(function (r) { return r.status === 'ok'; })
          .catch(function () { return false; });
      }
    })
  };

  function openPicker(name) {
    var p = pickers[name];
    if (p && p._open) p._open();
  }

  // ── BSS options modal ──

  function switchRow(nameKey, descKey, checked, id) {
    return el('div', 'fx-optrow', null,
      '<div class="fx-optinfo"><span class="fx-optname" data-i18n="' + nameKey + '">' + esc0(t(nameKey)) + '</span>' +
      '<span class="fx-optdesc" data-i18n="' + descKey + '">' + esc0(t(descKey)) + '</span></div>' +
      '<label class="fx-switch"><input type="checkbox" data-bss="' + id + '"' + (checked ? ' checked' : '') + '><span class="fx-swtrack"><span class="fx-swknob"></span></span></label>');
  }

  var BSS_FIELDS = [
    ['bss_opt_datasaver', 'bss_opt_datasaver_desc', 'bss_datasaver'],
    ['bss_opt_hotword', 'bss_opt_hotword_desc', 'bss_soundtrigger_disabled'],
    ['bss_opt_fullbackup', 'bss_opt_fullbackup_desc', 'bss_fullbackup_deferred'],
    ['bss_opt_keybackup', 'bss_opt_keybackup_desc', 'bss_keyvaluebackup_deferred'],
    ['bss_opt_force_standby', 'bss_opt_force_standby_desc', 'bss_force_standby'],
    ['bss_opt_force_bg', 'bss_opt_force_bg_desc', 'bss_force_bg_check'],
    ['bss_opt_sensors', 'bss_opt_sensors_desc', 'bss_sensors_disabled'],
    ['bss_opt_max_refresh', 'bss_opt_max_refresh_desc', 'bss_max_refresh']
  ];

  function openBssModal() {
    var p = state.prefs;
    var body = el('div', 'fx-optlist');
    BSS_FIELDS.forEach(function (f) {
      body.appendChild(switchRow(f[0], f[1], !!p[f[2]], f[2]));
    });
    body.appendChild(el('div', 'fx-sectionhead', { 'data-i18n': 'bss_opt_gps' }, esc0(t('bss_opt_gps'))));
    var gps = el('div', 'fx-gpslist');
    for (var i = 0; i <= 4; i++) {
      gps.appendChild(el('div', 'fx-gpsrow' + (p.bss_gps_mode === i ? ' fx-lvl-on' : ''), { 'data-gps': i },
        '<span class="fx-gpsdot"></span><span class="fx-gpsinfo"><span class="fx-gpsname" data-i18n="bss_gps_' + i + '">' + esc0(t('bss_gps_' + i)) + '</span>' +
        '<span class="fx-gpsdesc" data-i18n="bss_gps_hint_' + i + '">' + esc0(t('bss_gps_hint_' + i)) + '</span></span>'));
    }
    body.appendChild(gps);
    var actions = el('div', 'fx-modalactions', null,
      '<button class="fx-btn fx-btn-primary" data-bss-apply>' + esc0(t('bss_apply')) + '</button>');

    var shell = modalShell('fx-m-bss', 'bss_modal_title', null, {});
    shell.querySelector('.fx-modal-body').appendChild(body);
    shell.querySelector('.fx-modal-card').appendChild(actions);
    shell.addEventListener('click', function (e) {
      if (e.target === shell) closeModal(shell);
      var gpsRow = e.target.closest ? e.target.closest('.fx-gpsrow') : null;
      if (gpsRow) {
        shell.querySelectorAll('.fx-gpsrow').forEach(function (r) { r.classList.remove('fx-lvl-on'); });
        gpsRow.classList.add('fx-lvl-on');
      }
      if (e.target.closest && e.target.closest('[data-bss-apply]')) saveBss(shell);
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
  }

  async function saveBss(shell) {
    if (busy) return;
    busy = true;
    showLoading(t('loading_applying_bss'));
    try {
      var inputs = shell.querySelectorAll('[data-bss]');
      for (var i = 0; i < inputs.length; i++) {
        var key = inputs[i].getAttribute('data-bss');
        var want = inputs[i].checked ? 1 : 0;
        if ((state.prefs[key] || 0) !== want) {
          await setPref(key, want);
          state.prefs[key] = want;
        }
      }
      var gpsRow = shell.querySelector('.fx-gpsrow.fx-lvl-on');
      var gpsMode = gpsRow ? parseInt(gpsRow.getAttribute('data-gps')) : 0;
      if ((state.prefs.bss_gps_mode || 0) !== gpsMode) {
        await setPref('bss_gps_mode', gpsMode);
        state.prefs.bss_gps_mode = gpsMode;
      }
      if (state.prefs.battery_saver) {
        await runJSON('sh ' + MODDIR + '/scripts/frosty.sh apply_bss 2>/dev/null');
        logAction(t('log_bss_applied'), 'ok');
      }
      toast(t('log_bss_applied'), 'ok');
      closeModal(shell);
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
    hideLoading();
    busy = false;
  }

  // ── SOO options modal ──

  var DELAYS = [1, 5, 10, 15, 20, 30, 60, 120, 180, 240];

  function sooRow(nameKey, descKey, control) {
    return el('div', 'fx-optrow', null,
      '<div class="fx-optinfo"><span class="fx-optname" data-i18n="' + nameKey + '">' + esc0(t(nameKey)) + '</span>' +
      '<span class="fx-optdesc" data-i18n="' + descKey + '">' + esc0(t(descKey)) + '</span></div>' + control);
  }

  function sooToggle(key, checked) {
    return '<label class="fx-switch"><input type="checkbox" data-soo="' + key + '"' + (checked ? ' checked' : '') + '><span class="fx-swtrack"><span class="fx-swknob"></span></span></label>';
  }
  function sooSelect(key, val, options) {
    var opts = options.map(function (o) {
      return '<option value="' + o.v + '"' + (String(o.v) === String(val) ? ' selected' : '') + '>' + esc0(o.l) + '</option>';
    }).join('');
    return '<select class="fx-select" data-soo="' + key + '">' + opts + '</select>';
  }

  function openSooModal() {
    var p = state.prefs;
    var body = el('div', 'fx-optlist');
    body.appendChild(sooRow('soo_opt_wifi', 'soo_opt_wifi_desc', sooToggle('soo_kill_wifi', p.soo_kill_wifi)));
    body.appendChild(sooRow('soo_opt_bt', 'soo_opt_bt_desc', sooToggle('soo_kill_bt', p.soo_kill_bt)));
    body.appendChild(sooRow('soo_opt_data', 'soo_opt_data_desc', sooToggle('soo_kill_data', p.soo_kill_data)));
    body.appendChild(sooRow('soo_opt_nfc', 'soo_opt_nfc_desc', sooToggle('soo_kill_nfc', p.soo_kill_nfc)));
    body.appendChild(sooRow('soo_opt_location', 'soo_opt_location_desc', sooToggle('soo_kill_location', p.soo_kill_location)));
    body.appendChild(sooRow('soo_opt_sensors', 'soo_opt_sensors_desc', sooToggle('soo_kill_sensors', p.soo_kill_sensors)));
    body.appendChild(sooRow('soo_opt_panel_lpm', 'soo_opt_panel_lpm_desc', sooToggle('soo_kill_panel_lpm', p.soo_kill_panel_lpm)));
    var delayOpts = DELAYS.map(function (d) { return { v: d, l: d + ' min' }; });
    body.appendChild(sooRow('soo_opt_conn_delay', 'soo_opt_conn_delay_desc', sooSelect('soo_conn_delay', p.soo_conn_delay, delayOpts)));
    body.appendChild(sooRow('soo_opt_restore', 'soo_opt_restore_desc', sooToggle('soo_restore_on_unlock', p.soo_restore_on_unlock)));
    var cleanOpts = [
      { v: 'off', l: t('soo_ram_clean_off') }, { v: 'safe', l: t('soo_ram_clean_safe') },
      { v: 'aggressive', l: t('soo_ram_clean_aggressive') }, { v: 'extreme', l: t('soo_ram_clean_extreme') }
    ];
    body.appendChild(sooRow('soo_opt_ram_clean', 'soo_opt_ram_clean_desc', sooSelect('soo_ram_clean_mode', p.soo_ram_clean_mode, cleanOpts)));
    var delay2 = el('div', 'fx-optrow fx-soo-delay', { 'data-soo-delay': '1' },
      sooRow('soo_opt_ram_clean_delay', 'soo_opt_ram_clean_delay_desc', sooSelect('soo_ram_clean_delay', p.soo_ram_clean_delay, delayOpts)).innerHTML);
    body.appendChild(delay2);
    delay2.style.display = p.soo_ram_clean_mode !== 'off' ? '' : 'none';
    body.addEventListener('change', function (e) {
      if (e.target.getAttribute('data-soo') === 'soo_ram_clean_mode') {
        delay2.style.display = e.target.value !== 'off' ? '' : 'none';
      }
    });
    var actions = el('div', 'fx-modalactions', null,
      '<button class="fx-btn fx-btn-primary" data-soo-apply>' + esc0(t('soo_apply')) + '</button>');

    var shell = modalShell('fx-m-soo', 'soo_modal_title', null, {});
    shell.querySelector('.fx-modal-body').appendChild(body);
    shell.querySelector('.fx-modal-card').appendChild(actions);
    shell.addEventListener('click', function (e) {
      if (e.target === shell) closeModal(shell);
      if (e.target.closest && e.target.closest('[data-soo-apply]')) saveSoo(shell);
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
  }

  async function saveSoo(shell) {
    if (busy) return;
    busy = true;
    showLoading(t('loading_applying_soo'));
    try {
      var nodes = shell.querySelectorAll('[data-soo]');
      for (var i = 0; i < nodes.length; i++) {
        var key = nodes[i].getAttribute('data-soo');
        var want = nodes[i].type === 'checkbox' ? (nodes[i].checked ? 1 : 0) : nodes[i].value;
        if (String(state.prefs[key] !== undefined ? state.prefs[key] : '') !== String(want)) {
          await setPref(key, want);
          state.prefs[key] = key.indexOf('delay') !== -1 ? parseInt(want) : want;
        }
      }
      if (state.prefs.screen_off_opt) {
        await run('sh ' + MODDIR + '/scripts/frosty.sh apply_soo 2>&1');
        logAction(t('log_soo_applied'), 'ok');
      }
      toast(t('log_soo_applied'), 'ok');
      closeModal(shell);
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
    hideLoading();
    busy = false;
  }

  // ── RAM cleaner modal ──

  var rcPoll = null;

  function openRamCleanModal() {
    var body = el('div', 'fx-rcwrap');
    var picker = el('div', 'fx-rcpicker', null,
      '<button class="fx-rcwl" data-rc-wl>' + esc0(t('ram_wl_btn')) + ' <span class="fx-pill" data-fx-picker-count="ramwl">0</span></button>' +
      '<p class="fx-rcsub" data-i18n="ram_cleaner_subtitle">' + esc0(t('ram_cleaner_subtitle')) + '</p>');
    var modes = el('div', 'fx-rcmodes');
    [['safe', 'ram_clean_safe_name', 'ram_clean_safe_desc', 'M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z'],
     ['aggressive', 'ram_clean_aggressive_name', 'ram_clean_aggressive_desc', 'M7 2v11h3v9l7-12h-4l4-8z'],
     ['extreme', 'ram_clean_extreme_name', 'ram_clean_extreme_desc', 'M13.5.67s.74 2.65.74 4.8c0 2.06-1.35 3.73-3.41 3.73-2.07 0-3.63-1.67-3.63-3.73l.03-.36C5.21 7.51 4 10.62 4 14c0 4.42 3.58 8 8 8s8-3.58 8-8C20 8.61 17.41 3.8 13.5.67z']]
     .forEach(function (m) {
      modes.appendChild(el('button', 'fx-rcmode', { 'data-mode': m[0] },
        '<span class="fx-rcicon">' + svg(m[3], 20, false) + '</span>' +
        '<span class="fx-rcinfo"><span class="fx-rcname" data-i18n="' + m[1] + '">' + esc0(t(m[1])) + '</span>' +
        '<span class="fx-rcdesc" data-i18n="' + m[2] + '">' + esc0(t(m[2])) + '</span></span>'));
    });
    picker.appendChild(modes);
    var processing = el('div', 'fx-rcproc', { style: 'display:none' },
      '<div class="fx-rcspinner"><div class="fx-spin"></div><div class="fx-rcmode-txt"></div></div>' +
      '<div class="fx-rcresults" style="display:none">' +
      '<div class="fx-rcstat"><span class="fx-rcval" data-rc-apps></span><span class="fx-rclbl" data-i18n="rc_stat_apps">' + esc0(t('rc_stat_apps')) + '</span></div>' +
      '<div class="fx-rcstat"><span class="fx-rcval" data-rc-freed></span><span class="fx-rclbl" data-i18n="rc_stat_freed">' + esc0(t('rc_stat_freed')) + '</span></div></div>');
    body.appendChild(picker);
    body.appendChild(processing);

    var shell = modalShell('fx-m-ramclean', 'ram_cleaner_title', null, {});
    var bodyWrap = shell.querySelector('.fx-modal-body');
    bodyWrap.appendChild(body);

    shell.addEventListener('click', function (e) {
      if (e.target === shell) { closeModal(shell); stopRcPoll(); }
      if (e.target.closest && e.target.closest('[data-rc-wl]')) openPicker('ramwl');
      var modeBtn = e.target.closest ? e.target.closest('.fx-rcmode') : null;
      if (modeBtn) startRamClean(shell, modeBtn.getAttribute('data-mode'));
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
  }

  function stopRcPoll() {
    if (rcPoll) { clearInterval(rcPoll); rcPoll = null; busy = false; }
  }

  async function startRamClean(shell, mode) {
    if (busy) return;
    busy = true;
    var picker = shell.querySelector('.fx-rcpicker');
    var proc = shell.querySelector('.fx-rcproc');
    var modeTxt = shell.querySelector('.fx-rcmode-txt');
    picker.style.display = 'none';
    proc.style.display = '';
    shell.querySelector('.fx-rcresults').style.display = 'none';
    modeTxt.textContent = t('ram_clean_' + mode + '_name');
    try {
      var r = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh ram_clean \'' + esc(mode) + '\' 2>/dev/null');
      if (r.status !== 'started' && r.status !== 'busy') throw new Error('ram_clean failed');
      rcPoll = setInterval(async function () {
        try {
          var p = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh ram_clean_poll 2>/dev/null');
          if (!p.running) {
            stopRcPoll();
            shell.querySelector('.fx-rcspinner').style.display = 'none';
            var res = shell.querySelector('.fx-rcresults');
            res.style.display = '';
            shell.querySelector('[data-rc-apps]').textContent = p.apps;
            shell.querySelector('[data-rc-freed]').textContent = p.freed ? (p.freed + ' MB') : '-';
            logAction(t('ram_clean_' + mode + '_name') + ': ' + p.apps + ' / ' + (p.freed || 0) + 'MB', 'ok');
          }
        } catch (e) { stopRcPoll(); }
      }, 1200);
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      picker.style.display = '';
      proc.style.display = 'none';
      busy = false;
    }
  }

  // ── import / export modal ──

  function openIoModal() {
    var body = el('div', 'fx-iowrap');
    body.appendChild(el('button', 'fx-btn fx-btn-primary fx-ioexport', { 'data-io-export': '1' }, esc0(t('io_export'))));
    var list = el('div', 'fx-iolist', null, '<div class="fx-emptystate">' + esc0(t('io_loading')) + '</div>');
    body.appendChild(list);

    var shell = modalShell('fx-m-io', 'io_title', null, {});
    var bodyWrap = shell.querySelector('.fx-modal-body');
    bodyWrap.appendChild(body);

    shell.addEventListener('click', function (e) {
      if (e.target === shell) closeModal(shell);
      if (e.target.closest && e.target.closest('[data-io-export]')) {
        (async function () {
          var btn = shell.querySelector('[data-io-export]');
          btn.disabled = true;
          showLoading(t('io_loading'));
          try {
            var path = await runStrict('sh ' + MODDIR + '/scripts/frosty.sh export 2>&1');
            toast(tf('toast_exported', path.trim ? path.trim() : path), 'ok');
            logAction(t('toast_exported'), 'ok');
            loadIoList(shell);
          } catch (er) {
            toast(t('toast_export_failed'), 'err');
          }
          hideLoading();
          btn.disabled = false;
        })();
      }
      var impBtn = e.target.closest ? e.target.closest('[data-io-import]') : null;
      if (impBtn) {
        (async function () {
          impBtn.disabled = true;
          showLoading(t('io_loading'));
          var before = { prefs: Object.assign({}, state.prefs), cats: Object.assign({}, state.categories) };
          var ok = await run("sh '" + MODDIR + "/scripts/frosty.sh' import '" + esc(impBtn.getAttribute('data-io-import')) + "' 2>&1").then(function (r) { return r.trim() === 'OK'; });
          hideLoading();
          if (ok) {
            closeModal(shell);
            await loadPrefs();
            showLoading(t('loading_reverting_all'));
            await revertDisabled(before);
            hideLoading();
            toast(t('toast_imported'), 'ok');
            log(t('log_not_applied'), 'warn');
          }
          else { toast(t('toast_import_failed'), 'err'); impBtn.disabled = false; }
        })();
      }
      var delBtn = e.target.closest ? e.target.closest('[data-io-del]') : null;
      if (delBtn) {
        var path = delBtn.getAttribute('data-io-del');
        run("rm -f '" + esc(path) + "'");
        var item = delBtn.closest('.fx-ioitem');
        if (item) item.remove();
      }
      var renBtn = e.target.closest ? e.target.closest('[data-io-rename]') : null;
      if (renBtn) {
        var oldPath = renBtn.getAttribute('data-io-rename');
        var spanEl = renBtn.closest('.fx-ioitem').querySelector('.fx-ioname');
        var cur = spanEl.textContent;
        var nn = window.prompt(t('io_rename_prompt'), cur);
        if (!nn || nn === cur) return;
        var dir = oldPath.substring(0, oldPath.lastIndexOf('/') + 1);
        var newPath = dir + 'frosty_' + nn.replace(/[\/\:*?"<>|`$]/g, '_') + '.json';
        if (newPath === oldPath) return;
        run("[ -e '" + esc(newPath) + "' ] && echo EXISTS || { mv '" + esc(oldPath) + "' '" + esc(newPath) + "' && echo OK; }").then(function (out) {
          if (out.indexOf('OK') === -1) { toast(t('toast_rename_failed'), 'err'); return; }
          spanEl.textContent = nn;
          renBtn.setAttribute('data-io-rename', newPath);
          var ib = renBtn.closest('.fx-ioitem').querySelector('[data-io-import]');
          ib.setAttribute('data-io-import', newPath);
          var db = renBtn.closest('.fx-ioitem').querySelector('[data-io-del]');
          db.setAttribute('data-io-del', newPath);
        });
      }
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
    loadIoList(shell);
  }

  async function loadIoList(shell) {
    var list = shell.querySelector('.fx-iolist');
    if (!list) return;
    list.innerHTML = '<div class="fx-emptystate">' + esc0(t('io_loading')) + '</div>';
    try {
      var backups = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh list_backups 2>&1').catch(function () { return []; });
      if (!backups.length) {
        list.innerHTML = '<div class="fx-emptystate">' + esc0(t('io_empty')) + '</div>';
        return;
      }
      list.innerHTML = '';
      backups.forEach(function (b) {
        var name = b.name.replace('frosty_', '').replace('.json', '');
        var m = name.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})/);
        var label = m ? m[1] + '-' + m[2] + '-' + m[3] + ' ' + m[4] + ':' + m[5] + ':' + m[6] : b.name;
        list.appendChild(el('div', 'fx-ioitem', null,
          '<span class="fx-ioname">' + esc0(label) + '</span>' +
          '<span class="fx-ioacts">' +
          '<button class="fx-icoact" data-io-import="' + esc0(b.path) + '" title="' + esc0(t('io_btn_import')) + '">' + svg(ICO.import, 17) + '</button>' +
          '<button class="fx-icoact" data-io-rename="' + esc0(b.path) + '" title="' + esc0(t('io_btn_rename')) + '">' + svg(ICO.rename, 15) + '</button>' +
          '<button class="fx-icoact fx-icoact-del" data-io-del="' + esc0(b.path) + '" title="' + esc0(t('io_btn_delete')) + '">' + svg(ICO.del, 17) + '</button>' +
          '</span>'));
      });
    } catch (e) {
      list.innerHTML = '<div class="fx-emptystate">' + esc0(t('io_error')) + '</div>';
    }
  }

  // ── bug report modal ──

  function openBugReportModal() {
    var body = el('div', 'fx-brwrap');
    body.appendChild(el('div', 'fx-notice', null, svg(ICO.info, 15) + '<span data-i18n="bugreport_notice">' + esc0(t('bugreport_notice')) + '</span>'));
    body.appendChild(el('button', 'fx-btn fx-btn-primary fx-brgen', { 'data-br-gen': '1' }, esc0(t('bugreport_generate'))));
    var list = el('div', 'fx-brlist', null, '<div class="fx-emptystate">' + esc0(t('io_loading')) + '</div>');
    body.appendChild(list);

    var shell = modalShell('fx-m-bugreport', 'bugreport_title', null, {});
    shell.querySelector('.fx-modal-body').appendChild(body);

    shell.addEventListener('click', function (e) {
      if (e.target === shell) closeModal(shell);
      if (e.target.closest && e.target.closest('[data-br-gen]')) {
        (async function () {
          var btn = shell.querySelector('[data-br-gen]');
          btn.disabled = true;
          showLoading(t('bugreport_generate'));
          try {
            var r = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh bug_report 2>&1');
            if (r.status === 'ok') { toast(t('bugreport_generated'), 'ok'); logAction(t('bugreport_generated'), 'ok'); }
            else toast(t('bugreport_failed'), 'err');
          } catch (er) { toast(t('bugreport_failed'), 'err'); }
          hideLoading();
          btn.disabled = false;
          loadBrList(shell);
        })();
      }
      var delBtn = e.target.closest ? e.target.closest('[data-br-del]') : null;
      if (delBtn) {
        run("rm -f '" + esc(delBtn.getAttribute('data-br-del')) + "'");
        var item = delBtn.closest('.fx-britem');
        if (item) item.remove();
      }
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
    loadBrList(shell);
  }

  async function loadBrList(shell) {
    var list = shell.querySelector('.fx-brlist');
    if (!list) return;
    try {
      var reports = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh list_bug_reports 2>&1').catch(function () { return []; });
      if (!reports.length) {
        list.innerHTML = '<div class="fx-emptystate">' + esc0(t('bugreport_empty')) + '</div>';
        return;
      }
      list.innerHTML = '';
      reports.forEach(function (r) {
        list.appendChild(el('div', 'fx-britem', null,
          '<span class="fx-ioname">' + esc0(r.name) + '</span>' +
          '<button class="fx-icoact fx-icoact-del" data-br-del="' + esc0(r.path) + '" title="' + esc0(t('io_btn_delete')) + '">' + svg(ICO.del, 17) + '</button>'));
      });
    } catch (e) {
      list.innerHTML = '<div class="fx-emptystate">' + esc0(t('bugreport_empty')) + '</div>';
    }
  }

  // ── about modal ──

  async function openAboutModal() {
    var body = el('div', 'fx-about');
    body.innerHTML =
      '<div class="fx-abhero"><div class="fx-abico">' + svg('M22 11h-4.17l3.24-3.24-1.41-1.42L15 11h-2V9l4.66-4.66-1.42-1.41L13 6.17V2h-2v4.17L7.76 2.93 6.34 4.34 11 9v2H9L4.34 6.34 2.93 7.76 6.17 11H2v2h4.17l-3.24 3.24 1.41 1.42L9 13h2v2l-4.66 4.66 1.42 1.41L11 17.83V22h2v-4.17l3.24 3.24 1.42-1.41L13 15v-2h2l4.66 4.66 1.41-1.42L17.83 13H22z', 30) + '</div>' +
      '<div class="fx-abname" data-ab-name>Frosty</div><div class="fx-abver" data-ab-ver></div></div>' +
      '<div class="fx-abdesc" data-ab-desc></div><div class="fx-abauthor" data-ab-author></div>';
    var shell = modalShell('fx-m-about', 'menu_about', null, { centered: true });
    shell.querySelector('.fx-modal-body').appendChild(body);
    shell.addEventListener('click', function (e) { if (e.target === shell) closeModal(shell); });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
    try {
      var raw = await run('cat ' + MODDIR + '/module.prop 2>/dev/null');
      var lines = {};
      raw.split('\n').forEach(function (l) {
        var eq = l.indexOf('=');
        if (eq > 0) lines[l.slice(0, eq).trim()] = l.slice(eq + 1).trim();
      });
      shell.querySelector('[data-ab-name]').textContent = lines.name || 'Frosty';
      shell.querySelector('[data-ab-ver]').textContent = lines.version ? 'v' + lines.version : '';
      shell.querySelector('[data-ab-desc]').textContent = t('about_desc') || lines.description || '';
      shell.querySelector('[data-ab-author]').textContent = lines.author ? 'by ' + lines.author : '';
    } catch (e) {}
  }

  // ── language modal ──

  function openLangModal() {
    var body = el('div', 'fx-langlist');
    LANGUAGES.forEach(function (l) {
      var cur = l[0].toLowerCase() === _lang.toLowerCase();
      var b = el('button', 'fx-langbtn' + (cur ? ' fx-langcur' : ''), cur ? { 'data-lang': l[0], 'aria-current': 'true' } : { 'data-lang': l[0] },
        '<span class="fx-langflag">' + esc0(l[1]) + '</span><span>' + esc0(l[2]) + '</span>' +
        '<i class="fx-flag fx-flag-' + l[0].toLowerCase() + '" aria-hidden="true"></i>');
      body.appendChild(b);
    });
    var shell = modalShell('fx-m-lang', 'lang_title', null, {});
    shell.querySelector('.fx-modal-body').appendChild(body);
    shell.addEventListener('click', function (e) {
      if (e.target === shell) closeModal(shell);
      var b = e.target.closest ? e.target.closest('.fx-langbtn') : null;
      if (b) { loadLang(b.getAttribute('data-lang')); render(); closeModal(shell); }
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
  }

  // ── theme modal ──

  var THEME_LIST = [
    { id: 'stock',    file: 'index.html',    name: 'Stock' },
    { id: 'comic',    file: 'comic.html',    name: 'Comic' },
    { id: 'retro',    file: 'retro.html',    name: 'Retro' },
    { id: 'terminal', file: 'terminal.html', name: 'Terminal' },
    { id: 'handheld', file: 'handheld.html', name: 'Handheld' }
  ];

  function switchTheme(id) {
    var target = THEME_LIST.filter(function (th) { return th.id === id; })[0];
    if (!target) return;
    setPref('webui_theme', id).then(function () {
      var done = false;
      function go() { if (done) return; done = true; location.replace(target.file); }
      if (historyPushCount > 0) {
        function unwind() {
          if (historyPushCount > 0) { history.back(); return; }
          window.removeEventListener('popstate', unwind);
          go();
        }
        window.addEventListener('popstate', unwind);
        history.back();
        setTimeout(function () { window.removeEventListener('popstate', unwind); go(); }, 400);
      } else {
        go();
      }
    });
  }

  function openThemesModal() {
    var current = (state.prefs && state.prefs.webui_theme) || 'stock';
    var body = el('div', 'fx-themelist');
    THEME_LIST.forEach(function (th) {
      var isCurrent = th.id === current;
      var card = el('button', 'fx-themecard' + (isCurrent ? ' fx-themecard-on' : ''),
        { 'data-theme-id': th.id, style: "background-image:url('themes/card-" + th.id + ".jpg')" },
        '<span class="fx-themeinfo"><span class="fx-themename">' + esc0(th.name) + '</span>' +
        '<span class="fx-themedesc" data-i18n="theme_' + th.id + '_desc">' + esc0(t('theme_' + th.id + '_desc')) + '</span></span>' +
        (isCurrent ? '<span class="fx-themechk">' + svg(ICO.check, 14, true) + '</span>' : ''));
      body.appendChild(card);
    });
    var shell = modalShell('fx-m-themes', 'themes_title', null, {});
    shell.querySelector('.fx-modal-body').appendChild(body);
    shell.addEventListener('click', function (e) {
      if (e.target === shell) closeModal(shell);
      var c = e.target.closest ? e.target.closest('.fx-themecard') : null;
      if (!c) return;
      var id = c.getAttribute('data-theme-id');
      closeModal(shell);
      if (id !== current) switchTheme(id);
    });
    shell.dataset.fxDynamic = '1';
    openModal(shell);
  }

  // ── navigation ──

  function showView(id) {
    currentView = id;
    $all('[data-fx-view]').forEach(function (v) {
      var on = v.getAttribute('data-fx-view') === id;
      v.classList.toggle('fx-view-on', on);
      v.classList.toggle('fx-view-off', !on);
    });
    $all('[data-fx-nav]').forEach(function (b) {
      b.classList.toggle('fx-nav-on', b.getAttribute('data-fx-nav') === id);
    });
    hooks.view.forEach(function (fn) { fn(id); });
  }

  // ── bindings ──

  var ACTIONS = {
    freeze: applyFreeze,
    stock: applyStock,
    reapply: reapply
  };
  // old-stock behavior: "Configure Options" (BSS/SOO) shows the loading window
  // with the theme animation before the options form appears
  function openOptionsWithLoading(openFn) {
    showLoading(t('loading_options'));
    var t0 = Date.now();
    setTimeout(function () {
      openFn();
      // keep the loading card up for a perceptible beat, min 700ms total
      var rest = 700 - (Date.now() - t0);
      if (rest > 20) setTimeout(hideLoading, rest);
      else hideLoading();
    }, 450);
  }
  var MODAL_OPENERS = {
    bss: function () { openOptionsWithLoading(openBssModal); },
    soo: function () { openOptionsWithLoading(openSooModal); },
    ramclean: openRamCleanModal,
    io: openIoModal,
    bugreport: openBugReportModal,
    about: openAboutModal,
    lang: openLangModal,
    themes: openThemesModal
  };

  function openNamedModal(name) {
    var fn = MODAL_OPENERS[name];
    if (fn) fn();
  }

  function switchMarkup() {
    return '<label class="fx-switch"><input type="checkbox"><span class="fx-swtrack"><span class="fx-swknob"></span></span></label>';
  }

  function bind() {
    $all('[data-fx-switch]').forEach(function (slot) {
      if (!slot.querySelector('.fx-switch')) slot.innerHTML = switchMarkup();
    });

    document.addEventListener('change', function (e) {
      var row = e.target.closest ? e.target.closest('[data-fx-toggle], [data-fx-cat]') : null;
      if (row && e.target.type === 'checkbox') {
        if (row.hasAttribute('data-fx-toggle')) togglePref(row.getAttribute('data-fx-toggle'));
        else toggleCategory(row.getAttribute('data-fx-cat'));
      }
    });

    document.addEventListener('click', function (e) {
      var row = e.target.closest ? e.target.closest('[data-fx-toggle], [data-fx-cat]') : null;
      if (row && !e.target.closest('.fx-switch') && !e.target.closest('a, button')) {
        var input = row.querySelector('input[type=checkbox]');
        if (input) { input.checked = !input.checked; input.dispatchEvent(new Event('change', { bubbles: true })); }
      }

      var nav = e.target.closest ? e.target.closest('[data-fx-nav]') : null;
      if (nav) { showView(nav.getAttribute('data-fx-nav')); return; }

      var lvl = e.target.closest ? e.target.closest('[data-fx-level]') : null;
      if (lvl) {
        var group = lvl.closest('[data-fx-levelgroup]');
        var key = group ? group.getAttribute('data-fx-levelgroup') : null;
        if (key === 'deep_doze_level') setDozeLevel(lvl.getAttribute('data-fx-level'));
        else if (key === 'ram_optimizer_level') setRamLevel(lvl.getAttribute('data-fx-level'));
        else if (key === 'multitask_profile') setMultitaskProfile(lvl.getAttribute('data-fx-level'));
        return;
      }

      var act = e.target.closest ? e.target.closest('[data-fx-action]') : null;
      if (act) {
        var fn = ACTIONS[act.getAttribute('data-fx-action')];
        if (fn) fn();
        return;
      }

      var mo = e.target.closest ? e.target.closest('[data-fx-modal-open]') : null;
      if (mo) {
        var mfn = MODAL_OPENERS[mo.getAttribute('data-fx-modal-open')];
        if (mfn) mfn();
        return;
      }

      var po = e.target.closest ? e.target.closest('[data-fx-picker-open]') : null;
      if (po) { openPicker(po.getAttribute('data-fx-picker-open')); return; }

      var closer = e.target.closest ? e.target.closest('[data-fx-modal-close]') : null;
      if (closer) {
        var modal = closer.closest('.fx-modal');
        if (modal) closeModal(modal);
        return;
      }

      var bulk = e.target.closest ? e.target.closest('[data-fx-cat-bulk]') : null;
      if (bulk) { toggleAllCategories(bulk.getAttribute('data-fx-cat-bulk') === 'on'); return; }
    });

    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') closeTopModal();
    });

    window.addEventListener('popstate', function () {
      if (historyPushCount > 0) historyPushCount--;
      closeTopModal();
    });

    var copyBtn = document.querySelector('[data-fx-log-copy]');
    if (copyBtn) copyBtn.addEventListener('click', function () {
      var text = logs.map(function (r) { return r.ts + '  ' + r.msg; }).join('\n');
      if (!text) return;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function () { toast(t('toast_log_copied'), 'ok'); })
          .catch(function () { toast(t('toast_copy_failed'), 'err'); });
      } else {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.style.cssText = 'position:fixed;opacity:0;top:0;left:0';
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand('copy'); toast(t('toast_log_copied'), 'ok'); }
        catch (er) { toast(t('toast_copy_failed'), 'err'); }
        ta.remove();
      }
    });
    var clearBtn = document.querySelector('[data-fx-log-clear]');
    if (clearBtn) clearBtn.addEventListener('click', function () {
      logs = [];
      $all('[data-fx-log]').forEach(function (box) { box.innerHTML = ''; });
    });

    $all('[data-fx-view]').forEach(function (v) { v.classList.add('fx-view-off'); });
    var initial = document.querySelector('[data-fx-nav][data-fx-initial]') ||
                  document.querySelector('nav [data-fx-nav]') ||
                  document.querySelector('[data-fx-nav]');
    showView(initial ? initial.getAttribute('data-fx-nav') : 'home');
  }

  // ── pull to refresh ──

  function setupPtr() {
    var ptr = el('div', 'fx-ptr', null,
      svg('M17.65 6.35A7.958 7.958 0 0 0 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08A5.99 5.99 0 0 1 12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z', 24));
    document.body.appendChild(ptr);
    var startY = 0, pulling = false, threshold = 72, rafId = null, currentDist = 0;
    var scroller = document.querySelector('[data-fx-scroll]') || document.documentElement;

    function frame() {
      var progress = Math.min(currentDist / threshold, 1);
      ptr.style.opacity = progress;
      ptr.style.transform = 'translateX(-50%) translateY(' + Math.min(currentDist * 0.4, 36) + 'px) rotate(' + (progress * 360) + 'deg)';
      rafId = null;
    }
    document.addEventListener('touchstart', function (e) {
      if (anyModalOpen()) return;
      var st = scroller.scrollTop || window.scrollY || 0;
      if (st <= 0) { startY = e.touches[0].clientY; pulling = true; }
    }, { passive: true });
    document.addEventListener('touchmove', function (e) {
      if (!pulling) return;
      var dist = e.touches[0].clientY - startY;
      if (dist > 0) {
        currentDist = dist;
        if (!rafId) rafId = requestAnimationFrame(frame);
      } else {
        pulling = false;
        ptr.style.opacity = 0;
        ptr.style.transform = 'translateX(-50%)';
      }
    }, { passive: true });
    document.addEventListener('touchend', function (e) {
      if (!pulling) return;
      var dist = e.changedTouches[0].clientY - startY;
      pulling = false;
      if (rafId) { cancelAnimationFrame(rafId); rafId = null; }
      ptr.style.opacity = 0;
      ptr.style.transform = 'translateX(-50%)';
      if (dist > threshold && !busy) { loadPrefs(); toast(t('toast_refreshed'), 'ok'); }
    });
  }

  // ── polling ──

  function startPolling() {
    stopPolling();
    pollTimer = setInterval(function () {
      if (!busy && document.visibilityState === 'visible') loadPrefs();
    }, 8000);
  }
  function stopPolling() {
    if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
  }

  document.addEventListener('visibilitychange', function () {
    if (document.hidden) stopPolling();
    else if (!demo) startPolling();
  });

  // ── init ──

  var moduleVersion = '';
  async function loadModuleVersion() {
    try {
      var raw = await run('cat ' + MODDIR + '/module.prop 2>/dev/null');
      if (demo) {
        try { var pr = await fetch('../module.prop'); if (pr.ok) raw = await pr.text(); } catch (e2) {}
      }
      var m = /^version=(.*)$/m.exec(raw || '');
      moduleVersion = m ? m[1].trim() : '';
    } catch (e) { moduleVersion = ''; }
    $all('[data-fx-version]').forEach(function (n) { if (moduleVersion) n.textContent = 'v' + moduleVersion; });
  }

  async function init() {
    ensureChrome();

    try {
      var resp = await fetch('locales/languages.json');
      var langMap = await resp.json();
      LANGUAGES = Object.keys(langMap).map(function (code) {
        return [code, code === 'en' ? 'EN' : code.toUpperCase().slice(0, 2), langMap[code]];
      });
    } catch (e) {
      LANGUAGES = [['en', 'EN', 'English']];
    }

    await initLang();
    showLoading(t('loading_default'));
    bind();
    setupPtr();
    loadModuleVersion();

    if (demo) {
      var bar = el('div', 'fx-demobar', null,
        svg(ICO.info, 13) + '<span>Preview mode - no root bridge detected</span>');
      document.body.appendChild(bar);
      requestAnimationFrame(function () { bar.classList.add('show'); });
      setTimeout(function () { bar.classList.remove('show'); }, 6000);
      bar.addEventListener('click', function () { bar.classList.remove('show'); });
    }

    await loadPrefs();
    log(t('log_webui_ready'), 'ok');
    if (!demo && counts().total > 0) {
      var applied = await run('[ -f "' + MODDIR + '/tmp/applied" ] && echo 1 || echo 0');
      if (applied.trim() !== '1') { log(t('log_not_applied'), 'warn'); toast(t('log_not_applied')); }
    }
    if (!demo) startPolling();

    try {
      var wl = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh list_wl 2>/dev/null');
      setInPlace(wlPkgs, wl.packages);
    } catch (e) {}
    try {
      var cad = await runJSON('sh ' + MODDIR + '/scripts/app_doze.sh list 2>/dev/null');
      setInPlace(cadPkgs, cad.packages);
    } catch (e) {}
    try {
      var ramwl = await runJSON('sh ' + MODDIR + '/scripts/frosty.sh list_ram_wl 2>/dev/null');
      setInPlace(ramwlPkgs, ramwl.packages);
    } catch (e) {}
    updatePickerCounts();
    render();

    hideLoading();
    hooks.ready.forEach(function (fn) { fn(); });
  }

  function on(event, fn) {
    if (hooks[event]) hooks[event].push(fn);
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.body.removeAttribute('unresolved');
    init();
  });

  return {
    demo: demo,
    MODDIR: MODDIR,
    exec: exec, run: run,
    t: t, tf: tf, tkey: tkey,
    init: init,
    on: on,
    toast: toast,
    showLoading: showLoading, updateLoading: updateLoading, hideLoading: hideLoading,
    refresh: loadPrefs,
    get state() { return state; },
    counts: counts,
    openPicker: openPicker,
    openModal: openNamedModal,
    registerSkin: registerSkin,
    showView: showView,
    log: log,
    getLang: function () { return _lang; }
  };
})();
