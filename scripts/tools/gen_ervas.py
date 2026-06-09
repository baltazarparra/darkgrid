"""Gera os sprites das ervas do cachimbo + o cachimbo (Acampamento).

Cada aprimoramento da Caipora é uma ERVA que ela põe no cachimbo para fumar.
Duas trilhas:
  - Fúria (dano): acentos âmbar/sangue, brasa acesa.
  - Cura (HP):    acentos de musgo/verde, seiva.

Saídas em assets/sprites/ (32×32 cada erva; cachimbo 48×32):
  erva_folha_brasa.png      erva_seiva_mae.png
  erva_cinza_viva.png       erva_casca_boa.png
  erva_raiz_de_ira.png      erva_folha_de_sangue.png
  erva_breu_ancestral.png   erva_coracao_de_cerne.png
  cachimbo.png

Pipeline stdlib puro (struct/zlib), determinístico, na paleta de constants.gd —
espelha gen_weapon_forca3.py (zero dependência externa, pixel-art NEAREST).
"""
import struct, zlib, os, math

ICON = 32  # ervas: tamanho de item (32×32)


# ─── PNG encode (idêntico a gen_weapon_forca3.py) ─────────────────────────────
def png_chunk(tag: bytes, data: bytes) -> bytes:
    c = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", c)


def encode_png(pixels: list[list[tuple[int, int, int, int]]]) -> bytes:
    h, w = len(pixels), len(pixels[0])
    raw = b""
    for row in pixels:
        raw += b"\x00"
        for r, g, b, a in row:
            raw += bytes([r, g, b, a])
    ihdr = struct.pack(">II", w, h) + bytes([8, 6, 0, 0, 0])  # RGBA, 8-bit
    compressed = zlib.compress(raw, 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", compressed)
        + png_chunk(b"IEND", b"")
    )


# ─── Paleta (r,g,b,a) — espelha constants.gd / gen_tiles / gen_weapon ─────────
TRANSP      = (  0,   0,   0,   0)
# Verde folha (cura)
LEAF_DARK   = ( 20,  38,  20, 255)
LEAF_MID    = ( 34,  58,  30, 255)
LEAF_LIGHT  = ( 56,  92,  44, 255)
MOSS_LIGHT  = ( 40,  66,  36, 255)
VEIN_GREEN  = ( 24,  44,  24, 255)
# Madeira / casca / raiz (fúria t3 + cura t2/t4 + cachimbo)
WOOD_DARK   = ( 41,  18,   3, 255)
WOOD_MID    = ( 82,  43,  10, 255)
WOOD_LIGHT  = (163,  94,  36, 255)
WOOD_HI     = (212, 152,  80, 255)
BARK_DARK   = ( 25,  15,   5, 255)
BARK_MID    = ( 46,  28,  13, 255)
BARK_HI     = ( 92,  62,  30, 255)
# Sangue / brasa / âmbar (fúria + folha-de-sangue)
BLOOD       = (139,   0,   0, 255)
BLOOD_DARK  = ( 74,   0,   0, 255)
AMBER       = (255, 107,   0, 255)
EMBER_HOT   = (255, 180,  60, 255)
ASH         = ( 88,  82,  74, 255)
ASH_LIGHT   = (140, 132, 120, 255)
# Cinza/breu escuro
SOOT        = ( 28,  24,  22, 255)


def blank(w: int = ICON, h: int = ICON) -> list[list[tuple]]:
    return [[TRANSP] * w for _ in range(h)]


def put(g, x: int, y: int, col) -> None:
    if 0 <= y < len(g) and 0 <= x < len(g[0]):
        g[y][x] = col


