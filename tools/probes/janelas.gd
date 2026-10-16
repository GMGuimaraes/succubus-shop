extends SceneTree

## Sonda das janelas: a loja obedece a uma frase só — a rua anda enquanto nenhuma janela
## estiver na tela. O resumo de offline, o balanço do dia, a lembrança de origem e o menu
## do ESC já decidiam isso cada um do próprio lado, e o buraco aparece quando uma janela
## fecha por um caminho que o código dela não previu: o OK emite `confirmed`, mas ESC, o X
## e um hide() só escondem o Window. Preso ao `confirmed`, o relógio morria ali e o
## freguês que estava no balcão ficava plantado para sempre — o "goblin travado".
##
## Caso A: janela confirmada pelo OK → a rua volta a andar.
## Caso B: janela escondida sem OK (o que o ESC faz) → mede se o relógio morreu.
## Caso C: o mesmo B com o menu por cima, que é a ordem real do primeiro startup
##         (relatório de offline e depois o seletor de idioma em cima dele).
##
## Os três têm de andar. Zero ticks em qualquer um é janela que devolveu a loja pela
## metade, e é isso que esta sonda existe para não deixar voltar.
##
## Uso: godot --headless --path . --quit-after 2600 -s res://tools/probes/janelas.gd

const OUT := "D:/Downloads/tmp-userdata/"

func _initialize() -> void:
	var fresh := DirAccess.open("D:/Downloads/tmp-userdata/")
	if fresh != null:
		fresh.remove("Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg")
		fresh.remove("Godot/app_userdata/Succubus Shop/locale_settings.cfg")
	var resultados := {}
	resultados["A OK no botão"] = await _rodada("confirmado")
	resultados["B escondida por ESC"] = await _rodada("cancelado")
	resultados["C ESC com menu em cima"] = await _rodada("cancelado_com_menu")
	print("\n== veredito (ticks em 600 quadros a 4x com a rua liberada) ==")
	var broken: Array[String] = []
	for label in resultados.keys():
		var r: Dictionary = resultados[label]
		print("%s: +%d ticks, relógio parado=%s, segurado por=%s, corpo plantado=%s (%s)" % [
			label, int(r["ticks"]), str(r["stopped"]), str(r["holder"]), str(r["frozen"]), str(r["body"])])
		# Andar é a exigência; parado no fim só é aceitável se outra janela assumiu o
		# relógio. "Ninguém" segurando um relógio morto é a forma exata do bug original.
		if int(r["ticks"]) <= 0:
			broken.append("%s (nem um tique)" % label)
		elif bool(r["stopped"]) and str(r["holder"]) in ["ninguém", "resumo de offline"]:
			broken.append("%s (relógio morto sem janela na tela)" % label)
	if broken.is_empty():
		print("APROVADO: os três jeitos de fechar o resumo devolvem a rua andando.")
	else:
		print("REPROVADO: " + ", ".join(broken))
	quit()

func _rodada(modo: String) -> Dictionary:
	print("== CASO %s ==" % modo)
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	# Estado de quem ficou duas horas fora da loja. O relógio nasce andando (autostart).
	game._offline_elapsed_seconds = 7200.0
	game._apply_offline_progress()
	await _frames(3)
	var dialog: AcceptDialog = game.offline_dialog
	if dialog == null or not is_instance_valid(dialog):
		print("  SEM JANELA: o resumo não abriu, nada a medir")
		return {"ticks": -1, "stopped": game.world_timer.is_stopped(), "frozen": false,
			"body": "-", "holder": "sem janela"}
	print("  janela abriu=%s  relógio parado por ela=%s" % [
		str(dialog.visible), str(game.world_timer.is_stopped())])
	if modo == "confirmado":
		dialog.confirmed.emit()
	else:
		# Exatamente o caminho do ESC: o Window se esconde, `confirmed` não dispara.
		dialog.hide()
	# O menu por cima é a ordem do primeiro startup: relatório e depois seletor de idioma.
	if modo == "cancelado_com_menu":
		game._open_menu(true)
		game._close_menu()
	# Nada de mexer no Timer: o que se mede é justamente se a loja o devolveu. Com
	# relógio 4x acelerado, 600 quadros valem dias de tique para um relógio vivo e
	# nada para um morto.
	Engine.time_scale = 4.0
	var ticks_antes := int(game.ticks)
	await _frames(600)
	Engine.time_scale = 1.0
	var ganho := int(game.ticks) - ticks_antes
	var body := str(game.stage_customer.get_meta("stage_body", "-"))
	var frozen: bool = ganho == 0 and game.stage_customer.visible
	# Relógio parado no fim da amostragem não é necessariamente o resumo devolvendo a
	# loja pela metade: a própria rua pode ter chegado na virada do dia e parado por
	# conta nova. Quem segura o relógio é a única leitura que separa as duas coisas.
	var holder := _quem_segura(game)
	print("  ticks em 600 quadros a 4x=+%d  relógio parado=%s  segurado por=%s  fila=%d  cliente visível=%s (%s)" % [
		ganho, str(game.world_timer.is_stopped()), holder, game.service_queue.size(),
		str(game.stage_customer.visible), body])
	var out := {"ticks": ganho, "stopped": game.world_timer.is_stopped(),
		"frozen": frozen, "body": body, "holder": holder}
	game.free()
	await _frames(2)
	return out

## Espelha `_modal_holds_clock()` do jogo, janela por janela, para dizer qual delas está
## de fato na tela no instante da medição.
func _quem_segura(game: Node) -> String:
	if game.offline_dialog != null and (game.offline_dialog as Window).visible:
		return "resumo de offline"
	if is_instance_valid(game.day_layer) and (game.day_layer as Control).visible:
		return "balanço do dia"
	if is_instance_valid(game.origin_layer) and (game.origin_layer as Control).visible:
		return "lembrança de origem"
	if is_instance_valid(game.menu_layer) and (game.menu_layer as Control).visible:
		return "menu"
	return "ninguém"

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
