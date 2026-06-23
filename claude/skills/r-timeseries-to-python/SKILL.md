---
name: r-timeseries-to-python
description: Use when porting an R time-series example to Python - pulling a tsibbledata/fpp3 dataset (ansett, PBS, aus_retail, vic_elec, etc.) or an fma/fpp2 ts-object dataset (hsales, ustreas, etc.) into Python without installing R packages, fixing a tsibble yearweek/yearmonth index that exports as a meaningless number, converting a base-R ts object to dated rows, reproducing a feasts gg_season seasonal plot (including its exact colors), or reproducing the fable/feasts autoplot ggplot2 look in Python with polars + plotnine.
---

# R tsibble datasets and plots in Python

## Overview

Bring R time-series datasets into a Python (polars + plotnine) workflow and
reproduce the `autoplot()` ggplot2 aesthetic. Two recurring jobs: (1) export the
R object to CSV with a *real* date (or integer) index, (2) plot it so it matches
the R book figures.

**Two dataset families, two conversions — pick the branch first:**

- **tsibble datasets** (`ansett`, `PBS`, `aus_production`, `gafa_stock`,
  `vic_elec`, `tourism`, …): the object is a **tsibble**. → Part 1.
- **`fma`/`fpp2`/`fpp`** (`hsales`, `ustreas`, `elecsales`, …): the object is a
  base-R **`ts`** (or `mts`). The days-since-epoch trick does NOT apply here.
  → Part 1b.

Don't assume "R time series" means "tsibble" — `class(x)` settles it.

**Repo + default branch is per-dataset — there is no universal branch.** A wrong
branch 404s silently. Check the GitHub repo, or `gh api repos/<org>/<repo> -q .default_branch`:

| Dataset(s) | Repo | Branch |
|---|---|---|
| `ansett`, `PBS`, `aus_production`, `gafa_stock`, `vic_elec` | `tidyverts/tsibbledata` | `master` |
| `tourism` | `tidyverts/tsibble` (NOT tsibbledata) | `main` |
| `hsales`, `ustreas`, `elecsales` | `robjhyndman/fma` (or `fpp2`) | `master` |

## When to Use

- Porting a "Forecasting: Principles and Practice" (fpp2/fpp3) example to Python
- Need `ansett`, `PBS`, `aus_production`, `hsales`, `ustreas`, etc. as a CSV
- A tsibble's date column exports as a bare number (e.g. `7130`) and you need a date
- A base-R `ts` object has no date column and you need real dates (or an integer day index)
- Want a Python chart that looks like `autoplot()` (grey panel, `Week [1W]` axis)

## Part 1: tsibble dataset → CSV (no package install)

`tsibbledata` datasets are `.rda` files in the package's GitHub repo. Pull the
one you need directly; do not install the package (it drags in tsibble/tsibble
deps).

```bash
# Branch is per-repo (see table above): tsibbledata=master, tsibble=main.
curl -fsSL -o /tmp/PBS.rda \
  https://github.com/tidyverts/tsibbledata/raw/master/data/PBS.rda
```

Then load + convert in base R. **The trap:** when you `as.data.frame()` a
tsibble, a `yearweek`/`yearmonth`/`yearquarter` index column keeps its class but
its underlying numeric is **days since 1970-01-01** (Monday-aligned), NOT
weeks/months. Two consequences:

- `as.Date(df$Week, ...)` fails: *"do not know how to convert to class Date"*
  (the column still has the `yearweek` class). You must `unclass()` /
  `as.numeric()` first.
- Treating the number as weeks/months gives dates centuries off. With weekly
  data the rows happen to differ by 7 so you might catch it; with monthly data
  there is no such clue and a wrong epoch passes silently. Always use the
  days origin.

```r
# /tmp/convert.R  — base R only
e <- new.env(); load("/tmp/PBS.rda", envir = e)
d  <- get(ls(e)[1], envir = e)
df <- as.data.frame(d)
df$Month <- as.Date(as.numeric(unclass(df$Month)), origin = "1970-01-01")
df <- df[as.character(df$ATC2) == "A10", ]   # filter while you're here
write.csv(df, "data/A10.csv", row.names = FALSE)
```

Verify: weekly dates should all land on Mondays; monthly on the 1st.

Not every tsibble index is a `yearX` class. `gafa_stock`'s index is already a
real `Date` (irregular trading days), so the "bare number" framing doesn't
apply — `as.numeric(unclass(x))` + days origin is still correct and harmless,
or you can keep the column as-is. Check `class(df$<index>)` before assuming.

## Part 1b: ts-object dataset → CSV (fma/fpp2)

