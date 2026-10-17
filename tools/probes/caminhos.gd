extends SceneTree

## Auditoria de oclusão: para cada ponto de chão que o jogo usa de propósito
## (fila, vitrine, chegada, encontro, faixa de passeio, porta), mede quantos pontos
## da cabeça ao pé o móvel pintado engole. Um corpo engolido no lugar onde ele fica
## parado é caminho inalcançável: o freguês espera e ninguém vê. Porta e chefe têm
## tolerância de 90% porque o desaparecimento delas é o efeito desejado — a visita
## sai por trás do móvel e a chefe trabalha ATRAS do balcão.
##
## Uso: godot --headless --path . --quit-after 1800 --script res://tools/probes/caminhos.gd

const OUT := "D:/Downloads/tmp-userdata/"

func _initialize() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	game.world_timer.stop()

	var rooms: Array = [
		"res://assets/shop_scene.png",
		"res://assets/forge_scene.png",
		"res://assets/library_room_scene.png",
		"res://assets/sanctum_room_scene.png",
		"res://assets/expedition_hall_scene.png",
	]
	var worst := 0.0
	var flagged := 0
	var total := 0
	for room in rooms:
		game._stage_room = room
		var layer: Control = game.stage_layer
		var layer_h := layer.size.y
		var groups := {
			"fila": [game.STAGE_ROOM_QUEUE.get(room, []), 0.0],
			"vitrine": [game.STAGE_ROOM_BROWSE.get(room, []), 0.0],
			"chegada": [game.STAGE_ROOM_ARRIVE.get(room, []), 0.0],
			"cliente": [[Vector2(game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37)).y, game.STAGE_FRONT_DEPTH)], 0.0],
			"porta": [game.STAGE_ROOM_DOOR.get(room, []), 0.9],
			"chefe": [[Vector2(game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37)).x, game._lane_depths[1])], 0.9],
		}
		if game.STAGE_ROOM_WALK.has(room):
			var span: Vector2 = game.STAGE_ROOM_WALK[room]
			for depth in [0.82, 0.40, 0.08]:
				groups["passeio%.2f" % depth] = [[Vector2(span.x, depth), Vector2(span.y, depth)], 0.0]
		print("== %s (palco %.0fx%.0f, moveis %.0fx%.0f)" % [
			room.get_file(), layer.size.x, layer_h,
			game.stage_occluder.size.x, game.stage_occluder.size.y
		])
		for label in groups:
			var tolerance: float = groups[label][1]
			for spot in groups[label][0]:
				var x := float(spot.x)
				var depth := float(spot.y)
				var lane: Dictionary = game._lane_at(depth)
				var scale := float(lane["scale"])
				var foot_local := Vector2(x * layer.size.x, float(lane["floor_y"]))
				var tall := 250.0 * scale
				var covered := _covered_fraction(game, room, depth, foot_local, tall)
				total += 1
				var over := covered > tolerance + 0.2
				var mark := "???" if over else "   "
				if over:
					flagged += 1
					worst = maxf(worst, covered - tolerance)
				print("%s %-11s x=%.3f d=%+.2f pe=%.3f encoberto=%+.1f%% (tolerado %+.0f%%)" % [
					mark, label, x, depth, foot_local.y / layer_h, covered * 100.0, tolerance * 100.0
				])
	print("-- veredito: %d de %d pontos fora da tolerancia; pior excesso %+.1f%%" % [
		flagged, total, worst * 100.0
	])
	quit()

## Fração da altura desenhada do corpo que cai dentro de um móvel na frente dele.
## Os contornos vivem na tela inteira do recorte de móveis; o pé vive na camada do
## palco — comparar os dois exige um só espaço de coordenadas.
func _covered_fraction(game: Object, room: String, depth: float, foot_local: Vector2, tall: float) -> float:
	var layer: Control = game.stage_layer
	var occluder: Control = game.stage_occluder
	var to_screen := layer.get_global_transform()
	var to_occ := occluder.get_global_transform().affine_inverse()
	var foot: Vector2 = to_occ * to_screen * foot_local
	var head: Vector2 = to_occ * to_screen * (foot_local + Vector2(0.0, -tall))
	var props: Array = game.STAGE_ROOM_PROPS.get(room, [])
	var depths: Array = game.STAGE_ROOM_PROP_DEPTHS.get(room, [])
	var hidden := 0.0
	for i in range(props.size()):
		if i < depths.size() and depth >= float(depths[i]):
			continue
		var corners: PackedVector2Array = game._prop_corners(props[i])
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
