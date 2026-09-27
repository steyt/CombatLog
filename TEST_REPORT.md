# CombatLog MAX 3.0 — test report

Build: **MAX 3.0**  
Schema: **20**  
Production boundary: **127.0.0.1:18765 / data/combatlog.json**  
Date: **2026-08-18**

## Automated test suite

- JavaScript syntax: `web/app.js`, report designer/query/template engines — **PASS**.
- JavaScript regression/contract files: **44 PASS / 0 FAIL**.
- Go named tests/subtests: **142 PASS / 0 FAIL**.
- `go vet ./...` — **PASS**.
- `go test -race ./...` — **PASS**.
- `go test -count=5 ./...` — **PASS**.

## Schema 20 / stable promotion

- Import/decode gate accepts schema **18, 19, 20** and rejects older/future schemas — **PASS**.
- Schema 19 mission `PositionID/Position` migrates into universal `Origin`; legacy fields are cleared — **PASS**.
- Startup schema upgrade writes a **byte-identical** `pre_migration_schema...json` before transforming the working database — **PASS**.
- Stable runtime source contract uses `127.0.0.1:18765` and `data/combatlog.json`; TEST port/data paths are absent — **PASS**.
- Startup ordering claims/detects the production listener **before** `repo.Load()`, preventing a new process from migrating the shared database behind an already-running CombatLog — **PASS**.

## Production-copy migration smoke

The supplied working schema-18 backup was copied into an isolated temporary `data/combatlog.json` and opened through the real repository loader.

- input schema: **18**;
- input flights: **250**;
- input missions: **0**;
- output schema: **20**;
- output flights: **250**;
- output missions: **0**;
- exactly one `pre_migration_schema18_*.json` produced;
- pre-migration backup compared byte-for-byte with the original input — **PASS**.

The source backup contains multiple UAV episodes in some flights; the existing event-projection tests still verify that `Події` may exceed `Вильотів`, while the `Вильотів` statistic counts distinct source-flight IDs.

## NRK mission point model

- A mission may start from the normal NRK position, another named CombatLog position, or free text — **PASS**.
- Linked named positions receive a server-owned historical position snapshot — **PASS**.
- Named position labels remain canonical uppercase, e.g. `ВП НРК «ГВИНТИК»`, `ЗПМ «ПРАДА»` — **PASS**.
- Free-text origin casing is preserved, e.g. `район завантаження` — **PASS**.
- Free-text route casing is preserved, e.g. `позиції, що облаштовується` — **PASS**.
- Free-text places are not silently converted into position inventory entities — **PASS**.
- Remembered custom-place suggestions do not override the casing typed in the current mission — **PASS**.
- Pilot/call-sign normalization remains uppercase — **PASS**.
- Stock NRK start/result/loss templates use the universal `{{ originText }}` placeholder — **PASS**.

## Data-driven / no concrete UAV runtime branches

A runtime source scan excluding seed/test fixtures found no concrete starter UAV names/IDs (`VAMPIRE`, `MATRICE`, `MAVIC`, `AUTEL`, concrete asset IDs, fiber-family IDs) in Go/JS business logic — **PASS**.

Legacy field/model keys remain only at explicit compatibility/migration boundaries where old schema data must be consumed and scrubbed.

## Runtime/build

- Native Linux smoke build started on loopback and `/healthz` returned HTTP 200 with security headers — **PASS**.
- Windows amd64 GUI build (`CGO_ENABLED=0`, `-trimpath`, stripped, `windowsgui`) — **PASS**.

## Packaging checks

Performed after final packaging:

- standalone EXE SHA-256 equals the EXE inside Portable;
- `EXPECTED_SHA256.txt` equals that hash;
- Portable ZIP integrity — PASS;
- Source ZIP integrity — PASS;
- Source ZIP contains no `.exe`, operational database, `data-test`, or backup files.
