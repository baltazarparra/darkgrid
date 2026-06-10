#!/usr/bin/env python3
"""Generate the common-enemy sprites (Caçador & Bruxo) — premium organic pipeline.

Same recipe as the protagonist (`gen_caipora.py`), parameterized for 48×48:
organic vector shapes supersampled 8× → area downsample → closed-palette snap
(per character) → continuous 1px dark outline.

Art law: `docs/PLANO-redesign-cacador-bruxo.md` (§2) — the invaders are earth,
leather, pitch-black and bone. Brand locks: no pure-white round eyes, no
protagonist orange (#ff4500/#8b2a00), no crystal green. Enemies face LEFT,
toward the Caipora (arena: player x=160, enemy x=480).
"""

from __future__ import annotations

import math
import os

from PIL import Image, ImageDraw


OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
# Os invasores são humanos adultos: maiores que a Caipora-criança (96px,
# corpo ~75px). Combate/arena usa 112px (corpo ~103px ≈ 1.4x ela); o mapa de
# exploração usa variante 56px re-renderizada dos mesmos vetores (a Caipora
# anda no mapa a scale 0.533 ≈ 51px). Lei: docs/PLANO-escala-invasores-e-zoom-retrato.md.
SIZE = 112
MAP_SIZE = 56
GRID = 48        # espaço de desenho: as coordenadas abaixo vivem na grade 48
SS = 8

TRANSPARENT = (0, 0, 0, 0)
OUTLINE = (26, 18, 10)          # #1a120a — mesmo contorno do mundo

# ── Caçador (predador de chapéu) ──────────────────
LEATHER_DK = (36, 21, 9)        # #241509 chapéu/couro sombra
LEATHER = (61, 38, 20)          # #3d2614 chapéu/couro
PONCHO = (74, 42, 30)           # #4a2a1e pano base
PONCHO_LT = (107, 61, 36)       # #6b3d24 pano iluminado
SKIN = (138, 106, 78)           # #8a6a4e pele mínima (queixo)
STEEL_DK = (42, 38, 36)         # #2a2624 aço da espingarda
STEEL = (138, 138, 146)         # #8a8a92 fio/reflexo do aço
EYE_RED = (200, 30, 20)         # #c81e14 brilho dos olhos na sombra
BLOOD = (139, 0, 0)             # #8b0000 sangue seco
BONE = (216, 200, 168)          # #d8c8a8 troféus (dentes/garras)

CACADOR_PALETTE = [
    OUTLINE, LEATHER_DK, LEATHER, PONCHO, PONCHO_LT,
    SKIN, STEEL_DK, STEEL, EYE_RED, BLOOD, BONE,
]

# ── Bruxo (feiticeiro do breu) ────────────────────
ROBE_DK = (28, 15, 40)          # #1c0f28 breu-roxo podre (sombra)
ROBE = (58, 31, 82)             # #3a1f52 manto
BONE_DK = (156, 140, 112)       # #9c8c70 osso em sombra / mão de galho
EMBER = (200, 60, 20)           # #c83c14 brasa mortiça (olhos em fenda)
EMBER_HOT = (232, 116, 44)      # #e8742c ponto vivo da brasa ritual

BRUXO_PALETTE = [
    OUTLINE, ROBE_DK, ROBE, BONE_DK, BONE, EMBER, EMBER_HOT, BLOOD,
]


class Painter:
    def __init__(self, size: int = SIZE) -> None:
        self.size = size
        self.k = size / GRID * SS   # grade 48 → canvas supersampled
        self.im = Image.new("RGBA", (size * SS, size * SS), TRANSPARENT)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, pts: list[tuple[float, float]], col: tuple[int, int, int]) -> None:
        self.d.polygon([(x * self.k, y * self.k) for x, y in pts], fill=col)

    def ellipse(self, cx: float, cy: float, rx: float, ry: float, col: tuple[int, int, int]) -> None:
        self.d.ellipse(
            [(cx - rx) * self.k, (cy - ry) * self.k, (cx + rx) * self.k, (cy + ry) * self.k],
            fill=col,
        )

    def limb(
        self,
        a: tuple[float, float],
        b: tuple[float, float],
        wa: float,
        wb: float,
        col: tuple[int, int, int],
    ) -> None:
        x0, y0 = a
        x1, y1 = b
        dx = x1 - x0
        dy = y1 - y0
        length = math.hypot(dx, dy) or 1.0
        nx = -dy / length
        ny = dx / length
        self.poly(
            [
                (x0 + nx * wa / 2, y0 + ny * wa / 2),
                (x1 + nx * wb / 2, y1 + ny * wb / 2),
                (x1 - nx * wb / 2, y1 - ny * wb / 2),
                (x0 - nx * wa / 2, y0 - ny * wa / 2),
            ],
            col,
        )
        self.ellipse(x0, y0, wa / 2, wa / 2, col)
        self.ellipse(x1, y1, wb / 2, wb / 2, col)

    def render(self, palette: list[tuple[int, int, int]]) -> Image.Image:
        small = self.im.resize((self.size, self.size), Image.Resampling.BOX)
        px = small.load()
        for y in range(self.size):
            for x in range(self.size):
                r, g, b, a = px[x, y]
                if a < 112:
                    px[x, y] = TRANSPARENT
                else:
                    px[x, y] = _nearest_palette((r, g, b), palette)
        return small


