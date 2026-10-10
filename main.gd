extends Control

const SAVE_PATH := "user://succubus_shop_save.cfg"

var gold: int = 80
var reputation: int = 0
var customers_served: int = 0
var affection: int = 0
var adult_content_enabled: bool = true
var private_moments_unlocked: int = 0
var ad_level: int = 0
var imp_hired: bool = false
var ticks: int = 0
var rare_events_found: int = 0
var last_event: String = "Bem-vindo! Vamos transformar esta espelunca em um império."

var products: Array = [
	{"name": "Poção de Dano Emocional", "cost": 8, "price": 15, "stock": 1, "desc": "Lembra você daquela mensagem que mandou em 2018."},
	{"name": "Pato Amaldiçoado Premium", "cost": 10, "price": 24, "stock": 1, "desc": "Ele não faz nada. Mas julga suas decisões."},
	{"name": "Lágrimas de Jogador Derrotado", "cost": 12, "price": 30, "stock": 1, "desc": "Ingrediente raro. Salgado. Muito salgado."},
	{"name": "Caixa Misteriosa Vazia", "cost": 5, "price": 12, "stock": 1, "desc": "A surpresa é perceber que você pagou por uma caixa."},
	{"name": "Poção de Confiança Instantânea", "cost": 9, "price": 22, "stock": 1, "desc": "Funciona até alguém pedir para você explicar."}
]

var gold_label: Label
var rep_label: Label
var customers_label: Label
var affection_label: Label
var status_label: Label
var event_label: Label
var products_box: VBoxContainer
var craft_buttons: Array = []
var product_labels: Array = []
var upgrade_button: Button
var imp_button: Button
var private_button: Button
var adult_toggle_button: Button

func _ready() -> void:
	_load_game()
	_build_ui()
	_refresh_ui()
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.timeout.connect(_on_customer_tick)
	add_child(timer)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.075, 0.055, 0.11, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 12)
	root.add_theme_constant_override("margin_left", 28)
	root.add_theme_constant_override("margin_right", 28)
	root.add_theme_constant_override("margin_top", 22)
	root.add_theme_constant_override("margin_bottom", 22)
	add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)

	var title := Label.new()
	title.text = "SUCCUBUS SHOP"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.67, 0.88))
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "  •  Loja mágica, negócios duvidosos"
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.75, 0.88))
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(subtitle)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 24)
	root.add_child(stats)

	gold_label = _make_stat_label("Ouro: 0")
	stats.add_child(gold_label)
	rep_label = _make_stat_label("Reputação: 0")
	stats.add_child(rep_label)
	customers_label = _make_stat_label("Clientes: 0")
	stats.add_child(customers_label)
	affection_label = _make_stat_label("Afinidade: 0/10")
	stats.add_child(affection_label)

	var intro := Label.new()
	intro.text = "A dona da loja está convencida de que qualquer porcaria pode virar um produto premium."
	intro.add_theme_font_size_override("font_size", 16)
	intro.add_theme_color_override("font_color", Color(0.91, 0.87, 0.95))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var separator := HSeparator.new()
	root.add_child(separator)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 22)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)

	var product_title := Label.new()
	product_title.text = "MERCADORIAS"
	product_title.add_theme_font_size_override("font_size", 22)
	product_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	left.add_child(product_title)

	var hint := Label.new()
	hint.text = "Fabrique itens para abastecer a loja. Os clientes chegam automaticamente."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.71, 0.81))
	left.add_child(hint)

	products_box = VBoxContainer.new()
	products_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	products_box.add_theme_constant_override("separation", 8)
	left.add_child(products_box)

	for i in range(products.size()):
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.105, 0.20, 1)
		style.border_color = Color(0.36, 0.22, 0.43, 1)
		style.set_border_width_all(1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		products_box.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var product_label := Label.new()
		product_label.add_theme_font_size_override("font_size", 17)
		product_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.96))
		info.add_child(product_label)
		product_labels.append(product_label)

		var desc := Label.new()
		desc.text = str(products[i]["desc"])
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.76, 0.72, 0.81))
		info.add_child(desc)

		var craft := Button.new()
		craft.custom_minimum_size = Vector2(150, 44)
		craft.add_theme_font_size_override("font_size", 15)
		craft.pressed.connect(_craft_product.bind(i))
		row.add_child(craft)
		craft_buttons.append(craft)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 300
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	body.add_child(right)

	var shop_title := Label.new()
	shop_title.text = "ESCRITÓRIO DA CHEFE"
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	right.add_child(shop_title)

	var mascot := Label.new()
	mascot.text = "  (•̀ᴗ•́)و\n\n  A CHEFE DIZ:\n  “Amor, não é golpe\n  se você leu a descrição.”"
	mascot.custom_minimum_size = Vector2(280, 120)
	mascot.add_theme_font_size_override("font_size", 19)
	mascot.add_theme_color_override("font_color", Color(1.0, 0.83, 0.92))
	mascot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(mascot)

	status_label = Label.new()
	status_label.text = "CLIENTE"
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.87, 0.72, 1.0))
	right.add_child(status_label)

	event_label = Label.new()
	event_label.custom_minimum_size = Vector2(280, 110)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.92))
	right.add_child(event_label)

	upgrade_button = Button.new()
	upgrade_button.custom_minimum_size.y = 48
	upgrade_button.text = "Comprar propaganda infernal"
	upgrade_button.pressed.connect(_buy_advertising)
	right.add_child(upgrade_button)

	imp_button = Button.new()
	imp_button.custom_minimum_size.y = 48
	imp_button.text = "Contratar diabrete estagiário"
	imp_button.pressed.connect(_hire_imp)
	right.add_child(imp_button)

	private_button = Button.new()
	private_button.custom_minimum_size.y = 44
	private_button.text = "Momento especial (afinidade 5)"
	private_button.pressed.connect(_show_private_moment)
	right.add_child(private_button)

	adult_toggle_button = Button.new()
	adult_toggle_button.custom_minimum_size.y = 40
	adult_toggle_button.pressed.connect(_toggle_adult_content)
	right.add_child(adult_toggle_button)

	var footer := Label.new()
	footer.text = "Protótipo 0.3 • Clientes especiais e eventos raros • Conteúdo sensual opcional"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.62, 0.57, 0.68))
	root.add_child(footer)

