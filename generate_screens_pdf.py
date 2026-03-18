#!/usr/bin/env python3
"""
Generates a screen-design reference PDF for Project Nexus.
Produces pixel-accurate wireframe mockups for all 7 screens.
"""
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Spacer, Paragraph, Table, TableStyle, HRFlowable
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.platypus import Flowable
from reportlab.graphics.shapes import Drawing, Rect, String, Circle, Line, Polygon
from reportlab.graphics import renderPDF
import os

# ── Palette ───────────────────────────────────────────────────────────────────
BG          = colors.HexColor("#F2F2F7")    # systemGroupedBackground (light)
CARD        = colors.HexColor("#FFFFFF")
ACCENT      = colors.HexColor("#007AFF")    # system blue
ACCENT_SOFT = colors.HexColor("#E5F0FF")
GREEN       = colors.HexColor("#34C759")
ORANGE      = colors.HexColor("#FF9500")
RED         = colors.HexColor("#FF3B30")
INDIGO      = colors.HexColor("#5856D6")
LABEL       = colors.HexColor("#000000")
LABEL2      = colors.HexColor("#3C3C43")    # secondary label (60%)
LABEL3      = colors.HexColor("#8E8E93")    # tertiary label
SEP         = colors.HexColor("#C6C6C8")
WHITE       = colors.white

W_PHONE  = 3.3 * inch     # iPhone 15 Pro logical width
H_PHONE  = 6.8 * inch     # iPhone 15 Pro logical height
CORNER   = 20             # phone corner radius
STATUS_H = 0.22 * inch    # status bar height
TAB_H    = 0.6 * inch     # tab bar height


# ── Low-level helpers ─────────────────────────────────────────────────────────

def phone_frame(d: Drawing, x=0, y=0):
    """Draws phone outline with rounded corners and status bar."""
    # Body
    d.add(Rect(x, y, W_PHONE, H_PHONE,
               rx=CORNER, ry=CORNER,
               fillColor=BG, strokeColor=colors.HexColor("#D1D1D6"),
               strokeWidth=1.5))
    # Status bar tint
    d.add(Rect(x, y + H_PHONE - STATUS_H, W_PHONE, STATUS_H,
               rx=0, ry=0, fillColor=colors.transparent, strokeColor=None))
    # Dynamic island pill
    pill_w, pill_h = 0.6*inch, 0.12*inch
    d.add(Rect(x + W_PHONE/2 - pill_w/2, y + H_PHONE - STATUS_H + 4,
               pill_w, pill_h, rx=pill_h/2, ry=pill_h/2,
               fillColor=LABEL, strokeColor=None))


def card(d: Drawing, x, y, w, h, fill=CARD, stroke=SEP, radius=10):
    d.add(Rect(x, y, w, h, rx=radius, ry=radius,
               fillColor=fill, strokeColor=stroke, strokeWidth=0.5))


def label(d, x, y, text, size=8, color=LABEL, bold=False, align="left"):
    font = "Helvetica-Bold" if bold else "Helvetica"
    s = String(x, y, text, fontSize=size, fillColor=color,
               fontName=font, textAnchor={"left":"start","center":"middle","right":"end"}.get(align,"start"))
    d.add(s)


def pill(d, x, y, w, h, fill=ACCENT_SOFT, text="", text_color=ACCENT, radius=None):
    r = (h/2) if radius is None else radius
    d.add(Rect(x, y, w, h, rx=r, ry=r, fillColor=fill, strokeColor=None))
    if text:
        label(d, x + w/2, y + h/2 - 3, text, size=6, color=text_color, align="center")


def hbar(d, x, y, w, h, pct, fill=ACCENT):
    d.add(Rect(x, y, w, h, rx=2, ry=2,
               fillColor=colors.HexColor("#E5E5EA"), strokeColor=None))
    d.add(Rect(x, y, w * pct, h, rx=2, ry=2, fillColor=fill, strokeColor=None))


