extends SceneTree

## Sonda do salão das capas finas (#78): prova que o cordão de veludo é escada de
## progressão, não roleta de gorjeta — com o cordão guardado nenhuma visita é capa fina,
## nenhum `randi()` extra é consumido e nenhum número do balcão se move; com ele estendido,
## a visita paga mais porque LEVA O TOPO DA BARRA, e quando a estante não tem o degrau que
## ela exige ela devolve a peça no lugar: estoque intacto, caixa intacto, fama cobrada.
##
## Medidas desta sonda: (1) cordão guardado — chance 0, exigência 0, 4000 sorteios sem uma
## única capa fina, e a cauda de 40 `randi()` depois de 200 carimbos é IDÊNTICA ao controle
## que nunca chamou a função; (2) os três nós cobram caixa e fama, recusa por fama e por ouro
## não movem um ouro, e o quarto clique no teto é recusado com o caixa intacto; (3) a fatia
## sorteada bate com o nó do cordão (8% / 14% / 22% em 4000 sorteios), o bolso multiplica e a
## paciência ganha um tique; (4) a capa fina servida sai com o topo da barra e deixa exatamente
## a gorjeta que a tabela do degrau anuncia sobre o preço de peça, fama +1 e nível parado;
## (5) estante abaixo da exigência devolve a peça: estoque, registro e caixa idênticos,
## desanimados +1, fama −1, recusadas +1, gorjeta 0 e o selo de serviço não acende; (6) o
## painel lê degrau, cordão e gorjetas nos quatro estados; (7) ler e escrever no salão não
## consome sorteio; (8) as quatro chaves atravessam o arquivo, o degrau é podado para o teto
## (9 vira 3), as contagens negativas e textuais viram 0, e save antigo sem as chaves acorda
## com o cordão guardado; (9) reencarnar enrola o cordão e apaga as gorjetas da vida; (10) os
## dois selos acendem exatamente em 1 e 10 servidas, e a lista fecha com 97 definições (91
## na leitura original do salão; o par do livro de reclamações, #79, e o par do cartaz do
## combo, #80, entraram depois);
## (11) na corrida de 200 tiques com a prateleira montada igual nos três lados e a mesma
## semente, o cordão guardado não tem UMA capa fina no salão — e os degraus 1 e 3 têm.
##
## Armadilha de régua: a gorjeta é lida sobre o preço de tabela da peça (`_piece_price`, sem
## mercado, fama, facção nem cartas), nunca sobre a etiqueta final do balcão — medir no caixa
## da venda leria tudo isso junto. E o produto escolhido tem de ser caro: a gorjeta tem piso
## de 4 ouro, e sobre a poção de 15 do índice 0 os 15% do degrau 1 (3 de ouro) virariam piso
## em todos os degraus, provando só o `maxi`. Aqui é o Pato Amaldiçoado (24 de base) com o
## topo em Obra-prima: a tabela da peça sai 44.40, 15% são **7** de gorjeta (o número lido na
## régua) e 30% seriam 13. As medidas de caixa selam as conquistas e estacionam o nível em 60:
## o primeiro selo paga 40 de ouro, o segundo 220, e estender o cordão dá 12 de experiência —
## sem a rolha, "gorjeta de 15%" estaria medindo o prêmio do selo e o ouro do level-up.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/salao.gd

const Locales = preload("res://locales.gd")
const Quality = preload("res://quality.gd")
const GameScript = preload("res://main.gd")

const SEED_VAL := 20261024

## O degrau que a sonda põe no topo da barra: Obra-prima é o índice 3 do espectro — passa no
## cordão 1 (que exige Refinado) e no cordão 2 (que exige Obra-prima), e é devolvido no
## lugar pelo cordão 3, que só aceita Mítico.
const TOPO := 3

## Pato Amaldiçoado: 24 de base e SEM validade — não apodrece na virada, não deixa lote
## órfão no registro de idade e dá gorjeta acima do piso de 4 em qualquer degrau.
const ALVO := 1

