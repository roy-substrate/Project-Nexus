#!/usr/bin/env python3
"""
Project Nexus — Design Preview PDF Generator (ReportLab)
Renders 6 iPhone screens + design tokens + typography + component specs.
"""

from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import os, math

# ─── Colour palette ────────────────────────────────────────────────────────────
BG        = colors.HexColor('#000000')
SURFACE   = colors.HexColor('#0D0D0D')
BORDER    = colors.HexColor('#D9D9D9')
TEXT      = colors.HexColor('#F0F0F0')
TEXT_DIM  = colors.HexColor('#737373')
PHOSPHOR  = colors.HexColor('#39FF14')
PHOS_DIM  = colors.HexColor('#1A5C09')
WARNING   = colors.HexColor('#FFB32E')
PAGE_BG   = colors.HexColor('#111111')

# ─── Page setup ───────────────────────────────────────────────────────────────
W, H = landscape(A4)   # 297 × 210 mm
MARGIN = 14 * mm

OUT_PATH = os.path.join(os.path.dirname(__file__), 'design_preview.pdf')

# ─── Drawing helpers ───────────────────────────────────────────────────────────

def rect_filled(c, x, y, w, h, fill):
    c.setFillColor(fill)
    c.rect(x, y, w, h, fill=1, stroke=0)

def rect_stroke(c, x, y, w, h, stroke_color, lw=0.5):
    c.setStrokeColor(stroke_color)
    c.setLineWidth(lw)
    c.rect(x, y, w, h, fill=0, stroke=1)

def rect_filled_stroke(c, x, y, w, h, fill, stroke_color, lw=0.5):
    c.setFillColor(fill)
    c.setStrokeColor(stroke_color)
    c.setLineWidth(lw)
    c.rect(x, y, w, h, fill=1, stroke=1)

def text_at(c, x, y, txt, font='Courier', size=7, color=TEXT, align='left'):
    c.setFont(font, size)
    c.setFillColor(color)
    if align == 'center':
        c.drawCentredString(x, y, txt)
    elif align == 'right':
        c.drawRightString(x, y, txt)
    else:
        c.drawString(x, y, txt)

def scanlines(c, x, y, w, h):
    """Draw CRT scanline overlay over a region."""
    c.saveState()
    c.setFillColor(colors.Color(0, 0, 0, alpha=0.04))
    cy = y
    while cy < y + h:
        c.rect(x, cy, w, 0.5, fill=1, stroke=0)
        cy += 2
    c.restoreState()

# ─── Phone frame ───────────────────────────────────────────────────────────────
PHONE_W  = 47 * mm
PHONE_H  = 90 * mm

def phone_frame(c, px, py, title):
    """Draw phone outline and return (px, py) for inner content."""
    # Outer shell
    rect_filled_stroke(c, px, py, PHONE_W, PHONE_H, BG, BORDER, lw=0.7)
    # Scanlines
    scanlines(c, px, py, PHONE_W, PHONE_H)
    # Status bar bg
    rect_filled(c, px, py + PHONE_H - 5.5*mm, PHONE_W, 5.5*mm, BG)
    # Time
    text_at(c, px + 2.5*mm, py + PHONE_H - 3.8*mm, '9:41', size=6, color=TEXT)
    # Icons
    text_at(c, px + PHONE_W - 2.5*mm, py + PHONE_H - 3.8*mm, '||| 100%',
            size=5.5, color=TEXT, align='right')
    # Separator
    c.setStrokeColor(BORDER)
    c.setLineWidth(0.3)
    c.line(px, py + PHONE_H - 5.5*mm, px + PHONE_W, py + PHONE_H - 5.5*mm)
    # Screen label below phone
    text_at(c, px + PHONE_W/2, py - 5, title, size=5.5, color=TEXT_DIM, align='center')
    # Return top-left of inner content area (bottom of status bar)
    return px, py + PHONE_H - 5.5*mm

# ─── Spectrum bars ─────────────────────────────────────────────────────────────
BAR_HEIGHTS_IDLE   = [.28,.42,.58,.48,.35,.65,.52,.38,.28,.22,.18,.13]
BAR_HEIGHTS_ACTIVE = [.35,.55,.78,.20,.62,.88,.70,.22,.44,.34,.28,.18]
IS_NOTCH = [False]*12
IS_NOTCH_ACTIVE = [F:=False,F,F,True,F,F,F,True,F,F,F,F]

def draw_spectrum(c, x, y, w, h, active=False):
    rect_filled_stroke(c, x, y, w, h, BG, BORDER, lw=0.4)
    heights = BAR_HEIGHTS_ACTIVE if active else BAR_HEIGHTS_IDLE
    notched = IS_NOTCH_ACTIVE if active else IS_NOTCH
    n = len(heights)
    bar_w = (w - 2) / n
    for i, (ht, notch) in enumerate(zip(heights, notched)):
        bh = ht * (h - 2)
        bx = x + 1 + i * bar_w
        by = y + 1
        if active:
            col = PHOS_DIM if notch else PHOSPHOR
        else:
            col = TEXT_DIM
        c.setFillColor(col)
        c.rect(bx, by, bar_w - 0.5, bh, fill=1, stroke=0)

