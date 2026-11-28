## Goal

A stop on the hawker's route can be marked arrived and then fulfilled from the hawker
screen, and a fulfilled stop leaves the route.

## Non-goals

Dropping a stop by hand (no decided trigger), timing per stop, undo, notifications,
any change to the offline sweep, any guard on the screen.

## Acceptance checks

- `ruby bin/rails test test/controllers/stops_controller_test.rb` → arrived keeps the
  stop on the route, fulfilled removes it, fulfilling before arriving is `409`,
  `0 failures`.
- `ruby bin/rails test test/controllers/hawkers_controller_test.rb` → an accepted stop
  offers arrival, an arrived stop offers fulfilment, `0 failures`.
- `ruby bin/ci` → `EXIT=0`.

## Files expected to change

`app/controllers/stops_controller.rb`, `app/views/hawkers/_workspace.html.erb`,
`app/assets/stylesheets/application.css`, both controller tests, `AGENTS.md`.

## Impact

`StopsController#update` grows two `when` branches on the same `state` param and keeps
answering `400`/`409`, so nothing else changes shape. `#workspace` gains a button per
route row; the route query (`Stop.on_route`) already excludes `fulfilled`, so the row
and the count drop on the same replace. `arrive!`/`fulfill!` already exist and enforce
order themselves.

## Risks

A stale page can offer a button a stop has already left; the model raises
`Stop::InvalidTransition` and the controller answers `409`, so nothing is recorded. The
screen stays unguarded, unchanged.
