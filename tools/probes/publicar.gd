extends SceneTree

## Sonda de publicação: o que tem de estar certo antes de o jogo existir no itch.io.
##
## O que aqui se mede, e por que importa na loja da vitrine:
## - O artefato. Os presets gravam em `.export/`, e o que está no `.gitignore` não entra
##   no commit; um .exe versionado no repositório é a briga de merge que ninguém ganha.
## - Os presets. Três alvos (mesa Windows, Linux, navegador) com `runnable`, arquitetura,
##   pck embutido e o caminho de saída conferidos no arquivo, porque o itch.io recusa o
##   upload que não tem o executável no lugar onde a página diz que está.
## - A versão. `config/version` no `project.godot` e `application/file_version` no preset
##   Windows têm de dizer o mesmo número: o explorador do Windows mostra o dele, e
##   discordar as duas é o jogador jurando que roda o build novo. Linux e navegador não
##   têm campo de versão — escrever a chave lá seria o arquivo prometer o que a plataforma
##   ignora —, então a sonda confere também a ausência.
## - O selo. `icon.svg` precisa existir: sem ele o exportado sai com a cara do Godot e a
##   página do itch.io nasce sem ícone.
## - A guarda da plataforma. O navegador não tem `FileDialog` — `ACCESS_FILESYSTEM` só
##   enxerga o `/home/web_user` virtual —, então a fileira exportar/importar some e o
##   aviso no lugar dela diz onde o save mora. Na mesa os dois botões continuam lá. Isso
##   é reproduzido de verdade: a loja do lado web nasce com `web_build = true` ANTES de
##   `_ready()`, que é a única ordem em que um build web existe.
## - Nenhum número muda. Duzentos tiques sob a mesma semente, uma loja de mesa e outra de
##   navegador, prateleira posta dos dois lados: se esconder a porta de arquivo mexesse em
##   caixa, fama ou fila, as duas irmãs divergiriam.
## - As duas frases novas do aviso têm irmã nas cinco línguas traduzidas. Sem a irmã, a
##   sonda de idioma alheia reprova no commit seguinte.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/publicar.gd
##
## Veredito medido nesta rodada: **60 conferências, 0 quebras**, sem ERROR nem WARNING no
## log e com o save real intacto. `.export/` está ignorado e os três presets leem. Os alvos
## são `Windows Desktop`/`Windows Desktop`, `Linux`/`Linux/X11` e `Web`/`Web`, todos
## `runnable=true`, com saída em `.export/windows/Succubus Shop.exe`,
## `.export/linux/Succubus Shop.x86_64` e `.export/web/index.html`. A versão:
## `config/version` é `0.1.0-alpha.5`, núcleo `0.1.0`, e só o preset de Windows carrega
## `file_version`/`product_version` `0.1.0.5` — as duas outras plataformas **não** têm o
## campo (a primeira rodada tinha, e quebrou: Windows-only). Janela e renderizador copiados
## para a vitrine: 1280x720, `canvas_items`, `gl_compatibility`. Ícone presente (1127 bytes).
## Menu 💾 em mesa: 8 itens com as duas portas de arquivo; em navegador: 7 itens, o aviso
## web no lugar e a frase de fechamento trocada. A corrida de 200 tiques com a mesma semente
## fecha idêntica dos dois lados — `caixa 2357 • fama 0 • dia 11 • servidos 20 • decepções
## 167 • fila 0` — com o painel web aberto antes da corrida mostrando a loja no ponto de
## partida (`caixa 1200 • fama 20 • dia 1`). Catálogo com 228 chaves nas cinco línguas
## traduzidas, e as duas frases novas respondem em en e de.
##
## `Linux/X11` não é typo de manual velho: medido nesta máquina, com `Linux/*BSD` ou
## `Linux/bsd` o motor **descarta o preset em silêncio** ao carregar o cfg (nenhum erro no
## boot do editor) e o export responde `Invalid export preset name: Linux` citando só
## "Windows Desktop" e "Web". Os três candidatos foram rodados um por um.

const SEED_VAL := 20261018
const GameScript = preload("res://main.gd")
const Locales = preload("res://locales.gd")
const TIER_BASE := 0
const PRESETS := [
	["preset.0", "Windows Desktop", "Windows Desktop"],
	["preset.1", "Linux", "Linux/X11"],
	["preset.2", "Web", "Web"],
]

