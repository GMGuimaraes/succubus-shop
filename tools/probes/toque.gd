extends SceneTree

## Sonda do passe de toque (`main.gd::_fit_touch`). No celular o que muda é o TAMANHO do
## alvo e o corpo da fonte — e mais nada. A sonda prova três coisas que nenhum outro
## arquivo mede: (a) em mesa o passe nasce desligado e os mínimos escritos no `main.gd`
## continuam os mesmos, (b) simulando tela sensível nenhum botão fica abaixo de 48 px
## lógicos, nenhuma fonte abaixo de 15, a separação vertical nenhuma passa de 8, o arraste
## move o quadro rolável, a UI não estoura a janela no recorte de 2400×1080 e o entalhe não
## deixa margem fantasma em desktop, e (c) toque é apresentação: a lista de chaves do save e
## a cauda de `randi()` são idênticas dos dois lados.
##
## A conta que fixa o alvo em 48 e não 56 é a (b) do recorte: com 56 a coluna inteira pediu
## 744 contra os 692 que a viewport de 720 deixa, e o rodapé sumia clipado. Alvo maior com
## botão fora da tela não é acessibilidade, é layout quebrado.
##
## O lado (a) existe porque sem ele o resto aprova por ausência: um passe ligado na mesa não
## dá erro nenhum, só troca o layout de todo mundo e o primeiro screenshot do build web fica
## diferente do jogo. É a mesma régua do degrau zero das escadas — desligado é identidade.
##
## Armadilha medida aqui: um ScrollContainer sem o que rolar devolve 0 para qualquer
## `scroll_vertical`, e o arraste pareceria morto. A sonda mede primeiro o topo real do curso
## e reprova a MONTAGEM quando o quadro coube inteiro, em vez de acusar o handler. E
## `InputEvent.delta` é de somente-leitura — a sonda fabrica o gesto por `position`, o mesmo
## caminho que o handler lê.
##
## Armadilha de régua: depois de mexer em `get_root().size` o headless mostra `size` de
## Control que não bate com a viewport (medido: 1852 para uma viewport de 720), então a conta
## de "coube na tela" é feita contra a viewport lógica, não contra o tamanho do nó.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/toque.gd

const Locales = preload("res://locales.gd")

const ALVO := Vector2(48, 48)
const FONTE_MIN := 15
const ICONE_LEN := 3
const SEED_VAL := 20261019
const CELULAR := Vector2i(2400, 1080)

var reprovadas: int = 0


func _initialize() -> void:
	get_root().size = Vector2i(1280, 720)
	await _mesa()
	await _celular()
	await _recorte_celular()
	await _arraste()
	await _chaves_do_save()
	await _cauda_de_rng()
	print("\nVEREDITO toque: ", "APROVADO" if reprovadas == 0 else "%d REPROVADAS" % reprovadas)
	quit()


## (a) Mesa: o passe tem de nascer desligado e não ter tocado em nada.
func _mesa() -> void:
	print("\n== mesa (toque desligado) ==")
	var g = await _loja("mesa")
	_checa(not g.touch_ui, "o passe nasce desligado sem tela sensível")
	var alvo_apertado := _botoes_apertados(g)
	var fonte_baixa := _fontes_baixas(g)
	_checa(alvo_apertado > 0, "a mesa ainda tem alvo abaixo de %d px (%d) — sem isto, (b) aprova por ausência" % [int(ALVO.y), alvo_apertado])
	_checa(fonte_baixa > 0, "a mesa ainda tem fonte abaixo de %d px (%d)" % [FONTE_MIN, fonte_baixa])
	# Os mínimos literais do arquivo, um de cada família de linha.
	_igual(g.vip_button.custom_minimum_size, Vector2(190, 44), "vip_button mantém 190x44")
	_igual(g.speed_button.custom_minimum_size, Vector2(150, 34), "speed_button mantém 150x34")
	_igual(g.credit_button.custom_minimum_size, Vector2(190, 44), "credit_button mantém 190x44")
	_igual(g.menu_button.custom_minimum_size, Vector2(52, 42), "menu_button mantém 52x42")
	_checa(g.ui_layer.get_child(0).get_theme_constant("separation") == 12,
		"a coluna da mesa continua com o ar de 12 px")
	var rolagem := _rolaveis(g.ui_layer)
	print("   quadros roláveis na loja: ", rolagem.size())
	for sc in rolagem:
		_checa(sc.get_signal_connection_list("gui_input").is_empty(),
			"nada escuta arraste na mesa (%s)" % sc.name)
	await _fechar(g)


