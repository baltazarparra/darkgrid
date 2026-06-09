#!/usr/bin/env python3
"""Gera os sprites da CAIPORA — a protagonista, núcleo visual do jogo.

Conceito: "A Predadora-Rainha da Mata" (ver docs/CONCEITO-protagonista.md).
Silhueta felina assimétrica, juba-cometa de fogo (fonte de luz própria),
pele escura com rim light térmico, pintura de guerra de urucum/jenipapo,
saiote e ombreira de folhas, cipó-chicote vivo com ponta em brasa.

Pipeline premium (diferente do gen_chars.py de retângulos):
  1. desenho vetorial supersampled 8x (formas orgânicas, membros capsulares)
  2. downsample por área -> 64x64
  3. snap de paleta (ramps fechados por material)
  4. outline seletivo escuro (selout) — coesão contra qualquer fundo
  5. rim light procedural — o fogo da juba ilumina as bordas superiores do corpo
  6. dither de bandas no fogo — chama orgânica, não listras

Saída: player_idle/walk_1/walk_2/windup/strike/recover.png (64x64).
Determinístico — mesmo input, mesmos pixels.
"""
import math
import os
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

SS = 8          # fator de supersample
SIZE = 64       # canvas final

# ── Paleta (ramps fechados por material) ─────────────────────────────
# Fogo (juba, brasa do chicote) — do mais profundo ao núcleo branco-quente
F_DEEP = (148, 28, 8)
F_LOW  = (208, 54, 4)
F_MID  = (255, 107, 0)
F_HOT  = (255, 172, 48)
F_CORE = (255, 236, 180)
# Pele (escura, caboclinha da mata)
SK_DK2 = (52, 28, 22)
SK_DK  = (84, 48, 30)
SK     = (124, 76, 44)
SK_HL  = (178, 116, 62)     # rim light térmico
# Folhas / cipó
LF_DK  = (16, 32, 18)
LF     = (34, 58, 30)
LF_HL  = (84, 110, 48)
# Terra / madeira do cipó
ER_DK  = (34, 18, 16)
ER     = (61, 31, 31)
# Pintura de guerra
URUCUM = (196, 44, 20)      # vermelho urucum
JENIPAPO = (24, 16, 20)     # preto-azulado jenipapo
# Olhos
EYE    = (255, 214, 84)
EYE_CORE = (255, 255, 220)
# Outline
OUTLINE = (12, 8, 12)

FIRE_RAMP = [F_DEEP, F_LOW, F_MID, F_HOT, F_CORE]
GLOW_COLORS = set(FIRE_RAMP) | {EYE, EYE_CORE}

PALETTE = FIRE_RAMP + [SK_DK2, SK_DK, SK, SK_HL, LF_DK, LF, LF_HL,
                       ER_DK, ER, URUCUM, JENIPAPO, EYE, EYE_CORE]

# Material -> highlight do rim light
RIM_MAP = {SK: SK_HL, SK_DK: SK, SK_DK2: SK_DK,
           LF: LF_HL, LF_DK: LF, ER: SK_DK, ER_DK: ER}


def _hash01(n: float) -> float:
    """Ruído determinístico [0,1) — sem random, mesmo resultado em qualquer SO."""
    return (math.sin(n * 127.1 + 311.7) * 43758.5453) % 1.0


