"""Gera assets/sprites/weapon_forca{1..6}.png e variantes _fogo.

Cada tier representa uma evolução visual da arma da Caipora:
  T1 "Galho da Guardiã"    – galho fino, rústico, madeira clara
  T2 "Galho Cinzento"      – galho mais grosso, topo queimado
  T3 "Tronco Buster"       – tronco maciço estilo Buster (FF7)
  T4 "Tronco de Breu"      – tronco revestido de resina preta/verde
  T5 "Osso Quebrado"       – osso fossilizado com farpas de sangue seco
  T6 "Chaga Viva"          – carne/espinho biomecânico, veias pulsando

Todas as sprites são 64×112 para o WEAPON_OFFSET continuar válido.
A variante _fogo usa a mesma geometria com paleta carbonizada + brasa.

Geometria 100% determinística (sem dependências externas: struct/zlib puros).
"""
import struct, zlib, os

W, H = 64, 112
CX = 32  # centro X (eixo de simetria)


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
    ihdr = struct.pack(">II", w, h) + bytes([8, 6, 0, 0, 0])
    compressed = zlib.compress(raw, 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", compressed)
        + png_chunk(b"IEND", b"")
    )


def blank() -> list[list[tuple]]:
    return [[(0, 0, 0, 0)] * W for _ in range(H)]


