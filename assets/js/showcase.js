// PFCL Hallway TV Showcase Controller
(function() {
  'use strict';

  const DURATION_MS = 12000; // 12 seconds per slide
  const RELOAD_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes silent refresh

  const slides = Array.from(document.querySelectorAll('.showcase-slide'));
  const progressBar = document.getElementById('showcase-progress');
  const counterEl = document.getElementById('showcase-counter');
  const categoryBadge = document.getElementById('showcase-category');
  const pauseBadge = document.getElementById('showcase-pause-status');
  const clockEl = document.getElementById('showcase-clock');
  const dateEl = document.getElementById('showcase-date');

  let currentIndex = 0;
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

  function showSlide(index) {
    if (slides.length === 0) return;
    slides.forEach((slide, i) => {
      slide.classList.toggle('is-active', i === index);
    });

    const activeSlide = slides[index];
    if (!activeSlide) return;
    const category = activeSlide.dataset.category || 'SHOWCASE';

    if (categoryBadge) categoryBadge.textContent = category;
    if (counterEl) counterEl.textContent = `Slide ${index + 1} of ${slides.length}`;

    startTime = Date.now();
    if (progressBar) progressBar.style.width = '0%';
  }

  function nextSlide() {
    if (slides.length === 0) return;
    currentIndex = (currentIndex + 1) % slides.length;
    showSlide(currentIndex);
  }

  function prevSlide() {
    if (slides.length === 0) return;
    currentIndex = (currentIndex - 1 + slides.length) % slides.length;
    showSlide(currentIndex);
  }

  function togglePause() {
    if (slides.length === 0) return;
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
  if (slides.length === 0) return;
  showSlide(0);
  tick();
})();