def _nearest_palette(
    color: tuple[int, int, int], palette: list[tuple[int, int, int]]
) -> tuple[int, int, int, int]:
    best = palette[0]
    best_d = 10**12
    for candidate in palette:
        d = (
            (color[0] - candidate[0]) ** 2
            + (color[1] - candidate[1]) ** 2
            + (color[2] - candidate[2]) ** 2
        )
        if d < best_d:
            best = candidate
            best_d = d
    return best + (255,)


def _outline(img: Image.Image) -> None:
    size = img.width
    px = img.load()
    edge: list[tuple[int, int]] = []
    for y in range(size):
        for x in range(size):
            if px[x, y][3] == 0:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx = x + ox
                ny = y + oy
                if not (0 <= nx < size and 0 <= ny < size) or px[nx, ny][3] == 0:
                    edge.append((x, y))
                    break
    for x, y in edge:
        px[x, y] = OUTLINE + (255,)


def _shift_down(img: Image.Image, dy: int) -> Image.Image:
    out = Image.new("RGBA", img.size, TRANSPARENT)
    out.paste(img, (0, dy))
    return out


# ════════════════════════════════════════════════════
# Caçador — leitura a 32px: a aba do chapéu e o cano
# ════════════════════════════════════════════════════

def _cacador_legs(p: Painter) -> None:
    p.limb((20.5, 37.0), (19.5, 43.5), 3.6, 2.8, LEATHER)
    p.limb((27.0, 37.0), (27.5, 43.5), 3.6, 2.8, LEATHER)
    # botas
    p.limb((19.5, 44.5), (17.0, 45.0), 3.0, 2.4, LEATHER_DK)
    p.limb((27.5, 44.5), (25.0, 45.0), 3.0, 2.4, LEATHER_DK)


def _cacador_poncho(p: Painter) -> None:
    hem = [
        (34.5, 31.0), (33.5, 38.0), (31.0, 33.5), (28.0, 37.5),
        (24.5, 33.0), (21.0, 37.5), (17.5, 33.5), (15.0, 38.0),
        (13.5, 31.0),
    ]
    body = [(16.0, 21.5), (24.0, 20.0), (32.0, 21.5), (35.0, 27.0)] + hem[:1] + hem[1:] + [(13.0, 27.0)]
    p.poly(body, PONCHO)
    # lado iluminado (encara a esquerda)
    p.poly([(16.0, 21.5), (20.0, 21.0), (18.5, 33.0), (15.0, 38.0), (13.5, 31.0), (13.0, 27.0)], PONCHO_LT)
    # vinco central em sombra
    p.poly([(23.5, 22.0), (26.0, 22.0), (26.5, 35.0), (24.0, 33.0)], LEATHER_DK)
    # sombra no flanco direito (profundidade)
    p.poly([(32.0, 21.5), (35.0, 27.0), (34.5, 31.0), (33.5, 38.0), (31.5, 34.0), (30.5, 22.5)], LEATHER_DK)
    # sangue seco na barra — respingo, não bandeira
    p.poly([(29.5, 34.5), (31.5, 34.0), (32.5, 37.2), (30.0, 36.5)], BLOOD)
    p.ellipse(28.6, 33.0, 0.9, 0.7, BLOOD)


