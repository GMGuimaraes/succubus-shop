extends SceneTree

## Auditoria de proporção: quanto do corpo de quem fica ATRÁS de um móvel pintado
## aparece acima da linha de corte, sala por sala. A pergunta não é "o sprite está
## grande?", é "a cabeça boiando sobre a mesa lê-se como gente?". Um corpo com 13% da
## altura visível é cabeça e pescoço atrás de um tampo — o "anão" que a tela mostra —
## e o mesmo corpo no balcão da recepção mostra 30% e ninguém reclama.
##
## A sonda refaz a conta que o palco faz de verdade (nó assado em `_lane_height` /
## `_figure_base_height` × `scale` do nó × multiplicador da sala), imprime pé, cabeça,
## corte e fração visível em fração da tela, e fecha com o veredito por sala: abaixo
## de 30% do corpo acima do móvel, a sala está pintando anão.
##
## Uso (janela visível — em `--headless` o palco nasce 64×64 e toda fração sai errada):
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 900 \
##     -s res://tools/probes/proporcao.gd

## Salas com chão pintado. As faixas do salão respondem pela geometria da recepção,
## então uma linha delas basta.
const SALAS: Array[String] = [
	"res://assets/shop_scene.png",
	"res://assets/forge_scene.png",
	"res://assets/library_room_scene.png",
	"res://assets/sanctum_room_scene.png",
	"res://assets/expedition_hall_scene.png",
]
## 0,40 é a faixa da chefe (`_lane_depths[1]`) e 0,05 a 0,30 é o sorteio real do
## transeunte em `_spawn_stage_walker`.
const PROFUNDIDADES: Array[float] = [0.05, 0.12, 0.20, 0.30, 0.40]
## A porta de aprovação é a própria recepção: a sala dela foi medida e olhada, e é o
## padrão de "gente atrás do balcão". Sala que mostra menos corpo que a recepção está
## encolhendo quem passa atrás do móvel.
var falhas := 0

func _initialize() -> void:
	var game = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(5)
	game.world_timer.stop()
	var layer: Vector2 = game.stage_layer.size
	print("== Proporção corpo × móvel pintado ==")
	print("palco: %.0f x %.0f px • figura cheia: %.0f px" % [
		layer.x, layer.y, game.STAGE_FIGURE_HEIGHT])
	if layer.y < 200.0:
		print("✕ palco sem tamanho de janela — rode sem --headless")
		quit()
		return
	for path in SALAS:
		_sala(game, path, layer)
	print("── veredito ──")
	var referencia: float = _chefe(game, SALAS[0], layer)["vis"]
	print("   referência da recepção: %.0f%% do corpo acima do balcão" % (referencia * 100.0))
	for path in SALAS:
		var chefe := _chefe(game, path, layer)
		if chefe["cut"] <= 0.0:
			print("   %-22s sem móvel na frente da chefe — nada a cortar" % [
				path.get_file().get_basename()])
			continue
		var ok: bool = chefe["vis"] >= referencia - 0.05
		if not ok:
			falhas += 1
		print("   %-22s corpo %.0fpx • visível acima do móvel %.0f%%  %s" % [
			path.get_file().get_basename(), chefe["body"], chefe["vis"] * 100.0,
			"ok" if ok else "ANÃO"])
	print("   %d sala(s) pintando anão" % falhas)
	await _fechar(game)
	quit()


