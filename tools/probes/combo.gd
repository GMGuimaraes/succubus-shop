extends SceneTree

## Sonda do cartaz do combo (#80): prova que a sequência de vendas do mesmo dia paga ouro
## de verdade na etiqueta, e que com o cartaz na gaveta o balcão é byte a byte o de sempre.
## A escada é a mesma inércia das outras três: o degrau 0 tem custo, fama e bônus zero, a
## sequência é contada mas nunca paga, e nenhum sorteio novo nasce da leitura. É essa inércia
## que segura as vizinhas relidas — `tools/probes/salao.gd` nos mesmos 22 atendimentos e caixa
## 8518, `tools/probes/fiado.gd` nos mesmos 1684/1640 com 77 na rua, `tools/probes/reclamacoes.gd`
## nos mesmos 23 atendimentos e caixa 8516, e o lado 0 desta sonda bate o 8516 do livro porque
## as duas corridas comem a mesma estante e a mesma semente (20261025).
##
## Medidas desta sonda: (1) cartaz na gaveta — taxa exatamente 0.0000 nas sequências 0 a 12,
## vinte vendas sem cartaz sobem a contagem até o teto 12 sem premiar (recorde 0, cofre 0),
## painel 🔕, botão de degrau 1 aceso e 200 leituras do painel que deixam a cauda de 40
## `randi()` idêntica à do controle;
## (2) a tabela lida nó a nó — 180 de ouro + 6 de fama paga a partir da 3ª com +2% e teto 6%,
## 460 + 18 sobe para +3% e teto 12%, 980 + 38 começa na 2ª com +5% e teto 25%, e a contagem
## para em 12 (a taxa da sequência 12 é a mesma da 8); (3) o bônus é dinheiro: peça de tabela
## 32, mesma semente, sequência 7 — caixa +47 sem cartaz, +49 no degrau 1, +55 no degrau 3, e
## o que passa do controle é exatamente +2 e +8; sequência 0 no degrau 0 fecha o mesmo +47;
## (4) quem corta — fila desistida leva 9 → 0, capa fina devolvida leva 8 → 0 (e escreve 2
## linhas no livro da rua), a virada zera sequência, recorde do dia e pago hoje mas guarda o
## que é da vida (recorde 8, cofre 45), e o balanço só fala do cartaz na virada que pagou;
## (5) a nota do fiado — mesma semente e mesma peça, degrau 0 anota 28 e degrau 3 anota 32, com
## diferença de caixa 0 entre os lados e cofre e recorde em 0 enquanto a sequência conta;
## (6) pendurar cobra o que anuncia — 30 de caixa devolve 30, fama 2 devolve 5000, o clique
## pago sai 5000 → 4820 com fama 41 e a sequência zerada, a escada inteira fecha 4820 → 3380
## e o quarto clique no teto fica 3380 → 3380 com o botão apagado; (7) o painel nos três
## estados (guardado, cartaz pendurado sem ritmo, pagando) e o botão com ele; (8) as quatro
## chaves atravessam o arquivo (2/7/9/388), payload lixo é podado (12 → 3 pelo teto da escada,
## −5 → 0, 900 → 12 pelo teto da contagem, −900 → 0) e save antigo sem as chaves acorda 0/0/0/0
## com taxa 0.0000, caixa 1500 → 1500 e cauda idêntica ao controle; (9) reencarnar raspa o
## cartaz (3/11/12/777/5/33 → tudo 0); (10) os dois selos acendem no recorde 3 e no cofre 600
## (599 ainda não), e a lista fecha com 100 definições — o trio do topo da escada de cenários
## entrou nela depois desta leitura; (11) a corrida de 200 tiques em três
## lados (degrau 0, 1 e 3) — os três atendem 23 e perdem 229 visitas, e o que muda é só o
## caixa: 8516, 8526 e 8559, com cofre 0, 10 e 45.
##
## Armadilha do fiado: a visita medida é freguesa, e a ficha dela paga o ato 1 no primeiro
## atendimento — 260 de ouro com o nível parado no 60, que não são venda. A primeira leitura
## desta sonda anunciou "a nota não passa pelo caixa" com os dois lados +260: a medida estava
## certa (a diferença entre os lados é o que importa) mas a linha mentia no rótulo. Agora a
## nota roda com as fichas raspadas (`_raspar_fichas`), e a corrida continua sem raspar, porque
## lá o freguês atendido é exatamente o que se conta. Com o caixa travado em 5000 e o painel
## refreshado antes da captura, a faixa da reforma também não sobe no meio do corredor e não
## escreve a própria notícia por cima do recibo 📖.
##
## Armadilha da corrida: a estante é `[0,0,2,0,1,0]` — Refinado e Mítico, sem torto e sem cordão
## — porque peça torto anotaria linha no livro de reclamações (que corta paciência e etiqueta e
## entraria na medida como se fosse o cartaz) e visita devolvida na prateleira cortaria a
## sequência por fora do que se quer medir. Selada e com o nível em 60: o segundo selo do cartaz
## paga 240 de ouro e 9 de fama, e sem a rolha a corrida estaria medindo o prêmio do selo.
##
## Armadilha do mural: o rodapé 🔥 nasce antes do recibo da virada e antes da meta de vida, e a
## conta do dia é zerada pelo balanço no mesmo tique em que é impressa. A foto do dia é lida
## ANTES de cada tique, senão a sonda jura que o cartaz nunca pagou nada.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/combo.gd

