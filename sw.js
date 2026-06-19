// FRPL Service Worker — caches app shell + perfume catalogue
const CACHE = 'frpl-v27';
const SUPABASE_JS = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js';
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
  e.waitUntil((async () => {
    const c = await caches.open(CACHE);
    await c.addAll(PRECACHE);
    // Cache the cross-origin Supabase library too (best-effort — never block install).
    try { await c.add(new Request(SUPABASE_JS, { mode: 'cors' })); } catch (_) {}
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// fetch-with-timeout so a flaky network can never hang a navigation forever
function timedFetch(req, ms) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('timeout')), ms);
    fetch(req).then(r => { clearTimeout(t); resolve(r); }, err => { clearTimeout(t); reject(err); });
  });
}

self.addEventListener('fetch', e => {
  const url = e.request.url;

  // Supabase API calls — network only (never cache auth/data); fall back to empty json offline.
  if (url.includes('supabase.co')) {
    e.respondWith(fetch(e.request).catch(() => new Response('{}', { headers: { 'Content-Type': 'application/json' } })));
    return;
  }

  // The Supabase library — cache-first (so reopening offline still boots auth).
  if (url === SUPABASE_JS) {
    e.respondWith(
      caches.match(e.request).then(cached => cached || fetch(new Request(SUPABASE_JS, { mode: 'cors' })).then(res => {
        const clone = res.clone();
        caches.open(CACHE).then(c => c.put(e.request, clone));
        return res;
      }))
    );
    return;
  }

  // App shell (the HTML) — network-first with a short timeout so fresh deploys are picked up,
  // but a slow/offline reopen instantly falls back to the cached copy instead of hanging.
  if (e.request.mode === 'navigate' || url.includes('FRPL.dc.html')) {
    e.respondWith(
      timedFetch(e.request, 3500).then(res => {
        if (res && res.status === 200) {
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return res;
      }).catch(() => caches.match(e.request).then(c => c || caches.match('./FRPL.dc.html')))
    );
    return;
  }

  // Everything else — cache-first.
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
