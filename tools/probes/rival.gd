extends SceneTree

## Sonda da concorrência: prova que a placa do vizinho cobra de verdade. Três rivais
## acendem a placa em dias fixos do calendário da loja e, enquanto estão na praça,
## tiram corpo da porta (antes do clamp, então a loja nunca fecha) e dinheiro do bolso
## de quem entra — as duas contas medidas aqui com a loja parada, sem sorteio no meio.
## Confere que o tempo da rua modula o estrago (feira dobra, chuva/névoa/tempestade
## cortam pela metade), que a fama de bairro segura metade, que comprar a placa fecha o
## rombo de uma vez e sobe peça real na prateleira (estoque e contagem de qualidade,
## não só o número do painel), que o preço da espera encarece a cada virada, que as três
## recusas dizem o motivo sem tocar no caixa, que as duas conquistas acendem, que o save
## carrega a praça e descarta placa inexistente, e que reencarnar devolve as rivais para
## a rua. Fecha com duzentos tiques de loja rodados duas vezes sob a mesma semente:
## concorrência é aritmética, não mais um dado no rolo.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/rival.gd
##
## Veredito medido nesta rodada: placas acendem nos dias 4 / 13 / 27 e o balanço da
## manhã entrega o aviso (a fala vive em `day_report`; `last_event` é do primeiro
## cliente do mesmo tique). Porta, fama 20, dia limpo: 1 placa −1, 2 −2, 3 −4 de corpo
## (o clamp deixa 1 de pé, a loja nunca fecha por fora); feira dobra a conta e chuva
## corta pela metade. Com fama 55 a praça toda cobra −2 em vez de −4. Bolso: 42 → 10,
## 110 → 52, 210 → 152 com três placas (corte 58); com fama 55 o corte é 29 e 42 → 13;
## o item de 12 ouro só volta a ser vendável com fama acima de 50 ou placa comprada.
## Compra: caixa cobra o preço da tabela (627 líquido na Botica, porque uma conquista
## pagou +80 no caminho — as duas rivais ficam pré-destravadas nesta seção), fama +3/+5/+8
## da rival, prateleira 0 → 3 / 0 → 2 / 0 → 1 peças honestas na contagem de qualidade,
## e a perda de porta cai 4 → 3 → 2 → 0 com o bolso voltando a 58 → 48 → 30 → 0. Espera
## encarece: 520 no dia em que acende, 707 no dia 40 (+36%). As três recusas (antes do
## dia, sem caixa, já sua) não tocaram no caixa (9000 / 100 / 8630 com a segunda batida
## cobrando 0). Conquistas *Placa desligada* e *A praça é sua* acendem, placar +1110 com
## o caixa devolvido. Save: ["botica","vitrine"] atravessam e a placa falsa
## "quiosque_da_lua" é descartada sem quebrar o carregamento; quem restou na rua segue
## cobrando −1 de porta e −18 de bolso. Reencarnar zerou a lista e a mesma praça reabre
## com 3 placas contra a casa nova. Duzentos tiques em duas lojas irmãs fecharam idênticas
## (caixa 755 • fama 0 • 5 atendidos • 174 decepções • placar 1024): concorrência não é
## dado novo no rolo.

const SEED_VAL := 20261015
const Rivals = preload("res://rivals.gd")
const TICKS := 200
const TODAS: Array = ["botica", "alambique", "vitrine"]