A base-R `ts` has no date column at all — it stores `start`/`end`/`frequency`,
and `as.data.frame()` will NOT give you dates. Build them from `time()`:

```bash
curl -fsSL -o /tmp/hsales.rda \
  https://github.com/robjhyndman/fma/raw/master/data/hsales.rda   # also master
```

```r
e <- new.env(); load("/tmp/hsales.rda", envir = e)
x  <- get(ls(e)[1], envir = e)            # a ts object
tt <- as.numeric(time(x))                 # decimal years, e.g. 1973.0, 1973.083...
yr <- floor(tt + 1e-6)
mo <- round((tt - yr) * frequency(x)) + 1 # period within the year
dates <- as.Date(sprintf("%d-%02d-01", yr, mo))   # monthly → 1st of month
df <- data.frame(Month = dates, Sales = as.numeric(x))
write.csv(df, "data/hsales.csv", row.names = FALSE)
```

**No real calendar?** Some `ts` objects (e.g. `ustreas`: `tsp == 1 100 1`,
frequency 1) are just consecutive observations with no dates — `time(x)` is the
integer index `1..N`. Don't fabricate dates: export `Day = seq_len(length(x))`
and plot it on a plain numeric axis (see Part 2).

## Part 2: reproduce the autoplot() aesthetic with plotnine

`autoplot()` is ggplot2 under the hood, so use **plotnine** (its `theme_grey`
default already matches). plotnine 0.14+ accepts a **polars DataFrame
directly** (via narwhals) — no pandas needed — but it reads it through
**pyarrow**, so include pyarrow as a dep.

```python
# /// script
# requires-python = ">=3.11"
# dependencies = ["polars", "pyarrow", "plotnine"]
# ///
import polars as pl
from plotnine import aes, geom_line, ggplot, labs, scale_x_date

a10 = (
    pl.read_csv("data/A10.csv", try_parse_dates=True)
    .group_by("Month").agg(Cost=pl.col("Cost").sum() / 1e6).sort("Month")
)

plot = (
    ggplot(a10, aes(x="Month", y="Cost"))   # polars df straight in, no .to_pandas()
    + geom_line()
    + scale_x_date(date_breaks="5 years", date_labels="%Y %b")  # -> "2000 Jan"
    + labs(title="Australian antidiabetic drug sales", x="Month [1M]", y="$ (millions)")
)
plot.save("a10.png", dpi=150, width=10, height=5, units="in", verbose=False)
```

### Matching tsibble's axis conventions

The axis title encodes the index interval; match it to the data:

| Interval | Axis title | x scale / labels |
|---|---|---|
| Weekly | `Week [1W]` | `scale_x_date` + ISO year+week labeller (below) |
| Monthly | `Month [1M]` | `scale_x_date(date_labels="%Y %b")` → `2000 Jan` |
| Quarterly | `Quarter [1Q]` | `scale_x_date(date_labels="%Y %b")` |
| Irregular (daily stock, etc.) | `Date [!]` | `scale_x_date(date_breaks="1 year", date_labels="%Y %b")` |
| Integer index (no calendar) | bare name, e.g. `Day` | `scale_x_continuous` — NOT `scale_x_date` |

`[!]` is tsibble's marker for an irregular interval (e.g. `gafa_stock` trading
days). ISO year+week (e.g. `1987 W53`) has no strftime code; use a custom
labeller (breaks arrive as `datetime.datetime`, which has `.isocalendar()`):

```python
def yearweek_labels(breaks):
    return ["" if b is None else f"{b.isocalendar()[0]} W{b.isocalendar()[1]:02d}"
            for b in breaks]
# + scale_x_date(date_breaks="1 year", labels=yearweek_labels)
```

**Daily change** of a price series (e.g. Google close): sort, then
`pl.col("Close").diff()` and drop the leading null:

```python
.sort("Date").with_columns(Change=pl.col("Close").diff()).drop_nulls("Change")
```

### Seasonal plots: reproducing `feasts::gg_season`

plotnine has **no** `gg_season`. Build it by hand: split the index into a
within-period x-axis and draw **one line per period** (`group=`), colored by the
period's chronological rank. The mechanics are easy; the trap is the colors —
feasts does NOT use a saturated rainbow or viridis. The exact recipe (read from
feasts v0.3.1 `R/graphics.R`):

- **Palette is `scales::hue_pal()(9)`** — the muted ggplot2 HCL hue wheel. The 9
  stops, in order:
  `#F8766D #D39200 #93AA00 #00BA38 #00C19F #00B9E3 #619CFF #DB72FB #FF61C3`
- **Color maps to the period's chronological rank** (feasts: `unclass(id)`):
  first period → first stop, last → last. A monotonic numeric like "days since
  the first period" reproduces it.
