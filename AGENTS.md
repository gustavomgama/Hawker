# Hawker — Rails 8.1 operating manual

Contract for anyone (human or agent) editing this repository. Every statement
below was verified against this tree. When the tree and this file disagree, the
tree wins: fix this file in the same change.

---

## 1. Hard rules

1. **No comments in code.** Names, structure and small methods carry intent. This applies to `.rb`, `.erb`, `.js`, `.css`, `Dockerfile`, migrations. It does not apply to Markdown (`AGENTS.md`, `README.md`, `specs/`).
2. **Never report done without running the gate in §4** and quoting the command and its result.
3. **Windows is the primary dev platform.** Run Rails as `ruby bin/rails …`. `bin/rails` has no `.exe` and PowerShell will not execute it directly.
4. **Never edit a migration that has already run.** Add a new one.
5. **Never hand-edit `db/schema.rb`.** It is generated from the database.
6. **Never commit** `config/master.key`, `.env*`, `coverage/`, `log/*`, `tmp/*`, `storage/*`.
7. **One change, one reason.** Do not reformat files you did not need to touch; it hides the real diff.
8. **Prefer deletion over abstraction.** A wrapper, option, or "for later" seam must earn its existence now.

---

## 2. Verified stack

| Piece | Value | Source of truth |
| --- | --- | --- |
| App / module | folder `Hawker`, module `Hawker` | `config/application.rb`, `config/database.yml` |
| Rails | 8.1.4.1, `config.load_defaults 8.1` | `Gemfile`, `config/application.rb` |
| Ruby | 4.0.10 | `.ruby-version`, `Dockerfile` `ARG RUBY_VERSION` |
| Database | PostgreSQL, db `hawker_development` / `_test` / `_production`, role `hawker` | `config/database.yml` |
| Web server | Puma (3 threads default), Thruster in front | `config/puma.rb`, `Dockerfile` |
| Assets | Propshaft (no build step), importmap pins | `Gemfile`, `config/importmap.rb` |
| Front end | ERB + Hotwire (Turbo, Stimulus) | `Gemfile`, `app/views` |
| Jobs / cache / cable | `solid_queue`, `solid_cache`, `solid_cable` installed, **not wired** | `Gemfile` vs `config/` |
| Deploy | Kamal + Docker multi-stage, non-root user, `/up` health check | `Dockerfile`, `config/routes.rb` |
| Lint / security / audit | `rubocop-rails-omakase`, `brakeman`, `bundler-audit`, `i18n-tasks`, `rubycritic`, `strong_migrations`, `prosopite` | `Gemfile`, `config/ci.rb` |
| CI | `bin/ci` locally and in GitHub Actions, 1 job, every branch, `postgres:16` service; Dependabot weekly | `.github/workflows/ci.yml`, `.github/dependabot.yml` |
| Tests | Minitest, transactional, no fixtures yet | `test/` |
| Agent config | `opencode.jsonc` (compaction), `.opencode/{agents,commands,plugins}` | repo root |

Check the interpreter before debugging anything else: `ruby -v` must match
`.ruby-version`. A mismatch surfaces as confusing native-gem failures, not as a
version error.

---

## 3. Identity: one name

The app, the Rails module, the databases and the image are all `Hawker`
(`Hawker::Application`, `hawker_*` databases, `hawker` image). There is one hawker
per deployment: no `hawkers` table, no `hawker_id` column, no tenant scoping.
`DriverTracker` is retired and must not reappear anywhere.

---

## 4. Gate: definition of done

Run in this order; cheapest first. Each is expected to pass with the stated output.

