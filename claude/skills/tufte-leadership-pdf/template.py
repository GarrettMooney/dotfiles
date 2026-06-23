# /// script
# requires-python = ">=3.11"
# dependencies = ["polars>=1.0", "numpy", "matplotlib>=3.8", "reportlab>=4.0"]
# ///
"""Tufte leadership-PDF scaffolding (Garrett's weather/traffic report house style).

Copy this file, then replace ONLY: compute(), the chart_*() functions, and the
story in build_pdf(). Leave the palette, page geometry, FigureBlock, callout,
data_table, and footer as-is. Run `uv run template.py` to render a sample.

Verified against the shipped reports in
~/work/predictive_clv/analyses/2026-06-05_*/build_report.py.
"""

from __future__ import annotations

import tempfile
from pathlib import Path

import matplotlib
import numpy as np

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from reportlab.lib import colors  # noqa: E402
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT  # noqa: E402
from reportlab.lib.pagesizes import LETTER  # noqa: E402
from reportlab.lib.styles import ParagraphStyle  # noqa: E402
from reportlab.lib.units import inch  # noqa: E402
from reportlab.lib.utils import ImageReader  # noqa: E402
from reportlab.platypus import (  # noqa: E402
    Flowable,
    HRFlowable,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

HERE = Path(__file__).resolve().parent
OUT_PDF = (
    HERE / "report.pdf"
)  # GOTCHA: if you git mv the PDF later, update THIS line too.
FOOTER_TEXT = "Report Title   ·   Garrett Mooney"

# Tufte palette: warm paper, near-black ink, one muted accent. Do not change.
PAPER, INK, SOFT, ACCENT, RULE = "#fffff8", "#1a1a1a", "#6b6b63", "#8c2f22", "#c9c5b4"

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.serif": ["Times New Roman", "Times", "DejaVu Serif"],
        "text.color": INK,
        "axes.labelcolor": INK,
        "axes.edgecolor": INK,
        "xtick.color": INK,
        "ytick.color": INK,
        "figure.facecolor": PAPER,
        "savefig.facecolor": PAPER,
        "axes.facecolor": PAPER,
    }
)


def _minus(s: str) -> str:
    """Use in matplotlib text so hyphens read as a true minus, not em-dash mush."""
    return s.replace("-", "−")


# --------------------------------------------------------------------------
# 1. compute the numbers  ->  REPLACE THIS. Recompute every printed number
#    from a cached parquet so the report is reproducible from one `uv run`.
# --------------------------------------------------------------------------
def compute() -> dict:
    # e.g. df = pl.read_parquet(DATA / "scored.parquet"); auc = roc_auc_score(...)
    rng = np.random.default_rng(0)
    return {
        "headline": 0.74,
        "baseline": 0.20,
        "n": 3_278_982,
        "series": np.sort(rng.uniform(0, 1, 5)),
    }


# --------------------------------------------------------------------------
# 2. charts -- data-ink only: no grid, spines hidden bar a short bottom rule,
#    direct value labels (no legend), dot/lollipop/dumbbell over bars.  REPLACE.
# --------------------------------------------------------------------------
def chart_example(d: dict, path: Path) -> None:
    vals, ys = d["series"], list(range(5))
    fig, ax = plt.subplots(figsize=(5.0, 2.2))
    for yy, v in zip(ys, vals):
        ax.hlines(yy, 0, v, color=SOFT, lw=1.1, zorder=1)
        ax.scatter([v], [yy], color=INK, s=34, zorder=3)
        ax.annotate(
            f"{v:.0%}",
            (v, yy),
            textcoords="offset points",
            xytext=(8, 0),
            va="center",
            ha="left",
            fontsize=9,
            color=INK,
            fontweight="bold",
        )
    ax.set_yticks(ys)
    ax.set_yticklabels([f"Row {i + 1}" for i in ys], fontsize=9, color=INK)
    ax.set_xlim(0, 1.12)
    ax.set_xticks([0, 0.25, 0.5, 0.75, 1.0])
    ax.set_xticklabels(["0%", "25%", "50%", "75%", "100%"])
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(RULE)
    ax.spines["bottom"].set_bounds(0, 1.0)
    ax.tick_params(axis="y", length=0)
    ax.tick_params(axis="x", length=2, labelsize=8.5, colors=SOFT)
    ax.set_xlabel("what the axis measures", fontsize=8.5, color=SOFT)
    ax.grid(False)
    fig.savefig(path, dpi=200, bbox_inches="tight", pad_inches=0.04)
    plt.close(fig)


