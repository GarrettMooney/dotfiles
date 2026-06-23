---
name: pair
description: Use when a long or autonomous coding/agent session could drift off-spec and you want a fresh-context second model supervising the primary agent and nudging it back. Triggers (intent-bearing phrases, not single words): "pair a watcher with my session", "supervise this run", "keep the agent on track", "catch drift" / "guard against drift", "is the agent off-spec", "babysit my agent", "re-anchor me to the spec", "watch the watcher", "mwm", or any request to set up / launch the pair watcher harness. NOT for one-off "watch this file/build/deploy" requests (that is loop/agent-browser/verify).
---

# pair

A fresh-context **watcher** model periodically reads a `mission.md` spec plus the
primary agent's recent turns, judges whether the primary is drifting off-spec, and
injects a one-line course-correction into the primary's tmux pane when it is.

Catches two failure modes a long autonomous run drifts into: **execution drift**
(wrong turn in the weeds) and **direction drift** (solving the wrong problem).

Harness lives at `~/pair` (local git repo, no remote). Requires
`tmux`, `jq`, and a judge CLI (`claude -p` by default).

## When to use

- A coding/agent session will run a while unattended and could wander off-spec.
- You want a second, fresh-context model checking the primary against its mission.
- You're the *primary* and want a safety net that re-anchors you to the spec.

**Not for:** short interactive tasks (the overhead isn't worth it), or anything
where you're already reviewing every turn yourself.

## Quick start

```bash
cd ~/pair
cp mission.md /tmp/my-mission.md   # then edit: put the real spec under ## Spec
bin/bootstrap.sh /tmp/my-mission.md
tmux attach -t pair                # pane 0 = primary agent, pane 1 = watcher loop
```

`bootstrap.sh` creates the two-pane `pair` session, seeds the primary to read the
mission, and starts the watcher loop in the other pane.

## How it works (one tick)

`watch-loop.sh` runs `tick.sh` every `INTERVAL` seconds:

1. `read-transcript.sh N` — primary's last N turns (from the claude transcript, or `tmux capture-pane`).
2. `judge.sh mission.md` — fresh model compares spec vs. turns → verdict JSON `{drifting, severity, correction}`. Defaults to *not drifting*; invalid output is coerced to a safe no-op.
3. Verdict is appended to `watch.log`.
4. Gate: inject only if `drifting=true` **and** `severity >= SEVERITY_MIN`.
5. `inject.sh` — waits for the primary pane to be idle, then `send-keys` the correction and appends it to the mission `## Log`.

## Configuration (env vars)

| Var | Default | Purpose |
|-----|---------|---------|
| `INTERVAL` | `300` | seconds between ticks |
| `N` | `30` | primary turns the watcher reads |
| `HARNESS` | `claude` | `claude` (read `TRANSCRIPT_PATH`) or `pane` (capture tmux pane) |
| `TRANSCRIPT_PATH` | — | claude-mode transcript jsonl |
| `PANE` | `pair.primary` | primary pane the watcher reads/injects |
| `SESSION` | `pair` | tmux session name |
| `PRIMARY_CMD` | `claude` | command run in the primary pane |
| `SEVERITY_MIN` | `medium` | min severity that triggers an injection (`low`/`medium`/`high`) |
| `JUDGE_CMD` | `claude -p` | the judging model CLI (gets the prompt on stdin) |
| `IDLE_PATTERN` / `IDLE_TIMEOUT` | `> $` / `30` | how `inject.sh` detects an idle prompt before sending |

## Gotchas

- **Bias toward silence:** the judge defaults to *not drifting* and any malformed verdict becomes a no-op — false positives are the expensive failure, so it under-injects by design. Lower `SEVERITY_MIN` to `low` if it's too quiet.
- **Idle guard:** if the primary pane never matches `IDLE_PATTERN`, the tick is skipped (won't interrupt mid-generation). Tune `IDLE_PATTERN` to your prompt.
- **`mission.md` and `watch.log` are gitignored** — they're per-run state, not committed.
- **Safe dry run:** set `PRIMARY_CMD=cat`, `HARNESS=pane`, and point `JUDGE_CMD` at a stub to exercise the wiring without spawning a real agent (see the safe smoke test pattern).
- It spawns a real second agent and real `claude -p` judge calls by default — that's real token spend on a timer.
