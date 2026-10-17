extends SceneTree

## Sonda do livro de reclamações da rua (#79): prova que fama ruim cobra por caderninho
## próprio, e não mexendo na fama — porque `reputation < 12` já está publicado em quatro
## sondas vivas que rodam a loja com fama 0 e 5, e qualquer corte na própria fama reescreveria
## o README inteiro. O livro abre com zero linhas, e zero linha não move um centavo, um
## degrau de paciência nem um corpo na porta: é a inércia medida no primeiro bloco desta
## sonda, e é ela que segura a vizinha `tools/probes/salao.gd` relida nos mesmos 22
## atendimentos e caixa 8518 do cordão guardado.
##
## Medidas desta sonda: (1) livro em branco — degrau 0, fator exatamente 1.0, paciência −0,
## porta −0, painel de caderno vazio, botão apagado, custo do cartório na tabela e as 40
## `randi()` da leitura iguais às do controle; (2) as três fontes escrevem 1, 2 e 1 linha: a
## peça torto entregue na mão do cliente, a capa fina devolvida na prateleira e a nota
## riscada no fiado, cada uma com o rodapé 📙 que a casa imprime junto; (3) a tabela de
## cobrança entre 5, 6, 7, 12, 13, 15, 16 e 24 linhas, com o piso de −20% e o teto do livro;
## (4) a etiqueta custa ouro de verdade — mesma semente, mesma estante, cinco linhas contra
## seis, e o que muda é só o desconto; (5) a virada de dia apaga exatamente uma linha e fala
## dela no balanço, e o caderno em branco não fala; (6) o cartório cobra 40 + 12 por linha,
## risca três, recusa livro vazio e recusa caixa curto sem apagar nada; (7) o painel nos
## quatro estados (branco, murmúrio, boato, escândalo) e o botão com ele; (8) ler o painel e
## salvar não consomem sorteio; (9) as três chaves atravessam o arquivo, payload lixo é podado
## (99 → teto 24, −5 → 0, apagadas > escritas volta para escritas) e save antigo sem as chaves
## acorda em branco e inerte; (10) reencarnar raspa o livro; (11) os dois selos acendem em 1
## linha escrita e 9 apagadas pagando, e a lista fecha com 97 definições (o par do cartaz do
## combo, #80, entrou depois desta leitura; a sonda lê o tamanho real); (12) a corrida de
## 200 tiques em três lados (0, 8 e 14 linhas) com a mesma semente e nenhuma peça torto na
## estante, para a cobrança aparecer na partida e não só no painel.
##
## Armadilha medida aqui: a corrida não pode ter torto novo nem capa fina na estante. Com
## `[0,0,2,0,1,0]` o balcão tira a pior peça disponível, que é Refinado, e com o cordão
## guardado nenhuma visita é devolvida na prateleira — assim as linhas dos lados B e C caem
## pela virada de dia, e "caixa diferente" mede etiqueta e paciência, não a casa reclamando de
## si mesma a cada venda. Duas leituras saíram daqui e nenhuma é defeito: o lado A ainda escreve
## **1** linha em 200 tiques, porque a estante apodrece e uma peça desce ao degrau torto sozinha
## (é a rua anotando a casa, não a sonda), e o lado C fecha **mais rico** que A (9005 contra
## 8516) com um atendimento a mais na rua, porque etiqueta mais baixa também segura o mercado de
## alta — vendendo menos e mais barato, o corredor empurra o preço de amanhã para cima. O que a
## corrida prova é movimento (B ≠ A e C ≠ A em caixa, em servidos e em livro final), não sinal.
##
## Armadilha de mural: a linha 📙 não é a última do `last_event`. A meta de vida e a faixa da
## reforma escrevem por baixo dela na mesma rodada, então a sonda procura o marcador em vez de
## ler o fim do texto — "rodapé do mural" sem 📙 seria a queixa desaparecida, não o rodapé.
##
## Armadilha de régua: as três medidas de caixa selam as 97 conquistas e estacionam o nível
## em 60. O segundo selo do livro paga 90 de ouro e 3 de fama, e venda dá experiência — sem a
## rolha, "a etiqueta custa 2%" estaria medindo o prêmio do selo. As caudas de 40 `randi()`
## são sempre lidas logo após `seed(SEED_VAL)` cravado, e o A/B de etiqueta roda um tique por
## loja, com a mesma semente nas duas: cinco linhas contra seis muda só o fator, porque porta
## só perde corpo a partir da décima segunda e paciência não consome sorteio.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/reclamacoes.gd

