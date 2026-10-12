extends Control

const SAVE_PATH := "user://succubus_shop_save.cfg"
const Regulars = preload("res://regulars.gd")
const GameAudio = preload("res://audio.gd")
const Factions = preload("res://factions.gd")
const Ingredients = preload("res://ingredients.gd")

var gold: int = 80
var reputation: int = 0
var customers_served: int = 0
var affection: int = 0
var regular_bonds: Dictionary = {}
var regular_orders_completed: Dictionary = {}
var regular_story_progress: Dictionary = {}
var regular_story_completed: Array[String] = []
var faction_standing: Dictionary = {}
var adult_content_enabled: bool = true
var private_moments_unlocked: int = 0
var ad_level: int = 0
var imp_hired: bool = false
var ticks: int = 0
var rare_events_found: int = 0
var unlocked_achievements: Array[String] = []
var player_level: int = 1
var player_xp: int = 0
var skill_points: int = 0
var shop_day: int = 1
var daily_quest_index: int = 0
var daily_quest_progress: int = 0
var daily_quest_claimed: bool = false
var daily_gold_earned: int = 0
var daily_crafts: int = 0
var alchemy_rank: int = 0
var trade_rank: int = 0
var charm_rank: int = 0
var logistics_rank: int = 0
var ingredient_stock: Dictionary = {"essencia": 1, "pena": 1, "sal": 1, "vazio": 1, "po_lunar": 1, "tinta": 1}
var premium_stock: Dictionary = {}
var total_ingredients_bought: int = 0
var premium_crafted: int = 0
var talent_label: Label
var alchemy_button: Button
var trade_button: Button
var charm_button: Button
var logistics_button: Button
var ingredient_labels: Array = []
var ingredient_buttons: Array = []
var last_event: String = "Bem-vindo! Vamos transformar esta espelunca em um império."

const PRODUCT_ICONS := ["🧪", "🦆", "💧", "📦", "✨", "🐟", "🌀", "💎", "📜", "☕"]

var products: Array = [
	{"name": "Poção de Dano Emocional", "cost": 8, "price": 15, "stock": 1, "ingredients": {"essencia": 1}, "desc": "Lembra você daquela mensagem que mandou em 2018."},
	{"name": "Pato Amaldiçoado Premium", "cost": 10, "price": 24, "stock": 1, "ingredients": {"pena": 1}, "desc": "Ele não faz nada. Mas julga suas decisões."},
	{"name": "Lágrimas de Jogador Derrotado", "cost": 12, "price": 30, "stock": 1, "ingredients": {"sal": 1}, "desc": "Ingrediente raro. Salgado. Muito salgado."},
	{"name": "Caixa Misteriosa Vazia", "cost": 5, "price": 12, "stock": 1, "ingredients": {"vazio": 1}, "desc": "A surpresa é perceber que você pagou por uma caixa."},
	{"name": "Poção de Confiança Instantânea", "cost": 9, "price": 22, "stock": 1, "ingredients": {"essencia": 1, "tinta": 1}, "desc": "Funciona até alguém pedir para você explicar."},
	{"name": "Elixir de Memória de Peixe", "cost": 18, "price": 48, "stock": 0, "required_level": 3, "ingredients": {"sal": 1, "po_lunar": 1}, "desc": "Você esquece por que comprou. E compra de novo."},
	{"name": "Incenso de Teletransporte Barato", "cost": 26, "price": 68, "stock": 0, "required_level": 5, "ingredients": {"po_lunar": 1, "tinta": 1}, "desc": "Leva você a três metros dali. Às vezes quatro."},
	{"name": "Cristal de Crédito Cósmico", "cost": 42, "price": 115, "stock": 0, "required_level": 8, "ingredients": {"vazio": 1, "tinta": 2}, "desc": "Converte promessas vagas em dívidas muito concretas."},
	{"name": "Pergaminho de Procrastinação Certificada", "cost": 55, "price": 150, "stock": 0, "required_level": 10, "ingredients": {"tinta": 2, "essencia": 1}, "desc": "Adia tarefas importantes com selo ISO de preguiça."},
	{"name": "Frasco de Motivação de Segunda-feira", "cost": 70, "price": 195, "stock": 0, "required_level": 12, "ingredients": {"po_lunar": 2, "sal": 1}, "desc": "Efeito dura até o primeiro e-mail."}
]

var gold_label: Label
var rep_label: Label
var customers_label: Label
var affection_label: Label
var status_label: Label
var regulars_label: Label
var faction_label: Label
var event_label: Label
var achievement_label: Label
var progression_label: Label
var quest_label: Label
var quest_button: Button
var products_box: VBoxContainer
var craft_buttons: Array = []
var product_labels: Array = []
var product_margin_labels: Array = []
var upgrade_button: Button
var imp_button: Button
var private_button: Button
var adult_toggle_button: Button
var audio: Node
var mute_button: Button
var seller_portrait: TextureRect
var reaction_label: Label
var seller_speech_label: Label
var customer_tween: Tween
var happy_customers: int = 0
var disappointed_customers: int = 0
var customer_portrait: TextureRect
var customer_portrait_paths: Array[String] = ["res://assets/customer_adventurer.svg", "res://assets/customer_mage.svg", "res://assets/customer_goth.svg"]
var seller_portrait_paths: Dictionary = {"happy": "res://assets/seller_happy.svg", "neutral": "res://assets/seller_neutral.svg", "surprised": "res://assets/seller_surprised.svg"}

const SELLER_DELIGHTED_LINES := [
	"A súcubo pisca para o cliente: “Gosto de quem tem bom gosto. Volte sempre, herói.”",
	"Ela manda um beijinho no ar: “A casa adora você. E eu também, um pouquinho.”",
	"A chefe ronrona: “Mais um conquistado. Eu sou boa nisso, não sou?”",
	"Ela se debruça no balcão, sorrindo: “Leva mais uma? Para mim, você nunca é pouco.”"
]
const SELLER_CONTENT_LINES := [
	"A chefe sorri de canto: “Cliente satisfeito é cliente que volta. Ou que indica.”",
	"Ela guarda as moedas com estilo: “Bom negócio. Traga o próximo, querido.”",
	"A súcubo confere o caixa: “Nada mal. Nada mal mesmo.”"
]
const SELLER_DISAPPOINTED_LINES := [
	"A súcubo faz beicinho: “Ele foi embora? Que grosseria... Eu vou me esforçar mais, prometo.”",
	"A chefe bate o pé: “Estoque vazio é pecado, até para mim. Reabasteça, por favor!”",
	"Ela cruza os braços: “Ninguém resiste ao meu charme duas vezes. Ele volta, você vai ver.”"
]
const SELLER_CHARMED_LINES := [
	"A súcubo se inclina no balcão e sussurra algo. O cliente sai sorrindo, jurando que volta.",
	"Ela gira uma mecha de cabelo: “Sem estoque? Deixa comigo.” O cliente sai prometendo voltar."
]

func _ready() -> void:
	audio = GameAudio.new()
	add_child(audio)
	_load_game()
	_build_ui()
	_refresh_ui()
	_start_ambient_animations()
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.timeout.connect(_on_customer_tick)
	add_child(timer)

