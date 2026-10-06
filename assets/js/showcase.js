// PFCL Hallway TV Showcase Controller (Supports Dual-Split & Single-Slide Modes)
(function() {
  'use strict';

  document.documentElement.classList.add('has-showcase-js');

  const DURATION_MS = 12000; // 12 seconds per slide
  const RELOAD_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes silent refresh

  const projectSlides = Array.from(document.querySelectorAll('.showcase-column-projects .showcase-panel-slide, .showcase-column-projects .showcase-slide'));
  const newsSlides = Array.from(document.querySelectorAll('.showcase-column-news .showcase-panel-slide, .showcase-column-news .showcase-slide'));
  const singleSlides = Array.from(document.querySelectorAll('.showcase-slider > .showcase-slide'));

  const progressBar = document.getElementById('showcase-progress');
  const counterEl = document.getElementById('showcase-counter');
  const categoryBadge = document.getElementById('showcase-category');
  const pauseBadge = document.getElementById('showcase-pause-status');
  const clockEl = document.getElementById('showcase-clock');
  const dateEl = document.getElementById('showcase-date');

  const isSplitMode = projectSlides.length > 0 && newsSlides.length > 0;

  let projectIndex = 0;
  let newsIndex = 0;
  let singleIndex = 0;
  let isPaused = false;
  let startTime = Date.now();
  let animationFrameId = null;

  function updateClock() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    if (clockEl) clockEl.textContent = `${hours}:${minutes}:${seconds}`;

    if (dateEl) {
      const options = { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric' };
      dateEl.textContent = now.toLocaleDateString('en-US', options);
    }
  }

  // Randomize slide order per page load (re-shuffled on the 30-min reload).
  function shuffleSlides() {
    if (isSplitMode) {
      for (let i = projectSlides.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [projectSlides[i], projectSlides[j]] = [projectSlides[j], projectSlides[i]];
      }
      for (let i = newsSlides.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [newsSlides[i], newsSlides[j]] = [newsSlides[j], newsSlides[i]];
      }
    } else {
      for (let i = singleSlides.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [singleSlides[i], singleSlides[j]] = [singleSlides[j], singleSlides[i]];
      }
    }
  }

  // Render a per-slide QR code into the slide's [data-qr-target] frame as a scalable SVG.
  function renderQrCodes() {
    if (typeof qrcode !== 'function') return;
    document.querySelectorAll('[data-qr-url]').forEach((slide) => {
      const target = slide.querySelector('[data-qr-target]');
      if (!target || target.childElementCount > 0) return;
      try {
        const qr = qrcode(0, 'M');
        qr.addData(slide.dataset.qrUrl);
        qr.make();
        target.innerHTML = qr.createSvgTag({ cellSize: 4, margin: 0, scalable: true });
      } catch (err) {
        // Degrades gracefully
      }
    });
  }

  function showSlide() {
    if (isSplitMode) {
      projectSlides.forEach((slide, i) => {
        slide.classList.toggle('is-active', i === projectIndex);
      });
      newsSlides.forEach((slide, i) => {
        slide.classList.toggle('is-active', i === newsIndex);
      });

      if (categoryBadge) categoryBadge.textContent = 'PROJECTS & RESEARCH HIGHLIGHTS';
      if (counterEl) {
        counterEl.textContent = `Project ${projectIndex + 1} of ${projectSlides.length}  ·  Update ${newsIndex + 1} of ${newsSlides.length}`;
      }
    } else {
      if (singleSlides.length === 0) return;
      singleSlides.forEach((slide, i) => {
        slide.classList.toggle('is-active', i === singleIndex);
      });
      const activeSlide = singleSlides[singleIndex];
      if (!activeSlide) return;
      if (categoryBadge) categoryBadge.textContent = activeSlide.dataset.category || 'SHOWCASE';
      if (counterEl) counterEl.textContent = `Slide ${singleIndex + 1} of ${singleSlides.length}`;
    }

    startTime = Date.now();
    if (progressBar) progressBar.style.width = '0%';
  }

  function nextSlide() {
    if (isSplitMode) {
      if (projectSlides.length > 0) {
        projectIndex = (projectIndex + 1) % projectSlides.length;
      }
      if (newsSlides.length > 0) {
        newsIndex = (newsIndex + 1) % newsSlides.length;
      }
    } else {
      if (singleSlides.length === 0) return;
      singleIndex = (singleIndex + 1) % singleSlides.length;
    }
    showSlide();
  }

  function prevSlide() {
    if (isSplitMode) {
      if (projectSlides.length > 0) {
        projectIndex = (projectIndex - 1 + projectSlides.length) % projectSlides.length;
      }
      if (newsSlides.length > 0) {
        newsIndex = (newsIndex - 1 + newsSlides.length) % newsSlides.length;
      }
    } else {
      if (singleSlides.length === 0) return;
      singleIndex = (singleIndex - 1 + singleSlides.length) % singleSlides.length;
    }
    showSlide();
  }

  function togglePause() {
    isPaused = !isPaused;
    if (pauseBadge) pauseBadge.style.display = isPaused ? 'inline-block' : 'none';
    if (isPaused) {
      if (animationFrameId) cancelAnimationFrame(animationFrameId);
    } else {
      startTime = Date.now();
      tick();
    }
  }

  function tick() {
    if (isPaused) return;

    const elapsed = Date.now() - startTime;
    const progress = Math.min((elapsed / DURATION_MS) * 100, 100);

    if (progressBar) progressBar.style.width = `${progress}%`;

    if (elapsed >= DURATION_MS) {
      nextSlide();
    }

    animationFrameId = requestAnimationFrame(tick);
  }

  // Key navigation
  window.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === ' ') {
      e.preventDefault();
      nextSlide();
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault();
      prevSlide();
    } else if (e.key === 'p' || e.key === 'P') {
      togglePause();
    }
  });

  // Click to toggle pause
  document.addEventListener('click', (e) => {
    if (e.target.closest('a')) return;
    togglePause();
  });

  // Live clock interval
  updateClock();
  setInterval(updateClock, 1000);

  // Background refresh to pick up fresh builds
  setTimeout(() => {
    window.location.reload();
  }, RELOAD_INTERVAL_MS);

  // Start presentation
  if (!isSplitMode && singleSlides.length === 0) return;
  shuffleSlides();
  renderQrCodes();
  showSlide();
  tick();
})();
