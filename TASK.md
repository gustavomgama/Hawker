# Task backlog

Ordered. One unchecked item per loop iteration. Procedure: `docs/loop-prompt.md`.

## Backlog

- [x] Root route and customer screen: reads the singleton `HawkerProfile`, renders "Your hawker is working" or "not working", with tests for both states
- [x] Customer request form: posts an address and items, creates the stop through `Stop.request!`, redirects, test
- [x] Refused request while offline: honest message, no record written, test
- [x] Hawker screen: toggle online/offline and pause/resume, tests
- [ ] Guard the hawker screen: it is reachable by anyone until login exists
- [ ] Hawker sees requested stops and can accept or decline, updating without a reload
- [ ] Hawker route list: accepted stops in `sequence` order plus the requested-versus-accepted stop count, test
- [ ] Stop lifecycle from the hawker screen: arrive, fulfil, test
- [ ] Hawker login with `has_secure_password` and a session, protecting every hawker action, tests
- [ ] Customer identity by phone, tying a request to the signed-in customer, tests
- [ ] Live availability: publish the profile state so the customer screen flips without a reload, test
- [ ] `positions` table and an endpoint for the hawker app to post a position, pruned by a job, test
- [ ] Customer sees the hawker's last known position and when it was recorded, test

## Blocked

* What guards the hawker screen until real login exists: HTTP basic from credentials, a single shared token, or leave it open? Every stopgap is either a new auth scheme or bypassable behind Thruster, so this is the user's call.

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
