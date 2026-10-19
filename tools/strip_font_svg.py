#!/usr/bin/env python3
"""Recorta as tabelas de emoji que o Godot NAO le de uma fonte sfnt (TTF/OTF).

Por que isto existe: a Noto Color Emoji oficial do `google/fonts` tem 25.332.736
bytes, e 20.288.281 deles (80%) sao a tabela `SVG ` -- um fallback de *navegador*
para emoji vetorial. O rasterizador de texto do Godot 4.7.2 nao le `SVG `: ele le
`COLR` (versao 1) + `CPAL`, medido na sonda `res://_tmp_emoji.gd`, que devolveu
atlas RGBA8 com 3.256 cores distintas e o trofeu em dourado. A tabela que ocupa
quatro quintos do arquivo e justamente a unica que o jogo nao usa.

Isto NAO e subset: cmap, glyf, COLR e CPAL continuam inteiros, com todos os
glifos. So sai o payload `SVG ` (e `sbix`, se houver), o diretorio de tabelas e
reescrito e o `head.checkSumAdjustment` e recomputado na ordem certa -- o arquivo
precisa continuar um sfnt valido, nao apenas "abrir por acidente".

Prova de que o recorte nao mudou o resultado (os dois lados da compara):
  python tools/strip_font_svg.py <original.ttf> <recortada.ttf>
  godot --headless --path . --quit-after 1800 -s res://_tmp_emoji.gd
  # a sonda le FONT_PATH / FONT_PATH_B e compara cobertura, indices e atlas.

Licenca: OFL 1.1 sem Reserved Font Name (conferido em fonts/OFL-NotoColorEmoji.txt,
clausula 3) -- o texto da licenca acompanha a fonte recortada no repositorio.

Procedencia do original:
  https://raw.githubusercontent.com/google/fonts/main/ofl/notocoloremoji/NotoColorEmoji-Regular.ttf
  md5 45d1fb1d47ce3f922e5384468e1391c8, 25.332.736 bytes, medido em 2026-10-18.
"""

import struct
import sys

DESCARTAR = {"SVG ", "sbix"}
HEAD_CHECKSUM_ADJUSTMENT = 8  # offset de checkSumAdjustment dentro da tabela head
SFNT_VERSIONS = (0x00010000, 0x4F54544F, 0x74727565)  # 1.0, 'OTTO', 'true'


def _checksum(blob: bytes) -> int:
	if len(blob) % 4:
		blob = blob + b"\x00" * (4 - len(blob) % 4)
	total = 0
	for i in range(0, len(blob), 4):
		total += struct.unpack_from(">I", blob, i)[0]
	return total & 0xFFFFFFFF


def ler_tabelas(dados: bytes):
	"""(versao, [(tag, checksum, offset, comprimento)]) com validacao de fronteira."""
	if len(dados) < 12:
		raise ValueError("arquivo curto demais para ser um sfnt")
	version, num = struct.unpack_from(">IH", dados, 0)
	if version not in SFNT_VERSIONS:
		raise ValueError("versao sfnt desconhecida: 0x%08X" % version)
	tabelas = []
	for i in range(num):
		off = 12 + 16 * i
		tag = dados[off:off + 4].decode("latin1")
		checksum, t_off, t_len = struct.unpack_from(">III", dados, off + 4)
		if t_off + t_len > len(dados):
			raise ValueError("tabela %s aponta para fora do arquivo" % tag)
		tabelas.append((tag, checksum, t_off, t_len))
	return version, tabelas


def recortar(dados: bytes) -> bytes:
	version, tabelas = ler_tabelas(dados)
	restantes = [t for t in tabelas if t[0] not in DESCARTAR]
	num = len(restantes)
	dir_len = 12 + 16 * num

	# 1) Corpo: cada tabela no seu lugar, 4-byte aligned, com head.checkSumAdjustment = 0.
	corpo = bytearray()
	plan = []  # (tag, checksum_da_tabela, inicio, comprimento, offset_no_corpo)
	for tag, _velho, off, length in restantes:
		blob = dados[off:off + length]
		inicio = dir_len + len(corpo)
		corpo += blob + b"\x00" * (((length + 3) & ~3) - length)
		plan.append((tag, _checksum(blob), inicio, length, inicio - dir_len))
	# head.checkSumAdjustment zerado ANTES de somar o arquivo inteiro.
	for tag, _c, _ini, _len, base in plan:
		if tag == "head":
			corpo[base + HEAD_CHECKSUM_ADJUSTMENT:base + HEAD_CHECKSUM_ADJUSTMENT + 4] = b"\x00\x00\x00\x00"

	# 2) Cabecalho com searchRange/entrySelector/rangeShift ja definitivos, para que
	#    a soma abaixo seja a soma do arquivo FINAL.
	search = (1 << (num.bit_length() - 1)) * 16 if num else 0
	entry = (num.bit_length() - 1) if num else 0
	cab = bytearray(struct.pack(">IHHHH", version, num, search, entry, num * 16 - search))
	diretorio = bytearray()
	for tag, checksum, inicio, length, _base in plan:
		diretorio += tag.encode("latin1") + struct.pack(">III", checksum, inicio, length)

	# 3) Ajuste: total do arquivo tem de dar 0xB1B0AFBA.
	soma = _checksum(bytes(cab) + bytes(diretorio) + bytes(corpo))
	for tag, _c, _ini, _len, base in plan:
		if tag == "head":
			ajuste = (0xB1B0AFBA - soma) & 0xFFFFFFFF
			struct.pack_into(">I", corpo, base + HEAD_CHECKSUM_ADJUSTMENT, ajuste)
	return bytes(cab) + bytes(diretorio) + bytes(corpo)


def main(argv):
	if len(argv) != 3:
		print("uso: python tools/strip_font_svg.py <entrada.ttf> <saida.ttf>")
		return 2
	entrada, saida = argv[1], argv[2]
	with open(entrada, "rb") as f:
		dados = f.read()
	version, tabelas = ler_tabelas(dados)
	print("entrada: %d bytes, %d tabelas, sfnt 0x%08X" % (len(dados), len(tabelas), version))
	for tag, _c, _o, length in tabelas:
		if tag in ("SVG ", "COLR", "CPAL", "CBDT", "CBLC", "glyf", "sbix"):
			print("  %-5s %10d bytes" % (tag, length))
	novo = recortar(dados)
	with open(saida, "wb") as f:
		f.write(novo)
	ganho = len(dados) - len(novo)
	print("saida:   %d bytes (-%.2f MB, -%.1f%%)" % (len(novo), ganho / 1e6, 100.0 * ganho / len(dados)))

	# Rele a saida: o arquivo recortado tem de ser um sfnt lido pelas mesmas regras.
	_v2, t2 = ler_tabelas(novo)
	marcas = sorted(t[0] for t in t2)
	print("releitura: %d tabelas | SVG presente? %s | COLR presente? %s | CPAL presente? %s" % (
		len(t2), "SVG " in marcas, "COLR" in marcas, "CPAL" in marcas))
	if "COLR" not in marcas or "CPAL" not in marcas:
		print("FALHA: sem COLR+CPAL o Godot nao tem como pintar cor.")
		return 1
	if "SVG " in marcas:
		print("FALHA: a tabela SVG continua no arquivo.")
		return 1
	soma_final = _checksum(novo)
	print("checksum total = 0x%08X (esperado 0xB1B0AFBA)" % soma_final)
	if soma_final != 0xB1B0AFBA:
		print("FALHA: checkSumAdjustment nao fecha -- sfnt invalido.")
		return 1
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv))