const Locales = preload("res://locales.gd")
const Quality = preload("res://quality.gd")
const Regulars = preload("res://regulars.gd")
const GameScript = preload("res://main.gd")

const SEED_VAL := 20261025

## Índice do produto alvo — o mesmo da sonda do livro de reclamações, para as duas
## corridas comerem a mesma estante.
const ALVO := 1

## Degraus de qualidade usados na estante montada à mão.
const TORTO := 0
const REFINADO := 2

## Freguês do elenco usado para forçar a porta do fiado.
const ALDRIC := "aldric"

## Bolso mínimo do fiado, igual ao da sonda do livro: a etiqueta da peça tem de ficar
## acima dele para a visita entrar no caderno em vez de pagar à vista.
const BOLSO_MINIMO := 10


func _initialize() -> void:
	print("── o cartaz na gaveta não paga nem cobra ──")
	var g = await _loja("gaveta")
	_blindar(g)
	g.gold = 5000
	g.reputation = 60
	var taxas: Array[String] = []
	for s in range(0, 13):
		g.combo_streak = s
		taxas.append("%.4f" % float(g._combo_rate()))
	print("   degrau 0, sequência 0..12: %s" % ", ".join(taxas))
	g.combo_streak = 0
	for i in range(20):
		g._bump_combo(0)
	g._refresh_ui()
	print("   vinte vendas sem cartaz: sequência %d (teto %d) • recorde premiado %d (0) • cofre %d (0)" % [
		int(g.combo_streak), GameScript.COMBO_CEIL, int(g.combo_best), int(g.combo_gold)])
	print("   painel: %s" % _primeira_linha(str(g._combo_summary())))
	print("   botão: %s disabled=%s" % [
		_aspado(str(g.combo_button.text)), str(bool(g.combo_button.disabled))])
	seed(SEED_VAL)
	var controle := _cauda(40)
	seed(SEED_VAL)
	for i in range(200):
		g._combo_summary()
		g._combo_rate()
		g._combo_next_row()
	print("   200 leituras do painel não sorteiam: cauda igual ao controle? %s" % str(
		_cauda(40) == controle))
	await _fechar(g)

	print("── a escada, venda a venda ──")
	var e = await _loja("escada")
	_blindar(e)
	for rank in [1, 2, 3]:
		var row: Dictionary = e._combo_row(rank)
		e.combo_rank = rank
		var partes: Array[String] = []
		for s in [1, 2, 3, 4, 5, 6, 7, 8, 12]:
			e.combo_streak = s
			partes.append("%d:%+.4f" % [s, float(e._combo_rate())])
		print("   degrau %d • custo %d • fama %d • a partir da %dª • +%d por cento por venda • teto %d por cento" % [
			rank, int(row["cost"]), int(row["rep"]), int(row["start"]),
			int(round(float(row["step"]) * 100.0)), int(round(float(row["cap"]) * 100.0))])
		print("      %s" % ", ".join(partes))
	print("   teto da contagem: degrau 3 na sequência 12 lê %+.4f (o mesmo da 8)" % float(
		e._combo_rate()))
	await _fechar(e)

	print("── o bônus é ouro de verdade: mesma semente, mesma estante ──")
	var a := await _venda_medida(0, 7)
	var b := await _venda_medida(1, 7)
	var c := await _venda_medida(3, 7)
	var d := await _venda_medida(0, 0)
	for lado in [a, b, c]:
		print("   degrau %d, sequência %d: vendida %s • caixa %+d • peça %d • taxa %.4f • bônus %d" % [
			int(lado["degrau"]), int(lado["sequencia"]), str(bool(lado["vendida"])),
			int(lado["delta"]), int(lado["peca"]), float(lado["taxa"]), int(lado["bonus"])])
	print("   degrau 0, sequência 0 (controle): caixa %+d" % int(d["delta"]))
	print("   cartaz guardado é o controle exato (7 seguidas = 0 seguidas): %s • o cartaz nunca paga menos: %s • degrau 3 acima de 1: %s" % [
		str(int(a["delta"]) == int(d["delta"])),
		str(int(b["delta"]) >= int(a["delta"]) and int(c["delta"]) >= int(a["delta"])),
		str(int(c["delta"]) > int(b["delta"]))])
	print("   o que sobe do caixa É o bônus, centavo a centavo: degrau 1 %+d == %d • degrau 3 %+d == %d" % [
		int(b["delta"]) - int(a["delta"]), int(b["bonus"]),
		int(c["delta"]) - int(a["delta"]), int(c["bonus"])])
	print("   rodapé do balcão (degrau 3): %s" % _linha_do_combo(str(c["mural"])))
	print("   recorde e cofre do lado C: %d venda(s) premiadas, %d de ouro no caixa do combo" % [
		int(c["recorde"]), int(c["cofre"])])

	print("── quem corta a sequência ──")
	var f = await _loja("corte")
	_blindar(f)
	f.gold = 5000
	f.reputation = 60
	f.combo_rank = 3
	f.combo_streak = 9
	f.ticks = 1
	f.service_queue.clear()
	f.service_queue.append({"profile": _perfil_rapaz(), "waited": 40, "limit": 1})
	_raspar_estante(f)
	f._on_customer_tick()
	print("   visita que desistiu da fila: sequência 9 → %d • saíram da fila %d" % [
		int(f.combo_streak), int(f.queue_walkouts)])
	await _fechar(f)

	var v = await _loja("recusa")
	_blindar(v)
	v.gold = 5000
	v.reputation = 60
	_raspar_estante(v)
	_por_estante(v, ALVO, [1, 0, 0, 0, 0, 0])
	v.vip_rank = 3
	v.combo_rank = 3
	v.combo_streak = 8
	var livro_antes := int(v.complaints)
	_enfileirar(v, _perfil_vip(v))
	v._on_customer_tick()
	print("   capa fina devolvida (só torto na estante): sequência 8 → %d • degrau exigido %d • livro %d → %d" % [
		int(v.combo_streak), int(v._vip_row(3)["standard"]), livro_antes, int(v.complaints)])
	await _fechar(v)

	var h = await _loja("virada")
	_blindar(h)
	h.gold = 5000
	h.reputation = 60
	_raspar_estante(h)
	for i in range(h.products.size()):
		_por_estante(h, i, [0, 0, 2, 0, 1, 0])
	h.combo_rank = 3
	h._refresh_ui()
	# A foto do dia é lida ANTES do tique: a virada zera a sequência e o balanço zera as
	# contas do dia no mesmo tique em que as imprime, então medir depois do tique é medir
	# a manhã vazia e chamar de dia.
	var antes_sequencia := 0
	var antes_recorde := 0
	var antes_pago := 0
	var dia_antes := int(h.shop_day)
	var viradas_lidas := 0
	for i in range(120):
		antes_sequencia = int(h.combo_streak)
		antes_recorde = int(h.combo_day_best)
		antes_pago = int(h.combo_day_gold)
		h._on_customer_tick()
		if int(h.shop_day) == dia_antes:
			continue
		viradas_lidas += 1
		if viradas_lidas == 1:
			print("   meio do dia 1 (antes da virada): sequência %d • recorde do dia %d • %d de ouro pago no dia" % [
				antes_sequencia, antes_recorde, antes_pago])
		print("   virada %d (tique %d): sequência %d (0) • recorde do dia %d (0) • pago hoje %d (0) • dia %d → %d" % [
			viradas_lidas, i, int(h.combo_streak), int(h.combo_day_best), int(h.combo_day_gold),
			dia_antes, int(h.shop_day)])
		print("      balanço falou do cartaz: %s com %d pago(s) no dia • %s" % [
			str(str(h.day_report).contains("🔥 O cartaz pagou")), antes_pago,
			_linha_do_combo(str(h.day_report))])
		dia_antes = int(h.shop_day)
	print("   o que a virada guarda: recorde da vida %d • cofre da vida %d • degrau %d em %d virada(s)" % [
		int(h.combo_best), int(h.combo_gold), int(h.combo_rank), viradas_lidas])
	await _fechar(h)

	print("── a nota do fiado não conta o bônus duas vezes ──")
	var nota0 := await _nota_medida(0, 9)
	var nota3 := await _nota_medida(3, 9)
	print("   degrau 0: semente %d • peça %d • etiqueta %d no bolso de %d → nota %d • %d nota(s) • caixa %+d" % [
		int(nota0["semente"]), int(nota0["peca"]), int(nota0["etiqueta"]), BOLSO_MINIMO,
		int(nota0["nota"]), int(nota0["notas"]), int(nota0["caixa"])])
	print("   degrau 3: semente %d • peça %d • etiqueta %d no bolso de %d → nota %d • %d nota(s) • caixa %+d" % [
		int(nota3["semente"]), int(nota3["peca"]), int(nota3["etiqueta"]), BOLSO_MINIMO,
		int(nota3["nota"]), int(nota3["notas"]), int(nota3["caixa"])])
	print("   o bônus entra na nota junto com a peça: +%d de ouro anotado para a rua" % (
		int(nota3["nota"]) - int(nota0["nota"])))
	print("   e não sai do balcão: caixa %+d sem cartaz contra %+d com ele • diferença %+d (os dois têm de ser 0)" % [
		int(nota0["caixa"]), int(nota3["caixa"]), int(nota3["caixa"]) - int(nota0["caixa"])])
	print("   e não entra no cofre: degrau 3 com cofre %d (0) e recorde %d (0) • sequência %d (conta, paga zero)" % [
		int(nota3["cofre"]), int(nota3["recorde"]), int(nota3["sequencia"])])
	print("   balcão (degrau 3): %s" % _primeira_linha(str(nota3["mural"])))

	print("── pendurar o cartaz ──")
	var o = await _loja("compra")
	_blindar(o)
	o.gold = 30
	o.reputation = 40
	o._buy_combo_rank()
	print("   caixa curto: degrau %d • caixa %d → %d (igual) • mural: %s" % [
		int(o.combo_rank), 30, int(o.gold), _primeira_linha(str(o.last_event))])
	o.gold = 5000
	o.reputation = 2
	o._buy_combo_rank()
	print("   fama curta: degrau %d • caixa %d (5000) • mural: %s" % [
		int(o.combo_rank), int(o.gold), _primeira_linha(str(o.last_event))])
	o.reputation = 40
	var antes_1 := int(o.gold)
	o._buy_combo_rank()
	print("   pagando: degrau 0 → %d • caixa %d → %d (−%d) • fama 40 → %d • sequência zerada: %d" % [
		int(o.combo_rank), antes_1, int(o.gold), antes_1 - int(o.gold), int(o.reputation),
		int(o.combo_streak)])
	var degrau_2 := int(o.gold)
	o._buy_combo_rank()
	o._buy_combo_rank()
	print("   escada inteira: degrau %d • caixa %d → %d (−%d)" % [
		int(o.combo_rank), degrau_2, int(o.gold), degrau_2 - int(o.gold)])
	var no_topo := int(o.gold)
	o._buy_combo_rank()
	print("   degrau máximo não cobra de novo: caixa %d → %d (igual) • degrau %d" % [
		no_topo, int(o.gold), int(o.combo_rank)])
	print("   botão no topo: %s disabled=%s" % [
		_aspado(str(o.combo_button.text)), str(bool(o.combo_button.disabled))])
	await _fechar(o)

	print("── o painel nos três estados ──")
	var p = await _loja("painel")
	_blindar(p)
	p.gold = 1200
	p.reputation = 30
	p.combo_rank = 0
	p.combo_streak = 0
	p.combo_best = 4
	p.combo_gold = 90
	p._refresh_ui()
	print("   guardado: %s" % str(p._combo_summary()))
	print("      botão: %s disabled=%s" % [
		_aspado(str(p.combo_button.text)), str(bool(p.combo_button.disabled))])
	p.combo_rank = 2
	p.combo_streak = 1
	p._refresh_ui()
	print("   sem ritmo: %s" % str(p._combo_summary()))
	print("      botão: %s disabled=%s" % [
		_aspado(str(p.combo_button.text)), str(bool(p.combo_button.disabled))])
	p.combo_streak = 6
	p.combo_day_gold = 41
	p.combo_day_best = 6
	p._refresh_ui()
	print("   pagando: %s" % str(p._combo_summary()))
	print("      botão: %s disabled=%s" % [
		_aspado(str(p.combo_button.text)), str(bool(p.combo_button.disabled))])
	p.combo_rank = 3
	p.gold = 5
	p._refresh_ui()
	print("   caixa curto no topo: botão %s disabled=%s" % [
		_aspado(str(p.combo_button.text)), str(bool(p.combo_button.disabled))])
	await _fechar(p)

	print("── as quatro chaves atravessam o arquivo ──")
	var q = await _loja("arquivo")
	_blindar(q)
	q.gold = 1500
	q.combo_rank = 2
	q.combo_streak = 7
	q.combo_best = 9
	q.combo_gold = 388
	q._save_game()
	await _frames(2)
	var r = await _reload("relido")
	print("   relido: degrau %d (2) • sequência %d (7) • recorde %d (9) • cofre %d (388) • caixa %d" % [
		int(r.combo_rank), int(r.combo_streak), int(r.combo_best), int(r.combo_gold), int(r.gold)])
	await _fechar(r)
	_escrever_chave("combo_rank", "12")
	_escrever_chave("combo_streak", "-5")
	_escrever_chave("combo_best", "900")
	_escrever_chave("combo_gold", "-900")
	var l = await _reload("lixo")
	print("   payload lixo podado: degrau 12 → %d (teto %d) • sequência -5 → %d (0) • recorde 900 → %d (teto %d) • cofre -900 → %d (0)" % [
		int(l.combo_rank), GameScript.COMBO_TIERS.size() - 1, int(l.combo_streak),
		int(l.combo_best), GameScript.COMBO_CEIL, int(l.combo_gold)])
	await _fechar(l)
	_apagar_chaves()
	var n = await _reload("antigo")
	print("   sem as chaves no arquivo: degrau %d (0) • sequência %d (0) • recorde %d (0) • cofre %d (0)" % [
		int(n.combo_rank), int(n.combo_streak), int(n.combo_best), int(n.combo_gold)])
	seed(SEED_VAL)
	var controle_2 := _cauda(40)
	var caixa_antigo := int(n.gold)
	seed(SEED_VAL)
	for i in range(200):
		n._combo_summary()
		n._combo_rate()
		n._combo_next_row()
		n._refresh_ui()
	print("   save antigo é inerte: taxa %+.4f (0.0) • caixa %d → %d (igual) • cauda igual ao controle? %s" % [
		float(n._combo_rate()), caixa_antigo, int(n.gold), str(_cauda(40) == controle_2)])
	print("   cofre e recorde continuam 0: %d/%d" % [int(n.combo_gold), int(n.combo_best)])
	await _fechar(n)
	await _fechar(q)

	print("── reencarnar raspa o cartaz ──")
	var s = await _loja("reencarnar")
	_blindar(s)
	s.combo_rank = 3
	s.combo_streak = 11
	s.combo_best = 12
	s.combo_gold = 777
	s.combo_day_best = 5
	s.combo_day_gold = 33
	print("   vida com cartaz pendurado: %d/%d/%d/%d/%d/%d" % [
		int(s.combo_rank), int(s.combo_streak), int(s.combo_best), int(s.combo_gold),
		int(s.combo_day_best), int(s.combo_day_gold)])
	s._reset_run()
	print("   vida nova: %d/%d/%d/%d/%d/%d" % [
		int(s.combo_rank), int(s.combo_streak), int(s.combo_best), int(s.combo_gold),
		int(s.combo_day_best), int(s.combo_day_gold)])
	await _fechar(s)

	print("── os dois selos acendem na fronteira ──")
	var t = await _loja("selos")
	var painel: Array = t._achievement_definitions()
	print("   painel de conquistas: %d definições • os dois selos do cartaz estão na lista: %s" % [
		painel.size(), str(_tem_conquista(t, "combo_three") and _tem_conquista(t, "combo_paid_back"))])
	for caso in [[0, 0], [3, 0], [3, 599], [12, 600]]:
		t.unlocked_achievements.clear()
		t.player_xp = 0
		t.combo_best = int(caso[0])
		t.combo_gold = int(caso[1])
		t._check_achievements()
		print("   recorde %d / cofre %d: ritmo de balcão %s • o cartaz se paga %s" % [
			int(caso[0]), int(caso[1]),
			str(_tem_conquista_paga(t, "combo_three")), str(_tem_conquista_paga(t, "combo_paid_back"))])
	await _fechar(t)

	print("── 200 tiques com a prateleira cheia: o cartaz aparece na partida ──")
	var x0 := await _corrida(0)
	var x1 := await _corrida(1)
	var x3 := await _corrida(3)
	for lado in [x0, x1, x3]:
		print("   degrau %d na largada: servidos %d • sem comprar %d • caixa %d • nível %d • sequência no fim %d • recorde %d • cofre %d" % [
			int(lado["degrau"]), int(lado["servidos"]), int(lado["desanimados"]), int(lado["caixa"]),
			int(lado["nivel"]), int(lado["sequencia"]), int(lado["recorde"]), int(lado["cofre"])])
	print("   degrau 0 bate o número publicado pela sonda do livro (23 servidos / 8516 de caixa): %s" % str(
		int(x0["servidos"]) == 23 and int(x0["caixa"]) == 8516))
	print("   o cartaz põe ouro no caixa: 0 → %d • 1 → %d • 3 → %d" % [
		int(x0["caixa"]), int(x1["caixa"]), int(x3["caixa"])])
	print("   e paga ritmo de verdade: cofre 0/%d • 1/%d • 3/%d, recorde 0/%d • 1/%d • 3/%d" % [
		int(x0["cofre"]), int(x1["cofre"]), int(x3["cofre"]),
		int(x0["recorde"]), int(x1["recorde"]), int(x3["recorde"])])

	quit()


