# CombatLog MAX 3.0 — architecture

## 1. Runtime boundary

3.0 is the stable runtime:

- listener preference: `127.0.0.1:18765`;
- repository: `data/combatlog.json` beside `CombatLog.exe`;
- current schema: **20**;
- import compatibility: schema **18–20**.

Before an on-disk schema upgrade, the exact old JSON bytes are copied to `data/backups/pre_migration_schema<version>_<timestamp>.json`. Migration then proceeds on the working database.

Because 2.9.2 and 3.0 use the same production boundary, they are not intended to run in parallel. A schema-20 database is not readable by schema-18 2.9.2; rollback requires restoring the pre-migration backup.

## 2. Screen/module architecture

`Події` is the home screen and a read-only chronological projection. It owns no second copy of operational records.

Authoritative source modules:
- `Вильоти` — UAV flights and their episodes;
- `Місії` — manual ground missions (NRK implemented; vehicle/group types already exist as data-driven shells);
- position lifecycle events.

Every projected event retains its source kind/id. Editing, deletion and certificate actions occur in the authoritative source module, not in `Події`.

`Події`, `Вильоти` and `Місії` share the same UI contract: collapsible filters, date/time range, time presets, bounded table viewport, compact source row, expandable detail, collapse-all control and collapsible filter-scoped statistics.

`Події` projects UAV episodes as chronological events, but its `Вильотів` statistic counts distinct source flight IDs. Therefore `Подій > Вильотів` is valid and does not mean duplicated flights.

## 3. UAV configuration model

Configuration is data-driven:

`class -> asset -> model -> allowed actions`

A model is catalog data belonging to an asset. It never owns business logic.

### Field catalog

`refs.fields` is the single configurable UAV field catalog. `AssetProfile.FieldConfig` stores the operator choice:
- enabled / disabled;
- placement: `main` / `additional`.

Field conditions use semantic metadata such as action tags/flags. Runtime code must not gate a field by a concrete UAV name, model, asset ID or family.

`AssetProfile.Fields` exists only as a compact compatibility projection for legacy import/parser paths and is regenerated from `FieldConfig`.

### UAV certificates

`refs.certificateTypes` defines exactly three categories:
- `Ураження`;
- `Втрата борту`;
- `Мінування`.

Each asset profile owns its own optional template binding for each category in `AssetProfile.Templates`. Other actions such as reconnaissance or relay may exist operationally but do not create additional UAV certificate categories.

Action-global `defaultTemplateId` / `templateRules` are not runtime routing. They are read only at the schema-18 migration boundary so existing customized templates can be copied into concrete asset-owned templates and the legacy routing discarded.

### Guided flight editor

Manual entry and parser output share one draft editor. Position-driven suggestions are derived from selected date/position, the position configuration and recent operational data: next sortie number, crew, pilot and permitted/recent asset. Suggestions are editable.

Completeness and warning logic is driven by field/action metadata, not concrete asset names.

## 4. Migration chain

### Schema 18 -> 19

The migration:
1. consumes old action/template routing as legacy input only;
2. preserves operator-selected fields into complete `FieldConfig`;
3. creates independent asset-owned template copies;
4. removes action-global template routing;
5. normalizes obsolete fields/dictionaries/aliases.

### Schema 19 -> 20

Schema 20 introduces a universal mission point for the mission origin.

Legacy `Mission.PositionID` / `Mission.Position` are converted into `Mission.Origin` and then cleared. `Mission.Origin` and every `Mission.RoutePoint` use the same structure:

- linked named position: `PositionID` + historical `PositionSnapshot` + canonical display name;
- custom place: free `Name` without a position entity.

Old stock NRK mission templates are migrated from a hardcoded `ВП НРК «{{ position }}»` fragment to the universal `{{ originText }}` placeholder.

## 5. Mission point semantics

A mission normally starts at an NRK field position, but this is a default workflow, not a data constraint.

A point can be:
1. any existing CombatLog position; or
2. arbitrary free text.

Named positions are canonical identifiers and render uppercase according to their point kind, e.g. `ВП НРК «ГВИНТИК»` or `ЗПМ «ПРАДА»`.

Free-text places preserve operator casing exactly, e.g. `позиції, що облаштовується` or `район завантаження`. They may be remembered in the route-place reference list, but are never silently turned into inventory/position entities.

If typed text exactly matches a known position name/point name/PDP/canonical label, it resolves to that position and receives a server-owned historical snapshot.

## 6. NRK mission model

NRK remains separate from UAV flights and is not parsed from pilot messages.

One `Mission` covers start -> result plus optional later clarification/evacuation events. The module records operational facts required for reports, not an inventory of physical NRK boards.

Dedicated catalogs hold NRK models, pilots, navigators, team members, cargo and remembered free route places. S/N, Starlink and loss geo live only in the loss snapshot when the mission result requires them.

Mission `status` is lifecycle only: `active`, `followup`, `completed`. Outcome and equipment state are separate facts.

## 7. Normalization policy

Uppercase is a property of canonical named domains, not of every text input.

Uppercase-normalized domains include pilot/call-sign catalogs, crews/groups, named positions and settlements. Reference catalogs opt into uppercase through `RefData.Uppercase`.

Free narrative/location text is preserved unless its field/catalog explicitly requires uppercase. Runtime logic must not enumerate concrete names to decide casing.

## 8. Persistence / backup

`Події` is derived and is never duplicated in storage.

Normal writes remain atomic. Canonical exports scrub obsolete/transitional duplicates while preserving authoritative snapshots. Import creates a backup before replacing the current database. Startup schema migration creates a raw pre-migration backup before any transformation.

## 9. Security

Listener is loopback-only. Every API request passes exact Host checks, Origin/fetch-site validation and a random per-process CSRF token. Unsafe methods require same-origin Origin and JSON content type. `/healthz` is the only unauthenticated dynamic endpoint and exposes no operational data.
