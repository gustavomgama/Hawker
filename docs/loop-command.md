# Loop invocation

Copy-paste. This is the exact `/loop` command for this project; `docs/loop-prompt.md`
is the procedure it injects, `TASK.md` is the backlog it reads.

```text
/loop --safe --ask-never --progress-file TASK.md --prompt-file docs/loop-prompt.md --until-checklist-complete --verify "ruby bin/ci" --pause-on-verify-fail --max-failures 3 --max-runs 30 --max-runtime 3h --compact-every 20 Work TASK.md: one item per iteration.
```

## Flags

| Flag | Why this project needs it |
| --- | --- |
| `--safe` | never injects a turn on top of active work |
| `--ask-never` | runs unattended |
| `--progress-file TASK.md` | the backlog, and the only file whose checkboxes the host reads |
| `--prompt-file docs/loop-prompt.md` | the procedure, injected by the host instead of relying on the model to open it |
| `--until-checklist-complete` | the real stop: host-checked, not a model claim |
| `--verify "ruby bin/ci"` | the gate is re-run by the host; a chat claim of green counts for nothing |
| `--pause-on-verify-fail` | a red gate pauses instead of stacking broken work |
| `--max-failures 3` | stops a loop that keeps failing |
| `--max-runs 30` | turn-count backstop for 12 backlog items |
| `--max-runtime 3h` | wall-clock backstop |
| `--compact-every 20` | compacts the session every 20 loop turns |

## Compaction, specifically

Two independent mechanisms, not one:

1. **Project auto-compaction** — `opencode.jsonc` sets `compaction.buffer: "93%"`, so
   OpenCode compacts by itself at roughly 70k tokens used on a 1M-context model. Works
   with no flags.
2. **Loop-driven compaction** — `--compact-every 20` asks Loop to trigger a session
   compaction every 20 turns, so a long unattended run does not creep toward the limit
   and compact at the worst possible moment.

The value can be a turn count (`20`) or a duration — the README's own worked example
uses `--compact-every 200m`. Pick one, not both.

**Capability-gated.** Loop's explicit compaction requires the host to expose
`session.compact`; older hosts reject it before scheduling, and a native compaction
waits for a terminal event before the next turn. If the flag is rejected, the project
level auto-compaction above still protects the session — check `/loop-status` after
starting and drop `--compact-every` rather than fighting the host.

## Operating it

```text
/loop-status      jobs, runs, failures, pause reasons
/loop-pause       pause without losing the job
/loop-resume      resume
/loop-stop        stop
/loop-clear       remove all jobs for this session
/loop-doctor      diagnose when a job says enabled but never runs
```

You must issue these yourself. Asking the model to print `/loop-stop` does not invoke
the command.

`--safe` reduces risk, but it is not a permission sandbox. For unattended work the
README recommends granting routine read, edit and test operations while keeping
destructive shell commands on ask or deny. It never pushes: the prompt commits to
`loop/continuous` and stops there.
