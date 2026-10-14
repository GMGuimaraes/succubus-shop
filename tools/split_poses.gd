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
## As poses são separadas por faixas de colunas totalmente vazias depois do
## chroma key, então a folha deve ter respiro generoso entre as figuras.

const STAGE_HEIGHT := 420.0
const MIN_GAP_COLUMNS := 12
const MIN_SEGMENT_WIDTH := 40
## Verde do fundo é chroma key: qualquer pixel mais verde que vermelho e azul, e
## verde o bastante para não ser dourado de armadura, vira transparente.
const GREEN_MIN := 0.45
const GREEN_DOMINANCE := 1.12

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
	var segments := _find_segments(sheet)
	if segments.size() != pose_names.size():
		push_error("a folha tem %d poses, os nomes pediram %d" % [segments.size(), pose_names.size()])
		quit(1)
		return
	for i in range(segments.size()):
		var out_path := "%s_%s.png" % [prefix, str(pose_names[i]).strip_edges()]
		var sprite := _crop_to_stage(sheet, segments[i])
		var absolute := ProjectSettings.globalize_path(out_path)
		if sprite.save_png(absolute) != OK:
			push_error("falhou ao salvar %s" % out_path)
			quit(1)
			return
		print("%s <- %d x %d (origem %d px de largura)" % [out_path, sprite.get_width(), sprite.get_height(), (segments[i] as Rect2).size.x])
	quit(0)

## Tira o verde e, no contorno, devolve o pixel para não deixar borda neon.
func _key_green(sheet: Image) -> void:
	for y in range(sheet.get_height()):
		for x in range(sheet.get_width()):
			var color := sheet.get_pixel(x, y)
			var green := color.g / maxf(color.r, 0.001)
			var green_vs_blue := color.g / maxf(color.b, 0.001)
			if color.g >= GREEN_MIN and green >= GREEN_DOMINANCE and green_vs_blue >= GREEN_DOMINANCE:
				sheet.set_pixel(x, y, Color(0, 0, 0, 0))
			elif color.a > 0.0 and color.g >= GREEN_MIN:
				sheet.set_pixel(x, y, Color(color.r, color.g * 0.82, color.b, color.a))

## Colunas sem nenhum pixel opaco delimitam as poses. Um buraco menor que
## MIN_GAP_COLUMNS é só um oco entre braço e quadril, não uma divisória, então a
## faixa continua aberta até o vazio de verdade.
func _find_segments(sheet: Image) -> Array[Rect2]:
	var width := sheet.get_width()
	var occupied: Array[bool] = []
	for x in range(width):
		var hit := false
		for y in range(sheet.get_height()):
			if sheet.get_pixel(x, y).a > 0.05:
				hit = true
				break
		occupied.append(hit)
	var segments: Array[Rect2] = []
	var start := -1
	var last_hit := -1
	var x := 0
	while x < width:
		if occupied[x]:
			if start < 0:
				start = x
			last_hit = x
			x += 1
			continue
		var gap_end := x
		while gap_end < width and not occupied[gap_end]:
			gap_end += 1
		var closed := gap_end >= width or gap_end - x >= MIN_GAP_COLUMNS
		if closed and start >= 0 and last_hit + 1 - start >= MIN_SEGMENT_WIDTH:
			segments.append(Rect2(start, 0, last_hit + 1 - start, sheet.get_height()))
			start = -1
		x = gap_end if closed else x + 1
	if start >= 0 and last_hit + 1 - start >= MIN_SEGMENT_WIDTH:
		segments.append(Rect2(start, 0, last_hit + 1 - start, sheet.get_height()))
	# Duas poses coladas produziriam uma faixa larga demais; o desmembrador deve
	# falhar alto em vez de entregar um sprite com dois corpos.
	for segment in segments:
		if (segment as Rect2).size.x > width / maxf(1.0, float(segments.size())) * 1.9:
			push_error("faixa larga demais (%d px): as poses estão encostadas" % (segment as Rect2).size.x)
	return segments

## Recorta o bounding box real da pose, escala para a altura do palco e alinha o
## pé na base, que é o que permite trocar de frame sem o corpo pular de lugar.
func _crop_to_stage(sheet: Image, column_range: Rect2) -> Image:
	var bounds := _content_bounds(sheet, column_range)
	var cropped := sheet.get_region(Rect2i(bounds.position, bounds.size))
	var scale := STAGE_HEIGHT / float(cropped.get_height())
	cropped.resize(maxi(1, int(round(cropped.get_width() * scale))), int(STAGE_HEIGHT), Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(cropped.get_width(), int(STAGE_HEIGHT) + 2, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	canvas.blit_rect(cropped, Rect2i(0, 0, cropped.get_width(), cropped.get_height()), Vector2i(0, 1))
	return canvas

func _content_bounds(sheet: Image, column_range: Rect2) -> Rect2:
	var min_x := int(column_range.end.x)
	var max_x := int(column_range.position.x)
	var min_y := sheet.get_height()
	var max_y := 0
	for x in range(int(column_range.position.x), int(column_range.end.x)):
		for y in range(sheet.get_height()):
			if sheet.get_pixel(x, y).a <= 0.05:
				continue
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return column_range
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
