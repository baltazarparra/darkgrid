#!/usr/bin/env python3
"""Gera sprites dos personagens na paleta de horror folk amazônico.

Pixel art autoral algorítmica (determinística), priorizando traços-assinatura
que tornam cada personagem identificável:

  Caipora  — guardiã da mata 64x64: cabelo de fogo, pele escura, corpo coberto
             de folhas/cipós, olhos brilhando, chicote de cipó, PÉS NORMAIS PRA
             FRENTE (o pé-pra-trás é do Curupira, parente — NÃO da Caipora),
             imponente (maior que o caçador)
  Caçador  — 48x48: chapéu, poncho, espingarda (inimigo humano predador)
  Bruxo    — 48x48: capuz, cajado com gema, olhos brilhando (boss)

Saída: player_idle/walk_1/walk_2.png (64x64), enemy_idle.png, boss_idle.png (48x48)
"""
import os
from PIL import Image

S = 48
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")

# ── Paleta ────────────────────────────────────────
SKIN = (122, 74, 46)
SKIN_DK = (84, 48, 28)
HAIR = (255, 107, 0)
HAIR_HOT = (255, 168, 56)
HAIR_DEEP = (188, 42, 0)
EYE = (255, 214, 84)
EARTH = (61, 31, 31)
EARTH_DK = (40, 20, 20)
LEAF = (34, 58, 30)
LEAF_DK = (20, 38, 20)

HAT = (38, 25, 16)
HAT_DK = (24, 15, 9)
HAT_BAND = (96, 30, 18)
PONCHO = (74, 42, 30)
PONCHO_DK = (50, 28, 20)
HUMAN_SKIN = (150, 112, 82)
HUMAN_SKIN_DK = (108, 78, 54)
GUN = (28, 24, 22)
GUN_HL = (70, 64, 58)

HOOD = (47, 16, 62)
HOOD_DK = (28, 9, 40)
ROBE = (33, 13, 48)
ROBE_DK = (20, 7, 30)
STAFF = (74, 44, 22)
GEM = (255, 107, 0)
GEM_HOT = (255, 190, 90)
GLOW_EYE = (255, 80, 30)


