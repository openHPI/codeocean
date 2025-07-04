import { initializeTooltips, destroyTooltips } from './tooltips';

// `turbo:load` is dispatched earlier than the previous `turbolinks:load` event.
// This is causing issues for our migration, since some assets are not fully loaded
// when the event is dispatched. To ensure that the DOM content is fully rendered,
// we use `requestAnimationFrame` to ensures that the DOM content is completely painted
// before dispatching a custom event `turbo-migration:load`.
//
// Further, we need to ensure that the `turbo-migration:load` event is only processed after
// Sprockets has loaded, since it would miss the event otherwise.
//
// We should remove this workaround once we fully migrated to Turbo and dropped Sprockets.

let sprocketsLoaded = false;
const sprocketsLoadQueue = [];
const turboRenderQueue = [];

document.addEventListener('turbo:load', (event) => {
  sprocketsLoaded ? forwardTurboLoad(event) : sprocketsLoadQueue.push(event);
});

// Wait for Sprockets to load before processing queued Turbo events
document.addEventListener('sprockets:load', () => {
  sprocketsLoaded = true;
  flushQueue(sprocketsLoadQueue);
});

// Handle failed form submissions by waiting for `turbo:render` events
document.addEventListener('turbo:submit-end', (event) => {
  if (!event.detail.success) {
    // If the form submission was _not_ successful, we need to re-initialize JavaScript elements.
    // This is necessary since Turbo does not dispatch a `turbo:load` event in this case.
    turboRenderQueue.push(event);
  }
});

document.addEventListener('turbo:render', () => {
  if (sprocketsLoaded) {
    flushQueue(turboRenderQueue);
  } else {
    // In the unlikely case that Sprockets isn't ready yet, we queue the events.
    sprocketsLoadQueue.push(...turboRenderQueue);
    turboRenderQueue.length = 0;
  }
});

function forwardTurboLoad(event) {
  requestAnimationFrame(() => {
    const delayedEvent = new CustomEvent('turbo-migration:load', { detail: { ...event.detail } });
    document.dispatchEvent(delayedEvent);

    initializeTooltips();
  });
}

const flushQueue = (queue) => {
  queue.forEach(forwardTurboLoad);
  queue.length = 0;
};

document.addEventListener('turbo:visit', (event) => {
  destroyTooltips();
})
