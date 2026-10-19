extends SceneTree

## Galeria de prints do README (#59): fotografa a partida de verdade — sete telas de sete
## sistemas — e imprime o que cada uma mostra, para o texto do README não prometer o que o
## arquivo não tem. A sonda não mede economia: monta estado, abre a tela, espera o layout e
## salva o PNG. O veredito de legibilidade é lido no PNG de volta, não aqui.
##
## Duas coisas a foto não pode fazer: escrever no save real (daí o APPDATA descartável) e
## fingir conteúdo. A nota do fiado nasce do próprio balcão — uma visita sem bolso mandada
## pela fila, no molde de `tools/probes/fiado.gd` — e não de um dicionário montado à mão.
##
## Uso (janela aberta, de propósito): o servidor de renderição `--headless` é o dummy e não
## tem textura nenhuma — `get_texture().get_image()` devolve null. A galeria exige a janela
## real, mesma regra de `tools/probes/trajeto.gd`:
##   APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 90000 \
##     -s res://tools/probes/galeria.gd
## E nas medidas da vitrine da Epic Games Store, com o argumento depois do `--`:
##   APPDATA="D:\\Downloads\\tmp-userdata" godot --path . --quit-after 90000 \
##     -s res://tools/probes/galeria.gd -- 1920
##
## As sete fotos caem em D:/Downloads/tmp-userdata/galeria/ e são copiadas manualmente para
## `res://screenshots/` com os nomes `gallery_*.png` que o README usa.
##
## Um argumento depois de `--` muda a janela e a pasta: `-- 1920` fotografa em 1920×1080 em
## `galeria-1920/`, que são as medidas do carrossel da Epic Games Store. A proporção é a
## mesma 16:9 do projeto, então com `stretch/mode="canvas_items"` o que muda é só o fator
## (1,0 → 1,5): o layout não reflui, o quadro fica mais nítido.

var pasta := "galeria"
var saida := "D:/Downloads/tmp-userdata/galeria/"
var medida := Vector2i.ZERO
const Regulars := preload("res://regulars.gd")
const SEED_VAL := 20261025

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var largura := int(args[0])
		if largura != 1280:
			medida = Vector2i(largura, int(largura * 9.0 / 16.0))
			pasta = "galeria-%d" % largura
			saida = "D:/Downloads/tmp-userdata/%s/" % pasta

	var dir := DirAccess.open("D:/Downloads/tmp-userdata/")
	if dir != null and not dir.dir_exists(pasta):
		dir.make_dir(pasta)

	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(10)
	## O save descartável nunca viu a loja, então a primeira abertura traz o seletor de
	## idioma por cima de tudo — e ele tapava as seis fotos. Fechá-lo é o caminho do
	## jogador, não um `visible = false`.
	if is_instance_valid(game.menu_layer):
		game._close_menu()
		await _frames(6)
	if medida != Vector2i.ZERO:
		## Medido nesta tela de 1920 × 1080: pedida antes do boot, a troca não segura —
		## `_apply_player_settings()` (main.gd) reaplica o modo gravado no `_ready()` e a
		## textura vinha 1920 × 1061, a janela com barra de título não comporta 1080 de
		## conteúdo. Depois do boot a tela cheia bate os 1920 × 1080 que a Epic exige.
		DisplayServer.window_set_size(medida)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		await _frames(12)
	game.world_timer.stop()
	game._reset_run()
	game.gold = 2400
	game.reputation = 46
	game.player_level = 14
	for product in game.products:
		for ingredient_id in (product.get("ingredients", {}) as Dictionary).keys():
			game.ingredient_stock[str(ingredient_id)] = 40
	## O estoque da prateleira é índice, não chave do dicionário.
	for index in range(game.products.size()):
		if int(game.products[index].get("stock", 0)) == 0:
			game._add_piece(index, 0)
	game._refresh_ui()
	await _frames(6)

	print("── 01 recepção com fila ──")
	for i in range(14):
		game._on_customer_tick()
	await _frames(8)
	print("  fila %d • atendidos %d • caixa %d • dia %d" % [
		game.service_queue.size(), game.customers_served, int(game.gold), int(game.shop_day)])
	await _snap("01_recepcao")

	print("── 02 balanço do dia ──")
	game.day_walkouts = 2
	game.ticks = 19
	game._on_customer_tick()
	await _frames(8)
	print("  janela aberta? %s" % str(is_instance_valid(game.day_layer)))
	await _snap("02_balanco")
	game._close_day_report()
	await _frames(4)

	print("── 03 forja com peça na brasa ──")
	game._set_sector("forge")
	game.gold = 2400
	game._craft_product(2)
	await _frames(8)
	print("  empregos %d • %s" % [game.craft_jobs.size(), str(game.last_event).split("\n")[0]])
	await _snap("03_forja")

	print("── 04 fiado e combo na parede ──")
	game._set_sector("reception")
	game.gold = 2400
	game._buy_credit_rank()
	game._buy_combo_rank()
	game._buy_combo_rank()
	## A nota tem de ser do balcão, não da sonda: o caixa encolhe de propósito para a
	## visita não ter como pagar, e volta ao normal depois do recibo 📖. A prateleira é
	## reabastecida porque os 14 tiques do salão já venderam o que estava nela.
	for index in range(4):
		game._add_piece(index, 0)
	game.gold = 4
	var alvo := _peça_cabevel(game)
	var semente := -1
	if alvo >= 0:
		semente = _servir_pobre(game, "aldric", 10, alvo)
	await _frames(8)
	game.gold = 2400
	game.combo_streak = 6
	game.combo_best = 6
	game.combo_gold = 128
	game._refresh_ui()
	await _frames(6)
	print("  fiado degrau %d • notas %d (semente %d, peça %d) • combo degrau %d" % [
		int(game.credit_rank), int(game.credit_book.size()), semente, alvo, int(game.combo_rank)])
	await _rolar_para(game, game.credit_button, "04_fiado")
	await _rolar_para(game, game.combo_button, "05_combo")

	print("── 06 painel de conquistas ──")
	game._show_menu_screen("conquistas")
	await _frames(8)
	print("  painel aberto? %s" % str(is_instance_valid(game.menu_layer)))
	await _snap("06_conquistas")
	game._free_menu_layer()
	await _frames(4)

	print("── 07 estrada com expedição em curso ──")
	game.gold = 2400
	game._set_sector("expedition")
	game._start_expedition("beco")
	await _frames(8)
	print("  em curso %d • %s" % [game.expeditions.size(), str(game.last_event).split("\n")[0]])
	await _snap("07_estrada")

	print("── galeria fechada ──")
	quit()


