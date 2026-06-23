---
name: publishing-claude-skills-as-plugins
description: Use when turning a gist, loose SKILL.md, or local skill directory into a GitHub repo installable via /plugin in Claude Code — packaging someone else's skill (attribution/licensing), un-flattening gist `__` paths, writing marketplace.json/plugin.json, or "install the skill from claude".
---

# Publishing Claude Skills as Plugins

## Overview

A skill becomes installable in Claude Code by wrapping it in a **plugin** that a **marketplace manifest** (a JSON file in the same GitHub repo) points to. Users then run two `/plugin` commands. There is no `npx`, npm registry, or `skill install` — the marketplace manifest *is* the install mechanism.

## Step 0 — Attribution FIRST (the judgment call)

**If the skill is not yours (someone's gist, another repo), do this before anything mechanical:**

- **Do NOT invent a license.** You cannot relicense someone else's code. If the source has no license, add **none** of your own — adding MIT to unlicensed work is wrong.
- **Credit the author**: a `README.md` and `ATTRIBUTION.md` naming the original author and linking the source, stating this is a *credited redistribution* with no ownership claim.
- **Preserve original content verbatim**; only change directory structure and add packaging metadata.
- If the source *does* have a license, **keep that license file** and bundle it (e.g. a vendored font/asset → bundle its LICENSE next to it).

Skipping this is the most common and most damaging mistake. Mechanics are recoverable; misattribution is not.

## Step 1 — Un-flatten gist paths

Gists can't hold folders, so they encode them with `__`. Restore real directories:

`references__principles.md` → `references/principles.md` · `demo__a.html` → `demo/a.html`

Then **grep the SKILL.md for `__`** and rewrite any internal links to the folder paths. This is the #1 breakage in gist→repo moves.

## Step 2 — Repo layout (root-as-plugin = simplest)

```
my-repo/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md            # keeps its own name/description frontmatter
│       ├── references/*.md
│       └── demo/*.html
├── README.md
└── ATTRIBUTION.md              # if redistributing
```

The whole repo *is* the plugin (`source: "./"`). Skills auto-discover from `skills/<name>/SKILL.md` — do not list them in plugin.json.

## Step 3 — Manifests (verified schema)

`.claude-plugin/marketplace.json` — `owner.name` is **required** (object, not string):
```json
{
  "name": "<marketplace-name>",
  "owner": { "name": "Your Name", "email": "you@example.com" },
  "plugins": [
    { "name": "<plugin-name>", "source": "./", "description": "One line." }
  ]
}
```

`.claude-plugin/plugin.json` — only `name` is required; set `version` for stable installs (else each git commit is a new version):
```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "One line.",
  "author": { "name": "Original Author", "url": "https://source-url" }
}
```

## Step 4 — Create, verify, push

```bash
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json')); json.load(open('.claude-plugin/plugin.json'))"  # validate
gh repo create OWNER/REPO --public --source=. --remote=origin --push
gh api "repos/OWNER/REPO/git/trees/main?recursive=1" --jq '.tree[].path'   # confirm structure landed
```

## Step 5 — Install commands

```
/plugin marketplace add OWNER/REPO
/plugin install <plugin-name>@<marketplace-name>
```

Install id is `pluginName@marketplaceName` — they're independent fields, even if equal.

**Caveat — you (Claude) cannot run interactive `/plugin` yourself.** To test in the *current* session, install manually: `cp -R skills/<name> ~/.claude/skills/<name>` (loads in a new session). Offer the user the two commands above for the real install.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Adding MIT/your license to someone else's code | Don't. Credit + link source; keep their license if any |
| Leaving `__` paths or broken SKILL.md links | Un-flatten, then grep `__` and fix links |
| `owner` as a string | Must be `{ "name": ... }` object |
| Omitting `version` then surprised by churn | Pin `version` for stable installs |
| Claiming the skill is installed after running `/plugin` | You can't run it; verify structure + give the user the commands |
| Listing skills in plugin.json | Unneeded — `skills/<name>/SKILL.md` auto-discovers |