# --------------------------------------------------------------------------
# 3. page geometry + styles + flowables  ->  KEEP AS-IS.
# --------------------------------------------------------------------------
PAGE_W, PAGE_H = LETTER
MARGIN_L, MARGIN_TOP, MARGIN_BOT = 0.9 * inch, 0.85 * inch, 0.95 * inch
NOTE_GUTTER, NOTE_W, OUTER_R = 0.22 * inch, 1.75 * inch, 0.62 * inch
MARGIN_R = NOTE_GUTTER + NOTE_W + OUTER_R
MAIN_W = PAGE_W - MARGIN_L - MARGIN_R
CONTENT_R = MARGIN_L + MAIN_W + NOTE_GUTTER + NOTE_W

_S = lambda n, **k: ParagraphStyle(n, **k)  # noqa: E731
ST_TITLE = _S(
    "title",
    fontName="Times-Bold",
    fontSize=21,
    textColor=colors.HexColor(INK),
    leading=24,
    spaceAfter=3,
)
ST_SUB = _S(
    "sub",
    fontName="Times-Italic",
    fontSize=10.5,
    textColor=colors.HexColor(SOFT),
    spaceAfter=2,
)
ST_H2 = _S(
    "h2",
    fontName="Times-Bold",
    fontSize=13,
    textColor=colors.HexColor(INK),
    leading=16,
    spaceBefore=4,
    spaceAfter=7,
)
ST_BODY = _S(
    "body",
    fontName="Times-Roman",
    fontSize=10.5,
    textColor=colors.HexColor(INK),
    leading=15.5,
    spaceAfter=8,
)
ST_BULLET = _S(
    "bullet",
    parent=ST_BODY,
    leftIndent=15,
    bulletIndent=2,
    spaceAfter=7,
    bulletFontName="Times-Roman",
    bulletFontSize=8,
    bulletColor=colors.HexColor(ACCENT),
)
ST_KICKER = _S(
    "kicker",
    fontName="Times-Bold",
    fontSize=8,
    textColor=colors.HexColor(SOFT),
    spaceAfter=3,
)
ST_LEAD = _S(
    "lead",
    fontName="Times-Roman",
    fontSize=12.5,
    textColor=colors.HexColor(INK),
    leading=17.5,
)
ST_SIDENOTE = _S(
    "sidenote",
    fontName="Times-Roman",
    fontSize=8.2,
    textColor=colors.HexColor(SOFT),
    leading=11.3,
)
ST_FOOTNOTE = _S(
    "footnote",
    fontName="Times-Roman",
    fontSize=8,
    textColor=colors.HexColor(SOFT),
    leading=11,
)
_ALIGN = {"LEFT": TA_LEFT, "RIGHT": TA_RIGHT, "CENTER": TA_CENTER}


class FigureBlock(Flowable):
    """Image in the main column; caption as an italic Tufte sidenote in the wide
    right margin, top-aligned with the image."""

    def __init__(self, img_path: Path, number: int, caption: str):
        super().__init__()
        iw, ih = ImageReader(str(img_path)).getSize()
        self.img_path, self.img_w, self.img_h = str(img_path), MAIN_W, MAIN_W * ih / iw
        self.number, self.caption = number, caption

    def wrap(self, availWidth, availHeight):
        self._cap = Paragraph(
            f"<i>Figure {self.number}.</i> {self.caption}", ST_SIDENOTE
        )
        _, self._cap_h = self._cap.wrap(NOTE_W, self.img_h)
        self.width, self.height = MAIN_W, max(self.img_h, self._cap_h)
        return (self.width, self.height)

    def draw(self):
        top = self.height
        self.canv.drawImage(
            self.img_path,
            0,
            top - self.img_h,
            width=self.img_w,
            height=self.img_h,
            mask="auto",
        )
        self._cap.drawOn(self.canv, MAIN_W + NOTE_GUTTER, top - self._cap_h)


def callout(text: str) -> list:
    """The answer-first 'THE BOTTOM LINE' block. Bold the key numbers in `text`."""
    return [
        Paragraph("THE BOTTOM LINE", ST_KICKER),
        HRFlowable(
            width=MAIN_W,
            thickness=0.75,
            color=colors.HexColor(INK),
            spaceBefore=1,
            spaceAfter=7,
        ),
        Paragraph(text, ST_LEAD),
        HRFlowable(
            width=MAIN_W,
            thickness=0.5,
            color=colors.HexColor(RULE),
            spaceBefore=8,
            spaceAfter=1,
        ),
    ]


def _cell(text, font, size, align):
    return Paragraph(
        text,
        _S(
            "c",
            fontName=font,
            fontSize=size,
            leading=size + 2.6,
            textColor=colors.HexColor(INK),
            alignment=_ALIGN[align],
        ),
    )


