/* Requisição de Materiais e Serviços · service worker (nota 075)
   - Páginas do próprio site: busca sempre a versão nova na rede; sem rede, usa a última cópia guardada.
   - Dados (Supabase) e bibliotecas externas: nunca guardados aqui (sempre ao vivo). */
const CACHE = "rms-app-v1";
const BASE = ["./", "./index.html", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(BASE)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const r = e.request; if (r.method !== "GET") return;
  const u = new URL(r.url); if (u.origin !== self.location.origin) return;
  e.respondWith(fetch(r).then(resp => { if (resp.ok) { const cp = resp.clone(); caches.open(CACHE).then(c => c.put(r, cp)); } return resp; })
    .catch(() => caches.match(r).then(m => m || (r.mode === "navigate" ? caches.match("./index.html") : undefined))));
});
