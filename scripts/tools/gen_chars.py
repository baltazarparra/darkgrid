#!/usr/bin/env python3
"""Gera sprites dos personagens na paleta de horror folk amazônico.

Pixel art autoral algorítmica (determinística), priorizando traços-assinatura
que tornam cada personagem identificável:

  Caipora  — PROTAGONISTA: gerada por gen_caipora.py (pipeline premium próprio,
             ver docs/CONCEITO-protagonista.md). Este módulo apenas delega.
  Caçador & Bruxo — INIMIGOS COMUNS: gerados por gen_inimigos.py (pipeline
             premium 112px arena + 56px mapa, ver docs/CONCEITO-inimigos.md). Delega.
  Curupira — BOSS P3: gerado por gen_bosses.py (pipeline premium 128px arena +
             48px mapa, ver docs/CONCEITO-curupira.md). Delega.
  Boitatá — BOSS P2: gerado por gen_boitata.py (pipeline premium 160x128). Delega.
  Caçador c/ machados — 48x48: capuz, manto, dois machados, olhos brilhando (boss base)
  Mula sem Cabeça     — 192x192 via gen_mula.py: sem cabeça, jato de fogo no toco,
                        ferraduras de ferro, arreio amaldiçoado (boss da Fase 1)

Saída: player_* via gen_caipora (96x96), enemy/bruxo_* via gen_inimigos
       (112x112 + 56x56 map variants), curupira_* via gen_bosses (128x128 + 48x48),
       boitata_* via gen_boitata (160x128), mula_idle/windup.png (192x192),
       boss/saci/jesuita_idle.png (48x48 legado).
"""
import os
from PIL import Image

import gen_caipora
import gen_inimigos
import gen_mula
import gen_bosses
import gen_boitata

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

HOOD = (47, 16, 62)
HOOD_DK = (28, 9, 40)
ROBE = (33, 13, 48)
ROBE_DK = (20, 7, 30)
STAFF = (74, 44, 22)
GLOW_EYE = (255, 80, 30)
AXE_HAFT = (58, 34, 18)        # cabo de madeira escura
AXE_HAFT_DK = (38, 22, 12)
AXE_STEEL = (60, 56, 52)       # lâmina de aço sombrio
AXE_EDGE = (140, 138, 146)     # fio reluzente da lâmina
STRAP = (96, 30, 18)           # correia/couro cruzada do boss


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

    def shift(self, dx, dy):
        """Desloca o desenho inteiro (linguagem corporal: agachar, avançar)."""
        im2 = Image.new("RGBA", (self.S, self.S), (0, 0, 0, 0))
        im2.paste(self.im, (dx, dy))
        self.im = im2
        self.p = im2.load()


def _axe(c, haft_x, blade_side, dy=0):
    """Machado de cabo longo. haft_x = coluna do cabo; blade_side -1 esq / +1 dir;
    dy desloca o machado inteiro (erguer no windup).

    Lâmina larga no topo (single-bit) voltada pra fora, fio reluzente — leitura
    clara de 'machado' e separa o boss do caçador-espingarda.
    """
    # ── Cabo (vertical, madeira escura) ──
    c.rect(haft_x, 9 + dy, haft_x + 1, 41 + dy, AXE_HAFT)
    c.rect(haft_x, 9 + dy, haft_x, 41 + dy, AXE_HAFT_DK)
    # ── Cabeça da lâmina (no topo do cabo, voltada pra fora) ──
    if blade_side > 0:
        bx0, bx1 = haft_x + 2, haft_x + 7        # cresce pra direita
        c.rect(bx0, 7 + dy, bx1, 16 + dy, AXE_STEEL)
        c.rect(bx0, 9 + dy, bx1 + 1, 14 + dy, AXE_STEEL)   # barriga da lâmina
        c.rect(bx1 + 1, 9 + dy, bx1 + 1, 14 + dy, AXE_EDGE)
        c.rect(bx0, 7 + dy, bx0, 16 + dy, AXE_EDGE)        # topo do gume
    else:
        bx0, bx1 = haft_x - 5, haft_x            # cresce pra esquerda
        c.rect(bx0, 7 + dy, bx1, 16 + dy, AXE_STEEL)
        c.rect(bx0 - 1, 9 + dy, bx1, 14 + dy, AXE_STEEL)   # barriga da lâmina
        c.rect(bx0 - 1, 9 + dy, bx0 - 1, 14 + dy, AXE_EDGE)
        c.rect(bx1, 7 + dy, bx1, 16 + dy, AXE_EDGE)        # topo do gume