## ── ajudantes ──────────────────────────────────────────────────────────────────────

## Loja nova: save descartável apagado, cena instanciada, idioma travado, mundo parado,
## semente cravada e vida zerada. É o único jeito de duas medidas da mesma semente
## começarem no mesmo quadro.
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


## Marca toda conquista como já ganha: as medidas de caixa precisam disso, porque o selo
## do cartaz paga 70 de ouro e 2 de fama.
func _selar(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)
	g.player_xp = 0


## Selos + nível estacionado: venda dá experiência e level-up paga ouro — sem a rolha a
## etiqueta medida estaria comparando o prêmio do selo.
func _blindar(g) -> void:
	_selar(g)
	g.player_level = 60


## Terceira torneira, copiada da sonda do fiado: a FICHA do freguês paga no primeiro
## atendimento que ele recebe (ato 1 = 20 + nível×4 de ouro, 260 com o nível parado no 60).
## A corrida NÃO fecha a ficha, porque lá o freguês atendido é exatamente o que se quer
## contar — e fechá-la mudaria o 8516 publicado pela sonda do livro. Na nota do cartaz a
## ficha é só ruído: sem ela, o delta dos dois lados é o balcão, e o balcão a crédito é mudo.
func _raspar_fichas(g) -> void:
	for fregues_id in ["aldric", "lyra", "korvax", "mina", "tuck"]:
		g.regular_arc_seen[fregues_id] = GameScript.ARC_REWARDS.size()
		if not (g.regular_story_completed as Array).has(fregues_id):
			g.regular_story_completed.append(fregues_id)