# ─── Primitivas ───────────────────────────────────────────────────────────────
def leaf(g, cx, cy, hw, hh, body, edge, vein, tip_dark=True) -> None:
    """Folha amêndoa apontada para cima, com nervura central e borda escura."""
    for y in range(cy - hh, cy + hh + 1):
        t = (y - cy) / float(hh)            # -1 topo .. +1 base
        # largura: elipse, afinando mais no topo (ponta)
        w = hw * math.sqrt(max(0.0, 1.0 - t * t))
        if t < -0.4:                        # ponta superior afilada
            w *= (1.0 + t) / 0.6
        w = int(round(w))
        if w <= 0:
            if -1.0 <= t <= -0.4:
                put(g, cx, y, edge)         # ponta de 1px
            continue
        for x in range(cx - w, cx + w + 1):
            d = abs(x - cx) / float(max(1, w))
            if x == cx - w or x == cx + w:
                col = edge
            elif x == cx:
                col = vein                  # nervura central
            elif d > 0.72:
                col = edge
            elif d < 0.34:
                col = body[2] if len(body) == 3 else body  # highlight
            else:
                col = body[1] if len(body) == 3 else body
            put(g, x, y, col)


def stem(g, x0, y0, x1, y1, col, col_dark=None) -> None:
    """Linha (caule/galho) grossa de 2px com lado escuro."""
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(steps + 1):
        x = round(x0 + (x1 - x0) * i / steps)
        y = round(y0 + (y1 - y0) * i / steps)
        put(g, x, y, col)
        put(g, x + 1, y, col_dark or col)


def blob(g, cx, cy, r, col, edge=None) -> None:
    """Disco preenchido. Se col is None, desenha só o contorno (precisa de edge)."""
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 > r * r:
                continue
            on_edge = d2 > (r - 1) * (r - 1)
            if edge and on_edge:
                put(g, x, y, edge)
            elif col is not None:
                put(g, x, y, col)


def ember(g, cx, cy, r=2) -> None:
    """Brasa acesa: miolo quente + halo âmbar."""
    blob(g, cx, cy, r + 1, AMBER)
    blob(g, cx, cy, r, EMBER_HOT)
    put(g, cx, cy, (255, 230, 160, 255))


def smoke(g, cx, cy) -> None:
    """Fiapo de fumaça subindo (poucos px translúcidos)."""
    wisp = (180, 170, 160, 90)
    for i, dy in enumerate(range(0, -7, -1)):
        dx = int(round(1.6 * math.sin(i * 0.9)))
        put(g, cx + dx, cy + dy, wisp)


# ─── FÚRIA (dano) ──────────────────────────────────────────────────────────────
def folha_brasa():
    """T1: folha verde-âmbar com a ponta em brasa."""
    g = blank()
    stem(g, 16, 30, 16, 19, WOOD_MID, WOOD_DARK)
    leaf(g, 16, 14, 7, 11, (LEAF_DARK, LEAF_MID, LEAF_LIGHT), LEAF_DARK, VEIN_GREEN)
    # borda superior pegando fogo
    for x in range(12, 21):
        put(g, x, 5 + ((x % 2)), AMBER)
    ember(g, 16, 5, 1)
    return g


def cinza_viva():
    """T2: maço de folhas com cinzas e brasa central."""
    g = blank()
    stem(g, 16, 31, 16, 22, WOOD_MID, WOOD_DARK)
    leaf(g, 11, 18, 5, 9, (LEAF_DARK, LEAF_MID, LEAF_LIGHT), LEAF_DARK, VEIN_GREEN)
    leaf(g, 21, 18, 5, 9, (LEAF_DARK, LEAF_MID, LEAF_LIGHT), LEAF_DARK, VEIN_GREEN)
    leaf(g, 16, 14, 6, 11, (LEAF_DARK, LEAF_MID, LEAF_LIGHT), LEAF_DARK, VEIN_GREEN)
    # cinzas caindo
    for (x, y) in [(9, 24), (23, 25), (12, 27), (20, 28), (16, 29)]:
        put(g, x, y, ASH)
        put(g, x + 1, y, ASH_LIGHT)
    ember(g, 16, 7, 2)
    return g


