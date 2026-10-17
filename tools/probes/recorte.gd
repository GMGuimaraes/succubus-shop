extends SceneTree

## Auditoria do recorte de oclusão: desenha cada contorno de móvel por cima da arte que
## ele deve recortar, com grade de coordenadas normalizadas, e imprime a linha de corte
## da chefe em cada faixa. Serve para duas perguntas que não têm resposta de memória:
## (1) toda arte da escada de progresso tem recorte PRÓPRIO — herdar o contorno da sala
## não é mais opção, porque a profundidade de cada móvel agora é derivada do pé pintado
## daquele contorno (`_prop_depth`), e o pé da banda é outro móvel em outro degrau do
## chão; e (2) a borda de cima bate com a quina pintada e a base bate com a linha de
## contato, lidas em pixels e não em opinião. Os PNG saem em `OUT` e se leem de volta
## com a ferramenta de imagem.
##
## A cartela risca também o chão daquela arte (verde = fundo do piso pintado, ciano =
## frente): um pé de contorno fora dessas duas linhas está declarando parede onde a arte
## pintou móvel, e isso é o elenco inteiro desaparecendo naquele x.
##
## Uso: APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . --quit-after 1800 \
##     -s res://tools/probes/recorte.gd
## A sonda só lê constantes e imagens; o `world_timer` é parado antes de qualquer tique
## para nenhum `_save_game()` acontecer. Ainda assim roda com o APPDATA descartável.

const OUT := "D:/Downloads/tmp-userdata/"
## Artes fora da escada do salão. A guilda de expedições é um estado único e continua
## na tabela por sala; as bandas nomeadas de sala (forja, biblioteca, santuário) já têm
## contorno próprio e só aparecem aqui porque a cartela percorre arte pintada por arte.
const OUTRAS_SALAS: Array[String] = [
	"res://assets/expedition_hall_scene.png",
	"res://assets/forge_scene.png",
	"res://assets/library_room_scene.png",
	"res://assets/sanctum_room_scene.png",
]

func _initialize() -> void:
	var game = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	game.world_timer.stop()
	print("== Recorte de oclusão por arte pintada ==")
	var faixa_x: float = (game.STAGE_ROOM_MEET.get(game.SALON_GEOMETRY_KEY, Vector2(0.505, 0.37)) as Vector2).x
	var sem_recorte := 0
	for path in game.PROGRESS_BAND_ART:
		var proprio: bool = game.STAGE_ART_PROPS.has(path) or path == game.SALON_GEOMETRY_KEY
		if not proprio:
			sem_recorte += 1
		_report(game, path, faixa_x)
	print("faixas do salão sem recorte próprio: %d %s" % [sem_recorte, "✓" if sem_recorte == 0 else "✕"])
	for path in game.PROGRESS_BAND_ART + OUTRAS_SALAS:
		_sheet(game, path)
	_escada_de_oficio(game)
	quit()

## Linha de inventário de uma arte: recorte próprio ou herdado, o corte da chefe e, para
## cada contorno, o pé pintado convertido em profundidade do palco pela mesma régua que
## `_apply_room_props` usa. `parede` é o único caso em que o móvel esconde a qualquer
## profundidade — e só é honesto onde a arte pintou a parede de frente da sala.
func _report(game, path: String, faixa_x: float) -> void:
	var props: Array = _props(game, path)
	var band := _band(game, path)
	var corte := _cut_at(props, faixa_x, band)
	var proprio: bool = game.STAGE_ART_PROPS.has(path) or path == game.SALON_GEOMETRY_KEY
	print("%-22s %s  chao %.3f..%.3f  corte da chefe em x=%.3f: y=%s" % [
		path.get_file().get_basename(),
		"próprio" if proprio else "HERDADO",
		band.x, band.y, faixa_x,
		"%.3f" % corte if corte > 0.0 else "—",
	])
	for i in range(props.size()):
		var c := _corners(props[i])
		var depth: float = game._prop_depth(c, band)
		print("      movel %d  x %.3f..%.3f  pe %.3f  prof %+.2f  %s" % [
			i, minf(c[0].x, c[3].x), maxf(c[1].x, c[2].x),
			maxf(c[2].y, c[3].y), depth,
			"parede" if depth >= 1.0 else ("fundo da sala" if depth < 0.0 else "dentro da sala"),
		])