| Command | Proves | Expected |
| --- | --- | --- |
| `ruby bin/ci` | every check below in one run | all steps pass, exit `0` |
| `ruby bin/rails zeitwerk:check` | autoloading/eager-load integrity, catches misplaced or misnamed files | `All is good!` |
| `ruby bin/rubocop` | omakase style | `31 files inspected, no offenses detected` (count grows) |
| `ruby bin/rails test` | domain rules and state transitions | `13 runs, 25 assertions, 0 failures` (counts grow) |
| `ruby bin/brakeman --no-pager` | security static analysis | `No warnings found`, exit `0` |
| `ruby bin/bundler-audit check --update` | CVEs against `Gemfile.lock` via ruby-advisory-db | `No vulnerabilities found` |
| `ruby bin/importmap audit` | vulnerable pinned JS packages | `No vulnerable packages found` |
| `ruby bin/i18n-tasks missing` | keys used in code but absent from `config/locales` | `No translations are missing.` |
| `ruby bin/rubycritic --no-browser app lib config` | churn, complexity, duplication and smell report | writes `tmp/rubycritic/overview.html` |
| `ruby bin/rails routes` | route table still parses (run when routes change) | table prints |
| `ruby bin/rails db:migrate` | migration applies cleanly (run when `db/` changes) | `== … migrated` |

Notes:

- `ruby bin/ci` (`config/ci.rb`) runs every check below and reports at the end; it needs no database. GitHub Actions runs the same command, so local and CI cannot drift.
- RubyCritic is a report, not a verdict: it always exits `0` unless it crashes. Read `tmp/rubycritic/overview.html`, never gate a merge on its score.

- `brakeman` prints `Process.fork is not supported by this Ruby` on Windows. It falls back to a serial scan. Harmless; exit code is still `0`.
- CI runs the same command on Linux using `.ruby-version`. If CI fails and local does not, suspect a platform assumption (paths, `fork`, case sensitivity, `.exe` binstubs), not the code.
- If a check cannot run (no database, wrong interpreter), say so explicitly. Never silently skip.

---

## 5. Commands

| Task | Command |
| --- | --- |
| Install deps | `bundle install` |
| First-time setup | `ruby bin/setup --skip-server` |
| Dev server | `ruby bin/rails server` (or `ruby bin/dev`, which execs the same) |
| Console | `ruby bin/rails console` |
| DB create / migrate | `ruby bin/rails db:prepare`, `ruby bin/rails db:migrate` |
| DB rollback | `ruby bin/rails db:rollback` |
| Generate | `ruby bin/rails generate model|controller|migration|job|mailer …` |
| Routes | `ruby bin/rails routes` |
| Secrets | `ruby bin/rails credentials:edit` |
| Logs | `ruby bin/rails log:clear`; dev log at `log/development.log` |
| Assets | `ruby bin/rails assets:precompile` (rarely needed locally; Propshaft serves directly) |
| Full local gate | `bin/ci` (from PowerShell: `ruby bin/ci`) |

`bin/dev` is a single-process exec of `bin/rails server`. There is no
`Procfile.dev` and no foreman: when a JS/CSS build step is added, replace it
with a process manager instead of bolting onto the current script.

---

## 6. Where code goes

| Location | Holds | Does not hold |
| --- | --- | --- |
| `app/models` | ActiveRecord models, associations, validations, scopes, small POROs that own a rule | HTTP, sessions, view formatting |
| `app/controllers` | request parsing, authorization checks, one render/redirect | business rules, SQL strings |
| `app/jobs` | one class, one `perform`, idempotent | orchestration of other jobs |
| `app/mailers` + `app/views/<mailer>` | one method per email | inline HTML |
| `app/views` | ERB, partials | queries, mutations, `Model.all` in a loop |
| `app/helpers` | presentation helpers used by 2+ templates | domain logic |
| `app/models/concerns`, `app/controllers/concerns` | shared behaviour with **2+ concrete users** | speculative reuse |
| `lib/` | pure Ruby, autoloaded (`config.autoload_lib` ignores `assets` and `tasks`) | anything needing request context |
| `specs/` | Markdown specs (§20) | code |

- No service-object layer by default. Introduce a plain object in `app/models`
  (or `lib/`) when an action exceeds ~15 lines or one workflow touches two or
  more models — not before.
- A concern with one includer is indirection: inline it.
- Naming: models singular `CamelCase`, tables plural `snake_case`, jobs `<Verb>Job`
  with a single `perform`, scopes as adjectives or plural nouns (`active`,
  `recent`), predicates end in `?`, bang methods mutate or raise.