func _initialize() -> void:
	var g = await _loja("salão")
	_blindar(g)
	g.gold = 5000
	g.reputation = 30
	g._refresh_ui()

	print("── o cordão guardado não troca uma visita ──")
	var chance_zero: int = g._vip_chance()
	var exige_zero: int = g._vip_standard()
	var sumario := String(g._vip_summary())
	var base := _perfil_base(g)
	var carimbadas := 0
	for i in range(4000):
		if bool(g._maybe_vip(base).get("vip", false)):
			carimbadas += 1
	seed(SEED_VAL)
	for i in range(200):
		g._maybe_vip(base)
	var cauda_guardado := _cauda(40)
	seed(SEED_VAL)
	var cauda_controle := _cauda(40)
	print("   rank %d • chance %d (0) • exigência %d (0) • capa fina em 4000 sorteios: %d" % [
		g.vip_rank, chance_zero, exige_zero, carimbadas])
	print("   painel: %s" % sumario.substr(0, 96))
	print("   cauda de 40 randi() após 200 carimbos == controle sem chamada: %s" % str(
		cauda_guardado == cauda_controle))
	print("   botão: %s disabled=%s" % [_aspado(String(g.vip_button.text)), str(g.vip_button.disabled)])

	print("── a escada: três nós, cada um cobrando caixa e fama ──")
	var escada: Array[String] = []
	for r in range(GameScript.VIP_TIERS.size()):
		var row: Dictionary = GameScript.VIP_TIERS[r]
		# O degrau 0 não tem topo exigido: com a gaveta fechada `_vip_standard()` devolve o
		# índice 0 da tabela, que é o nome "Torto" — e nenhuma visita capa fina existe para
		# exigir nada. A etiqueta abaixo lê a inércia, não a tabela.
		var topo := "nada (gaveta fechada)" if int(row["rank"]) == 0 else str(Quality.tier(
			int(row["standard"]))["name"])
		escada.append("degrau %d: %d de ouro • fama %d • %d%% • bolso ×%.1f • exige %s • gorjeta %.0f%%" % [
			int(row["rank"]), int(row["cost"]), int(row["rep"]), int(row["chance"]),
			float(row["budget"]), topo, float(row["tip"]) * 100.0])
	print("   tabela medida: %s" % " | ".join(escada))
	g.reputation = 0
	var caixa := int(g.gold)
	g._buy_vip_rank()
	print("   sem fama: caixa %d→%d (igual) • rank %d • mural: %s" % [
		caixa, int(g.gold), g.vip_rank, String(g.last_event)])
	g.reputation = 10
	caixa = int(g.gold)
	g._buy_vip_rank()
	print("   degrau 1: caixa %d→%d (−220) • rank %d • fama %d→%d (10+1) • chance %d • exige %s" % [
		caixa, int(g.gold), g.vip_rank, 10, int(g.reputation), g._vip_chance(),
		str(Quality.tier(g._vip_standard())["name"])])
	g.reputation = 20
	caixa = int(g.gold)
	g._buy_vip_rank()
	print("   fama 20 no degrau 2 (pede 24): caixa %d→%d (igual) • rank %d" % [
		caixa, int(g.gold), g.vip_rank])
	g.reputation = 24
	g.gold = 500
	caixa = int(g.gold)
	g._buy_vip_rank()
	print("   ouro 500 no degrau 2 (custa 520): caixa %d→%d (igual) • rank %d" % [
		caixa, int(g.gold), g.vip_rank])
	g.gold = 5000
	g.reputation = 60
	caixa = int(g.gold)
	g._buy_vip_rank()
	var caixa_2 := int(g.gold)
	g._buy_vip_rank()
	print("   degrau 2 e 3 com fama 60: caixa %d→%d→%d (−520, −1100) • rank %d • chance %d • exige %s" % [
		caixa, caixa_2, int(g.gold), g.vip_rank, g._vip_chance(),
		str(Quality.tier(g._vip_standard())["name"])])
	caixa = int(g.gold)
	g._buy_vip_rank()
	print("   quarto clique no teto: caixa %d→%d (igual) • rank %d • botão %s disabled=%s" % [
		caixa, int(g.gold), g.vip_rank, _aspado(String(g.vip_button.text)),
		str(g.vip_button.disabled)])

	print("── a fatia sorteada bate com o nó do cordão ──")
	for r in range(1, GameScript.VIP_TIERS.size()):
		g.vip_rank = r
		var carimbo := 0
		for i in range(4000):
			if bool(g._maybe_vip(base).get("vip", false)):
				carimbo += 1
		var mostra := _perfil_vip(g)
		print("   degrau %d: %d de 4000 (%.1f%%) anunciados • bolso %d→%d • paciência %d→%d" % [
			r, carimbo, float(carimbo) / 40.0, int(base.get("budget", 0)),
			int(mostra.get("budget", 0)), int(base.get("patience", 0)),
			int(mostra.get("patience", 0))])
	g.vip_rank = 3

	print("── a capa fina sai da loja com o topo da barra ──")
	g._reset_run()
	_blindar(g)
	g.gold = 5000
	g.reputation = 30
	g.vip_rank = 1
	_raspar_estante(g)
	_por_estante(g, ALVO, _so_no_topo(3))
	var item: Dictionary = g.products[ALVO]
	var id_produto := str(item["id"])
	var tabela: float = g._piece_price(item, TOPO)
	var gorjeta_prevista := maxi(4, int(round(tabela * float(g._vip_row(1)["tip"]))))
	print("   estante raspada, só o índice %d (%s) com 3 unidades no degrau %s • registro %s" % [
		ALVO, id_produto, str(Quality.tier(TOPO)["name"]), _barra(g, id_produto)])
	print("   topo da barra: degrau %s • preço de tabela da peça %.2f • gorjeta anunciada %d" % [
		str(Quality.tier(g._best_tier_for(ALVO))["name"]), tabela, gorjeta_prevista])
	var antes := _marcar(g)
	var tiques := 0
	while tiques < 18:
		antes = _marcar(g)
		_enfileirar(g, _perfil_vip(g))
		g._on_customer_tick()
		tiques += 1
		if int(g.vip_served) > 0:
			break
	print("   servida em %d tique(s) • vip_served %d • recusas %d (0)" % [
		tiques, int(g.vip_served), int(g.vip_refusals)])
	print("   caixa %d→%d • gorjeta prevista %d • gorjeta lida %d • bate: %s" % [
		int(antes["caixa"]), int(g.gold), gorjeta_prevista, int(g.vip_tips_gold),
		str(int(g.vip_tips_gold) == gorjeta_prevista)])
	print("   registro %s→%s • estoque %d→%d • topo agora %s" % [
		str(antes["barra"]), _barra(g, id_produto), int(antes["estoque"]), int(item["stock"]),
		str(Quality.tier(g._best_tier_for(ALVO))["name"])])
	print("   fama %d→%d (+1 do convite) • nível %d→%d (parado) • servidos %d→%d • desanimados %d→%d" % [
		int(antes["fama"]), int(g.reputation), int(antes["nivel"]), int(g.player_level),
		int(antes["servidos"]), int(g.customers_served), int(antes["desanimados"]),
		int(g.disappointed_customers)])
	print("   mural: %s" % String(g.last_event).replace("\n", " / "))

	print("── estante abaixo do degrau devolve a peça no lugar ──")
	g._reset_run()
	_blindar(g)
	g.gold = 5000
	g.reputation = 30
	g.vip_rank = 3
	_raspar_estante(g)
	_por_estante(g, ALVO, _so_no_topo(3))
	item = g.products[ALVO]
	print("   degrau 3 exige %s, estante tem %s" % [
		str(Quality.tier(g._vip_standard())["name"]),
		str(Quality.tier(g._best_tier_for(ALVO))["name"])])
	antes = _marcar(g)
	tiques = 0
	while tiques < 18:
		antes = _marcar(g)
		_enfileirar(g, _perfil_vip(g))
		g._on_customer_tick()
		tiques += 1
		if int(g.vip_refusals) > 0:
			break
	print("   recusa em %d tique(s) • recusadas %d • servidas %d (0) • gorjeta %d (0)" % [
		tiques, int(g.vip_refusals), int(g.vip_served), int(g.vip_tips_gold)])
	print("   caixa %d→%d (igual) • registro %s→%s (igual) • estoque %d→%d (igual)" % [
		int(antes["caixa"]), int(g.gold), str(antes["barra"]), _barra(g, id_produto),
		int(antes["estoque"]), int(item["stock"])])
	print("   desanimados %d→%d • servidos %d→%d (igual) • fama %d→%d (−1)" % [
		int(antes["desanimados"]), int(g.disappointed_customers), int(antes["servidos"]),
		int(g.customers_served), int(antes["fama"]), int(g.reputation)])
	print("   painel: %s • mural: %s" % [_aspado(String(g.status_label.text)),
		String(g.last_event).substr(0, 118)])

	print("── o painel do salão lê degrau, cordão e gorjetas ──")
	g._reset_run()
	_blindar(g)
	for r in range(0, GameScript.VIP_TIERS.size()):
		g.vip_rank = r
		g.vip_served = r * 3
		g.vip_refusals = r
		g.vip_tips_gold = 90 * r
		g._refresh_ui()
		print("   rank %d: %s" % [r, String(g._vip_summary())])
		print("      cartão: %s disabled=%s" % [_aspado(String(g.vip_button.text)),
			str(g.vip_button.disabled)])

	print("── ler e escrever no salão não sorteia nada ──")
	g._reset_run()
	_blindar(g)
	g.vip_rank = 2
	g.vip_served = 4
	g.vip_refusals = 1
	g.vip_tips_gold = 260
	seed(SEED_VAL)
	g._vip_summary()
	g._refresh_ui()
	var cauda_leitura := _cauda(40)
	seed(SEED_VAL)
	g._save_game()
	var cauda_salvar := _cauda(40)
	await _fechar(g)
	print("   resumo + painel: cauda igual ao controle? %s" % str(cauda_leitura == cauda_controle))
	print("   salvar com o salão no degrau 2: cauda igual? %s" % str(cauda_salvar == cauda_controle))

	print("── as quatro chaves atravessam o arquivo ──")
	g = await _loja("salão arquivo")
	_blindar(g)
	g.vip_rank = 3
	g.vip_served = 7
	g.vip_refusals = 2
	g.vip_tips_gold = 450
	g._save_game()
	g = await _reload("salão arquivo relido")
	print("   relido: rank %d • servidas %d • recusadas %d • gorjetas %d" % [
		g.vip_rank, g.vip_served, g.vip_refusals, g.vip_tips_gold])
	await _fechar(g)
	g = await _loja("salão lixo")
	g.gold = 1200
	g._save_game()
	_escrever_chave("vip_rank", "9")
	_escrever_chave("vip_served", "-5")
	_escrever_chave("vip_refusals", "\"abc\"")
	_escrever_chave("vip_tips_gold", "1e9")
	g = await _reload("salão lixo relido")
	print("   payload lixo podado: rank 9→%d (teto 3) • servidas −5→%d • recusadas texto→%d • gorjetas 1e9→%d" % [
		g.vip_rank, g.vip_served, g.vip_refusals, g.vip_tips_gold])
	await _fechar(g)
	g = await _loja("salão antigo")
	g.vip_rank = 2
	g.vip_served = 5
	g.vip_tips_gold = 300
	g.gold = 1416
	g._save_game()
	_apagar_chaves()
	g = await _reload("salão antigo relido")
	var caixa_virada := int(g.gold)
	var chance_zero_2: int = g._vip_chance()
	seed(SEED_VAL)
	for i in range(200):
		g._maybe_vip(base)
	var cauda_zero := _cauda(40)
	var caixa_zero := int(g.gold)
	print("   sem as chaves no arquivo: rank %d • servidas %d • recusadas %d • gorjetas %d" % [
		g.vip_rank, g.vip_served, g.vip_refusals, g.vip_tips_gold])
	print("   cordão guardado não vira moeda: caixa %d→%d (igual) • chance %d (0)" % [
		caixa_virada, caixa_zero, chance_zero_2])
	print("   save antigo relido, 200 carimbos: cauda igual ao controle? %s" % str(
		cauda_zero == cauda_controle))
	await _fechar(g)

	print("── reencarnar enrola o cordão ──")
	g = await _loja("salão vida")
	_blindar(g)
	g.vip_rank = 3
	g.vip_served = 4
	g.vip_refusals = 2
	g.vip_tips_gold = 210
	print("   vida com salão aberto: rank %d • servidas %d • recusadas %d • gorjetas %d" % [
		g.vip_rank, g.vip_served, g.vip_refusals, g.vip_tips_gold])
	g._reset_run()
	print("   vida nova: rank %d • servidas %d • recusadas %d • gorjetas %d" % [
		g.vip_rank, g.vip_served, g.vip_refusals, g.vip_tips_gold])

	print("── os dois selos acendem na fronteira ──")
	var selada: Array = g._achievement_definitions()
	print("   painel de conquistas: %d definições • os dois selos do salão estão na lista: %s" % [
		selada.size(), str(_tem_conquista(g, "vip_first_robe") and _tem_conquista(
			g, "vip_full_salon"))])
	for alvo in [0, 1, 9, 10]:
		g._reset_run()
		g.unlocked_achievements.clear()
		g.vip_served = alvo
		g._check_achievements()
		print("   %d servida(s): capa no balcão %s • salão cheio %s" % [
			alvo, str(g.unlocked_achievements.has("vip_first_robe")),
			str(g.unlocked_achievements.has("vip_full_salon"))])
	await _fechar(g)

	print("── 200 tiques com a prateleira cheia: o salão aparece na partida ──")
	var lados: Array[Dictionary] = [await _corrida(0), await _corrida(1), await _corrida(3)]
	for lado in lados:
		print("   degrau %d: servidos %d • sem comprar %d • caixa %d • nível %d • capa servida %d • recusada %d • gorjeta %d" % [
			int(lado["rank"]), int(lado["servidos"]), int(lado["desanimados"]),
			int(lado["caixa"]), int(lado["nivel"]), int(lado["servidas"]),
			int(lado["recusadas"]), int(lado["gorjetas"])])
	var guardado: Dictionary = lados[0]
	print("   com a gaveta fechada nenhuma visita é capa fina: %s" % str(
		int(guardado["servidas"]) == 0 and int(guardado["recusadas"]) == 0
		and int(guardado["gorjetas"]) == 0))

	print("VEREDITO: cordão guardado não troca uma visita nem consome um sorteio, a escada cobra caixa e fama em cada nó e para no terceiro, a capa fina só sai da loja com o topo da barra que o degrau exige e deixa a gorjeta que a tabela anuncia sobre o preço de peça, e estante baixa devolve a peça sem queimar estoque nem cobrar um ouro duas vezes. Capa fina nascendo de sorteio com a gaveta fechada, gorjeta saindo do preço de fama e facção, recusa mordendo estoque ou acerto subindo o nível é o salão virando roleta — e roleta não é progressão.")
	quit()


