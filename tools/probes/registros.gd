extends SceneTree

## Registros da casa: prova que o painel só lê, que a trava é marco e não compra, e que
## abrir a tela não move um número nem queima um sorteio.
##
## O que aqui se mede, e por que importa na tela:
## - forma: oito seções, ids únicos, linha suficiente, e a trava só existe onde a seção
##   ainda está fechada — uma seção aberta com texto de porta é o painel mentindo.
## - vida nova: só o balcão acende. As outras sete trancadas é o estado honesto do dia um.
## - um marco por seção basta para acendê-la: painel que exige três feitos esconde o que
##   o jogador já fez.
## - desenho: a raiz passou de 8 para 9 botões, a tela lê o título certo e cada linha vira
##   um nó; com os marcos postos nenhuma porta sobra, e na vida nova sobram as sete.
## - inércia: duzentos tiques na mesma semente, um lado lendo o painel cem vezes no meio do
##   laço e o outro nunca — estado final e cauda de `randi()` idênticos.
## - disco: abrir e fechar a camada não escreve no save; o painel não tem chave própria.
## - catálogo: doze chaves novas, cada uma com irmã nas cinco tabelas, nenhuma vazia.
##
## Armadilha medida nesta sonda, duas vezes, e as duas custaram uma rodada:
## - A/B com as duas lojas vivas através do `await` da criação diverge por calendário, não
##   pelo recurso: a que nasceu primeiro come frames reais de rotação de atores a mais. Uma
##   loja por vez, `seed()` cravado logo antes do laço, é o molde do `publicar.gd`.
## - `regular_bonds`, `regular_arc_seen`, `origin_seen`, `prestige_runs`, `endings_seen` e
##   `ruined_lives` são da família e atravessam o `_reset_run()` por decisão de projeto. Sem
##   limpá-los, a "vida nova" do painel mostra cinco portas e não sete, e a sonda acusaria o
##   painel de mentir na trava.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 4000 --script res://tools/probes/registros.gd
##
## Veredito medido nesta rodada: **177 conferências, 0 quebras**. Oito seções, ids únicos,
## toda aberta sem texto de porta e toda fechada anunciando a dela; no dia 1 só o balcão
## acende, e um marco basta para acender cada uma das outras sete. A raiz lista os 9 botões
## com "📊 Registros da casa" e a camada lê o título "REGISTROS DA CASA" (7 portas na vida
## nova, 0 com os marcos postos). O save não muda de hash ao abrir, ler a seção 40 vezes e
## fechar. As cinco tabelas traduzidas têm **228** chaves cada, com as doze novas preenchidas.
## Corrida de 200 tiques na semente 90210, um lado lendo o painel cem vezes no meio do laço:
## **caixa 2781 • fama 0 • dia 11 • 19 servidos • 187 decepções • fila 0, idêntica nos dois
## lados**, e a cauda de 20 `randi()` depois do laço é a mesma — o painel não sorteia.

const Locales = preload("res://locales.gd")
const SEED_VAL := 90210
const NOVAS := [
	"📊 Registros da casa", "REGISTROS DA CASA", "BALCÃO DE HOJE",
	"CAIXA E COBRANÇA", "CASA, GENTE E CELA", "ESTRADA, FORJA E BANCADA",
	"CULTO E MURALHA", "FREGUESIA E FACÇÕES", "VIDAS E TEMPORADAS",
	"FACHADA, FILIAIS E CARTAS", "Ainda fechada: %s",
	"Seções abertas neste balcão: %d de %d — e nada aqui gasta um sorteio nem move um ouro.",
]

var quebras := 0
var conferidas := 0

func _initialize() -> void:
	var loja = await _loja("registros-forma")
	_confere(loja._records_sections().size() == 8, "8 secoes declaradas")
	_forma(loja)
	_vida_nova(loja)
	_marcos(loja)
	_desenho(loja)
	_disco(loja)
	await _fechar(loja)
	_catalogo()
	await _inercia()
	print("REGISTROS: %d conferencias, %d quebras" % [conferidas, quebras])
	if quebras > 0:
		print("REGISTROS: QUEBRA • o painel moveu alguma conta ou mentiu na trava")
	quit()

