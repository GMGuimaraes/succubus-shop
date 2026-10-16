extends SceneTree

## Sonda da chegada: fotografa cada QUADRO da vida de um cliente no palco — quanto falta
## para ele parar (`arrive_left`), onde está, e onde o balcão fica — e conta quantas
## caminhadas fecham em 0 px do balcão. Visita cortada no meio é gente que "anda contra a
## parede e some", que é o travado visto da cadeira; a medição só vale quadro a quadro,
## porque amostrar na borda do tique lê o `arrive_left` logo depois de ele ser posto.
##
## Uso: godot --headless --path . --quit-after 900 -s res://tools/probes/chegada.gd

const OUT := "D:/Downloads/tmp-userdata/"

var game: Node
var visits: Array[Dictionary] = []
var current: Dictionary = {}
var meet_x := 0.0
var meet_depth := 0.0

func _initialize() -> void:
	var fresh := DirAccess.open("D:/Downloads/tmp-userdata/")
	if fresh != null:
		fresh.remove("Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg")
		fresh.remove("Godot/app_userdata/Succubus Shop/locale_settings.cfg")
	game = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	Engine.time_scale = 4.0
	meet_x = float(game._room_meet().y) * game.stage_layer.size.x
	meet_depth = 0.82
	print("== balcão em x=%.0f profundidade=%.2f | tick=%.2fs | chegada 2.80s (0.62 do tick) ==" % [
		meet_x, meet_depth, game.world_timer.wait_time])
	for f in range(800):
		await process_frame
		_track()
	if not current.is_empty():
		visits.append(current)
	_report()
	quit()

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame

func _track() -> void:
	var node: Control = game.stage_customer
	if not is_instance_valid(node):
		return
	var body := str(node.get_meta("stage_body", "?"))
	var left := float(node.get_meta("arrive_left", -1.0))
	if current.is_empty() or str(current["body"]) != body or left > float(current["max_left"]):
		if not current.is_empty():
			visits.append(current)
		current = {"body": body, "max_left": left, "left": left, "x": node.position.x + node.size.x * 0.5,
			"depth": float(node.get_meta("stage_depth", 0.0)), "samples": 0, "stopped": left <= 0.0}
	current["samples"] = int(current["samples"]) + 1
	current["left"] = left
	current["x"] = node.position.x + node.size.x * 0.5
	current["depth"] = float(node.get_meta("stage_depth", 0.0))
	if left <= 0.0:
		current["stopped"] = true

func _report() -> void:
	var walked := 0
	var arrived := 0
	var cut := 0
	print("\n== visitas ==")
	for v in visits:
		var gap: float = absf(float(v["x"]) - meet_x)
		# `arrive_left` negativo é o sentinela de "ainda não começou a caminhada": a figura
		# está plantada na porta esperando o tique, e contar isso como chegada infla o
		# veredito. Só entra na conta quem teve janela de chegada de verdade.
		if float(v["max_left"]) <= 0.0:
			print("%-11s sem caminhada (figura esperando o tique na porta)  x=%.0f  %d quadros" % [
				str(v["body"]), float(v["x"]), int(v["samples"])])
			continue
		walked += 1
		if bool(v["stopped"]):
			arrived += 1
		else:
			cut += 1
		print("%-11s parou=%s  arrive_left iniciou %.2fs terminou %.2fs  |  x=%.0f (faltam %.0f px para o balcão)  profundidade %.2f  %d quadros" % [
			str(v["body"]), "SIM" if bool(v["stopped"]) else "NÃO",
			float(v["max_left"]), float(v["left"]), float(v["x"]), gap, float(v["depth"]), int(v["samples"])])
	print("\n== veredito: %d de %d caminhadas terminaram no balcão (%d cortadas pelo fim da janela de amostragem) ==" % [
		arrived, walked, cut])
	if walked > 0 and cut == 0:
		print("APROVADO: toda caminhada que o orçamento deixou medir fechou em 0 px do balcão.")
	elif arrived == 0:
		print("REPROVADO: nenhuma visita chegou — o palco anda contra a parede e some.")
	else:
		print("ATENÇÃO: caminhada inacabada; confira se é o fim da amostragem ou o passo que parou.")