func _tem_conquista(g, badge_id: String) -> bool:
	for achievement in g._achievement_definitions():
		if str(achievement["id"]) == badge_id:
			return true
	return false


func _tem_conquista_paga(g, badge_id: String) -> bool:
	return g.unlocked_achievements.has(badge_id)


func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto):
		partes.append(str(randi() % 1000))
	return ",".join(partes)


## O formatador do GDScript não tem `%r`; a sonda escreve as aspas ela mesma para o texto
## roubado de um painel não se misturar com a etiqueta do print.
func _aspado(texto: String) -> String:
	return "\"" + texto + "\""


func _primeira_linha(texto: String) -> String:
	return str(texto.split("\n")[0])


## A primeira linha do mural que menciona a marca pedida: o rodapé da faixa da loja e a
## meta de vida também escrevem no mesmo texto, e ler a última linha seria ler outra coisa.
func _linha_com(texto: String, marca: String) -> String:
	for linha in texto.split("\n"):
		if str(linha).contains(marca):
			return str(linha)
	return "(nenhuma linha com %s no mural)" % _aspado(marca)


## A linha do cartaz dentro do mural: a casa escreve 🔥 e o balcão ainda pode embaixo dela
## a meta de vida, a faixa da reforma e o degrau do freguês. Ler pelo marcador é ler o que
## o combo escreveu, não a última coisa que aconteceu.
func _linha_do_combo(texto: String) -> String:
	for linha in texto.split("\n"):
		if str(linha).begins_with("🔥"):
			return str(linha)
	return "(nenhuma linha 🔥 no mural)"


