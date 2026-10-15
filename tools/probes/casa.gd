extends SceneTree

## Sonda da conserva: prova que barro no chão cobra nas duas contas que o jogo já
## tinha (tique de fila e ponto de etiqueta), que existe mais de uma mão para
## tirá-lo (balde em ouro, criada na folha, servo por afeto), que o vândalo vem na
## proporção do que a casa mostra por fora, e que a cela do santuário é decisão de
## verdade — sangue na forja de um lado, prato na conta do outro, e três destinos
## diferentes para o mesmo preso. Confere também o banido que nunca mais é sorteado
## e o round-trip do save, porque cela que não atravessa o carregamento é decoração.

##
## Uso: godot --headless --path . --quit-after 1800 --script res://tools/probes/casa.gd

const OUT := "D:/Downloads/tmp-userdata/"

var _game

func _initialize() -> void:
	_game = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(_game)
	await _frames(3)
	var game = _game
	game.world_timer.stop()

	print("── o barro cobra nas contas que já existiam ──")
	_limpa()
	var perfil := {"patience": 2}
	var base_wait: int = game._queue_patience(perfil)
	var base_tag: float = game._mess_price_multiplier()
	for level in [0, 33, 34, 68, 100]:
		game.mess = level
		print("   %3d de barro: fila %+d tique (%d -> %d) • etiqueta x%.3f (%+.1f%%)" % [
			level,
			game._queue_patience(perfil) - base_wait,
			base_wait, game._queue_patience(perfil),
			game._mess_price_multiplier(),
			(game._mess_price_multiplier() - base_tag) * 100.0
		])
	# O castigo tem teto: barro nenhum tira mais que dois tiques de um freguês.
	game.mess = game.MESS_LIMIT
	print("   teto do castigo: fila %+d tique com salão no máximo (esperado -2)" % [
		game._queue_patience(perfil) - base_wait
	])

	print("── quem tira o pé do chão ──")
	_limpa()
	game.mess = 80
	var mop: int = game._mop_cost()
	game.gold = mop - 1
	game._sweep_floor()
	print("   sem caixa (%d de %d): salão %d, vassouras %d (esperado intocado)" % [
		game.gold, mop, game.mess, game.sweeps_done])
	game.gold = 500
	game._sweep_floor()
	print("   com caixa: balde %d -> salão %d, vassouras %d, ouro %d (esperado 500-%d=0 saldo limpo)" % [
		mop, game.mess, game.sweeps_done, game.gold, mop])
	# Preço do balde é da casa, não da marcha de quem administra.
	game.house_rank = 5
	print("   Administração 5 marchas não muda o balde: %d (era %d)" % [game._mop_cost(), mop])
	game.house_rank = 0
	game.branches.append(str(game.Branches.DATA[0]["id"]))
	game.library_upgrade_level = 2
	game.sanctum_upgrade_level = 2
	print("   casa grande cobra mais chão: balde %d (%d filial + 4 reformas)" % [game._mop_cost(), 1])

	_limpa()
	game.mess = 80
	var maid_line: String = ""
	game.staff_hired.append("createda")
	maid_line = game._clean_house_turn()
	print("   criada na folha:%s" % maid_line)
	game.staff_hired.clear()
	game.mess = 80
	game.servants.append(str(game.Regulars.DATA[0]["id"]))
	game.servants.append(str(game.Regulars.DATA[1]["id"]))
	print("   dois servos por afeto:%s (salão %d)" % [game._clean_house_turn(), game.mess])

	print("── o vândalo vem na proporção do que a casa mostra ──")
	_limpa()
	for case in [[0, 30], [20, 30], [50, 30], [80, 30], [100, 30], [100, 0], [100, 4]]:
		game.mess = case[0]
		game.reputation = case[1]
		print("   %3d de barro e %2d de fama -> %d%% de visita indesejada" % [
			case[0], case[1], game._vandal_chance()])

	print("── sem cela, a guilda leva; com cela, a casa guarda ──")
	_limpa()
	game.sanctum_upgrade_level = 0
	game.staff_hired.append("ronda")
	game.gold = 100
	game.reputation = 30
	game.mess = 0
	var before_guild: int = game.gold
	game._catch_culprit("Rufino Meia-Noite", "")
	print("   santuário Nv.0: presos=%d, ouro %+d, fama %+d (esperado: entregue à guilda)" % [
		game.prisoners.size(), game.gold - before_guild, game.reputation - 30])
	game.sanctum_upgrade_level = 2
	game._catch_culprit("Boca-Salgada Vera", "")
	print("   santuário Nv.2: presos=%d de %d (esperado 1 de 2)" % [
		game.prisoners.size(), game._cell_capacity()])

	print("── a cela rende sangue e cobra prato ──")
	_limpa()
	game.sanctum_upgrade_level = 3
	game.staff_hired.append("ronda")
	game.reputation = 30
	game.mess = 0
	var bill_zero: int = game._daily_upkeep()
	for seat in range(2):
		game._catch_culprit("Preso %d" % seat, "")
	var jars_line: String = game._harvest_cell()
	var stock_blood: int = int(game.ingredient_stock.get("sangue", 0))
	print("   2 presos: conta %d -> %+d ouro • colheita%s estoque=%d frasco(s)" % [
		bill_zero, game._daily_upkeep() - bill_zero, jars_line, stock_blood])
	game.catalyst_enabled = false
	var rare: Dictionary = game._catalyst_available()
	print("   o sangue é raridade de forja? %s (sorte %d)" % [
		str(rare.get("id", "nenhum")), int(rare.get("catalyst_luck", 0))])

	print("── os três destinos do mesmo preso ──")
	_limpa()
	var courted := str(game.Regulars.DATA[2]["id"])
	var courted_short := str(game.Regulars.find(courted)["short"])
	game.sanctum_upgrade_level = 3
	game.reputation = 30
	game.charm_rank = 5
	game.romance_stage[courted] = 3
	game.seduction_successes = 30
	game._offer_servant(courted)
	# As três conquistas que estes atos destravam pagam fama dentro da medição;
	# entram como já pagas para o delta ser só o do ato.
	for ach_id in ["servant_first", "cell_blood", "banish_one", "clean_five"]:
		if not game.unlocked_achievements.has(ach_id):
			game.unlocked_achievements.append(ach_id)
	var served: int = game.servants.size()
	game._catch_culprit(courted_short, courted)
	print("   preso que era servo: servants %d -> %d (esperado 0, cela não atende balcão)" % [
		served, game.servants.size()])
	var ach_in: int = game.unlocked_achievements.size()
	var rep_in: int = _flush_rep()
	var bond_in: int = int(game.regular_bonds.get(courted, 0))
	game._release_prisoner()
	print("   solto: presos=%d, fama %+d, vínculo %+d (esperado 0, +1 ato, +1)" % [
		game.prisoners.size(), game.reputation - rep_in, int(game.regular_bonds.get(courted, 0)) - bond_in])
	if game.unlocked_achievements.size() > ach_in:
		print("      (conquistas pagas no meio do ato: %s)" % str(
			game.unlocked_achievements.slice(ach_in)))
	# Banimento fecha a porta para sempre: 2.000 sorteios e ele não aparece.
	game._catch_culprit(courted_short, courted)
	rep_in = _flush_rep()
	game._banish_prisoner()
	print("   expulso: fama %+d e porta fechada para %s" % [game.reputation - rep_in, str(game.banned_regulars)])
	var hits := 0
	for i in range(2000):
		if str(game._pick_regular()["id"]) == courted:
			hits += 1
	print("   banido: presos=%d, banidos=%s, aparece em %d de 2000 sorteios (esperado 0)" % [
		game.prisoners.size(), str(game.banned_regulars), hits])
	# Entrega à guilda é o meio-termo: rua paga, sangue perdido.
	game._catch_culprit("Caco Tiracolo", "")
	var gold_in: int = _flush_gold()
	var rep_guild: int = game.reputation
	var blood_in: int = int(game.ingredient_stock.get("sangue", 0))
	game._deliver_prisoner()
	print("   entregue à guilda: presos=%d, ouro %+d, fama %+d, frascos no estoque %+d (esperado 0, +%d, +2, 0)" % [
		game.prisoners.size(), game.gold - gold_in, game.reputation - rep_guild,
		int(game.ingredient_stock.get("sangue", 0)) - blood_in, 15 + game.player_level])

	print("── o filtro muda o tom, não a porta ──")
	_limpa()
	game.adult_content_enabled = false
	game.sanctum_upgrade_level = 3
	game.reputation = 30
	game._catch_culprit("Nino do Beco Sem Nome", "")
	print("   conteúdo sensual OFF: presos=%d, sangue/conta seguem valendo (esperado 1)" % [
		game.prisoners.size()])

	print("── round-trip do save ──")
	_limpa()
	game.sanctum_upgrade_level = 2
	game.mess = 57
	game.sweeps_done = 4
	game.blood_harvested = 9
	game._catch_culprit("Zeca Pé-de-Ferro", "")
	var kept := str(game.Regulars.DATA[3]["id"])
	game.banned_regulars.append(kept)
	game._save_game()
	var wrote: int = game.mess
	game._reset_run()
	print("   vida nova: salão %d, presos %d, banidos %d, vassouras %d (esperado tudo zero)" % [
		game.mess, game.prisoners.size(), game.banned_regulars.size(), game.sweeps_done])
	game._load_game()
	print("   reload do save de antes do reset: salão %d -> %d, presos=%d, banidos=%s, vassouras=%d, colhido=%d" % [
		wrote, game.mess, game.prisoners.size(), str(game.banned_regulars), game.sweeps_done, game.blood_harvested])
	_limpa()
	game._save_game()
	print("== fim da sonda ==")
	quit()

func _limpa() -> void:
	var game = _game
	game._reset_run()
	game.servants.clear()
	game.staff_hired.clear()
	game.romance_stage.clear()
	game.regular_bonds.clear()
	game.seduction_successes = 0
	game.charm_rank = 0
	game.fury = 0
	game.reputation = 0
	game.gold = 500
	game.sweeps_done = 0
	game.blood_harvested = 0

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

## Conquista que destrava no meio da medição paga fama e ouro pelo caminho — é
## ganho real, mas não é a entrega que a sonda está medindo. Descarrega antes de
## cada delta e devolve o número limpo.
func _flush_rep() -> int:
	_game._check_achievements()
	return int(_game.reputation)

func _flush_gold() -> int:
	_game._check_achievements()
	return int(_game.gold)
