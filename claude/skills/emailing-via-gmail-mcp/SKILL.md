---
name: emailing-via-gmail-mcp
description: Use when asked to send, reply to, or forward email via the claude_ai_Gmail MCP, especially when attaching a local file (resume, PDF, document) to an email or replying in an existing thread. Covers the draft-only and attachment limitations so you plan correctly instead of discovering them mid-task.
---

# Emailing via the claude_ai_Gmail MCP

## Overview

The `mcp__claude_ai_Gmail__*` tools are **draft-only and effectively cannot attach local files**. Know both limits *before* you start so you give the user a correct plan up front instead of wasting effort and discovering the wall mid-task.

## Two hard limitations

1. **No send.** There is no send tool. The only write tool is `create_draft`. You create a draft; **the user must press Send.** Never claim you "sent" or "replied to" an email.

2. **No reliable local-file attachments.** `create_draft` has an `attachments[].content` field (base64), but:
   - The tool's own description says attachment creation is "not supported yet."
   - Even if it worked, you author tool params token-by-token. You **cannot** reproduce a large base64 blob (a 47 KB PDF ≈ 63 KB base64) verbatim, and one wrong char corrupts the file.
   - So: **do not base64-encode a real document hoping to attach it.** A few KB of inline text/data is the practical ceiling.

## Correct workflow

**Reply with an attachment** (the common "reply to X with my resume" case):
1. State the limitation **first**: "I'll draft the reply; you'll need to attach the file and send, because this Gmail integration can't attach local files or send."
2. Locate the file (latest resume: `find ~ -iname '*resume*.pdf' -exec ls -lt {} +` and take the newest mtime).
3. `search_threads` (Gmail query syntax: `from:`, `subject:`, `"exact phrase"`) → get the thread + message id.
4. `get_thread` with `FULL_CONTENT` to read context and write an on-point reply.
5. `create_draft` with `replyToMessageId: <message id>`, `to`, `subject: "Re: ..."`. Body is appended to the original.
6. Tell the user the manual steps: Gmail → Drafts → that reply → attach `<path>` → Send. Quote the draft body so they can review.

**Plain send:** same, minus `replyToMessageId`.

## Do NOT

- **Don't hunt for alternative send credentials** (SMTP, OAuth tokens, gcloud, scanning project dirs for secrets) to work around the limits. It trips credential-exploration guards and is the wrong instinct. Surface the limitation to the user and let them decide.
- **Don't encode the file before confirming attachment is even viable.** It wastes a turn and floods context with base64.
- **Don't say "done / sent."** Say the draft is ready and what's left for the user.

## Quick reference

| Need | Tool | Note |
|------|------|------|
| Find an email | `search_threads` | Gmail query syntax; returns thread + message ids |
| Read full body | `get_thread` | use `messageFormat: FULL_CONTENT` |
| Draft a reply | `create_draft` | set `replyToMessageId`; body appended to original |
| Send | — | no tool; user sends manually |
| Attach local file | — | not viable; user attaches in Gmail |