## Perfil comum, do jeito que o sorteio devolve: sem `vip`, com bolso e fala próprios, e
## sem `regular_id` — para o arco de freguês e a gorjeta de romance ficarem fora da medida.
func _perfil_base(g) -> Dictionary:
	var item: Dictionary = g.products[ALVO]
	return {
		"name": "A Aventureira de Capa Fina",
		"favorite": "Nada do catálogo",
		"line": "“Só passando pela sua vitrine.”",
		"portrait": 2,
		"tier": 0,
		"personal_request": false,
		"faction": "aventureiros",
		"budget": 90,
		"patience": 2,
		"item": str(item["name"]),
	}


## A visita carimbada pela própria loja, rodada até o sorteio acertar a capa: é o balcão
## lendo o que `_maybe_vip` produz, não a sonda reimplementando a fórmula.
func _perfil_vip(g) -> Dictionary:
	var base := _perfil_base(g)
	for i in range(4000):
		var attempt: Dictionary = g._maybe_vip(base)
		if bool(attempt.get("vip", false)):
			return attempt
	return base


## Um corpo anônimo para a fila: é o freguês de bairro, com o bolso do catálogo, e o que
## a sonda quer medir é a desistência dele, não a venda.
func _perfil_rapaz() -> Dictionary:
	return {
		"name": "O Rapaz da Porta",
		"favorite": "Nada do catálogo",
		"line": "“Passando.”",
		"portrait": 0,
		"tier": 0,
		"personal_request": false,
		"faction": "aventureiros",
		"budget": 90,
		"patience": 3,
	}