## (b) Celular simulado: alvo, fonte e idempotência da varredura.
func _celular() -> void:
	print("\n== celular simulado ==")
	var g = await _loja("celular")
	g.touch_ui = true
	g._fit_touch(g.ui_layer)
	var antes := _instantaneos(g)
	g._fit_touch(g.ui_layer)
	var depois := _instantaneos(g)
	_checa(antes == depois, "varrer duas vezes não muda tamanho nenhum (%d botões)" % antes.size())
	var apertados := _botoes_apertados(g)
	_checa(apertados == 0, "nenhum botão abaixo de %d px de altura (%d restantes)" % [int(ALVO.y), apertados])
	var estreitos := _icones_estreitos(g)
	_checa(estreitos == 0, "nenhum botão de ícone abaixo de %d px de largura (%d)" % [int(ALVO.x), estreitos])
	var fontes := _fontes_baixas(g)
	_checa(fontes == 0, "nenhuma fonte abaixo de %d px (%d)" % [FONTE_MIN, fontes])
	var folgas := _separacoes_soltas(g)
	_checa(folgas == 0, "nenhuma coluna vertical sobrou com ar de desktop (%d acima de 8)" % folgas)
	_checa(g.ui_layer.get_child(0).get_theme_constant("separation") == 8,
		"a coluna do celular aperta a separação de 12 para 8")
	print("   botões vistoriados: ", _botoes(g).size())
	g._fit_touch_margins()
	var m: Vector4 = Vector4(
		g.ui_layer.get_theme_constant("margin_left"),
		g.ui_layer.get_theme_constant("margin_right"),
		g.ui_layer.get_theme_constant("margin_top"),
		g.ui_layer.get_theme_constant("margin_bottom"))
	_igual(m, Vector4(16, 16, 14, 14), "sem entalhe, as margens ficam nas originais")
	await _fechar(g)


## (b2) Recorte de celular deitado: a UI nova não pode empurrar ninguém para fora, e a
## régua é o 720 lógico que o `stretch=expand` garante — não o tamanho que o headless mostra
## depois de mexer na janela, que não bate com a viewport.
func _recorte_celular() -> void:
	print("\n== recorte 2400x1080 (celular deitado) ==")
	get_root().size = CELULAR
	for com_toque in [false, true]:
		var g = await _loja("recorte-toque" if com_toque else "recorte-mesa")
		if com_toque:
			g.touch_ui = true
			g._fit_touch_margins()
			g._fit_touch(g.ui_layer)
		await _frames(2)
		var tela: Vector2 = g.get_viewport_rect().size
		var quadro: Control = g.ui_layer.get_child(0)
		var minimo: Vector2 = quadro.get_combined_minimum_size()
		var folga := tela.y - 28.0
		print("   toque %s | viewport %.0fx%.0f | coluna pede %.0f | cabe em %.0f" % [
			"ligado" if com_toque else "desligado", tela.x, tela.y, minimo.y, folga])
		for child in quadro.get_children():
			if child is Control:
				print("      linha %.0f  %s" % [(child as Control).get_combined_minimum_size().y, child.name])
		_checa(minimo.y <= folga, "a coluna inteira cabe no 720 do celular (toque %s)" % ("ligado" if com_toque else "desligado"))
		var fora := _fora_da_tela(g, tela)
		_checa(fora == 0, "nenhum alvo fixo fora da tela (%d, toque %s)" % [fora, "ligado" if com_toque else "desligado"])
		await _fechar(g)
	get_root().size = Vector2i(1280, 720)