def axe_hunter(pose="idle"):
    """Caçador com machados (boss): capuz, manto, dois machados, olhos no vazio.

    pose "windup": machados içados acima da cabeça — o golpe duplo vem aí.

    Predador humano amaldiçoado — silhueta imponente, encapuzado na sombra,
    empunhando um machado em cada mão. A aura de sombra fica a cargo do boss.gd.
    """
    c = C()
    # ── Machados (um de cada lado; içados no windup) ──
    axe_dy = -5 if pose == "windup" else 0
    _axe(c, 9, -1, axe_dy)
    _axe(c, 38, +1, axe_dy)
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
    # ── Manto longo ──
    c.rect(13, 26, 33, 46, ROBE)
    c.rect(13, 26, 15, 46, ROBE_DK)
    c.rect(31, 26, 33, 46, ROBE_DK)
    c.rect(22, 26, 24, 46, ROBE_DK)     # dobra central
    # ── Braços estendidos segurando os machados ──
    c.rect(10, 28, 16, 31, ROBE)        # braço esq
    c.rect(9, 30, 12, 33, HOOD_DK)      # mão esq no cabo
    c.rect(30, 28, 38, 31, ROBE)        # braço dir
    c.rect(36, 30, 39, 33, HOOD_DK)     # mão dir no cabo
    # barra esfarrapada
    for x in range(13, 34, 3):
        c.px(x, 46, ROBE_DK)
        c.px(x + 1, 45, ROBE_DK)
    # ── Correia de couro cruzada no peito (caçador, sem tema mágico) ──
    c.line(17, 28, 28, 38, STRAP)
    c.line(17, 29, 28, 39, AXE_HAFT_DK)
    if pose == "windup":
        c.shift(0, 1)   # afunda na base antes de descer os machados
    return c


