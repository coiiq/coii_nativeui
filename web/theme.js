(() => {
  'use strict';
  function applyAccent(value) {
    const hex = typeof value === 'string' && /^#[\da-f]{6}$/i.test(value) ? value : '#50B7F5';
    const rgb = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
    const style = document.documentElement.style;
    const setRgb = (name, channels) => style.setProperty(name, channels.map(Math.round).join(', '));
    style.setProperty('--coii-accent', hex);
    setRgb('--coii-accent-rgb', rgb);
    setRgb('--coii-accent-selection', rgb.map((v, i) => v * [22/80, 57/183, 91/245][i]));
    setRgb('--coii-accent-light', rgb.map(v => v + (255 - v) * .55));
    style.setProperty('--coii-accent-ink', rgb[0] * .299 + rgb[1] * .587 + rgb[2] * .114 > 145 ? '#08192a' : '#f6f6f3');
  }
  window.addEventListener('message', event => {
    const data = event.data || {};
    if (!['coii:minimap:configure', 'coii:quick'].includes(data.action)) return;
    if (data.accent !== undefined) applyAccent(data.accent);
    if (data.background !== undefined) applyBackground(data.background);
  });
  function applyBackground(value) {
    const hex = typeof value === 'string' && /^#[\da-f]{6}$/i.test(value) ? value : '#0B1320';
    const rgb = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16));
    const light = rgb[0] * .299 + rgb[1] * .587 + rgb[2] * .114 > 145;
    const style = document.documentElement.style;
    style.setProperty('--coii-background', hex);
    style.setProperty('--coii-background-rgb', rgb.join(', '));
    style.setProperty('--coii-background-deep', rgb.map(v => Math.round(v * .6)).join(', '));
    style.setProperty('--coii-background-text', light ? '#111820' : '#f6f6f3');
    style.setProperty('--coii-background-muted', light ? '#33404b' : '#c2d0dc');
  }
  applyAccent('#50B7F5');
  applyBackground('#0B1320');
})();
