---
name: todo-sweep
description: Use when the user wants to review, triage, or update their personal todos — triggers like "/todo-sweep", "sweep my todos", "what should I do today", "update my todo list", "triage my todos". Reads ~/personal/TODO.md and ~/personal/shared-todos/, surfaces stale/duplicate items, and proposes a prioritized short-list.
---

# Todo Sweep

Triage Garrett's personal todos into a short, current, prioritized list. The goal
is a focused "what to do next," not a reorganization of everything.

## Sources
- `~/personal/TODO.md` — personal priority + bucketed list.
- `~/personal/shared-todos/` — shared task system (read docs/next-steps.md if present).
- Optional, only if the user asks: scan calendar/email via the connected Gmail/Calendar MCPs for time-sensitive items.

## Steps
1. Read `~/personal/TODO.md` and `~/personal/shared-todos/docs/next-steps.md` (if it exists).
2. Flag, but do not auto-delete:
   - **Duplicates** (e.g. repeated "reach out about stomach doctor").
   - **Stale** items with past dates already mentioned (e.g. "Jim said 2025-03-31 for attic estimate").
   - Items that read as already-done.
3. Produce a **Top 5 for now** list, ordered by urgency × importance. Lead with anything time-sensitive (calls, forms, deadlines).
4. Present the triage as a concise table/list. Ask before editing `TODO.md`.
5. If the user confirms, rewrite `TODO.md`: keep the `# priority` / bucket structure, move completed items out, collapse duplicates, and append a dated `## swept YYYY-MM-DD` note. Use today's date from session context — never invent one.

## Style
- Be concise. Garrett prefers short, direct output (no preamble).
- Don't add items the user didn't ask for.
- Don't reorganize the whole file unless asked — minimal diff.