def draw_level_bar(c, x, y, w, h, pct, active=False):
    rect_filled_stroke(c, x, y, w, h, colors.HexColor('#1A1A1A'), colors.HexColor('#333333'), lw=0.3)
    fill_col = PHOSPHOR if active else TEXT_DIM
    c.setFillColor(fill_col)
    c.rect(x, y, w * pct, h, fill=1, stroke=0)

# ─── Progress text bar ─────────────────────────────────────────────────────────
def progress_bar_text(pct, width=12):
    filled = round(pct * width)
    return '[' + '█' * filled + '░' * (width - filled) + f' {int(pct*100)}%]'

# ─── Draw strip ────────────────────────────────────────────────────────────────
def draw_status_strip(c, px, py, active=False):
    sy = py - 5.5*mm
    rect_filled(c, px, sy, PHONE_W, 5.5*mm, BG)
    c.setStrokeColor(BORDER)
    c.setLineWidth(0.3)
    c.line(px, sy + 5.5*mm, px + PHONE_W, sy + 5.5*mm)
    lv = 'LAT:7ms  LVL:-28dB  ROUTE:SPK  TECH:5' if active else 'LAT:8ms  LVL:-42dB  ROUTE:SPK  TECH:5'
    text_at(c, px + 2*mm, sy + 1.5*mm, lv, size=5, color=TEXT_DIM)
    return sy

# ─── Tier button ────────────────────────────────────────────────────────────────
def draw_tier_btn(c, x, y, w, h, label, sublabel, enabled=True):
    bc = PHOSPHOR if enabled else BORDER
    rect_filled_stroke(c, x, y, w, h, BG, bc, lw=0.5)
    tc = PHOSPHOR if enabled else TEXT
    dot = '●' if enabled else '○'
    dc = PHOSPHOR if enabled else TEXT_DIM
    cx = x + w / 2
    text_at(c, cx - 2.5*mm, y + h - 3.2*mm, label, size=7.5, color=tc, align='center')
    text_at(c, cx + 1.5*mm, y + h - 3.2*mm, dot, size=6, color=dc, align='center')
    text_at(c, cx, y + 1.8*mm, sublabel, size=5, color=TEXT_DIM, align='center')

# ─── Card box ─────────────────────────────────────────────────────────────────
def card_box(c, x, y, w, h):
    rect_filled_stroke(c, x, y, w, h, SURFACE, BORDER, lw=0.4)

# ─────────────────────────────────────────────────────────────────────────────
# PAGE 1: Screens  (landscape A4)
# ─────────────────────────────────────────────────────────────────────────────

def draw_page1(c):
    rect_filled(c, 0, 0, W, H, PAGE_BG)

    # Title bar
    text_at(c, W/2, H - 10*mm, '> PROJECT NEXUS — DESIGN SYSTEM v1.0',
            size=10, color=PHOSPHOR, align='center')
    text_at(c, W/2, H - 15*mm,
            'PIXEL TERMINAL AESTHETIC · COURIER MONO · PHOSPHOR #39FF14 · 2026-03-16',
            size=6, color=TEXT_DIM, align='center')

    top_y = H - 25*mm   # top of phone row
    # 6 phones, spaced evenly
    total_w = 6 * PHONE_W + 5 * 8*mm
    start_x = (W - total_w) / 2

    phones = [
        'MAIN · OFFLINE',
        'MAIN · ACTIVE',
        'ONBOARD · WELCOME',
        'ONBOARD · HOW IT WORKS',
        'ONBOARD · MICROPHONE',
        'ONBOARD · READY',
    ]

    draw_fns = [
        draw_screen_main_offline,
        draw_screen_main_active,
        draw_screen_ob_welcome,
        draw_screen_ob_hiw,
        draw_screen_ob_perm,
        draw_screen_ob_ready,
    ]

    for i, (lbl, fn) in enumerate(zip(phones, draw_fns)):
        px = start_x + i * (PHONE_W + 8*mm)
        py = top_y - PHONE_H
        ix, iy = phone_frame(c, px, py, lbl)
        fn(c, px, py, ix, iy)