def _cacador_trophies(p: Painter) -> None:
    # colar de dentes/garras — triângulos de osso pendurados no peito
    for i, (tx, ty) in enumerate(((19.0, 23.2), (21.7, 24.2), (24.4, 24.6), (27.1, 24.0), (29.4, 23.0))):
        drop = 2.2 if i in (1, 3) else 2.8
        p.poly([(tx - 0.9, ty), (tx + 0.9, ty), (tx, ty + drop)], BONE)


def _cacador_head(p: Painter) -> None:
    # vazio do rosto sob a aba (a sombra engole o humano)
    p.ellipse(23.5, 17.0, 6.0, 4.6, OUTLINE)
    # queixo mínimo de pele doente
    p.poly([(21.0, 19.5), (26.5, 19.5), (25.5, 21.8), (22.0, 21.8)], SKIN)
    # chapéu: aba larga + copa
    p.ellipse(23.5, 13.0, 11.0, 2.6, LEATHER)
    p.poly([(12.5, 13.0), (34.5, 13.0), (33.0, 11.2), (14.0, 11.2)], LEATHER_DK)
    p.poly([(17.5, 12.0), (29.5, 12.0), (28.5, 4.5), (18.5, 4.5)], LEATHER)
    p.ellipse(23.5, 4.8, 5.0, 1.8, LEATHER)
    p.poly([(17.8, 11.8), (29.2, 11.8), (29.2, 9.8), (17.8, 9.8)], LEATHER_DK)  # fita


def _cacador_eyes(p: Painter, windup: bool) -> None:
    ry = 0.7 if windup else 0.9
    p.ellipse(20.8, 17.0, 1.5, ry, EYE_RED)
    p.ellipse(25.6, 17.0, 1.5, ry, EYE_RED)


def cacador(pose: str = "idle", size: int = SIZE) -> Image.Image:
    p = Painter(size)
    windup = pose == "windup"
    _cacador_legs(p)
    _cacador_poncho(p)
    _cacador_trophies(p)
    if windup:
        # PONTARIA: cano nivelado no olhar, coronha cravada no ombro.
        p.poly([(30.0, 16.5), (36.5, 15.5), (37.5, 20.5), (31.0, 21.5)], LEATHER)   # coronha
        p.limb((31.0, 18.6), (4.0, 18.2), 2.0, 1.6, STEEL_DK)                       # cano
        p.limb((29.0, 17.6), (6.0, 17.3), 0.8, 0.7, STEEL)                          # fio do cano
        p.ellipse(3.6, 18.2, 1.0, 0.9, STEEL)                                       # reflexo na boca
        p.ellipse(14.0, 19.4, 1.8, 1.6, SKIN)                                       # mão da frente
        p.ellipse(27.5, 20.0, 1.9, 1.7, SKIN)                                       # mão do gatilho
    else:
        # atravessada, apontando frente-baixo — pronto pra erguer
        p.poly([(31.0, 26.5), (37.5, 24.5), (38.5, 28.5), (32.5, 30.5)], LEATHER)   # coronha
        p.limb((32.0, 28.4), (5.5, 31.6), 2.2, 1.8, STEEL_DK)                       # cano
        p.limb((30.0, 27.5), (7.5, 30.3), 0.9, 0.8, STEEL)                          # fio do cano
        p.ellipse(16.0, 30.4, 1.8, 1.6, SKIN)
        p.ellipse(28.0, 29.0, 1.9, 1.7, SKIN)
    _cacador_head(p)
    _cacador_eyes(p, windup)
    img = p.render(CACADOR_PALETTE)
    if windup:
        img = _shift_down(img, max(1, round(size / GRID)))   # peso cravado no chão
    _outline(img)
    return img


# ════════════════════════════════════════════════════
# Bruxo — leitura a 32px: o capuz torto e o cajado de osso
# ════════════════════════════════════════════════════

