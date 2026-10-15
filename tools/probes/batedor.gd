extends SceneTree
## Sonda do cadastro de estrada (#55). Prova três coisas que o painel promete:
## 1) a curva de taxa de sucesso por habilidade e por peça na mochila, medida na
##    fórmula real do contratempo com a sorte da casa zerada — assim o número que
##    aparece é só do batedor;
## 2) quantas viagens cada rota ensina até o teto, e quanto o cachê sobe com elas;
## 3) o caminho completo contratar → partir → voltar em cima do jogo de verdade:
##    ouro descontado, peça saindo do estoque, XP entrando, painel escrevendo a
##    linha certa — e o caminho anônimo intacto para quem nunca contratou ninguém.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 1800 --script res://tools/probes/batedor.gd
##
## Veredito medido nesta rodada: contratempo do beco 8% → 2% já no Nv.1; pântano
## 18% → 2%, catacumba 30% → 2% e fenda 45% → 13% no teto (Nv.5 + peça Lendária).
## Peça extra na mala = sorte × 12% até o teto de 96%, e o caminho anônimo continua
## cobrando só a passagem (25 = 25, painel "batedor anônimo (+0) … 92%"). Uma viagem
## limpa com duas peças ensina 5/6/7/8 XP por rota, o teto chega em 5/5/4/4 carimbos
## e o cachê no topo é tabela + 4. Mochila paga: a Adaga Mítica sai da prateleira
## (2 → 1), soma +2 de sorte e não volta para a loja — a viagem gasta a peça, com
## contratempo ou sem ele. Round-trip do save preserva who/level/skill/gear/gear_name
## e vira anônimo quando o nome sai do cadastro. Se o contratempo da fenda passar de
## 13% no teto, ou se a partida sem cadastro cobrar mais que a passagem, a curva
## mudou de lugar.

const Adventurers = preload("res://adventurers.gd")
const Expedition = preload("res://expedition.gd")
const Quality = preload("res://quality.gd")

const CORVA: Dictionary = {
	"id": "corva", "name": "Corva Sete-Dias", "role": "Batedora de beco",
	"hire": 90, "fee": 4, "base": 1, "route": "beco", "gear": "adaga_charme", "day": 2,
}

func _initialize() -> void:
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	game.world_timer.stop()
	print("=== A. CURVA DE SUCESSO (sorte da casa = 0, só o batedor) ===")
	_curve()
	print("=== B. O QUE A ESTRADA ENSINA (XP e cachê por rota) ===")
	_lessons()
	print("=== C. CAMINHO ANÔNIMO INTACTO ===")
	_anonymous(game)
	print("=== D. CAMINHO COM CADASTRO, MOCHILA E VOLTA ===")
	_with_roster(game)
	print("=== E. O QUE O PAINEL ESCREVE ===")
	_panel(game)
	quit()

## A. Para cada rota, o risco cru da tabela contra o risco com cada mão disponível.
func _curve() -> void:
	for destination in Expedition.DATA:
		var bare := Expedition.mishap_chance(destination, 0)
		var base_chance := int((destination["loot"] as Array)[0]["chance"])
		print("  %s (perigo %d, contratempo cru %d%%, porta da %d%%):" % [
			str(destination["name"]), int(destination["danger"]), bare, base_chance])
		for tier in [-1, 0, 2, 5]:
			for xp in [0, 8, 25]:
				var skill := Adventurers.skill_of(CORVA, xp, str(destination["id"]), tier)
				var risk := Expedition.mishap_chance(destination, skill)
				var extra := clampi(skill * 12, 0, 100)
				print("    XP %2d • peça %-10s → sorte +%2d • contratempo %2d%% • peça extra na mala %3d%%" % [
					xp, _tier_name(tier), skill, risk, extra])

## B. Quantas viagens a pessoa precisa para chegar ao teto, por rota, e o preço.
func _lessons() -> void:
	for destination in Expedition.DATA:
		var xp := 0
		var carimbos: Array[int] = []
		var level := 1
		var trip := 0
		while level < Adventurers.max_level() and trip < 200:
			trip += 1
			xp += Adventurers.mission_xp(destination, true, 2)
			var next := Adventurers.level_of(xp)
			if next > level:
				carimbos.append(trip)
				level = next
		print("  %s: %d XP por viagem limpa com duas peças • degraus nos carimbos %s • Nv.%d • cachê no teto %d" % [
			str(destination["name"]), Adventurers.mission_xp(destination, true, 2),
			str(carimbos), Adventurers.level_of(xp), Adventurers.fee_for(CORVA, xp)])

