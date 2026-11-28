# Hawker — product idea

Status: **draft v5**. Decisions in §2 are settled; everything else is open.
This file is the shared reference for elaboration — edit it here rather than
restating the idea in conversation.

Scope: this file defines **behaviour, states and terminology**. Interface and
interaction design is a separate layer — mis-taps, affordances, layout and feedback
are solved there, never by adding states, flags or endpoints here.

---

## 1. The idea

One hawker, one app. A merchant sells from whatever they move with — a car, a
cart, a bicycle, on foot — and this app is their storefront, their live position
and their work queue.

There is **no marketplace**: not one hawker among many, not a city map of
merchants, no discovery, no ranking, no dispatch. The whole product is the
relationship between **one hawker and the customers who depend on them**.

**The hawker has no obligation to work.** No shift, no schedule, no promise. When
they press **online**, every customer can see that the hawker is working, and only
then can anyone ask them for anything. When they press **offline**, the customer
cannot interact with the hawker in any way.

The app therefore has two dominant states, and everything else is secondary:

| Customer's screen says | Which means |
| --- | --- |
| **Your hawker is working** | position live, requests possible |
| **Your hawker is not working** | see it, do nothing — no requests, no messages, no interaction |

What the product sells is **certainty of arrival for people who depend on one
merchant**, not speed and not supply.

---

## 2. Decisions

| # | Decision | Consequence |
| --- | --- | --- |
| 1 | **Per-hawker.** A customer sees one hawker city-wide. | No marketplace, no assignment, no fairness question. Every request goes to that one hawker. |
| 2 | **Customer ETA does not matter.** | No ETA, no arrival promise, no "your order moved" problem. Route order is the hawker's private concern; the live position is the customer's answer. |
| 3 | **Location sharing is toggleable.** | Solves the safety concern; not a permanent public record of a person's day. |
| 4 | **Name from scratch.** Pre-existing code is disregarded. | Module, databases and prefixes are renamed before the first model. Nothing is ported. See §8. |
| 5 | **Two independent states** — availability (`online`/`offline`) and broadcast (`broadcasting`/`paused`). | Pausing the map never cancels accepted work. Decided. See §7. |
| 6 | **One hawker only.** One deployment = one merchant. | No `hawkers` table, no `hawker_id` column, no tenant scoping. The hawker is the application. |
| 7 | **The hawker has no obligation to work.** | No schedule, no shifts, no promised response time, no nagging. |
| 8 | **Availability is visible, not announced.** Customers see that the hawker is working when they look. There is **no push notification to customers** when the hawker goes online. | Customer-facing push does not exist as a feature. The hawker alone receives push, for requests. |
| 9 | **Offline means no interaction at all.** No new requests, no messages, no calls, nothing to accept. | Being offline is a hard gate, enforced by the server, not a UI hint. |
| 10 | **Going offline drops accepted stops, without warning the hawker first.** The customer is shown **"The hawker stopped working"**. | No confirmation dialog, no "you have 2 stops" warning. The toggle is one press. The customer's state is honest instead of silent. |

---

## 3. Actors

| Actor | Who | What they need |
| --- | --- | --- |
| Hawker | the one merchant, and the person moving with the goods | to go out when they want, to see requests, a route, a stop count |
| Customer | buyers who depend on that merchant | to see whether the hawker is working, to be found, to know the hawker is coming |

No operator, no fleet, no second hawker. Every customer belongs to the one hawker;
there is nothing to select and nobody to compete with.

Hawker modes (affects speed, where they can physically stop, route realism):
car · bicycle · on foot · cart / trolley · other.

---

## 4. The core loop

1. The hawker decides to work. Presses **online**, and broadcasting with it;
   position streams.
2. Customers opening the app see that the hawker is working, and see the live
   position.
3. A customer **types an address** (or drops a pin): "I want to buy something".
4. The request reaches the hawker as a **notification**.
5. The hawker **accepts**; a route to that customer is created.
6. As more customers request, the hawker sees **how many stops are requested** and a
   **full route on the map**.
7. Every new accept **rebuilds the route** live.
8. The hawker takes a break — **paused**, map frozen, route intact — or ends the day
   with **offline**, and the customer app goes inert.

Steps 6 and 7 are the heart of it: the hawker is never serving one customer at a
time, they are continuously re-solving "who do I serve next, in what order".

---

## 5. What each side has to do

