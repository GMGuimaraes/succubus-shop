extends SceneTree

## Sonda da regra da casa (#74): prova que dificuldade não é enfeite de menu — cada fator
## é consumido no lugar onde o jogo já media aquela grandeza, o Calçada é identidade pura
## (nenhuma medida antiga se move), e a aura é paga pelos dias efetivamente morados na
## regra, não pelo botão batido na hora de reencarnar.
##
## Medidas desta sonda: (1) etiqueta, conta da casa e os dois limiares da rua nos três
## modos com o mesmo estado; (2) o Calçada bate com o número pré-feature (conta 12 de loja
## nova) e id fantasma cai nele; (3) ler as funções de chance não consome sorteio: a mesma
## semente dá a mesma cauda de 40 valores nos três modos e igual ao controle limpo;
## (4) o caderno de dias cresce um por virada na fila de verdade, e a aura é a média
## ponderada dos dias morados; (5) `_reincarnate()` deposita no cofre a aura multiplicada;
## (6) o painel e o botão lêem regra, fatores e dias; (7) as duas chaves atravessam o
## arquivo, id fantasma e dia negativo são sumidos, save antigo acorda no Calçada com o
## caderno vazio; (8) o selo do Poço acende no décimo dia, não no nono, e a lista fechava com
## 91 definições nesta leitura (o par do livro de fiado, #75, o par da bancada de ensaios,
## #76, o par do salão das capas finas, #78, o par do livro de reclamações, #79, e o par do
## cartaz do combo, #80, entraram depois; a sonda lê o tamanho real da lista, não este número,
## e hoje ela fecha em 97).
##
## Armadilha medida nesta sonda: `business_score()` soma 1200 pontos quando o império está
## fechado, então a pontuação tem de ser lida DEPOIS de ligar `game_completed`. Medindo
## antes, a régua esperava +20 de um cofre que pagava +23 — o desvio era da sonda, e é
## exatamente o tipo de número que vira "regressão" no papel.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/dificuldade.gd
##
## Veredito medido nesta rodada: a mesma loja, o mesmo dia e o mesmo barro mudam de regra só
## de bolso — etiqueta Mítica do cristal 287 → 258 → 230 (Calçada → Juro Alto → Poço Sem
## Fundo), conta da casa 12 → 16 → 22, vândalo com barro 20 e fama 0 em 11 → 17 → 22 e
## invasão no dia 60 com três portas seguras em 6 → 9 → 12; no barro 400 os três modos batem
## no mesmo teto de 40, que é o teto antigo da rua. O Calçada é identidade pura: 12 de conta,
## 287 de etiqueta, 11 de vândalo e os quatro fatores lidos ×1.00, e um id fora da tabela
## ("modo_fantasma") cai nele em vez de ler índice morto. Ler a chance não gasta sorteio: com
## a semente 20261017 fixada, a cauda de 40 `randi()` dos três modos é byte a byte igual ao
## controle limpo — a regra muda a parede onde o número bate, nunca o número. Na fila de
## verdade, 60 tiques no Poço viram 3 dias de caderno (aura ×2.500) e +40 tiques no Calçada
## viram {poco 3, calcada 2}: média ponderada esperada 1.900, medida 1.900, enquanto a
## etiqueta continua seguindo a regra de HOJE (287 → 230) e não a média da vida. Vida de
## 10845 pontos: tabela 9, Calçada 9, meia vida no Poço 16, vida inteira 23 — e o
## `_reincarnate()` de verdade depositou exatamente 23 no cofre (0 → 23), com a regra
## atravessando a vida e o caderno voltando ao zero. Painel: "REGRA DA CASA: Juro Alto —
## etiqueta ×0.90, conta ×1.30, rua ×1.50, aura ×1.99 • dias morados: Juro Alto 4, Poço Sem
## Fundo 3", e o botão gira Juro Alto ▶ → Poço Sem Fundo ▶ já valendo no mesmo clique (conta
## 22, etiqueta 230). Save: as duas chaves voltam como poco_sem_fundo com {calcada: 2,
## poco_sem_fundo: 7}, ouro 3210 e aura ×2.167; payload lixo (id fantasma, dia −4, dia 0)
## sobra só em {juro_alto: 6} e acorda no Calçada; sem as chaves no arquivo a loja abre no
## Calçada com caderno vazio e aura ×1.00. O selo *Poço Sem Fundo por 10 dias de balcão* não
## acende no nono dia e acende no décimo, e o painel fecha com 97 definições. Se qualquer
## linha do Calçada se mover, a regra nova virou regressão nas contas de sempre; se a aura
## pagar dia não morado, ela virou enfeite de botão.

