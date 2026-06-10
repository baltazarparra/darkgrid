#!/usr/bin/env python3
"""Gera TODOS os assets de marca do caipora a partir da protagonista aprovada.

Fonte visual (lei): docs/CONCEITO-protagonista.md — a marca é o recorte da
cabeça da Caipora: juba laranja serrilhada envolvendo o capuz, vazio preto,
dois olhos brancos puros e chifres pretos rompendo a silhueta. O wordmark
"CAIPORA" deriva da mesma matéria: letras chunky na rampa da juba, serrilhadas
como a capa, com o "O" virando o rosto-vazio. Sangue mínimo como acento.

Pipeline premium do gen_caipora.py: desenho supersampled (SS=8) → downsample
BOX → threshold de alpha → snap de paleta fechada → outline 1px. Upscale final
sempre NEAREST inteiro. Determinístico (seeds fixas).

Saídas:
- assets/sprites/brand_mark.png + brand_mark_blink.png   (64x64, alpha)
- assets/sprites/logo_title.png + logo_title_blink.png   (256x96, alpha)
- assets/sprites/boot_splash.png                         (1280x720, fundo noite)
- icon.png                                               (512x512, fundo noite)
- assets/icons/icon_144.png / icon_180.png / icon_512.png (PWA, fundo noite)

Nunca editar os PNGs gerados à mão: toda mudança passa por aqui.
"""

from __future__ import annotations

import base64
import io
import math
import os
import random
import re

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SPRITES = os.path.join(ROOT, "assets", "sprites")
ICONS = os.path.join(ROOT, "assets", "icons")

REF = 64          # espaço de referência do rosto-marca
SS = 8            # supersample

TRANSPARENT = (0, 0, 0, 0)
NIGHT = (13, 17, 23)          # #0d1117 — mesmo bg do boot_splash/bg_color
ORANGE_DK = (139, 42, 0)      # #8b2a00 — juba (sombra)
ORANGE = (255, 69, 0)         # #ff4500 — juba (base vibrante)
BLACK = (0, 0, 0)             # vazio / chifres
EYE = (255, 255, 255)         # olhos brancos PUROS
BLOOD = (139, 0, 0)           # #8b0000 — acento hostil, mínimo
BLOOD_DK = (84, 0, 0)
OUTLINE = (26, 18, 10)        # #1a120a — contorno 1px da silhueta

MARK_PALETTE = [ORANGE_DK, ORANGE, BLACK, EYE]

MARK_SEED = 2606              # prancha aprovada em 2026-06
WORDMARK_SEED = 7331


# ─── rosto-marca ───────────────────────────────────────────────────────────

def _sp(v: float) -> float:
    return v * SS


def _poly(d: ImageDraw.ImageDraw, pts: list[tuple[float, float]], col: tuple[int, int, int]) -> None:
    d.polygon([(_sp(x), _sp(y)) for x, y in pts], fill=col)


def _ellipse(d: ImageDraw.ImageDraw, cx: float, cy: float, rx: float, ry: float,
             col: tuple[int, int, int]) -> None:
    d.ellipse([_sp(cx - rx), _sp(cy - ry), _sp(cx + rx), _sp(cy + ry)], fill=col)


def _limb(d: ImageDraw.ImageDraw, a: tuple[float, float], b: tuple[float, float],
          wa: float, wb: float, col: tuple[int, int, int]) -> None:
    x0, y0 = a
    x1, y1 = b
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy) or 1.0
    nx, ny = -dy / length, dx / length
    _poly(d, [
        (x0 + nx * wa / 2, y0 + ny * wa / 2),
        (x1 + nx * wb / 2, y1 + ny * wb / 2),
        (x1 - nx * wb / 2, y1 - ny * wb / 2),
        (x0 - nx * wa / 2, y0 - ny * wa / 2),
    ], col)
    _ellipse(d, x0, y0, wa / 2, wa / 2, col)
    _ellipse(d, x1, y1, wb / 2, wb / 2, col)