## A escada de ofício (forja, biblioteca, santuário) é pintada em artes separadas por
## banda, e cada banda pisa um móvel diferente num degrau diferente do chão. Nenhuma
## delas pode herdar o contorno da sala: a profundidade passou a ser o pé daquele
## contorno, então herdar é esconder o elenco atrás de um móvel que aquela faixa não
## pintou. É isto que a cartela mostra, cell a cell.
func _escada_de_oficio(game) -> void:
	print("== Escada de ofício: recorte próprio arte por arte ==")
	var total := 0
	var sem_proprio := 0
	for oficio in game.SECTOR_SCENERY_ART:
		var artes: Array = game.SECTOR_SCENERY_ART[oficio]
		var caminho_sala := str(game.SECTOR_SCENERY_ROOM[oficio])
		var faixa_x: float = (game.STAGE_ROOM_MEET.get(caminho_sala, Vector2(0.5, 0.4)) as Vector2).x
		var celulas: Array = []
		for caminho in artes:
			var path := str(caminho)
			total += 1
			if not game.STAGE_ART_PROPS.has(path):
				sem_proprio += 1
			_report(game, path, faixa_x)
			celulas.append(path)
		_cartela(game, oficio, celulas, faixa_x)
	print("artes de ofício auditadas: %d • sem recorte próprio: %d %s" % [
		total, sem_proprio, "✓" if sem_proprio == 0 else "✕",
	])