def _bruxo_robe(p: Painter, windup: bool) -> None:
    spread = 2.5 if windup else 0.0
    hem = [
        (31.5 + spread, 38.0), (29.5, 41.5), (27.0 + spread * 0.4, 45.5),
        (25.0, 41.0), (22.0, 45.5), (19.0, 41.5), (16.0 - spread * 0.4, 45.5),
        (13.5, 40.5), (12.0 - spread, 37.5),
    ]
    body = [(16.5, 20.0), (22.0, 18.5), (28.5, 20.5), (31.0, 28.0), (32.0 + spread, 34.0)] + hem + [(13.0 - spread, 30.0), (15.0, 24.0)]
    p.poly(body, ROBE)
    # sombra interna: o manto come a luz do lado direito e no vão central
    p.poly([(27.5, 21.5), (31.0, 28.0), (32.0 + spread, 34.0), (31.5 + spread, 38.0), (29.5, 41.5), (27.5, 36.0), (26.5, 23.0)], ROBE_DK)
    p.poly([(21.0, 30.0), (24.0, 30.5), (24.5, 43.0), (21.5, 41.0)], ROBE_DK)
    # marca ritual de sangue no peito — talhos diagonais (NUNCA uma cruz;
    # cruz é do invasor catequizador, não do bruxo do mato)
    p.limb((18.0, 25.5), (21.5, 30.5), 1.1, 0.9, BLOOD)
    p.limb((21.0, 25.0), (18.0, 29.0), 0.9, 0.8, BLOOD)
    p.ellipse(20.0, 32.2, 0.7, 0.6, BLOOD)


def _bruxo_hood(p: Painter, windup: bool) -> None:
    # capuz fechado em volta do vazio, pico QUEBRADO tombando pra esquerda
    p.poly([(15.5, 19.5), (16.5, 11.0), (21.0, 7.0), (26.5, 7.5), (30.0, 12.5), (30.5, 19.5), (27.0, 22.0), (18.5, 22.0)], ROBE)
    p.poly([(27.5, 10.5), (30.0, 12.5), (30.5, 19.5), (27.0, 22.0), (26.0, 13.0)], ROBE_DK)
    # pico torto: sobe e DOBRA no meio, tombando morto pra esquerda
    p.poly([(19.0, 10.0), (22.5, 3.5), (26.0, 9.0)], ROBE)
    p.poly([(23.5, 5.5), (22.0, 2.5), (16.5, 1.5), (13.0, 3.5), (18.5, 5.5)], ROBE)
    p.ellipse(13.5, 3.2, 1.5, 1.2, ROBE_DK)   # ponta morta caída
    # vazio do rosto
    p.ellipse(22.5, 16.0, 4.6, 4.0, OUTLINE)


def _bruxo_eyes(p: Painter, windup: bool) -> None:
    col = EMBER_HOT if windup else EMBER
    ry = 0.8 if windup else 0.55
    p.ellipse(20.4, 15.6, 1.3, ry, col)
    p.ellipse(24.9, 15.6, 1.3, ry, col)


def _bruxo_staff(p: Painter, windup: bool) -> None:
    if windup:
        base = (24.0, 39.0)
        top = (7.5, 11.0)
    else:
        base = (10.5, 45.5)
        top = (12.0, 12.5)
    p.limb(base, top, 1.7, 1.5, BONE_DK)
    # fetiche: crânio de bicho pequeno coroando o osso
    sx, sy = top[0], top[1] - 2.4
    p.ellipse(sx, sy, 2.9, 2.5, BONE)
    p.poly([(sx - 1.8, sy + 1.8), (sx + 1.8, sy + 1.8), (sx + 1.0, sy + 4.0), (sx - 1.0, sy + 4.0)], BONE_DK)  # focinho/mandíbula
    p.ellipse(sx - 1.2, sy - 0.3, 0.8, 0.7, OUTLINE)   # órbitas
    p.ellipse(sx + 1.2, sy - 0.3, 0.8, 0.7, OUTLINE)
    if windup:
        # o fetiche ACENDE — brasa ritual nas órbitas e faíscas soltas
        p.ellipse(sx - 1.2, sy - 0.3, 0.55, 0.45, EMBER_HOT)
        p.ellipse(sx + 1.2, sy - 0.3, 0.55, 0.45, EMBER_HOT)
        p.ellipse(sx - 3.2, sy - 2.6, 0.6, 0.6, EMBER)
        p.ellipse(sx + 2.4, sy - 3.4, 0.5, 0.5, EMBER_HOT)
        p.ellipse(sx - 0.4, sy - 4.2, 0.5, 0.5, EMBER)
    # amarrado de ossos pendurado abaixo do crânio
    ax, ay = (sx + 2.0, sy + 3.4) if windup else (sx + 1.6, sy + 3.0)
    p.limb((ax, ay), (ax + 1.2, ay + 3.6), 0.7, 0.6, BONE_DK)
    p.ellipse(ax + 1.4, ay + 4.2, 0.9, 0.6, BONE)


