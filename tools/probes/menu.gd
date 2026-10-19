extends SceneTree

## Sonda do menu ☰: prova que as duas portas (o clique na sanduíche e o ESC) abrem a
## mesma janela, que as camadas descem e sobem sem perder a loja de vista, e que nada do
## que mora dentro delas escreve no disco antes da hora.
##
## O que aqui se mede, e por que importa na tela:
## - ☰ e ESC têm de cair no mesmo `_open_menu`, sem abrir segunda janela: duas portas,
##   uma camada.
## - Navegar é redesenho da mesma camada, não abertura de outra: a rua fica parada do
##   primeiro toque ao último, e o que prova isso é tique de verdade, não a flag.
## - Arrastar o volume não pode recriar a tela, senão o slider foge do dedo. Mudo,
##   ocultar painel e balanço automático trocam estado E rótulo.
## - Tela, escala e sincronismo têm de sobreviver às duas idas e vindas do arquivo de
##   preferência: salvar o idioma sem ler o disco apagava a seção da tela, e vice-versa.
##   Essa inimizade entre seções é o bug que `_save_person_settings()` existe para não ter.
## - Conquistas listam exatamente o que está destravado; créditos e relatório de bug abrem
##   sem escrever nada.
## - O rodapé do painel anuncia a versão do build em toda tela, e a frase dela tem irmã em
##   cada língua traduzida: em navegador e em Linux não há arquivo para olhar o número.
## - Salvar, exportar e apagar: só a janela de confirmação aparece; o save continua no
##   disco até o sim.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/menu.gd
##
## Veredito medido nesta rodada: **95 conferências, 0 quebras**. ☰ e ESC caem na mesma
## camada (nenhuma segunda `Window` nasce do menu), e os três controles de som saíram do
## topo do painel. A raiz tem 9 itens e desce em cinco camadas — ⚙ Opções 10, 💾 Salvar e
## carregar 9, 🏆 Conquistas 3, ✨ Créditos 7, 🌐 Idioma 5 — e "← Voltar ao menu" sobe para
## `root`. Arrastar o volume muda `audio.volume` sem recriar `menu_box` (mesma instância),
## e o rótulo acompanha; mudo, painel, balanço automático e cenas sensuais trocam estado E
## rótulo sem tocar em caixa nem em atendidos. Tela → 2, Escala → 1.25, VSync → 2 sobrevivem
## à escrita do idioma e a uma reabertura completa (um `ConfigFile` só, lido antes de
## escrito). Conquistas listam exatamente as 2 destravadas de 100; créditos fecham com 7
## notas, a segunda sendo o selo `Versão: 0.1.0-alpha.5`, que também aparece no rodapé do
## menu raiz e segue o idioma (em espanhol: `Versión: 0.1.0-alpha.5`). Salvar dá recibo e
## grava no descartável; exportar abre em modo de gravação e
## importar em modo de leitura; "Apagar todo o progresso" só mostra a confirmação e o save
## continua no disco; o relatório de bug abre janela própria com publicar travado até a
## caixa de consentimento. A rua, medida em tiques de verdade em janelas de 600 quadros a
## 4x: +7 sem menu, **+0** com as cinco camadas navegadas, +7 depois de fechar.

const SEED_VAL := 20261016
const Locales = preload("res://locales.gd")

var _falhas: Array[String] = []
var _conferidas := 0

