extends SceneTree

## Sonda da porta: prova que a defesa da casa é soma de mãos que o jogo já media
## (ronda, servo, batedor, santuário, Administração, privilégio), que a chance de
## visita e a curva de repulsa respondem a essas mãos e à resposta dada ao vigário,
## e que uma visita tem consequência em ouro, barro, fúria, reputação e peça que sai do
## estoque de verdade. Confere também as três respostas do dízimo (preço, janela de
## escudo e o que cada uma faz na chance), a devolução da milícia, as trinta viradas
## rodando no `_on_customer_tick` de verdade, o round-trip do save (inclusive
## adulterado), o que reencarnar apaga e o que ela não toca, e a tabela da trilha
## situacional, que hoje escolhe entre as duas faixas da casa e ainda afina o tom.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 3000 --script res://tools/probes/porta.gd
##
## Veredito medido nesta rodada: casa cheia (ronda + 4 servos + 5 batedores +
## santuário 5 + Administração 5 + dobradiça) fecha a porta com 144 de mão contra os
## 112 da visita final — 87% de repulsa, e 47% depois de doze portas seguradas
## (escalada de +10 a cada três carimbos). Sem ninguém no balcão, 0 de defesa contra a
## comitiva de poder 46 segura 9%; o empate é 55% e o teto, 95%. Chance de visita: 4%
## no placar zero, 12% no teto de +8, −4 com dízimo em dia, −9 com o endereço apagado,
## −4 com o sino, +3 por recusa, clampado de 0 a 35%. O vigário chega no dia 9 e cobra
## 76 com 20 de fama (160 no dia 30); o suborno é 6× isso (456 → 960) e compra 24 dias,
## contra 7 do dízimo e 5 da recusa — e sem caixa no balcão a postura não muda.
## Arrombo medido em caixa de 1000: saco de 90, 22 de barro, +1 de fúria, −2 de
## reputação e 1 peça fora da prateleira (5 → 4, a melhor do produto sorteado). Com a
## milícia, a porta segurada devolve 45 e sobe 2 de reputação em vez de 1. Trinta
## viradas de jogo real, com ronda e criada contratadas e seis recusas na conta: 5
## portas seguradas, 8 arrombadas, chance fechando em 25% e a dobradiça paga no
## terceiro carimbo (defesa 0 → 10). Save: as dez chaves novas atravessam o
## carregamento; postura "santificado", escudo até o dia 999999, −5 portas e
## "espada_laser" duplicado acordam em postura vazia, portas 0 e só ["dobradica"].
## Reencarnar zera postura, mural e alarme e deixa carimbos, arrombadas, dízimos pagos
## e privilégios no caixilho. Trilha: salão 1,00/-13, forja 1,06/-11, estrada
## 1,02/-12, biblioteca 0,95/-15, santuário 0,88/-17, alarme 1,12/-8, ruína 0,84/-18 e
## vigário na porta 0,92/-14. Sete conquistas novas nas 82 definições. Se a casa cheia
## segurar menos de 87% contra a visita final, ou se o arrombo parar de mexer no
## estoque, a curva mudou de lugar.

const OUT := "D:/Downloads/tmp-userdata/"
const SAVE := "user://succubus_shop_save.cfg"

const NEUTRAL: Array[String] = [
	"first_door", "door_three", "defense_campaign", "door_breach",
	"tithe_paid", "vicar_bribed", "vicar_refused",
]

var _game
var _inv