var _falhas: Array[String] = []
var _conferidas := 0

func _initialize() -> void:
	var cfg := ConfigFile.new()
	var erro := cfg.load("res://export_presets.cfg")
	print("── o artefato nunca entra no commit ──")
	var ignore := FileAccess.get_file_as_string("res://.gitignore")
	_confere(erro == OK, "o arquivo de presets abre (erro %d)" % erro)
	_confere(ignore.contains(".export/"), "`.export/` está no .gitignore: %s" % str(ignore.contains(".export/")))
	print("   .export/ ignorado? %s • presets leram? %s" % [str(ignore.contains(".export/")), str(erro == OK)])

	print("── os três alvos do itch.io ──")
	for alvo in PRESETS:
		var secao := str(alvo[0])
		var nome := str(cfg.get_value(secao, "name", ""))
		var plataforma := str(cfg.get_value(secao, "platform", ""))
		var runnable := bool(cfg.get_value(secao, "runnable", false))
		var saida := str(cfg.get_value(secao, "export_path", ""))
		var filtro := str(cfg.get_value(secao, "export_filter", ""))
		_confere(nome == str(alvo[1]), "%s se chama %s (é %s)" % [secao, alvo[1], nome])
		_confere(plataforma == str(alvo[2]), "%s mira a plataforma %s (é %s)" % [secao, alvo[2], plataforma])
		_confere(runnable, "%s é alvo corrido" % secao)
		_confere(saida.begins_with(".export/"), "%s escreve dentro de .export/: %s" % [secao, saida])
		_confere(filtro == "all_resources", "%s leva todos os recursos: %s" % [secao, filtro])
		print("   %-16s %-16s runnable=%s  %s" % [nome, plataforma, str(runnable), saida])
	_confere(str(cfg.get_value("preset.0.options", "binary_format/embed_pck", false)) == "true",
			"a mesa embute o pck: um arquivo só na hora de subir")
	_confere(str(cfg.get_value("preset.1.options", "binary_format/embed_pck", false)) == "true",
			"linux embute o pck")
	_confere(bool(cfg.get_value("preset.2.options", "variant/thread_support", true)) == false,
			"o web nasce sem threads: não depende de SharedArrayBuffer para abrir no navegador")
	_confere(bool(cfg.get_value("preset.2.options", "vram_texture_compression/for_mobile", false)),
			"o web compacta textura para o formato do navegador")
	_confere(int(cfg.get_value("preset.0.options", "debug/export_console_wrapper", 1)) == 0,
			"a janela preta do console não abre junto do jogo")

	print("── a versão que a vitrine anuncia ──")
	var versao := str(ProjectSettings.get_setting("application/config/version", ""))
	var partes := versao.split(".")
	var nucleo := ""
	if partes.size() >= 3:
		nucleo = "%s.%s.%s" % [partes[0], partes[1], partes[2].split("-")[0]]
	# Só a mesa tem campo de versão no preset. Linux e navegador não conhecem essas
	# chaves: escrevê-las lá seria o arquivo prometendo um número que o exportador ignora.
	for chave in ["application/file_version", "application/product_version"]:
		var declarado := str(cfg.get_value("preset.0.options", chave, ""))
		_confere(declarado.begins_with(nucleo),
				"windows %s diz %s, o núcleo do config/version é %s" % [chave, declarado, nucleo])
		_confere(str(cfg.get_value("preset.1.options", chave, "ausente")) == "ausente",
				"linux não carrega %s: a plataforma não tem esse campo" % chave)
		_confere(str(cfg.get_value("preset.2.options", chave, "ausente")) == "ausente",
				"web não carrega %s: a plataforma não tem esse campo" % chave)
	print("   config/version %s • núcleo %s • preset windows diz %s / %s" % [
		versao, nucleo,
		str(cfg.get_value("preset.0.options", "application/file_version", "")),
		str(cfg.get_value("preset.0.options", "application/product_version", ""))])

	print("── a janela e o renderizador que a página copia ──")
	_confere(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 1280,
			"a viewport é 1280 de largura")
	_confere(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 720,
			"a viewport é 720 de altura")
	_confere(str(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items",
			"o stretch é canvas_items: a loja escala sem cortar o palco")
	_confere(str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")) == "gl_compatibility",
			"o renderizador é gl_compatibility: WebGL 2 de navegador aceita")
	print("   1280x720 • canvas_items • %s" % str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")))

	print("── o selo ──")
	var tem_selo := FileAccess.file_exists("res://icon.svg")
	var selo := FileAccess.get_file_as_string("res://icon.svg")
	_confere(tem_selo, "res://icon.svg existe (sem ele o exportado sai com a cara do Godot)")
	_confere(selo.contains("<svg") and selo.contains('width="128"'),
			"o selo é SVG de 128: %s" % selo.substr(0, 38).replace("\n", " "))
	print("   selo: %s • %d bytes" % [str(tem_selo), selo.length()])

	print("── em mesa: a porta de arquivo está aberta ──")
	var mesa = await _loja("mesa", false)
	_confere(bool(mesa.web_build) == false, "a sonda roda fora do navegador, então a mesa é o lado de controle")
	_confere(bool(mesa.save_transfer_box.visible), "a fileira exportar/importar aparece na loja de mesa")
	_confere(bool(mesa.web_save_note.visible) == false, "o aviso de navegador fica escondido na mesa")
	_confere(mesa.hard_reset_dialog.dialog_text.contains("exporte uma cópia"),
			"a confirmação de apagar manda exportar antes — na mesa isso é possível")
	var itens_mesa := _itens_do_menu(mesa)
	print("   tela 💾: %d item(ns)" % itens_mesa.size())
	print("   %s" % ", ".join(itens_mesa))

	print("── no navegador: a porta fecha e o aviso entra no lugar ──")
	await _fechar(mesa)
	var navegador = await _loja("navegador", true)
	_confere(bool(navegador.web_build), "esta loja nasceu já como build web (flag antes do _ready)")
	_confere(bool(navegador.save_transfer_box.visible) == false,
			"exportar/importar arquivo sai de cena no navegador")
	_confere(bool(navegador.web_save_note.visible), "o aviso sobre o armazenamento do site aparece no painel")
	_confere(str(navegador.web_save_note.text) == GameScript.WEB_SAVE_NOTE,
			"o aviso é a frase do catálogo, não um texto solto")
	_confere(str(navegador.hard_reset_dialog.dialog_text) == GameScript.WEB_SAVE_NOTE,
			"apagar no navegador não manda exportar algo que não existe")
	var itens_web := _itens_do_menu(navegador)
	_confere(itens_web.size() == itens_mesa.size() - 1,
			"a tela 💾 perde os dois botões e ganha um aviso: %d -> %d" % [itens_mesa.size(), itens_web.size()])
	for proibido in ["Exportar save para arquivo", "Importar save de arquivo"]:
		_confere(not itens_web.has(proibido), "no navegador a tela não mostra %s" % proibido)
	_confere(itens_web.has(GameScript.WEB_SAVE_NOTE), "no navegador a tela mostra o aviso no lugar dos botões")
	_confere(itens_web.has("Salvar agora") and itens_web.has("Carregar o último save do disco")
			and itens_web.has("Apagar todo o progresso"),
			"sobram as três portas que o navegador realmente tem")
	print("   tela 💾: %d item(ns)" % itens_web.size())
	print("   %s" % ", ".join(itens_web))

	print("── a guarda não move número nenhum ──")
	# Duzentos tiques sob a mesma semente, prateleira posta dos dois lados. Estado vazio
	# provaria por ausência, não pela igualdade: sem peça na estante nenhuma venda acontece.
	var retrato_navegador := _retrato(navegador)
	await _fechar(navegador)
	var mesa_corrida = await _loja("mesa com corrida", false)
	var corrida_mesa: String = await _corrida(mesa_corrida)
	await _fechar(mesa_corrida)
	var navegador_corrida = await _loja("navegador com corrida", true)
	var corrida_navegador: String = await _corrida(navegador_corrida)
	await _fechar(navegador_corrida)
	_confere(corrida_mesa == corrida_navegador,
			"200 tiques, mesma semente, mesa e navegador: %s" % str(corrida_mesa == corrida_navegador))
	print("   mesa:      %s" % corrida_mesa)
	print("   navegador: %s" % corrida_navegador)
	print("   painel web aberto antes da corrida: %s" % retrato_navegador)

	print("── as frases novas têm irmã em toda língua ──")
	var frases: Array[String] = [
		str(GameScript.WEB_SAVE_NOTE),
		"Apagar reabre a loja: nada é escrito sem a janela de confirmação aparecer antes.",
	]
	for idioma in ["en", "es", "fr", "it", "de"]:
		var tabela: Dictionary = Locales.MESSAGES[idioma]
		for frase in frases:
			_confere(tabela.has(frase) and str(tabela[frase]).strip_edges() != "",
					"%s tem irmã para: %s" % [idioma, frase.substr(0, 32)])
	_confere(Locales.MESSAGES["en"].keys().size() == Locales.MESSAGES["de"].keys().size(),
			"as tabelas fecham com o mesmo tamanho: en %d • de %d" % [
				Locales.MESSAGES["en"].keys().size(), Locales.MESSAGES["de"].keys().size()])
	print("   catálogo: %d chaves em cada uma das %d línguas traduzidas" % [
		Locales.MESSAGES["en"].keys().size(), Locales.MESSAGES.size()])
	print("   en: %s" % str(Locales.MESSAGES["en"][frases[0]]))
	print("   de: %s" % str(Locales.MESSAGES["de"][frases[0]]))

	print("── veredito ──")
	print("   %d conferência(s), %d quebra(s)" % [_conferidas, _falhas.size()])
	for falta in _falhas:
		print("   QUEBRA: %s" % falta)
	quit(0 if _falhas.is_empty() else 1)


## Loja montada, com ou sem o navegador — a flag tem de ser posta ANTES de `add_child`,
## porque é em `_ready()` que o painel é desenhado e é aí que a guarda decide a tela.
func _loja(rotulo: String, em_navegador: bool):
	_apagar("user://succubus_shop_save.cfg")
	_apagar(Locales.SETTINGS_PATH)
	_apagar("user://audio_settings.cfg")
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	g.web_build = em_navegador
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	g._reset_run()
	g._refresh_ui()
	_estoque_balcão(g)
	seed(SEED_VAL)
	return g


## Estante posta: três peças de cada produto já desbloqueado, do degrau mais barato.
func _estoque_balcão(g) -> void:
	g.gold = 1200
	g.reputation = 20
	for i in range(g.products.size()):
		if not bool(g._is_product_unlocked(g.products[i])):
			continue
		for peca in range(3):
			g._add_piece(i, TIER_BASE)


## Duzentos tiques sem nenhum `await` no meio: a rotação de atores do palco consome RNG
## guiado por frames reais, e esperar dentro do laço mudaria o resultado entre os lados.
func _corrida(g) -> String:
	_selar_conquistas(g)
	seed(SEED_VAL)
	for tick in range(200):
		g._on_customer_tick()
	await _frames(1)
	return _retrato(g)


func _retrato(g) -> String:
	return "caixa %d • fama %d • dia %d • servidos %d • decepções %d • fila %d • setor %s" % [
		g.gold, g.reputation, g.shop_day, g.customers_served, g.disappointed_customers,
		g.service_queue.size(), str(g.current_sector)]


func _selar_conquistas(g) -> void:
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)


## Toda etiqueta da tela 💾, na ordem em que o jogador desce nela.
func _itens_do_menu(loja) -> Array[String]:
	loja._show_menu_screen("save")
	var textos: Array[String] = []
	if is_instance_valid(loja.menu_box):
		for filho in loja.menu_box.get_children():
			# Só quem tem `text`:container sem a propriedade derrubaria a sonda no acesso.
			if not (filho is Label or filho is Button):
				continue
			var texto := str(filho.text)
			if not texto.is_empty():
				textos.append(texto)
	loja._close_menu()
	return textos


func _confere(condicao: bool, rotulo: String) -> void:
	_conferidas += 1
	if not condicao:
		_falhas.append(rotulo)


func _apagar(caminho: String) -> void:
	var absoluto: String = ProjectSettings.globalize_path(caminho)
	if FileAccess.file_exists(absoluto):
		DirAccess.remove_absolute(absoluto)


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
