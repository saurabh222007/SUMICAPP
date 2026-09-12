import { initVariableProximity } from './variable-proximity.js';
import { initSoftAurora } from './soft-aurora.js';
import { initTrueFocus } from './true-focus.js';
import { initScrambledText } from './scrambled-text.js';

(function () {
  'use strict';

  // Initialize the premium SoftAurora background with performance‑friendly settings
  initSoftAurora('auroraBg', {
    speed: 0.3,
    scale: 1.2,
    brightness: 0.8,
    color1: '#181818',
    color2: '#262626',
    noiseFrequency: 0.5,
    noiseAmplitude: 0.4,
    bandHeight: 0.5,
    bandSpread: 0.5,
    octaveDecay: 0.15,
    layerOffset: 0.0,
    colorSpeed: 0.6,
    enableMouseInteraction: true,
    mouseInfluence: 0.2
  });

  // Apply a CSS hint to the aurora canvas for smoother compositor handling
  const auroraCanvas = document.getElementById('auroraBg');
  if (auroraCanvas) {
    auroraCanvas.style.willChange = 'transform, opacity';
    auroraCanvas.style.pointerEvents = 'none';
  }

  const isMobileLogin = window.innerWidth <= 1023 || ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);

  if (!isMobileLogin) {
    // Initialize TrueFocus component
    initTrueFocus('trueFocusContainer', {
      sentence: 'music, redefined.',
      separator: ' ',
      manualMode: false,
      blurAmount: 5,
      borderColor: '#D96548',
      glowColor: 'rgba(217, 101, 72, 0.4)',
      animationDuration: 0.5,
      pauseBetweenAnimations: 1.0
    });

    // Initialize ScrambledText component with custom paragraph for sumic streaming app
    initScrambledText('scrambledTextContainer', {
      radius: 100,
      duration: 1.2,
      speed: 0.5,
      scrambleChars: '.:',
      text: 'A late-night listening room built for audiophiles, dreamers, and curators. Pure sound, archival records, and zero distractions.'
    });
  }

  // Initialize VariableProximity on the login page branding
  const brandTitle = document.querySelector('.auth-brand .brand-title');
  if (brandTitle) {
    initVariableProximity(brandTitle, {
      label: 'SUMIC',
      fromFontVariationSettings: "'wght' 300, 'opsz' 8",
      toFontVariationSettings: "'wght' 1000, 'opsz' 40",
      container: document.getElementById('authShell'),
      radius: 220,
      falloff: 'linear'
    });
  }

  // Fluid page transition overlay (CSS lives in styles.css)
  function initFluidPageTransitions() {
    if (document.getElementById('pageTransitionOverlay')) return;

    const overlay = document.createElement('div');
    overlay.id = 'pageTransitionOverlay';
    const blob = document.createElement('div');
    blob.id = 'pageTransitionBlob';
    overlay.appendChild(blob);
    document.body.appendChild(overlay);

    // Reveal the login page by fading out the overlay
    requestAnimationFrame(() => {
      setTimeout(() => {
        overlay.classList.add('fade-out');
        setTimeout(() => { overlay.style.display = 'none'; }, 750);
      }, 100);
    });
  }

  window.triggerPageTransition = function(targetUrl) {
    const overlay = document.getElementById('pageTransitionOverlay');
    if (overlay) {
      overlay.style.display = 'flex';
      overlay.offsetHeight; // force reflow
      overlay.classList.remove('fade-out');
      setTimeout(() => { window.location.href = targetUrl; }, 850);
    } else {
      window.location.href = targetUrl;
    }
  };

  // Run page transitions on load
  initFluidPageTransitions();

  function setUser(user) {
    localStorage.setItem('sumic_user', JSON.stringify(user));
    if (window.triggerPageTransition) {
      window.triggerPageTransition('/');
    } else {
      window.location.href = '/';
    }
  }

  const loginForm = document.getElementById('loginForm');
  const guestBtn = document.getElementById('guestBtn');

  if (loginForm) {
    loginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const name = document.getElementById('userName')?.value?.trim();
      const email = document.getElementById('userEmail')?.value?.trim();
      if (!name && !email) {
        alert('Add your name or email to continue');
        return;
      }
      setUser({ name: name || 'Guest', email: email || '', guest: !email });
    });
  }
  
  if (guestBtn) {
    guestBtn.addEventListener('click', () => {
      setUser({ name: 'Guest', email: '', guest: true });
    });
  }
  // Fetch latest APK download URL and update button
  function fetchLatestApk() {
    fetch('https://api.github.com/repos/saurabh222007/sumic/releases/latest')
      .then(response => response.json())
      .then(data => {
        if (!data || !data.assets) return;
        const apkAsset = data.assets.find(a => a.name && a.name.endsWith('.apk'));
        if (apkAsset && apkAsset.browser_download_url) {
          const btn = document.getElementById('apkDownloadBtn');
          if (btn) btn.href = apkAsset.browser_download_url;
        }
        // Update footer with version info
        if (data.tag_name) {
          const footer = document.querySelector('#loginApkAd .apk-ad-sub');
          if (footer) footer.textContent = 'by Saurabh222007 · ' + data.tag_name;
        }
      })
      .catch(err => console.error('Failed to fetch APK release:', err));
  }
  // Invoke on load
  fetchLatestApk();
})();
