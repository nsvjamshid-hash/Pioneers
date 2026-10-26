self.addEventListener('install',()=>self.skipWaiting());
self.addEventListener('fetch',e=>{const r=e.request;if(r.method!='GET'||new URL(r.url).origin!=location.origin)return;e.respondWith(fetch(r).then(x=>{const c=x.clone();caches.open('p1').then(k=>k.put(r,c));return x}).catch(()=>caches.match(r)))});