def raiz_de_ira():
    """T3: raiz/galho retorcido com veios de sangue e brasa."""
    g = blank()
    # tronco vertical retorcido
    pts = [(16, 30), (15, 26), (17, 22), (15, 18), (17, 14), (16, 10)]
    for i in range(len(pts) - 1):
        stem(g, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], WOOD_MID, WOOD_DARK)
    # raízes laterais
    stem(g, 16, 27, 10, 30, WOOD_DARK)
    stem(g, 16, 27, 23, 31, WOOD_DARK)
    stem(g, 16, 13, 22, 9, BARK_MID, BARK_DARK)
    stem(g, 16, 17, 9, 14, BARK_MID, BARK_DARK)
    # veios de sangue pulsando na madeira
    for (x, y) in [(16, 24), (16, 20), (16, 16), (22, 10), (10, 15)]:
        put(g, x, y, BLOOD)
        put(g, x, y + 1, BLOOD_DARK)
    ember(g, 16, 8, 2)
    smoke(g, 16, 6)
    return g


def breu_ancestral():
    """T4: maço amarrado, denso e aceso — fogo forte + fumaça."""
    g = blank()
    # maço escuro (breu) amarrado
    for y in range(15, 30):
        w = 6 - abs(y - 22) // 3
        for x in range(16 - w, 16 + w + 1):
            col = SOOT if (x + y) % 3 else BARK_DARK
            put(g, x, y, col)
    # amarra de fibra
    for x in range(10, 23):
        put(g, x, 23, BARK_HI)
        put(g, x, 24, BARK_DARK)
    # topo em chamas
    flame = [(13, 13), (19, 13), (16, 9), (14, 11), (18, 11), (16, 6)]
    for (x, y) in flame:
        blob(g, x, y, 2, AMBER)
    blob(g, 16, 11, 3, AMBER)
    blob(g, 16, 12, 2, EMBER_HOT)
    ember(g, 16, 14, 2)
    smoke(g, 15, 5)
    smoke(g, 18, 7)
    return g


# ─── CURA (HP) ───────────────────────────────────────────────────────────────
def seiva_mae():
    """T1: folha verde com gota de seiva pingando."""
    g = blank()
    stem(g, 16, 30, 16, 19, MOSS_LIGHT, LEAF_DARK)
    leaf(g, 16, 13, 8, 11, (LEAF_DARK, LEAF_MID, LEAF_LIGHT), LEAF_DARK, VEIN_GREEN)
    # gota de seiva na ponta da folha
    put(g, 16, 25, LEAF_LIGHT)
    blob(g, 16, 27, 1, MOSS_LIGHT)
    put(g, 16, 27, (120, 180, 110, 255))
    return g


def casca_boa():
    """T2: lasca de casca com musgo curativo."""
    g = blank()
    for y in range(7, 28):
        w = 5 if 11 < y < 24 else 4
        for x in range(16 - w, 16 + w + 1):
            if x <= 16 - w + 1:
                col = BARK_DARK
            elif x >= 16 + w - 1:
                col = WOOD_DARK
            elif (x + y) % 4 == 0:
                col = WOOD_LIGHT
            else:
                col = BARK_MID
            put(g, x, y, col)
    # musgo verde grudado
    for (x, y) in [(13, 10), (19, 13), (12, 18), (20, 21), (15, 24), (18, 9)]:
        put(g, x, y, LEAF_MID)
        put(g, x + 1, y, MOSS_LIGHT)
    return g


def folha_de_sangue():
    """T3: folha com nervuras de sangue (horror) — vital e doente."""
    g = blank()
    stem(g, 16, 31, 16, 20, BLOOD_DARK, WOOD_DARK)
    leaf(g, 16, 13, 9, 12, (LEAF_DARK, LEAF_MID, LEAF_LIGHT), LEAF_DARK, BLOOD_DARK)
    # nervuras de sangue irradiando do talo
    veins = [(-1, -1), (1, -1), (-1, 1), (1, 1), (0, -1)]
    for (dx, dy) in veins:
        for k in range(1, 7):
            put(g, 16 + dx * k, 13 + dy * k, BLOOD if k % 2 else BLOOD_DARK)
    put(g, 16, 13, BLOOD)
    # gota de sangue escorrendo
    put(g, 16, 26, BLOOD)
    put(g, 16, 28, BLOOD_DARK)
    return g


