extends SceneTree

## Prova a rota das fontes embarcadas no build web, em três passos, e fecha com a A/B de
## economia.
##
## 1) Cobertura: `load()` de `res://` (o caminho real do `.pck`, não o `load_dynamic_font`
##    de arquivo solto) devolve FontFile com paleta CPAL; a colorida cobre 63 dos 84
##    símbolos que o jogo imprime, a monocromática cobre os 21 que sobraram e a união fecha
##    84/84. Faltando qualquer um, o web mostra tofu.
## 2) Cadeia: a função do jogo monta o fallback do `ThemeDB` com a emoji PRIMEIRO. Isso é
##    asserção, não detalhe: a DejaVu também desenha vários dos 63 codepoints da Noto e, se
##    vier antes, o emoji sai preto-e-branco. A prova é o atlas de cada fonte depois de um
##    Label SEM override de fonte: o da emoji em RGBA8 com milhares de matizes, o da DejaVu
##    populated também. E a fonte real do rótulo continua sendo a do motor, porque trocar a
##    fonte padrão é o que moveria a métrica de todo texto.
## 3) A/B de 200 tiques, mesmo seed, com e sem a cadeia montada pela função do jogo. Um lado
##    por processo: conquista paga uma vez e vínculo de freguês atravessam o `_reset_run()`,
##    então as duas corridas no mesmo processo divergiriam por causa da primeira, não por
##    causa da fonte — foi o que a primeira versão desta sonda mediu (3 quebras falsas).
##
## Uso (os dois lados, um processo cada, com o user dir descartável):
##   env APPDATA="D:\\Downloads\\tmp-userdata" LADO=com  godot --headless --path . --quit-after 1800 -s res://tools/probes/fonte.gd
##   env APPDATA="D:\\Downloads\\tmp-userdata" LADO=sem  godot --headless --path . --quit-after 1800 -s res://tools/probes/fonte.gd
## Cada lado imprime uma linha `MEDIDA|...`; comparar as duas.
##
## O passo 2 é intermitente e a causa NÃO é a cadeia de fontes. Um FATAL do TextServer
## ("Index 171 is out of bounds (size() = 170)", core/templates/cowdata.h:197) caiu em 4/8
## processos com `flat`, 5/8 com `nested` e 5/8 com a emoji sozinha — mas também em 5/12
## com o passo 2 inteiro sem fiação nenhuma (`VARIO=none`). Trocar os 84 símbolos por ASCII
## na mesma posição limpa as três variantes (0/12), e sem a cena do jogo no tree o Label de
## símbolos também nunca cai (0/12). Ou seja: o gatilho é um Label novo, com glifos raros,
## entrando numa árvore de jogo que já roda — caminho do motor, não do recurso. A rota que
## sobe para o navegador é medida no passo 3, e ali a frequência é outra: 6 processos com a
## cadeia montada e 6 sem deram 0 crashes e `MEDIDA` byte por byte idêntica nos dois lados.
## Por isso o passo 2 roda uma vez só e, se ele cair nesse FATAL, o veredito do passo 2 não
## reprova a feature: o que prova o envio é o passo 1 (cobertura) e o passo 3 (paralelia).
## A triagem completa está em `tools/probes/fonte_frequencia.gd` (harness de frequência,
## variantes por env, um processo por amostra).

const OUT := "D:/Downloads/tmp-userdata/"
const TAM := 64
const POS := Vector2i(TAM, 0)
const TICKS := 200
const SEED := 20261018


func _initialize() -> void:
	var codepoints := _codepoints_do_jogo()
	var lado := OS.get_environment("LADO")
	if lado == "":
		await _prova_fontes(codepoints)
		print("== 3) A/B omitida: defina LADO=com ou LADO=sem, um processo por lado ==")
		quit()
		return
	await _corrida(lado)
	quit()


