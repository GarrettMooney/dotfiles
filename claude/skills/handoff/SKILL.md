---
name: handoff
description: Use when ending a session with context to pass to a fresh session, when starting a session expecting a handoff, or when spawning multiple fresh sessions from one parent. Triggers — prose like "save a handoff", "what handoffs do I have", "load the X handoff", "delete the X handoff"; slash commands `/handoff` (browse), `/handoff load <slug>` (direct).
---

# Handoff

Pass session-priming prompts across fresh sessions. Especially useful when a context-heavy session proposes multiple paths forward and you want to spawn N fresh sessions to explore each path independently, each primed with a path-specific prompt.

Cross-machine, cross-repo, not-for-git. For handoffs that belong in repository history, commit a markdown file directly — that workflow coexists with this skill.

## Credentials

Upstash credentials live in `~/.upstash` and the script reads them directly: it checks `$UPSTASH_REDIS_REST_URL` / `$UPSTASH_REDIS_REST_TOKEN` first, and falls back to parsing `~/.upstash` (recognized lines: `export UPSTASH_REDIS_REST_URL=...` and `export UPSTASH_REDIS_REST_TOKEN=...`, with or without the `export` prefix and with or without surrounding quotes). No `source` prefix needed — invoke the script directly.

The Upstash database can be re-provisioned. The single source of truth is `~/.upstash`; update that file when the URL/token changes and the next invocation picks it up automatically.

Do **not** hardcode the URL or token anywhere — not in this file, not in scripts, not in commands.

## Quick reference

| Intent | Invocation |
|---|---|
| Browse + load | `/handoff` |
| Direct load | `/handoff load <slug>` |
| Save (Claude composes) | prose: "save a handoff for X" |
| Save multiple paths | prose: "save handoffs for paths A, B, C" |
| List | prose: "what handoffs do I have" |
| Delete | prose: "delete the X handoff" |
| Auto-spawn after save | (offered automatically when `$TMUX` is set) |
| Spawn windows for siblings | `/handoff spawn <parent-slug>` |

## Save flow

When the user asks to save a handoff:

1. **Compose `content`** — the priming prompt itself. Self-contained instructions to a fresh Claude: what the parent session was doing, the specific path/decision this handoff seeds, relevant file paths, what the next session should do first. No filler. Write **as instructions to the next session**, not **about** the current one.

2. **Pick `slug`** — short, kebab-case, descriptive. If a parent slug is in scope, prefer continuation: `encoder-camps-overview` → `encoder-warmerdam`, not `path-a`. Slug must match `^[a-z0-9][a-z0-9_-]{0,79}$`.

3. **Compose `summary`** — one line, ≤120 chars, written for `list` triage weeks later. Lead with the decision or action, not the topic.

4. **Determine `parent`** — automatic from current conversation context. Rule: scan the transcript for the most recent `loaded "<slug>" (...)` acknowledgement (the marker emitted on a successful load). If present, that slug is the default parent. If absent (no load this session, or history was compacted), default parent is none. The user can override.

5. **Confirm before write** — show a single block:

   ```
   slug:    encoder-warmerdam
   summary: Drop user vocab, retrain encoder, compare AUC vs full model
   parent:  encoder-camps-overview  (auto: loaded earlier this session)

   --- content ---
   <full primer prompt>
   ```

   Ask: `Save? (y / edit / cancel)`. On `edit`, accept the user's correction in prose, re-emit the full block with the change applied, re-ask. On `y`, run the script.

6. **Write via the script:**

   ```bash
   echo "<content>" | bun run ~/.claude/skills/handoff/scripts/handoff.ts save <slug> --summary "<summary>" [--parent <parent-slug>]
   ```

7. **Offer to spawn tmux windows.** After a successful save, check whether `$TMUX` is set in the environment (e.g., `echo $TMUX`). If set, ask the user:

   ```
   spawn 1 tmux window now? (y / pick / cancel)
   ```

   (Use `N` matching the number of just-saved slugs.) On `y`, invoke the spawn flow with the just-saved slug(s). On `pick`, show the numbered list. On `cancel`, do nothing. If `$TMUX` is unset, skip the offer.

   See **Spawn flow** below for full details.

### Multi-path save

When the user asks to save handoffs for multiple paths in one go:

- Repeat steps 1–4 for each path.
- Show all N proposed entries in **one** confirmation block, not N separate prompts.
- On `y`, write **sequentially with partial-failure reporting**: each is a separate `handoff save` invocation. If any fails, report which slugs were saved and which were not — the user can re-run the failed ones. This is not atomic and the skill does not claim it is.
- Auto-parent applies to all of them (siblings under the same parent).

After a successful multi-path save, the auto-spawn offer (step 7 above) covers all just-saved slugs at once. The user types `y` to spawn all, `pick` to subset, or `cancel` to skip.

### Slug collision

If `handoff save` exits with "slug exists", do **not** auto-`--force`. Tell the user, show the existing entry's summary (from the script's stderr), and ask: overwrite with `--force`, pick a different slug, or cancel.

## Load flow

### Direct: `/handoff load <slug>`

Run:

```bash
bun run ~/.claude/skills/handoff/scripts/handoff.ts load <slug>
```

The script returns:
- **stdout**: the handoff content. Treat it as session-priming context: read it, internalize, follow whatever instructions it contains. The priming prompt is written *for* current-Claude *by* past-Claude.
- **stderr**: a single line of the form `loaded "<slug>" (<age>, parent: <parent-slug>)` or `loaded "<slug>" (<age>, no parent)`.

