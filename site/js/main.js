/**
 * Caipora Landing Page - Interactions
 * Native JS. Zero frameworks.
 */

(function () {
  'use strict';

  // ----------------------------------------------------------
  // Nav glassmorphism on scroll
  // ----------------------------------------------------------
  const nav = document.getElementById('nav');
  let navScrolled = false;

  function updateNav() {
    const scrolled = window.scrollY > 20;
    if (scrolled !== navScrolled) {
      nav.classList.toggle('is-scrolled', scrolled);
      navScrolled = scrolled;
    }
  }

  // Use requestAnimationFrame for scroll handling (not on every event)
  let ticking = false;
  window.addEventListener('scroll', function () {
    if (!ticking) {
      window.requestAnimationFrame(function () {
        updateNav();
        ticking = false;
      });
      ticking = true;
    }
  }, { passive: true });

  // Initial check
  updateNav();

  // ----------------------------------------------------------
  // Scroll-reveal via IntersectionObserver
  // ----------------------------------------------------------
  const revealElements = document.querySelectorAll('.section-reveal');

  if ('IntersectionObserver' in window) {
    const revealObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            revealObserver.unobserve(entry.target);
          }
        });
      },
      {
        root: null,
        rootMargin: '0px 0px -60px 0px',
        threshold: 0.1,
      }
    );

    revealElements.forEach(function (el) {
      revealObserver.observe(el);
    });
  } else {
    // Fallback: show all immediately
    revealElements.forEach(function (el) {
      el.classList.add('is-visible');
    });
  }

  // ----------------------------------------------------------
  // Smooth scroll for anchor links (polyfill for older browsers)
  // ----------------------------------------------------------
  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#') return;
      const target = document.querySelector(targetId);
      if (target) {
        e.preventDefault();
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    });
  });
})();