# ─── Main · Offline ────────────────────────────────────────────────────────────
def draw_screen_main_offline(c, px, py, ix, iy):
    inner_top = iy   # content starts here, going down
    cy = inner_top - 3*mm

    # Shield box
    sb_w = 18*mm; sb_h = 18*mm
    sb_x = px + (PHONE_W - sb_w) / 2
    sb_y = cy - sb_h
    rect_filled_stroke(c, sb_x, sb_y, sb_w, sb_h, BG, BORDER, lw=0.6)
    text_at(c, sb_x + sb_w/2, sb_y + sb_h - 5*mm, '[NEXUS]', size=6.5, color=TEXT_DIM, align='center')
    lines = ['/  \\', '| S |', ' \\_/']
    for j, ln in enumerate(lines):
        text_at(c, sb_x + sb_w/2, sb_y + sb_h - 9*mm - j*2.5*mm, ln,
                size=5.5, color=TEXT_DIM, align='center')
    cy = sb_y - 3*mm

    # Status
    text_at(c, px + PHONE_W/2, cy, '> SHIELD OFFLINE', size=7.5, color=TEXT_DIM,
            align='center', font='Courier-Bold')
    cy -= 4*mm
    text_at(c, px + PHONE_W/2, cy, 'VOICE PROTECTION OFFLINE', size=5.5, color=TEXT_DIM, align='center')
    cy -= 3*mm
    text_at(c, px + PHONE_W/2, cy, 'SESSIONS LOGGED: 4', size=5.5, color=TEXT_DIM, align='center')
    cy -= 5*mm

    # Tier row
    tier_h = 7*mm; tier_w = (PHONE_W - 4*mm - 2*mm) / 2
    draw_tier_btn(c, px + 2*mm, cy - tier_h, tier_w, tier_h, 'STD', 'TIER 1', True)
    draw_tier_btn(c, px + 2*mm + tier_w + 2*mm, cy - tier_h, tier_w, tier_h, 'AI', 'TIER 2', True)
    cy -= tier_h + 2*mm

    # Spectrum card
    card_h = 22*mm
    card_x = px + 2*mm; card_y = cy - card_h
    card_box(c, card_x, card_y, PHONE_W - 4*mm, card_h)
    text_at(c, card_x + 2*mm, card_y + card_h - 3.5*mm, 'SPECTRUM ANALYSIS', size=5.5, color=TEXT)
    spec_y = card_y + 1.5*mm; spec_h = 10*mm
    draw_spectrum(c, card_x + 2*mm, spec_y + 2*mm, PHONE_W - 8*mm, spec_h, active=False)
    ax_y = spec_y + 0.5*mm
    for lbl, align, off in [('100HZ','left',0), ('1KHZ','center',0), ('4KHZ','center',0), ('20KHZ','right',0)]:
        ax = card_x + 2*mm if align=='left' else (card_x + PHONE_W - 6*mm if align=='right' else card_x + PHONE_W/2 - 4*mm + off)
        text_at(c, ax, ax_y, lbl, size=4.5, color=TEXT_DIM)
    draw_level_bar(c, card_x + 2*mm, spec_y + 13.5*mm, PHONE_W - 8*mm, 1.2*mm, 0.18, active=False)
    cy = card_y - 2*mm

    # Intensity card
    card2_h = 16*mm
    card2_y = cy - card2_h
    card_box(c, card_x, card2_y, PHONE_W - 4*mm, card2_h)
    text_at(c, card_x + 2*mm, card2_y + card2_h - 3.5*mm, 'INTENSITY', size=5.5, color=TEXT)
    text_at(c, card_x + PHONE_W - 6*mm, card2_y + card2_h - 3.5*mm, '70%', size=6.5,
            color=TEXT, align='right', font='Courier-Bold')
    pb = progress_bar_text(0.70, 10)
    text_at(c, card_x + 2*mm, card2_y + card2_h - 6.5*mm, pb, size=5.5, color=TEXT)
    # Slider
    sl_y = card2_y + 5.5*mm; sl_x = card_x + 2*mm; sl_w = PHONE_W - 8*mm
    rect_filled_stroke(c, sl_x, sl_y, sl_w, 1*mm, colors.HexColor('#1A1A1A'), colors.HexColor('#333'), lw=0.3)
    c.setFillColor(BORDER)
    c.rect(sl_x, sl_y, sl_w * 0.70, 1*mm, fill=1, stroke=0)
    # Hint
    text_at(c, card_x + 2*mm, card2_y + 2.5*mm, 'HIGHER VALUES INCREASE JAM EFFECTIVENESS', size=4.2, color=TEXT_DIM)

    # Status strip
    strip_y = py + 5.5*mm
    rect_filled(c, px, py, PHONE_W, 5.5*mm, BG)
    c.setStrokeColor(BORDER)
    c.setLineWidth(0.3)
    c.line(px, py + 5.5*mm, px + PHONE_W, py + 5.5*mm)
    text_at(c, px + 2*mm, py + 1.8*mm, 'LAT:8ms  LVL:-42dB  ROUTE:SPK  TECH:5', size=4.5, color=TEXT_DIM)


