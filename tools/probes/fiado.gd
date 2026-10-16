extends SceneTree

## Sonda do livro de fiado (#75): prova que vender a crédito não é texto de painel — a
## nota nasce no ponto exato onde a venda se perdia, nenhum sorteio novo é sorteado pelo
## livro, a cobrança mora no bolso que a visita já tinha trazido, e o ouro emprestado fica
## FORA do caixa e FORA do balanço do dia — e entra em ambos no dia em que a casa recebe.
## Degrau zero é identidade: com a gaveta fechada nenhuma medida antiga se move.
##
## Medidas desta sonda: (1) com o degrau zero, `_can_lend` mente fechado, a virada não tem
## linha de fiado e a visita sem bolso sai como sempre saiu (fama −1, disappointed +1,
## caixa parado); (2) no degrau 1 a MESMA visita leva a MESMA peça e o caixa não vê um ouro:
## a nota entra no livro com o preço honesto da peça, o prazo do degrau e o registro da
## prateleira abatendo uma peça, e o balanço do dia fecha em 0 — nem a meta de ouro do dia
## vê o que a rua levou; o recibo do fiado ainda precisa continuar no mural quando a loja
## reformada avisa da faixa nova por cima dele; (3) quitar não reempresta no mesmo balcão —
## sem essa tranca a casa giraria o próprio ouro; (4) o pedido pessoal é a segunda porta:
## quem veio pela peça que a casa tem e não chega nela leva o pedido no livro, e no degrau
## zero a mesma visita não tem porta nenhuma; (5) juro só existe para quem atrasou, quem tem
## bolso menor que a nota não é cobrado, e o ouro cobrado entra no balanço do dia da
## cobrança; (6) a riscada é no terceiro dia de atraso, com fama −2 e vínculo −1, e nos dois
## primeiros o livro só marca; (7) teto por nota, uma nota por nome e lotação do livro barram
## a gaveta; (8) ler e escrever no livro não consome sorteio: a mesma semente dá a mesma
## cauda de 40 valores do controle limpo; (9) 200 tiques na mesma estante mixada (peça honesta
## que o bolso paga + peça Mítica que não paga): com o livro aberto o balcão serve mais gente
## e o que ele não cobrou está na rua e no prejuízo, não no caixa; (10) as cinco chaves
## atravessam o arquivo, payload lixo é podado, save antigo acorda com a gaveta fechada, e
## `_reset_run()` zera o livro junto com a vida; (11) o painel lê degrau, notas e botão, a
## escada custa 150 → 380 → 720, fama e caixa recusam degrau, e o quarto clique no teto não
## gasta ouro; (12) os dois selos novos acendem nas fronteiras e a lista fecha com 91
## definições (o par da bancada, #76, entrou depois desta leitura; a sonda lê o tamanho
## real).
##
## Armadilha de caixa, terceira torneira: a FICHA do freguês paga no PRIMEIRO atendimento que
## ele recebe (ato 1 = 20 + nível×4 de ouro, +1 de fama). Blindar só selos e nível deixou
## 260 ouro entrarem no caixa de uma venda a crédito e a sonda leu "a etiqueta não entrou"
## com o caixa cheio. `_blindar()` também fecha os quatro atos e o capítulo dos cinco nomes
## medidos; a corrida de 200 tiques não blinda ficha nenhuma, porque lá o freguês atendido é
## exatamente o que se quer contar.
##
## Armadilha medida aqui: o balcão sorteia o evento raro no topo do tique e devolve o tique
## sem atender ninguém, o `_visit_budget()` tem piso de 10 ouro, e `_flood_service_queue()`
## põe gente nova na fila ANTES de chamar a nossa — fila cheia não quer dizer visita
## servida. Toda medida de fila deste arquivo crava a semente até a sentinela da visita
## sumir da fila (a semente sai impressa) e escolhe uma peça com etiqueta acima do piso,
## senão "nada aconteceu" lê como "o fiado não existe".
##
## Armadilha de régua, corrigida a mao nesta sonda: a cauda de 40 `randi()` é sempre lida
## logo apos `seed(SEED_VAL)` cravado. Sem o segundo seed, a segunda cauda nasce na casa 80
## da stream e a sonda acusaria "o livro sorteia" onde o livro só lê dicionario. E as
## medidas de caixa blindam os selos da lista (91 na última corrida) e o nivel (degrau 60): a Primeira Venda paga 10
## ouro e um level-up paga 25 — sem isso, "venda a credito nao entra no caixa" mediria o
## premio da conquista em vez do fiado.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/fiado.gd

const Locales = preload("res://locales.gd")
const Main = preload("res://main.gd")
const Regulars = preload("res://regulars.gd")

const SEED_VAL := 20261017
## Piso do bolso sorteado: `_visit_budget()` nunca devolve menos que isto, então a etiqueta
## emprestada precisa ficar acima disso e abaixo do teto do degrau.
const BOLSO_MINIMO := 10
## Bolso de um freguês de sempre no degrau mais baixo da confiança: `_draw_visitor_profile()`
## devolve 60 + tier×30, então abaixo de 60 nenhuma peça da estante é cara para ele.
const BOLSO_REGULAR := 60