func _initialize() -> void:
	print("── a placa acende no dia combinado ──")
	var dias: Array[String] = []
	for dia in [1, 3, 4, 12, 13, 26, 27, 40]:
		dias.append("dia %d: %d" % [int(dia), Rivals.active_ids(int(dia), []).size()])
	print("   placas acesas por dia de loja -> %s" % " • ".join(dias))
	for rival in Rivals.DATA:
		print("      %s: acende no dia %d • porta −%d • bolso −%d • placa %d • dá %s" % [
			str(rival["name"]), int(rival["day"]), int(rival["crowd"]), int(rival["undercut"]),
			int(rival["cost"]), str(rival["gain"]["product"])])

	print("── a virada avisa antes de a rua esvaziar ──")
	var loja = await _loja("virada", false)
	var manha := ""
	var painel := ""
	for i in range(200):
		var antes: int = loja.shop_day
		loja._on_customer_tick()
		if loja.shop_day > antes and loja.shop_day >= 4:
			# O mural que importa aqui é o balanço da manhã: no mesmo tique o primeiro
			# cliente já escreveu a própria fala em last_event.
			manha = str(loja.day_report)
			loja._refresh_ui()
			painel = str(loja.rival_summary_label.text)
			break
	print("   dia %d • balanço da manhã traz a placa? %s" % [loja.shop_day, "sim" if manha.contains("Botica") else "NÃO"])
	print("   manhã: %s" % manha.replace("\n", " ⏐ ").substr(0, 190))
	print("   painel: %s" % painel)
	await _fechar(loja)

	print("── o que a placa cobra na porta ──")
	loja = await _loja("porta", false)
	loja.branches.clear()
	loja.shop_day = 27
	for rep in [20, 55]:
		loja.reputation = int(rep)
		var partes: Array[String] = []
		for tempo in ["limpo", "chuva", "feirao"]:
			loja.weather = str(tempo)
			_absorvidas(loja, [])
			var com_placas: int = loja._arrivals_this_tick()
			_absorvidas(loja, TODAS)
			var sem_placas: int = loja._arrivals_this_tick()
			partes.append("%s %d -> %d (−%d)" % [str(tempo), sem_placas, com_placas, sem_placas - com_placas])
		print("   dia 27, três placas • fama %d: %s" % [int(rep), " • ".join(partes)])
	print("   a conta cresce com a praça cheia — placa por placa, fama 20, dia limpo")
	loja.reputation = 20
	loja.weather = "limpo"
	for ativas in range(1, 4):
		_absorvidas(loja, TODAS.slice(ativas, TODAS.size()))
		print("      %d placa(s) na rua: porta −%d • bolso −%d" % [
			ativas, loja._rival_crowd_loss(), loja._rival_undercut()])
	await _fechar(loja)

	print("── o que a placa cobra do bolso ──")
	loja = await _loja("bolso", false)
	loja.shop_day = 27
	loja.trade_rank = 0
	var pobre := {"budget": 42}
	var medio := {"budget": 110}
	var rico := {"budget": 210}
	_absorvidas(loja, TODAS)
	var sem_placa: Array = [_bolso(loja, pobre), _bolso(loja, medio), _bolso(loja, rico)]
	_absorvidas(loja, [])
	loja.reputation = 20
	var com_placa: Array = [_bolso(loja, pobre), _bolso(loja, medio), _bolso(loja, rico)]
	var corte_20: int = loja._rival_undercut()
	loja.reputation = 55
	var com_fama: Array = [_bolso(loja, pobre), _bolso(loja, medio), _bolso(loja, rico)]
	var corte_55: int = loja._rival_undercut()
	loja.reputation = 0
	var fundo := _bolso(loja, {"budget": 12})
	print("   praça sem placa  : 42 -> %d • 110 -> %d • 210 -> %d" % sem_placa)
	print("   três placas, fama 20: 42 -> %d • 110 -> %d • 210 -> %d (corte de %d)" % [
		com_placa[0], com_placa[1], com_placa[2], corte_20])
	print("   três placas, fama 55: 42 -> %d • 110 -> %d • 210 -> %d (corte de %d)" % [
		com_fama[0], com_fama[1], com_fama[2], corte_55])
	print("   o pobre sem fama: bolso de 12 com corte de %d chega com %d — o item de 12 ouro só volta a vender quando a fama passa de %d ou a placa é comprada" % [
		corte_20, fundo, Rivals.FAME_HOLD])
	await _fechar(loja)

	print("── comprar a placa fecha o rombo e enche a prateleira ──")
	loja = await _loja("compra", false)
	loja.shop_day = 40
	loja.gold = 9000
	# As duas conquistas da praça ficam pré-destravadas aqui: esta seção mede o preço
	# e a peça, e o payout da conquista é medido à parte na seção seguinte.
	loja.unlocked_achievements.append("rival_first")
	loja.unlocked_achievements.append("rival_all")
	loja._check_achievements()
	for rival in Rivals.DATA:
		var id := str(rival["id"])
		var index := int(loja._product_index(str(rival["gain"]["product"])))
		var ouro_antes: int = loja.gold
		var fama_antes: int = loja.reputation
		var peca_antes: int = int(loja.products[index]["stock"])
		var honesto_antes: int = _honestos(loja, _id_of(loja, index))
		var perda_antes: int = loja._rival_crowd_loss()
		var bolso_antes: int = loja._rival_undercut()
		loja._absorb_rival(id)
		print("   %s: caixa −%d (tabela %d) • fama +%d • prateleira %d -> %d • honestos %d -> %d • perda de porta %d -> %d • bolso %d -> %d" % [
			str(rival["name"]), ouro_antes - loja.gold, Rivals.price_for(rival, 40),
			loja.reputation - fama_antes, peca_antes, int(loja.products[index]["stock"]),
			honesto_antes, _honestos(loja, _id_of(loja, index)),
			perda_antes, loja._rival_crowd_loss(), bolso_antes, loja._rival_undercut()])
	_absorvidas(loja, TODAS)
	print("   praça toda comprada: porta −%d • bolso −%d" % [loja._rival_crowd_loss(), loja._rival_undercut()])
	print("   preço da espera: %s custa %d no dia em que acende e %d no dia 40 (+%.1f%% por 36 viradas)" % [
		str(Rivals.DATA[0]["name"]), int(Rivals.DATA[0]["cost"]), Rivals.price_for(Rivals.DATA[0], 40),
		(float(Rivals.price_for(Rivals.DATA[0], 40)) / float(Rivals.price_for(Rivals.DATA[0], int(Rivals.DATA[0]["day"]))) - 1.0) * 100.0])
	await _fechar(loja)

	print("── as três recusas não tocam no caixa ──")
	loja = await _loja("recusas", false)
	loja.shop_day = 1
	loja.gold = 9000
	_absorvidas(loja, [])
	loja._absorb_rival("botica")
	print("   antes de acender: %s • caixa %d" % [str(loja.last_event).substr(0, 76), loja.gold])
	loja.shop_day = 4
	loja.gold = 100
	loja._absorb_rival("botica")
	print("   sem caixa: %s • caixa %d" % [str(loja.last_event).substr(0, 76), loja.gold])
	loja.gold = 9000
	loja._absorb_rival("botica")
	var caixa_depois: int = loja.gold
	loja._absorb_rival("botica")
	print("   já é sua: %s • caixa %d (segunda batida tirou %d)" % [
		str(loja.last_event).substr(0, 68), loja.gold, caixa_depois - loja.gold])
	await _fechar(loja)

	print("── as duas conquistas da praça ──")
	loja = await _loja("conquista", false)
	loja.shop_day = 40
	loja.gold = 9000
	_absorvidas(loja, [])
	loja._check_achievements()
	var antes_1: int = loja.unlocked_achievements.size()
	var caixa_antes: int = loja.gold
	var placar_antes: int = loja.business_score()
	loja._absorb_rival("botica")
	var primeira: bool = loja.unlocked_achievements.has("rival_first")
	loja.gold = 9000
	loja._absorb_rival("alambique")
	loja.gold = 9000
	loja._absorb_rival("vitrine")
	loja.gold = caixa_antes
	print("   conquistas %d -> %d • primeira: %s • praça toda: %s" % [
		antes_1, loja.unlocked_achievements.size(), str(primeira),
		str(loja.unlocked_achievements.has("rival_all"))])
	print("   placar com o caixa devolvido: %d -> %d (+%d: 70 por placa mais a fama paga)" % [
		placar_antes, loja.business_score(), loja.business_score() - placar_antes])
	await _fechar(loja)

	print("── o save carrega a praça, e placa falsa não derruba o balcão ──")
	loja = await _loja("save", false)
	loja.shop_day = 40
	loja.gold = 9000
	_absorvidas(loja, [])
	loja._absorb_rival("botica")
	loja._absorb_rival("vitrine")
	loja._save_game()
	var leitura = await _reload("reload")
	print("   lidas: %s • placa que restou na rua cobra porta −%d e bolso −%d" % [
		str(leitura.rivals_absorbed), leitura._rival_crowd_loss(), leitura._rival_undercut()])
	await _fechar(leitura)
	_gravar_placa_falsa()
	var quebrado = await _reload("reload quebrado")
	print("   placa inexistente no arquivo acorda: %s (esperado: só as duas reais)" % str(quebrado.rivals_absorbed))
	await _fechar(quebrado)
	await _fechar(loja)

	print("── reencarnar devolve as rivais para a rua ──")
	loja = await _loja("vida", false)
	loja.shop_day = 40
	loja.gold = 9000
	_absorvidas(loja, [])
	loja._absorb_rival("botica")
	var antes_2: int = loja.rivals_absorbed.size()
	loja._reset_run()
	print("   absorvidas antes %d • vida nova %d • dia %d com %d placa(s) acesa(s)" % [
		antes_2, loja.rivals_absorbed.size(), loja.shop_day, loja._rivals_active_ids().size()])
	loja.shop_day = 40
	print("   a mesma praça reabre contra a casa nova: %d placa(s)" % loja._rivals_active_ids().size())
	await _fechar(loja)

	print("── duzentos tiques sob a mesma semente ──")
	var irma_a = await _loja("irma A", false)
	for i in range(TICKS):
		irma_a._on_customer_tick()
	var contas_a := _contas(irma_a)
	await _fechar(irma_a)
	var irma_b = await _loja("irma B", false)
	for i in range(TICKS):
		irma_b._on_customer_tick()
	var contas_b := _contas(irma_b)
	await _fechar(irma_b)
	print("   %s" % contas_a)
	print("   %s -> %s" % [contas_b, "idem" if contas_a == contas_b else "DIVERGE: concorrência virou dado"])

	print("VEREDITO: placa que não cobra porta e bolso é enfeite; compra que não devolve caixa, fama e peça é botão de ouro. Divergência entre irmãs é sorteio escondido na concorrência.")
	quit()


