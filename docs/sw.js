// Service worker do "Rifon no Telon". Só cuida do "esqueleto" do app.html
// (a única página instalável) pra abrir rápido e funcionar offline. Os
// dados do sorteio em si (Firestore) NUNCA passam por aqui — sempre
// buscados direto da rede, ao vivo.

const CACHE_NAME = 'rifon-no-telon-v3';
const APP_SHELL = [
  './',
  './app.html',
  './manifest-app.json',
  './index.html',
  './operador.html',
  './logo.png',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((name) => name !== CACHE_NAME)
          .map((name) => caches.delete(name))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Nunca intercepta Firestore/Google APIs — o sorteio tem que ser
  // sempre ao vivo, nunca servido de um cache antigo.
  if (
    url.hostname.includes('googleapis.com') ||
    url.hostname.includes('gstatic.com') ||
    url.hostname.includes('firestore')
  ) {
    return;
  }

  // Só cuida de pedidos do próprio app (mesma origem).
  if (url.origin !== self.location.origin) return;

  // Network-first: tenta buscar a versão mais nova; se não tiver
  // internet, cai pro que já está guardado, pra abrir mesmo offline.
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        const clone = response.clone();
        caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