# ─── Main · Active ─────────────────────────────────────────────────────────────
def draw_screen_main_active(c, px, py, ix, iy):
    cy = iy - 3*mm

    # Shield box — phosphor border, dark green fill
    sb_w = 18*mm; sb_h = 18*mm
    sb_x = px + (PHONE_W - sb_w) / 2
    sb_y = cy - sb_h
    rect_filled_stroke(c, sb_x, sb_y, sb_w, sb_h, colors.HexColor('#020E00'), PHOSPHOR, lw=0.9)
    text_at(c, sb_x + sb_w/2, sb_y + sb_h - 5*mm, '[NEXUS]', size=6.5, color=PHOSPHOR,
            align='center', font='Courier-Bold')
    # Waveform text
    text_at(c, sb_x + sb_w/2, sb_y + sb_h - 9*mm, '_/\\/\\__/\\/_', size=6, color=PHOSPHOR, align='center')
    cy = sb_y - 2.5*mm

    # Status active
    text_at(c, px + PHONE_W/2, cy, '> SHIELD ACTIVE ▌', size=7.5, color=PHOSPHOR,
            align='center', font='Courier-Bold')
    cy -= 3.5*mm

    # Uptime
    text_at(c, px + PHONE_W/2, cy, 'UPTIME', size=5, color=TEXT_DIM, align='center')
    cy -= 5*mm
    text_at(c, px + PHONE_W/2, cy, '03:47', size=16, color=PHOSPHOR, align='center', font='Courier-Bold')
    cy -= 3.5*mm
    text_at(c, px + PHONE_W/2, cy, 'TECH:5  ACTIVE', size=5.5, color=TEXT_DIM, align='center')
    cy -= 3*mm

    # JAM badge
    jb_w = 28*mm; jb_h = 4.5*mm
    jb_x = px + (PHONE_W - jb_w) / 2
    jb_y = cy - jb_h
    rect_filled_stroke(c, jb_x, jb_y, jb_w, jb_h, BG, PHOSPHOR, lw=0.5)
    text_at(c, jb_x + 1.5*mm, jb_y + 1.3*mm, 'JAM: [████████░░ 82%]', size=5, color=PHOSPHOR)
    cy = jb_y - 2.5*mm

    # Tier row
    tier_h = 7*mm; tier_w = (PHONE_W - 4*mm - 2*mm) / 2
    draw_tier_btn(c, px + 2*mm, cy - tier_h, tier_w, tier_h, 'STD', 'TIER 1', True)
    draw_tier_btn(c, px + 2*mm + tier_w + 2*mm, cy - tier_h, tier_w, tier_h, 'AI', 'TIER 2', True)
    cy -= tier_h + 2*mm

    # Spectrum card — active
    card_h = 22*mm; card_x = px + 2*mm; card_y = cy - card_h
    card_box(c, card_x, card_y, PHONE_W - 4*mm, card_h)
    text_at(c, card_x + 2*mm, card_y + card_h - 3.5*mm, 'SPECTRUM ANALYSIS', size=5.5, color=TEXT)
    # LIVE badge
    c.setFillColor(PHOSPHOR)
    c.circle(card_x + PHONE_W - 8*mm, card_y + card_h - 2.8*mm, 1, fill=1, stroke=0)
    text_at(c, card_x + PHONE_W - 6.5*mm, card_y + card_h - 3.5*mm, 'LIVE', size=5, color=PHOSPHOR)
    draw_spectrum(c, card_x + 2*mm, card_y + 2*mm + 2*mm, PHONE_W - 8*mm, 10*mm, active=True)
    draw_level_bar(c, card_x + 2*mm, card_y + 3.5*mm, PHONE_W - 8*mm, 1.2*mm, 0.63, active=True)
    cy = card_y - 2*mm

    # Intensity card — active
    card2_h = 14*mm; card2_y = cy - card2_h
    card_box(c, card_x, card2_y, PHONE_W - 4*mm, card2_h)
    text_at(c, card_x + 2*mm, card2_y + card2_h - 3.5*mm, 'INTENSITY', size=5.5, color=TEXT)
    text_at(c, card_x + PHONE_W - 6*mm, card2_y + card2_h - 3.5*mm, '70%', size=6.5,
            color=PHOSPHOR, align='right', font='Courier-Bold')
    pb = progress_bar_text(0.70, 10)
    text_at(c, card_x + 2*mm, card2_y + card2_h - 6.5*mm, pb, size=5.5, color=PHOSPHOR)
    sl_y = card2_y + 5*mm; sl_x = card_x + 2*mm; sl_w = PHONE_W - 8*mm
    rect_filled_stroke(c, sl_x, sl_y, sl_w, 1*mm, colors.HexColor('#1A1A1A'), colors.HexColor('#333'), lw=0.3)
    c.setFillColor(PHOSPHOR)
    c.rect(sl_x, sl_y, sl_w * 0.70, 1*mm, fill=1, stroke=0)

    # Status strip
    rect_filled(c, px, py, PHONE_W, 5.5*mm, BG)
    c.setStrokeColor(BORDER)
    c.setLineWidth(0.3)
    c.line(px, py + 5.5*mm, px + PHONE_W, py + 5.5*mm)
    text_at(c, px + 2*mm, py + 1.8*mm, 'LAT:7ms  LVL:-28dB  ROUTE:SPK  TECH:5', size=4.5, color=TEXT_DIM)