## Degraus de qualidade usados para compor estante: `quality_stock` é o vetor
## [torto, honesto, refinado, obra-prima, mítico, lendário], então 1 é a peça de etiqueta
## base (×1.0) e 4 é a Mítica (×2.5). É com o degrau, não com o catálogo, que a loja nova
## consegue etiqueta acima do bolso de um freguês de bairro.
const TIER_HONESTO := 1
const TIER_MITICO := 4

## Fregueses reais do elenco — fiado é nome, e sem um deles no livro nada acontece.
const ALDRIC := "aldric"
const LYRA := "lyra"
const KORVAX := "korvax"
const MINA := "mina"
const TUCK := "tuck"


func _initialize() -> void:
	print("── com a gaveta fechada o fiado não existe ──")
	var a = await _loja("gaveta")
	_blindar(a)
	a.gold = 500
	a.reputation = 20
	print("   degrau 0: teto %d • lugares %d • prazo %d dias • _can_lend(aldric,1) = %s" % [
		a._credit_limit(), a._credit_seats(), a._credit_due_days(), str(a._can_lend(ALDRIC, 1))])
	print("   virada com o livro vazio: linha \"%s\" (tem de ser vazia) • quitação: %s" % [
		str(a._age_credit_book()), str(a._settle_credit_note(ALDRIC).is_empty())])
	var alvo_a := _peça_emprestável(a, 1)
	var etiqueta_a: int = int(a._shelf_price(alvo_a))
	var fama_antes: int = a.reputation
	var ouro_antes: int = a.gold
	var seed_gaveta := _servir_visitante(a, ALDRIC, BOLSO_MINIMO, alvo_a)
	print("   semente do tique em que ela sentou: %d • etiqueta da vitrine: %d • bolso: %d" % [
		seed_gaveta, etiqueta_a, BOLSO_MINIMO])
	print("   venda perdida de sempre: saiu sem comprar %d • fama %d→%d • caixa %d→%d • livro %d • texto sem fiado: %s" % [
		a.disappointed_customers, fama_antes, a.reputation, ouro_antes, a.gold,
		a.credit_book.size(), str(not str(a.last_event).contains("📖"))])
	print("   painel: %s" % str(a._credit_summary()).split("\n")[0])
	await _fechar(a)

	print("── a nota entra no lugar exato da venda perdida ──")
	var b = await _loja("nota")
	_blindar(b)
	b.gold = 500
	b.reputation = 20
	var alvo := _peça_emprestável(b, 1)
	var etiqueta: int = int(b._shelf_price(alvo))
	var estoque_antes := _estoque_do(b, alvo)
	var registro_antes := _registro_do(b, alvo)
	b.credit_rank = 1
	var fama_b: int = b.reputation
	var ouro_b: int = b.gold
	var seed_nota := _servir_visitante(b, ALDRIC, BOLSO_MINIMO, alvo)
	var nota: Dictionary = b.credit_book.get(ALDRIC, {})
	print("   semente %d • etiqueta %d no bolso de %d → nota %s" % [
		seed_nota, etiqueta, BOLSO_MINIMO, str(nota)])
	print("   caixa %d → %d (+%d): a etiqueta %d não entrou — selos, nível, ficha de arco e capítulo blindados" % [
		ouro_b, b.gold, b.gold - ouro_b, etiqueta])
	print("   balanço do dia: %d de ouro ganho (tem de ser 0 — o dia não cobra o que a rua levou) • fama %d → %d • saiu sem comprar: %d" % [
		b.daily_gold_earned, fama_b, b.reputation, b.disappointed_customers])
	print("   prateleira: estoque %d → %d • registro de idade %d → %d (só tem registro quem vence)" % [
		estoque_antes, _estoque_do(b, alvo), registro_antes, _registro_do(b, alvo)])
	print("   prazo do degrau 1 (%d dias): dia %d → vence dia %d • ouro na rua %d" % [
		b._credit_due_days(), b.shop_day, int(nota.get("due_day", 0)), b._credit_on_street()])
	print("   balcão (manchete): %s" % str(b.last_event).split("\n")[0])
	print("   o recibo do fiado sobrevive ao aviso da reforma: %s • mural em %d linha(s)" % [
		str(str(b.last_event).contains("📖")), str(b.last_event).split("\n").size()])
	await _fechar(b)

	print("── quem acaba de quitar não leva nota nova no mesmo balcão ──")
	var c = await _loja("girouro")
	_blindar(c)
	c.gold = 500
	c.reputation = 20
	c.credit_rank = 1
	var alvo_c := _peça_emprestável(c, 1)
	var etiqueta_c: int = int(c._shelf_price(alvo_c))
	var divida := maxi(1, int(etiqueta_c / 2))
	c.credit_book = {ALDRIC: {"name": "Aldric", "item": str(c.products[alvo_c]["name"]),
		"owed": divida, "due_day": c.shop_day + 6, "late": 0}}
	var seed_giro := _servir_visitante(c, ALDRIC, etiqueta_c, alvo_c)
	print("   semente %d • bolso %d, dívida %d → quitou %d, sobra %d (etiqueta da peça: %d)" % [
		seed_giro, etiqueta_c, divida, c.credit_paid, c.current_customer_budget, etiqueta_c])
	print("   livro depois da quitação: %d nota(s) — reemprestado seria 1 • saiu sem comprar: %d • caixa %d" % [
		c.credit_book.size(), c.disappointed_customers, c.gold])
	print("   sem a tranca seria emprestável agora: _can_lend(aldric, %d) = %s" % [
		etiqueta_c, str(c._can_lend(ALDRIC, etiqueta_c))])
	await _fechar(c)

	print("── o pedido pessoal é a segunda porta do fiado ──")
	var t = await _loja("pedido")
	_blindar(t)
	t.gold = 500
	t.reputation = 20
	var u = await _loja("pedido_zero")
	_blindar(u)
	u.gold = 500
	u.reputation = 20
	var teto_3 := int(Main.CREDIT_TIERS[3]["limit"])
	var estante_t: Dictionary = _estante_de_pedido(t, BOLSO_REGULAR, teto_3)
	var estante_u: Dictionary = _estante_de_pedido(u, BOLSO_REGULAR, teto_3)
	t.credit_rank = 3
	var ouro_t: int = t.gold
	var ouro_u: int = u.gold
	var seed_t := _servir_visitante(t, ALDRIC, BOLSO_REGULAR, int(estante_t["cara"]), true)
	var seed_u := _servir_visitante(u, ALDRIC, BOLSO_REGULAR, int(estante_u["cara"]), true)
	var nota_t: Dictionary = t.credit_book.get(ALDRIC, {})
	print("   estante de duas peças: barata %d (o bolso paga) • cara %d (pediu e não paga) • bolso %d" % [
		int(estante_t["barata_preco"]), int(estante_t["cara_preco"]), BOLSO_REGULAR])
	print("   degrau 3 (semente %d): nota %s" % [seed_t, str(nota_t)])
	print("   degrau 3: caixa %d→%d (+%d • %d no balanço do dia) • pedido de Aldric %d • saiu sem comprar %d" % [
		ouro_t, t.gold, t.gold - ouro_t, t.daily_gold_earned,
		int(t.regular_orders_completed.get(ALDRIC, 0)), t.disappointed_customers])
	print("   degrau 0 (semente %d): %d nota(s) • caixa %d→%d (+%d • %d no balanço) • pedido de Aldric %d — a porta não existia" % [
		seed_u, u.credit_book.size(), ouro_u, u.gold, u.gold - ouro_u, u.daily_gold_earned,
		int(u.regular_orders_completed.get(ALDRIC, 0))])
	print("   a nota cabe no teto do degrau (%d): %s • ouro na rua %d" % [
		t._credit_limit(), str(int(nota_t.get("owed", 0)) <= t._credit_limit()), t._credit_on_street()])
	print("   balcão (manchete): %s" % str(t.last_event).split("\n")[0])
	print("   o pedido no fiado ficou no mural: %s" % str(str(t.last_event).contains("PEDIDO ESPECIAL")))
	await _fechar(t)
	await _fechar(u)

	print("── o juro mora só em quem atrasou ──")
	var d = await _loja("juro")
	d.credit_rank = 2
	d.gold = 500
	d.reputation = 25
	d.current_customer_budget = 400
	d.credit_book = {LYRA: {"name": "Lyra", "item": "frasco", "owed": 120,
		"due_day": d.shop_day + 8, "late": 0}}
	var em_dia: Dictionary = d._settle_credit_note(LYRA)
	d.current_customer_budget = 400
	d.credit_book[LYRA] = {"name": "Lyra", "item": "frasco", "owed": 120,
		"due_day": d.shop_day + 8, "late": 2}
	var atrasada: Dictionary = d._settle_credit_note(LYRA)
	var juro := int(round(120.0 * Main.CREDIT_INTEREST))
	print("   em dia: cobra %d (esperado 120, juro zero) • atrasada 2 dias: cobra %d (esperado %d = 120 + %d)" % [
		int(em_dia.get("purse", 0)), int(atrasada.get("purse", 0)), 120 + juro, juro])
	print("   texto da Em dia: %s" % str(em_dia.get("line", "")))
	print("   texto da atrasada: %s" % str(atrasada.get("line", "")))
	print("   livro: %d nota(s) • quitadas %d • caixa 500 → %d (500+120+%d) • fama %d • vínculo de Lyra %d" % [
		d.credit_book.size(), d.credit_paid, d.gold, 120 + juro, d.reputation,
		int(d.regular_bonds.get(LYRA, 0))])
	print("   o ouro da nota entra no balanço do dia em que chega: %d ganho hoje (tem de ser 120+%d)" % [
		d.daily_gold_earned, 120 + juro])
	d.current_customer_budget = 250
	d.credit_book = {KORVAX: {"name": "Korvax", "item": "frasco", "owed": 300,
		"due_day": d.shop_day, "late": 0}}
	var ouro_korvax: int = d.gold
	var recusado: Dictionary = d._settle_credit_note(KORVAX)
	print("   bolso 250 contra nota de 300: cobrou %s • nota no livro %d • caixa %d (intocado: %s)" % [
		str(recusado.is_empty()), d.credit_book.size(), d.gold, str(d.gold == ouro_korvax)])
	await _fechar(d)

	print("── a riscada é no terceiro dia, não no primeiro ──")
	var e = await _loja("riscada")
	e.credit_rank = 3
	e.reputation = 40
	e.regular_bonds[MINA] = 5
	e.credit_book = {MINA: {"name": "Mina", "item": "adaga", "owed": 70,
		"due_day": e.shop_day, "late": 0}}
	for volta in range(4):
		e.shop_day += 1
		var linha := str(e._age_credit_book())
		var viva: bool = e.credit_book.has(MINA)
		var atraso := 0
		if viva:
			atraso = int((e.credit_book[MINA] as Dictionary).get("late", 0))
		print("   virada %d (dia %d): nota no livro %s • atraso %d • riscadas %d • prejuízo %d • fama %d • vínculo %d%s" % [
			volta + 1, e.shop_day, str(viva), atraso, e.credit_written, e.credit_lost_gold,
			e.reputation, int(e.regular_bonds.get(MINA, 0)),
			" • linha: %s" % linha if linha != "" else ""])
	print("   a casa risca no dia %d de atraso (CREDIT_WRITEOFF_DAYS)" % Main.CREDIT_WRITEOFF_DAYS)
	await _fechar(e)

	print("── teto, nome e lotação ──")
	var f = await _loja("limite")
	f.credit_rank = 1
	var cheio := {
		ALDRIC: {"name": "Aldric", "item": "x", "owed": 30, "due_day": f.shop_day + 6, "late": 0},
		LYRA: {"name": "Lyra", "item": "x", "owed": 30, "due_day": f.shop_day + 6, "late": 0},
		KORVAX: {"name": "Korvax", "item": "x", "owed": 30, "due_day": f.shop_day + 6, "late": 0},
	}
	f.credit_book = cheio.duplicate(true)
	print("   degrau 1: teto %d • lugares %d • livro com %d" % [
		f._credit_limit(), f._credit_seats(), f.credit_book.size()])
	print("   etiqueta %d com o livro cheio (%d/%d): %s" % [
		f._credit_limit(), f.credit_book.size(), f._credit_seats(),
		str(f._can_lend(TUCK, f._credit_limit()))])
	f.credit_book.erase(KORVAX)
	print("   vaga livre, etiqueta no teto (%d): %s" % [
		f._credit_limit(), str(f._can_lend(TUCK, f._credit_limit()))])
	print("   um ouro acima do teto (%d): %s" % [
		f._credit_limit() + 1, str(f._can_lend(TUCK, f._credit_limit() + 1))])
	print("   nome que já deve na casa (%s): %s" % [ALDRIC, str(f._can_lend(ALDRIC, 20))])
	print("   visita sem nome (corpo fora do elenco): %s" % str(f._can_lend("", 20)))
	await _fechar(f)

	print("── ler e escrever no livro não sorteia nada ──")
	var g = await _loja("sorteio")
	# Cada cauda precisa nascer da MESMA posição da stream: a semente é cravada antes de
	# cada chamada medida, senão a segunda cauda sai na casa 80 e o "diferente" seria da
	# régua, não do jogo.
	g.credit_rank = 2
	g.gold = 900
	g.reputation = 25
	seed(SEED_VAL)
	var cauda_controle := _cauda(40)
	var alvos: Array[int] = [0, 1, 2]
	seed(SEED_VAL)
	for leitura in range(30):
		g._can_lend(ALDRIC, 50)
		g._credit_limit()
		g._credit_seats()
		g._credit_due_days()
		g._credit_summary()
		g._credit_on_street()
		g._cheapest_index(alvos)
	g._lend_note(MINA, "Mina", "adaga", 44)
	var empresta := _cauda(40)
	var nota_mina: Dictionary = g.credit_book[MINA]
	nota_mina["due_day"] = g.shop_day
	g.shop_day += 1
	seed(SEED_VAL)
	var linha_envelhece := str(g._age_credit_book())
	var envelhece := _cauda(40)
	g.current_customer_budget = 500
	seed(SEED_VAL)
	var nota_quitada: Dictionary = g._settle_credit_note(MINA)
	var quita := _cauda(40)
	print("   30 leituras + lançar nota: cauda de 40 igual ao controle limpo? %s" % str(
		empresta == cauda_controle))
	print("   virar o livro um dia (linha \"%s\"): cauda igual? %s" % [
		linha_envelhece, str(envelhece == cauda_controle)])
	print("   quitar a nota (cobra %d, juro %s): cauda igual? %s" % [
		int(nota_quitada.get("purse", 0)), str(nota_quitada.get("purse", 0) > 44),
		str(quita == cauda_controle)])
	await _fechar(g)

	print("── 200 tiques: o mesmo balcão com a gaveta fechada e aberta ──")
	# As duas vidas partem do mesmo chão: a MESMA estante cara, a MESMA fama e os MESMOS
	# selos já pagos. Sem selar as conquistas, o pacote de cartas que a primeira venda abre
	# consome sorteio e as duas corridas deixam de ser a mesma loja.
	var h = await _loja("sem_livro")
	_selar_conquistas(h)
	_preparar_loja_cheia(h)
	for tick in range(200):
		h._on_customer_tick()
	var h_fechado := _retrato(h)
	var h_nota_vendida: int = h.credit_book.size()
	await _fechar(h)
	var i = await _loja("com_livro")
	_selar_conquistas(i)
	_preparar_loja_cheia(i)
	i.credit_rank = 3
	for tick in range(200):
		i._on_customer_tick()
	print("   fechado: %s • %d nota(s)" % [h_fechado, h_nota_vendida])
	print("   aberto:  %s" % _retrato(i))
	print("   no livro %d nota(s) = %d na rua • %d quitada(s) • %d riscada(s) (%d de prejuízo)" % [
		i.credit_book.size(), i._credit_on_street(), i.credit_paid, i.credit_written,
		i.credit_lost_gold])
	print("   o ouro que a loja deixou de cobrar: rua %d + prejuízo %d = %d fora do caixa" % [
		i._credit_on_street(), i.credit_lost_gold, i._credit_on_street() + i.credit_lost_gold])
	await _fechar(i)

	print("── as cinco chaves atravessam o arquivo ──")
	var j = await _loja("arquivo")
	j.gold = 2222
	j.credit_rank = 2
	j.credit_paid = 4
	j.credit_written = 1
	j.credit_lost_gold = 88
	j.shop_day = 30
	j.credit_book = {
		ALDRIC: {"name": "Aldric", "item": "frasco", "owed": 55, "due_day": 36, "late": 1},
		LYRA: {"name": "Lyra", "item": "adaga", "owed": 90, "due_day": 38, "late": 0},
	}
	j._save_game()
	var k = await _reload("relido")
	print("   relido: degrau %d • ouro %d • %d nota(s) • quitadas %d • riscadas %d • prejuízo %d" % [
		k.credit_rank, k.gold, k.credit_book.size(), k.credit_paid, k.credit_written,
		k.credit_lost_gold])
	print("   a idade atravessou: %s" % str(k.credit_book.get(ALDRIC, {})))
	await _fechar(k)

	print("── payload lixo e save antigo acordam com a gaveta fechada ──")
	_escrever_chave("credit_rank", "12")
	_escrever_chave("credit_book", "{\"fantasma\": {\"owed\": 40, \"due_day\": 40}, \"aldric\": {\"owed\": 0, \"due_day\": 40}, \"lyra\": {\"owed\": 55, \"due_day\": -3}, \"korvax\": \"nota que nao e dicionario\", \"mina\": {\"owed\": 60, \"due_day\": 44, \"late\": 9}}")
	var l = await _reload("podado")
	print("   nível 12 no arquivo vira degrau %d • prazo do degrau: %d dias" % [
		l.credit_rank, l._credit_due_days()])
	var sobras: Array[String] = []
	for id in l.credit_book:
		var entrada: Dictionary = l.credit_book[id]
		sobras.append("%s=%d(dia %d, atraso %d)" % [str(id), int(entrada.get("owed", 0)),
			int(entrada.get("due_day", 0)), int(entrada.get("late", 0))])
	print("   5 entradas lixo viram %d: %s" % [l.credit_book.size(), ", ".join(sobras)])
	print("   primeira virada depois do lixo: linha \"%s\"" % str(l._age_credit_book()))
	await _fechar(l)
	_apagar_chaves()
	var m = await _reload("antigo")
	print("   sem as chaves no arquivo: degrau %d • %d nota(s) • quitadas %d • prejuízo %d • %d produto(s) na estante" % [
		m.credit_rank, m.credit_book.size(), m.credit_paid, m.credit_lost_gold, m.products.size()])
	print("   virada imediata: linha \"%s\" (nada a riscar) • _can_lend: %s" % [
		str(m._age_credit_book()), str(m._can_lend(ALDRIC, 10))])
	await _fechar(m)

	print("── reencarnar apaga as notas da rua ──")
	var n = await _loja("vida")
	n.credit_rank = 3
	n.credit_paid = 7
	n.credit_written = 2
	n.credit_lost_gold = 200
	n.credit_book = {TUCK: {"name": "Tuck", "item": "frasco", "owed": 30,
		"due_day": n.shop_day + 4, "late": 0}}
	n._reset_run()
	print("   vida nova: degrau %d • %d nota(s) • quitadas %d • riscadas %d • prejuízo %d" % [
		n.credit_rank, n.credit_book.size(), n.credit_paid, n.credit_written, n.credit_lost_gold])
	await _fechar(n)

	print("── a escada do caderno: 150 → 380 → 720, e o quarto degrau é recusado ──")
	var o = await _loja("caixa")
	o.gold = 2000
	o.reputation = 40
	o._buy_credit_rank()
	var ouro_1: int = o.gold
	o._buy_credit_rank()
	var ouro_2: int = o.gold
	o._buy_credit_rank()
	var ouro_3: int = o.gold
	o._buy_credit_rank()
	print("   2000 − %d (degrau 1) − %d (degrau 2) − %d (degrau 3) = %d, degrau %d, teto %d, %d lugares, prazo %d dias" % [
		2000 - ouro_1, ouro_1 - ouro_2, ouro_2 - ouro_3, ouro_3, o.credit_rank,
		o._credit_limit(), o._credit_seats(), o._credit_due_days()])
	print("   quarto clique no teto: caixa %d (tem de ser o mesmo %d) • degrau %d • %s" % [
		o.gold, ouro_3, o.credit_rank, str(o.last_event).split("\n")[0]])
	print("   fama 40 + 1 por degrau comprado = %d e %d selo(s) acesos na vida" % [
		o.reputation, o.unlocked_achievements.size()])
	var p = await _loja("falta_fama")
	p.gold = 4000
	p.reputation = 5
	p._buy_credit_rank()
	print("   4000 de ouro com 5 de fama: degrau %d, caixa %d intocado • %s" % [
		p.credit_rank, p.gold, str(p.last_event).split("\n")[0]])
	var q = await _loja("caixa_vazio")
	q.gold = 10
	q.reputation = 40
	q._buy_credit_rank()
	print("   10 de ouro no caixa: degrau %d e ouro %d intocados • %s" % [
		q.credit_rank, q.gold, str(q.last_event).split("\n")[0]])
	await _fechar(o)
	await _fechar(p)
	await _fechar(q)

	print("── o painel lê degrau, notas e botão ──")
	var r = await _loja("painel")
	r.credit_rank = 2
	r.gold = 1500
	r.shop_day = 12
	r.credit_paid = 3
	r.credit_written = 1
	r.credit_lost_gold = 40
	r.credit_book = {
		ALDRIC: {"name": "Aldric", "item": "frasco", "owed": 55, "due_day": 14, "late": 2},
		LYRA: {"name": "Lyra", "item": "adaga", "owed": 90, "due_day": 20, "late": 0},
	}
	r._refresh_ui()
	print("   label: %s" % str(r.credit_label.text).replace("\n", " / "))
	print("   botão: %s (disabled: %s)" % [str(r.credit_button.text), str(r.credit_button.disabled)])
	r.credit_rank = 3
	r._refresh_ui()
	print("   no teto: %s (disabled: %s)" % [str(r.credit_button.text), str(r.credit_button.disabled)])
	r.credit_rank = 0
	r._refresh_ui()
	print("   gaveta fechada: botão %s • label %s" % [
		str(r.credit_button.text), str(r.credit_label.text).split("\n")[0]])
	await _fechar(r)

	print("── os dois selos novos acendem na fronteira ──")
	var s = await _loja("selos")
	s.gold = 3000
	s.credit_paid = 4
	s.credit_written = 2
	s._check_achievements()
	print("   4 quitadas e 2 riscadas: quem deve paga %s • tinta vermelha %s" % [
		str(s.unlocked_achievements.has("credit_paid_five")),
		str(s.unlocked_achievements.has("credit_red_ink"))])
	s.credit_paid = 5
	s._check_achievements()
	print("   5 quitadas: quem deve paga %s" % str(s.unlocked_achievements.has("credit_paid_five")))
	s.credit_written = 3
	s._check_achievements()
	print("   3 riscadas: tinta vermelha %s" % str(s.unlocked_achievements.has("credit_red_ink")))
	var definicoes := 0
	for definition in s._achievement_definitions():
		definicoes += 1
	print("   painel de conquistas: %d definições • os dois selos estão entre elas: %s" % [
		definicoes, str(_tem_conquista(s, "credit_paid_five") and _tem_conquista(s, "credit_red_ink"))])
	await _fechar(s)

	print("VEREDITO: degrau fechado tem de bater com a venda perdida de sempre (caixa, fama e disappointed na mesma), a nota tem de nascer no lugar exato da venda sem um ouro no caixa, sem um ouro no balanço do dia e com a prateleira abatida, o recibo tem de continuar no mural quando a reforma avisa por cima, quitar não pode reemprestar no mesmo balcão, o ouro cobrado tem de entrar no balanço do dia da cobrança, juro só com atraso, riscada só no terceiro dia, e ler ou escrever no livro não pode mover um sorteio. Ouro mudando com a gaveta fechada, etiqueta emprestada contando como caixa do dia, sorteio consumido pelo livro ou nota nova na visita em que a dívida foi paga é o fiado cortando progressão.")
	quit()