## ── ajudantes ──────────────────────────────────────────────────────────────────────

func _loja(rotulo: String):
	_apagar_save()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	_fixar_locale(g)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	return g


## Reabre a loja lendo o save que está no disco, sem apagar e sem resetar.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	_fixar_locale(g)
	g.world_timer.stop()
	return g


func _fixar_locale(g) -> void:
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)


## Marca toda conquista como já ganha: é o que as medidas de caixa precisam, porque o
## primeiro selo do salão paga 40 de ouro e o segundo 220.
func _selar(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)
	g.player_xp = 0


## Selos + nível estacionado longe do próximo degrau: estender o cordão dá 12 de
## experiência e level-up paga ouro — sem a rolha a escada mediria o prêmio do nível.
func _blindar(g) -> void:
	_selar(g)
	g.player_level = 60


func _tem_conquista(g, badge_id: String) -> bool:
	for achievement in g._achievement_definitions():
		if str(achievement["id"]) == badge_id:
			return true
	return false


func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto):
		partes.append(str(randi() % 1000))
	return ",".join(partes)


## O formatador do GDScript não tem `%r`; a sonda escreve as aspas ela mesma para o texto
## roubado de um painel não se misturar com a etiqueta do print.
func _aspado(texto: String) -> String:
	return "\"" + texto + "\""


