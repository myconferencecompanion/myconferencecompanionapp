"""Generate the NSE '26 app Infrastructure & Running Cost estimate (Naira).

Run:  python tools/make_cost_pdf.py
Output: NSE26-App-Infrastructure-Costs.pdf (project root)
"""
import os
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader, simpleSplit
from reportlab.lib.colors import Color
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "NSE26-App-Infrastructure-Costs.pdf")

W, H = A4  # portrait 595 x 842 pt


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
WHITE     = hexc("FFFFFF")
ROW_ALT   = hexc("F6F8FB")
LINE      = hexc("E1E5EC")

# ---- fonts: register Arial (has the Naira glyph) ----------------------------
FONT, FONTB = "Helvetica", "Helvetica-Bold"
NAIRA = "NGN "  # fallback prefix
for reg, bold, base in [
    (r"C:\Windows\Fonts\arial.ttf", r"C:\Windows\Fonts\arialbd.ttf", "Arial"),
]:
    try:
        pdfmetrics.registerFont(TTFont(base, reg))
        pdfmetrics.registerFont(TTFont(base + "-Bold", bold))
        FONT, FONTB = base, base + "-Bold"
        NAIRA = "\u20a6"  # ₦
        break
    except Exception:
        pass

CREST = os.path.join(ROOT, "assets", "images", "nse_crest.png")
APP_ICON = os.path.join(ROOT, "assets", "images", "app_icon.png")

RATE = 1600  # NGN per USD

c = canvas.Canvas(OUT, pagesize=(W, H))


def money(n):
    return f"{NAIRA}{n:,.0f}"


def text(x, y, s, font=FONT, size=10, color=INK, align="l"):
    c.setFont(font, size)
    c.setFillColor(color)
    if align == "l":
        c.drawString(x, y, s)
    elif align == "c":
        c.drawCentredString(x, y, s)
    else:
        c.drawRightString(x, y, s)


def paragraph(x, y, s, width, font=FONT, size=9.5, color=INK_SOFT, leading=None):
    leading = leading or size * 1.5
    for ln in simpleSplit(s, font, size, width):
        c.setFont(font, size)
        c.setFillColor(color)
        c.drawString(x, y, ln)
        y -= leading
    return y


MARGIN = 46
CW = W - 2 * MARGIN


def header_band():
    c.setFillColor(NAVY_DARK)
    c.rect(0, H - 132, W, 132, fill=1, stroke=0)
    c.setFillColor(GOLD)
    c.rect(0, H - 132, W, 4, fill=1, stroke=0)
    # crest
    try:
        img = ImageReader(CREST)
        iw, ih = img.getSize()
        s = 78 / ih
        c.drawImage(img, MARGIN, H - 118, iw * s, 78, preserveAspectRatio=True, mask="auto")
    except Exception:
        pass
    text(MARGIN + 92, H - 52, "NSE INTERNATIONAL CONFERENCE 2026", FONTB, 11, GOLD)
    text(MARGIN + 92, H - 76, "Conference App", FONTB, 20, WHITE)
    text(MARGIN + 92, H - 98, "Infrastructure & Running Cost Estimate", FONT, 13, NAVY_SOFT)
    text(W - MARGIN, H - 98, "All amounts in Nigerian Naira (" + NAIRA + ")", FONT, 9.5, NAVY_SOFT, align="r")


def section_title(y, label):
    c.setFillColor(GOLD)
    c.roundRect(MARGIN, y - 2, 5, 16, 2, fill=1, stroke=0)
    text(MARGIN + 14, y, label, FONTB, 12.5, NAVY_DARK)
    return y - 10


