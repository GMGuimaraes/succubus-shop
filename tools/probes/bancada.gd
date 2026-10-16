extends SceneTree

## Sonda da bancada de ensaios (#76): prova que alquimia experimental é porta de entrada
## para a receita que o nível prende, não sorteio disfarçado de descoberta — a resposta é a
## tabela de fichas contra a mistura da mesa, nenhum `randi()` da loja é consumido pela
## bancada, e o que ela cobra é exatamente o que ela anuncia: carvão por unidade,
## ingrediente queimado e barro no salão.
##
## Medidas desta sonda: (1) com a mesa raspada nada acontece — o acender é recusado, o caixa
## e o estoque não se movem, e o botão nasce desabilitado; (2) três portas fecham a brasa:
## terceira espécie, quinta unidade e raridade do bolso (catalisador não é ingrediente de
## ensaio), e a quarta é o estoque que não tem; (3) a assinatura é a mistura, não a ordem de
## montagem — sal+pó e pó+sal são o mesmo ensaio e o mesmo preço; (4) beco riscado cobra
## carvão (12 por unidade), queima as unidades, deixa 3 de barro e 2 de experiência, e não
## toca no nível; (5) o mesmo beco não cobra duas vezes — a recusa devolve ouro e estoque
## intactos, e o botão já nasce apagado; (6) a faísca arranca a receita do nível: tinta×2 +
## essência entrega Pergaminho de Procrastinação Certificada sem subir degrau, com fama +1,
## e a prateleira dela sai de "Receita bloqueada" para botão de fabricar; (7) uma mistura pode
## entregar duas receitas — sal + pó lunar é a ficha do Elixir de Memória de Peixe e do
## Martelo de Faísca Dramática, e as duas caem na mesma faísca; (8) receita que já é sua não
## tem o que descobrir, e a forja normal continua cozinhando aquela ficha; (9) o palpite do
## grimório sobe a escada pela ordem do nível (2 → 3 → 4 → 5 → 8 → 10 → 12), tem desconto da
## biblioteca, escreve a ficha no painel do grimório e para quando não há mais o que
## sussurrar; (10) a mesa é montada nos botões da forja, e o painel lê brasa, caderno e
## acerto; (11) ler e escrever na bancada não consome sorteio: as três caudas de 40 `randi()`
## são idênticas ao controle limpo; (12) as cinco chaves atravessam o arquivo, payload lixo é
## podado, save antigo acorda com a mesa raspada, e reencarnar raspa tudo; (13) os dois selos
## novos acendem nas fronteiras e a lista fecha com 91 definições.
##
## Armadilha medida aqui: ao nível 1 cada acerto dá 12 de experiência e o degrau 2 custa 65,
## então seis acertos seguidos subiriam um nível sozinhos — e nível novo entrega receita por
## si, roubando da bancada o que se quer medir. Na seção dos selos a sonda devolve nível e XP
## ao zero a cada faísca, e imprime isso, para o "7 de 7 descobertas na bancada" significar
## bancada e não experiência.
##
## Armadilha de régua: a cauda de 40 `randi()` é sempre lida logo apos `seed(SEED_VAL)`
## cravado. Sem o segundo seed, a segunda cauda nasce na casa 80 da stream e a sonda acusaria
## "a bancada sorteia" onde a bancada só compara assinatura de dicionario. E as medidas de
## caixa selam as 91 conquistas: o primeiro acerto paga 60 de ouro e o sétimo paga 300 — sem
## a rolha, "carvão cobrado" leria o premio do selo.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/bancada.gd

const Locales = preload("res://locales.gd")
const Main = preload("res://main.gd")
const Ingredients = preload("res://ingredients.gd")

const SEED_VAL := 20261023

