// Endereço antigo: o portal mudou para https://portal-requisicao-material.github.io/
// Este service worker se desliga e limpa o cache da versão antiga.
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil((async () => {
  for (const k of await caches.keys()) await caches.delete(k);
  await self.registration.unregister();
  for (const c of await self.clients.matchAll({type:'window'})) c.navigate(c.url);
})()));