def table(y, rows, subtotal_label=None, subtotal_val=None, col2_header="Basis"):
    """rows: list of (item, basis, amount|None, note_bool). amount None => text in basis."""
    x0 = MARGIN
    row_h = 26
    c1 = x0 + 12          # item
    c2 = x0 + CW * 0.52   # basis
    cA = x0 + CW - 12     # amount (right)
    # header
    c.setFillColor(NAVY)
    c.roundRect(x0, y - 22, CW, 22, 6, fill=1, stroke=0)
    text(c1, y - 15, "Item", FONTB, 9.5, WHITE)
    text(c2, y - 15, col2_header, FONTB, 9.5, WHITE)
    text(cA, y - 15, "Amount", FONTB, 9.5, WHITE, align="r")
    y -= 22
    for i, (item, basis, amount) in enumerate(rows):
        if i % 2 == 1:
            c.setFillColor(ROW_ALT)
            c.rect(x0, y - row_h, CW, row_h, fill=1, stroke=0)
        text(c1, y - 17, item, FONT, 9.5, INK)
        text(c2, y - 17, basis, FONT, 8.8, INK_SOFT)
        if amount is None:
            text(cA, y - 17, "Included", FONT, 9.5, GREEN, align="r")
        elif amount == 0:
            text(cA, y - 17, "Free tier", FONT, 9.5, GREEN, align="r")
        else:
            text(cA, y - 17, money(amount), FONTB, 9.5, INK, align="r")
        y -= row_h
    c.setStrokeColor(LINE)
    c.setLineWidth(1)
    c.line(x0, y, x0 + CW, y)
    if subtotal_label:
        c.setFillColor(NAVY_SOFT)
        c.roundRect(x0, y - 26, CW, 24, 6, fill=1, stroke=0)
        text(c1, y - 19, subtotal_label, FONTB, 10, NAVY_DARK)
        text(cA, y - 19, money(subtotal_val), FONTB, 11, NAVY_DARK, align="r")
        y -= 28
    return y


def footer(page):
    c.setStrokeColor(LINE)
    c.line(MARGIN, 38, W - MARGIN, 38)
    text(MARGIN, 26, "NSE '26 Conference App  ·  Infrastructure cost estimate  ·  Prepared July 2026",
         FONT, 8, INK_SOFT)
    text(W - MARGIN, 26, f"Page {page}", FONT, 8, INK_SOFT, align="r")


# ============================== PAGE 1 =======================================
c.setFillColor(PAPER)
c.rect(0, 0, W, H, fill=1, stroke=0)
header_band()

y = H - 160

# Assumptions box
c.setFillColor(WHITE)
c.roundRect(MARGIN, y - 92, CW, 92, 10, fill=1, stroke=0)
c.setFillColor(GOLD_SOFT)
c.roundRect(MARGIN, y - 92, 5, 92, 2, fill=1, stroke=0)
text(MARGIN + 16, y - 20, "Basis of estimate", FONTB, 11, NAVY_DARK)
assume = ("Figures below are planning estimates for hosting and running the conference app for its "
          "first year, covering the build-up period and the conference itself. Based on ~2,000 delegates "
          "on Android and iOS. Currency converted at " + NAIRA + f"{RATE:,.0f} = US$1. "
          "Cloud services are billed monthly and scale with usage; free tiers are noted where applicable.")
paragraph(MARGIN + 16, y - 40, assume, CW - 32, FONT, 9.3, INK_SOFT, leading=14.5)
y -= 112

# Section A — one-time setup
y = section_title(y, "A.  One-time setup costs (Year 1)")
setup_rows = [
    ("Google Play Developer account", "One-time registration (US$25)", 40_000),
    ("Apple Developer Program", "Annual, required for iOS App Store (US$99)", 158_400),
    ("Domain name (.com.ng)", "Registration, first year", 25_000),
    ("Backend setup & security hardening", "Database, auth & role configuration", 150_000),
]
setup_total = sum(r[2] for r in setup_rows)
y = table(y - 6, setup_rows, "Setup subtotal", setup_total)
y -= 12