def _nearest(color: tuple[int, int, int], palette: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    best, best_d = palette[0], 10 ** 12
    for cand in palette:
        dist = sum((color[i] - cand[i]) ** 2 for i in range(3))
        if dist < best_d:
            best, best_d = cand, dist
    return best


def _snap(img: Image.Image, palette: list[tuple[int, int, int]]) -> None:
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 112:
                px[x, y] = TRANSPARENT
            else:
                px[x, y] = _nearest((r, g, b), palette) + (255,)


def _outline(img: Image.Image) -> None:
    px = img.load()
    w, h = img.size
    edge: list[tuple[int, int]] = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] == 0:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + ox, y + oy
                if not (0 <= nx < w and 0 <= ny < h) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = OUTLINE + (255,)


def _draw_mark(d: ImageDraw.ImageDraw) -> None:
    """Recorte da cabeça: juba serrilhada, vazio e chifres rompendo.

    Os olhos NÃO entram aqui: são pintados pós-snap (pixels brancos puros,
    sem halo de downsample — trava do conceito)."""
    rng = random.Random(MARK_SEED)
    cx, cy = 32.0, 35.0
    base_r = 19.5

    # juba: massa serrilhada irregular — eriçada no topo, assentando na base
    pts: list[tuple[float, float]] = []
    n = 30
    for i in range(n):
        ang = -math.pi / 2 + i * (2 * math.pi / n) + rng.uniform(-0.06, 0.06)
        spike = 6.5 if i % 2 == 0 else 1.0
        up = -math.sin(ang)
        spike *= 1.0 + 0.45 * up
        r = base_r + spike + rng.uniform(-1.2, 1.2)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang) * 0.94))
    _poly(d, pts, ORANGE)

    # sombra interna (2 tons por material, como o cloak do gen_caipora)
    _poly(d, [(cx - 1, cy + 10), (cx + 16, cy + 5), (cx + 14, cy + 17), (cx + 2, cy + 20)], ORANGE_DK)
    _poly(d, [(cx - 17, cy + 7), (cx - 10, cy + 13), (cx - 15, cy + 16)], ORANGE_DK)

    # vazio do rosto emoldurado pela juba (a juba domina a leitura)
    _ellipse(d, cx, cy + 1.5, 11.0, 9.2, BLACK)

    # chifres finos e assimétricos: as pontas SEMPRE ultrapassam a juba
    _limb(d, (cx - 7.5, cy - 10), (cx - 14, cy - 24), 3.8, 2.0, BLACK)
    _limb(d, (cx - 14, cy - 24), (cx - 11, cy - 31), 1.8, 0.9, BLACK)
    _limb(d, (cx + 7.5, cy - 10), (cx + 12, cy - 20.5), 3.8, 2.0, BLACK)
    _limb(d, (cx + 12, cy - 20.5), (cx + 9.5, cy - 26.5), 1.8, 0.9, BLACK)


def _paint_eyes(img: Image.Image, base: int) -> None:
    """Dois olhos brancos PUROS, iguais, pós-snap — crisp, sem halo."""
    px = img.load()
    s = base / float(REF)
    r = 2.9 * s
    for ecx in (27.0, 37.0):
        for y in range(int((35.0 - r - 1) * s), int((35.0 + r + 2) * s) + 1):
            for x in range(int((ecx - r - 1) * s), int((ecx + r + 2) * s) + 1):
                if not (0 <= x < base and 0 <= y < base):
                    continue
                if math.hypot(x + 0.5 - ecx * s, y + 0.5 - 35.0 * s) <= r:
                    px[x, y] = EYE + (255,)


def mark(base: int = REF, blink: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (REF * SS, REF * SS), TRANSPARENT)
    _draw_mark(ImageDraw.Draw(canvas))
    small = canvas.resize((base, base), Image.Resampling.BOX)
    _snap(small, MARK_PALETTE)
    _outline(small)
    if not blink:
        _paint_eyes(small, base)
    return small


# ─── wordmark "CAIPORA" ────────────────────────────────────────────────────

SCALE = 4
GAP = 8
MARGIN = 3        # folga no mask por letra para os dentes da serrilha

