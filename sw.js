const CACHE_NAME = 'snapgram-v1';
const OFFLINE_HTML = `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/><title>SNAPGRAM — Offline</title><style>body{font-family:system-ui,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;background:#09090b;color:#fff;text-align:center;padding:24px}button{margin-top:16px;padding:10px 20px;border-radius:12px;border:none;background:#ec4899;color:#fff;font-weight:600;cursor:pointer}</style></head><body><div><h2>You are offline</h2><p>Check your internet connection and try again.</p><button onclick="location.reload()">Retry</button></div></body></html>`;

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => new Response(OFFLINE_HTML, { headers: { 'Content-Type': 'text/html' } }))
    );
  }
});