# ─── Onboarding · Welcome ─────────────────────────────────────────────────────
def draw_screen_ob_welcome(c, px, py, ix, iy):
    cy = iy - 8*mm

    # ASCII logo
    logo = [
        '  _   _ _______  ___  ___',
        ' | \\ | | ____\\ \\/ / |/ /',
        ' |  \\| |  _|  \\  /| \' /',
        ' | |\\  | |___ /  \\| . \\',
        ' |_| \\_|_____/_/\\_\\_|\\_\\',
    ]
    for ln in logo:
        text_at(c, px + 2.5*mm, cy, ln, size=4.5, color=PHOSPHOR)
        cy -= 2.5*mm
    cy -= 1.5*mm

    # Version
    text_at(c, px + 2.5*mm, cy, '> ', size=6, color=PHOSPHOR)
    text_at(c, px + 5*mm, cy, 'NEXUS SHIELD v1.0', size=6, color=TEXT_DIM)
    cy -= 4.5*mm

    # Headline
    text_at(c, px + 2.5*mm, cy, 'YOUR VOICE.', size=14, color=TEXT, font='Courier-Bold')
    cy -= 7.5*mm
    text_at(c, px + 2.5*mm, cy, 'YOUR RULES.', size=14, color=TEXT, font='Courier-Bold')
    cy -= 6*mm

    # Subhead
    subs = [
        'REAL-TIME ACOUSTIC PROTECTION.',
        'DEFEATS AI TRANSCRIPTION.',
        'INVISIBLY. LOCALLY. INSTANTLY.',
    ]
    for s in subs:
        text_at(c, px + 2.5*mm, cy, s, size=5.5, color=TEXT_DIM)
        cy -= 3.5*mm

    _draw_ob_bottom(c, px, py, page=0)


def _draw_ob_bottom(c, px, py, page=0, extra_btn=None):
    """Progress dots + CTA button at bottom of onboarding."""
    # Dots
    dot_y = py + 13*mm
    total_dots = 4
    dot_spacing = 4*mm
    dots_w = total_dots * 3*mm + (total_dots - 1) * 1*mm
    dx = px + (PHONE_W - dots_w) / 2
    for i in range(total_dots):
        if i == page:
            rect_filled(c, dx, dot_y, 5*mm, 1*mm, PHOSPHOR)
            dx += 5*mm + 1*mm
        else:
            rect_filled(c, dx, dot_y, 1.5*mm, 1*mm, TEXT_DIM)
            dx += 1.5*mm + 1*mm

    # Button
    btn_y = py + 6*mm; btn_x = px + 2.5*mm; btn_w = PHONE_W - 5*mm; btn_h = 5.5*mm
    labels = ['[ GET STARTED ]', '[ CONTINUE ]', '[ ALLOW ACCESS ]', None]
    lbl = labels[page] if page < len(labels) else '[ CONTINUE ]'
    if lbl:
        rect_filled_stroke(c, btn_x, btn_y, btn_w, btn_h, BG, BORDER, lw=0.5)
        text_at(c, btn_x + btn_w/2, btn_y + 1.8*mm, lbl, size=6.5, color=TEXT, align='center')

    if extra_btn:
        text_at(c, px + PHONE_W/2, btn_y - 3*mm, extra_btn, size=5.5, color=TEXT_DIM, align='center')


# ─── Onboarding · How It Works ────────────────────────────────────────────────
def draw_screen_ob_hiw(c, px, py, ix, iy):
    cy = iy - 8*mm

    text_at(c, px + 2.5*mm, cy, '> ', size=8, color=PHOSPHOR)
    text_at(c, px + 5.5*mm, cy, 'HOW IT WORKS', size=8, color=TEXT, font='Courier-Bold')
    cy -= 4.5*mm
    text_at(c, px + 2.5*mm, cy, 'TWO LAYERS. ONE TAP. ZERO DATA.', size=5.5, color=TEXT_DIM)
    cy -= 5*mm

    steps = [
        ('01', 'ACOUSTIC MASKING',
         ['Psychoacoustic noise below hearing', 'threshold disrupts ASR systems.']),
        ('02', 'ADVERSARIAL AI',
         ['ML-crafted perturbations cause', 'Whisper and DeepSpeech to fail.']),
        ('03', 'ON-DEVICE ONLY',
         ['Under 10ms. Zero data leaves phone.', 'No cloud. No accounts.']),
    ]
    for num, title, body in steps:
        text_at(c, px + 2.5*mm, cy, num + '/ ', size=7, color=PHOSPHOR)
        text_at(c, px + 9*mm, cy, title, size=7, color=TEXT, font='Courier-Bold')
        cy -= 3.5*mm
        for ln in body:
            text_at(c, px + 4*mm, cy, ln, size=5.5, color=TEXT_DIM)
            cy -= 3*mm
        cy -= 1.5*mm

    _draw_ob_bottom(c, px, py, page=1)


