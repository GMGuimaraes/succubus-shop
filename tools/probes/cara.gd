extends SceneTree

## A loja muda de cara com o placar? O probe sobe o ouro até cada uma das cinco
## faixas e fotografa o salão em janela, sempre em par: a mesma cena com a camada
## escondida e com a camada acesa. A diferença entre as duas fotos é o que a
## decoração pintou, nada além disso — o resto da cena (fundo, elenco, painel, poeira)
## está congelado nos dois cliques. A faixa 0 entrou no laço porque agora ela também
## pinta: é o canteiro, e a referência dela só pode ser a camada escondida — zerar a
## banda já não apaga nada, e medir banda 0 contra banda 0 daria um 0,00 de engano.
## Prova também o aquecimento do fundo, a lona lavando a cor dos móveis, o que o painel
## diz, que a sala sem chão não recebe decoração nenhuma e que o reset devolve o salão
## em obras — duas leituras seguidas do canteiro têm de bater, porque a obra é desenhada
## sem sorteio.
##
## Uso (janela, nunca --headless: o recorte de frame precisa de rasterizador):
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 9000 \
##     --script res://tools/probes/cara.gd
##
## Veredito medido nesta rodada: a camada pinta 5,33 → 3,55 → 2,06 → 2,74 → 4,02 de
## diferença média por canal sobre o salão congelado. A escada NÃO é crescente de
## propósito: o canteiro é o que mais diverge da arte pintada (andaime, lona, entulho,
## massa crua e lâmpada), e o meio da escada é a faixa 2, onde a casa está exatamente
## como o PNG. "Corrigir" o 5,33 para caber numa rampa crescente é apagar a obra. O
## resto fecha o cerco: 0,00 na sala sem chão, 4,02 de volta na recepção reaberta e o
## par do reset idêntico (5,33 / 5,33), porque a obra é desenhada sem sorteio. A luz
## acompanha: fundo 0,460/0,460/0,620 na faixa 0 subindo a 1,120/1,070/0,930 na 4, com
## o elenco junto (0,579 → 1,094, alfa sempre 1,00, porque o alfa é do fade de sala).
## Se a faixa 0 voltar a dar 0,00, a obra sumiu da camada e a loja abre pronta demais.
## Se o elenco divergir do fundo, alguém pisou `stage_layer.modulate` inteiro e cortou
## o fade de troca de sala.

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

	print("── a faixa acende o salão, começando pelo canteiro ──")
	for band in range(0, game.PROGRESS_BAND_SCORES.size()):
		# Devolve a camada à banda anterior antes do refresh: sem isso a medição
		# forçada do laço deixaria a subida da faixa 1 parecida com uma descida, e
		# o aviso não dispara.
		game._progress_band = band - 1
		game.gold = int(game.PROGRESS_BAND_SCORES[band])
		game._refresh_ui()
		var warm: Color = game.background_layer.modulate
		var lona: Color = game.stage_occluder.modulate
		var elenco: Color = game.stage_layer.modulate
		var med := await _par(band, "faixa-%d" % band)
		print("faixa %d (%s): placar %d, banda automática=%s, camada pinta %.2f de 255, " % [
			band, game.PROGRESS_BAND_NAMES[band], game.business_score(),
			str(game._progress_band == band), med] + "fundo %.3f/%.3f/%.3f, " % [
			warm.r, warm.g, warm.b] + "lona dos móveis %.3f/%.3f/%.3f, " % [
			lona.r, lona.g, lona.b] + "elenco %.3f/%.3f/%.3f a %.2f, poeira %d" % [
			elenco.r, elenco.g, elenco.b, elenco.a, game.ambient_particles.amount])
		print("   painel: %s" % game._progress_line())
		print("   aviso: %s" % game.last_event)

	print("\n── a sala sem chão não recebe decoração ──")
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

	print("\n── o reset devolve o salão em obras, e a obra é sempre a mesma ──")
	game._reset_run()
	game._refresh_ui()
	await _frames(40)
	# A luz da cena é lida ANTES da medição: `_freeze()` devolve o fundo ao branco
	# para isolar a camada, e uma cor pega depois do congelamento seria sempre 1,000.
	var fundo_cru: Color = game.background_layer.modulate
	var lona_cru: Color = game.stage_occluder.modulate
	var poeira_cru: int = game.ambient_particles.amount
	var crua := await _auto("depois-do-reset")
	var repetida := await _auto("depois-do-reset-de-novo")
	print("banda=%d, fundo %.3f/%.3f/%.3f, lona dos móveis %.3f/%.3f/%.3f, poeira %d, o jogo pintou %.2f e %.2f" % [
		game._progress_band, fundo_cru.r, fundo_cru.g, fundo_cru.b,
		lona_cru.r, lona_cru.g, lona_cru.b, poeira_cru, crua, repetida])
	print("   os dois números são a mesma cena lida duas vezes: divergir é a obra " +
		"dependendo de sorteio, e redraw diferente é salão tremendo")
	print("   painel depois do reset: %s" % game._progress_line())
	print("   quiet depois da primeira tela: %s (esperado false)" % str(game._progress_quiet))

	## O canteiro com elenco, painel e poeira: foto para olhar, não para medir. É a
	## primeira tela de quem abre o jogo pela primeira vez.
	game._reset_run()
	game._show_stage_for_room("res://assets/shop_scene.png", true)
	await _frames(40)
	_mostrar_tudo(game)
	game._refresh_ui()
	game._on_customer_tick()
	await _frames(120)
	_shot("canteiro-cheio-faixa-0.png")
	print("\ncanteiro com elenco na faixa 0: %scanteiro-cheio-faixa-0.png" % OUT)

	## O salão de volta ao normal, com elenco, painel e poeira na faixa máxima:
	## foto para olhar, não para medir.
	game.gold = int(game.PROGRESS_BAND_SCORES[4])
	game._show_stage_for_room("res://assets/shop_scene.png", true)
	await _frames(40)
	_mostrar_tudo(game)
	game._refresh_ui()
	game._on_customer_tick()
	await _frames(120)
	_shot("salao-cheio-faixa-4.png")
	print("salão com elenco na faixa 4: %ssalao-cheio-faixa-4.png" % OUT)
	quit()