def data_table(header, rows, widths, aligns) -> Table:
    head = [_cell(h, "Times-Italic", 9, a) for h, a in zip(header, aligns)]
    body = [
        [_cell(str(v), "Times-Roman", 9.5, a) for v, a in zip(r, aligns)] for r in rows
    ]
    t = Table([head] + body, colWidths=widths, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("TOPPADDING", (0, 0), (-1, -1), 6),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
                ("LEFTPADDING", (0, 0), (-1, -1), 3),
                ("RIGHTPADDING", (0, 0), (-1, -1), 5),
                ("LINEABOVE", (0, 0), (-1, 0), 0.75, colors.HexColor(INK)),
                ("LINEBELOW", (0, 0), (-1, 0), 0.4, colors.HexColor(RULE)),
                ("LINEBELOW", (0, -1), (-1, -1), 0.75, colors.HexColor(INK)),
            ]
        )
    )
    return t


def footer(canvas, doc) -> None:
    canvas.saveState()
    canvas.setFillColor(colors.HexColor(PAPER))
    canvas.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    y = 0.6 * inch
    canvas.setStrokeColor(colors.HexColor(RULE))
    canvas.setLineWidth(0.5)
    canvas.line(MARGIN_L, y, CONTENT_R, y)
    canvas.setFont("Times-Roman", 8)
    canvas.setFillColor(colors.HexColor(SOFT))
    canvas.drawString(MARGIN_L, y - 12, FOOTER_TEXT)
    canvas.drawRightString(CONTENT_R, y - 12, str(doc.page))
    canvas.restoreState()


# --------------------------------------------------------------------------
# 4. assemble  ->  REPLACE the story. Keep the page-1 shape (callout + asked +
#    found + scope). GOTCHA: keep page-1 prose short or the footnote splits and
#    leaves a phantom blank page; move a PageBreak up to make a balanced closing
#    page instead of two orphan lines.
# --------------------------------------------------------------------------
def build_pdf(d: dict, charts: dict) -> None:
    doc = SimpleDocTemplate(
        str(OUT_PDF),
        pagesize=LETTER,
        leftMargin=MARGIN_L,
        rightMargin=MARGIN_R,
        topMargin=MARGIN_TOP,
        bottomMargin=MARGIN_BOT,
        title="Report Title",
        author="Garrett Mooney",
    )
    story = [
        Paragraph("Does the Thing Work the Way You Asked?", ST_TITLE),
        Paragraph("Garrett Mooney &nbsp;&nbsp;·&nbsp;&nbsp; Month Year", ST_SUB),
        Spacer(1, 14),
        KeepTogether(
            callout(
                f'<font name="Times-Bold">Yes.</font> The headline lands at '
                f'<font name="Times-Bold">{d["headline"]:.0%}</font>, against '
                f"{d['baseline']:.0%} by chance, on {d['n']:,} cases. One caution stated plainly here."
            )
        ),
        Spacer(1, 16),
        Paragraph("What you asked", ST_H2),
        Paragraph(
            "Restate the request in one tight paragraph, second person.", ST_BODY
        ),
        Spacer(1, 4),
        Paragraph("What we found", ST_H2),
        Paragraph(
            "<i>First finding.</i> A sentence with the number.",
            ST_BULLET,
            bulletText="•",
        ),
        Paragraph("<i>Second finding.</i> Another.", ST_BULLET, bulletText="•"),
        Spacer(1, 14),
        HRFlowable(
            width=MAIN_W, thickness=0.4, color=colors.HexColor(RULE), spaceAfter=6
        ),
        Paragraph(
            f"Scope: keep this footnote short. n = {d['n']:,}. Define the metric and the baseline.",
            ST_FOOTNOTE,
        ),
        PageBreak(),
        Paragraph("The detail", ST_H2),
        FigureBlock(
            charts["example"],
            1,
            "Caption set as a sidenote: say what the reader is looking at and why the shape matters.",
        ),
        Spacer(1, 12),
        Paragraph("Prose explaining the figure, then a table.", ST_BODY),
        data_table(
            ["Measure", "Value"],
            [
                ["Headline", f"{d['headline']:.0%}"],
                ["Baseline", f"{d['baseline']:.0%}"],
            ],
            [MAIN_W * 0.7, MAIN_W * 0.3],
            ["LEFT", "RIGHT"],
        ),
    ]
    doc.build(story, onFirstPage=footer, onLaterPages=footer)


def main() -> None:
    d = compute()
    with tempfile.TemporaryDirectory() as tmp:
        charts = {"example": Path(tmp) / "example.png"}
        chart_example(d, charts["example"])
        build_pdf(d, charts)
    print(f"wrote {OUT_PDF} ({OUT_PDF.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