---

## 7. Data layer

- PostgreSQL is the only database. `pool` comes from `RAILS_MAX_THREADS` (default 5) and must be ≥ Puma threads.
- Migrations must be reversible. Use `change` with reversible operations; write `up`/`down` when it is not.
- Every foreign key gets `foreign_key: true` **and** an index. `add_reference :x, :y, foreign_key: true, index: true` is the default, not a nicety.
- Every column used in `where`, `order` or `join` on a production path gets an index. Composite indexes order columns by selectivity, then by the query's sort.
- Enforce invariants twice: model validation for the message, DB constraint for the truth (`null: false`, `default:`, unique index behind `validates uniqueness:`).
- `string` columns: set `limit:` when the real-world limit is known.
- No `default_scope`. It leaks into every association and cannot be escaped reliably. Use named scopes.
- No business logic in `after_save`/`before_create`. Side effects (mail, jobs, cache busting) go in `after_commit`, and only when the effect needs committed data.
- No raw `connection.execute` for anything ActiveRecord can express.
- Seeds must be idempotent: `find_or_create_by!` / `upsert_all`, never bare `create!` that explodes on rerun.
- `db/cache_migrate`, `db/queue_migrate`, `db/cable_migrate` do not exist yet. Creating them is part of wiring the Solid stack (§10), not a free-standing task.
- `strong_migrations` is installed and guards `db:migrate` in every environment: it raises on operations that lock a table or rewrite it unsafely. Never disable it to push a migration through — split the migration instead.

---

## 8. Controllers and routing

- RESTful resources only: `index show new create edit update destroy`. A new verb means a new resource, not an eighth action.
- `resources :x, only: %i[…]` — never expose actions you do not implement.
- Strong params live in a private method: `params.require(:x).permit(:a, :b)`. `permit!` is a bug.
- Exactly one `render`/`redirect_to` per action path. Turbo Stream responses replace re-rendering whole pages.
- Authorization happens in a `before_action` and returns `404`/`403` — never hide the control in the view only.
- Status codes: `200` read, `201` created, `204` no content, `302` redirect after form, `422` validation failure, `404` missing or unauthorized resource.
- Keep `get "up" => "rails/health#show"` as `:rails_health_check`. Deploy health checks depend on it.
- There is no root route yet. Adding one means adding a controller, a view, and a test — not a `redirect_to` placeholder.

---

## 9. Views, front end, assets

- ERB only. Turbo Drive is automatic on links and forms; Turbo Frames scope partial navigation; Turbo Streams update after mutations; Stimulus adds isolated behaviour. No React/Vue/jQuery, no client-side router.
- **Hotwire is wired.** `config/importmap.rb` pins Turbo, Stimulus and `app/javascript/controllers`; `app/javascript/application.js` imports them; the layout renders `javascript_importmap_tags`. Add a package with `ruby bin/importmap pin <name>`, add a Stimulus controller under `app/javascript/controllers/`, and `bin/importmap audit` runs in the gate.
- Styles: the single stylesheet is `app/assets/stylesheets/application.css`, linked with `stylesheet_link_tag :app`. **`:app` is correct** in Rails 8.1 — verified to resolve to `application.css` with a digest. Do not "fix" it to `"application"`.
- No CSS build step. `cssbundling-rails` is in the `Gemfile` but there is no `package.json`, so it does nothing; do not assume Tailwind/Sass is available.
- No inline `<script>` or `<style>`. The CSP initializer is fully commented out, so nothing is protecting inline content today — enable `content_security_policy` before adding third-party scripts.
- Partials: `_name.html.erb`, locals passed explicitly, no reliance on controller instance variables.
- Extract a partial when a template exceeds ~50 lines or a block repeats twice.
- Accessibility is not optional: every input has a `<label>`, dynamic regions announce with `aria-live`, heading order is logical, focus is visible, color is never the only signal, tap targets ≥ 44px.
- Forms: `form_with model:`; never hand-roll CSRF tokens or method overrides.

---