| Capability | Customer | Hawker | Live |
| --- | --- | --- | --- |
| See whether the hawker is working | yes | — | yes, on opening the app |
| See hawker position | yes | — | yes, while broadcasting |
| Broadcast own position | — | yes | yes, toggleable |
| Go online / offline | — | yes | yes |
| Request a stop at an address | only while online | — | yes |
| Receive request notification | — | yes | yes, push |
| Accept / decline request | — | yes | yes |
| Route to accepted stops | — | yes | yes, re-optimised |
| Stop count and order | — | yes | yes |
| Request state ("accepted", "on the way", "arrived") | yes | yes | yes |
| Catalogue or item list | yes | yes | — |
| Payment | yes | yes | — |
| ETA / arrival time | **no** | optional, internal | — |
| Anything at all while offline | **no** | — | — |
| Schedule, shift, promised availability | **never** | **never** | — |
| Push notification to customers | **none** | — | — |

---

## 6. The stop and route model

Must be exactly right before anything is built.

- **Request** — a customer has asked the hawker to come to an address. Not yet
  accepted, possibly declined or expired.
- **Stop** — an accepted request. One customer, one address, one handover.
- **Route** — the ordered stops the hawker will serve, from where they are now.
- **Stop count** — how many requested versus accepted. This is what the hawker looks
  at to decide whether to take one more.

**Invariant: a request exists only while the hawker is online.** Availability gates
both creation and survival. Going offline voids every unaccepted request — there is
nothing to come back to tomorrow, because nothing was ever promised.

An accepted stop is not exempt. Going offline drops it too, and the customer is told
**"The hawker stopped working"**. The hawker is not asked to confirm; the stop simply
ends, exactly like the working day does.

Because customer ETA does not matter, **the route may reorder freely**: re-optimising
on every accept breaks no promise. That is the biggest simplification this product
has over ride-hailing.

A request and a stop are the same thing in different states. One record moving
through states, not two tables to keep in sync.

---

## 7. Two independent states (decided)

| State | Meaning | Effect |
| --- | --- | --- |
| **Availability** — `online` / `offline` | am I working today? | offline: customers see "not working", **nothing can be created or accepted**, unaccepted requests are voided, accepted stops are dropped, the route ends |
| **Broadcast** — `broadcasting` / `paused` | can customers see where I am? | paused: position stops updating; requests and accepted stops continue |

A hawker eating lunch **pauses** and keeps their route. A hawker finishing the day
goes **offline**. One switch would silently strand work already accepted — that is
why they are separate.

Because there is exactly one hawker, **offline is a dead end for the customer** —
no other merchant to fall back to. The unavailable state is honest and carries no
pressure: no countdown, no "come back later" promise.

---

## 8. Naming

Starting from scratch. This section is the authority; use these words in the doc,
the code, the API and the UI.

| Thing | Name |
| --- | --- |
| Product, tenant, Rails module | `Hawker` |
| Database prefix | `hawker_` (`hawker_development`, `hawker_test`, `hawker_production`) |
| Container image | `hawker` |
| Core records | `customers`, `stops`, `positions` |
| Retired | `DriverTracker` — used nowhere, in nothing |

Because there is one hawker, **there is no `hawkers` table and no `hawker_id`
column**. The hawker's identity is a single profile record plus their login, not a
row every other table points at. A `hawker_id` in a migration is a bug.

Rules:

- **One noun per concept, never a synonym.** "Order", "job", "trip", "delivery" are
  not used unless defined in the glossary. A request becomes a stop; never "an
  order" on one screen and "a stop" on another.
- **Lifecycle in one table.** `stops` carries `requested → accepted → arrived →
  fulfilled`, plus `declined`, `expired`, `voided` and `dropped`. No separate
  `requests` table.
- **High-volume data is separate.** Position pings belong in `positions`
  (append-only, pruned), never on the profile row — the row would be rewritten
  constantly and the history is what makes the map work.
- **State names are literal.** `online` / `offline` for availability,
  `broadcasting` / `paused` for location. Never "active", "enabled" or "visible".
- **No `Driver`, no `Tracker`, no `Delivery`, no `Shift`, no `Schedule`** in class or
  table names. There is no obligation to work, so those concepts do not exist.

---

## 9. Open questions

Shrinking as decisions land.

