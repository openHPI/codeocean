let tooltipList = [];

export function initializeTooltips() {
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
}

export function destroyTooltips() {
  tooltipList.map(tooltip => tooltip.dispose());
  tooltipList = [];
}