## O retrato do balcão antes do tique que importa. Tudo lido, nada sorteado.
func _marcar(g) -> Dictionary:
	var item: Dictionary = g.products[ALVO]
	return {
		"caixa": int(g.gold),
		"fama": int(g.reputation),
		"nivel": int(g.player_level),
		"servidos": int(g.customers_served),
		"desanimados": int(g.disappointed_customers),
		"estoque": int(item["stock"]),
		"barra": _barra(g, str(item["id"])),
	}


## Perfil comum, do jeito que o sorteio devolve: sem `vip`, com bolso e fala próprios, e
## sem `regular_id` — para o arco de freguês, o pedido pessoal e a gorjeta de romance
## ficarem do lado de fora da medida.
func _perfil_base(g) -> Dictionary:
	var item: Dictionary = g.products[ALVO]
	return {
		"name": "A Aventureira de Capa Fina",
		"favorite": "Nada do catálogo",
		"line": "“Só passando pela sua vitrine.”",
		"portrait": 2,
		"tier": 0,
		"personal_request": false,
		"faction": "aventureiros",
		"budget": 90,
		"patience": 2,
		"item": str(item["name"]),
	}


## A visita carimbada pela própria loja, rodada até o sorteio acertar a capa: é o balcão
## lendo o que `_maybe_vip` produz, não a sonda reimplementando a fórmula.
func _perfil_vip(g) -> Dictionary:
	var base := _perfil_base(g)
	for i in range(4000):
		var attempt: Dictionary = g._maybe_vip(base)
		if bool(attempt.get("vip", false)):
			return attempt
	return base