## Esvazia a prateleira de verdade: estoque, barrinha de qualidade e registro de idade.
## Zerar só o `stock` deixaria a etiqueta de vitrine espiando o degrau da peça velha.
func _limpar_prateleira(g) -> void:
	for i in range(g.products.size()):
		g.products[i]["stock"] = 0
	g.quality_stock.clear()
	g.shelf_batches.clear()


## Fecha as duas torneiras de ouro que não são o balcão: os selos da lista, 91 na última
## corrida (todos já pagos, para
## a "Primeira venda" não pagar no meio da medida) e o nível, estacionado longe do próximo
## degrau de XP. Sem isso, "venda a crédito não entra no caixa" estaria medindo o prêmio de
## conquista e o ouro de level-up — e o `_grant_pack()` que eles abrem moveria a sorteio.
func _blindar(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)
	g.player_level = 60
	g.player_xp = 0
	# Terceira torneira, e foi ela que mentiu nesta sonda: a FICHA do freguês paga no
	# PRIMEIRO atendimento que ele recebe (ato 1 = 20 + nível×4 de ouro e +1 de fama). Com
	# o nível estacionado no 60, um freguês atendido entra no caixa com 260 ouro que não são
	# venda — e a linha "a etiqueta não entrou no caixa" media a ficha, não o fiado.
	for fregues_id in [ALDRIC, LYRA, KORVAX, MINA, TUCK]:
		g.regular_arc_seen[fregues_id] = Main.ARC_REWARDS.size()
		if not (g.regular_story_completed as Array).has(fregues_id):
			g.regular_story_completed.append(fregues_id)