# ──────────────────────────────────────────────────────────────────────────────
# TIER 1 – "Galho da Guardiã"
# ──────────────────────────────────────────────────────────────────────────────
def gen_t1() -> list[list[tuple]]:
    """Galho fino e simples, madeira clara."""
    TRANSP = (0, 0, 0, 0)
    BARK_D = (55, 35, 18, 255)
    BARK_M = (92, 62, 30, 255)
    BARK_L = (143, 102, 52, 255)
    WOOD_D = (82, 55, 22, 255)
    WOOD_M = (130, 90, 40, 255)
    WOOD_L = (175, 130, 65, 255)
    MOSS   = (55, 90, 35, 255)

    g = blank()
    # Lâmina fina (24×80), leve curva para direita
    for row in range(0, 81):
        w = max(6, 12 + int(8 * (row / 80.0)))
        off = int(3 * (row / 80.0))  # curva suave
        left = CX - w // 2 + off
        right = left + w
        for x in range(left, right):
            t = abs(x - (CX + off)) / float(max(1, w // 2))
            if x == left or x == right - 1:
                col = BARK_D
            elif t < 0.25:
                col = WOOD_L
            elif t < 0.6:
                col = WOOD_M
            else:
                col = WOOD_D
            # musgo raro nas bordas
            if (row + x) % 17 == 0 and col == WOOD_D:
                col = MOSS
            g[row][x] = col

    # Guarda: dois galhos cruzados finos
    for row in range(81, 86):
        for x in range(CX - 18, CX + 18):
            dy = abs(row - 83.5)
            dx = abs(x - CX)
            if dy < 2.5 and (dx < 14 or (dx < 18 and dy < 1.5)):
                col = BARK_M if dy < 1.5 else BARK_D
                g[row][x] = col

    # Cabo enrolado
    for row in range(87, 104):
        w = 8
        left = CX - w // 2
        right = left + w
        band = ((row - 87) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_D
            else:
                col = BARK_M if band == 0 else BARK_D
            g[row][x] = col

    # Pomo pequeno
    for row in range(105, 111):
        w = 10 if row < 108 else 8
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            g[row][x] = BARK_D if (x == left or x == right - 1) else BARK_M

    return g


def gen_t1_fire() -> list[list[tuple]]:
    """T1 carbonizado com brasas."""
    TRANSP = (0, 0, 0, 0)
    CHAR_E = (20, 12, 6, 255)
    CHAR_D = (45, 22, 10, 255)
    CHAR_M = (78, 38, 16, 255)
    EMBER_L = (160, 72, 18, 255)
    EMBER_M = (210, 105, 25, 255)
    EMBER_H = (255, 155, 45, 255)
    CRACK_H = (255, 200, 80, 255)
    CRACK_C = (255, 235, 140, 255)

    g = blank()
    for row in range(0, 81):
        w = max(6, 12 + int(8 * (row / 80.0)))
        off = int(3 * (row / 80.0))
        left = CX - w // 2 + off
        right = left + w
        for x in range(left, right):
            t = abs(x - (CX + off)) / float(max(1, w // 2))
            if x == left or x == right - 1:
                col = CHAR_E
            elif t < 0.25:
                col = EMBER_H if row % 4 == 0 else EMBER_M
            elif t < 0.6:
                col = EMBER_L if (row + x) % 5 == 0 else CHAR_M
            else:
                col = CHAR_D
            # rachaduras incandescentes
            if col in (CHAR_M, CHAR_D, EMBER_L) and (row % 7 == 0 or (x - CX) % 11 == 0):
                col = CRACK_C if row % 2 == 0 else CRACK_H
            g[row][x] = col

    for row in range(81, 86):
        for x in range(CX - 18, CX + 18):
            dy = abs(row - 83.5)
            dx = abs(x - CX)
            if dy < 2.5 and (dx < 14 or (dx < 18 and dy < 1.5)):
                col = CHAR_M if dy < 1.5 else CHAR_E
                g[row][x] = col

    for row in range(87, 104):
        w = 8
        left = CX - w // 2
        right = left + w
        band = ((row - 87) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            else:
                col = CHAR_M if band == 0 else CHAR_E
            g[row][x] = col

    for row in range(105, 111):
        w = 10 if row < 108 else 8
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            g[row][x] = CHAR_E if (x == left or x == right - 1) else CHAR_M

    return g


# ──────────────────────────────────────────────────────────────────────────────
# TIER 2 – "Galho Cinzento"
# ──────────────────────────────────────────────────────────────────────────────
def gen_t2() -> list[list[tuple]]:
    """Galho mais grosso, topo queimado/cinzento."""
    TRANSP = (0, 0, 0, 0)
    BARK_D = (45, 28, 14, 255)
    BARK_M = (78, 50, 25, 255)
    BARK_L = (125, 85, 42, 255)
    WOOD_D = (72, 48, 20, 255)
    WOOD_M = (118, 82, 38, 255)
    WOOD_L = (165, 118, 58, 255)
    ASH_D  = (90, 85, 80, 255)
    ASH_M  = (130, 125, 118, 255)
    ASH_L  = (170, 165, 158, 255)

    g = blank()
    for row in range(0, 81):
        # Topo queimado nas primeiras 18 linhas
        is_ash = row < 18
        w = max(8, 18 + int(14 * (row / 80.0)))
        off = int(2 * (row / 80.0))
        left = CX - w // 2 + off
        right = left + w
        for x in range(left, right):
            t = abs(x - (CX + off)) / float(max(1, w // 2))
            if is_ash:
                if x == left or x == right - 1:
                    col = ASH_D
                elif t < 0.3:
                    col = ASH_L
                elif t < 0.65:
                    col = ASH_M
                else:
                    col = ASH_D
            else:
                if x == left or x == right - 1:
                    col = BARK_D
                elif t < 0.2:
                    col = WOOD_L
                elif t < 0.55:
                    col = WOOD_M
                else:
                    col = WOOD_D
            # transição suave entre cinza e madeira
            if row == 18 and col in (ASH_D, ASH_M):
                col = WOOD_D
            g[row][x] = col

    # Guarda mais pronunciada
    for row in range(81, 87):
        w = 26
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_D
            elif row == 81:
                col = BARK_L
            elif row == 86:
                col = BARK_D
            else:
                col = BARK_M
            g[row][x] = col

    # Cabo
    for row in range(88, 105):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - 88) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_D
            else:
                col = BARK_M if band == 0 else BARK_D
            g[row][x] = col

    # Pomo
    for row in range(106, 112):
        w = 12 if row < 109 else 10
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            g[row][x] = BARK_D if (x == left or x == right - 1) else BARK_M

    return g


def gen_t2_fire() -> list[list[tuple]]:
    """T2 carbonizado, topo flamejante."""
    TRANSP = (0, 0, 0, 0)
    CHAR_E = (18, 10, 5, 255)
    CHAR_D = (42, 20, 9, 255)
    CHAR_M = (72, 34, 14, 255)
    EMBER_L = (155, 68, 16, 255)
    EMBER_M = (205, 98, 22, 255)
    EMBER_H = (255, 150, 42, 255)
    CRACK_H = (255, 195, 78, 255)
    CRACK_C = (255, 230, 135, 255)
    FLAME_C = (255, 240, 180, 255)

    g = blank()
    for row in range(0, 81):
        is_flame = row < 18
        w = max(8, 18 + int(14 * (row / 80.0)))
        off = int(2 * (row / 80.0))
        left = CX - w // 2 + off
        right = left + w
        for x in range(left, right):
            t = abs(x - (CX + off)) / float(max(1, w // 2))
            if is_flame:
                if t < 0.3:
                    col = FLAME_C if row % 2 == 0 else CRACK_C
                elif t < 0.65:
                    col = EMBER_H if row % 3 == 0 else EMBER_M
                else:
                    col = EMBER_L
            else:
                if x == left or x == right - 1:
                    col = CHAR_E
                elif t < 0.2:
                    col = EMBER_H if row % 5 == 0 else EMBER_M
                elif t < 0.55:
                    col = EMBER_L if (row + x) % 7 == 0 else CHAR_M
                else:
                    col = CHAR_D
            if col in (CHAR_M, CHAR_D, EMBER_L) and (row % 6 == 0 or (x - CX) % 9 == 0):
                col = CRACK_C if row % 2 == 0 else CRACK_H
            g[row][x] = col

    for row in range(81, 87):
        w = 26
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            elif row == 81:
                col = EMBER_M
            elif row == 86:
                col = CHAR_E
            else:
                col = CHAR_M
            g[row][x] = col

    for row in range(88, 105):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - 88) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            else:
                col = CHAR_M if band == 0 else CHAR_E
            g[row][x] = col

    for row in range(106, 112):
        w = 12 if row < 109 else 10
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            g[row][x] = CHAR_E if (x == left or x == right - 1) else CHAR_M

    return g


# ──────────────────────────────────────────────────────────────────────────────
# TIER 3 – "Tronco Buster" (reutiliza código dos geradores existentes)
# ──────────────────────────────────────────────────────────────────────────────
def gen_t3() -> list[list[tuple]]:
    TRANSP     = (0, 0, 0, 0)
    WOOD_DARK  = (41, 18, 3, 255)
    WOOD_MID   = (82, 43, 10, 255)
    WOOD_LIGHT = (163, 94, 36, 255)
    WOOD_HI    = (212, 152, 80, 255)
    BARK_DARK  = (25, 15, 5, 255)
    BARK_MID   = (46, 28, 13, 255)
    BARK_HI    = (92, 62, 30, 255)
    VEIN       = (55, 28, 5, 255)
    KNOT_RING  = (60, 33, 9, 255)
    KNOT_CORE  = (18, 10, 3, 255)

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    GUARD_TOP, GUARD_BOT = 81, 86
    GRIP_TOP,  GRIP_BOT  = 87, 104
    POMMEL_TOP, POMMEL_BOT = 105, 111
    BLADE_MAX_W = 44
    TIP_END = 9

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(18 + (BLADE_MAX_W - 18) * (row / float(TIP_END))))
        if row <= 70:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 6 * ((row - 70) / 10.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            if x == left or x == right - 1:
                col = BARK_DARK
            elif x == left + 1 or x == right - 2:
                col = WOOD_DARK
            elif t < 0.14:
                col = WOOD_HI
            elif t < 0.42:
                col = WOOD_LIGHT
            else:
                col = WOOD_MID
            if col in (WOOD_MID, WOOD_LIGHT) and (x - CX) in (-9, 6, 13):
                col = VEIN
            g[row][x] = col

    def paint_knot(cx, cy, rx, ry):
        for y in range(cy - ry, cy + ry + 1):
            if y < BLADE_TOP or y > BLADE_BOT:
                continue
            for x in range(cx - rx, cx + rx + 1):
                if x < 0 or x >= W or g[y][x] == TRANSP:
                    continue
                dx = (x - cx) / float(rx)
                dy = (y - cy) / float(ry)
                d = dx * dx + dy * dy
                if d <= 1.0:
                    g[y][x] = KNOT_CORE if d <= 0.45 else KNOT_RING

    paint_knot(CX - 4, 48, 4, 6)
    paint_knot(CX + 5, 64, 3, 5)

    for row in range(GUARD_TOP, GUARD_BOT + 1):
        w = 30
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_DARK
            elif row == GUARD_TOP:
                col = BARK_HI
            elif row == GUARD_BOT:
                col = BARK_DARK
            else:
                col = BARK_MID
            g[row][x] = col

    for row in range(GRIP_TOP, GRIP_BOT + 1):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - GRIP_TOP) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_DARK
            else:
                col = BARK_MID if band == 0 else BARK_DARK
            g[row][x] = col

    widths = [10, 12, 14, 14, 12, 10, 8]
    for i, row in enumerate(range(POMMEL_TOP, POMMEL_BOT + 1)):
        w = widths[min(i, len(widths) - 1)]
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            g[row][x] = BARK_DARK if (x == left or x == right - 1) else BARK_MID

    return g


def gen_t3_fire() -> list[list[tuple]]:
    TRANSP     = (0, 0, 0, 0)
    CHAR_EDGE  = (14, 6, 3, 255)
    CHAR_DARK  = (34, 14, 6, 255)
    CHAR_MID   = (64, 26, 11, 255)
    EMBER_LOW  = (140, 52, 14, 255)
    EMBER_MID  = (210, 92, 22, 255)
    EMBER_HOT  = (255, 150, 45, 255)
    CRACK_HOT  = (255, 196, 90, 255)
    CRACK_CORE = (255, 232, 150, 255)
    BARK_DARK  = (20, 10, 5, 255)
    BARK_MID   = (40, 20, 10, 255)
    BARK_HI    = (96, 46, 18, 255)
    KNOT_RING  = (70, 30, 10, 255)
    KNOT_CORE  = (16, 8, 3, 255)

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    GUARD_TOP, GUARD_BOT = 81, 86
    GRIP_TOP,  GRIP_BOT  = 87, 104
    POMMEL_TOP, POMMEL_BOT = 105, 111
    BLADE_MAX_W = 44
    TIP_END = 9

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(18 + (BLADE_MAX_W - 18) * (row / float(TIP_END))))
        if row <= 70:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 6 * ((row - 70) / 10.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            if x == left or x == right - 1:
                col = CHAR_EDGE
            elif x == left + 1 or x == right - 2:
                col = CHAR_DARK
            elif t < 0.14:
                col = EMBER_HOT
            elif t < 0.30:
                col = EMBER_MID
            elif t < 0.55:
                col = EMBER_LOW
            else:
                col = CHAR_MID
            if col in (CHAR_MID, EMBER_LOW, EMBER_MID) and (x - CX) in (-9, 6, 13):
                col = CRACK_CORE if (row % 3 == 0) else CRACK_HOT
            g[row][x] = col

    def paint_knot(cx, cy, rx, ry):
        for y in range(cy - ry, cy + ry + 1):
            if y < BLADE_TOP or y > BLADE_BOT:
                continue
            for x in range(cx - rx, cx + rx + 1):
                if x < 0 or x >= W or g[y][x] == TRANSP:
                    continue
                dx = (x - cx) / float(rx)
                dy = (y - cy) / float(ry)
                d = dx * dx + dy * dy
                if d <= 1.0:
                    g[y][x] = KNOT_CORE if d <= 0.45 else KNOT_RING

    paint_knot(CX - 4, 48, 4, 6)
    paint_knot(CX + 5, 64, 3, 5)

    for row in range(GUARD_TOP, GUARD_BOT + 1):
        w = 30
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_EDGE
            elif row == GUARD_TOP:
                col = BARK_HI
            elif row == GUARD_BOT:
                col = BARK_DARK
            else:
                col = BARK_MID
            g[row][x] = col

    for row in range(GRIP_TOP, GRIP_BOT + 1):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - GRIP_TOP) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BARK_DARK
            else:
                col = BARK_MID if band == 0 else BARK_DARK
            g[row][x] = col

    widths = [10, 12, 14, 14, 12, 10, 8]
    for i, row in enumerate(range(POMMEL_TOP, POMMEL_BOT + 1)):
        w = widths[min(i, len(widths) - 1)]
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            g[row][x] = BARK_DARK if (x == left or x == right - 1) else BARK_MID

    return g


# ──────────────────────────────────────────────────────────────────────────────
# TIER 4 – "Tronco de Breu"
# ──────────────────────────────────────────────────────────────────────────────
def gen_t4() -> list[list[tuple]]:
    TRANSP = (0, 0, 0, 0)
    BREU_E = (15, 12, 8, 255)      # borda externa
    BREU_D = (28, 22, 14, 255)     # sombra interna
    BREU_M = (48, 38, 24, 255)     # corpo
    RESIN_D = (35, 55, 20, 255)    # resina escura
    RESIN_M = (55, 85, 30, 255)    # resina musgo
    RESIN_L = (80, 120, 45, 255)   # resina brilhante
    AMBER_D = (90, 55, 10, 255)    # âmbar escuro
    AMBER_M = (140, 85, 18, 255)   # âmbar médio
    AMBER_L = (185, 115, 25, 255)  # âmbar brilhante
    ROOT_D = (38, 25, 12, 255)     # raiz escura
    ROOT_M = (62, 42, 20, 255)     # raiz média

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    BLADE_MAX_W = 46
    TIP_END = 10

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(20 + (BLADE_MAX_W - 20) * (row / float(TIP_END))))
        if row <= 68:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 8 * ((row - 68) / 12.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            # resina escorrendo do centro
            resin_band = abs(x - CX) < 4 and row > 15
            if x == left or x == right - 1:
                col = BREU_E
            elif x == left + 1 or x == right - 2:
                col = BREU_D
            elif resin_band:
                col = RESIN_L if row % 5 == 0 else (RESIN_M if row % 3 == 0 else RESIN_D)
            elif t < 0.15:
                col = AMBER_L
            elif t < 0.35:
                col = AMBER_M
            elif t < 0.6:
                col = AMBER_D
            else:
                col = BREU_M
            g[row][x] = col

    # Guarda: raízes entrelaçadas
    for row in range(81, 87):
        w = 32
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = ROOT_D
            elif row == 81:
                col = ROOT_M
            elif row == 86:
                col = ROOT_D
            else:
                # raízes cruzadas
                col = ROOT_M if (x + row) % 4 < 2 else ROOT_D
            g[row][x] = col

    # Cabo com resina
    for row in range(88, 105):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - 88) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = BREU_E
            else:
                col = ROOT_M if band == 0 else BREU_D
            g[row][x] = col

    # Pomo com resina
    for row in range(106, 112):
        w = 12 if row < 109 else 10
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            col = BREU_E if (x == left or x == right - 1) else ROOT_M
            if abs(x - CX) < 2 and row > 108:
                col = AMBER_M
            g[row][x] = col

    return g


def gen_t4_fire() -> list[list[tuple]]:
    TRANSP = (0, 0, 0, 0)
    CHAR_E = (12, 10, 6, 255)
    CHAR_D = (26, 20, 12, 255)
    CHAR_M = (44, 34, 20, 255)
    EMBER_L = (120, 80, 15, 255)
    EMBER_M = (180, 115, 22, 255)
    EMBER_H = (255, 165, 35, 255)
    CRACK_H = (255, 210, 70, 255)
    CRACK_C = (255, 245, 130, 255)
    FLAME_G = (180, 255, 60, 255)  # fogo verde musgo (breu)

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    BLADE_MAX_W = 46
    TIP_END = 10

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(20 + (BLADE_MAX_W - 20) * (row / float(TIP_END))))
        if row <= 68:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 8 * ((row - 68) / 12.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            flame_band = abs(x - CX) < 4 and row > 15
            if x == left or x == right - 1:
                col = CHAR_E
            elif x == left + 1 or x == right - 2:
                col = CHAR_D
            elif flame_band:
                col = FLAME_G if row % 4 == 0 else (EMBER_H if row % 3 == 0 else EMBER_M)
            elif t < 0.15:
                col = EMBER_H if row % 3 == 0 else EMBER_M
            elif t < 0.35:
                col = EMBER_M if (row + x) % 5 == 0 else EMBER_L
            elif t < 0.6:
                col = EMBER_L if (row + x) % 4 == 0 else CHAR_M
            else:
                col = CHAR_D
            if col in (CHAR_M, CHAR_D, EMBER_L) and (row % 6 == 0 or (x - CX) % 10 == 0):
                col = CRACK_C if row % 2 == 0 else CRACK_H
            g[row][x] = col

    for row in range(81, 87):
        w = 32
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            elif row == 81:
                col = EMBER_M
            elif row == 86:
                col = CHAR_E
            else:
                col = EMBER_L if (x + row) % 4 < 2 else CHAR_D
            g[row][x] = col

    for row in range(88, 105):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - 88) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            else:
                col = EMBER_L if band == 0 else CHAR_D
            g[row][x] = col

    for row in range(106, 112):
        w = 12 if row < 109 else 10
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            col = CHAR_E if (x == left or x == right - 1) else EMBER_L
            if abs(x - CX) < 2 and row > 108:
                col = EMBER_H
            g[row][x] = col

    return g


# ──────────────────────────────────────────────────────────────────────────────
# TIER 5 – "Osso Quebrado"
# ──────────────────────────────────────────────────────────────────────────────
def gen_t5() -> list[list[tuple]]:
    TRANSP = (0, 0, 0, 0)
    BONE_E = (160, 148, 130, 255)   # borda externa
    BONE_D = (185, 172, 150, 255)   # sombra
    BONE_M = (210, 196, 172, 255)   # corpo
    BONE_L = (232, 220, 198, 255)   # highlight
    BONE_H = (245, 235, 218, 255)   # brilho
    DRY_BLOOD = (120, 35, 22, 255)  # sangue seco nas farpas
    DRY_DARK = (80, 22, 14, 255)    # sangue escuro
    MARROW = (55, 42, 28, 255)      # tutano visível
    FLESH = (155, 90, 65, 255)      # carne seca

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    BLADE_MAX_W = 48
    TIP_END = 8

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(22 + (BLADE_MAX_W - 22) * (row / float(TIP_END))))
        if row <= 65:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 10 * ((row - 65) / 15.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            # farpas nas bordas em linhas alternadas
            spike = (row % 5 == 0) and (t > 0.85)
            marrow_visible = (row > 30 and row < 55) and abs(x - CX) < 3

            if spike:
                col = DRY_BLOOD if row % 10 == 0 else DRY_DARK
            elif x == left or x == right - 1:
                col = BONE_E
            elif x == left + 1 or x == right - 2:
                col = BONE_D
            elif marrow_visible:
                col = MARROW
            elif t < 0.12:
                col = BONE_H
            elif t < 0.35:
                col = BONE_L
            elif t < 0.65:
                col = BONE_M
            else:
                col = BONE_D
            # manchas de carne seca
            if col in (BONE_M, BONE_D) and (row + x) % 13 == 0:
                col = FLESH
            g[row][x] = col

    # Guarda: costelas cruzadas
    for row in range(81, 87):
        w = 34
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = DRY_DARK
            elif row == 81:
                col = BONE_L
            elif row == 86:
                col = BONE_E
            else:
                # padrão de costela
                col = BONE_M if (abs(x - CX) < 8 or abs(x - CX) > 12) else BONE_D
            g[row][x] = col

    # Cabo: tendão enrolado
    for row in range(88, 105):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - 88) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = DRY_DARK
            else:
                col = FLESH if band == 0 else MARROW
            g[row][x] = col

    # Pomo: fragmento de osso
    for row in range(106, 112):
        w = 14 if row < 109 else 10
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            col = BONE_E if (x == left or x == right - 1) else BONE_M
            if abs(x - CX) < 2 and row > 108:
                col = MARROW
            g[row][x] = col

    return g


def gen_t5_fire() -> list[list[tuple]]:
    TRANSP = (0, 0, 0, 0)
    CHAR_E = (45, 38, 30, 255)
    CHAR_D = (70, 55, 40, 255)
    CHAR_M = (95, 72, 50, 255)
    EMBER_L = (170, 65, 18, 255)
    EMBER_M = (220, 95, 22, 255)
    EMBER_H = (255, 140, 35, 255)
    CRACK_H = (255, 195, 75, 255)
    CRACK_C = (255, 235, 130, 255)
    BLOOD_F = (180, 30, 12, 255)    # sangue fervendo

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    BLADE_MAX_W = 48
    TIP_END = 8

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(22 + (BLADE_MAX_W - 22) * (row / float(TIP_END))))
        if row <= 65:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 10 * ((row - 65) / 15.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            spike = (row % 5 == 0) and (t > 0.85)
            marrow_visible = (row > 30 and row < 55) and abs(x - CX) < 3

            if spike:
                col = BLOOD_F if row % 10 == 0 else EMBER_H
            elif x == left or x == right - 1:
                col = CHAR_E
            elif x == left + 1 or x == right - 2:
                col = CHAR_D
            elif marrow_visible:
                col = EMBER_H if row % 3 == 0 else EMBER_M
            elif t < 0.12:
                col = EMBER_H
            elif t < 0.35:
                col = EMBER_M if (row + x) % 4 == 0 else EMBER_L
            elif t < 0.65:
                col = EMBER_L if (row + x) % 5 == 0 else CHAR_M
            else:
                col = CHAR_D
            if col in (CHAR_M, CHAR_D, EMBER_L) and (row % 5 == 0 or (x - CX) % 11 == 0):
                col = CRACK_C if row % 2 == 0 else CRACK_H
            g[row][x] = col

    for row in range(81, 87):
        w = 34
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            elif row == 81:
                col = EMBER_M
            elif row == 86:
                col = CHAR_E
            else:
                col = EMBER_L if (abs(x - CX) < 8 or abs(x - CX) > 12) else CHAR_D
            g[row][x] = col

    for row in range(88, 105):
        w = 10
        left = CX - w // 2
        right = left + w
        band = ((row - 88) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            else:
                col = EMBER_L if band == 0 else CHAR_D
            g[row][x] = col

    for row in range(106, 112):
        w = 14 if row < 109 else 10
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            col = CHAR_E if (x == left or x == right - 1) else EMBER_L
            if abs(x - CX) < 2 and row > 108:
                col = EMBER_H
            g[row][x] = col

    return g


# ──────────────────────────────────────────────────────────────────────────────
# TIER 6 – "Chaga Viva"
# ──────────────────────────────────────────────────────────────────────────────
def gen_t6() -> list[list[tuple]]:
    TRANSP = (0, 0, 0, 0)
    FLESH_E = (85, 18, 18, 255)      # borda escura
    FLESH_D = (130, 28, 28, 255)     # sombra
    FLESH_M = (175, 42, 42, 255)     # carne média
    FLESH_L = (210, 58, 58, 255)     # carne clara
    FLESH_H = (235, 78, 78, 255)     # carne brilhante
    VEIN_D = (55, 12, 28, 255)       # veia escura
    VEIN_M = (85, 18, 42, 255)       # veia média
    SPINE_E = (45, 45, 45, 255)      # espinho escuro
    SPINE_M = (75, 75, 75, 255)      # espinho médio
    SPINE_L = (115, 115, 115, 255)   # espinho claro
    PUS = (185, 165, 55, 255)        # secreção amarelada

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    BLADE_MAX_W = 50
    TIP_END = 7

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(24 + (BLADE_MAX_W - 24) * (row / float(TIP_END))))
        if row <= 60:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 12 * ((row - 60) / 20.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            # espinhos nas bordas
            spine = (row % 4 == 0) and (t > 0.82)
            # veias centrais
            vein = (abs(x - CX) < 5) and (row % 6 < 3)
            # secreção
            pus = (row + x) % 19 == 0 and t < 0.7

            if spine:
                col = SPINE_L if row % 8 == 0 else SPINE_M
            elif x == left or x == right - 1:
                col = FLESH_E
            elif x == left + 1 or x == right - 2:
                col = FLESH_D
            elif vein:
                col = VEIN_M if (row + x) % 3 == 0 else VEIN_D
            elif pus:
                col = PUS
            elif t < 0.1:
                col = FLESH_H
            elif t < 0.3:
                col = FLESH_L
            elif t < 0.6:
                col = FLESH_M
            else:
                col = FLESH_D
            g[row][x] = col

    # Guarda: carne com espinhos
    for row in range(81, 88):
        w = 36
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            spine = (row % 3 == 0) and (abs(x - left) < 3 or abs(x - right + 1) < 3)
            if spine:
                col = SPINE_L
            elif x == left or x == right - 1:
                col = FLESH_E
            elif row == 81:
                col = FLESH_L
            elif row == 87:
                col = FLESH_E
            else:
                col = FLESH_M if (x + row) % 3 == 0 else FLESH_D
            g[row][x] = col

    # Cabo: músculo enrolado
    for row in range(89, 106):
        w = 12
        left = CX - w // 2
        right = left + w
        band = ((row - 89) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = VEIN_D
            else:
                col = FLESH_M if band == 0 else FLESH_D
            g[row][x] = col

    # Pomo: nódulo de carne
    for row in range(107, 112):
        w = 14 if row < 110 else 12
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            col = FLESH_E if (x == left or x == right - 1) else FLESH_M
            if abs(x - CX) < 2:
                col = FLESH_L
            g[row][x] = col

    return g


def gen_t6_fire() -> list[list[tuple]]:
    TRANSP = (0, 0, 0, 0)
    CHAR_E = (35, 8, 8, 255)
    CHAR_D = (55, 12, 12, 255)
    CHAR_M = (80, 18, 18, 255)
    EMBER_L = (200, 45, 20, 255)
    EMBER_M = (240, 65, 25, 255)
    EMBER_H = (255, 95, 35, 255)
    CRACK_H = (255, 180, 60, 255)
    CRACK_C = (255, 225, 120, 255)
    FLAME_W = (255, 250, 200, 255)  # brasa branca

    g = blank()
    BLADE_TOP, BLADE_BOT = 0, 80
    BLADE_MAX_W = 50
    TIP_END = 7

    def blade_width(row: int) -> int:
        if row < TIP_END:
            return int(round(24 + (BLADE_MAX_W - 24) * (row / float(TIP_END))))
        if row <= 60:
            return BLADE_MAX_W
        return int(round(BLADE_MAX_W - 12 * ((row - 60) / 20.0)))

    for row in range(BLADE_TOP, BLADE_BOT + 1):
        w = blade_width(row)
        left = CX - w // 2
        right = left + w
        half = max(1, w // 2)
        for x in range(left, right):
            t = abs(x - CX) / float(half)
            spine = (row % 4 == 0) and (t > 0.82)
            vein_fire = (abs(x - CX) < 5) and (row % 6 < 3)
            white_hot = (row < 15) and (t < 0.3)

            if spine:
                col = EMBER_H if row % 8 == 0 else EMBER_M
            elif white_hot:
                col = FLAME_W if row % 2 == 0 else CRACK_C
            elif x == left or x == right - 1:
                col = CHAR_E
            elif x == left + 1 or x == right - 2:
                col = CHAR_D
            elif vein_fire:
                col = EMBER_H if (row + x) % 3 == 0 else EMBER_M
            elif t < 0.1:
                col = EMBER_H
            elif t < 0.3:
                col = EMBER_M if (row + x) % 4 == 0 else EMBER_L
            elif t < 0.6:
                col = EMBER_L if (row + x) % 5 == 0 else CHAR_M
            else:
                col = CHAR_D
            if col in (CHAR_M, CHAR_D, EMBER_L) and (row % 4 == 0 or (x - CX) % 8 == 0):
                col = CRACK_C if row % 2 == 0 else CRACK_H
            g[row][x] = col

    for row in range(81, 88):
        w = 36
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            spine = (row % 3 == 0) and (abs(x - left) < 3 or abs(x - right + 1) < 3)
            if spine:
                col = EMBER_H
            elif x == left or x == right - 1:
                col = CHAR_E
            elif row == 81:
                col = EMBER_M
            elif row == 87:
                col = CHAR_E
            else:
                col = EMBER_L if (x + row) % 3 == 0 else CHAR_D
            g[row][x] = col

    for row in range(89, 106):
        w = 12
        left = CX - w // 2
        right = left + w
        band = ((row - 89) // 2) % 2
        for x in range(left, right):
            if x == left or x == right - 1:
                col = CHAR_E
            else:
                col = EMBER_L if band == 0 else CHAR_D
            g[row][x] = col

    for row in range(107, 112):
        w = 14 if row < 110 else 12
        left = CX - w // 2
        right = left + w
        for x in range(left, right):
            col = CHAR_E if (x == left or x == right - 1) else EMBER_L
            if abs(x - CX) < 2:
                col = EMBER_H
            g[row][x] = col

    return g


# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────
def main() -> None:
    # __file__ is scripts/tools/gen_weapons.py; go up two levels to reach project root
    base = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "sprites")
    base = os.path.normpath(base)
    os.makedirs(base, exist_ok=True)

    tiers = [
        ("weapon_forca1", gen_t1, gen_t1_fire),
        ("weapon_forca2", gen_t2, gen_t2_fire),
        ("weapon_forca3", gen_t3, gen_t3_fire),
        ("weapon_forca4", gen_t4, gen_t4_fire),
        ("weapon_forca5", gen_t5, gen_t5_fire),
        ("weapon_forca6", gen_t6, gen_t6_fire),
    ]

    for name, gen_normal, gen_fire in tiers:
        path_normal = os.path.join(base, f"{name}.png")
        with open(path_normal, "wb") as f:
            f.write(encode_png(gen_normal()))
        print(f"Gerado: {path_normal}")

        path_fire = os.path.join(base, f"{name}_fogo.png")
        with open(path_fire, "wb") as f:
            f.write(encode_png(gen_fire()))
        print(f"Gerado: {path_fire}")


if __name__ == "__main__":
    main()