def _bruxo_hands(p: Painter, windup: bool) -> None:
    if windup:
        # braço do cajado erguido + mão livre aberta de dedos de galho
        p.limb((19.0, 22.5), (13.0, 17.5), 3.2, 2.2, ROBE)
        p.ellipse(13.0, 17.0, 1.6, 1.4, BONE_DK)
        p.limb((27.0, 23.5), (31.5, 17.5), 3.0, 2.0, ROBE)
        for tip in ((30.0, 13.0), (32.5, 12.8), (34.5, 14.2), (35.0, 16.8)):
            p.limb((31.5, 17.0), tip, 1.0, 0.55, BONE_DK)
    else:
        # curvado sobre o cajado fincado, dedos longos enroscados na haste
        p.limb((18.5, 24.0), (12.5, 27.5), 3.2, 2.0, ROBE)
        for tip in ((9.8, 26.5), (9.6, 28.3), (10.2, 30.0)):
            p.limb((13.0, 27.0), tip, 1.0, 0.55, BONE_DK)


def bruxo(pose: str = "idle", size: int = SIZE) -> Image.Image:
    p = Painter(size)
    windup = pose == "windup"
    _bruxo_staff(p, windup)
    _bruxo_robe(p, windup)
    _bruxo_hood(p, windup)
    _bruxo_eyes(p, windup)
    _bruxo_hands(p, windup)
    img = p.render(BRUXO_PALETTE)
    if windup:
        img = _shift_down(img, max(1, round(size / GRID)))   # assenta o peso antes do ataque
    _outline(img)
    return img


# ════════════════════════════════════════════════════
# Prancha de conceito
# ════════════════════════════════════════════════════

def _contact_sheet(frames: list[tuple[str, Image.Image]]) -> None:
    """Prancha: inimigos 2× + Caipora idle 2× (hierarquia) + leitura 32px."""
    zoom = 2
    cell = SIZE * zoom + 16
    label_h = 14
    caipora_path = os.path.join(OUT, "player_idle.png")
    caipora = Image.open(caipora_path).convert("RGBA") if os.path.exists(caipora_path) else None
    caipora_w = (caipora.width * zoom + 16) if caipora else 0
    width = cell * len(frames) + caipora_w
    height = label_h + max(cell, (caipora.height * zoom + 16) if caipora else 0) + 44
    sheet = Image.new("RGBA", (width, height), (18, 14, 15, 255))
    draw = ImageDraw.Draw(sheet)
    base_y = height - 44
    for i, (label, img) in enumerate(frames):
        x = i * cell
        big = img.resize((SIZE * zoom, SIZE * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (x + 8, base_y - big.height))
        draw.text((x + 8, 1), label, fill=(230, 210, 180, 255))
        # leitura 32px (checklist da skill §5)
        tiny = img.resize((32, 32), Image.Resampling.BOX)
        sheet.alpha_composite(tiny, (x + 8, base_y + 8))
    if caipora:
        big = caipora.resize((caipora.width * zoom, caipora.height * zoom), Image.Resampling.NEAREST)
        sheet.alpha_composite(big, (cell * len(frames) + 8, base_y - big.height))
        draw.text((cell * len(frames) + 8, 1), "caipora (ref)", fill=(230, 210, 180, 255))
    sheet.save(os.path.join(OUT, "inimigos_contact_sheet.png"))


def generate_all() -> None:
    os.makedirs(OUT, exist_ok=True)
    frames: list[tuple[str, Image.Image]] = []
    jobs = (
        ("enemy_idle.png", "cacador idle", cacador, "idle"),
        ("enemy_windup.png", "cacador windup", cacador, "windup"),
        ("bruxo_idle.png", "bruxo idle", bruxo, "idle"),
        ("bruxo_windup.png", "bruxo windup", bruxo, "windup"),
    )
    for name, label, fn, pose in jobs:
        img = fn(pose)
        img.save(os.path.join(OUT, name))
        frames.append((label, img))
    # Variantes do mapa de exploração: re-render 56px dos MESMOS vetores
    # (snap+outline corretos — nunca downscale por NEAREST do asset grande).
    cacador("idle", MAP_SIZE).save(os.path.join(OUT, "enemy_map.png"))
    bruxo("idle", MAP_SIZE).save(os.path.join(OUT, "bruxo_map.png"))
    _contact_sheet(frames)
    print("[gen_inimigos] cacador + bruxo idle/windup (112x112) + variantes de mapa (56x56) + prancha gerados")


if __name__ == "__main__":
    generate_all()