- **≤7 distinct periods → discrete legend** (one entry per period, feasts'
  `max_col_discrete`); more → a continuous gradient. So a yearly plot of 3 years
  is discrete+legend; a daily plot of 1000+ days is a gradient.

| `period=` | within-period x | one line per | color rank |
|---|---|---|---|
| day | `dt.hour() + dt.minute()/60` (0–24) | date | days since first date |
| week | `(t - t.dt.truncate("1w")).dt.total_minutes()/60` (0–168, Mon-start) | week | days since first week |
| year | `dt.ordinal_day()-1 + (dt.hour()+dt.minute()/60)/24` | year | the year |

```python
HUE9 = ["#F8766D","#D39200","#93AA00","#00BA38","#00C19F",
        "#00B9E3","#619CFF","#DB72FB","#FF61C3"]
# many periods → gradient (color = numeric rank column):
+ scale_color_gradientn(colors=HUE9) + theme(legend_position="none")
# few periods (≤7) → keep the legend; sample stops (3 yrs → t=0,0.5,1 = idx 0,4,8):
+ scale_color_manual(values=[HUE9[0], HUE9[4], HUE9[8]])
```

Drop the colorbar with `theme(legend_position="none")` (e.g. when year labels sit
on the line ends, `gg_season(labels="both")`); keep it for a few-period plot.

### Subseries plots: reproducing `feasts::gg_subseries`

One **facet per season** (e.g. month or quarter); within a facet the line is that
season's value across years; plus a horizontal per-facet mean line. The layout is
easy to get right; two non-obvious bits:

- **The mean line is literal `colour = "blue"` = `#0000FF`** — feasts hardcodes
  plain blue, NOT a tasteful steel-blue (`#0072B2`/`#3366FF`). Compute it as
  `pl.col(y).mean().over(<season>)` and draw with `geom_hline(aes(yintercept=...), color="blue")`.
- **Season must be an ordered `pl.Enum`** (`["Jan",…]` / `["Q1",…]`) or facets
  sort alphabetically (Apr, Aug, …).

### Keyed tsibbles (one series per key)

A tsibble keyed by e.g. `State` holds several series. Both gg_season and
gg_subseries **facet by the key with `scales="free_y"`**:

- gg_season: `facet_grid("State ~ .", scales="free_y")` (key = rows).
- gg_subseries: `facet_grid("State ~ Season", scales="free_y")` (key rows ×
  season cols; the mean is then `.mean().over("State", <season>)`).

`autoplot()` of a keyed tsibble instead draws one **colored line per key** in a
single panel (`aes(color="State")`) — no faceting.

### feasts uses three different palettes — never assume one from another

This trips you up if you generalize: each feasts display hardcodes a *different*
color scheme. Match the one for the plot you're reproducing:

| Display | Palette |
|---|---|
| `gg_season` | `scales::hue_pal()(9)` (muted HCL hue wheel) |
| `gg_subseries` mean line | literal `"blue"` = `#0000FF` |
| `gg_lag` | **viridis** (discrete) |

### Lag plots: reproducing `feasts::gg_lag`

`gg_lag(y, geom="point")` is a faceted grid, one panel per lag k (default
`lags = 1:9`), plotting `y[t]` (y-axis) against `y[t-k]` (x-axis, labelled
`lag(y, k)`), each point colored by its **season** (e.g. quarter), with a
**dashed grey y=x reference line**. plotnine has no `gg_lag`; build it:

- One frame per k: `pl.col(y).shift(k)` → x, `drop_nulls`, keep y + the season
  label, tag `lag=f"lag {k}"`; `pl.concat` and `facet_wrap("lag")`.
- **Color is viridis, NOT `hue_pal()` — this is the trap** (gg_season uses the
  hue wheel; do not carry that over). 4 quarters →
  `["#440154","#31688E","#35B779","#FDE725"]` (Q1 dark purple → Q4 yellow).
  Season as an ordered `pl.Enum` so the legend reads Q1..Q4.
- Reference line is **dashed**: `geom_abline(slope=1, intercept=0, color="grey",
  linetype="dashed")` — not solid.

```python
frames = [recent.with_columns(lagged=pl.col("Beer").shift(k))
          .drop_nulls("lagged")
          .select(lag=pl.lit(f"lag {k}"), x="lagged", y="Beer", season="season")
          for k in range(1, 10)]
VIRIDIS4 = ["#440154", "#31688E", "#35B779", "#FDE725"]
(ggplot(pl.concat(frames), aes("x", "y", color="season"))
 + geom_abline(slope=1, intercept=0, color="grey", linetype="dashed")
 + geom_point() + facet_wrap("lag") + scale_color_manual(values=VIRIDIS4)
 + labs(x="lag(Beer, k)", y="Beer"))
```