## 10. Jobs, cache, cable

Current state, verified: the three Solid gems are installed but nothing is
configured. There is no `connects_to`, no `db/*_migrate` directory, and
`config/cable.yml` production still says `adapter: redis` while the `redis` gem
is not in the lockfile — production cable would fail at boot.

| Environment | Cache | Jobs | Cable |
| --- | --- | --- | --- |
| development | `:memory_store` | default (`:async`) | `:async` |
| test | `:null_store` | default | `:test` |
| production | defaults to memory until wired | defaults to `:async` — **jobs are lost on restart** | `redis` — **gem missing** |

To wire production properly:

1. `config.active_job.queue_adapter = :solid_queue` and `config.solid_queue.connects_to = { database: { writing: :queue } }`.
2. `config.cache_store = :solid_cache_store`.
3. `config/cable.yml` production → `adapter: solid_cable`, `connects_to: { database: { writing: :cable } }`.
4. `ruby bin/rails solid_queue:install`, `solid_cache:install`, `solid_cable:install`, then `db:prepare`.
5. `SOLID_QUEUE_IN_PUMA=1` runs the worker inside Puma for single-server deploys (`config/puma.rb` already supports it).

Job rules:

- Idempotent. A job may run twice; use a natural key or `find_or_create_by`.
- Small arguments. Pass GlobalID records (`record`) or scalars, never large objects or files.
- `retry_on` with exponential backoff for transient failures; `discard_on` for permanent ones. Never retry on argument errors.
- `limits_concurrency` for anything hitting a rate-limited external API.
- Enqueue from `after_commit` when the job reads the row it was enqueued from. Rails 8 defers enqueue-until-commit only for adapters that advertise it, so do not rely on that.

---

## 11. Config and secrets

- Credentials: `config/credentials.yml.enc` is committed; `config/master.key` is not. In production, inject `RAILS_MASTER_KEY`. Read with `Rails.application.credentials.dig(:section, :key)`.
- **`.env` is inert.** `dotenv` appears in the lockfile only as a Kamal dependency, and Kamal is `require: false`. Nothing loads `.env` at boot, so `GOOGLE_MAPS_API_KEY` in it is not visible to Rails. Either export variables in the shell (`$env:GOOGLE_MAPS_API_KEY = "…"` in PowerShell) or add `dotenv-rails` deliberately and say so.
- `ENV.fetch("X")` for required settings (fail fast), `ENV["X"]` for optional ones. No hardcoded hosts, ports, passwords or keys.
- Production database password: `HAWKER_DATABASE_PASSWORD`. `DATABASE_URL` merges over `database.yml` and is the portable way to configure any environment.
- `config/application.rb` holds app-wide settings; `config/environments/*.rb` override them later. Keep `assume_ssl` and `force_ssl` enabled in production — they were intentionally restored and are the last defense if a proxy is misconfigured.
- Changing `config/` requires a server restart; changing `app/` does not (reloading is on in development).

---

## 12. Security

- Brakeman is the gate. Do not silence a warning — fix the code. If a warning is genuinely a false positive, add it to `.brakeman.ignore` with a written reason and mention it in the report.
- Never `raw`/`html_safe` on user input. ERB escapes by default; keep it that way.
- Never interpolate into SQL: `where("name = '#{x}'")` is a bug. Use `where(name: x)` or a placeholder array. Escape `LIKE` patterns with `sanitize_sql_like`.
- Mass assignment: explicit `permit` keys only. No `params.to_h` into `create`.
- File uploads: validate content type and size in the model. `image_processing` is commented out in the `Gemfile`, so `variant` calls raise — add it before using transformations.
- `config/initializers/filter_parameter_logging.rb` already filters passwords and tokens. Add new sensitive params there, not in a `logger` call.
- Auth does not exist yet. When it arrives: `bcrypt` is commented out in the `Gemfile` and must be uncommented for `has_secure_password`; session cookies need `httponly: true, secure: true, same_site: :lax`; login gets `rate_limit`; authorization is per-resource, never a UI toggle.
- Active Storage, Action Text and Action Mailbox engines are required in `config/application.rb` but no tables exist (`db/` has no migrations). Any `has_one_attached`, rich text field or inbound mailbox raises until you run the corresponding `:install` task and migrate.
- Redirects to user-supplied URLs need an allowlist. Brakeman flags these; so do reviewers.