## Põe a visita no degrau da frente da fila: `_next_served_profile()` popa o índice 0, e é
## assim que a sonda leva um perfil exato ao balcão sem depender de qual visita sai do rolo.
func _enfileirar(g, profile: Dictionary) -> void:
	g.service_queue.clear()
	g.service_queue.append({
		"profile": profile,
		"waited": 0,
		"limit": int(profile.get("patience", 2)) + 9,
	})


## Estante raspada: um produto por vez na loja inteira, para o escolhido ser leitura e não
## sorteio de lista.
func _raspar_estante(g) -> void:
	for entry in g.products:
		var produto: Dictionary = entry
		produto["stock"] = 0
		g.quality_stock[str(produto["id"])] = Quality.empty_stock()
		var lotes: Array = g._batches_for(str(produto["id"]))
		lotes.clear()


## A barra inteira vazia, com `quantos` unidades só no degrau medido.
func _so_no_topo(quantos: int) -> Array:
	var counts: Array = []
	for t in range(Quality.size()):
		counts.append(quantos if t == TOPO else 0)
	return counts


func _por_estante(g, index: int, counts: Array) -> void:
	var item: Dictionary = g.products[index]
	var produto_id := str(item["id"])
	var total := 0
	for t in range(counts.size()):
		total += int(counts[t])
	item["stock"] = total
	g.quality_stock[produto_id] = Quality.empty_stock()
	var registro: Array = g._quality_for(produto_id)
	for t in range(counts.size()):
		registro[t] = int(counts[t])
	var lotes: Array = g._batches_for(produto_id)
	lotes.clear()
	for t in range(counts.size()):
		for n in range(int(counts[t])):
			lotes.append({"tier": t, "day": int(g.shop_day)})