const Locales = preload("res://locales.gd")
const Prestige = preload("res://prestige.gd")

const SEED_VAL := 20261017
## Cristal de Crédito Cósmico: o preço de tabela mais alto sem validade — a etiqueta é
## lida limpa, sem a despensa no meio.
const VIDRINE := 7
const CALCADA := "calcada"
const JURO := "juro_alto"
const POCO := "poco_sem_fundo"


func _initialize() -> void:
	print("── a regra cobra etiqueta, conta e rua onde já eram medidos ──")
	var a = await _loja("tabela")
	var etiquetas: Array[String] = []
	var contas: Array[String] = []
	var vandais: Array[String] = []
	var invasoes: Array[String] = []
	for id in [CALCADA, JURO, POCO]:
		a.difficulty = str(id)
		a.mess = 20
		a.reputation = 0
		a.shop_day = 60
		a.invasions_repelled = 3
		a.gold = 1200
		etiquetas.append("%s %d" % [str(a._difficulty_row(str(id))["name"]), int(a._piece_price(a.products[VIDRINE], 4))])
		contas.append("%s %d" % [str(a._difficulty_row(str(id))["name"]), a._daily_upkeep()])
		vandais.append("%s %d" % [str(a._difficulty_row(str(id))["name"]), a._vandal_chance()])
		invasoes.append("%s %d" % [str(a._difficulty_row(str(id))["name"]), a._invasion_chance()])
	print("   etiqueta Mítica do cristal: %s" % " • ".join(etiquetas))
	print("   conta da casa (loja nova): %s" % " • ".join(contas))
	print("   vândalo com barro 20 e fama 0: %s" % " • ".join(vandais))
	print("   invasão no dia 60 com 3 portas seguras: %s" % " • ".join(invasoes))
	a.mess = 400
	var tetos: Array[String] = []
	for id in [CALCADA, JURO, POCO]:
		a.difficulty = str(id)
		tetos.append("%s %d" % [str(id), a._vandal_chance()])
	print("   barro 400 (o teto do beco continua teto): %s" % " • ".join(tetos))
	await _fechar(a)

	print("── o Calçada é identidade, e id fora da tabela cai nele ──")
	var b = await _loja("identidade")
	var conta_calcada: int = b._daily_upkeep()
	var etiqueta_calcada: int = int(b._piece_price(b.products[VIDRINE], 4))
	b.mess = 20
	b.reputation = 0
	var chance_calcada: int = b._vandal_chance()
	var etiqueta_fantasma := 0
	var conta_fantasma := 0
	var chance_fantasma := 0
	b.difficulty = "modo_que_nao_existe"
	conta_fantasma = b._daily_upkeep()
	etiqueta_fantasma = int(b._piece_price(b.products[VIDRINE], 4))
	chance_fantasma = b._vandal_chance()
	print("   calçada: conta %d • etiqueta %d • vândalo %d" % [conta_calcada, etiqueta_calcada, chance_calcada])
	print("   id fantasma: conta %d • etiqueta %d • vândalo %d (tem de bater em cima)" % [
		conta_fantasma, etiqueta_fantasma, chance_fantasma])
	print("   fator lido no calçada: etiqueta ×%.2f • conta ×%.2f • rua ×%.2f • aura ×%.2f" % [
		b._difficulty_price_factor(), b._difficulty_upkeep_factor(), b._difficulty_risk_factor(),
		b._difficulty_aura_factor()])
	print("   regra em uso depois do lixo: %s" % str(b._difficulty_row()["name"]))
	await _fechar(b)

	print("── a regra muda o limiar, não o sorteio ──")
	var controle = await _loja("controle")
	seed(SEED_VAL)
	var cauda_controle := _cauda(40)
	for id in [CALCADA, JURO, POCO]:
		controle.difficulty = str(id)
		controle.mess = 20
		controle.reputation = 0
		controle.shop_day = 60
		seed(SEED_VAL)
		for leitura in range(20):
			controle._vandal_chance()
			controle._invasion_chance()
			controle._difficulty_price_factor()
			controle._difficulty_upkeep_factor()
			controle._difficulty_aura_factor()
		var cauda := _cauda(40)
		print("   %s: 20 leituras de chance e a cauda é igual ao controle limpo? %s" % [
			str(id), str(cauda == cauda_controle)])
	await _fechar(controle)

	print("── o caderno de dias é o que prova a regra ──")
	var d = await _loja("caderno")
	d.difficulty = POCO
	d.gold = 4000
	for tick in range(60):
		d._on_customer_tick()
	var so_poco: float = d._difficulty_aura_factor()
	print("   60 tiques no Poço = %d dia(s) • caderno %s • aura ×%.3f" % [
		int(d.difficulty_days.get(POCO, 0)), str(d.difficulty_days), so_poco])
	d.difficulty = CALCADA
	for tick in range(40):
		d._on_customer_tick()
	print("   +40 tiques no Calçada: caderno %s" % str(d.difficulty_days))
	var esperado := (3.0 * 2.5 + 2.0 * 1.0) / 5.0
	print("   média dos dias morados: esperado %.3f • medido %.3f" % [esperado, d._difficulty_aura_factor()])
	var etiqueta_calcada_agora := int(d._piece_price(d.products[VIDRINE], 4))
	d.difficulty = POCO
	var etiqueta_poco_agora := int(d._piece_price(d.products[VIDRINE], 4))
	print("   etiqueta segue a regra de HOJE, não a média do caderno: %d → %d" % [
		etiqueta_calcada_agora, etiqueta_poco_agora])
	await _fechar(d)

	print("── o cofre paga a regra vivida ──")
	var e = await _loja("cofre")
	e.gold = 9000
	e.reputation = 30
	e.game_completed = true
	# A pontuação lê o império fechado, então a vida precisa estar fechada ANTES de
	# medir: com game_completed desligado o esperado sai 1200 pontos mais baixo e a
	# conta bate +20 contra um cofre que pagou +23 — erro da régua, não do jogo.
	var pontos: int = e.business_score()
	var tabela := Prestige.aura_for(pontos)
	e.difficulty = POCO
	e.difficulty_days = {POCO: 20}
	var ganho_poco: int = e._aura_gain(pontos)
	e.difficulty_days = {POCO: 10, CALCADA: 10}
	var ganho_meio: int = e._aura_gain(pontos)
	e.difficulty_days = {CALCADA: 20}
	e.difficulty = CALCADA
	var ganho_calcada: int = e._aura_gain(pontos)
	print("   vida de %d pontos: tabela %d • calçada %d • meia vida no Poço %d • vida inteira no Poço %d" % [
		pontos, tabela, ganho_calcada, ganho_meio, ganho_poco])
	e.difficulty = POCO
	e.difficulty_days = {POCO: 20}
	var aura_antes: int = e.prestige_aura
	var esperado_cofre: int = e._aura_gain(e.business_score())
	e._reincarnate()
	print("   reencarnar de verdade no Poço: cofre %d → %d (+%d, esperado +%d, mesma régua de vida inteira: %s)" % [
		aura_antes, e.prestige_aura, e.prestige_aura - aura_antes, esperado_cofre,
		str(e.prestige_aura - aura_antes == esperado_cofre and esperado_cofre == ganho_poco)])
	print("   vida nova: regra %s continua • caderno %s (os dias voltam ao zero)" % [
		e.difficulty, str(e.difficulty_days)])
	await _fechar(e)

	print("── o painel diz a regra, os fatores e os dias ──")
	var f = await _loja("painel")
	f.difficulty = JURO
	f.difficulty_days = {JURO: 4, POCO: 3}
	f._refresh_ui()
	print("   %s" % f._difficulty_summary().replace("\n", " / "))
	var botao_antes := str(f.difficulty_button.text)
	f._cycle_difficulty()
	print("   botão: %s → %s" % [botao_antes, str(f.difficulty_button.text)])
	print("   a troca vale desde já: regra %s • conta %d • etiqueta %d" % [
		str(f._difficulty_row()["name"]), f._daily_upkeep(), int(f._piece_price(f.products[VIDRINE], 4))])
	await _fechar(f)

	print("── as duas chaves atravessam o arquivo ──")
	var g = await _loja("save")
	g.difficulty = POCO
	g.difficulty_days = {POCO: 7, CALCADA: 2}
	g.gold = 3210
	g._save_game()
	var h = await _reload("relido")
	print("   relido: regra %s • caderno %s • ouro %d • aura ×%.3f" % [
		h.difficulty, str(h.difficulty_days), h.gold, h._difficulty_aura_factor()])
	await _fechar(h)

	print("── payload lixo e save antigo acordam no calçada ──")
	var lixo = await _loja("lixo")
	lixo.difficulty = POCO
	lixo.difficulty_days = {POCO: 5}
	lixo._save_game()
	_escrever_chave("difficulty", "\"modo_fantasma\"")
	_escrever_chave("difficulty_days", "{\"calcada\": -4, \"juro_alto\": 6, \"modo_fantasma\": 9, \"poco_sem_fundo\": 0}")
	var i = await _reload("podado")
	print("   id fantasma + dia negativo + dia zero: regra %s • caderno %s (só juro_alto 6 sobra)" % [
		i.difficulty, str(i.difficulty_days)])
	await _fechar(i)
	_apagar_chaves()
	var j = await _reload("antigo")
	print("   sem as chaves no arquivo: regra %s • caderno %s • aura ×%.2f" % [
		j.difficulty, str(j.difficulty_days), j._difficulty_aura_factor()])
	await _fechar(j)
	await _fechar(lixo)

	print("── dez dias de Poço valem o selo da casa ──")
	var k = await _loja("selo")
	k.difficulty = POCO
	k.gold = 4000
	for tick in range(180):
		k._on_customer_tick()
	k._check_achievements()
	print("   9 dias: selo %s (esperado false)" % str(k.unlocked_achievements.has("poco_atravessado")))
	for tick in range(20):
		k._on_customer_tick()
	k._check_achievements()
	print("   10 dias: selo %s • caderno %s" % [
		str(k.unlocked_achievements.has("poco_atravessado")), str(k.difficulty_days)])
	var definicoes := 0
	for definition in k._achievement_definitions():
		definicoes += 1
	print("   painel de conquistas: %d definições • o selo do poço está entre elas: %s" % [
		definicoes, str(_tem_conquista(k, "poco_atravessado"))])
	await _fechar(k)

	print("VEREDITO: o Calçada tem de bater com o número pré-feature em etiqueta, conta e rua, e id fora da tabela tem de cair nele; ler chance não pode mover um sorteio; o caderno tem de crescer um por virada e pagar a média ponderada dos dias morados; dia negativo e modo fantasma somem do carregamento sem estourar índice. Calçada mexido é a regra virar regressão, e aura paga por dia não morado é a regra virar enfeite.")
	quit()


