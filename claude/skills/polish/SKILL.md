---
name: polish
description: Use when a chunk of work feels done and you want it merge-ready before opening a PR. Runs the finish ladder over the current diff (review, simplify, verify) and drafts a PR description. Triggers - "polish this", "/polish", "make this merge-ready", "finish this branch", "tidy up before PR", "ready to ship?". NOT for mid-implementation cleanup of a single function (use /simplify) or hunting for bugs in code you are still writing (use /code-review directly).
---

# polish

The finish ladder for a branch: take work that is functionally complete and make
it merge-ready. One pass, cheap-to-expensive, stopping early if a layer fails.

Run against the **current diff** (uncommitted + commits ahead of the base branch).
If the working tree is clean and there is nothing ahead of base, say so and stop.

## The ladder (run in order)

1. **Scope check.** `git diff --stat` against the base branch. Confirm the diff is
   all one logical change. If it sprawls into unrelated edits, flag them and ask
   before continuing - polishing a mixed-bag diff hides problems.

2. **Correctness review.** Invoke `/code-review` on the diff. Triage findings:
   fix the real bugs now; for anything uncertain or out-of-scope, list it and let
   the user decide. Do not perform agreement - if a finding is wrong, say why and
   skip it (the `superpowers:receiving-code-review` discipline applies).

3. **Quality pass.** Invoke `/simplify` for reuse / dead-code / altitude cleanups.
   Keep the diff scoped: do not reformat or refactor untouched code.

4. **Verify it runs.** Don't claim it works from reading the diff
   (`superpowers:verification-before-completion`). In order of what exists:
   - tests: run the project's suite (or the targeted tests for the change).
   - Python: `/astral:ruff` and `/astral:ty` are the bar; the PostToolUse ruff hook
     already formatted on save, so this is the lint/type gate.
   - evals: if the change touches an LLM pipeline, see `~/.claude/guides/evals.md`.
   - behavior: if it's a runnable app/feature, use `/verify` or `/run` to exercise it.
   Paste the actual command output. If a layer fails, fix and re-run from step 2.

5. **Draft the PR description.** Only after 1-4 are green. Write it with the
   `writing-clearly-and-concisely` skill. Structure:
   - **What** changed and **why** (the problem, not a file-by-file narration).
   - **How verified** - the commands you actually ran and their results.
   - Risks / follow-ups worth a reviewer's attention.
   No AI attribution, no `Co-Authored-By: Claude`, no reviewers unless named
   (per the global contract). Output the draft for approval; do not push or open
   the PR unless explicitly asked.

6. **Log it.** After the PR draft is approved (or the branch is otherwise
   finished), invoke `/worklog` to append a dated entry to `~/personal/worklog.md`
   with the PR/doc link and any follow-ups. Skip only for trivial one-offs.

## Notes

- This is a quality + readiness gate, not a bug hunt. Deep bug-finding is
  `/code-review` at high/ultra effort; run that separately if the change is risky.
- Stop and report at the first layer that needs a human decision rather than
  guessing. A half-polished diff with a clear flag beats a confident wrong fix.
