"""Generate a branded PDF presentation for the NSE '26 conference app.

Run:  python tools/make_presentation.py
Output: NSE26-App-Presentation.pdf (project root)
"""
import os
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader, simpleSplit
from reportlab.lib.colors import Color

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "NSE26-App-Presentation.pdf")

# 16:9 slide canvas (points)
W, H = 960.0, 540.0

# ---- Brand palette (from lib/theme/app_theme.dart) --------------------------
def hexc(h, a=1.0):
    h = h.lstrip("#")
    return Color(int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, a)

INK       = hexc("18201A")
INK_SOFT  = hexc("566057")
NAVY      = hexc("123E73")
NAVY_DARK = hexc("0C2A4F")
NAVY_SOFT = hexc("E6EEF7")
GREEN     = hexc("123F2A")
GREEN_SOFT= hexc("DFEEE4")
GOLD      = hexc("FFA000")
GOLD_SOFT = hexc("FFF4DC")
PAPER     = hexc("F3F4F6")
SURFACE   = hexc("FFFFFF")
WHITE     = hexc("FFFFFF")
RED       = hexc("C93D2E")
RED_SOFT  = hexc("FCECEA")

APP_ICON = os.path.join(ROOT, "assets", "images", "app_icon.png")
CREST    = os.path.join(ROOT, "assets", "images", "nse_crest.png")

FONT   = "Helvetica"
FONTB  = "Helvetica-Bold"

c = canvas.Canvas(OUT, pagesize=(W, H))


# ---- primitives -------------------------------------------------------------
def bg(color=PAPER):
    c.setFillColor(color)
    c.rect(0, 0, W, H, fill=1, stroke=0)


def soft_shadow_rect(x, y, w, h, r, fill):
    # fake soft shadow: a slightly larger, very light rect behind
    c.setFillColor(Color(0.11, 0.16, 0.27, 0.06))
    c.roundRect(x - 1, y - 5, w + 2, h + 2, r, fill=1, stroke=0)
    c.setFillColor(fill)
    c.roundRect(x, y, w, h, r, fill=1, stroke=0)


def text(x, y, s, font=FONT, size=12, color=INK, align="l"):
    c.setFont(font, size)
    c.setFillColor(color)
    if align == "l":
        c.drawString(x, y, s)
    elif align == "c":
        c.drawCentredString(x, y, s)
    else:
        c.drawRightString(x, y, s)


def paragraph(x, y, s, width, font=FONT, size=12, color=INK_SOFT, leading=None):
    leading = leading or size * 1.45
    lines = simpleSplit(s, font, size, width)
    c.setFont(font, size)
    c.setFillColor(color)
    for ln in lines:
        c.drawString(x, y, ln)
        y -= leading
    return y


def kicker_title(kicker, title, sub=None):
    # left accent bar
    c.setFillColor(GOLD)
    c.roundRect(64, H - 96, 6, 46, 3, fill=1, stroke=0)
    text(84, H - 66, kicker.upper(), FONTB, 12, GOLD)
    text(84, H - 92, title, FONTB, 30, NAVY_DARK)
    if sub:
        text(84, H - 114, sub, FONT, 13, INK_SOFT)


def footer(page, total):
    c.setStrokeColor(hexc("D8DCE3"))
    c.setLineWidth(1)
    c.line(64, 40, W - 64, 40)
    text(64, 26, "NSE '26  ·  Official Conference App", FONT, 9, INK_SOFT)
    text(W - 64, 26, f"{page} / {total}", FONT, 9, INK_SOFT, align="r")


def feature_tile(x, y, w, h, title, body, accent, accent_soft, glyph=""):
    soft_shadow_rect(x, y, w, h, 16, SURFACE)
    # icon disc
    d = 34
    c.setFillColor(accent_soft)
    c.roundRect(x + 18, y + h - 18 - d, d, d, 10, fill=1, stroke=0)
    c.setFillColor(accent)
    c.circle(x + 18 + d / 2, y + h - 18 - d / 2, 5, fill=1, stroke=0)
    text(x + 18 + d + 12, y + h - 30, title, FONTB, 14, INK)
    paragraph(x + 18, y + h - 52, body, w - 36, FONT, 10.5, INK_SOFT, leading=15)