---

## 13. Tests

Minitest is enabled (`rails/test_unit/railtie`), `test/` exists, and the suite runs
inside the gate. Transactional tests, no fixtures yet: each test builds what it needs.

- Every domain rule gets a test. The state machine is the current subject: going
  offline voids requested stops and drops accepted ones, a stop cannot be accepted
  twice, a request is refused while offline.
- `ruby bin/rails db:test:prepare` loads `db/schema.rb` into `hawker_test`. It is a
  step in `bin/ci`, so a fresh clone needs no manual setup.
- `test/test_helper.rb` exposes `profile`, the singleton `HawkerProfile`. Use it
  instead of `HawkerProfile.instance` in tests.
- Test the boundary, not the framework: model rules, state transitions, controller
  status. Never assert Rails' own behavior.
- Fixtures over factories until a second test needs the same graph.
- The test database is `hawker_test`, connects over `localhost` as the `hawker` role,
  and is wiped by test runs.
- CI runs a `postgres:16` service container with the same `hawker` role. If a test
  passes locally and fails in CI, compare the connection host first.

---

## 14. Style

- `rubocop-rails-omakase` is inherited with no overrides (`.rubocop.yml`). Adding an override requires a reason in the change description; do not add one to make a warning disappear.
- Ruby: 2-space indent, double quotes, trailing commas in multi-line literals, `%i[]` for symbol arrays, `&.` instead of `try`, no `and`/`or` for control flow, no `unless … else`.
- Do not sprinkle `# frozen_string_literal: true` where the repo does not already use it.
- ERB: tight `%>`, no trailing whitespace, `<%= … %>` only when output is wanted.
- Remove `puts`, `p`, `binding.break`, and `logger.debug` scaffolding before finishing. Use `Rails.logger.info { … }` (block form keeps it lazy).
- Timestamps in the app stay in UTC. Nothing but presentation converts to a zone.
- Commits: imperative subject under 72 characters; body explains why, not what.

---

## 15. Performance

- Fix N+1 with `includes`/`preload`/`eager_load` before touching anything else; `verbose_query_logs` and query log tags are already on in development.
- `prosopite` is wired into development (`config/initializers/prosopite.rb`): it appends a page footer listing detected N+1s and reports them for Turbo/XHR responses too. It raises in the test environment. A footer warning is a bug, not noise.
- Add `strict_loading` on hot associations to keep regressions loud.
- Index first, cache second, denormalize third. Never cache to hide a missing index.
- `find_each` for batches, `pluck` instead of `map` on a column, `select` only needed columns on wide tables.
- Counter cache for `count` on a hot parent page.
- Fragment cache keyed on `[record, I18n.locale]` so an update busts it automatically.
- Measure before optimizing: log durations or `Benchmark.realtime`. No speculative `Rails.cache` calls.

---

## 16. Deploy

- Kamal + Thruster, multi-stage `Dockerfile`, non-root `rails` user (uid 1000), entrypoint runs `db:prepare`, `CMD` is `./bin/thrust ./bin/rails server`.
- **The Docker build is broken today.** The build stage copies `package.json` and `yarn.lock` and runs `yarn install --immutable`, but neither file exists in this repo. With no JS toolchain in the app, the `ARG NODE_VERSION`/`ARG YARN_VERSION` lines, the `node-build` download, `corepack enable && yarn set version …`, and both yarn lines are dead weight — remove them before the first deploy.
- `BUNDLE_WITHOUT="development"` does not exclude the `development, test` group, so `debug`, `brakeman` and `rubocop-rails-omakase` are installed in the image. Add `test` to `BUNDLE_WITHOUT` if image size matters.
- Assets precompile in the build stage with `SECRET_KEY_BASE_DUMMY=1`; no Node needed for Propshaft.
- Do not deploy while the Solid stack is unwired (§10): background jobs would run `:async` inside Puma and vanish on restart, and Action Cable would fail for a missing `redis` gem.
- `config/deploy.yml` does not exist yet. Adding Kamal deploy config is its own task with its own spec.

