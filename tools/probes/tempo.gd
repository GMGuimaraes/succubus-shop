extends SceneTree

## Sonda do tempo: prova que a rua faz humor de verdade na economia da loja, e que o
## humor não é texto bonito. Cada um dos seis tempos mexe em três contas medidas aqui —
## quantos batem na porta, quanto o cliente topa esperar e a etiqueta do produto que a
## cidade acordou querendo (+25% exatos, medidos na prateleira). A rolagem consome
## sorteio sempre, então a mesma semente desenha a mesma sequência de dias: duas lojas
## irmãs com a mesma semente têm de ler o mesmo calendário, e é isso que a primeira
## seção exige. Confere ainda que a virada do dia entrega o tempo no mural, que o save
## carrega tempo, produto do dia e o caderno de tempos já vistos, que um tempo
## desconhecido no arquivo não derruba a loja, que a conquista das seis marcas acende,
## e que vida nova volta ao dia limpo sem apagar o caderno.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/tempo.gd
##
## Veredito medido nesta rodada: 60 dias sorteados duas vezes com a mesma semente dão
## sequência idêntica (limpo x7 • chuva x7 • névoa x10 • tempestade x13 • calor x12 •
## feira x11), e loja vazia × loja com estoque a partir da mesma semente dão o mesmo
## calendário — o sorteio não olha para a prateleira. Fila real com fama 20: dia limpo
## abre 2 corpos por tique e topa esperar 6; chuva e névoa −1 na porta e +1 de
## paciência; tempestade −1 (o clamp deixa um de pé) e −1 de paciência; calor +1 e −1;
## feira +2 na porta. Etiqueta do dia: fator x1,25, Poção de Dano Emocional 15 → 19
## (+26,7% já arredondado) enquanto o vizinho fora do dia fica 26 → 26. A virada entrega
## o tempo no balanço da manhã e a linha do painel de mercado. Save: tempo, produto do
## dia e caderno atravessam; um tempo inexistente no arquivo acorda dia limpo.
## Conquista *Previsão da casa* acende com os seis tempos (0 → 1) e a vida nova volta ao
## dia limpo sem apagar o caderno (6 marcas).

const SEED_VAL := 20261015
const DIAS := 60

