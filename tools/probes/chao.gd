extends SceneTree

## Onde o código planta o pé, no frame que o jogador realmente vê. Fotografa a recepção
## em cada uma das cinco faixas da escada e depois as outras quatro salas, riscando na
## foto a linha de chão de cada profundidade usada pelo elenco
## (0,08 / 0,12 / 0,22 / 0,40 / 0,82 / 1,00). Se a linha cair ACIMA do assoalho pintado,
## é ali que o corpo flutua — e o elenco do fundo flutuava em quatro das cinco faixas
## antes da faixa de chão passar a ser lida por arte (`STAGE_ART_FLOOR`).
##
## A régua ampliada existe porque o primeiro detector automático de junção parede/chão se
## provou não confiável (leu 0,867 na guilda e 0,673 no salão cheio, onde a junção real é
## 0,575): nas nove cenas históricas quem lê a altura é o olho, sobre uma escala desenhada
## a cada 0,01 de tela. A auditoria no topo da sonda é o segundo detector — degrau de
## rugosidade sobre o arquivo pintado — e só vale depois de bater com essas nove leituras;
## ele serve para as artes novas, que ainda não têm olho passado nelas.
##
## Uso (janela, nunca --headless: o recorte de frame precisa de rasterizador):
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 9000 \
##     --script res://tools/probes/chao.gd
## Só a auditoria de junção, sem abrir janela:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 600 --script res://tools/probes/chao.gd

const OUT := "D:/Downloads/tmp-userdata/chao/"
const BANDAS := [0, 900, 2400, 5200, 9000]
const PROFUNDIDADES := [0.08, 0.12, 0.22, 0.40, 0.82, 1.00]
## Junção parede/chão lida a olho na régua, cena por cena. 0,0 = ainda não medido: a
## sonda fotografa e imprime as linhas, mas não reprova.
const PISO_PINTADO := {
	"banda_0": 0.672,
	"banda_1": 0.685,
	"banda_2": 0.575,
	"banda_3": 0.615,
	"banda_4": 0.655,
	"guilda": 0.578,
	"forja": 0.600,
	"biblioteca": 0.665,
	"santuario": 0.600,
	## As quinze artes novas da escada de ofício, lidas na cartela por família.
	"forge_bare_scene": 0.610,
	"forge_tidy_scene": 0.595,
	"forge_bellows_scene": 0.625,
	"forge_master_scene": 0.620,
	"forge_grand_scene": 0.622,
	"library_bare_scene": 0.650,
	"library_tidy_scene": 0.610,
	"library_stacks_scene": 0.660,
	"library_master_scene": 0.655,
	"library_grand_scene": 0.668,
	"sanctum_bare_scene": 0.650,
	"sanctum_tidy_scene": 0.605,
	"sanctum_relics_scene": 0.655,
	"sanctum_master_scene": 0.655,
	"sanctum_grand_scene": 0.645,
}
const SALAS := {
	"guilda": "res://assets/expedition_hall_scene.png",
	"forja": "res://assets/forge_scene.png",
	"biblioteca": "res://assets/library_room_scene.png",
	"santuario": "res://assets/sanctum_room_scene.png",
}
## As cinco artes da recepção, na ordem da escada — as mesmas que `PISO_PINTADO` mede.
const FACHADAS := [
	"res://assets/salon_bare_scene.png",
	"res://assets/salon_tidy_scene.png",
	"res://assets/shop_scene.png",
	"res://assets/salon_gilded_scene.png",
	"res://assets/salon_empire_scene.png",
]
## Artes novas ainda sem junção medida. O detector imprime a candidata de cada uma; o
## número vai para `STAGE_ART_FLOOR` depois de conferido na régua.
const A_MEDIR := [
	"res://assets/forge_bare_scene.png", "res://assets/forge_tidy_scene.png",
	"res://assets/forge_bellows_scene.png", "res://assets/forge_master_scene.png",
	"res://assets/forge_grand_scene.png",
	"res://assets/library_bare_scene.png", "res://assets/library_tidy_scene.png",
	"res://assets/library_stacks_scene.png", "res://assets/library_master_scene.png",
	"res://assets/library_grand_scene.png",
	"res://assets/sanctum_bare_scene.png", "res://assets/sanctum_tidy_scene.png",
	"res://assets/sanctum_relics_scene.png", "res://assets/sanctum_master_scene.png",
	"res://assets/sanctum_grand_scene.png",
]
## Faixa vertical que a folha de junções recorta, em fração de tela. Apertada de propósito:
## com 0,22 de tela em 300 pixels de célula, cada tique de 0,01 tem 13 px e o olho lê a
## junção com erro de meio tique. Janela larga demais transformava a régua em estática.
const DE := 0.50
const ATE := 0.72

