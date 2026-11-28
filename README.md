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

## Seed data

`db:seed` runs automatically when `db:prepare` creates an empty database. Outside
production it leaves you with a working hawker and enough data for every screen
and control to have something behind it:

| Seeded | What it is for |
| --- | --- |
| the hawker, `online` and `broadcasting` | `/` says working and shows a fresh `Last seen at` |
| 8 customers, one stop each | 2 `requested`, 1 `accepted` (route position 1), 1 `arrived` (position 2), 1 `fulfilled`, 1 `declined`, 1 `dropped`, 1 `voided` |
| 3 positions, 9, 5 and 1 minutes old | the `Last seen at` readout, and pruning when the hawker stops |

So `/` renders the form and `/hawker` renders `2 waiting · 2 on the route`.

Production seeds only the profile record and stays offline.

## Try it

Start `ruby bin/dev` with `HAWKER_USERNAME` and `HAWKER_PASSWORD` exported, then:

1. Open `/`. The hawker is working, `Last seen at` is recent, and the request form
   is there. Ask for a stop with any name and address.
2. Open `/hawker` with basic auth. The request is listed under the counts with
   **Accept** and **Decline**.
3. Accept it — the stop moves onto the route with the next position number. Arrive
   it, then Fulfil it — it leaves the route.
4. Decline a request — it leaves the list.
5. Pause — `/` still says working and keeps `Last seen at`, and `POST /positions`
   answers `409` while storing nothing. Resume and a ping answers `204`.
6. Stop working with a stop on the route — requested stops become `voided`, route
   stops `dropped`, positions are pruned, `Last seen at` disappears, and any open
   customer tab flips to not working without a reload. The form is gone, and a
   request posted anyway is refused with nothing written.
7. `/up` returns `200`; `/hawker` without credentials returns `401`.

Seeding never overwrites a stop you have already moved, and re-seeding an existing
database adds nothing. Use `ruby bin/rails db:reset` for a pristine dataset — it
drops the database, so keep it away from anything you want to keep.

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
