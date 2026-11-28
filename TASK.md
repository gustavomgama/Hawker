# Task backlog

Ordered. One unchecked item per loop iteration. Procedure: `docs/loop-prompt.md`.

## Backlog

- [x] Root route and customer screen: reads the singleton `HawkerProfile`, renders "Your hawker is working" or "not working", with tests for both states
- [x] Customer request form: posts an address and items, creates the stop through `Stop.request!`, redirects, test
- [x] Refused request while offline: honest message, no record written, test
- [x] Hawker screen: toggle online/offline and pause/resume, tests
- [x] Guard the hawker screen: it is reachable by anyone until login exists
- [x] Hawker sees requested stops and can accept or decline, updating without a reload
- [x] Hawker route list: accepted stops in `sequence` order plus the requested-versus-accepted stop count, test
- [x] Stop lifecycle from the hawker screen: arrive, fulfil, test
- [x] Live availability: publish the profile state so the customer screen flips without a reload, test
- [x] `positions` table and an endpoint for the hawker app to post a position, pruned by a job, test
- [x] Customer sees the hawker's last known position and when it was recorded, test

## Blocked

* Decided (user): HTTP basic from `HAWKER_USERNAME`/`HAWKER_PASSWORD` **stays**. A password login with `has_secure_password` and a session does not replace it, so that item is dropped from the backlog. Recorded in `AGENTS.md` §12.
* Decided (user): **no customer identity by phone**. The name and address a customer types on the request are enough, so the phone-identity item is dropped. Recorded in `AGENTS.md` §12.
* Decided (user): positions are kept **until the hawker goes offline** — `PrunePositionsJob` deletes every row when `availability` leaves `online`, and a ping sent while not broadcasting is refused with `409` and writes nothing. `solid_queue` and `solid_cable` are wired for production (`AGENTS.md` §10); `solid_cache` stays unwired until something needs it.
* Decided (user): while paused the customer sees the last recorded position **as text** — "Last seen at 14:03" — never a map or a pin. `/` and the availability broadcast both render it from `HawkerProfile#last_position`, gated on `working?`, so nothing lingers once the hawker is offline and the positions are pruned.

## Needs a decision from the user

Not checkboxes on purpose: an unanswered question must never block the loop from finishing.

* Does an unaccepted request expire while the hawker is still online, and after how long?
* Is the customer waiting at the address, or is this a delivery to a door?
* Is an order free text, or a catalogue with items and prices?
* How is payment taken: cash on arrival, in-app, or both?
* What area does the hawker serve, and is dropping a pin the primary address input where streets have no names?
* Is there a maximum number of stops, and what happens at the limit?
* Does the hawker see any internal timing per stop?
