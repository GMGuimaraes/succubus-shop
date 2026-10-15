extends SceneTree

## Rastro dos corpos do palco. O probe deixa o relógio do mundo correr em 1x e grava,
## quadro a quadro, onde está cada figura: nome do corpo, profundidade e x do pé. Com
## isso dá para provar que cada corpo faz o trajeto UMA vez (o loop que a chefe
## reclamava aparecia como a profundidade voltando a ~1.4 no meio da caminhada) e
## fotografa de perto o pé de cada um contra a sombra.
##
## Uso:
##   APPDATA=<pasta descartavel> godot --path . -s res://tools/probes/trajeto.gd
##   (janela: precisa de viewport para os recortes; ~15 s de partida)
##
## Veredito: "corpos que refizeram o trajeto: 0 de N". Um corpo do balcão pode
## aparecer uma vez por visita repetida com o mesmo rosto — é o nó persistente
## vestindo alguém de novo, não o mesmo personagem voltando à quarta parede.

const OUT := "D:/Downloads/tmp-userdata/"

var _game = null
var _line := 0
## instance id → [última profundidade, quantas vezes a profundidade voltou atrás]
var _hist := {}

func _initialize() -> void:
	_line = 0
	_hist.clear()
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	_game = game
	await _frames(6)
	_estoque(_game)
	_game.reputation = 60
	print("\n── o rastro ──")
	var last_tick := -1
	for frame in range(900):
		await process_frame
		if not is_instance_valid(_game):
			break
		if _game.ticks != last_tick:
			last_tick = _game.ticks
			print("── tique %d (fila %d, %d corpos em cena) ──" % [
				_game.ticks, _game.service_queue.size(), _game._bodies_on_stage()])
		if frame % 6 != 0:
			continue
		_line += 1
		var parts: Array[String] = []
		parts.append_array(_peek(_game.stage_customer, "balcão"))
		for entry in _game._stage_waiters:
			parts.append_array(_peek(entry["node"], "fila "))
		for entry in _game._stage_walkers:
			parts.append_array(_peek(entry["node"], "salão"))
		if not parts.is_empty():
			print("  %3d │ %s" % [_line, "  ||  ".join(parts)])
		if frame % 90 == 0:
			_snap("traje_%03d" % _line)
			_zoom(_game.stage_customer, "pes_%03d" % _line)
			_crop(Rect2i(120, 300, 470, 330), "chao_%03d" % _line)
			if not _game._stage_waiters.is_empty():
				_zoom(_game._stage_waiters[0]["node"], "fila_%03d" % _line)
	print("\n── veredito: quantas vezes cada corpo voltou ao início do trajeto ──")
	var refazendo := 0
	for id in _hist:
		var record: Array = _hist[id]
		if int(record[1]) > 0:
			refazendo += 1
			print("  %s voltou ao começo %d vezes" % [str(record[0]), int(record[1])])
	print("  corpos que refizeram o trajeto: %d de %d" % [refazendo, _hist.size()])
	print("── fim do rastro ──")
	quit()

## Um corpo lido: nome, profundidade, x. E a única coisa que importa aqui — se a
## profundidade subiu de novo depois de já ter descido, o corpo voltou à quarta
## parede no meio da caminhada.
func _peek(node, label: String) -> Array[String]:
	var out: Array[String] = []
	if not is_instance_valid(node) or not (node as CanvasItem).visible:
		return out
	var control := node as Control
	var depth := float(control.get_meta("stage_depth", 0.0))
	var id := control.get_instance_id()
	var body := str(control.get_meta("stage_body", "?"))
	var name := "%s %s#%d" % [label, body, id % 10000]
	if not _hist.has(id):
		_hist[id] = [name, 0, depth, body]
		return out
	var record: Array = _hist[id]
	if str(record[3]) != body:
		# O nó do balcão é sempre o mesmo: vestir outro rosto é uma visita nova, não
		# o corpo anterior voltando ao começo do caminho.
		record[0] = name
		record[2] = depth
		record[3] = body
		return out
	# Entrar na sala é descer a profundidade (1.42 → 0.82). Subir de novo, com folga
	# maior que o passo de um quadro, é o corpo tendo voltado à quarta parede.
	if depth > float(record[2]) + 0.18:
		record[1] = int(record[1]) + 1
	record[2] = depth
	out.append("%s d%.2f x%.0f a%.2f" % [name, depth,
		control.position.x + control.size.x * 0.5, control.modulate.a])
	return out

## Prateleira das três primeiras receitas abertas, para a fila ter motivo para andar.
func _estoque(game) -> void:
	var postos := 0
	for i in range(game.products.size()):
		if postos >= 3:
			break
		if not game._is_product_unlocked(game.products[i]):
			continue
		while int(game.products[i].get("stock", 0)) < 12:
			game._add_piece(i, 2)
		postos += 1

func _snap(name: String) -> void:
	get_root().get_texture().get_image().save_png(OUT + "traj/%s.png" % name)

## Recorte 4x em volta do pé de um corpo: é onde a sombra se lê ou se denuncia.
func _zoom(node: Control, name: String) -> void:
	if not is_instance_valid(node):
		return
	var img := get_root().get_texture().get_image()
	var at := node.get_global_transform() * Vector2(node.size.x * 0.5, node.size.y)
	var side := 190
	var region := Rect2i(int(at.x) - side / 2, int(at.y) - side / 2, side, side)
	region = region.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if region.size.x <= 0 or region.size.y <= 0:
		return
	var crop := img.get_region(region)
	crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + "traj/%s.png" % name)

## Recorte fixo da faixa de chão da fila, em 2x: é onde a linha inteira se lê de
## uma vez, do degrau do balcão ao fundo.
func _crop(region: Rect2i, name: String) -> void:
	var img := get_root().get_texture().get_image()
	var cut := region.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if cut.size.x <= 0 or cut.size.y <= 0:
		return
	var part := img.get_region(cut)
	part.resize(part.get_width() * 2, part.get_height() * 2, Image.INTERPOLATE_NEAREST)
	part.save_png(OUT + "traj/%s.png" % name)

func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