def tab_bar(d, x, y, w, tabs, active_idx):
    d.add(Rect(x, y, w, TAB_H, rx=0, ry=0,
               fillColor=colors.HexColor("#F9F9F9"),
               strokeColor=SEP, strokeWidth=0.5))
    tw = w / len(tabs)
    for i, (icon, name) in enumerate(tabs):
        tx = x + i * tw + tw/2
        col = ACCENT if i == active_idx else LABEL3
        label(d, tx, y + TAB_H - 0.17*inch, icon, size=14, color=col, align="center")
        label(d, tx, y + 5, name, size=6, color=col, align="center")


# ── Screen drawers ────────────────────────────────────────────────────────────

TABS = [("🛡", "Shield"), ("⚙", "Settings"), ("📡", "Routing"),
        ("📊", "Diagnostics"), ("👤", "Account")]

def content_region(d, px, py):
    """Returns (cx, cy, cw, ch) — usable area inside phone minus status+tab."""
    cx = px
    cy = py + TAB_H
    cw = W_PHONE
    ch = H_PHONE - STATUS_H - TAB_H
    return cx, cy, cw, ch


def draw_onboarding(d, px, py):
    phone_frame(d, px, py)
    _, cy, cw, ch = content_region(d, px, py)
    # No tab bar on onboarding

    # Large shield icon area
    shield_cx = px + cw/2
    shield_cy = py + H_PHONE*0.62
    d.add(Circle(shield_cx, shield_cy, 0.55*inch,
                 fillColor=ACCENT, strokeColor=None))
    label(d, shield_cx, shield_cy - 5, "🛡", size=24, align="center")

    label(d, px + cw/2, shield_cy - 0.75*inch, "Project Nexus",
          size=14, color=LABEL, bold=True, align="center")
    label(d, px + cw/2, shield_cy - 0.95*inch,
          "Protect your voice from AI transcription",
          size=7, color=LABEL2, align="center")

    # Page dots
    dot_y = py + H_PHONE*0.32
    for i in range(4):
        cx2 = px + cw/2 + (i-1.5)*12
        d.add(Circle(cx2, dot_y, 3,
                     fillColor=ACCENT if i==0 else SEP, strokeColor=None))

    # CTA button
    btn_x = px + 0.4*inch
    btn_y = py + H_PHONE*0.18
    btn_w = cw - 0.8*inch
    d.add(Rect(btn_x, btn_y, btn_w, 0.38*inch, rx=12, ry=12,
               fillColor=ACCENT, strokeColor=None))
    label(d, px + cw/2, btn_y + 0.13*inch, "Get Started",
          size=9, color=WHITE, bold=True, align="center")


def draw_main_shield(d, px, py):
    phone_frame(d, px, py)
    cx, cy, cw, ch = content_region(d, px, py)
    tab_bar(d, px, py, W_PHONE, TABS, 0)

    # Ambient rings
    shield_cx = px + cw/2
    shield_cy = cy + ch*0.60
    d.add(Circle(shield_cx, shield_cy, 0.82*inch,
                 fillColor=colors.HexColor("#E8F0FF"), strokeColor=None))
    d.add(Circle(shield_cx, shield_cy, 0.70*inch,
                 fillColor=ACCENT, strokeColor=None))
    label(d, shield_cx, shield_cy + 6, "🛡", size=26, align="center")
    label(d, shield_cx, shield_cy - 0.1*inch, "Active", size=7, color=WHITE, bold=True, align="center")

    # Waveform inside button (tiny)
    for dx in range(-16, 17, 4):
        h2 = abs(dx) * 0.02 + 0.02
        d.add(Rect(shield_cx + dx - 1.5, shield_cy - 0.26*inch,
                   3, h2*inch, rx=1, ry=1,
                   fillColor=colors.HexColor("#AAAEFF"), strokeColor=None))

    label(d, shield_cx, shield_cy + 0.62*inch, "Protecting your voice",
          size=8, color=ACCENT, bold=True, align="center")
    label(d, shield_cx, shield_cy + 0.48*inch, "3 techniques running",
          size=7, color=LABEL3, align="center")

    # Spectrum card at bottom
    spec_y = cy + 4
    card(d, px + 8, spec_y, cw - 16, ch * 0.32)
    label(d, px + 18, spec_y + ch*0.32 - 14, "Spectrum", size=8, color=LABEL, bold=True)
    # Mini bars
    bar_y = spec_y + 12
    for i in range(32):
        bh = (abs(i-16)/16 * 0.5 + 0.1) * 0.4*inch
        bc = ACCENT if i < 18 else INDIGO
        d.add(Rect(px + 12 + i*6, bar_y, 4, bh, rx=1, ry=1,
                   fillColor=bc, strokeColor=None))
    # Level meter
    hbar(d, px + 12, spec_y + 8, cw - 28, 4, 0.65)