# Section B — monthly running
y = section_title(y, "B.  Monthly running costs (while live)")
run_rows = [
    ("Supabase Pro (backend)", "Managed backend platform (US$25/mo)", 40_000),
    ("Usage & bandwidth buffer", "Headroom for peak conference traffic", 40_000),
    ("In-app AI assistant", "Chatbot API usage (event month)", 64_000),
    ("Push notifications", "Firebase Cloud Messaging", 0),
    ("Transactional email", "Sign-in & notification emails", 0),
]
run_total = sum(r[2] for r in run_rows)
y = table(y - 6, run_rows, "Monthly subtotal", run_total)

footer(1)
c.showPage()

# ============================== PAGE 2 =======================================
c.setFillColor(PAPER)
c.rect(0, 0, W, H, fill=1, stroke=0)
header_band()
y = H - 160

# Section C — optional
y = section_title(y, "C.  Optional / variable services")
opt_rows = [
    ("SMS OTP verification", "Phone sign-in \u2014 per 10,000 messages", 45_000),
    ("Additional AI usage", "If chatbot traffic is very high", 30_000),
    ("Apple Developer renewal", "From Year 2 onward (annual)", 158_400),
    ("Domain renewal", "Annual, from Year 2", 25_000),
]
y = table(y - 6, opt_rows, None, None)
y -= 16

# Section D — Year 1 total (highlighted)
y = section_title(y, "D.  Estimated Year-1 total")
months = 6
running = run_total * months
contingency = round((setup_total + running) * 0.10)
grand = setup_total + running + contingency

box_h = 150
c.setFillColor(WHITE)
c.roundRect(MARGIN, y - box_h, CW, box_h, 12, fill=1, stroke=0)

def line_item(yy, label, val, bold=False, big=False):
    text(MARGIN + 20, yy, label, FONTB if bold else FONT, 12 if big else 10.5,
         NAVY_DARK if bold else INK)
    text(W - MARGIN - 20, yy, money(val), FONTB if bold else FONT, 15 if big else 11,
         NAVY_DARK if bold else INK, align="r")

yy = y - 30
line_item(yy, "One-time setup", setup_total)
yy -= 26
line_item(yy, f"Running cost ({months} active months x {money(run_total)})", running)
yy -= 26
line_item(yy, "Contingency (10%)", contingency)
yy -= 10
c.setStrokeColor(LINE)
c.line(MARGIN + 20, yy, W - MARGIN - 20, yy)
yy -= 26
c.setFillColor(GOLD_SOFT)
c.roundRect(MARGIN + 12, yy - 8, CW - 24, 30, 8, fill=1, stroke=0)
line_item(yy, "Estimated Year-1 total", grand, bold=True, big=True)
y -= box_h + 16

# steady state note
c.setFillColor(GREEN_SOFT)
c.roundRect(MARGIN, y - 58, CW, 58, 10, fill=1, stroke=0)
text(MARGIN + 16, y - 22, "Steady-state (off-peak) running cost", FONTB, 10.5, GREEN)
paragraph(MARGIN + 16, y - 40,
          "Outside the conference period the backend can be scaled down to roughly "
          + money(40_000) + " per month, since the AI assistant and traffic buffer are only needed "
          "during the live event.", CW - 32, FONT, 9.3, INK_SOFT, leading=14)
y -= 74

# Notes
y = section_title(y, "Notes")
notes = [
    "These are running / infrastructure costs only and do not include app design or software development.",
    "Cloud services (Supabase, AI, SMS) are pay-as-you-go and may be higher or lower than shown, depending on real delegate numbers and usage.",
    "Apple's fee applies only if the app is published to the iOS App Store; an Android-only rollout removes " + money(158_400) + " from Year 1.",
    "Exchange rate (" + NAIRA + f"{RATE:,.0f}/US$1) as at July 2026; USD-billed items will move with the rate.",
]
for n in notes:
    c.setFillColor(GOLD)
    c.circle(MARGIN + 4, y - 4, 2, fill=1, stroke=0)
    y = paragraph(MARGIN + 14, y - 1, n, CW - 20, FONT, 9.2, INK_SOFT, leading=13.5) - 4

footer(2)
c.showPage()
c.save()
print("WROTE", OUT)