## Perfil de freguês do elenco montado à mão, com a sentinela que deixa saber, no fim do
## tique, se foi ESTA visita que o balcão atendeu.
func _perfil_fregues(fregues_id: String, bolso: int, favorite_id: String) -> Dictionary:
	var regular: Dictionary = Regulars.find(fregues_id)
	return {
		"name": str(regular.get("name", fregues_id)),
		"favorite": favorite_id,
		"line": "bate no bolso vazio e olha a vitrine.",
		"regular_id": fregues_id,
		"portrait": int(regular.get("portrait", 0)),
		"tier": 1,
		"personal_request": false,
		"probe_sentinela": "visita medida",
		"faction": str(regular.get("faction", "aventureiros")),
		"budget": bolso,
		"patience": 3,
	}


## Põe a visita no degrau da frente da fila: `_next_served_profile()` popa o índice 0.
func _enfileirar(g, profile: Dictionary) -> void:
	g.service_queue.clear()
	g.service_queue.append({
		"profile": profile,
		"waited": 0,
		"limit": int(profile.get("patience", 2)) + 9,
	})


## Estante raspada: um produto por vez na loja inteira, para o escolhido ser leitura e não
## sorteio de lista — e nenhuma venda suja acontecer sem a sonda querer.
func _raspar_estante(g) -> void:
	for entry in g.products:
		var produto: Dictionary = entry
		produto["stock"] = 0
		g.quality_stock[str(produto["id"])] = Quality.empty_stock()
		var lotes: Array = g._batches_for(str(produto["id"]))
		lotes.clear()


