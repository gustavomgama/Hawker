## Goal

The hawker screen shows the accepted stops in `sequence` order and a count of what is
waiting versus what is on the route, and an answer redraws both without a reload.

## Non-goals

Arrive/fulfil (next item), reordering or drag, map, ETAs, per-stop timing, any guard.

## Acceptance checks

- `ruby bin/rails test test/controllers/hawkers_controller_test.rb` → the route renders
  in sequence order (not creation order) with the counts, `0 failures`.
- `ruby bin/rails test test/controllers/stops_controller_test.rb` → accept and decline
  answer with a `replace` stream for `#workspace`, `0 failures`.
- `ruby bin/ci` → `EXIT=0`.

## Files expected to change

`app/views/hawkers/_workspace.html.erb` (new), `app/views/hawkers/show.html.erb`,
`app/controllers/hawkers_controller.rb`, `app/controllers/stops_controller.rb`,
`app/assets/stylesheets/application.css`, both controller tests, `AGENTS.md`.

## Impact

`StopsController#update` stops rendering `turbo_stream.remove` for a single row and
replaces `#workspace` instead, so the previous DOM id target is gone; the request row
id (`dom_id(stop)`) is still what the request list renders, now inside the workspace.
Nothing else reads those ids.

## Risks

The whole workspace re-renders on every answer, including the request list: cheap at
this size, and the only way the counts cannot drift. If it ever grows past a screenful,
switch to append/replace per region rather than keep re-rendering.
