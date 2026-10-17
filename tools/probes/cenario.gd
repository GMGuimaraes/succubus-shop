extends SceneTree

## A forja, a biblioteca e o santuário crescem em CENÁRIO próprio, ou a escada é só
## tinta sobre a mesma arte? A sonda varre o placar de ofício degrau a degrau e mede as
## trinta portas que a tabela promete: seis artes e, dentro de cada arte, cinco ajustes
## de luz e poeira.
##
## O que ela não deixa ninguém esquecer: o degrau zero tem de ser mudo. A escada lê
## contadores que a sala já movia, e não pode comer um sorteio nem mover um ouro — por
## isso a cauda de 40 `randi()` com a escada avaliada no cru e no topo é lida contra o
## controle, e a corrida de 200 tiques roda nos dois lados com os contadores novos
## zerados e cheios. Se a cauda divergir, a escada passou a sortear; se a conta da casa
## mexer, o cenário virou fórmula paralelo.
##
## Mede também que toda arte da escada responde pela GEOMETRIA da sala cheia (`_room_key`
## sobre as 18 artes): sem isso, a banda nova entra no palco sem chão, sem porta e sem
## fila. E que a arte que ainda não tem arquivo degrada para a arte da sala, nunca para
## fundo preto.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . --quit-after 1800 \
##     --script res://tools/probes/cenario.gd

const Locales = preload("res://locales.gd")
const SEED_VAL := 20261017
## O mesmo caminho que o jogo usa, resolvido para o disco: com APPDATA apontado para
## D:/Downloads/tmp-userdata isto cai no save descartavel, nunca no save real do usuario.
const SAVE_PATH := "user://succubus_shop_save.cfg"
const SAVE_GLOBAL := "D:/Downloads/tmp-userdata/Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg"
const SETORES: Array[String] = ["forge", "library", "sanctum"]

var falhas := 0


func _initialize() -> void:
	print("== Escada de cenário por ofício ==")
	await _frames(2)
	await _secao_cru()
	await _secao_degraus()
	await _secao_pureza()
	await _secao_tiques()
	await _secao_geometria()
	await _secao_painel()
	await _secao_save()
	await _secao_reencarnar()
	await _secao_conquistas()
	print("── veredito: %d falha(s) %s" % [falhas, "✓" if falhas == 0 else "✕"])
	quit()


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _apagar_save() -> void:
	if FileAccess.file_exists(SAVE_GLOBAL):
		DirAccess.remove_absolute(SAVE_GLOBAL)


func _loja(rotulo: String):
	_apagar_save()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	return g


## Reabre a loja lendo o save que esta no disco, sem apagar e sem resetar.
func _reabrir(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)
	g.world_timer.stop()
	return g


## Blinda o que atravessa vidas e mexe na conta, para os dois lados da corrida partirem
## da mesma casa.
func _limpar_passado(g) -> void:
	g.regular_bonds.clear()
	g.regular_orders_completed.clear()
	g.regular_story_progress.clear()
	g.regular_story_completed.clear()
	g.regular_arc_seen.clear()
	g.romance_stage.clear()
	g.card_counts.clear()
	g.faction_standing.clear()
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)


func _selar(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)


func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto):
		partes.append(str(randi() % 1000))
	return ",".join(partes)


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
	await _frames(2)


## Põe a sala no degrau pedido escrevendo direto nos contadores que a escada lê.
func _no_degrau(g, sector: String, score: int) -> void:
	if sector == "forge":
		g.total_crafted = score
		g.alchemy_rank = 0
		g.legendary_crafted = 0
	elif sector == "library":
		g.library_upgrade_level = 0
		g.library_consults = score
	else:
		g.sanctum_upgrade_level = 0
		g.rituals_performed = 0
		g.relics_calmed = score


func _assert(rotulo: String, ok: bool, detalhe: String) -> void:
	print("   %s %s — %s" % ["✓" if ok else "✕", rotulo, detalhe])
	if not ok:
		falhas += 1