def draw_image_contain(path, x, y, w, h):
    try:
        img = ImageReader(path)
        iw, ih = img.getSize()
        scale = min(w / iw, h / ih)
        dw, dh = iw * scale, ih * scale
        c.drawImage(img, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh,
                    preserveAspectRatio=True, mask="auto")
    except Exception:
        pass


# =============================================================================
# SLIDE 1 — COVER
# =============================================================================
def slide_cover():
    # navy gradient-ish background (bands)
    bg(NAVY_DARK)
    c.setFillColor(NAVY)
    c.rect(0, 0, W, H * 0.62, fill=1, stroke=0)
    c.setFillColor(NAVY_DARK)
    c.rect(0, 0, W, H * 0.30, fill=1, stroke=0)
    # gold accent line
    c.setFillColor(GOLD)
    c.rect(0, H - 6, W, 6, fill=1, stroke=0)

    # right-side crest watermark (drawn first so text sits above it)
    draw_image_contain(CREST, W - 290, 150, 215, 270)

    # app icon in a rounded white card
    card = 138
    cx = 84
    cy = H - 66 - card
    c.setFillColor(WHITE)
    c.roundRect(cx, cy, card, card, 32, fill=1, stroke=0)
    draw_image_contain(APP_ICON, cx + 13, cy + 13, card - 26, card - 26)

    text(84, cy - 42, "OFFICIAL CONFERENCE COMPANION APP", FONTB, 13, GOLD)
    text(82, cy - 92, "NSE International", FONTB, 48, WHITE)
    text(82, cy - 142, "Conference 2026", FONTB, 48, WHITE)

    text(84, 150, "Engineering Innovation for Enhanced Security", FONT, 14.5, NAVY_SOFT)
    text(84, 128, "and Sustainable National Development", FONT, 14.5, NAVY_SOFT)

    # detail chips
    def chip(x, label, value):
        c.setFillColor(Color(1, 1, 1, 0.10))
        c.roundRect(x, 52, 224, 48, 12, fill=1, stroke=0)
        text(x + 16, 82, label.upper(), FONTB, 8.5, GOLD)
        text(x + 16, 64, value, FONTB, 12.5, WHITE)
    chip(84, "Dates", "30 Nov \u2013 4 Dec 2026")
    chip(324, "Venue", "ICC, Maiduguri")
    chip(564, "Platform", "Android \u00b7 iOS")


# =============================================================================
# SLIDE 2 — OVERVIEW
# =============================================================================
def slide_overview(page, total):
    bg()
    kicker_title("Overview", "One app for the entire conference")
    y = paragraph(
        84, H - 150,
        "NSE '26 puts everything a delegate needs in one place \u2014 the programme, speakers, "
        "accommodation, the venue map, concierge services and live updates \u2014 while giving the "
        "organising committee a built-in admin console to run the event in real time. It is designed "
        "to work reliably in Maiduguri, with key content bundled for offline use.",
        W - 168, FONT, 13.5, INK_SOFT, leading=21)

    cols = [
        ("For delegates", "A premium, bank-app-grade experience: plan your days, find rooms, "
         "book services and stay informed.", NAVY, NAVY_SOFT),
        ("For organisers", "Role-based admin tools to manage sessions, hotels, menus, "
         "announcements and live service queues.", GREEN, GREEN_SOFT),
        ("Built to last", "Offline-ready assets, secure sign-in and a consistent design system "
         "across every screen.", GOLD, GOLD_SOFT),
    ]
    tw = (W - 168 - 2 * 24) / 3
    for i, (t, b, ac, acs) in enumerate(cols):
        x = 84 + i * (tw + 24)
        feature_tile(x, 90, tw, 150, t, b, ac, acs)
    footer(page, total)