def draw_settings(d, px, py):
    phone_frame(d, px, py)
    cx, cy, cw, ch = content_region(d, px, py)
    tab_bar(d, px, py, W_PHONE, TABS, 1)

    label(d, px + 16, cy + ch - 28, "Settings", size=14, color=LABEL, bold=True)

    rows = [
        ("Acoustic (Tier 1)", True, None),
        ("Spectral Notch", True, "toggle"),
        ("Babble Noise", True, "toggle"),
        ("Frequency Sweep", False, "toggle"),
        ("Adversarial ML (Tier 2)", True, None),
        ("UAP Ensemble", True, "toggle"),
    ]
    row_h = 0.28*inch
    y_cursor = cy + ch - 58
    for name, enabled, ctrl in rows:
        if ctrl is None:
            label(d, px + 16, y_cursor, name, size=7, color=LABEL3)
        else:
            card(d, px + 8, y_cursor - row_h + 6, cw - 16, row_h - 2)
            label(d, px + 18, y_cursor - 8, name, size=8, color=LABEL)
            if ctrl == "toggle":
                tog_x = px + cw - 50
                tog_col = ACCENT if enabled else SEP
                d.add(Rect(tog_x, y_cursor - 12, 28, 14, rx=7, ry=7,
                           fillColor=tog_col, strokeColor=None))
                knob_x = tog_x + (18 if enabled else 4)
                d.add(Circle(knob_x, y_cursor - 5, 5, fillColor=WHITE, strokeColor=None))
        y_cursor -= row_h

    # Intensity card
    int_y = cy + 14
    card(d, px + 8, int_y, cw - 16, 0.65*inch)
    label(d, px + 18, int_y + 0.48*inch, "Intensity", size=8, color=LABEL, bold=True)
    label(d, px + cw - 40, int_y + 0.48*inch, "80%", size=8, color=ACCENT, bold=True)
    hbar(d, px + 18, int_y + 0.22*inch, cw - 36, 5, 0.80)


def draw_routing(d, px, py):
    phone_frame(d, px, py)
    cx, cy, cw, ch = content_region(d, px, py)
    tab_bar(d, px, py, W_PHONE, TABS, 2)

    label(d, px + 16, cy + ch - 28, "Routing", size=14, color=LABEL, bold=True)

    modes = [
        ("Speaker Playback", True,
         "Plays through device speaker", ["No setup", "Any app", "Offline"]),
        ("VoIP Mix", False,
         "Direct mix into outgoing audio", ["Direct mix", "Inaudible"]),
    ]
    y_cur = cy + ch - 56
    for name, selected, desc, tags in modes:
        h2 = 0.85*inch
        stroke = ACCENT if selected else SEP
        card(d, px + 8, y_cur - h2, cw - 16, h2, stroke=stroke)
        label(d, px + 18, y_cur - 14, name, size=9, color=LABEL, bold=True)
        if selected:
            label(d, px + cw - 24, y_cur - 14, "✓", size=9, color=ACCENT)
        label(d, px + 18, y_cur - 26, desc, size=7, color=LABEL2)
        tx = px + 18
        for tag in tags:
            pill(d, tx, y_cur - h2 + 8, len(tag)*4.5 + 12, 14, text=tag)
            tx += len(tag)*4.5 + 18
        y_cur -= h2 + 10

    # BT section
    bt_y = cy + 12
    card(d, px + 8, bt_y, cw - 16, 0.55*inch)
    label(d, px + 18, bt_y + 0.38*inch, "AirPods High-Quality Input", size=8, color=LABEL, bold=True)
    label(d, px + 18, bt_y + 0.22*inch, "Switches AirPods to wide-band mic mode", size=6, color=LABEL3)
    tog_x = px + cw - 50
    d.add(Rect(tog_x, bt_y + 0.25*inch, 28, 14, rx=7, ry=7, fillColor=SEP, strokeColor=None))
    d.add(Circle(tog_x + 6, bt_y + 0.25*inch + 7, 5, fillColor=WHITE, strokeColor=None))