1. Can the hawker **decline**, and when does an unaccepted request **expire**? With
   requests voided at offline, expiry only has to cover the working day.
2. Is the customer **waiting at the address**, or is this a delivery to a door?
3. What is being ordered — **free text** ("2 empanadas") or a **catalogue with items
   and prices**?
4. **Payment**: cash on arrival, in-app, or both?
5. **What does the customer see when the hawker is paused?** Frozen last position, a
   greyed map, or text only?
6. What **area** does the hawker serve, and with no street names in informal areas,
   is dropping a pin the primary address input?
7. **Capacity**: maximum stops held at once? What happens at the limit?
8. Does the hawker see **stop numbers only**, or also internal timing per stop?

---

## 10. Constraints that will shape the design

Realities, not decisions.

- **No obligation means no false expectations.** No "we will be there by…", no
  nagging, no streaks, no performance scoreboard. A merchant who feels judged for
  taking a day off stops using the app.
- **Pressing offline is one press, with no confirmation** (decision 10). Accepted
  stops are dropped silently from the hawker's side, so the toggle has to be
  unmistakable on its own — no dialog will save them — and the stop count belongs
  right next to it.
- **A mis-tap is a UI/UX problem and is solved there.** Prevention is a design
  concern: affordance, placement, gesture, feedback. The model deliberately has no
  recovery path — no undo endpoint, no grace period, no `pending_offline` state, no
  reversible drop. If the button is easy to hit by accident, fix the button.
- **No customer push means the customer finds out by looking.** That is the accepted
  trade-off of decision 8. Do not build retention mechanics to compensate — no
  emails, no "your hawker is back" campaigns.
- **Continuous location is the most expensive requirement here.** Background GPS is
  OS-restricted on iOS and Android and drains the battery of the device the hawker
  depends on all day. Pausing helps; streaming policy is still a design problem.
- **Typed addresses fail where hawkers work.** Informal settlements, markets and
  unnamed roads geocode badly or not at all. Pin-on-map is likely primary, typing a
  shortcut.
- **Route re-optimisation is a vehicle routing problem.** Needs a routing engine —
  external API with per-call cost, or self-hosted — and the order must be explainable
  or the hawker will not follow it.
- **Push is one-directional.** Only the hawker receives notifications, for requests.
  That halves the push surface and removes the customer app's opt-in problem.
- **Two-way real time needs a persistent channel** (websocket / SSE) and a mobile
  client. This repository is a Rails server, not a mobile app.
- **One hawker keeps fan-out low.** One position stream, to their own customers only —
  cheap, and a small privacy footprint.

---

## 11. Current state of the repository

The pre-existing scaffold is **disregarded** (decision 4). What exists is a running
Rails application with the first product slice in it:

- Rails 8.1.4.1 on Ruby 4.0.10, PostgreSQL, Propshaft, Hotwire, Puma — a usable base.
- `HawkerProfile`, `Stop`, `Customer` and `Position` exist; the availability and stop
  state machines, the customer screen and the hawker workspace are tested.
- HTTP basic guards the hawker surface; customers still have no identity.
- Position pings are append-only and are pruned when the hawker goes offline.
- `solid_queue` and `solid_cable` are wired for production on their own databases;
  `solid_cache` is installed and still unwired.
- `bin/ci` is green (autoloading, rubocop, brakeman, gem audit, i18n, rubycritic), so
  the gate exists before the first line of product code.
- The `DriverTracker` → `Hawker` rename is done: module, every database, image and
  page title. `DriverTracker` appears nowhere.

---

## 12. Glossary

| Term | Meaning |
| --- | --- |
| **Hawker** | the one merchant this app belongs to, and the person moving with the goods |
| **Customer** | a buyer who depends on that hawker |
| **Online / offline** | the hawker is working today and taking requests, or is not |
| **Broadcasting / paused** | the hawker's position is visible to customers, or is not |
| **Request** | a customer asking the hawker to come to an address; not yet accepted |
| **Stop** | an accepted request, on the route, owed to one customer |
| **Route** | the ordered stops the hawker will serve, from their current position |
| **Accept / decline** | the hawker's response to a request |
| **Voided** | an unaccepted request that ended because the hawker went offline |
| **Dropped** | an accepted stop that ended because the hawker went offline; the customer sees "The hawker stopped working" |
| **Arrived** | the hawker is at the stop's address |
| **Fulfilled** | the handover happened; the stop is done |