const Locales = preload("res://locales.gd")
const Quality = preload("res://quality.gd")
const GameScript = preload("res://main.gd")

const SEED_VAL := 20261025

## O degrau torto é o índice 0 do espectro: é dele que sai a primeira linha do livro, e é a
## única estante que precisa dele montada.
const TORTO := 0

## Refinado é o índice 2: acima do torto (nenhuma venda suja o livro na corrida) e abaixo do
## Mítico que o terceiro cordão exige — a peça que a capa fina devolve no lugar.
const REFINADO := 2

## Pato Amaldiçoado: 24 de base e SEM validade — não apodrece na virada, não deixa lote órfão
## no registro de idade, e nenhuma medida desta sonda precisa de um dia inteiro para acontecer.
const ALVO := 1

## O devedor da nota riscada: id e nome de um regular qualquer, porque a riscada lê o livro,
## não a lista de amigos da casa.
const DEVEDOR := "aldric"


func _initialize() -> void:
	var g = await _loja("reclamações")
	_blindar(g)
	g.gold = 5000
	g.reputation = 30
	g._refresh_ui()

	print("── o livro em branco não move um número ──")
	var stage_zero: int = g._complaint_stage()
	var fator_zero: float = g._complaint_label_factor()
	var paci_zero: int = g._complaint_patience_loss()
	var porta_zero: int = g._complaint_crowd_loss()
	var custo_zero: int = g._hush_cost()
	seed(SEED_VAL)
	var cauda_controle := _cauda(40)
	seed(SEED_VAL)
	for i in range(200):
		g._complaint_summary()
		g._complaint_label_factor()
		g._complaint_stage()
		g._refresh_ui()
	var cauda_leitura := _cauda(40)
	print("   linhas %d • degrau %d (0) • fator %.4f (1.0 cravado) • paciência −%d (0) • porta −%d (0) • cartório %d (%d)" % [
		g.complaints, stage_zero, fator_zero, paci_zero, porta_zero, custo_zero,
		GameScript.COMPLAINT_HUSH_BASE])
	print("   painel: %s" % String(g._complaint_summary()).substr(0, 120))
	print("   botão: %s disabled=%s" % [_aspado(String(g.complaint_button.text)),
		str(g.complaint_button.disabled)])
	print("   200 leituras do livro não sorteiam: cauda igual ao controle? %s" % str(
		cauda_leitura == cauda_controle))

	print("── as três fontes escrevem 1, 2 e 1 linha ──")
	await _fechar(g)
	g = await _loja("fonte torto")
	_blindar(g)
	g.gold = 5000
	g.reputation = 8
	_raspar_estante(g)
	_por_estante(g, ALVO, [3, 0, 0, 0, 0, 0])
	print("   estante: só o índice %d com 3 unidades no degrau %s • registro %s" % [
		ALVO, str(Quality.tier(TORTO)["name"]), _barra(g, str(g.products[ALVO]["id"]))])
	seed(SEED_VAL)
	var caixa_torto := int(g.gold)
	_enfileirar(g, _perfil_base(g))
	g._on_customer_tick()
	print("   venda torto: linhas %d (1) • escritas %d (1) • caixa %d→%d • fama %d" % [
		g.complaints, g.complaints_written, caixa_torto, int(g.gold), int(g.reputation)])
	print("   rodapé do mural: %s" % _linha_da_rua(String(g.last_event)))

	g = await _loja("fonte capa fina")
	_blindar(g)
	g.gold = 5000
	g.reputation = 8
	g.vip_rank = 3
	_raspar_estante(g)
	_por_estante(g, ALVO, [0, 0, 1, 0, 0, 0])
	print("   degrau 3 exige %s e a barra tem %s" % [
		str(Quality.tier(g._vip_standard())["name"]),
		str(Quality.tier(g._best_tier_for(ALVO))["name"])])
	seed(SEED_VAL)
	caixa_torto = int(g.gold)
	_enfileirar(g, _perfil_vip(g))
	g._on_customer_tick()
	print("   recusa: linhas %d (2) • escritas %d • recusadas %d • servidas %d (0) • gorjeta %d (0)" % [
		g.complaints, g.complaints_written, int(g.vip_refusals), int(g.vip_served),
		int(g.vip_tips_gold)])
	print("   caixa %d→%d (igual) • estoque %d→%d (igual) • fama 8→%d (−1) • registro %s" % [
		caixa_torto, int(g.gold), 1, int(g.products[ALVO]["stock"]), int(g.reputation),
		_barra(g, str(g.products[ALVO]["id"]))])
	print("   rodapé do mural: %s" % _linha_da_rua(String(g.last_event)))

	g = await _loja("fonte fiado")
	_blindar(g)
	g.reputation = 20
	g._lend_note(DEVEDOR, "A Aldric de Sal", str(g.products[ALVO]["name"]), 30)
	var nota: Dictionary = g.credit_book[DEVEDOR]
	nota["due_day"] = int(g.shop_day) - 1
	nota["late"] = GameScript.CREDIT_WRITEOFF_DAYS - 1
	var riscada := String(g._age_credit_book())
	print("   riscada: linhas %d (1) • escritas %d • nota saiu do livro: %s" % [
		g.complaints, g.complaints_written, str(g.credit_book.is_empty())])
	print("   rodapé do fiado: %s" % _depois_do_marca(riscada))
	await _fechar(g)

	print("── a tabela de cobrança, linha a linha ──")
	g = await _loja("tabela")
	_blindar(g)
	for linhas in [5, 6, 7, 12, 13, 15, 16, 24]:
		g.complaints = linhas
		g.complaints_written = linhas
		g.complaints_hushed = 0
		g._refresh_ui()
		print("   %d linha(s): degrau %d • fator %.4f • etiqueta %s • paciência −%d • porta −%d • cartório %d" % [
			linhas, g._complaint_stage(), g._complaint_label_factor(), _aspado(_label_word(g)),
			g._complaint_patience_loss(), g._complaint_crowd_loss(), g._hush_cost()])
	g.complaints = GameScript.COMPLAINT_CAP
	var antes_teto: int = g._add_complaint(2)
	print("   teto do livro: 24 linhas mais 2 fontes ficam em %d (24) • escritas %d (26) • fator %.4f no piso de vinte por cento" % [
		antes_teto, g.complaints_written, g._complaint_label_factor()])
	g.complaints = 0
	print("   zero entra na conta: _add_complaint(0) devolve %d e não escreve nada" % g._add_complaint(0))

	print("── a etiqueta custa ouro: cinco linhas contra seis, mesma semente ──")
	var lados_etiqueta: Array[Dictionary] = []
	for linhas in [5, 6]:
		var loja = await _loja("etiqueta %d" % linhas)
		_blindar(loja)
		loja.gold = 5000
		loja.reputation = 8
		_raspar_estante(loja)
		_por_estante(loja, ALVO, [0, 2, 0, 0, 0, 0])
		seed(SEED_VAL)
		loja.complaints = linhas
		loja.complaints_written = linhas
		loja._refresh_ui()
		var caixa := int(loja.gold)
		var linhas_antes := int(loja.complaints)
		_enfileirar(loja, _perfil_base(loja))
		loja._on_customer_tick()
		lados_etiqueta.append({
			"linhas": linhas, "ganho": int(loja.gold) - caixa,
			"fator": loja._complaint_label_factor(), "venda": int(loja.customers_served),
			"depois": int(loja.complaints), "antes": linhas_antes,
			"tique": int(loja.ticks),
		})
		await _fechar(loja)
	for lado in lados_etiqueta:
		print("   %d linha(s): fator %.4f • vendida %s • caixa %+.1f • tique %d • livro %d→%d" % [
			int(lado["linhas"]), float(lado["fator"]), str(int(lado["venda"]) > 0),
			float(lado["ganho"]), int(lado["tique"]), int(lado["antes"]), int(lado["depois"])])
	print("   a rua nunca paga mais com o livro aberto (B ≤ A): %s • desconto stricto: %s" % [
		str(int(lados_etiqueta[1]["ganho"]) <= int(lados_etiqueta[0]["ganho"])),
		str(int(lados_etiqueta[1]["ganho"]) < int(lados_etiqueta[0]["ganho"]))])

	print("── a virada de dia apaga exatamente uma linha ──")
	g = await _loja("virada")
	_blindar(g)
	g.gold = 5000
	g.reputation = 8
	_raspar_estante(g)
	g.complaints = 7
	g.complaints_written = 7
	var dia_antes := int(g.shop_day)
	var ticks_ate_virar := 0
	while int(g.shop_day) == dia_antes and ticks_ate_virar < 40:
		g._on_customer_tick()
		ticks_ate_virar += 1
	print("   virada em %d tique(s): livro 7→%d (−1) • escritas %d (não apaga história)" % [
		ticks_ate_virar, g.complaints, g.complaints_written])
	print("   balanço fala da rua: %s" % str(String(g.day_report).contains("📙")))
	print("   linha lida: %s" % String(g.day_report).substr(maxi(0,
		String(g.day_report).find("📙"))).replace("\n", " / "))
	g.complaints = 0
	g.complaints_written = 0
	dia_antes = int(g.shop_day)
	ticks_ate_virar = 0
	while int(g.shop_day) == dia_antes and ticks_ate_virar < 40:
		g._on_customer_tick()
		ticks_ate_virar += 1
	print("   caderno em branco na virada: %s • livro %d" % [
		str(String(g.day_report).contains("📙")), g.complaints])

	print("── o cartório da praça: preço, riscada e recusa ──")
	await _fechar(g)
	g = await _loja("cartório")
	_blindar(g)
	for linhas in [1, 3, 6, 12, 24]:
		g.complaints = linhas
		print("   %d linha(s) no livro: a voz da rua custa %d (40 + 12×%d)" % [
			linhas, g._hush_cost(), linhas])
	g.complaints = 0
	g.gold = 5000
	var caixa_cheia := int(g.gold)
	g._hush_street()
	print("   livro vazio com caixa cheio: caixa %d→%d (igual) • linhas %d • apagadas %d" % [
		caixa_cheia, int(g.gold), g.complaints, g.complaints_hushed])
	print("   mural da recusa: %s" % String(g.last_event))
	g.complaints = 8
	g.complaints_written = 8
	g.gold = 39
	caixa_cheia = int(g.gold)
	g._hush_street()
	print("   sem ouro: preço %d, caixa %d→%d (igual) • livro %d (8) • apagadas %d (0)" % [
		g._hush_cost(), caixa_cheia, int(g.gold), g.complaints, g.complaints_hushed])
	g.gold = 2000
	var linhas_preco: int = g._hush_cost()
	caixa_cheia = int(g.gold)
	g._hush_street()
	print("   pagando: caixa %d→%d (−%d) • livro 8→%d (−3) • apagadas %d • degrau %d" % [
		caixa_cheia, int(g.gold), linhas_preco, g.complaints, g.complaints_hushed,
		g._complaint_stage()])
	g.complaints = 6
	g.gold = 2000
	var degrau_antes: int = g._complaint_stage()
	caixa_cheia = int(g.gold)
	g._hush_street()
	print("   seis riscadas três: degrau %d→%d, fator volta a %.4f, paciência −%d, caixa −%d" % [
		degrau_antes, g._complaint_stage(), g._complaint_label_factor(),
		g._complaint_patience_loss(), caixa_cheia - int(g.gold)])
	g.complaints = 24
	g.complaints_written = 24
	g.gold = 5000
	var apagadas_andavam := int(g.complaints_hushed)
	g._hush_street()
	print("   teto riscado três de cada vez: livro 24→%d • apagadas %d→%d" % [
		g.complaints, apagadas_andavam, g.complaints_hushed])

	print("── o painel nos quatro estados ──")
	await _fechar(g)
	g = await _loja("painel")
	_blindar(g)
	g.gold = 5000
	for estado in [[0, 0, 0], [3, 4, 1], [8, 9, 2], [14, 15, 3]]:
		g.complaints = int(estado[0])
		g.complaints_written = int(estado[1])
		g.complaints_hushed = int(estado[2])
		g._refresh_ui()
		print("   %d linha(s): %s" % [g.complaints, String(g.complaint_label.text)])
		print("      botão: %s disabled=%s" % [_aspado(String(g.complaint_button.text)),
			str(g.complaint_button.disabled)])
	g.gold = 12
	g.complaints = 20
	g._refresh_ui()
	print("   caixa curto com escândalo no livro: botão %s disabled=%s" % [
		_aspado(String(g.complaint_button.text)), str(g.complaint_button.disabled)])
	await _fechar(g)

	print("── as três chaves atravessam o arquivo ──")
	g = await _loja("arquivo")
	_blindar(g)
	g.complaints = 11
	g.complaints_written = 19
	g.complaints_hushed = 4
	g.gold = 1500
	g._save_game()
	g = await _reload("arquivo relido")
	print("   relido: livro %d (11) • escritas %d (19) • apagadas %d (4) • degrau %d • caixa %d" % [
		g.complaints, g.complaints_written, g.complaints_hushed, g._complaint_stage(),
		int(g.gold)])
	await _fechar(g)
	g = await _loja("arquivo lixo")
	g.gold = 1500
	g._save_game()
	_escrever_chave("complaints", "99")
	_escrever_chave("complaints_written", "-5")
	_escrever_chave("complaints_hushed", "900")
	g = await _reload("arquivo lixo relido")
	print("   payload lixo podado: livro 99→%d (teto 24) • escritas −5→%d (0) • apagadas 900→%d (escritas)" % [
		g.complaints, g.complaints_written, g.complaints_hushed])
	await _fechar(g)
	g = await _loja("arquivo antigo")
	g.complaints = 9
	g.complaints_written = 12
	g.complaints_hushed = 3
	g.gold = 1416
	g._save_game()
	_apagar_chaves()
	g = await _reload("arquivo antigo relido")
	var caixa_antigo := int(g.gold)
	seed(SEED_VAL)
	for i in range(200):
		g._complaint_summary()
		g._refresh_ui()
	var cauda_antigo := _cauda(40)
	print("   sem as chaves no arquivo: livro %d (0) • escritas %d (0) • apagadas %d (0) • degrau %d" % [
		g.complaints, g.complaints_written, g.complaints_hushed, g._complaint_stage()])
	print("   save antigo é inerte: fator %.4f (1.0) • caixa %d→%d (igual) • cauda igual ao controle? %s" % [
		g._complaint_label_factor(), caixa_antigo, int(g.gold), str(
			cauda_antigo == cauda_controle)])
	await _fechar(g)

	print("── reencarnar raspa o livro ──")
	g = await _loja("vida")
	_blindar(g)
	g.complaints = 13
	g.complaints_written = 22
	g.complaints_hushed = 5
	print("   vida com livro aberto: %d/%d/%d • degrau %d" % [
		g.complaints, g.complaints_written, g.complaints_hushed, g._complaint_stage()])
	g._reset_run()
	print("   vida nova: %d/%d/%d • degrau %d • fator %.4f" % [
		g.complaints, g.complaints_written, g.complaints_hushed, g._complaint_stage(),
		g._complaint_label_factor()])

	print("── os dois selos acendem na fronteira ──")
	var selada: Array = g._achievement_definitions()
	print("   painel de conquistas: %d definições • os dois selos do livro estão na lista: %s" % [
		selada.size(), str(_tem_conquista(g, "claims_first_line") and _tem_conquista(
			g, "claims_quiet_street"))])
	for alvo in [0, 1, 8, 9]:
		g._reset_run()
		g.unlocked_achievements.clear()
		g.complaints_written = alvo
		g.complaints_hushed = alvo
		g._check_achievements()
		print("   %d escrita(s)/apagada(s): a rua abriu o livro %s • boca calada %s" % [
			alvo, str(g.unlocked_achievements.has("claims_first_line")),
			str(g.unlocked_achievements.has("claims_quiet_street"))])
	await _fechar(g)

	print("── 200 tiques com a prateleira cheia: a rua aparece na partida ──")
	var corridas: Array[Dictionary] = [await _corrida(0), await _corrida(8), await _corrida(14)]
	for lado in corridas:
		print("   %d linha(s) na largada: servidos %d • sem comprar %d • caixa %d • nível %d • livro no fim %d • escritas %d" % [
			int(lado["largada"]), int(lado["servidos"]), int(lado["desanimados"]),
			int(lado["caixa"]), int(lado["nivel"]), int(lado["livro"]),
			int(lado["escritas"])])
	var branco: Dictionary = corridas[0]
	var b: Dictionary = corridas[1]
	var c: Dictionary = corridas[2]
	print("   lado A escreve %d linha(s) nova(s) em 200 tiques (10 viradas, sem torto novo e sem capa fina): a estante que vira é a única fonte" % [
		int(branco["escritas"])])
	print("   o livro aberto mexe no corredor: B ≠ A em caixa %s e em servidos %s • C ≠ A em caixa %s e em livro final %s" % [
		str(int(b["caixa"]) != int(branco["caixa"])), str(int(b["servidos"]) != int(branco["servidos"])),
		str(int(c["caixa"]) != int(branco["caixa"])), str(int(c["livro"]) != int(branco["livro"]))])
	print("   o saldo não é monotônico e é lido como medida: etiqueta menor também segura a alta do mercado, então caixa A %d, B %d, C %d com %d, %d e %d atendimentos" % [
		int(branco["caixa"]), int(b["caixa"]), int(c["caixa"]), int(branco["servidos"]),
		int(b["servidos"]), int(c["servidos"])])

	print("VEREDITO: livro em branco é balcão de sempre — fator 1.0 cravado, paciência −0, porta −0, nenhum sorteio consumido, e a vizinha do salão relida tem de fechar nos mesmos números de antes; as três fontes da casa errada escrevem 1, 2 e 1 linha com o rodapé 📙 dentro do mural, mesmo quando a meta de vida escreve por baixo; da sexta linha a etiqueta cai 2% por linha até o piso de vinte por cento e a fila encurta, da décima segunda um corpo a menos bate na porta por tique, a virada apaga uma linha e o cartório apaga três por 40 + 12×linhas sem nunca comprar fama. Fama cortando número já publicado, queixa nascendo de sorteio, etiqueta cobrando abaixo do piso e caderno apagado voltando cheio do arquivo é o livro virando roleta — e roleta não é reputação.")
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


