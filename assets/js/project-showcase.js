(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    var showcase = document.querySelector('[data-project-showcase]');
    if (!showcase) return;

    var track = showcase.querySelector('[data-showcase-track]');
    var slides = showcase.querySelectorAll('[data-showcase-slide]');
    var prevBtn = showcase.querySelector('[data-showcase-prev]');
    var nextBtn = showcase.querySelector('[data-showcase-next]');
    var dotsContainer = showcase.querySelector('[data-showcase-dots]');

    if (!track || slides.length === 0) return;

    var totalSlides = slides.length;
    var currentIndex = 0;
    var timer = null;
    var intervalMs = 7000;
    var prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    // Build indicator dots
    if (dotsContainer && totalSlides > 1) {
      dotsContainer.innerHTML = '';
      for (var i = 0; i < totalSlides; i++) {
        var dot = document.createElement('button');
        dot.className = 'pfcl-showcase-dot' + (i === 0 ? ' is-active' : '');
        dot.setAttribute('type', 'button');
        dot.setAttribute('aria-label', 'Go to slide ' + (i + 1) + ' of ' + totalSlides);
        dot.dataset.slideIndex = i;
        dot.addEventListener('click', function (e) {
          var targetIndex = parseInt(e.currentTarget.dataset.slideIndex, 10);
          goToSlide(targetIndex);
          resetTimer();
        });
        dotsContainer.appendChild(dot);
      }
    }

    if (totalSlides <= 1) {
      if (prevBtn) prevBtn.style.display = 'none';
      if (nextBtn) nextBtn.style.display = 'none';
      if (dotsContainer) dotsContainer.style.display = 'none';
      return;
    }

    function updateDots(index) {
      if (!dotsContainer) return;
      var dots = dotsContainer.querySelectorAll('.pfcl-showcase-dot');
      dots.forEach(function (dot, idx) {
        if (idx === index) {
          dot.classList.add('is-active');
        } else {
          dot.classList.remove('is-active');
        }
      });
    }

    function goToSlide(index) {
      if (index < 0) {
        index = totalSlides - 1;
      } else if (index >= totalSlides) {
        index = 0;
      }
      currentIndex = index;
      var targetSlide = slides[index];
      if (targetSlide) {
        track.scrollTo({
          left: targetSlide.offsetLeft,
          behavior: prefersReducedMotion ? 'auto' : 'smooth'
        });
      }
      updateDots(currentIndex);
    }

    if (prevBtn) {
      prevBtn.addEventListener('click', function () {
        goToSlide(currentIndex - 1);
        resetTimer();
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener('click', function () {
        goToSlide(currentIndex + 1);
        resetTimer();
      });
    }

    // Synchronize active dot when user scrolls manually
    var scrollDebounce = null;
    track.addEventListener('scroll', function () {
      clearTimeout(scrollDebounce);
      scrollDebounce = setTimeout(function () {
        var scrollLeft = track.scrollLeft;
        var slideWidth = track.clientWidth;
        var detectedIndex = Math.round(scrollLeft / slideWidth);
        if (detectedIndex >= 0 && detectedIndex < totalSlides && detectedIndex !== currentIndex) {
          currentIndex = detectedIndex;
          updateDots(currentIndex);
        }
      }, 50);
    });

    // Auto-advance timer management
    function startTimer() {
      if (prefersReducedMotion || totalSlides <= 1) return;
      stopTimer();
      timer = setInterval(function () {
        goToSlide(currentIndex + 1);
      }, intervalMs);
    }

    function stopTimer() {
      if (timer) {
        clearInterval(timer);
        timer = null;
      }
    }

    function resetTimer() {
      stopTimer();
      startTimer();
    }

    showcase.addEventListener('mouseenter', stopTimer);
    showcase.addEventListener('mouseleave', startTimer);
    showcase.addEventListener('focusin', stopTimer);
    showcase.addEventListener('focusout', startTimer);
    showcase.addEventListener('touchstart', stopTimer, { passive: true });
    showcase.addEventListener('touchend', startTimer, { passive: true });

    startTimer();
  });
})();