## Passos 1 e 2: cobertura das duas fontes e cadeia montada pela função do jogo.
func _prova_fontes(codepoints: Array[int]) -> void:
	print("== 1) cobertura (load de res://, o caminho do build) ==")
	var emoji := load("res://fonts/NotoColorEmoji-Colr.ttf") as FontFile
	var mono := load("res://fonts/DejaVuSans.ttf") as FontFile
	if emoji == null or mono == null:
		print("VEREDITO: fonte embarcada nao abriu; emoji=%s mono=%s" % [str(emoji), str(mono)])
		return
	print("  %s: paletas=%d  %s" % [emoji.get_font_name(), emoji.get_palette_count(), _fmt(_bytes("res://fonts/NotoColorEmoji-Colr.ttf"))])
	print("  %s: paletas=%d  %s" % [mono.get_font_name(), mono.get_palette_count(), _fmt(_bytes("res://fonts/DejaVuSans.ttf"))])
	var so_emoji := _faltam(emoji, codepoints)
	var so_mono := _faltam(mono, codepoints)
	var na_uniao: Array[int] = []
	for c in codepoints:
		if not emoji.has_char(c) and not mono.has_char(c):
			na_uniao.append(c)
	print("  emoji cobre %d/%d (faltam %s)" % [codepoints.size() - so_emoji.size(), codepoints.size(), _listar(so_emoji)])
	print("  DejaVu cobre %d/%d (faltam %s)" % [codepoints.size() - so_mono.size(), codepoints.size(), _listar(so_mono)])
	print("  uniao: %d/%d  ainda sem glifo: %s" % [
		codepoints.size() - na_uniao.size(), codepoints.size(), _listar(na_uniao)
	])
	print("== 2) a cadeia montada pela funcao do jogo ==")
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	var base := ThemeDB.fallback_font
	var antes := _fallbacks(base)
	game._setup_web_fonts()
	var cadeia := _fallbacks(base)
	print("  antes=%d  depois=%d  emoji primeiro? %s" % [
		antes.size(), cadeia.size(), str(cadeia.size() >= 2 and cadeia[0] == emoji)
	])
	game._setup_web_fonts()
	var repetida := _fallbacks(base)
	print("  idempotente (rodar duas vezes nao duplica)? %s  cadeia=%d" % [str(repetida.size() == cadeia.size()), repetida.size()])
	var rot := Label.new()
	rot.name = "WebFontLabel"
	rot.text = _texto(codepoints)
	rot.add_theme_font_size_override("font_size", TAM)
	rot.position = Vector2(16, 16)
	game.add_child(rot)
	await _frames(10)
	var por_emoji := _atlas(emoji)
	var por_mono := _atlas(mono)
	print("  fonte real do rotulo: %s  (precisa continuar sendo a do motor)" % str(rot.get_theme_font("font").get_font_name()))
	print("  atlas emoji: %s" % _linha_atlas(por_emoji))
	print("  atlas DejaVu: %s" % _linha_atlas(por_mono))
	print("  VEREDITO: %s" % str(
		na_uniao.is_empty()
		and cadeia.size() >= 2 and cadeia[0] == emoji
		and int(por_emoji["formato"]) == Image.FORMAT_RGBA8 and int(por_emoji["matizes"]) > 64
		and int(por_mono["count"]) > 0
		and rot.get_theme_font("font") != emoji
	))
	base.set_fallbacks(antes)
	game.queue_free()
	await _frames(2)