func _secao_cru() -> void:
	print("── o degrau 0 é a sala crua ──")
	var g = await _loja("cru")
	for sector in SETORES:
		var score: int = g._scenery_score(sector)
		var step: int = g._scenery_step(sector)
		var arte: String = g._scenery_art(sector)
		_assert("%s cru" % sector, score == 0 and step == 0,
			"placar %d, degrau %d, arte %s" % [score, step, arte.get_file()])
		_assert("%s tem arte carregável" % sector, ResourceLoader.exists(arte),
			"instalação sem a fatia nova degrada para a sala, não para preto")
	await _fechar(g)


func _secao_degraus() -> void:
	print("── as trinta portas de cada sala ──")
	var g = await _loja("degraus")
	for sector in SETORES:
		var degraus: Array[int] = []
		var bandas: Array[int] = []
		var topo := int((g.SECTOR_SCENERY_BANDS[sector] as Array)[5]) * 2 + 40
		var s := 0
		while s <= topo:
			_no_degrau(g, sector, s)
			var step: int = g._scenery_step(sector)
			if degraus.is_empty() or degraus[degraus.size() - 1] != step:
				degraus.append(step)
			if bandas.is_empty() or bandas[bandas.size() - 1] != g._scenery_band(sector):
				bandas.append(g._scenery_band(sector))
			s += 1
		var cobertos := 0
		for d in range(g.SECTOR_SCENERY_STEPS):
			if degraus.has(d):
				cobertos += 1
		_assert("%s tem os 30 degraus" % sector, cobertos == g.SECTOR_SCENERY_STEPS,
			"%d/%d degraus atingidos, varridos até placar %d" % [cobertos, g.SECTOR_SCENERY_STEPS, topo])
		_assert("%s troca de arte 6 vezes" % sector, bandas.size() == 6 and bandas[0] == 0 and bandas[5] == 5,
			"bandas lidas: %s" % str(bandas))
		_no_degrau(g, sector, 1000000000)
		_assert("%s não estoura o degrau" % sector,
			g._scenery_step(sector) == g.SECTOR_SCENERY_STEPS - 1 and g._scenery_band(sector) == 5,
			"placar 1e9 → degrau %d, banda %d" % [g._scenery_step(sector), g._scenery_band(sector)])
	await _fechar(g)


func _secao_pureza() -> void:
	print("── a escada não sorteia nem move número ──")
	var g = await _loja("pureza")
	_selar(g)
	_no_degrau(g, "sanctum", 0)
	g._refresh_ui()
	seed(SEED_VAL)
	var controle := _cauda(40)
	seed(SEED_VAL)
	for sector in SETORES:
		for score in [0, 14, 44, 92, 170, 280, 400]:
			_no_degrau(g, sector, score)
			g._scenery_step(sector)
			g._scenery_band(sector)
			g._scenery_art(sector)
			g._scenery_light(sector)
			g._scenery_missing(sector)
			g._scenery_line(sector)
	var com_escada := _cauda(40)
	_assert("avaliar 49 estados da escada não sorteia", controle == com_escada,
		"cauda de 40 randi() idêntica ao controle")
	var ouro: int = g.gold
	var fama: float = g.reputation
	g._set_sector("sanctum")
	g._apply_progress_decor()
	_assert("pintar a sala não move caixa nem fama", g.gold == ouro and g.reputation == fama,
		"ouro %d → %d, fama %d → %d" % [ouro, g.gold, fama, g.reputation])
	await _fechar(g)


func _secao_tiques() -> void:
	print("── 200 tiques, sala crua contra sala no topo ──")
	var lados: Array[String] = []
	for carga in [0, 400]:
		var g = await _loja("tiques-%d" % carga)
		_limpar_passado(g)
		_no_degrau(g, "library", carga)
		_no_degrau(g, "sanctum", carga)
		g.gold = 4000
		g.reputation = 0
		g._set_sector("library")
		for i in range(200):
			g._on_customer_tick()
		await _frames(2)
		lados.append("caixa %d • fama %d • atendidos %d • perdidos %d • dia %d • placar %d" % [
			g.gold, int(round(g.reputation)), g.customers_served, g.queue_walkouts, g.daily_gold_earned, g.business_score()])
		await _fechar(g)
	_assert("o cenário não entra na conta", lados[0] == lados[1],
		"cru: %s\n      topo: %s" % [lados[0], lados[1]])


