#!/usr/bin/env python3
"""Aplica o orçamento de textura que faz o build web caber na itch.io.

Medido nesta árvore (676 texturas, 169,60 Mpx) com o importador do próprio motor:

| modo                     | B/texel medido     | arte no .pck               |
|--------------------------|--------------------|----------------------------|
| 0 sem perdas (era assim) | 1,07               | 204 MB                     |
| 1 com perdas q=0,8       | 0,13 (opaca)       |  25 MB                     |
| 2 compressão de VRAM     | 0,50 POR CONJUNTO  | 85 MB (um) / 170 MB (dois) |
| 3 Basis/UASTC            | 3,00               | 508 MB                     |

O `.pck` web exportado mediu 207,33 MB e a itch.io limita cada arquivo extraído a 200 MB
(500 MB no total). A alavanca escolhida é o modo 1, com qualidade diferente por classe,
porque as texturas com alfa são justamente o recorte dos personagens e dos objetos de
cenário — é a borda que o olho pega:

* opacas   -> q=0,85 (fundos pintados; medido 0,16-0,28 B/texel)
* com alfa -> q=0,92 (medido 0,36-0,39 B/texel)

Os PNGs do repositório não mudam: só o que entra no `.ctex`. `--reset` devolve o modo 0
e o import seguinte re-encodeia sem perdas.

Uso:
  python tools/set_texture_budget.py            # aplica e imprime a projeção
  python tools/set_texture_budget.py --reset    # volta tudo para sem perdas
Depois: godot --headless --path . --import  (re-encodeia) e o export de sempre.
"""
import glob
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODE_LOSSY = 1
MODE_LOSSLESS = 0
Q_OPAQUE = "0.85"
Q_ALPHA = "0.92"
# Médias das faixas medidas acima. Sprite pequeno paga mais por texel (o bloco do
# compressor é tamanho fixo e a sobra é preenchida), então a classe com alfa fica mais alta.
# Revalidar com o
# export real antes de publicar número novo em README ou doc.
BPP_LOSSLESS = 1.07
BPP_LOSSY_OPAQUE = 0.21
BPP_LOSSY_ALPHA = 0.37


def textura(imp):
    """(source_file, com_alfa, pixels) ou None se não é textura raster com PNG por trás."""
    txt = open(imp, encoding="utf-8", errors="ignore").read()
    if 'importer="texture"' not in txt:
        return None
    src = re.search(r'source_file="([^"]+)"', txt)
    if not src:
        return None
    rel = src[1].replace("res://", "")
    full = os.path.join(ROOT, rel.replace("/", os.sep))
    if not rel.lower().endswith(".png") or not os.path.exists(full):
        return None
    with open(full, "rb") as f:
        head = f.read(26)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    w, h = struct.unpack(">II", head[16:24])
    return rel, head[25] in (4, 6), w * h


def gravar(imp, modo, qualidade):
    linhas = open(imp, encoding="utf-8").read().splitlines(True)
    for i, l in enumerate(linhas):
        if l.startswith("compress/mode="):
            linhas[i] = "compress/mode=%d\n" % modo
        elif modo == MODE_LOSSY and l.startswith("compress/lossy_quality="):
            linhas[i] = "compress/lossy_quality=%s\n" % qualidade
    with open(imp, "w", encoding="utf-8", newline="") as f:
        f.writelines(linhas)


def main():
    reset = "--reset" in sys.argv
    tocadas = opacas = alfa = 0
    px_opaca = px_alfa = 0
    for imp in glob.glob(os.path.join(ROOT, "**", "*.import"), recursive=True):
        info = textura(imp)
        if info is None:
            continue
        _, com_alfa, px = info
        tocadas += 1
        if reset:
            gravar(imp, MODE_LOSSLESS, None)
            continue
        gravar(imp, MODE_LOSSY, Q_ALPHA if com_alfa else Q_OPAQUE)
        if com_alfa:
            alfa += 1
            px_alfa += px
        else:
            opacas += 1
            px_opaca += px
    if reset:
        print("%d .import voltaram para compress/mode=0" % tocadas)
        return
    antes = (px_opaca + px_alfa) * BPP_LOSSLESS / 1e6
    agora = (px_opaca * BPP_LOSSY_OPAQUE + px_alfa * BPP_LOSSY_ALPHA) / 1e6
    print("%d opacas (%.1f Mpx) em q=%s, %d com alfa (%.1f Mpx) em q=%s"
          % (opacas, px_opaca / 1e6, Q_OPAQUE, alfa, px_alfa / 1e6, Q_ALPHA))
    print("projeção da arte no .pck: %.1f MB -> %.1f MB (sem contar scripts e áudio)" % (antes, agora))
    print("re-encodeia com:  godot --headless --path . --import")


if __name__ == "__main__":
    main()