func _make_stat_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.91, 1.0, 0.75))
	return label

func _craft_product(index: int) -> void:
	var item: Dictionary = products[index]
	var cost: int = int(item["cost"])
	if gold < cost:
		last_event = "A caixa registradora está tão vazia que até o eco pediu demissão. Falta ouro."
		_refresh_ui()
		return
	gold -= cost
	item["stock"] = int(item["stock"]) + 1
	last_event = "Produzido: %s. A qualidade foi inspecionada por alguém que não entende do assunto." % item["name"]
	_save_game()
	_refresh_ui()

func _buy_advertising() -> void:
	var cost := 75 + ad_level * 60
	if gold < cost:
		last_event = "A chefe quer anunciar em todos os planos astrais, mas o orçamento discorda."
		_refresh_ui()
		return
	gold -= cost
	ad_level += 1
	last_event = "Campanha lançada! Agora os clientes pagam mais porque o anúncio tinha letras brilhantes."
	_save_game()
	_refresh_ui()

func _hire_imp() -> void:
	if imp_hired:
		last_event = "O diabrete já está trabalhando. Ele pediu aumento e recebeu uma bolacha."
		_refresh_ui()
		return
	if gold < 125:
		last_event = "Contratar o diabrete custa 125 de ouro. Ele aceita pagamento em dinheiro, não em exposição."
		_refresh_ui()
		return
	gold -= 125
	imp_hired = true
	last_event = "Contratado! O diabrete produz uma Poção de Dano Emocional a cada 9 segundos."
	_save_game()
	_refresh_ui()