# -- forma ----------------------------------------------------------------------

func _forma(loja) -> void:
	var vistos: Array[String] = []
	for section in loja._records_sections():
		var id := str(section["id"])
		_confere(not vistos.has(id), "id unico %s" % id)
		vistos.append(id)
		_confere(str(section["titulo"]) == str(section["titulo"]).to_upper(), "titulo em caixa alta %s" % id)
		_confere((section["linhas"] as Array).size() >= 3, "%s tem 3+ linhas" % id)
		var aberta := bool(section["aberta"])
		if aberta:
			_confere(str(section["trava"]) == "", "%s aberta sem texto de porta" % id)
		else:
			_confere(str(section["trava"]) != "", "%s fechada anuncia a porta" % id)

func _vida_nova(loja) -> void:
	var abertas: Array[String] = []
	for section in loja._records_sections():
		if bool(section["aberta"]):
			abertas.append(str(section["id"]))
	_confere(abertas.size() == 1 and abertas[0] == "balcao",
			"no dia 1 so o balcao acende (%s)" % ", ".join(abertas))

func _marcos(loja) -> void:
	# Um marco por vez, no corpo da mesma loja: cada um deve acender a secao dele sozinho.
	var gatilhos := {
		"fiado": func(): loja.credit_rank = 1,
		"casa": func(): loja.staff_hired.append("maid"),
		"estrada": func(): loja.expeditions_done = 1,
		"culto": func(): loja.rituals_performed = 1,
		"freguesia": func(): loja.regular_bonds["aldrich"] = 1,
		"vidas": func(): loja.prestige_runs = 1,
		"fachada": func(): loja.ad_level = 1,
	}
	for id in gatilhos.keys():
		(gatilhos[id] as Callable).call()
		var aberta := false
		for section in loja._records_sections():
			if str(section["id"]) == id:
				aberta = bool(section["aberta"])
		_confere(aberta, "um marco chega e %s acende" % id)
	var abertas_final := 0
	for section in loja._records_sections():
		if bool(section["aberta"]):
			abertas_final += 1
	_confere(abertas_final == 8, "os sete marcos abrem as oito secoes (%d)" % abertas_final)

# -- desenho --------------------------------------------------------------------

func _desenho(loja) -> void:
	loja._show_menu_screen("root")
	var raiz := _rota_de_botoes(loja)
	_confere(raiz.has("📊 Registros da casa"), "raiz tem o botao dos registros")
	_confere(_conta_botoes(loja) == 9, "raiz passou a ter 9 botoes (%d)" % _conta_botoes(loja))
	_confere(_nota_da_raiz(loja) == 2, "raiz continua com as duas notas de rodape (%d)" % _nota_da_raiz(loja))
	loja._show_menu_screen("registros")
	_confere(loja._menu_title() == "REGISTROS DA CASA", "titulo da camada lido")
	var nos: int = loja.menu_box.get_child_count()
	_confere(nos > 8, "camada montada tem %d nos" % nos)
	var travas := _portas_na_tela(loja)
	_confere(travas == 0, "com os marcos postos nenhuma porta sobra na tela (%d)" % travas)
	loja._reset_run()
	# Armadilha medida nesta sonda: `regular_bonds` e `prestige_runs` sao da FAMILIA e
	# atravessam o `_reset_run()` por decisao de projeto. Sem limpa-los a vista, a loja nova
	# mostra cinco portas e nao sete, e a sonda acusaria o painel de mentir na trava.
	loja.regular_bonds.clear()
	loja.regular_arc_seen.clear()
	loja.origin_seen.clear()
	loja.prestige_runs = 0
	loja.endings_seen.clear()
	loja.ruined_lives = 0
	loja._show_menu_screen("registros")
	_confere(_portas_na_tela(loja) == 7, "vida nova limpa mostra as sete portas (%d)" % _portas_na_tela(loja))

func _portas_na_tela(loja) -> int:
	var fechadas := 0
	for filho in loja.menu_box.get_children():
		if filho is Label and str(filho.text).begins_with("Ainda fechada: "):
			fechadas += 1
	return fechadas

func _nota_da_raiz(loja) -> int:
	var n := 0
	for filho in loja.menu_box.get_children():
		if filho is Label:
			n += 1
	return n