For quarterly data the lag-4 panel hugs the diagonal (strongest autocorrelation
at the annual lag) — a good sanity check.

### Scatterplot matrix: reproducing `GGally::ggpairs`

`ggpairs(columns=...)` on a `pivot_wider`'d frame (one column per key) is an n×n
matrix: **diagonal = density**, **lower = scatter**, **upper = `Corr:` text +
significance stars**, key names on the top and right strips. plotnine has no
`ggpairs`; two routes:

- **matplotlib `subplots(n, n)` — easiest and most faithful.** Each cell is its
  own Axes, so the diagonal density keeps a true density y-scale and you can drop
  the grid per cell (`ax.grid(False)` only in the upper triangle). Mimic
  theme_grey with `ax.set_facecolor("#EBEBEB")` + white gridlines.
- **pure plotnine via `facet_grid("row ~ col", scales="free")`.** Build three
  long frames (scatter / density / corr-text), each carrying the `row`/`col`
  facet keys, and layer `geom_point` / `geom_line` / `geom_text`. Two traps:
  - **Diagonal density must be rescaled into the row's value range.** Faceting
    forces every row to share one y-axis (the value scale), so a raw 0–0.005
    density blows the row up. Rescale `lo + (d-d.min())/(d.max()-d.min())*(hi-lo)`
    — shape is right, absolute density magnitude is lost (the matplotlib route
    keeps it).
  - **No per-panel grid removal in plotnine.** To kill the grid in only the upper
    cells, overlay a `geom_rect` filling the panel grey (`fill="#EBEBEB"`,
    `inherit_aes=False`, bounds oversized past the data so it covers the clipped
    panel) *before* the `geom_text`.

Correlations + stars from `scipy.stats.pearsonr` (`*** <0.001, ** <0.01,
* <0.05`). `pl.DataFrame.pivot(on=key)` keeps **first-appearance** column order —
`sorted()` the keys to match the book's alphabetical layout.

Run scripts with `uv run script.py` (PEP 723 inline deps).

## Common Mistakes

| Symptom | Cause / Fix |
|---|---|
| `curl ... 404` | Wrong repo or branch — branch is **per-repo** (tsibbledata=`master`, tsibble=`main`, fma=`master`); see the table in Part 1. `tourism` is in `tsibble`, not tsibbledata |
| gg_subseries mean line is the wrong blue | feasts uses literal `"blue"` (`#0000FF`), not `#0072B2`/`#3366FF` |
| Unclass/days trick gives `NA` or nonsense on an fma dataset | It's a `ts` object, not a tsibble — build dates from `time()`/`frequency()` (Part 1b) |
| Inventing fake dates for `ustreas`-style data | It has no calendar (frequency 1) — use an integer `Day` index + `scale_x_continuous` |
| `as.Date`: "do not know how to convert to Date" | yearweek class still attached → `as.numeric(unclass(x))` first |
| Dates land in the 2100s | Treated the index as weeks/months; it's **days** since 1970-01-01 |
| `ModuleNotFoundError`/plotnine can't read polars | Add `pyarrow` to deps (the polars→plotnine bridge) |
| polars reads a datetime column as `str` (`expected Datetime, got str`) | `try_parse_dates` only parses pure dates; a datetime WITH a time (e.g. `vic_elec`'s POSIXct `Time`) stays a string → `pl.col("Time").str.to_datetime()` |
| gg_season colors look like a rainbow / viridis, not the book | feasts uses `scales::hue_pal()(9)` mapped to chronological rank — see the gg_season section, not a guess |
| `gg_lag` colors look like the hue wheel, not the book's purple→yellow | `gg_lag` uses **viridis**, NOT `hue_pal()` like gg_season — `["#440154","#31688E","#35B779","#FDE725"]` for 4 seasons. feasts uses a different palette per display |
| polars `ComputeError: could not parse 'NA' as dtype i64` | R wrote `NA` for missing values (e.g. `aus_production` Tobacco/Bricks late quarters) → `pl.read_csv(..., null_values="NA")` |
| Re-exported CSV lacks a column you now need (e.g. `vic_elec` Temperature) | The earlier R export `select`ed a subset — re-run the export keeping all columns (the `.rda` has them); never fabricate the column |
| Just-added import vanishes before you use it | ruff format-on-save strips an imported-but-unused name. Add the import and its first use in the **same** edit; when **renaming** an import across two separate edits, add the body usage FIRST, then the import (so it's never momentarily unused) |
| Title bold/centered, not like the book | plotnine's `theme_grey` is the ggplot default — don't hand-roll matplotlib; just use plotnine |
