const preview = document.querySelector('#coii-preview');
const navigationModule = document.querySelector('.navigation-module');
const minimapViewport = document.querySelector('.minimap-viewport');
const bearingValue = document.querySelector('#bearing-value');
const bearingNumber = document.querySelector('#bearing-number');
const minimapDistance = document.querySelector('#minimap-distance');
const locationName = document.querySelector('.location-copy strong');
const streetName = document.querySelector('.location-copy small');
const isFiveM = typeof GetParentResourceName === 'function';
const scrambleGlyphs = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789#%&!';

let runtimeScaleMultiplier = 1;
let layoutTimer = 0;
let lastCompassHeading = null;
let compassDialAngle = 0;
let locationWasVisible = false;
let districtTarget = locationName.textContent.trim();
let streetTarget = streetName.textContent.trim();
const scrambleFrames = new Map();

function formatHeading(value) {
  return `${String(Math.round(Number(value)) % 360).padStart(3, '0')}\u00B0`;
}

function formatDistance(meters) {
  const value = Math.max(0, Math.round(Number(meters) || 0));

  if (value <= 0) return '';
  if (value < 1000) return `${value} M`;
  return `${(value / 1000).toFixed(1)} KM`;
}

function setHeading(value) {
  const numericHeading = ((Math.round(Number(value) || 0) % 360) + 360) % 360;
  const heading = formatHeading(numericHeading);

  if (lastCompassHeading === null) {
    compassDialAngle = -numericHeading;
  } else {
    const delta = ((numericHeading - lastCompassHeading + 540) % 360) - 180;
    compassDialAngle -= delta;
  }

  lastCompassHeading = numericHeading;
  navigationModule.style.setProperty('--coii-dial-angle', `${compassDialAngle}deg`);
  navigationModule.style.setProperty('--coii-label-angle', `${-compassDialAngle}deg`);

  bearingNumber.textContent = String(numericHeading).padStart(3, '0');
  bearingValue.setAttribute('aria-label', heading);

}

function setDistance(value) {
  const distance = formatDistance(value);

  minimapDistance.textContent = distance;
  minimapDistance.classList.toggle('is-hidden', !distance);

}

function scrambleText(element, value, duration = 900, delay = 0) {
  const target = String(value || '').toUpperCase();
  const previousFrame = scrambleFrames.get(element);

  if (previousFrame) window.cancelAnimationFrame(previousFrame);
  if (!target) {
    element.textContent = '';
    scrambleFrames.delete(element);
    return;
  }

  const startedAt = performance.now() + delay;
  let lastPhase = -1;
  let lastRevealed = -1;

  const render = (now) => {
    const elapsed = Math.max(0, now - startedAt);
    const progress = Math.min(1, elapsed / duration);
    const revealed = Math.floor(progress * (target.length + 1));
    const phase = Math.floor(elapsed / 45);

    if (phase !== lastPhase || revealed !== lastRevealed) {
      element.textContent = Array.from(target, (character, index) => {
        if (character === ' ') return ' ';
        if (index < revealed) return character;

        const glyphIndex = (index * 17 + phase * 13 + target.length * 7) % scrambleGlyphs.length;
        return scrambleGlyphs[glyphIndex];
      }).join('');

      lastPhase = phase;
      lastRevealed = revealed;
    }

    if (progress < 1) {
      scrambleFrames.set(element, window.requestAnimationFrame(render));
      return;
    }

    element.textContent = target;
    scrambleFrames.delete(element);
  };

  scrambleFrames.set(element, window.requestAnimationFrame(render));
}

function setLocation(district, street, force = false) {
  const nextDistrict = typeof district === 'string' && district ? district : districtTarget;
  const nextStreet = typeof street === 'string' && street ? street : streetTarget;

  if (force || nextDistrict !== districtTarget) {
    districtTarget = nextDistrict;
    scrambleText(locationName, districtTarget, 850);
  }

  if (force || nextStreet !== streetTarget) {
    streetTarget = nextStreet;
    scrambleText(streetName, streetTarget, 950, 55);
  }
}

function updateRuntimeScale() {
  if (!isFiveM) return;

  const resolutionScale = Math.min(window.innerHeight / 1080, window.innerWidth / 1920);
  const scale = Math.max(0.55, Math.min(1.5, resolutionScale * runtimeScaleMultiplier));
  document.documentElement.style.setProperty('--coii-runtime-scale', String(scale));
}

function reportRuntimeLayout() {
  if (!isFiveM) return;

  window.clearTimeout(layoutTimer);
  layoutTimer = window.setTimeout(() => {
    const bounds = minimapViewport.getBoundingClientRect();

    if (bounds.width < 1 || bounds.height < 1) return;

    fetch(`https://${GetParentResourceName()}/layout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({
        left: bounds.left / window.innerWidth,
        top: bounds.top / window.innerHeight,
        width: bounds.width / window.innerWidth,
        height: bounds.height / window.innerHeight
      })
    }).catch(() => {});
  }, 50);
}

function configureRuntime(data) {
  const ui = data.ui || {};

  runtimeScaleMultiplier = Number(ui.scale) || 1;
  document.documentElement.style.setProperty('--coii-runtime-left', `${Number(ui.leftVw) || 2.2}vw`);
  document.documentElement.style.setProperty('--coii-runtime-bottom', `${Number(ui.bottomVh) || 3.2}vh`);
  updateRuntimeScale();
  reportRuntimeLayout();
}

function updateRuntime(data) {
  setHeading(data.heading);
  setDistance(data.distance);
  const visible = data.visible === true;

  setLocation(data.district, data.street, visible && !locationWasVisible);
  locationWasVisible = visible;

  if (data.lighting === 'day' || data.lighting === 'night') {
    preview.dataset.lighting = data.lighting;
  }

  navigationModule.classList.toggle('is-visible', visible);
}

if (isFiveM) {
  document.documentElement.classList.add('is-fivem');
  window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'coii:minimap:configure') configureRuntime(data);
    if (data.action === 'coii:minimap:update') updateRuntime(data);
  });

  window.addEventListener('resize', () => {
    updateRuntimeScale();
    reportRuntimeLayout();
  });

  fetch(`https://${GetParentResourceName()}/ready`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: '{}'
  }).catch(() => {});

  updateRuntimeScale();
  document.fonts.ready.then(reportRuntimeLayout);
}