func _initialize() -> void:
	print("── ☰ e ESC, a mesma janela ──")
	var loja = await _loja("portas")
	_confere(is_instance_valid(loja.menu_button) and str(loja.menu_button.text) == "☰",
			"a sanduíche existe no topo")
	var janelas_antes := _janelas(loja).size()
	loja.menu_button.pressed.emit()
	await _frames(2)
	_confere(is_instance_valid(loja.menu_layer) and str(loja.menu_screen) == "root",
			"☰ abre na raiz, não no seletor de idioma")
	_confere(loja.world_timer.is_stopped(), "☰ para a rua")
	_confere(_janelas(loja).size() == janelas_antes,
			"☰ não abre segunda janela: %d -> %d janelas" % [janelas_antes, _janelas(loja).size()])
	_esc(loja)
	await _frames(2)
	_confere(not is_instance_valid(loja.menu_layer), "ESC fecha o que ☰ abriu")
	_esc(loja)
	await _frames(2)
	_confere(is_instance_valid(loja.menu_layer) and str(loja.menu_screen) == "root",
			"ESC cai na mesma raiz do ☰")
	print("   som e relatório saíram do topo: mute=%s market=%s slider=%s" % [
		str(loja.get("mute_button")), str(loja.get("market_toggle_button")),
		str(loja.get("volume_slider"))])

	print("── camadas: descer e subir ──")
	for prefixo in ["⚙", "💾", "🏆", "✨", "🌐"]:
		var alvo := _botao_por_prefixo(loja, prefixo)
		_confere(alvo != null, "a raiz tem o botão %s" % prefixo)
		if alvo == null:
			continue
		var rotulo := str(alvo.text)
		alvo.pressed.emit()
		await _frames(2)
		_confere(str(loja.menu_screen) != "root", "%s desceu para uma camada" % rotulo)
		_confere(loja.world_timer.is_stopped(), "a camada %s mantém a rua parada" % rotulo)
		_confere(_janelas(loja).size() == janelas_antes,
				"descer para %s não abriu janela nova" % rotulo)
		if str(loja.menu_screen) == "idioma":
			## Um botão por idioma declarado em `SUPPORTED` — a conta é lida do catálogo,
			## porque uma língua nova na tabela não pode cobrar edição de sonda.
			_confere(loja.menu_language_buttons.size() == Locales.SUPPORTED.size(),
					"a camada de idioma traz %d botão(ões), um por entrada de SUPPORTED" % Locales.SUPPORTED.size())
		var voltar := _botao(loja, "← Voltar ao menu")
		_confere(voltar != null, "%s tem botão de voltar" % rotulo)
		print("   %-26s -> tela %-11s • %2d itens • título %s" % [
			rotulo, str(loja.menu_screen), loja.menu_box.get_child_count(),
			str(loja._menu_title())])
		if voltar != null:
			voltar.pressed.emit()
			await _frames(2)
			_confere(str(loja.menu_screen) == "root", "voltar devolve a raiz")
	loja._show_menu_screen("opcoes")
	await _frames(2)
	_esc(loja)
	_confere(str(loja.menu_screen) == "root", "ESC dentro de Opções volta, não fecha")
	_esc(loja)
	await _frames(2)
	_confere(not is_instance_valid(loja.menu_layer), "o segundo ESC fecha o menu")

	print("── volume, mudo, painel e balanço ──")
	loja.menu_button.pressed.emit()
	loja._show_menu_screen("opcoes")
	await _frames(2)
	var caixa = loja.menu_box
	var barrinha := _slider(loja)
	_confere(barrinha != null, "Opções carrega a barra de volume")
	if barrinha != null:
		barrinha.value = 0.25
		await _frames(1)
		_confere(_mesma_caixa(caixa, loja.menu_box), "arrastar o volume não redesenha a tela")
		_confere(is_equal_approx(loja.audio.volume, 0.25), "o volume foi para 25%%")
		_confere(str(loja.menu_volume_label.text) == loja.tr("Volume: %d%%") % 25,
				"a legenda acompanhou a barra: %s" % str(loja.menu_volume_label.text))
	var mudo_antes := bool(loja.audio.muted)
	var botao_mudo := _botao_de_som(loja)
	_confere(botao_mudo != null, "Opções tem o botão de som")
	if botao_mudo != null:
		var rotulo_mudo := str(botao_mudo.text)
		botao_mudo.pressed.emit()
		await _frames(2)
		var depois_do_mudo := _botao_de_som(loja)
		_confere(bool(loja.audio.muted) != mudo_antes, "mudo virou o estado")
		_confere(depois_do_mudo != null and str(depois_do_mudo.text) != rotulo_mudo,
				"e virou o próprio rótulo: %s -> %s" % [rotulo_mudo,
					"<sumiu>" if depois_do_mudo == null else str(depois_do_mudo.text)])
		var painel_antes := bool(loja.market_panel.visible)
		var oculta := _botao(loja, "Ocultar o painel da loja")
		if oculta == null:
			oculta = _botao(loja, "Mostrar o painel da loja")
		_confere(oculta != null, "esconder o HUD migrou para Opções")
		if oculta != null:
			oculta.pressed.emit()
			await _frames(2)
			_confere(bool(loja.market_panel.visible) != painel_antes, "o painel obedeceu ao menu")
			_confere(_botao(loja, "Ocultar o painel da loja") != null
					or _botao(loja, "Mostrar o painel da loja") != null,
					"e o rótulo diz o que o botão faz agora")
		var auto_antes := bool(loja.day_auto_ok)
		var balanco := _botao_por_prefixo(loja, "Balanço do dia:")
		_confere(balanco != null, "o balanço automático mora em Opções")
		if balanco != null:
			balanco.pressed.emit()
			await _frames(2)
			_confere(bool(loja.day_auto_ok) != auto_antes, "e ele liga/desliga daqui")
		var cenas := _botao_de_cenas(loja)
		_confere(cenas != null, "o tom das cenas migrou para Opções")
		if cenas != null:
			var cenas_antes := bool(loja.adult_content_enabled)
			var rotulo_cenas := str(cenas.text)
			cenas.pressed.emit()
			await _frames(2)
			_confere(bool(loja.adult_content_enabled) != cenas_antes,
					"ligar e desligar troca o tom da loja")
			var novo_rotulo := _botao_de_cenas(loja)
			_confere(novo_rotulo != null and str(novo_rotulo.text) != rotulo_cenas,
					"e o rótulo diz em que pé a loja está: %s -> %s" % [rotulo_cenas,
						"<sumiu>" if novo_rotulo == null else str(novo_rotulo.text)])
			var caixa_antes := int(loja.gold)
			var atendidos_antes := int(loja.customers_served)
			if bool(loja.adult_content_enabled) != cenas_antes:
				cenas = _botao_de_cenas(loja)
				if cenas != null:
					cenas.pressed.emit()
					await _frames(2)
			_confere(int(loja.gold) == caixa_antes and int(loja.customers_served) == atendidos_antes,
					"e o botão não mexe em nenhuma conta da loja")
		print("   volume 25%% • mudo %s • painel visível %s • balanço automático %s • cenas liberadas %s" % [
			str(loja.audio.muted), str(loja.market_panel.visible), str(loja.day_auto_ok),
			str(loja.adult_content_enabled)])

	print("── tela, escala e sincronismo: gravam sem brigar com o idioma ──")
	var janela_antes := int(loja.window_mode)
	var escala_antes := float(loja.ui_scale)
	var vsync_antes := int(loja.vsync_mode)
	var leitura_antes := ConfigFile.new()
	leitura_antes.load(Locales.SETTINGS_PATH)
	var idioma_no_disco := str(leitura_antes.get_value("locale", "language", "pt"))
	for prefixo in ["Tela:", "Escala da interface:", "Sincronismo vertical:"]:
		var ciclo := _botao_por_prefixo(loja, prefixo)
		_confere(ciclo != null, "Opções tem o ciclisto %s" % prefixo)
		if ciclo != null:
			ciclo.pressed.emit()
			await _frames(2)
	print("   Tela -> %d • Escala -> %.2f • VSync -> %d" % [
		int(loja.window_mode), loja.ui_scale, int(loja.vsync_mode)])
	_confere(int(loja.window_mode) != janela_antes
			or float(loja.ui_scale) != escala_antes
			or int(loja.vsync_mode) != vsync_antes, "os três ciclistos andaram")
	var no_arquivo := ConfigFile.new()
	_confere(no_arquivo.load(Locales.SETTINGS_PATH) == OK, "a preferência foi para o disco")
	_confere(int(no_arquivo.get_value("display", "window_mode", -1)) == int(loja.window_mode),
			"o disco guarda a tela escolhida")
	loja._pick_locale("en")
	await _frames(2)
	var depois_do_idioma := ConfigFile.new()
	depois_do_idioma.load(Locales.SETTINGS_PATH)
	_confere(str(depois_do_idioma.get_value("locale", "language", "")) == "en",
			"salvar o idioma escreveu no arquivo")
	_confere(int(depois_do_idioma.get_value("display", "window_mode", -1)) == int(loja.window_mode),
			"e não apagou a seção da tela: o load-antes-do-save é o que segura isso")
	loja._pick_locale("pt")
	await _frames(2)
	loja._close_menu()
	await _frames(2)
	var reaberta = await _reload("reaberta")
	_confere(int(reaberta.window_mode) == int(loja.window_mode), "a reabertura traz a tela de volta")
	_confere(is_equal_approx(float(reaberta.ui_scale), float(loja.ui_scale)), "traz a escala de volta")
	_confere(int(reaberta.vsync_mode) == int(loja.vsync_mode), "traz o sincronismo de volta")
	_confere(str(reaberta.locale) == idioma_no_disco, "e traz o idioma de volta: %s" % str(reaberta.locale))
	print("   reaberta: Tela -> %d • Escala -> %.2f • VSync -> %d • idioma %s" % [
		int(reaberta.window_mode), reaberta.ui_scale, int(reaberta.vsync_mode), str(reaberta.locale)])
	await _fechar(reaberta)

	print("── conquistas e créditos ──")
	var defs: Array[Dictionary] = loja._achievement_definitions()
	var duas: Array[String] = [str(defs[0]["id"]), str(defs[1]["id"])]
	loja.unlocked_achievements = duas
	loja._show_menu_screen("conquistas")
	await _frames(2)
	var marcadas := _notas_por_prefixo(loja, "✓")
	_confere(marcadas == duas.size(),
			"a tela lista exatamente as %d destravadas (listou %d)" % [duas.size(), marcadas])
	print("   conquistas: %d linhas ✓ de %d destravadas • %d definições • título %s" % [
		marcadas, loja.unlocked_achievements.size(), defs.size(), str(loja._menu_title())])
	loja._show_menu_screen("creditos")
	await _frames(2)
	var notas := _notas_por_prefixo(loja, "")
	_confere(str(loja._menu_title()) == "CRÉDITOS", "créditos têm título próprio")
	_confere(notas >= 5, "créditos têm quem agradecer (%d notas)" % notas)
	print("   créditos: %d notas, a última lendo %s" % [notas, _ultima_nota(loja)])

	print("── o selo de versão ──")
	var idioma_antes := str(TranslationServer.get_locale())
	var selo := str(loja._version_stamp())
	_confere(selo.contains("."), "o selo traz o número do project.godot: %s" % selo)
	_confere(_tem_rotulo(loja, selo), "os créditos mostram o selo")
	loja._show_menu_screen("root")
	await _frames(2)
	_confere(_tem_rotulo(loja, selo), "o menu raiz mostra o selo debaixo da lista")
	TranslationServer.set_locale("es")
	_confere(str(loja.tr("Versão: %s")) == "Versión: %s", "a frase do selo tem irmã em espanhol")
	var selo_es := str(loja._version_stamp())
	_confere(selo_es.begins_with("Versión: "), "e o selo segue o idioma: %s" % selo_es)
	TranslationServer.set_locale(idioma_antes)
	print("   selo: %s • em espanhol: %s" % [selo, selo_es])

	print("── salvar, exportar e apagar: nada sem confirmação ──")
	loja._show_menu_screen("save")
	await _frames(2)
	var salvar := _botao(loja, "Salvar agora")
	_confere(salvar != null, "a camada de save tem o botão de salvar")
	if salvar != null:
		salvar.pressed.emit()
		await _frames(2)
		_confere(str(loja.menu_status_label.text) == loja.tr("progresso salvo"),
				"salvar dá recibo na tela")
		_confere(FileAccess.file_exists("user://succubus_shop_save.cfg"),
				"e o save está no descartável, não no seu")
	var exporta := _botao(loja, "Exportar save para arquivo")
	_confere(exporta != null, "exportar está na camada de save")
	if exporta != null:
		exporta.pressed.emit()
		await _frames(2)
		_confere(loja.save_file_dialog.visible, "exportar abre a janela de arquivo")
		_confere(int(loja.save_file_dialog.file_mode) == FileDialog.FILE_MODE_SAVE_FILE,
				"no modo de gravação")
		loja.save_file_dialog.hide()
	var importa := _botao(loja, "Importar save de arquivo")
	if importa != null:
		importa.pressed.emit()
		await _frames(2)
		_confere(int(loja.save_file_dialog.file_mode) == FileDialog.FILE_MODE_OPEN_FILE,
				"importar abre no modo de leitura")
		loja.save_file_dialog.hide()
	var apaga := _botao(loja, "Apagar todo o progresso")
	if apaga != null:
		apaga.pressed.emit()
		await _frames(2)
		_confere(FileAccess.file_exists("user://succubus_shop_save.cfg"),
				"apagar não apaga antes do sim")
		_confere(loja.hard_reset_dialog.visible, "apagar pede a confirmação")
		loja.hard_reset_dialog.hide()
	_confere(_botao(loja, "Carregar o último save do disco") != null,
			"recarregar do disco está na camada (não clicado aqui: reabre a cena)")

	print("── relatar um problema mudou de bolso, não de corpo ──")
	loja._show_menu_screen("root")
	await _frames(2)
	var relato := _botao(loja, "🐞 Relatar um problema")
	_confere(relato != null, "a raiz carrega o relatório de bug")
	if relato != null:
		var antes := _janelas(loja).size()
		relato.pressed.emit()
		await _frames(2)
		_confere(_janelas(loja).size() == antes + 1,
				"e ele abre uma janela própria: %d -> %d" % [antes, _janelas(loja).size()])
		var janela = _janela_de_relato(loja)
		if janela != null:
			var botao_ok = janela.get_ok_button()
			_confere(bool(botao_ok.disabled), "o publicar está travado até o consentimento")
			var consentimento: CheckBox = null
			for filho in _todos_os_filhos(janela):
				if filho is CheckBox:
					consentimento = filho
			_confere(consentimento != null, "há uma caixa de consentimento")
			if consentimento != null:
				_confere(not bool(consentimento.button_pressed), "a caixa começa desmarcada")
				consentimento.set_pressed(true)
				await _frames(1)
				_confere(bool(consentimento.button_pressed), "marcar destrava o publicar")
				_confere(not bool(botao_ok.disabled), "consentir destrava o publicar")
			janela.queue_free()
			await _frames(2)

	print("── a rua para com o menu e volta com ele (medido em tiques) ──")
	var firme = await _loja("relógio")
	var contador := {"n": 0}
	firme.world_timer.timeout.connect(func() -> void: contador["n"] += 1)
	Engine.time_scale = 4.0
	await _frames(600)
	var sem_menu := int(contador["n"])
	contador["n"] = 0
	firme.menu_button.pressed.emit()
	await _frames(2)
	for camada in ["opcoes", "save", "conquistas", "creditos", "root"]:
		firme._show_menu_screen(camada)
		await _frames(2)
	await _frames(600)
	var com_menu := int(contador["n"])
	contador["n"] = 0
	_esc(firme)
	await _frames(2)
	await _frames(600)
	var de_volta := int(contador["n"])
	var outra_janela: bool = firme._modal_holds_clock()
	Engine.time_scale = 1.0
	print("   600 quadros sem menu: +%d tiques • menu navegado em 5 camadas: +%d • fechado: +%d" % [
		sem_menu, com_menu, de_volta])
	_confere(sem_menu > 0, "a rua anda quando ninguém está no menu")
	_confere(com_menu == 0, "e para em todas as camadas")
	_confere(de_volta > 0 or outra_janela,
			"a rua volta quando o menu fecha (a menos que outra janela %s tenha assumido)" \
					% str(outra_janela))
	await _fechar(firme)
	await _fechar(loja)

	print("── veredito ──")
	print("   %d conferência(s), %d quebra(s)" % [_conferidas, _falhas.size()])
	if _falhas.is_empty():
		print("APROVADO: ☰ e ESC são a mesma porta, as camadas descem e sobem com a rua parada, e nada do menu escreve no disco antes da confirmação.")
	else:
		for quebra in _falhas:
			print("   REPROVADO: %s" % quebra)
	quit()


