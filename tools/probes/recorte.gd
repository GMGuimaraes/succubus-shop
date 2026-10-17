extends SceneTree

## Auditoria do recorte de oclusão: desenha cada contorno de móvel por cima da arte que
## ele deve recortar, com grade de coordenadas normalizadas, e imprime a linha de corte
## da chefe em cada faixa. Serve para duas perguntas que não têm resposta de memória:
## (1) toda arte da escada de progresso tem recorte próprio, ou está herdando o contorno
## da sala e cortando a chefe no alto de um balcão que aquela faixa não pintou;
## (2) a borda de cima do contorno bate com a quina pintada, lida em pixels e não em
## opinião. Os PNG saem em `OUT` e se leem de volta com a ferramenta de imagem.
##
## Uso: APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . --quit-after 1800 \
##     -s res://tools/probes/recorte.gd
## A sonda só lê constantes e imagens; o `world_timer` é parado antes de qualquer tique
## para nenhum `_save_game()` acontecer. Ainda assim roda com o APPDATA descartável.

const OUT := "D:/Downloads/tmp-userdata/"
## Salas fora da escada do salão: cada uma tem um único estado pintado, então o recorte
## delas continua na tabela por sala.
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
		var props: Array = _props(game, path)
		var corte := _cut_at(props, faixa_x)
		print("%-22s %s  corte da chefe em x=%.3f: y=%s" % [
			path.get_file().get_basename(),
			"próprio" if proprio else "HERDADO",
			faixa_x,
			"%.3f" % corte if corte > 0.0 else "—",
		])
	print("faixas sem recorte próprio: %d %s" % [sem_recorte, "✓" if sem_recorte == 0 else "✕"])
	for path in game.PROGRESS_BAND_ART + OUTRAS_SALAS:
		_sheet(game, path)
	_escada_de_oficio(game)
	quit()


## A escada de ofício (forja, biblioteca, santuário) é pintada em artes separadas por
## banda, e hoje nenhuma delas tem contorno próprio: todas herdam o recorte da sala.
## Herdar só é honesto enquanto o móvel herdado estiver onde a banda o pintou — é isto
## que a cartela por família mostra, cell a cell, com o corte da chefe impresso.
func _escada_de_oficio(game) -> void:
	print("== Escada de ofício: herança de recorte arte por arte ==")
	var total := 0
	for oficio in game.SECTOR_SCENERY_ART:
		var artes: Array = game.SECTOR_SCENERY_ART[oficio]
		var caminho_sala := str(game.SECTOR_SCENERY_ROOM[oficio])
		var faixa_x: float = (game.STAGE_ROOM_MEET.get(caminho_sala, Vector2(0.5, 0.4)) as Vector2).x
		var celulas: Array = []
		for caminho in artes:
			var props: Array = _props(game, str(caminho))
			var corte := _cut_at(props, faixa_x)
			total += 1
			print("   %-11s %-24s %s  corte da chefe em x=%.2f: y=%s" % [
				oficio, str(caminho).get_file().get_basename(),
				"próprio" if game.STAGE_ART_PROPS.has(str(caminho)) else "herdado",
				faixa_x, "%.3f" % corte if corte > 0.0 else "—",
			])
			celulas.append(str(caminho))
		_cartela(game, oficio, celulas, faixa_x)
	print("artes de ofício auditadas: %d (todas podem ter de herdar; a cartela é o veredito)" % total)


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
		for p in props:
			var corners := _corners(p)
			for k in range(corners.size()):
				var a: Vector2 = corners[k]
				var b: Vector2 = corners[(k + 1) % corners.size()]
				_line(img, Vector2i(int(a.x * w), int(a.y * h)), Vector2i(int(b.x * w), int(b.y * h)), Color(1, 0, 0.2, 0.95), 6)
		var corte := _cut_at(props, faixa_x)
		if corte > 0.0:
			img.fill_rect(Rect2i(0, int(corte * float(h)), w, 8), Color(1, 1, 0, 0.95))
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

## y da borda de cima do contorno que cobre o x da chefe — o número que decide onde o
## corpo dela é cortado. Sem móvel ali, devolve −1.
func _cut_at(props: Array, x: float) -> float:
	var melhor := -1.0
	for p in props:
		var c := _corners(p)
		if x < minf(c[0].x, c[3].x) or x > maxf(c[1].x, c[2].x):
			continue
		var y := _edge_y(c, x)
		if y >= 0.0 and (melhor < 0.0 or y > melhor):
			melhor = y
	return melhor

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
	for p in props:
		var corners := _corners(p)
		for i in range(corners.size()):
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % corners.size()]
			_line(img, Vector2i(int(a.x * w), int(a.y * h)), Vector2i(int(b.x * w), int(b.y * h)), Color(1, 0, 0.2, 0.9), 4)
	for i in range(props.size()):
		var c: Vector2 = _corners(props[i])[0]
		img.fill_rect(Rect2i(int(c.x * w) - 6, int(c.y * h) - 6, 12, 12), Color(1, 1, 0))
	for gx in range(0, 21):
		var x := int(float(gx) / 20.0 * float(w))
		img.fill_rect(Rect2i(x, 0, 1, h), Color(1, 1, 1, 0.28))
	for gy in range(0, 21):
		var y := int(float(gy) / 20.0 * float(h))
		img.fill_rect(Rect2i(0, y, w, 1), Color(1, 1, 1, 0.28))
	var nome := path.get_file().get_basename()
	img.save_png(OUT + "recorte_" + nome + ".png")
	print("%s -> %dx%d • %d móvel(is)" % [nome, w, h, props.size()])

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
