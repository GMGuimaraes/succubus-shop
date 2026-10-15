extends SceneTree

## A loja muda de cara com o placar? O probe sobe o ouro até cada uma das cinco
## faixas e fotografa o salão em janela, sempre em par: a mesma cena sem camada e
## com a camada. A diferença entre as duas fotos é o que a decoração pintou, nada
## além disso — o resto da cena (fundo, elenco, painel, poeira) está congelado nos
## dois cliques. Prova também o aquecimento do fundo, o que o painel diz, que a
## sala sem chão não recebe tapete e que o reset devolve o salão cru.
##
## Uso (janela, nunca --headless: o recorte de frame precisa de rasterizador):
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 6000 \
##     --script res://tools/probes/cara.gd
##
## Veredito medido nesta rodada: a camada pinta 1,15 → 2,06 → 2,74 → 4,01 de
## diferença média por canal sobre o salão cru, 0,00 na sala sem chão, 4,01 de
## volta na recepção reaberta e 0,00 depois do reset. Um "0,00" na faixa 4 da
## recepção, ou um número que não cresce, é a camada tendo sumido do palco.

const OUT := "D:/Downloads/tmp-userdata/cara/"

var _game = null

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	_game = game
	await _frames(6)
	game.world_timer.stop()
	game._reset_run()
	game._refresh_ui()
	game.background_layer.texture = load("res://assets/shop_scene.png")
	game._show_stage_for_room("res://assets/shop_scene.png", true)
	await _frames(40)
	var layer: Control = game._progress_layer
	print("\ncamada: valid=%s, z=%d, tamanho %.0fx%.0f, mouse=%d (entre o fundo -1000 e o palco -500)" % [
		str(is_instance_valid(layer)), layer.z_index, layer.size.x, layer.size.y, layer.mouse_filter])
	print("camada isolada, cenário congelado: %.2f de 255\n" % await _par(4, "congelada"))

	print("── a faixa acende o salão ──")
	for band in range(1, game.PROGRESS_BAND_SCORES.size()):
		# Devolve a camada à banda anterior antes do refresh: sem isso a medição
		# forçada do laço deixaria a subida da faixa 1 parecida com uma descida, e
		# o aviso não dispara.
		game._progress_band = band - 1
		game.gold = int(game.PROGRESS_BAND_SCORES[band])
		game._refresh_ui()
		var warm: Color = game.background_layer.modulate
		var med := await _par(band, "faixa-%d" % band)
		print("faixa %d (%s): placar %d, banda automática=%s, camada pinta %.2f de 255, fundo %.3f/%.3f/%.3f, poeira %d" % [
			band, game.PROGRESS_BAND_NAMES[band], game.business_score(),
			str(game._progress_band == band), med, warm.r, warm.g, warm.b,
			game.ambient_particles.amount])
		print("   painel: %s" % game._progress_line())
		print("   aviso: %s" % game.last_event)

	print("\n── a sala sem chão não recebe tapete ──")
	game._show_stage_for_room("res://assets/reception_scene_flirty.png", false)
	await _frames(40)
	var sem_chao := await _auto("sala-fechada")
	print("walkable=%s, banda=%d: o jogo pintou %.2f (esperado 0,00 — sem chão não há onde desenhar)" % [
		str(game._stage_walkable), game._progress_band, sem_chao])
	game._show_stage_for_room("res://assets/shop_scene.png", true)
	await _frames(40)
	var de_volta := await _auto("sala-de-volta")
	print("sala de volta: walkable=%s, o jogo pintou %.2f (esperado igual à faixa 4)" % [
		str(game._stage_walkable), de_volta])

	print("\n── o reset devolve o salão cru ──")
	game._reset_run()
	game._refresh_ui()
	await _frames(40)
	var crua := await _auto("depois-do-reset")
	print("banda=%d, fundo %.3f/%.3f/%.3f, poeira %d, o jogo pintou %.2f (esperado 0,00)" % [
		game._progress_band, game.background_layer.modulate.r,
		game.background_layer.modulate.g, game.background_layer.modulate.b,
		game.ambient_particles.amount, crua])
	print("   a descida de faixa não comemora: aviso diz \"%s\"" % game.last_event)
	print("   quiet depois da primeira tela: %s (esperado false)" % str(game._progress_quiet))

	## O salão de volta ao normal, com elenco, painel e poeira na faixa máxima:
	## foto para olhar, não para medir.
	game.gold = int(game.PROGRESS_BAND_SCORES[4])
	game._show_stage_for_room("res://assets/shop_scene.png", true)
	await _frames(40)
	game.stage_layer.visible = true
	game.stage_occluder.visible = true
	game.ui_layer.visible = true
	game.ambient_particles.visible = true
	game.stage_seller.visible = true
	game._refresh_ui()
	game._on_customer_tick()
	await _frames(120)
	_shot("salao-cheio-faixa-4.png")
	print("\nsalão com elenco na faixa 4: %ssalao-cheio-faixa-4.png" % OUT)
	quit()

