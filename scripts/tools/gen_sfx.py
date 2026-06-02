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


def _pitch_jitter(amount=0.06):
    """Leve aleatoriedade de pitch por som (±amount) p/ não soar repetitivo."""
    return 1.0 + random.uniform(-amount, amount)


def attack_wav():
    # Whoosh aéreo: ruído com filtro abrindo (cutoff sobe) e pitch caindo no fim.
    n = int(SAMPLE_RATE * 0.2)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / n
        # cutoff do low-pass abre ao longo do som: começa abafado, fica aéreo.
        cut = 0.25 + 0.55 * t
        raw = _noise()
        prev = prev * (1.0 - cut) + raw * cut
        out.append(prev * _env(i, n, 0.02, 0.6) * 0.5)
    return out


def hit_wav():
    # Punch carnudo: thump grave (corpo) + snap mid (ataque) + ruído filtrado.
    n = int(SAMPLE_RATE * 0.16)
    out = []
    j = _pitch_jitter()
    f_thump = 62.0 * j   # fundamental grave que "enche"
    f_snap = 260.0 * j   # camada mid do impacto
    prev = 0.0
    for i in range(n):
        t = i / SAMPLE_RATE
        e = _env(i, n, 0.004, 0.85)
        # thump cai um pouco de pitch (pancada que assenta)
        thump = math.sin(2 * math.pi * f_thump * (1.0 - 0.15 * (i / n)) * t)
        snap = math.sin(2 * math.pi * f_snap * t) * math.exp(-22.0 * t)
        prev = prev * 0.5 + _noise() * 0.5  # ruído um pouco filtrado
        body = 0.5 * thump + 0.22 * snap + 0.28 * prev
        out.append(body * e * 0.72)
    return out


def dodge_wav():
    # Whoosh rápido com filtro abrindo: aéreo, curto e limpo.
    n = int(SAMPLE_RATE * 0.2)
    out = []
    prev = 0.0
    for i in range(n):
        t = i / n
        cut = 0.3 + 0.5 * t
        raw = _noise()
        prev = prev * (1.0 - cut) + raw * cut
        e = max(0.0, 1.0 - t ** 0.5)
        out.append(prev * e * 0.45)
    return out


def timing_perfect_wav():
    # Chime que brilha: voz base + oitava, com leve sweep ascendente (recompensa).
    n = int(SAMPLE_RATE * 0.18)
    out = []
    j = _pitch_jitter(0.03)
    base = 1320.0 * j
    for i in range(n):
        t = i / SAMPLE_RATE
        bend = 1.0 + 0.05 * (i / n)  # sobe ~5% ao longo do som (brilho)
        e = math.exp(-15.0 * t)
        s = (
            0.55 * math.sin(2 * math.pi * base * bend * t)
            + 0.30 * math.sin(2 * math.pi * base * 1.5 * bend * t)  # quinta
            + 0.15 * math.sin(2 * math.pi * base * 2.0 * bend * t)  # oitava
        )
        out.append(s * e * 0.5)
    return out


def death_wav():
    # Growl descendente: sawtooth com pitch caindo + textura de ruído modulado.
    n = int(SAMPLE_RATE * 0.42)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        freq = 200 * (1.0 - 0.72 * (i / n))
        phase = (t * freq) % 1.0
        saw = 2.0 * phase - 1.0
        sub = math.sin(2 * math.pi * freq * 0.5 * t)  # sub-oitava reforça o grave
        tremolo = 0.7 + 0.3 * math.sin(2 * math.pi * 30 * t)  # textura modulada
        e = _env(i, n, 0.02, 0.5)
        out.append((0.55 * saw + 0.2 * sub + 0.25 * _noise() * tremolo) * e * 0.62)
    return out


def timing_alert_wav():
    # Aviso de vulnerabilidade: dois beeps curtos ascendentes, claros e secos.
    n = int(SAMPLE_RATE * 0.14)
    out = []
    half = n // 2
    for i in range(n):
        t = i / SAMPLE_RATE
        # primeiro beep mais grave, segundo mais agudo (sobe = "agora!").
        freq = 880.0 if i < half else 1320.0
        local = (i % half) / SAMPLE_RATE
        e = math.exp(-26.0 * local)
        out.append(0.5 * math.sin(2 * math.pi * freq * t) * e * 0.5)
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
    _write("timing_alert.wav", timing_alert_wav())
    _write("death.wav", death_wav())
    _write("ui_click.wav", ui_click_wav())
    print("Pronto.")


if __name__ == "__main__":
    main()
