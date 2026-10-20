#!/usr/bin/env python3
"""Verifica o .zip de macOS que o Godot exporta do Windows.

O export de macOS nao exige um Mac, mas duas coisas so se provam lendo o arquivo:

1. o binario dentro do bundle tem de nascer com o bit de execucao. A doc oficial e explicita
   sobre a armadilha ("Due to file system limitations, .app bundles exported from Windows lack
   the executable flag and won't run on macOS. Projects exported as .zip are not affected") --
   entao quem confere e o modo unix de cada entrada, nao a presenca da pasta;
2. "universal" tem de ser Universal 2 de verdade (x86_64 + arm64 no mesmo Mach-O), porque e o
   que autoriza dizer que um so arquivo cobre MacBook Intel e MacBook Apple Silicon.

Reprova tambem qualquer entrada descompactada acima de 200 MB, que e o teto da itch.io.

Uso:
    python tools/check_macho_fat.py ".export/macos/Succubus Shop.zip"

Saida em ASCII de proposito: o stdout do Windows aqui e cp1252 e acento viraria mojibake.
"""

import struct
import sys
import zipfile

LIMITE_ITCH = 200 * 1000 * 1000  # 200 MB por arquivo descompactado, medido na doc da itch

CPUS = {
    7: "x86_64 (Intel)",
    12: "arm64 (Apple Silicon)",
    14: "x86_64h",
    0x01000007: "x86_64 (Intel)",
    0x0100000C: "arm64 (Apple Silicon)",
    0x0100000E: "arm64e",
}
# Magias Mach-O: fat (multi-arch, sempre big-endian) e thin (uma arch so, little-endian).
FAT_BE = 0xCAFEBABE
FAT64_BE = 0xCAFEBABF
THIN_64_LE = 0xFEEDFACF
THIN_32_LE = 0xFEEDFACE


def arqs_do_macho(blob):
    """Le a cabecalho Mach-O e devolve a lista de archs com nome, offset e tamanho."""
    if len(blob) < 8:
        return []
    magic = struct.unpack(">I", blob[:4])[0]
    if magic in (FAT_BE, FAT64_BE):
        n = struct.unpack(">I", blob[4:8])[0]
        out = []
        for i in range(n):
            if magic == FAT64_BE:
                base = 8 + i * 32
                cputype = struct.unpack(">I", blob[base:base + 4])[0]
                off = struct.unpack(">Q", blob[base + 8:base + 16])[0]
                size = struct.unpack(">Q", blob[base + 16:base + 24])[0]
            else:
                base = 8 + i * 20
                cputype = struct.unpack(">I", blob[base:base + 4])[0]
                off = struct.unpack(">I", blob[base + 8:base + 12])[0]
                size = struct.unpack(">I", blob[base + 12:base + 16])[0]
            out.append((CPUS.get(cputype, "cpu 0x%X" % cputype), off, size))
        return out
    thin = struct.unpack("<I", blob[:4])[0]
    if thin in (THIN_64_LE, THIN_32_LE):
        cputype = struct.unpack("<I", blob[4:8])[0]
        return [(CPUS.get(cputype, "cpu 0x%X" % cputype), 0, len(blob))]
    return []


def main(caminho):
    try:
        z = zipfile.ZipFile(caminho)
    except OSError as erro:
        print("FALHA: nao abri %s (%s)" % (caminho, erro))
        return 1
    infos = z.infolist()
    if not infos:
        print("FALHA: zip vazio")
        return 1

    problemas = []
    binarios = []
    for info in infos:
        modo = (info.external_attr >> 16) & 0o7777
        if info.file_size > LIMITE_ITCH:
            problemas.append("passa dos 200 MB da itch: %s" % info.filename)
        if info.create_system != 3:
            problemas.append("entrada sem sistema Unix (modo ignorado): %s" % info.filename)
        if "/Contents/MacOS/" in info.filename and not info.is_dir():
            binarios.append((info, modo))

    plist = [i for i in infos if i.filename.endswith("/Contents/Info.plist")]
    if plist:
        texto = z.read(plist[0].filename).decode("utf-8", "replace")
        for chave in ("CFBundleIdentifier", "CFBundleShortVersionString", "CFBundleName"):
            marcador = "<key>%s</key>" % chave
            if marcador in texto:
                cauda = texto.split(marcador, 1)[1]
                valor = cauda.split("<string>", 1)[1].split("</string>", 1)[0] if "<string>" in cauda else "?"
                print("%s = %s" % (chave, valor))
            else:
                problemas.append("Info.plist sem %s" % chave)
    else:
        problemas.append("sem Info.plist: isto nao e um bundle .app")

    if not binarios:
        problemas.append("nenhum executavel em Contents/MacOS/")
    for info, modo in binarios:
        if not (modo & 0o111):
            problemas.append("sem bit de execucao (modo %04o): %s" % (modo, info.filename))
        blob = z.read(info.filename)[:64]
        arqs = arqs_do_macho(blob)
        print("executavel %s: %d bytes descompactados, modo %04o" % (
            info.filename.rsplit("/", 1)[-1], info.file_size, modo))
        if not arqs:
            problemas.append("Mach-O nao reconhecido em %s" % info.filename)
        for nome, off, size in arqs:
            print("   slice: %-26s offset %12d  tamanho %12d" % (nome, off, size))
        nomes = {a[0] for a in arqs}
        falta = {"x86_64 (Intel)", "arm64 (Apple Silicon)"} - nomes
        if falta:
            problemas.append("Universal 2 incompleto, falta: %s" % ", ".join(sorted(falta)))

    print("entradas: %d, tamanho do zip: %d bytes" % (len(infos), sum(i.compress_size for i in infos)))
    if problemas:
        print("REPROVADO:")
        for p in problemas:
            print("   - " + p)
        return 1
    print("APROVADO: bundle valido, Universal 2 com as duas archs, execucao preservada.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Uso: python tools/check_macho_fat.py <caminho do .zip>")
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