var _game = null
var _falhas := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	_auditando_juncao()
	if DisplayServer.get_name() == "headless":
		print("── sem rasterizador: só a auditoria de junção rodou, as fotos exigem janela")
		quit()
		return
	get_root().size = Vector2i(1280, 720)
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	_game = game
	await _frames(8)
	if is_instance_valid(game.menu_layer):
		game._close_menu()
		await _frames(8)
	game.world_timer.stop()
	game._reset_run()
	for banda in range(5):
		game.gold = BANDAS[banda]
		game._refresh_ui()
		await _foto("banda_%d" % banda, game)
	for chave in SALAS:
		var arte := str(SALAS[chave])
		## `_show_stage_for_room` troca o recorte e a faixa, mas quem pinta o fundo é o
		## `background_layer`: sem encostar nele a foto sai com o salão emprestado e a
		## leitura da junção parede/chão vira mentira.
		if is_instance_valid(game.background_layer):
			game.background_layer.texture = load(arte)
		game._show_stage_for_room(arte, true)
		await _foto(str(chave), game)
	## A escada de ofício inteira: cada arte nova fotografada com o próprio recorte e a
	## própria faixa, porque é exatamente aí que o elenco voltaria a flutuar se uma arte
	## entrasse no arquivo sem entrada em `STAGE_ART_FLOOR`.
	for caminho in A_MEDIR:
		var arte := str(caminho)
		if is_instance_valid(game.background_layer):
			game.background_layer.texture = load(arte)
		game._show_stage_for_room(arte, true)
		## O rótulo é o nome pelado do arquivo: é a chave de `PISO_PINTADO` e o nome do PNG.
		## `get_basename()` sozinho devolve `res://assets/forge_bare_scene`, e o save_png
		## reprova o caminho.
		await _foto(arte.get_file().get_basename(), game)
	print("── veredito: %d linha(s) de pé acima do piso pintado %s" % [
		_falhas, "✓" if _falhas == 0 else "✗"])
	print("fotos e réguas em %s" % OUT)
	quit()


## Uma cena fotografada: esconde a UI, congela o palco, risca as linhas de pé e salva a
## foto cheia mais a régua ampliada do terço esquerdo.
func _foto(rotulo: String, game) -> void:
	if is_instance_valid(game.ui_layer):
		game.ui_layer.visible = false
	if is_instance_valid(game.offline_dialog):
		game.offline_dialog.visible = false
	await _frames(40)
	var foto: Image = get_root().get_texture().get_image()
	var h := foto.get_height()
	var w := foto.get_width()
	var piso: float = PISO_PINTADO.get(rotulo, 0.0)
	print("── %s • arte %s • chão do código %.3f..%.3f • piso pintado %.3f (%dx%d)" % [
		rotulo, game._stage_art,
		(float(game._lane_at(0.0)["floor_y"]) / game.stage_layer.size.y),
		(float(game._lane_at(1.0)["floor_y"]) / game.stage_layer.size.y), piso, w, h])
	for d in PROFUNDIDADES:
		var lane: Dictionary = game._lane_at(d)
		var y: float = float(lane["floor_y"]) / game.stage_layer.size.y
		var px := clampi(int(y * float(h)), 0, h - 1)
		var cor := foto.get_pixel(int(0.31 * w), px)
		foto.fill_rect(Rect2i(0, px, w, 2), Color(1.0, 0.0, 1.0))
		foto.fill_rect(Rect2i(int(0.31 * w), maxi(0, px - 8), 6, 18), Color(1.0, 1.0, 0.0))
		var veredito := "sem medição"
		var margem := int(round((y - piso) * float(h)))
		if piso > 0.0:
			veredito = "no chão"
			if y < piso:
				veredito = "FLUTUANDO na parede"
				_falhas += 1
		print("   prof %.2f → pés em y %.3f (%d px) • %s • margem %+d px • pixel rgb %.2f/%.2f/%.2f" % [
			d, y, px, veredito, margem, cor.r, cor.g, cor.b])
	foto.save_png(OUT + "%s.png" % rotulo)
	_zoom(foto, rotulo, h, w)


## Régua sobre a faixa do chão: recorta o terço esquerdo entre 0,52 e 0,88 de tela,
## amplia 3× e risca um fio a cada 0,01 (verde) com marca azul a cada 0,05. As linhas
## magenta do código continuam por baixo, então a foto diz sozinha se o pé está no
## mármore pintado ou na parede.
func _zoom(foto: Image, rotulo: String, h: int, w: int) -> void:
	var y0 := int(0.52 * h)
	var y1 := int(0.88 * h)
	var x1 := int(0.46 * w)
	var recorte: Image = foto.get_region(Rect2i(0, y0, x1, y1 - y0))
	var grande: Image = recorte.duplicate()
	grande.resize(x1 * 3, (y1 - y0) * 3, Image.INTERPOLATE_NEAREST)
	for k in range(37):
		var yy := clampi(int(float(k) / 36.0 * float(grande.get_height() - 2)), 0, grande.get_height() - 2)
		var cor := Color(0.0, 1.0, 0.0)
		if k % 5 == 0:
			cor = Color(0.0, 0.55, 1.0)
		grande.fill_rect(Rect2i(0, yy, grande.get_width(), 1), cor)
	grande.save_png(OUT + "zoom_%s.png" % rotulo)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


