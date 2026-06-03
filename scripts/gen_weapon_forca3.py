"""Gera assets/sprites/weapon_forca3.png — espada de folha de madeira 32x32."""
import struct, zlib, os

def png_chunk(tag: bytes, data: bytes) -> bytes:
    c = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", c)

def encode_png(pixels: list[list[tuple[int,int,int,int]]]) -> bytes:
    h, w = len(pixels), len(pixels[0])
    raw = b""
    for row in pixels:
        raw += b"\x00"
        for r, g, b, a in row:
            raw += bytes([r, g, b, a])
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2 | (1 << 2), 0, 0, 0)  # RGBA
    # fix: bit depth 8, color type 6 (RGBA)
    ihdr = struct.pack(">II", w, h) + bytes([8, 6, 0, 0, 0])
    compressed = zlib.compress(raw, 9)
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", compressed)
        + png_chunk(b"IEND", b"")
    )

# Paleta madeira (r, g, b, a)
TRANSP     = (  0,   0,   0,   0)
WOOD_DARK  = ( 41,  18,   3, 255)   # borda / sombra
WOOD_MID   = ( 82,  43,  10, 255)   # corpo da lâmina
WOOD_LIGHT = (163,  94,  36, 255)   # luz da lâmina
WOOD_HI    = (212, 152,  80, 255)   # highlight central
BARK_DARK  = ( 25,  15,   5, 255)   # cabo escuro
BARK_MID   = ( 46,  28,  13, 255)   # cabo médio
VEIN       = ( 55,  28,   5, 255)   # veio de madeira

# Desenho pixel-a-pixel 32×32
# X=col, Y=row (0=topo). Folha lanceolada + cabo curto.
# Larguras da lâmina por linha (simétrico em torno de col=15):
#   row 0-1:  ponta (2px)
#   row 2-3:  afila (4px)
#   row 4-7:  cresce (8-14px)
#   row 8-13: máx (16-18px)
#   row 14-19: afila de volta (14→6px)
#   row 20-25: base da lâmina (4px)
#   row 26-31: cabo (6px)

BLADE_WIDTHS = [
    2, 2,       # 0-1
    4, 4,       # 2-3
    8, 10, 12, 14,  # 4-7
    16, 18, 18, 18, 18, 16,  # 8-13
    14, 12, 10, 8, 6, 4,     # 14-19
    4, 4, 4, 4, 4, 4,         # 20-25 (base + transição)
]
HANDLE_ROWS = range(26, 32)
HANDLE_W    = 6
CX          = 15  # centro X (0-indexed)

def blade_row(row: int, w: int) -> list[tuple]:
    left  = CX - w // 2
    right = left + w
    mid   = CX
    line: list[tuple] = [TRANSP] * 32
    for x in range(32):
        if x < left or x >= right:
            continue
        if x == left or x == right - 1:
            line[x] = WOOD_DARK
        elif x == left + 1 or x == right - 2:
            line[x] = WOOD_MID
        elif x == mid:
            line[x] = VEIN  # veio central
        elif x in (mid - 1, mid + 1):
            line[x] = WOOD_LIGHT
        else:
            line[x] = WOOD_HI
    return line

def handle_row(row: int) -> list[tuple]:
    left  = CX - HANDLE_W // 2
    right = left + HANDLE_W
    line: list[tuple] = [TRANSP] * 32
    for x in range(32):
        if x < left or x >= right:
            continue
        if x == left or x == right - 1:
            line[x] = BARK_DARK
        else:
            line[x] = BARK_MID
    return line

pixels: list[list[tuple]] = []
for row in range(32):
    if row < len(BLADE_WIDTHS):
        pixels.append(blade_row(row, BLADE_WIDTHS[row]))
    else:
        pixels.append(handle_row(row))

out = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites", "weapon_forca3.png")
out = os.path.normpath(out)
with open(out, "wb") as f:
    f.write(encode_png(pixels))
print(f"Gerado: {out}  ({32}x{32}px)")
