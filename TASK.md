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
- [ ] Hawker login with `has_secure_password` and a session, protecting every hawker action, tests
- [ ] Customer identity by phone, tying a request to the signed-in customer, tests
- [x] Live availability: publish the profile state so the customer screen flips without a reload, test
- [ ] `positions` table and an endpoint for the hawker app to post a position, pruned by a job, test
- [ ] Customer sees the hawker's last known position and when it was recorded, test

## Blocked

* Decided (user): HTTP basic from `HAWKER_USERNAME`/`HAWKER_PASSWORD` guards the hawker surface for now. Recorded in `AGENTS.md` §8/§12. Item 15 (real login) is therefore still open on the question of whether and when `has_secure_password` plus a session replaces basic auth; no `bcrypt` or `password_digest` work starts before that answer.
* Hawker login (item 15) and customer phone identity (item 16) are both auth changes, which `AGENTS.md` §19 and the loop's stop rule put in the user's hands. Basic auth covers the hawker surface meanwhile; item 16 needs a decision on how a phone identifies a customer (verified by SMS, unverified, or a signed link).
* `positions` (item 18) has its endpoint auth answered by the basic-auth decision above, and the user approved wiring `solid_queue` and `solid_cable`. Remaining before it can ship: run the three `:install` tasks, add `db/queue_migrate`/`db/cable_migrate`, set the adapters, `db:prepare`, and update `AGENTS.md` §10. That is a schema change, now sanctioned.
* Item 19 depends on item 18 and on the unanswered paused-state question below (frozen position, greyed map, or text only), so it cannot be built without both.

## Needs a decision from the user

Not checkboxes on purpose: an unanswered question must never block the loop from finishing.

* Does an unaccepted request expire while the hawker is still online, and after how long?
* Is the customer waiting at the address, or is this a delivery to a door?
* Is an order free text, or a catalogue with items and prices?
* How is payment taken: cash on arrival, in-app, or both?
* What does the customer see when the hawker is paused — frozen position, greyed map, or text only?
* What area does the hawker serve, and is dropping a pin the primary address input where streets have no names?
* Is there a maximum number of stops, and what happens at the limit?
* Does the hawker see any internal timing per stop?