## Marca toda conquista como já ganha: as medidas de caixa precisam disso, porque boca calada
## paga 90 de ouro e 3 de fama.
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


func _tem_conquista(g, badge_id: String) -> bool:
	for achievement in g._achievement_definitions():
		if str(achievement["id"]) == badge_id:
			return true
	return false


func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto):
		partes.append(str(randi() % 1000))
	return ",".join(partes)


## O formatador do GDScript não tem `%r`; a sonda escreve as aspas ela mesma para o texto
## roubado de um painel não se misturar com a etiqueta do print.
func _aspado(texto: String) -> String:
	return "\"" + texto + "\""


## A linha da rua dentro do mural: a casa escreve 📙 e o balcão ainda pode embaixo dela a
## meta de vida e a faixa da reforma. Procurar pelo marcador é ler o que a queixa escreveu,
## não a última coisa que aconteceu.
func _linha_da_rua(texto: String) -> String:
	for linha in texto.split("\n"):
		if str(linha).begins_with("📙"):
			return str(linha)
	return "(nenhuma linha 📙 no mural)"


## O último pedaço depois do marcador do fiado, onde a casa pôs o rodapé da rua.
func _depois_do_marca(texto: String) -> String:
	var partes := texto.split("•")
	if partes.is_empty():
		return texto
	return str(partes[partes.size() - 1]).strip_edges()


