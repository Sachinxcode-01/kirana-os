// KiranaOS Service Worker cleanup / unregister handler
// This safely unregisters any legacy or stale service worker cached in the browser

self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    self.registration
      .unregister()
      .then(() => self.clients.matchAll())
      .then((clients) => {
        clients.forEach((client) => {
          if (client.url && "navigate" in client) {
            client.navigate(client.url);
          }
        });
      })
  );
});

// Pass-through fetch handler in case of immediate requests
self.addEventListener("fetch", (event) => {
  event.respondWith(fetch(event.request));
});