## Um lado da A/B: monta (com) ou não (sem) a cadeia pela função do próprio jogo e roda os
## 200 tiques. Sem `await` dentro do laço: o rodízio de atores consome RNG guiado por frames
## reais e quebraria a paralelia entre os lados.
func _corrida(lado: String) -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	if lado == "com":
		game._setup_web_fonts()
	game.world_timer.stop()
	game._reset_run()
	game._refresh_ui()
	seed(SEED)
	for i in range(TICKS):
		game._on_customer_tick()
	await _frames(2)
	print("MEDIDA|%s|dia=%d|ouro=%d|fama=%d|atendidos=%d|afeto=%d|furia=%d|prateleira=%d|vinculos=%d" % [
		lado, int(game.shop_day), int(game.gold), int(game.reputation),
		int(game.customers_served), int(game.affection), int(game.fury),
		int(game.shelf_batches.size()), int(game.regular_bonds.size()),
	])
	print("  fonte do rotulo do jogo: %s  cadeia: %d" % [
		str(game.gold_label.get_theme_font("font").get_font_name()),
		_fallbacks(ThemeDB.fallback_font).size(),
	])
	game.queue_free()
	await _frames(2)


func _atlas(f: Font) -> Dictionary:
	var tc: int = f.get_texture_count(0, POS)
	var formato := -1
	var matizes := 0
	var visiveis := 0
	for i in range(tc):
		var ti: Image = f.get_texture_image(0, POS, i)
		if ti == null:
			continue
		formato = ti.get_format()
		var cores := _contar_cores(ti)
		matizes += int(cores["matizes"])
		visiveis += int(cores["visiveis"])
	return {"count": tc, "formato": formato, "matizes": matizes, "visiveis": visiveis}


func _linha_atlas(a: Dictionary) -> String:
	return "count=%d format=%d (%s) visiveis=%d matizes=%d" % [
		int(a["count"]), int(a["formato"]), _nome_formato(int(a["formato"])),
		int(a["visiveis"]), int(a["matizes"])
	]


func _nome_formato(fmt: int) -> String:
	if fmt == Image.FORMAT_RGBA8:
		return "RGBA8"
	if fmt == Image.FORMAT_L8:
		return "L8/mascara"
	return "outro"


func _faltam(f: Font, cps: Array[int]) -> Array[int]:
	var saida: Array[int] = []
	for c in cps:
		if not f.has_char(c):
			saida.append(c)
	return saida


func _fallbacks(fonte: Font) -> Array[Font]:
	var saida: Array[Font] = []
	for fb in fonte.get_fallbacks():
		if fb is Font:
			saida.append(fb)
	return saida


func _listar(cps: Array[int]) -> String:
	var s := ""
	for c in cps:
		s += "U+%04X " % c
	return s if s != "" else "-"


func _texto(cps: Array[int]) -> String:
	var s := ""
	for c in cps:
		s += char(c) + " "
	return s


func _codepoints_do_jogo() -> Array[int]:
	var f := FileAccess.open(OUT + "emoji_usados.txt", FileAccess.READ)
	if f == null:
		return [0x1F3C6, 0x1F525, 0x2764, 0x2630]
	var saida: Array[int] = []
	while not f.eof_reached():
		var linha := f.get_line().strip_edges()
		if linha != "":
			var c := linha.hex_to_int()
			if c > 0:
				saida.append(c)
	f.close()
	return saida


func _bytes(caminho: String) -> int:
	var f := FileAccess.open(caminho, FileAccess.READ)
	if f == null:
		return -1
	var n := f.get_length()
	f.close()
	return n


func _fmt(n: int) -> String:
	return "%d bytes (%.2f MB)" % [n, float(n) / 1000000.0]


func _contar_cores(img: Image) -> Dictionary:
	var work := img
	if work.get_format() != Image.FORMAT_RGBA8:
		work = img.duplicate()
		work.convert(Image.FORMAT_RGBA8)
	var vistas := {}
	var visiveis := 0
	for y in range(work.get_height()):
		for x in range(work.get_width()):
			var c := work.get_pixel(x, y)
			if c.a < 0.2:
				continue
			visiveis += 1
			var chave := "%d,%d,%d" % [int(c.r * 255), int(c.g * 255), int(c.b * 255)]
			if not vistas.has(chave):
				vistas[chave] = true
	return {"visiveis": visiveis, "matizes": vistas.size()}


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
