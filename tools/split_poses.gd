extends SceneTree
## Divide uma folha de poses em sprites individuais.
##
## A folha é uma imagem só com N poses do MESMO personagem recortadas sobre verde
## puro (#00FF00). Gerar uma folha custa uma imagem e entrega N poses idênticas em
## rosto, roupa e escala; gerar N poses separadas custa N imagens e quase nunca
## bate. É isto que torna viável ter vinte quadros por personagem.
##
## Uso:
##   godot --headless --path . -s res://tools/split_poses.gd -- \
##     <caminho da folha> <prefixo de saida> <nomes das poses, separados por virgula>
## Exemplo:
##   ... -- C:/folhas/adventurer.png res://assets/stage_adventurer walk1,walk2,walk3
##   grava assets/stage_adventurer_walk1.png e companhia, com o pé de cada pose
##   alinhado na base e a altura normalizada em STAGE_HEIGHT.
##
## O corte cai nos vales da curva de ocupação, não em painéis de largura fixa: capa
## e lenço atravessam o vão entre duas poses, e o espaçamento de uma folha gerada
## nunca é exato. Cada pose ainda é aparada na sua caixa de pixels vivos e ancorada
## pelo pé, então o ciclo de caminhada troca de quadro sem deslocar o corpo.

const STAGE_HEIGHT := 420.0
## Verde do fundo é chroma key: qualquer pixel mais verde que vermelho e azul, e
## verde o bastante para não ser dourado de armadura, vira transparente.
const GREEN_MIN := 0.45
const GREEN_DOMINANCE := 1.12
## O vale procurado fica até 30% do passo para cada lado da fronteira teórica, e a
## curva é suavizada para um braço solitário não ser confundido com um vão.
const CUT_SEARCH := 0.3
const SMOOTH_WINDOW := 25
## Mancha menor que isso, comparada com o corpo, é resíduo de pose vizinha.
const MASS_MIN_SHARE := 0.06

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		push_error("uso: -s res://tools/split_poses.gd -- <folha.png> <prefixo> <pose1,pose2,...>")
		quit(1)
		return
	var sheet_path := str(args[0])
	var prefix := str(args[1])
	var pose_names := str(args[2]).split(",")
	var sheet := Image.load_from_file(sheet_path)
	if sheet == null:
		push_error("não consegui abrir a folha: %s" % sheet_path)
		quit(1)
		return
	sheet.convert(Image.FORMAT_RGBA8)
	_key_green(sheet)
	var cuts := _cut_columns(sheet, pose_names.size())
	for i in range(pose_names.size()):
		var from := 0 if i == 0 else int(cuts[i - 1])
		var to := sheet.get_width() if i >= cuts.size() else int(cuts[i])
		var bounds := _content_bounds(sheet, from, to)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			push_error("a pose %s veio vazia do recorte" % str(pose_names[i]))
			quit(1)
			return
		var out_path := "%s_%s.png" % [prefix, str(pose_names[i]).strip_edges()]
		var sprite := _to_stage(sheet, bounds)
		if sprite.save_png(ProjectSettings.globalize_path(out_path)) != OK:
			push_error("falhou ao salvar %s" % out_path)
			quit(1)
			return
		print("%s <- %dx%d (recorte %dx%d, x %d..%d)" % [out_path, sprite.get_width(), sprite.get_height(), bounds.size.x, bounds.size.y, bounds.position.x, bounds.end.x])
	quit(0)

## Tira o verde e, no contorno, segura o transbordo para não deixar borda neon.
func _key_green(sheet: Image) -> void:
	for y in range(sheet.get_height()):
		for x in range(sheet.get_width()):
			var color := sheet.get_pixel(x, y)
			if color.g >= GREEN_MIN and color.g / maxf(color.r, 0.001) >= GREEN_DOMINANCE and color.g / maxf(color.b, 0.001) >= GREEN_DOMINANCE:
				sheet.set_pixel(x, y, Color(0, 0, 0, 0))
			elif color.g >= GREEN_MIN:
				sheet.set_pixel(x, y, Color(color.r, color.g * 0.82, color.b, color.a))