## Quarenta valores da sorte, costurados em string para comparar trilha a trilha.
func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto):
		partes.append(str(randi() % 1000))
	return ",".join(partes)


## Reescreve uma chave do save descartável no disco, sem passar pelo jogo: é assim que se
## testa o carregamento de um payload que o próprio jogo nunca produziria.
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


## Tira as duas chaves do arquivo: é o save antigo, escrito antes de a regra existir.
func _apagar_chaves() -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	for chave in ["difficulty", "difficulty_days"]:
		var linha := texto.find("%s=" % chave)
		if linha < 0:
			continue
		var fim := texto.find("\n", linha)
		if fim < 0:
			fim = texto.length()
		texto = texto.substr(0, linha) + texto.substr(fim)
	var file := FileAccess.open(caminho, FileAccess.WRITE)
	file.store_string(texto)
	file.close()


## Loja recém-instalada com o save descartável apagado, relógio do mundo parado, idioma
## travado, semente cravada e vida resetada: o chão de onde toda medida aqui parte.
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


## A preferência de idioma mora em `user://locale_settings.cfg` e sobrevive ao
## `_reset_run()`: sem travar aqui uma rodada anterior do seletor deixa o painel noutra
## língua e a sonda lê o texto de outra loja.
func _fixar_locale(g) -> void:
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)


func _tem_conquista(g, badge_id: String) -> bool:
	for achievement in g._achievement_definitions():
		if str(achievement["id"]) == badge_id:
			return true
	return false


func _caminho_save() -> String:
	return ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"


func _apagar_save() -> void:
	var caminho: String = _caminho_save()
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