class C:
    def __init__(self, size=S):
        self.S = size
        self.im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        self.p = self.im.load()

    def px(self, x, y, c):
        if 0 <= x < self.S and 0 <= y < self.S:
            self.p[x, y] = (c[0], c[1], c[2], 255) if len(c) == 3 else c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c)

    def disc(self, cx, cy, r, c):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                    self.px(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        """Bresenham simples — usado pelo cipó/chicote."""
        dx = abs(x1 - x0)
        dy = abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx - dy
        while True:
            self.px(x0, y0, c)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x0 += sx
            if e2 < dx:
                err += dx
                y0 += sy

    def save(self, name):
        self.im.save(os.path.join(OUT, name))


def _leaf(c, x, y, col, shade):
    """Folha pequena (3x3) com sombra — usada na cobertura vegetal da Caipora."""
    c.rect(x, y + 1, x + 2, y + 1, col)
    c.px(x + 1, y, col)
    c.px(x + 1, y + 2, shade)
    c.px(x + 2, y + 2, shade)


def caipora(leg_phase=0):
    """Guardiã da mata, 64x64. leg_phase: 0 idle, -1/+1 passos.

    Imponente, coberta de folhas/cipós, cabelo de fogo, olhos brilhando, cipó
    na mão. PÉS NORMAIS PRA FRENTE (o pé-pra-trás é do Curupira, não da Caipora).
    """
    c = C(64)
    cx = 32
    # ── Juba/coroa de fogo (chamas subindo) ──
    c.rect(20, 8, 44, 22, HAIR_DEEP)
    c.disc(cx, 18, 13, HAIR_DEEP)
    for (x, top) in [(19, 6), (23, 1), (27, 4), (31, -1), (35, 3), (39, 1), (43, 6)]:
        c.rect(x, max(top, 0), x + 2, 18, HAIR)
    for (x, top) in [(24, 2), (29, 1), (33, 0), (37, 3), (41, 3)]:
        c.rect(x, max(top, 0), x + 1, top + 9, HAIR_HOT)
    c.rect(21, 16, 43, 21, HAIR)
    # ── Cabeça (pele escura, sombreada) ──
    c.disc(cx, 27, 9, SKIN)
    c.rect(23, 22, 41, 31, SKIN)
    c.rect(23, 22, 25, 31, SKIN_DK)       # lado em sombra
    c.rect(24, 31, 40, 33, SKIN_DK)       # queixo
    # sobrancelha pesada (encara, ameaça)
    c.rect(26, 24, 38, 25, SKIN_DK)
    # ── Olhos brilhando intensamente ──
    c.rect(27, 26, 30, 28, EYE)
    c.rect(34, 26, 37, 28, EYE)
    c.rect(28, 26, 29, 27, (255, 255, 210))   # núcleo branco-quente
    c.rect(35, 26, 36, 27, (255, 255, 210))
    c.px(27, 28, HAIR)                        # brilho derrama pra baixo
    c.px(37, 28, HAIR)
    # ── Torso (terra) ──
    c.rect(24, 33, 40, 50, EARTH)
    c.rect(24, 33, 26, 50, EARTH_DK)          # flanco em sombra
    c.rect(30, 34, 33, 49, EARTH_DK)          # vinco do peito
    # ── Cobertura de folhas/cipós (ombros, peito, cintura) ──
    for (lx_, ly_) in [(22, 33), (38, 33), (25, 33), (35, 33),   # ombros
                       (27, 39), (34, 39), (30, 42),             # peito
                       (24, 45), (28, 46), (32, 45), (36, 46), (40, 45)]:  # saiote
        _leaf(c, lx_, ly_, LEAF, LEAF_DK)
    c.rect(23, 48, 41, 50, LEAF_DK)           # barra do saiote de folhas
    # ── Braços ──
    c.rect(19, 34, 23, 47, SKIN_DK)           # braço esq (em sombra)
    c.rect(41, 34, 45, 47, SKIN)
    c.rect(41, 34, 42, 47, SKIN_DK)
    c.rect(19, 46, 23, 48, SKIN)              # mão esq
    c.rect(41, 46, 45, 49, SKIN)              # mão dir (segura o cipó)
    # ── Chicote de cipó (desce da mão direita, vivo) ──
    c.line(44, 48, 48, 52, EARTH_DK)
    c.line(48, 52, 45, 57, EARTH_DK)
    c.line(45, 57, 49, 60, EARTH_DK)
    c.line(44, 49, 47, 52, LEAF_DK)           # realce do cipó
    _leaf(c, 47, 54, LEAF, LEAF_DK)
    c.px(49, 60, LEAF)
    # ── Pernas ──
    lx = 27 + leg_phase * 2
    rx = 33 - leg_phase * 2
    c.rect(lx, 50, lx + 4, 59, SKIN)
    c.rect(rx, 50, rx + 4, 59, SKIN)
    c.rect(lx, 50, lx, 59, SKIN_DK)
    c.rect(rx, 50, rx, 59, SKIN_DK)
    # ── PÉS NORMAIS PRA FRENTE (planta no chão, dedos apontando pra frente/baixo) ──
    for fx in (lx, rx):
        c.rect(fx - 1, 59, fx + 5, 61, SKIN)      # pé apontando pra frente
        c.rect(fx - 1, 59, fx - 1, 61, SKIN_DK)   # calcanhar (atrás)
        c.px(fx + 2, 61, SKIN_DK)                 # separação dos dedos
        c.px(fx + 4, 61, SKIN_DK)
    return c


def hunter():
    """Caçador humano: chapéu, poncho, espingarda apontada."""
    c = C()
    # ── Chapéu de aba larga ──
    c.rect(14, 13, 33, 15, HAT_DK)      # aba
    c.rect(13, 14, 34, 15, HAT_DK)
    c.rect(18, 6, 29, 13, HAT)          # copa
    c.rect(18, 11, 29, 12, HAT_BAND)    # fita
    c.rect(18, 6, 19, 13, HAT_DK)
    # ── Rosto na sombra do chapéu ──
    c.rect(19, 16, 28, 23, HUMAN_SKIN)
    c.rect(19, 16, 28, 17, HUMAN_SKIN_DK)  # sombra da aba
    c.rect(20, 19, 21, 20, (20, 10, 8))    # olhos fundos
    c.rect(26, 19, 27, 20, (20, 10, 8))
    c.rect(22, 22, 25, 23, HUMAN_SKIN_DK)  # barba/queixo
    # ── Poncho ──
    c.rect(15, 24, 32, 38, PONCHO)
    c.rect(15, 24, 17, 38, PONCHO_DK)
    c.rect(30, 24, 32, 38, PONCHO_DK)
    c.rect(22, 24, 25, 38, PONCHO_DK)   # vinco central
    for y in range(38, 41):             # franja
        for x in range(15, 33, 2):
            c.px(x, y, PONCHO_DK)
    # ── Pernas/botas ──
    c.rect(19, 40, 22, 46, EARTH_DK)
    c.rect(25, 40, 28, 46, EARTH_DK)
    c.rect(18, 45, 23, 46, HAT_DK)
    c.rect(24, 45, 29, 46, HAT_DK)
    # ── Espingarda (atravessada, apontando p/ frente-baixo) ──
    c.rect(30, 27, 45, 29, GUN)         # cano
    c.rect(30, 26, 45, 26, GUN_HL)
    c.rect(27, 28, 33, 33, EARTH_DK)    # coronha
    c.px(45, 27, GUN_HL)
    # mãos segurando
    c.rect(30, 29, 32, 31, HUMAN_SKIN)
    c.rect(36, 28, 38, 30, HUMAN_SKIN)
    return c


def wizard():
    """Bruxo: capuz, túnica, cajado com gema, olhos brilhando no vazio."""
    c = C()
    # ── Cajado (à direita) ──
    c.rect(36, 10, 38, 46, STAFF)
    c.rect(36, 10, 36, 46, EARTH_DK)
    # gema âmbar no topo, brilhando
    c.disc(37, 8, 4, GEM)
    c.disc(37, 8, 2, GEM_HOT)
    c.px(36, 7, (255, 255, 220))
    # ── Capuz ──
    c.rect(16, 10, 31, 14, HOOD)
    c.disc(23, 14, 9, HOOD)
    c.rect(14, 14, 32, 26, HOOD)
    c.rect(14, 14, 16, 26, HOOD_DK)
    c.rect(30, 14, 32, 26, HOOD_DK)
    # pico do capuz
    c.rect(21, 6, 26, 12, HOOD)
    c.rect(22, 4, 24, 8, HOOD_DK)
    # ── Vazio do rosto + olhos brilhando ──
    c.rect(18, 17, 29, 25, (8, 3, 12))
    c.rect(20, 20, 22, 22, GLOW_EYE)
    c.rect(25, 20, 27, 22, GLOW_EYE)
    c.px(21, 21, (255, 180, 120))
    c.px(26, 21, (255, 180, 120))
    # ── Túnica longa ──
    c.rect(13, 26, 33, 46, ROBE)
    c.rect(13, 26, 15, 46, ROBE_DK)
    c.rect(31, 26, 33, 46, ROBE_DK)
    c.rect(22, 26, 24, 46, ROBE_DK)     # dobra central
    # mangas/braço segurando o cajado
    c.rect(30, 28, 37, 32, ROBE)
    c.rect(30, 31, 38, 33, HOOD_DK)
    # barra esfarrapada
    for x in range(13, 34, 3):
        c.px(x, 46, ROBE_DK)
        c.px(x + 1, 45, ROBE_DK)
    # símbolo ritual no peito (pentagrama simplificado em sangue)
    c.rect(22, 34, 24, 40, (90, 0, 0))
    c.rect(20, 36, 26, 37, (90, 0, 0))
    return c


if __name__ == "__main__":
    caipora(0).save("player_idle.png")
    caipora(-1).save("player_walk_1.png")
    caipora(1).save("player_walk_2.png")
    hunter().save("enemy_idle.png")
    wizard().save("boss_idle.png")
    print("[gen_chars] caipora (64x64) + caçador + bruxo (48x48) gerados")
