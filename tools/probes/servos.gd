extends SceneTree

## Sonda dos servos da casa: prova que a vaga atrás do balcão abre por degrau de
## sedução, que ela depende de vínculo pago e não do interruptor de conteúdo, e que
## cada servo mexe nas três contas que ele promete mexer — fila, conta da casa e
## etiqueta. Também confere a porta de saída (fúria alta manda embora) e o
## round-trip do save, porque vínculo que não atravessa o carregamento não é
## vínculo, é variável.
##
## Uso: godot --headless --path . --quit-after 1800 --script res://tools/probes/servos.gd

const OUT := "D:/Downloads/tmp-userdata/"

var _game

func _initialize() -> void:
	_game = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(_game)
	await _frames(3)
	var game = _game
	game.world_timer.stop()

	print("── escada de vagas (seduções provadas -> servo) ──")
	for rung in [0, 3, 4, 9, 10, 17, 18, 29, 30, 44]:
		game.seduction_successes = rung
		print("   %2d sedução -> teto %d" % [rung, game.servant_cap()])

	print("── quem entra para a casa ──")
	_limpa()
	var lonely := str(game.Regulars.DATA[0]["id"])
	var courted := str(game.Regulars.DATA[1]["id"])
	game.seduction_successes = 30
	game.charm_rank = 5
	# Sem degrau de convite pago, a vaga não abre por mais que a chefe sorria.
	game.romance_stage[lonely] = 0
	game._offer_servant(lonely)
	print("   sem convite pago: servants=%d (esperado 0)" % game.servants.size())
	game.romance_stage[courted] = 3
	game._offer_servant(courted)
	print("   com convite pago: servants=%d (esperado 1)" % game.servants.size())
	# Repetir o convite não duplica o servo.
	game._offer_servant(courted)
	print("   convite repetido: servants=%d (esperado 1)" % game.servants.size())
	# O teto é o teto: quatro nomes apaixonados, três vagas.
	game.seduction_successes = 18
	for i in range(2, game.Regulars.DATA.size()):
		var id := str(game.Regulars.DATA[i]["id"])
		game.romance_stage[id] = 3
		game._offer_servant(id)
	print("   teto de 3 vagas com %d apaixonados: servants=%d" % [
		game.Regulars.DATA.size(), game.servants.size()
	])

	print("── o filtro corta o tom, não a porta ──")
	_limpa()
	game.adult_content_enabled = false
	game.charm_rank = 5
	game.seduction_successes = 30
	var plain := str(game.Regulars.DATA[2]["id"])
	game.romance_stage[plain] = 3
	game._offer_servant(plain)
	print("   conteúdo sensual OFF: servants=%d (esperado 1)" % game.servants.size())
	game.adult_content_enabled = true

	print("── o que cada servo muda na conta ──")
	_limpa()
	# Casa de verdade, para o alívio aparecer na medida: com a loja vazia a conta é
	# 12 e o piso de 1 ouro engole qualquer desconto antes dele chegar.
	game.library_upgrade_level = 3
	game.sanctum_upgrade_level = 3
	game.ad_level = 2
	for seat in game.Staff.DATA:
		game.staff_hired.append(str(seat["id"]))
	var perfil := {"patience": 2}
	var bill_zero: int = game._daily_upkeep()
	var wait_zero: int = game._queue_patience(perfil)

	for seat in range(4):
		var id := str(game.Regulars.DATA[seat]["id"])
		game.romance_stage[id] = 1
		game.servants.append(id)
		var tag: float = 1.0 + game.SERVANT_PRICE_SHARE * game.servants.size()
		print("   %d servo(s): fila %d -> %+d tique • conta %d -> %+d ouro • etiqueta x%.3f" % [
			game.servants.size(), wait_zero, game._queue_patience(perfil) - wait_zero,
			bill_zero, game._daily_upkeep() - bill_zero, tag
		])
	print("   ronda de servo sozinho barra furto em %d%% das tentativas" % [
		game.servants.size() * game.SERVANT_GUARD_CHANCE
	])

	print("── porta de saída ──")
	_limpa()
	# Aqui o quadro é montado à mão: a sonda mede a porta de saída, não a sorte de
	# entrada, e um append não depende de RNG para existir.
	for seat in range(2):
		game.servants.append(str(game.Regulars.DATA[seat + 4]["id"]))
	var before: int = game.servants.size()
	# A visita que decepciona também é a que sobe a fúria: o corte é lido no
	# temperamento de depois da porta bater, não do antes.
	game.fury = 0
	game._react_to_visit("disappointed", false)
	print("   fúria 0 -> %d depois da visita: %d -> %d (esperado sem perda)" % [
		game.fury, before, game.servants.size()
	])
	var mid: int = game.servants.size()
	game.fury = 3
	game._react_to_visit("disappointed", false)
	print("   fúria 3 -> %d depois da visita: %d -> %d (esperado -1)" % [
		game.fury, mid, game.servants.size()
	])

	print("── round-trip do save ──")
	_limpa()
	# Quadro montado à mão de novo: aqui o que se prova é a travessia do save, não a
	# sorte do convite.
	var keep := str(game.Regulars.DATA[5]["id"])
	game.servants.append(keep)
	game.servants.append("nome_que_nao_existe")
	var wrote: int = game.servants.size()
	game._save_game()
	var loaded = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(loaded)
	await _frames(3)
	print("   gravado %d, relido %d (fantasma raspado: %s)" % [
		wrote, loaded.servants.size(),
		"ok" if not loaded.servants.has("nome_que_nao_existe") else "VAZOU"
	])
	print("   nome verdadeiro sobreviveu: %s" % ("ok" if loaded.servants.has(keep) else "PERDIDO"))
	quit()

## Zera o quadro sem tocar no que atravessa vidas de propósito.
func _limpa() -> void:
	var game = _game
	game.servants.clear()
	game.staff_hired.clear()
	game.romance_stage.clear()
	game.seduction_successes = 0
	game.charm_rank = 0
	game.fury = 0

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