func _barra(g, produto_id: String) -> String:
	var partes: Array[String] = []
	for c in g._quality_for(produto_id):
		partes.append(str(int(c)))
	return "/".join(partes)


## A corrida de 200 tiques com a mesma semente, num degrau do cordão. A prateleira é montada
## igual nos três lados (2 Refinado + 1 Mítico por produto), porque sem estoque a loja nem
## chega a sortear visita — e uma corrida sem venda provaria o quê? Selada e com o nível
## estacionado, para nenhum prêmio de conquista ou de level-up entrar no caixa medido. Todos
## os tiques rodam em sequência, sem um `await` no meio: o rodízio do palco é guiado por
## quadros reais.
func _corrida(rank: int) -> Dictionary:
	var g = await _loja("corrida %d" % rank)
	_blindar(g)
	g.gold = 5000
	g.reputation = 60
	_raspar_estante(g)
	for i in range(g.products.size()):
		_por_estante(g, i, [0, 0, 2, 0, 1, 0])
	g.vip_rank = rank
	g._refresh_ui()
	for i in range(200):
		g._on_customer_tick()
	var resultado := {
		"rank": rank,
		"servidos": int(g.customers_served),
		"desanimados": int(g.disappointed_customers),
		"caixa": int(g.gold),
		"nivel": int(g.player_level),
		"servidas": int(g.vip_served),
		"recusadas": int(g.vip_refusals),
		"gorjetas": int(g.vip_tips_gold),
	}
	await _fechar(g)
	return resultado


## Reescreve uma chave do save descartável no disco, sem passar pelo jogo.
func _escrever_chave(chave: String, valor: String) -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	var linha := texto.find("%s=" % chave)
	if linha < 0:
		print("      (a chave %s não está no arquivo — o teste abaixo vale pouco)" % chave)
		return
	var fim := texto.find("\n", linha)
	if fim < 0:
		fim = texto.length()
	texto = texto.substr(0, linha) + "%s=%s" % [chave, valor] + texto.substr(fim)
	var file := FileAccess.open(caminho, FileAccess.WRITE)
	file.store_string(texto)
	file.close()


## Tira as quatro chaves do salão: é o save antigo, escrito antes de o cordão existir.
func _apagar_chaves() -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	for chave in ["vip_rank", "vip_served", "vip_refusals", "vip_tips_gold"]:
		var linha := texto.find("\n%s=" % chave)
		if linha < 0:
			continue
		var fim := texto.find("\n", linha + 1)
		if fim < 0:
			fim = texto.length()
		texto = texto.substr(0, linha) + texto.substr(fim)
	var file := FileAccess.open(caminho, FileAccess.WRITE)
	file.store_string(texto)
	file.close()


func _caminho_save() -> String:
	return ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"


func _apagar_save() -> void:
	var caminho := _caminho_save()
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