## Fronteiras entre poses: o ponto mais frouxo da curva suavizada ao redor de cada
## divisão teórica da folha.
func _cut_columns(sheet: Image, count: int) -> Array[int]:
	var width := sheet.get_width()
	if count < 2:
		return []
	var raw: Array[int] = []
	for x in range(width):
		var hit := 0
		for y in range(sheet.get_height()):
			if sheet.get_pixel(x, y).a > 0.0:
				hit += 1
		raw.append(hit)
	var smoothed: Array[float] = []
	var half := SMOOTH_WINDOW / 2
	for x in range(width):
		var total := 0
		var samples := 0
		for offset in range(-half, half + 1):
			var sample_x := x + offset
			if sample_x < 0 or sample_x >= width:
				continue
			total += raw[sample_x]
			samples += 1
		smoothed.append(float(total) / float(maxi(1, samples)))
	var cuts: Array[int] = []
	var step := float(width) / float(count)
	for i in range(1, count):
		var center := int(round(step * float(i)))
		var reach := int(step * CUT_SEARCH)
		var best := center
		var best_value := 1e20
		for x in range(maxi(1, center - reach), mini(width - 1, center + reach)):
			if smoothed[x] < best_value:
				best_value = smoothed[x]
				best = x
		cuts.append(best)
	cuts.sort()
	return cuts

## Caixa apertada do conteúdo real entre duas fronteiras.
func _content_bounds(sheet: Image, from: int, to: int) -> Rect2i:
	var min_x := to
	var max_x := from
	var min_y := sheet.get_height()
	var max_y := 0
	for x in range(from, to):
		for y in range(sheet.get_height()):
			if sheet.get_pixel(x, y).a <= 0.0:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

## Escala a pose para a altura do palco e ancora o pé na base, para que trocar de
## quadro não desloque o corpo nem o pivô.
func _to_stage(sheet: Image, bounds: Rect2i) -> Image:
	var cropped := sheet.get_region(bounds)
	_keep_main_mass(cropped)
	var kept := _tight_bounds(cropped)
	if kept.size.x <= 0 or kept.size.y <= 0:
		return cropped
	cropped = cropped.get_region(kept)
	var scale := STAGE_HEIGHT / float(kept.size.y)
	cropped.resize(maxi(1, int(round(kept.size.x * scale))), int(STAGE_HEIGHT), Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(cropped.get_width(), int(STAGE_HEIGHT) + 2, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(cropped, Rect2i(0, 0, cropped.get_width(), cropped.get_height()), Vector2i(0, 1))
	return canvas

## O lenço de uma pose vizinha invade o corte e sobra como manchinha na borda. O
## corpo é a maior mancha conectada da caixa (roupa e cabelo estão grudados nele),
## então qualquer pedaço menor que uma fração dele é resíduo da folha e vai fora.
func _keep_main_mass(cropped: Image) -> void:
	var width := cropped.get_width()
	var height := cropped.get_height()
	var labels := PackedInt32Array()
	labels.resize(width * height)
	labels.fill(-1)
	var sizes: Array[int] = []
	var next_label := 0
	for start in range(width * height):
		if labels[start] >= 0 or cropped.get_pixel(start % width, start / width).a <= 0.0:
			continue
		var stack: Array[int] = [start]
		labels[start] = next_label
		var area := 0
		while not stack.is_empty():
			var index := int(stack.pop_back())
			area += 1
			var x := index % width
			var y := index / width
			for neighbor in [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]]:
				var nx: int = neighbor[0]
				var ny: int = neighbor[1]
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				var n_index := ny * width + nx
				if labels[n_index] >= 0 or cropped.get_pixel(nx, ny).a <= 0.0:
					continue
				labels[n_index] = next_label
				stack.append(n_index)
		sizes.append(area)
		next_label += 1
	if sizes.size() < 2:
		return
	var biggest := int(sizes.max())
	for index in range(width * height):
		var label := labels[index]
		if label >= 0 and sizes[label] < int(biggest * MASS_MIN_SHARE):
			cropped.set_pixel(index % width, index / width, Color(0, 0, 0, 0))

func _tight_bounds(cropped: Image) -> Rect2i:
	var min_x := cropped.get_width()
	var max_x := 0
	var min_y := cropped.get_height()
	var max_y := 0
	for x in range(cropped.get_width()):
		for y in range(cropped.get_height()):
			if cropped.get_pixel(x, y).a <= 0.0:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