---

## 17. Known traps (all verified in this tree)

| Trap | Reality | What to do |
| --- | --- | --- |
| `bin/rails …` in PowerShell | not executable, no `.exe` | `ruby bin/rails …` |
| `bin/*` shebangs | must stay `#!/usr/bin/env ruby`; `app:update` can regress them to `ruby.exe`, breaking Linux CI and Docker | revert any such change |
| Local interpreter | machine has Ruby 4.0.9 at `C:\Ruby40-x64`; project pins 4.0.10 | install 4.0.10 before debugging gem errors |
| `bundle outdated` | lists `marcel 1.2.1` and `net-ssh 7.3.10` | capped by `activestorage (~> 1.0)` and `ed25519 (~> 7.3)`; not upgradable, do not force |
| No `db/migrate`, no `db/schema.rb` | `db:prepare` has nothing to build | the first migration creates both |
| `db:prepare` fails | `fe_sendauth: no password supplied` on `localhost:5432` | set `DATABASE_URL` or `database.yml` credentials |
| `.env` | never loaded (no `dotenv-rails`) | export in the shell |
| `cssbundling-rails` | installed with no `package.json` | no Tailwind/Sass until you add a build |
| Solid trio | gems installed, zero configuration, cable points at `redis` without the gem | §10 |
| Active Storage / Text / Mailbox | engines required, no tables | run `:install` + migrate before using |
| `bcrypt`, `image_processing` | commented out in the `Gemfile` | uncomment before `has_secure_password` / `variant` |
| `coverage/` | untracked build output at repo root | now gitignored; do not `git add -A` it back |
| `git` on PATH | shimmed on this machine | if it misbehaves use `C:\Program Files\Git\cmd\git.exe` |
| Brakeman on Windows | prints `Process.fork is not supported by this Ruby` | serial fallback, exit `0`, ignore |
| `stylesheet_link_tag :app` | resolves to `application.css` + digest | correct for Rails 8.1, leave it |
| `zeitwerk:check` | eager-loads the whole app | any failure here blocks everything else |

---

## 18. Reject in review

- A service object, form object, presenter or concern with exactly one caller.
- `default_scope`, `permit!`, `update_column`/`update_all` without a stated reason, `rescue => e; nil`.
- Callbacks that send mail or enqueue jobs before commit.
- Query builders or `Model.find` inside views/helpers.
- `raw`/`html_safe`/`sanitize` on user input; SQL built with string interpolation.
- A new gem before checking Ruby stdlib, Rails and the already-installed set.
- `data-turbo="false"` used to work around a Turbo problem instead of fixing it.
- Generated boilerplate committed without reading it (`app:update` rewrites `bin/*` and production SSL settings — review its diff).
- A spec or a documented check that no command can verify.
- Commented-out code left in place "for reference".

---

## 19. Stop and ask before

- Dropping or renaming a column or table that holds data.
- Changing authentication, sessions, or authorization rules.
- Money, currency, tax or billing math.
- Changing a public route or response shape another client depends on.
- Any irreversible migration (destructive `change_column`, type narrowing, `drop_table`).
- Adding a dependency that changes the deploy shape (Redis, Node, a second datastore, Sidekiq).
- Overriding `.rubocop.yml` or adding `.brakeman.ignore` entries.
- Wiring the Solid stack or adding Active Storage tables (schema-level, hard to reverse).

---

## 20. Specs for larger changes

Any change touching 3+ files, adding behavior, or altering a public surface gets
`specs/<slug>.md` **before** the edit, with exactly:

```markdown
## Goal
## Non-goals
## Acceptance checks
## Files expected to change
## Risks
```

Acceptance checks must be runnable commands with expected output (§4). Keep the
file after completion — it is the audit trail. Precedent: `specs/upgrade-to-latest.md`.
