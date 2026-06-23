---
name: tufte-leadership-pdf
description: Use when building a leadership/executive findings PDF for a stakeholder in Garrett's "weather/traffic report" house style, an answer-first one-pager with a serif face, warm paper, margin-note figure captions, and one accent color. Triggers include "like the weather report", "Tufte report", "leadership PDF", "findings PDF for <person>", a report that pairs ReportLab + matplotlib charts, or any 2-4 page stakeholder writeup of a model/analysis result.
---

# Tufte leadership PDF

## Overview

Garrett ships stakeholder findings as a recurring house style (the traffic/weather report, the churn head-to-head, the CLV validation). It is Tufte-flavored: warm off-white paper, a single serif face, the highest data-ink ratio (no gridlines, no bar fills, no table shading), one muted rust accent, figure captions set as **sidenotes in a wide right margin**, and the answer stated first in a "THE BOTTOM LINE" callout.

Don't rebuild the scaffolding from scratch. Copy `template.py`, replace `compute()` and the chart functions, write the page flow. The palette, page geometry, `FigureBlock` sidenote flowable, `callout`, `data_table`, and `footer` are done and verified.

## When to use

- A 2-4 page PDF summarizing a model/analysis for a non-technical stakeholder.
- The user references the weather/traffic report, "answer first", margin captions, or an existing report to mirror (read that report's generator and match it).

Not for: internal markdown findings (write `.md`), slide decks, or interactive dashboards.

## House style (non-negotiable)

- **Palette:** paper `#fffff8`, ink `#1a1a1a`, soft `#6b6b63`, accent `#8c2f22`, rule `#c9c5b4`. Accent used sparingly (one line, the diagonal of a matrix, a kicker bullet).
- **Type:** Times serif everywhere, body 10.5pt, the bottom-line lead 12.5pt.
- **Charts:** matplotlib, serif, no grid, spines hidden except a short bottom rule, direct value labels on the marks (no legend boxes), `fig.facecolor` = paper. Dumbbell/lollipop/dot beats bars.
- **Figures:** image in the main column, caption as an italic sidenote in the right margin, top-aligned (`FigureBlock`).
- **Page 1:** title, subtitle (author · month), `THE BOTTOM LINE` callout (the answer, bolded numbers), "What you asked", "What we found" bullets, a thin rule, a small scope footnote.
- **Voice:** second person ("your population", "you asked"). Never name an individual in the rendered PDF; address requests, don't attribute them. No em-dashes (use the `_minus()` helper for figures; commas/colons in prose).

## Quick reference

| Need | Use |
|------|-----|
| Answer-first block | `callout(text)` → "THE BOTTOM LINE" |
| Figure + margin caption | `FigureBlock(png_path, n, caption)` |
| Clean table | `data_table(header, rows, widths, aligns)` |
| Running footer + page no. | `footer(canvas, doc)` |
| Self-contained, recomputed numbers | `compute()` reads cached parquet, returns a dict |

## Gotchas (each cost a cycle when built fresh)

- **Page-1 overflow → phantom blank page.** If the page-1 footnote is long it splits across the page, and the following `PageBreak()` then yields a near-empty page 2. Keep page-1 prose short; if a section won't fit, move a `PageBreak()` *up* so the next page is a deliberate, balanced closing page (e.g. table + "What ships" + footnote together), not two orphan lines.
- **Renaming the PDF ≠ renaming the output var.** After `git mv`-ing a generated PDF, grep the generator for the old name and fix `OUT_PDF` (and the docstring). A bare file rename leaves the script regenerating the old name.
- **Em-dashes** render as literal `-` mush in matplotlib titles; use `_minus()` (U+2212) there, and avoid em-dashes in prose entirely (Garrett's standing rule).
- **Self-contained generators.** `compute()` should recompute every printed number from a cached parquet so the report is reproducible from one `uv run`. Don't hardcode results.
- **Run it and look.** Render, then Read the PDF pages back (and check page count with pypdf). Layout bugs are invisible in the code.
- **After regenerating, re-send.** If the PDF was already sent to the phone (previewing-on-iphone) and you regenerate it, re-copy it; verify with `cmp`.

## Implementation

`template.py` is the verified scaffolding (inline-deps `uv run` script: polars, numpy, matplotlib, reportlab). Copy it, swap `compute()` + the two `chart_*` functions + the `build_pdf` story, keep everything else. It mirrors the shipped reports in `~/work/predictive_clv/analyses/2026-06-05_*/build_report.py`, read one of those for a full worked example.