## Os ids que a bancada pode arrancar do nível, na ordem em que o nível os entregaria.
## Não é lista de fantasia: é a leitura do catálogo com `required_level > 1`.
const ESCADA := [
	"adaga_charme", "elixir_memoria", "martelo_faisca", "incenso_teleporte",
	"cristal_credito", "pergaminho_procrastinacao", "frasco_motivacao",
]
## Os dois nomes que a mesma ficha cobre: é o par que a bancada entrega de uma vez.
const GEMEOS := ["elixir_memoria", "martelo_faisca"]
## Receita de nível 1, sempre sua: a mesma ficha na mesa tem de virar beco, não descoberta.
const JA_SUA := "confianca_instantanea"


func _initialize() -> void:
	print("── com a mesa raspada a bancada não existe ──")
	var a = await _loja("mesa")
	_selar(a)
	a.gold = 500
	a.reputation = 20
	var ouro_a: int = a.gold
	var barro_a: int = a.mess
	var brasa_a := _unidades(a)
	a._lab_fire()
	a._refresh_ui()
	print("   acender sem brasa: caixa %d→%d • barro %d→%d • unidades %d→%d • caderno %d linha(s)" % [
		ouro_a, a.gold, barro_a, a.mess, brasa_a, _unidades(a), a.lab_trials.size()])
	print("   texto: %s" % str(a.last_event))
	print("   botão acender: \"%s\" disabled=%s • botão palpite disabled=%s" % [
		str(a.lab_fire_button.text), str(a.lab_fire_button.disabled), str(a.lab_hint_button.disabled)])
	var hint_ouro: int = a.gold
	a._lab_buy_hint()
	print("      caixa %d→%d • ficha revelada %s • alvo era %s" % [
		hint_ouro, a.gold, str(a.lab_hints), str(_nome(a, "adaga_charme"))])
	print("   painel: %s" % str(a._lab_summary()).split("\n")[0])
	await _fechar(a)

	print("── três portas fecham a brasa, e uma é o estoque ──")
	var b = await _loja("portas")
	_selar(b)
	b.gold = 2000
	for i in range(Ingredients.DATA.size()):
		b.ingredient_stock[str(Ingredients.DATA[i]["id"])] = 3
	b._lab_add("essencia")
	b._lab_add("pena")
	var Ouro_b: int = b.gold
	b._lab_add("sal")
	print("   terceira espécie (essencia+pena+sal): caixa %d→%d • mesa %d espécie(s) • %s" % [
		Ouro_b, b.gold, b.lab_mix.size(), str(b.last_event)])
	b._lab_clear()
	for i in range(Main.LAB_MAX_UNITS):
		b._lab_add("sal")
	var topo_b: int = b.gold
	b._lab_add("sal")
	print("   quinta unidade (teto %d): caixa %d→%d • mesa %d unidade(s) • %s" % [
		Main.LAB_MAX_UNITS, topo_b, b.gold, _unidades(b), str(b.last_event)])
	b._lab_clear()
	var raro_b: int = b.gold
	b._lab_add("brasa")
	print("   raridade do bolso (catalisador, não ingrediente): caixa %d→%d • mesa %d unidade(s) • %s" % [
		raro_b, b.gold, _unidades(b), str(b.last_event)])
	b._lab_clear()
	b.ingredient_stock["tinta"] = 1
	b._lab_add("tinta")
	var sede_b: int = b.gold
	b._lab_add("tinta")
	print("   estoque que não tem a segunda unidade (tinta tinha 1): caixa %d→%d • mesa %d de tinta • %s" % [
		sede_b, b.gold, int(b.lab_mix.get("tinta", 0)), str(b.last_event)])
	await _fechar(b)

	print("── a assinatura é a mistura, não a ordem da mesa ──")
	var c = await _loja("assinatura")
	_selar(c)
	c._lab_add("sal")
	c._lab_add("po_lunar")
	var primeira: String = c._lab_signature(c.lab_mix)
	c._lab_clear()
	c._lab_add("po_lunar")
	c._lab_add("sal")
	var segunda: String = c._lab_signature(c.lab_mix)
	print("   sal→pó: \"%s\" • pó→sal: \"%s\" • igual: %s • legível: %s" % [
		primeira, segunda, str(primeira == segunda), c._lab_readable(segunda)])
	print("   carvão de 2 unidades: %d • de 3: %d • de 4: %d" % [
		c._lab_fee(2), c._lab_fee(3), c._lab_fee(4)])
	print("   escada medida no catálogo (required_level > 1): %d ficha(s) • a sonda esperava %d" % [
		c._lab_targets_total(), ESCADA.size()])
	await _fechar(c)

	print("── beco riscado cobra carvão, queima unidade e deixa barro ──")
	var d = await _loja("beco")
	_selar(d)
	d.gold = 1000
	d.reputation = 20
	d.mess = 0
	d.player_level = 1
	d.player_xp = 0
	d._lab_add("essencia")
	d._lab_add("sal")
	var ouro_d: int = d.gold
	var essencia_d := int(d.ingredient_stock["essencia"])
	var sal_d := int(d.ingredient_stock["sal"])
	var xp_d: int = d.player_xp
	d._lab_fire()
	print("   %s: caixa %d→%d (−%d de carvão) • essência %d→%d • sal %d→%d • barro %d→%d" % [
		d._lab_readable(d._lab_signature({"essencia": 1, "sal": 1})),
		ouro_d, d.gold, ouro_d - d.gold, essencia_d, int(d.ingredient_stock["essencia"]),
		sal_d, int(d.ingredient_stock["sal"]), d.mess - Main.LAB_FIZZLE_MESS, d.mess])
	print("   caderno: %d beco(s) • experiência %d→%d (+%d) • nível %d→%d (tem de continuar %d)" % [
		d.lab_flops, xp_d, d.player_xp, d.player_xp - xp_d, 1, d.player_level, 1])
	print("   mesa esvaziada: %d unidade(s) • texto: %s" % [_unidades(d), str(d.last_event)])
	print("   nada travado foi descoberto: lab_discovered %d • known_recipes %d" % [
		d.lab_discovered.size(), d.known_recipes.size()])
	var ouro_d2: int = d.gold
	var essencia_d2 := int(d.ingredient_stock["essencia"])
	var barro_d2: int = d.mess
	d._lab_add("essencia")
	d._lab_add("sal")
	d._lab_fire()
	print("── o mesmo beco não cobra duas vezes ──")
	print("   segunda faísca no mesmo punhado: caixa %d→%d • essência %d→%d • barro %d→%d • becos %d→%d" % [
		ouro_d2, d.gold, essencia_d2, int(d.ingredient_stock["essencia"]),
		barro_d2, d.mess, d.lab_flops, d.lab_flops])
	print("   texto: %s" % str(d.last_event))
	d._refresh_ui()
	print("   depois do _refresh_ui: disabled=%s • texto \"%s\"" % [
		str(d.lab_fire_button.disabled), str(d.lab_fire_button.text)])
	await _fechar(d)

	print("── a faísca arranca a receita do nível ──")
	var e = await _loja("faisca")
	_selar(e)
	e.gold = 1000
	e.reputation = 20
	e.player_level = 1
	e.player_xp = 0
	for ficha in ["tinta", "essencia"]:
		e.ingredient_stock[ficha] = 4
	var label_antes := _texto_prateleira(e, "pergaminho_procrastinacao")
	var ouro_e: int = e.gold
	var fama_e: int = e.reputation
	var travadas_e: int = e._lab_locked_ids().size()
	e._lab_add("essencia")
	e._lab_add("tinta")
	e._lab_add("tinta")
	e._lab_fire()
	print("   tinta×2 + essência: caixa %d→%d (−%d) • fama %d→%d • travadas %d→%d" % [
		ouro_e, e.gold, ouro_e - e.gold, fama_e, e.reputation, travadas_e, e._lab_locked_ids().size()])
	print("   texto: %s" % str(e.last_event))
	print("   known_recipes: %s • lab_discovered: %s • unlocked pelo jogo: %s" % [
		str(e.known_recipes), str(e.lab_discovered),
		str(e._is_product_unlocked(e._product_by_id("pergaminho_procrastinacao")))])
	print("   nível continua 1 (tem de ser 1): %d • xp %d" % [e.player_level, e.player_xp])
	e._refresh_ui()
	print("   prateleira antes: \"%s\"" % label_antes)
	print("   prateleira depois: \"%s\"" % _texto_prateleira(e, "pergaminho_procrastinacao"))
	print("   caderno lê o acerto: %s" % str(e._lab_trial_line("essencia:1+tinta:2")))
	await _fechar(e)

	print("── uma mistura, duas receitas ──")
	var f = await _loja("gemeos")
	_selar(f)
	f.gold = 1000
	f.player_level = 1
	f.player_xp = 0
	f.ingredient_stock["sal"] = 3
	f.ingredient_stock["po_lunar"] = 3
	f._lab_add("sal")
	f._lab_add("po_lunar")
	f._lab_fire()
	var nomes: Array[String] = []
	for id in GEMEOS:
		nomes.append("%s=%s" % [id, str(f.known_recipes.has(id))])
	print("   sal + pó lunar: descobertos %d • %s" % [f.lab_discovered.size(), ", ".join(nomes)])
	print("   caderno: %s" % f._lab_trial_line("po_lunar:1+sal:1"))
	print("   travadas que sobraram: %d (a escada tinha %d)" % [
		f._lab_locked_ids().size(), f._lab_targets_total()])
	await _fechar(f)

	print("── receita que já é sua não tem o que descobrir ──")
	var g = await _loja("jasua")
	_selar(g)
	g.gold = 1000
	g.player_level = 1
	g.ingredient_stock["essencia"] = 4
	g.ingredient_stock["tinta"] = 4
	var ficha_sua: String = g._lab_signature(g._product_by_id(JA_SUA).get("ingredients", {}))
	g._lab_add("essencia")
	g._lab_add("tinta")
	g._lab_fire()
	print("   ficha da %s na mesa (%s): vira %s" % [
		str(g._product_by_id(JA_SUA)["name"]), ficha_sua,
		"beco riscado" if str(g.lab_trials.get(ficha_sua, "x")).is_empty() else "DESCOBERTA (inaceitável)"])
	print("   descobertos: %d • becos: %d • texto: %s" % [g.lab_discovered.size(), g.lab_flops, str(g.last_event)])
	g.ingredient_stock["essencia"] = 3
	g.products[_index(g, JA_SUA)]["stock"] = 0
	var ouro_g := int(g.products[_index(g, JA_SUA)]["stock"])
	g._craft_product(_index(g, JA_SUA))
	print("   a forja normal continua cozinhando essa ficha: estoque %d→%d • %s" % [
		ouro_g, int(g.products[_index(g, JA_SUA)]["stock"]), str(g.last_event).split("\n")[0]])
	await _fechar(g)

	print("── o palpite sobe a escada do grimório ──")
	var h = await _loja("palpite")
	_selar(h)
	h.gold = 4000
	h.player_level = 1
	h.player_xp = 0
	print("   custo na biblioteca 0: %d • na 1: %d • na 5 (piso 20): %d" % [
		h._lab_hint_cost(), roundi(float(Main.LAB_HINT_COST) * 0.9),
		maxi(20, int(round(float(Main.LAB_HINT_COST) * (1.0 - 0.5))))])
	for passo in range(ESCADA.size()):
		var alvo: String = h._lab_hint_target()
		var custo: int = h._lab_hint_cost()
		var ouro_h: int = h.gold
		h._lab_buy_hint()
		print("   palpite %d: alvo %s (nível %d) −%d de ouro • ficha no painel: %s" % [
			passo + 1, _nome(h, alvo),
			int(h._product_by_id(alvo).get("required_level", 1)), ouro_h - h.gold,
			str(h.recipe_labels[_index(h, alvo)].text).contains("ficha do palpite")])
		h._refresh_ui()
	print("   escada revelada: %s" % str(h.lab_hints))
	var ouro_h2: int = h.gold
	h._lab_buy_hint()
	h._refresh_ui()
	print("   oitava ficha: caixa %d→%d (tem de ser igual) • texto: %s" % [
		ouro_h2, h.gold, str(h.last_event)])
	print("   botão: \"%s\" disabled=%s" % [str(h.lab_hint_button.text), str(h.lab_hint_button.disabled)])
	print("   palpite não descobre receita: known_recipes %d • discovered %d" % [
		h.known_recipes.size(), h.lab_discovered.size()])
	await _fechar(h)

	print("── a mesa é montada nos botões da forja ──")
	var i = await _loja("botoes")
	_selar(i)
	i.gold = 1000
	i.player_level = 1
	i.player_xp = 0
	i.ingredient_stock["tinta"] = 4
	i.ingredient_stock["essencia"] = 4
	for botao in i.lab_add_buttons:
		if str(botao.text).contains("Tinta"):
			botao.emit_signal("pressed")
			botao.emit_signal("pressed")
	for botao in i.lab_add_buttons:
		if str(botao.text).contains("Essência"):
			botao.emit_signal("pressed")
	i._refresh_ui()
	print("   botões de adding: %s" % _rotulos(i.lab_add_buttons))
	print("   acender pelo botão: \"%s\" disabled=%s" % [str(i.lab_fire_button.text), str(i.lab_fire_button.disabled)])
	i.lab_fire_button.emit_signal("pressed")
	i._refresh_ui()
	print("   painel depois da faísca:")
	for linha in str(i.lab_label.text).split("\n"):
		print("      | %s" % linha)
	await _fechar(i)

	print("── ler e escrever na bancada não sorteia nada ──")
	var k = await _loja("cauda")
	_selar(k)
	k.gold = 4000
	k.player_level = 1
	k.ingredient_stock["tinta"] = 6
	k.ingredient_stock["essencia"] = 6
	k.ingredient_stock["sal"] = 6
	seed(SEED_VAL)
	var controle := _cauda(40)
	seed(SEED_VAL)
	k._lab_add("essencia")
	k._lab_add("tinta")
	k._lab_add("tinta")
	k._lab_fire()
	k._lab_buy_hint()
	k._lab_add("sal")
	k._lab_add("sal")
	k._lab_fire()
	var com_bancada := _cauda(40)
	seed(SEED_VAL)
	k._refresh_ui()
	k._lab_summary()
	k._lab_trial_line("essencia:1+tinta:2")
	k._lab_clear()
	var so_painel := _cauda(40)
	seed(SEED_VAL)
	k._save_game()
	var relida_store = await _reload("cauda-relida")
	seed(SEED_VAL)
	var depois_relida := _cauda(40)
	print("   2 faíscas + 1 palpite + esvaziar: cauda igual ao controle? %s" % str(controle == com_bancada))
	print("   ler painel e resumo: cauda igual? %s" % str(controle == so_painel))
	print("   salvar e reler a loja: cauda igual? %s" % str(controle == depois_relida))
	await _fechar(k)
	await _fechar(relida_store)

	print("── as cinco chaves atravessam o arquivo ──")
	var m = await _loja("arquivo")
	_blindar(m)
	m.gold = 1500
	m.player_level = 1
	m.ingredient_stock["tinta"] = 5
	m.ingredient_stock["essencia"] = 5
	m._lab_add("essencia")
	m._lab_add("tinta")
	m._lab_fire()
	m._lab_add("tinta")
	m._lab_buy_hint()
	m._lab_add("sal")
	m._lab_add("sal")
	var salvo_mix := _lab_mix_texto(m)
	m._save_game()
	await _frames(2)
	await _fechar(m)
	var r = await _reload("arquivo-relido")
	await _frames(2)
	print("   relido: beco(s) %d • descoberto(s) %d • ficha(s) %s • mesa %s" % [
		r.lab_flops, r.lab_discovered.size(), str(r.lab_hints), _lab_mix_texto(r)])
	print("   a mesa em brasa voltou com a mistura salva (%s == %s): %s" % [
		salvo_mix, _lab_mix_texto(r), str(salvo_mix == _lab_mix_texto(r))])
	print("   caderno relido: %s" % str(r._lab_trial_line("essencia:1+tinta:2")))
	await _fechar(r)

	print("── payload lixo e save antigo acordam com a mesa raspada ──")
	_escrever_chave("lab_trials", '{ "essencia:99": "receita_inventada", "sal:1": "elixir_memoria", "inutil": "frasco_motivacao", "tinta:1+essencia:1": "", "pena:1": 7 }')
	_escrever_chave("lab_hints", '["elixir_memoria", "elixir_memoria", "dano_emocional", "nao_existe", "frasco_motivacao"]')
	_escrever_chave("lab_discovered", '["po_lunar_receita", "cristal_credito", "cristal_credito"]')
	_escrever_chave("lab_flops", "-4")
	_escrever_chave("lab_mix", '{"tinta": 99, "essencia": 3, "sal": 2, "pena": 1}')
	var s = await _reload("lixo")
	await _frames(2)
	print("   5 entradas de caderno viram %d: %s" % [s.lab_trials.size(), str(s.lab_trials)])
	print("   hinted: %s • discovered: %s • becos: %d (negativo vira 0)" % [
		str(s.lab_hints), str(s.lab_discovered), s.lab_flops])
	print("   mesa podada (teto %d unidades, %d espécies, estoque %d de tinta): %s" % [
		Main.LAB_MAX_UNITS, Main.LAB_MAX_KINDS, int(s.ingredient_stock["tinta"]), str(s.lab_mix)])
	print("   acender com a mesa podada: %s" % str(s._lab_signature_valid(s._lab_signature(s.lab_mix))))
	await _fechar(s)
	_apagar_chaves()
	var u = await _reload("antigo")
	await _frames(2)
	print("   sem as chaves no arquivo: becos %d • descobertos %d • fichas %d • mesa %d unidade(s)" % [
		u.lab_flops, u.lab_discovered.size(), u.lab_hints.size(), _unidades(u)])
	var ouro_u: int = u.gold
	u._lab_fire()
	print("   virada imediata: caixa %d→%d (tem de ser igual) • acender recusa: %s" % [
		ouro_u, u.gold, str(not str(u.last_event).contains("ACERTO"))])
	await _fechar(u)

	print("── reencarnar raspa a mesa e o caderno ──")
	var v = await _loja("reencarnar")
	_blindar(v)
	v.gold = 1500
	v.player_level = 1
	v.ingredient_stock["sal"] = 4
	v.ingredient_stock["po_lunar"] = 4
	v._lab_add("sal")
	v._lab_add("po_lunar")
	v._lab_fire()
	v._lab_add("sal")
	v._lab_buy_hint()
	print("   vida com bancada usada: becos %d • descobertos %d • fichas %d • mesa %d" % [
		v.lab_flops, v.lab_discovered.size(), v.lab_hints.size(), _unidades(v)])
	v._reset_run()
	print("   vida nova: becos %d • descobertos %d • fichas %d • caderno %d • mesa %d" % [
		v.lab_flops, v.lab_discovered.size(), v.lab_hints.size(), v.lab_trials.size(), _unidades(v)])
	print("   receita descoberta na vida velha voltou a estar presa: %s" % str(
		not v._is_product_unlocked(v._product_by_id("elixir_memoria"))))
	await _fechar(v)

	print("── os dois selos novos acendem na fronteira ──")
	var w = await _loja("selos")
	w.gold = 4000
	w.player_level = 1
	w.player_xp = 0
	for ficha in ["tinta", "essencia", "sal", "po_lunar", "pena", "vazio"]:
		w.ingredient_stock[ficha] = 9
	var seis := [
		{"pena": 1, "tinta": 1},
		{"sal": 1, "po_lunar": 1},
		{"po_lunar": 1, "tinta": 1},
		{"tinta": 2, "vazio": 1},
		{"tinta": 2, "essencia": 1},
		{"po_lunar": 2, "sal": 1},
	]
	for passo in range(seis.size()):
		w.player_level = 1
		w.player_xp = 0
		for ficha in seis[passo]:
			for unidade in range(int(seis[passo][ficha])):
				w._lab_add(str(ficha))
		w._lab_fire()
		var tem_primeiro: bool = w.unlocked_achievements.has("lab_first_spark")
		var tem_cheia: bool = w.unlocked_achievements.has("lab_full_bench")
		print("   faísca %d: descobertos %d • primeira faísca %s • bancada venceu o nível %s" % [
			passo + 1, w.lab_discovered.size(), str(tem_primeiro), str(tem_cheia)])
	print("   escada zerada na bancada: %d de %d • travadas sobrando %d" % [
		w.lab_discovered.size(), w._lab_targets_total(), w._lab_locked_ids().size()])
	var definicoes := 0
	for definition in w._achievement_definitions():
		definicoes += 1
	print("   painel de conquistas: %d definições • os dois selos estão entre elas: %s" % [
		definicoes, str(_tem_conquista(w, "lab_first_spark") and _tem_conquista(w, "lab_full_bench"))])
	await _fechar(w)

	print("VEREDITO: mesa raspada não cobra, beco riscado não cobra duas vezes, a resposta é" \
		+ " a ficha da receita contra a mistura (nunca o sorteio), nível 1 continua nível 1" \
		+ " depois do acerto, e o que a bancada entrega é receita travada sem degrau de" \
		+ " experiência. Ouro mudando sem brasa, descoberta nascendo de sorteio, beco" \
		+ " repetido cobrando de novo ou um acerto subindo nível é a bancada virando roleta" \
		+ " — e roleta não é progressão.")
	quit()


