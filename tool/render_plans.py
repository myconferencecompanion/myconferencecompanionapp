"""Render the ICC floor-plan PDFs into high-resolution PNGs for offline use.

Run: python tool/render_plans.py
"""
import os
import fitz  # PyMuPDF

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "misc")
OUT = os.path.join(ROOT, "assets", "venue", "plans")
os.makedirs(OUT, exist_ok=True)

# source pdf -> output slug
MAP = {
    "ICC UPDATED(2) PENULTIMATE-ICC LAYOUT.pdf": "icc_layout",
    "ICC UPDATED(2) PENULTIMATE-FLLOR PLANpdf.pdf": "ground_floor",
    "ICC UPDATED(2) PENULTIMATE-FIRST FLOOR.pdf": "first_floor",
}

DPI = 220

for fname, slug in MAP.items():
    path = os.path.join(SRC, fname)
    if not os.path.exists(path):
        print("MISSING:", path)
        continue
    doc = fitz.open(path)
    print(f"{fname}: {doc.page_count} page(s)")
    for i, page in enumerate(doc):
        mat = fitz.Matrix(DPI / 72, DPI / 72)
        pix = page.get_pixmap(matrix=mat, alpha=False)
        suffix = "" if doc.page_count == 1 else f"_{i+1}"
        out_path = os.path.join(OUT, f"{slug}{suffix}.png")
        pix.save(out_path)
        print(f"  -> {out_path}  {pix.width}x{pix.height}")
    doc.close()

print("Done.")
