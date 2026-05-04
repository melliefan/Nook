// Minimal JS: subtle fade-in on scroll, nothing else.
(function () {
  if (typeof IntersectionObserver === 'undefined') {
    document.querySelectorAll('.reveal').forEach(function (el) {
      el.classList.add('is-visible');
    });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) {
        e.target.classList.add('is-visible');
        io.unobserve(e.target);
      }
    });
  }, { rootMargin: '0px 0px -8% 0px', threshold: 0.05 });

  document.querySelectorAll('.reveal').forEach(function (el) { io.observe(el); });
})();