func _initialize() -> void:
	_game = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(_game)
	await _frames(3)
	var game = _game
	game.world_timer.stop()
	game._reset_run()

	_inv = load("res://invasions.gd")
	var Inv = _inv

	print("── mão na porta: quem soma ──")
	var empty_snap := {"ronda": 0, "servants": 0, "adventurers": 0, "sanctum": 0, "rank": 0, "privileges": []}
	print("   casa sem ninguém: defesa %d • linhas %d" % [
		Inv.defense_power(empty_snap), Inv.defense_lines(empty_snap).size()])
	var full := {
		"ronda": 40, "servants": 2, "adventurers": 3, "sanctum": 3, "rank": 2,
		"privileges": ["dobradica", "sino", "milicia"],
	}
	for line in Inv.defense_lines(full):
		print("   %-34s +%d" % [str(line["name"]), int(line["value"])])
	print("   TOTAL: %d (ronda 40 + servos 12 + batedores 21 + santuário 12 + admin 6 + dobradiça 10)" % Inv.defense_power(full))

	print("── curva de segurar a porta (visita de poder 46) ──")
	var wave46 := {"power": 46}
	for defesa in [0, 10, 20, 46, 60, 90, 200]:
		var snap := {"ronda": 0, "servants": 0, "adventurers": 0, "sanctum": 0, "rank": 0, "privileges": [], "p": defesa}
		var measured: int = Inv.repel_chance({"ronda": defesa, "servants": 0, "adventurers": 0, "sanctum": 0, "rank": 0, "privileges": []}, wave46)
		print("   defesa %3d vs poder 46 -> %d%%" % [defesa, measured])

	var teto := {
		"ronda": 40, "servants": 4, "adventurers": 5, "sanctum": 5, "rank": 5,
		"privileges": ["dobradica"],
	}
	var teto_pow: int = Inv.defense_power(teto)
	var ultima: Dictionary = Inv.wave_for(42, 0)
	var ultima2: Dictionary = Inv.wave_for(42, 12)
	print("── teto da porta ──")
	print("   casa cheia (%d de mão) vs visita final (%d) -> %d%% • com 12 portas seguradas (%d) -> %d%%" % [
		teto_pow, int(ultima["power"]), Inv.repel_chance(teto, ultima),
		int(ultima2["power"]), Inv.repel_chance(teto, ultima2)])

	print("── chance de a rua bater na virada ──")
	var base := {"ronda": 0, "servants": 0, "adventurers": 0, "sanctum": 0, "rank": 0, "privileges": []}
	var sino := {"ronda": 0, "servants": 0, "adventurers": 0, "sanctum": 0, "rank": 0, "privileges": ["sino"]}
	for score in [0, 900, 2400, 5200, 9000, 20000]:
		print("   placar %5d -> %d%% (teto de +8)" % [score, Inv.invasion_chance(score, "", 0, 12, 0, base)])
	print("   dízimo em dia: %d%% • suborno: %d%% • sem resposta: %d%%" % [
		Inv.invasion_chance(3600, "pago", 20, 12, 0, base),
		Inv.invasion_chance(3600, "subornado", 20, 12, 0, base),
		Inv.invasion_chance(3600, "", 0, 12, 0, base)])
	print("   escudo vencido (dia 12, valia até 8): %d%%" % Inv.invasion_chance(3600, "pago", 8, 12, 0, base))
	print("   duas recusas: %d%% • sino com dízimo: %d%%" % [
		Inv.invasion_chance(3600, "", 0, 12, 2, base),
		Inv.invasion_chance(3600, "pago", 20, 12, 0, sino)])
	print("   teto da página: %d%% (placar 90000, quatro recusas)" % Inv.invasion_chance(90000, "", 0, 12, 4, base))

	print("── a visita da vez e a escalada dos carimbos ──")
	for day in [1, 6, 11, 16, 21, 27, 34, 42]:
		var w: Dictionary = Inv.wave_for(day, 0)
		print("   dia %2d -> %s" % [day, "nenhuma (loja sem alvo)" if w.is_empty() else "%s, poder %d" % [str(w["name"]), int(w["power"]) ]])
	for repelled in [0, 3, 6, 9, 12]:
		var w2: Dictionary = Inv.wave_for(42, repelled)
		print("   %2d portas seguradas -> %s (poder %d, escalada +%d)" % [
			repelled, str(w2["name"]), int(w2["power"]), Inv.escalation(repelled)])
	for rung in [2, 3, 5, 6, 9, 10, 11]:
		var p: Dictionary = Inv.privilege_for(rung)
		print("   %2d portas -> %s" % [rung, "nada novo" if p.is_empty() else str(p["name"])])

	print("── o bolso do vigário ──")
	for day in [9, 14, 21, 30]:
		print("   dia %2d, reputação 20: dízimo %d • suborno %d (%dx) • janelas %d/%d dias" % [
			day, Inv.tithe_for(day, 20), Inv.bribe_for(day, 20), Inv.BRIBE_MULTIPLIER,
			Inv.TITHE_WEEK, Inv.BRIBE_DAYS])
	print("   dízimo cresce com a fama: dia 12 rep 0 = %d, rep 40 = %d" % [
		Inv.tithe_for(12, 0), Inv.tithe_for(12, 40)])

	# ---------- vivo: arrombo ----------
	print("── visita medida ao vivo: porta arrombada ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 16
	game.gold = 1000
	game.reputation = 20
	game.mess = 0
	game.fury = 0
	game.prisoners.clear()
	var shelf_before: int = _shelf(game)
	var breach_wave: Dictionary = Inv.wave_for(game.shop_day, 0)
	var esperado_saco: int = Inv.plunder_for(breach_wave, 1000)
	var linha_breach: String = str(game._breach_invasion(breach_wave))
	print("   %s" % linha_breach.substr(0, 160))
	print("   caixa 1000 -> %d (saco %d) • barro %d • fúria %d • reputação %d • prateleira %d -> %d" % [
		game.gold, esperado_saco, game.mess, game.fury, game.reputation, shelf_before, _shelf(game)])
	print("   peças levadas da tabela: %d • perdidas de verdade: %d" % [
		int(breach_wave["pieces"]), shelf_before - _shelf(game)])
	print("   carimbo de arrombada: %d • alarme na trilha até o dia %d" % [game.invasions_lost, game.music_alarm_until])

	# ---------- vivo: repulsa ----------
	print("── porta segurada (com e sem milícia) ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 16
	game.gold = 1000
	game.reputation = 20
	game.invasions_repelled = 0
	var sem_milicia: String = str(game._repel_invasion(breach_wave))
	print("   sem milícia: caixa %d • reputação %d • portas %d" % [game.gold, game.reputation, game.invasions_repelled])
	print("   %s" % sem_milicia.substr(0, 150))
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 16
	game.gold = 1000
	game.reputation = 20
	var so_milicia: Array[String] = ["milicia"]
	game.defense_privileges = so_milicia
	var com_milicia: String = str(game._repel_invasion(breach_wave))
	print("   com milícia: caixa %d (devolve %d) • reputação %d • portas %d" % [
		game.gold, Inv.militia_reclaim(breach_wave, 1000), game.reputation, game.invasions_repelled])
	print("   campanha: %s" % com_milicia.substr(com_milicia.find(" CAMPANHA"), 120))

	print("── a dobradiça chega com o terceiro carimbo ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.defense_privileges.clear()
	game.invasions_repelled = 0
	var antes: int = game._defense_power()
	for i in range(3):
		game.invasions_repelled += 1
		game._claim_defense_privilege()
	print("   defesa %d -> %d • privilégios %s" % [antes, game._defense_power(), str(game.defense_privileges)])
	print("   %s" % Inv.campaign_line(game.invasions_repelled))

	# ---------- vivo: as três respostas ----------
	print("── as três respostas do vigário ──")
	for answer in ["dizimo", "suborno", "recusa"]:
		_neutral(game)
		game._reset_run()
		_neutral(game)
		game.shop_day = 12
		game.gold = 2000
		game.reputation = 20
		game.vicar_refusals = 1
		game.faction_standing["submundo"] = 0
		var chance_antes: int = game._invasion_chance()
		game._answer_vicar(answer)
		print("   %-8s: caixa %d (+%d de custo previsto) • postura \"%s\" até dia %d • reputação %d • recusos %d • submundo %d • chance %d%% -> %d%%" % [
			answer, game.gold,
			Inv.tithe_for(12, 20) if answer == "dizimo" else (Inv.bribe_for(12, 20) if answer == "suborno" else 0),
			game.tithe_stance, game.tithe_until, game.reputation, game.vicar_refusals,
			int(game.faction_standing.get("submundo", 0)), chance_antes, game._invasion_chance()])
		print("      %s" % game._vicar_panel_line())

	print("── sem caixa, a resposta não sai pela boca ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 12
	game.gold = 10
	game.reputation = 20
	game._answer_vicar("dizimo")
	print("   dízimo com 10 no caixa: postura \"%s\" (esperado vazio) • caixa %d • texto: %s" % [
		game.tithe_stance, game.gold, game.last_event.substr(0, 80)])

	print("── resposta vencida volta a cobrar ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 12
	game.gold = 2000
	game._answer_vicar("dizimo")
	var esperando: bool = game._vicar_waiting()
	game.shop_day = game.tithe_until
	var dentro: bool = game._vicar_waiting()
	game.shop_day = game.tithe_until + 1
	print("   dia do pagamento: esperando=%s • último dia do escudo: %s • dia seguinte: %s" % [
		esperando, dentro, game._vicar_waiting()])

	# ---------- trilha ----------
	print("── trilha situacional (duas faixas, a situação escolhe) ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	for caso in [
		["salão", {}, ""],
		["alarme", {"music_alarm_until": 99}, ""],
		["ruína", {"debt": 99999}, ""],
		["vigário", {"shop_day": 20}, "porta"],
	]:
		game._reset_run()
		_neutral(game)
		for chave in caso[1].keys():
			game[chave] = caso[1][chave]
		if caso[2] == "porta":
			game.vicar_announced_day = 20
		var tune: Dictionary = game._music_situation()
		print("   %-8s -> %-16s %-9s pitch %.2f • %.1f dB" % [
			caso[0], str(tune["name"]), str(tune["track"]), float(tune["pitch"]), float(tune["db"])])
	for sala in ["reception", "forge", "library", "expedition", "sanctum"]:
		game._reset_run()
		_neutral(game)
		game.music_alarm_until = 0
		game._set_sector(sala)
		var tune2: Dictionary = game._music_situation()
		print("   setor %-11s -> %-16s %-9s pitch %.2f • %.1f dB" % [
			sala, str(tune2["name"]), str(tune2["track"]), float(tune2["pitch"]), float(tune2["db"])])

	# ---------- painel ----------
	print("── painel da recepção ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 12
	game.gold = 2000
	game.reputation = 20
	var folha: Array[String] = ["ronda"]
	var cadastro: Array[String] = ["corva", "torvald"]
	game.staff_hired = folha
	game.adventurers_hired = cadastro
	game._refresh_ui()
	print("   defesa: %s" % game.defense_label.text)
	print("   linhas: %s" % game._defense_breakdown_line())
	print("   vigário: %s" % game.vicar_label.text)
	print("   botões: \"%s\" (disabled=%s) • \"%s\" (disabled=%s) • \"%s\" (disabled=%s)" % [
		game.tithe_button.text, game.tithe_button.disabled, game.bribe_button.text,
		game.bribe_button.disabled, game.refuse_button.text, game.refuse_button.disabled])
	game._answer_vicar("dizimo")
	print("   depois do dízimo: \"%s\" (disabled=%s) • botões %s %s %s" % [
		game.tithe_button.text, game.tithe_button.disabled,
		str(game.bribe_button.disabled), str(game.refuse_button.disabled), game.vicar_label.text.substr(0, 60)])
	game.invasion_label.text = game.last_invasion
	print("   última visita no mural: %s" % ("vazio" if game.last_invasion.is_empty() else "%d caracteres" % game.last_invasion.length()))

	# ---------- save ----------
	print("── round-trip do save ──")
	_neutral(game)
	game._reset_run()
	_neutral(game)
	game.shop_day = 18
	game.gold = 2500
	game.tithe_stance = "subornado"
	game.tithe_until = 30
	game.tithe_demands = 4
	game.tithe_paid_total = 640
	game.vicar_refusals = 2
	game.vicar_bribes = 1
	game.invasions_repelled = 7
	game.invasions_lost = 3
	var privilegios: Array[String] = ["dobradica", "sino"]
	game.defense_privileges = privilegios
	game.last_invasion = "🛡 teste de mural"
	game._save_game()
	var relido = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(relido)
	await _frames(3)
	relido.world_timer.stop()
	print("   postura \"%s\" até %d • recusos %d • subornos %d • dízimos pagos %d (%d cobranças)" % [
		relido.tithe_stance, relido.tithe_until, relido.vicar_refusals, relido.vicar_bribes,
		relido.tithe_paid_total, relido.tithe_demands])
	print("   portas %d • arrombadas %d • privilégios %s • mural %d caracteres" % [
		relido.invasions_repelled, relido.invasions_lost, str(relido.defense_privileges),
		relido.last_invasion.length()])
	print("   defesa após carregar: %d (ronda=%s servos=%d batedores=%d)" % [
		relido._defense_power(), str(relido.staff_hired), relido.servants.size(),
		relido.adventurers_hired.size()])

	print("── save adulterado não ganha escudo eterno ──")
	var messy := ConfigFile.new()
	messy.load(SAVE)
	messy.set_value("game", "tithe_stance", "santificado")
	messy.set_value("game", "tithe_until", 999999)
	messy.set_value("game", "invasions_repelled", -5)
	messy.set_value("game", "defense_privileges", ["dobradica", "espada_laser", "dobradica"])
	messy.save(SAVE)
	var consertado = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(consertado)
	await _frames(3)
	consertado.world_timer.stop()
	print("   postura: \"%s\" (esperado vazio) • portas %d (esperado 0) • privilégios %s" % [
		consertado.tithe_stance, consertado.invasions_repelled, str(consertado.defense_privileges)])

	print("── reencarnar: o que fica na porta ──")
	consertado.shop_day = 40
	consertado._reset_run()
	print("   depois da reencarnação: postura \"%s\" • mural vazio=%s • alarme %d" % [
		consertado.tithe_stance, str(consertado.last_invasion.is_empty()), consertado.music_alarm_until])
	print("   permanece: portas %d (zerado pelo save adulterado acima) • arrombadas %d • dízimos pagos %d • privilégios %s" % [
		consertado.invasions_repelled, consertado.invasions_lost, consertado.tithe_paid_total,
		str(consertado.defense_privileges)])

	print("── conquistas da porta ──")
	var defs: Array = consertado._achievement_definitions()
	var achados: Array[String] = []
	for a in defs:
		if str(a["id"]) in NEUTRAL:
			achados.append("%s (%s, %d/%d)" % [str(a["id"]), str(a["name"]), int(a["gold"]), int(a["rep"])])
	print("   novas: %d de %d definições" % [achados.size(), defs.size()])
	for linha in achados:
		print("      %s" % linha)

	print("── a virada chama a visita? ──")
	_neutral(consertado)
	consertado._reset_run()
	_neutral(consertado)
	consertado.shop_day = 20
	consertado.gold = 3000
	consertado.reputation = 40
	consertado.tithe_stance = ""
	consertado.vicar_refusals = 0
	var chance: int = consertado._invasion_chance()
	var batidas := 0
	for i in range(200):
		if randi() % 100 < chance:
			batidas += 1
	print("   chance declarada %d%% -> %d batidas em 200 viradas (%.1f%%)" % [
		chance, batidas, batidas * 100.0 / 200.0])
	var wave: Dictionary = consertado._next_wave()
	print("   visita prevista para o dia 20: %s" % ("nenhuma" if wave.is_empty() else "%s pede %d, casa segura em %d%%" % [
		str(wave["name"]), int(wave["power"]), _inv.repel_chance(
			consertado._defense_snapshot(), wave)]))

	print("── trinta viradas de verdade: a porta bate? ──")
	_neutral(consertado)
	consertado._reset_run()
	_neutral(consertado)
	consertado.shop_day = 1
	consertado.gold = 3000
	consertado.reputation = 30
	consertado.vicar_refusals = 6
	consertado.tithe_stance = ""
	consertado.tithe_until = 0
	consertado.defense_privileges.clear()
	var folha_viva: Array[String] = ["ronda", "createda"]
	consertado.staff_hired = folha_viva
	var dia_inicial: int = consertado.shop_day
	var mural_antes: String = str(consertado.last_invasion)
	for i in range(30 * 20):
		consertado._on_customer_tick()
	print("   %d viradas -> dias %d->%d • portas seguradas %d • arrombadas %d • dízimos respondidos %d" % [
		30 * 20, dia_inicial, consertado.shop_day, consertado.invasions_repelled,
		consertado.invasions_lost, consertado.tithe_demands])
	print("   chance no fim: %d%% • recusos acumulados %d • privilégios %s" % [
		consertado._invasion_chance(), consertado.vicar_refusals, str(consertado.defense_privileges)])
	print("   trilha no fim da rodada: %s" % str(consertado._music_situation()["name"]))
	print("   mural mudou? %s" % str(consertado.last_invasion != mural_antes))
	print("   última linha do mural: %s" % consertado.last_invasion.substr(0, 170))

	print("VEREDITO: ver linhas acima; qualquer desvio de soma, janela ou clamp é curva mudada.")
	quit()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _neutral(game) -> void:
	for achievement_id in NEUTRAL:
		if not game.unlocked_achievements.has(achievement_id):
			game.unlocked_achievements.append(achievement_id)


func _shelf(game) -> int:
	var total := 0
	for item in game.products:
		total += int(item["stock"])
	return total