## A asserção da sonda: conta em `_conferidas` e só fala para reclamar. O veredito imprime
## o total, senão uma seção muda leria como "nada havia para conferir".
func _confere(condicao: bool, rotulo: String) -> void:
	_conferidas += 1
	if not condicao:
		_falhas.append(rotulo)


func _botao(loja, texto: String) -> Button:
	if not is_instance_valid(loja.menu_box):
		return null
	for filho in loja.menu_box.get_children():
		var alvo := filho as Button
		if alvo != null and str(alvo.text) == texto:
			return alvo
	return null


## Os botões montados (`🏆 Conquistas (3/24)`, `Tela: Janela`) são achados pelo começo da
## legenda: a string inteira muda com o número e com o idioma, o pictograma não.
func _botao_por_prefixo(loja, prefixo: String) -> Button:
	if not is_instance_valid(loja.menu_box):
		return null
	for filho in loja.menu_box.get_children():
		var alvo := filho as Button
		if alvo != null and str(alvo.text).begins_with(prefixo):
			return alvo
	return null


func _botao_de_som(loja) -> Button:
	var ligado := _botao(loja, "🔊 Som: LIGADO")
	return ligado if ligado != null else _botao(loja, "🔇 Som: DESLIGADO")


## Os dois rótulos possíveis do mesmo botão: a sonda procura pelo estado atual, porque o
## botão que aparece é justamente o que a loja ainda não é.
func _botao_de_cenas(loja) -> Button:
	var liberadas := _botao(loja, "🔥 Cenas sensuais: LIBERADAS")
	return liberadas if liberadas != null else _botao(loja, "🌸 Cenas sensuais: CONTIDAS")