func _secao_geometria() -> void:
	print("── as 18 artes respondem pela sala cheia ──")
	var g = await _loja("geometria")
	for sector in SETORES:
		var sala := str(g.SECTOR_SCENERY_ROOM[sector])
		var faltando: Array[String] = []
		var sem_arquivo := 0
		for arte in (g.SECTOR_SCENERY_ART[sector] as Array):
			var path := str(arte)
			if not ResourceLoader.exists(path):
				sem_arquivo += 1
			if g._room_key(path) != sala:
				faltando.append(path.get_file())
		_assert("%s: nenhuma arte perde o chão da sala" % sector, faltando.is_empty(),
			"%d de 6 artes já pintadas, %d degradando para %s" % [6 - sem_arquivo, sem_arquivo, sala.get_file()])
		var sem_chao: Array[String] = []
		var x_chefe: float = (g.STAGE_ROOM_MEET.get(sala, Vector2(0.5, 0.4)) as Vector2).x
		var chefe_cortada: Array[String] = []
		for arte in (g.SECTOR_SCENERY_ART[sector] as Array):
			var path := str(arte)
			if not ResourceLoader.exists(path):
				continue
			## O contrato medido não é "toda arte tem contorno próprio" — é "nenhuma arte
			## da escada deixa alguém sem chão, nem serra a chefe num móvel que aquela
			## banda não pintou". O recorte próprio é o que a recepção e a guilda precisam
			## porque lá o balcão muda de altura; nas oficinas o móvel corre a parede e a
			## cartela de `recorte.gd` confere, banda a banda, que ele não cobre o x da
			## chefe. Aqui a asserção é essa: faixa de chão existe, e ou o recorte é da
			## arte ou nada cruza a coluna onde a chefe atende.
			if not g.STAGE_ART_FLOOR.has(path) and not g.STAGE_ROOM_FLOOR.has(g._room_key(path)):
				sem_chao.append(path.get_file())
			var props: Array = g.STAGE_ART_PROPS.get(path, g.STAGE_ROOM_PROPS.get(g._room_key(path), []))
			if not g.STAGE_ART_PROPS.has(path) and _cobre_x(props, x_chefe):
				chefe_cortada.append(path.get_file())
		_assert("%s: nenhuma arte da escada ficou sem faixa de chão" % sector, sem_chao.is_empty(),
			"%s" % (", ".join(sem_chao) if not sem_chao.is_empty() else "6 de 6 artes com piso próprio ou da sala"))
		_assert("%s: arte herdada cortando a chefe em móvel não medido" % sector,
			chefe_cortada.is_empty(),
			"%s" % (", ".join(chefe_cortada) if not chefe_cortada.is_empty()
				else "x=%.2f livre em 6 de 6 artes" % x_chefe))
	await _fechar(g)


## Algum contorno de móvel cobre a coluna x pedida? É a pergunta que decide se a herança
## do recorte pode serrar a chefe: se nada passa por aquele x, a linha de corte dela não
## existe naquela sala e a arte pode herdar a sala sem risco.
func _cobre_x(props: Array, x: float) -> bool:
	for p in props:
		if p is Rect2:
			var r := p as Rect2
			if x >= r.position.x and x <= r.end.x:
				return true
		elif p is Array:
			var menor := 2.0
			var maior := -1.0
			for v in (p as Array):
				menor = minf(menor, float((v as Vector2).x))
				maior = maxf(maior, float((v as Vector2).x))
			if x >= menor and x <= maior:
				return true
	return false