## Devolve à tela tudo que a medição escondeu: sem isso a foto "para olhar" sairia sem
## elenco, sem painel e sem a camada que acabou de ser medida. O tom do fundo e da lona
## volta pelo `_refresh_ui()` do chamador, não pelo branco do congelamento — a foto tem
## de mostrar a luz que quem joga vê.
func _mostrar_tudo(game) -> void:
	game.stage_layer.visible = true
	game.stage_occluder.visible = true
	game.ui_layer.visible = true
	game.ambient_particles.visible = true
	game.stage_seller.visible = true
	game._progress_layer.visible = true
	game._progress_layer.queue_redraw()

## Congela tudo que não é a camada: o fundo pintado fica na cor original, a lona dos
## móveis volta ao tom de tinta, elenco, palco, painel e poeira saem de cena. O que
## sobra entre duas fotos é a decoração, e só ela.
func _freeze() -> void:
	var game = _game
	game.background_layer.modulate = Color(1.0, 1.0, 1.0, 1.0)
	game.stage_occluder.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if is_instance_valid(game.stage_layer):
		game.stage_layer.visible = false
	if is_instance_valid(game.stage_occluder):
		game.stage_occluder.visible = false
	if is_instance_valid(game.ui_layer):
		game.ui_layer.visible = false
	if is_instance_valid(game.ambient_particles):
		game.ambient_particles.visible = false

## Par de fotos da mesma cena: uma com a camada escondida, uma com a banda pedida.
## Esconder em vez de zerar a banda é o que dá à faixa 0 uma referência que não é ela
## mesma. Devolve a diferença média por canal, em 255.
func _par(band: int, nome: String) -> float:
	var game = _game
	_freeze()
	game._progress_band = band
	game._progress_layer.visible = false
	game._progress_layer.queue_redraw()
	await _frames(3)
	var sem := _shot("%s-sem-camada.png" % nome)
	game._progress_layer.visible = true
	game._progress_layer.queue_redraw()
	await _frames(3)
	var com := _shot("%s.png" % nome)
	return _mean_diff(sem, com)

## O mesmo par, mas medindo o que o próprio jogo desenhou: a primeira foto é o estado
## em que a cena está, a segunda esconde a camada. É a conta que prova que a sala errada
## não recebe decoração e que a vida nova recebe obra.
func _auto(nome: String) -> float:
	var game = _game
	_freeze()
	await _frames(3)
	var agora := _shot("%s-auto.png" % nome)
	var camada: Control = game._progress_layer
	camada.visible = false
	camada.queue_redraw()
	await _frames(3)
	var sem := _shot("%s-sem-camada.png" % nome)
	# Devolve a camada ao ar: a próxima medição precisa encontrar a cena exatamente
	# como ela está, senão o 0,00 de uma sala viraria o 0,00 de todas.
	camada.visible = true
	camada.queue_redraw()
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