def draw_diagnostics(d, px, py):
    phone_frame(d, px, py)
    cx, cy, cw, ch = content_region(d, px, py)
    tab_bar(d, px, py, W_PHONE, TABS, 3)

    label(d, px + 16, cy + ch - 28, "Diagnostics", size=14, color=LABEL, bold=True)
    d.add(Circle(px + cw - 18, cy + ch - 22, 4, fillColor=GREEN, strokeColor=None))
    label(d, px + cw - 30, cy + ch - 24, "LIVE", size=5, color=GREEN, bold=True, align="right")

    # Spectrum card
    spec_y = cy + ch - 68
    card(d, px + 8, spec_y - 0.9*inch, cw - 16, 0.9*inch)
    for i in range(32):
        bh = (abs(i-16)/16*0.6 + 0.15)*0.55*inch
        bc = ACCENT if i < 18 else INDIGO
        d.add(Rect(px + 12 + i*6, spec_y - 0.85*inch, 4, bh, rx=1, ry=1,
                   fillColor=bc, strokeColor=None))

    # Metric tiles 2×3
    tile_w = (cw - 24) / 2
    tile_h = 0.55*inch
    metrics = [
        ("LATENCY", "12.3", "ms", GREEN),
        ("RMS LEVEL", "-18.4", "dB", ACCENT),
        ("PEAK LEVEL", "-6.1", "dB", ORANGE),
        ("UNDERRUNS", "0", "", GREEN),
        ("CPU", "14.2", "%", GREEN),
    ]
    grid_y = cy + ch - 68 - 0.9*inch - 10
    for i, (name, val, unit, col) in enumerate(metrics):
        row, col_i = divmod(i, 2)
        tx = px + 8 + col_i*(tile_w + 8)
        ty = grid_y - (row+1)*tile_h - row*6
        card(d, tx, ty, tile_w, tile_h, fill=colors.HexColor("#F9F9FB"))
        label(d, tx + 8, ty + tile_h - 14, name, size=5, color=LABEL3)
        label(d, tx + 8, ty + 10, val + unit, size=11, color=col, bold=True)

    # ASR Jam card
    jam_y = cy + 8
    card(d, px + 8, jam_y, cw - 16, 0.6*inch)
    label(d, px + 18, jam_y + 0.44*inch, "ASR JAMMING", size=6, color=LABEL3, bold=True)
    label(d, px + 18, jam_y + 0.28*inch, "73%", size=16, color=RED, bold=True)
    hbar(d, px + 18, jam_y + 0.14*inch, cw - 36, 5, 0.73, fill=RED)
    pill(d, px + cw - 55, jam_y + 0.38*inch, 40, 14, fill=colors.HexColor("#FFE5E3"),
         text="High", text_color=RED)


