---
name: config-audit
description: Use when Garrett wants to prune and de-duplicate his Claude config — triggers like "/config-audit", "audit my config", "clean up my CLAUDE.md", "find conflicting rules", "is anything duplicated in my config". The pruning counterpart to /mine-transcripts (which only adds rules). Surfaces overlapping/contradicting rules and stray directory-level settings so each rule lives in exactly one place.
---

# Config audit

`/mine-transcripts` *adds* rules to the config. Nothing *prunes* them, so over time
the config drifts toward overlap and contradiction. This skill is the periodic
refactor pass: **each rule or preference should live in exactly one place.**

Run it occasionally (monthly, or after a few `/mine-transcripts` rounds). It proposes
edits; it does not apply them without confirmation.

## What to scan

1. **Global contract** — `~/.claude/CLAUDE.md`.
2. **Lazy-loaded guides** — `~/.claude/guides/*.md` (referenced from the global file).
3. **Project/repo configs** — every `CLAUDE.md` / `AGENTS.md` under `~/git` and
   `~/personal`. Find them: `find ~/git ~/personal -maxdepth 3 \( -iname CLAUDE.md -o -iname AGENTS.md \) 2>/dev/null`.
4. **Settings** — `~/.claude/settings.json` (symlinked into dotfiles) plus any stray
   directory-level `settings.json` / `.claude/settings.json` that drifted out of the
   global one: `find ~/git ~/personal -maxdepth 3 -name 'settings*.json' 2>/dev/null`.
5. **Memory** — `~/.claude/projects/-Users-garrettmooney/memory/` (duplicate facts).

## What to flag

- **Duplication** — the same rule stated in two files. Keep the most-scoped correct
  home; delete the rest. (Global behavior → global `CLAUDE.md`; repo convention → repo
  `CLAUDE.md`; project fact → project dir.)
- **Contradiction** — two files giving conflicting instructions (e.g. global says X,
  project says not-X). Surface both; ask which wins; note that project overrides global.
- **Stale** — rules referencing files/skills/flags that no longer exist. Verify the
  target exists before keeping a rule that names it.
- **Bloat** — a long block in a `CLAUDE.md` that should be a lazy-loaded
  `~/.claude/guides/<topic>.md` referenced "when relevant" instead of always loaded.
- **Stray settings** — directory-level `settings.json` that should fold back into the
  global one. (Do NOT flag the intentional `CLAUDE.md` → `@AGENTS.md` delegation pairs;
  that duplication is deliberate cross-tool routing.)

## Output

A short report, grouped by the categories above. For each finding: the rule, every
file it appears in, and the single recommended home. Then ask which to apply. Apply
only confirmed edits, keeping diffs scoped (do not reword untouched rules).

## Relationship to the loop

`/mine-transcripts` (add) → `/config-audit` (prune) → tighter config → sharper
`/daily` and `/polish`. See `~/.claude/guides/worklog-workflow.md` for the wider loop.