def saci():
    """Saci Pererê — boss final, 48x48. UMA perna só (saltando), carapuça vermelha,
    cachimbo fumegante, corpo carbonizado consumido pelo fogo (brasas, olhos em brasa)."""
    c = C()
    SKIN     = (40, 27, 25)        # pele carbonizada
    SKIN_DK  = (22, 14, 13)
    CAP      = (200, 30, 20)       # carapuça vermelha (assinatura)
    CAP_HOT  = (255, 84, 40)
    CAP_DK   = (130, 14, 8)
    EMBER    = (255, 120, 30)      # brasa viva (rachaduras / olhos)
    EMBER_HOT= (255, 196, 90)
    PIPE     = (92, 56, 28)        # cabo do cachimbo (madeira)
    PIPE_BOWL= (44, 30, 20)        # fornilho
    PIPE_FIRE= (255, 140, 40)

    # ── Carapuça vermelha pontuda (tomba pra direita) ──
    c.rect(16, 12, 31, 14, CAP)       # aba/base
    c.rect(17, 9, 30, 12, CAP)
    c.rect(18, 6, 29, 9, CAP)
    c.rect(20, 3, 29, 6, CAP)
    c.rect(26, 1, 32, 4, CAP)         # ponta tombando pra frente
    c.rect(18, 7, 20, 13, CAP_HOT)    # brilho à esquerda
    c.rect(28, 6, 30, 13, CAP_DK)     # sombra à direita

    # ── Cabeça (carbonizada) ──
    c.disc(24, 19, 7, SKIN)
    c.rect(18, 15, 30, 24, SKIN)
    c.rect(18, 15, 20, 24, SKIN_DK)
    # olhos em brasa
    c.rect(20, 18, 22, 20, EMBER)
    c.rect(26, 18, 28, 20, EMBER)
    c.px(21, 19, EMBER_HOT)
    c.px(27, 19, EMBER_HOT)
    # rachaduras incandescentes no rosto
    c.px(24, 16, EMBER)
    c.px(23, 22, EMBER)

    # ── Cachimbo fumegante (sai da boca pra direita) ──
    c.rect(23, 23, 27, 24, SKIN_DK)   # boca
    c.rect(28, 23, 33, 24, PIPE)      # cabo
    c.rect(33, 21, 35, 24, PIPE_BOWL) # fornilho
    c.px(34, 21, PIPE_FIRE)           # brasa no fornilho
    c.px(33, 21, PIPE_FIRE)
    # fumaça subindo (semi-transparente)
    c.px(35, 19, (150, 140, 140, 160))
    c.px(36, 17, (150, 140, 140, 120))
    c.px(35, 15, (150, 140, 140, 90))

    # ── Tronco pequeno e encurvado ──
    c.rect(19, 25, 29, 35, SKIN)
    c.rect(19, 25, 20, 35, SKIN_DK)
    c.rect(28, 25, 29, 35, SKIN_DK)
    # brasas pelo corpo (consumido pelo fogo)
    c.px(23, 29, EMBER)
    c.px(25, 31, EMBER)
    c.px(22, 33, EMBER_HOT)

    # ── Braços (esq. abaixado, dir. levando ao cachimbo) ──
    c.rect(14, 26, 19, 30, SKIN_DK)
    c.rect(13, 29, 16, 32, SKIN_DK)   # mão esq
    c.rect(29, 27, 35, 30, SKIN)
    c.rect(34, 28, 37, 31, SKIN)      # mão dir (no cachimbo)

    # ── UMA PERNA SÓ (centro, saltando) ──
    c.rect(22, 35, 26, 45, SKIN)
    c.rect(22, 35, 22, 45, SKIN_DK)
    c.px(24, 40, EMBER)               # rachadura na perna
    # pé
    c.rect(20, 45, 28, 47, SKIN)
    c.rect(20, 45, 28, 45, SKIN_DK)
    c.px(21, 47, SKIN_DK)
    c.px(24, 47, SKIN_DK)
    c.px(27, 47, SKIN_DK)

    return c


