---
name: worklog
description: Use when Garrett finishes a substantial task or branch and wants it recorded — triggers like "/worklog", "log this", "add to the worklog", "note what I did". Also invoked by /polish after a PR draft. Appends a dated, newest-first entry to ~/personal/worklog.md with links and follow-ups. NOT for morning planning (use /daily) or session handoff (use /handoff).
---

# Worklog

Append a short record of finished work to `~/personal/worklog.md`. This is the
"close the loop" log: it accumulates what got done so `/daily` and config
refactors have ground truth. Keep it terse — a log, not a report.

## When to log
- A branch reached merge-ready / a PR was opened.
- A substantial task finished (a doc shipped, an analysis delivered, a system set up).
- Skip trivial one-offs and pure exploration — log outcomes, not activity.

## Steps
1. Read the top of `~/personal/worklog.md` to match the existing entry format.
2. Compose one entry, **newest-first** (insert directly below the `---` separator,
   above the previous newest entry):

   ```
   ## YYYY-MM-DD — <short title>
   - **What:** one line — what got done and why.
   - **Links:** PR/doc/commit URLs or paths (omit the line if none).
   - **Follow-ups:** anything left open (omit the line if none).
   ```

3. Use today's date from session context — never invent one.
4. Pull links from the actual work (PR URL, doc path, commit). Don't fabricate URLs.
5. Append and confirm in one line. Don't restate the whole entry back.

## Style
- Concise, direct, no preamble (global contract). No AI attribution.
- One entry per task. If several small things finished, one entry with a short
  bulleted "What" beats many stubs.
- Don't reorganize or rewrite older entries — minimal diff, append only.