func _start_ambient_animations() -> void:
	for portrait in [seller_portrait, customer_portrait]:
		if not is_instance_valid(portrait):
			continue
		portrait.pivot_offset = portrait.custom_minimum_size / 2.0
		var breathe := create_tween().set_loops()
		breathe.tween_property(portrait, "scale", Vector2(1.025, 1.025), 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		breathe.tween_property(portrait, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(seller_portrait):
		var glow := create_tween().set_loops()
		glow.tween_property(seller_portrait, "modulate", Color(1.0, 0.91, 1.0, 1.0), 2.2).set_trans(Tween.TRANS_SINE)
		glow.tween_property(seller_portrait, "modulate", Color.WHITE, 2.2).set_trans(Tween.TRANS_SINE)

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/shop_scene.svg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.theme = _build_visual_theme()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

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
	_build_audio_controls(header)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 24)
	root.add_child(stats)

	gold_label = _make_stat_label("Ouro: 0")
	stats.add_child(gold_label)
	rep_label = _make_stat_label("Reputação: 0")
	stats.add_child(rep_label)
	customers_label = _make_stat_label("Clientes: 0")
	stats.add_child(customers_label)
	affection_label = _make_stat_label("Afinidade: 0/100")
	stats.add_child(affection_label)

	progression_label = Label.new()
	progression_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progression_label.add_theme_font_size_override("font_size", 16)
	progression_label.add_theme_color_override("font_color", Color(0.78, 0.95, 1.0))
	root.add_child(progression_label)

	talent_label = Label.new()
	talent_label.add_theme_font_size_override("font_size", 14)
	talent_label.add_theme_color_override("font_color", Color(0.88, 0.83, 1.0))
	root.add_child(talent_label)

	var talent_row := HBoxContainer.new()
	talent_row.add_theme_constant_override("separation", 8)
	root.add_child(talent_row)
	alchemy_button = Button.new()
	alchemy_button.pressed.connect(_buy_talent.bind("alchemy"))
	talent_row.add_child(alchemy_button)
	trade_button = Button.new()
	trade_button.pressed.connect(_buy_talent.bind("trade"))
	talent_row.add_child(trade_button)
	charm_button = Button.new()
	charm_button.pressed.connect(_buy_talent.bind("charm"))
	talent_row.add_child(charm_button)
	logistics_button = Button.new()
	logistics_button.pressed.connect(_buy_talent.bind("logistics"))
	talent_row.add_child(logistics_button)

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

	var product_scroll := ScrollContainer.new()
	product_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	product_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(product_scroll)

	products_box = VBoxContainer.new()
	products_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	products_box.add_theme_constant_override("separation", 8)
	product_scroll.add_child(products_box)

	for i in range(products.size()):
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.075, 0.045, 0.12, 0.94)
		style.border_color = Color(0.52, 0.30, 0.65, 0.95)
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.shadow_color = Color(0.015, 0.005, 0.035, 0.65)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 2)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", style)
		products_box.add_child(card)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)

		var icon_badge := PanelContainer.new()
		icon_badge.custom_minimum_size = Vector2(52, 52)
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(0.20, 0.08, 0.25, 0.95)
		icon_style.border_color = Color(0.72, 0.40, 0.77, 0.95)
		icon_style.set_border_width_all(1)
		icon_style.set_corner_radius_all(12)
		icon_badge.add_theme_stylebox_override("panel", icon_style)
		row.add_child(icon_badge)
		var icon_label := Label.new()
		icon_label.text = PRODUCT_ICONS[i]
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 27)
		icon_badge.add_child(icon_label)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 3)
		row.add_child(info)

		var product_label := Label.new()
		product_label.add_theme_font_size_override("font_size", 16)
		product_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.96))
		product_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(product_label)
		product_labels.append(product_label)

		var margin_label := Label.new()
		margin_label.add_theme_font_size_override("font_size", 13)
		margin_label.add_theme_color_override("font_color", Color(0.65, 1.0, 0.72))
		info.add_child(margin_label)
		product_margin_labels.append(margin_label)

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

	var market_title := Label.new()
	market_title.text = "MERCADO DE INGREDIENTES"
	market_title.add_theme_font_size_override("font_size", 20)
	market_title.add_theme_color_override("font_color", Color(0.78, 0.95, 1.0))
	products_box.add_child(market_title)

	var market_hint := Label.new()
	market_hint.text = "Os preços mudam a cada dia. Compre barato, fabrique caro."
	market_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_hint.add_theme_font_size_override("font_size", 13)
	market_hint.add_theme_color_override("font_color", Color(0.75, 0.71, 0.81))
	products_box.add_child(market_hint)

	for ingredient in Ingredients.DATA:
		var ingredient_id := str(ingredient["id"])
		var market_card := PanelContainer.new()
		var market_style := StyleBoxFlat.new()
		market_style.bg_color = Color(0.045, 0.07, 0.11, 0.94)
		market_style.border_color = Color(0.28, 0.48, 0.62, 0.95)
		market_style.set_border_width_all(1)
		market_style.set_corner_radius_all(10)
		market_style.shadow_color = Color(0.005, 0.015, 0.03, 0.65)
		market_style.shadow_size = 4
		market_style.shadow_offset = Vector2(0, 2)
		market_style.content_margin_left = 14
		market_style.content_margin_right = 14
		market_style.content_margin_top = 8
		market_style.content_margin_bottom = 8
		market_card.add_theme_stylebox_override("panel", market_style)
		products_box.add_child(market_card)

		var market_row := HBoxContainer.new()
		market_row.add_theme_constant_override("separation", 12)
		market_card.add_child(market_row)

		var market_info := VBoxContainer.new()
		market_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		market_row.add_child(market_info)

		var ingredient_label := Label.new()
		ingredient_label.add_theme_font_size_override("font_size", 15)
		ingredient_label.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0))
		market_info.add_child(ingredient_label)
		ingredient_labels.append(ingredient_label)

		var ingredient_desc := Label.new()
		ingredient_desc.text = str(ingredient["desc"])
		ingredient_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ingredient_desc.add_theme_font_size_override("font_size", 12)
		ingredient_desc.add_theme_color_override("font_color", Color(0.70, 0.76, 0.82))
		market_info.add_child(ingredient_desc)

		var buy := Button.new()
		buy.custom_minimum_size = Vector2(150, 40)
		buy.add_theme_font_size_override("font_size", 14)
		buy.pressed.connect(_buy_ingredient.bind(ingredient_id))
		market_row.add_child(buy)
		ingredient_buttons.append(buy)

	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size.x = 300
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(right_scroll)

	var right_panel := PanelContainer.new()
	var right_panel_style := StyleBoxFlat.new()
	right_panel_style.bg_color = Color(0.025, 0.018, 0.055, 0.90)
	right_panel_style.border_color = Color(0.43, 0.25, 0.68, 0.95)
	right_panel_style.set_border_width_all(1)
	right_panel_style.set_corner_radius_all(10)
	right_panel_style.content_margin_left = 12
	right_panel_style.content_margin_right = 12
	right_panel_style.content_margin_top = 12
	right_panel_style.content_margin_bottom = 12
	right_panel.add_theme_stylebox_override("panel", right_panel_style)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_panel)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	right_panel.add_child(right)

	var shop_title := Label.new()
	shop_title.text = "ESCRITÓRIO DA CHEFE"
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	right.add_child(shop_title)

	var portrait_row := HBoxContainer.new()
	portrait_row.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_row.add_theme_constant_override("separation", 10)
	right.add_child(portrait_row)

	var seller_frame := PanelContainer.new()
	var seller_frame_style := StyleBoxFlat.new()
	seller_frame_style.bg_color = Color(0.17, 0.055, 0.16, 0.98)
	seller_frame_style.border_color = Color(1.0, 0.52, 0.80, 1.0)
	seller_frame_style.set_border_width_all(2)
	seller_frame_style.set_corner_radius_all(14)
	seller_frame_style.content_margin_left = 4
	seller_frame_style.content_margin_right = 4
	seller_frame_style.content_margin_top = 4
	seller_frame_style.content_margin_bottom = 4
	seller_frame.add_theme_stylebox_override("panel", seller_frame_style)
	portrait_row.add_child(seller_frame)
	seller_portrait = TextureRect.new()
	seller_portrait.custom_minimum_size = Vector2(126, 136)
	seller_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seller_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	seller_portrait.texture = load(seller_portrait_paths["neutral"])
	seller_frame.add_child(seller_portrait)

	var customer_frame := PanelContainer.new()
	var customer_frame_style := StyleBoxFlat.new()
	customer_frame_style.bg_color = Color(0.045, 0.10, 0.16, 0.98)
	customer_frame_style.border_color = Color(0.43, 0.80, 1.0, 0.95)
	customer_frame_style.set_border_width_all(2)
	customer_frame_style.set_corner_radius_all(14)
	customer_frame_style.content_margin_left = 4
	customer_frame_style.content_margin_right = 4
	customer_frame_style.content_margin_top = 4
	customer_frame_style.content_margin_bottom = 4
	customer_frame.add_theme_stylebox_override("panel", customer_frame_style)
	portrait_row.add_child(customer_frame)
	customer_portrait = TextureRect.new()
	customer_portrait.custom_minimum_size = Vector2(106, 116)
	customer_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	customer_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	customer_portrait.texture = load(customer_portrait_paths[0])
	customer_frame.add_child(customer_portrait)

	reaction_label = Label.new()
	reaction_label.custom_minimum_size = Vector2(260, 24)
	reaction_label.add_theme_font_size_override("font_size", 15)
	reaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(reaction_label)

	var mascot := Label.new()
	mascot.text = "A CHEFE DIZ: “Amor, não é golpe se você leu a descrição.”"
	mascot.custom_minimum_size = Vector2(260, 72)
	mascot.add_theme_font_size_override("font_size", 15)
	mascot.add_theme_color_override("font_color", Color(1.0, 0.83, 0.92))
	mascot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(mascot)
	seller_speech_label = mascot

	status_label = Label.new()
	status_label.text = "CLIENTE"
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.87, 0.72, 1.0))
	right.add_child(status_label)

	regulars_label = Label.new()
	regulars_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	regulars_label.add_theme_font_size_override("font_size", 13)
	regulars_label.add_theme_color_override("font_color", Color(0.82, 0.78, 1.0))
	right.add_child(regulars_label)

	faction_label = Label.new()
	faction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	faction_label.add_theme_font_size_override("font_size", 13)
	faction_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.72))
	right.add_child(faction_label)

	event_label = Label.new()
	event_label.custom_minimum_size = Vector2(280, 110)
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.add_theme_color_override("font_color", Color(0.88, 0.85, 0.92))
	right.add_child(event_label)

	achievement_label = Label.new()
	achievement_label.custom_minimum_size = Vector2(280, 92)
	achievement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	achievement_label.add_theme_color_override("font_color", Color(0.91, 0.88, 0.68))
	achievement_label.add_theme_font_size_override("font_size", 13)
	right.add_child(achievement_label)

	quest_label = Label.new()
	quest_label.custom_minimum_size = Vector2(280, 78)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.add_theme_color_override("font_color", Color(0.78, 0.95, 1.0))
	right.add_child(quest_label)

	quest_button = Button.new()
	quest_button.custom_minimum_size.y = 42
	quest_button.text = "Resgatar contrato"
	quest_button.pressed.connect(_claim_daily_quest)
	right.add_child(quest_button)

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
	footer.text = "Protótipo 0.6 • Facções, fregueses e contratos • Conteúdo sensual opcional"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.62, 0.57, 0.68))
	root.add_child(footer)