## Só os selos, sem mexer no nível nem na estante: é o que a corrida de 200 tiques precisa
## para as duas vidas partirem do mesmo catálogo da loja nova.
func _selar_conquistas(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)


## Estante de duas peças para a medida do pedido pessoal: a barata que o bolso paga e a cara
## que ele pediu e não paga. Devolve os índices e as etiquetas lidas com uma peça posta, que
## é exatamente como o balcão as lê.
func _estante_de_pedido(g, bolso: int, teto: int) -> Dictionary:
	var barata := -1
	var barata_preco := 0
	var cara := -1
	var cara_preco := 0
	for i in range(g.products.size()):
		if not bool(g._is_product_unlocked(g.products[i])):
			continue
		_limpar_prateleira(g)
		g._add_piece(i, 1)
		var preco: int = int(g._shelf_price(i))
		if preco <= bolso and (barata < 0 or preco > barata_preco):
			barata = i
			barata_preco = preco
		elif preco > bolso and preco <= teto and (cara < 0 or preco < cara_preco):
			cara = i
			cara_preco = preco
	_limpar_prateleira(g)
	if barata < 0 or cara < 0:
		print("      (estante de pedido incompleta: barata %d • cara %d — a medida abaixo não vale)" % [barata, cara])
	if barata >= 0:
		g._add_piece(barata, 1)
	if cara >= 0:
		g._add_piece(cara, 1)
	return {"barata": barata, "barata_preco": barata_preco,
		"cara": cara, "cara_preco": cara_preco}