## Conta fechada dos dois lados do A/B: se a concorrência não sorteia nada, as duas
## strings iguais são a prova de que a mesma semente desenha a mesma loja.
func _contas(loja) -> String:
	return "caixa %d • fama %d • atendidos %d • decepções %d • dia %d • porta %d • bolso −%d • placar %d" % [
		loja.gold, loja.reputation, loja.customers_served, loja.disappointed_customers,
		loja.shop_day, loja._arrivals_this_tick(), loja._rival_undercut(), loja.business_score()]


func _bolso(loja, perfil: Dictionary) -> int:
	return int(loja._visit_budget(perfil))


func _honestos(loja, produto_id: String) -> int:
	var conta: Array = loja.quality_stock.get(produto_id, [])
	return int(conta[1]) if conta.size() > 1 else 0


func _id_of(loja, index: int) -> String:
	return str(loja.products[index]["id"])


## A lista de absorvidas é Array[String] no jogo: entra uma a uma, nunca de uma vez.
func _absorvidas(loja, ids: Array) -> void:
	loja.rivals_absorbed.clear()
	for id in ids:
		loja.rivals_absorbed.append(str(id))


## Loja recém-instalada com o save descartável apagado, relógio do mundo parado,
## semente cravada e vida resetada.
func _loja(rotulo: String, ligado: bool):
	_apagar_save()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	g.adult_content_enabled = ligado
	return g


## Reabre a loja lendo o save que está no disco, sem apagar e sem resetar.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	return g


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


## Escreve uma placa que não existe na tabela no save descartável, para conferir a
## volta por cima do carregamento.
func _gravar_placa_falsa() -> void:
	var config := ConfigFile.new()
	if config.load("user://succubus_shop_save.cfg") != OK:
		print("      (não deu para abrir o save descartável)")
		return
	config.set_value("game", "rivals_absorbed", ["botica", "quiosque_da_lua", "vitrine"])
	config.save("user://succubus_shop_save.cfg")


func _apagar_save() -> void:
	var caminho: String = ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
