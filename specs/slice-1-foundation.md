## Goal

Make the app the Hawker domain and give it the decided state machine, with tests
that prove it. Rename first (decision 4), wire Hotwire (it is installed but inert),
then the first schema. Vertical slice only — no streaming, no routing engine.

## Non-goals

- No websocket position streaming, no map, no push notifications.
- No `positions` table yet: it belongs to the streaming slice, and an unused table is
  not worth committing.
- No payments, catalogue, pin-drop, capacity limits — `docs/product-idea.md` §9.
- No expiry job: `expired` exists in the schema, nothing sets it yet.
- No admin area, no second hawker, no schedule.

## Acceptance checks

- `ruby bin/rails runner "puts Hawker::Application.name"` → `Hawker::Application`
- `ruby bin/rails db:prepare` → creates `hawker_development`
- `ruby bin/rails test` → green, including offline voids requests and drops stops
- `ruby bin/ci` → exit 0
- `ruby bin/rails routes` → customer screen, hawker screen, health check
- Customer page renders "Your hawker is working" while online, "not working" while
  offline, with `<script type="importmap">` present in the HTML

## Files expected to change

`config/application.rb`, `config/database.yml`, `config/cable.yml`, `config/importmap.rb`,
`app/javascript/**`, `app/views/layouts/application.html.erb`, `app/views/pwa/manifest.json.erb`,
`Dockerfile`, `AGENTS.md`, `docs/product-idea.md`, `db/migrate/*`, `app/models/*`,
`app/controllers/*`, `app/views/*`, `test/**`.

## Impact

- The rename touches 17 occurrences across 7 files. No migrations and no models exist,
  so there is no data to lose and no consumer to break.
- `hawker_*` databases replace `driver_tracker_*`; the old databases, if any were ever
  created, are empty and can be dropped.
- `AGENTS.md` §3 inverts: one name for app, module and database, not two.
- Postgres needs credentials before any migration can run (currently blocked).

## Risks

- Local PostgreSQL has no known password, so migrations and tests cannot be verified
  until it is supplied. The schema is written but unproven.
- Wiring importmap adds a JS entrypoint to a layout that had none; if the tag is wrong
  the page still renders but Turbo is dead, which is silent at a glance.
