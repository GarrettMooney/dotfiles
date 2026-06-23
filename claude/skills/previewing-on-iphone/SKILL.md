---
name: previewing-on-iphone
description: Use when the session has produced a visual artifact (PNG, PDF, HTML, SVG, plot, diagram, screenshot, rendered report) that would be easier to inspect on a phone than in the terminal, or when the user asks to "show", "send", "preview", "pull up", or "view" something on their iPhone. Triggers include "send to my phone", "phone view", "look at this on iPhone", "preview on phone", or generating a chart/figure/PDF that the user will want to see.
---

# Previewing on iPhone

## Overview

Garrett has a persistent web app on his iPhone that mirrors `~/phoneview-inbox/`. Drop a file into a session subdirectory on the Mac and within about a second it shows up on the phone (the page holds a Server-Sent Events connection; the Mac pushes on change). Use this for any artifact that's annoying to inspect in a terminal: plots, PDFs, rendered HTML, diagrams, screenshots.

The phone app is already installed (Home Screen icon "Artifacts"). The Mac runs an always-on Go binary as a launchd LaunchAgent. You don't start anything; you just drop the file.

## When to use

- The session just produced a visual artifact (PNG, PDF, HTML, SVG, plot, diagram, screenshot).
- The user asks to show, send, preview, or view something on their phone.
- The user wants to glance at a result away from the keyboard.

## When NOT to use

- File is plain text or code: print it or open it in the editor.
- File needs to leave the tailnet (share with someone else): use a different mechanism. `phoneview` is tailnet-only.

## How

One command, from anywhere (the binary is on PATH):

```bash
phoneview-inbox send <file> [session]
```

`session` is optional: it defaults to the current directory's basename,
sanitized for URL safety. Pass it explicitly when the cwd name isn't a good
label (see "Naming"). The command creates the session dir, copies atomically
(no half-written artifacts on the phone), and prints the phone URL.

Then tell the user:

> Sent to your iPhone (Artifacts app, or https://garretts-macbook-air.tailefecb2.ts.net/). It appears within a second or two.

Fallback if the binary is somehow missing: `mkdir -p ~/phoneview-inbox/<session> && cp <file> ~/phoneview-inbox/<session>/`.

## Naming the session

- Working in a repo: use the repo basename (`clickstream-foundation`, `price-elasticity`).
- Working on a topic / one-pager / report: use a short topical label (`reviews`, `mmm`, `forecast`).
- Throwaway scratch: use something terse like `scratch` or the date (`2026-05-22`).
- Keep names ASCII, no spaces, no slashes. They become URL path components.

Don't try to create a session literally named `(loose)`; that label is reserved for the pseudo-session of root-level loose files (wire identifier `__phoneview_loose__`). Use a subdir.

## Multiple files

Drop them into the same session subdir. The phone shows them under one session header, newest first.

## Re-send after regenerating

The copy in `~/phoneview-inbox/` is a snapshot, not a live link. If you send an artifact and later regenerate it (re-run the script, edit, re-export), the phone still shows the old bytes. Re-`cp` it and confirm with `cmp -s <source> <inbox-copy>`. When asked "is X on my phone?", compare bytes, don't assume the earlier send is current.

## Discard

Discard happens from the phone (tap the `×` on a row, confirm). Files are permanently `rm`'d (no Trash). Don't try to discard from the Mac on the user's behalf unless asked; that's their UI.

## Troubleshooting

If the URL doesn't respond:

- `phoneview-inbox status` shows whether the launchd agent is loaded and the tailscale serve config.
- `phoneview-inbox setup` is idempotent; safe to re-run if anything drifted (e.g., after a Tailscale app reinstall).
- Logs at `~/.local/state/phoneview-inbox.log`.

## Reference

- Repo: `~/git/phoneview-inbox/` (Go, stdlib only, embedded static frontend).
- URL: `https://garretts-macbook-air.tailefecb2.ts.net/`.
- launchd label: `com.garrettmooney.phoneview-inbox`.
- Spec + plan: `~/work/docs/superpowers/{specs,plans}/2026-05-22-phoneview-inbox*.md`.
