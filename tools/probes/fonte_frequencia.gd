extends SceneTree

## Harness de frequência: mede QUANTA vez uma fiação de fonte cai, não se cai.
##
## Por que existe: o passo 2 de `tools/probes/fonte.gd` passou a morrer um FATAL do
## TextServer ("Index 171 is out of bounds (size() = 170)", core/templates/cowdata.h:197)
## em cerca de metade dos processos — e a primeira leitura culpou a cadeia de duas fontes
## embarcadas. A frequência absolveu a cadeia: `flat` 4/8, `nested` 5/8, `emoji` 5/8 e
## `none` (nenhuma fiação) 5/12. O que decide é o par de controles: com o mesmo Label em
## ASCII as três variantes ficam limpas (0/12), e sem a cena do jogo no tree o Label de
## 84 símbolos também nunca cai (0/12). Ou seja, o gatilho é um Label novo com glifos raros
## entrando numa árvore de jogo que já roda — caminho do motor no Windows headless, não do
## recurso. A rota publicada (passo 3 de `fonte.gd`: jogo + UI + 200 tiques com a cadeia
## montada) mediu 6/6 limpa, e 6/6 limpa sem cadeia, com `MEDIDA` idêntica nos dois lados.
##
## Um processo = uma amostra. O laço de fora conta os crashes; por isso cada variante roda
## numa célula separada do shell, com o save descartável limpo entre as rodadas.
##
## Uso (uma célula; repita trocando VARIO/TEXTO/ROTULO e conte as saídas `AMOSTRA|`):
##   env APPDATA="D:\\Downloads\\tmp-userdata" VARIO=flat JOGO=1 ROTULO=1 \
##     godot --headless --path . --quit-after 900 -s res://tools/probes/fonte_frequencia.gd
## Env: VARIO=none|flat|nested|emoji, JOGO=0 tira a cena do jogo, ROTULO=0 tira o Label,
##      TEXTO=ascii troca os 84 símbolos por letras, TAM=<px> muda o corpo (padrão 64).
## O arquivo de símbolos lido é `D:/Downloads/tmp-userdata/emoji_usados.txt` (hex por linha,
## um codepoint): os 84 codepoints não-ASCII dos `.gd` do projeto que a sonda considera os
## difíceis — emoji e símbolos de interface (♥ ★ ☰ ✓ ✦ ▸ ░ █ ─), e não as letras acentuadas
## do português, que a fonte padrão do motor já desenha. É a mesma lista que `fonte.gd` usa.

const EMOJI := "res://fonts/NotoColorEmoji-Colr.ttf"
const MONO := "res://fonts/DejaVuSans.ttf"
const SIMBOLOS := "D:/Downloads/tmp-userdata/emoji_usados.txt"


func _initialize() -> void:
	var vario := OS.get_environment("VARIO")
	var com_jogo := OS.get_environment("JOGO") != "0"
	var com_rotulo := OS.get_environment("ROTULO") != "0"
	var tam := int(OS.get_environment("TAM"))
	if tam <= 0:
		tam = 64
	var emoji := load(EMOJI) as FontFile
	var mono := load(MONO) as FontFile
	var base := ThemeDB.fallback_font
	if vario == "flat":
		base.set_fallbacks([emoji, mono])
	elif vario == "nested":
		emoji.set_fallbacks([mono])
		base.set_fallbacks([emoji])
	elif vario == "emoji":
		base.set_fallbacks([emoji])
	elif vario == "none":
		pass
	else:
		print("VARIO invalido")
		quit()
		return
	print("M|wired")
	var pai: Node = get_root()
	if com_jogo:
		var game := (load("res://main.tscn") as PackedScene).instantiate()
		get_root().add_child(game)
		await _frames(3)
		pai = game
	print("M|jogo")
	if com_rotulo:
		var rot := Label.new()
		print("M|label_new")
		rot.text = _texto()
		print("M|label_text")
		rot.add_theme_font_size_override("font_size", tam)
		pai.add_child(rot)
	print("M|label")
	await _frames(14)
	print("M|frames")
	var n: int = emoji.get_texture_count(0, Vector2i(tam, 0))
	var m: int = mono.get_texture_count(0, Vector2i(tam, 0))
	print("AMOSTRA|%s|jogo=%d|rotulo=%d|emoji_atlas=%d|mono_atlas=%d" % [vario, 1 if com_jogo else 0, 1 if com_rotulo else 0, n, m])
	print("M|antes_do_quit")
	quit()


## Os 84 codepoints que o jogo imprime, um por linha em hex.
func _texto() -> String:
	if OS.get_environment("TEXTO") == "ascii":
		return "Abc 123 def ghi jkl"
	var f := FileAccess.open(SIMBOLOS, FileAccess.READ)
	if f == null:
		return "🏆 ✓ ☰"
	var s := ""
	while not f.eof_reached():
		var linha := f.get_line().strip_edges()
		if linha != "":
			var c := linha.hex_to_int()
			if c > 0:
				s += char(c) + " "
	f.close()
	return s


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