class Painter:
    """Canvas supersampled: coordenadas em espaço 64 (floats), desenho a 8x."""

    def __init__(self):
        self.im = Image.new("RGBA", (SIZE * SS, SIZE * SS), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    # ── primitivas (coords em espaço 64) ──
    def ellipse(self, cx, cy, rx, ry, col):
        self.d.ellipse([(cx - rx) * SS, (cy - ry) * SS,
                        (cx + rx) * SS, (cy + ry) * SS], fill=col)

    def poly(self, pts, col):
        self.d.polygon([(x * SS, y * SS) for (x, y) in pts], fill=col)

    def limb(self, p0, p1, w0, w1, col):
        """Membro capsular com largura que afunila de w0 (p0) para w1 (p1)."""
        x0, y0 = p0
        x1, y1 = p1
        dx, dy = x1 - x0, y1 - y0
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        self.poly([(x0 + nx * w0 / 2, y0 + ny * w0 / 2),
                   (x1 + nx * w1 / 2, y1 + ny * w1 / 2),
                   (x1 - nx * w1 / 2, y1 - ny * w1 / 2),
                   (x0 - nx * w0 / 2, y0 - ny * w0 / 2)], col)
        self.ellipse(x0, y0, w0 / 2, w0 / 2, col)
        self.ellipse(x1, y1, w1 / 2, w1 / 2, col)

    def stroke(self, pts, w, col):
        """Polilinha espessa (chicote): segmentos capsulares encadeados."""
        for a, b in zip(pts, pts[1:]):
            self.limb(a, b, w, w, col)

    def blob_path(self, pts, r0, r1, col):
        """Discos sobrepostos ao longo de um caminho, raio afunilando — juba."""
        n = max(len(pts) - 1, 1)
        steps = 24
        for i in range(steps + 1):
            t = i / steps
            ft = t * n
            k = min(int(ft), n - 1)
            lt = ft - k
            x = pts[k][0] + (pts[k + 1][0] - pts[k][0]) * lt
            y = pts[k][1] + (pts[k + 1][1] - pts[k][1]) * lt
            r = r0 + (r1 - r0) * t
            self.ellipse(x, y, r, r, col)

    def render(self) -> Image.Image:
        """Downsample por área + alpha threshold + snap de paleta."""
        small = self.im.resize((SIZE, SIZE), Image.BOX)
        px = small.load()
        for y in range(SIZE):
            for x in range(SIZE):
                r, g, b, a = px[x, y]
                if a < 110:
                    px[x, y] = (0, 0, 0, 0)
                else:
                    px[x, y] = _snap((r, g, b))
        return small


def _snap(c):
    best, bd = PALETTE[0], 1e9
    for p in PALETTE:
        d = (2 * (c[0] - p[0]) ** 2 + 4 * (c[1] - p[1]) ** 2
             + 3 * (c[2] - p[2]) ** 2)
        if d < bd:
            best, bd = p, d
    return best + (255,)


# ── Pós-processamento a 64px ─────────────────────────────────────────

def _selout(img):
    """Outline seletivo: borda externa escurecida (fogo/olhos ficam de fora)."""
    px = img.load()
    edges = []
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            if a == 0 or (r, g, b) in GLOW_COLORS:
                continue
            for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + ox, y + oy
                if not (0 <= nx < SIZE and 0 <= ny < SIZE) or px[nx, ny][3] == 0:
                    edges.append((x, y, r, g, b))
                    break
    for x, y, r, g, b in edges:
        px[x, y] = ((r + OUTLINE[0]) // 3, (g + OUTLINE[1]) // 3,
                    (b + OUTLINE[2]) // 3, 255)


def _rim_light(img, fire_cx, fire_cy, reach=26.0):
    """O fogo da juba acende as bordas superiores do corpo (rim light térmico)."""
    px = img.load()
    hits = []
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            c = (r, g, b)
            if a == 0 or c in GLOW_COLORS or c not in RIM_MAP:
                continue
            up = px[x, y - 1] if y > 0 else (0, 0, 0, 0)
            lt = px[x - 1, y] if x > 0 else (0, 0, 0, 0)
            up_glow = up[3] != 0 and (up[0], up[1], up[2]) in GLOW_COLORS
            lt_open = lt[3] == 0 and x - 1 < fire_cx + 4      # borda das costas
            d = math.hypot(x - fire_cx, y - fire_cy)
            if up[3] == 0 or up_glow:
                if d < reach or up_glow:
                    hits.append((x, y, RIM_MAP[c]))
                elif d < reach * 1.5 and (x + y) % 2 == 0:   # falloff em dither
                    hits.append((x, y, RIM_MAP[c]))
            elif lt_open and d < reach and (x + y) % 2 == 0:
                hits.append((x, y, RIM_MAP[c]))              # luz lambendo as costas
    for x, y, c in hits:
        px[x, y] = c + (255,)


def _fire_dither(img):
    """Quebra as bandas do fogo com dither xadrez — chama viva, não listras."""
    order = {c: i for i, c in enumerate(FIRE_RAMP)}
    px = img.load()
    swaps = []
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b, a = px[x, y]
            c = (r, g, b)
            if a == 0 or c not in order or (x + y) % 2:
                continue
            below = px[x, y + 1] if y + 1 < SIZE else (0, 0, 0, 0)
            bc = (below[0], below[1], below[2])
            if below[3] != 0 and bc in order and order[bc] == order[c] - 1:
                swaps.append((x, y, bc))
    for x, y, c in swaps:
        px[x, y] = c + (255,)


# ── A figura ─────────────────────────────────────────────────────────

def _mane(p: Painter, head, sweep, lift, length=1.0, blown=0.0, chama=False):
    """Juba-cometa: sobe da cabeça e flui pra trás em arco ASCENDENTE (energia,
    não peso). sweep/lift moldam o arco; blown estica horizontal (strike);
    chama incendeia (juba mais longa e quente — a CHAMA é DELA)."""
    hx, hy = head
    if chama:
        length += 0.8
        lift += 1.0
    # espinha da juba: nasce atrás do couro, arqueia pra cima-trás, cauda solta
    tail_x = hx - (13 + 4 * length) - 5 * blown
    tail_y = hy - 11 - lift + 5 * blown
    spine = [(hx - 1, hy - 6.5), (hx - 4.5, hy - 10.5 + sweep),
             (hx - 8.5, hy - 12.5 + sweep + blown * 2),
             (hx - 12.5, hy - 12.0 + sweep + blown * 3), (tail_x, tail_y)]
    p.blob_path(spine, 5.2, 1.2, F_DEEP)
    p.blob_path(spine[:4], 4.0, 1.4, F_LOW)
    p.blob_path(spine[:3], 3.0, 1.4, F_MID)
    if chama:
        p.blob_path(spine[:3], 2.0, 1.0, F_HOT)   # coração mais quente
    # línguas soltas desprendendo da cauda (ritmo orgânico)
    for i in range(5 if chama else 4):
        t = 0.5 + i * 0.15
        sx = hx - 1 + (tail_x - hx + 1) * t
        sy = hy - 7 + (tail_y - hy + 7) * t + (_hash01(i * 3.7) - 0.5) * 2.5
        p.limb((sx, sy), (sx - 3.0 - 2 * blown, sy - 2.0 + _hash01(i) * 2.0),
               1.9 - i * 0.3, 0.5,
               F_HOT if (chama and i % 2 == 0) else (F_LOW if i % 2 else F_MID))
    p.ellipse(hx - 4.5, hy - 8.5, 1.6, 1.2, F_HOT)   # brasa subindo na nuca


def _crown(p: Painter, head, lift=0.0, blown=0.0, chama=False):
    """Frente da juba — desenhada DEPOIS da cabeça: o cabelo-fogo nasce do
    couro e sobe em línguas vivas (nada de testa careca, nada de touca)."""
    hx, hy = head
    if chama:
        lift += 2.0
    # couro cabeludo de fogo abraçando o ALTO do crânio (rosto fica livre)
    p.ellipse(hx - 0.2, hy - 5.2, 5.7, 2.9, F_DEEP)
    p.poly([(hx + 0.4, hy - 2.2), (hx + 2.4, hy - 3.6), (hx - 1.4, hy - 3.8)],
           F_DEEP)                                   # bico da franja na testa
    p.ellipse(hx - 1.0, hy - 6.2, 4.2, 2.0, F_LOW)
    # coroa: chamas vivas subindo do couro
    for i, (ox, h) in enumerate([(-3.4, 4.5), (-1.2, 6.8), (1.4, 5.8), (3.4, 3.8)]):
        bend = (_hash01(i * 9.1) - 0.5) * 2.0 - blown * 2.5 - 0.8
        p.limb((hx + ox, hy - 5.2), (hx + ox + bend, hy - 5.7 - h - lift * 0.5),
               2.2, 0.6, F_MID)
        p.limb((hx + ox, hy - 5.2), (hx + ox + bend * 0.7, hy - 5.7 - h * 0.6),
               1.4, 0.5, F_HOT)
    # núcleo branco-quente no coração da coroa (pequeno — acento, não holofote)
    p.ellipse(hx - 0.8, hy - 7.6, 2.0, 1.3, F_CORE)
    p.ellipse(hx + 1.4, hy - 6.4, 1.1, 0.9, F_HOT)
    if chama:
        p.ellipse(hx - 0.4, hy - 8.4, 1.4, 1.0, F_CORE)   # coroa transborda


def _embers(p: Painter, head, pose: str, leg_phase: int = 0):
    """Brasas soltas orbitando a Caipora incendiada (variante CHAMA).
    leg_phase entra na semente: as brasas DERIVAM entre os frames de walk
    (senão ficam pixel-congeladas enquanto o corpo anima). Zona de exclusão
    no rosto — brasa não cai no olho dela."""
    hx, hy = head
    seed = sum(map(ord, pose)) + (leg_phase + 1) * 31
    for i in range(6):
        a = _hash01(i * 5.3 + seed) * math.tau                # determinístico
        r = 9.0 + _hash01(i * 2.1 + seed) * 7.0
        ex = hx + math.cos(a) * r * 1.2
        ey = hy - 6 + math.sin(a) * r * 0.8 - _hash01(i + seed) * 4.0
        if hx - 6.5 < ex < hx + 7.5 and hy - 4.0 < ey < hy + 6.5:
            continue                                          # rosto é sagrado
        p.ellipse(ex, ey, 0.7, 0.7, F_HOT if i % 2 else F_LOW)


def _head(p: Painter, cx, cy, jaw_fwd=0.0):
    """Cabeça com queixo afilado, faixa de jenipapo nos olhos, brasa no olhar."""
    p.ellipse(cx, cy - 1, 5.8, 5.4, SK)                       # crânio
    p.poly([(cx - 5.0, cy - 0.5), (cx + 5.6 + jaw_fwd, cy - 0.5),
            (cx + 3.4 + jaw_fwd, cy + 4.8), (cx - 1.5, cy + 5.0)], SK)  # mandíbula
    p.poly([(cx - 5.0, cy - 1), (cx - 2.6, cy - 1), (cx - 1.4, cy + 4.6),
            (cx - 1.6, cy + 4.8)], SK_DK)                     # lado em sombra
    # faixa FINA de jenipapo só na linha dos olhos (a brasa estoura no escuro)
    p.poly([(cx - 5.2, cy - 1.5), (cx + 5.8 + jaw_fwd, cy - 1.5),
            (cx + 5.5 + jaw_fwd, cy + 0.8), (cx - 5.0, cy + 0.8)], JENIPAPO)
    # olhos de brasa (o da frente maior — encara a presa)
    p.ellipse(cx + 2.8 + jaw_fwd * 0.6, cy - 0.4, 1.5, 1.1, EYE)
    p.ellipse(cx - 1.6, cy - 0.4, 1.2, 1.0, EYE)
    p.ellipse(cx + 3.2 + jaw_fwd * 0.6, cy - 0.6, 0.65, 0.55, EYE_CORE)
    p.ellipse(cx - 1.3, cy - 0.6, 0.5, 0.45, EYE_CORE)
    # urucum: risco de garra na bochecha (curto, não mancha o queixo)
    p.limb((cx + 2.2, cy + 1.9), (cx + 4.2 + jaw_fwd, cy + 1.7), 0.7, 0.6, URUCUM)
    # boca dura (1px, sem sorriso)
    p.limb((cx + 1.2, cy + 4.0), (cx + 2.6 + jaw_fwd, cy + 3.9), 0.55, 0.5, SK_DK2)


def _whip(p: Painter, hand, pose, chama=False):
    """Cipó-chicote vivo: madeira escura, realce de folha, ponta em brasa."""
    hx, hy = hand
    tip_r = 1.7 if chama else 1.3
    tip_core_r = 0.95 if chama else 0.7   # base EXATA de antes da CHAMA (arte travada)
    if pose == "windup":
        # arco tensionado atrás do ombro — a chicotada vem aí
        pts = [(hx, hy), (hx + 3.5, hy - 4.5), (hx + 3.5, hy - 10),
               (hx - 0.5, hy - 14.5), (hx - 5.5, hy - 16)]
    elif pose == "strike":
        # smear de 3 tons — a chicotada como mancha de luz descendo na presa
        for off, col, wd in [(-1.8, F_DEEP, 1.6), (0.0, F_MID, 2.2),
                             (1.8, F_HOT, 1.6)]:
            arc = [(hx + 0.5, hy + off * 0.4), (hx + 6, hy - 1.5 + off),
                   (hx + 11.5, hy + 0.5 + off * 1.4), (hx + 15.5, hy + 4 + off * 1.7)]
            p.stroke(arc, wd, col)
        snap_r = 2.3 if chama else 1.8        # estalo da ponta (um nome por raio,
        snap_core_r = 1.3 if chama else 1.0   # nunca pares de ternários por eixo)
        p.ellipse(hx + 16.5, hy + 6.5, snap_r, snap_r, F_HOT)
        p.ellipse(hx + 16.5, hy + 6.5, snap_core_r, snap_core_r, F_CORE)
        p.limb((hx + 11, hy - 0.5), (hx + 13.5, hy - 4.0), 1.2, 0.4, LF)  # folha arrancada
        return
    elif pose == "recover":
        pts = [(hx, hy), (hx + 3.5, hy + 4), (hx + 1, hy + 8.5),
               (hx + 4.5, hy + 12), (hx + 2.5, hy + 15)]
    else:  # idle / walk: pende vivo da mão, ondulando
        pts = [(hx, hy), (hx + 2.8, hy + 3.5), (hx + 0.6, hy + 7.5),
               (hx + 3.2, hy + 11), (hx + 1.4, hy + 14.5)]
    p.stroke(pts, 2.0, ER_DK)
    p.stroke(pts[:3], 1.1, LF_DK)
    # folhas vivas ao longo do cipó
    mid = pts[2]
    p.ellipse(mid[0] + 1.2, mid[1] + 0.5, 1.6, 1.1, LF)
    p.ellipse(pts[3][0] - 1.0, pts[3][1], 1.3, 1.0, LF)
    # ponta em brasa (assinatura: o estalo crítico nasce aqui)
    p.ellipse(pts[-1][0], pts[-1][1], tip_r, tip_r, F_LOW)
    p.ellipse(pts[-1][0], pts[-1][1], tip_core_r, tip_core_r, F_HOT)
    if chama:
        p.ellipse(pts[-1][0], pts[-1][1], 0.5, 0.5, F_CORE)


def caipora(pose="idle", leg_phase=0, chama=False):
    """Renderiza um frame da Caipora. Retorna Image 64x64 RGBA.

    chama=True: variante incendiada (CHAMA conquistada) — juba mais longa e
    quente, brasas orbitando, ponta do chicote em brasa viva.
    """
    p = Painter()

    # ── esqueleto base (facing right, pés na base y~61) ──
    crouch = {"idle": 0.0, "walk": 0.0, "windup": 3.0,
              "strike": -1.0, "recover": 1.0}[pose if pose != "walk" else "walk"]
    lean = {"idle": 1.5, "walk": 2.5, "windup": -2.0,
            "strike": 6.0, "recover": 0.5}[pose]

    hip = (29.0, 45.0 + crouch)
    chest = (hip[0] + lean, 35.5 + crouch * 0.7)
    head = (chest[0] + lean * 0.8 + 1.2, 24.5 + crouch * 0.9)

    # pernas
    if pose == "strike":
        lf, rf = -5.0, 7.5          # afundo grande no avanço
    elif pose == "windup":
        lf, rf = -3.0, 2.5          # base larga, mola comprimida
    else:
        lf, rf = -2.0 + leg_phase * 2.4, 2.0 - leg_phase * 2.4
    foot_y = 61.0
    far_knee = (hip[0] + lf * 0.6 - 1.2, 53.0 + crouch * 0.5)
    near_knee = (hip[0] + rf * 0.7 + 1.8, 53.0 + crouch * 0.5)
    far_ankle = (hip[0] + lf - 0.5, foot_y - 1.5)
    near_ankle = (hip[0] + rf + 1.2, foot_y - 1.5)

    # braços
    far_sh = (chest[0] - 4.8, 32.5 + crouch * 0.7)
    near_sh = (chest[0] + 5.0, 32.0 + crouch * 0.7)
    if pose == "windup":
        near_el = (near_sh[0] + 3.5, near_sh[1] - 3.5)
        near_hand = (near_sh[0] + 6.0, near_sh[1] - 8.0)      # erguido atrás
        far_el = (far_sh[0] - 3.5, far_sh[1] + 4.0)
        far_hand = (far_sh[0] - 1.5, far_sh[1] + 8.0)
    elif pose == "strike":
        near_el = (near_sh[0] + 5.5, near_sh[1] + 2.5)
        near_hand = (near_sh[0] + 10.0, near_sh[1] + 5.0)     # estendido no golpe
        far_el = (far_sh[0] - 4.0, far_sh[1] + 3.5)
        far_hand = (far_sh[0] - 6.0, far_sh[1] + 1.0)         # contrapeso atrás
    else:
        swing = leg_phase * 1.2                                # contrabalanço da passada
        near_el = (near_sh[0] + 2.4 - swing * 0.6, near_sh[1] + 6.5)
        near_hand = (near_sh[0] + 4.0 - swing, near_sh[1] + 13.0)
        far_el = (far_sh[0] - 2.2 + swing * 0.6, far_sh[1] + 6.5)
        far_hand = (far_sh[0] - 1.2 + swing, far_sh[1] + 12.5)

    # ── pintura, de trás pra frente ──
    blown = 1.0 if pose == "strike" else 0.0
    _mane(p, head, sweep={"windup": 2.0}.get(pose, 0.0) + leg_phase * 0.8,
          lift={"windup": 2.5}.get(pose, 0.0), blown=blown, chama=chama)

    # braço/perna distantes (em sombra)
    p.limb(far_sh, far_el, 4.0, 3.2, SK_DK)
    p.limb(far_el, far_hand, 3.2, 2.4, SK_DK)
    p.limb((hip[0] - 1.2, hip[1]), far_knee, 5.2, 3.8, SK_DK)
    p.limb(far_knee, far_ankle, 3.8, 2.8, SK_DK)
    p.poly([(far_ankle[0] - 1.8, foot_y - 2.2), (far_ankle[0] + 5.0, foot_y - 1),
            (far_ankle[0] + 5.5, foot_y + 1), (far_ankle[0] - 1.8, foot_y + 1)], SK_DK)

    # torso (tronco felino: ombros largos, cintura fina, quadril presente)
    p.poly([(chest[0] - 6.0, chest[1] - 3.5), (chest[0] + 6.2, chest[1] - 4.0),
            (hip[0] + 4.2, hip[1] - 2.0), (hip[0] + 5.4, hip[1] + 2.0),
            (hip[0] - 5.4, hip[1] + 2.0), (hip[0] - 4.2, hip[1] - 2.0)], SK)
    p.poly([(chest[0] - 6.0, chest[1] - 3.5), (chest[0] - 2.4, chest[1] - 3.8),
            (hip[0] - 2.0, hip[1] + 1.5), (hip[0] - 5.4, hip[1] + 1.5)], SK_DK)
    # faixa de jenipapo cruzando o peito (diagonal, assimétrica)
    p.limb((chest[0] - 5.2, chest[1] - 2.5), (hip[0] + 4.0, hip[1] - 3.0),
           2.2, 1.8, JENIPAPO)

    # saiote de folhas (pontas vivas, irregular)
    for i in range(7):
        bx = hip[0] - 5.4 + i * 1.9
        drop = 4.0 + _hash01(i * 1.3) * 3.0
        p.poly([(bx - 1.3, hip[1] + 0.5), (bx + 1.5, hip[1] + 0.5),
                (bx + 0.2, hip[1] + drop)], LF if i % 2 else LF_DK)
    p.limb((hip[0] - 5.2, hip[1] + 0.2), (hip[0] + 5.2, hip[1]), 1.8, 1.8, LF_DK)

    # perna próxima
    p.limb((hip[0] + 1.4, hip[1]), near_knee, 5.4, 4.0, SK)
    p.limb(near_knee, near_ankle, 4.0, 3.0, SK)
    p.poly([(near_ankle[0] - 1.8, foot_y - 2.2), (near_ankle[0] + 5.5, foot_y - 1),
            (near_ankle[0] + 6.0, foot_y + 1), (near_ankle[0] - 1.8, foot_y + 1)], SK)
    # sombra interna da perna próxima (volume)
    p.limb((hip[0] + 0.2, hip[1] + 1.0), (near_knee[0] - 1.2, near_knee[1]),
           1.6, 1.2, SK_DK)
    # cipó enrolado na canela próxima
    p.limb((near_knee[0] - 1.6, near_knee[1] + 2.5),
           (near_knee[0] + 2.2, near_knee[1] + 4.0), 1.2, 1.2, LF_DK)

    # peitoral de folhas (busto coberto, assimétrico)
    p.poly([(chest[0] - 5.8, chest[1] - 3.8), (chest[0] + 6.0, chest[1] - 4.2),
            (chest[0] + 4.8, chest[1] + 2.0), (chest[0] - 4.2, chest[1] + 2.3)], LF)
    p.poly([(chest[0] - 5.8, chest[1] - 3.8), (chest[0] - 1.2, chest[1] - 4.0),
            (chest[0] - 1.8, chest[1] + 2.1), (chest[0] - 4.2, chest[1] + 2.3)], LF_DK)
    # pontas de folha caindo do peitoral
    for i, ox in enumerate((-3.5, -0.5, 2.5)):
        p.poly([(chest[0] + ox - 1.0, chest[1] + 1.8),
                (chest[0] + ox + 1.2, chest[1] + 1.8),
                (chest[0] + ox + 0.1, chest[1] + 4.2)], LF_DK if i % 2 else LF)

    # ombreira de folhas SÓ no ombro próximo (assimetria de design)
    for i, (ox, oy, r) in enumerate([(-1.8, -1.5, 2.6), (0.8, -2.4, 2.8),
                                     (3.2, -1.2, 2.3)]):
        p.ellipse(near_sh[0] + ox, near_sh[1] + oy, r, r * 0.75,
                  LF if i % 2 else LF_DK)
    p.ellipse(near_sh[0] + 0.5, near_sh[1] - 3.0, 1.6, 1.0, LF_HL)

    # braço próximo (o do chicote)
    p.limb(near_sh, near_el, 4.2, 3.4, SK)
    p.limb(near_el, near_hand, 3.4, 2.6, SK)
    # bracelete de cipó no antebraço
    bm = ((near_el[0] + near_hand[0]) / 2, (near_el[1] + near_hand[1]) / 2)
    p.limb((bm[0] - 1.8, bm[1]), (bm[0] + 1.8, bm[1] + 0.5), 1.3, 1.3, LF_DK)

    # pescoço + cabeça
    p.limb((chest[0] + 0.5, chest[1] - 3.0), (head[0] - 0.5, head[1] + 4.0),
           3.4, 3.0, SK)
    _head(p, head[0], head[1], jaw_fwd=1.0 if pose == "strike" else 0.0)
    _crown(p, head, lift={"windup": 2.5}.get(pose, 0.0), blown=blown, chama=chama)

    # chicote por cima de tudo; brasas orbitando fecham a variante CHAMA
    _whip(p, near_hand, pose, chama=chama)
    if chama:
        _embers(p, head, pose, leg_phase)

    # ── render + pós ──
    img = p.render()
    _selout(img)
    _rim_light(img, head[0], head[1] - 8)
    _fire_dither(img)
    return img


POSES = [("player_idle.png", "idle", 0),
         ("player_walk_1.png", "walk", -1),
         ("player_walk_2.png", "walk", 1),
         ("player_windup.png", "windup", 0),
         ("player_strike.png", "strike", 0),
         ("player_recover.png", "recover", 0)]


def generate_all() -> None:
    for name, pose, phase in POSES:
        caipora(pose, phase).save(os.path.join(OUT, name))
        chama_name = name.replace(".png", "_chama.png")
        caipora(pose, phase, chama=True).save(os.path.join(OUT, chama_name))
    print("[gen_caipora] protagonista 64x64 premium gerada (6 frames + 6 CHAMA)")


if __name__ == "__main__":
    generate_all()