# ─── Onboarding · Permission ──────────────────────────────────────────────────
def draw_screen_ob_perm(c, px, py, ix, iy):
    cy = iy - 12*mm

    # Mic icon
    mic = ['┌─────┐', '│ MIC │', '│ ))) │', '└──┬──┘', '   │   ', '───┴───']
    for ln in mic:
        text_at(c, px + PHONE_W/2, cy, ln, size=7, color=TEXT, align='center')
        cy -= 3.5*mm
    cy -= 2.5*mm

    text_at(c, px + 2.5*mm, cy, '> ', size=7, color=PHOSPHOR)
    text_at(c, px + 5.5*mm, cy, 'REQUESTING', size=7, color=TEXT, font='Courier-Bold')
    cy -= 4.5*mm
    text_at(c, px + 2.5*mm, cy, 'MICROPHONE ACCESS', size=7, color=TEXT, font='Courier-Bold')
    cy -= 4.5*mm
    text_at(c, px + 2.5*mm, cy, 'AUDIO PROCESSED ON-DEVICE ONLY.', size=5.5, color=TEXT_DIM)
    cy -= 3*mm
    text_at(c, px + 2.5*mm, cy, 'NOTHING RECORDED OR TRANSMITTED.', size=5.5, color=TEXT_DIM)

    _draw_ob_bottom(c, px, py, page=2, extra_btn='[ SKIP FOR NOW ]')


# ─── Onboarding · Ready ───────────────────────────────────────────────────────
def draw_screen_ob_ready(c, px, py, ix, iy):
    cy = iy - 10*mm

    # Checkmark box
    box_lines = ['┌───┐', '│ ✓ │', '└───┘']
    for ln in box_lines:
        text_at(c, px + 2.5*mm, cy, ln, size=9, color=PHOSPHOR)
        cy -= 4.5*mm
    cy -= 2*mm

    text_at(c, px + 2.5*mm, cy, '> SYSTEM READY ▌', size=9.5, color=PHOSPHOR, font='Courier-Bold')
    cy -= 5.5*mm
    text_at(c, px + 2.5*mm, cy, '> ALL SYSTEMS NOMINAL', size=6.5, color=PHOSPHOR)
    cy -= 5*mm
    text_at(c, px + 2.5*mm, cy, 'TAP THE SHIELD ON THE HOME SCREEN', size=5.5, color=TEXT_DIM)
    cy -= 3*mm
    text_at(c, px + 2.5*mm, cy, 'TO BEGIN VOICE PROTECTION.', size=5.5, color=TEXT_DIM)

    # CTA button — phosphor active
    btn_y = py + 6*mm; btn_x = px + 2.5*mm; btn_w = PHONE_W - 5*mm; btn_h = 5.5*mm
    rect_filled_stroke(c, btn_x, btn_y, btn_w, btn_h, BG, PHOSPHOR, lw=0.8)
    text_at(c, btn_x + btn_w/2, btn_y + 1.8*mm, '[ START NEXUS SHIELD ]',
            size=6.5, color=PHOSPHOR, align='center', font='Courier-Bold')


# ─────────────────────────────────────────────────────────────────────────────
# PAGE 2: Tokens + Typography + Components
# ─────────────────────────────────────────────────────────────────────────────

