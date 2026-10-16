extends SceneTree

## Prova de campo do cronômetro da forja: o usuário lê "12s" e o número parece congelado.
## Esta sonda não conserta nada ainda — ela mede. Roda a loja com o relógio esticado,
## fabrica uma peça, e grava a legenda quadro a quadro. O que importa são três números:
## quantas leituras diferentes a tela mostrou, de quanto em quanto elas mudaram (em
## quadros) e se a queda é contínua ou em degraus de 3 segundos (o tique do mundo).
## Se a legenda muda a cada tique, o número está preso ao relógio do mundo; se muda a
## cada quadro, ele já é vivo e a queixa está em outro lugar da tela.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/relogio.gd
##
## Veredito medido, já com o conserto no lugar: a peça de 6,0s de mundo foi lida 13 vezes
## em 64 quadros, mudando a cada **4,7 quadros** em média (pior 8), **monótona** — nenhuma
## leitura voltou para cima — e atravessando os **2 tiques** do relógio do mundo sem degrau
## visível. O botão lê `⏳ Forjando 5.7s • ░░░░░░░░` e a faixa da fila mostra o mesmo número.
## Antes deste ciclo o botão dizia apenas "Na fila" (sem tempo nenhum) e só era reescrito por
## `_refresh_ui()`, que é por evento: o número que a pessoa via era o da frase de rodapé
## "levará 12.0s", escrita uma vez e nunca atualizada — recibo de instante, não relógio.
## Armadilha desta sonda, e ela mentiu uma rodada inteira por causa dela: lambda de GDScript
## captura **por valor**, então `var tiques := 0` acrescido dentro do `timeout.connect` deixa
## o de fora em zero para sempre. Contador de lambda mora em Dictionary, ou não conte.

const SEED_VAL := 20261016
const QUADROS := 2400

var _saltos: Array[String] = []

## Os segundos que a legenda anuncia ("⏳ Forjando 4.2s • ███░░"). É o número que a pessoa
## persegue com o olho; se ele subir no meio da contagem, a contagem está quebrada.
func _segundos(legenda: String) -> float:
	var inicio := legenda.find("Forjando ")
	if inicio < 0:
		return 1000000.0
	var resto := legenda.substr(inicio + len("Forjando "))
	var fim := resto.find("s")
	if fim < 0:
		return 1000000.0
	return float(resto.substr(0, fim))

func _initialize() -> void:
	_apagar("user://succubus_shop_save.cfg")
	var loja = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(loja)
	await _frames(3)
	seed(SEED_VAL)
	loja._reset_run()
	loja.gold = 400
	for item in loja.products:
		for chave in (item.get("ingredients", {}) as Dictionary).keys():
			loja.ingredient_stock[str(chave)] = 99
	loja._refresh_ui()
	loja._craft_product(0)
	var trabalho: Dictionary = loja.craft_jobs[0]
	print("   trabalho criado: remaining=%.2f  (duration de %.2fs de mundo)" % [
		float(trabalho["remaining"]), float(trabalho["remaining"])])
	print("   `world_timer.wait_time` = %.2f • `world_speed()` = %.1f" % [
		loja.world_timer.wait_time, loja.world_speed()])
	Engine.time_scale = 8.0
	var ultima_legenda := ""
	var mudancas: Array[int] = []
	var leituras: Array[String] = []
	var ultimo_quadro := 0
	# O contador mora num Dictionary: lambda do GDScript captura por VALOR, então um `int`
	# local acrescido dentro do lambda deixaria o de fora sempre em zero — a medição anterior
	# desta sonda mentiu exatamente por isso.
	var tiques := {"n": 0}
	var ultimo_numero := 1000000.0
	loja.world_timer.timeout.connect(func() -> void: tiques["n"] += 1)
	for quadro in range(QUADROS):
		await process_frame
		if not is_instance_valid(loja) or loja.craft_jobs.is_empty():
			print("   a peça saiu da bancada no quadro %d (%d tiques do mundo)" % [quadro, int(tiques["n"])])
			break
		# O que a pessoa lê é o botão do produto; a faixa do topo é só o resumo da fila.
		var legenda := str(loja.craft_buttons[0].text) + "   ||   " + str(loja.forge_status_label.text)
		if legenda != ultima_legenda:
			var numero := _segundos(legenda)
			if numero > ultimo_numero + 0.001:
				_saltos.append("q%d: %.1f -> %.1f" % [quadro, ultimo_numero, numero])
			ultimo_numero = minf(ultimo_numero, numero)
			mudancas.append(quadro - ultimo_quadro)
			ultimo_quadro = quadro
			ultima_legenda = legenda
			if leituras.size() < 40:
				leituras.append("q%d: %s" % [quadro, legenda])
	Engine.time_scale = 1.0
	print("   leituras distintas na tela: %d • tiques do mundo no período: %d" % [
		leituras.size(), int(tiques["n"])])
	print("   número que voltou para cima no meio da contagem: %d vez(es) %s" % [
		_saltos.size(), "(monótono)" if _saltos.is_empty() else str(_saltos)])
	if not mudancas.is_empty():
		var soma := 0
		var maior := 0
		for salto in mudancas:
			soma += int(salto)
			maior = maxi(maior, int(salto))
		print("   intervalo entre mudanças: média %.1f quadros • pior %d quadros" % [
			float(soma) / float(mudancas.size()), maior])
	for leitura in leituras:
		print("      %s" % leitura)
	if is_instance_valid(loja):
		loja.queue_free()
		await _frames(2)
	print("VEREDITO: medido, não opinado.")
	quit()


func _apagar(caminho: String) -> void:
	var absoluto: String = ProjectSettings.globalize_path(caminho)
	if FileAccess.file_exists(absoluto):
		DirAccess.remove_absolute(absoluto)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
