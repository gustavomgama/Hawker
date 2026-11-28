# Continuous work loop

Run unattended. One slice per iteration. This file is the procedure; `TASK.md` is the
backlog; `AGENTS.md` is the law.

## Every iteration

1. **Read**: `AGENTS.md`, `docs/product-idea.md` §2 (decided behaviour), `TASK.md`.
   Do not re-read the whole product doc — §2 is the frozen contract.
2. **Pick the first unchecked `- [ ]` item in `TASK.md`.** One item. Do not start a
   second, do not batch, do not tidy unrelated files.
3. **Failing test first.** Run it. Watch it fail for the right reason (missing
   behaviour, not a typo). If it passes immediately, the test is wrong.
4. **Minimum code to pass.** No abstraction with one caller, no unused table, no
   endpoint nothing calls, no config nobody asked for.
5. **`ruby bin/ci` must exit 0.** Fix what you broke; never weaken, skip or silence a
   check to get green.
6. **Sync the docs** if `AGENTS.md` or `docs/product-idea.md` now states something
   false. Same commit.
7. **Tick the item** in `TASK.md` (`- [ ]` → `- [x]`).
8. **Commit** on branch `loop/continuous`: imperative subject under 72 characters,
   body explains why. Never push, never force-push, never rewrite history, never
   commit `config/master.key` or `.env`.
9. **Reply with at most 6 lines**: the item, what the tests prove, the commit sha,
   what is next. No essay.

## Preconditions

- If the current branch is not `loop/continuous`, create it from `master` and switch
  to it before the first commit.
- The database is reachable (`ruby bin/rails db:prepare`), role `hawker`, local.

## Frozen behaviour — never change without the user

From `docs/product-idea.md` §2: one hawker per deployment, no marketplace, no customer
ETA, no push to customers, availability and broadcast are separate states, going
offline voids requested stops and drops accepted ones with no confirmation, the
customer sees "The hawker stopped working", no schedule or obligation.

## Decisions are the user's, not yours

`TASK.md` has a **Needs a decision** section (plain bullets, not checkboxes). If an item
depends on one of those answers:

- Do **not** invent the behaviour.
- Add a plain bullet under **Blocked** in `TASK.md` naming the exact question.
- Leave the item unchecked only if nothing else can be done; otherwise skip to the next
  item and keep going.

Never turn a product question into a default. Guessing a payment model, an expiry
window or an address format costs more than waiting.

## Host controls — set by the `/loop` command, not by you

These run outside the model. Do not try to emulate or bypass them.

- `--verify "ruby bin/ci"` re-runs the gate. The checklist is only considered complete
  when the **host** has observed a success, so a green claim in chat changes nothing.
- `--pause-on-verify-fail` pauses the loop when the gate fails. That pause is a signal
  to fix the tree, not permission to move on. Do not delete or relax a check to escape
  it.
- `--max-failures 3` stops the run after three failed turns. Leave the working tree
  clean and the failure reproducible, or the next human cannot diagnose it.
- `--compact-every 20` compacts long runs. Keep each commit small so work survives
  compaction; a large uncommitted change is lost work.
- If the host pauses for review, stop and report. Never resume yourself.

## One progress file

`TASK.md` is the progress file. Do not create `progress.md`, and do not add checkboxes
anywhere else — the host reads this one file, and checkboxes in other files, including
examples inside code fences, are ignored.

## When to stop early

Stop the iteration, leave the tree clean, and report exactly what blocks it if:

- `ruby bin/ci` cannot pass for a reason outside your change (missing service, broken
  tool, network).
- A test cannot be written because the behaviour is undecided.
- The change would delete or rewrite data, change auth, or touch money — that needs the
  user first.
