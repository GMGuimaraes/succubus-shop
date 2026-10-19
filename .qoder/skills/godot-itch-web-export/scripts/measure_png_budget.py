#!/usr/bin/env python3
"""Orcamento de textura para itch.io: soma pixels lendo so o IHDR de cada PNG (sem decodificar).

Uso: python measure_png_budget.py <dir1> [dir2 ...]
Medir antes de estimar: no succubus-shop a estimativa de 155 MB ficou na metade da medida
(2026-10-18: 667 PNG / 169,60 Mpx / 274,9 MB em disco). Limite da itch.io: cada arquivo
extraido <= 200 MB (na pratica e o .pck).
"""
import os
import struct
import sys

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def png_size(path):
    try:
        with open(path, "rb") as fh:
            head = fh.read(33)
        if not head.startswith(PNG_MAGIC) or head[12:16] != b"IHDR":
            return None
        width, height = struct.unpack(">II", head[16:24])
        return width, height
    except OSError:
        return None


def main():
    if len(sys.argv) < 2:
        print("uso: measure_png_budget.py <dir1> [dir2 ...]")
        return 2

    total_px = total_n = total_bytes = bad = 0
    per_dir = {}
    for root_dir in sys.argv[1:]:
        if not os.path.isdir(root_dir):
            print(f"ignorado (nao e diretorio): {root_dir}")
            continue
        d_px = d_n = d_bytes = 0
        for dirpath, _, filenames in os.walk(root_dir):
            for name in filenames:
                if name.lower().endswith(".png"):
                    path = os.path.join(dirpath, name)
                    size = png_size(path)
                    if size is None:
                        bad += 1
                        continue
                    w, h = size
                    d_px += w * h
                    d_n += 1
                    try:
                        d_bytes += os.path.getsize(path)
                    except OSError:
                        pass
        per_dir[root_dir] = (d_px, d_n, d_bytes)
        total_px += d_px
        total_n += d_n
        total_bytes += d_bytes

    for d, (px, n, nbytes) in sorted(per_dir.items(), key=lambda kv: -kv[1][0]):
        print(f"{px / 1e6:>10.2f} Mpx  {n:>5} png  {nbytes / 1e6:>8.1f} MB em disco  {d}")

    print(f"\nTOTAL: {total_n} PNG, {total_px / 1e6:.2f} Mpx, {total_bytes / 1e6:.2f} MB em disco")
    if bad:
        print(f"aviso: {bad} arquivo(s) .png sem IHDR valido ignorado(s)")

    # Ordem de grandeza (succubus-shop medido em 2026-10-18: 274,9 MB de PNG para
    # 169,60 Mpx => ~1,6 B/px em disco, nao 0,96). O .pck com compressao VRAM NAO segue esse numero
    # -- por isso o passo 5 do SKILL.md manda medir o .pck exportado, nao confiar aqui.
    est_mb = total_bytes / 1e6
    print(f"\nLimite itch.io: cada arquivo extraido <= 200 MB (tipicamente o .pck).")
    print(f"Arte em PNG soma {est_mb:.1f} MB em disco -- se >= ~100 MB, confira se o preset Web "
          f"tem for_desktop E for_mobile (dobro no .pck) e rode o export de verdade para medir.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
