#!/usr/bin/env python3
"""TC Blackletter fontuna eksik Türkçe glifleri ve noktalama işaretlerini ekler.

NEDEN: oyunun başlık fontunda ğ Ğ İ Ş — … · YOK. Godot bu karakterleri sistemdeki başka bir
fonttan tamamlıyordu; Türkçe başlıklarda ("Savaş", "Faksiyonunu Seç — …") harfler farklı bir
yazı tipiyle karışık görünüyordu.

Yöntem: glifler fontun KENDİ parçalarından kurulur, böylece kalem kalınlığı ve karakter tutar:
  İ  = I + i'nin noktası (i'nin x-yüksekliği üstündeki konturu)
  ğ  = g + kısa işaret (breve) — fontun kalem kalınlığında çizilmiş hilal
  Ğ  = G + aynı kısa işaret (büyük harf yüksekliğinde)
  Ş  = S + çengel (cedilla) — ç'deki çengelin ölçülerinde çizilmiş kanca
  —  = – (en dash) yatayda ~1.9x
  …  = üç nokta
  ·  = nokta, x-yüksekliğinin ortasına kaldırılmış

Kullanım:  python3 tools/patch_blackletter_tr.py
Çıktı:     assets/fonts/TCBlackletter-TR.ttf  (tema üreticisi bu dosyayı kullanır)
"""
from pathlib import Path

from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/fonts/TCBlackletterRegular-BuxT2Ctr.woff2"
OUT = ROOT / "assets/fonts/TCBlackletter-TR.ttf"


def contours_of(font, name):
    """Glifi kontur listesi olarak döndürür (her kontur: pen komutları listesi)."""
    rec = DecomposingRecordingPen(font.getGlyphSet())
    font.getGlyphSet()[name].draw(rec)
    out, cur = [], []
    for op, args in rec.value:
        cur.append((op, args))
        if op in ("closePath", "endPath"):
            out.append(cur)
            cur = []
    return out


def contour_bbox(c):
    pts = [p for _, args in c for p in args]
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def replay(contours, pen, transform=(1, 0, 0, 1, 0, 0)):
    tp = TransformPen(pen, transform)
    for c in contours:
        for op, args in c:
            getattr(tp, op)(*args)


def draw_breve(pen, cx, base_y, width, thick):
    """Kalın, uçları sivrilen hilal (U biçimli kısa işaret)."""
    w = width / 2
    # dış eğri (aşağı sarkan), iç eğri geri
    pen.moveTo((cx - w, base_y + thick * 1.6))
    pen.qCurveTo((cx - w * 0.55, base_y - thick * 0.2), (cx, base_y - thick * 0.25))
    pen.qCurveTo((cx + w * 0.55, base_y - thick * 0.2), (cx + w, base_y + thick * 1.6))
    pen.lineTo((cx + w - thick * 0.55, base_y + thick * 1.6))
    pen.qCurveTo((cx + w * 0.45, base_y + thick * 0.75), (cx, base_y + thick * 0.75))
    pen.qCurveTo((cx - w * 0.45, base_y + thick * 0.75), (cx - w + thick * 0.55, base_y + thick * 1.6))
    pen.closePath()


def draw_cedilla(pen, x, top_y, size):
    """Tabandan aşağı inen küçük kanca."""
    s = size
    pen.moveTo((x - s * 0.12, top_y))
    pen.lineTo((x + s * 0.14, top_y))
    pen.lineTo((x + s * 0.10, top_y - s * 0.28))
    pen.qCurveTo((x + s * 0.62, top_y - s * 0.34), (x + s * 0.55, top_y - s * 0.68))
    pen.qCurveTo((x + s * 0.40, top_y - s * 1.0), (x - s * 0.38, top_y - s * 0.98))
    pen.lineTo((x - s * 0.34, top_y - s * 0.84))
    pen.qCurveTo((x + s * 0.24, top_y - s * 0.84), (x + s * 0.28, top_y - s * 0.62))
    pen.qCurveTo((x + s * 0.30, top_y - s * 0.44), (x - s * 0.16, top_y - s * 0.44))
    pen.closePath()


