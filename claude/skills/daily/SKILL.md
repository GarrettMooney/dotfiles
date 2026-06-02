---
name: daily
description: Use when Garrett wants a morning briefing / daily standup for himself — triggers like "/daily", "daily brief", "what's on today", "morning rundown", "plan my day". Pulls calendar, email, todos, and open PRs into one prioritized note.
---

# Daily

Assemble a single prioritized morning brief from four sources and save it to a
dated file. Goal: a 30-second read that answers "what matters today and what's
on fire," not an exhaustive dump.

## Gather (in parallel where possible)

1. **Calendar** — today's events via the `gog` CLI:
   `gog --gmail-no-send -a garrettrmooney@gmail.com calendar events --today --json`
   Note start times, conflicts, and anything needing prep (e.g. forms to bring).
2. **Email** — unread/recent threads via the `gog` CLI:
   `gog --gmail-no-send -a garrettrmooney@gmail.com gmail search "is:unread newer_than:2d" --json`
   (also try `is:important is:unread` if light). Only surface threads that plausibly need a reply or action.

   Notes on `gog`: always pass `--gmail-no-send` (agent safety — the OAuth token is read-write `gmail.modify`/full `calendar`, so this is the guardrail). Tokens live in the macOS Keychain. If a command errors with an auth/token problem, run `gog auth doctor` and note it; re-auth is `gog auth add garrettrmooney@gmail.com --services gmail,calendar`.
3. **Todos** — glance at `~/personal/TODO.md` and `~/personal/shared-todos/`. Pull the few most urgent/time-sensitive items. This is a *glance*, not a rewrite — for triage use `/todo-sweep`.
4. **Code** — open PRs and dirty branches:
   - `gh search prs --author=@me --state=open --limit 20` (PRs awaiting you, across all repos).
   - Local repos that are dirty or ahead: scan git dirs under `~/git` and `~/personal` (e.g. `for d in ~/git/*/ ~/personal/*/; do git -C "$d" status -s 2>/dev/null | grep -q . && echo "$d dirty"; done`). Keep it brief.

If a source errors or isn't authenticated, note it in one line and continue — never block the whole brief on one source.

## Synthesize & save

- Get today's date with `date +%F` — never invent a date.
- Write to `~/personal/daily/YYYY-MM-DD.md` (`mkdir -p ~/personal/daily` first). If the file exists, overwrite only after showing the user; otherwise create it.
- End with a one-line **Focus** call: the 1–3 things that actually matter today.
- After writing, print the path and a 3–5 line digest to the terminal. Be concise — no preamble.

## Output template

```markdown
## Daily — YYYY-MM-DD

**Calendar**
- HH:MM event (prep note if any)

**Needs reply** (N)
- sender — subject

**Top todos**
1. item
2. item

**Code**
- PR #123 awaiting review · repoX dirty

**Focus:** the 1–3 things that matter today.
```

## Notes
- Garrett prefers concise, direct output. Don't editorialize.
- Don't send email, accept invites, or modify todos/PRs — this is read-only briefing unless he asks.
