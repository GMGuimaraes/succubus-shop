extends SceneTree

## A loja muda de CARA com o placar, ou só de temperatura? A sonda sobe o ouro até cada
## uma das cinco faixas e mede a tela com o elenco, o painel, a poeira e a luz congelados:
## o que sobra entre duas fotos é a arte nova, e só ela. Faixa a faixa, do salão cru ao
## império, a diferença tem de ser grande — se uma faixa der 0,00 sobre a anterior, dois
## degraus da escada apontam para o mesmo PNG e o jogador não vê reforma nenhuma.
## Prova também que a escada é arte e não tinta (`_stage_room` continua sendo a GEOMETRIA
## do salão cheio em toda faixa, enquanto `_stage_art` é o PNG pintado), que a mesma faixa
## lida duas vezes não treme, que sala que não é o salão não recebe escada, que a guilda de
## expedição tem casa própria em todas as tabelas de chão, e que a reencarnação devolve o
## casarão cru.
##
## Uso (janela, nunca --headless: o recorte de frame precisa de rasterizador):
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 9000 \
##     --script res://tools/probes/cara.gd
##
## Veredito medido nesta rodada: a casa ABRE na faixa 0 (`salon_bare_scene.png` na primeira
## tela, geometria `shop_scene.png`), e a escada pinta 26,44 → 27,95 → 34,23 → 39,16 de
## diferença média por canal de uma faixa para a seguinte (escala 0–255 da tela inteira),
## com 0,00 da primeira tela para a faixa 0 — porque as duas JÁ são o mesmo casarão cru, e
## é exatamente esse 0,00 que prova a abertura. Contra o cru a escada abre 26,44 → 33,61 →
## 34,66 → 41,11: crescente de ponta a ponta, nenhum degrau apontando para o PNG do vizinho.
## A luz acompanha: fundo 0,800/0,820/0,950 no cru subindo a 1,100/1,060/0,940 no império,
## elenco junto a 0,78 do degradê (0,844 → 1,078), poeira 52 → 36 → 48 → 60 → 72.
## O resto fecha o cerco: placar 999999999 continua na banda 4 (índice não estoura), a
## mesma faixa lida duas vezes dá 0,00 e 0,00 (a arte não depende de sorteio), reabrir um
## save da faixa 4 acorda com o império NA PRIMEIRA TELA (`_load_game` roda antes de
## `_build_ui`, então a arte do placar salvo é a arte da abertura), o close-up sem chão não
## recebe escada nenhuma, a recepção reaberta reencontra a arte da faixa, a guilda de
## expedição tem arte e geometria próprias nas nove tabelas de sala (e nenhuma trilha de
## passeio, de propósito), a escada pedida dentro da guilda não a pinta, e a reencarnação
## devolve o império ao casarão cru — 0,00 nas duas leituras.
## Se a primeira tela voltar a ser `shop_scene.png`, a faixa 0 virou 0 de novo e ninguém
## vê reforma nenhuma; se algum salto entre faixas der 0,00, dois degraus apontam para o
## mesmo PNG. Se o elenco divergir do fundo, alguém pisou `stage_layer.modulate` inteiro e
## cortou o fade de troca de sala.

const OUT := "D:/Downloads/tmp-userdata/cara/"
const GUILD_KEY := "res://assets/expedition_hall_scene.png"

