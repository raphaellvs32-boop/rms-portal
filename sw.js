/* Requisição de Materiais e Serviços · service worker (nota 075)
   - Páginas do próprio site: busca sempre a versão nova na rede; sem rede, usa a última cópia guardada.
   - Dados (Supabase) e bibliotecas externas: nunca guardados aqui (sempre ao vivo). */
const CACHE = "rms-app-v2";
const BASE = ["./", "./index.html", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(BASE)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const r = e.request; if (r.method !== "GET") return;
  const u = new URL(r.url); if (u.origin !== self.location.origin) return;
  e.respondWith(fetch(r).then(resp => { if (resp.ok) { const cp = resp.clone(); caches.open(CACHE).then(c => c.put(r, cp)); } return resp; })
    .catch(() => caches.match(r).then(m => m || (r.mode === "navigate" ? caches.match("./index.html") : undefined))));
});

/* Avisos no celular (nota 087): mostra o aviso mesmo com o app fechado e, ao tocar, abre a tela certa */
self.addEventListener("push", e => {
  let d = {}; try { d = e.data ? e.data.json() : {}; } catch { d = { titulo: "Portal RMS", texto: e.data ? e.data.text() : "" }; }
  e.waitUntil(self.registration.showNotification(d.titulo || "Portal RMS", {
    body: d.texto || "", icon: "./icon-192.png", badge: "./icon-192.png", tag: d.tag || undefined, renotify: !!d.tag,
    data: { url: d.url || "#painel" }, lang: "pt-BR" }));
});
self.addEventListener("notificationclick", e => {
  e.notification.close(); const alvo = new URL("./" + (e.notification.data?.url || ""), self.registration.scope).href;
  e.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(ws => {
    for (const w of ws) { if (w.url.startsWith(self.registration.scope)) { w.navigate ? w.navigate(alvo).catch(()=>{}) : null; return w.focus(); } }
    return self.clients.openWindow(alvo); }));
});
