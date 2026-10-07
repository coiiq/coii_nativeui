(() => {
  'use strict';
  const root = document.getElementById('quick-menu');
  const confirm = document.getElementById('quick-confirm');
  const status = document.getElementById('quick-status');
  const buttons = [...root.querySelectorAll('[data-quick]')];
  const cancel = document.getElementById('quick-cancel');
  const quit = document.getElementById('quick-quit');
  const curtain = document.getElementById('quick-transition');
  const reducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const runtime = typeof GetParentResourceName === 'function';
  if (runtime) document.documentElement.classList.add('is-fivem');
  let session = 0, busy = false, openedAt = 0;
  let generation = 0, curtainTimer;
  function cover(enabled) {
    clearTimeout(curtainTimer);
    curtain.classList.toggle('is-active', enabled && !reducedMotion());
    if (enabled) curtainTimer = setTimeout(() => cover(false), 1800);
  }
  const validUrl = value => { try { const url = new URL(value); return url.protocol === 'https:' && !url.username && !url.password; } catch { return false; } };
  const controls = () => confirm.hidden ? buttons.filter(b => !b.disabled) : [cancel, quit];
  function show(data) {
    generation++;
    root.classList.remove('is-leaving');
    root.hidden = data.visible !== true;
    document.documentElement.classList.toggle('quick-is-open', !root.hidden);
    confirm.hidden = true;
    busy = false;
    if (root.hidden) { if (!data.handoff) cover(false); return; }
    cover(false);
    session = data.session;
    openedAt = performance.now();
    status.textContent = '';
    document.getElementById('quick-title').textContent = data.title || 'Pause menu';
    document.getElementById('quick-brand').textContent = data.brand || 'COII ROLEPLAY';
    document.getElementById('quick-logo').src = typeof data.logo === 'string' && /^[\w./-]+\.png$/i.test(data.logo) && !data.logo.includes('..') ? data.logo : 'logo.png';
    document.getElementById('quick-player').textContent = data.player || 'Player';
    document.getElementById('quick-location').textContent = data.district || 'San Andreas';
    const website = buttons.find(b => b.dataset.quick === 'website');
    website.disabled = !validUrl(data.website);
    website.setAttribute('aria-label', website.disabled ? 'Website (not configured)' : 'Website');
    root.scrollTop = 0;
    root.scrollLeft = 0;
    buttons[0].focus({ preventScroll: true });
  }
  async function request(action, extra = {}) {
    if (!runtime) return { ok: true };
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3500);
    try {
      const response = await fetch(`https://${GetParentResourceName()}/quickAction`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ action, session, ...extra }), signal: controller.signal });
      if (!response.ok) throw new Error('Request failed');
      return await response.json();
    } finally { clearTimeout(timeout); }
  }
  async function act(action) {
    if (root.hidden || busy) return;
    if (action === 'quit' && confirm.hidden) return;
    const originalSession = session;
    const originalGeneration = generation;
    busy = true;
    try {
      if (['map', 'settings', 'resume'].includes(action) && !reducedMotion()) {
        root.classList.add('is-leaving');
        if (action !== 'resume') cover(true);
        await new Promise(resolve => setTimeout(resolve, 180));
        if (generation !== originalGeneration || session !== originalSession || root.hidden) return;
      }
      const result = await request(action, action === 'quit' ? { confirmed: true } : {});
      if (session !== originalSession) return;
      if (!result.ok) { cover(false); status.textContent = result.error || 'Please try again.'; confirm.hidden = true; buttons[0].focus(); return; }
      if (action === 'prepareQuit') { confirm.hidden = false; cancel.focus(); }
      else if (action === 'cancelQuit') { confirm.hidden = true; buttons.at(-1).focus(); }
      else if (action === 'website' && runtime && validUrl(result.url)) { window.invokeNative('openUrl', result.url); }
      else if (!runtime) { status.textContent = `${action.toUpperCase()} — preview only; no game action executed.`; confirm.hidden = true; buttons[0].focus(); }
    } catch {
      if (session === originalSession) { cover(false); status.textContent = 'Could not reach the game. Press ESC to try resuming.'; confirm.hidden = true; buttons[0].focus(); }
    } finally { if (session === originalSession) { busy = false; root.classList.remove('is-leaving'); if (!runtime) cover(false); } }
  }
  function move(step) {
    const list = controls();
    const index = list.indexOf(document.activeElement);
    list[(index + step + list.length) % list.length].focus();
  }
  function input(key) {
    if (root.hidden || busy || performance.now() - openedAt < 250) return;
    if (key === 'up') move(-1);
    if (key === 'down') move(1);
    if (key === 'back') act(confirm.hidden ? 'resume' : 'cancelQuit');
    if (key === 'accept') (controls().includes(document.activeElement) ? document.activeElement : controls()[0]).click();
  }
  buttons.forEach(button => {
    button.addEventListener('click', () => act(button.dataset.quick));
    button.addEventListener('mouseenter', () => { if (!button.disabled && confirm.hidden && !busy) button.focus({ preventScroll: true }); });
  });
  cancel.addEventListener('click', () => act('cancelQuit'));
  quit.addEventListener('click', () => act('quit'));
  window.addEventListener('keydown', event => {
    if (root.hidden) return;
    if (['Escape', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Enter', ' ', 'Tab'].includes(event.key)) event.preventDefault();
    if (event.repeat) return;
    if (event.key === 'Escape') input('back');
    if (event.key === 'ArrowUp' || event.key === 'ArrowLeft') input('up');
    if (event.key === 'ArrowDown' || event.key === 'ArrowRight') input('down');
    if (event.key === 'Enter' || event.key === ' ') input('accept');
    if (event.key === 'Tab' && !busy) move(event.shiftKey ? -1 : 1);
  });
  window.addEventListener('message', ({ data }) => {
    if (!data || typeof data !== 'object') return;
    if (data.action === 'coii:quick') show(data);
    if (data.action === 'coii:quick:input') input(data.key);
    if (data.action === 'coii:quick:error') status.textContent = data.text || '';
    if (data.action === 'coii:quick:transitionEnd' && data.session === session) cover(false);
  });
  if (runtime) fetch(`https://${GetParentResourceName()}/quickReady`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}' }).catch(() => {});
  else if (new URLSearchParams(location.search).has('quick')) show({ visible: true, session: 1, player: 'coii', district: 'Pillbox Hill' });
})();
