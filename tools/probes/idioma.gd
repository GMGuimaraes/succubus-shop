extends SceneTree

## Sonda do idioma: prova que a loja fala outra língua sem falar outro número. O catálogo
## vive em `locales.gd` e é entregue ao TranslationServer do motor, que traduz o rótulo
## pronto na hora de desenhar; o que é montado na hora ("Ouro: %d") passa por `tr()` no
## chamador. Aqui se mede os dois caminhos, e se mede a armadilha do meio: o Godot escolhe
## o "melhor ajuste" entre as tabelas registradas, então um português sem tabela própria
## voltaria do inglês lendo inglês — a tabela identidade do original existe para isso.
## Confere também o menu do ESC (abre, fecha, para a rua e retoma a rua, e não acorda o
## relógio por cima do balanço do dia), o seletor da primeira abertura (aparece uma vez,
## fecha e não volta), o fato de o idioma ser preferência e não conta da vida (atravessa
## reencarnação, settings e save, e o settings manda sobre o save), que um idioma
## inexistente no arquivo acorda em português sem derrubar o balcão, e — o que fecha a
## conta — duzentos tiques de loja sob a mesma semente em duas línguas diferentes: se a
## tradução mexesse em caixa, fila ou placar, as duas irmãs divergiriam.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/idioma.gd
##
## Veredito medido nesta rodada: catálogo de 215 chaves com **paridade total** nas cinco
## línguas traduzidas (en, es, fr, it, de) — `chaves sem irmã` lidas contra a UNIÃO de todas
## as tabelas, e uma chave vazia conta como órfã; a mesma frase sai
## "Ouro: %d / TALENTOS / ⚒ Forja" em pt, "Gold: %d / TALENTS / ⚒ Forge" em en,
## "Oro: %d / TALENTI / ⚒ Fucina" em it e "Or : %d / TALENTE / ⚒ Schmiede" em de. Registrar
## duas vezes deixa 6 tabelas no motor (sem duplicata). A armadilha do melhor-ajuste é
## real e medida: locale sem tabela ("zz") acorda **em inglês** — por isso o português tem
## tabela identidade; ainda assim `set_locale("pt")` depois de inglês devolve "Ouro: 0".
## ESC: menu abre a RAIZ (relógio para; o seletor não mora mais ali, mora na camada 🌐 a um
## toque, e descendo nela os 6 botões de idioma aparecem com o ✓ na escolha), ESC volta para
## a raiz e fecha (relógio volta), e por
## cima do balanço do dia o fechar **não** acorda a rua. Primeira abertura: sem escolha o
## jogo não abre menu em headless (não há quem clique) mas `locale_confirmed` está
## false; `_open_menu(true)` mostra o seletor, e fechar sem escolher grava preferência no
## disco e o seletor não volta na reabertura. Painel em inglês: `Gold: 137`,
## `Reputation: 22 • Promising Shop (+4%)`, `In the shop: 0 • Queue: 0 ♥0 ✗0 • Served: 9`,
## `WORLD CLOCK: 1.0x`; a aba continua carregando o literal "⚒ Forja" no `.text` porque é
## o motor que traduz na hora de desenhar (o `tr()` da chave lê "⚒ Forge"), e o ✓ do menu
## acompanha o idioma escolhido. castelhano e volta ao português batem; `pick` de idioma
## inexistente é ignorado sem tocar no locale. Preferência: reencarnar não muda o idioma
## (caixa volta a 80 e a língua fica en), settings apagados fazem o save falar mais alto,
## e settings × save em conflito é o settings que vence (save es + settings pt → pt).
## Arquivo quebrado (settings "francês", save "klingon") acorda em pt com o painel de pé.
## Duzentos tiques sob a mesma semente, uma loja em pt e outra em en, fecharam **idênticas**
## (caixa 755 • fama 0 • 5 atendidos • 174 decepções • dia 11 • estoque 0 • placar 1024):
## tradução não é engrenagem. A faixa da casa é o caso difícil e foi medida na loja de
## verdade, não no catálogo: `A CASA ESTÁ: casa em obras (placar 45) — …` vira
## `THE HOUSE IS: house under repair (score 45) — the hall under repair: …` em en e
## `LA CASA ES: casa en obras (puntos 45) — el salón en obras: …` em es, nas duas pontas da
## escada (0 e 4), e o aviso "A casa virou …" acompanha. Nome e presente vêm de lista, a
## frase nasce montada, então é o `tr()` do chamador que salva — traduzir o catálogo sem
## tocar em `main.gd` deixaria o painel em português dentro de uma loja em inglês.