var _game = null

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	_game = game
	await _frames(6)
	## O save descartável nunca viu a loja: o seletor de idioma abre por cima de tudo e
	## taparia as fotos. Fechá-lo é o caminho do jogador, não um `visible = false`.
	if is_instance_valid(game.menu_layer):
		game._close_menu()
		await _frames(6)
	game.world_timer.stop()
	game._reset_run()
	game._refresh_ui()
	await _frames(40)
	## A primeira tela é lida SEM empurrar sala nenhuma: forçar o fundo aqui é a sonda
	## consertando o que ela devia medir. A casa abre na faixa do placar, e placar zero é
	## o casarão cru.
	print("\n── a casa abre na faixa do placar ──")
	print("primeira tela: pintada=%s, `_stage_art`=%s, geometria=%s, banda=%d, arte esperada=%s" % [
		str(game.background_layer.texture.resource_path), game._stage_art,
		game._stage_room, game._progress_band, game._salon_art(game._progress_band_now())])
	print("   abrir com o salão cheio é a escada inteira perder o ponto de partida")
	print("\n── a escada é arte, não tinta ──")
	print("chaves: %d artes, %d luzes, %d nomes, %d presentes, %d placares — escada de tamanho torto é faixa sem PNG" % [
		game.PROGRESS_BAND_ART.size(), game.PROGRESS_BAND_LIGHT.size(),
		game.PROGRESS_BAND_NAMES.size(), game.PROGRESS_BAND_GIFTS.size(),
		game.PROGRESS_BAND_SCORES.size()])
	print("placa vazia lida duas vezes: %.2f (esperado 0,00 — é a mesma tela, duas capturas)" % await _auto("vazio"))

	var cru: Image = null
	var ultima: Image = await _band_photo(-1, "cru-de-partida")
	for band in range(0, game.PROGRESS_BAND_SCORES.size()):
		# Devolve a banda à faixa anterior antes do refresh: sem isso a subida forçada do
		# laço não teria de onde sair e a troca de arte não dispararia.
		game._progress_band = band - 1
		var atual := await _band_photo(band, "faixa-%d" % band)
		var salto := _mean_diff(ultima, atual)
		var do_cru := 0.0
		if band == 0:
			cru = atual
		else:
			do_cru = _mean_diff(cru, atual)
		var warm: Color = game.background_layer.modulate
		var lona: Color = game.stage_occluder.modulate
		var elenco: Color = game.stage_layer.modulate
		print("faixa %d (%s): placar %d, banda=%d, arte=%s, geometria=%s, salto da anterior %.2f, do cru %.2f de 255" % [
			band, game.PROGRESS_BAND_NAMES[band], game.business_score(), game._progress_band,
			game._stage_art, game._stage_room, salto, do_cru])
		print("   luz: fundo %.3f/%.3f/%.3f, móveis %.3f/%.3f/%.3f, elenco %.3f/%.3f/%.3f a %.2f, poeira %d" % [
			warm.r, warm.g, warm.b, lona.r, lona.g, lona.b,
			elenco.r, elenco.g, elenco.b, elenco.a, game.ambient_particles.amount])
		print("   painel: %s" % game._progress_line())
		ultima = atual

	print("\n── a escada fecha no topo e não treme ──")
	game._progress_band = game.PROGRESS_BAND_ART.size() - 1
	game.gold = 999999999
	game._refresh_ui()
	print("placar 999999999: banda=%d, arte=%s — índice fora da tabela é crash, banda estourada é PNG repetido" % [
		game._progress_band_now(), game._stage_art])
	var topo := await _auto("topo")
	var topo_de_novo := await _auto("topo")
	print("faixa 4 lida duas vezes: %.2f e %.2f (esperado iguais e 0,00 — a arte não depende de sorteio)" % [topo, topo_de_novo])

	print("\n── reabrir a casa crescida acorda crescida ──")
	# O caso que a faixa 0 de abertura esconde: `_load_game()` roda ANTES de `_build_ui()`,
	# então a primeira tela de quem volta é a arte do placar salvo, sem ninguém pedir.
	game.gold = int(game.PROGRESS_BAND_SCORES[4])
	game._refresh_ui()
	game._save_game()
	var reaberta = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(reaberta)
	await _frames(6)
	print("segunda abertura, save da faixa 4: pintada=%s, `_stage_art`=%s, geometria=%s, banda=%d" % [
		str(reaberta.background_layer.texture.resource_path), reaberta._stage_art,
		reaberta._stage_room, reaberta._progress_band])
	reaberta.queue_free()
	await _frames(3)

	print("\n── sala que não é o salão não recebe escada ──")
	game._show_stage_for_room("res://assets/reception_scene_flirty.png", false)
	await _frames(40)
	var close_arte: String = game._stage_art
	game._progress_band = 0
	game.gold = int(game.PROGRESS_BAND_SCORES[4])
	game._refresh_ui()
	await _frames(20)
	print("close-up com a faixa 4 pedida: arte=%s, banda=%d, pintura mudou=%s (esperado a MESMA arte — escada é do salão)" % [
		game._stage_art, game._progress_band, str(game._stage_art != close_arte)])
	# A volta à recepção passa por `_sector_scene` direto, não por `_set_sector`: o
	# balcão sorteia a chefe pintada na parede (22%), e uma foto mediada por sorteio não
	# prova a escada de ninguém.
	var cena: Dictionary = game._sector_scene("reception")
	game.background_layer.texture = load(str(cena["path"]))
	game._show_stage_for_room(str(cena["path"]), bool(cena["walkable"]))
	await _frames(40)
	print("de volta à recepção: arte=%s, banda=%d (esperado a arte da faixa 4, lida por `_sector_scene`)" % [
		game._stage_art, game._progress_band_now()])

	print("\n── a guilda de expedição é casa própria ──")
	game._set_sector("expedition")
	await _frames(40)
	print("expedição: arte=%s, geometria=%s, walkable=%s" % [
		game._stage_art, game._stage_room, str(game._stage_walkable)])
	print("normalização: a guilda é uma das artes do salão? %s — virar chave do salão é a sala perder o próprio chão" % [
		str(game.PROGRESS_BAND_ART.has(GUILD_KEY))])
	var tabelas := [
		["STAGE_ROOM_PROPS", game.STAGE_ROOM_PROPS],
		["STAGE_ROOM_DOOR", game.STAGE_ROOM_DOOR],
		["STAGE_ROOM_ARRIVE", game.STAGE_ROOM_ARRIVE],
		["STAGE_ROOM_QUEUE", game.STAGE_ROOM_QUEUE],
		["STAGE_ROOM_BROWSE", game.STAGE_ROOM_BROWSE],
		["STAGE_ROOM_MEET", game.STAGE_ROOM_MEET],
		["STAGE_ROOM_FLOOR", game.STAGE_ROOM_FLOOR],
		["STAGE_ROOM_LIGHTS", game.STAGE_ROOM_LIGHTS],
	]
	for linha in tabelas:
		var dados: Dictionary = linha[1]
		var tem := dados.has(GUILD_KEY)
		var medida = dados[GUILD_KEY] if tem else null
		print("   %s: %s (%s)" % [linha[0], "tem" if tem else "FALTA",
			str(medida.size()) if medida is Array else str(medida)])
	print("   STAGE_ROOM_WALK: %s — sem trilha o elenco cruza o salão por inteiro e passa atrás da mesa de guerra" % [
		str((game.STAGE_ROOM_WALK as Dictionary).has(GUILD_KEY))])
	game._progress_band = 0
	game.gold = int(game.PROGRESS_BAND_SCORES[4])
	game._refresh_ui()
	await _frames(20)
	print("escada pedida dentro da guilda: arte=%s banda=%d (esperado a guilda intacta)" % [
		game._stage_art, game._progress_band])
	_shot("guilda-expedicacao.png")
	print("   foto da guilda: %sguilda-expedicacao.png" % OUT)

	print("\n── a reencarnação devolve o casarão cru ──")
	# A volta à recepção é lida por `_sector_scene`, não por `_set_sector`: o balcão
	# sorteia a chefe pintada na parede e uma foto mediada por sorteio não prova escada
	# nenhuma. Reentrar tem de reencontrar a arte da FAIXA, não a da guilda.
	var volta: Dictionary = game._sector_scene("reception")
	game.background_layer.texture = load(str(volta["path"]))
	game._show_stage_for_room(str(volta["path"]), bool(volta["walkable"]))
	await _frames(40)
	print("de volta à recepção com a faixa 4 no placar: arte=%s, geometria=%s" % [
		game._stage_art, game._stage_room])
	game._reset_run()
	game._refresh_ui()
	await _frames(40)
	var cru_reset := await _auto("depois-do-reset")
	var cru_de_novo := await _auto("depois-do-reset")
	print("banda=%d, arte=%s, geometria=%s, fundo %.3f/%.3f/%.3f, poeira %d, lida duas vezes: %.2f e %.2f" % [
		game._progress_band, game._stage_art, game._stage_room,
		game.background_layer.modulate.r, game.background_layer.modulate.g, game.background_layer.modulate.b,
		game.ambient_particles.amount, cru_reset, cru_de_novo])
	print("   painel: %s" % game._progress_line())
	print("   quiet depois da primeira tela: %s (esperado false)" % str(game._progress_quiet))

	## As duas telas que quem joga vê: o salão cru na primeira abertura e o império no
	## topo. Foto para olhar, não para medir — elenco, painel e poeira de volta.
	for faixa in [0, 4]:
		game._reset_run()
		game._progress_band = faixa - 1
		game.gold = int(game.PROGRESS_BAND_SCORES[faixa])
		game._show_stage_for_room(str(game._salon_art(faixa)), true)
		await _frames(40)
		_mostrar_tudo(game)
		game._refresh_ui()
		game._on_customer_tick()
		await _frames(120)
		var nome := "salao-faixa-%d.png" % faixa
		_shot(nome)
		print("tela da faixa %d com elenco: %s%s (arte=%s)" % [faixa, OUT, nome, game._stage_art])
	quit()

