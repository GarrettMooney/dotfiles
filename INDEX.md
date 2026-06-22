# ~ — Machine Index

Top-level map of how this machine is organized for working with AI. Read this first
to orient; then drop into the relevant sub-index. The two content trees each have
their own annotated `INDEX.md`; this file maps the *system* (config, skills, the loop)
that spans them.

Suggested reading order for a fresh session: **this file → `git/INDEX.md` or
`personal/INDEX.md` → the target dir's `CLAUDE.md`/`AGENTS.md`/README**.

## The two content trees

- **`~/git/`** — code repos (the `~/src` equivalent). Active projects + `learn-*`
  sandboxes. See **`~/git/INDEX.md`**.
- **`~/personal/`** — knowledge vault (the `~/vault` equivalent). Projects, notes,
  records, household. Not a git repo at the top level. See **`~/personal/INDEX.md`**.

Both are organized so models can retrieve context with `grep`/`glob`, and most dirs
carry a `CLAUDE.md` (often `→ @AGENTS.md`) onboarding doc.

## Config & taste (`~/.claude/`)

- **`CLAUDE.md`** — global behavior contract (communication, git/PR, code, project
  conventions). Symlinked from `~/git/dotfiles/claude/`.
- **`settings.json`** — harness config: hooks, plugins, permissions. The
  verification ladder's bottom rung lives here (PostToolUse `ruff format`/`check --fix`).
- **`guides/`** — lazy-loaded references, pulled in only "when relevant":
  - `evals.md` — Shankar/Husain eval methodology.
  - `worklog-workflow.md` — how `/daily`, `/handoff`, `/worklog` fit together.
- **`skills/`** + plugin skills — recurring workflows. Invoked as `/<name>`.
- **memory** (`projects/-Users-garrettmooney/memory/`) — durable facts/preferences,
  indexed by `MEMORY.md`, loaded each session.

## The close-the-loop system

```
morning   /daily ──► reads worklog → today's priorities
work      do the task (worktrees, parallel sessions, /pair watcher for long runs)
finish    branch → /polish (review→simplify→verify→PR, auto-logs)
          other  → /worklog  ("log it")
record    ~/personal/worklog.md (newest-first, append-only)
refine    /mine-transcripts (ADD rules) → /config-audit (PRUNE rules)
          → tighter config → sharper next /daily and /polish
```

- **Record:** `~/personal/worklog.md`, `~/personal/TODO.md`.
- **Add config:** `/mine-transcripts` mines sessions for recurring corrections.
- **Prune config:** `/config-audit` de-dupes and resolves conflicts (each rule in
  exactly one place).
- **Explore cheaply:** `cs` alias = `CLAUDE_CODE_SIMPLE=1 claude` (CLAUDE.md without
  the agentic harness/hooks/skill loops).

## Conventions

- Each rule lives in exactly one place: global behavior → `~/.claude/CLAUDE.md`; repo
  convention → repo `CLAUDE.md`; project fact → project dir. `/config-audit` enforces this.
- `CLAUDE.md` → `@AGENTS.md` delegation is intentional (cross-tool routing), not duplication.
- When a landmark changes, update the nearest `INDEX.md` (this one for system-level).
