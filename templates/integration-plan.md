<!-- The main agent writes this before api-integrator or integration-verifier run.
     Save as docs/integrations/<provider>-plan.md. Builders refuse to start until Status is APPROVED. -->
# Integration plan: <provider or service>

Status: DRAFT | APPROVED (by the user, <date>)
Stack: <flutter | react-next | react-native | swift | pytorch-ml | docker>   Platforms: <ios, android, web, server, ...>

## Purpose
<one paragraph: what the product needs from this service, and which features use it>

## Auth
- Flow: <OAuth 2.0 + PKCE (public client) | OAuth confidential (server) | API key (server only) | service account | none>
- Client IDs per platform and environment: <table or "see config">
- Redirect URIs / URL schemes per platform: <list>
- Scopes, each with the feature that needs it, requested incrementally at: <point of use>
- Token storage per platform: <Keychain / Keystore / SecureStore / httpOnly cookie / server vault>
- Refresh: <who refreshes, when; on 401: one refresh, then re-auth>
- Sign-out and revocation: <what is cleared>

## Endpoints and contracts
| Operation | Method + path / SDK call | Request | Response fields used | Pagination | Our DTO / type |
| --- | --- | --- | --- | --- | --- |

## Errors, limits and retries
- Error mapping: <provider error → domain failure>
- Rate limits: <documented quota>; retry 429/5xx with exponential backoff + jitter, honoring `Retry-After`; never retry 4xx auth blindly.
- Timeouts: <connect / read>

## Configuration and secrets
| Value | Where it lives per environment | Secret? |
| --- | --- | --- |
Secrets never go in the repo or the client. Name the env vars, CI secrets and platform files (Info.plist, AndroidManifest, entitlements, app.json/eas.json, .env.local, compose secrets) that change.

## Data handling
<PII fields, what is stored, retention, what must never be logged>

## Verification checklist (integration-verifier runs every item)
- [ ] <config item: e.g. iOS URL scheme matches reversed client ID> → evidence: <file or command>
- [ ] <console/portal item for the user: e.g. Android SHA-1 for the upload key registered>
- [ ] Smoke test: sign in → one read call → forced refresh → sign out, per platform
- [ ] No secrets in repo: `git grep -nIE "client_secret|api[_-]?key|BEGIN PRIVATE KEY"`

## Slices
<ordered list of work orders for api-integrator, with files per slice>

## Open decisions
<anything still undecided; the plan cannot be APPROVED with open decisions>