def add_glyph(font, name, codepoint, build, advance):
    pen = TTGlyphPen(font.getGlyphSet())
    build(pen)
    glyph = pen.glyph()
    glyph.recalcBounds(font["glyf"])
    font["glyf"][name] = glyph
    font["hmtx"][name] = (advance, glyph.xMin if glyph.numberOfContours else 0)
    if name not in font.getGlyphOrder():
        font.setGlyphOrder(font.getGlyphOrder() + [name])
    for table in font["cmap"].tables:
        if table.isUnicode():
            table.cmap[codepoint] = name


def main():
    font = TTFont(SRC)
    font.flavor = None
    hmtx = font["hmtx"]
    glyf = font["glyf"]
    adv = lambda n: hmtx[n][0]

    # i'nin noktası: x-yüksekliğinin (dotlessi tavanı) üstündeki kontur(lar)
    x_height = glyf["dotlessi"].yMax
    i_dots = [c for c in contours_of(font, "i") if contour_bbox(c)[1] > x_height]
    dot_bb = [contour_bbox(c) for c in i_dots]
    dot_cx = (min(b[0] for b in dot_bb) + max(b[2] for b in dot_bb)) / 2
    dot_h = max(b[3] for b in dot_bb) - min(b[1] for b in dot_bb)
    cap = glyf["I"].yMax
    stem = 110  # kalem kalınlığı (endash yüksekliği ~107)

    def build_Idot(pen):
        replay(contours_of(font, "I"), pen)
        ic = (glyf["I"].xMin + glyf["I"].xMax) / 2
        lift = cap + 40 - min(b[1] for b in dot_bb)
        replay(i_dots, pen, (1, 0, 0, 1, ic - dot_cx, lift))
    add_glyph(font, "Idotaccent", 0x130, build_Idot, adv("I"))

    def build_gbreve(pen):
        replay(contours_of(font, "g"), pen)
        cx = (glyf["g"].xMin + glyf["g"].xMax) / 2
        draw_breve(pen, cx, x_height + 70, 380, stem * 0.9)
    add_glyph(font, "gbreve", 0x11F, build_gbreve, adv("g"))

    def build_Gbreve(pen):
        replay(contours_of(font, "G"), pen)
        cx = (glyf["G"].xMin + glyf["G"].xMax) / 2
        draw_breve(pen, cx, cap + 80, 440, stem)
    add_glyph(font, "Gbreve", 0x11E, build_Gbreve, adv("G"))

    def build_Scedilla(pen):
        replay(contours_of(font, "S"), pen)
        cx = (glyf["S"].xMin + glyf["S"].xMax) / 2
        draw_cedilla(pen, cx, 10, 360)
    add_glyph(font, "Scedilla", 0x15E, build_Scedilla, adv("S"))

    def build_emdash(pen):
        e = glyf["endash"]
        replay(contours_of(font, "endash"), pen, (1.9, 0, 0, 1, -e.xMin * 0.9, 0))
    add_glyph(font, "emdash", 0x2014, build_emdash, int(adv("endash") * 1.9))

    def build_ellipsis(pen):
        for k in range(3):
            replay(contours_of(font, "period"), pen, (1, 0, 0, 1, k * adv("period") * 0.82, 0))
    add_glyph(font, "ellipsis", 0x2026, build_ellipsis, int(adv("period") * 2.8))

    def build_middot(pen):
        replay(contours_of(font, "period"), pen, (1, 0, 0, 1, 0, x_height * 0.42))
    add_glyph(font, "periodcentered", 0xB7, build_middot, adv("period"))

    font["maxp"].numGlyphs = len(font.getGlyphOrder())
    font.save(OUT)
    print("yazıldı:", OUT, "| nokta yüksekliği", dot_h)


if __name__ == "__main__":
    main()
