// FROSTY - WebUI App

(function () {
  'use strict';

  var state = { prefs: {}, categories: {}, state: 'unknown' };
  var localLogs = [];
  var pollTimer = null;
  var busy = false;
  var _rcPollTimer = null;

  var wlAllApps = [];
  var wlPkgs = [];
  var wlSearch = '';
  var wlShowSys = false;
  var wlLoaded = false;
  var wlRendered = 0;
  var wlFiltered = [];
  var wlScrolling = false;
  var wlIconObserver = null;
  var wlIconCache = new Map();

  var ramwlPkgs = [];
  var ramwlSearch = '';
  var ramwlShowSys = false;
  var ramwlRendered = 0;
  var ramwlFiltered = [];
  var ramwlScrolling = false;
  var ramwlIconObserver = null;
  var ramwlSearchTimer = null;

  var cadAllApps = [];
  var cadPkgs = [];
  var cadSearch = '';
  var cadLoaded = false;
  var cadRendered = 0;       // FIX: batch rendering counter (was missing)
  var cadFiltered = [];
  var cadScrolling = false;
  var cadIconObserver = null;

  var CAD_BLOCKED = {
    'android': 'cad_warn_system',
    'com.android.systemui': 'cad_warn_system',
    'com.android.phone': 'cad_warn_system',
    'com.android.settings': 'cad_warn_system',
    'com.android.shell': 'cad_warn_system',
    'com.android.bluetooth': 'cad_warn_system',
    'com.android.nfc': 'cad_warn_system'
  };

  // ── i18n ───
  var _strings = {};
  var _enStrings = {};
  var _lang = 'en';
  var RTL_LANGS = ['ar'];

  function t(key) { return _strings[key] || _enStrings[key] || key; }

  // tf('key', arg0, arg1) — replaces {0}, {1} in translated string
  function tf(key) {
    var s = t(key);
    var args = arguments;
    return s.replace(/{(\d+)}/g, function(_, i) {
      return args[parseInt(i) + 1] !== undefined ? args[parseInt(i) + 1] : '';
    });
  }

  // tkey(pref/cat key) — translates internal snake_case key to UI label
  var _TKEY_MAP = {
    kernel_tweaks: 'tgl_kernel', system_props: 'tgl_sysprops',
    blur_disable: 'tgl_blur', log_killing: 'tgl_logs',
    kill_tracking: 'tgl_tracking',
    ram_optimizer: 'tgl_ram_optimizer',
    deep_doze: 'tgl_deep_doze', battery_saver: 'tgl_bss',
    custom_app_doze: 'tgl_cad', screen_off_opt: 'tgl_soo',
    telemetry: 'cat_telemetry', background: 'cat_background',
    location: 'cat_location', connectivity: 'cat_connectivity',
    cloud: 'cat_cloud', payments: 'cat_payments',
    wearables: 'cat_wearables', games: 'cat_games'
  };
  function tkey(k) { return t(_TKEY_MAP[k] || k); }

  function applyStrings() {
    // text nodes
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      if (_strings[key]) el.textContent = _strings[key];
    });
    // placeholders
    document.querySelectorAll('[data-i18n-ph]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-ph');
      if (_strings[key]) el.placeholder = _strings[key];
    });
    // empty-state text (used with CSS content: attr(data-empty))
    document.querySelectorAll('[data-i18n-empty]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-empty');
      if (_strings[key]) el.dataset.empty = _strings[key];
    });
    // RTL
    var isRtl = RTL_LANGS.indexOf(_lang) !== -1;
    document.documentElement.dir = isRtl ? 'rtl' : 'ltr';
  }

  async function loadLang(code) {
    try {
      var resp = await fetch('locales/strings/' + code + '.xml');
      if (!resp.ok) throw new Error('not found');
      var text = await resp.text();
      var parser = new DOMParser();
      var doc = parser.parseFromString(text, 'application/xml');
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
            var enDoc = (new DOMParser()).parseFromString(await enR.text(), 'application/xml');
            _enStrings = {};
            enDoc.querySelectorAll('string').forEach(function(n) {
              _enStrings[n.getAttribute('name')] = n.textContent;
            });
          }
        } catch(ef) {}
      }
      applyStrings();
      if (typeof render === 'function') render();
      try { localStorage.setItem('frosty_lang', code); } catch(e) {}
    } catch(e) {
      if (code !== 'en') { await loadLang('en'); }
    }
  }

  async function initLang() {
    var saved;
    try { saved = localStorage.getItem('frosty_lang'); } catch(e) {}
    var navFull = (navigator.language || 'en');
    var navShort = navFull.split('-')[0];
    var supported = ['en','fr','de','pl','it','es','pt-BR','tr','id','ru','uk','zh-CN','ja','ar'];
    var detected = supported.find(function(c){ return c === navFull; }) ||
                   supported.find(function(c){ return c.split('-')[0] === navShort; }) ||
                   'en';
    await loadLang(saved || detected);

    // Show lang confirm popup on first launch when system is non-English
    if (!saved && detected !== 'en') {
      var match = LANGUAGES.find(function(l){ return l[0] === detected; });
      if (match) { showLangConfirm(detected, match[1], match[2]); }
    }
  }

  function showLangConfirm(code, flag, fullName) {
    var HEADERS = {
      fr:'Langue détectée', de:'Sprache erkannt', pl:'Wykryto język',
      it:'Lingua rilevata', es:'Idioma detectado', 'pt-BR':'Idioma detectado',
      tr:'Dil algılandı', id:'Bahasa terdeteksi', ru:'Обнаружен язык',
      uk:'Виявлено мову', 'zh-CN':'检测到语言', ja:'言語を検出しました', ar:'تم اكتشاف اللغة'
    };
    var QUESTIONS = {
      fr:'Voulez-vous utiliser cette langue ?',
      de:'Möchten Sie diese Sprache verwenden?',
      pl:'Chcesz używać tego języka?',
      it:'Vuoi usare questa lingua?',
      es:'¿Deseas usar este idioma?',
      'pt-BR':'Deseja usar este idioma?',
      tr:'Bu dili kullanmak ister misiniz?',
      id:'Ingin menggunakan bahasa ini?',
      ru:'Использовать этот язык?',
      uk:'Бажаєте використовувати цю мову?',
      'zh-CN':'是否使用此语言？',
      ja:'この言語を使用しますか？',
      ar:'هل تريد استخدام هذه اللغة؟'
    };
    var bd = $('lang-confirm-backdrop');
    if (!bd) return;
    $('lc-flag').textContent        = flag;
    $('lc-header').textContent      = HEADERS[code] || 'Detected language';
    $('lc-lang-name').textContent   = fullName;
    $('lc-question').textContent    = QUESTIONS[code] || 'Would you like to use this language?';
    $('lc-btn-keep').textContent    = flag + ' ' + fullName;
    bd.classList.add('open');

    $('lc-btn-keep').onclick = function() {
      bd.classList.remove('open');
      try { localStorage.setItem('frosty_lang', code); } catch(e) {}
    };
    $('lc-btn-en').onclick = async function() {
      bd.classList.remove('open');
      await loadLang('en');
    };
  }




  var $ = function (id) { return document.getElementById(id); };

  function esc(s) {
    var d = document.createElement('span');
    d.textContent = s;
    return d.innerHTML;
  }


  // ── Toast ──

  function toast(msg, type) {
    type = type || 'info';
    var wrap = $('toast-wrap');
    if (!wrap) return;
    var el = document.createElement('div');
    el.className = 'toast toast-' + type;
    el.textContent = msg;
    wrap.appendChild(el);
    requestAnimationFrame(function () { el.classList.add('show'); });
    setTimeout(function () {
      el.classList.remove('show');
      setTimeout(function () { el.remove(); }, 250);
    }, 5000);
  }

  // ── Activity Log ──

  function log(msg, type) {
    type = type || 'info';
    var ts = new Date().toLocaleTimeString('en-US', { hour12: false });
    localLogs.unshift({ ts: ts, msg: msg, type: type });
    if (localLogs.length > 50) localLogs.pop();
    renderLog();
  }

  function logAction(msg, type) {
    log(msg, type);
    try { API.appendLog(msg); } catch (e) {}
  }

  // Prepend a single row instead of rebuilding all 50 on every log call
  function renderLog() {
    var el = $('log-box');
    if (!el) return;
    if (localLogs.length === 0) { el.innerHTML = ''; return; }
    var e = localLogs[0];
    var row = document.createElement('div');
    row.className = 'log-e ' + e.type;
    row.innerHTML = '<span class="log-ts">' + esc(e.ts) + '</span>' +
                    '<span class="log-msg">' + esc(e.msg) + '</span>';
    el.insertBefore(row, el.firstChild);
    // Trim excess rows
    while (el.children.length > 50) el.removeChild(el.lastChild);
  }

  // ── Loading Overlay ──

  function showLoading(txt) {
    var o = $('loading-overlay'), el = $('loading-txt');
    if (el) el.textContent = txt || t('loading_default');
    if (o) o.classList.add('on');
    document.body.style.overflow = 'hidden';
  }

  function updateLoading(txt) {
    var el = $('loading-txt');
    if (el) el.textContent = txt || t('loading_default');
  }

  function hideLoading() {
    var o = $('loading-overlay');
    if (o) o.classList.remove('on');
    document.body.style.overflow = '';
  }

  // ── Load & Render ──

  async function loadPrefs() {
    try {
      var next = await API.getPrefs();
      // Only re-render if something actually changed
      if (JSON.stringify(next) !== JSON.stringify(state)) {
        state = next;
        render();
      }
    } catch (e) {
      log(tf('log_load_failed', e.message), 'err');
    }
  }

  function render() {
    var p = state.prefs || {};
    var c = state.categories || {};
    setChk('t-kernel', p.kernel_tweaks);
    setChk('t-blur', p.blur_disable);
    setChk('t-logs', p.log_killing);
    setChk('t-tracking', p.kill_tracking);
    setChk('t-sysprops', p.system_props);
    setChk('t-ram-optimizer', p.ram_optimizer);
    setChk('t-deep-doze', p.deep_doze);
    setChk('t-custom-app-doze', p.custom_app_doze);

    var cadx = $('cad-extras');
    if (cadx) {
      if (p.custom_app_doze) cadx.classList.add('on');
      else cadx.classList.remove('on');
    }

    var ddx = $('dd-extras');
    if (ddx) {
      if (p.deep_doze) ddx.classList.add('on');
      else ddx.classList.remove('on');
    }

    var mod = $('lvl-mod'), max = $('lvl-max');
    if (mod) { if (p.deep_doze_level === 'moderate') mod.classList.add('on'); else mod.classList.remove('on'); }
    if (max) { if (p.deep_doze_level === 'maximum') max.classList.add('on'); else max.classList.remove('on'); }

    var ramoptx = $('ram-opt-extras');
    if (ramoptx) {
      if (p.ram_optimizer) ramoptx.classList.add('on');
      else ramoptx.classList.remove('on');
    }

    var ramMod = $('ram-lvl-mod'), ramMax = $('ram-lvl-max');
    if (ramMod) { if (p.ram_optimizer_level === 'moderate') ramMod.classList.add('on'); else ramMod.classList.remove('on'); }
    if (ramMax) { if (p.ram_optimizer_level === 'maximum') ramMax.classList.add('on'); else ramMax.classList.remove('on'); }

    setChk('t-bss', p.battery_saver);
    var bssx = $('bss-extras');
    if (bssx) {
      if (p.battery_saver) bssx.classList.add('on');
      else bssx.classList.remove('on');
    }

    setChk('t-screen-off-opt', p.screen_off_opt);
    var soox = $('soo-extras');
    if (soox) {
      if (p.screen_off_opt) soox.classList.add('on');
      else soox.classList.remove('on');
    }

    // ── GMS Categories ──
    var cats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
    cats.forEach(function (cat) { setChk('t-' + cat, c[cat]); });
    updateStatusCards();
  }

  function setChk(id, val) {
    var el = $(id);
    if (el && el.checked !== !!val) el.checked = !!val;
  }

  function fmtKey(k) {
    return k.replace(/_/g, ' ').replace(/\b\w/g, function (c) { return c.toUpperCase(); });
  }

  // ── Toggle Pref ──

  async function togglePref(key) {
    if (busy) return;
    var current = state.prefs[key] || 0;
    var nv = current ? 0 : 1;
    busy = true;
    showLoading((nv ? t('loading_enabling') : t('loading_disabling')) + ' ' + fmtKey(key) + '...');

    try {
      var res = await API.setPref(key, nv);
      if (res.status !== 'ok') { toast(res.message || t('toast_error'), 'err'); hideLoading(); busy = false; return; }

      if (key === 'kernel_tweaks') {
        if (nv) {
          updateLoading(t('loading_applying_kernel'));
          var r = await API.applyKernelTweaks();
          if (r.status === 'ok') logAction(tf('log_kernel_applied', r.applied, r.failed, r.skipped || 0), r.failed > 0 ? 'warn' : 'ok');
        } else {
          updateLoading(t('loading_reverting_kernel'));
          var r2 = await API.revertKernelTweaks();
          if (r2.status === 'ok') logAction(tf('log_kernel_restored', r2.restored), 'ok');
        }
      } else if (key === 'blur_disable') {
        updateLoading(t('loading_applying_blur'));
        var rb = await API.applyBlur();
        if (rb.status === 'ok') {
          logAction(tf('log_blur_state', t(rb.blur === 'enabled' ? 'word_enabled' : 'word_disabled')), 'ok');
          if (rb.message) log(t('log_reboot_effect'), 'warn');
        }
      } else if (key === 'log_killing') {
        if (nv) {
          updateLoading(t('loading_killing_logs'));
          var rl = await API.killLogs();
          if (rl.status === 'ok') logAction(tf('log_killed_logs', rl.killed), 'ok');
        } else {
          updateLoading(t('loading_reverting_logs'));
          await API.revertKillLogs();
          logAction(t('log_logs_reverted'), 'ok');
        }
        log(t('log_reboot_effect'), 'warn');
      } else if (key === 'kill_tracking') {
        if (nv) {
          updateLoading(t('loading_applying_tracking'));
          var rt = await API.applyKillTracking();
          if (rt.status === 'ok') logAction(t('log_tracking_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_tracking'));
          var rt2 = await API.revertKillTracking();
          if (rt2.status === 'ok') logAction(t('log_tracking_reverted'), 'ok');
        }
      } else if (key === 'system_props') {
        updateLoading((nv ? t('loading_applying_sysprops') : t('loading_disabling_sysprops')));
        var rsp = await API.toggleSystemProps();
        if (rsp.status === 'ok') {
          logAction(t(nv ? 'log_sysprops_enabled' : 'log_sysprops_disabled'), 'ok');
        } else {
          logAction(tf('log_sysprops_failed', rsp.message || ''), 'err');
        }
        log(t('log_reboot_effect'), 'warn');
      } else if (key === 'screen_off_opt') {
        if (nv) {
          updateLoading(t('loading_applying_soo'));
          await API.applyScreenOffOpt();
          logAction(t('log_soo_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_soo'));
          await API.revertScreenOffOpt();
          logAction(t('log_soo_reverted'), 'ok');
        }
      } else if (key === 'deep_doze') {
        if (nv) {
          updateLoading(t('loading_applying_deep_doze'));
          await API.applyDeepDoze();
          logAction(t('log_deep_doze_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_deep_doze'));
          await API.revertDeepDoze();
          logAction(t('log_deep_doze_reverted'), 'ok');
        }
      } else if (key === 'ram_optimizer') {
        if (nv) {
          updateLoading(t('loading_applying_ram'));
          await API.applyRamOptimizer();
          logAction(t('log_ram_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_ram'));
          await API.revertRamOptimizer();
          logAction(t('log_ram_reverted'), 'ok');
        }
      } else if (key === 'custom_app_doze') {
        if (nv) {
          updateLoading(t('loading_applying_cad'));
          await API.applyCustomAppDoze();
          logAction(t('log_cad_applied'), 'ok');
          var cadReboot = await API.checkCadNeedsReboot();
          if (cadReboot) log(t('log_reboot_effect'), 'warn');
        } else {
          updateLoading(t('loading_reverting_cad'));
          await API.revertCustomAppDoze();
          logAction(t('log_cad_reverted'), 'ok');
          log(t('log_reboot_effect'), 'warn');
        }
      } else if (key === 'battery_saver') {
        if (nv) {
          updateLoading(t('loading_applying_bss'));
          await API.applyBatterySaver();
          logAction(t('log_bss_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_bss'));
          await API.revertBatterySaver();
          logAction(t('log_bss_reverted'), 'ok');
        }
      }

      toast(tkey(key) + ': ' + (nv ? t('toast_on') : t('toast_off')), 'ok');

      // Update local state and re-render without a shell round-trip
      state.prefs[key] = nv;
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
      // On error, resync from disk to recover correct state
      await loadPrefs();
    }
    hideLoading();
    busy = false;
  }

  // ── Toggle Category ──

  async function toggleCategory(cat) {
    if (busy) return;
    var current = state.categories[cat] || 0;
    var nv = current ? 0 : 1;
    busy = true;
    showLoading((nv ? t('loading_freezing') : t('loading_unfreezing')) + ' ' + fmtKey(cat) + '...');

    try {
      var res = await API.setPref(cat, nv);
      if (res.status !== 'ok') { toast(res.message || t('toast_error'), 'err'); hideLoading(); busy = false; return; }

      if (nv) {
        var fr = await API.freezeCategory(cat);
        if (fr.status === 'ok') {
          logAction(tf('log_cat_frozen', tkey(cat), fr.disabled, fr.failed), fr.failed > 0 ? 'warn' : 'ok');
          toast(tkey(cat) + ' ' + t('toast_cat_frozen'), 'ok');
        }
      } else {
        var uf = await API.unfreezeCategory(cat);
        if (uf.status === 'ok') {
          logAction(tf('log_cat_restored', tkey(cat), uf.enabled, uf.failed), uf.failed > 0 ? 'warn' : 'ok');
          toast(tkey(cat) + ' ' + t('toast_cat_restored'), 'ok');
        }
      }

      // Update local state and re-render without a shell round-trip
      state.categories[cat] = nv;
      render();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
      await loadPrefs();
    }
    hideLoading();
    busy = false;
  }

  // ── Doze Level ──

  async function setDozeLevel(level) {
    if (busy) return;
    if (level === state.prefs.deep_doze_level) return;
    busy = true;
    showLoading(t('loading_setting_level'));
    try {
      var res = await API.setPref('deep_doze_level', level);
      if (res.status === 'ok') {
        toast(tf('log_deep_doze_level', level), 'ok');
        logAction(tf('log_deep_doze_level', level), 'info');

        if (state.prefs.deep_doze) {
          updateLoading(t('loading_reapplying_deep'));
          await API.applyDeepDoze();
          logAction(t('log_deep_doze_reapplied'), 'ok');
        }

        // Update local state and re-render without a shell round-trip
        state.prefs.deep_doze_level = level;
        render();
      }
    } catch (e) { toast(t('toast_error'), 'err'); }
    hideLoading();
    busy = false;
  }

  async function setRamOptLevel(level) {
    if (busy) return;
    if (level === state.prefs.ram_optimizer_level) return;
    busy = true;
    showLoading(t('loading_setting_level'));
    try {
      var res = await API.setPref('ram_optimizer_level', level);
      if (res.status === 'ok') {
        toast(tf('log_ram_opt_level', level), 'ok');
        logAction(tf('log_ram_opt_level', level), 'info');

        if (state.prefs.ram_optimizer) {
          updateLoading(t('loading_reapplying_ram'));
          await API.applyRamOptimizer();
          logAction(t('log_ram_opt_reapplied'), 'ok');
        }

        state.prefs.ram_optimizer_level = level;
        render();
      }
    } catch (e) { toast(t('toast_error'), 'err'); }
    hideLoading();
    busy = false;
  }

  // ── BSS Modal ──

  var _bssGpsSelected = 0;

  function openBssModal() {
    var p = state.prefs;
    setChk('bss-t-datasaver',     p.bss_datasaver);
    setChk('bss-t-soundtrigger',  p.bss_soundtrigger_disabled);
    setChk('bss-t-fullbackup',    p.bss_fullbackup_deferred);
    setChk('bss-t-keybackup',     p.bss_keyvaluebackup_deferred);
    setChk('bss-t-force-standby', p.bss_force_standby);
    setChk('bss-t-force-bg',      p.bss_force_bg_check);
    setChk('bss-t-sensors',       p.bss_sensors_disabled);

    var gpsMode = p.bss_gps_mode || 0;
    _bssGpsSelected = gpsMode;
    for (var g = 0; g <= 4; g++) {
      var grow = $('bss-gps-' + g);
      if (grow) { if (g === gpsMode) grow.classList.add('on'); else grow.classList.remove('on'); }
    }
    $('bss-modal').classList.add('open');
  }

  function closeBssModal() {
    $('bss-modal').classList.remove('open');
  }

  function openSooModal() {
    var p = state.prefs;
    setChk('soo-t-wifi',       p.soo_kill_wifi);
    setChk('soo-t-bt',         p.soo_kill_bt);
    setChk('soo-t-data',       p.soo_kill_data);
    setChk('soo-t-location',   p.soo_kill_location);
    setChk('soo-t-sensors',    p.soo_kill_sensors);
    setChk('soo-t-panel-lpm',  p.soo_kill_panel_lpm);
    setChk('soo-t-restore',    p.soo_restore_on_unlock !== undefined ? p.soo_restore_on_unlock : 1);
    var rdEl = $('soo-conn-delay');
    var modeEl = $('soo-t-ram-clean-mode');
    var cdEl   = $('soo-ram-clean-delay');
    if (rdEl)   rdEl.value   = p.soo_conn_delay          !== undefined ? p.soo_conn_delay         : 5;
    if (modeEl) modeEl.value = p.soo_ram_clean_mode       !== undefined ? p.soo_ram_clean_mode      : 'off';
    if (cdEl)   cdEl.value   = p.soo_ram_clean_delay      !== undefined ? p.soo_ram_clean_delay     : 5;
    var ramExtras = $('soo-ram-clean-extras');
    if (ramExtras) ramExtras.style.maxHeight = (modeEl && modeEl.value !== 'off') ? '80px' : '0';
    $('soo-modal').classList.add('open');
  }

  function closeSooModal() {
    $('soo-modal').classList.remove('open');
  }

  async function saveSooOptions() {
    if (busy) return;
    busy = true;
    showLoading(t('loading_applying_soo'));
    try {
      var rdEl   = $('soo-conn-delay');
      var modeEl = $('soo-t-ram-clean-mode');
      var cdEl   = $('soo-ram-clean-delay');
      var opts = {
        soo_kill_wifi:         $('soo-t-wifi').checked       ? 1 : 0,
        soo_kill_bt:           $('soo-t-bt').checked         ? 1 : 0,
        soo_kill_data:         $('soo-t-data').checked       ? 1 : 0,
        soo_kill_location:     $('soo-t-location').checked   ? 1 : 0,
        soo_kill_sensors:      $('soo-t-sensors').checked    ? 1 : 0,
        soo_kill_panel_lpm:    $('soo-t-panel-lpm').checked  ? 1 : 0,
        soo_restore_on_unlock: $('soo-t-restore').checked    ? 1 : 0,
        soo_ram_clean_mode:    modeEl ? modeEl.value : 'off',
        soo_conn_delay:        rdEl   ? parseInt(rdEl.value)  || 5 : 5,
        soo_ram_clean_delay:   cdEl   ? parseInt(cdEl.value)  || 5 : 5
      };
      for (var k in opts) { await API.setPref(k, opts[k]); state.prefs[k] = opts[k]; }
      if (state.prefs.screen_off_opt) {
        await API.applyScreenOffOpt();
        logAction(t('log_soo_applied'), 'ok');
      }
      toast(t('log_soo_applied'), 'ok');
      closeSooModal();
      render();
    } catch (e) { toast(t('toast_error') + ': ' + e.message, 'err'); }
    hideLoading();
    busy = false;
  }

  async function saveBssOptions() {
    if (busy) return;
    busy = true;
    showLoading(t('loading_applying_bss'));
    try {
      var opts = {
        bss_datasaver:              $('bss-t-datasaver').checked       ? 1 : 0,
        bss_soundtrigger_disabled:  $('bss-t-soundtrigger').checked   ? 1 : 0,
        bss_fullbackup_deferred:    $('bss-t-fullbackup').checked    ? 1 : 0,
        bss_keyvaluebackup_deferred:$('bss-t-keybackup').checked     ? 1 : 0,
        bss_force_standby:          $('bss-t-force-standby').checked ? 1 : 0,
        bss_force_bg_check:         $('bss-t-force-bg').checked      ? 1 : 0,
        bss_sensors_disabled:       $('bss-t-sensors').checked       ? 1 : 0,
        bss_gps_mode:               _bssGpsSelected
      };
      for (var k in opts) { await API.setPref(k, opts[k]); state.prefs[k] = opts[k]; }
      if (state.prefs.battery_saver) {
        await API.applyBatterySaver();
        logAction(t('log_bss_reapplied'), 'ok');
      }
      toast(t('log_bss_applied'), 'ok');
      closeBssModal();
      render();
    } catch (e) { toast(t('toast_error') + ': ' + e.message, 'err'); }
    hideLoading();
    busy = false;
  }

  // ── Progress yield helper ──
  function yieldFrame(msg) {
    updateLoading(msg);
    return new Promise(function(r) { requestAnimationFrame(function() { setTimeout(r, 0); }); });
  }

  // ── Freeze All ──

  async function applyFreeze() {
    if (busy) return;
    busy = true;
    showLoading(t('loading_enabling_all'));
    log(t('log_freeze_all'), 'info');

    try {
      // Step 1: Turn ON all prefs
      await yieldFrame(t('loading_enabling_toggles'));
      var allPrefs = ['kernel_tweaks', 'system_props', 'blur_disable', 'log_killing', 'kill_tracking', 'ram_optimizer', 'custom_app_doze', 'deep_doze', 'battery_saver', 'screen_off_opt'];
      for (var i = 0; i < allPrefs.length; i++) {
        await API.setPref(allPrefs[i], 1);
      }
      logAction(t('log_toggles_enabled'), 'ok');

      // Step 2: Turn ON all categories
      await yieldFrame(t('loading_freezing_cats'));
      var allCats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
      for (var j = 0; j < allCats.length; j++) {
        await API.setPref(allCats[j], 1);
      }
      logAction(t('log_cats_enabled'), 'ok');

      // Step 3: Freeze GMS services
      await yieldFrame(t('loading_freezing_services'));
      var res = await API.applyFreeze();
      if (res.status === 'ok') {
        logAction(tf('log_gms_frozen', res.disabled, res.enabled, res.failed),
          res.failed > 0 ? 'warn' : 'ok');
      }

      // Step 4: Apply kernel tweaks
      await yieldFrame(t('loading_applying_kernel'));
      var rk = await API.applyKernelTweaks();
      if (rk.status === 'ok') logAction(tf('log_kernel_applied', rk.applied, rk.failed, rk.skipped || 0), rk.failed > 0 ? 'warn' : 'ok');

      // Step 5: Enable system props (rename .old → system.prop if needed)
      await yieldFrame(t('loading_applying_sysprops'));
      var rsp = await API.toggleSystemProps();
      if (rsp.status === 'ok') logAction(t('log_sysprops_enabled'), 'ok');
      else logAction(tf('log_sysprops_failed', rsp.action || rsp.message || ''), 'err');

      // Step 6: Disable blur
      await yieldFrame(t('loading_applying_blur'));
      var rb = await API.applyBlur();
      if (rb.status === 'ok') logAction(tf('log_blur_state', t(rb.blur === 'enabled' ? 'word_enabled' : 'word_disabled')), 'ok');

      // Step 7: Kill logs (RC/bin changes take effect on next reboot via post-fs-data.sh)
      await yieldFrame(t('loading_killing_logs'));
      var rl = await API.killLogs();
      if (rl.status === 'ok') logAction(tf('log_killed_logs', rl.killed), 'ok');

      // Step 8: Block Google tracking
      await yieldFrame(t('loading_applying_tracking'));
      var rtr = await API.applyKillTracking();
      if (rtr.status === 'ok') logAction(t('log_tracking_applied'), 'ok');

      // Step 9: Apply RAM optimizer
      await yieldFrame(t('loading_applying_ram'));
      var rram = await API.applyRamOptimizer();
      if (rram.status === 'ok') logAction(t('log_ram_applied'), 'ok');

      // Step 10: Apply App Doze
      await yieldFrame(t('loading_applying_cad'));
      await API.applyCustomAppDoze();
      logAction(t('log_cad_applied'), 'ok');

      // Step 11: Apply Deep Doze
      await yieldFrame(t('loading_applying_deep_doze'));
      await API.applyDeepDoze();
      logAction(t('log_deep_doze_applied'), 'ok');

      // Step 12: Apply Battery Saver profile
      await yieldFrame(t('loading_applying_bss'));
      await API.applyBatterySaver();
      logAction(t('log_bss_applied'), 'ok');

      // Step 13: Start Screen-Off Opt
      await yieldFrame(t('loading_applying_soo'));
      await API.applyScreenOffOpt();
      logAction(t('log_soo_applied'), 'ok');

      toast(t('toast_frozen'), 'ok');
      log(t('log_reboot_effect'), 'warn');
      await loadPrefs();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
    }
    hideLoading();
    busy = false;
  }

  // ── Revert All ──

  async function applyStock() {
    if (busy) return;
    busy = true;
    showLoading(t('loading_reverting_all'));
    log(t('log_reverting_all'), 'info');

    try {
      // Step 1: Turn OFF all prefs
      await yieldFrame(t('loading_disabling_toggles'));
      var allPrefs = ['kernel_tweaks', 'system_props', 'blur_disable', 'log_killing', 'kill_tracking', 'ram_optimizer', 'custom_app_doze', 'deep_doze', 'battery_saver', 'screen_off_opt'];
      for (var i = 0; i < allPrefs.length; i++) {
        await API.setPref(allPrefs[i], 0);
      }
      logAction(t('log_toggles_disabled'), 'ok');

      // Step 2: Turn OFF all categories
      await yieldFrame(t('loading_disabling_cats'));
      var allCats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
      for (var j = 0; j < allCats.length; j++) {
        await API.setPref(allCats[j], 0);
      }
      logAction(t('log_cats_disabled'), 'ok');

      // Step 3: Revert kernel FIRST (before frosty.sh stock backup)
      await yieldFrame(t('loading_restoring_kernel'));
      var rk = await API.revertKernelTweaks();
      if (rk.status === 'ok') logAction(tf('log_kernel_vals_restored', rk.restored), rk.restored > 0 ? 'ok' : 'warn');

      // Step 4: Disable system props (rename system.prop → .old)
      await yieldFrame(t('loading_disabling_sysprops'));
      var rsp2 = await API.toggleSystemProps();
      if (rsp2.status === 'ok') logAction(t('log_sysprops_disabled'), 'ok');
      else logAction(tf('log_sysprops_failed', rsp2.action || rsp2.message || ''), 'err');

      // Step 5: Re-enable all GMS services
      await yieldFrame(t('loading_re_enabling_gms'));
      var res = await API.applyStock();
      if (res.status === 'ok') {
        logAction(tf('log_gms_restored', res.enabled, res.failed),
          res.failed > 0 ? 'warn' : 'ok');
      }

      // Step 6: Revert blur
      await yieldFrame(t('loading_restoring_blur'));
      await API.applyBlur();
      logAction(t('log_blur_restored'), 'ok');

      // Step 7: Revert Google tracking block
      await yieldFrame(t('loading_reverting_tracking'));
      var rtr2 = await API.revertKillTracking();
      if (rtr2.status === 'ok') logAction(t('log_tracking_reverted'), 'ok');

      // Step 8: Revert RAM optimizer
      await yieldFrame(t('loading_reverting_ram'));
      var rram2 = await API.revertRamOptimizer();
      if (rram2.status === 'ok') logAction(t('log_ram_reverted'), 'ok');

      // Step 9: Revert App Doze
      await yieldFrame(t('loading_reverting_cad'));
      await API.revertCustomAppDoze();
      logAction(t('log_cad_reverted'), 'ok');

      // Step 10: Revert Deep Doze
      await yieldFrame(t('loading_reverting_deep_doze'));
      await API.revertDeepDoze();
      logAction(t('log_deep_doze_reverted'), 'ok');

      // Step 11: Revert Battery Saver
      await yieldFrame(t('loading_reverting_bss'));
      await API.revertBatterySaver();
      logAction(t('log_bss_reverted'), 'ok');

      // Step 12: Stop Screen-Off Opt
      await yieldFrame(t('loading_reverting_soo'));
      await API.revertScreenOffOpt();
      logAction(t('log_soo_reverted'), 'ok');

      toast(t('toast_stocked'), 'ok');
      log(t('log_reboot_effect'), 'warn');
      await loadPrefs();
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
      log(tf('log_load_failed', e.message), 'err');
    }
    hideLoading();
    busy = false;
  }

  // ══════════════════════════════
  //  WHITELIST
  // ══════════════════════════════

  function openWhitelist() {
    var titleEl = document.querySelector('#wl-modal .modal-head h3 span[data-i18n]');
    var noticeEl = document.querySelector('#wl-modal .modal-notice span[data-i18n="wl_notice"]');
    if (titleEl) titleEl.textContent = t('wl_title');
    if (noticeEl) noticeEl.textContent = t('wl_notice');
    $('wl-modal').classList.add('open');
    renderWlLoading();
    setTimeout(function () {
      if (!wlLoaded) {
        loadAllApps().then(function () {
          return loadWlPkgs();
        }).then(function () {
          wlFiltered = getSortedFiltered();
          renderWl();
        });
      } else {
        loadWlPkgs().then(function () {
          wlFiltered = getSortedFiltered();
          renderWl();
        });
      }
    }, 50);
  }

  function closeWhitelist() {
    $('wl-modal').classList.remove('open');
    if (wlIconObserver) { wlIconObserver.disconnect(); wlIconObserver = null; }
  }

  function renderWlLoading() {
    var list = $('wl-list');
    if (!list) return;
    list.innerHTML = '<div class="wl-empty">' + t('wl_loading') + '</div>';
    list.style.pointerEvents = 'none';
  }

  async function loadWlPkgs() {
    try {
      var res = await API.getWhitelist();
      wlPkgs = res.packages || [];
      updateWlCount();
    } catch (e) {
      wlPkgs = [];
    }
  }

  async function loadAllApps() {
    wlAllApps = [];
    try {
      var userPkgs = API.nativeListPackages('user');
      var sysPkgs = API.nativeListPackages('system');
      var seen = {};
      var all = [];

      function add(list, sys) {
        for (var i = 0; i < list.length; i++) {
          if (!seen[list[i]]) {
            seen[list[i]] = true;
            all.push({ pkg: list[i], system: sys });
          }
        }
      }
      add(userPkgs, false);
      add(sysPkgs, true);

      // If native API returned nothing (unsupported KSU build), fall through to pm fallback
      if (all.length === 0) throw new Error('nativeListPackages empty');

      var CHUNK = 40;
      for (var c = 0; c < all.length; c += CHUNK) {
        var chunk = all.slice(c, c + CHUNK);
        var names = chunk.map(function (a) { return a.pkg; });
        var infos = API.nativeGetPackagesInfo(names);
        var infoMap = {};
        for (var k = 0; k < infos.length; k++) infoMap[infos[k].packageName] = infos[k];

        for (var m = 0; m < chunk.length; m++) {
          var info = infoMap[chunk[m].pkg];
          wlAllApps.push({
            pkg: chunk[m].pkg,
            label: info ? (info.appLabel || chunk[m].pkg) : chunk[m].pkg,
            system: chunk[m].system
          });
        }
      }

      wlAllApps.sort(function (a, b) {
        return a.label.toLowerCase().localeCompare(b.label.toLowerCase());
      });
      wlLoaded = true;
    } catch (e) {
      try {
        var raw = await API.run("pm list packages 2>/dev/null | cut -d: -f2 | sort");
        wlAllApps = raw.split('\n').filter(function (l) { return l.trim(); }).map(function (p) {
          return { pkg: p.trim(), label: p.trim(), system: false };
        });
        wlLoaded = true;
      } catch (e2) {
        wlAllApps = [];
      }
    }
  }

  function getFilteredApps() {
    return wlAllApps.filter(function (a) {
      if (!wlShowSys && a.system) return false;
      if (wlSearch) {
        var q = wlSearch.toLowerCase();
        return a.label.toLowerCase().indexOf(q) !== -1 || a.pkg.toLowerCase().indexOf(q) !== -1;
      }
      return true;
    });
  }

  function getSortedFiltered() {
    var filtered = getFilteredApps();
    var checked = [];
    var unchecked = [];
    for (var i = 0; i < filtered.length; i++) {
      if (wlPkgs.indexOf(filtered[i].pkg) !== -1) checked.push(filtered[i]);
      else unchecked.push(filtered[i]);
    }
    return checked.concat(unchecked);
  }

  function setupIconObserver() {
    if (wlIconObserver) wlIconObserver.disconnect();
    wlIconObserver = new IntersectionObserver(function (entries) {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].isIntersecting) {
          var img = entries[i].target;
          var pkg = img.dataset.pkg;
          var src = img.dataset.src;
          if (src) {
            if (wlIconCache.has(pkg)) {
              var cached = wlIconCache.get(pkg);
              if (cached !== 'err') img.src = cached;
              else img.style.visibility = 'hidden';
            } else { img.src = src; }
            img.removeAttribute('data-src');
          }
          wlIconObserver.unobserve(img);
        }
      }
    }, { root: $('wl-list'), rootMargin: '500px 0px' });
  }

  function renderWl() {
    var list = $('wl-list');
    if (!list) return;
    list.style.pointerEvents = '';

    if (wlFiltered.length === 0) {
      list.innerHTML = '<div class="wl-empty">' + t('wl_empty') + '</div>';
      return;
    }

    wlRendered = 0;
    list.scrollTop = 0;
    list.innerHTML = '';
    setupIconObserver();

    var hasChecked = false;
    for (var i = 0; i < wlFiltered.length; i++) {
      if (wlPkgs.indexOf(wlFiltered[i].pkg) !== -1) { hasChecked = true; break; }
    }

    appendWlBatch(40, hasChecked);
  }

  function appendWlBatch(count, addSeparator) {
    var list = $('wl-list');
    if (!list || wlRendered >= wlFiltered.length) return;

    var end = Math.min(wlRendered + count, wlFiltered.length);
    var frag = document.createDocumentFragment();
    var separatorAdded = list.querySelector('.wl-sep') !== null;

    for (var i = wlRendered; i < end; i++) {
      var app = wlFiltered[i];
      var isWl = wlPkgs.indexOf(app.pkg) !== -1;

      if (addSeparator && !separatorAdded && !isWl && i > 0) {
        var prevIsWl = wlPkgs.indexOf(wlFiltered[i - 1].pkg) !== -1;
        if (prevIsWl) {
          var sep = document.createElement('div');
          sep.className = 'wl-sep';
          sep.setAttribute('data-i18n', 'wl_sep_other');
          sep.textContent = t('wl_sep_other') || 'Other apps';
          frag.appendChild(sep);
          separatorAdded = true;
        }
      }

      var row = document.createElement('div');
      row.className = 'wl-item' + (isWl ? ' active' : '');
      row.dataset.pkg = app.pkg;

      var img = document.createElement('img');
      img.className = 'wl-ico';
      img.decoding = 'async';
      img.dataset.pkg = app.pkg;
      img.dataset.src = 'ksu://icon/' + app.pkg;
      img.onload = function () { wlIconCache.set(this.dataset.pkg, this.src); };
      img.onerror = function () { wlIconCache.set(this.dataset.pkg, 'err'); this.style.visibility = 'hidden'; };

      var infoDiv = document.createElement('div');
      infoDiv.className = 'wl-app';

      var nameSpan = document.createElement('span');
      nameSpan.className = 'wl-name';
      nameSpan.textContent = app.label;
      infoDiv.appendChild(nameSpan);

      if (app.label !== app.pkg) {
        var pkgSpan = document.createElement('span');
        pkgSpan.className = 'wl-pkg';
        pkgSpan.textContent = app.pkg;
        infoDiv.appendChild(pkgSpan);
      }

      var chk = document.createElement('span');
      chk.className = 'wl-chk';
      chk.innerHTML = isWl ? '<svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>' : '';

      row.appendChild(img);
      row.appendChild(infoDiv);
      row.appendChild(chk);
      frag.appendChild(row);
    }

    list.appendChild(frag);

    var newImgs = list.querySelectorAll('img[data-src]');
    for (var j = 0; j < newImgs.length; j++) {
      wlIconObserver.observe(newImgs[j]);
    }

    wlRendered = end;
  }

  function onWlScroll() {
    if (wlScrolling) return;
    wlScrolling = true;
    requestAnimationFrame(function () {
      var list = $('wl-list');
      if (!list || wlRendered >= wlFiltered.length) {
        wlScrolling = false;
        return;
      }
      var scrollBottom = list.scrollTop + list.clientHeight;
      var threshold = list.scrollHeight - 300;
      if (scrollBottom >= threshold) {
        appendWlBatch(25, true);
      }
      wlScrolling = false;
    });
  }

  async function toggleWlApp(pkg) {
    var list = $('wl-list');
    var isWl = wlPkgs.indexOf(pkg) !== -1;
    try {
      if (isWl) {
        await API.removeWhitelist(pkg);
        wlPkgs = wlPkgs.filter(function (p) { return p !== pkg; });
      } else {
        await API.addWhitelist(pkg);
        wlPkgs.push(pkg);
      }
      updateWlCount();
      wlFiltered = getSortedFiltered();

      if (list) {
        var savedScroll = list.scrollTop;
        renderWl();
        list.scrollTop = savedScroll;
      }
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
  }

  function updateWlCount() {
    var el = $('wl-count');
    if (el) el.textContent = wlPkgs.length;
  }

  function openRamWhitelist() {
    var titleEl = document.querySelector('#ramwl-modal .modal-head h3 span[data-i18n]');
    var noticeEl = document.querySelector('#ramwl-modal .modal-notice span[data-i18n="ram_wl_notice"]');
    if (titleEl) titleEl.textContent = t('ram_wl_title');
    if (noticeEl) noticeEl.textContent = t('ram_wl_notice');
    $('ramwl-modal').classList.add('open');
    renderRamWlLoading();
    setTimeout(function () {
      if (!wlLoaded) {
        loadAllApps().then(function () {
          return loadRamWlPkgs();
        }).then(function () {
          ramwlFiltered = getRamWlSortedFiltered();
          renderRamWl();
        });
      } else {
        loadRamWlPkgs().then(function () {
          ramwlFiltered = getRamWlSortedFiltered();
          renderRamWl();
        });
      }
    }, 50);
  }

  function closeRamWhitelist() {
    $('ramwl-modal').classList.remove('open');
    if (ramwlIconObserver) { ramwlIconObserver.disconnect(); ramwlIconObserver = null; }
  }

  function renderRamWlLoading() {
    var list = $('ramwl-list');
    if (!list) return;
    list.innerHTML = '<div class="wl-empty">' + t('wl_loading') + '</div>';
    list.style.pointerEvents = 'none';
  }

  async function loadRamWlPkgs() {
    try {
      var res = await API.getRamWhitelist();
      ramwlPkgs = res.packages || [];
      updateRamWlCount();
    } catch (e) {
      ramwlPkgs = [];
    }
  }

  function updateRamWlCount() {
    var el = $('ramwl-count');
    if (el) el.textContent = ramwlPkgs.length;
  }

  function getRamWlFilteredApps() {
    return wlAllApps.filter(function (a) {
      if (!ramwlShowSys && a.system) return false;
      if (ramwlSearch) {
        var q = ramwlSearch.toLowerCase();
        return a.label.toLowerCase().indexOf(q) !== -1 || a.pkg.toLowerCase().indexOf(q) !== -1;
      }
      return true;
    });
  }

  function getRamWlSortedFiltered() {
    var filtered = getRamWlFilteredApps();
    var checked = [];
    var unchecked = [];
    for (var i = 0; i < filtered.length; i++) {
      if (ramwlPkgs.indexOf(filtered[i].pkg) !== -1) checked.push(filtered[i]);
      else unchecked.push(filtered[i]);
    }
    return checked.concat(unchecked);
  }

  function setupRamWlIconObserver() {
    if (ramwlIconObserver) ramwlIconObserver.disconnect();
    ramwlIconObserver = new IntersectionObserver(function (entries) {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].isIntersecting) {
          var img = entries[i].target;
          var pkg = img.dataset.pkg;
          var src = img.dataset.src;
          if (src) {
            if (wlIconCache.has(pkg)) {
              var cached = wlIconCache.get(pkg);
              if (cached !== 'err') img.src = cached;
              else img.style.visibility = 'hidden';
            } else { img.src = src; }
            img.removeAttribute('data-src');
          }
          ramwlIconObserver.unobserve(img);
        }
      }
    }, { root: $('ramwl-list'), rootMargin: '500px 0px' });
  }

  function renderRamWl() {
    var list = $('ramwl-list');
    if (!list) return;
    list.style.pointerEvents = '';

    if (ramwlFiltered.length === 0) {
      list.innerHTML = '<div class="wl-empty">' + t('wl_empty') + '</div>';
      return;
    }

    ramwlRendered = 0;
    list.scrollTop = 0;
    list.innerHTML = '';
    setupRamWlIconObserver();

    var hasChecked = false;
    for (var i = 0; i < ramwlFiltered.length; i++) {
      if (ramwlPkgs.indexOf(ramwlFiltered[i].pkg) !== -1) { hasChecked = true; break; }
    }

    appendRamWlBatch(25, false);
    if (hasChecked) {
      var sepIdx = -1;
      for (var j = 0; j < ramwlFiltered.length; j++) {
        if (ramwlPkgs.indexOf(ramwlFiltered[j].pkg) === -1) { sepIdx = j; break; }
      }
      if (sepIdx > 0) {
        var sep = document.createElement('div');
        sep.className = 'wl-sep';
        sep.textContent = t('wl_sep_other') || 'Other apps';
        var rows = list.querySelectorAll('.wl-item');
        if (rows[sepIdx]) list.insertBefore(sep, rows[sepIdx]);
      }
    }
  }

  function appendRamWlBatch(count, append) {
    var list = $('ramwl-list');
    if (!list) return;
    var end = Math.min(ramwlRendered + count, ramwlFiltered.length);
    var frag = document.createDocumentFragment();
    for (var i = ramwlRendered; i < end; i++) {
      var a = ramwlFiltered[i];
      var isWl = ramwlPkgs.indexOf(a.pkg) !== -1;

      var row = document.createElement('div');
      row.className = 'wl-item' + (isWl ? ' active' : '');
      row.dataset.pkg = a.pkg;

      var img = document.createElement('img');
      img.className = 'wl-ico';
      img.decoding = 'async';
      img.dataset.pkg = a.pkg;
      if (wlIconCache.has(a.pkg) && wlIconCache.get(a.pkg) !== 'err') {
        img.src = wlIconCache.get(a.pkg);
      } else {
        img.dataset.src = 'ksu://icon/' + a.pkg;
        img.onload = function () { wlIconCache.set(this.dataset.pkg, this.src); };
        img.onerror = function () { wlIconCache.set(this.dataset.pkg, 'err'); this.style.visibility = 'hidden'; };
        ramwlIconObserver.observe(img);
      }

      var infoDiv = document.createElement('div');
      infoDiv.className = 'wl-app';
      var nameSpan = document.createElement('span');
      nameSpan.className = 'wl-name';
      nameSpan.textContent = a.label;
      infoDiv.appendChild(nameSpan);
      if (a.label !== a.pkg) {
        var pkgSpan = document.createElement('span');
        pkgSpan.className = 'wl-pkg';
        pkgSpan.textContent = a.pkg;
        infoDiv.appendChild(pkgSpan);
      }

      var chk = document.createElement('span');
      chk.className = 'wl-chk';
      chk.innerHTML = isWl ? '<svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>' : '';

      row.appendChild(img);
      row.appendChild(infoDiv);
      row.appendChild(chk);
  
      frag.appendChild(row);
    }
    list.appendChild(frag);
    ramwlRendered = end;
    if (!append) list.onscroll = onRamWlScroll;
  }

  function onRamWlScroll() {
    if (ramwlScrolling) return;
    ramwlScrolling = true;
    requestAnimationFrame(function () {
      var list = $('ramwl-list');
      if (!list || ramwlRendered >= ramwlFiltered.length) {
        ramwlScrolling = false;
        return;
      }
      var scrollBottom = list.scrollTop + list.clientHeight;
      var threshold = list.scrollHeight - 300;
      if (scrollBottom >= threshold) {
        appendRamWlBatch(25, true);
      }
      ramwlScrolling = false;
    });
  }

  async function toggleRamWlApp(pkg) {
    var list = $('ramwl-list');
    var isWl = ramwlPkgs.indexOf(pkg) !== -1;
    try {
      if (isWl) {
        await API.removeRamWhitelist(pkg);
        ramwlPkgs = ramwlPkgs.filter(function (p) { return p !== pkg; });
      } else {
        await API.addRamWhitelist(pkg);
        ramwlPkgs.push(pkg);
      }
      updateRamWlCount();
      ramwlFiltered = getRamWlSortedFiltered();

      if (list) {
        var savedScroll = list.scrollTop;
        renderRamWl();
        list.scrollTop = savedScroll;
      }
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
  }


  // ══════════════════════════════
  //  CUSTOM APP DOZE
  // ══════════════════════════════
  function openCustomAppDoze() {
    $('cad-modal').classList.add('open');
    renderCadLoading();
    setTimeout(function () {
      if (!cadLoaded) {
        loadCadPkgs().then(function () {
          return loadCadApps();
        }).then(function () {
          cadFiltered = getCadSortedFiltered();
          renderCad();
        }).catch(function () {
          cadFiltered = getCadSortedFiltered();
          renderCad();
        });
      } else {
        loadCadPkgs().then(function () {
          cadFiltered = getCadSortedFiltered();
          renderCad();
        }).catch(function () {
          cadFiltered = getCadSortedFiltered();
          renderCad();
        });
      }
    }, 50);
  }

  function closeCustomAppDoze() {
    $('cad-modal').classList.remove('open');
    if (cadIconObserver) { cadIconObserver.disconnect(); cadIconObserver = null; }
  }

  function renderCadLoading() {
    var list = $('cad-list');
    if (!list) return;
    list.innerHTML = '<div class="wl-empty">' + t('cad_loading') + '</div>';
    list.style.pointerEvents = 'none';
  }

  async function loadCadPkgs() {
    try {
      var res = await API.getCustomDozeList();
      cadPkgs = res.packages || [];
      updateCadCount();
    } catch (e) { cadPkgs = []; }
  }

  async function loadCadApps() {
    cadAllApps = [];
    try {
      var res = await API.getNotOptimizedApps();
      var notOpt = res.packages || [];

      var merged = {};
      notOpt.forEach(function(p) { merged[p] = true; });
      cadPkgs.forEach(function(p) { merged[p] = true; });

      var all = Object.keys(merged).sort();

      // Get app labels via nativeGetPackagesInfo
      var infos = API.nativeGetPackagesInfo(all);
      var infoMap = {};
      for (var k = 0; k < infos.length; k++) infoMap[infos[k].packageName] = infos[k];

      cadAllApps = all.map(function(pkg) {
        var info = infoMap[pkg];
        return {
          pkg: pkg,
          label: info ? (info.appLabel || pkg) : pkg,
          system: false
        };
      });

      cadAllApps.sort(function(a, b) {
        return a.label.toLowerCase().localeCompare(b.label.toLowerCase());
      });
      cadLoaded = true;
    } catch (e) {
      // Fallback: just show already-added packages
      cadAllApps = cadPkgs.map(function(p) { return { pkg: p, label: p, system: false }; });
      cadLoaded = true;
    }
  }

  function getCadFiltered() {
    return cadAllApps.filter(function(a) {
      if (cadSearch) {
        var q = cadSearch.toLowerCase();
        return a.label.toLowerCase().indexOf(q) !== -1 || a.pkg.toLowerCase().indexOf(q) !== -1;
      }
      return true;
    });
  }

  function getCadSortedFiltered() {
    var filtered = getCadFiltered();
    var checked = [], unchecked = [];
    for (var i = 0; i < filtered.length; i++) {
      if (cadPkgs.indexOf(filtered[i].pkg) !== -1) checked.push(filtered[i]);
      else unchecked.push(filtered[i]);
    }
    return checked.concat(unchecked);
  }

  function setupCadIconObserver() {
    if (cadIconObserver) cadIconObserver.disconnect();
    cadIconObserver = new IntersectionObserver(function(entries) {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].isIntersecting) {
          var img = entries[i].target;
          var pkg = img.dataset.pkg;
          var src = img.dataset.src;
          if (src) {
            if (wlIconCache.has(pkg)) {
              var cached = wlIconCache.get(pkg);
              if (cached !== 'err') img.src = cached;
              else img.style.visibility = 'hidden';
            } else { img.src = src; }
            img.removeAttribute('data-src');
          }
          cadIconObserver.unobserve(img);
        }
      }
    }, { root: $('cad-list'), rootMargin: '500px 0px' });
  }

  function renderCad() {
    var list = $('cad-list');
    if (!list) return;
    list.style.pointerEvents = '';

    if (cadFiltered.length === 0) {
      list.innerHTML = '<div class="wl-empty">' + t('cad_empty') + '</div>';
      return;
    }

    cadRendered = 0;
    list.scrollTop = 0;
    list.innerHTML = '';
    setupCadIconObserver();

    var hasChecked = cadFiltered.some(function(a) { return cadPkgs.indexOf(a.pkg) !== -1; });
    appendCadBatch(40, hasChecked);
  }

  function appendCadBatch(count, addSeparator) {
    var list = $('cad-list');
    if (!list || cadRendered >= cadFiltered.length) return;

    var end = Math.min(cadRendered + count, cadFiltered.length);
    var frag = document.createDocumentFragment();
    var separatorAdded = list.querySelector('.wl-sep') !== null;

    for (var i = cadRendered; i < end; i++) {
      var app = cadFiltered[i];
      var isCad = cadPkgs.indexOf(app.pkg) !== -1;

      if (addSeparator && !separatorAdded && !isCad && i > 0) {
        var prevIsCad = cadPkgs.indexOf(cadFiltered[i-1].pkg) !== -1;
        if (prevIsCad) {
          var sep = document.createElement('div');
          sep.className = 'wl-sep';
          sep.textContent = t('wl_sep_other') || 'Other apps';
          frag.appendChild(sep);
          separatorAdded = true;
        }
      }

      var row = document.createElement('div');
      row.className = 'wl-item' + (isCad ? ' active' : '');
      row.dataset.pkg = app.pkg;

      var img = document.createElement('img');
      img.className = 'wl-ico';
      img.decoding = 'async';
      img.dataset.pkg = app.pkg;
      img.dataset.src = 'ksu://icon/' + app.pkg;
      img.onload = function() { wlIconCache.set(this.dataset.pkg, this.src); };
      img.onerror = function() { wlIconCache.set(this.dataset.pkg, 'err'); this.style.visibility = 'hidden'; };

      var infoDiv = document.createElement('div');
      infoDiv.className = 'wl-app';
      var nameSpan = document.createElement('span');
      nameSpan.className = 'wl-name';
      nameSpan.textContent = app.label;
      infoDiv.appendChild(nameSpan);
      if (app.label !== app.pkg) {
        var pkgSpan = document.createElement('span');
        pkgSpan.className = 'wl-pkg';
        pkgSpan.textContent = app.pkg;
        infoDiv.appendChild(pkgSpan);
      }

      var chk = document.createElement('span');
      chk.className = 'wl-chk';
      chk.innerHTML = isCad ? '<svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>' : '';

      row.appendChild(img);
      row.appendChild(infoDiv);
      row.appendChild(chk);
      frag.appendChild(row);
    }

    list.appendChild(frag);

    var newImgs = list.querySelectorAll('img[data-src]');
    for (var j = 0; j < newImgs.length; j++) cadIconObserver.observe(newImgs[j]);

    cadRendered = end;
  }

  function onCadScroll() {
    if (cadScrolling) return;
    cadScrolling = true;
    requestAnimationFrame(function () {
      var list = $('cad-list');
      if (!list || cadRendered >= cadFiltered.length) {
        cadScrolling = false;
        return;
      }
      var scrollBottom = list.scrollTop + list.clientHeight;
      var threshold = list.scrollHeight - 300;
      if (scrollBottom >= threshold) {
        appendCadBatch(25, true);
      }
      cadScrolling = false;
    });
  }

  async function toggleCadApp(pkg) {
    // Safety check
    if (CAD_BLOCKED[pkg]) {
      toast(t(CAD_BLOCKED[pkg]), 'warn');
      return;
    }

    var isCad = cadPkgs.indexOf(pkg) !== -1;
    try {
      if (isCad) {
        await API.removeCustomDoze(pkg);
        cadPkgs = cadPkgs.filter(function(p) { return p !== pkg; });
      } else {
        await API.addCustomDoze(pkg);
        cadPkgs.push(pkg);
      }
      updateCadCount();
      cadFiltered = getCadSortedFiltered();

      var list = $('cad-list');
      if (list) {
        var savedScroll = list.scrollTop;
        renderCad();
        list.scrollTop = savedScroll;
      }
    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
  }

  function updateCadCount() {
    var el = $('cad-count');
    if (el) el.textContent = cadPkgs.length;
  }

  var cadSearchTimer = null;
  function debouncedCadSearch(val) {
    cadSearch = val;
    if (cadSearchTimer) clearTimeout(cadSearchTimer);
    cadSearchTimer = setTimeout(function() {
      cadFiltered = getCadSortedFiltered();
      renderCad();
    }, 150);
  }

  // ── Polling ──

  function startPolling() {
    stopPolling();
    pollTimer = setInterval(function () {
      if (!busy && document.visibilityState === 'visible') loadPrefs();
    }, 8000);
  }

  function stopPolling() {
    if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
  }

  var searchTimer = null;
  function debouncedSearch(val) {
    wlSearch = val;
    if (searchTimer) clearTimeout(searchTimer);
    searchTimer = setTimeout(function () {
      wlFiltered = getSortedFiltered();
      renderWl();
    }, 150);
  }

  function debouncedRamWlSearch(val) {
    ramwlSearch = val;
    if (ramwlSearchTimer) clearTimeout(ramwlSearchTimer);
    ramwlSearchTimer = setTimeout(function () {
      ramwlFiltered = getRamWlSortedFiltered();
      renderRamWl();
    }, 150);
  }

  // ── Event Binding ──


  async function openAbout() {
    $('about-modal').classList.add('open');
    try {
      var raw = await API.run('cat ' + API.MODDIR + '/module.prop 2>/dev/null');
      var lines = {};
      raw.split('\n').forEach(function(l) {
        var eq = l.indexOf('=');
        if (eq > 0) lines[l.slice(0,eq).trim()] = l.slice(eq+1).trim();
      });
      $('about-name').textContent    = lines.name        || 'Frosty';
      $('about-desc').textContent    = t('about_desc') || lines.description || '';
      $('about-version').textContent = lines.version ? 'v' + lines.version : '';
      $('about-author').textContent  = lines.author ? 'by ' + lines.author : '';
    } catch(e) {}
  }

  async function loadIOList() {
    var list = $('io-list');
    if (!list) return;
    list.innerHTML = '<div class="io-empty">' + t('io_loading') + '</div>';
    try {
      var backups = await API.listBackups();
      if (!backups.length) {
        list.innerHTML = '<div class="io-empty">' + t('io_empty') + '</div>';
        return;
      }
      list.innerHTML = '';
      backups.forEach(function (b) {
        var name = b.name.replace('frosty_','').replace('.json','');
        var m = name.match(/(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})/);
        var label = m ? m[1]+'-'+m[2]+'-'+m[3]+'  '+m[4]+':'+m[5]+':'+m[6] : b.name;
        var item = document.createElement('div'); item.className = 'io-item';
        var span = document.createElement('span'); span.className = 'io-item-name'; span.textContent = label;
        var acts = document.createElement('div'); acts.className = 'io-item-acts';
        var importBtn = document.createElement('button'); importBtn.className = 'io-item-import ripple';
        importBtn.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M19 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V5a2 2 0 0 0-2-2zm-7 14-5-5 1.41-1.41L11 13.17V7h2v6.17l2.59-2.58L17 12l-5 5z"/></svg>';
        importBtn.title = t('io_btn_import');
        importBtn.addEventListener('click', (function(path) { return async function() {
          importBtn.disabled = true;
          var ok = await API.importSettings(path);
          if (ok) { $('io-modal').classList.remove('open'); await loadPrefs(); toast(t('toast_imported'), 'ok'); }
          else { toast(t('toast_import_failed'), 'err'); importBtn.disabled = false; }
        }; })(b.path));
        var delBtn = document.createElement('button'); delBtn.className = 'io-item-del ripple';
        delBtn.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zm2.46-7.12 1.41-1.41L12 12.59l2.12-2.12 1.41 1.41L13.41 14l2.12 2.12-1.41 1.41L12 15.41l-2.12 2.12-1.41-1.41L10.59 14l-2.13-2.12zM15.5 4l-1-1h-5l-1 1H5v2h14V4z"/></svg>';
        delBtn.title = t('io_btn_delete');
        delBtn.addEventListener('click', (function(path, el) { return async function() {
          delBtn.disabled = true;
          await API.run('rm -f "' + path + '"');
          el.remove();
          var remaining = $('io-list').querySelectorAll('.io-item').length;
          if (!remaining) $('io-list').innerHTML = '<div class="io-empty">' + t('io_empty') + '</div>';
        }; })(b.path, item));
        var renameBtn = document.createElement('button'); renameBtn.className = 'io-item-rename ripple';
        renameBtn.innerHTML = '<svg viewBox="0 0 24 24" width="15" height="15" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>';
        renameBtn.title = t('io_btn_rename');
        renameBtn.addEventListener('click', (function(path, spanEl, bObj) { return function() {
          var dir = path.substring(0, path.lastIndexOf('/') + 1);
          var curName = spanEl.textContent;
          var newName = window.prompt(t('io_rename_prompt'), curName);
          if (!newName || newName === curName) return;
          var newPath = dir + 'frosty_' + newName.replace(/[\/\:*?"<>|`$]/g, '_') + '.json';
          API.run('mv "' + path + '" "' + newPath + '"').then(function() {
            spanEl.textContent = newName;
            bObj.path = newPath;
            importBtn.onclick = null;
            importBtn.addEventListener('click', (function(p) { return async function() {
              importBtn.disabled = true;
              var ok = await API.importSettings(p);
              if (ok) { $('io-modal').classList.remove('open'); await loadPrefs(); toast(t('toast_imported'), 'ok'); }
              else { toast(t('toast_import_failed'), 'err'); importBtn.disabled = false; }
            }; })(newPath));
            delBtn.onclick = null;
            delBtn.addEventListener('click', (function(p, el) { return async function() {
              delBtn.disabled = true;
              await API.run('rm -f "' + p + '"');
              el.remove();
              var remaining = $('io-list').querySelectorAll('.io-item').length;
              if (!remaining) $('io-list').innerHTML = '<div class="io-empty">' + t('io_empty') + '</div>';
            }; })(newPath, item));
          }).catch(function() { toast(t('toast_rename_failed'), 'err'); });
        }; })(b.path, span, b));
        acts.appendChild(renameBtn); acts.appendChild(importBtn); acts.appendChild(delBtn);
        item.appendChild(span); item.appendChild(acts);
        list.appendChild(item);
      });
    } catch(e) { list.innerHTML = '<div class="io-empty">' + t('io_error') + '</div>'; }
  }

  var LANGUAGES = [
    ['en',    '🇬🇧', 'English'],
    ['fr',    '🇫🇷', 'Français'],
    ['de',    '🇩🇪', 'Deutsch'],
    ['pl',    '🇵🇱', 'Polski'],
    ['it',    '🇮🇹', 'Italiano'],
    ['es',    '🇪🇸', 'Español'],
    ['pt-BR', '🇧🇷', 'Português (BR)'],
    ['tr',    '🇹🇷', 'Türkçe'],
    ['id',    '🇮🇩', 'Indonesia'],
    ['ru',    '🇷🇺', 'Русский'],
    ['uk',    '🇺🇦', 'Українська'],
    ['zh-CN', '🇨🇳', '中文'],
    ['ja',    '🇯🇵', '日本語'],
    ['ar',    '🇸🇦', 'العربية'],
  ];

  function openLang() {
    var list = $('lang-list');
    list.innerHTML = '';
    LANGUAGES.forEach(function (pair) {
      var code = pair[0], flag = pair[1], name = pair[2];
      var btn = document.createElement('button');
      btn.className = 'lang-item ripple' + (code === _lang ? ' active' : '');
      btn.innerHTML = '<span class="lang-flag">' + flag + '</span><span class="lang-name">' + name + '</span>' +
        '<span class="lang-check">' + (code === _lang ? '✓' : '') + '</span>';
      btn.addEventListener('click', async function () {
        await loadLang(code);
        $('lang-modal').classList.remove('open');
      });
      list.appendChild(btn);
    });
    $('lang-modal').classList.add('open');
  }

  async function openIO() {
    $('io-modal').classList.add('open');
    loadIOList();
  }

  // Back Button Handler
  var _MODAL_ORDER = [
    { id: 'cad-modal',           close: function() { closeCustomAppDoze(); } },
    { id: 'wl-modal',            close: function() { closeWhitelist(); } },
    { id: 'ramwl-modal',         close: function() { closeRamWhitelist(); } },
    { id: 'bss-modal',           close: function() { closeBssModal(); } },
    { id: 'soo-modal',           close: function() { closeSooModal(); } },
    { id: 'about-modal',         close: function() { $('about-modal').classList.remove('open'); } },
    { id: 'io-modal',            close: function() { $('io-modal').classList.remove('open'); } },
    { id: 'lang-modal',          close: function() { $('lang-modal').classList.remove('open'); } },
    { id: 'lang-confirm-backdrop', close: function() { $('lang-confirm-backdrop').classList.remove('open'); } }
  ];

  function _closeTopModal() {
    for (var i = 0; i < _MODAL_ORDER.length; i++) {
      var m = document.getElementById(_MODAL_ORDER[i].id);
      if (m && m.classList.contains('open')) {
        _MODAL_ORDER[i].close();
        return true;
      }
    }
    return false;
  }

  // Push a history entry whenever a modal opens so popstate fires on back press
  function _pushModalHistory() {
    history.pushState({ frostyModal: true }, '');
  }

  function showPage(id) {
    document.querySelectorAll('.page').forEach(function(p) { p.classList.remove('page-active'); });
    document.querySelectorAll('.nav-tab').forEach(function(t) { t.classList.remove('active'); });
    var page = document.getElementById('page-' + id);
    if (page) page.classList.add('page-active');
    var tab = document.querySelector('.nav-tab[data-page="' + id + '"]');
    if (tab) tab.classList.add('active');
    var app = document.getElementById('app');
    if (app) app.scrollTop = 0;
  }

  function initTheme() {
    var saved; try { saved = localStorage.getItem('frosty-theme'); } catch(e) {}
    var theme = saved || 'dark';
    document.documentElement.setAttribute('data-theme', theme);
    _updateThemeMeta(theme);
  }
  function toggleTheme() {
    var cur = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', cur);
    try { localStorage.setItem('frosty-theme', cur); } catch(e) {}
    _updateThemeMeta(cur);
  }
  function _updateThemeMeta(theme) {
    var meta = document.getElementById('theme-meta');
    if (meta) meta.content = theme === 'light' ? '#EEF3F8' : '#0D0F11';
  }

  function updateStatusCards() {
    var p = state.prefs || {};
    var c = state.categories || {};
    var sections = [
      { id: 'tweaks', total: 6, src: p, keys: [
          { k: 'kernel_tweaks',  l: t('pill_kernel')     },
          { k: 'system_props',   l: t('pill_props')      },
          { k: 'ram_optimizer',  l: t('pill_ram')        },
          { k: 'blur_disable',   l: t('pill_blur')       },
          { k: 'log_killing',    l: t('pill_logs')       },
          { k: 'kill_tracking',  l: t('pill_tracking')   }
      ]},
      { id: 'doze', total: 4, src: p, keys: [
          { k: 'deep_doze',       l: t('pill_deep_doze')  },
          { k: 'custom_app_doze', l: t('pill_app_doze')   },
          { k: 'battery_saver',   l: t('pill_batt_saver') },
          { k: 'screen_off_opt',  l: t('pill_screen_off') }
      ]},
      { id: 'gms', total: 8, src: c, keys: [
          { k: 'telemetry',    l: t('pill_telemetry')    },
          { k: 'background',   l: t('pill_background')   },
          { k: 'location',     l: t('pill_location')     },
          { k: 'connectivity', l: t('pill_connectivity') },
          { k: 'cloud',        l: t('pill_cloud')        },
          { k: 'payments',     l: t('pill_payments')     },
          { k: 'wearables',    l: t('pill_wearables')    },
          { k: 'games',        l: t('pill_games')        }
      ]}
    ];
    var grand = 0;
    sections.forEach(function(sec) {
      var card    = document.getElementById('status-' + sec.id);
      var countEl = document.getElementById('status-count-' + sec.id);
      var ratioEl = document.getElementById('status-ratio-' + sec.id);
      var pillsEl = document.getElementById('status-pills-' + sec.id);
      if (!card) return;
      var active = sec.keys.filter(function(item) { return sec.src[item.k]; }).length;
      grand += active;
      if (countEl) countEl.textContent = t('status_count').replace('{0}', active).replace('{1}', sec.total);
      if (ratioEl) ratioEl.textContent = active + '/' + sec.total;
      if (pillsEl) pillsEl.innerHTML = sec.keys.map(function(item) {
        return '<span class="status-pill' + (sec.src[item.k] ? ' active' : '') + '">' + item.l + '</span>';
      }).join('');
      card.classList.toggle('has-active', active > 0);
    });
    var totalEl = document.getElementById('home-total-num');
    if (totalEl) totalEl.textContent = grand;
    var _kpiFill = document.getElementById('kpi-fill');
    var _kpiNum  = document.getElementById('kpi-num');
    var _kpiWrap = document.getElementById('kpi-ring-wrap');
    var _CIRC = 534.07, _TOTAL = 18;
    if (_kpiFill) _kpiFill.style.strokeDashoffset = (_CIRC * (1 - grand / _TOTAL)).toFixed(2);
    if (_kpiNum)  _kpiNum.textContent = grand;
    if (_kpiWrap) _kpiWrap.classList.toggle('has-active', grand > 0);

  }

  function bind() {
    $('btn-freeze').addEventListener('click', applyFreeze);
    $('btn-stock').addEventListener('click', applyStock);

    // ── Nav & Theme ──
    document.querySelectorAll('.nav-tab').forEach(function(tab) {
      tab.addEventListener('click', function() { showPage(tab.dataset.page); });
    });
    var themeBtn = document.getElementById('theme-toggle');
    if (themeBtn) themeBtn.addEventListener('click', toggleTheme);

    document.querySelectorAll('.status-card').forEach(function(card) {
      card.addEventListener('click', function() { showPage(card.dataset.page); });
    });

    // ── System Tweaks ──
    $('t-kernel').addEventListener('change', function () { togglePref('kernel_tweaks'); });
    $('t-sysprops').addEventListener('change', function () { togglePref('system_props'); });
    $('t-blur').addEventListener('change', function () { togglePref('blur_disable'); });
    $('t-logs').addEventListener('change', function () { togglePref('log_killing'); });
    $('t-tracking').addEventListener('change', function () { togglePref('kill_tracking'); });
    $('t-ram-optimizer').addEventListener('change', function () { togglePref('ram_optimizer'); });
    $('t-deep-doze').addEventListener('change', function () { togglePref('deep_doze'); });
    $('t-bss').addEventListener('change', function () { togglePref('battery_saver'); });
    $('t-screen-off-opt').addEventListener('change', function () { togglePref('screen_off_opt'); });
    document.querySelectorAll('.tgl-row, .cat-row, .bss-opt-row').forEach(function (row) {
      row.addEventListener('click', function (e) {
        if (e.target.closest('.tgl')) return;
        var chk = row.querySelector('input[type="checkbox"]');
        if (chk) chk.click();
      });
    });

    // ── Doze ──
    $('lvl-mod').addEventListener('click', function () { setDozeLevel('moderate'); });
    $('lvl-max').addEventListener('click', function () { setDozeLevel('maximum'); });

    // ── Battery Saver Tuner ──
    $('bss-open').addEventListener('click', function() { _pushModalHistory(); openBssModal(); });
    $('bss-close').addEventListener('click', closeBssModal);
    $('bss-modal').addEventListener('click', function (e) {
      if (e.target === this) closeBssModal();
    });
    $('bss-apply').addEventListener('click', saveBssOptions);

    // BSS location mode rows
    for (var _gi = 0; _gi <= 4; _gi++) {
      (function (gi) {
        var grow = $('bss-gps-' + gi);
        if (!grow) return;
        grow.addEventListener('click', function () {
          _bssGpsSelected = gi;
          for (var x = 0; x <= 4; x++) {
            var gr = $('bss-gps-' + x);
            if (gr) { if (x === gi) gr.classList.add('on'); else gr.classList.remove('on'); }
          }
        });
      })(_gi);
    }

    $('soo-open').addEventListener('click', function() { _pushModalHistory(); openSooModal(); });
  // ── RAM Cleaner ──

  function openRamCleanModal() {
    var picker    = $('ram-clean-picker');
    var procWrap  = $('ram-clean-processing');
    var closeBtn  = $('ram-clean-close');
    if (picker)   { picker.style.display   = ''; }
    if (procWrap) { procWrap.style.display = 'none'; }
    if (closeBtn) { closeBtn.style.display = ''; }
    $('ram-clean-modal').classList.add('open');
  }

  function closeRamCleanModal() {
    if (_rcPollTimer) return;
    $('ram-clean-modal').classList.remove('open');
  }

  async function startRamClean(mode) {
    if (busy) return;
    var picker      = $('ram-clean-picker');
    var procWrap    = $('ram-clean-processing');
    var spinnerWrap = $('rc-spinner-wrap');
    var resultBox   = $('rc-result-box');
    var modeLabel   = $('rc-proc-mode');
    var closeBtn    = $('ram-clean-close');
    var modal       = $('ram-clean-modal');
    var modeKeyMap  = { safe: 'ram_clean_safe_name', aggressive: 'ram_clean_aggressive_name', extreme: 'ram_clean_extreme_name' };

    if (picker)      { picker.style.display      = 'none'; }
    if (procWrap)    { procWrap.style.display     = ''; }
    if (spinnerWrap) { spinnerWrap.style.display  = ''; }
    if (resultBox)   { resultBox.style.display    = 'none'; }
    if (modeLabel)   { modeLabel.textContent      = t(modeKeyMap[mode]) || mode; }
    if (closeBtn)    { closeBtn.style.display     = 'none'; }
    if (modal)       { modal.dataset.cleaning     = '1'; }

    try { await API.ramClean(mode, ''); } catch (_) {}

    _rcPollTimer = setInterval(async function() {
      try {
        var data = await API.ramCleanPoll();
        if (!data || !data.running) {
          clearInterval(_rcPollTimer);
          _rcPollTimer = null;
          if (spinnerWrap) { spinnerWrap.style.display = 'none'; }
          if (resultBox) {
            resultBox.style.display = '';
            var appsEl  = $('rc-apps-val');
            var freedEl = $('rc-freed-val');
            var apps    = data ? parseInt(data.apps)  || 0 : 0;
            var freed   = data ? parseInt(data.freed) || 0 : 0;
            if (appsEl)  appsEl.textContent  = apps;
            if (freedEl) freedEl.textContent = (freed > 0 ? '+' : '') + freed + ' MB';
          }
          if (closeBtn) { closeBtn.style.display = ''; }
          if (modal)    { delete modal.dataset.cleaning; }
        }
      } catch (_) {
        clearInterval(_rcPollTimer);
        _rcPollTimer = null;
        if (spinnerWrap) { spinnerWrap.style.display = 'none'; }
        if (closeBtn)    { closeBtn.style.display    = ''; }
        if (modal)       { delete modal.dataset.cleaning; }
      }
    }, 1500);
  }

    $('soo-close').addEventListener('click', closeSooModal);
    $('soo-modal').addEventListener('click', function (e) {
      if (e.target === this) closeSooModal();
    });
    $('soo-apply').addEventListener('click', saveSooOptions);
    $('soo-t-ram-clean-mode').addEventListener('change', function() {
      var ramExtras = $('soo-ram-clean-extras');
      if (ramExtras) ramExtras.style.maxHeight = this.value !== 'off' ? '80px' : '0';
    });

    $('ram-clean-open').addEventListener('click', function() { _pushModalHistory(); openRamCleanModal(); });
    $('ram-clean-close').addEventListener('click', closeRamCleanModal);
    $('ram-clean-modal').addEventListener('click', function(e) {
      if (e.target === this && !this.dataset.cleaning) closeRamCleanModal();
    });
    $('ram-clean-modes').addEventListener('click', function(e) {
      var btn = e.target.closest('.ram-clean-mode');
      if (btn && btn.dataset.mode) startRamClean(btn.dataset.mode);
    });

    // ── Custom App Doze ──
    $('cad-open').addEventListener('click', function() { _pushModalHistory(); openCustomAppDoze(); });
    $('cad-close').addEventListener('click', closeCustomAppDoze);
    $('cad-modal').addEventListener('click', function (e) {
      if (e.target === this) closeCustomAppDoze();
    });
    $('cad-search').addEventListener('input', function () {
      debouncedCadSearch(this.value);
    });
    $('cad-list').addEventListener('click', function (e) {
      var item = e.target.closest('.wl-item');
      if (item && item.dataset.pkg) toggleCadApp(item.dataset.pkg);
    });
    $('cad-list').addEventListener('scroll', onCadScroll, { passive: true });
    $('t-custom-app-doze').addEventListener('change', function () { togglePref('custom_app_doze'); });

    // ── Whitelist ──
    $('wl-open').addEventListener('click', function() { _pushModalHistory(); openWhitelist('deep_doze'); });
    $('wl-close').addEventListener('click', closeWhitelist);
    $('wl-modal').addEventListener('click', function (e) {
      if (e.target === this) closeWhitelist();
    });

    $('wl-search').addEventListener('input', function () {
      debouncedSearch(this.value);
    });

    $('wl-sys').addEventListener('change', function () {
      wlShowSys = this.checked;
      wlFiltered = getSortedFiltered();
      renderWl();
    });

    $('wl-list').addEventListener('scroll', onWlScroll, { passive: true });

    $('wl-list').addEventListener('click', function (e) {
      var item = e.target.closest('.wl-item');
      if (item && item.dataset.pkg) {
        toggleWlApp(item.dataset.pkg);
      }
    });

    // ── RAM Cleaner Whitelist ──
    $('ram-wl-open').addEventListener('click', function() { _pushModalHistory(); openRamWhitelist(); });
    $('ram-wl-close').addEventListener('click', closeRamWhitelist);
    $('ramwl-modal').addEventListener('click', function (e) {
      if (e.target === this) closeRamWhitelist();
    });

    $('ram-wl-search').addEventListener('input', function () {
      debouncedRamWlSearch(this.value);
    });

    $('ram-wl-sys').addEventListener('change', function () {
      ramwlShowSys = this.checked;
      ramwlFiltered = getRamWlSortedFiltered();
      renderRamWl();
    });

    $('ramwl-list').addEventListener('scroll', onRamWlScroll, { passive: true });

    $('ramwl-list').addEventListener('click', function (e) {
      var item = e.target.closest('.wl-item');
      if (item && item.dataset.pkg) {
        toggleRamWlApp(item.dataset.pkg);
      }
    });

    $('ram-lvl-mod').addEventListener('click', function () { setRamOptLevel('moderate'); });
    $('ram-lvl-max').addEventListener('click', function () { setRamOptLevel('maximum'); });

    // ── GMS Categories ──
    var cats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
    cats.forEach(function (cat) {
      var el = $('t-' + cat);
      if (el) el.addEventListener('change', function () { toggleCategory(cat); });
    });

    // ── 3-dots menu ──
    var dropdown = $('hdr-dropdown');
    $('hdr-dots-btn').addEventListener('click', function (e) {
      e.stopPropagation();
      dropdown.classList.toggle('open');
    });
    document.addEventListener('click', function () {
      dropdown.classList.remove('open');
    });
    document.addEventListener('scroll', function (e) {
      if (dropdown.contains(e.target)) return;
      dropdown.classList.remove('open');
    }, { passive: true, capture: true });
    var _appEl = document.getElementById('app');
    if (_appEl) _appEl.addEventListener('scroll', function (e) {
      if (dropdown.contains(e.target)) return;
      dropdown.classList.remove('open');
    }, { passive: true });

    // ── About ──
    $('menu-about').addEventListener('click', function () {
      dropdown.classList.remove('open');
      _pushModalHistory();
      openAbout();
    });
    $('about-close').addEventListener('click', function () {
      $('about-modal').classList.remove('open');
    });
    $('about-modal').addEventListener('click', function (e) {
      if (e.target === this) this.classList.remove('open');
    });
    $('about-gh-btn').addEventListener('click', function (e) {
      e.preventDefault();
      try { API.run('am start -a android.intent.action.VIEW -d "https://github.com/Drsexo/Frosty"'); }
      catch (err) { window.open('https://github.com/Drsexo/Frosty', '_blank'); }
    });

    // ── Import / Export ──
    $('menu-io').addEventListener('click', function () {
      dropdown.classList.remove('open');
      _pushModalHistory();
      openIO();
    });
    $('io-close').addEventListener('click', function () {
      $('io-modal').classList.remove('open');
    });
    $('io-modal').addEventListener('click', function (e) {
      if (e.target === this) this.classList.remove('open');
    });
    $('io-export-btn').addEventListener('click', async function () {
      var btn = this;
      btn.disabled = true;
      try {
        var path = await API.exportSettings();
        if (path && path.indexOf('frosty_') !== -1) {
          toast(t('toast_exported') + ': ' + path.split('/').pop(), 'ok');
          loadIOList();
        } else {
          toast(t('toast_export_failed'), 'err');
        }
      } catch(e) { toast(t('toast_export_failed') + ': ' + String(e.message || e).substring(0, 60), 'err'); }
      btn.disabled = false;
    });

    // ── Language ──
    $('menu-lang').addEventListener('click', function () {
      dropdown.classList.remove('open');
      _pushModalHistory();
      openLang();
    });
    $('lang-close').addEventListener('click', function () {
      $('lang-modal').classList.remove('open');
    });
    $('lang-modal').addEventListener('click', function (e) {
      if (e.target === this) this.classList.remove('open');
    });

    // Back handler: close topmost modal on back press
    window.addEventListener('popstate', function (e) {
      if (_closeTopModal()) {
      }
    });

    // ── Activity Log ──
    $('log-clear-btn').addEventListener('click', function () {
      localLogs = [];
      var box = $('log-box');
      if (box) box.innerHTML = '';
    });

    $('log-expand-btn').addEventListener('click', function () {
      $('log-box').classList.toggle('expanded');
      this.classList.toggle('expanded');
    });

    $('btn-reapply').addEventListener('click', async function () {
      if (busy) return;
      var rp = state.prefs || {}, rc = state.categories || {};
      var hasAnyCat = Object.keys(rc).some(function(k) { return rc[k] === 1; });
      var hasAny = Object.keys(rp).some(function(k) {
        return k !== 'deep_doze_level' && rp[k] === 1;
      }) || hasAnyCat;
      if (!hasAny) { toast(t('toast_nothing_to_apply'), 'info'); return; }
      busy = true;

      // Build step list based on what's enabled
      var _steps = [];
      if (rp.kernel_tweaks) _steps.push('loading_applying_kernel');
      if (rp.ram_optimizer)  _steps.push('loading_applying_ram');
      if (rp.system_props)  _steps.push('loading_applying_sysprops');
      if (rp.blur_disable)  _steps.push('loading_applying_blur');
      if (rp.log_killing)    _steps.push('loading_killing_logs');
      if (rp.kill_tracking)  _steps.push('loading_applying_tracking');
      if (hasAnyCat)         _steps.push('loading_freezing_services');
      if (rp.custom_app_doze)  _steps.push('loading_applying_cad');
      if (rp.deep_doze)        _steps.push('loading_applying_deep_doze');
      if (rp.battery_saver)    _steps.push('loading_applying_bss');
      if (rp.screen_off_opt)   _steps.push('loading_applying_soo');
      var _total = _steps.length, _cur = 0;

      function stepLoad(key) {
        _cur++;
        updateLoading('[' + _cur + '/' + _total + '] ' + t(key));
        return new Promise(function(r) { requestAnimationFrame(function() { setTimeout(r, 0); }); });
      }

      showLoading(t('loading_reapplying'));
      logAction(t('log_reapply_start'), 'info');

      try {
        if (rp.kernel_tweaks) {
          await stepLoad('loading_applying_kernel');
          var rk = await API.applyKernelTweaks();
          if (rk.status === 'ok') logAction(tf('log_kernel_applied', rk.applied, rk.failed, rk.skipped || 0), rk.failed > 0 ? 'warn' : 'ok');
          else logAction(rk.message || 'Kernel: error', 'err');
        }

        if (rp.ram_optimizer) {
          await stepLoad('loading_applying_ram');
          await API.applyRamOptimizer();
          logAction(t('log_ram_applied'), 'ok');
        }

        if (rp.system_props) {
          await stepLoad('loading_applying_sysprops');
          var rsp = await API.toggleSystemProps();
          if (rsp.status === 'ok') logAction(t('log_sysprops_enabled'), 'ok');
          else logAction(tf('log_sysprops_failed', rsp.message || ''), 'err');
        }

        if (rp.blur_disable) {
          await stepLoad('loading_applying_blur');
          var rb = await API.applyBlur();
          if (rb.status === 'ok') logAction(tf('log_blur_state', t('word_disabled')), 'ok');
        }

        if (rp.log_killing) {
          await stepLoad('loading_killing_logs');
          var rl = await API.killLogs();
          if (rl.status === 'ok') logAction(tf('log_killed_logs', rl.killed), 'ok');
        }

        if (rp.kill_tracking) {
          await stepLoad('loading_applying_tracking');
          var rtr = await API.applyKillTracking();
          if (rtr.status === 'ok') logAction(t('log_tracking_applied'), 'ok');
        }

        if (hasAnyCat) {
          await stepLoad('loading_freezing_services');
          var res = await API.applyFreeze();
          if (res.status === 'ok') {
            logAction(tf('log_gms_frozen', res.disabled, res.enabled, res.failed),
              res.failed > 0 ? 'warn' : 'ok');
          }
        }

        if (rp.custom_app_doze) {
          await stepLoad('loading_applying_cad');
          await API.applyCustomAppDoze();
          logAction(t('log_cad_applied'), 'ok');
          var cadReboot2 = await API.checkCadNeedsReboot();
          if (cadReboot2) log(t('log_reboot_effect'), 'warn');
        }

        if (rp.deep_doze) {
          await stepLoad('loading_applying_deep_doze');
          await API.applyDeepDoze();
          logAction(t('log_deep_doze_applied'), 'ok');
        }

        if (rp.battery_saver) {
          await stepLoad('loading_applying_bss');
          await API.applyBatterySaver();
          logAction(t('log_bss_applied'), 'ok');
        }

        if (rp.screen_off_opt) {
          await stepLoad('loading_applying_soo');
          await API.applyScreenOffOpt();
          logAction(t('log_soo_applied'), 'ok');
        }

        toast(t('toast_reapplied'), 'ok');
        log(t('log_reboot_effect'), 'warn');
      } catch (e) {
        toast(tf('log_load_failed', e.message), 'err');
        log(tf('log_load_failed', e.message), 'err');
      }
      hideLoading();
      busy = false;
    });

    $('log-copy-btn').addEventListener('click', function () {
      var box = $('log-box');
      if (!box || !box.children.length) return;
      var lines = Array.from(box.children).map(function (row) {
        var ts  = row.querySelector('.log-ts');
        var msg = row.querySelector('.log-msg');
        return (ts ? ts.textContent + '  ' : '') + (msg ? msg.textContent : '');
      });
      var text = lines.join('\n');
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function () {
          toast(t('toast_log_copied'), 'ok');
        }).catch(function () {
          toast(t('toast_copy_failed'), 'err');
        });
      } else {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.style.cssText = 'position:fixed;opacity:0;top:0;left:0';
        document.body.appendChild(ta);
        ta.focus(); ta.select();
        try { document.execCommand('copy'); toast(t('toast_log_copied'), 'ok'); }
        catch (e) { toast(t('toast_copy_failed'), 'err'); }
        document.body.removeChild(ta);
      }
    });

    // Pause polling when app is backgrounded, resume when foregrounded
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) stopPolling();
      else startPolling();
    });
  }

  // ── Init ──

  async function init() {
    initTheme();
    showPage('home');
    showLoading(t('io_loading'));
    await initLang();

    if (!API.available()) {
      $('app').innerHTML =
        '<div class="card" style="margin-top:60px;text-align:center;padding:30px">' +
        '<div style="margin-bottom:12px;display:flex;justify-content:center"><svg viewBox="0 0 24 24" width="40" height="40" fill="var(--orange,#ff9800)"><path d="M1 21h22L12 2 1 21zm12-3h-2v-2h2v2zm0-4h-2v-4h2v4z"/></svg></div>' +
        '<h2 style="font-size:1rem;margin-bottom:6px">' + t('ksu_unavailable_title') + '</h2>' +
        '<p style="color:var(--text-dim);font-size:.82rem">' + t('ksu_unavailable_desc') + '</p></div>';
      hideLoading();
      return;
    }

    bind();

    await loadPrefs();
    startPolling();

    log(t('log_webui_ready'), 'ok');

    try {
      var wl = await API.getWhitelist();
      wlPkgs = wl.packages || [];
      updateWlCount();
    } catch (e) {}

    try {
      var cad = await API.getCustomDozeList();
      cadPkgs = cad.packages || [];
      updateCadCount();
    } catch (e) {}

    try {
      var ramwl = await API.getRamWhitelist();
      ramwlPkgs = ramwl.packages || [];
      updateRamWlCount();
    } catch (e) {}

    hideLoading();
  }


  // ── Pull-to-refresh ──
  (function () {
    var ptr = document.createElement('div');
    ptr.id = 'ptr';
    ptr.innerHTML = '<svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor"><path d="M17.65 6.35A7.958 7.958 0 0 0 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08A5.99 5.99 0 0 1 12 18c-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/></svg>';
    document.body.appendChild(ptr);

    var startY = 0, pulling = false, threshold = 72;
    var rafId = null, currentDist = 0;
    var appEl = null;

    function isModalOpen() {
      var ids = ['wl-modal', 'ramwl-modal', 'cad-modal', 'bss-modal', 'soo-modal', 'about-modal', 'io-modal', 'lang-modal', 'lang-confirm-backdrop'];
      for (var i = 0; i < ids.length; i++) {
        var m = document.getElementById(ids[i]);
        if (m && m.classList.contains('open')) return true;
      }
      return false;
    }

    function applyPtrFrame() {
      var progress = Math.min(currentDist / threshold, 1);
      ptr.style.opacity = progress;
      ptr.style.transform = 'translateX(-50%) translateY(' + Math.min(currentDist * 0.4, 36) + 'px) rotate(' + (progress * 360) + 'deg)';
      rafId = null;
    }

    document.addEventListener('touchstart', function (e) {
      if (isModalOpen()) return;
      if (!appEl) appEl = document.getElementById('app');
      if (appEl && appEl.scrollTop === 0) {
        startY = e.touches[0].clientY;
        pulling = true;
      }
    }, { passive: true });

    document.addEventListener('touchmove', function (e) {
      if (!pulling) return;
      var dist = e.touches[0].clientY - startY;
      if (dist > 0) {
        currentDist = dist;
        if (!rafId) rafId = requestAnimationFrame(applyPtrFrame);
      } else {
        pulling = false;
        ptr.style.opacity = 0;
        ptr.style.transform = 'translateX(-50%) translateY(0) rotate(0deg)';
      }
    }, { passive: true });

    document.addEventListener('touchend', function (e) {
      if (!pulling) return;
      var dist = e.changedTouches[0].clientY - startY;
      pulling = false;
      if (rafId) { cancelAnimationFrame(rafId); rafId = null; }
      ptr.style.opacity = 0;
      ptr.style.transform = 'translateX(-50%) translateY(0) rotate(0deg)';
      if (dist > threshold && !busy) { loadPrefs(); toast(t('toast_refreshed'), 'ok'); }
    }, { passive: true });
  })();
  document.addEventListener('DOMContentLoaded', function () {
    document.body.removeAttribute('unresolved');
    init();
  });
})();