const SEED_VAL := 20261015
const TICKS := 200
const Locales = preload("res://locales.gd")

func _initialize() -> void:
	print("── o catálogo acorda no motor ──")
	_apagar_idioma()
	_apagar_save()
	Locales.register()
	var ids: Array[String] = []
	for supported in Locales.SUPPORTED:
		ids.append(str(supported["id"]))
	var tabelas: Array[String] = []
	for id in ids:
		TranslationServer.set_locale(id)
		tabelas.append("%s: %s / %s / %s" % [id,
			TranslationServer.translate("Ouro: %d"), TranslationServer.translate("TALENTOS"),
			TranslationServer.translate("⚒ Forja")])
	print("   frases por idioma no catálogo -> %s" % ", ".join(_cobertura()))
	print("   uma frase, todas as bocas -> %s" % "  •  ".join(tabelas))
	var orfaos := _orfãos()
	print("   chaves sem irmã (união de %s): %s" % [
		", ".join(_linguas_com_tabela()), (orfaos if orfaos != "" else "nenhuma")])
	var antes := TranslationServer.get_translations().size()
	Locales.register()
	var depois := TranslationServer.get_translations().size()
	print("   registrar duas vezes: %d -> %d tabela(s) no motor (esperado idem)" % [antes, depois])

	# O painel de faixa é o caso difícil: nome e presente vêm de listas e a frase é
	# montada na hora, então só o `tr()` do chamador salva. Lido na loja de verdade,
	# não traduzido à mão na sonda — copiar o molde aqui seria provar outra coisa.
	print("── a faixa da casa fala todas as línguas do catálogo ──")
	var casa = (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(casa)
	await _frames(4)
	casa.world_timer.stop()
	casa._reset_run()
	for banda in [0, 4]:
		casa.gold = int(casa.PROGRESS_BAND_SCORES[banda])
		var bocas: Array[String] = []
		for id in ids:
			TranslationServer.set_locale(id)
			casa._refresh_ui()
			bocas.append("%s: %s" % [id, casa._progress_line()])
		print("   faixa %d -> %s" % [banda, "  ||  ".join(bocas)])
		var aviso: Array[String] = []
		for id in ids:
			TranslationServer.set_locale(id)
			# `TranslationServer.translate` em vez de `tr` da SceneTree: o `tr` prende o
			# contexto ao nome da classe, e aqui o que se quer medir é a chave solta.
			aviso.append("%s: %s" % [id, TranslationServer.translate("A casa virou %s: %s") % [
				TranslationServer.translate(casa.PROGRESS_BAND_NAMES[banda]),
				TranslationServer.translate(casa.PROGRESS_BAND_GIFTS[banda])]])
		print("      aviso -> %s" % "  ||  ".join(aviso))
	TranslationServer.set_locale(Locales.DEFAULT)
	casa.queue_free()
	await _frames(2)

	print("── voltar ao português volta de verdade ──")
	var falas: Array[String] = []
	for id in _linguas_com_tabela():
		TranslationServer.set_locale(id)
		falas.append("%s -> %s" % [id, TranslationServer.translate("Ouro: 0")])
	TranslationServer.set_locale(Locales.DEFAULT)
	var de_volta: String = TranslationServer.translate("Ouro: 0")
	print("   " + " • ".join(falas))
	print("   pt -> %s" % de_volta)
	print("   a loja voltou a falar português? %s" % str(de_volta == "Ouro: 0"))
	## O melhor-ajuste do motor só aparece numa língua que NÃO tem tabela: com tabela, a
	## tradução vence e a armadilha fica invisível.
	TranslationServer.set_locale("zz")
	print("   locale sem tabela (zz) acorda: %s" % TranslationServer.translate("Ouro: 0"))
	TranslationServer.set_locale(Locales.DEFAULT)

	print("── o ESC abre, fecha e manda na rua ──")
	var loja = await _loja("esc")
	loja.world_timer.start()
	# Em janela a loja acorda com o portão de idioma na tela — o portão só abre fora do
	# headless. Um ESC antes de medir fecha o portão e devolve a loja ao chão da medida
	# (menu fechado); sem isto a mesma sonda lê dois estados de partida diferentes
	# conforme o modo de lançamento, e o primeiro ESC fecha em vez de abrir.
	if not loja.locale_confirmed and is_instance_valid(loja.menu_layer):
		_esc(loja)
		await _frames(2)
	print("   antes do ESC: menu %s • relógio %s" % [
		"fechado" if not is_instance_valid(loja.menu_layer) else "aberto",
		"rodando" if not loja.world_timer.is_stopped() else "parado"])
	_esc(loja)
	print("   depois do ESC: menu %s • relógio %s • raiz com %d item(ns) • modo abertura %s" % [
		"aberto" if is_instance_valid(loja.menu_layer) else "fechado",
		"parado" if loja.world_timer.is_stopped() else "RODANDO",
		0 if not is_instance_valid(loja.menu_box) else loja.menu_box.get_child_count(),
		str(loja.menu_start_mode)])
	# O seletor saiu da raiz: hoje mora na camada 🌐, a um toque do menu. Descer nela é
	# a conta honesta dos botões de idioma.
	var porta = _porta_da_camada(loja, "🌐")
	if porta != null:
		porta.pressed.emit()
		await _frames(2)
		print("   camada 🌐 Idioma: %d botão(ões) de idioma • o ✓ está em %s" % [
			loja.menu_language_buttons.size(), _marcado(loja)])
		var de_volta_raiz = _porta_da_camada(loja, "←")
		if de_volta_raiz != null:
			de_volta_raiz.pressed.emit()
			await _frames(2)
			print("   voltar sobe para a raiz: %s" % (
				"sim" if str(loja.menu_screen) == "root" else "NÃO (%s)" % loja.menu_screen))
	_esc(loja)
	print("   ESC de novo: menu %s • relógio %s" % [
		"aberto" if is_instance_valid(loja.menu_layer) else "fechado",
		"rodando" if not loja.world_timer.is_stopped() else "PARADO"])
	# O balanço do dia também para a rua. Fechar o menu por cima dele não pode acordar
	# o relógio que outra janela decidiu parar.
	loja.day_layer = Control.new()
	loja.add_child(loja.day_layer)
	_esc(loja)
	_esc(loja)
	print("   menu por cima do balanço: relógio ficou %s" % (
		"parado" if loja.world_timer.is_stopped() else "ACORDADO"))
	loja.day_layer.queue_free()
	loja.day_layer = null
	await _fechar(loja)

	print("── a primeira abertura pergunta o idioma uma vez ──")
	loja = await _loja("abertura")
	print("   sem escolha prévia: confirmado %s • camada em tela %s (headless não tem quem clique)" % [
		str(loja.locale_confirmed), "sim" if is_instance_valid(loja.menu_layer) else "não"])
	loja._open_menu(true)
	print("   seletor aberto: %d botões • título lê %s • saída lê %s" % [
		loja.menu_language_buttons.size(), loja.tr("ESCOLHA O IDIOMA"), loja.tr("Entrar na loja")])
	loja._close_menu()
	print("   fechar sem escolher: confirmado %s • settings no disco %s • menu %s" % [
		str(loja.locale_confirmed),
		str(FileAccess.file_exists(Locales.SETTINGS_PATH)),
		"fechado" if not is_instance_valid(loja.menu_layer) else "ABERTO"])
	var reaberta = await _reload("abertura 2")
	print("   reabrir o jogo: idioma %s • confirmado %s (o seletor não volta)" % [
		reaberta.locale, str(reaberta.locale_confirmed)])
	await _fechar(reaberta)
	await _fechar(loja)

	print("── escolher idioma troca o painel, não a conta ──")
	loja = await _loja("painel")
	loja.gold = 137
	loja.reputation = 22
	loja.customers_served = 9
	loja.affection = 40
	loja._pick_locale("en")
	print("   locale no motor: %s • confirmado %s" % [TranslationServer.get_locale(), str(loja.locale_confirmed)])
	print("   painel em inglês: %s" % " •  ".join(_painel_textos(loja)))
	print("   aba (o motor traduz ao desenhar): text=%s • tr()=%s • auto_translate=%s" % [
		loja.forge_button.text, loja.tr("⚒ Forja"), str(loja.forge_button.auto_translate_mode)])
	print("   ✓ do seletor (camada 🌐, não desenhada na raiz): está em %s • %d botão(ões) de idioma em tela" % [
		_marcado(loja), loja.menu_language_buttons.size()])
	loja._pick_locale("es")
	print("   castelhano: %s" % " •  ".join(_painel_textos(loja)))
	loja._pick_locale("pt")
	print("   português de novo: %s" % " •  ".join(_painel_textos(loja)))
	loja._pick_locale("esperanto")
	print("   idioma que não existe no catálogo: locale continua %s" % loja.locale)
	await _fechar(loja)

	print("── idioma é preferência, não conta da vida ──")
	loja = await _loja("preferência")
	loja._pick_locale("en")
	loja._reset_run()
	print("   reencarnou: idioma %s • confirmado %s • caixa %d" % [
		loja.locale, str(loja.locale_confirmed), loja.gold])
	_apagar_idioma()
	var espelho := ConfigFile.new()
	espelho.load("user://succubus_shop_save.cfg")
	var do_save = await _reload("só com save")
	print("   settings apagados, save diz %s: a loja acorda em %s" % [
		str(espelho.get_value("game", "locale", "")), do_save.locale])
	await _fechar(do_save)
	# O arquivo de preferência manda sobre o save: a loja pode ir de máquina sem
	# arrastar a língua de quem a emprestou.
	var conflito := ConfigFile.new()
	conflito.load("user://succubus_shop_save.cfg")
	conflito.set_value("game", "locale", "es")
	conflito.save("user://succubus_shop_save.cfg")
	var preferido := ConfigFile.new()
	preferido.set_value("locale", "language", "pt")
	preferido.set_value("locale", "confirmed", true)
	preferido.save(Locales.SETTINGS_PATH)
	var ganhou = await _reload("settings × save")
	print("   save diz es, settings dizem pt: a loja abre em %s" % ganhou.locale)
	await _fechar(ganhou)
	await _fechar(loja)

	print("── um idioma quebrado no arquivo não derruba o balcão ──")
	var quebrado := ConfigFile.new()
	quebrado.load("user://succubus_shop_save.cfg")
	quebrado.set_value("game", "locale", "klingon")
	quebrado.save("user://succubus_shop_save.cfg")
	var settings_ruim := ConfigFile.new()
	settings_ruim.set_value("locale", "language", "francês")
	settings_ruim.save(Locales.SETTINGS_PATH)
	var sorda = await _reload("arquivo ruim")
	print("   settings %s + save %s: acordou em %s • confirmado %s • painel: %s" % [
		"francês", "klingon", sorda.locale, str(sorda.locale_confirmed),
		str(sorda.gold_label.text).substr(0, 24)])
	await _fechar(sorda)
	await _fechar(loja)

	print("── a língua não mexe em nenhuma conta da loja ──")
	var irma_pt = await _loja("irmã pt")
	for i in range(TICKS):
		irma_pt._on_customer_tick()
	var contas_pt := _contas(irma_pt)
	await _fechar(irma_pt)
	var irma_en = await _loja("irmã en")
	irma_en._pick_locale("en")
	for i in range(TICKS):
		irma_en._on_customer_tick()
	var contas_en := _contas(irma_en)
	await _fechar(irma_en)
	print("   pt: %s" % contas_pt)
	print("   en: %s -> %s" % [contas_en, "idem" if contas_pt == contas_en else "DIVERGE: tradução mexeu na economia"])

	print("VEREDITO: idioma que não troca rótulo é enfeite; rótulo que troca e conta que muda junto é bug. Voltar ao português e continuar em inglês é o melhor-ajuste do motor sem tabela do original. Divergência entre irmãs de línguas diferentes é sorteio escondido na tradução.")
	quit()


## Os cinco rótulos que o painel mostra, já na boca do idioma atual. São as strings
## montadas com `tr()` — o literal fixo é traduzido pelo motor na hora de desenhar.
func _painel_textos(loja) -> Array[String]:
	var textos: Array[String] = []
	for label in [loja.gold_label, loja.rep_label, loja.customers_label,
			loja.affection_label, loja.speed_label]:
		textos.append(str(label.text))
	return textos


## O botão da camada do menu cujo rótulo começa com o prefixo dado. Descer de camada por
## aqui é apertar o botão de verdade, e não chamar `_show_menu_screen` por fora.
func _porta_da_camada(loja, prefixo: String):
	if not is_instance_valid(loja.menu_box):
		return null
	for filho in loja.menu_box.get_children():
		if filho is Button and str(filho.text).contains(prefixo):
			return filho
	return null


## Qual botão de idioma do menu carrega o ✓: a escolha precisa aparecer marcada.
func _marcado(loja) -> String:
	for supported in Locales.SUPPORTED:
		var id := str(supported["id"])
		if loja._locale_button_text(id).contains("✓"):
			return id
	return "ninguém"


func _cobertura() -> Array[String]:
	var chaves := _uniao_de_chaves().size()
	var linhas: Array[String] = []
	for supported in Locales.SUPPORTED:
		var id := str(supported["id"])
		if id == Locales.DEFAULT:
			linhas.append("%s original (%d chaves)" % [id, chaves])
			continue
		linhas.append("%s %s" % [id, Locales.coverage(id)])
	return linhas


## Toda língua do catálogo que tem tabela própria — o original fica fora porque a tabela
## dele é identidade, não tradução.
func _linguas_com_tabela() -> Array[String]:
	var ids: Array[String] = []
	for supported in Locales.SUPPORTED:
		var id := str(supported["id"])
		if id != Locales.DEFAULT and Locales.MESSAGES.has(id):
			ids.append(id)
	return ids


func _uniao_de_chaves() -> Dictionary:
	var uniao := {}
	for id in _linguas_com_tabela():
		for key in (Locales.MESSAGES[id] as Dictionary).keys():
			uniao[str(key)] = true
	return uniao


## Chave que existe em uma tabela e não em outra: meio catálogo traduzido é meia loja.
## A comparação é contra a união de TODAS as línguas do catálogo (menos o original, que é
## a tabela identidade), e não contra uma irmã fixa — acrescentar idioma sem paridade é
## exatamente o tipo de meio-trabalho que esta sonda existe para pegar.
func _orfãos() -> String:
	var uniao := _uniao_de_chaves()
	var faltando: Array[String] = []
	for id in _linguas_com_tabela():
		var tabela: Dictionary = Locales.MESSAGES[id]
		## Vazio também é órfã: a chave traduzida para "" some do painel sem dar erro.
		for key in tabela.keys():
			if str(tabela[key]).strip_edges() == "":
				faltando.append("%s vazia: %s" % [id, str(key)])
		for key in uniao.keys():
			if not tabela.has(str(key)):
				faltando.append("%s←%s" % [id, str(key)])
	return ", ".join(faltando)


## Conta fechada dos dois lados do A/B de idioma: se a língua não muda número, as duas
## strings iguais provam que a tradução é capa, não engrenagem.
func _contas(loja) -> String:
	var estoque := 0
	for item in loja.products:
		estoque += int(item.get("stock", 0))
	return "caixa %d • fama %d • atendidos %d • felizes %d • decepções %d • dia %d • estoque %d • tempo %s • placar %d" % [
		loja.gold, loja.reputation, loja.customers_served, loja.happy_customers,
		loja.disappointed_customers, loja.shop_day, estoque, loja.weather, loja.business_score()]


## Loja recém-instalada com preferência e save descartáveis apagados, relógio parado e
## semente cravada: o chão de onde toda medida aqui parte.
func _loja(rotulo: String):
	_apagar_save()
	_apagar_idioma()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	return g


## Reabre a loja lendo o que está no disco, sem apagar e sem resetar: mostra o que
## `_load_locale_settings()` e o save restauram de verdade.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	return g


## Batida de ESC de verdade: o jogo só escuta `_unhandled_key_input`, então é por aqui
## que a sonda aperta a tecla, e não chamando `_open_menu` por fora.
func _esc(loja) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	loja._unhandled_key_input(key)


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _apagar_save() -> void:
	_apagar("user://succubus_shop_save.cfg")


func _apagar_idioma() -> void:
	_apagar(Locales.SETTINGS_PATH)


func _apagar(caminho: String) -> void:
	var absoluto: String = ProjectSettings.globalize_path(caminho)
	if FileAccess.file_exists(absoluto):
		DirAccess.remove_absolute(absoluto)
		if FileAccess.file_exists(absoluto):
			print("      (o descartável não apagou: %s)" % absoluto)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