## A peça mais barata que já está na prateleira e que não cabe no bolso de 10 ouro.
func _peça_cabevel(game) -> int:
	var melhor := -1
	var melhor_preco := 1 << 30
	for index in range(game.products.size()):
		if int(game.products[index].get("stock", 0)) <= 0:
			continue
		var preco := int(game._shelf_price(index))
		if preco > 10 and preco < melhor_preco:
			melhor = index
			melhor_preco = preco
	return melhor


func _perfil(fregues_id: String, bolso: int, favorite_id: String) -> Dictionary:
	var regular: Dictionary = Regulars.find(fregues_id)
	return {
		"name": str(regular.get("name", fregues_id)),
		"favorite": favorite_id,
		"line": "bate no bolso vazio e olha a vitrine.",
		"regular_id": fregues_id,
		"portrait": int(regular.get("portrait", 0)),
		"tier": 1,
		"personal_request": false,
		"probe_sentinela": "visita fotografada",
		"faction": str(regular.get("faction", "aventureiros")),
		"budget": bolso,
		"patience": 3,
	}


## Manda a visita sentar no balcão e roda tiques até ELA ser atendida; a prova é a
## sentinela sair da fila, não a fila ficar vazia.
func _servir_pobre(game, fregues_id: String, bolso: int, alvo: int) -> int:
	var favorite := str(game.products[alvo]["id"])
	for tentativa in range(20):
		var semente := SEED_VAL + tentativa
		game.ticks = 1
		game.service_queue.clear()
		game.service_queue.append({"profile": _perfil(fregues_id, bolso, favorite),
			"waited": 0, "limit": 9})
		seed(semente)
		game._on_customer_tick()
		if not _fila_tem_sentinela(game):
			return semente
	return -1


## A visita fotografada ainda está esperando na fila?
func _fila_tem_sentinela(game) -> bool:
	for entry in game.service_queue:
		if str(entry.get("profile", {}).get("probe_sentinela", "")) == "visita fotografada":
			return true
	return false


## A coluna direita é um ScrollContainer sem alça guardada no jogo: a sonda acha o
## antepassado do botão e calcula o deslocamento dele dentro do conteúdo.
func _rolar_para(game, alvo: Control, nome: String) -> void:
	if alvo == null:
		print("  sem alvo para rolar")
		await _snap(nome)
		return
	for node in game.find_children("*", "ScrollContainer", true, false):
		var scroll := node as ScrollContainer
		if scroll == null or not scroll.is_ancestor_of(alvo):
			continue
		var conteudo := int(alvo.get_global_rect().position.y - scroll.get_global_rect().position.y) \
			+ int(scroll.scroll_vertical)
		scroll.scroll_vertical = maxi(0, conteudo - 40)
		await _frames(6)
		print("  rolado para y=%d (mín %d, máx %d) • fiado degrau %d, combo degrau %d" % [
			scroll.scroll_vertical, scroll.get_v_scroll_bar().min_value,
			scroll.get_v_scroll_bar().max_value, int(game.credit_rank), int(game.combo_rank)])
		await _snap(nome)
		return
	print("  nenhum ScrollContainer contém o botão: foto sem rolagem")
	await _snap(nome)


func _snap(nome: String) -> void:
	var image := get_root().get_texture().get_image()
	if image == null:
		print("  %s: SEM TEXTURA — rode sem --headless" % nome)
		return
	var obtida := Vector2i(image.get_width(), image.get_height())
	var desvio := ""
	if medida != Vector2i.ZERO and obtida != medida:
		desvio = "  ← FORA DA MEDIDA PEDIDA (%d x %d)" % [medida.x, medida.y]
	print("  %s.png salvo (%s) • %dx%d%s" % [
		nome, error_string(image.save_png(saida + nome + ".png")), obtida.x, obtida.y, desvio])


func _frames(count: int) -> void:
	for i in range(count):
		await process_frame
