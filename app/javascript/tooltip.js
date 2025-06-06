const tooltipMap = new WeakMap();

function manageTooltips() {
  const selector = '[data-bs-toggle="tooltip"]';
  const currentElements = new Set(document.querySelectorAll(selector));

  // Dispose tooltips for elements no longer in the DOM
  for (const [element, tooltipInstance] of tooltipMap.entries()) {
    if (!currentElements.has(element)) {
      tooltipInstance.dispose();
      tooltipMap.delete(element);
    }
  }

  // Initialize tooltips for new elements
  currentElements.forEach((element) => {
    if (!tooltipMap.has(element)) {
      const instance = new bootstrap.Tooltip(element);
      tooltipMap.set(element, instance);
    }
  });
}

window.addEventListener('turbo:load', manageTooltips);
window.addEventListener('turbo:frame-load', manageTooltips);
