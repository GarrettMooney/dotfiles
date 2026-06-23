---
name: mine-transcripts
description: Use when Garrett wants to find recurring corrections in his own past sessions and turn them into config — triggers like "/mine-transcripts", "mine my transcripts", "what do I keep correcting", "update my CLAUDE.md from my sessions", "find gaps in my setup". Scans session transcripts for correction signals, counts recurrence, and proposes CLAUDE.md / skill edits. This is the "close the loop" step — distinct from /fewer-permission-prompts (which only mines for an allowlist).
---

# Mine transcripts

Garrett's global `~/.claude/CLAUDE.md` is "derived from recurring corrections
across my sessions." This skill automates that derivation: read his own past
prompts, find where he repeatedly corrected, nudged, or re-asked, and propose
concrete config changes so the correction stops recurring.

Goal: a short, ranked list of **recurring** frictions, each with a proposed fix
(a CLAUDE.md line, a new/edited skill, or a settings hook). Not an exhaustive
dump — frequency is the signal.

## 1. Extract Garrett's prompts

Transcripts live in `~/.claude/projects/*/*.jsonl`. Only **user-typed** messages
matter (not tool results, not assistant turns). Pull recent ones — default to the
last ~30 days unless he says otherwise.

```bash
# user-typed prompts only: type==user, string content, not a tool_result array
find ~/.claude/projects -name '*.jsonl' -mtime -30 -print0 \
| xargs -0 cat 2>/dev/null \
| jq -rc 'select(.type=="user" and (.message.content|type=="string"))
          | .message.content' 2>/dev/null \
> /tmp/mine-prompts.txt
wc -l /tmp/mine-prompts.txt
```

If that yields little (some versions store content as an array), fall back to:
`jq -rc 'select(.type=="user") | (.message.content | if type=="string" then . else (map(select(.type=="text").text) | join(" ")) end)'`

## 2. Find correction signals

Correction signals are phrases that mean "you didn't do what I expected." Count
case-insensitive matches and, more importantly, read the surrounding prompt to
understand *what* was being corrected. Signal phrases:

- `no,` / `nope` / `that's not` / `not what I` — direct rejection
- `actually` / `instead` — redirect
- `can you also` / `you forgot` / `you missed` / `also need` — omission
- `did you` / `did you check` / `make sure you` — verification nag
- `still` (still wrong / still failing / still doing) — repeated failure
- `stop` / `don't` / `quit` — behavior to suppress
- `again` / `like I said` / `as I mentioned` — repetition
- `why did you` / `why are you` — unexpected action

```bash
grep -ioE "no,|nope|that'?s not|not what i|actually|instead|can you also|you forgot|you missed|did you check|make sure you|still (wrong|failing|broken|happening)|stop |don'?t |again|like i said|why (did|are) you" \
  /tmp/mine-prompts.txt | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn
```

The raw counts are a starting point, not the answer — many "actually"s are
benign. Read the actual prompts behind the high-count signals (grep them back
out with context) to find the *theme*.

## 3. Cluster into recurring themes

Group the corrections by what they're really about. Examples of themes worth
catching: a tool he always has to redirect you toward, a verification step he
repeatedly asks for, a formatting/output preference, a workflow he re-explains.
A theme only counts as "recurring" if it shows up across **multiple sessions**
(different files), not many times in one session.

## 4. Cross-check existing config

Before proposing anything, read what's already covered so you don't duplicate:
- `~/.claude/CLAUDE.md` (the contract)
- `~/.claude/guides/*.md`
- `~/.claude/skills/*/SKILL.md` (names + descriptions)
- `~/.claude/settings.json` (hooks, env)

A recurring correction that *is* already in config means the config isn't being
followed (maybe wrong wording, wrong file, or needs a hook instead of a rule) —
flag that distinctly from a genuinely missing rule.

## 5. Propose fixes (don't apply yet)

Output a ranked table. For each recurring theme:

```
| # | Theme | Sessions | Proposed fix | Target |
|---|-------|----------|--------------|--------|
| 1 | <what he keeps correcting> | <count> | <exact line or skill/hook> | CLAUDE.md / guide / skill / settings |
```

Then, for the top items, show the **exact diff** you'd make. Map fix type to the
verification ladder:
- Pure preference / phrasing → a CLAUDE.md or guide line.
- A repeated multi-step workflow → a new skill (offer to draft it).
- A mechanical, every-time action (format, lint, notify) → a settings hook, not
  a rule (rules get forgotten; hooks always fire).

Ask Garrett which to apply before editing anything. He prefers each rule to live
in exactly one place — when adding a line, check it doesn't overlap an existing
one.

## Notes
- Concise output. Lead with the ranked list; keep evidence brief (1 example
  prompt per theme is enough).
- Don't surface one-off frictions — frequency across sessions is the bar.
- Clean up `/tmp/mine-prompts.txt` when done.