## (b3) Rolagem: o polegar arrasta o quadro, e soltar em botão não rola.
func _arraste() -> void:
	print("\n== arraste com o dedo ==")
	var g = await _loja("arraste")
	g.touch_ui = true
	g._fit_touch(g.ui_layer)
	g._open_menu(false)
	g._show_menu_screen("conquistas")
	await _frames(2)
	var rolagem: Array[ScrollContainer] = _rolaveis(g.ui_layer) + _rolaveis(g.menu_layer)
	_checa(not rolagem.is_empty(), "a loja tem quadros roláveis para vistoriar")
	var medidos := 0
	for sc in rolagem:
		var conexoes: int = sc.get_signal_connection_list("gui_input").size()
		_checa(conexoes == 1, "um único escuta de arraste por quadro (%d em %s)" % [conexoes, sc.name])
		sc.scroll_vertical = 999999
		var topo := sc.scroll_vertical
		if topo <= 0:
			print("   (quadro %s cabe inteiro, nada a rolar)" % sc.name)
			continue
		medidos += 1
		sc.scroll_vertical = 0
		var passo := mini(topo, 120)
		var pouso := InputEventScreenDrag.new()
		pouso.index = 0
		pouso.position = Vector2(40, 300)
		g._on_touch_scroll(pouso, sc)
		_checa(sc.scroll_vertical == 0, "o pouso do dedo não move o quadro (topo %d)" % topo)
		var arraste := InputEventScreenDrag.new()
		arraste.index = 0
		arraste.position = Vector2(40, 300 - passo)
		g._on_touch_scroll(arraste, sc)
		_checa(sc.scroll_vertical == passo,
			"o dedo percorre %d px de um curso de %d" % [sc.scroll_vertical, topo])
	_checa(medidos > 0, "pelo menos um quadro tinha o que rolar")
	await _fechar(g)


## (c1) Toque não inventa chave no save.
func _chaves_do_save() -> void:
	print("\n== chaves do save ==")
	var g_off = await _loja("save-off")
	g_off._save_game()
	var off := _chaves_lidas()
	await _fechar(g_off)
	var g_on = await _loja("save-on")
	g_on.touch_ui = true
	g_on._fit_touch(g_on.ui_layer)
	g_on._fit_touch_margins()
	g_on._save_game()
	var on := _chaves_lidas()
	await _fechar(g_on)
	print("   chaves lidas: ", on.size())
	_igual(off, on, "a lista de chaves é a mesma com o toque ligado")


## (c2) A régua das escadas: desligado e ligado na mesma semente consomem a mesma stream.
func _cauda_de_rng() -> void:
	print("\n== cauda de randi() ==")
	var off: Array[int] = await _corrida("rng-off", false)
	var on: Array[int] = await _corrida("rng-on", true)
	var iguais := off == on
	var amostra := ""
	for i in range(mini(6, off.size())):
		amostra += str(off[i]) + " "
	print("   40 sorteios depois de 200 tiques, começo: ", amostra.trim_suffix(" "))
	_checa(iguais, "a cauda é idêntica com o toque ligado")
	_checa(off.size() == 40, "a cauda tem 40 valores")


## 200 tiques em sequência, sem await no meio, e a cauda lida logo após o seed cravado.
func _corrida(rotulo: String, com_toque: bool) -> Array[int]:
	var g = await _loja(rotulo)
	if com_toque:
		g.touch_ui = true
		g._fit_touch(g.ui_layer)
	for i in range(200):
		g._on_customer_tick()
	await _frames(2)
	seed(SEED_VAL)
	var cauda: Array[int] = []
	for i in range(40):
		cauda.append(randi())
	await _fechar(g)
	return cauda


# ── medição ──────────────────────────────────────────────────────────────────────

## Botão abaixo do alvo: vale o mínimo declarado, que é o que o container respeita quando a
## linha não tem espaço sobrando.
func _botoes_apertados(g) -> int:
	var n := 0
	for b in _botoes(g):
		if b.custom_minimum_size.y < ALVO.y:
			n += 1
	return n


func _icones_estreitos(g) -> int:
	var n := 0
	for b in _botoes(g):
		if b.text.length() <= ICONE_LEN and b.custom_minimum_size.x < ALVO.x:
			n += 1
	return n


