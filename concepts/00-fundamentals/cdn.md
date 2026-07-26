# Content Delivery Network (CDN)

---

A **CDN** is a globally distributed network of **edge servers** that cache content close to users, so requests are served from a nearby edge instead of the distant **origin**. It cuts latency, offloads the origin, and absorbs traffic spikes. Related: [caching](./caching.md).

## 1. Why a CDN?

Physical distance = latency (a round trip across the world is ~150 ms). Serving a user in Tokyo from a US origin is slow and wastes origin capacity. A CDN puts a copy at a **point of presence (PoP)** near the user:

- **Lower latency** — content travels a shorter distance.
- **Origin offload** — the edge absorbs most reads; origin load drops sharply.
- **Scalability & spike absorption** — thousands of edges soak up traffic (flash sales, launches).
- **Availability & DDoS protection** — edges shield the origin and can serve stale on origin failure.

## 2. How it works

```
User ─▶ nearest PoP (edge)
          │  cache HIT  ─▶ serve immediately
          └─ cache MISS ─▶ fetch from Origin ─▶ store at edge (with TTL) ─▶ serve
```

Routing to the nearest edge is done via **anycast** or **DNS-based** geo-routing. Each cached object has a **TTL**; after it expires the edge revalidates with the origin.

## 3. What to cache (and what not)

- **Great fit — static / immutable:** images, video, CSS/JS bundles, fonts, downloads. Cache long; **version the URL** (`app.v3.js` / content hash) so a new deploy = new URL, no stale problem.
- **Possible — semi-dynamic:** API responses / HTML that tolerate short TTLs; personalized or auth'd content is usually **not** cached (or cached per-key with care).
- **Push vs Pull CDN:** **Pull** (lazy) — edge fetches from origin on first miss (default, low effort). **Push** — you upload content to the CDN ahead of time (good for large, known assets like video).

## 4. Invalidation & consistency

The CDN holds copies, so it's **eventually consistent** — an object can be stale until its TTL expires. To push updates sooner:

- **Versioned URLs / cache busting** — the cleanest approach; a changed URL is a guaranteed fresh fetch.
- **Purge / invalidation API** — explicitly evict a path from all edges (slower to propagate, sometimes rate-limited).
- **Cache-Control headers** — `max-age`, `s-maxage`, `no-cache`, `ETag` for revalidation.

## 5. Best practices

- **Version immutable assets** and set long TTLs; never rely on purge as the primary mechanism.
- Set correct **`Cache-Control`** headers; use **`ETag`/`Last-Modified`** for cheap revalidation.
- **Compress** (gzip/Brotli) and serve modern formats (WebP/AVIF); use **HTTP/2/3**.
- Keep a **cache-key** strategy — don't split the cache by needless query params.
- Monitor **cache hit ratio**, edge latency, and origin offload %.

## 6. Real-world CDNs

| CDN | Notes |
|---|---|
| **Cloudflare** | CDN + security/DDoS + edge compute (Workers) |
| **AWS CloudFront** | Integrates with S3 / AWS origins |
| **Akamai** | Oldest, largest edge footprint |
| **Fastly** | Real-time purge, edge compute (VCL) |
| **Google Cloud CDN** | GCP-integrated |

## 7. One-Paragraph Summary (for quick revision)

A **CDN** is a global mesh of **edge servers (PoPs)** that cache content near users, serving from the nearest edge on a **hit** and fetching from the **origin** (then caching with a **TTL**) on a **miss** — routed via anycast/DNS geo-routing. It slashes latency, offloads the origin, absorbs spikes, and shields against DDoS. Cache **static/immutable** assets aggressively and **version their URLs** so a deploy = a new URL (avoiding staleness); avoid caching personalized/auth'd content. Use **pull** (lazy) or **push** (pre-upload) modes. It's **eventually consistent**, so refresh via versioned URLs (best), purge APIs, or `Cache-Control`/`ETag`. Best practice: long TTLs on versioned assets, correct cache headers, compression + HTTP/2/3, a tight cache-key, and monitoring **hit ratio + origin offload**. Major providers: Cloudflare, CloudFront, Akamai, Fastly.