func _build_audio_controls(parent: Control) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	mute_button = Button.new()
	mute_button.custom_minimum_size = Vector2(96, 34)
	mute_button.pressed.connect(_on_mute_pressed)
	parent.add_child(mute_button)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(110, 24)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = audio.volume
	slider.value_changed.connect(_on_volume_changed)
	parent.add_child(slider)
	_update_mute_button()

func _on_mute_pressed() -> void:
	audio.toggle_muted()
	audio.play("click")
	_update_mute_button()

func _on_volume_changed(value: float) -> void:
	audio.set_volume(value)

func _update_mute_button() -> void:
	if is_instance_valid(mute_button):
		mute_button.text = "♪ Som: mudo" if audio.muted else "♪ Som: ligado"

func _build_visual_theme() -> Theme:
	var visual_theme := Theme.new()
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.035, 0.025, 0.075, 0.94)
	normal.border_color = Color(0.43, 0.25, 0.68, 1.0)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.15, 0.06, 0.22, 0.98)
	hover.border_color = Color(1.0, 0.56, 0.82, 1.0)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.28, 0.08, 0.38, 1.0)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.07, 0.055, 0.09, 0.88)
	disabled.border_color = Color(0.22, 0.18, 0.28, 1.0)
	visual_theme.set_stylebox("normal", "Button", normal)
	visual_theme.set_stylebox("hover", "Button", hover)
	visual_theme.set_stylebox("pressed", "Button", pressed)
	visual_theme.set_stylebox("disabled", "Button", disabled)
	visual_theme.set_color("font_color", "Button", Color(0.97, 0.91, 1.0))
	visual_theme.set_color("font_hover_color", "Button", Color(1.0, 0.78, 0.9))
	visual_theme.set_color("font_pressed_color", "Button", Color(1.0, 0.9, 1.0))
	visual_theme.set_color("font_disabled_color", "Button", Color(0.48, 0.43, 0.55))
	visual_theme.set_font_size("font_size", "Button", 15)
	visual_theme.set_constant("outline_size", "Label", 1)
	visual_theme.set_color("font_outline_color", "Label", Color(0.025, 0.015, 0.05, 0.8))
	return visual_theme

func _make_stat_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.91, 1.0, 0.75))
	return label

func _craft_product(index: int) -> void:
	var item: Dictionary = products[index]
	if not _is_product_unlocked(item):
		last_event = "Essa receita ainda está bloqueada. Continue subindo de nível para pesquisá-la."
		_refresh_ui()
		return
	var cost: int = maxi(1, int(round(float(item["cost"]) * (1.0 - 0.05 * alchemy_rank))))
	if gold < cost:
		last_event = "A caixa registradora está tão vazia que até o eco pediu demissão. Falta ouro."
		_refresh_ui()
		return
	var missing := _missing_ingredients(item)
	if not missing.is_empty():
		last_event = "Faltam ingredientes para %s: %s. Compre no mercado enquanto o preço está bom." % [item["name"], ", ".join(missing)]
		_refresh_ui()
		return
	gold -= cost
	_consume_ingredients(item)
	item["stock"] = int(item["stock"]) + 1
	daily_crafts += 1
	audio.play("craft")
	_add_xp(5)
	_progress_daily_quest("craft", 1)
	var premium_chance := 8 + 4 * alchemy_rank
	if randi() % 100 < premium_chance:
		var product_name := str(item["name"])
		premium_stock[product_name] = int(premium_stock.get(product_name, 0)) + 1
		premium_crafted += 1
		audio.play("rare")
		last_event = "OBRA-PRIMA! %s saiu impecável e vale 50%% a mais. A chefe finge que foi de propósito." % product_name
	else:
		last_event = "Produzido: %s. A qualidade foi inspecionada por alguém que não entende do assunto." % item["name"]
	_check_achievements()
	_save_game()
	_refresh_ui()