func _slider(loja) -> HSlider:
	if not is_instance_valid(loja.menu_box):
		return null
	for filho in _todos_os_filhos(loja.menu_box):
		var alvo := filho as HSlider
		if alvo != null:
			return alvo
	return null


func _ultima_nota(loja) -> String:
	if not is_instance_valid(loja.menu_box):
		return "<sem caixa>"
	for i in range(loja.menu_box.get_child_count() - 1, -1, -1):
		var alvo := loja.menu_box.get_child(i) as Label
		if alvo != null:
			return str(alvo.text)
	return "<sem nota>"


## O selo de versão mora fora da `menu_box` (é rodapé do painel), então aqui a varredura
## é pela árvore inteira da loja.
func _tem_rotulo(loja, texto: String) -> bool:
	for filho in _todos_os_filhos(loja):
		var label := filho as Label
		if label != null and str(label.text) == texto:
			return true
	return false


func _notas_por_prefixo(loja, prefixo: String) -> int:
	if not is_instance_valid(loja.menu_box):
		return 0
	var n := 0
	for filho in loja.menu_box.get_children():
		var nota := filho as Label
		if nota != null and (prefixo == "" or str(nota.text).begins_with(prefixo)):
			n += 1
	return n


func _janelas(loja) -> Array[Window]:
	var achadas: Array[Window] = []
	for filho in loja.get_children():
		var janela := filho as Window
		if janela != null:
			achadas.append(janela)
	return achadas


