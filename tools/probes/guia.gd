extends SceneTree
## A sonda do guia: prova que a loja sabe se explicar sem se meter na conta.
##
## O que aqui se mede, na ordem em que se lê:
## 1. abrir o guia não move número nenhum e não consome sorteio — a corrida de vinte
##    tiques com e sem guia tem de terminar no mesmo retrato e na mesma cauda de RNG;
## 2. o cartaz do primeiro dia obedece à marca da pessoa: nasce à vista, recolhe quando
##    o guia é lido ou dispensado, e reencarnar não o traz de volta;
## 3. a chave `guide/seen` atravessa o arquivo de preferências nos dois sentidos, e um
##    arquivo sem a chave acorda como primeira vez;
## 4. "o que fazer agora" responde ao estado da casa e não a cabeça: estante vazia, forja
##    parada, talento na gaveta, dia um e casa redonda cada um diz a sua linha;
## 5. o painel monta nas três línguas e nenhuma frase do guia fica sem irmã no catálogo;
## 6. o ESC dentro do guia volta para a raiz em vez de fechar a loja, e o relógio da rua
##    para com o guia aberto e volta quando ele fecha.
##
## Uso: godot --headless --path . --quit-after 200000 -s res://tools/probes/guia.gd
##
## O orçamento de quadros é maior que o das outras sondas porque esta loja é instalada
## nove vezes: cada seção quer uma casa recém-nascida, e o 1800 de sempre parava no meio
## da prova de idioma sem dizer que parou.

const Locales = preload("res://locales.gd")
const Main = preload("res://main.gd")

const SEED_VAL := 20261017
const RODADA := 20
## Quantas peças a corrida e a medida põem na estante. O segundo argumento de `_add_piece`
## é o degrau de qualidade, não a quantidade: quem passa esta dezena como degrau cai em
## "out of bounds" no array de qualidade e a corrida mediria duas lojas quebradas.
const ESTANTE_CHEIA := 10
## Grau médio, seguro em qualquer tabela de qualidade e caro o bastante para o balcão
## vender de verdade durante a corrida.
const TIER_DE_ESTANTE := 3
## O passo do talento é o único montado com número: o que mora no catálogo é o molde.
const _MOLDE_TALENTO := "Há %d ponto(s) de talento parado(s) na gaveta. Gaste na Biblioteca — talento não gasto é loja parada."

## Colhido durante a medida do estado, para o teste do catálogo não manter lista à parte.
var passos_do_guia: Array[String] = []

var falhas := 0


