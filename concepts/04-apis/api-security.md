# API Security

---

Hardening an API beyond who-can-call-it. Assumes [authentication & authorization](./authentication-and-authorization.md) is in place; this covers the transport, abuse, and input surfaces. See also [API design](./api-design.md).

## 1. Transport — TLS everywhere

**What is TLS?** **TLS (Transport Layer Security)** — the successor to SSL — is the protocol that secures data in transit; **HTTPS is just HTTP over TLS**. It gives three guarantees:
- **Encryption** — data is unreadable to anyone sniffing the wire (defeats eavesdropping).
- **Integrity** — tampering in transit is detected (a MAC on each record).
- **Authentication** — the server proves its identity with an **X.509 certificate** signed by a trusted **CA**, so you know you're talking to the real server (defeats man-in-the-middle).

**The handshake** (before any data): 1) TCP 3-way handshake. 2) **Client Hello** (offers TLS versions + cipher suites) → **Server Hello** (picks them) → server sends its **certificate** (asymmetric public key). 3) **Key exchange** — client verifies the cert; both derive a shared **session key** (RSA: client encrypts a key with the server's public key; modern: **Diffie-Hellman**). 4) Switch to fast **symmetric** encryption for all requests/responses. **mTLS** adds a client certificate so both sides authenticate.

**Hybrid encryption — why both:**

| Type | Used for | Why |
|---|---|---|
| **Asymmetric** (public/private key) | handshake & key exchange | solves key-sharing over an untrusted network, but **slow** |
| **Symmetric** (shared session key) | bulk data | **fast** — one key encrypts *and* decrypts |

**TLS 1.2 → 1.3:** handshake **2-RTT → 1-RTT** (0-RTT on resume); **static RSA removed** (it lacks **forward secrecy** — a leaked private key would decrypt past traffic); **(EC)DHE Diffie-Hellman** now mandatory — both sides compute the same session key without ever sending it.

**In practice:** serve **only over HTTPS/TLS**, redirect HTTP→HTTPS, enforce **HSTS**, and never put secrets/tokens in URLs (they land in logs and history).

## 2. Rate limiting & throttling

Cap requests per client/key/IP to stop abuse, brute-force, and accidental overload; protects the backend and enables fair use.

- Return **429 Too Many Requests** with `Retry-After` + limit headers (`X-RateLimit-Remaining`).
- Algorithms: **token bucket** (bursty), **leaky bucket** (smooth), **fixed/sliding window**.
- Usually enforced at the **API gateway** (§6).

## 3. Input validation

**Never trust client input.** Validate type, length, range, and format on the server; reject unexpected fields.

- Prevents **injection** (SQL/NoSQL/command) — use **parameterized queries**, never string-concatenate.
- Prevents **XSS** — encode/escape output.
- Enforce payload **size limits** and pagination caps to avoid resource-exhaustion.

## 4. Browser-facing concerns

| Risk | What it is | Mitigation |
|---|---|---|
| **CORS** | which origins may call your API from a browser | explicit `Access-Control-Allow-Origin` allowlist (not `*` for credentialed) |
| **CSRF** | browser sends a user's cookies on a forged cross-site request | `SameSite` cookies, CSRF tokens; token-in-header auth avoids it |

## 5. Secrets & data

- Keep API keys/DB creds in a **secrets manager / env vars**, never in code or git.
- **Rotate** keys/tokens; scope to **least privilege**.
- Don't leak internals in errors (no stack traces); log securely (mask PII/tokens).
- Use **non-guessable IDs** (UUIDs) so records can't be enumerated — a [session-01](../../practice/README.md) miss.

## 6. API gateway (the enforcement point)

A gateway in front of services centralizes cross-cutting security: **TLS termination, authN/authZ, rate limiting, request validation, and logging** — so each service doesn't re-implement them. Examples: Kong, AWS API Gateway, NGINX, Apigee.

## 7. One-Paragraph Summary (for quick revision)

API security layers on top of auth. Serve **only over TLS** (+ HSTS; never secrets in URLs). **Rate-limit/throttle** per client and return **429 + Retry-After** (token/leaky bucket, sliding window), usually at the gateway. **Validate all input** server-side and use **parameterized queries** to block injection, encode output against XSS, and cap payload/page sizes. For browsers, lock down **CORS** to an origin allowlist and defend **CSRF** with `SameSite`/tokens. Keep secrets in a **secrets manager**, rotate and least-privilege them, avoid leaking internals in errors, and use **non-guessable UUIDs**. An **API gateway** (Kong, AWS API Gateway, NGINX) is the natural place to enforce TLS, auth, rate limiting, and validation centrally.