func _initialize() -> void:
	print("── a mesma semente desenha o mesmo calendário ──")
	var loja_a = await _loja("calendário A", false)
	var ordem: Array = loja_a.WEATHER_ORDER
	var calendário_a: Array[String] = []
	for i in range(DIAS):
		loja_a._roll_weather()
		calendário_a.append(loja_a.weather)
	await _fechar(loja_a)
	var loja_b = await _loja("calendário B", false)
	var calendário_b: Array[String] = []
	for i in range(DIAS):
		loja_b._roll_weather()
		calendário_b.append(loja_b.weather)
	await _fechar(loja_b)
	var desvio := _primeiro_desvio(calendário_a, calendário_b)
	print("   %d dias sorteados duas vezes: %s" % [
		DIAS, "sequência idêntica" if desvio < 0 else "divergem no dia %d" % desvio])
	var vistos: Dictionary = {}
	for w in calendário_a:
		vistos[w] = int(vistos.get(w, 0)) + 1
	var linhas: Array[String] = []
	for w in ordem:
		linhas.append("%s x%d" % [str(w), int(vistos.get(w, 0))])
	print("   distribuição: %s" % " • ".join(linhas))

	print("── o calendário não olha para a prateleira ──")
	var vazia = await _loja("sem estoque", false)
	var cheia = await _loja("com estoque", false)
	for i in range(cheia.products.size()):
		cheia.products[i]["stock"] = 3
	var mesma_sorte := true
	var seq_vazia: Array[String] = []
	seed(SEED_VAL)
	for i in range(12):
		vazia._roll_weather()
		seq_vazia.append(vazia.weather + "|" + vazia.weather_star)
	var seq_cheia: Array[String] = []
	seed(SEED_VAL)
	for i in range(12):
		cheia._roll_weather()
		seq_cheia.append(cheia.weather + "|" + cheia.weather_star)
	mesma_sorte = _primeiro_desvio(seq_vazia, seq_cheia) < 0
	print("   12 dias de loja vazia × loja com estoque, cada uma a partir da mesma semente: %s" % (
		"mesmo calendário" if mesma_sorte else "DIVERGEM"))
	await _fechar(vazia)
	await _fechar(cheia)

	print("── o que cada tempo cobra e paga na fila ──")
	var loja = await _loja("efeitos", false)
	loja.reputation = 20
	var perfil := {"patience": 2}
	var base_porta: int = loja._arrivals_this_tick()
	var base_paciencia: int = loja._queue_patience(perfil)
	print("   dia limpo (base): porta %d • paciência %d" % [base_porta, base_paciencia])
	for w in loja.WEATHER_ORDER:
		loja.weather = str(w)
		var porta: int = loja._arrivals_this_tick()
		var pac: int = loja._queue_patience(perfil)
		print("   %-11s porta %+d • paciência %+d • painel: %s" % [
			str(w), porta - base_porta, pac - base_paciencia, str(loja._weather()["name"])])
	loja.weather = "limpo"
	await _fechar(loja)

	print("── a etiqueta do dia vale os 25% prometidos ──")
	loja = await _loja("etiqueta", false)
	var id_alvo := str(loja.products[0]["id"])
	loja.products[0]["stock"] = 4
	var sem_estrela: int = loja._shelf_price(0)
	loja.weather_star = id_alvo
	var com_estrela: int = loja._shelf_price(0)
	var outro: int = loja._shelf_price(1)
	loja.weather_star = ""
	var outro_sem: int = loja._shelf_price(1)
	print("   fator da casa x%.2f • %s: %d -> %d (%+.1f%% já arredondado na etiqueta) • vizinho fora do dia: %d -> %d" % [
		loja.WEATHER_STAR_PRICE, id_alvo, sem_estrela, com_estrela,
		(float(com_estrela - sem_estrela) / float(maxi(1, sem_estrela))) * 100.0,
		outro_sem, outro])
	await _fechar(loja)

	print("── a virada do dia entrega o tempo no mural ──")
	loja = await _loja("virada", false)
	var tempo_inicial: String = loja.weather
	loja.products[0]["stock"] = 5
	loja.products[1]["stock"] = 5
	for i in range(20):
		loja._on_customer_tick()
	print("   dia %d • tempo %s • visto no caderno %d • a rua quer: %s" % [
		loja.shop_day, loja.weather, loja.weather_seen.size(),
		loja._product_name(loja.weather_star)])
	print("   balanço da manhã: %s" % str(loja.day_report).replace("\n", " • ").substr(0, 170))
	print("   mudou do limpo inicial? %s" % str(tempo_inicial != loja.weather or loja.weather_seen.size() > 0))
	print("   painel de mercado:\n      %s" % str(loja.market_label.text).replace("\n", "\n      "))
	await _fechar(loja)

	print("── o save carrega o céu, e um tempo desconhecido não derruba a loja ──")
	loja = await _loja("save", true)
	loja.weather = "tempestade"
	loja.weather_star = str(loja.products[2]["id"])
	loja.weather_seen = {"tempestade": true, "feirao": true}
	loja._save_game()
	var leitura = await _reload("reload")
	print("   lido: tempo %s • estrela %s • caderno %d" % [
		leitura.weather, leitura.weather_star, leitura.weather_seen.size()])
	await _fechar(leitura)
	_gravar_tempo_invalido()
	var quebrado = await _reload("reload quebrado")
	print("   tempo inexistente no arquivo acorda: %s (esperado limpo) • estrela lida: %s" % [
		quebrado.weather, "vazia" if quebrado.weather_star == "" else quebrado.weather_star])
	await _fechar(quebrado)
	await _fechar(loja)

	print("── a conquista das seis marcas e a vida nova ──")
	loja = await _loja("conquista", true)
	loja.weather_seen = {}
	loja._check_achievements()
	var antes: int = int(loja.unlocked_achievements.size())
	for w in loja.WEATHER_ORDER:
		loja.weather_seen[str(w)] = true
	loja._check_achievements()
	print("   conquistas %d -> %d • seis tempos no caderno: %s" % [
		antes, loja.unlocked_achievements.size(),
		str(loja.unlocked_achievements.has("weather_six"))])
	loja._reset_run()
	print("   vida nova: tempo %s • estrela %s • caderno intacto: %d" % [
		loja.weather, "vazia" if loja.weather_star == "" else loja.weather_star,
		loja.weather_seen.size()])
	await _fechar(loja)

	print("VEREDITO: calendário igual sob a mesma semente, porta e paciência se mexendo por tempo, +25% na etiqueta do dia e nada de tempo travado no save. Sequência divergente é sorteio dependente de estado; efeito zero é enfeite.")
	quit()


## Loja recém-instalada com o save descartável apagado, relógio do mundo parado,
## semente cravada e vida resetada: é o chão de onde toda medida aqui parte.
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


## Reabre a loja lendo o save que está no disco, sem apagar e sem resetar: mostra o que
## _load_game() restaurou de verdade.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	return g


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _primeiro_desvio(a: Array, b: Array) -> int:
	for i in range(mini(a.size(), b.size())):
		if str(a[i]) != str(b[i]):
			return i
	return -1


## Escreve um save com tempo que não existe na tabela, para conferir a volta por cima.
func _gravar_tempo_invalido() -> void:
	var config := ConfigFile.new()
	if config.load("user://succubus_shop_save.cfg") != OK:
		print("      (não deu para abrir o save descartável)")
		return
	config.set_value("game", "weather", "tsunami_de_burocracia")
	config.save("user://succubus_shop_save.cfg")


func _apagar_save() -> void:
	var caminho: String = ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
