# Single Sign-On: SAML, OAuth 2.0 & OIDC

---

**Single Sign-On (SSO)** is the *goal* — one identity used across many apps, without sharing passwords. Three standards get you there; they're easiest to understand as a hierarchy. Builds on [tokens/JWT](./authentication-and-authorization.md).

```
[ SSO ]                        ← the goal: one identity, many apps
   │
   ├──► [ SAML ]               XML protocol — AuthN + AuthZ (enterprise SSO)
   │
   └──► [ OAuth 2.0 ]          REST framework — authorization (delegated access)
             │
             └──► [ OIDC ]     identity layer ON TOP of OAuth 2.0 — AuthN (modern SSO)
```

Two families: **SAML** (a self-contained enterprise SSO protocol) and **OAuth 2.0** (authorization), which **OIDC** extends to provide modern login.

## 1. SAML — enterprise XML SSO

**SAML** (Security Assertion Markup Language) is an older, **XML-based** standard that does **both authentication and authorization**, still dominant in **enterprise**. The **Identity Provider (IdP)** — Okta, ADFS, Azure AD — authenticates the user and sends a signed XML **assertion** to the **Service Provider (SP)**, the app, via browser redirect/POST. The SP trusts the assertion instead of handling a password.

## 2. OAuth 2.0 — delegated authorization

OAuth2 is a **REST framework** for **authorization**: a **client** app accesses a user's resources on a **resource server** **without the password**, using a token from an **authorization server**. It's about *what an app may do*, not login.

**Roles:** **resource owner** (the user) · **client** (the app) · **authorization server** (issues tokens) · **resource server** (the API holding the data).

| Grant / flow | Use |
|---|---|
| **Authorization Code (+ PKCE)** | web/mobile apps acting for a user — the default |
| **Client Credentials** | service-to-service (no user involved) |
| **Refresh Token** | get a new access token when the old one expires |

Issues a short-lived **access token** (sent to APIs as `Authorization: Bearer …`) and a long-lived **refresh token**. Legacy flows (Implicit, Password) are discouraged — use Authorization Code + PKCE.

The **Authorization Code** flow end to end — front-channel authorization via the browser yields a code, which the backend exchanges server-to-server for tokens, then uses the access token to call the resource server:

![OAuth 2.0 Authorization Code flow sequence — client registration, then front-channel authorization request via the browser returning an auth code, back-channel token exchange for access and refresh tokens, and finally using the Bearer access token to call the resource server](./diagrams/oauth2-authorization-code-flow.png)

## 3. OIDC — authentication on top of OAuth 2.0

OAuth2 alone doesn't tell the client **who** logged in. **OIDC** is a thin **identity layer built ON TOP of OAuth 2.0** that adds an **`id_token`** (always a JWT) describing the authenticated user — this powers "**Log in with Google/GitHub**" (modern SSO). OAuth2 = authorization; OIDC = authentication/login.

Both together in one system — the app uses **OIDC** with identity providers (Apple, Google) that issue an **ID token** to log the user in, and **OAuth 2.0** to get **access tokens** for calling third-party APIs (Facebook, LinkedIn) on the user's behalf:

![OIDC and OAuth 2.0 in one architecture — a Learning Management System logs users in via OIDC identity providers such as Apple and Google that issue ID tokens, and separately obtains OAuth 2.0 access tokens to call external APIs such as Facebook and LinkedIn, alongside its own local IAM and datastore](./diagrams/oidc-and-oauth2-architecture.png)

## 4. Access token vs ID token

A common interview point — they are **not** interchangeable:

| | **Access token** | **ID token** |
|---|---|---|
| Answers | *what* the app may do | *who* the user is |
| Spec | OAuth2 | OIDC |
| Audience | the **resource server** (API) | the **client** app |
| Sent to APIs? | **yes** — as a Bearer token | **no** — consumed by the client only |
| Format | opaque **or** JWT | always a **JWT** |

Rule: send the **access token** to APIs; use the **id token** only to establish the user's identity in the client.

## 5. OIDC vs SAML (the two SSO routes)

| | **OIDC** | **SAML** |
|---|---|---|
| Format | JSON / REST (JWT) | XML / SOAP-era |
| Built on | OAuth 2.0 | its own standard |
| Best for | modern web, **mobile, APIs** | **enterprise** web SSO |
| Token | `id_token` (JWT) | XML **assertion** |

Both deliver **SSO/federation**; OIDC is the modern default, SAML is entrenched in enterprise IT.

## 6. One-Paragraph Summary (for quick revision)

**SSO** is the goal — one identity across many apps. **SAML** is a self-contained **XML** protocol doing both authN and authZ (an **IdP** sends a signed **assertion** to an **SP**), dominant in **enterprise**. **OAuth 2.0** is a **REST authorization** framework: a client gets an **access token** (+ refresh token) from an **authorization server** to call a **resource server** on the user's behalf, without the password (use **Authorization Code + PKCE**; Client Credentials for service-to-service). **OIDC** builds **authentication ON TOP of OAuth 2.0** by adding an **`id_token`** (a JWT saying *who* logged in) — the basis of "log in with Google" and modern SSO. Keep the tokens straight: the **access token** goes to APIs (*what you can do*), the **id token** stays in the client (*who you are*). **OIDC vs SAML** = JSON/mobile-friendly vs XML/enterprise-entrenched.