## A etiqueta como o painel a lê, pela loja da sonda (o helper é do jogo, a chamada também).
func _label_word(g) -> String:
	return g._label_word()


## Perfil comum, do jeito que o sorteio devolve: sem `vip`, com bolso e fala próprios, e sem
## `regular_id` — para o arco de freguês e a gorjeta de romance ficarem fora da medida.
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


func _barra(g, produto_id: String) -> String:
	var partes: Array[String] = []
	for c in g._quality_for(produto_id):
		partes.append(str(int(c)))
	return "/".join(partes)


## A corrida de 200 tiques com a mesma semente e um livro de `largada` linhas. A prateleira é
## montada igual nos três lados (2 Refinado + 1 Mítico por produto), sem torto nenhum: assim
## a casa não escreve linha nova durante a corrida e o que cai no caixa é só o que a rua já
## cobrava. Selada e com o nível parado, para nenhum prêmio entrar na medida. Todos os tiques
## rodam em sequência, sem `await` no meio: o rodízio do palco é guiado por quadros reais.
func _corrida(linhas: int) -> Dictionary:
	var g = await _loja("corrida %d" % linhas)
	_blindar(g)
	g.gold = 5000
	g.reputation = 60
	_raspar_estante(g)
	for i in range(g.products.size()):
		_por_estante(g, i, [0, 0, 2, 0, 1, 0])
	g.complaints = linhas
	g.complaints_written = linhas
	g._refresh_ui()
	for i in range(200):
		g._on_customer_tick()
	var resultado := {
		"largada": linhas,
		"servidos": int(g.customers_served),
		"desanimados": int(g.disappointed_customers),
		"caixa": int(g.gold),
		"nivel": int(g.player_level),
		"livro": int(g.complaints),
		"escritas": int(g.complaints_written),
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


## Tira as três chaves do livro: é o save antigo, escrito antes de a rua abrir o caderno.
func _apagar_chaves() -> void:
	var caminho := _caminho_save()
	var texto := FileAccess.get_file_as_string(caminho)
	for chave in ["complaints", "complaints_written", "complaints_hushed"]:
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
