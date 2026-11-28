## Goal

The hawker app can post a position; the customer's answer to "where is the
hawker" is a stored ping. Positions never outlive the working day: going offline
deletes all of them. `solid_queue` and `solid_cable` are wired for production so
the pruning job is durable and the availability stream works in production.

## Non-goals

- No customer-facing map or position display (item 19, blocked on the paused-state
  question).
- No routing, no reverse geocoding, no history view.
- No `solid_cache` wiring.
- No retention window in hours; the user chose "until the hawker goes offline".

## Acceptance checks

- `ruby bin/rails test` → `52 runs, 197 assertions, 0 failures`, including:
  a ping while broadcasting is stored and answers `204`; a ping without
  credentials answers `401`; a ping while paused answers `409` and writes
  nothing; an out-of-range coordinate answers `422`; going offline enqueues
  `PrunePositionsJob` and leaves `Position` empty.
- `ruby bin/rails db:migrate` → `CreatePositions: migrated`.
- `ruby bin/ci` → exit `0`.

## Files expected to change

- `db/migrate/20261128041500_create_positions.rb`, `db/schema.rb`
- `app/models/position.rb`, `app/models/hawker_profile.rb`
- `app/controllers/positions_controller.rb`, `config/routes.rb`
- `app/jobs/prune_positions_job.rb`
- `config/environments/production.rb`, `config/cable.yml`, `config/queue.yml`,
  `config/recurring.yml`, `db/queue_schema.rb`, `db/cable_schema.rb`, `bin/jobs`
- tests: `test/controllers/positions_controller_test.rb`,
  `test/jobs/prune_positions_job_test.rb`, `test/models/hawker_profile_test.rb`
- `AGENTS.md`, `TASK.md`, `docs/product-idea.md`

## Risks

- A ping while paused is refused rather than recorded: matches "position stops
  updating", but a client that keeps sending gets `409` instead of silence.
- Pruned only on going offline, so a hawker who never goes offline keeps every
  ping of the day. Bounded by one day of movement; acceptable.
- Production `db:prepare` now builds three databases; a role without rights on
  `hawker_production_queue`/`_cable` fails at container start.
