## Goal

Install the audit toolchain that can produce a real signal in this repo, wire
each tool into a single local gate (`bin/ci`), and run that same gate on every
push and pull request to any branch.

## Non-goals

- No N+1, migration, or schema tools armed for code that does not exist yet.
- No test suite, coverage, or performance profiling (nothing to measure).
- No `erb_lint` (676 days stale) and no `herb` (no Windows binary; needs a Rust toolchain).
- No `ruby_audit` (flags the local 4.0.9 interpreter, a machine issue, not a repo issue).
- No `bullet`, `skunk`, `rails_best_practices`, `active_record_doctor`,
  `database_consistency`, `pghero` — duplicated, noisy, or database-bound.

## Acceptance checks

- `ruby bin/ci` runs every step and exits 0.
- `ruby bin/rubocop` → `no offenses detected`.
- `ruby bin/rails zeitwerk:check` → `All is good!`.
- `ruby bin/bundler-audit check` → `No vulnerabilities found`.
- `ruby bin/i18n-tasks missing` → exits 0.
- `ruby bin/rubycritic --no-browser app lib config` writes `tmp/rubycritic/overview.html`.
- `ruby -c config/ci.rb` → `Syntax OK`; workflow YAML parses.

## Files expected to change

`Gemfile`, `Gemfile.lock`, `bin/bundler-audit`, `bin/i18n-tasks`,
`bin/rubycritic`, `config/ci.rb`, `config/environments/development.rb`,
`.github/workflows/ci.yml`, `.github/dependabot.yml`, `AGENTS.md`.

## Impact

- `Gemfile` gains 5 gems; `bundle install` must still succeed on Windows and Linux.
- `config/ci.rb` drops the `bin/setup` step, which ran `db:prepare` and failed
  without PostgreSQL. `bin/ci` becomes runnable on this machine.
- `.github/workflows/ci.yml` collapses 2 jobs into 1 that runs `bin/ci`; the
  previous `scan_ruby` and `lint` checks still run, inside the gate.
- `development.rb` gains a N+1 middleware; development requests log N+1s.

## Risks

- `rubycritic` pulls a legacy dependency chain (`virtus`, `ruby_parser`); if
  `bundle install` fails on Windows it is the first thing to drop.
- `bundler-audit --update` clones ruby-advisory-db on first run and needs `git`
  on PATH (shimmed on this machine).
- The gate can go red from an upstream CVE that has no fix yet; that is a true
  positive and must be triaged, not silenced.
