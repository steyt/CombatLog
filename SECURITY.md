# CombatLog MAX 3.0 — localhost security model

CombatLog treats loopback as a network boundary, not as implicit trust.

## Runtime boundary

The stable build prefers `127.0.0.1:18765` and stores operational state in `data/combatlog.json` beside `CombatLog.exe`.

If 18765 is already occupied by a healthy CombatLog instance, the launcher opens that existing instance. If it is occupied by another process, CombatLog falls back only to another loopback port; it never binds to an external interface.

## Request gates

Every request passes security middleware before application routing:

1. TCP peer must be loopback.
2. `Host` must exactly match the listener address/port.
3. `/api/*` accepts only the method whitelisted for the endpoint.
4. If `Origin` is present, it must match the CombatLog origin.
5. `Sec-Fetch-Site`, when present, may only be `same-origin` or `none`.
6. Every `/api/*` request requires the per-process `X-CombatLog-CSRF` token.
7. POST/DELETE additionally require exact same-origin `Origin`.
8. POST requires `Content-Type: application/json`.

The CSRF token is generated from `crypto/rand` on every start, injected only into the served same-origin page and is never persisted.

## Data reads / DNS rebinding

Exact Host validation blocks DNS-rebinding hostnames. Sensitive read endpoints (`state`, reports, export, lifecycle) require the same process token. `/healthz` is unauthenticated and returns only `ok` so an already-running local instance can be detected without exposing operational data.

## Browser hardening

Responses include CSP with `frame-ancestors 'none'`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Cross-Origin-Resource-Policy: same-origin`, `Cross-Origin-Opener-Policy: same-origin`, `Referrer-Policy: no-referrer` and `Cache-Control: no-store`.

## Backup/import/migration boundary

3.0 accepts schema 18, 19 and 20 imports. A startup database upgrade is guarded by a byte-for-byte pre-migration backup written to `data/backups` before transformation. Import separately creates a backup of the current database before replacement.

A schema-20 database must not be opened by old schema-18 CombatLog 2.9.2. Rollback means stopping 3.0 and restoring the saved schema-18 pre-migration backup.

## Local Windows trust kit

The portable package does not ship a reusable private signing key. `INSTALL_CERT.cmd` creates/uses a non-exportable code-signing key in the current user's certificate store, trusts its public certificate on that workstation and signs the verified local `CombatLog.exe`. `VERIFY.cmd` checks the shipped SHA-256 or a valid locally trusted CombatLog signature.