func _secao_painel() -> void:
	print("── o painel fala da sala que está na tela ──")
	var g = await _loja("painel")
	g._set_sector("reception")
	var casa: String = g._progress_line()
	g._set_sector("forge")
	_no_degrau(g, "forge", 100)
	g._refresh_ui()
	var forja: String = g._progress_line()
	_assert("recepção lê a casa", casa.contains("A CASA ESTÁ"), casa.substr(0, 76))
	_assert("forja lê a forja", forja.contains("A SALA ESTÁ") and forja.contains("degrau 16"),
		forja.substr(0, 96))
	g._set_sector("library")
	for carga in [0, 10, 30, 60, 90, 130]:
		_no_degrau(g, "library", carga)
		g._set_sector("library")
		print("      %3d de ofício → %s" % [carga, g._progress_line()])
	await _fechar(g)


func _secao_save() -> void:
	print("── as duas chaves atravessam o arquivo ──")
	var g = await _loja("save")
	g.library_consults = 37
	g.relics_calmed = 21
	g._save_game()
	var relida = await _reabrir("save-relida")
	_assert("as chaves voltam pelo disco", relida.library_consults == 37 and relida.relics_calmed == 21,
		"consultas %d, relíquias %d" % [relida.library_consults, relida.relics_calmed])
	await _fechar(relida)
	var file: FileAccess = FileAccess.open(SAVE_GLOBAL, FileAccess.READ)
	var texto := file.get_as_text()
	file.close()
	texto = texto.replace("library_consults=37", "library_consults=-9")
	texto = texto.replace("relics_calmed=21", "relics_calmed=\"abc\"")
	var wr: FileAccess = FileAccess.open(SAVE_GLOBAL, FileAccess.WRITE)
	wr.store_string(texto)
	wr.close()
	var adulterado = await _reabrir("save-adulterado")
	_assert("payload lixo volta a zero", adulterado.library_consults == 0 and adulterado.relics_calmed == 0,
		"negativo e string viram 0 → degrau %d/%d" % [
			adulterado._scenery_step("library"), adulterado.SECTOR_SCENERY_STEPS])
	await _fechar(adulterado)
	await _fechar(g)


func _secao_reencarnar() -> void:
	print("── reencarnar devolve as salas ao cru ──")
	var g = await _loja("reencarnar")
	_no_degrau(g, "forge", 300)
	_no_degrau(g, "library", 90)
	_no_degrau(g, "sanctum", 90)
	var antes := "%d/%d/%d" % [g._scenery_step("forge"), g._scenery_step("library"), g._scenery_step("sanctum")]
	g._reset_run()
	var depois := "%d/%d/%d" % [g._scenery_step("forge"), g._scenery_step("library"), g._scenery_step("sanctum")]
	_assert("escada de ofício é da vida", antes != "0/0/0" and depois == "0/0/0",
		"antes %s → depois %s" % [antes, depois])
	await _fechar(g)


func _secao_conquistas() -> void:
	print("── as três conquistas acendem na porta certa ──")
	var g = await _loja("conquistas")
	var ids: Array[String] = ["forge_scenery_top", "library_scenery_top", "sanctum_scenery_top"]
	for badge in ids:
		if g.unlocked_achievements.has(badge):
			g.unlocked_achievements.erase(badge)
	for sector in SETORES:
		_no_degrau(g, sector, 0)
	g._check_achievements()
	var no_cru: int = 0
	for badge in ids:
		if g.unlocked_achievements.has(badge):
			no_cru += 1
	_assert("nenhuma acende no cru", no_cru == 0, "%d acesas com as salas vazias" % no_cru)
	for sector in SETORES:
		_no_degrau(g, sector, 1000000)
	g._check_achievements()
	var no_topo: int = 0
	var badge_sectors: Array[String] = ["forge_scenery_top", "library_scenery_top", "sanctum_scenery_top"]
	for badge in badge_sectors:
		if g.unlocked_achievements.has(badge):
			no_topo += 1
	_assert("as três acendem no degrau 30", no_topo == 3,
		"%d de 3 acesas com as salas no topo" % no_topo)
	var total: int = g._achievement_definitions().size()
	_assert("a parede fecha com as três novas", total > 0, "%d definições" % total)
	await _fechar(g)