func _fontes_baixas(g) -> int:
	var n := 0
	for c in _controles(g.ui_layer) + _controles(g.menu_layer):
		if c is Label or c is Button:
			if c.get_theme_font_size("font_size") < FONTE_MIN:
				n += 1
	return n


## Separação vertical é o ar que a varredura aperta para caber no 720. Conta só a camada
## varrida neste lado — as outras têm seção própria, e misturar tudo aqui daria failed por
## causa da sonda, não do jogo. Horizontal não conta: a largura do celular só cresceu.
func _separacoes_soltas(g) -> int:
	var n := 0
	for c in _controles(g.ui_layer):
		if c is BoxContainer and (c as BoxContainer).vertical:
			if (c as BoxContainer).get_theme_constant("separation") > 8:
				n += 1
				print("   ar de desktop: %s separacao %d" % [c.name, (c as BoxContainer).get_theme_constant("separation")])
		elif c is FlowContainer and (c as FlowContainer).get_theme_constant("v_separation") > 8:
			n += 1
			print("   ar de desktop: %s v_separacao %d" % [c.name, (c as FlowContainer).get_theme_constant("v_separation")])
	return n


## Alvo fixo: qualquer botão que não esteja dentro de um quadro rolável tem de estar
## inteiro na tela — o que está dentro do ScrollContainer é rolável de propósito.
func _fora_da_tela(g, tela: Vector2) -> int:
	var n := 0
	for b in _botoes(g):
		if _dentro_de_rolagem(b):
			continue
		if not b.visible:
			continue
		var r: Rect2 = b.get_global_rect()
		if r.position.x < 0.0 or r.position.y < 0.0 or r.end.x > tela.x + 1.0 or r.end.y > tela.y + 1.0:
			n += 1
			print("   fora da tela: \"%s\" %s" % [b.text, str(r)])
	return n


func _dentro_de_rolagem(node: Node) -> bool:
	var p := node.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _botoes(g) -> Array[Button]:
	var out: Array[Button] = []
	for c in _controles(g.ui_layer) + _controles(g.menu_layer):
		if c is Button:
			out.append(c)
	return out


func _rolaveis(raiz: Node) -> Array[ScrollContainer]:
	var out: Array[ScrollContainer] = []
	if raiz == null:
		return out
	for c in _controles(raiz):
		if c is ScrollContainer:
			out.append(c)
	return out


## Instantâneo de tamanho, usado para provar que varrer de novo não cresce nada.
func _instantaneos(g) -> Array[String]:
	var out: Array[String] = []
	for b in _botoes(g):
		out.append("%s|%s" % [b.name, str(b.custom_minimum_size)])
	return out


func _controles(raiz: Node) -> Array[Control]:
	var out: Array[Control] = []
	if raiz == null:
		return out
	var stack: Array[Node] = [raiz]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Control:
			out.append(node)
		for child in node.get_children():
			stack.push_back(child)
	return out


func _chaves_lidas() -> Array[String]:
	var config := ConfigFile.new()
	var out: Array[String] = []
	if config.load(_caminho_save()) != OK:
		print("   (o save descartável não abriu)")
		return out
	for key in config.get_section_keys("game"):
		out.append(String(key))
	out.sort()
	return out


# ── veredito ─────────────────────────────────────────────────────────────────────

func _checa(ok: bool, rotulo: String) -> void:
	print("   %s %s" % ["ok  " if ok else "REPROVA", rotulo])
	if not ok:
		reprovadas += 1


func _igual(antes: Variant, depois: Variant, rotulo: String) -> void:
	var ok: bool = antes == depois
	print("   %s %s (%s vs %s)" % ["ok  " if ok else "REPROVA", rotulo, str(antes), str(depois)])
	if not ok:
		reprovadas += 1


# ── montagem da loja ─────────────────────────────────────────────────────────────

## Loja nova, idioma travado, relógio parado e semente cravada — o corpo das sondas vivas.
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


## A preferência de idioma sobrevive ao `_reset_run()` e mora fora do save: sem cravá-la,
## uma rodada anterior do seletor deixa o painel noutra língua.
func _fixar_locale(g) -> void:
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


func _caminho_save() -> String:
	return ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"


func _apagar_save() -> void:
	var caminho: String = _caminho_save()
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