# =============================================================================
# SLIDE 3 — AT A GLANCE (stats)
# =============================================================================
def slide_stats(page, total):
    bg()
    kicker_title("At a glance", "Two products in a single app")
    stats = [
        ("2-in-1", "Delegate app +\nadmin console", NAVY, NAVY_SOFT),
        ("30+", "Fully designed\nscreens & flows", GREEN, GREEN_SOFT),
        ("20+", "Hotels ranked,\nwith photo galleries", GOLD, GOLD_SOFT),
        ("Indoor", "Venue wayfinding\nwith \u201cyou are here\u201d", NAVY, NAVY_SOFT),
        ("Offline", "Maps & plans\nbundled in-app", GREEN, GREEN_SOFT),
        ("Live", "Real-time queues\n& announcements", GOLD, GOLD_SOFT),
    ]
    cols, rows = 3, 2
    gap = 24
    tw = (W - 168 - (cols - 1) * gap) / cols
    th = 130
    top = H - 170
    for i, (big, lbl, ac, acs) in enumerate(stats):
        r, cc = divmod(i, cols)
        x = 84 + cc * (tw + gap)
        y = top - r * (th + gap) - th
        soft_shadow_rect(x, y, tw, th, 16, SURFACE)
        c.setFillColor(acs)
        c.roundRect(x, y, 8, th, 4, fill=1, stroke=0)
        text(x + 26, y + th - 46, big, FONTB, 34, ac)
        yy = y + th - 74
        for line in lbl.split("\n"):
            text(x + 26, yy, line, FONT, 12, INK_SOFT)
            yy -= 17
    footer(page, total)


# =============================================================================
# Generic feature slide (2x2 tiles)
# =============================================================================
def feature_slide(page, total, kicker, title, tiles):
    bg()
    kicker_title(kicker, title)
    gap = 22
    tw = (W - 168 - gap) / 2
    th = 120
    top = H - 168
    for i, (t, b, ac, acs) in enumerate(tiles):
        r, cc = divmod(i, 2)
        x = 84 + cc * (tw + gap)
        y = top - r * (th + gap) - th
        feature_tile(x, y, tw, th, t, b, ac, acs)
    footer(page, total)


# =============================================================================
# SLIDE — Design & brand
# =============================================================================
def slide_design(page, total):
    bg()
    kicker_title("Design & quality", "A deliberate, premium design system")
    y = paragraph(
        84, H - 150,
        "Every screen shares one visual language: soft, borderless cards floating on a light canvas, "
        "generous spacing, a single accent-driven navigation, and consistent typography \u2014 the same "
        "attention to detail you expect from a modern banking app.",
        W - 168, FONT, 13, INK_SOFT, leading=20)

    text(84, y - 6, "OFFICIAL PALETTE", FONTB, 11, NAVY_DARK)
    swatches = [
        ("Navy", NAVY, "#123E73"),
        ("Navy dark", NAVY_DARK, "#0C2A4F"),
        ("Gold", GOLD, "#FFA000"),
        ("Green", GREEN, "#123F2A"),
        ("Paper", PAPER, "#F3F4F6"),
    ]
    sx = 84
    sy = y - 120
    sw = 150
    for name, col, hx in swatches:
        soft_shadow_rect(sx, sy, sw, 92, 14, SURFACE)
        c.setFillColor(col)
        c.roundRect(sx + 12, sy + 34, sw - 24, 44, 10, fill=1, stroke=1 if name == "Paper" else 0)
        if name == "Paper":
            c.setStrokeColor(hexc("D8DCE3"))
        text(sx + 14, sy + 20, name, FONTB, 11, INK)
        text(sx + 14, sy + 8, hx, FONT, 8.5, INK_SOFT)
        sx += sw + 16
    footer(page, total)


# =============================================================================
# SLIDE — Technology
# =============================================================================
def slide_tech(page, total):
    bg()
    kicker_title("Technology", "Built for reliability in the field")
    tiles = [
        ("Flutter (Android & iOS)", "One codebase, native performance, a single consistent UI on every device.", NAVY, NAVY_SOFT),
        ("Supabase backend", "Secure authentication, live data and real-time service queues.", GREEN, GREEN_SOFT),
        ("Offline-first assets", "Hotel galleries, venue plans and the 3D tour are bundled inside the app.", GOLD, GOLD_SOFT),
        ("Role-based access", "Admin tools are gated by role: program, logistics, kitchen, comms, front desk.", NAVY, NAVY_SOFT),
    ]
    gap = 22
    tw = (W - 168 - gap) / 2
    th = 116
    top = H - 168
    for i, (t, b, ac, acs) in enumerate(tiles):
        r, cc = divmod(i, 2)
        x = 84 + cc * (tw + gap)
        yy = top - r * (th + gap) - th
        feature_tile(x, yy, tw, th, t, b, ac, acs)
    footer(page, total)


