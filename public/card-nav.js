let isHamburgerOpen = false;
let isExpanded = false;
let navTl = null;

function calculateHeight() {
  const navEl = document.getElementById('cardNav');
  if (!navEl) return 260;

  const isMobile = window.matchMedia('(max-width: 768px)').matches;
  if (isMobile) {
    const contentEl = document.getElementById('cardNavContent');
    if (contentEl) {
      const wasVisible = contentEl.style.visibility;
      const wasPointerEvents = contentEl.style.pointerEvents;
      const wasPosition = contentEl.style.position;
      const wasHeight = contentEl.style.height;

      contentEl.style.visibility = 'visible';
      contentEl.style.pointerEvents = 'auto';
      contentEl.style.position = 'static';
      contentEl.style.height = 'auto';

      // force reflow
      void contentEl.offsetHeight;

      const topBar = 60;
      const padding = 16;
      const contentHeight = contentEl.scrollHeight;

      contentEl.style.visibility = wasVisible;
      contentEl.style.pointerEvents = wasPointerEvents;
      contentEl.style.position = wasPosition;
      contentEl.style.height = wasHeight;

      return topBar + contentHeight + padding;
    }
  }
  return 260;
}

function createTimeline() {
  const navEl = document.getElementById('cardNav');
  const cards = document.querySelectorAll('#cardNavContent .nav-card');
  if (!navEl) return null;

  gsap.set(navEl, { height: 60, overflow: 'hidden' });
  gsap.set(cards, { y: 50, opacity: 0 });

  const tl = gsap.timeline({ paused: true });

  tl.to(navEl, {
    height: calculateHeight,
    duration: 0.4,
    ease: 'power3.out'
  });

  tl.to(cards, { y: 0, opacity: 1, duration: 0.4, ease: 'power3.out', stagger: 0.08 }, '-=0.1');

  return tl;
}

window.addEventListener('DOMContentLoaded', () => {
  if (typeof gsap !== 'undefined') {
    navTl = createTimeline();
  } else {
    // Wait for GSAP to load if deferred
    window.addEventListener('load', () => {
      if (typeof gsap !== 'undefined') {
        navTl = createTimeline();
      }
    });
  }

  window.addEventListener('resize', () => {
    if (!navTl) return;
    if (isExpanded) {
      const newHeight = calculateHeight();
      gsap.set(document.getElementById('cardNav'), { height: newHeight });
      navTl.kill();
      navTl = createTimeline();
      if (navTl) navTl.progress(1);
    } else {
      navTl.kill();
      navTl = createTimeline();
    }
  });
});

window.S = window.S || {};
window.S.toggleCardNav = function() {
  if (!navTl && typeof gsap !== 'undefined') {
    navTl = createTimeline();
  }
  if (!navTl) return;

  const navEl = document.getElementById('cardNav');
  const hamburger = document.getElementById('hamburgerMenu');

  if (!isExpanded) {
    isHamburgerOpen = true;
    isExpanded = true;
    if (navEl) navEl.classList.add('open');
    if (hamburger) hamburger.classList.add('open');
    navTl.play(0);
  } else {
    isHamburgerOpen = false;
    if (hamburger) hamburger.classList.remove('open');
    navTl.eventCallback('onReverseComplete', () => {
      isExpanded = false;
      if (navEl) navEl.classList.remove('open');
    });
    navTl.reverse();
  }
};