## Deixa UM produto com estoque na loja: o mais barato cuja etiqueta caiba entre o piso do
## bolso (10) e o teto do degrau pedido. Sem isso a visita cairia na prateleira vazia ou
## pagaria à vista, e a medida não seria de fiado.
func _peça_emprestável(g, degrau: int) -> int:
	var teto := 0
	if degrau > 0:
		teto = int(Main.CREDIT_TIERS[degrau]["limit"])
	var melhor := -1
	var melhor_preco := 0
	for i in range(g.products.size()):
		if not bool(g._is_product_unlocked(g.products[i])):
			continue
		# A etiqueta é lida com a única peça já posta: é com esse estoque que o balcão
		# trabalha, e a escassez mexe no preço.
		_limpar_prateleira(g)
		g._add_piece(i, 1)
		var preco: int = int(g._shelf_price(i))
		if preco <= BOLSO_MINIMO:
			continue
		if teto > 0 and preco > teto:
			continue
		if melhor < 0 or preco < melhor_preco:
			melhor = i
			melhor_preco = preco
	_limpar_prateleira(g)
	if melhor >= 0:
		g._add_piece(melhor, 1)
	return melhor


## Perfil de freguês montado à mão: o mesmo corpo que o jogo sorteia, com o bolso travado
## para que a etiqueta escolhida nunca caiba no pagamento. A sentinela é o carimbo que
## deixa saber, no fim do tique, se foi ESTA visita que o balcão atendeu.
func _perfil(fregues_id: String, bolso: int, favorite_id: String, pedido: bool = false) -> Dictionary:
	var regular: Dictionary = Regulars.find(fregues_id)
	return {
		"name": str(regular.get("name", fregues_id)),
		"favorite": favorite_id,
		"line": "bate no bolso vazio e olha a vitrine.",
		"regular_id": fregues_id,
		"portrait": int(regular.get("portrait", 0)),
		"tier": 1,
		"personal_request": pedido,
		"probe_sentinela": "visita medida",
		"faction": str(regular.get("faction", "aventureiros")),
		"budget": bolso,
		"patience": 3,
	}