func _initialize() -> void:
	print("── abrir o guia não move número nem sorteio ──")
	var com_guia := await _corrida(true)
	var sem_guia := await _corrida(false)
	print("   com guia -> %s" % str(com_guia["retrato"]))
	print("   sem guia -> %s" % str(sem_guia["retrato"]))
	print("   cauda de sorte idêntica? %s" % str(com_guia["cauda"] == sem_guia["cauda"]))
	_assert("o retrato da casa é o mesmo com e sem leitura",
		str(com_guia["retrato"]) == str(sem_guia["retrato"]),
		"%s | %s" % [str(com_guia["retrato"]), str(sem_guia["retrato"])])
	_assert("a cauda de RNG não sente a presença do guia",
		str(com_guia["cauda"]) == str(sem_guia["cauda"]),
		"%d valores comparados" % RODADA)

	print("── o cartaz obedece à marca da pessoa ──")
	var loja = await _loja("cartaz")
	_assert("primeira vez: o cartaz está à vista", loja.guide_strip.visible,
		"visível=%s com guide_seen=%s" % [str(loja.guide_strip.visible), str(loja.guide_seen)])
	loja._menu_open_guia()
	_assert("lido: a marca fecha", loja.guide_seen, "guide_seen=%s" % str(loja.guide_seen))
	_assert("lido: o cartaz recolheu", not loja.guide_strip.visible,
		"visível=%s" % str(loja.guide_strip.visible))
	loja._reset_run()
	_assert("reencarnar não traz o cartaz de volta", not loja.guide_strip.visible,
		"depois do _reset_run visível=%s" % str(loja.guide_strip.visible))
	_assert("o guia tem painel montado", loja.menu_box.get_child_count() > 20,
		"%d nós na tela do guia" % loja.menu_box.get_child_count())
	loja._close_menu()
	await _frames(2)
	await _fechar(loja)

	print("── dispensar sem ler também é resposta ──")
	var dispensada = await _loja("dispensa")
	dispensada._dismiss_guide_strip()
	_assert("dispensado: o cartaz recolheu", not dispensada.guide_strip.visible,
		"visível=%s" % str(dispensada.guide_strip.visible))
	await _fechar(dispensada)

	print("── a chave atravessa o arquivo de preferências ──")
	var gravada = await _loja("grava")
	gravada.guide_seen = false
	gravada._refresh_guide_strip()
	gravada._menu_open_guia()
	await _fechar(gravada)
	var relida = await _reload("relê")
	_assert("ler o arquivo devolve a marca escrita", relida.guide_seen,
		"guide_seen=%s depois de recarregar" % str(relida.guide_seen))
	_assert("o cartaz continua fechado na loja relida", not relida.guide_strip.visible,
		"visível=%s" % str(relida.guide_strip.visible))
	await _fechar(relida)
	_apagar_chave_pessoa()
	var acordada = await _reload("acorda")
	_assert("arquivo sem a chave acorda como primeira vez", not acordada.guide_seen,
		"guide_seen=%s" % str(acordada.guide_seen))
	_assert("e o cartaz aparece para quem nunca leu", acordada.guide_strip.visible,
		"visível=%s" % str(acordada.guide_strip.visible))
	await _fechar(acordada)

	print("── o que fazer agora lê a casa, não a cabeça ──")
	var medida = await _loja("medida")
	_blindar(medida)
	_limpar_prateleira(medida)
	medida.craft_jobs.clear()
	medida.skill_points = 0
	medida.shop_day = 5
	var caixa_antes := int(medida.gold)
	var vazia: Array[String] = medida._guide_next_steps()
	print("   estante vazia, forja parada -> %s" % vazia[0])
	_assert("estante vazia manda fabricar", str(vazia[0]).find("Comece pela Forja") == 0,
		"%d linha(s)" % vazia.size())
	medida.craft_jobs.append({"index": 0, "remaining": 5.0, "total": 9.0, "luck": 0})
	var forjando: Array[String] = medida._guide_next_steps()
	print("   estante vazia, forja trabalhando -> %s" % forjando[0])
	_assert("forja trabalhando não manda fabricar de novo",
		str(forjando[0]).find("A forja já trabalha") == 0, "%s" % forjando[0])
	medida.craft_jobs.clear()
	_por_estante(medida, 0, ESTANTE_CHEIA)
	var cheia: Array[String] = medida._guide_next_steps()
	print("   casa abastecida, dia cinco -> %s" % String(" | ").join(cheia))
	_assert("casa abastecida não pede forja", _sem(cheia, "Forja"), "%d linha(s)" % cheia.size())
	_assert("casa redonda em dia avançado fecha com a folga",
		cheia.size() == 1 and str(cheia[0]).find("A casa está redonda") == 0,
		"%s" % String(" || ").join(cheia))
	medida.skill_points = 3
	var Gaveta: Array[String] = medida._guide_next_steps()
	print("   três pontos de talento parados -> %s" % String(" | ").join(Gaveta))
	_assert("talento na gaveta é linha do guia", _tem(Gaveta, "talento parado"),
		"%d linha(s)" % Gaveta.size())
	medida.skill_points = 0
	medida.shop_day = 1
	var dia_um: Array[String] = medida._guide_next_steps()
	print("   primeiro dia -> %s" % String(" | ").join(dia_um))
	_assert("primeiro dia avisa da virada", _tem(dia_um, "virada do dia"),
		"%d linha(s)" % dia_um.size())
	_assert("ler o passo do dia não move a caixa", int(medida.gold) == caixa_antes,
		"caixa %d → %d" % [caixa_antes, int(medida.gold)])
	# As cinco leituras acima são também a fonte das frases que o catálogo tem de ter:
	# medir o estado e colher o vocabulário na mesma rodada evita lista duplicada.
	for step in vazia + forjando + cheia + Gaveta + dia_um:
		var molde := str(step)
		if molde.find("ponto(s) de talento parado(s)") >= 0:
			molde = _MOLDE_TALENTO
		if not passos_do_guia.has(molde):
			passos_do_guia.append(molde)
	print("   %s" % _retrato(medida))
	await _fechar(medida)

	print("── o painel fala as três línguas ──")
	var multilingue = await _loja("idiomas")
	for supported in Locales.SUPPORTED:
		var id := str(supported["id"])
		TranslationServer.set_locale(id)
		# A tela é montada DENTRO do idioma: é o caminho de verdade (o jogador abre o guia
		# com a língua já escolhida) e é o único que mede o passo composto na hora.
		multilingue._menu_open_guia()
		await _frames(2)
		var texto := _texto_da_tela(multilingue)
		print("   %s -> %s" % [id, texto.substr(0, 90)])
		_assert("a tela %s monta com painel cheio" % id, texto.length() > 1200,
			"%d caracteres lidos" % texto.length())
		if id != str(Locales.DEFAULT):
			var cruas := _cruas_no_locale()
			print("      frases cruas no motor: %s" % (cruas if cruas != "" else "nenhuma"))
			_assert("nenhuma frase do guia fica crua em %s" % id, cruas == "", cruas)
		multilingue._free_menu_layer()
	TranslationServer.set_locale(Locales.DEFAULT)
	await _fechar(multilingue)

	print("── nenhuma frase do guia fica sem irmã no catálogo ──")
	var orfas := _orfãs_do_guia()
	print("   frases do guia na boca da sonda: %d" % _frases_do_guia().size())
	print("   órfãs (en × es): %s" % (orfas if orfas != "" else "nenhuma"))
	_assert("todo texto do guia tem versão em inglês e espanhol", orfas == "", orfas)
	_assert("a sonda colheu os passos do estado, não de memória",
		passos_do_guia.size() >= 5, "%d molde(s) de passo" % passos_do_guia.size())

	print("── o ESC e o relógio dentro do guia ──")
	var portao = await _loja("esc")
	portao.world_timer.start()
	portao._menu_open_guia()
	_assert("o relógio para com o guia aberto", portao.world_timer.is_stopped(),
		"parado=%s" % str(portao.world_timer.is_stopped()))
	_esc(portao)
	await _frames(2)
	_assert("um ESC dentro do guia volta para a raiz, não fecha a loja",
		str(portao.menu_screen) == "root" and is_instance_valid(portao.menu_layer),
		"tela=%s menu=%s" % [str(portao.menu_screen),
			"aberto" if is_instance_valid(portao.menu_layer) else "fechado"])
	portao._close_menu()
	await _frames(2)
	_assert("fechado o menu o relógio volta a andar", not portao.world_timer.is_stopped(),
		"parado=%s" % str(portao.world_timer.is_stopped()))
	await _fechar(portao)

	print("── veredito ──")
	# Loja solta na raiz é o vazamento que o motor denuncia no fim: duas instâncias
	# penduradas são dois `queue_free` que não aconteceram, e o relatório de recurso em uso
	# sairia junto com a próxima sonda que rodar.
	_assert("nenhuma loja ficou pendurada na raiz", get_root().get_child_count() == 0,
		"%d nó(s) vivos" % get_root().get_child_count())
	print("   %d falha(s) no guia" % falhas)
	quit()