## Congela tudo que não é a camada: o fundo pintado fica na cor original, elenco,
## palco, móveis, painel e poeira saem de cena. O que sobra entre duas fotos é a
## decoração, e só ela.
func _freeze() -> void:
	var game = _game
	game.background_layer.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if is_instance_valid(game.stage_layer):
		game.stage_layer.visible = false
	if is_instance_valid(game.stage_occluder):
		game.stage_occluder.visible = false
	if is_instance_valid(game.ui_layer):
		game.ui_layer.visible = false
	if is_instance_valid(game.ambient_particles):
		game.ambient_particles.visible = false

## Par de fotos da mesma cena: uma com a camada desligada (banda 0), uma com a
## banda pedida. Devolve a diferença média por canal, em 255.
func _par(band: int, nome: String) -> float:
	var game = _game
	_freeze()
	game._progress_band = 0
	game._progress_layer.queue_redraw()
	await _frames(3)
	var sem := _shot("%s-sem-camada.png" % nome)
	game._progress_band = band
	game._progress_layer.queue_redraw()
	await _frames(3)
	var com := _shot("%s.png" % nome)
	return _mean_diff(sem, com)

## O mesmo par, mas medindo o que o próprio jogo desenhou: a primeira foto é o
## estado em que a cena está, a segunda força a camada a apagar. É a conta que
## prova que a sala errada ou a vida nova não recebem decoração.
func _auto(nome: String) -> float:
	var game = _game
	_freeze()
	await _frames(3)
	var agora := _shot("%s-auto.png" % nome)
	var antes: int = game._progress_band
	game._progress_band = 0
	game._progress_layer.queue_redraw()
	await _frames(3)
	var sem := _shot("%s-sem-camada.png" % nome)
	# Devolve a banda que o jogo tinha aplicado: a próxima medição precisa encontrar
	# a cena exatamente como ela está, senão o 0,00 de uma sala viraria o 0,00 de todas.
	game._progress_band = antes
	game._progress_layer.queue_redraw()
	await _frames(3)
	return _mean_diff(sem, agora)

func _shot(nome: String) -> Image:
	var shot := get_root().get_texture().get_image()
	if shot == null:
		return null
	var err := shot.save_png(OUT + nome)
	if err != OK:
		print("   ERRO salvando %s (%d)" % [nome, err])
	return shot

## Diferença média por canal entre duas fotos do mesmo tamanho, amostrando de 3 em
## 3 pixels: é o número que diz se o salão mudou de cara de verdade.
func _mean_diff(a: Image, b: Image) -> float:
	if a == null or b == null:
		return -1.0
	var dim := a.get_size()
	if dim != b.get_size():
		return -1.0
	var total := 0.0
	var n := 0
	for y in range(0, dim.y, 3):
		for x in range(0, dim.x, 3):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	return (total / maxf(1.0, float(n))) * 255.0 / 3.0

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