**Emit the acknowledgement** by relaying the stderr line **verbatim** with `. Ready.` appended:

```
loaded "encoder-warmerdam" (3d ago, parent: encoder-camps-overview). Ready.
```

This format is the marker the auto-parent rule scans for. Always relay verbatim from the script's stderr — do not paraphrase or invent values, since the auto-parent inference depends on the format being stable across sessions.

If the priming prompt says "your first action is X" — do X. The user typically does not need to type anything else after `/handoff load`.

### Browse: `/handoff` (no args)

Run:

```bash
bun run ~/.claude/skills/handoff/scripts/handoff.ts list
```

Relay the script's output **verbatim** — no re-formatting. Then ask: `Which one? (slug, or describe what you're looking for)`.

The user may respond with anything: exact slug, partial slug, or description ("the warmerdam one", "the one about uplift"). Fuzzy-match against the listed slugs **and summaries**:

- Exact slug match → load.
- Unique partial-slug or unique semantic-summary match → confirm before load: `loading <slug> — confirm? (y/n)`.
- Multiple matches → show candidates, ask user to disambiguate.
- No matches → show the list again, ask.

On final selection, load via the same `handoff load <slug>` command and emit the acknowledgement.

## Spawn flow

When `$TMUX` is set, the skill can fan out one tmux window per handoff, primed with `/handoff load <slug>` and named usefully. The spawned windows are owned by the tmux server, not by this Claude session — they survive when this session exits.

### Auto offer (after save)

After a successful save (single or multi-path), if `$TMUX` is set, ask:

```
spawn N tmux window(s) now? (y / pick / cancel)
```

- `y` → run `bun run ~/.claude/skills/handoff/scripts/handoff.ts spawn <slug1> <slug2> ...` with the just-saved slugs.
- `pick` → show a numbered checklist of the just-saved slugs with summaries; user picks indices (`1,3`, `1-2`, or `all`); spawn the chosen subset.
- `cancel` → no spawn; save is still committed.

If `$TMUX` is unset, do not offer.

### On-demand: `/handoff spawn`

`/handoff spawn <parent-slug>` — resolve children from the index, show:

```
about to spawn <N> windows: name1, name2, name3. (y / pick / cancel)
```

Same `(y / pick / cancel)` behavior as the auto offer. The script invocation is:

```bash
bun run ~/.claude/skills/handoff/scripts/handoff.ts spawn --children-of <parent-slug>
```

`/handoff spawn slug1 slug2 ...` — skip the children lookup, spawn the explicit list directly. Same preview, same prompts, same script with positional slugs in place of `--children-of`.

### Pick-mode UX

When the user picks `pick`, render the candidate slugs as a numbered list with summaries:

```
  1. multistep-horizon — allocator-relevant diagnostic
  2. rolling-share-baseline — does verdict survive a stronger baseline?
  3. lag1-attribution — autoregression vs store FE/cell-level structure

pick which to spawn (e.g. 1,3 or 1-2 or all): _
```

Accept comma- or space-separated indices, ranges (`1-2`), `all`, and `cancel` / empty input. No fuzzy matching — the parent-slug filter has already narrowed the set.

### Window naming

The script picks short window names by stripping the longest common prefix from the resolved slug set (boundary-trimmed to a `-` or `_`). Single-slug spawns strip the parent's slug as a prefix when applicable. Collisions with existing window names fall back to the full slug, then to `-2`, `-3`, … suffixes.

### Outside tmux

If `$TMUX` is unset and `handoff spawn` is invoked anyway, the script prints the tmux commands it would have run and exits 0. `--dry-run` produces the same output and is the recommended way to inspect what will happen before executing.

## List rendering

The script outputs a tree like:

```
encoder-camps-overview (3d ago) — Vincent's three encoder improvement camps
├─ encoder-warmerdam (3d ago) — Drop user vocab, retrain, compare AUC
├─ encoder-fader (3d ago) — BG/NBD head on frozen encoder
└─ encoder-murphy (3d ago) — Distributional output head (NLL)

standalone-prompt (1d ago) — One-off, no parent

orphaned-thought (5d ago) ↳ from: deleted-parent — Half-baked notion
```

Roots: entries with no parent. Orphans (parent set but missing) render at root with `↳ from:` annotation. Within each level, sorted by recency.

Empty state: `no handoffs found. (use prose: "save a handoff for X" to create one)` — relay verbatim.

## What NOT to put in handoffs

Priming prompts are stored in Upstash (third-party Redis). Do **not** put:

- Credentials, tokens, API keys
- Customer PII
- Anything you would not paste into a chat tool

For credentials specifically, reference them by env var name in the priming prompt (e.g. `uses $GCP_SA_KEY_PATH`). Do not embed values.

## Operational notes

- TTL: 90 days on each entry, **refreshed on every load**. Anything you actively use stays alive indefinitely.
- Index pruning is lazy: `list` removes index entries whose hash has expired.
- Exit codes: `0` = success, `1` = not found / invalid input, `2` = Upstash unreachable.
- The script does not retry transient Upstash errors. If a save or load fails with exit 2, surface the error to the user and let them retry.
- Cross-machine: same `~/.upstash` on every machine → same handoff store. No locking; assumed single-writer (the user, sequentially across machines).