def draw_account(d, px, py):
    phone_frame(d, px, py)
    cx, cy, cw, ch = content_region(d, px, py)
    tab_bar(d, px, py, W_PHONE, TABS, 4)

    label(d, px + 16, cy + ch - 28, "Account", size=14, color=LABEL, bold=True)

    # Stats
    label(d, px + 16, cy + ch - 50, "Your Shield Stats", size=7, color=LABEL3)
    stats = [
        ("🛡", "Total Activations", "42", ACCENT),
        ("⏱", "Total Protected Time", "3h 14m", GREEN),
        ("📉", "Peak ASR Jam Score", "87%", RED),
        ("📅", "Sessions Recorded", "18", LABEL3),
    ]
    row_h = 0.26*inch
    y_cur = cy + ch - 62
    for icon, stat_name, val, col in stats:
        card(d, px + 8, y_cur - row_h + 4, cw - 16, row_h - 2)
        label(d, px + 18, y_cur - 8, icon + "  " + stat_name, size=8, color=LABEL)
        label(d, px + cw - 16, y_cur - 8, val, size=8, color=col, bold=True, align="right")
        y_cur -= row_h

    # Data & Privacy
    label(d, px + 16, y_cur - 4, "Data & Privacy", size=7, color=LABEL3)
    y_cur -= 18
    for item in ["Session History →", "Delete Analytics Data"]:
        col = RED if "Delete" in item else LABEL
        card(d, px + 8, y_cur - 0.25*inch, cw - 16, 0.24*inch)
        label(d, px + 18, y_cur - 12, item, size=8, color=col)
        y_cur -= 0.28*inch

    # About
    label(d, px + 16, y_cur - 4, "About", size=7, color=LABEL3)
    y_cur -= 16
    about = [("Version", "1.0 (1)"), ("Privacy", "100% On-Device")]
    for key, val in about:
        card(d, px + 8, y_cur - 0.24*inch, cw - 16, 0.22*inch)
        label(d, px + 18, y_cur - 10, key, size=8, color=LABEL2)
        label(d, px + cw - 16, y_cur - 10, val, size=8, color=LABEL3, align="right")
        y_cur -= 0.26*inch


# ── PhoneFlowable ─────────────────────────────────────────────────────────────

class PhoneDrawing(Flowable):
    def __init__(self, draw_fn, title, desc, w=W_PHONE, h=H_PHONE):
        super().__init__()
        self.draw_fn = draw_fn
        self.title = title
        self.desc = desc
        self.phone_w = w
        self.phone_h = h
        self.width = w
        self.height = h + 0.55*inch

    def draw(self):
        d = Drawing(self.phone_w, self.phone_h)
        self.draw_fn(d, 0, 0)
        renderPDF.draw(d, self.canv, 0, 0.55*inch)
        self.canv.setFont("Helvetica-Bold", 10)
        self.canv.setFillColor(LABEL)
        self.canv.drawString(0, 0.38*inch, self.title)
        self.canv.setFont("Helvetica", 8)
        self.canv.setFillColor(LABEL2)
        self.canv.drawString(0, 0.22*inch, self.desc)


# ── Main ──────────────────────────────────────────────────────────────────────

