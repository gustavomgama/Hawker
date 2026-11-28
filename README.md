# Hawker

The storefront of one hawker: a cart, a bicycle, a person on foot. Customers open
it to see whether their hawker is working, see when the hawker's position was last
recorded, and ask for a stop. The hawker sees the requests, accepts them, and works
a route.

One hawker per deployment. No marketplace, no second seller, no customer ETA, no
push to customers.

## Requirements

- Ruby 4.0.10 (`.ruby-version`)
- PostgreSQL with a `hawker` role that can create `hawker_development`,
  `hawker_test` and `hawker_production` (plus the `_queue` and `_cable` databases
  production uses)
- Nothing else: no Node, no CSS build step, Propshaft serves the stylesheet as is

## Setup

```sh
bundle install
ruby bin/rails db:prepare
ruby bin/rails db:seed
ruby bin/dev
```

On Windows always call Rails as `ruby bin/rails …`; `bin/rails` has no `.exe` and
PowerShell will not run it directly.

## Credentials

The hawker surface is behind HTTP basic auth. Export both variables before starting
the server; missing ones raise on the first hawker request rather than at boot.

```sh
export HAWKER_USERNAME=hawker
export HAWKER_PASSWORD=choose-something
```

PowerShell: `$env:HAWKER_USERNAME = "hawker"`. `.env` is not loaded — there is no
`dotenv-rails` — so exporting in the shell is the only way in.

`DATABASE_URL` overrides `config/database.yml` if you would rather configure the
connection that way.

## Screens

| Path | Who | Notes |
| --- | --- | --- |
| `/` | customers | "Your hawker is working" or "not working", the request form, and `Last seen at HH:MM` |
| `/hawker` | the hawker | availability and broadcast toggles, requested stops, the route |
| `/up` | load balancer | boots the app and returns 200 |

## Two states, independent of each other

| | Means | Customer effect |
| --- | --- | --- |
| availability `online` / `offline` | whether the hawker works at all | offline: no requests, no form, nothing |
| broadcast `broadcasting` / `paused` | whether position pings are stored | paused: requests and the route continue |

Going offline voids requested stops and drops accepted ones without asking. The
customer sees "The hawker stopped working".

## Tests and checks

```sh
ruby bin/ci
```

That is the whole gate: autoloading, rubocop, the test suite, brakeman, gem and
importmap audits, i18n, rubycritic. Expect `55 runs, 202 assertions` and exit `0`.

Single file, faster loop:

```sh
ruby bin/rails test test/controllers/home_controller_test.rb
```

## Deployment

Kamal and a multi-stage `Dockerfile`; Thruster fronts Puma; the entrypoint runs
`db:prepare` so the queue and cable tables appear on first boot. `RAILS_MASTER_KEY`
and `HAWKER_DATABASE_PASSWORD` come from the environment.

The image build is not usable yet: it copies `package.json` and `yarn.lock` that do
not exist in this repo. See `AGENTS.md` §16 before the first deploy.

## Where the rules live

- `AGENTS.md` — conventions, the gate, known traps. Read before editing.
- `docs/product-idea.md` — the frozen product contract (§2) and open questions (§9).
- `TASK.md` — the backlog, and the one surviving progress file.
- `specs/` — one spec per larger change.