func _por_estante(g, index: int, counts: Array) -> void:
	var item: Dictionary = g.products[index]
	var produto_id := str(item["id"])
	var total := 0
	for t in range(counts.size()):
		total += int(counts[t])
	item["stock"] = total
	g.quality_stock[produto_id] = Quality.empty_stock()
	var registro: Array = g._quality_for(produto_id)
	for t in range(counts.size()):
		registro[t] = int(counts[t])
	var lotes: Array = g._batches_for(produto_id)
	lotes.clear()
	for t in range(counts.size()):
		for n in range(int(counts[t])):
			lotes.append({"tier": t, "day": int(g.shop_day)})


## Deixa UM produto com estoque na loja: o mais barato cuja etiqueta caiba acima do bolso
## mínimo e abaixo do teto do degrau pedido. É a porta do fiado, copiada da sonda do livro.
func _peça_emprestavel(g, degrau: int) -> int:
	var teto := 0
	if degrau > 0:
		teto = int(GameScript.CREDIT_TIERS[degrau]["limit"])
	var melhor := -1
	var melhor_preco := 0
	for i in range(g.products.size()):
		if not bool(g._is_product_unlocked(g.products[i])):
			continue
		_raspar_estante(g)
		g._add_piece(i, REFINADO)
		var preco: int = int(g._shelf_price(i))
		if preco <= BOLSO_MINIMO:
			continue
		if teto > 0 and preco > teto:
			continue
		if melhor < 0 or preco < melhor_preco:
			melhor = i
			melhor_preco = preco
	_raspar_estante(g)
	if melhor >= 0:
		g._add_piece(melhor, REFINADO)
	return melhor


## Manda a visita ao balcão e roda tiques até que ELA seja atendida. Devolve a semente.
func _servir_visitante(g, fregues_id: String, bolso: int, alvo: int) -> int:
	var favorite := ""
	if alvo >= 0 and alvo < g.products.size():
		favorite = str(g.products[alvo]["id"])
	for tentativa in range(20):
		var semente := SEED_VAL + tentativa
		g.ticks = 1
		g.service_queue.clear()
		g.service_queue.append({"profile": _perfil_fregues(fregues_id, bolso, favorite),
			"waited": 0, "limit": 9})
		seed(semente)
		g._on_customer_tick()
		if not _fila_tem_sentinela(g):
			return semente
	return -1


func _fila_tem_sentinela(g) -> bool:
	for entry in g.service_queue:
		if str((entry as Dictionary).get("profile", {}).get("probe_sentinela", "")) != "":
			return true
	return false