func _sala(game, path: String, layer: Vector2) -> void:
	game._apply_room_props(path)
	var room: String = game._stage_room
	var props: Array = game.STAGE_ART_PROPS.get(path, game.STAGE_ROOM_PROPS.get(room, []))
	var meet: Vector2 = game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37))
	var band: Vector2 = game._stage_floor_line()
	print("── %s ── chão %.3f..%.3f • chefe em x=%.3f • adulto da sala ×%.2f" % [
		path.get_file().get_basename(), band.x, band.y, meet.x, game._room_figure_scale()])
	# A chefe: nó assado em `_lane_height(1)`, escala de descanso da sala, pé no chão
	# da faixa 1. É o corpo que mora atrás do móvel, e é dele que a tela fala.
	var chefe := _chefe(game, path, layer)
	if chefe["cut"] > 0.0:
		print("   chefe    pé=%.3f cabeça=%.3f corpo=%.0fpx corte=%.3f visível=%.0f%%" % [
			chefe["foot"] / layer.y, chefe["head"] / layer.y, chefe["body"],
			chefe["cut"] / layer.y, chefe["vis"] * 100.0])
	# O transeunte: nó assado em `_figure_base_height()`, escala da faixa no nó.
	for depth in PROFUNDIDADES:
		var lane: Dictionary = game._lane_at(depth)
		var body_px: float = game._figure_base_height() * float(lane["scale"])
		var foot_px: float = float(lane["floor_y"])
		var head_px: float = foot_px - body_px
		var cut_px := _cut_px(props, meet.x, layer.y)
		var vis := _visivel_px(head_px, cut_px, body_px) / body_px
		print("   d=%.2f    pé=%.3f cabeça=%.3f corpo=%.0fpx corte=%s visível=%s" % [
			depth, foot_px / layer.y, head_px / layer.y, body_px,
			"%.3f" % (cut_px / layer.y) if cut_px > 0.0 else "—     ",
			"%.0f%%" % (vis * 100.0) if cut_px > 0.0 else "todo ",
		])
	# O cliente do turno, que fica NA FRENTE do móvel: ele tem de continuar maior que
	# a chefe, senão a sala inverte a perspectiva.
	var frente: Dictionary = game._lane_at(game.STAGE_FRONT_DEPTH)
	var cliente_px: float = game._figure_base_height() * float(frente["scale"])
	print("   cliente  pé=%.3f corpo=%.0fpx  %s" % [
		frente["floor_y"] / layer.y, cliente_px,
		"mais perto = maior ✓" if cliente_px > chefe["body"] else "MENOR QUE A CHEFA ✕"])


## A conta da chefe na sala: devolve pé, cabeça, corpo, corte e fração visível em px.
func _chefe(game, path: String, layer: Vector2) -> Dictionary:
	game._apply_room_props(path)
	var room: String = game._stage_room
	var props: Array = game.STAGE_ART_PROPS.get(path, game.STAGE_ROOM_PROPS.get(room, []))
	var meet: Vector2 = game.STAGE_ROOM_MEET.get(room, Vector2(0.505, 0.37))
	var body_px: float = game._lane_height(1) * float(game._seller_rest_scale().x)
	var foot_px: float = float(game._lane(1)["floor_y"])
	var head_px: float = foot_px - body_px
	var cut_px := _cut_px(props, meet.x, layer.y)
	return {
		"foot": foot_px, "head": head_px, "body": body_px, "cut": cut_px,
		"vis": _visivel_px(head_px, cut_px, body_px) / body_px,
	}


## y do corte em px no x pedido, ou -1 quando nenhum móvel cobre aquele x.
func _cut_px(props: Array, x: float, height: float) -> float:
	var melhor := -1.0
	for p in props:
		var c := _corners(p)
		if x < minf(c[0].x, c[3].x) or x > maxf(c[1].x, c[2].x):
			continue
		var y := _edge_y(c, x)
		if y >= 0.0 and (melhor < 0.0 or y > melhor):
			melhor = y
	return melhor * height if melhor >= 0.0 else -1.0


## Quanto do corpo sobra acima do corte: zero se o móvel engoliu tudo, altura inteira
## se não há móvel na frente.
func _visivel_px(head_px: float, cut_px: float, body_px: float) -> float:
	if cut_px <= 0.0:
		return body_px
	return clampf(cut_px - head_px, 0.0, body_px)


func _corners(p: Variant) -> Array:
	if p is Array:
		var out: Array = []
		for v in p:
			out.append(v as Vector2)
		while out.size() < 4:
			out.append(Vector2.ZERO)
		return out
	var r := p as Rect2
	return [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x, r.end.y), Vector2(r.position.x, r.end.y)]


func _edge_y(c: Array, x: float) -> float:
	var a: Vector2 = c[0]
	var b: Vector2 = c[1]
	if absf(b.x - a.x) < 0.0001:
		return maxf(a.y, b.y)
	var t := clampf((x - a.x) / (b.x - a.x), 0.0, 1.0)
	return lerpf(a.y, b.y, t)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _fechar(game) -> void:
	game.world_timer.stop()
	game.queue_free()
	await _frames(2)
