// PFCL Hallway TV Showcase Controller (Single-Slide Unified Presentation)
(function() {
  'use strict';

  document.documentElement.classList.add('has-showcase-js');

  const DURATION_MS = 12000; // 12 seconds per slide
  const RELOAD_INTERVAL_MS = 30 * 60 * 1000; // 30 minutes silent refresh

  const slides = Array.from(document.querySelectorAll('.showcase-slider > .showcase-slide'));

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

  // Randomize slide order per page load (re-shuffled on the 30-min reload).
  function shuffleSlides() {
    for (let i = slides.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [slides[i], slides[j]] = [slides[j], slides[i]];
    }
  }

  function showSlide() {
    if (slides.length === 0) return;

    slides.forEach((slide, i) => {
      slide.classList.toggle('is-active', i === currentIndex);
    });

    const activeSlide = slides[currentIndex];
    if (!activeSlide) return;

    if (categoryBadge) {
      categoryBadge.textContent = activeSlide.dataset.category || 'SHOWCASE';
    }
    if (counterEl) {
      counterEl.textContent = `Slide ${currentIndex + 1} of ${slides.length}`;
    }

    startTime = Date.now();
  }

  function nextSlide() {
    if (slides.length === 0) return;
    currentIndex = (currentIndex + 1) % slides.length;
    showSlide();
  }

  function prevSlide() {
    if (slides.length === 0) return;
    currentIndex = (currentIndex - 1 + slides.length) % slides.length;
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
    if (elapsed >= DURATION_MS) {
      nextSlide();
    } else {
      animationFrameId = requestAnimationFrame(tick);
    }
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

  // Click anywhere to toggle pause (unless clicking an interactive link)
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
  shuffleSlides();
  showSlide();
  tick();
})();