func _rota_de_botoes(loja) -> Array[String]:
	var nomes: Array[String] = []
	for filho in loja.menu_box.get_children():
		if filho is Button:
			nomes.append(str(filho.text))
	return nomes

func _conta_botoes(loja) -> int:
	var n := 0
	for filho in loja.menu_box.get_children():
		if filho is Button:
			n += 1
	return n

# -- disco ----------------------------------------------------------------------

func _disco(loja) -> void:
	loja._save_game()
	var antes := FileAccess.get_sha256(_caminho_save())
	loja._show_menu_screen("registros")
	for i in range(40):
		loja._records_sections()
	loja._show_menu_screen("root")
	var depois := FileAccess.get_sha256(_caminho_save())
	_confere(antes == depois, "abrir e fechar a camada nao escreve no save")

# -- catalog --------------------------------------------------------------------

func _catalogo() -> void:
	for id in ["en", "es", "fr", "it", "de"]:
		var tabela: Dictionary = Locales.MESSAGES[id]
		_confere(tabela.size() == 228, "%s tem 228 chaves (%d)" % [id, tabela.size()])
		for chave in NOVAS:
			_confere(tabela.has(chave), "%s conhece \"%s\"" % [id, chave])
			_confere(str(tabela[chave]) != "", "%s nao traduz %s para vazio" % [id, chave])

# -- inercia --------------------------------------------------------------------

func _inercia() -> void:
	# Uma loja por vez, cada uma com o `seed()` cravado logo antes do laco: com as duas vivas
	# atravessando o `await` da criacao, a que nasceu primeiro come frames reais de rotacao de
	# atores a mais, e a corrida acusaria o painel de sortear onde o que divergia era o
	# calendario de cada uma. Foi assim que esta sonda mentiu na primeira rodada.
	var a = await _loja("inercia-A")
	_preparar(a)
	var retrato_a: String = await _corrida(a, false)
	var cauda_a := _cauda(20)
	await _fechar(a)
	var b = await _loja("inercia-B")
	_preparar(b)
	var retrato_b: String = await _corrida(b, true)
	var cauda_b := _cauda(20)
	await _fechar(b)
	print("REGISTROS: A %s" % retrato_a)
	print("REGISTROS: B %s" % retrato_b)
	_confere(retrato_a == retrato_b, "200 tiques, painel aberto ou nao, mesmo estado")
	_confere(cauda_a == cauda_b, "a cauda de 20 randi apos a corrida e identica")

## Duzentos tiques sem nenhum `await` no meio. O que o lado B acrescenta e so a leitura do
## painel, nunca um frame nem um tique a mais.
func _corrida(loja, com_painel: bool) -> String:
	seed(SEED_VAL)
	for tick in range(200):
		loja._on_customer_tick()
		if com_painel and tick % 4 == 0:
			loja._records_sections()
			loja._records_sections()
	await _frames(1)
	return _retrato(loja)

func _preparar(loja) -> void:
	# Chao do recurso montado nos dois lados: com a prateleira vazia a corrida nao mede
	# nada, mede ausencia. Enche a mesa para os tiques terem o que vender.
	loja.gold = 1200
	loja.reputation = 20
	for i in range(loja.products.size()):
		if bool(loja._is_product_unlocked(loja.products[i])):
			for copia in range(3):
				loja._add_piece(i, 1)

func _retrato(loja) -> String:
	return "caixa %d • fama %d • dia %d • servidos %d • decepcoes %d • fila %d" % [
		loja.gold, loja.reputation, loja.shop_day, loja.customers_served,
		loja.disappointed_customers, loja.service_queue.size()]

func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto):
		partes.append(str(randi() % 1000))
	return ",".join(partes)

func _confere(ok: bool, rotulo: String) -> void:
	conferidas += 1
	if not ok:
		quebras += 1
		print("REGISTROS: QUEBRA • %s" % rotulo)

func _caminho_save() -> String:
	return ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"

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
	g._refresh_ui()
	return g

func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
	await _frames(2)

func _apagar_save() -> void:
	var caminho: String = _caminho_save()
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartavel nao apagou: %s)" % caminho)

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
