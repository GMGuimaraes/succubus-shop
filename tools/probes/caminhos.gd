extends SceneTree

## Auditoria de oclusão: para cada ponto de chão que o jogo usa de propósito
## (fila, vitrine, chegada, encontro, faixa de passeio, porta), mede quantos pontos
## da cabeça ao pé o móvel pintado engole. Um corpo engolido no lugar onde ele fica
## parado é caminho inalcançável: o freguês espera e ninguém vê. Porta e chefe têm
## tolerância de 90% porque o desaparecimento delas é o efeito desejado — a visita
## sai por trás do móvel e a chefe trabalha ATRAS do balcão.
##
## A auditoria roda por ARTE PINTADA, não só por sala: o salão tem cinco estados no
## mesmo chão e cada um corta a chefe numa altura diferente, então um recorte errado
## numa faixa é corpo engolido só naquele degrau da escada.
##
## Desde que a profundidade passou a ser DERIVADA do pé pintado de cada contorno
## (`_prop_depth`), o corpo serrado em piso aberto é geometricamente impossível: a
## figura só é cortada por um móvel se o pé dela estiver ACIMA da linha de contato
## daquele móvel, e é exatamente isso que significa "estar atrás". O que sobra para
## esta sonda acusar é o meio-termo — o corpo cortado numa faixa que a arte não
## pintou ali. Encobrimento total não é mais defeito: quem passa atrás de um
## monumento alto some inteiro por alguns passos, e é esse o efeito pedido. A sonda
## conta os dois separados: `???` é serra errada, `[  atras  ]` é oclusão honesta e
## vale conferir na arte.
##
## Uso: godot --headless --path . --quit-after 1800 --script res://tools/probes/caminhos.gd

const OUT := "D:/Downloads/tmp-userdata/"