## Manda a visita ao balcão e roda tiques até que ELA seja atendida. Duas coisas podem
## enganar: o evento raro sorteado no topo do tique devolve o tique sem atender ninguém, e
## `_flood_service_queue()` põe mais gente na fila antes de chamar a nossa — fila cheia não
## quer dizer visita servida. Por isso a prova é a sentinela, não `is_empty()`. Devolve a
## semente em que a visita sentou no balcão.
func _servir_visitante(g, fregues_id: String, bolso: int, alvo: int, pedido := false) -> int:
	var favorite := ""
	if alvo >= 0 and alvo < g.products.size():
		favorite = str(g.products[alvo]["id"])
	for tentativa in range(20):
		var semente := SEED_VAL + tentativa
		g.ticks = 1
		g.service_queue.clear()
		g.service_queue.append({"profile": _perfil(fregues_id, bolso, favorite, pedido),
			"waited": 0, "limit": 9})
		seed(semente)
		g._on_customer_tick()
		if not _fila_tem_sentinela(g):
			return semente
	return -1


## A visita medida ainda está esperando na fila?
func _fila_tem_sentinela(g) -> bool:
	for entry in g.service_queue:
		if str((entry as Dictionary).get("profile", {}).get("probe_sentinela", "")) != "":
			return true
	return false