## Vinte tiques do mundo com a mesma semente, com e sem abrir o guia. A loja é cega para
## conquista (nenhum pagamento de parede entra na conta) e o retrato é lido no fim.
func _corrida(abre_guia: bool) -> Dictionary:
	var g = await _loja("corrida")
	_blindar(g)
	_selar_conquistas(g)
	_preparar_estante(g)
	if abre_guia:
		g._menu_open_guia()
		g._close_menu()
		await _frames(2)
		seed(SEED_VAL)
	for i in range(RODADA):
		g._on_customer_tick()
	var retrato := _retrato(g) + " • nivel %d • xp %d • faixa %d" % [
		int(g.player_level), int(g.player_xp), int(g._progress_band)]
	var cauda := _cauda(RODADA)
	await _fechar(g)
	return {"retrato": retrato, "cauda": cauda}


## Loja recém-instalada com o save e o arquivo de preferências apagados, relógio parado,
## idioma travado, semente cravada e vida resetada.
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
	g.guide_seen = false
	g._refresh_guide_strip()
	return g


## Reabre a loja lendo o que está no disco, sem apagar nem resetar.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.locale = Locales.DEFAULT
	TranslationServer.set_locale(Locales.DEFAULT)
	g.world_timer.stop()
	return g


## Trava o nível e a experiência para a corrida não pagar level-up de um lado só.
func _blindar(g) -> void:
	g.player_level = 60
	g.player_xp = 0
	g.skill_points = 0


## Fecha a parede de conquistas antes da corrida: prêmio de conquista entra no caixa e
## sem esta rolha o lado A pagaria e o lado B não.
func _selar_conquistas(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)


## Estante com estoque nos dois primeiros produtos: o balcão tem o que vender desde o
## primeiro tique, senão a corrida mediria duas lojas quebradas e não duas lojas iguais.
func _preparar_estante(g) -> void:
	for i in range(mini(2, g.products.size())):
		_por_estante(g, i, ESTANTE_CHEIA)


## A peça entra uma a uma porque `_add_piece` soma uma peça de um grau por chamada.
func _por_estante(g, index: int, qtd: int) -> void:
	for _k in range(qtd):
		g._add_piece(index, TIER_DE_ESTANTE)


func _limpar_prateleira(g) -> void:
	for item in g.products:
		item["stock"] = 0


