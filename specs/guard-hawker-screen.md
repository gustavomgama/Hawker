## Goal

Only the hawker can reach the hawker screen and answer stops. Decided by the user: HTTP
basic auth from the environment for now, replacing it with a real login later.

## Non-goals

- No `has_secure_password`, no sessions, no `password_digest` column (item 15 stays open).
- No customer authentication; the customer screen and `StopsController#create` stay open.
- No login page, no logout, no rate limiting.

## Acceptance checks

- `ruby bin/rails test test/controllers/hawkers_controller_test.rb` → 401 without or with wrong credentials, desk with the right ones
- `ruby bin/rails test test/controllers/stops_controller_test.rb` → answering needs credentials, requesting does not
- `ruby bin/ci` → exit 0

## Files expected to change

- `app/controllers/application_controller.rb`: `authenticate_hawker`, reading `HAWKER_USERNAME` and `HAWKER_PASSWORD` per request
- `app/controllers/hawkers_controller.rb`: guard both actions
- `app/controllers/stops_controller.rb`: guard `update` only
- `test/test_helper.rb`: test credentials and a header helper
- `test/controllers/hawkers_controller_test.rb`, `test/controllers/stops_controller_test.rb`
- `AGENTS.md` §8/§12/§17

## Impact

- `HawkersController#show`/`#update` and `StopsController#update` now answer `401` without
  credentials; the browser prompts once and caches for the session.
- `HomeController` and `StopsController#create` are untouched, so the customer flow keeps
  working. Their tests need no header.
- Missing `HAWKER_USERNAME`/`HAWKER_PASSWORD` raises at request time, not at boot, so
  `zeitwerk:check` and asset precompile still pass without the variables.

## Risks

- Basic auth is only safe over TLS; production already forces SSL. Anyone holding the
  credentials has the whole desk, which is accepted for a single hawker.
