// Manually clear Turbo cache when a specific meta tag is present.
// This is required to ensure privacy compliance on shared devices once the user logs out.

document.addEventListener('turbo:load', () => {
  const turboCacheMeta = document.head.querySelector("meta[name='custom-turbo-cache'][content='clear']");
  if (turboCacheMeta) {
    Turbo.cache.clear();
  }
});