## Uma cartela por ofício: seis células com o recorte herdado riscado por cima da arte
## daquela banda, mais grade a cada 0,05 e a linha do corte da chefe em amarelo.
## Onde o vermelho corta madeira pintada, a herança vale; onde corta parede ou vazio, a
## chefe está sendo serrada no ar — e aí a arte precisa de contorno próprio.
func _cartela(game, oficio: String, artes: Array, faixa_x: float) -> void:
	var cw := 620
	var ch := 352
	var colunas := 2
	var linhas := int(ceil(float(artes.size()) / float(colunas)))
	var folha := Image.create(cw * colunas, ch * linhas, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.03, 0.03, 0.05))
	for i in range(artes.size()):
		var caminho := artes[i] as String
		if not ResourceLoader.exists(caminho):
			continue
		var img := (load(caminho) as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		var w := img.get_width()
		var h := img.get_height()
		var props: Array = _props(game, caminho)
		var band := _band(game, caminho)
		for p in props:
			var corners := _corners(p)
			for k in range(corners.size()):
				var a: Vector2 = corners[k]
				var b: Vector2 = corners[(k + 1) % corners.size()]
				_line(img, Vector2i(int(a.x * w), int(a.y * h)), Vector2i(int(b.x * w), int(b.y * h)), Color(1, 0, 0.2, 0.95), 6)
		var corte := _cut_at(props, faixa_x, band)
		if corte > 0.0:
			img.fill_rect(Rect2i(0, int(corte * float(h)), w, 8), Color(1, 1, 0, 0.95))
		_ruler(img, band, w, h)
		for gx in range(21):
			img.fill_rect(Rect2i(int(float(gx) / 20.0 * float(w)), 0, 2, h), Color(1, 1, 1, 0.35))
		for gy in range(21):
			img.fill_rect(Rect2i(0, int(float(gy) / 20.0 * float(h)), w, 2), Color(1, 1, 1, 0.35))
		img.resize(cw, ch, Image.INTERPOLATE_LANCZOS)
		folha.blit_rect(img, Rect2i(0, 0, cw, ch), Vector2i((i % colunas) * cw, int(float(i) / float(colunas)) * ch))
	folha.save_png(OUT + "recorte_oficio_%s.png" % oficio)
	print("cartela %s -> %srecorte_oficio_%s.png (%d artes)" % [oficio, OUT, oficio, artes.size()])


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

## A mesma ordem que `_apply_room_props` usa: a arte pintada manda no recorte, a sala
## só vale para o que não tem faixa própria.
func _props(game, path: String) -> Array:
	if game.STAGE_ART_PROPS.has(path):
		return game.STAGE_ART_PROPS[path]
	return game.STAGE_ROOM_PROPS.get(game._room_key(path), [])

## O chão daquela arte, no mesmo espaço normalizado dos contornos. `_stage_floor_line()`
## lê `_stage_art` com a sala como fallback, então a sonda fixa os dois antes de medir —
## é a mesma conta que `_lane_at` faz para pôr o pé da figura no piso pintado.
func _band(game, path: String) -> Vector2:
	game._stage_room = game._room_key(path)
	game._stage_art = path
	return game._stage_floor_line()

## y da borda de cima do contorno que cobre o x da chefe — o número que decide onde o
## corpo dela é cortado. Sem móvel ali, devolve −1.
func _cut_at(props: Array, x: float, band: Vector2) -> float:
	var melhor := -1.0
	for p in props:
		var c := _corners(p)
		if x < minf(c[0].x, c[3].x) or x > maxf(c[1].x, c[2].x):
			continue
		if not _hides(p, band):
			continue
		var y := _edge_y(c, x)
		if y >= 0.0 and (melhor < 0.0 or y > melhor):
			melhor = y
	return melhor

## Um contorno só corta quem passa por trás dele. Base no pé da tela é parede de frente
## e esconde a qualquer profundidade; o resto é móvel dentro da sala e tem a profundidade
## que o próprio pé pintado declara (`_prop_depth`).
func _hides(p: Variant, band: Vector2) -> bool:
	return _depth(p, band) >= 1.0

func _depth(p: Variant, band: Vector2) -> float:
	var c := _corners(p)
	var base: float = c[2].y
	for v in c:
		base = maxf(base, v.y)
	return inverse_lerp(band.x, band.y, base)

## Interpola a aresta superior (canto 0 → canto 1) na coluna pedida.
func _edge_y(c: Array, x: float) -> float:
	var a: Vector2 = c[0]
	var b: Vector2 = c[1]
	if absf(b.x - a.x) < 0.0001:
		return maxf(a.y, b.y)
	var t := clampf((x - a.x) / (b.x - a.x), 0.0, 1.0)
	return lerpf(a.y, b.y, t)

func _sheet(game, path: String) -> void:
	if not ResourceLoader.exists(path):
		print("sem arte: ", path)
		return
	var img := (load(path) as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var props: Array = _props(game, path)
	var band := _band(game, path)
	for p in props:
		var corners := _corners(p)
		for i in range(corners.size()):
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % corners.size()]
			_line(img, Vector2i(int(a.x * w), int(a.y * h)), Vector2i(int(b.x * w), int(b.y * h)), Color(1, 0, 0.2, 0.9), 4)
	for i in range(props.size()):
		var c: Vector2 = _corners(props[i])[0]
		img.fill_rect(Rect2i(int(c.x * w) - 6, int(c.y * h) - 6, 12, 12), Color(1, 1, 0))
	_ruler(img, band, w, h)
	for gx in range(0, 21):
		var x := int(float(gx) / 20.0 * float(w))
		img.fill_rect(Rect2i(x, 0, 1, h), Color(1, 1, 1, 0.28))
	for gy in range(0, 21):
		var y := int(float(gy) / 20.0 * float(h))
		img.fill_rect(Rect2i(0, y, w, 1), Color(1, 1, 1, 0.28))
	var nome := path.get_file().get_basename()
	img.save_png(OUT + "recorte_" + nome + ".png")
	print("%s -> %dx%d • %d móvel(is)" % [nome, w, h, props.size()])

## As duas linhas que delimitam o piso pintado daquela arte: ciano no fundo (onde o
## transeunte mais distante pisa) e verde na frente (onde o da frente pisa). Um pé de
## contorno ENTRE elas declara um móvel plantado no chão e a profundidade dele é o ponto
## onde pisa; um pé FORA delas declara parede (abaixo) ou móvel colado no muro (acima),
## e só o primeiro tem licença de esconder o elenco inteiro.
func _ruler(img: Image, band: Vector2, w: int, h: int) -> void:
	img.fill_rect(Rect2i(0, int(band.x * float(h)) - 2, w, 5), Color(0.2, 1.0, 1.0, 0.9))
	img.fill_rect(Rect2i(0, int(band.y * float(h)) - 2, w, 5), Color(0.2, 1.0, 0.3, 0.9))

func _corners(p: Variant) -> Array:
	if p is Array:
		var out: Array = []
		for v in p:
			out.append(v as Vector2)
		while out.size() < 4:
			out.append(Vector2.ZERO)
		return out
	var r := p as Rect2
	return [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y), Vector2(r.position.x, r.end.y)]

func _line(img: Image, a: Vector2i, b: Vector2i, color: Color, thickness: int) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	if steps == 0:
		return
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var x := int(round(lerpf(float(a.x), float(b.x), t)))
		var y := int(round(lerpf(float(a.y), float(b.y), t)))
		img.fill_rect(Rect2i(x - thickness / 2, y - thickness / 2, thickness, thickness), color)