func _missing_ingredients(item: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	var recipe: Dictionary = item.get("ingredients", {})
	for ingredient_id in recipe.keys():
		var needed := int(recipe[ingredient_id])
		var held := int(ingredient_stock.get(ingredient_id, 0))
		if held < needed:
			var ingredient_name := str(Ingredients.find(str(ingredient_id)).get("name", ingredient_id))
			missing.append("%s (%d/%d)" % [ingredient_name, held, needed])
	return missing

func _consume_ingredients(item: Dictionary) -> void:
	var recipe: Dictionary = item.get("ingredients", {})
	for ingredient_id in recipe.keys():
		ingredient_stock[ingredient_id] = int(ingredient_stock.get(ingredient_id, 0)) - int(recipe[ingredient_id])

## Estimativa conservadora: preço de venda base menos custo de fabricação e
## preço atual de reposição dos ingredientes da receita.
func _estimated_margin(item: Dictionary) -> int:
	var craft_cost := maxi(1, int(round(float(item["cost"]) * (1.0 - 0.05 * alchemy_rank))))
	var ingredient_cost := 0
	var recipe: Dictionary = item.get("ingredients", {})
	for ingredient_id in recipe.keys():
		ingredient_cost += _ingredient_price(str(ingredient_id)) * int(recipe[ingredient_id])
	return int(item["price"]) - craft_cost - ingredient_cost

func _ingredient_price(ingredient_id: String) -> int:
	var base := Ingredients.price_for_day(ingredient_id, shop_day)
	return maxi(1, int(round(float(base) * (1.0 - 0.05 * logistics_rank))))

func _buy_ingredient(ingredient_id: String) -> void:
	var price := _ingredient_price(ingredient_id)
	if gold < price:
		last_event = "O fornecedor riu da sua oferta. Falta ouro para %s." % str(Ingredients.find(ingredient_id).get("name", ingredient_id))
		_refresh_ui()
		return
	gold -= price
	ingredient_stock[ingredient_id] = int(ingredient_stock.get(ingredient_id, 0)) + 1
	total_ingredients_bought += 1
	audio.play("buy")
	last_event = "Comprado: %s por %d ouro. O fornecedor jurou que era o preço de amigo." % [str(Ingredients.find(ingredient_id).get("name", ingredient_id)), price]
	_check_achievements()
	_save_game()
	_refresh_ui()

## Produto em alta no dia: vende por 30% a mais. Determinístico por dia.
func _demand_index() -> int:
	return posmod(abs(hash("demanda:%d" % shop_day)), products.size())

func _buy_advertising() -> void:
	var cost := 75 + ad_level * 60
	if gold < cost:
		last_event = "A chefe quer anunciar em todos os planos astrais, mas o orçamento discorda."
		_refresh_ui()
		return
	gold -= cost
	ad_level += 1
	audio.play("buy")
	last_event = "Campanha lançada! Agora os clientes pagam mais porque o anúncio tinha letras brilhantes."
	_check_achievements()
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
	audio.play("buy")
	last_event = "Contratado! O diabrete produz uma Poção de Dano Emocional a cada 9 segundos."
	_save_game()
	_refresh_ui()

func _on_customer_tick() -> void:
	ticks += 1
	_set_seller_mood("neutral")
	if is_instance_valid(reaction_label):
		reaction_label.text = ""
	if ticks % 20 == 0:
		shop_day += 1
		daily_quest_index = (daily_quest_index + 1) % 4
		daily_quest_progress = 0
		daily_quest_claimed = false
		daily_gold_earned = 0
		daily_crafts = 0
		last_event = "Dia %d começou! Um novo contrato está disponível; o anterior expirou." % shop_day
	if imp_hired and ticks % 3 == 0:
		products[0]["stock"] = int(products[0]["stock"]) + 1
		last_event = "Seu diabrete fabricou uma poção. Ele perguntou se isso conta como experiência profissional."

	# Eventos raros podem acontecer mesmo quando a loja está sem estoque.
	if randi() % 100 < 7:
		_trigger_random_event()
		audio.play("rare")
		_add_xp(20)
		_progress_daily_quest("rare", 1)
		_check_achievements()
		_save_game()
		_refresh_ui()
		return

	var available: Array[int] = []
	for i in range(products.size()):
		if _is_product_unlocked(products[i]) and int(products[i]["stock"]) > 0:
			available.append(i)

	if available.is_empty():
		_animate_customer_arrival({"name": "Cliente Misterioso", "portrait": 2, "faction": "mercadores"})
		status_label.text = "CLIENTE: foi embora"
		_set_seller_mood("surprised")
		last_event = "Um cliente entrou, viu as prateleiras vazias e foi comprar em outro plano de existência. Reabasteça a loja para não perder vendas."
		_react_to_visit("disappointed", randi() % 100 < 15 * charm_rank)
	else:
		var profiles: Array[Dictionary] = [
			{"name": "Speedrunner", "favorite": 3, "line": "“Compra feita. Onde fica o botão de pular diálogo?”", "faction": "aventureiros", "portrait": 0},
			{"name": "Especialista em Tudo", "favorite": 0, "line": "“Vi um tutorial de 12 segundos e agora sou consultor.”", "faction": "guildas", "portrait": 1},
			{"name": "Gótico Econômico", "favorite": 2, "line": "“Minhas lágrimas são artesanais. As suas têm desconto?”", "faction": "submundo", "portrait": 2},
			{"name": "Colecionador de Patos", "favorite": 1, "line": "“Este pato combina com os outros 47 que não me julgam.”", "faction": "mercadores", "portrait": 0},
			{"name": "Coach Interdimensional", "favorite": 4, "line": "“Acredite no seu potencial! Meu boleto acredita em mim.”", "faction": "guildas", "portrait": 1},
			{"name": "Cliente Misterioso", "favorite": -1, "line": "“Não nos conhecemos. Se nos conhecemos, não se lembra.”", "faction": "nobres", "portrait": 2}
		]
		var profile: Dictionary = profiles[randi() % profiles.size()]
		if randi() % 100 < 35:
			var regular: Dictionary = Regulars.DATA[randi() % Regulars.DATA.size()]
			var regular_id := str(regular["id"])
			var bond := int(regular_bonds.get(regular_id, 0))
			var tier := Regulars.tier_for(bond)
			var lines_by_tier: Array = regular["lines"][tier]
			var regular_line := str(lines_by_tier[randi() % lines_by_tier.size()])
			var personal_request := tier >= 1 and randi() % 100 < 35
			if personal_request:
				regular_line = str(regular["request"])
			profile = {
				"name": regular["name"],
				"favorite": int(regular["favorite"]),
				"line": regular_line,
				"regular_id": regular_id,
				"portrait": int(regular["portrait"]),
				"tier": tier,
				"personal_request": personal_request,
				"faction": str(regular.get("faction", "aventureiros"))
			}
		_animate_customer_arrival(profile)
		var preferred_index: int = int(profile["favorite"])
		var chosen_index: int = available[randi() % available.size()]
		if preferred_index >= 0 and available.has(preferred_index) and randi() % 100 < 70:
			chosen_index = preferred_index

		var item: Dictionary = products[chosen_index]
		item["stock"] = int(item["stock"]) - 1
		var price_multiplier: float = (1.0 + 0.20 * ad_level) * (1.0 + 0.08 * trade_rank)
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
		if chosen_index == _demand_index():
			var demand_bonus := int(round(float(item["price"]) * 0.30))
			sale_price += demand_bonus
			last_event += "\nProduto em alta hoje: +%d ouro." % demand_bonus
		var premium_count := int(premium_stock.get(str(item["name"]), 0))
		if premium_count > 0:
			var premium_bonus := int(round(float(item["price"]) * 0.50))
			sale_price += premium_bonus
			premium_stock[str(item["name"])] = premium_count - 1
			last_event += "\nVenda de obra-prima: +%d ouro." % premium_bonus
		var faction_id := str(profile.get("faction", ""))
		var faction_bonus := 0
		if not faction_id.is_empty():
			var faction_tier := Factions.tier_for(int(faction_standing.get(faction_id, 0)))
			faction_bonus = int(round(float(item["price"]) * Factions.price_bonus(faction_tier)))
			sale_price += faction_bonus
		var fulfilled_personal_request := profile.has("personal_request") and bool(profile["personal_request"]) and preferred_index == chosen_index
		var headline_locked := false
		if fulfilled_personal_request:
			var request_bonus := maxi(8, int(round(float(item["price"]) * 0.5)))
			sale_price += request_bonus
			var completed_id := str(profile["regular_id"])
			regular_orders_completed[completed_id] = int(regular_orders_completed.get(completed_id, 0)) + 1
			last_event = "PEDIDO ESPECIAL concluído para %s! +%d ouro e +10 XP. %s" % [profile["name"], request_bonus, profile["line"]]
			_add_xp(10)
			headline_locked = true
		gold += sale_price
		audio.play("coin")
		reputation += 1
		customers_served += 1
		if profile.has("regular_id"):
			var regular_id := str(profile["regular_id"])
			var old_bond := int(regular_bonds.get(regular_id, 0))
			var old_tier := Regulars.tier_for(old_bond)
			var new_bond := old_bond + 1 + (2 if fulfilled_personal_request else 0)
			regular_bonds[regular_id] = new_bond
			var new_tier := Regulars.tier_for(new_bond)
			var regular_data: Dictionary = Regulars.find(regular_id)
			if new_tier > old_tier:
				var tier_lines: Array = regular_data.get("tier_up", [])
				var tier_line := str(tier_lines[new_tier - 1]) if tier_lines.size() >= new_tier else "Este freguês agora confia mais na sua loja."
				last_event = "%s agora é %s! %s" % [regular_data.get("short", regular_data.get("name", "Freguês")), Regulars.TIER_NAMES[new_tier], tier_line]
				headline_locked = true
			if preferred_index == chosen_index and new_bond >= 3 and not regular_story_completed.has(regular_id):
				var story_progress := int(regular_story_progress.get(regular_id, 0)) + 1
				regular_story_progress[regular_id] = story_progress
				if story_progress >= 3:
					regular_story_completed.append(regular_id)
					var story_reward := 60 + player_level * 5
					gold += story_reward
					reputation += 2
					_add_xp(30)
					last_event = "CAPÍTULO CONCLUÍDO: a história de %s avança! Recompensa: %d ouro, +30 XP e +2 reputação." % [regular_data.get("short", regular_data.get("name", "Freguês")), story_reward]
					headline_locked = true
				else:
					last_event += "\nMissão pessoal: %d/3 compras favoritas." % story_progress
		if not faction_id.is_empty():
			var old_standing := int(faction_standing.get(faction_id, 0))
			var old_faction_tier := Factions.tier_for(old_standing)
			var standing_gain := 1 + (1 if preferred_index == chosen_index else 0)
			var new_standing := old_standing + standing_gain
			faction_standing[faction_id] = new_standing
			var new_faction_tier := Factions.tier_for(new_standing)
			if new_faction_tier > old_faction_tier:
				var faction_data: Dictionary = Factions.find(faction_id)
				var faction_lines: Array = faction_data.get("tier_up", [])
				var faction_line := str(faction_lines[new_faction_tier - 1]) if faction_lines.size() >= new_faction_tier else "Essa facção agora respeita mais a loja."
				var faction_reward := 25 + player_level * 4 + new_faction_tier * 10
				gold += faction_reward
				reputation += new_faction_tier
				_add_xp(15)
				var faction_msg := "FACÇÃO: %s agora é %s! +%d ouro. %s" % [
					faction_data.get("short", faction_id), Factions.TIER_NAMES[new_faction_tier], faction_reward, faction_line
				]
				last_event = last_event + "\n" + faction_msg if headline_locked else faction_msg
			elif faction_bonus > 0:
				last_event += "\nBônus de facção (%s): +%d ouro." % [Factions.find(faction_id).get("short", faction_id), faction_bonus]
		daily_gold_earned += sale_price
		_add_xp(12)
		_progress_daily_quest("customers", 1)
		_progress_daily_quest("gold", sale_price)
		affection = mini(100, affection + 1 + charm_rank)
		status_label.text = "CLIENTE: %s" % profile["name"]
		_set_seller_mood("happy")
		_react_to_visit("delighted" if preferred_index == chosen_index else "content")

		if adult_content_enabled and affection >= 10 and affection % 10 == 0:
			last_event = "A súcubo se aproxima com um sorriso cúmplice: “Você está conquistando minha confiança… e isso pode render recompensas bem interessantes.”"
		elif affection > 0 and affection % 5 == 0:
			last_event = "A chefe pisca para você: “Olha só, estamos nos entendendo melhor, querido.”"

	_check_achievements()
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

func _animate_customer_arrival(profile: Dictionary) -> void:
	if not is_instance_valid(customer_portrait):
		return
	var portrait_index := int(profile.get("portrait", -1))
	if portrait_index < 0 or portrait_index >= customer_portrait_paths.size():
		portrait_index = 0
		var profile_name := str(profile.get("name", ""))
		match profile_name:
			"Especialista em Tudo", "Coach Interdimensional", "Lyra Cinzalume":
				portrait_index = 1
			"Gótico Econômico", "Cliente Misterioso", "Korvax, o Bárbaro Sensível", "Mina Duas-Adagas":
				portrait_index = 2
			_:
				portrait_index = 0
	if customer_tween != null and customer_tween.is_valid():
		customer_tween.kill()
	customer_portrait.modulate = Color.WHITE
	customer_portrait.rotation = 0.0
	customer_portrait.texture = load(customer_portrait_paths[portrait_index])
	customer_portrait.pivot_offset = customer_portrait.size / 2.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(customer_portrait, "modulate:a", 1.0, 0.24).from(0.0)
	tween.tween_property(customer_portrait, "scale", Vector2.ONE, 0.28).from(Vector2(0.78, 0.78))

func _react_to_visit(mood: String, charm_save: bool = false) -> void:
	var text := ""
	var color := Color(0.91, 1.0, 0.75)
	var line := ""
	var animation := mood
	match mood:
		"delighted":
			happy_customers += 1
			reputation += 1
			audio.play("happy")
			text = "♥ Cliente encantado! +1 de reputação"
			color = Color(1.0, 0.78, 0.9)
			line = SELLER_DELIGHTED_LINES.pick_random()
		"content":
			text = "Cliente satisfeito."
			color = Color(0.91, 1.0, 0.75)
			line = SELLER_CONTENT_LINES.pick_random()
		"disappointed":
			if charm_save:
				text = "♥ O charme da chefe salvou a visita. Sem penalidade."
				color = Color(1.0, 0.78, 0.9)
				line = SELLER_CHARMED_LINES.pick_random()
				animation = "delighted"
				audio.play("happy")
				_set_seller_mood("happy")
			else:
				disappointed_customers += 1
				audio.play("sad")
				reputation = maxi(0, reputation - 1)
				text = "… Cliente decepcionado. -1 de reputação"
				color = Color(1.0, 0.55, 0.55)
				line = SELLER_DISAPPOINTED_LINES.pick_random()
				_set_seller_mood("surprised")
	if is_instance_valid(reaction_label):
		reaction_label.text = text
		reaction_label.add_theme_color_override("font_color", color)
	if is_instance_valid(seller_speech_label):
		seller_speech_label.text = line
	_play_customer_reaction(animation)

func _play_customer_reaction(mood: String) -> void:
	if not is_instance_valid(customer_portrait):
		return
	customer_portrait.pivot_offset = customer_portrait.size / 2.0
	var tween := create_tween()
	customer_tween = tween
	tween.tween_interval(0.35)
	match mood:
		"delighted":
			tween.tween_property(customer_portrait, "modulate", Color(1.0, 0.92, 0.80, 1.0), 0.15)
			for i in range(2):
				tween.tween_property(customer_portrait, "scale", Vector2(1.14, 1.14), 0.14)
				tween.tween_property(customer_portrait, "scale", Vector2.ONE, 0.14)
			tween.tween_property(customer_portrait, "modulate:a", 0.3, 0.9)
		"disappointed":
			tween.tween_property(customer_portrait, "modulate", Color(0.62, 0.66, 0.80, 1.0), 0.2)
			for i in range(3):
				tween.tween_property(customer_portrait, "rotation", 0.10, 0.07)
				tween.tween_property(customer_portrait, "rotation", -0.10, 0.07)
			tween.tween_property(customer_portrait, "rotation", 0.0, 0.07)
			tween.tween_property(customer_portrait, "modulate:a", 0.25, 0.9)
		_:
			tween.tween_property(customer_portrait, "modulate:a", 0.45, 0.9)

func _set_seller_mood(mood: String) -> void:
	if is_instance_valid(seller_portrait) and seller_portrait_paths.has(mood):
		seller_portrait.texture = load(str(seller_portrait_paths[mood]))

func _refresh_ui() -> void:
	if not is_instance_valid(gold_label):
		return
	gold_label.text = "Ouro: %d" % gold
	rep_label.text = "Reputação: %d" % reputation
	customers_label.text = "Clientes: %d  ♥%d  ✗%d" % [customers_served, happy_customers, disappointed_customers]
	affection_label.text = "Afinidade: %d/100" % affection
	event_label.text = last_event
	if is_instance_valid(regulars_label):
		var regular_lines: Array[String] = ["FREGUESES RECORRENTES"]
		for regular in Regulars.DATA:
			var regular_id := str(regular["id"])
			var bond := int(regular_bonds.get(regular_id, 0))
			var tier := Regulars.tier_for(bond)
			var orders_done := int(regular_orders_completed.get(regular_id, 0))
			regular_lines.append("%s — %s (%d visitas, %d pedidos)" % [regular["short"], Regulars.TIER_NAMES[tier], bond, orders_done])
			if regular_story_completed.has(regular_id):
				regular_lines.append("  ✦ História concluída")
			elif bond >= 3:
				regular_lines.append("  ◇ Missão pessoal: %d/3 compras favoritas" % int(regular_story_progress.get(regular_id, 0)))
		regulars_label.text = "\n".join(regular_lines)
	if is_instance_valid(faction_label):
		var faction_lines: Array[String] = ["REPUTAÇÃO POR FACÇÃO"]
		for faction in Factions.DATA:
			var faction_id := str(faction["id"])
			var standing := int(faction_standing.get(faction_id, 0))
			var tier := Factions.tier_for(standing)
			var bonus_pct := int(round(Factions.price_bonus(tier) * 100.0))
			var bonus_text := "  +%d%%" % bonus_pct if bonus_pct > 0 else ""
			faction_lines.append("%s — %s (%d)%s" % [faction["short"], Factions.TIER_NAMES[tier], standing, bonus_text])
		faction_label.text = "\n".join(faction_lines)
	if is_instance_valid(progression_label):
		progression_label.text = "NÍVEL %d  •  XP: %d/%d  •  Pontos de talento: %d  •  Dia %d" % [player_level, player_xp, _xp_required(), skill_points, shop_day]
	if is_instance_valid(talent_label):
		talent_label.text = "TALENTOS • Alquimia %d/5 | Comércio %d/5 | Carisma %d/5 | Logística %d/5" % [alchemy_rank, trade_rank, charm_rank, logistics_rank]
	for talent_button in [alchemy_button, trade_button, charm_button]:
		if is_instance_valid(talent_button):
			talent_button.disabled = skill_points <= 0
	if is_instance_valid(alchemy_button):
		alchemy_button.text = "Alquimia %d/5" % alchemy_rank
		alchemy_button.disabled = skill_points <= 0 or alchemy_rank >= 5
	if is_instance_valid(trade_button):
		trade_button.text = "Comércio %d/5" % trade_rank
		trade_button.disabled = skill_points <= 0 or trade_rank >= 5
	if is_instance_valid(charm_button):
		charm_button.text = "Carisma %d/5" % charm_rank
		charm_button.disabled = skill_points <= 0 or charm_rank >= 5
	if is_instance_valid(logistics_button):
		logistics_button.text = "Logística %d/5" % logistics_rank
		logistics_button.disabled = skill_points <= 0 or logistics_rank >= 5
	for i in range(Ingredients.DATA.size()):
		var ingredient: Dictionary = Ingredients.DATA[i]
		var ingredient_id := str(ingredient["id"])
		var held := int(ingredient_stock.get(ingredient_id, 0))
		var price := _ingredient_price(ingredient_id)
		ingredient_labels[i].text = "%s | Estoque: %d | Preço: %d ouro" % [ingredient["name"], held, price]
		ingredient_buttons[i].text = "Comprar (%d)" % price
		ingredient_buttons[i].disabled = gold < price
	if is_instance_valid(quest_label):
		var quest := _get_daily_quest()
		var target: int = int(quest["target"])
		var progress_text := "%d/%d" % [mini(daily_quest_progress, target), target]
		quest_label.text = "CONTRATO DO DIA\n%s\nProgresso: %s%s" % [quest["name"], progress_text, "\nConcluído! Resgate a recompensa." if daily_quest_progress >= target and not daily_quest_claimed else "\nRecompensa resgatada." if daily_quest_claimed else ""]
	if is_instance_valid(quest_button):
		var quest_ready: bool = daily_quest_progress >= int(_get_daily_quest()["target"]) and not daily_quest_claimed
		quest_button.disabled = not quest_ready
		quest_button.text = "Resgatar contrato" if quest_ready else "Contrato resgatado ✓" if daily_quest_claimed else "Contrato em andamento"
	if is_instance_valid(achievement_label):
		achievement_label.text = _get_achievement_summary()
	for i in range(products.size()):
		var item: Dictionary = products[i]
		var unlocked := _is_product_unlocked(item)
		var required_level: int = int(item.get("required_level", 1))
		var premium_count := int(premium_stock.get(str(item["name"]), 0))
		var demand_marker := "  ✦ EM ALTA" if i == _demand_index() else ""
		if unlocked:
			var margin := _estimated_margin(item)
			product_labels[i].text = "%s%s\nEstoque: %d  •  Premium: %d  •  Venda: %d ouro" % [item["name"], demand_marker, item["stock"], premium_count, item["price"]]
			product_margin_labels[i].text = "Margem estimada: %s%d ouro" % ["+" if margin >= 0 else "−", abs(margin)]
			product_margin_labels[i].add_theme_color_override("font_color", Color(0.65, 1.0, 0.72) if margin >= 0 else Color(1.0, 0.55, 0.55))
		else:
			product_labels[i].text = "🔒 %s  •  Desbloqueia no nível %d" % [item["name"], required_level]
			product_margin_labels[i].text = "Receita bloqueada — continue evoluindo"
			product_margin_labels[i].add_theme_color_override("font_color", Color(0.67, 0.62, 0.73))
		var craft_cost := maxi(1, int(round(float(item["cost"]) * (1.0 - 0.05 * alchemy_rank))))
		var missing_ingredients: Array[String] = []
		if unlocked:
			missing_ingredients = _missing_ingredients(item)
		craft_buttons[i].text = "Fabricar (%d)" % craft_cost if unlocked and missing_ingredients.is_empty() else "Faltam ingredientes" if unlocked else "Receita bloqueada"
		craft_buttons[i].disabled = not unlocked or gold < craft_cost or not missing_ingredients.is_empty()
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
	config.set_value("game", "regular_bonds", regular_bonds)
	config.set_value("game", "regular_orders_completed", regular_orders_completed)
	config.set_value("game", "regular_story_progress", regular_story_progress)
	config.set_value("game", "regular_story_completed", regular_story_completed)
	config.set_value("game", "faction_standing", faction_standing)
	config.set_value("game", "adult_content_enabled", adult_content_enabled)
	config.set_value("game", "private_moments_unlocked", private_moments_unlocked)
	config.set_value("game", "ad_level", ad_level)
	config.set_value("game", "imp_hired", imp_hired)
	config.set_value("game", "rare_events_found", rare_events_found)
	config.set_value("game", "unlocked_achievements", unlocked_achievements)
	config.set_value("game", "player_level", player_level)
	config.set_value("game", "player_xp", player_xp)
	config.set_value("game", "skill_points", skill_points)
	config.set_value("game", "shop_day", shop_day)
	config.set_value("game", "daily_quest_index", daily_quest_index)
	config.set_value("game", "daily_quest_progress", daily_quest_progress)
	config.set_value("game", "daily_quest_claimed", daily_quest_claimed)
	config.set_value("game", "daily_gold_earned", daily_gold_earned)
	config.set_value("game", "daily_crafts", daily_crafts)
	config.set_value("game", "alchemy_rank", alchemy_rank)
	config.set_value("game", "trade_rank", trade_rank)
	config.set_value("game", "charm_rank", charm_rank)
	config.set_value("game", "logistics_rank", logistics_rank)
	config.set_value("game", "ingredient_stock", ingredient_stock)
	config.set_value("game", "premium_stock", premium_stock)
	config.set_value("game", "total_ingredients_bought", total_ingredients_bought)
	config.set_value("game", "premium_crafted", premium_crafted)
	config.set_value("game", "happy_customers", happy_customers)
	config.set_value("game", "disappointed_customers", disappointed_customers)
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
	var saved_bonds = config.get_value("game", "regular_bonds", {})
	if saved_bonds is Dictionary:
		regular_bonds = saved_bonds.duplicate(true)
	var saved_orders = config.get_value("game", "regular_orders_completed", {})
	if saved_orders is Dictionary:
		regular_orders_completed = saved_orders.duplicate(true)
	var saved_story_progress = config.get_value("game", "regular_story_progress", {})
	if saved_story_progress is Dictionary:
		regular_story_progress = saved_story_progress.duplicate(true)
	var saved_story_completed = config.get_value("game", "regular_story_completed", [])
	if saved_story_completed is Array:
		for completed_id in saved_story_completed:
			if not regular_story_completed.has(str(completed_id)):
				regular_story_completed.append(str(completed_id))
	var saved_factions = config.get_value("game", "faction_standing", {})
	if saved_factions is Dictionary:
		faction_standing = saved_factions.duplicate(true)
	adult_content_enabled = bool(config.get_value("game", "adult_content_enabled", adult_content_enabled))
	private_moments_unlocked = int(config.get_value("game", "private_moments_unlocked", private_moments_unlocked))
	ad_level = int(config.get_value("game", "ad_level", ad_level))
	imp_hired = bool(config.get_value("game", "imp_hired", imp_hired))
	rare_events_found = int(config.get_value("game", "rare_events_found", rare_events_found))
	player_level = int(config.get_value("game", "player_level", player_level))
	player_xp = int(config.get_value("game", "player_xp", player_xp))
	skill_points = int(config.get_value("game", "skill_points", skill_points))
	shop_day = int(config.get_value("game", "shop_day", shop_day))
	daily_quest_index = int(config.get_value("game", "daily_quest_index", daily_quest_index))
	daily_quest_progress = int(config.get_value("game", "daily_quest_progress", daily_quest_progress))
	daily_quest_claimed = bool(config.get_value("game", "daily_quest_claimed", daily_quest_claimed))
	daily_gold_earned = int(config.get_value("game", "daily_gold_earned", daily_gold_earned))
	daily_crafts = int(config.get_value("game", "daily_crafts", daily_crafts))
	alchemy_rank = int(config.get_value("game", "alchemy_rank", alchemy_rank))
	trade_rank = int(config.get_value("game", "trade_rank", trade_rank))
	charm_rank = int(config.get_value("game", "charm_rank", charm_rank))
	logistics_rank = int(config.get_value("game", "logistics_rank", logistics_rank))
	var saved_ingredients = config.get_value("game", "ingredient_stock", ingredient_stock)
	if saved_ingredients is Dictionary:
		ingredient_stock = saved_ingredients.duplicate(true)
	var saved_premium = config.get_value("game", "premium_stock", {})
	if saved_premium is Dictionary:
		premium_stock = saved_premium.duplicate(true)
	total_ingredients_bought = int(config.get_value("game", "total_ingredients_bought", total_ingredients_bought))
	premium_crafted = int(config.get_value("game", "premium_crafted", premium_crafted))
	happy_customers = int(config.get_value("game", "happy_customers", happy_customers))
	disappointed_customers = int(config.get_value("game", "disappointed_customers", disappointed_customers))
	var saved_achievements = config.get_value("game", "unlocked_achievements", [])
	if saved_achievements is Array:
		unlocked_achievements.clear()
		for achievement in saved_achievements:
			unlocked_achievements.append(str(achievement))
	var saved_products = config.get_value("game", "products", [])
	if saved_products is Array:
		for saved_item in saved_products:
			if not saved_item is Dictionary:
				continue
			for current_index in range(products.size()):
				if str(products[current_index]["name"]) == str(saved_item.get("name", "")):
					products[current_index]["stock"] = maxi(0, int(saved_item.get("stock", products[current_index]["stock"])))
					break






func _max_faction_tier() -> int:
	var highest := 0
	for faction in Factions.DATA:
		highest = maxi(highest, Factions.tier_for(int(faction_standing.get(str(faction["id"]), 0))))
	return highest

func _is_product_unlocked(item: Dictionary) -> bool:
	return player_level >= int(item.get("required_level", 1))

func _buy_talent(kind: String) -> void:
	if skill_points <= 0:
		last_event = "Você ainda não tem pontos de talento. Suba de nível para ganhar mais."
		_refresh_ui()
		return
	match kind:
		"alchemy":
			if alchemy_rank >= 5:
				return
			alchemy_rank += 1
			last_event = "Talento Alquimia melhorado! Fabricar mercadorias fica 5% mais barato por nível."
		"trade":
			if trade_rank >= 5:
				return
			trade_rank += 1
			last_event = "Talento Comércio melhorado! O valor das vendas aumenta 8% por nível."
		"charm":
			if charm_rank >= 5:
				return
			charm_rank += 1
			last_event = "Talento Carisma melhorado! Cada venda aumenta mais sua afinidade com a chefe."
		"logistics":
			if logistics_rank >= 5:
				return
			logistics_rank += 1
			last_event = "Talento Logística melhorado! Ingredientes ficam 5% mais baratos por nível."

	skill_points -= 1
	audio.play("talent")
	_save_game()
	_refresh_ui()

func _xp_required() -> int:
	return 40 + player_level * 25

func _add_xp(amount: int) -> void:
	var previous_level := player_level
	player_xp += amount
	var levels_gained := 0
	while player_xp >= _xp_required():
		player_xp -= _xp_required()
		player_level += 1
		skill_points += 1
		gold += 20 + player_level * 5
		reputation += 2
		levels_gained += 1
	if levels_gained > 0:
		audio.play("levelup")
		var newly_unlocked: Array[String] = []
		for item in products:
			var required_level: int = int(item.get("required_level", 1))
			if required_level > previous_level and required_level <= player_level:
				newly_unlocked.append(str(item["name"]))
		last_event = "SUBIU DE NÍVEL! Nível %d: +%d ponto(s) de talento, ouro e reputação." % [player_level, levels_gained]
		if not newly_unlocked.is_empty():
			last_event += "\nNOVAS RECEITAS: " + ", ".join(newly_unlocked)

func _get_daily_quest() -> Dictionary:
	var quests: Array[Dictionary] = [
		{"name": "Atenda 5 clientes hoje", "type": "customers", "target": 5, "gold": 45, "xp": 25},
		{"name": "Fature 100 de ouro hoje", "type": "gold", "target": 100, "gold": 55, "xp": 30},
		{"name": "Fabrique 3 produtos hoje", "type": "craft", "target": 3, "gold": 40, "xp": 35},
		{"name": "Encontre 1 evento raro hoje", "type": "rare", "target": 1, "gold": 65, "xp": 40}
	]
	return quests[posmod(daily_quest_index, quests.size())]

func _progress_daily_quest(kind: String, amount: int) -> void:
	if daily_quest_claimed:
		return
	var quest := _get_daily_quest()
	if str(quest["type"]) == kind:
		daily_quest_progress += amount

func _claim_daily_quest() -> void:
	var quest := _get_daily_quest()
	if daily_quest_claimed or daily_quest_progress < int(quest["target"]):
		return
	daily_quest_claimed = true
	audio.play("coin")
	var gold_reward: int = int(quest["gold"]) + shop_day * 3
	var xp_reward: int = int(quest["xp"]) + shop_day
	gold += gold_reward
	reputation += 3
	_add_xp(xp_reward)
	last_event = "Contrato concluído: %s. Recompensa: %d ouro, %d XP e 3 de reputação." % [quest["name"], gold_reward, xp_reward]
	_save_game()
	_refresh_ui()

func _check_achievements() -> void:
	var definitions: Array[Dictionary] = [
		{"id": "first_sale", "name": "Primeira venda", "condition": customers_served >= 1, "gold": 10, "rep": 1},
		{"id": "regulars_10", "name": "Já pode pedir pelo nome (10 clientes)", "condition": customers_served >= 10, "gold": 25, "rep": 2},
		{"id": "regulars_25", "name": "A clientela conhece a casa (25)", "condition": customers_served >= 25, "gold": 40, "rep": 3},
		{"id": "regulars_50", "name": "Lenda comercial do submundo (50)", "condition": customers_served >= 50, "gold": 75, "rep": 5},
		{"id": "chaos_3", "name": "Caos com recibo (3 eventos raros)", "condition": rare_events_found >= 3, "gold": 35, "rep": 2},
		{"id": "marketing_3", "name": "Propaganda em todo plano astral (nível 3)", "condition": ad_level >= 3, "gold": 30, "rep": 2},
		{"id": "delighted_10", "name": "Coração conquistado (10 clientes encantados)", "condition": happy_customers >= 10, "gold": 40, "rep": 3},
		{"id": "faction_noted", "name": "Diplomacia do balcão (facção Notada)", "condition": _max_faction_tier() >= 1, "gold": 35, "rep": 2},
		{"id": "faction_respected", "name": "Embaixadora infernal (facção Respeitada)", "condition": _max_faction_tier() >= 2, "gold": 60, "rep": 4},
		{"id": "ingredient_buyer", "name": "Fornecedor VIP (10 ingredientes comprados)", "condition": total_ingredients_bought >= 10, "gold": 25, "rep": 1},
		{"id": "premium_artisan", "name": "Mão de Midas (3 produtos premium)", "condition": premium_crafted >= 3, "gold": 45, "rep": 2}
	]
	for achievement in definitions:
		var achievement_id: String = str(achievement["id"])
		if bool(achievement["condition"]) and not unlocked_achievements.has(achievement_id):
			unlocked_achievements.append(achievement_id)
			gold += int(achievement["gold"])
			reputation += int(achievement["rep"])
			last_event = "CONQUISTA DESBLOQUEADA: %s! Recompensa: %d ouro e %d reputação." % [
				achievement["name"], achievement["gold"], achievement["rep"]
			]


func _get_achievement_summary() -> String:
	var names := {
		"first_sale": "Primeira venda",
		"regulars_10": "Já pode pedir pelo nome",
		"regulars_25": "A clientela conhece a casa",
		"regulars_50": "Lenda comercial do submundo",
		"chaos_3": "Caos com recibo",
		"marketing_3": "Propaganda astral",
		"delighted_10": "Coração conquistado",
		"faction_noted": "Diplomacia do balcão",
		"faction_respected": "Embaixadora infernal",
		"ingredient_buyer": "Fornecedor VIP",
		"premium_artisan": "Mão de Midas"
	}
	var lines: Array[String] = ["CONQUISTAS: %d/%d" % [unlocked_achievements.size(), names.size()]]
	for achievement_id in names.keys():
		var marker := "✓" if unlocked_achievements.has(achievement_id) else "○"
		lines.append("%s %s" % [marker, names[achievement_id]])
	return "\n".join(lines)

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