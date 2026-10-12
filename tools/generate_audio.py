#!/usr/bin/env python3
"""Gera os sons e a música do Succubus Shop por síntese (Python puro, sem dependências).

Tudo é criado por código, então não há direitos autorais de terceiros.
Uso: python3 tools/generate_audio.py   (grava em audio/)
"""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")


def hz(semitones_from_a4):
    return 440.0 * 2 ** (semitones_from_a4 / 12.0)


def mix(buf, sig, start, wrap=False):
    n = len(buf)
    for i, v in enumerate(sig):
        j = start + i
        if wrap:
            j %= n
        elif j >= n:
            break
        buf[j] += v


def bell(freq, dur, vol=0.6, decay=6.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / 0.004) * math.exp(-decay * t)
        v = math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(2 * math.pi * freq * 2.76 * t) + 0.15 * math.sin(2 * math.pi * freq * 5.4 * t)
        out.append(v * env * vol)
    return out


def soft(freq, dur, vol=0.5, vibrato=0.0):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / 0.03) * min(1.0, (dur - t) / 0.12)
        f = freq * (1 + vibrato * math.sin(2 * math.pi * 5.5 * t))
        out.append((math.sin(2 * math.pi * f * t) + 0.25 * math.sin(4 * math.pi * f * t)) * env * vol)
    return out


def noise(dur, vol=0.3, decay=30.0, rng=None):
    rng = rng or random.Random(1)
    n = int(SR * dur)
    return [(rng.random() * 2 - 1) * vol * math.exp(-decay * i / SR) for i in range(n)]


def sweep(f0, f1, dur, vol=0.4):
    n = int(SR * dur)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        phase += 2 * math.pi * (f0 + (f1 - f0) * t) / SR
        out.append(math.sin(phase) * vol * min(1.0, i / 300) * (1 - t * 0.6) * (1 + 0.3 * math.sin(2 * math.pi * 18 * i / SR)))
    return out


def pluck(freq, dur, vol=0.5, decay=0.996, rng=None):
    rng = rng or random.Random(7)
    size = max(2, int(SR / freq))
    ring = [rng.random() * 2 - 1 for _ in range(size)]
    out = []
    for i in range(int(SR * dur)):
        k = i % size
        v = ring[k]
        ring[k] = decay * 0.5 * (v + ring[(k + 1) % size])
        out.append(v * vol * min(1.0, (dur * SR - i) / 2000))
    return out


def save(name, sig, peak=0.8):
    m = max(1e-9, max(abs(v) for v in sig))
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v / m * peak)) * 32767)) for v in sig))
    print("%-14s %.2fs  %d KB" % (name, len(sig) / SR, os.path.getsize(path) // 1024))


def build_sfx():
    rng = random.Random(3)
    b = [0.0] * int(SR * 0.06); mix(b, noise(0.03, 0.6, 90, rng), 0); mix(b, bell(1500, 0.05, 0.3, 60), 0); save("click", b, 0.55)
    b = [0.0] * int(SR * 0.56); mix(b, bell(hz(7), 0.4, 0.6), 0); mix(b, bell(hz(12), 0.45, 0.6), int(SR * 0.07)); save("coin", b)
    b = [0.0] * int(SR * 0.55)
    for k in range(6):
        f = rng.uniform(300, 750); mix(b, sweep(f, f * 1.5, 0.07, 0.4), int(SR * 0.07 * k))
    mix(b, noise(0.5, 0.12, 6, rng), 0); save("craft", b, 0.7)
    b = [0.0] * int(SR * 0.3); mix(b, soft(hz(-21), 0.25, 0.9), 0); mix(b, noise(0.08, 0.5, 40, rng), 0); save("buy", b, 0.75)
    b = [0.0] * int(SR * 1.3)
    for k, s in enumerate([-9, -5, -2, 3]):
        mix(b, bell(hz(s), 0.9 if k == 3 else 0.35, 0.55, 4), int(SR * 0.13 * k))
    save("levelup", b)
    b = [0.0] * int(SR * 0.7); mix(b, bell(hz(-2), 0.4, 0.6), 0); mix(b, bell(hz(3), 0.5, 0.6), int(SR * 0.1)); mix(b, bell(hz(15), 0.4, 0.25, 9), int(SR * 0.16)); save("happy", b)
    b = [0.0] * int(SR * 1.0); mix(b, soft(hz(-5), 0.45, 0.6, 0.012), 0); mix(b, soft(hz(-9), 0.55, 0.6, 0.015), int(SR * 0.35)); save("sad", b, 0.7)
    b = [0.0] * int(SR * 1.2)
    for k, s in enumerate([3, 7, 10]):
        mix(b, bell(hz(s), 0.8, 0.5, 5), int(SR * 0.16 * k))
    save("rare", b)
    b = [0.0] * int(SR * 1.1); mix(b, sweep(400, 1700, 0.45, 0.5), 0); mix(b, bell(hz(15), 0.7, 0.55, 5), int(SR * 0.4)); save("talent", b)


# Melodia em Ré dórico (semitons a partir de D4); None = pausa. 8 colcheias por compasso.
N = None
MELODY = [
    [7, 9, 12, 9, 7, 5, 7, N], [5, 7, 9, 7, 5, 3, 2, N], [7, 9, 12, 14, 12, 9, 7, 9], [10, 9, 7, 5, 7, N, N, N],
    [2, 3, 5, 7, 9, 7, 5, 3], [2, 5, 7, 10, 9, 7, 5, 7], [9, 12, 14, 12, 10, 9, 7, 5], [7, 5, 3, 2, 0, N, N, N],
    [12, 14, 15, 14, 12, 10, 9, 10], [7, 9, 10, 12, 10, 9, 7, N], [5, 7, 9, 10, 12, 10, 9, 7], [5, 3, 2, 3, 5, N, 7, N],
    [14, 12, 10, 12, 14, 12, 10, 9], [7, 9, 10, 9, 7, 5, 3, 5], [7, 9, 12, 9, 7, 5, 3, 2], [0, N, 2, N, 0, N, N, N],
]
BASS = [0, -2, 0, -7, -2, 0, -2, 0, 0, -2, -5, -7, 0, -2, -7, 0]


def build_music(bpm=84):
    eighth = 60.0 / bpm / 2
    step = int(SR * eighth)
    total = step * 8 * len(MELODY)
    buf = [0.0] * total
    d4 = -7  # D4 em semitons a partir de A4
    for bar, notes in enumerate(MELODY):
        t0 = bar * 8 * step
        for i, s in enumerate(notes):
            if s is not None:
                mix(buf, pluck(hz(d4 + s), 1.0, 0.5, 0.9965), t0 + i * step, wrap=True)
        root = d4 - 12 + BASS[bar]
        mix(buf, pluck(hz(root), 1.6, 0.55, 0.998), t0, wrap=True)
        mix(buf, pluck(hz(root + 7), 1.2, 0.4, 0.998), t0 + 4 * step, wrap=True)
    save("music_tavern", buf, 0.6)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    build_sfx()
    build_music()
