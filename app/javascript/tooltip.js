function enableVisibaleTooltips() {
  document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function(element) {
    new bootstrap.Tooltip(element);
  });
}

window.addEventListener('turbo:load', enableVisibaleTooltips);
window.addEventListener('turbo:frame-load', enableVisibaleTooltips);