def draw_page2(c):
    rect_filled(c, 0, 0, W, H, PAGE_BG)

    text_at(c, W/2, H - 10*mm, '> DESIGN TOKENS · TYPOGRAPHY · COMPONENTS',
            size=10, color=PHOSPHOR, align='center')
    text_at(c, W/2, H - 15*mm, 'PixelDesignSystem.swift', size=6, color=TEXT_DIM, align='center')

    cy = H - 22*mm

    # ── Colour tokens ─────────────────────────────────────────────────────────
    tokens = [
        ('#000000', BG,       'BACKGROUND'),
        ('#0D0D0D', SURFACE,  'SURFACE'),
        ('#D9D9D9', BORDER,   'BORDER'),
        ('#F0F0F0', TEXT,     'TEXT'),
        ('#737373', TEXT_DIM, 'TEXT-DIM'),
        ('#39FF14', PHOSPHOR, 'PHOSPHOR'),
        ('#1A5C09', PHOS_DIM, 'PHOS-DIM'),
        ('#FFB32E', WARNING,  'WARNING'),
    ]

    section_header(c, MARGIN, cy, 'PIXELCOLOR PALETTE')
    cy -= 5*mm

    sw_w = 14*mm; sw_h = 8*mm; sw_gap = 3*mm
    row_x = MARGIN
    for hex_val, col, name in tokens:
        # Swatch
        c.setFillColor(col)
        c.setStrokeColor(colors.HexColor('#333333'))
        c.setLineWidth(0.3)
        c.rect(row_x, cy - sw_h, sw_w, sw_h, fill=1, stroke=1)
        text_at(c, row_x, cy - sw_h - 3*mm, name, size=5, color=TEXT_DIM)
        text_at(c, row_x, cy - sw_h - 6*mm, hex_val, size=5, color=TEXT)
        row_x += sw_w + sw_gap

    cy -= sw_h + 12*mm

    # ── Typography ────────────────────────────────────────────────────────────
    section_header(c, MARGIN, cy, 'PIXELFONT — ALL TYPEFACES')
    cy -= 5*mm

    type_rows = [
        ('hero() 44 bold', 'Courier-Bold', 18, PHOSPHOR, '03:47'),
        ('hero() 32 bold', 'Courier-Bold', 14, PHOSPHOR, '> SYSTEM READY ▌'),
        ('hero() 42 bold', 'Courier-Bold', 14, TEXT,     'YOUR VOICE. YOUR RULES.'),
        ('terminal() 14', 'Courier',       9,  TEXT,     '> SHIELD ACTIVE ▌'),
        ('sectionHead() 11', 'Courier',    7,  TEXT,     'SPECTRUM ANALYSIS'),
        ('stripLabel() 9', 'Courier',      6,  TEXT_DIM, 'LAT:7ms  LVL:-28dB  ROUTE:SPK  TECH:5'),
    ]

    meta_w = 30*mm
    for meta, font, size, color, sample in type_rows:
        text_at(c, MARGIN, cy, meta, size=5.5, color=TEXT_DIM)
        text_at(c, MARGIN + meta_w, cy, sample, font=font, size=size, color=color)
        # Separator
        c.setStrokeColor(colors.HexColor('#1A1A1A'))
        c.setLineWidth(0.3)
        c.line(MARGIN, cy - 1.5*mm, W/2 - 10*mm, cy - 1.5*mm)
        cy -= max(size * 0.5, 5) * mm * 0.38 + 4*mm

    cy -= 3*mm

    # ── Components ────────────────────────────────────────────────────────────
    # Right column
    rx = W/2 + 5*mm
    comp_cy = H - 22*mm

    section_header(c, rx, comp_cy, 'COMPONENTS')
    comp_cy -= 5*mm

    # Buttons
    btn_configs = [
        ('[ GET STARTED ]',     BORDER,  TEXT,    'DEFAULT'),
        ('[ START NEXUS ]',     PHOSPHOR, PHOSPHOR,'ACTIVE'),
        ('[ SKIP FOR NOW ]',    TEXT_DIM, TEXT_DIM,'MUTED'),
    ]
    bx = rx
    for lbl, stroke, tc, name in btn_configs:
        bw = 38*mm; bh = 5.5*mm
        rect_filled_stroke(c, bx, comp_cy - bh, bw, bh, BG, stroke, lw=0.6)
        text_at(c, bx + bw/2, comp_cy - bh + 1.5*mm, lbl, size=5.5, color=tc, align='center')
        text_at(c, bx + bw/2, comp_cy + 1*mm, name, size=4.5, color=TEXT_DIM, align='center')
        bx += bw + 3*mm
    comp_cy -= 5.5*mm + 7*mm

    # Progress bars
    pb_examples = [
        (progress_bar_text(0.82, 10), PHOSPHOR, 'PIXELTEXTPROGRESSBAR 82%'),
        (progress_bar_text(0.45, 10), TEXT,      'PIXELTEXTPROGRESSBAR 45%'),
    ]
    bx = rx
    for pb_txt, col, lbl in pb_examples:
        pw = 45*mm; ph = 5*mm
        rect_filled_stroke(c, bx, comp_cy - ph, pw, ph, BG, col, lw=0.5)
        text_at(c, bx + 2*mm, comp_cy - ph + 1.4*mm, pb_txt, size=5.5, color=col)
        text_at(c, bx + pw/2, comp_cy + 1*mm, lbl, size=4.5, color=TEXT_DIM, align='center')
        bx += pw + 5*mm
    comp_cy -= ph + 7*mm

    # Session banner
    bw2 = 80*mm; bh2 = 6*mm
    rect_filled_stroke(c, rx, comp_cy - bh2, bw2, bh2, BG, PHOSPHOR, lw=0.5)
    text_at(c, rx + 2*mm, comp_cy - bh2 + 1.8*mm, '[OK] ', size=6, color=PHOSPHOR, font='Courier-Bold')
    text_at(c, rx + 9*mm, comp_cy - bh2 + 1.8*mm, 'SESSION COMPLETE · 82% AI BLOCKED', size=5.5, color=TEXT)
    text_at(c, rx + bw2/2, comp_cy + 1*mm, 'SESSION RESULT BANNER', size=4.5, color=TEXT_DIM, align='center')
    comp_cy -= bh2 + 7*mm

    # Shield boxes
    sb_size = 12*mm
    for bx_off, title, border_c, fill_c, label, label_c, sub in [
        (0,      'SHIELD · OFFLINE', BORDER,  BG,              '[NEXUS]', TEXT_DIM, None),
        (sb_size + 6*mm, 'SHIELD · ACTIVE',  PHOSPHOR, colors.HexColor('#020E00'), '[NEXUS]', PHOSPHOR, '_/\\/\\/_'),
    ]:
        bx3 = rx + bx_off
        rect_filled_stroke(c, bx3, comp_cy - sb_size, sb_size, sb_size, fill_c, border_c, lw=0.7)
        text_at(c, bx3 + sb_size/2, comp_cy - 5*mm, label, size=5.5, color=label_c, align='center', font='Courier-Bold')
        if sub:
            text_at(c, bx3 + sb_size/2, comp_cy - 8*mm, sub, size=5, color=label_c, align='center')
        text_at(c, bx3 + sb_size/2, comp_cy + 1*mm, title, size=4.5, color=TEXT_DIM, align='center')

    comp_cy -= sb_size + 7*mm

    # Tier toggles
    tw = 16*mm; th = 9*mm
    for bx_off, lbl, sub, enabled in [
        (0, 'STD ●', 'TIER 1', True),
        (tw + 4*mm, 'AI ○', 'TIER 2', False),
    ]:
        bx4 = rx + bx_off
        bc2 = PHOSPHOR if enabled else BORDER
        tc2 = PHOSPHOR if enabled else TEXT
        rect_filled_stroke(c, bx4, comp_cy - th, tw, th, BG, bc2, lw=0.5)
        text_at(c, bx4 + tw/2, comp_cy - th + 4*mm, lbl, size=7, color=tc2, align='center', font='Courier-Bold')
        text_at(c, bx4 + tw/2, comp_cy - th + 1.5*mm, sub, size=4.5, color=TEXT_DIM, align='center')
        status = 'ENABLED' if enabled else 'DISABLED'
        text_at(c, bx4 + tw/2, comp_cy + 1*mm, f'TIER BTN · {status}', size=4.5, color=TEXT_DIM, align='center')

    # Dither pattern swatch
    dith_x = rx + 2*(tw + 4*mm); dith_w = 18*mm; dith_h = 9*mm
    rect_filled_stroke(c, dith_x, comp_cy - dith_h, dith_w, dith_h, BG, PHOSPHOR, lw=0.5)
    # Fill with Bayer pattern simulation
    bayer = [[0,8,2,10],[12,4,14,6],[3,11,1,9],[15,7,13,5]]
    density = 0.15
    for dy in range(int(dith_h * 2.83)):   # 1mm ≈ 2.83 pts
        for dx in range(int(dith_w * 2.83)):
            thresh = bayer[dy % 4][dx % 4] / 16.0
            if density > thresh:
                c.setFillColor(PHOSPHOR)
                c.rect(dith_x + dx/2.83, comp_cy - dith_h + dy/2.83, 0.35, 0.35, fill=1, stroke=0)
    text_at(c, dith_x + dith_w/2, comp_cy + 1*mm, 'BAYER 4×4 DITHER', size=4.5, color=TEXT_DIM, align='center')

    # Footer
    text_at(c, W/2, 7*mm, 'PROJECT NEXUS · PIXEL TERMINAL AESTHETIC · MARCH 2026',
            size=5.5, color=TEXT_DIM, align='center')


def section_header(c, x, y, label):
    text_at(c, x, y, label, size=7, color=TEXT_DIM)
    c.setStrokeColor(colors.HexColor('#2A2A2A'))
    c.setLineWidth(0.4)
    tw = pdfmetrics.stringWidth(label, 'Courier', 7)
    c.line(x + tw + 4, y + 2, x + 120*mm, y + 2)


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    c = canvas.Canvas(OUT_PATH, pagesize=landscape(A4))
    c.setTitle('Project Nexus — Design Preview')
    c.setAuthor('Project Nexus')

    # Page 1 — Screens
    draw_page1(c)
    c.showPage()

    # Page 2 — Tokens / Type / Components
    draw_page2(c)
    c.showPage()

    c.save()
    size = os.path.getsize(OUT_PATH)
    print(f'✅  PDF saved: {OUT_PATH}  ({size:,} bytes, {size/1024:.1f} KB)')


if __name__ == '__main__':
    main()
