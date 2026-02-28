// 🧊 FROSTY - WebUI App

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

  var $ = function (id) { return document.getElementById(id); };

  function esc(s) {
    var d = document.createElement('span');
    d.textContent = s;
    return d.innerHTML;
  }

  // ── Version ──
  function setVersion() {
    var el = $('version-badge');
    if (!el) return;
    API.run('grep "^version=" /data/adb/modules/Frosty/module.prop 2>/dev/null | cut -d= -f2')
      .then(function (v) {
        el.textContent = v ? 'v' + v.trim() : '';
      })
      .catch(function () { el.textContent = ''; });
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
    }, 2400);
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
    var o = $('loading-overlay'), t = $('loading-txt');
    if (t) t.textContent = txt || 'Processing...';
    if (o) o.classList.add('on');
    document.body.style.overflow = 'hidden';
  }

  function updateLoading(txt) {
    var t = $('loading-txt');
    if (t) t.textContent = txt || 'Processing...';
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
      log('Load failed: ' + e.message, 'err');
    }
  }

  function render() {
    var p = state.prefs || {};
    var c = state.categories || {};
    var st = state.state || 'unknown';

    var badge = $('state-badge');
    if (badge) {
      badge.className = 'state-badge ' + (st === 'frozen' ? 'frozen' : st === 'stock' ? 'stock' : 'unknown');
      badge.textContent = st === 'frozen' ? '🧊 FROZEN' : st === 'stock' ? '🔥 STOCK' : '— UNKNOWN';
    }

    setChk('t-kernel', p.kernel_tweaks);
    setChk('t-blur', p.blur_disable);
    setChk('t-logs', p.log_killing);
    setChk('t-sysprops', p.system_props);
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
    showLoading((nv ? 'Enabling' : 'Disabling') + ' ' + fmtKey(key) + '...');

    try {
      var res = await API.setPref(key, nv);
      if (res.status !== 'ok') { toast(res.message || 'Failed', 'err'); hideLoading(); busy = false; return; }

      if (key === 'kernel_tweaks') {
        if (nv) {
          updateLoading('Applying kernel tweaks...');
          var r = await API.applyTweaks();
          if (r.status === 'ok') logAction('Kernel: ' + r.applied + ' applied, ' + r.failed + ' failed', r.failed > 0 ? 'warn' : 'ok');
        } else {
          updateLoading('Reverting kernel...');
          var r2 = await API.revertTweaks();
          if (r2.status === 'ok') logAction('Kernel: ' + r2.restored + ' restored', 'ok');
        }
      } else if (key === 'blur_disable') {
        updateLoading('Applying blur settings...');
        var rb = await API.applyBlur();
        if (rb.status === 'ok') {
          logAction('Blur ' + rb.blur, 'ok');
          if (rb.message) log(rb.message, 'warn');
        }
      } else if (key === 'log_killing') {
        if (nv) {
          updateLoading('Killing log processes...');
          var rl = await API.killLogs();
          if (rl.status === 'ok') logAction('Killed ' + rl.killed + ' log processes', 'ok');
        }
        log('Reboot needed for log ' + (nv ? 'killing' : 'restore') + ' to take effect', 'warn');
      } else if (key === 'system_props') {
        updateLoading((nv ? 'Enabling' : 'Disabling') + ' system props...');
        var rsp = await API.toggleSystemProps(nv);
        if (rsp.status === 'ok') {
          logAction('System props ' + (nv ? 'enabled' : 'disabled') + ' (' + rsp.action + ')', 'ok');
        } else {
          logAction('System props toggle failed: ' + (rsp.message || ''), 'err');
        }
        log('Reboot required for system prop changes to take effect', 'warn');
      } else if (key === 'gms_doze') {
        if (nv) {
          updateLoading('Applying GMS Doze...');
          await API.applyGmsDoze();
          logAction('GMS Doze applied', 'ok');
        } else {
          updateLoading('Reverting GMS Doze...');
          await API.revertGmsDoze();
          logAction('GMS Doze reverted', 'ok');
        }
      } else if (key === 'deep_doze') {
        if (nv) {
          updateLoading('Applying Deep Doze...');
          await API.applyDeepDoze();
          logAction('Deep Doze applied', 'ok');
        } else {
          updateLoading('Reverting Deep Doze...');
          await API.revertDeepDoze();
          logAction('Deep Doze reverted', 'ok');
        }
      }

      toast(fmtKey(key) + ': ' + (nv ? 'ON' : 'OFF'), 'ok');
      logAction(fmtKey(key) + ' ' + (nv ? 'enabled' : 'disabled'), 'ok');

      // Update local state and re-render without a shell round-trip
      state.prefs[key] = nv;
      render();
    } catch (e) {
      toast('Error: ' + e.message, 'err');
      log('Error: ' + e.message, 'err');
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
    showLoading((nv ? 'Freezing' : 'Unfreezing') + ' ' + fmtKey(cat) + '...');

    try {
      var res = await API.setPref(cat, nv);
      if (res.status !== 'ok') { toast(res.message || 'Failed', 'err'); hideLoading(); busy = false; return; }

      if (nv) {
        var fr = await API.freezeCategory(cat);
        if (fr.status === 'ok') {
          logAction(fmtKey(cat) + ': ' + fr.disabled + ' disabled, ' + fr.failed + ' failed', fr.failed > 0 ? 'warn' : 'ok');
          toast(fmtKey(cat) + ' frozen', 'ok');
        }
      } else {
        var uf = await API.unfreezeCategory(cat);
        if (uf.status === 'ok') {
          logAction(fmtKey(cat) + ': ' + uf.enabled + ' re-enabled, ' + uf.failed + ' failed', uf.failed > 0 ? 'warn' : 'ok');
          toast(fmtKey(cat) + ' restored', 'ok');
        }
      }

      // Update local state and re-render without a shell round-trip
      state.categories[cat] = nv;
      render();
    } catch (e) {
      toast('Error: ' + e.message, 'err');
      log('Error: ' + e.message, 'err');
      await loadPrefs();
    }
    hideLoading();
    busy = false;
  }

  // ── Doze Level ──

  async function setDozeLevel(level) {
    if (busy) return;
    busy = true;
    showLoading('Setting doze level: ' + level + '...');
    try {
      var res = await API.setPref('deep_doze_level', level);
      if (res.status === 'ok') {
        toast('Level: ' + level, 'ok');
        logAction('Deep Doze → ' + level, 'info');

        if (state.prefs.deep_doze) {
          updateLoading('Re-applying Deep Doze...');
          await API.applyDeepDoze();
          logAction('Deep Doze re-applied', 'ok');
        }

        // Update local state and re-render without a shell round-trip
        state.prefs.deep_doze_level = level;
        render();
      }
    } catch (e) { toast('Error', 'err'); }
    hideLoading();
    busy = false;
  }

  // ── Freeze All ──

  async function applyFreeze() {
    if (busy) return;
    busy = true;
    showLoading('Enabling all settings...');
    log('Freeze All: enabling everything...', 'info');

    try {
      // Step 1: Turn ON all prefs
      updateLoading('Enabling all toggles...');
      var allPrefs = ['kernel_tweaks', 'system_props', 'blur_disable', 'log_killing', 'gms_doze', 'deep_doze'];
      for (var i = 0; i < allPrefs.length; i++) {
        await API.setPref(allPrefs[i], 1);
      }
      logAction('All system toggles enabled', 'ok');

      // Step 2: Turn ON all categories
      updateLoading('Freezing GMS categories...');
      var allCats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
      for (var j = 0; j < allCats.length; j++) {
        await API.setPref(allCats[j], 1);
      }
      logAction('All GMS categories enabled', 'ok');

      // Step 3: Freeze GMS services
      updateLoading('Freezing GMS services...');
      var res = await API.applyFreeze();
      if (res.status === 'ok') {
        logAction('GMS: ' + res.disabled + ' disabled, ' + res.enabled + ' re-enabled, ' + res.failed + ' failed',
          res.failed > 0 ? 'warn' : 'ok');
      }

      // Step 4: Apply kernel tweaks
      updateLoading('Applying kernel tweaks...');
      var rk = await API.applyTweaks();
      if (rk.status === 'ok') logAction('Kernel: ' + rk.applied + ' applied', rk.failed > 0 ? 'warn' : 'ok');

      // Step 5: Enable system props (rename .old → system.prop if needed)
      updateLoading('Enabling system props...');
      var rsp = await API.toggleSystemProps(1);
      if (rsp.status === 'ok') logAction('System props: ' + rsp.action, 'ok');

      // Step 6: Disable blur
      updateLoading('Disabling blur...');
      var rb = await API.applyBlur();
      if (rb.status === 'ok') logAction('Blur ' + rb.blur, 'ok');

      // Step 7: Kill logs (RC/bin changes take effect on next reboot via post-fs-data.sh)
      updateLoading('Killing log processes...');
      var rl = await API.killLogs();
      if (rl.status === 'ok') logAction('Killed ' + rl.killed + ' log processes', 'ok');

      // Step 8: Apply GMS Doze
      updateLoading('Applying GMS Doze...');
      await API.applyGmsDoze();
      logAction('GMS Doze applied', 'ok');

      // Step 9: Apply Deep Doze
      updateLoading('Applying Deep Doze...');
      await API.applyDeepDoze();
      logAction('Deep Doze applied', 'ok');

      toast('Everything frozen & applied', 'ok');
      log('Reboot recommended for full effect', 'warn');
      await loadPrefs();
    } catch (e) {
      toast('Error: ' + e.message, 'err');
      log('Error: ' + e.message, 'err');
    }
    hideLoading();
    busy = false;
  }

  // ── Revert All ──

  async function applyStock() {
    if (busy) return;
    busy = true;
    showLoading('Reverting everything...');
    log('Revert All: disabling everything...', 'info');

    try {
      // Step 1: Turn OFF all prefs
      updateLoading('Disabling all toggles...');
      var allPrefs = ['kernel_tweaks',  'system_props', 'blur_disable', 'log_killing', 'gms_doze', 'deep_doze'];
      for (var i = 0; i < allPrefs.length; i++) {
        await API.setPref(allPrefs[i], 0);
      }
      logAction('All system toggles disabled', 'ok');

      // Step 2: Turn OFF all categories
      updateLoading('Disabling all categories...');
      var allCats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
      for (var j = 0; j < allCats.length; j++) {
        await API.setPref(allCats[j], 0);
      }
      logAction('All GMS categories disabled', 'ok');

      // Step 3: Revert kernel FIRST (before frosty.sh stock backup)
      updateLoading('Restoring kernel values...');
      var rk = await API.revertTweaks();
      if (rk.status === 'ok') logAction('Kernel: ' + rk.restored + ' values restored', rk.restored > 0 ? 'ok' : 'warn');

      // Step 4: Disable system props (rename system.prop → .old)
      updateLoading('Disabling system props...');
      var rsp2 = await API.toggleSystemProps(0);
      if (rsp2.status === 'ok') logAction('System props: ' + rsp2.action, 'ok');

      // Step 5: Re-enable all GMS services
      updateLoading('Re-enabling GMS services...');
      var res = await API.applyStock();
      if (res.status === 'ok') {
        logAction('GMS: ' + res.enabled + ' re-enabled, ' + res.failed + ' failed',
          res.failed > 0 ? 'warn' : 'ok');
      }

      // Step 6: Revert blur
      updateLoading('Restoring blur...');
      await API.applyBlur();
      logAction('Blur restored', 'ok');

      // Step 7: Revert GMS Doze
      updateLoading('Reverting GMS Doze...');
      await API.revertGmsDoze();
      logAction('GMS Doze reverted', 'ok');

      // Step 8: Revert Deep Doze
      updateLoading('Reverting Deep Doze...');
      await API.revertDeepDoze();
      logAction('Deep Doze reverted', 'ok');

      toast('Everything reverted to stock', 'ok');
      log('Reboot recommended for RC/bin changes to take effect', 'warn');
      await loadPrefs();
    } catch (e) {
      toast('Error: ' + e.message, 'err');
      log('Error: ' + e.message, 'err');
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
    if (list) list.innerHTML = '<div class="wl-empty">Loading apps...</div>';
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
          var src = img.dataset.src;
          if (src) {
            img.src = src;
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
      list.innerHTML = '<div class="wl-empty">No apps found</div>';
      return;
    }

    wlRendered = 0;
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
          sep.textContent = 'Other apps';
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
      renderWl();
      var list = $('wl-list');
      if (list) list.scrollTop = 0;
    } catch (e) {
      toast('Error: ' + e.message, 'err');
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

  function bind() {
    $('btn-freeze').addEventListener('click', applyFreeze);
    $('btn-stock').addEventListener('click', applyStock);

    $('t-kernel').addEventListener('change', function () { togglePref('kernel_tweaks'); });
    $('t-sysprops').addEventListener('change', function () { togglePref('system_props'); });
    $('t-blur').addEventListener('change', function () { togglePref('blur_disable'); });
    $('t-logs').addEventListener('change', function () { togglePref('log_killing'); });
    $('t-gms-doze').addEventListener('change', function () { togglePref('gms_doze'); });
    $('t-deep-doze').addEventListener('change', function () { togglePref('deep_doze'); });
    document.querySelectorAll('.tgl-row, .cat-row').forEach(function (row) {
      row.addEventListener('click', function (e) {
        if (e.target.closest('.tgl')) return;
        var chk = row.querySelector('input[type="checkbox"]');
        if (chk) chk.click();
      });
    });

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

    var cats = ['telemetry', 'background', 'location', 'connectivity', 'cloud', 'payments', 'wearables', 'games'];
    cats.forEach(function (cat) {
      var el = $('t-' + cat);
      if (el) el.addEventListener('change', function () { toggleCategory(cat); });
    });

    $('gh-btn').addEventListener('click', function (e) {
      e.preventDefault();
      try { API.run('am start -a android.intent.action.VIEW -d "https://github.com/Drsexo/Frosty"'); }
      catch (err) { window.open('https://github.com/Drsexo/Frosty', '_blank'); }
    });

    $('log-clear-btn').addEventListener('click', function () {
      localLogs = [];
      var box = $('log-box');
      if (box) box.innerHTML = '';
    });

    $('log-expand-btn').addEventListener('click', function () {
      $('log-box').classList.toggle('expanded');
      this.classList.toggle('expanded');
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
          toast('Log copied', 'ok');
        }).catch(function () {
          toast('Copy failed', 'err');
        });
      } else {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.style.cssText = 'position:fixed;opacity:0;top:0;left:0';
        document.body.appendChild(ta);
        ta.focus(); ta.select();
        try { document.execCommand('copy'); toast('Log copied', 'ok'); }
        catch (e) { toast('Copy failed', 'err'); }
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
    if (!API.available()) {
      $('app').innerHTML =
        '<div class="card" style="margin-top:60px;text-align:center;padding:30px">' +
        '<div style="font-size:2rem;margin-bottom:12px">⚠️</div>' +
        '<h2 style="font-size:1rem;margin-bottom:6px">KSU API Not Available</h2>' +
        '<p style="color:var(--text-dim);font-size:.82rem">This WebUI requires KernelSU.<br>For Magisk/APatch, use the Action button or WebUI-X.</p></div>';
      return;
    }

    bind();

    setVersion();
    await loadPrefs();
    startPolling();

    log('WebUI ready', 'ok');

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
      var m = document.getElementById('wl-modal');
      return m && m.classList.contains('open');
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
      if (dist > threshold && !busy) { loadPrefs(); toast('Refreshed', 'ok'); }
    }, { passive: true });
  })();
  document.addEventListener('DOMContentLoaded', function () {
    // Remove [unresolved] so body fades in cleanly after styles are ready
    document.body.removeAttribute('unresolved');
    init();
  });
})();