## Uma venda medida, com o cartaz no degrau `degrau` e a sequência já aquecida em
## `sequencia`. Estante de um produto só (Refinado que o bolso paga), visita anônima na
## frente da fila, um tique. O que a sonda lê é o delta do caixa — assim o bônus aparece
## como dinheiro, não como porcentagem na parede.
func _venda_medida(degrau: int, sequencia: int) -> Dictionary:
	var g = await _loja("venda %d/%d" % [degrau, sequencia])
	_blindar(g)
	g.gold = 5000
	g.reputation = 60
	_raspar_estante(g)
	_por_estante(g, ALVO, [0, 0, 1, 0, 0, 0])
	g.combo_rank = degrau
	g.combo_streak = sequencia
	g._refresh_ui()
	var etiqueta := int(g._shelf_price(ALVO))
	var peca := int(g._piece_price(g.products[ALVO], REFINADO))
	var taxa_antes := float(g._combo_rate())
	var caixa_antes := int(g.gold)
	var servidos_antes := int(g.customers_served)
	_enfileirar(g, _perfil_base(g))
	g._on_customer_tick()
	var resultado := {
		"degrau": degrau,
		"sequencia": sequencia,
		"etiqueta": etiqueta,
		"peca": peca,
		"taxa": taxa_antes,
		"delta": int(g.gold) - caixa_antes,
		"vendida": int(g.customers_served) > servidos_antes,
		"bonus": int(round(float(peca) * taxa_antes)),
		"mural": str(g.last_event),
		"recorde": int(g.combo_best),
		"cofre": int(g.combo_gold),
	}
	await _fechar(g)
	return resultado


## A mesma visita, agora pela porta do fiado: o freguês tem bolso menor que a etiqueta, a
## casa tem o livro aberto (degrau 1) e a estante deixa só a peça mais barata que cabe no
## teto do caderno. É assim que o bônus aparece na nota — anotado junto com a peça, sem
## ouro no caixa e fora do cofre da vida, porque o dinheiro ainda não entrou na casa.
func _nota_medida(degrau: int, sequencia: int) -> Dictionary:
	var g = await _loja("nota %d/%d" % [degrau, sequencia])
	_blindar(g)
	_raspar_fichas(g)
	g.gold = 5000
	g.reputation = 60
	g.credit_rank = 1
	g.combo_rank = degrau
	g.combo_streak = sequencia
	## A régua da faixa é o `business_score`, e a virada da obra paga ouro no meio do
	## corredor. Com o painel refreshado antes da captura, a faixa já subiu e o que sobra
	## no delta é só o balcão — senão a nota seria medida contra o caixão da reforma.
	g._refresh_ui()
	var alvo := _peça_emprestavel(g, 1)
	var etiqueta := int(g._shelf_price(alvo)) if alvo >= 0 else 0
	var caixa_antes := int(g.gold)
	var semente := _servir_visitante(g, ALDRIC, BOLSO_MINIMO, alvo)
	var nota: Dictionary = g.credit_book.get(ALDRIC, {})
	var resultado := {
		"degrau": degrau,
		"semente": semente,
		"peca": alvo,
		"etiqueta": etiqueta,
		"nota": int(nota.get("owed", 0)),
		"notas": int(g.credit_book.size()),
		"caixa": int(g.gold) - caixa_antes,
		"cofre": int(g.combo_gold),
		"recorde": int(g.combo_best),
		"sequencia": int(g.combo_streak),
		"mural": str(g.last_event),
	}
	await _fechar(g)
	return resultado


## A corrida de 200 tiques com a mesma semente e o cartaz no degrau `degrau`. A prateleira
## é a mesma da sonda do livro (2 Refinado + 1 Mítico por produto): o lado 0 tem de bater
## exatamente o número publicado por ela, porque é assim que a aditividade aparece medida.
## Selada e com o nível parado, para nenhum prêmio entrar na conta. Todos os tiques rodam
## em sequência, sem `await` no meio: o rodízio do palco é guiado por quadros reais.
func _corrida(degrau: int) -> Dictionary:
	var g = await _loja("corrida %d" % degrau)
	_blindar(g)
	g.gold = 5000
	g.reputation = 60
	_raspar_estante(g)
	for i in range(g.products.size()):
		_por_estante(g, i, [0, 0, 2, 0, 1, 0])
	g.combo_rank = degrau
	g.combo_streak = 0
	g._refresh_ui()
	for i in range(200):
		g._on_customer_tick()
	var resultado := {
		"degrau": degrau,
		"servidos": int(g.customers_served),
		"desanimados": int(g.disappointed_customers),
		"caixa": int(g.gold),
		"nivel": int(g.player_level),
		"sequencia": int(g.combo_streak),
		"recorde": int(g.combo_best),
		"cofre": int(g.combo_gold),
	}
	await _fechar(g)
	return resultado


## Reescreve uma chave do save descartável no disco, sem passar pelo jogo.
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


## Tira as quatro chaves do cartaz: é o save antigo, escrito antes de a casa pendurar
## qualquer cartaz na parede.
func _apagar_chaves() -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	for chave in ["combo_rank", "combo_streak", "combo_best", "combo_gold"]:
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
	var caminho := _caminho_save()
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