## Auditoria de junção parede/chão arte por arte, sem depender do olho. A calibração
## obriga o detector a bater com as nove leituras feitas na régua; enquanto ele errar, a
## folha de junções é o instrumento e os números dele não entram em lugar nenhum.
func _auditando_juncao() -> void:
	print("── o detector de junção, calibrado nas nove leituras a olho ──")
	var esperadas := {
		"res://assets/salon_bare_scene.png": PISO_PINTADO["banda_0"],
		"res://assets/salon_tidy_scene.png": PISO_PINTADO["banda_1"],
		"res://assets/shop_scene.png": PISO_PINTADO["banda_2"],
		"res://assets/salon_gilded_scene.png": PISO_PINTADO["banda_3"],
		"res://assets/salon_empire_scene.png": PISO_PINTADO["banda_4"],
		SALAS["guilda"]: PISO_PINTADO["guilda"],
		SALAS["forja"]: PISO_PINTADO["forja"],
		SALAS["biblioteca"]: PISO_PINTADO["biblioteca"],
		SALAS["santuario"]: PISO_PINTADO["santuario"],
	}
	var desvios := 0
	for caminho in esperadas:
		var lido := _detectar_juncao(str(caminho))
		var olho: float = esperadas[caminho]
		if absf(lido - olho) > 0.02:
			desvios += 1
	print("calibração do detector de rugosidade: %d de %d artes fora de 0,02 → %s" % [
		desvios, esperadas.size(),
		"utilizável" if desvios == 0 else "inutilizável (degrau de rugosidade confunde " \
		+ "beiral de vitral com pé de parede); vale a folha abaixo"])
	_folha_de_juncao()


## A folha de junções, uma cartela por família de sala. Cada célula é o centro da arte
## entre 0,40 e 0,85 de tela, com a linha magenta do CÓDIGO riscada por cima e uma escala
## na beira esquerda: fio a cada 0,05 e um tique a cada 0,01. Onde a magenta nasce acima
## do pé pintado, o elenco flutua — e contando tiques se sabe de quantos centésimos.
## Roda em headless: são operações de Image, nenhum rasterizador no caminho.
func _folha_de_juncao() -> void:
	var constantes: Dictionary = (load("res://main.gd") as GDScript).get_script_constant_map()
	var por_arte: Dictionary = constantes.get("STAGE_ART_FLOOR", {})
	var por_sala: Dictionary = constantes.get("STAGE_ROOM_FLOOR", {})
	var grupos := {
		"recepcao": FACHADAS.duplicate() + [SALAS["guilda"]],
		"forja": [SALAS["forja"]],
		"biblioteca": [SALAS["biblioteca"]],
		"santuario": [SALAS["santuario"]],
	}
	for caminho in A_MEDIR:
		for familia in ["forja", "biblioteca", "santuario"]:
			## A família é a raiz do nome do arquivo (`forge_bellows_scene` → forja). Sem
			## `get_file()` o slice pega "res:", que casa com tudo e repetia as quinze artes
			## nas três cartelas.
			if str(caminho).contains(str(SALAS[familia]).get_file().get_basename().get_slice("_", 0)):
				grupos[familia].append(str(caminho))
	for familia in grupos:
		var artes: Array = grupos[familia]
		var cw := 600
		var ch := 300
		var colunas := 2
		var linhas := int(ceil(float(artes.size()) / float(colunas)))
		var folha := Image.create(cw * colunas, ch * linhas, false, Image.FORMAT_RGBA8)
		folha.fill(Color(0.04, 0.04, 0.06))
		print("── cartela %s (%d artes • %sjuncao_%s.png) ──" % [familia, artes.size(), OUT, familia])
		for i in range(artes.size()):
			var caminho := str(artes[i])
			var tex := load(caminho) as Texture2D
			if tex == null:
				print("   %02d %s: ARTE AUSENTE" % [i + 1, caminho.get_file()])
				continue
			var img := tex.get_image()
			img.convert(Image.FORMAT_RGBA8)
			var w := img.get_width()
			var h := img.get_height()
			var recorte: Image = img.get_region(Rect2i(
				int(0.20 * float(w)), int(DE * float(h)),
				int(0.55 * float(w)), int((ATE - DE) * float(h))))
			recorte.resize(cw, ch, Image.INTERPOLATE_LANCZOS)
			var banda: Vector2 = por_arte.get(caminho, por_sala.get(_sala_mae(caminho, por_sala), Vector2(0.60, 0.80)))
			## O que pisa a tela não é `banda.x`: é o pé da profundidade 0,08, que o lerp
			## já empurrou para baixo. É essa linha que tem de cair dentro do assoalho.
			var pe := lerpf(banda.x, banda.y, 0.08)
			for linha in [[banda.x, Color(1.0, 0.55, 0.0), 1], [pe, Color(1.0, 0.0, 1.0), 3]]:
				var y := clampi(int(round((float(linha[0]) - DE) / (ATE - DE) * float(ch - 1))), 0, ch - 1)
				recorte.fill_rect(Rect2i(0, y, cw, int(linha[2])), linha[1])
			var passos := int(round((ATE - DE) / 0.01))
			for k in range(passos + 1):
				var y := clampi(int(round(float(k) / float(passos) * float(ch - 1))), 0, ch - 1)
				if k % 5 == 0:
					recorte.fill_rect(Rect2i(0, y, cw, 1), Color(0.25, 0.6, 1.0))
					recorte.fill_rect(Rect2i(0, y - 3, 150, 7), Color(0.0, 0.4, 1.0))
				elif k % 2 == 0:
					recorte.fill_rect(Rect2i(0, y, 90, 1), Color(0.0, 1.0, 0.0))
				else:
					recorte.fill_rect(Rect2i(0, y, 45, 1), Color(0.0, 0.8, 0.2))
			print("   %02d %-26s banda.x %.3f • pé prof 0,08 em %.3f (%s)" % [i + 1, caminho.get_file(),
				banda.x, pe, "arte" if por_arte.has(caminho) else "herdado"])
			folha.blit_rect(recorte, Rect2i(0, 0, cw, ch), Vector2i(
				(i % colunas) * cw, int(float(i) / float(colunas)) * ch))
		folha.save_png(OUT + "juncao_%s.png" % familia)