func _estoque_do(g, index: int) -> int:
	if index < 0:
		return 0
	return int(g.products[index]["stock"])


func _registro_do(g, index: int) -> int:
	if index < 0:
		return 0
	return (g.shelf_batches.get(str(g.products[index]["id"]), []) as Array).size()


## Loja de balcão vivo para a corrida de 200 tiques: estante MISTA. Cada produto liberado
## entra ou como peça honesta (etiqueta que o bolso paga, e faz a loja vender) ou como peça
## Mítica (etiqueta acima do bolso de um freguês de bairro e abaixo do teto do degrau 3,
## que é onde o fiado tem porta). Com a estante toda em conta ninguém ficava sem com que
## pagar e o livro não tinha o que cobrar; com a estante toda cara ninguém era servido em
## lado nenhum e a corrida media loja vazia. As duas corridas comem a MESMA estante — o que
## muda entre elas é só o degrau.
func _preparar_loja_cheia(g) -> void:
	g.gold = 1200
	g.reputation = 20
	_limpar_prateleira(g)
	var caras := 0
	var baratas := 0
	var teto_3 := int(Main.CREDIT_TIERS[3]["limit"])
	for i in range(g.products.size()):
		if not bool(g._is_product_unlocked(g.products[i])):
			continue
		# A etiqueta é lida com a única peça posta, do jeito que o balcão a lê.
		_limpar_prateleira(g)
		g._add_piece(i, TIER_MITICO)
		var topo: int = int(g._shelf_price(i))
		_limpar_prateleira(g)
		g._add_piece(i, TIER_HONESTO)
		var base: int = int(g._shelf_price(i))
		_limpar_prateleira(g)
		if topo > BOLSO_REGULAR and topo <= teto_3:
			for _copia in range(3):
				g._add_piece(i, TIER_MITICO)
			caras += 1
		elif base <= BOLSO_REGULAR:
			for _copia in range(3):
				g._add_piece(i, TIER_HONESTO)
			baratas += 1
	if caras == 0 or baratas == 0:
		print("      (estante mixada falhou: %d cara(s) e %d barata(s) — a corrida abaixo não mede fiado)" % [caras, baratas])
	else:
		print("      estante da corrida: %d produto(s) caro(s) (porta do fiado) • %d barato(s) (caixa de sempre)" % [caras, baratas])


## Retrato do fim de uma corrida: o que a loja cobrou, o que ficou na rua e o que a casa
## riscou. Tudo em uma linha, para o antes/depois ser lido de uma vez.
func _retrato(g) -> String:
	return "servidos %d • sem comprar %d • caixa %d • dívida %d (pico %d) • fama %d • rua %d" % [
		g.customers_served, g.disappointed_customers, g.gold, g.debt, g.debt_peak,
		g.reputation, g._credit_on_street()]


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


## Tira as cinco chaves do arquivo: é o save antigo, escrito antes de o livro existir.
func _apagar_chaves() -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	for chave in ["credit_rank", "credit_book", "credit_paid", "credit_written",
		"credit_lost_gold"]:
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
