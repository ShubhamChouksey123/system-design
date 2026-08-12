# HTTP — Methods, Status Codes & Headers

---

**HTTP (HyperText Transfer Protocol)** is the protocol under most APIs. A **request** (method + path + headers + body) gets a **response** (status code + headers + body) — the shared vocabulary for [API design](./api-design.md), [REST](./rest.md), and [gRPC](./grpc.md) (which runs on HTTP/2). HTTPS is HTTP over **TLS** (encrypted).

## 1. Methods

| Method | Purpose | Safe? | Idempotent? |
|---|---|:---:|:---:|
| `GET` | Read a resource | ✅ | ✅ |
| `HEAD` | Like GET, headers only (no body) | ✅ | ✅ |
| `OPTIONS` | Discover allowed methods / CORS preflight | ✅ | ✅ |
| `POST` | Create; non-idempotent action | ❌ | ❌ |
| `PUT` | Create/replace at a known URI | ❌ | ✅ |
| `PATCH` | Partial update | ❌ | ❌ |
| `DELETE` | Remove a resource | ❌ | ✅ |

- **Safe** = no server-side change (read-only). **Idempotent** = repeating it has the same effect as once — critical for **safe retries** (make `POST` idempotent with an `Idempotency-Key`).

## 2. Status codes

Five classes: **1xx** informational, **2xx** success, **3xx** redirect, **4xx** client error, **5xx** server error.

> 📺 Quick explainer: [HTTP status codes (YouTube)](https://youtu.be/qmpUfWN7hh4?si=KcXcGAivs-I3_7fb)

| Code | One-line meaning |
|---|---|
| **1xx — informational** | request received, still processing |
| `100 Continue` | headers OK, client may send the body |
| `101 Switching Protocols` | upgrading (e.g. to WebSocket) |
| **2xx — success** | the request worked |
| `200 OK` | success, response has a body |
| `201 Created` | resource created (often with a `Location`) |
| `202 Accepted` | accepted for **async** processing, not done yet |
| `204 No Content` | success, no body (e.g. after a `DELETE`) |
| **3xx — redirect** | go elsewhere |
| `301 Moved Permanently` | resource moved for good — update links (SEO/cache) |
| `302 Found` | temporary redirect — keep using the original URL |
| `304 Not Modified` | cached copy is still valid (used with `ETag`) |
| **4xx — client error** | your request is wrong |
| `400 Bad Request` | malformed syntax / invalid input |
| `401 Unauthorized` | not **authenticated** (who are you?) |
| `403 Forbidden` | authenticated but **not allowed** |
| `404 Not Found` | resource doesn't exist |
| `409 Conflict` | conflicts with current state (e.g. duplicate) |
| `422 Unprocessable Entity` | syntax OK but **semantically** invalid (validation) |
| `429 Too Many Requests` | rate limit hit — back off (`Retry-After`) |
| **5xx — server error** | the server failed |
| `500 Internal Server Error` | generic server-side failure |
| `502 Bad Gateway` | upstream returned an invalid response |
| `503 Service Unavailable` | overloaded / down — retry later |
| `504 Gateway Timeout` | upstream didn't respond in time |

- **401 vs 403**: 401 = *not authenticated* (who are you?); 403 = *authenticated but not allowed*.
- **301 vs 302**: permanent (cache/SEO update) vs temporary. Return **3xx** for redirects, not 200.

## 3. Headers

| Direction | Header | Purpose |
|---|---|---|
| Request | `Authorization` | credentials (Bearer token, API key) |
| Request | `Content-Type` | format of the body sent |
| Request | `Accept` | format the client wants back |
| Request | `Cookie`, `User-Agent` | session, client info |
| Response | `Content-Type` | format of the body returned |
| Response | `Cache-Control`, `ETag` | caching + revalidation (see [caching](../caching.md)) |
| Response | `Location` | URI of a created/redirected resource |
| Response | `Set-Cookie` | set a session cookie |
| Response | `Access-Control-Allow-Origin` | **CORS** — which origins may call |
| Response | `Retry-After` | when to retry (with `429`/`503`) |

## 4. Content negotiation

The client sends `Accept: application/json`; the server replies with a matching `Content-Type`. Lets one endpoint serve JSON, XML, or different **API versions** via an `Accept` header.

## 5. One-Paragraph Summary (for quick revision)

HTTP carries a **request** (method + path + headers + body) and a **response** (status + headers + body). **Methods**: `GET/HEAD/OPTIONS` are safe; `GET/PUT/DELETE` are **idempotent** (safe to retry), `POST/PATCH` are not (add an `Idempotency-Key`). **Status codes** group into 2xx success, 3xx redirect, 4xx client error, 5xx server error — know `201/204`, `301 vs 302`, `401 vs 403`, `404`, `409`, `429`, `500/503`. **Headers** carry metadata: `Authorization`, `Content-Type`/`Accept` (content negotiation), `Cache-Control`/`ETag` (caching), `Location`, `Set-Cookie`, CORS, `Retry-After`. HTTP also has multiple versions (1.0 → 3) — see [HTTP versions](./http-versions.md).