func _on_customer_tick() -> void:
	ticks += 1
	if imp_hired and ticks % 3 == 0:
		products[0]["stock"] = int(products[0]["stock"]) + 1
		last_event = "Seu diabrete fabricou uma poção. Ele perguntou se isso conta como experiência profissional."

	# Eventos raros podem acontecer mesmo quando a loja está sem estoque.
	if randi() % 100 < 7:
		_trigger_random_event()
		_save_game()
		_refresh_ui()
		return

	var available: Array[int] = []
	for i in range(products.size()):
		if int(products[i]["stock"]) > 0:
			available.append(i)

	if available.is_empty():
		status_label.text = "CLIENTE: foi embora"
		last_event = "Um cliente entrou, viu as prateleiras vazias e foi comprar em outro plano de existência."
		reputation = maxi(0, reputation - 1)
	else:
		var profiles: Array[Dictionary] = [
			{"name": "Speedrunner", "favorite": 3, "line": "“Compra feita. Onde fica o botão de pular diálogo?”"},
			{"name": "Especialista em Tudo", "favorite": 0, "line": "“Vi um tutorial de 12 segundos e agora sou consultor.”"},
			{"name": "Gótico Econômico", "favorite": 2, "line": "“Minhas lágrimas são artesanais. As suas têm desconto?”"},
			{"name": "Colecionador de Patos", "favorite": 1, "line": "“Este pato combina com os outros 47 que não me julgam.”"},
			{"name": "Coach Interdimensional", "favorite": 4, "line": "“Acredite no seu potencial! Meu boleto acredita em mim.”"},
			{"name": "Cliente Misterioso", "favorite": -1, "line": "“Não nos conhecemos. Se nos conhecemos, não se lembra.”"}
		]
		var profile: Dictionary = profiles[randi() % profiles.size()]
		var preferred_index: int = int(profile["favorite"])
		var chosen_index: int = available[randi() % available.size()]
		if preferred_index >= 0 and available.has(preferred_index) and randi() % 100 < 70:
			chosen_index = preferred_index

		var item: Dictionary = products[chosen_index]
		item["stock"] = int(item["stock"]) - 1
		var price_multiplier: float = 1.0 + 0.20 * ad_level
		var preference_bonus := 0
		if preferred_index == chosen_index:
			preference_bonus = maxi(2, int(round(float(item["price"]) * 0.25)))
			last_event = "%s comprou %s e pagou %d de bônus! %s" % [
				profile["name"], item["name"], preference_bonus, profile["line"]
			]
		else:
			last_event = "%s comprou %s. %s" % [
				profile["name"], item["name"], profile["line"]
			]
		var sale_price: int = int(round(float(item["price"]) * price_multiplier)) + preference_bonus
		gold += sale_price
		reputation += 1
		customers_served += 1
		affection = mini(100, affection + 1)
		status_label.text = "CLIENTE: %s" % profile["name"]

		if adult_content_enabled and affection >= 10 and affection % 10 == 0:
			last_event = "A súcubo se aproxima com um sorriso cúmplice: “Você está conquistando minha confiança… e isso pode render recompensas bem interessantes.”"
		elif affection > 0 and affection % 5 == 0:
			last_event = "A chefe pisca para você: “Olha só, estamos nos entendendo melhor, querido.”"

	_save_game()
	_refresh_ui()


func _trigger_random_event() -> void:
	var events: Array[Dictionary] = [
		{
			"name": "Pombo do Fim dos Tempos",
			"message": "Um pombo de olhos brilhantes pousa na placa. Ele prevê o fim do mundo na próxima terça-feira e deixa uma moeda como gorjeta.",
			"gold": 25, "reputation": 2
		},
		{
			"name": "Especialista em Tudo",
			"message": "Um autoproclamado especialista oferece consultoria baseada num tutorial de 12 segundos. Por algum motivo, isso atrai clientes.",
			"gold": 18, "reputation": 1
		},
		{
			"name": "Caixa Misteriosa Suspeitamente Comum",
			"message": "Você abre uma caixa misteriosa e encontra outra caixa, menor. Um colecionador paga uma fortuna pela experiência conceitual.",
			"gold": 20, "reputation": 0
		},
		{
			"name": "Café Quântico",
			"message": "O diabrete toma um café que está quente, frio e atrasado ao mesmo tempo. Ele trabalha tão rápido que sobra dinheiro no balcão.",
			"gold": 15, "reputation": 0
		},
		{
			"name": "Atualização de Segunda-feira",
			"message": "A realidade reinicia para instalar uma atualização. A nota de versão diz apenas: “corrigido um erro que ninguém tinha percebido”.",
			"gold": -8, "reputation": 2
		},
		{
			"name": "Pote de Moedas de Chocolate",
			"message": "Um cliente paga por um pote de moedas de chocolate e insiste que são um investimento. Você consegue vender o pote de novo.",
			"gold": 12, "reputation": 1
		},
		{
			"name": "Placa Antialgoritmo",
			"message": "Você instala uma placa escrito “Não alimente o algoritmo”. A loja vira tendência justamente por causa da placa.",
			"gold": 22, "reputation": 1
		}
	]
	var event: Dictionary = events[randi() % events.size()]
	gold = maxi(0, gold + int(event["gold"]))
	reputation = maxi(0, reputation + int(event["reputation"]))
	rare_events_found += 1
	last_event = "EVENTO: %s! %s" % [event["name"], event["message"]]
	if adult_content_enabled and affection >= 5 and randi() % 2 == 0:
		last_event += "\nA súcubo ri: “Nossa loja é um desastre adorável. Ainda bem que você está aqui, querido.”"
