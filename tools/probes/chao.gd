extends SceneTree

## Onde o código planta o pé, no frame que o jogador realmente vê. Fotografa a recepção
## em cada uma das cinco faixas da escada e depois as outras quatro salas, riscando na
## foto a linha de chão de cada profundidade usada pelo elenco
## (0,08 / 0,12 / 0,22 / 0,40 / 0,82 / 1,00). Se a linha cair ACIMA do assoalho pintado,
## é ali que o corpo flutua — e o elenco do fundo flutuava em quatro das cinco faixas
## antes da faixa de chão passar a ser lida por arte (`STAGE_ART_FLOOR`).
##
## A régua ampliada existe porque detector automático de junção parede/chão se provou não
## confiável (leu 0,867 na guilda e 0,673 no salão cheio, onde a junção real é 0,575):
## aqui quem lê a altura é o olho, sobre uma escala desenhada a cada 0,01 de tela.
##
## Uso (janela, nunca --headless: precisa de rasterizador):
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 9000 \
##     --script res://tools/probes/chao.gd

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
}
const SALAS := {
	"guilda": "res://assets/expedition_hall_scene.png",
	"forja": "res://assets/forge_scene.png",
	"biblioteca": "res://assets/library_room_scene.png",
	"santuario": "res://assets/sanctum_room_scene.png",
}

var _game = null
var _falhas := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
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
