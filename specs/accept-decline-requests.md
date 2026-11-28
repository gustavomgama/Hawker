## Goal

The hawker screen lists the stops waiting for an answer, each with accept and decline,
and both answers take effect on that page without a reload.

## Non-goals

Route ordering view and stop counts (`TASK.md` next item), notifications, streaming
between devices, any guard on the hawker screen (blocked in `TASK.md`).

## Acceptance checks

- `ruby bin/rails test test/controllers/stops_controller_test.rb` → accepts a requested
  stop, declines a requested stop, refuses a second answer, each `0 failures`.
- `ruby bin/rails test test/controllers/hawkers_controller_test.rb` → the screen lists
  requested stops only, `0 failures`.
- `ruby bin/ci` → `EXIT=0`.

## Files expected to change

`config/routes.rb` (`stops` gains `update`), `app/controllers/stops_controller.rb`,
`app/views/stops/update.turbo_stream.erb`,
`app/controllers/hawkers_controller.rb` (`@requests`),
`app/views/hawkers/_request.html.erb`, `app/views/hawkers/show.html.erb`,
`app/assets/stylesheets/application.css`, both controller tests, `AGENTS.md`.

## Impact

`StopsController#update` is new, so nothing existing can break. `show` gains one
instance variable the view alone reads. `resources :stops, only: %i[create update]`
keeps `stops_path` and adds `stop_path(id)`, which nothing else uses.

## Risks

`accept!`/`decline!` already exist and raise `Stop::InvalidTransition`; the controller
turns that into `409` so a stale page cannot answer twice. The hawker screen stays
unguarded, unchanged from the previous iteration.