func _refresh_ui() -> void:
	if not is_instance_valid(gold_label):
		return
	gold_label.text = "Ouro: %d" % gold
	rep_label.text = "Reputação: %d" % reputation
	customers_label.text = "Clientes: %d" % customers_served
	affection_label.text = "Afinidade: %d/100" % affection
	event_label.text = last_event
	for i in range(products.size()):
		var item: Dictionary = products[i]
		product_labels[i].text = "%s  |  Estoque: %d  |  Venda: %d ouro" % [item["name"], item["stock"], item["price"]]
		craft_buttons[i].text = "Fabricar (%d)" % item["cost"]
		craft_buttons[i].disabled = gold < int(item["cost"])
	var ad_cost := 75 + ad_level * 60
	upgrade_button.text = "Propaganda infernal • %d ouro (nível %d)" % [ad_cost, ad_level]
	upgrade_button.disabled = gold < ad_cost
	private_button.text = "Momento especial (afinidade 5)" if affection >= 5 else "Momento especial • afinidade %d/5" % affection
	private_button.disabled = affection < 5
	adult_toggle_button.text = "Cenas sensuais: LIGADAS" if adult_content_enabled else "Cenas sensuais: DESLIGADAS"
	if imp_hired:
		imp_button.text = "Diabrete contratado ✓"
		imp_button.disabled = true
	else:
		imp_button.text = "Contratar diabrete • 125 ouro"
		imp_button.disabled = gold < 125

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "gold", gold)
	config.set_value("game", "reputation", reputation)
	config.set_value("game", "customers_served", customers_served)
	config.set_value("game", "affection", affection)
	config.set_value("game", "adult_content_enabled", adult_content_enabled)
	config.set_value("game", "private_moments_unlocked", private_moments_unlocked)
	config.set_value("game", "ad_level", ad_level)
	config.set_value("game", "imp_hired", imp_hired)
	config.set_value("game", "rare_events_found", rare_events_found)
	config.set_value("game", "products", products)
	config.save(SAVE_PATH)

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	gold = int(config.get_value("game", "gold", gold))
	reputation = int(config.get_value("game", "reputation", reputation))
	customers_served = int(config.get_value("game", "customers_served", customers_served))
	affection = int(config.get_value("game", "affection", affection))
	adult_content_enabled = bool(config.get_value("game", "adult_content_enabled", adult_content_enabled))
	private_moments_unlocked = int(config.get_value("game", "private_moments_unlocked", private_moments_unlocked))
	ad_level = int(config.get_value("game", "ad_level", ad_level))
	imp_hired = bool(config.get_value("game", "imp_hired", imp_hired))
	rare_events_found = int(config.get_value("game", "rare_events_found", rare_events_found))
	var saved_products = config.get_value("game", "products", products)
	if saved_products is Array and saved_products.size() == products.size():
		products = saved_products


func _show_private_moment() -> void:
	if affection < 5:
		last_event = "“Paciência, querido. Primeiro conquiste minha confiança.”"
	elif not adult_content_enabled:
		last_event = "O momento especial está desativado nas opções de conteúdo adulto."
	else:
		private_moments_unlocked += 1
		var moments: Array[String] = [
			"A súcubo inclina a cabeça, dá uma piscadela e puxa você para mais perto: “Esse é nosso segredinho, combinado?”",
			"Ela gira uma moeda entre os dedos e sorri de lado: “Talvez eu revele mais de mim quando nossa parceria ficar ainda mais lucrativa.”",
			"A chefe faz uma pose provocante e ri baixinho: “Você desbloqueou meu lado favorito: o que não aparece para qualquer cliente.”"
		]
		last_event = moments[(private_moments_unlocked - 1) % moments.size()]
	_save_game()
	_refresh_ui()

func _toggle_adult_content() -> void:
	adult_content_enabled = not adult_content_enabled
	last_event = "Cenas sensuais ativadas. As recompensas especiais estão disponíveis." if adult_content_enabled else "Cenas sensuais desativadas. A progressão e a economia continuam normalmente."
	_save_game()
	_refresh_ui()