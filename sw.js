// FRPL Service Worker — caches app shell + perfume catalogue
const CACHE = 'frpl-v2';
const PRECACHE = [
  './FRPL.dc.html',
  './data/catalogue-manifest.json',
  './data/perfumes.0.json',
  './data/perfumes.1.json',
  './data/perfumes.2.json',
  './data/perfumes.3.json',
  './data/perfumes.4.json',
  './data/perfumes.5.json',
  './data/perfumes.6.json',
  './data/perfumes.7.json',
  './assets/frpl-logo.png',
  './assets/icon-192.png',
  './assets/icon-512.png',
  './manifest.json'
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(PRECACHE)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  // Network-first for Supabase API calls
  if (e.request.url.includes('supabase.co')) {
    e.respondWith(fetch(e.request).catch(() => new Response('{}', { headers: { 'Content-Type': 'application/json' } })));
    return;
  }
  // Cache-first for everything else
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(res => {
        if (!res || res.status !== 200 || res.type === 'opaque') return res;
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return res;
      });
    })
  );
});
