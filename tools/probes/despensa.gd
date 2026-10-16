extends SceneTree

## Sonda da despensa (#66): prova que mercadoria perecível cobra prazo, não sorte nem
## margem. Cada virada de dia a peça mais antiga de uma estante com validade desce um
## degrau de qualidade — e a que já está no Torto sai pela porta. Medidas desta sonda:
## (1) envelhecer não consome um único sorteio, então a mesma semente desenha o mesmo
## vândalo com ou sem poção velha na prateleira; (2) o depósito de sal soma uma
## validade inteira por nível (6 → 12 → 18 → 24 dias) e não muda o preço de vitrine em
## um único ponto de etiqueta; (3) a estante acorda fresca — peça sem registro de idade
## entra como recém-posta, e um save antigo ou quebrado não é lido como lixo acumulado;
## (4) o balcão leva a peça mais velha do degrau, não a que aparece primeiro na lista,
## que é justamente o erro que faria a peça decada nunca apodrecer; (5) o que não tem
## validade (caixa, adaga, pergaminho, cristal, pato, martelo) não é tocado por virada
## nenhuma; (6) o registro de idade e o estoque batem grau a grau depois de qualquer
## chicoteada; (7) a frase da prateleira entra no balanço da manhã de dia em que virou
## e não entra no dia em que não virou; (8) `shelf_batches` e `cold_storage_level`
## atravessam o save, e payload lixo (tier 99, dia no futuro, entrada que não é dicionário)
## é podado sem estourar índice; (9) os três níveis compram ouro → reputação → XP →
## conquista *Sal na prateleira*, e o quarto nível é recusado sem tocar no caixa.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/despensa.gd
##
## Veredito medido nesta rodada: o prazo da Poção de Dano Emocional é 6 → 12 → 18 → 24 dias
## conforme o depósito (Nv.0 → Nv.3) e a etiqueta da mesma peça fica 17 → 17 ouro; a escada
## custa 120 / 300 / 480 e o quarto baú é recusado com o caixa intacto (1170 → 1170). Trinta
## viradas de prateleira não movem um sorteio: os 60 `randi()` depois de envelhecer são
## idênticos aos 60 do controle limpo. A escada de degrau medida dia a dia — Mítico posto no
## dia 1 vira Obra-prima no 7, Refinado no 13, e os dois corpos da estante somem pela porta no
## 14 e no 31 — enquanto o painel lê "Vence em 6 dias", "Vira HOJE" no dia 6 e "Vence em 5" no
## dia 8. Venda com o registro embaralhado leva a peça de dia 5 e deixa a de dia 8 (a ordem da
## lista mentiria sobre idade). Caixa misteriosa: 3 → 3 peças em 40 viradas e "∞ Não vence".
## Vinte e cinco viradas com entrada e saída misturadas fecham zero desajuste entre registro,
## qualidade e estoque. Na fila de verdade, 251 Míticos do dia 1 terminam como 79
## Obra-primas depois de 10 viradas, e a frase "A prateleira virou: 151 peça(s) desceu(ram) de
## qualidade" entra em 1 dos 10 balanços — exatamente o dia 7; nos outros 9 o dia não tinha o
## que virar e a linha não aparece. Save: degrau 4 dia 1 e degrau 1 dia 9 atravessam com o
## mesmo ouro e o mesmo Nv.2; payload lixo (degrau 99, dia 4000, dia −5, entrada que não é
## dicionário, nível 12) vira 3 entradas legítimas postas hoje, Nv.3, e a primeira virada
## depois dele não apodrece nada; sem a chave no arquivo a estante acorda com 0 peças
## registradas e o estoque intacto. Conquista *Sal na prateleira* acende no Nv.3, e o painel
## fecha com 86 definições. Se qualquer linha dessas mover um número entre o modo ligado e o
## desligado, ou se a etiqueta mudar com o depósito comprado, a despensa voltou a cortar
## progressão.

const Quality = preload("res://quality.gd")