func _initialize() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	game.world_timer.stop()
	## O chão é fração da altura da camada e o corpo é altura FIXA em pixels, então a
	## fração engolida depende da proporção da janela. Em headless a janela nasce
	## quadrada (1280x1280) e um corpo de 195px fica curto demais contra o balcão: a
	## sonda acusaria a chefe de sumir inteira num jogo onde ela mostra cabeça e
	## ombro. Fixar o 1280x720 do project.godot é o que faz o número da sonda ser o
	## número do jogo.
	if get_root().size != Vector2i(1280, 720):
		get_root().size = Vector2i(1280, 720)
		await _frames(4)
	print("janela %s • palco %s" % [get_root().size, game.stage_layer.size])

	## A auditoria percorre TODA arte que o jogo pinta, não só as salas: a escada do
	## salão (cinco estados no mesmo chão), as dezoito bandas de ofício e o salão de
	## expedições. Cada entrada é [geometria da sala, arte pintada].
	var rooms: Array = []
	for art in game.PROGRESS_BAND_ART:
		rooms.append([game.SALON_GEOMETRY_KEY, art])
	for oficio in game.SECTOR_SCENERY_ART:
		for art in game.SECTOR_SCENERY_ART[oficio]:
			rooms.append([str(game.SECTOR_SCENERY_ROOM[oficio]), str(art)])
	rooms.append([
		"res://assets/expedition_hall_scene.png",
		"res://assets/expedition_hall_scene.png",
	])
	var worst := 0.0
	var flagged := 0
	var hidden_count := 0
	var total := 0
	for entry in rooms:
		var room: String = entry[0]
		var art: String = entry[1]
		game._stage_room = room
		## A faixa de chão é lida por ARTE (`STAGE_ART_FLOOR`) com a sala como fallback:
		## sem fixar `_stage_art` aqui a auditoria mediria o chão do salão cheio sobre o
		## recorte do império — um número que nenhum jogador vê.
		game._stage_art = art
		var layer: Control = game.stage_layer
		var layer_h := layer.size.y
		var groups := {
			"fila": [game.STAGE_ROOM_QUEUE.get(room, []), 0.0],
			"vitrine": [game.STAGE_ROOM_BROWSE.get(room, []), 0.0],
			"chegada": [game.STAGE_ROOM_ARRIVE.get(room, []), 0.0],
			"cliente": [[Vector2(game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37)).y, game.STAGE_FRONT_DEPTH)], 0.0],
			"porta": [game.STAGE_ROOM_DOOR.get(room, []), 0.9],
			## A chefe fica na camada do meio (`_lane(1)`), o cliente na frente da sala;
			## `STAGE_ROOM_MEET` guarda os dois x, não a profundidade.
			"chefe": [[Vector2(game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37)).x, game._lane_depths[1])],
				0.9 if _has_front(game, room, art, game._lane_depths[1],
					float(game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37)).x)) else 0.2],
		}
		if game.STAGE_ROOM_WALK.has(room):
			var span: Vector2 = game.STAGE_ROOM_WALK[room]
			for depth in [0.82, 0.40, 0.08]:
				groups["passeio%.2f" % depth] = [[Vector2(span.x, depth), Vector2(span.y, depth)], 0.0]
		## A patrulha de verdade: `_spawn_stage_walker` sorteia profundidade entre 0,05
		## e 0,30 e atravessa a largura TODA da sala quando a sala não tem faixa de
		## passeio restrita. São esses corpos que somem no meio do salão — e a auditoria
		## dos pontos escritos à mão (fila, vitrine, chegada) não passa por nenhum deles.
		## Tolerância alta é o desenho novo: passando por trás do móvel pintado, o corpo
		## tem de ser cortado pela quina daquele móvel, não desaparecer por um contorno
		## herdado de outra faixa. O que ainda é defeito aqui é o 100% — corpo apagado em
		## piso aberto — e esse a sonda lista como `[atras]` para conferir na cartela.
		var faixa: Vector2 = game.STAGE_ROOM_WALK.get(room, Vector2(0.0, 1.0))
		var patrulha: Array = []
		for depth in [0.05, 0.12, 0.20, 0.30]:
			for step in range(9):
				patrulha.append(Vector2(lerpf(faixa.x, faixa.y, float(step) / 8.0), depth))
		groups["patrulha"] = [patrulha, 0.9]
		print("== %s (palco %.0fx%.0f, moveis %.0fx%.0f)" % [
			art.get_file(), layer.size.x, layer_h,
			game.stage_occluder.size.x, game.stage_occluder.size.y
		])
		## Inventário do recorte: o pé de cada contorno daquela arte convertido na
		## profundidade que ele mesmo declara (`_prop_depth`). É o número que antes morava
		## numa tabela à parte e era chutado; agora é o único que decide onde o corpo some
		## e de que plano ele some, e por isso as duas coisas não podem mais discordar.
		var band: Vector2 = game._stage_floor_line()
		var inventario: Array = game.STAGE_ART_PROPS.get(art, game.STAGE_ROOM_PROPS.get(room, []))
		if inventario.is_empty():
			print("    recorte: nenhum (chao aberto ate a parede)")
		for i in range(inventario.size()):
			var cantos: PackedVector2Array = game._prop_corners(inventario[i])
			var base := maxf(cantos[2].y, cantos[3].y)
			var prof: float = game._prop_depth(cantos, band)
			print("    recorte %d  x %.3f..%.3f  topo %.3f..%.3f  pe %.3f  prof %+.2f  %s" % [
				i, cantos[0].x, cantos[1].x, cantos[0].y, cantos[1].y, base, prof,
				"parede (esconde a qualquer profundidade)" if prof >= 1.0 else "movel dentro da sala",
			])
		for label in groups:
			var tolerance: float = groups[label][1]
			for spot in groups[label][0]:
				var x := float(spot.x)
				var depth := float(spot.y)
				var lane: Dictionary = game._lane_at(depth)
				var scale := float(lane["scale"])
				var foot_local := Vector2(x * layer.size.x, float(lane["floor_y"]))
				var tall: float = game._figure_base_height() * scale
				var covered := _covered_fraction(game, room, art, depth, foot_local, tall)
				total += 1
				var sawn := covered > tolerance + 0.2 and covered < 0.95
				var behind := covered >= 0.95
				var mark := "???" if sawn else ("[atras]" if behind else "   ")
				if sawn:
					flagged += 1
					worst = maxf(worst, covered - tolerance)
				if behind:
					hidden_count += 1
				print("%s %-11s x=%.3f d=%+.2f pe=%.3f encoberto=%+.1f%% (tolerado %+.0f%%)" % [
					mark, label, x, depth, foot_local.y / layer_h, covered * 100.0, tolerance * 100.0
				])
	print("-- veredito: %d de %d pontos serrados no lugar errado; %d escondidos atras de movel de verdade; pior excesso %+.1f%%" % [
		flagged, total, hidden_count, worst * 100.0
	])
	quit()