def jesuita():
    """Jesuíta Bandeirante Catequizador — boss FINAL (Fase 5), 48x48.

    Sincretismo de horror colonial: BATINA PRETA de jesuíta sob GIBÃO DE COURO e
    MORRIÃO (capacete de aço) de bandeirante; numa mão um ESPELHO de moldura
    dourada (a isca de conversão), na outra um ASPERSÓRIO pingando ÁGUA BENTA;
    rosto esquálido de zelote, olhos fundos em brasa dourada. CRUZ de ouro
    litúrgico no peito; barra da batina manchada de sangue. O sagrado colonial
    como o invasor — fim da linha da Caipora.
    """
    c = C()
    CASSOCK    = (18, 16, 22)        # batina preta (tom azulado)
    CASSOCK_HL = (40, 36, 48)        # realce de prega
    LEATHER    = (60, 39, 20)        # gibão de couro
    LEATHER_DK = (36, 22, 11)
    STEEL      = (120, 122, 134)     # morrião (aço)
    STEEL_HL   = (190, 194, 208)
    STEEL_DK   = (68, 70, 82)
    SK         = (150, 138, 120)     # pele pálida/esquálida
    SK_DK      = (102, 92, 78)
    EYE        = (255, 196, 90)      # olho em brasa dourada (fanático)
    EYE_CORE   = (255, 244, 205)
    GOLD       = (212, 180, 98)      # ouro litúrgico (cruz/moldura)
    GOLD_DK    = (150, 120, 50)
    MIRROR     = (186, 206, 214)     # superfície do espelho
    MIRROR_HL  = (245, 250, 255)
    HOLY       = (200, 222, 236)     # gota de água benta
    COLLAR     = (222, 222, 212)     # colarinho clerical branco
    BLOOD      = (110, 14, 10)

    # ── Morrião (capacete de bandeirante) com crista ──
    c.disc(24, 12, 7, STEEL)
    c.rect(17, 12, 31, 15, STEEL)        # base do capacete
    c.rect(17, 12, 18, 15, STEEL_DK)     # sombra à esquerda
    c.rect(29, 12, 31, 15, STEEL_DK)
    c.rect(20, 5, 28, 8, STEEL_HL)       # brilho do domo
    c.rect(23, 2, 25, 11, STEEL_DK)      # crista (comb)
    c.rect(24, 2, 24, 11, STEEL_HL)
    c.rect(13, 14, 17, 15, STEEL); c.px(12, 15, STEEL_DK)   # aba pontuda (frente)
    c.rect(31, 14, 35, 15, STEEL); c.px(35, 15, STEEL_DK)   # aba pontuda (trás)

    # ── Rosto esquálido (pálido, em sombra) ──
    c.rect(19, 15, 29, 25, SK)
    c.disc(24, 21, 5, SK)
    c.rect(19, 15, 21, 25, SK_DK)        # lado em sombra
    c.rect(20, 24, 28, 26, SK_DK)        # mandíbula encovada
    c.rect(20, 18, 22, 18, SK_DK)        # órbitas fundas
    c.rect(26, 18, 28, 18, SK_DK)
    c.rect(20, 19, 22, 21, EYE); c.px(21, 20, EYE_CORE)     # olhos em brasa
    c.rect(26, 19, 28, 21, EYE); c.px(27, 20, EYE_CORE)
    c.px(24, 22, SK_DK)                  # nariz adunco
    c.rect(22, 25, 26, 25, SK_DK)        # boca cerrada

    # ── Colarinho clerical branco ──
    c.rect(21, 26, 27, 28, COLLAR)
    c.px(24, 27, CASSOCK)                # fenda do colarinho

    # ── Batina preta (torso) sob gibão de couro ──
    c.rect(18, 28, 30, 44, CASSOCK)
    c.rect(29, 28, 30, 44, CASSOCK_HL)   # realce de prega
    c.rect(23, 29, 25, 44, CASSOCK_HL)   # prega central
    c.rect(18, 28, 30, 33, LEATHER)      # gibão por cima (peito/ombros)
    c.rect(18, 28, 19, 33, LEATHER_DK)
    c.rect(20, 28, 28, 29, LEATHER_DK)   # gola do gibão
    c.rect(23, 31, 25, 38, GOLD)         # cruz de ouro no peito
    c.rect(21, 33, 27, 35, GOLD)
    c.px(23, 31, GOLD_DK); c.px(25, 38, GOLD_DK)
    c.rect(18, 42, 30, 44, BLOOD)        # barra manchada de sangue
    c.px(20, 43, (150, 24, 18)); c.px(27, 43, (150, 24, 18))

    # ── Braço/mão esquerda: ESPELHO (isca de conversão) ──
    c.rect(13, 30, 18, 33, CASSOCK)      # braço esq
    c.rect(11, 32, 15, 35, SK)           # mão
    c.rect(8, 24, 14, 33, GOLD_DK)       # moldura dourada
    c.rect(9, 25, 13, 32, MIRROR)        # vidro
    c.line(9, 31, 12, 26, MIRROR_HL)     # glint diagonal
    c.px(10, 27, MIRROR_HL)
    c.rect(11, 33, 13, 36, GOLD)         # cabo do espelho

    # ── Braço/mão direita: ASPERSÓRIO (água benta pingando) ──
    c.rect(30, 30, 35, 33, CASSOCK)      # braço dir
    c.rect(34, 32, 37, 35, SK)           # mão
    c.rect(37, 22, 38, 33, GOLD_DK)      # haste
    c.disc(38, 21, 3, STEEL)             # bola perfurada
    c.px(37, 20, STEEL_HL); c.px(39, 22, STEEL_DK)
    c.px(36, 19, HOLY); c.px(40, 19, HOLY); c.px(38, 17, HOLY)  # gotas espirrando
    c.px(38, 26, HOLY); c.px(38, 29, HOLY); c.px(37, 32, HOLY)  # gotas pingando

    # ── Pernas / botas de bandeirante ──
    c.rect(20, 44, 23, 47, CASSOCK)
    c.rect(25, 44, 28, 47, CASSOCK)
    c.rect(19, 46, 24, 47, LEATHER_DK)   # bota esq
    c.rect(24, 46, 29, 47, LEATHER_DK)   # bota dir
    return c