# =============================================================================
# SLIDE — Closing
# =============================================================================
def slide_closing():
    bg(NAVY_DARK)
    c.setFillColor(NAVY)
    c.rect(0, 0, W, H * 0.45, fill=1, stroke=0)
    c.setFillColor(GOLD)
    c.rect(0, H - 6, W, 6, fill=1, stroke=0)
    draw_image_contain(APP_ICON, W / 2 - 55, H - 190, 110, 110)
    text(W / 2, H - 250, "Ready for delegates.", FONTB, 34, WHITE, align="c")
    text(W / 2, H - 288, "Ready for the committee.", FONTB, 34, WHITE, align="c")
    text(W / 2, 150, "NSE International Conference 2026", FONTB, 15, GOLD, align="c")
    text(W / 2, 126, "International Conference Centre · Maiduguri, Borno State", FONT, 12, NAVY_SOFT, align="c")
    text(W / 2, 92, "30 November – 4 December 2026", FONT, 12, NAVY_SOFT, align="c")


# =============================================================================
# BUILD
# =============================================================================
TOTAL = 11

slide_cover(); c.showPage()
slide_overview(2, TOTAL); c.showPage()
slide_stats(3, TOTAL); c.showPage()

feature_slide(4, TOTAL, "Delegate experience", "Plan your conference", [
    ("Home dashboard", "A calm, glanceable hub: up-next session, latest announcement, quick actions and a search bar.", NAVY, NAVY_SOFT),
    ("Schedule & sessions", "Filter the full programme by day and track; open any session for details, room and speakers.", GREEN, GREEN_SOFT),
    ("Speakers", "Browse keynote and technical speakers with bios, roles and their sessions.", GOLD, GOLD_SOFT),
    ("My Agenda", "Delegates bookmark sessions to build a personal, day-by-day schedule.", NAVY, NAVY_SOFT),
]); c.showPage()

feature_slide(5, TOTAL, "Delegate experience", "Find your way around", [
    ("Indoor venue map", "Interactive floor plans with turn-by-turn wayfinding and a QR \u201cyou are here\u201d locator.", NAVY, NAVY_SOFT),
    ("Hotels", "20+ partner hotels ranked by quality, each with photo galleries, distance and booking info.", GOLD, GOLD_SOFT),
    ("Nearby places", "Pharmacies, ATMs, food and fuel around the venue, with distances.", GREEN, GREEN_SOFT),
    ("Maiduguri guide", "A local guide with directions, tips and points of interest for visiting delegates.", NAVY, NAVY_SOFT),
]); c.showPage()

feature_slide(6, TOTAL, "Delegate experience", "Get things done \u2014 Concierge", [
    ("Call an usher", "Request on-the-spot assistance from the nearest usher, tracked live to resolution.", NAVY, NAVY_SOFT),
    ("Order food", "Browse the menu and place meal orders that flow straight to the kitchen queue.", GOLD, GOLD_SOFT),
    ("Send an errand", "Delegate small tasks to the support team and follow their status in real time.", GREEN, GREEN_SOFT),
    ("Transport", "Each delegate is assigned a dedicated bus for the conference, simplifying headcounts.", NAVY, NAVY_SOFT),
]); c.showPage()

feature_slide(7, TOTAL, "Delegate experience", "Stay connected & informed", [
    ("Networking", "Topic rooms and direct messages so delegates can connect during the event.", NAVY, NAVY_SOFT),
    ("Announcements", "Priority updates from the committee, surfaced first on the home screen.", GOLD, GOLD_SOFT),
    ("Emergency & safety", "One-tap access to emergency, medical and security contacts.", RED, RED_SOFT),
    ("Assistant & FAQ", "A built-in chatbot and FAQ answer common questions instantly.", GREEN, GREEN_SOFT),
]); c.showPage()

feature_slide(8, TOTAL, "For organisers", "A complete admin console", [
    ("Manage content", "Create and edit sessions, speakers, hotels, menus, announcements and emergency contacts.", NAVY, NAVY_SOFT),
    ("Live service queues", "Kitchen, usher and errand teams work real-time queues with status controls.", GREEN, GREEN_SOFT),
    ("Transport control", "Configure buses, routes and boarding policy for the whole fleet.", GOLD, GOLD_SOFT),
    ("Roles & delegates", "Role-based access and a searchable delegate directory for the committee.", NAVY, NAVY_SOFT),
]); c.showPage()

slide_design(9, TOTAL); c.showPage()
slide_tech(10, TOTAL); c.showPage()
slide_closing(); c.showPage()

c.save()
print("WROTE", OUT)