## Devolve à tela tudo que a medição escondeu. Sem isso a foto "para olhar" sairia sem
## elenco, sem painel e sem poeira. A luz volta pelo `_refresh_ui()` do chamador, não pelo
## branco do congelamento.
func _mostrar_tudo(game) -> void:
	game.background_layer.visible = true
	game.stage_layer.visible = true
	game.stage_occluder.visible = true
	game.ui_layer.visible = true
	game.ambient_particles.visible = true
	game.stage_seller.visible = true

## Congela tudo que não é a arte pintada: elenco, recorte dos móveis, painel e poeira saem
## de cena e a luz do fundo volta ao branco. O que sobra entre duas fotos é o PNG novo, e
## só ele — luz e arte não podem ser creditadas uma à outra.
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

## Foto congelada da faixa pedida: o ouro entra na conta, o refresh troca a arte, a tela
## congela e clica. Faixa -1 é a foto de referência sem mexer em nada.
func _band_photo(band: int, nome: String) -> Image:
	var game = _game
	if band >= 0:
		game.gold = int(game.PROGRESS_BAND_SCORES[band])
		game._refresh_ui()
	_freeze()
	await _frames(3)
	var img := _shot("%s.png" % nome)
	_unfreeze()
	return img

## A tela do jeito que o jogo a deixou, lida contra ela mesma: dá 0,00 se a cena é estável
## e dá o tremor se a arte depende de sorteio.
func _auto(nome: String) -> float:
	var game = _game
	_freeze()
	await _frames(3)
	var agora := _shot("%s-auto.png" % nome)
	await _frames(3)
	var repetida := _shot("%s-auto-2.png" % nome)
	_unfreeze()
	return _mean_diff(agora, repetida)

## Descongela: a luz de novo pelo painel (que é quem a aplica por faixa) e o elenco de
## volta ao ar, para a próxima medição encontrar a sala como ela está.
func _unfreeze() -> void:
	var game = _game
	game._refresh_ui()
	if is_instance_valid(game.stage_layer):
		game.stage_layer.visible = true
	if is_instance_valid(game.stage_occluder):
		game.stage_occluder.visible = true
	if is_instance_valid(game.ui_layer):
		game.ui_layer.visible = true
	if is_instance_valid(game.ambient_particles):
		game.ambient_particles.visible = true

func _shot(nome: String) -> Image:
	var shot := get_root().get_texture().get_image()
	if shot == null:
		print("   ERRO: sem textura (rodou com --headless?)")
		return null
	var err := shot.save_png(OUT + nome)
	if err != OK:
		print("   ERRO salvando %s (%d)" % [nome, err])
	return shot

## Diferença média por canal entre duas fotos do mesmo tamanho, amostrando de 3 em 3
## pixels: é o número que diz se a loja trocou de arte de verdade.
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