## ── ferramentas ────────────────────────────────────────────────────────────────────

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


func _fixar_locale(g) -> void:
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)


## Só os selos: é o que as medidas de caixa precisam. O nível fica onde a sonda pôs, porque
## ao contrário do fiado aqui o nível É a porta que a bancada arranca.
func _selar(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)
	g.player_xp = 0


## Selos + as fichas dos fregueses: para as seções que não mexem no balcão é a mesma rolha
## do fiado, escrita aqui sem depender do outro arquivo.
func _blindar(g) -> void:
	_selar(g)
	g.player_level = 60


func _tem_conquista(g, badge_id: String) -> bool:
	for achievement in g._achievement_definitions():
		if str(achievement["id"]) == badge_id:
			return true
	return false


func _unidades(g) -> int:
	return g._lab_units(g.lab_mix)


## O rótulo que a prateleira da forja mostra para um produto: é assim que a sonda prova que
## a receita saiu de "bloqueada" sem depender de clique.
func _texto_prateleira(g, product_id: String) -> String:
	g._refresh_ui()
	return str(g.product_labels[_index(g, product_id)].text)


func _index(g, product_id: String) -> int:
	return g._product_index(product_id)


func _nome(g, product_id: String) -> String:
	return str(g._product_by_id(product_id).get("name", product_id))


func _rotulos(botoes: Array) -> String:
	var partes: Array[String] = []
	for botao in botoes:
		partes.append(str(botao.text))
	return " | ".join(partes)


## A mesa em brasa como texto comparável entre o antes e o depois do arquivo.
func _lab_mix_texto(g) -> String:
	return g._lab_signature(g.lab_mix)


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


## Tira as cinco chaves da bancada: é o save antigo, escrito antes de a mesa existir.
func _apagar_chaves() -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	for chave in ["lab_trials", "lab_mix", "lab_hints", "lab_discovered", "lab_flops"]:
		var linha := texto.find("\n%s=" % chave)
		if linha < 0:
			continue
		var fim := texto.find("\n", linha + 1)
		if fim < 0:
			fim = texto.length()
		texto = texto.substr(0, linha) + texto.substr(fim)
	var file := FileAccess.open(caminho, FileAccess.WRITE)
	file.store_string(texto)
	file.close()


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
