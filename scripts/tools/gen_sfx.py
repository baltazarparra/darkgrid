#!/usr/bin/env python3
"""Gera os SFX de combate de caipora.

Fallback para jsfxr (indisponível via CLI). Usa apenas a stdlib (wave/math/struct)
para sintetizar ondas básicas. Saída: WAV mono 22050Hz 16-bit em assets/audio/sfx/.

Uso: python3 scripts/tools/gen_sfx.py
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 22050
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")


def _write(name, samples):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(frames)
    print(f"  {name}: {len(samples)} samples ({len(samples) * 2} bytes)")


def _env(i, n, attack=0.01, release=0.3):
    """Envelope ataque/decay linear simples (0..1)."""
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = 1.0 - max(0.0, (t - (1.0 - release)) / release) if release > 0 else 1.0
    return max(0.0, a * r)


def _noise():
    return random.uniform(-1.0, 1.0)


def attack_wav():
    # Whoosh: ruído filtrado com pitch caindo.
    n = int(SAMPLE_RATE * 0.2)
    out = []
    prev = 0.0
    for i in range(n):
        raw = _noise()
        prev = prev * 0.6 + raw * 0.4  # low-pass leve
        out.append(prev * _env(i, n, 0.02, 0.6) * 0.5)
    return out


def hit_wav():
    # Punch seco: burst de ruído + tom grave curto.
    n = int(SAMPLE_RATE * 0.15)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = _env(i, n, 0.005, 0.8)
        tone = math.sin(2 * math.pi * 90 * t)
        out.append((0.6 * _noise() + 0.4 * tone) * e * 0.7)
    return out


def dodge_wav():
    # Whoosh rápido com pitch subindo, depois silêncio.
    n = int(SAMPLE_RATE * 0.2)
    out = []
    prev = 0.0
    for i in range(n):
        raw = _noise()
        prev = prev * 0.7 + raw * 0.3
        e = max(0.0, 1.0 - (i / n) ** 0.5)
        out.append(prev * e * 0.45)
    return out


def timing_perfect_wav():
    # Chime: duas senoides altas com decay.
    n = int(SAMPLE_RATE * 0.15)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-18.0 * t)
        s = 0.6 * math.sin(2 * math.pi * 1320 * t) + 0.4 * math.sin(2 * math.pi * 1976 * t)
        out.append(s * e * 0.5)
    return out


def death_wav():
    # Growl descendente: sawtooth com pitch caindo.
    n = int(SAMPLE_RATE * 0.4)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 220 * (1.0 - 0.7 * (i / n))
        phase = (t * freq) % 1.0
        saw = 2.0 * phase - 1.0
        e = _env(i, n, 0.02, 0.5)
        out.append((0.7 * saw + 0.3 * _noise()) * e * 0.6)
    return out


def ui_click_wav():
    # Click seco muito curto.
    n = int(SAMPLE_RATE * 0.05)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        e = math.exp(-60.0 * t)
        out.append((0.5 * _noise() + 0.5 * math.sin(2 * math.pi * 800 * t)) * e * 0.5)
    return out


def main():
    random.seed(42)
    print("Gerando SFX de combate...")
    _write("attack.wav", attack_wav())
    _write("hit.wav", hit_wav())
    _write("dodge.wav", dodge_wav())
    _write("timing_perfect.wav", timing_perfect_wav())
    _write("death.wav", death_wav())
    _write("ui_click.wav", ui_click_wav())
    print("Pronto.")


if __name__ == "__main__":
    main()
