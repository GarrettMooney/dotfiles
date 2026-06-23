---
name: grmooney-blog-updates
description: Use when Garrett asks to edit, add, deploy, or check content on his personal blog/notes site ("my blog", grmooney.com, the avclub page, the Quarto notes site, or the grmooney.github.io repo), including "is it live yet" questions.
---

# grmooney.com blog updates

Quarto website. Source repo: `~/git/grmooney.github.io` (GitHub: `GarrettMooney/garrettmooney.github.io`). Live at **https://grmooney.com** (via CNAME; readers don't use the github.io URL).

## Layout

- Pages are `.qmd` files: homepage `index.qmd` (a listing page), notes under `notes/<slug>/index.qmd` with `title:` / `description:` frontmatter. The homepage listing pulls each note's title and description from that frontmatter.
- `_site/` is gitignored CI build output. It is often stale locally: never edit it, commit it, or treat it as evidence of what's live.

## Deploy model: push = deploy

`.github/workflows/publish.yml` runs `quarto render` and publishes to GitHub Pages on every push to `main`. There is no separate deploy step, and **no local `quarto render` is needed to publish** (render locally only to preview).

Workflow for "make this change and get it live":

1. Edit the `.qmd` source.
2. Commit (what + why, no AI attribution) and push to `main`.
3. Watch CI: `gh run list -L 1 --json databaseId --jq '.[0].databaseId' | xargs gh run watch --exit-status` (run from inside the repo; takes ~1–4 min).
4. Verify live: `curl -s https://grmooney.com/notes/<slug>/ | grep -i "<changed text>"` (curl bypasses browser cache). If title/description changed, also check the homepage listing at `https://grmooney.com/`.

## Conventions

- Only commit/push when Garrett asks, but "deploy" / "get it live" implies commit + push + watch + verify.
- Garrett's global contract applies: concise replies, no em-dashes, no Claude attribution in commits.