def mula():
    """Mula sem Cabeça — boss da Fase 1, 48x48, perfil voltado pra direita.

    Assinaturas folclóricas: NÃO TEM CABEÇA — no lugar do pescoço, um TOCO
    DECEPADO de onde JORRA FOGO (a 'cabeça' é uma coluna de chamas). Galopa com
    FERRADURAS DE FERRO que reluzem (faísca na noite). Carrega os restos de uma
    SELA/ARREIO amaldiçoado (vermelho-sangue). Crina e cauda terminam em brasa.
    O inimigo mais detalhado do elenco — primeiro boss, primeira impressão.
    """
    c = C()
    # ── Cores ──
    FUR     = (52, 30, 26)        # pelo escuro (deriva da terra)
    FUR_DK  = (30, 17, 15)        # sombra do corpo / perna distante
    FUR_HL  = (84, 52, 44)        # realce de músculo no dorso
    HOOF    = (16, 10, 9)         # casco
    SHOE    = (122, 124, 138)     # ferradura de ferro
    SHOE_HL = (188, 192, 206)     # brilho do ferro (faísca)
    WOUND   = (74, 8, 8)          # carne do toco decepado
    F_DEEP  = (188, 42, 0)        # base da chama
    F_MID   = (255, 107, 0)
    F_HOT   = (255, 168, 56)
    F_CORE  = (255, 240, 200)     # branco-quente
    SADDLE    = (40, 22, 14)      # arreio amaldiçoado (couro escuro)
    SADDLE_HL = (150, 24, 16)     # fita/fivela vermelho-sangue

    def _leg(x, col, dk, shiny):
        # Perna + casco + ferradura de ferro. shiny=False empurra a perna distante.
        c.rect(x, 29, x + 2, 42, col)
        c.rect(x, 29, x, 42, dk)              # aresta em sombra
        c.rect(x - 1, 40, x + 3, 42, col)     # boleto (engrossa embaixo)
        c.rect(x - 1, 42, x + 3, 44, HOOF)    # casco
        c.rect(x - 1, 44, x + 3, 45, SHOE)    # ferradura
        if shiny:
            c.px(x, 45, SHOE_HL)
            c.px(x + 2, 45, SHOE_HL)

    # ── Pernas distantes primeiro (atrás, mais escuras) ──
    _leg(15, FUR_DK, (22, 12, 11), False)     # traseira distante
    _leg(31, FUR_DK, (22, 12, 11), False)     # dianteira distante

    # ── Cauda (jorra do quadril, esfarrapada, ponta em brasa) ──
    c.line(11, 22, 6, 29, FUR_DK)
    c.line(10, 23, 5, 34, FUR_DK)
    c.line(10, 24, 7, 39, FUR_DK)
    c.px(5, 34, F_MID)
    c.px(7, 39, F_DEEP)

    # ── Tronco (barril fundo de peito) ──
    c.rect(12, 21, 33, 30, FUR)
    c.disc(13, 25, 5, FUR)                    # garupa (esquerda)
    c.disc(33, 25, 5, FUR)                    # peito/paleta (direita)
    c.rect(13, 20, 32, 21, FUR_HL)            # realce do dorso
    c.rect(14, 29, 31, 31, FUR_DK)            # sombra do ventre
    # ── Volume muscular ──
    c.line(27, 22, 28, 29, FUR_DK)            # vinco do ombro (separa peito do barril)
    c.line(18, 22, 17, 29, FUR_DK)            # vinco da garupa (separa anca do barril)
    c.rect(11, 21, 15, 22, FUR_HL)            # alto da anca iluminado

    # ── Arreio amaldiçoado (sela + barrigueira) ──
    c.rect(17, 18, 27, 21, SADDLE)            # sela no dorso
    c.rect(17, 18, 27, 18, SADDLE_HL)         # debrum vermelho-sangue
    c.rect(22, 21, 24, 31, SADDLE)            # barrigueira descendo o flanco
    c.px(22, 22, SADDLE_HL)                   # fivela

    # ── Pescoço subindo pro toco (sobe à direita) ──
    for (x0, y, x1) in [(30, 20, 36), (31, 18, 37), (32, 16, 37), (33, 14, 38)]:
        c.rect(x0, y, x1, y + 1, FUR)
        c.px(x0, y, FUR_DK)                   # crista do pescoço em sombra
    c.px(30, 18, F_DEEP)                      # crina em brasa
    c.px(31, 20, F_MID)

    # ── TOCO DECEPADO (carne crua) ──
    c.rect(33, 13, 38, 14, WOUND)

    # ── JATO DE FOGO no lugar da cabeça (jorra do toco pra cima) ──
    c.rect(33, 4, 39, 13, F_DEEP)
    c.disc(36, 9, 4, F_DEEP)
    for (x, top) in [(33, 6), (35, 2), (37, 4), (39, 7)]:
        c.rect(x, top, x + 1, 12, F_MID)
    for (x, top) in [(34, 4), (36, 1), (38, 5)]:
        c.rect(x, top, x, top + 7, F_HOT)
    c.rect(36, 5, 36, 11, F_CORE)             # núcleo branco-quente
    c.px(35, 8, F_CORE)
    c.px(37, 9, F_CORE)
    c.px(40, 3, F_HOT)                        # brasas soltas no ar
    c.px(32, 5, F_MID)
    c.px(41, 8, F_DEEP)

    # ── Luz do fogo lambendo o pelo (liga as chamas ao corpo) ──
    FIRE_LIT = (150, 66, 26)
    for (x, y) in [(38, 14), (37, 15), (36, 16), (35, 18), (34, 20),
                   (35, 22), (36, 23), (33, 21), (32, 20)]:
        c.px(x, y, FIRE_LIT)

    # ── Pernas próximas (na frente, ferro reluzindo) ──
    _leg(11, FUR, FUR_DK, True)               # traseira próxima
    _leg(28, FUR, FUR_DK, True)               # dianteira próxima

    return c


if __name__ == "__main__":
    gen_caipora.generate_all()   # protagonista (pipeline premium próprio)
    gen_inimigos.generate_all()  # caçador/bruxo (pipeline premium 112px+56px)
    gen_bosses.generate_all()    # curupira (pipeline premium 128px+48px)
    gen_boitata.generate_all()   # boitatá (pipeline premium 160x128)
    axe_hunter().save("boss_idle.png")
    axe_hunter("windup").save("boss_windup.png")
    saci().save("saci_idle.png")
    gen_mula.generate_all()
    jesuita().save("jesuita_idle.png")
    print("[gen_chars] caipora (via gen_caipora) + caçador/bruxo (via gen_inimigos) + curupira (via gen_bosses) + boitatá (via gen_boitata) + caçador-de-machados + saci + mula-sem-cabeça (via gen_mula) + jesuíta-bandeirante gerados")