## C. Sem ninguém no cadastro a loja tem de fazer exatamente o que fazia antes.
func _anonymous(game: Control) -> void:
	game._reset_run()
	game.shop_day = 5
	game.gold = 4000
	game.logistics_rank = 0
	var before := int(game.gold)
	game._start_expedition("beco")
	if game.expeditions.is_empty():
		print("  FALHOU: nenhuma viagem saiu")
		return
	var trip: Dictionary = game.expeditions[0]
	var passage := Expedition.cost_for(Expedition.find("beco"), 0)
	print("  partida anônima: quem='%s' skill=%d gear=%d • cobrado %d (passagem %d) • XP do cadastro: %s" % [
		str(trip.get("who", "<sem campo>")), int(trip.get("skill", 0)), int(trip.get("gear", -1)),
		before - int(game.gold), passage, str(game.adventurer_xp)])
	print("  linha do painel: %s" % game._expedition_trip_summary(trip, 0.0))
	print("  sem cadastro, _pick_adventurer devolve: %s" % str(game._pick_adventurer("beco")))
	game._advance_expeditions(999.0, false)
	print("  voltaram %d mala(s) • XP do cadastro depois da volta: %s" % [
		game.expeditions_done, str(game.adventurer_xp)])

## D. Contratar, armar a mochila, mandar e conferir a volta.
func _with_roster(game: Control) -> void:
	game._reset_run()
	game.shop_day = 3
	game.gold = 4000
	game.logistics_rank = 0
	game.pack_gear = true
	var adaga_index := -1
	for i in range(game.products.size()):
		if str(game.products[i]["id"]) == "adaga_charme":
			adaga_index = i
	if adaga_index < 0:
		print("  FALHOU: adaga_charme não está mais no catálogo")
		return
	game._add_piece(adaga_index, 2)
	game._add_piece(adaga_index, 4)
	var pieces_before := int(game.products[adaga_index]["stock"])
	var candidate := Adventurers.find("corva")
	var gold_in := int(game.gold)
	var badges_in: Array = game.unlocked_achievements.duplicate()
	game._manage_adventurer("corva")
	var payout := 0
	var fresh: Array[String] = []
	for badge in game.unlocked_achievements:
		if not badges_in.has(str(badge)):
			fresh.append(str(badge))
			payout += _badge_gold(game, str(badge))
	print("  contratar: taxa %d • conquistas novas %s pagando %d • ouro %d→%d • cadastro %s" % [
		int(candidate["hire"]), str(fresh), payout, gold_in, int(game.gold), str(game.adventurers_hired)])
	var pack: Dictionary = game._packable_gear(candidate)
	print("  mochila escolhe: %s (%s)" % [str(pack.get("name", "")), _tier_name(int(pack.get("tier", -1)))])
	var trip_gold_in := int(game.gold)
	game._start_expedition("beco")
	if game.expeditions.is_empty():
		print("  FALHOU: com cadastro a viagem não saiu")
		return
	var trip: Dictionary = game.expeditions[game.expeditions.size() - 1]
	var passage := Expedition.cost_for(Expedition.find("beco"), 0)
	var fee := Adventurers.fee_for(candidate, 0)
	print("  partir: cobrado %d = passagem %d + cachê %d • skill congelada %d (base 1 + casa 1 + Mítico 2) • Nv.%d • peça %s" % [
		trip_gold_in - int(game.gold), passage, fee, int(trip["skill"]), int(trip["level"]),
		_tier_name(int(trip["gear"]))])
	print("  na estrada: %s" % game._expedition_trip_summary(trip, 5.0))
	print("  estoque da adaga: %d → %d • mochilas pagas %d" % [
		pieces_before, int(game.products[adaga_index]["stock"]), game.gear_packed])
	print("  ocupado? %s • quem sairia para o pântano agora: %s" % [
		str(game._adventurer_on_road("corva")), str(game._pick_adventurer("pantano").get("id", "ninguém"))])
	game._manage_adventurer("corva")
	print("  dispensa na estrada ainda deixa no cadastro: %s" % str(game.adventurers_hired.has("corva")))
	_roundtrip(game, adaga_index)
	var logs_before := int(game.expedition_log.size())
	game._advance_expeditions(999.0, false)
	var xp := int(game.adventurer_xp.get("corva", 0))
	print("  volta: XP %d • %s • diário %d→%d" % [xp, Adventurers.level_line(xp), logs_before, game.expedition_log.size()])
	print("  diário: %s" % str(game.expedition_log[0]))
	print("  adaga depois da volta: %d (peça de viagem não volta para a prateleira)" % int(game.products[adaga_index]["stock"]))
	print("  cachê no nível atual: %d • livre de novo: %s" % [
		Adventurers.fee_for(candidate, xp), str(game._pick_adventurer("beco").get("id", ""))])
	game._cycle_route_pick("beco")
	print("  roteiro anotado: %s • %s" % [str(game.route_pick.get("beco", "")), game.last_event])
	print("  gate da Marola (rep 40): %s" % Adventurers.gate(Adventurers.find("marola"), game._adventurer_gate_state()))
	print("  gate do Nabo (6 malas): %s" % Adventurers.gate(Adventurers.find("nabo"), game._adventurer_gate_state()))
	print("  gate do Bilesca (logística 2): %s" % Adventurers.gate(Adventurers.find("bilesca"), game._adventurer_gate_state()))

