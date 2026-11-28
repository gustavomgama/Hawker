## Goal

The customer screen flips between "working" and "not working" without a reload when the
hawker goes online or offline.

## Non-goals

- No live route, no position, no presence.
- Pausing does not change the customer screen: `working?` is availability, not broadcasting.
- Wiring `solid_cable` for production stays out of scope.

## Acceptance checks

- `ruby bin/rails test test/models/hawker_profile_test.rb` → broadcasts on availability change, none on pause
- `ruby bin/rails test test/controllers/home_controller_test.rb` → page subscribes to the stall stream
- `ruby bin/ci` → exit 0

## Files expected to change

- `app/models/hawker_profile.rb`: broadcast the stall after an availability change
- `app/views/home/index.html.erb`: subscribe to the stream
- `app/views/home/_stall.html.erb`: new, the re-rendered fragment
- `test/models/hawker_profile_test.rb`, `test/controllers/home_controller_test.rb`

## Impact

- `HomeController#index` renders the partial instead of inline markup; no route or param change.
- `HawkerProfile#go_online!`/`go_offline!` broadcast after commit; `scan`/tests that assert
  no extra behaviour are unaffected because the test adapter records rather than sends.
- Development uses the async cable adapter; production cable is already unwired and undeployed.

## Risks

- A broadcast render failure would raise inside `after_commit` and roll back nothing but
  surface as a 500 on the toggle; the test renders the partial through the same path.