const SEED_VAL := 20261016
## Poção de Dano Emocional: validade 6 dias, a mais curta da lista útil.
const PER := 0
## Caixa Misteriosa Vazia: sem validade nenhuma.
const IMORTAL := 3


func _initialize() -> void:
	print("── o depósito de sal compra prazo, não margem ──")
	var loja = await _loja("prazo", false)
	var prazos: Array[String] = []
	for level in range(4):
		loja.cold_storage_level = level
		prazos.append("Nv.%d = %d dias" % [level, loja._shelf_life(PER)])
	loja.cold_storage_level = 0
	var etiqueta_0: int = loja._shelf_price(PER)
	loja.cold_storage_level = 3
	var etiqueta_3: int = loja._shelf_price(PER)
	loja.cold_storage_level = 0
	var escada: Array[String] = []
	for level in range(4):
		loja.cold_storage_level = level
		escada.append(str(loja._cold_storage_cost()))
	loja.cold_storage_level = 0
	print("   dano emocional: %s • caixa sem validade: %d dias (0 = não vence)" % [
		" • ".join(prazos), loja._shelf_life(IMORTAL)])
	print("   etiqueta da mesma peça sem e com o depósito cheio: %d → %d ouro" % [etiqueta_0, etiqueta_3])
	print("   escada de preço do depósito: %s ouro (Nv.1 → Nv.4 cobrado)" % " → ".join(escada))
	var valides: Array[String] = []
	for i in range(loja.products.size()):
		var item: Dictionary = loja.products[i]
		if int(item.get("validade", 0)) > 0:
			valides.append("%s=%d" % [str(item["name"]), int(item["validade"])])
	print("   perecíveis na lista: %d de %d (%s)" % [
		valides.size(), loja.products.size(), ", ".join(valides)])
	await _fechar(loja)

	print("── virar a despensa não gasta um sorteio ──")
	var g = await _loja("sorte", false)
	g.shop_day = 1
	g._add_piece(PER, 4)
	g._add_piece(PER, 2)
	seed(SEED_VAL)
	for cycle in range(30):
		g.shop_day += 1
		g._age_shelf()
	var depois: Array[int] = []
	for i in range(60):
		depois.append(randi() % 100000)
	seed(SEED_VAL)
	var antes: Array[int] = []
	for i in range(60):
		antes.append(randi() % 100000)
	var desvio := -1
	for i in range(60):
		if antes[i] != depois[i]:
			desvio = i
			break
	print("   30 viradas de prateleira + 60 sorteios × controle limpo: %s" % (
		"sequência idêntica (envelhecer não sorteia)" if desvio < 0 else "diverge no sorteio %d" % desvio))
	await _fechar(g)

	print("── a estante acorda fresca e desce degrau a degrau ──")
	var d = await _loja("escada", false)
	_limpar_outras_pereciveis(d, PER)
	d.shop_day = 1
	d._add_piece(PER, 4)
	print("   dia 1, só a poção de prazo 6 na estante: %s • painel: %s" % [
		Quality.summary(d._quality_for("dano_emocional")), d._shelf_marker(PER)])
	for cycle in range(30):
		d.shop_day += 1
		var resultado: Dictionary = d._age_shelf()
		if d.shop_day == 6 or int(resultado["turned"]) > 0 or int(resultado["lost"]) > 0:
			print("      dia %d: virou %d, perdeu %d • %s • estoque %d • %s" % [
				d.shop_day, int(resultado["turned"]), int(resultado["lost"]),
				Quality.summary(d._quality_for("dano_emocional")),
				int(d.products[PER]["stock"]), d._shelf_marker(PER)])
	await _fechar(d)

	print("── o balcão leva a mais velha do degrau ──")
	var f = await _loja("ordem", false)
	f.shop_day = 1
	f._add_piece(PER, 4)
	f.shop_day = 5
	f._add_piece(PER, 3)
	f.shop_day = 8
	f._age_shelf()
	var registro = f.shelf_batches["dano_emocional"]
	var ordem: Array[String] = []
	for entry in registro:
		ordem.append("degrau %d dia %d" % [int(entry["tier"]), int(entry["day"])])
	print("   antes da venda (Mítico decado + Obra-prima velho): %s" % ", ".join(ordem))
	f._take_piece(PER, Quality.BEST)
	var sobras: Array[String] = []
	for entry in f.shelf_batches["dano_emocional"]:
		sobras.append("degrau %d dia %d" % [int(entry["tier"]), int(entry["day"])])
	print("   depois de vender uma Obra-prima: %s (tem de sobrar a de dia 8)" % ", ".join(sobras))
	await _fechar(f)

	print("── o que não tem validade não apodrece ──")
	var i = await _loja("imortal", false)
	_limpar_outras_pereciveis(i, PER)
	i.shop_day = 1
	i._add_piece(IMORTAL, 5)
	i._add_piece(IMORTAL, 5)
	i._add_piece(PER, 3)
	var antes_caixa := int(i.products[IMORTAL]["stock"])
	print("   painel do dia 1: %s" % i._shelf_marker(PER))
	for cycle in range(40):
		i.shop_day += 1
		i._age_shelf()
		if i.shop_day == 4 or i.shop_day == 6:
			print("      painel no dia %d: %s" % [i.shop_day, i._shelf_marker(PER)])
	print("   caixa misteriosa (sem validade): %d → %d peças em 40 viradas • painel: %s" % [
		antes_caixa, int(i.products[IMORTAL]["stock"]), i._shelf_marker(IMORTAL)])
	print("   poção de prazo 6 depois das 40 viradas: estoque %d • %s" % [
		int(i.products[PER]["stock"]), Quality.summary(i._quality_for("dano_emocional"))])
	await _fechar(i)

	print("── registro e estoque batem grau a grau ──")
	var b = await _loja("saldo", false)
	for cycle in range(25):
		b.shop_day += 1
		b._add_piece(PER, cycle % 5)
		b._add_piece(1, 3)
		if cycle % 3 == 0:
			b._take_piece(PER, Quality.BEST)
		if cycle % 4 == 0:
			b._take_piece(PER, Quality.WORST)
		b._age_shelf()
	var desajuste := 0
	for index in range(b.products.size()):
		var item: Dictionary = b.products[index]
		var counts: Array = b._quality_for(str(item["id"]))
		if Quality.total(counts) != int(item["stock"]):
			desajuste += 1
			print("      %s: registro %d ≠ estoque %d" % [str(item["name"]), Quality.total(counts), int(item["stock"])])
			continue
		if b._shelf_life(index) <= 0:
			continue
		var tracked := Quality.empty_stock()
		for entry in b.shelf_batches.get(str(item["id"]), []):
			tracked[int(entry["tier"])] = int(tracked[int(entry["tier"])]) + 1
		for tier in range(Quality.size()):
			if int(tracked[tier]) != int(counts[tier]):
				desajuste += 1
				print("      %s degrau %d: %d registradas ≠ %d em estoque" % [
					str(item["name"]), tier, int(tracked[tier]), int(counts[tier])])
	print("   25 viradas com entrada e saída misturadas: %s" % (
		"nenhum desajuste" if desajuste == 0 else "%d desajustes" % desajuste))
	await _fechar(b)

	print("── a virada avisa no balanço da manhã ──")
	var t = await _loja("balanco", false)
	t.shop_day = 1
	t.ticks = 0
	_limpar_outras_pereciveis(t, PER)
	# A pilha é proposital: com meia dúzia de peças na estante o balcão vende todas
	# antes do sétimo dia, e a medida leria "nenhum aviso" onde havia apenas "nenhuma
	# peça velha sobrando". 250 peças garantem que a virada ache o que virar.
	for pile in range(250):
		t._add_piece(PER, 4)
	var primeiro_estoque := int(t.products[PER]["stock"])
	var avisos := 0
	var viradas := 0
	var relatorio := ""
	for cycle in range(200):
		var dia_antes: int = t.shop_day
		t._on_customer_tick()
		if t.shop_day != dia_antes:
			viradas += 1
			if str(t.day_report).find("A prateleira virou") >= 0:
				avisos += 1
				relatorio = str(t.day_report).replace("\n", " • ")
	print("   %d viradas de dia em 200 tiques: %d balanços com a frase da prateleira" % [viradas, avisos])
	print("   pilha de Míticos do dia 1: %d peças no começo, %d no fim • %s" % [
		primeiro_estoque, int(t.products[PER]["stock"]), Quality.summary(t._quality_for("dano_emocional"))])
	if relatorio != "":
		print("      %s" % relatorio.substr(maxi(0, relatorio.length() - 150)))
	await _fechar(t)

	print("── a idade atravessa o arquivo ──")
	var s = await _loja("save", false)
	s.gold = 5000
	s._buy_cold_storage()
	s._buy_cold_storage()
	s.shop_day = 1
	s._add_piece(PER, 4)
	s.shop_day = 9
	s._age_shelf()
	s._save_game()
	var idades: Array[String] = []
	for entry in s.shelf_batches["dano_emocional"]:
		idades.append("degrau %d dia %d" % [int(entry["tier"]), int(entry["day"])])
	var ouro_antes := int(s.gold)
	var nivel_antes := int(s.cold_storage_level)
	await _fechar(s)
	var r = await _reload("reaberto")
	var idades_depois: Array[String] = []
	for entry in r.shelf_batches.get("dano_emocional", []):
		idades_depois.append("degrau %d dia %d" % [int(entry["tier"]), int(entry["day"])])
	print("   antes do save: depósito Nv.%d • ouro %d • %s" % [nivel_antes, ouro_antes, ", ".join(idades)])
	print("   depois do load: depósito Nv.%d • ouro %d • %s" % [
		r.cold_storage_level, int(r.gold), ", ".join(idades_depois)])
	print("   o prazo continua o do nível comprado: %d dias" % r._shelf_life(PER))
	await _fechar(r)

	print("── payload lixo e save antigo acordam frescos ──")
	var sujo := ConfigFile.new()
	var codigo := sujo.load(_caminho_save())
	if codigo != OK:
		print("      (não deu para abrir o save descartável: código %d)" % codigo)
	else:
		var bagunca: Array = [
			{"tier": 99, "day": 4000},
			"lixo de balcão",
			{"tier": 3},
			{"tier": 2, "day": -5},
		]
		sujo.set_value("game", "shelf_batches", {"dano_emocional": bagunca, "orfa_de_estoque": bagunca})
		sujo.set_value("game", "cold_storage_level", 12)
		sujo.save(_caminho_save())
		var w = await _reload("com lixo")
		print("   nível 12 no arquivo vira Nv.%d • prazo %d dias" % [w.cold_storage_level, w._shelf_life(PER)])
		var lidos: Array = w.shelf_batches.get("dano_emocional", [])
		var descricao: Array[String] = []
		for entry in lidos:
			descricao.append("degrau %d dia %d" % [int(entry["tier"]), int(entry["day"])])
		print("   4 entradas lixo viram %d: %s" % [lidos.size(), ", ".join(descricao)])
		var virada: Dictionary = w._age_shelf()
		print("   primeira virada depois do lixo: virou %d, perdeu %d (nada apodrece na hora)" % [
			int(virada["turned"]), int(virada["lost"])])
		await _fechar(w)
	var sem_chave := ConfigFile.new()
	if sem_chave.load(_caminho_save()) == OK:
		sem_chave.erase_section_key("game", "shelf_batches")
		sem_chave.erase_section_key("game", "cold_storage_level")
		sem_chave.save(_caminho_save())
		var velho = await _reload("save antigo")
		var peças_velhas := 0
		for chave in velho.shelf_batches.keys():
			peças_velhas += (velho.shelf_batches[chave] as Array).size()
		print("   sem a chave no arquivo: %d produtos na estante de idade, %d peças registradas, depósito Nv.%d" % [
			velho.shelf_batches.size(), peças_velhas, velho.cold_storage_level])
		var primeira: Dictionary = velho._age_shelf()
		print("   virada imediata: virou %d, perdeu %d • prateleira: %s" % [
			int(primeira["turned"]), int(primeira["lost"]),
			Quality.summary(velho._quality_for("dano_emocional"))])
		await _fechar(velho)

	print("── o caixa compra o depósito, e o quarto baú é recusado ──")
	var c = await _loja("caixa", false)
	c.gold = 2000
	c._buy_cold_storage()
	var caixa_1 := int(c.gold)
	c._buy_cold_storage()
	var caixa_2 := int(c.gold)
	c._buy_cold_storage()
	var caixa_3 := int(c.gold)
	var rep_3 := int(c.reputation)
	var xp_3 := int(c.player_xp)
	var badges_3: Array = c.unlocked_achievements.duplicate()
	c._buy_cold_storage()
	print("   2000 − %d (Nv.1) − %d (Nv.2) − %d (Nv.3) = %d, nível %d, prazo %d dias" % [
		2000 - caixa_1, caixa_1 - caixa_2, caixa_2 - caixa_3, caixa_3, c.cold_storage_level, c._shelf_life(PER)])
	print("   quarto clique no teto: caixa %d (tem de ser o mesmo %d) • mensagem: %s" % [
		int(c.gold), caixa_3, str(c.last_event).substr(0, 62)])
	print("   ganho por nível: +1 reputação ×3 = %d, XP %d • conquista *Sal na prateleira*: %s" % [
		rep_3, xp_3, str(badges_3.has("salt_shelf"))])
	var sem_grana = await _loja("pobre", false)
	sem_grana.gold = 10
	var ouro_pobre := int(sem_grana.gold)
	sem_grana._buy_cold_storage()
	print("   10 de ouro no caixa: compra recusada, nível %d e %d ouro intocados" % [
		sem_grana.cold_storage_level, int(sem_grana.gold)])
	if ouro_pobre != int(sem_grana.gold):
		print("      (o caixa mudou numa recusa!)")
	var defs: Array = sem_grana._achievement_definitions()
	print("   painel de conquistas: %d definições, o selo do sal está entre elas: %s" % [
		defs.size(), str(_tem_conquista(sem_grana, "salt_shelf"))])
	await _fechar(c)
	await _fechar(sem_grana)

	print("VEREDITO: prazo dobra/triplica/quadruplica sem tocar na etiqueta, envelhecer não sorteia, estante acorda fresca, venda leva a mais velha do degrau, imune não vence, registro bate com estoque, aviso só no dia que vira, idade e nível atravessam o save, payload lixo é podado e o quarto baú não sai do caixa. Qualquer preço mudando com o depósito, ou sorteio consumido na virada, é a despensa cortando progressão.")
	quit()


## Esvazia as outras estantes com validade para a medida ler só o produto da vez: sem
## isso o "virou 1" do dia 5 era a confiança instantânea (prazo 4), não a poção medida.
func _limpar_outras_pereciveis(g, keep: int) -> void:
	for index in range(g.products.size()):
		if index == keep:
			continue
		var item: Dictionary = g.products[index]
		if int(item.get("validade", 0)) <= 0:
			continue
		item["stock"] = 0
		g.quality_stock[str(item["id"])] = Quality.empty_stock()
		g.shelf_batches[str(item["id"])] = []


## Loja recém-instalada com o save descartável apagado, relógio parado, semente cravada
## e vida resetada: o chão de onde toda medida aqui parte.
func _loja(rotulo: String, ligado: bool):
	_apagar_save()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	g.adult_content_enabled = ligado
	return g


## Reabre a loja lendo o save que está no disco, sem apagar e sem resetar.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	return g


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