## Fração da altura desenhada do corpo que cai dentro de um móvel na frente dele.
## Os contornos vivem na tela inteira do recorte de móveis; o pé vive na camada do
## palco — comparar os dois exige um só espaço de coordenadas. O recorte vem da arte
## pintada (`STAGE_ART_PROPS`) e só cai no contorno da sala quando a faixa não tem o
## seu, exatamente como `_apply_room_props` decide.
func _covered_fraction(game: Object, room: String, art: String, depth: float, foot_local: Vector2, tall: float) -> float:
	var layer: Control = game.stage_layer
	var occluder: Control = game.stage_occluder
	var to_screen := layer.get_global_transform()
	var to_occ := occluder.get_global_transform().affine_inverse()
	var foot: Vector2 = to_occ * to_screen * foot_local
	var head: Vector2 = to_occ * to_screen * (foot_local + Vector2(0.0, -tall))
	var props: Array = game.STAGE_ART_PROPS.get(art, game.STAGE_ROOM_PROPS.get(room, []))
	var base: Vector2 = game._stage_floor_line()
	var hidden := 0.0
	for prop in props:
		var corners: PackedVector2Array = game._prop_corners(prop)
		var depth_prop: float = game._prop_depth(corners, base)
		if depth_prop < 1.0 and depth >= depth_prop:
			continue
		var left := to_occ * (corners[0] * occluder.size)
		var right := to_occ * (corners[1] * occluder.size)
		var bottom := maxf(
			(to_occ * (corners[2] * occluder.size)).y,
			(to_occ * (corners[3] * occluder.size)).y
		)
		if foot.x < minf(left.x, right.x) or foot.x > maxf(left.x, right.x):
			continue
		var span := right.x - left.x
		var t := 0.0 if absf(span) < 0.0001 else clampf((foot.x - left.x) / span, 0.0, 1.0)
		var top := lerpf(left.y, right.y, t)
		var lo := maxf(head.y, top)
		var hi := minf(foot.y, bottom)
		if hi > lo:
			hidden += hi - lo
	return clampf(hidden / maxf(1.0, foot.y - head.y), 0.0, 1.0)

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

## Existe móvel NA FRENTE deste ponto do chão? Um recorte só esconde quem está em
## profundidade menor que a dele; se nenhum recorte da arte cobre o x na profundidade
## pedida, aquele corpo pisa piso aberto e não tem desculpa para sumir. É o que
## decide a tolerância da chefe: atrás do balcão ela desaparece de propósito, no
## meio do salão da biblioteca não.
func _has_front(game: Object, room: String, art: String, depth: float, x: float) -> bool:
	var props: Array = game.STAGE_ART_PROPS.get(art, game.STAGE_ROOM_PROPS.get(room, []))
	var band: Vector2 = game._stage_floor_line()
	for prop in props:
		var corners: PackedVector2Array = game._prop_corners(prop)
		var prop_depth: float = game._prop_depth(corners, band)
		if prop_depth < 1.0 and depth >= prop_depth:
			continue
		if x >= minf(corners[0].x, corners[3].x) and x <= maxf(corners[1].x, corners[2].x):
			return true
	return false
