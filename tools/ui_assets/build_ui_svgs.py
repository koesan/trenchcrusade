#!/usr/bin/env python3
"""Iron Requiem arayüz varlık seti — TEK KAYNAK üretici (SVG).

Görsel dil: karanlık ilahi gotik — katedral taşı ve kutsal emanet (reliquary).
  * zemin: is/kurum siyahı, hafif dikey degrade (düz renk değil)
  * çizgi: eskimiş varak altın; çift çizgi (dış belirgin, iç ince)
  * köşe: pah kırılmış taş köşe + küçük patté haçı (Trench Crusade logosundaki haç)
  * vurgu: tek renk — vitray kan kırmızısı; üzerine gelince mum ışığı ılıklığı
  * birim kartı: sivri gotik kemerli NİŞ (birimler katedral nişindeki azizler gibi)

Tüm ölçüler ve renkler bu dosyadadır; SVG'ler buradan üretilir, elle DÜZENLENMEZ.
Godot SVG'yi doğrudan içe aktarır (ThorVG) — filtre (blur) desteklenmez, bu yüzden parıltılar
radyal degrade ile yapılır.

Kullanım:  python3 tools/ui_assets/build_ui_svgs.py
Çıktı:     assets/ui/frames/*.svg, assets/ui/ornaments/*.svg, assets/ui/icons/*.svg
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "ui"

# ── PALET (tema üreticisi gothic_theme_builder.gd ile AYNI değerler) ─────────────
INK = "#0b0908"
SLATE_TOP = "#1e1916"
SLATE_BOT = "#100d0b"
GILT = "#b0915a"
GILT_DIM = "#6b5636"
GILT_LIT = "#e2c68c"
BONE = "#e8dfcc"
BLOOD = "#7c1a13"
BLOOD_DEEP = "#3a0b08"
BLOOD_LIT = "#c03a2c"
CANDLE = "#f3c97c"


def svg(w, h, body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">\n<defs>{defs}</defs>\n{body}\n</svg>\n')


def vgrad(gid, top, bottom, top_op=1.0, bottom_op=1.0):
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{top}" stop-opacity="{top_op}"/>'
            f'<stop offset="1" stop-color="{bottom}" stop-opacity="{bottom_op}"/></linearGradient>')


def rglow(gid, color, opacity):
    return (f'<radialGradient id="{gid}" cx="0.5" cy="0.5" r="0.6">'
            f'<stop offset="0" stop-color="{color}" stop-opacity="{opacity}"/>'
            f'<stop offset="1" stop-color="{color}" stop-opacity="0"/></radialGradient>')


def chamfer(x, y, w, h, c):
    """Pahlı dikdörtgen yol (köşeler c kadar kesik)."""
    return (f"M{x + c} {y} H{x + w - c} L{x + w} {y + c} V{y + h - c} L{x + w - c} {y + h} "
            f"H{x + c} L{x} {y + h - c} V{y + c} Z")


def cross_pattee(cx, cy, r, color, opacity=1.0):
    """Küçük patté haçı (kolları uca doğru genişleyen) — köşe süsü."""
    a, b = r * 0.22, r
    pts = [(-a, -b * 0.18), (-b * 0.42, -b), (b * 0.42, -b), (a, -b * 0.18),
           (b, -b * 0.42), (b, b * 0.42), (a, b * 0.18), (b * 0.42, b),
           (-b * 0.42, b), (-a, b * 0.18), (-b, b * 0.42), (-b, -b * 0.42)]
    d = "M" + " L".join(f"{cx + px:.2f} {cy + py:.2f}" for px, py in pts) + " Z"
    return f'<path d="{d}" fill="{color}" fill-opacity="{opacity}"/>'


# ── ÇERÇEVELER ───────────────────────────────────────────────────────────────────

def panel(name, rule, inner_op, ornament, fill_top=SLATE_TOP, fill_bot=SLATE_BOT, fill_op=0.96,
          size=128, cut=14):
    """9-dilim panel: pahlı köşe, dış altın çizgi, iç ince çizgi, köşelerde haç."""
    s = size
    defs = vgrad("fill", fill_top, fill_bot, fill_op, fill_op)
    body = [
        f'<path d="{chamfer(1, 1, s - 2, s - 2, cut)}" fill="url(#fill)" stroke="{INK}" stroke-width="2"/>',
        f'<path d="{chamfer(2.5, 2.5, s - 5, s - 5, cut - 1)}" fill="none" stroke="{rule}" stroke-width="1.6"/>',
        f'<path d="{chamfer(8, 8, s - 16, s - 16, cut - 4)}" fill="none" stroke="{BONE}" '
        f'stroke-opacity="{inner_op}" stroke-width="1"/>',
    ]
    if ornament:
        o = cut * 0.62
        for cx, cy in [(o + 1, o + 1), (s - o - 1, o + 1), (o + 1, s - o - 1), (s - o - 1, s - o - 1)]:
            body.append(cross_pattee(cx, cy, 4.2, ornament))
    write("frames", name, svg(s, s, "\n".join(body), defs))


def button(name, fill_top, fill_bot, rule, highlight_op=0.10, glow=None, size=64, cut=7,
           rule_w=1.2, inner=None):
    """Buton (9-dilim): pahlı, dikey degrade, üst ince ışık çizgisi, isteğe bağlı iç parıltı."""
    s = size
    defs = vgrad("fill", fill_top, fill_bot)
    body = [f'<path d="{chamfer(1, 1, s - 2, s - 2, cut)}" fill="url(#fill)" stroke="{INK}" stroke-width="2"/>']
    if glow:
        defs += rglow("glow", glow[0], glow[1])
        body.append(f'<path d="{chamfer(3, 3, s - 6, s - 6, cut - 1)}" fill="url(#glow)"/>')
    body.append(f'<path d="{chamfer(2.5, 2.5, s - 5, s - 5, cut - 1)}" fill="none" stroke="{rule}" '
                f'stroke-width="{rule_w}"/>')
    if inner:
        body.append(f'<path d="{chamfer(5, 5, s - 10, s - 10, cut - 3)}" fill="none" stroke="{inner[0]}" '
                    f'stroke-opacity="{inner[1]}" stroke-width="1.6"/>')
    body.append(f'<path d="M{cut + 2} 5 H{s - cut - 2}" stroke="{BONE}" stroke-opacity="{highlight_op}" '
                f'stroke-width="1"/>')
    write("frames", name, svg(s, s, "\n".join(body), defs))


def niche(name, rule, glow=None, fill_top="#231d19", fill_bot=SLATE_BOT, inner_op=0.18, w=120, h=170):
    """Birim kartı: sivri gotik kemerli niş. Kart genişliği sabit olduğu için yalnız DİKEY
    esner (tema: üst pay = kemer yüksekliği)."""
    # Kart MANTIKSAL boyutunda üretilir (9-dilimde kenar boyutu = doku pikseli). Tema payları:
    # sol/sağ 10, üst 40 (kemer), alt 10 — kart genişliği sabit 120 olduğundan kemer esnemez.
    arch_h = 34
    m = 2

    def arch_path(x0, y0, x1, y1, apex):
        """Sivri (lancet) kemer: iki yay, her birinin merkezi KARŞI taraftaki omuz hizasında
        (yarıçap ≈ açıklığın %90'ı) — gotik pencerenin klasik biçimi."""
        mx = (x0 + x1) / 2
        r = (x1 - x0) * 0.9
        return (f"M{x0} {y1} V{y0 + apex} A{r:.1f} {r:.1f} 0 0 1 {mx} {y0} "
                f"A{r:.1f} {r:.1f} 0 0 1 {x1} {y0 + apex} V{y1} Z")

    defs = vgrad("fill", fill_top, fill_bot)
    body = [f'<path d="{arch_path(m, m, w - m, h - m, arch_h)}" fill="url(#fill)" stroke="{INK}" stroke-width="2"/>']
    if glow:
        defs += (f'<radialGradient id="glow" cx="0.5" cy="0.38" r="0.7">'
                 f'<stop offset="0" stop-color="{glow[0]}" stop-opacity="{glow[1]}"/>'
                 f'<stop offset="1" stop-color="{glow[0]}" stop-opacity="0"/></radialGradient>')
        body.append(f'<path d="{arch_path(m + 2, m + 2, w - m - 2, h - m - 2, arch_h - 1)}" fill="url(#glow)"/>')
    body.append(f'<path d="{arch_path(m + 1.5, m + 1.5, w - m - 1.5, h - m - 1.5, arch_h - 1)}" fill="none" '
                f'stroke="{rule}" stroke-width="1.6"/>')
    body.append(f'<path d="{arch_path(m + 6, m + 7, w - m - 6, h - m - 6, arch_h - 4)}" fill="none" '
                f'stroke="{BONE}" stroke-opacity="{inner_op}" stroke-width="1"/>')
    body.append(cross_pattee(w / 2, m + 14, 3.6, rule))
    write("frames", name, svg(w, h, "\n".join(body), defs))


def banner(name, rule, glow=None, fill_top="#241d19", fill_bot="#130f0d", inner_op=0.18, w=160, h=212):
    """Faksiyon sancağı: üstte asma çubuğu, altta kırlangıç kuyruğu. Genişlik sabit (160) —
    tema payları: yan 12, üst 18, alt 40 (kuyruk); yalnız dikey esner."""
    tail = 30

    def path(x0, y0, x1, y1, t):
        mx = (x0 + x1) / 2
        return f"M{x0} {y0} H{x1} V{y1} L{mx} {y1 - t} L{x0} {y1} Z"

    defs = vgrad("fill", fill_top, fill_bot)
    body = [
        # asma çubuğu (pirinç)
        f'<rect x="2" y="4" width="{w - 4}" height="6" rx="3" fill="{GILT_DIM}"/>',
        f'<circle cx="5" cy="7" r="4" fill="{rule}"/><circle cx="{w - 5}" cy="7" r="4" fill="{rule}"/>',
        f'<path d="{path(8, 8, w - 8, h - 2, tail)}" fill="url(#fill)" stroke="{INK}" stroke-width="2"/>',
    ]
    if glow:
        defs += rglow("glow", glow[0], glow[1])
        body.append(f'<path d="{path(10, 10, w - 10, h - 4, tail)}" fill="url(#glow)"/>')
    body.append(f'<path d="{path(9.5, 9, w - 9.5, h - 3.5, tail)}" fill="none" stroke="{rule}" stroke-width="1.6"/>')
    body.append(f'<path d="{path(15, 14, w - 15, h - 12, tail - 6)}" fill="none" stroke="{BONE}" '
                f'stroke-opacity="{inner_op}" stroke-width="1"/>')
    write("frames", name, svg(w, h, "\n".join(body), defs))


# ── SÜSLER ───────────────────────────────────────────────────────────────────────

def checkboxes():
    """Onay kutusu (18x18): boş = bronz çerçeveli koyu kare, işaretli = içinde kemik onay."""
    box = (f'<rect x="1.5" y="1.5" width="15" height="15" rx="2" fill="#0e0b0a" '
           f'stroke="{GILT}" stroke-width="1.4"/>')
    write("frames", "check_off", svg(18, 18, box))
    tick = f'<path d="M4.5 9.5 L7.8 12.6 L13.8 5.6" fill="none" stroke="{GILT_LIT}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>'
    write("frames", "check_on", svg(18, 18, box + tick))


def ornaments():
    # Dikenli tel ayraç — yatay tile (128x16)
    wire = [
        f'<g fill="none" stroke="{GILT_DIM}" stroke-width="1.3" stroke-linecap="round">',
        '<path d="M0 8 C16 4.5 16 4.5 32 8 S48 11.5 64 8 S80 4.5 96 8 S112 11.5 128 8"/>',
        '<path d="M0 8 C16 11.5 16 11.5 32 8 S48 4.5 64 8 S80 11.5 96 8 S112 4.5 128 8"/>',
        f'<path d="M28 2 L36 14 M36 2 L28 14 M92 2 L100 14 M100 2 L92 14" stroke="{GILT}"/>',
        '</g>',
    ]
    write("ornaments", "divider_wire", svg(128, 16, "\n".join(wire)))
    # Başlık süsü: ince çizgi → baklavalar → ortada haç → simetrik (256x24)
    flo = [
        f'<path d="M8 12 H104" stroke="{GILT_DIM}" stroke-width="1"/>',
        f'<path d="M152 12 H248" stroke="{GILT_DIM}" stroke-width="1"/>',
        f'<path d="M104 12 L110 8 L116 12 L110 16 Z M140 12 L146 8 L152 12 L146 16 Z" fill="{GILT}"/>',
        f'<circle cx="8" cy="12" r="1.6" fill="{GILT_DIM}"/><circle cx="248" cy="12" r="1.6" fill="{GILT_DIM}"/>',
        cross_pattee(128, 12, 8.5, BLOOD_LIT),
    ]
    write("ornaments", "title_flourish", svg(256, 24, "\n".join(flo)))


def write(sub, name, content):
    d = OUT / sub
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{name}.svg").write_text(content, encoding="utf-8")


def frames():
    panel("panel", GILT, 0.16, GILT)
    panel("panel_emphasis", GILT_LIT, 0.26, BLOOD_LIT, fill_top="#231c18")
    panel("panel_inset", GILT_DIM, 0.0, None, fill_top="#120e0c", fill_bot="#0c0a09", fill_op=0.9, size=64, cut=6)
    panel("tooltip", GILT, 0.12, None, fill_top="#1a1512", fill_bot="#0e0b0a", fill_op=0.97, size=64, cut=6)

    button("btn_normal", "#2a231e", "#15110e", GILT_DIM)
    button("btn_hover", "#352b24", "#1a1411", GILT_LIT, highlight_op=0.16, glow=(CANDLE, 0.16))
    button("btn_pressed", "#130f0d", "#1c1612", GILT, highlight_op=0.04)
    button("btn_selected", "#2a1612", "#160c0a", GILT_LIT, glow=(BLOOD_LIT, 0.28), inner=(BLOOD_LIT, 0.9))
    button("btn_disabled", "#1a1714", "#121010", "#3e362d", highlight_op=0.03)
    button("btn_primary", "#6e1712", BLOOD_DEEP, GILT, highlight_op=0.14)
    button("btn_primary_hover", "#8c1e17", "#4a0e0a", GILT_LIT, highlight_op=0.2, glow=(CANDLE, 0.18))

    banner("banner_normal", GILT_DIM)
    banner("banner_hover", GILT_LIT, glow=(CANDLE, 0.14))
    banner("banner_selected", GILT_LIT, glow=(BLOOD_LIT, 0.3))

    niche("niche_normal", GILT_DIM)
    niche("niche_hover", GILT_LIT, glow=(CANDLE, 0.12))
    niche("niche_selected", GILT_LIT, glow=(BLOOD_LIT, 0.35))
    niche("niche_spent", "#3e362d", fill_top="#151210", inner_op=0.06)


# ── İKONLAR (64x64, dolu siluet, BEYAZ — renk temadan/modulate'tan gelir) ─────────
# Tasarım ızgarası: 6 px kenar boşluğu, ana çizgi kalınlığı ~5 px, köşeler hafif sivri (gotik).
W_ = "#ffffff"
ICONS = {
    # EYLEMLER
    "march": f"""<g fill="{W_}"><path d="M15 32c0-11 4-22 9.5-22S33 19 33 30s-3.4 12-8.5 12S15 39 15 32z"/>
<path d="M16 45h15v5c0 4.5-3.2 7-7.5 7S16 54.5 16 50z"/>
<path d="M33 24c0-11 4-20 9.5-20S51 13 51 24s-3.4 11-8.5 11S33 31 33 24z" opacity=".55"/>
<path d="M34 38h15v4.5c0 4.5-3.2 7-7.5 7S34 47 34 42.5z" opacity=".55"/></g>""",
    "charge": f"""<g fill="{W_}"><path d="M52 6 L58 6 L58 12 L30 40 L24 34 Z"/><path d="M20 30 L34 44 L30 48 L16 34 Z"/>
<path d="M22 42 L10 54 L14 58 L26 46 Z"/><circle cx="10" cy="56" r="4"/>
<path d="M6 16 H22 V20 H6Z M4 26 H16 V30 H4Z M10 6 H28 V10 H10Z" opacity=".6"/></g>""",
    "dash": f"""<g fill="{W_}"><path d="M8 12 L30 32 L8 52 V41 L18 32 L8 23Z"/><path d="M30 12 L52 32 L30 52 V41 L40 32 L30 23Z"/>
<rect x="53" y="12" width="5" height="40"/></g>""",
    "retreat": f"""<g fill="none" stroke="{W_}" stroke-width="6" stroke-linecap="square"><path d="M50 52 V30 C50 20 44 16 34 16 H16"/></g>
<path fill="{W_}" d="M4 16 L20 4 V28 Z"/>""",
    "shoot": f"""<g fill="none" stroke="{W_}" stroke-width="4.5"><circle cx="32" cy="32" r="17"/></g>
<g fill="{W_}"><rect x="29.5" y="4" width="5" height="17"/><rect x="29.5" y="43" width="5" height="17"/>
<rect x="4" y="29.5" width="17" height="5"/><rect x="43" y="29.5" width="17" height="5"/><circle cx="32" cy="32" r="3.5"/></g>""",
    "melee": f"""<g fill="{W_}"><path d="M29 8 L32 2 L35 8 V40 H29Z"/><path d="M18 40 H46 L42 46 H22Z"/>
<rect x="29.5" y="46" width="5" height="10"/><path d="M32 55 L37 60 L32 64 L27 60Z"/></g>""",
    "ability": f"""<path fill="{W_}" fill-rule="evenodd" d="M32 2 L36 24 L58 14 L42 30 L62 32 L42 34 L58 50 L36 40 L32 62 L28 40 L6 50 L22 34 L2 32 L22 30 L6 14 L28 24Z M32 26 A6 6 0 1 0 32.01 26Z"/>""",
    "end_turn": f"""<g fill="{W_}"><rect x="12" y="4" width="40" height="5"/><rect x="12" y="55" width="40" height="5"/>
<path d="M16 9 H48 C48 22 36 26 34 32 C36 38 48 42 48 55 H16 C16 42 28 38 30 32 C28 26 16 22 16 9Z M22 13 C23 21 30 24 32 28 C34 24 41 21 42 13Z" fill-rule="evenodd"/>
<path d="M24 51 C25 45 31 42 32 40 C33 42 39 45 40 51Z"/></g>""",
    "claim": f"""<path fill="{W_}" fill-rule="evenodd" d="M32 2 L52 22 V58 H12 V22Z M29 26 V32 H23 V37 H29 V49 H35 V37 H41 V32 H35 V26Z"/><rect x="6" y="56" width="52" height="5" fill="{W_}"/>""",
    "curse": f"""<path fill="{W_}" fill-rule="evenodd" d="M32 4 L62 58 H2Z M32 26 C22 26 15 34 13 40 C15 46 22 52 32 52 C42 52 49 46 51 40 C49 34 42 26 32 26Z M32 33 A7 7 0 1 0 32.01 33Z"/>""",
    "teleport": f"""<g fill="none" stroke="{W_}" stroke-width="5" stroke-linecap="round"><path d="M32 32 m0 -4 a4 4 0 1 1 -4 4 a8 8 0 0 1 8 -8 a12 12 0 0 1 12 12 a16 16 0 0 1 -16 16 a20 20 0 0 1 -20 -20 a24 24 0 0 1 24 -24"/></g>""",
    "rally": f"""<g fill="{W_}"><path d="M8 26 H20 L44 12 V52 L20 38 H8Z"/><path d="M50 22 C56 26 56 38 50 42 L47 38 C51 35 51 29 47 26Z"/><rect x="14" y="40" width="7" height="14"/></g>""",
    "log": f"""<g fill="{W_}"><path d="M56 4 C40 8 26 20 18 38 L14 48 L18 50 L24 42 C38 36 50 24 56 4Z"/>
<path d="M18 50 L10 60 L8 58 L15 47Z"/><rect x="6" y="58" width="26" height="3"/>
<path d="M30 30 L44 16" stroke="#000" stroke-opacity=".35" stroke-width="2" fill="none"/></g>""",
    # SİSTEM
    "menu": f"""<g fill="{W_}"><rect x="10" y="14" width="44" height="5"/><rect x="10" y="29.5" width="44" height="5"/><rect x="10" y="45" width="44" height="5"/></g>""",
    "codex": f"""<path fill="{W_}" fill-rule="evenodd" d="M4 14 C14 10 24 11 30 16 V56 C24 51 14 50 4 54Z M60 14 C50 10 40 11 34 16 V56 C40 51 50 50 60 54Z M44 22 h5 v6 h6 v5 h-6 v12 h-5 v-12 h-6 v-5 h6z"/>""",
    "objectives": f"""<g fill="{W_}"><rect x="12" y="4" width="5" height="56"/><path d="M17 8 H54 L46 20 L54 32 H17Z"/></g>""",
    "resources": f"""<g fill="none" stroke="{W_}" stroke-width="4.5"><circle cx="32" cy="32" r="25"/><circle cx="32" cy="32" r="18" stroke-width="1.5"/></g>
<path fill="{W_}" d="M29 18 H35 V29 H46 V35 H35 V46 H29 V35 H18 V29 H29Z"/>""",
    "settings": f"""<g fill="{W_}"><path d="M28 4 H36 L37 12 L43 15 L50 10 L56 16 L51 23 L54 29 L60 30 V36 L54 37 L51 43 L56 50 L50 56 L43 51 L37 54 L36 60 H28 L27 54 L21 51 L14 56 L8 50 L13 43 L10 37 L4 36 V30 L10 29 L13 23 L8 16 L14 10 L21 15 L27 12Z M32 22 A10 10 0 1 0 32.01 22Z" fill-rule="evenodd"/></g>""",
    "close": f"""<g fill="{W_}"><path d="M10 14 L14 10 L32 28 L50 10 L54 14 L36 32 L54 50 L50 54 L32 36 L14 54 L10 50 L28 32Z"/></g>""",
    "back": f"""<g fill="{W_}"><path d="M28 10 L6 32 L28 54 V38 H58 V26 H28Z"/></g>""",
    "roster": f"""<g fill="{W_}"><circle cx="32" cy="18" r="9"/><path d="M16 50 C16 38 23 31 32 31 S48 38 48 50Z"/>
<g opacity=".6"><circle cx="13" cy="25" r="7"/><path d="M1 54 C1 44 6 38 13 38 S25 44 25 54Z"/><circle cx="51" cy="25" r="7"/><path d="M39 54 C39 44 44 38 51 38 S63 44 63 54Z"/></g></g>""",
    "keywords": f"""<g fill="{W_}"><path d="M12 6 H46 C50 6 52 9 52 12 V52 C52 56 54 58 58 58 H18 C14 58 12 55 12 52Z M20 18 H44 V22 H20Z M20 28 H44 V32 H20Z M20 38 H36 V42 H20Z" fill-rule="evenodd"/>
<path d="M6 10 C6 6 12 6 12 10 V16 H6Z"/></g>""",
    "info": f"""<g fill="{W_}"><circle cx="32" cy="14" r="5"/><path d="M26 24 H36 V50 H42 V56 H22 V50 H28 V30 H26Z"/></g>""",
    "warning": f"""<path fill="{W_}" fill-rule="evenodd" d="M32 4 L62 58 H2Z M29 22 V40 H35 V22Z M29 45 V51 H35 V45Z"/>""",
    "check": f"""<path fill="{W_}" d="M6 34 L14 26 L26 38 L52 12 L60 20 L26 54Z"/>""",
    # İŞARETLER / DURUM
    "blood": f"""<path fill="{W_}" d="M32 3 C41 18 52 29 52 41 a20 20 0 0 1 -40 0 C12 29 23 18 32 3Z"/>""",
    "blessing": f"""<g fill="none" stroke="{W_}" stroke-width="3.5"><ellipse cx="32" cy="14" rx="15" ry="5"/></g>
<path fill="{W_}" d="M29 22 H35 V33 H46 V39 H35 V60 H29 V39 H18 V33 H29Z"/>""",
    "infection": f"""<g fill="none" stroke="{W_}" stroke-width="3"><circle cx="32" cy="32" r="26"/></g>
<g fill="{W_}"><circle cx="32" cy="19" r="7"/><circle cx="20" cy="40" r="7"/><circle cx="44" cy="40" r="7"/><circle cx="32" cy="34" r="3"/></g>""",
    "down": f"""<g fill="{W_}"><path d="M26 4 H38 V28 H50 L32 46 L14 28 H26Z"/><rect x="6" y="52" width="52" height="6"/></g>""",
    "shaken": f"""<path fill="{W_}" fill-rule="evenodd" d="M32 4 L56 12 V30 C56 46 44 56 32 60 C20 56 8 46 8 30 V12Z M33 10 L28 26 L36 30 L27 50 L30 31 L22 27Z"/>""",
    "armour": f"""<path fill="{W_}" d="M32 4 L56 12 V30 C56 46 44 56 32 60 C20 56 8 46 8 30 V12Z"/>""",
    "out_of_action": f"""<g fill="{W_}" fill-rule="evenodd"><path d="M32 6 C46 6 54 16 54 28 C54 36 50 40 46 42 V52 H18 V42 C14 40 10 36 10 28 C10 16 18 6 32 6Z M18 26 A7 7 0 1 0 32 26 A7 7 0 1 0 18 26Z M32 26 A7 7 0 1 0 46 26 A7 7 0 1 0 32 26Z M29 38 L32 33 L35 38Z"/>
<path d="M22 54 h5 v6 h-5z M30 54 h5 v6 h-5z M38 54 h5 v6 h-5z"/></g>""",
    "dice": f"""<rect x="8" y="8" width="48" height="48" rx="8" fill="none" stroke="{W_}" stroke-width="4.5"/>
<g fill="{W_}"><circle cx="21" cy="21" r="4.5"/><circle cx="32" cy="32" r="4.5"/><circle cx="43" cy="43" r="4.5"/><circle cx="43" cy="21" r="4.5"/><circle cx="21" cy="43" r="4.5"/></g>""",
    "glory": f"""<path fill="{W_}" d="M32 4 L39 23 L60 24 L43 37 L49 58 L32 46 L15 58 L21 37 L4 24 L25 23Z"/>""",
    "ducat": f"""<g fill="none" stroke="{W_}" stroke-width="4"><circle cx="32" cy="32" r="24"/></g>
<path fill="{W_}" d="M30 16 H34 V30 H48 V34 H34 V48 H30 V34 H16 V30 H30Z"/>""",
}


# Varak altın kabartma: dikey altın degrade gövde + 1.6 px aşağı kaydırılmış koyu gölge kopyası.
# (Düz beyaz siluetler mobil oyun gibi "çocuksu" duruyordu — kullanıcı geri bildirimi.)
GILT_GRAD = (
    '<linearGradient id="gilt" x1="0" y1="0" x2="0" y2="1">'
    '<stop offset="0" stop-color="#f4e2b4"/><stop offset="0.45" stop-color="#d2ae6c"/>'
    '<stop offset="1" stop-color="#8c6c3a"/></linearGradient>'
)


def icons():
    for name, body in ICONS.items():
        # 1) düz beyaz sürüm: tema/modulate ile RENKLENDİRİLEN yerler için (işaretler, durum)
        write("icons/flat", name, svg(64, 64, body))
        # 2) kabartma altın sürüm: butonlardaki eylem/sistem ikonları
        shadow = body.replace(W_, INK)
        gilt = body.replace(W_, "url(#gilt)")
        emb = (f'<g transform="translate(0 1.6)" opacity="0.85">{shadow}</g>\n'
               f'<g>{gilt}</g>')
        write("icons", name, svg(64, 64, emb, GILT_GRAD))

if __name__ == "__main__":
    frames()
    checkboxes()
    ornaments()
    icons()
    print("SVG'ler yazıldı:", OUT)