## F. O que o save escreve e o que o carregamento devolve: viagem em andamento sem
## nome, nível e peça na mala voltaria como anônima, e o XP do cadastro viraria pó.
func _roundtrip(game: Control, adaga_index: int) -> void:
	var config := ConfigFile.new()
	var err := config.load(ProjectSettings.globalize_path("user://succubus_shop_save.cfg"))
	var saved_trips = config.get_value("game", "expeditions", [])
	print("  save lido (erro %d): %s" % [err, str(saved_trips)])
	print("  chaves: hired=%s • xp=%s • pick=%s • mochila=%s • peças %s" % [
		str(config.get_value("game", "adventurers_hired", [])), str(config.get_value("game", "adventurer_xp", {})),
		str(config.get_value("game", "route_pick", {})), str(config.get_value("game", "pack_gear", null)),
		str(config.get_value("game", "gear_packed", -1))])
	var adaga_in_file = (config.get_value("game", "products", []) as Array)
	var stock_in_file := -1
	for saved_item in adaga_in_file:
		if str(saved_item.get("name", "")) == str(game.products[adaga_index]["name"]):
			stock_in_file = int(saved_item.get("stock", -1))
	print("  adaga no arquivo: %d (em memória %d)" % [stock_in_file, int(game.products[adaga_index]["stock"])])
	game.expeditions.clear()
	game._read_expeditions(saved_trips)
	if game.expeditions.is_empty():
		print("  FALHOU: reidratação não devolveu a viagem")
		return
	var back: Dictionary = game.expeditions[0]
	print("  reidratado: quem=%s Nv.%d skill=%d peça=%s (%s)" % [
		str(back.get("who", "")), int(back.get("level", 0)), int(back.get("skill", -1)),
		int(back.get("gear", -9)), str(back.get("gear_name", ""))])
	print("  painel reidratado: %s" % game._expedition_trip_summary(back, 0.0))
	## Nome raspado da tabela não pode continuar viajando com sorte emprestada.
	var orphan := [{"id": "beco", "remaining": 10.0, "total": 10.0, "who": "fantasma", "skill": 9, "level": 5, "gear": 5}]
	game._read_expeditions(orphan)
	print("  órfão virou anônimo: %s" % str(game.expeditions[0]))
	## E a viagem de verdade volta para a sala, porque o resto da sonda depende dela.
	game._read_expeditions(saved_trips)

## Ouro que uma conquista paga, lido da tabela do próprio jogo: sem esse detalhe o
## delta de ouro do contrato sai negativo e parece um bug de cobrança.
func _badge_gold(game: Control, badge_id: String) -> int:
	for achievement in game._achievement_definitions():
		if str(achievement["id"]) == badge_id:
			return int(achievement["gold"])
	return 0

## E. O que o jogador lê, nas strings reais dos controles.
func _panel(game: Control) -> void:
	game._set_sector("expedition")
	game._refresh_ui()
	print("  resumo do cadastro: %s" % game.adventurer_summary_label.text)
	print("  mochila: %s" % game.pack_gear_button.text)
	for e in range(game.expedition_labels.size()):
		print("  roteiro %d [%s]: %s" % [e, str(Expedition.DATA[e]["id"]), str(game.expedition_labels[e].text)])
		print("      botão: %s (disabled=%s) • %s" % [
			str(game.expedition_buttons[e].text), str(game.expedition_buttons[e].disabled),
			str(game.expedition_pick_buttons[e].text)])
	for b in range(game.adventurer_labels.size()):
		print("  cadastro %d: %s" % [b, str((game.adventurer_labels[b] as Label).text)])
		print("      botão: %s" % str(game.adventurer_buttons[b].text))
	print("  placar da casa com o cadastro: %d" % game.business_score())

func _tier_name(tier: int) -> String:
	return "sem peça" if tier < 0 else str(Quality.tier(tier)["name"])

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