func _janela_de_relato(loja) -> ConfirmationDialog:
	for filho in loja.get_children():
		var dialogo := filho as ConfirmationDialog
		if dialogo != null and str(dialogo.title) == "Relatar um problema":
			return dialogo
	return null


func _todos_os_filhos(de) -> Array:
	var todos: Array = []
	for filho in de.get_children():
		todos.append(filho)
		todos.append_array(_todos_os_filhos(filho))
	return todos


func _mesma_caixa(a, b) -> bool:
	return a != null and b != null and a.get_instance_id() == b.get_instance_id()


## Loja recém-instalada sobre descartável vazio, com semente cravada e relógio rodando:
## o chão de onde toda medida aqui parte.
func _loja(rotulo: String):
	_apagar("user://succubus_shop_save.cfg")
	_apagar(Locales.SETTINGS_PATH)
	_apagar("user://audio_settings.cfg")
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	seed(SEED_VAL)
	g._reset_run()
	g._refresh_ui()
	g.world_timer.start()
	return g


## Reabertura honesta: nada apagado, nada resetado — só o que `_ready()` lê do disco.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	return g


## ESC de verdade: o jogo só escuta `_unhandled_key_input`, então é por aqui que a sonda
## aperta a tecla, e não chamando `_close_menu()` por fora.
func _esc(loja) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	loja._unhandled_key_input(key)


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _apagar(caminho: String) -> void:
	var absoluto: String = ProjectSettings.globalize_path(caminho)
	if FileAccess.file_exists(absoluto):
		DirAccess.remove_absolute(absoluto)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