## A sala dona de uma arte da escada: `forge_bellows_scene` é forja; o que não casa com
## nenhuma sala é recepção, e a recepção já tem faixa própria por arte.
func _sala_mae(caminho: String, por_sala: Dictionary) -> String:
	for sala in por_sala:
		var raiz := str(sala).get_base_dir() + "/" + str(sala).get_file().get_basename().get_slice("_", 0)
		if caminho.begins_with(raiz):
			return sala
	return "res://assets/shop_scene.png"


## Junção parede/chão lida direto do arquivo pintado: degrau de rugosidade entre a janela
## de cima e a de baixo, no terço central. Conservado porque é o teste barato de que o
## instrumento continua sendo necessário — ver a calibração acima.
func _detectar_juncao(caminho: String) -> float:
	var tex := load(caminho) as Texture2D
	if tex == null:
		return -1.0
	var img := tex.get_image()
	if img == null:
		return -1.0
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var px := img.get_data()
	var x0 := int(0.28 * float(w))
	var x1 := int(0.72 * float(w))
	var passo := maxi(1, int(float(w) / 400.0))
	var amostras := 0
	for x in range(x0, x1, passo):
		amostras += 1
	var g := PackedFloat32Array()
	g.resize(h)
	for y in range(1, h):
		var soma := 0.0
		for x in range(x0, x1, passo):
			var o := (y * w + x) * 4
			var p := ((y - 1) * w + x) * 4
			soma += absf(
				(px[o] * 0.299 + px[o + 1] * 0.587 + px[o + 2] * 0.114)
				- (px[p] * 0.299 + px[p + 1] * 0.587 + px[p + 2] * 0.114))
		g[y] = soma / float(maxi(1, amostras))
	var s := PackedFloat32Array()
	s.resize(h)
	for y in range(h):
		var soma := 0.0
		var n := 0
		for k in range(-6, 7):
			var yy := y + k
			if yy >= 0 and yy < h:
				soma += g[yy]
				n += 1
		s[y] = soma / float(maxi(1, n))
	var janela := int(0.05 * float(h))
	var melhor := -1.0e9
	var corte := int(0.5 * h)
	for y in range(int(0.40 * float(h)), int(0.92 * float(h))):
		var queda := _media(s, y - janela, y) - _media(s, y, y + janela)
		if queda > melhor:
			melhor = queda
			corte = y
	return float(corte) / float(h)


func _media(v: PackedFloat32Array, de: int, ate: int) -> float:
	var soma := 0.0
	var n := 0
	for i in range(maxi(0, de), mini(v.size(), ate)):
		soma += v[i]
		n += 1
	return soma / float(maxi(1, n))