## Todo texto fixo que o guia escreve na tela: títulos, linhas, passos, botões e o aviso do
## cartaz. Os títulos e as linhas vêm da constante do jogo e os passos vêm da medida feita
## lá em cima — nada aqui é copiado de memória, porque lista copiada de memória envelhece
## sozinha e aprova um catálogo que já não cobre a tela.
func _frases_do_guia() -> Array[String]:
	var frases: Array[String] = [
		"COMO SE JOGA",
		"📖 Como se joga",
		"Entendi, abrir o balcão",
		"Não mostrar de novo",
		"O QUE FAZER AGORA",
		"Dois minutos de leitura e a loja deixa de ser um menu de botões.",
		"Leia sem pressa: com o menu aberto o relógio da rua para, e nenhum freguês bate à porta enquanto você está aqui.",
		"Primeiro dia na loja: o balcão vende sozinho o que está na prateleira. O guia explica o resto em dois minutos.",
	]
	for section in Main.GUIDE_SECTIONS:
		frases.append(str(section["titulo"]))
		for line in section["linhas"]:
			frases.append(str(line))
	frases.append_array(passos_do_guia)
	return frases


## Cruza cada frase do guia com as duas tabelas do catálogo: frase sem irmã é painel
## meio traduzido na loja de outra língua.
func _orfãs_do_guia() -> String:
	var en: Dictionary = Locales.MESSAGES["en"]
	var es: Dictionary = Locales.MESSAGES["es"]
	var faltando: Array[String] = []
	for frase in _frases_do_guia():
		var chave := frase
		if chave.find("ponto(s) de talento parado(s)") >= 0:
			chave = _MOLDE_TALENTO
		if not en.has(chave):
			faltando.append("en: " + chave.substr(0, 40))
		if not es.has(chave):
			faltando.append("es: " + chave.substr(0, 40))
	return ", ".join(faltando)


## Cada frase fixa do guia passada pelo tradutor do idioma já armado na loja. O `.text`
## do rótulo devolve o original português em qualquer língua — quem traduz é o motor no
## desenho, não o rótulo — então "crua" aqui é catálogo sem chave, não painel mudo.
func _cruas_no_locale() -> String:
	var cruas: Array[String] = []
	for frase in _frases_do_guia():
		var chave := frase
		if chave.find("ponto(s) de talento parado(s)") >= 0:
			chave = _MOLDE_TALENTO
		if TranslationServer.translate(chave) == chave:
			cruas.append(chave.substr(0, 40))
	return ", ".join(cruas)


func _texto_da_tela(g) -> String:
	var partes: Array[String] = []
	for child in g.menu_box.get_children():
		if child is Label:
			partes.append(str(child.text))
		elif child is Button:
			partes.append(str(child.text))
	return " § ".join(partes)


func _sem(lines: Array[String], alvo: String) -> bool:
	for line in lines:
		if str(line).find(alvo) >= 0:
			return false
	return true


func _tem(lines: Array[String], alvo: String) -> bool:
	return not _sem(lines, alvo)


func _retrato(g) -> String:
	return "servidos %d • sem comprar %d • caixa %d • fama %d • fila %d" % [
		int(g.customers_served), int(g.disappointed_customers), int(g.gold),
		int(g.reputation), int(g.service_queue.size())]


## Quarenta valores da sorte, costurados em string para comparar trilha a trilha.
func _cauda(quanto: int) -> String:
	var partes: Array[String] = []
	for i in range(quanto * 2):
		partes.append(str(randi() % 1000))
	return ",".join(partes)


func _caminho_pessoa() -> String:
	return ProjectSettings.globalize_path("user://") + "locale_settings.cfg"


func _caminho_save() -> String:
	return ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"


## Apaga o save descartável antes de instalar a loja: sonda que lê progresso de teste
## antigo como se fosse real mede outra loja.
func _apagar_save() -> void:
	var caminho: String = _caminho_save()
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


## Risca a seção do guia do arquivo de preferências: é a loja de antes do guia existir.
func _apagar_chave_pessoa() -> void:
	var caminho := _caminho_pessoa()
	if not FileAccess.file_exists(caminho):
		return
	var texto := FileAccess.get_file_as_string(caminho)
	var linha := text_find_secao(texto, "guide")
	if linha < 0:
		return
	var fim := texto.find("[", linha)
	var proximo := texto.find("[", fim + 1)
	var corte := proximo if proximo > 0 else texto.length()
	texto = texto.substr(0, fim) + texto.substr(corte)
	var file := FileAccess.open(caminho, FileAccess.WRITE)
	file.store_string(texto)
	file.close()


func text_find_secao(texto: String, secao: String) -> int:
	return texto.find("[%s]" % secao)


func _esc(loja) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	loja._unhandled_key_input(key)


func _assert(rotulo: String, ok: bool, detalhe: String) -> void:
	if not ok:
		falhas += 1
	print("   %s %s — %s" % ["✓" if ok else "✕", rotulo, detalhe])


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