def build():
    out = os.path.join(os.path.dirname(__file__), "ProjectNexus_ScreenDesigns.pdf")
    doc = SimpleDocTemplate(out, pagesize=letter,
                            leftMargin=0.5*inch, rightMargin=0.5*inch,
                            topMargin=0.5*inch, bottomMargin=0.5*inch)

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("T", parent=styles["Title"],
                                  fontSize=22, spaceAfter=4, textColor=colors.HexColor("#1C1C1E"))
    sub_style   = ParagraphStyle("S", parent=styles["Normal"],
                                  fontSize=11, textColor=colors.HexColor("#636366"), spaceAfter=16)
    h2_style    = ParagraphStyle("H2", parent=styles["Heading2"],
                                  fontSize=14, textColor=colors.HexColor("#1C1C1E"),
                                  spaceBefore=20, spaceAfter=8)

    story = []

    story.append(Paragraph("Project Nexus", title_style))
    story.append(Paragraph("Screen Design Reference  ·  iOS 18  ·  Swift 6", sub_style))
    story.append(HRFlowable(width="100%", thickness=0.5, color=SEP))
    story.append(Spacer(1, 0.15*inch))

    screens = [
        (draw_onboarding,    "Onboarding",    "Welcome + 4-page TabView journey with mic permission request"),
        (draw_main_shield,   "Shield (Home)", "Audio-reactive button, ambient rings, spectrum + level meter, sparkline"),
        (draw_settings,      "Settings",      "Native Form: Tier toggles, technique switches, intensity slider, codec picker"),
        (draw_routing,       "Routing",       "Mode selection, AirPods HQ toggle, live route / mic status"),
        (draw_diagnostics,   "Diagnostics",   "Spectrum analyser, 5-tile metrics grid, ASR jamming effectiveness panel"),
        (draw_account,       "Account",       "Stats dashboard, session history, analytics deletion, app reset"),
    ]

    # Lay out 2 phones per row
    for i in range(0, len(screens), 2):
        row_items = screens[i:i+2]
        row_drawables = []
        for fn, title, desc in row_items:
            row_drawables.append(PhoneDrawing(fn, title, desc))

        gap = 0.25*inch
        if len(row_drawables) == 2:
            table_data = [[row_drawables[0], row_drawables[1]]]
            col_w = [W_PHONE + gap, W_PHONE + gap]
        else:
            table_data = [[row_drawables[0]]]
            col_w = [W_PHONE + gap]

        t = Table(table_data, colWidths=col_w)
        t.setStyle(TableStyle([
            ("ALIGN",  (0,0), (-1,-1), "CENTER"),
            ("VALIGN", (0,0), (-1,-1), "TOP"),
            ("LEFTPADDING",  (0,0), (-1,-1), 0),
            ("RIGHTPADDING", (0,0), (-1,-1), 0),
        ]))
        story.append(t)
        story.append(Spacer(1, 0.3*inch))

    # Design tokens reference
    story.append(HRFlowable(width="100%", thickness=0.5, color=SEP))
    story.append(Paragraph("Design Tokens", h2_style))
    tokens = [
        ["Token", "Value", "Usage"],
        ["accent", "#007AFF", "Primary interactive colour, shield button, toggles"],
        ["positive", "#34C759", "Latency OK, mic available, low jam score"],
        ["warning", "#FF9500", "Latency >30 ms, moderate jam score"],
        ["danger", "#FF3B30", "Peak clip, high jam score, delete actions"],
        ["tier1", "hue 0.55", "Acoustic DSP spectrum bars (blue-teal)"],
        ["tier2", "hue 0.73", "Adversarial ML bars (indigo-violet)"],
        ["background", "systemGroupedBackground", "Adaptive page background"],
        ["cardBackground", "secondarySystemGroupedBackground", "Card surfaces"],
        ["cardStroke", "separator ×0.5", "1 px card border"],
        ["textPrimary", "Color.primary", "Headline text"],
        ["textSecondary", "Color.secondary", "Body / description"],
        ["textTertiary", "tertiaryLabel", "Caption / metadata"],
    ]
    ts = TableStyle([
        ("BACKGROUND", (0,0), (-1,0), ACCENT),
        ("TEXTCOLOR",  (0,0), (-1,0), WHITE),
        ("FONTNAME",   (0,0), (-1,0), "Helvetica-Bold"),
        ("FONTSIZE",   (0,0), (-1,-1), 8),
        ("ROWBACKGROUNDS", (0,1), (-1,-1), [WHITE, colors.HexColor("#F7F7F7")]),
        ("GRID", (0,0), (-1,-1), 0.25, SEP),
        ("LEFTPADDING",  (0,0), (-1,-1), 6),
        ("RIGHTPADDING", (0,0), (-1,-1), 6),
        ("TOPPADDING",   (0,0), (-1,-1), 5),
        ("BOTTOMPADDING",(0,0), (-1,-1), 5),
    ])
    token_table = Table(tokens, colWidths=[1.1*inch, 1.5*inch, 4.4*inch])
    token_table.setStyle(ts)
    story.append(token_table)

    doc.build(story)
    print(f"PDF written → {out}")
    return out


if __name__ == "__main__":
    build()
