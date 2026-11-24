import { initGhostFibers } from './ghost-fibers.js';

(function () {
  'use strict';

  const fibersEl = document.getElementById('ghostFibersBg');
  if (fibersEl) {
    initGhostFibers(fibersEl, {
      glowColor: '#ffffff',
      lineColor: '#ffffff',
      secondaryColor: '#555555',
      layers: 3,
      twist: 1.2,
      threads: 72,
      fiberStyle: 'dots',
      depthOfField: 0.85,
      hoverEffect: 'focus',
      intro: true,
      mouseInteraction: true,
      pulseOnClick: true,
      glow: 0.55,
      brightness: 0.72,
      vignette: 0.45,
      grain: 0.05
    });
  }

  const REPO_API_BASE = 'https://api.github.com/repos/saurabh222007/sumic';
  const FALLBACK_RELEASE_URL = 'https://github.com/saurabh222007/sumic/releases/latest';
  let latestDownloadUrl = FALLBACK_RELEASE_URL;

  function setUser(user) {
    localStorage.setItem('sumic_user', JSON.stringify(user));
    document.body.classList.add('fade-leaving');
    setTimeout(() => {
      window.location.href = '/';
    }, 180);
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

  // Cycling label below SUMIC: Tracks -> Playlists -> Music
  function initBrandCycle() {
    const el = document.getElementById('heroBrandCycle');
    if (!el) return;
    const words = ['Tracks', 'Playlists', 'Music'];
    let idx = 0;

    setInterval(() => {
      el.classList.add('switching');
      setTimeout(() => {
        idx = (idx + 1) % words.length;
        el.textContent = words[idx];
        el.classList.remove('switching');
      }, 220);
    }, 2200);
  }

  function applyDownloadUrl(url, tag) {
    latestDownloadUrl = url || FALLBACK_RELEASE_URL;
    ['apkDownloadBtn', 'navGetAppBtn'].forEach(id => {
      const el = document.getElementById(id);
      if (el) el.href = latestDownloadUrl;
    });
    if (tag) {
      const versionEl = document.getElementById('apkVersionTag');
      if (versionEl) versionEl.textContent = tag;
    }
  }

  async function fetchLatestApk() {
    try {
      const response = await fetch(`${REPO_API_BASE}/releases/latest`);
      if (!response.ok) return;
      const data = await response.json();
      if (!data) return;
      const apkAsset = Array.isArray(data.assets)
        ? data.assets.find(a => a.name && a.name.endsWith('.apk'))
        : null;
      const targetUrl = apkAsset?.browser_download_url || data.html_url || FALLBACK_RELEASE_URL;
      applyDownloadUrl(targetUrl, data.tag_name || '');
    } catch {
      // Keep fallback release URL
    }
  }

  async function fetchGitHubRepoInfo() {
    try {
      const response = await fetch(REPO_API_BASE);
      if (!response.ok) return;
      const data = await response.json();
      if (!data) return;

      const starEl = document.getElementById('ghStarCount');
      if (starEl && typeof data.stargazers_count === 'number') {
        starEl.textContent = data.stargazers_count.toLocaleString();
      }

      const descEl = document.getElementById('ghRepoDesc');
      if (descEl && data.description) {
        descEl.textContent = data.description;
      }
    } catch {
      // Keep fallback GitHub card values
    }
  }

  ['apkDownloadBtn', 'navGetAppBtn'].forEach(id => {
    const btn = document.getElementById(id);
    if (!btn) return;
    btn.addEventListener('click', async (e) => {
      if (latestDownloadUrl === FALLBACK_RELEASE_URL) {
        e.preventDefault();
        await fetchLatestApk();
        window.open(latestDownloadUrl, '_blank', 'noopener');
      }
    });
  });

  initBrandCycle();
  fetchLatestApk();
  fetchGitHubRepoInfo();
})();
