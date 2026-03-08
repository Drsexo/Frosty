// FROSTY - WebUI App

(function () {
  'use strict';

  var state = { prefs: {}, categories: {}, state: 'unknown' };
  var localLogs = [];
  var pollTimer = null;
  var busy = false;

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

  // ── i18n ───
  var _strings = {};
  var _lang = 'en';
  var RTL_LANGS = ['ar'];

  function t(key) { return _strings[key] || key; }

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
    ram_optimizer: 'tgl_ram_optimizer',
    gms_doze: 'tgl_gms_doze', deep_doze: 'tgl_deep_doze',
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
    setChk('t-sysprops', p.system_props);
    setChk('t-ram-optimizer', p.ram_optimizer);
    setChk('t-gms-doze', p.gms_doze);
    setChk('t-deep-doze', p.deep_doze);

    var ddx = $('dd-extras');
    if (ddx) {
      if (p.deep_doze) ddx.classList.add('on');
      else ddx.classList.remove('on');
    }

    var mod = $('lvl-mod'), max = $('lvl-max');
    if (mod) { if (p.deep_doze_level === 'moderate') mod.classList.add('on'); else mod.classList.remove('on'); }
    if (max) { if (p.deep_doze_level === 'maximum') max.classList.add('on'); else max.classList.remove('on'); }

    var cats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
    cats.forEach(function (cat) { setChk('t-' + cat, c[cat]); });
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
        }
        log(t('log_reboot_effect'), 'warn');
      } else if (key === 'system_props') {
        updateLoading((nv ? t('loading_applying_sysprops') : t('loading_disabling_sysprops')));
        var rsp = await API.toggleSystemProps(nv);
        if (rsp.status === 'ok') {
          logAction(t(nv ? 'log_sysprops_enabled' : 'log_sysprops_disabled'), 'ok');
        } else {
          logAction(tf('log_sysprops_failed', rsp.message || ''), 'err');
        }
        log(t('log_reboot_effect'), 'warn');
      } else if (key === 'gms_doze') {
        if (nv) {
          updateLoading(t('loading_applying_gms_doze'));
          await API.applyGmsDoze();
          logAction(t('log_gms_doze_applied'), 'ok');
        } else {
          updateLoading(t('loading_reverting_gms_doze'));
          await API.revertGmsDoze();
          logAction(t('log_gms_doze_reverted'), 'ok');
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
      }

      toast(tkey(key) + ': ' + (nv ? t('toast_on') : t('toast_off')), 'ok');
      logAction(tf(nv ? 'log_toggle_on' : 'log_toggle_off', tkey(key)), 'ok');

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
        toast('Level: ' + level, 'ok');
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
    } catch (e) { toast('Error', 'err'); }
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
      var allPrefs = ['kernel_tweaks', 'system_props', 'blur_disable', 'log_killing', 'ram_optimizer', 'gms_doze', 'deep_doze'];
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
      var rsp = await API.toggleSystemProps(1);
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

      // Step 8: Apply RAM optimizer
      await yieldFrame(t('loading_applying_ram'));
      var rram = await API.applyRamOptimizer();
      if (rram.status === 'ok') logAction(t('log_ram_applied'), 'ok');

      // Step 9: Apply GMS Doze
      await yieldFrame(t('loading_applying_gms_doze'));
      await API.applyGmsDoze();
      logAction(t('log_gms_doze_applied'), 'ok');

      // Step 10: Apply Deep Doze
      await yieldFrame(t('loading_applying_deep_doze'));
      await API.applyDeepDoze();
      logAction(t('log_deep_doze_applied'), 'ok');

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
      var allPrefs = ['kernel_tweaks', 'system_props', 'blur_disable', 'log_killing', 'ram_optimizer', 'gms_doze', 'deep_doze'];
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
      var rsp2 = await API.toggleSystemProps(0);
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

      // Step 7: Revert RAM optimizer
      await yieldFrame(t('loading_reverting_ram'));
      var rram2 = await API.revertRamOptimizer();
      if (rram2.status === 'ok') logAction(t('log_ram_reverted'), 'ok');

      // Step 8: Revert GMS Doze
      await yieldFrame(t('loading_reverting_gms_doze'));
      await API.revertGmsDoze();
      logAction(t('log_gms_doze_reverted'), 'ok');

      // Step 9: Revert Deep Doze
      await yieldFrame(t('loading_reverting_deep_doze'));
      await API.revertDeepDoze();
      logAction(t('log_deep_doze_reverted'), 'ok');

      toast(t('toast_reverted'), 'ok');
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
    $('wl-modal').classList.add('open');
    if (!wlLoaded) {
      renderWlLoading();
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
  }

  function closeWhitelist() {
    $('wl-modal').classList.remove('open');
  }

  function renderWlLoading() {
    var list = $('wl-list');
    if (list) list.innerHTML = '<div class="wl-empty">' + t('wl_loading') + '</div>';
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
        var raw = await API.run("pm list packages -3 2>/dev/null | cut -d: -f2 | sort");
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
      img.dataset.src = 'ksu://icon/' + app.pkg;
      img.onerror = function () { this.style.visibility = 'hidden'; };

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
      chk.textContent = isWl ? '✓' : '';

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

      // ── In-place update: toggle every rendered row for this pkg ──
      if (list) {
        var rows = list.querySelectorAll('.wl-item[data-pkg="' + pkg + '"]');
        for (var i = 0; i < rows.length; i++) {
          if (isWl) {
            rows[i].classList.remove('active');
            rows[i].querySelector('.wl-chk').textContent = '';
          } else {
            rows[i].classList.add('active');
            rows[i].querySelector('.wl-chk').textContent = '✓';
          }
        }
      }

      // ── Update top selected section without touching scroll position ──
      if (list) {
        var sep = list.querySelector('.wl-sep');
        if (isWl) {
          // Removing: delete duplicate row from top section if present
          var topRows = list.querySelectorAll('.wl-item[data-pkg="' + pkg + '"]');
          // If there's a separator, the first match above it is the top copy
          if (sep && topRows.length > 1) {
            for (var j = 0; j < topRows.length; j++) {
              if (topRows[j].compareDocumentPosition(sep) & Node.DOCUMENT_POSITION_FOLLOWING) {
                topRows[j].remove();
                break;
              }
            }
          }
          // If no more selected apps, remove separator
          var remaining = list.querySelectorAll('.wl-item.active');
          if (sep && remaining.length === 0) sep.remove();
        } else {
          // Adding: insert a copy at the top (before separator or at start)
          var appData = null;
          for (var k = 0; k < wlFiltered.length; k++) {
            if (wlFiltered[k].pkg === pkg) { appData = wlFiltered[k]; break; }
          }
          if (appData) {
            var newRow = document.createElement('div');
            newRow.className = 'wl-item active';
            newRow.dataset.pkg = pkg;

            var img = document.createElement('img');
            img.className = 'wl-ico';
            img.decoding = 'async';
            img.dataset.pkg = pkg;
            if (wlIconCache && wlIconCache.has(pkg) && wlIconCache.get(pkg) !== 'err') {
              img.src = wlIconCache.get(pkg);
            } else {
              img.dataset.src = 'ksu://icon/' + pkg;
              img.onerror = function () { this.style.visibility = 'hidden'; };
              if (wlIconObserver) wlIconObserver.observe(img);
            }

            var infoDiv = document.createElement('div');
            infoDiv.className = 'wl-app';
            var nameSpan = document.createElement('span');
            nameSpan.className = 'wl-name';
            nameSpan.textContent = appData.label;
            infoDiv.appendChild(nameSpan);
            if (appData.label !== appData.pkg) {
              var pkgSpan = document.createElement('span');
              pkgSpan.className = 'wl-pkg';
              pkgSpan.textContent = appData.pkg;
              infoDiv.appendChild(pkgSpan);
            }

            var chk = document.createElement('span');
            chk.className = 'wl-chk';
            chk.textContent = '✓';

            newRow.appendChild(img);
            newRow.appendChild(infoDiv);
            newRow.appendChild(chk);

            // Ensure separator exists
            if (!sep) {
              sep = document.createElement('div');
              sep.className = 'wl-sep';
              sep.setAttribute('data-i18n', 'wl_sep_other');
              sep.textContent = t('wl_sep_other') || 'Other apps';
              list.insertBefore(sep, list.firstChild);
            }
            list.insertBefore(newRow, sep);
          }
        }
      }

    } catch (e) {
      toast(tf('log_load_failed', e.message), 'err');
    }
  }

  function updateWlCount() {
    var el = $('wl-count');
    if (el) el.textContent = wlPkgs.length;
  }

  // ── Polling ──

  function startPolling() {
    stopPolling();
    // Skip poll if an operation is in progress
    pollTimer = setInterval(function () {
      if (!busy) loadPrefs();
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

  // ── Event Binding ──


  async function openAbout() {
    $('about-modal').classList.add('open');
    try {
      var raw = await API.run('cat /data/adb/modules/Frosty/module.prop 2>/dev/null');
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
        importBtn.title = 'Import';
        importBtn.addEventListener('click', (function(path) { return async function() {
          importBtn.disabled = true;
          var ok = await API.importSettings(path);
          if (ok) { $('io-modal').classList.remove('open'); await loadPrefs(); toast(t('toast_imported'), 'ok'); }
          else { toast(t('toast_import_failed'), 'err'); importBtn.disabled = false; }
        }; })(b.path));
        var delBtn = document.createElement('button'); delBtn.className = 'io-item-del ripple';
        delBtn.innerHTML = '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zm2.46-7.12 1.41-1.41L12 12.59l2.12-2.12 1.41 1.41L13.41 14l2.12 2.12-1.41 1.41L12 15.41l-2.12 2.12-1.41-1.41L10.59 14l-2.13-2.12zM15.5 4l-1-1h-5l-1 1H5v2h14V4z"/></svg>';
        delBtn.title = 'Delete';
        delBtn.addEventListener('click', (function(path, el) { return async function() {
          delBtn.disabled = true;
          await API.run('rm -f "' + path + '"');
          el.remove();
          var remaining = $('io-list').querySelectorAll('.io-item').length;
          if (!remaining) $('io-list').innerHTML = '<div class="io-empty">' + t('io_empty') + '</div>';
        }; })(b.path, item));
        var renameBtn = document.createElement('button'); renameBtn.className = 'io-item-rename ripple';
        renameBtn.innerHTML = '<svg viewBox="0 0 24 24" width="15" height="15" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04a1 1 0 0 0 0-1.41l-2.34-2.34a1 1 0 0 0-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>';
        renameBtn.title = 'Rename';
        renameBtn.addEventListener('click', (function(path, spanEl, bObj) { return function() {
          var dir = path.substring(0, path.lastIndexOf('/') + 1);
          var curName = spanEl.textContent;
          var newName = window.prompt('Rename backup:', curName);
          if (!newName || newName === curName) return;
          var newPath = dir + 'frosty_' + newName.replace(/[\/\:*?"<>|]/g, '_') + '.json';
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

  function bind() {
    $('btn-freeze').addEventListener('click', applyFreeze);
    $('btn-stock').addEventListener('click', applyStock);
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
      if (rp.log_killing)   _steps.push('loading_killing_logs');
      if (hasAnyCat)        _steps.push('loading_freezing_services');
      if (rp.gms_doze)      _steps.push('loading_applying_gms_doze');
      if (rp.deep_doze)     _steps.push('loading_applying_deep_doze');
      var _total = _steps.length, _cur = 0;

      function stepLoad(key) {
        _cur++;
        updateLoading('[' + _cur + '/' + _total + '] ' + t(key));
        return new Promise(function(r) { requestAnimationFrame(function() { setTimeout(r, 0); }); });
      }

      function yieldFrame(msg) {
        updateLoading(msg);
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
          var rsp = await API.toggleSystemProps(1);
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

        if (hasAnyCat) {
          await stepLoad('loading_freezing_services');
          var res = await API.applyFreeze();
          if (res.status === 'ok') {
            logAction(tf('log_gms_frozen', res.disabled, res.enabled, res.failed),
              res.failed > 0 ? 'warn' : 'ok');
          }
        }

        if (rp.gms_doze) {
          await stepLoad('loading_applying_gms_doze');
          await API.applyGmsDoze();
          logAction(t('log_gms_doze_applied'), 'ok');
        }

        if (rp.deep_doze) {
          await stepLoad('loading_applying_deep_doze');
          await API.applyDeepDoze();
          logAction(t('log_deep_doze_applied'), 'ok');
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

    // ── System Tweaks ──
    $('t-kernel').addEventListener('change', function () { togglePref('kernel_tweaks'); });
    $('t-sysprops').addEventListener('change', function () { togglePref('system_props'); });
    $('t-blur').addEventListener('change', function () { togglePref('blur_disable'); });
    $('t-logs').addEventListener('change', function () { togglePref('log_killing'); });
    $('t-ram-optimizer').addEventListener('change', function () { togglePref('ram_optimizer'); });
    $('t-gms-doze').addEventListener('change', function () { togglePref('gms_doze'); });
    $('t-deep-doze').addEventListener('change', function () { togglePref('deep_doze'); });
    document.querySelectorAll('.tgl-row, .cat-row').forEach(function (row) {
      row.addEventListener('click', function (e) {
        if (e.target.closest('.tgl')) return;
        var chk = row.querySelector('input[type="checkbox"]');
        if (chk) chk.click();
      });
    });

    // ── Doze ──
    $('lvl-mod').addEventListener('click', function () { setDozeLevel('moderate'); });
    $('lvl-max').addEventListener('click', function () { setDozeLevel('maximum'); });

    $('wl-open').addEventListener('click', openWhitelist);
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

    // ── GMS Categories ──
    var cats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
    cats.forEach(function (cat) {
      var el = $('t-' + cat);
      if (el) el.addEventListener('change', function () { toggleCategory(cat); });
    });

    // ── Miscellaneous ──
    $('btn-dexopt').addEventListener('click', async function () {
      showLoading(tf('executing', t("cat_dexopt")));
      try {
        await API.executeDexOpt();
        log(tf('log_executed', t("cat_dexopt")), 'ok');
        toast(tf('log_executed', t("cat_dexopt")), 'ok');
      } catch (e) {
        log(tf('log_execution_failed', e.message), 'err');
        toast(tf('log_execution_failed', e.message), 'err');
      }
      hideLoading();
    });

    // ── Activity Log ──
    $('btn-copy-log').addEventListener('click', function () {
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
    $('btn-clear-log').addEventListener('click', function () {
      localLogs = [];
      var box = $('log-box');
      if (box) box.innerHTML = '';
    });
    $('btn-expand-log').addEventListener('click', function () {
      $('log-box').classList.toggle('expanded');
      this.classList.toggle('expanded');
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

    // ── Import / Export ──
    $('menu-io').addEventListener('click', function () {
      dropdown.classList.remove('open');
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
      openLang();
    });
    $('lang-close').addEventListener('click', function () {
      $('lang-modal').classList.remove('open');
    });
    $('lang-modal').addEventListener('click', function (e) {
      if (e.target === this) this.classList.remove('open');
    });

    // ── About ──
    $('menu-about').addEventListener('click', function () {
      dropdown.classList.remove('open');
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

    // Pause polling when app is backgrounded, resume when foregrounded
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) stopPolling();
      else startPolling();
    });
  }

  // ── Init ──

  async function init() {
    // if (!API.available()) {
    //   $('app').innerHTML =
    //     '<div class="card" style="margin-top:60px;text-align:center;padding:30px">' +
    //     '<div style="font-size:2rem;margin-bottom:12px">⚠️</div>' +
    //     '<h2 style="font-size:1rem;margin-bottom:6px">' + t('ksu_unavailable_title') + '</h2>' +
    //     '<p style="color:var(--text-dim);font-size:.82rem">' + t('ksu_unavailable_desc') + '</p></div>';
    //   return;
    // }

    await initLang();

    bind();

    await loadPrefs();
    startPolling();

    log(t('log_webui_ready'), 'ok');

    try {
      var wl = await API.getWhitelist();
      wlPkgs = wl.packages || [];
      updateWlCount();
    } catch (e) {}
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
      var ids = ['wl-modal', 'about-modal', 'io-modal', 'lang-modal', 'lang-confirm-backdrop'];
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
      if ((appEl ? appEl.scrollTop : window.scrollY) === 0) {
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
    // Remove [unresolved] so body fades in cleanly after styles are ready
    document.body.removeAttribute('unresolved');
    init();
  });
})();