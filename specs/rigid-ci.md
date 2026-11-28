# Rigid CI

## Goal

Make `ruby bin/ci` and GitHub Actions reject drift, not just breakage: a stale
lockfile, a migration without its `db/schema.rb` update, a dead translation key,
and a workflow that cannot be mutated by the checks it runs.

## Non-goals

- No new gems or tools (`erb_lint`, `actionlint`, Playwright stay out).
- No matrix, no extra jobs, no change to caching or the Ruby/Postgres versions.
- No pinning actions to commit SHAs; Dependabot already tracks the major tags.
- No application behaviour change; no schema, route, model or view change.

## Acceptance checks

```
ruby bin/ci                                  # exit 0, every step green
bundle check                                 # The Gemfile's dependencies are satisfied
ruby bin/i18n-tasks unused                   # No unused translations were found.
ruby bin/rails db:migrate && git diff --exit-code -- db/schema.rb   # exit 0
ruby bin/rails test                          # 55 runs, 202 assertions, 0 failures
```

## Files expected to change

- `config/ci.rb` — explicit `RAILS_ENV=test`, lockfile check, schema-drift pair,
  unused-translation check.
- `.github/workflows/ci.yml` — read-only permissions, concurrency, job timeout,
  frozen bundle, credentials not persisted, tracked-file mutation assert.
- `config/i18n-tasks.yml` — new; ignores `time.formats.*`, which no static
  scanner can resolve from `l(record, format: :time)`.
- `config/locales/en.yml` — drop the dead `hello` key.
- `AGENTS.md` §4 — gate table and notes match the new steps.

## Impact

- `ruby bin/ci` now needs the `hawker_test` database and a git checkout; it
  fails when `db/schema.rb` is behind `db/migrate` or a locale key is dead.
- `BUNDLE_FROZEN` in CI means editing `Gemfile` without committing
  `Gemfile.lock` fails at install, before any step runs.
- Nothing in `app/`, `db/migrate`, `config/routes.rb` or the test suite changes:
  no runtime, auth or deploy effect.

## Risks

- `i18n-tasks unused` is static. A key resolved by interpolation is reported
  dead; add it to `ignore_unused` with a reason rather than dropping the check.
- The schema-drift check dumps from the test database, so it depends on
  `db:test:prepare` running first. It does, in the same run.
- Renaming a step changes `config/ci.rb` output only; the workflow calls
  `ruby bin/ci`, never an individual step.