def coracao_de_cerne():
    """T4: corte de cerne (anéis de tronco) com miolo vivo pulsando."""
    g = blank()
    # disco de madeira concêntrico
    rings = [(11, BARK_DARK), (9, WOOD_MID), (7, WOOD_LIGHT), (5, WOOD_MID), (3, WOOD_LIGHT)]
    for r, col in rings:
        for y in range(16 - r, 16 + r + 1):
            for x in range(16 - r, 16 + r + 1):
                d2 = (x - 16) ** 2 + (y - 16) ** 2
                if (r - 1) ** 2 < d2 <= r * r:
                    put(g, x, y, col)
    blob(g, 16, 16, 11, None, edge=BARK_DARK)  # contorno externo
    # miolo (cerne) vivo
    blob(g, 16, 16, 2, BLOOD)
    put(g, 16, 16, AMBER)
    # rachadura
    stem(g, 16, 16, 16, 5, WOOD_DARK)
    return g


# ─── CACHIMBO ────────────────────────────────────────────────────────────────
def cachimbo():
    """Cachimbo de madeira: fornilho à esquerda, haste curva até a boquilha."""
    g = blank(48, 32)
    # fornilho (taça) — cilindro de madeira
    for y in range(6, 24):
        for x in range(7, 18):
            edge = x in (7, 17) or y in (6, 23)
            inner = 9 <= x <= 15 and 7 <= y <= 10
            if inner:
                col = SOOT                       # boca do fornilho (tabaco/cinza)
            elif edge:
                col = WOOD_DARK
            elif (x + y) % 5 == 0:
                col = WOOD_LIGHT
            else:
                col = WOOD_MID
            put(g, x, y, col)
    # base arredondada do fornilho
    for x in range(9, 16):
        put(g, x, 24, WOOD_DARK)
    # haste curva descendo até a boquilha (direita)
    haste = [(17, 20), (22, 22), (28, 24), (34, 25), (40, 25)]
    for i in range(len(haste) - 1):
        stem(g, *haste[i], *haste[i + 1], WOOD_MID, WOOD_DARK)
        x0, y0 = haste[i]; x1, y1 = haste[i + 1]
        # engrossa a haste
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for k in range(steps + 1):
            x = round(x0 + (x1 - x0) * k / steps)
            y = round(y0 + (y1 - y0) * k / steps)
            put(g, x, y - 1, WOOD_LIGHT)
            put(g, x, y + 1, WOOD_DARK)
    # boquilha
    for x in range(40, 45):
        put(g, x, 24, BARK_HI)
        put(g, x, 25, BARK_MID)
        put(g, x, 26, BARK_DARK)
    # brasa + fumaça saindo do fornilho
    ember(g, 12, 8, 1)
    smoke(g, 12, 5)
    return g



# ─── FÚRIA T5/T6 ─────────────────────────────────────────────────────────────
def osso_quebrado():
    """T5: osso fossilizado quebrado, com sangue seco e veios negros."""
    g = blank()
    # Osso principal (curva quebrada)
    pts = [(10, 28), (12, 22), (16, 18), (20, 14), (18, 10), (22, 8), (26, 12)]
    for i in range(len(pts) - 1):
        stem(g, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1], WOOD_HI, WOOD_MID)
    # Rachadura no osso
    for (x, y) in [(16, 18), (17, 17), (18, 16), (19, 15)]:
        put(g, x, y, BLOOD_DARK)
        put(g, x + 1, y, BLOOD)
    # Fragmentos soltos
    for (x, y) in [(8, 26), (24, 10), (28, 14)]:
        blob(g, x, y, 1, WOOD_LIGHT)
    return g