LETTERS = {
    "C": [".####.", "##..##", "##....", "##....", "##....", "##..##", ".####."],
    "A": [".####.", "##..##", "##..##", "######", "##..##", "##..##", "##..##"],
    "I": ["######", "..##..", "..##..", "..##..", "..##..", "..##..", "######"],
    "P": ["#####.", "##..##", "##..##", "#####.", "##....", "##....", "##...."],
    "O": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
    "R": ["#####.", "##..##", "##..##", "#####.", "##.##.", "##..##", "##..##"],
}
WORD = "CAIPORA"
EYE_LETTER_INDEX = 4   # o "O" é o rosto-vazio — a mata olha de volta


def _glyph_mask(letter: str) -> tuple[list[list[bool]], int, int]:
    rows = LETTERS[letter]
    gw, gh = len(rows[0]) * SCALE, len(rows) * SCALE
    w, h = gw + 2 * MARGIN, gh + 2 * MARGIN
    mask = [[False] * w for _ in range(h)]
    for y in range(gh):
        for x in range(gw):
            if rows[y // SCALE][x // SCALE] == "#":
                mask[y + MARGIN][x + MARGIN] = True
    return mask, w, h


def _serrate(mask: list[list[bool]], w: int, h: int, index: int, rng: random.Random) -> None:
    """A palavra é a juba: dentes pra fora em cima, mordidas nas laterais."""
    for x in range(w):
        top = next((y for y in range(h) if mask[y][x]), -1)
        if top <= 0:
            continue
        phase = (x // 3 + index) % 3
        if phase == 0:
            mask[top - 1][x] = True
            if top > 1 and (x // 3 + index) % 6 == 0:
                mask[top - 2][x] = True
    for x in range(w):
        bottom = next((y for y in range(h - 1, -1, -1) if mask[y][x]), -1)
        if bottom < 0 or bottom >= h - 1:
            continue
        if (x // 4 + index) % 4 == 0:
            mask[bottom + 1][x] = True
    # mordidas: lascas arrancadas nas bordas laterais (madeira não — carne da juba)
    for _ in range(6):
        x, y = rng.randrange(1, w - 1), rng.randrange(1, h - 1)
        if not mask[y][x]:
            continue
        if not mask[y][x - 1] or not mask[y][x + 1]:
            mask[y][x] = False


def wordmark(blink: bool = False) -> Image.Image:
    img = Image.new("RGBA", (256, 96), TRANSPARENT)
    px = img.load()
    rng = random.Random(WORDMARK_SEED)
    word_w = len(WORD) * 6 * SCALE + (len(WORD) - 1) * GAP
    x0 = (256 - word_w) // 2
    y0 = 30

    for i, letter in enumerate(WORD):
        mask, w, h = _glyph_mask(letter)
        _serrate(mask, w, h, i, rng)
        ox0, oy0 = x0 - MARGIN, y0 - MARGIN
        # contorno de treva 1px ao redor da silhueta serrilhada
        for y in range(h):
            for x in range(w):
                if not mask[y][x]:
                    continue
                for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    yy, xx = y + dy, x + dx
                    inside = 0 <= xx < w and 0 <= yy < h and mask[yy][xx]
                    gx, gy = ox0 + xx, oy0 + yy
                    if not inside and 0 <= gx < 256 and 0 <= gy < 96:
                        px[gx, gy] = OUTLINE + (255,)
        # preenchimento na rampa da juba: laranja vibrante, base na sombra
        glyph_bottom = MARGIN + 7 * SCALE
        for y in range(h):
            for x in range(w):
                if not mask[y][x]:
                    continue
                col = ORANGE_DK if y >= glyph_bottom - 4 else ORANGE
                px[ox0 + x, oy0 + y] = col + (255,)
        # o "O" vira o rosto-vazio: miolo preto + dois olhos brancos puros
        if i == EYE_LETTER_INDEX:
            hole_x0, hole_x1 = x0 + 7, x0 + 17
            hole_y0, hole_y1 = y0 + 4, y0 + 24
            for gy in range(hole_y0, hole_y1):
                for gx in range(hole_x0, hole_x1):
                    px[gx, gy] = BLACK + (255,)
            if not blink:
                for ex in (x0 + 8, x0 + 13):
                    for dx in range(3):
                        for dy in range(3):
                            px[ex + dx, y0 + 12 + dy] = EYE + (255,)
        # sangue mínimo: um escorrido em algumas letras, poça na base
        if rng.random() < 0.55:
            dx = rng.randrange(MARGIN + 2, w - MARGIN - 2)
            bottom = next((y for y in range(h - 1, -1, -1) if mask[y][dx]), -1)
            if bottom > 0:
                drip = rng.randint(4, 10)
                for dy in range(drip):
                    gy = oy0 + bottom + 1 + dy
                    if gy >= 96:
                        break
                    col = (BLOOD if dy < drip - 2 else BLOOD_DK) + (255,)
                    px[ox0 + dx, gy] = col
                for bx in range(max(0, dx - 1), min(w, dx + 2)):
                    if mask[bottom][bx]:
                        px[ox0 + bx, oy0 + bottom] = BLOOD + (255,)
        x0 += 6 * SCALE + GAP
    return img


# ─── composições ───────────────────────────────────────────────────────────

def _upscale(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.Resampling.NEAREST)


def boot_splash(mark_img: Image.Image, word_img: Image.Image) -> Image.Image:
    """1280x720, composição espelhada pelo loader HTML (handoff invisível)."""
    img = Image.new("RGBA", (1280, 720), NIGHT + (255,))
    big_mark = _upscale(mark_img, 4)            # 256x256
    big_word = _upscale(word_img, 2)            # 512x192
    img.alpha_composite(big_mark, (640 - big_mark.width // 2, 150))
    img.alpha_composite(big_word, (640 - big_word.width // 2, 430))
    return img


def icon(size: int, base: int, factor: int) -> Image.Image:
    """Rosto-marca sobre fundo noite (favicon, PWA, og:image via export)."""
    assert base * factor == size
    img = Image.new("RGBA", (size, size), NIGHT + (255,))
    img.alpha_composite(_upscale(mark(base), factor), (0, 0))
    return img


def _b64(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode("ascii")


def inject_shell(mark_open: Image.Image, mark_blink: Image.Image,
                 word_img: Image.Image) -> None:
    """Embute os PNGs da marca em base64 no loader HTML (html/shell.html).

    O shell replica a composição do boot_splash; os blocos GEN_BRAND são a
    única parte gerada — o resto do arquivo é código-fonte normal."""
    path = os.path.join(ROOT, "html", "shell.html")
    if not os.path.exists(path):
        print("[gen_brand] html/shell.html ausente — injeção de base64 pulada")
        return
    with open(path, encoding="utf-8") as fh:
        html = fh.read()
    for elem_id, img in (("brand-mark-open", mark_open),
                         ("brand-mark-blink", mark_blink),
                         ("brand-wordmark", word_img)):
        pattern = r'(<img id="%s" src=")[^"]*(")' % elem_id
        html, n = re.subn(pattern, r"\g<1>%s\g<2>" % _b64(img), html, count=1)
        if n != 1:
            raise SystemExit("[gen_brand] âncora <img id=\"%s\"> não encontrada no shell" % elem_id)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(html)


def generate_all() -> None:
    os.makedirs(SPRITES, exist_ok=True)
    os.makedirs(ICONS, exist_ok=True)

    mark_open = mark(REF)
    mark_blink = mark(REF, blink=True)
    mark_open.save(os.path.join(SPRITES, "brand_mark.png"))
    mark_blink.save(os.path.join(SPRITES, "brand_mark_blink.png"))

    word_open = wordmark()
    word_open.save(os.path.join(SPRITES, "logo_title.png"))
    wordmark(blink=True).save(os.path.join(SPRITES, "logo_title_blink.png"))

    boot_splash(mark_open, word_open).save(os.path.join(SPRITES, "boot_splash.png"))

    icon(512, 64, 8).save(os.path.join(ROOT, "icon.png"))
    icon(512, 64, 8).save(os.path.join(ICONS, "icon_512.png"))
    icon(144, 48, 3).save(os.path.join(ICONS, "icon_144.png"))
    icon(180, 60, 3).save(os.path.join(ICONS, "icon_180.png"))

    inject_shell(mark_open, mark_blink, word_open)

    print("[gen_brand] marca regenerada: brand_mark(+blink), logo_title(+blink), "
          "boot_splash, icon.png, icons PWA 144/180/512, base64 do shell")


if __name__ == "__main__":
    generate_all()