def chaga_da_mata():
    """T6: ferida viva da floresta — massa negra pulsando com espinhos carmim."""
    g = blank()
    # Massa negra central (corpo da chaga)
    blob(g, 16, 16, 10, SOOT)
    blob(g, 16, 16, 7, BARK_DARK)
    # Espinhos carmim irradiando
    for angle in [0.3, 0.9, 1.8, 2.5, 3.8, 4.5, 5.2]:
        x0 = int(round(16 + 7 * math.cos(angle)))
        y0 = int(round(16 + 7 * math.sin(angle)))
        x1 = int(round(16 + 14 * math.cos(angle)))
        y1 = int(round(16 + 14 * math.sin(angle)))
        stem(g, x0, y0, x1, y1, BLOOD, BLOOD_DARK)
        put(g, x1, y1, BLOOD)
    # Miolo pulsando (âmbar-sangue)
    blob(g, 16, 16, 3, AMBER)
    put(g, 16, 16, EMBER_HOT)
    return g


# ─── CURA T5/T6 ──────────────────────────────────────────────────────────────
def rachadura_viva():
    """T5: rachadura na terra com seiva verde brilhando — ferida que cura."""
    g = blank()
    # Terra escura
    for y in range(8, 26):
        w = 7 - abs(y - 17) // 2
        for x in range(16 - w, 16 + w + 1):
            put(g, x, y, SOOT if (x + y) % 3 == 0 else BARK_DARK)
    # Rachadura central
    for y in range(10, 24):
        dx = int(round(2 * math.sin(y * 0.7)))
        put(g, 16 + dx, y, SOOT)
        put(g, 16 + dx - 1, y, MOSS_LIGHT)
        put(g, 16 + dx + 1, y, MOSS_LIGHT)
    # Seiva brilhando nos bordos
    for (x, y) in [(13, 12), (19, 15), (12, 20), (20, 22)]:
        blob(g, x, y, 1, LEAF_LIGHT)
    return g


def pele_de_defunto():
    """T6: membrana pálida/cinzenta esticada, com veias escuras e pontos de luz doentia."""
    g = blank()
    # Membrana pálida (elipse)
    for y in range(6, 28):
        w = int(round(9 * math.sqrt(max(0.0, 1.0 - ((y - 17) / 11.0) ** 2))))
        for x in range(16 - w, 16 + w + 1):
            t = abs(x - 16) / float(max(1, w))
            if t < 0.3:
                col = ASH_LIGHT
            elif t < 0.7:
                col = ASH
            else:
                col = (60, 50, 45, 255)
            put(g, x, y, col)
    # Veias escuras
    for angle in [0.5, 1.2, 2.8, 3.9, 5.1]:
        x0 = int(round(16 + 3 * math.cos(angle)))
        y0 = int(round(17 + 3 * math.sin(angle)))
        x1 = int(round(16 + 10 * math.cos(angle)))
        y1 = int(round(17 + 10 * math.sin(angle)))
        stem(g, x0, y0, x1, y1, BLOOD_DARK, (40, 30, 28, 255))
    # Pontos de luz doentia (musgo doentio)
    for (x, y) in [(12, 10), (20, 12), (14, 22), (22, 20), (16, 8)]:
        blob(g, x, y, 1, MOSS_LIGHT)
    return g


# ─── Saída ───────────────────────────────────────────────────────────────────
ERVAS = {
    "erva_folha_brasa": folha_brasa,
    "erva_cinza_viva": cinza_viva,
    "erva_raiz_de_ira": raiz_de_ira,
    "erva_breu_ancestral": breu_ancestral,
    "erva_osso_quebrado": osso_quebrado,
    "erva_chaga_da_mata": chaga_da_mata,
    "erva_seiva_mae": seiva_mae,
    "erva_casca_boa": casca_boa,
    "erva_folha_de_sangue": folha_de_sangue,
    "erva_coracao_de_cerne": coracao_de_cerne,
    "erva_rachadura_viva": rachadura_viva,
    "erva_pele_de_defunto": pele_de_defunto,
    "cachimbo": cachimbo,
}


def main() -> None:
    out_dir = os.path.normpath(
        os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
    )
    for name, fn in ERVAS.items():
        grid = fn()
        path = os.path.join(out_dir, name + ".png")
        with open(path, "wb") as f:
            f.write(encode_png(grid))
        print(f"Gerado: {path}  ({len(grid[0])}x{len(grid)}px)")


if __name__ == "__main__":
    main()
