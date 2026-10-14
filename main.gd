extends Control

const SAVE_PATH := "user://succubus_shop_save.cfg"
const Regulars = preload("res://regulars.gd")
const Factions = preload("res://factions.gd")
const Ingredients = preload("res://ingredients.gd")

var gold: int = 80
var reputation: int = 0
var customers_served: int = 0
var affection: int = 0
var fury: int = 0
var demonic_form_active: bool = false
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
var world_speed_options: Array[float] = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
var world_speed_index: int = 1
var world_timer: Timer
var speed_label: Label
var speed_button: Button
var forge_status_label: Label
var craft_jobs: Array[Dictionary] = []
var library_upgrade_level: int = 0
var sanctum_upgrade_level: int = 0
var library_upgrade_button: Button
var sanctum_upgrade_button: Button
var queue_distractions: int = 0
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

const PRODUCT_ICONS := ["🧪", "🦆", "💧", "📦", "✨", "🐟", "🌀", "💎", "📜", "☕", "🗡️", "🔨"]

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
		{"name": "Frasco de Motivação de Segunda-feira", "cost": 70, "price": 195, "stock": 0, "required_level": 12, "ingredients": {"po_lunar": 2, "sal": 1}, "desc": "Efeito dura até o primeiro e-mail."},
		{"name": "Adaga de Charme Duvidoso", "cost": 30, "price": 95, "stock": 0, "required_level": 2, "ingredients": {"pena": 1, "tinta": 1}, "desc": "Brilha quando alguém promete pagar amanhã."},
		{"name": "Martelo de Faísca Dramática", "cost": 45, "price": 140, "stock": 0, "required_level": 4, "ingredients": {"sal": 1, "po_lunar": 1}, "desc": "Cada golpe produz uma faísca e uma opinião não solicitada."
		}
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
var recover_theft_button: Button
var fury_label: Label
var seller_portrait: TextureRect
var reaction_label: Label
var seller_speech_label: Label
var customer_tween: Tween
var happy_customers: int = 0
var disappointed_customers: int = 0
var seduction_attempts: int = 0
var seduction_successes: int = 0
var current_negotiation_dialogue: String = ""
var customer_portrait: TextureRect
var customer_emotion_label: Label
var background_layer: TextureRect
var sector_title_label: Label
var sector_hint_label: Label
var reception_button: Button
var forge_button: Button
var library_button: Button
var sanctum_button: Button
var current_sector: String = "reception"
var current_customer_budget: int = 0
var current_customer_patience: int = 0
var stolen_item_name: String = ""
var theft_recovery_available: bool = false
var seduction_peak_triggered: bool = false
var ambient_particles: CPUParticles2D
var music_player: AudioStreamPlayer
var feedback_audio_player: AudioStreamPlayer
var toast_label: Label
var toast_tween: Tween
var market_panel: VBoxContainer
var market_toggle_button: Button
var sensual_tween: Tween
var customer_portrait_paths: Array[String] = ["res://assets/customer_adventurer.png", "res://assets/customer_mage.png", "res://assets/customer_goth.png"]
var seller_portrait_paths: Dictionary = {"happy": "res://assets/seller_happy.png", "neutral": "res://assets/seller_neutral.png", "surprised": "res://assets/seller_surprised.png", "demonic": "res://assets/seller_demonic.png"}

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
const SUCCUBUS_NEGOTIATION_LINES := [
	"A succubus inclina o rosto: “Você pode pagar depois... mas vai ter que voltar para me agradecer.”",
	"Ela apoia o cotovelo no balcão: “Para um aventureiro tão interessante, eu sempre encontro um desconto.”",
	"A chefe pisca: “Não é magia. É só você querendo muito me impressionar.”",
	"Ela desliza o item pelo balcão: “Leve. O preço é pequeno perto da história que você vai contar.”"
]

func _ready() -> void:
	_load_game()
	_build_ui()
	_setup_feedback_audio()
	_setup_background_music()
	_refresh_ui()
	_start_ambient_animations()
	var timer := Timer.new()
	world_timer = timer
	timer.wait_time = 3.0 / world_speed()
	timer.autostart = true
	timer.timeout.connect(_on_customer_tick)
	add_child(timer)

func world_speed() -> float:
	return world_speed_options[clampi(world_speed_index, 0, world_speed_options.size() - 1)]

func _cycle_world_speed() -> void:
	world_speed_index = (world_speed_index + 1) % world_speed_options.size()
	if is_instance_valid(world_timer):
		world_timer.wait_time = 3.0 / world_speed()
	last_event = "Velocidade do mundo ajustada para %.1fx. A forja e a paciência dos clientes acompanham o ritmo." % world_speed()
	_play_feedback_tone(520.0 + world_speed() * 60.0, 0.08, 0.1)
	_save_game()
	_refresh_ui()

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
	background_layer = bg
	var opening_scene := "res://assets/reception_scene_flirty.png" if adult_content_enabled and randi() % 100 < 28 else "res://assets/reception_scene.png"
	if not ResourceLoader.exists(opening_scene):
		opening_scene = "res://assets/shop_scene.png"
	bg.texture = load(opening_scene)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	ambient_particles = CPUParticles2D.new()
	ambient_particles.amount = 32
	ambient_particles.lifetime = 3.2
	ambient_particles.position = Vector2(600, 360)
	ambient_particles.direction = Vector2(0, -1)
	ambient_particles.spread = 120.0
	ambient_particles.gravity = Vector2(0, -10)
	ambient_particles.initial_velocity_min = 8.0
	ambient_particles.initial_velocity_max = 22.0
	ambient_particles.scale_amount_min = 0.35
	ambient_particles.scale_amount_max = 0.8
	ambient_particles.color = Color(0.85, 0.35, 1.0, 0.34)
	ambient_particles.emitting = true
	ambient_particles.z_index = 1
	add_child(ambient_particles)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.clip_contents = true
	margin.theme = _build_visual_theme()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.clip_contents = true
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := FlowContainer.new()
	header.add_theme_constant_override("h_separation", 8)
	header.add_theme_constant_override("v_separation", 6)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	var title := Label.new()
	title.text = "SUCCUBUS SHOP"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.67, 0.88))
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "  •  Loja mágica, negócios duvidosos"
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color(0.80, 0.75, 0.88))
	subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(subtitle)

	market_toggle_button = Button.new()
	market_toggle_button.text = "☰ Abrir mercado"
	market_toggle_button.custom_minimum_size = Vector2(160, 42)
	market_toggle_button.pressed.connect(_toggle_market_panel)
	header.add_child(market_toggle_button)

	reception_button = Button.new()
	reception_button.text = "Recepção"
	reception_button.custom_minimum_size = Vector2(115, 42)
	reception_button.pressed.connect(_set_sector.bind("reception"))
	header.add_child(reception_button)

	forge_button = Button.new()
	forge_button.text = "⚒ Forja"
	forge_button.custom_minimum_size = Vector2(115, 42)
	forge_button.pressed.connect(_set_sector.bind("forge"))
	header.add_child(forge_button)

	library_button = Button.new()
	library_button.text = "📚 Biblioteca"
	library_button.custom_minimum_size = Vector2(135, 42)
	library_button.pressed.connect(_set_sector.bind("library"))
	header.add_child(library_button)

	sanctum_button = Button.new()
	sanctum_button.text = "✦ Santuário"
	sanctum_button.custom_minimum_size = Vector2(130, 42)
	sanctum_button.pressed.connect(_set_sector.bind("sanctum"))
	header.add_child(sanctum_button)

	var stats := FlowContainer.new()
	stats.add_theme_constant_override("h_separation", 24)
	stats.add_theme_constant_override("v_separation", 8)
	root.add_child(stats)

	gold_label = _make_stat_label("Ouro: 0")
	stats.add_child(gold_label)
	rep_label = _make_stat_label("Reputação: 0")
	stats.add_child(rep_label)
	customers_label = _make_stat_label("Clientes: 0")
	stats.add_child(customers_label)
	affection_label = _make_stat_label("Afinidade: 0/100")
	stats.add_child(affection_label)
	fury_label = _make_stat_label("Fúria: 0/5")
	fury_label.add_theme_font_size_override("font_size", 18)
	fury_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	stats.add_child(fury_label)

	var speed_row := FlowContainer.new()
	speed_row.add_theme_constant_override("h_separation", 10)
	speed_row.add_theme_constant_override("v_separation", 6)
	root.add_child(speed_row)
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 15)
	speed_label.add_theme_color_override("font_color", Color(0.78, 0.95, 1.0))
	speed_row.add_child(speed_label)
	speed_button = Button.new()
	speed_button.custom_minimum_size = Vector2(150, 34)
	speed_button.pressed.connect(_cycle_world_speed)
	speed_row.add_child(speed_button)
	forge_status_label = Label.new()
	forge_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	forge_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forge_status_label.add_theme_font_size_override("font_size", 14)
	forge_status_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.48))
	speed_row.add_child(forge_status_label)

	progression_label = Label.new()
	progression_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progression_label.add_theme_font_size_override("font_size", 16)
	progression_label.add_theme_color_override("font_color", Color(0.78, 0.95, 1.0))
	root.add_child(progression_label)

	talent_label = Label.new()
	talent_label.add_theme_font_size_override("font_size", 14)
	talent_label.add_theme_color_override("font_color", Color(0.88, 0.83, 1.0))
	root.add_child(talent_label)

	var talent_row := FlowContainer.new()
	talent_row.add_theme_constant_override("h_separation", 8)
	talent_row.add_theme_constant_override("v_separation", 6)
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
	body.clip_contents = true
	body.add_theme_constant_override("separation", 22)
	root.add_child(body)
	get_viewport().size_changed.connect(_update_body_orientation.bind(body))

	var left := VBoxContainer.new()
	market_panel = left
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.6
	left.add_theme_constant_override("separation", 8)
	left.visible = false
	body.add_child(left)

	var product_title := Label.new()
	sector_title_label = product_title
	product_title.text = "MERCADORIAS"
	product_title.add_theme_font_size_override("font_size", 22)
	product_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	left.add_child(product_title)

	var hint := Label.new()
	sector_hint_label = hint
	hint.text = "Fabrique itens para abastecer a loja. Os clientes chegam automaticamente."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.71, 0.81))
	left.add_child(hint)

	var product_scroll := ScrollContainer.new()
	product_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	product_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(product_scroll)

	library_upgrade_button = Button.new()
	library_upgrade_button.custom_minimum_size = Vector2(220, 36)
	library_upgrade_button.pressed.connect(_buy_sector_upgrade.bind("library"))
	left.add_child(library_upgrade_button)
	sanctum_upgrade_button = Button.new()
	sanctum_upgrade_button.custom_minimum_size = Vector2(220, 36)
	sanctum_upgrade_button.pressed.connect(_buy_sector_upgrade.bind("sanctum"))
	left.add_child(sanctum_upgrade_button)

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
	right_scroll.custom_minimum_size.x = 360
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.clip_contents = true
	body.add_child(right_scroll)

	var right_panel := PanelContainer.new()
	right_panel.clip_contents = true
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
	shop_title.text = "RECEPÇÃO • A CHEFE"
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
	seller_portrait.custom_minimum_size = Vector2(148, 176)
	seller_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seller_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
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
	customer_portrait.custom_minimum_size = Vector2(148, 176)
	customer_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	customer_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	customer_portrait.texture = load(customer_portrait_paths[0])
	customer_frame.add_child(customer_portrait)

	customer_emotion_label = Label.new()
	customer_emotion_label.text = "🙂 aguardando"
	customer_emotion_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	customer_emotion_label.add_theme_font_size_override("font_size", 12)
	customer_emotion_label.add_theme_color_override("font_color", Color(0.70, 0.90, 1.0))
	right.add_child(customer_emotion_label)

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

	toast_label = Label.new()
	toast_label.custom_minimum_size = Vector2(280, 30)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 15)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	toast_label.modulate.a = 0.0
	right.add_child(toast_label)

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

	recover_theft_button = Button.new()
	recover_theft_button.custom_minimum_size.y = 42
	recover_theft_button.text = "Rastrear item roubado"
	recover_theft_button.pressed.connect(_recover_stolen_item)
	right.add_child(recover_theft_button)

	var footer := Label.new()
	footer.text = "Protótipo 0.6 • Facções, fregueses e contratos • Conteúdo sensual opcional"
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", Color(0.62, 0.57, 0.68))
	root.add_child(footer)
	_update_body_orientation(body)

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

func _update_body_orientation(body: BoxContainer) -> void:
	if not is_instance_valid(body):
		return
	# Keep the illustrated shop beside the market on wide screens,
	# and stack them on narrow windows such as small desktop displays.
	body.vertical = get_viewport_rect().size.x < 900.0

func _toggle_market_panel() -> void:
	if not is_instance_valid(market_panel):
		return
	market_panel.visible = not market_panel.visible
	if is_instance_valid(market_toggle_button):
		market_toggle_button.text = "☰ Ocultar mercado" if market_panel.visible else "☰ Abrir mercado"
	_play_feedback_tone(520.0 if market_panel.visible else 360.0, 0.08, 0.1)
	_show_feedback("Mercado expandido." if market_panel.visible else "Recepção em foco.", Color(0.78, 0.95, 1.0))

func _buy_sector_upgrade(sector: String) -> void:
	var current_level := library_upgrade_level if sector == "library" else sanctum_upgrade_level
	var cost := 90 + current_level * 120
	if current_level >= 5:
		last_event = "Este setor já alcançou o nível máximo. Até a arquitetura pediu férias."
		_refresh_ui()
		return
	if gold < cost:
		last_event = "O upgrade custa %d ouro. A succubus sugere um sorriso, mas o ferreiro exige moedas." % cost
		_refresh_ui()
		return
	gold -= cost
	if sector == "library":
		library_upgrade_level += 1
		last_event = "Biblioteca Arcana melhorada para o nível %d: grimórios aceleram XP e eventos raros." % library_upgrade_level
	else:
		sanctum_upgrade_level += 1
		last_event = "Santuário melhorado para o nível %d: relíquias amplificam o charme da succubus." % sanctum_upgrade_level
	reputation += 1
	_add_xp(8)
	_check_achievements()
	_save_game()
	_refresh_ui()

func _set_sector(sector: String) -> void:
	current_sector = sector
	var is_forge := sector == "forge"
	var is_reception := sector == "reception"
	var is_library := sector == "library"
	var is_sanctum := sector == "sanctum"
	if is_instance_valid(background_layer):
		var scene_path := "res://assets/reception_scene.png"
		if is_forge and ResourceLoader.exists("res://assets/forge_close_scene.png"):
			scene_path = "res://assets/forge_close_scene.png"
		elif is_library and ResourceLoader.exists("res://assets/library_close_scene.png"):
			scene_path = "res://assets/library_close_scene.png"
		elif is_sanctum and ResourceLoader.exists("res://assets/sanctum_close_scene.png"):
			scene_path = "res://assets/sanctum_close_scene.png"
		elif ResourceLoader.exists("res://assets/reception_scene.png"):
			scene_path = "res://assets/reception_scene.png"
		elif ResourceLoader.exists("res://assets/shop_scene.png"):
			scene_path = "res://assets/shop_scene.png"
		background_layer.texture = load(scene_path)
	if is_instance_valid(ambient_particles):
		ambient_particles.color = Color(1.0, 0.43, 0.16, 0.46) if is_forge else Color(0.36, 0.72, 1.0, 0.38) if is_library else Color(0.73, 0.30, 1.0, 0.42) if is_sanctum else Color(0.85, 0.35, 1.0, 0.34)
	if is_instance_valid(market_panel):
		market_panel.visible = not is_reception
	if is_instance_valid(sector_title_label):
		sector_title_label.text = "FORJA & OFICINA" if is_forge else "BIBLIOTECA ARCANA" if is_library else "SANTUÁRIO DE ARTEFATOS" if is_sanctum else "MERCADORIAS"
	if is_instance_valid(sector_hint_label):
		sector_hint_label.text = "O ferreiro transforma ingredientes e ouro em equipamentos. A fila avança com o tempo do mundo." if is_forge else "Consulte grimórios e descubra receitas ocultas." if is_library else "Relíquias carregadas de magia aguardam uma negociação cuidadosa." if is_sanctum else "Fabrique itens para abastecer a loja. Os clientes chegam automaticamente."
	if is_instance_valid(market_toggle_button):
		market_toggle_button.text = "☰ Ocultar painel" if not is_reception else "☰ Abrir mercado"
	if is_instance_valid(reception_button):
		reception_button.disabled = is_reception
	if is_instance_valid(forge_button):
		forge_button.disabled = is_forge
	if is_instance_valid(library_button):
		library_button.disabled = is_library
	if is_instance_valid(sanctum_button):
		sanctum_button.disabled = is_sanctum
	var sector_message := "A forja está em atividade." if is_forge else "Os grimórios sussurram novas receitas." if is_library else "O santuário pulsa com artefatos inquietos." if is_sanctum else "A recepção voltou ao foco."
	_show_feedback(sector_message, Color(1.0, 0.82, 0.48) if is_forge else Color(0.70, 0.90, 1.0) if is_library else Color(0.86, 0.60, 1.0) if is_sanctum else Color(1.0, 0.78, 0.9))

func _play_sensual_reception_moment() -> void:
	if not adult_content_enabled or not is_instance_valid(seller_portrait):
		return
	if sensual_tween != null and sensual_tween.is_valid():
		sensual_tween.kill()
	seller_portrait.pivot_offset = seller_portrait.size / 2.0
	sensual_tween = create_tween()
	sensual_tween.tween_property(seller_portrait, "scale", Vector2(1.07, 1.07), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sensual_tween.tween_property(seller_portrait, "modulate", Color(1.0, 0.82, 0.95, 1.0), 0.32)
	sensual_tween.tween_interval(1.6)
	sensual_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sensual_tween.tween_property(seller_portrait, "modulate", Color.WHITE, 0.42)

func _play_seduction_peak_pose() -> void:
	if not adult_content_enabled or not is_instance_valid(seller_portrait):
		return
	if sensual_tween != null and sensual_tween.is_valid():
		sensual_tween.kill()
	seller_portrait.pivot_offset = seller_portrait.size / 2.0
	sensual_tween = create_tween()
	sensual_tween.tween_property(seller_portrait, "position", Vector2(0, -12), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sensual_tween.tween_property(seller_portrait, "rotation", -0.045, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sensual_tween.tween_property(seller_portrait, "scale", Vector2(1.12, 1.12), 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sensual_tween.tween_property(seller_portrait, "modulate", Color(1.0, 0.70, 0.90, 1.0), 0.25)
	sensual_tween.tween_interval(1.1)
	sensual_tween.tween_property(seller_portrait, "rotation", 0.045, 0.18)
	sensual_tween.tween_property(seller_portrait, "position", Vector2(0, 4), 0.24)
	sensual_tween.tween_property(seller_portrait, "scale", Vector2(1.04, 1.04), 0.22)
	sensual_tween.tween_property(seller_portrait, "modulate", Color.WHITE, 0.28)
	sensual_tween.tween_property(seller_portrait, "rotation", 0.0, 0.12)
	sensual_tween.tween_property(seller_portrait, "position", Vector2.ZERO, 0.18)
	sensual_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.24)
	last_event = "MEDIDOR DE SEDUÇÃO CHEIO! A chefe sobe no balcão por um instante: “Agora você entende por que ninguém sai daqui pensando direito.”"
	private_moments_unlocked += 1
	reputation += 3
	_add_xp(15)
	_play_feedback_tone(1040.0, 0.26, 0.22)
	_show_feedback("♥ Pose especial desbloqueada!", Color(1.0, 0.62, 0.88))

func _setup_feedback_audio() -> void:
	feedback_audio_player = AudioStreamPlayer.new()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.25
	feedback_audio_player.stream = generator
	feedback_audio_player.volume_db = -8.0
	add_child(feedback_audio_player)

func _setup_background_music() -> void:
	var music_path := "res://assets/shop_theme_loop.mp3"
	if not ResourceLoader.exists(music_path):
		return
	music_player = AudioStreamPlayer.new()
	var music_stream := load(music_path) as AudioStreamMP3
	if music_stream == null:
		return
	music_stream.loop = true
	music_player.stream = music_stream
	music_player.volume_db = -13.0
	add_child(music_player)
	music_player.play()

func _play_feedback_tone(frequency: float, duration: float = 0.12, volume: float = 0.16) -> void:
	if not is_instance_valid(feedback_audio_player):
		return
	feedback_audio_player.play()
	var playback := feedback_audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var stream := feedback_audio_player.stream as AudioStreamGenerator
	var frame_count := int(stream.mix_rate * duration)
	for frame in range(frame_count):
		var progress := float(frame) / float(maxi(1, frame_count))
		var envelope := minf(1.0, minf(progress / 0.08, (1.0 - progress) / 0.18))
		var sample := sin(TAU * frequency * float(frame) / stream.mix_rate) * volume * envelope
		playback.push_frame(Vector2(sample, sample))

func _show_feedback(message: String, color: Color = Color(1.0, 0.78, 0.9)) -> void:
	if not is_instance_valid(toast_label):
		return
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", color)
	toast_label.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(1.4)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.8)

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
	if craft_jobs.size() >= 3:
		last_event = "A fila da forja está cheia. O ferreiro pediu espaço para respirar e reclamar do carvão."
		_refresh_ui()
		return
	gold -= cost
	_consume_ingredients(item)
	var duration := 6.0 + float(index) * 1.4 - float(alchemy_rank) * 0.7 - float(library_upgrade_level) * 0.45
	craft_jobs.append({"index": index, "remaining": maxf(3.0, duration)})
	last_event = "Forja iniciada: %s levará %.1fs de tempo de mundo." % [item["name"], maxf(3.0, duration)]
	_play_feedback_tone(420.0, 0.12, 0.14)
	_show_feedback("⚒ Fabricação em andamento.", Color(1.0, 0.82, 0.48))
	_save_game()
	_refresh_ui()

func _advance_craft_jobs(game_seconds: float) -> void:
	if craft_jobs.is_empty():
		return
	var completed: Array[Dictionary] = []
	for job in craft_jobs:
		job["remaining"] = float(job.get("remaining", 0.0)) - game_seconds
		if float(job["remaining"]) <= 0.0:
			completed.append(job)
	for job in completed:
		craft_jobs.erase(job)
		var index := int(job.get("index", 0))
		var item: Dictionary = products[index]
		item["stock"] = int(item["stock"]) + 1
		daily_crafts += 1
		_add_xp(5)
		_progress_daily_quest("craft", 1)
		var premium_chance := 8 + 4 * alchemy_rank
		if randi() % 100 < premium_chance:
			var product_name := str(item["name"])
			premium_stock[product_name] = int(premium_stock.get(product_name, 0)) + 1
			premium_crafted += 1
			last_event = "OBRA-PRIMA! %s saiu impecável e vale 50%% a mais. A chefe finge que foi de propósito." % product_name
			_play_feedback_tone(880.0, 0.16, 0.18)
			_show_feedback("✦ Obra-prima criada!", Color(1.0, 0.86, 0.45))
		else:
			last_event = "Produzido: %s. O ferreiro bateu o martelo e pediu aplausos." % item["name"]
			_play_feedback_tone(560.0)
			_show_feedback("Produto pronto para vender.")
	_check_achievements()
	_save_game()

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
	last_event = "Comprado: %s por %d ouro. O fornecedor jurou que era o preço de amigo." % [str(Ingredients.find(ingredient_id).get("name", ingredient_id)), price]
	_play_feedback_tone(420.0)
	_show_feedback("Ingrediente adicionado ao estoque.", Color(0.78, 0.95, 1.0))
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
	last_event = "Contratado! O diabrete produz uma Poção de Dano Emocional a cada 9 segundos."
	_save_game()
	_refresh_ui()

func _on_customer_tick() -> void:
	ticks += 1
	_advance_craft_jobs(3.0)
	_set_seller_mood("demonic" if demonic_form_active else "neutral")
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
	if randi() % 100 < 7 + library_upgrade_level * 2:
		_trigger_random_event()
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
			{"name": "Speedrunner", "favorite": 3, "line": "“Compra feita. Onde fica o botão de pular diálogo?”", "faction": "aventureiros", "portrait": 0, "budget": 75, "patience": 1},
			{"name": "Especialista em Tudo", "favorite": 0, "line": "“Vi um tutorial de 12 segundos e agora sou consultor.”", "faction": "guildas", "portrait": 1, "budget": 48, "patience": 2},
				{"name": "Gótico Econômico", "favorite": 2, "line": "“Minhas lágrimas são artesanais. As suas têm desconto?”", "faction": "submundo", "portrait": 2, "budget": 90, "patience": 3},
				{"name": "Mago do Quero Mana", "favorite": 9, "line": "“Quero manaaa! Isso aqui é uma porcaria... me vê duas poções mesmo assim.”", "faction": "guildas", "portrait": 1, "budget": 120, "patience": 2},
				{"name": "Fiscal do Pix Astral", "favorite": 6, "line": "“Aceita Pix astral? Se não aceitar, vou pagar em promessa e reclamar no fórum.”", "faction": "mercadores", "portrait": 0, "budget": 115, "patience": 2},
				{"name": "Só Mais Uma Run", "favorite": 3, "line": "“É rapidinho, só mais uma compra. Dessa vez eu paro antes do amanhecer.”", "faction": "aventureiros", "portrait": 2, "budget": 100, "patience": 1},
				{"name": "Ladino do Ctrl+C", "favorite": 0, "line": "“Vi isso em outro lugar. Vou levar o seu, porque parece mais fácil.”", "faction": "submundo", "portrait": 2, "budget": 70, "patience": 2, "thief": true},
				{"name": "Cliente do É Sobre Isso", "favorite": 4, "line": "“É sobre isso e está tudo bem. Mas se tiver desconto, fica ainda mais sobre isso.”", "faction": "nobres", "portrait": 1, "budget": 150, "patience": 3},
				{"name": "Colecionador de Patos", "favorite": 1, "line": "“Este pato combina com os outros 47 que não me julgam.”", "faction": "mercadores", "portrait": 0, "budget": 42, "patience": 2},
				{"name": "Coach Interdimensional", "favorite": 4, "line": "“Acredite no seu potencial! Meu boleto acredita em mim.”", "faction": "guildas", "portrait": 1, "budget": 125, "patience": 3},
				{"name": "Cliente Misterioso", "favorite": -1, "line": "“Não nos conhecemos. Se nos conhecemos, não se lembra.”", "faction": "nobres", "portrait": 2, "budget": 60, "patience": 1},
				{"name": "Bardo do Duplo Sentido", "favorite": 4, "line": "“Se essa poção for tão quente quanto seu sorriso, eu compro duas.”", "faction": "aventureiros", "portrait": 1, "budget": 110, "patience": 2},
				{"name": "Paladina do Caos", "favorite": 10, "line": "“Prometi ser virtuosa hoje. Mas posso abrir uma exceção para você.”", "faction": "nobres", "portrait": 0, "budget": 145, "patience": 2},
				{"name": "Ladrão de Relíquias Sensíveis", "favorite": 8, "line": "“Não estou roubando seu coração. Só testando se ele cabe no meu inventário.”", "faction": "submundo", "portrait": 2, "budget": 135, "patience": 1},
				{"name": "Bruxa em Lua de Mel", "favorite": 6, "line": "“Meu familiar disse que você é perigosa. Por isso mesmo fiquei.”", "faction": "guildas", "portrait": 1, "budget": 180, "patience": 3}
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
		current_customer_budget = int(profile.get("budget", 50)) + trade_rank * 8
		current_customer_patience = maxi(1, int(round(float(int(profile.get("patience", 2)) + logistics_rank) / world_speed())))
		var seduction_used := false
		if is_instance_valid(customer_emotion_label):
			customer_emotion_label.text = "🏃 pressa" if current_customer_patience <= 1 else "🙂 observando"
		if bool(profile.get("thief", false)) and current_customer_patience <= 1:
			_handle_thief_escape(profile, available)
			_check_achievements()
			_save_game()
			_refresh_ui()
			return
		var affordable: Array[int] = []
		for affordable_index in available:
			if int(products[affordable_index]["price"]) <= current_customer_budget:
				affordable.append(affordable_index)
		if affordable.is_empty():
			var charm_negotiation := adult_content_enabled and charm_rank > 0 and randi() % 100 < 25 + charm_rank * 12 + sanctum_upgrade_level * 5
			if charm_negotiation and available.size() > 0:
				seduction_used = true
				seduction_attempts += 1
				seduction_successes += 1
				current_customer_budget += 20 + charm_rank * 10
				affection = mini(100, affection + 2 + charm_rank)
				reputation += 1 + _reputation_seduction_bonus()
				last_event = "%s suspira: “Meu orçamento é curto...” %s O cliente reconsidera." % [profile["name"], SUCCUBUS_NEGOTIATION_LINES.pick_random()]
				for affordable_index in available:
					if int(products[affordable_index]["price"]) <= current_customer_budget:
						affordable.append(affordable_index)
			else:
				last_event = "%s não conseguiu pagar nenhum item e saiu %s: “Volto quando meu bolso parar de chorar.”" % [profile["name"], "com pressa" if current_customer_patience <= 1 else "frustrado"]
				disappointed_customers += 1
				reputation = maxi(0, reputation - 1)
				status_label.text = "CLIENTE: saiu sem comprar"
				if is_instance_valid(customer_emotion_label):
					customer_emotion_label.text = "😤 frustração"
				_play_customer_reaction("disappointed")
				_check_achievements()
				_save_game()
				_refresh_ui()
				return
		var chosen_index: int = affordable[randi() % affordable.size()] if not affordable.is_empty() else available[randi() % available.size()]
		if preferred_index >= 0 and available.has(preferred_index) and randi() % 100 < 70:
			chosen_index = preferred_index
			if not seduction_used and adult_content_enabled and charm_rank > 0 and randi() % 100 < 8 + charm_rank * 5 + sanctum_upgrade_level * 3 and (preferred_index == chosen_index or current_customer_patience <= 1):
				seduction_used = true
				seduction_attempts += 1
				seduction_successes += 1
				affection = mini(100, affection + 1 + charm_rank + sanctum_upgrade_level)
				reputation += _reputation_seduction_bonus()

		var item: Dictionary = products[chosen_index]
		item["stock"] = int(item["stock"]) - 1
		var price_multiplier: float = (1.0 + 0.20 * ad_level) * (1.0 + 0.08 * trade_rank) * _reputation_price_multiplier()
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
			reputation += 1 + (1 if seduction_used else 0)
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
		affection = mini(100, affection + 1 + charm_rank + sanctum_upgrade_level)
		status_label.text = "CLIENTE: %s" % profile["name"]
		_set_seller_mood("happy")
		_react_to_visit("delighted" if preferred_index == chosen_index else "content", seduction_used)
		_set_negotiation_dialogue(profile, item, seduction_used, preferred_index == chosen_index)

	if adult_content_enabled and affection >= 10 and affection % 10 == 0:
		last_event = "A súcubo se aproxima com um sorriso cúmplice: “Você está conquistando minha confiança… e isso pode render recompensas bem interessantes.”"
		_play_sensual_reception_moment()
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
			},
			{
				"name": "Fila Encantada",
				"message": "A succubus se apoia no balcão e sussurra um elogio indecente. Os aventureiros esquecem por alguns segundos que estavam com pressa.",
				"gold": 12, "reputation": 2, "queue_distraction": true
			},
			{
				"name": "Negociação com Olhar Demorado",
				"message": "Ela promete um desconto para quem conseguir manter a compostura. Ninguém consegue, mas todos permanecem na fila.",
				"gold": 18, "reputation": 3, "queue_distraction": true
			}
	]
	var event: Dictionary = events[randi() % events.size()]
	gold = maxi(0, gold + int(event["gold"]))
	reputation = maxi(0, reputation + int(event["reputation"]))
	rare_events_found += 1
	last_event = "EVENTO: %s! %s" % [event["name"], event["message"]]
	if bool(event.get("queue_distraction", false)):
		queue_distractions += 1
		current_customer_patience += 1 + sanctum_upgrade_level
		seduction_attempts += 1
		seduction_successes += 1
		affection = mini(100, affection + 2 + sanctum_upgrade_level)
		if is_instance_valid(customer_emotion_label):
			customer_emotion_label.text = "💘 distraído"
		status_label.text = "CLIENTE: distraído pelo charme"
		_play_sensual_reception_moment()
	_play_feedback_tone(280.0, 0.2, 0.18)
	_show_feedback("Evento raro!", Color(1.0, 0.86, 0.45))
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
	customer_portrait.position = Vector2(-18, 4)
	tween.tween_property(customer_portrait, "position", Vector2.ZERO, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(customer_portrait, "modulate:a", 1.0, 0.24).from(0.0)
	tween.tween_property(customer_portrait, "scale", Vector2.ONE, 0.28).from(Vector2(0.78, 0.78))

func _reputation_title() -> String:
	if reputation >= 60:
		return "Lenda do Submundo"
	if reputation >= 35:
		return "Nome Quente"
	if reputation >= 15:
		return "Loja Promissora"
	if reputation >= 5:
		return "Boa Fama"
	return "Desconhecida"

func _reputation_seduction_bonus() -> int:
	return 1 if reputation >= 15 else 0

func _reputation_price_multiplier() -> float:
	return 1.0 + minf(0.12, float(maxi(0, reputation)) * 0.002)

func _handle_thief_escape(profile: Dictionary, available: Array[int]) -> void:
	if available.is_empty():
		return
	var stolen_index := available[randi() % available.size()]
	var stolen_item: Dictionary = products[stolen_index]
	stolen_item["stock"] = maxi(0, int(stolen_item["stock"]) - 1)
	stolen_item_name = str(stolen_item["name"])
	theft_recovery_available = true
	fury = mini(5, fury + 2)
	_update_demonic_form()
	status_label.text = "CLIENTE: ladrão escapou"
	if is_instance_valid(customer_emotion_label):
		customer_emotion_label.text = "🏃 ladrão"
	last_event = "%s pegou %s e correu! A succubus rosna: “Ninguém rouba da minha loja e sai sem deixar um recibo.”" % [profile.get("name", "O cliente"), stolen_item_name]
	_show_feedback("⚠ Roubo! O rastreador está pronto.", Color(1.0, 0.55, 0.45))
	_play_feedback_tone(150.0, 0.2, 0.18)
	_play_customer_reaction("hurry")

func _recover_stolen_item() -> void:
	if not theft_recovery_available or stolen_item_name.is_empty():
		last_event = "Nenhum item foi roubado. A succubus guarda o rastreador e finge que foi tudo planejado."
		_refresh_ui()
		return
	for item in products:
		if str(item.get("name", "")) == stolen_item_name:
			item["stock"] = int(item.get("stock", 0)) + 1
			break
	theft_recovery_available = false
	last_event = "Rastreamento concluído: %s recuperado. O ladrão deixou um pedido de desculpas e uma gorjeta simbólica." % stolen_item_name
	stolen_item_name = ""
	fury = maxi(0, fury - 1)
	_update_demonic_form()
	_play_feedback_tone(680.0, 0.14, 0.16)
	_show_feedback("Item recuperado.", Color(0.75, 1.0, 0.72))
	_save_game()
	_refresh_ui()

func _set_negotiation_dialogue(profile: Dictionary, item: Dictionary, seduction_used: bool, favorite_item: bool) -> void:
	if not is_instance_valid(seller_speech_label):
		return
	var customer_name := str(profile.get("name", "Aventureiro"))
	var customer_line := "“Isso parece exatamente o que eu precisava.”" if favorite_item else "“Não era meu primeiro plano, mas parece útil.”"
	if current_customer_patience <= 1:
		customer_line = "“Rápido, por favor. Tenho um dragão me esperando.”"
	if seduction_used:
		seller_speech_label.text = "CHEFE: %s\n%s: %s" % [SUCCUBUS_NEGOTIATION_LINES.pick_random(), customer_name, customer_line]
	else:
		seller_speech_label.text = "CHEFE: “%s por %d ouro. Quer levar?”\n%s: %s" % [str(item.get("name", "isto")), int(item.get("price", 0)), customer_name, customer_line]

func _react_to_visit(mood: String, charm_save: bool = false) -> void:
	var text := ""
	var color := Color(0.91, 1.0, 0.75)
	var line := ""
	var animation := mood
	match mood:
		"delighted":
			happy_customers += 1
			reputation += 1
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
				_set_seller_mood("happy")
			else:
				disappointed_customers += 1
				reputation = maxi(0, reputation - 1)
				fury = mini(5, fury + 1)
				_update_demonic_form()
				text = "… Cliente decepcionado. -1 de reputação"
				color = Color(1.0, 0.55, 0.55)
				line = SELLER_DISAPPOINTED_LINES.pick_random()
				_set_seller_mood("surprised")
	if is_instance_valid(customer_emotion_label):
		var emotion_text := "🙂 satisfeito"
		if animation == "delighted":
			emotion_text = "😍 amor e empolgação" if charm_save else "😄 felicidade"
		elif animation == "disappointed":
			emotion_text = "🏃 pressa" if current_customer_patience <= 1 else "😤 raiva/frustração"
		elif mood == "content":
			emotion_text = "😌 calma"
		customer_emotion_label.text = emotion_text
	if is_instance_valid(reaction_label):
		reaction_label.text = text
		reaction_label.add_theme_color_override("font_color", color)
	if is_instance_valid(seller_speech_label):
		seller_speech_label.text = line
	match animation:
		"delighted":
			_play_feedback_tone(880.0, 0.14, 0.17)
			_show_feedback("♥ Cliente encantado!", Color(1.0, 0.78, 0.9))
		"disappointed":
			_play_feedback_tone(180.0, 0.18, 0.14)
			_show_feedback("Estoque vazio: cliente perdido.", Color(1.0, 0.55, 0.55))
		_:
			_play_feedback_tone(660.0, 0.1, 0.13)
			_show_feedback("Venda concluída.", Color(0.91, 1.0, 0.75))
	_play_customer_reaction("hurry" if animation == "disappointed" and current_customer_patience <= 1 else animation)
	if animation != "disappointed" and not theft_recovery_available:
		fury = maxi(0, fury - 1)
		_update_demonic_form()
	if adult_content_enabled and affection >= 100 and not seduction_peak_triggered:
		seduction_peak_triggered = true
		_play_seduction_peak_pose()

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
		"hurry":
			tween.tween_property(customer_portrait, "modulate", Color(1.0, 0.78, 0.60, 1.0), 0.14)
			for i in range(3):
				tween.tween_property(customer_portrait, "position", Vector2(-8, 0), 0.06)
				tween.tween_property(customer_portrait, "position", Vector2(8, 0), 0.06)
				tween.tween_property(customer_portrait, "position", Vector2.ZERO, 0.06)
			tween.tween_property(customer_portrait, "modulate:a", 0.35, 0.55)
		_:
			tween.tween_property(customer_portrait, "modulate:a", 0.45, 0.9)

func _set_seller_mood(mood: String) -> void:
	if is_instance_valid(seller_portrait) and seller_portrait_paths.has(mood):
		var mood_path := str(seller_portrait_paths[mood])
		if ResourceLoader.exists(mood_path):
			seller_portrait.texture = load(mood_path)

func _update_demonic_form() -> void:
	if adult_content_enabled and fury >= 4 and not demonic_form_active:
		demonic_form_active = true
		_set_seller_mood("demonic")
		last_event = "A FÚRIA CHEGOU AO LIMITE! A succubus assume sua forma demoníaca: “Respirem. Eu ainda sei negociar.”"
		if is_instance_valid(seller_portrait):
			seller_portrait.modulate = Color(1.0, 0.55, 0.62, 1.0)
			var demon_tween := create_tween()
			demon_tween.tween_property(seller_portrait, "scale", Vector2(1.10, 1.10), 0.22).set_trans(Tween.TRANS_BACK)
			demon_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.34)
		_play_feedback_tone(120.0, 0.25, 0.2)
		_show_feedback("Forma demoníaca ativada.", Color(1.0, 0.48, 0.58))
	elif demonic_form_active and fury <= 1:
		demonic_form_active = false
		_set_seller_mood("neutral")
		last_event = "A succubus respira fundo e retorna à forma habitual. A loja sobreviveu ao drama."

func _refresh_ui() -> void:
	if not is_instance_valid(gold_label):
		return
	gold_label.text = "Ouro: %d" % gold
	rep_label.text = "Reputação: %d • %s (+%d%%)" % [reputation, _reputation_title(), int(round((_reputation_price_multiplier() - 1.0) * 100.0))]
	customers_label.text = "Clientes: %d  ♥%d  ✗%d" % [customers_served, happy_customers, disappointed_customers]
	affection_label.text = "Afinidade: %d/100 • Seduções: %d/%d" % [affection, seduction_successes, seduction_attempts]
	if is_instance_valid(fury_label):
		fury_label.text = "Fúria: %d/5%s" % [fury, " • FORMA DEMONÍACA" if demonic_form_active else ""]
	if is_instance_valid(speed_label):
		speed_label.text = "TEMPO DO MUNDO: %.1fx" % world_speed()
	if is_instance_valid(speed_button):
		speed_button.text = "Acelerar relógio ▶"
	if is_instance_valid(forge_status_label):
		if craft_jobs.is_empty():
			forge_status_label.text = "Forja: livre"
		else:
			var queue_text: Array[String] = []
			for job in craft_jobs:
				var queued_item: Dictionary = products[int(job.get("index", 0))]
				queue_text.append("%s %.1fs" % [queued_item["name"], maxf(0.0, float(job.get("remaining", 0.0)))])
			forge_status_label.text = "Forja: " + " | ".join(queue_text)
	if is_instance_valid(library_upgrade_button):
		var library_cost := 90 + library_upgrade_level * 120
		library_upgrade_button.text = "Biblioteca Nv.%d • Upgrade %d ouro" % [library_upgrade_level, library_cost] if library_upgrade_level < 5 else "Biblioteca Nv.5 • Máximo"
		library_upgrade_button.disabled = library_upgrade_level >= 5 or gold < library_cost
	if is_instance_valid(sanctum_upgrade_button):
		var sanctum_cost := 90 + sanctum_upgrade_level * 120
		sanctum_upgrade_button.text = "Santuário Nv.%d • Upgrade %d ouro" % [sanctum_upgrade_level, sanctum_cost] if sanctum_upgrade_level < 5 else "Santuário Nv.5 • Máximo"
		sanctum_upgrade_button.disabled = sanctum_upgrade_level >= 5 or gold < sanctum_cost
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
		var already_queued := false
		for job in craft_jobs:
			if int(job.get("index", -1)) == i:
				already_queued = true
		craft_buttons[i].text = "Na fila" if already_queued else "Fabricar (%d)" % craft_cost if unlocked and missing_ingredients.is_empty() else "Faltam ingredientes" if unlocked else "Receita bloqueada"
		craft_buttons[i].disabled = already_queued or craft_jobs.size() >= 3 or not unlocked or gold < craft_cost or not missing_ingredients.is_empty()
	var ad_cost := 75 + ad_level * 60
	upgrade_button.text = "Propaganda infernal • %d ouro (nível %d)" % [ad_cost, ad_level]
	upgrade_button.disabled = gold < ad_cost
	private_button.text = "Momento especial (afinidade 5)" if affection >= 5 else "Momento especial • afinidade %d/5" % affection
	private_button.disabled = affection < 5
	adult_toggle_button.text = "Cenas sensuais: LIGADAS" if adult_content_enabled else "Cenas sensuais: DESLIGADAS"
	if is_instance_valid(recover_theft_button):
		recover_theft_button.text = "Rastrear: %s" % stolen_item_name if theft_recovery_available else "Rastrear item roubado"
		recover_theft_button.disabled = not theft_recovery_available
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
	config.set_value("game", "fury", fury)
	config.set_value("game", "stolen_item_name", stolen_item_name)
	config.set_value("game", "theft_recovery_available", theft_recovery_available)
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
	config.set_value("game", "seduction_attempts", seduction_attempts)
	config.set_value("game", "seduction_successes", seduction_successes)
	config.set_value("game", "world_speed_index", world_speed_index)
	config.set_value("game", "library_upgrade_level", library_upgrade_level)
	config.set_value("game", "sanctum_upgrade_level", sanctum_upgrade_level)
	config.set_value("game", "queue_distractions", queue_distractions)
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
	fury = clampi(int(config.get_value("game", "fury", fury)), 0, 5)
	stolen_item_name = str(config.get_value("game", "stolen_item_name", stolen_item_name))
	theft_recovery_available = bool(config.get_value("game", "theft_recovery_available", theft_recovery_available))
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
	demonic_form_active = adult_content_enabled and fury >= 4
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
	seduction_attempts = int(config.get_value("game", "seduction_attempts", seduction_attempts))
	seduction_successes = int(config.get_value("game", "seduction_successes", seduction_successes))
	world_speed_index = clampi(int(config.get_value("game", "world_speed_index", world_speed_index)), 0, world_speed_options.size() - 1)
	library_upgrade_level = clampi(int(config.get_value("game", "library_upgrade_level", library_upgrade_level)), 0, 5)
	sanctum_upgrade_level = clampi(int(config.get_value("game", "sanctum_upgrade_level", sanctum_upgrade_level)), 0, 5)
	queue_distractions = int(config.get_value("game", "queue_distractions", queue_distractions))
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
		{"id": "premium_artisan", "name": "Mão de Midas (3 produtos premium)", "condition": premium_crafted >= 3, "gold": 45, "rep": 2},
		{"id": "library_master", "name": "Bibliotecária do Submundo (Biblioteca Nv.3)", "condition": library_upgrade_level >= 3, "gold": 80, "rep": 4, "pose": "book"},
		{"id": "sanctum_keeper", "name": "Guardiã das Relíquias (Santuário Nv.3)", "condition": sanctum_upgrade_level >= 3, "gold": 90, "rep": 5, "pose": "relic"},
		{"id": "queue_charmer", "name": "Ninguém sai da fila (3 distrações)", "condition": queue_distractions >= 3, "gold": 65, "rep": 4, "pose": "queue"},
		{"id": "speed_demon", "name": "Cinco vezes mais charmosa (velocidade 5x)", "condition": world_speed() >= 5.0, "gold": 50, "rep": 3, "pose": "speed"}
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
			if achievement.has("pose"):
				_play_achievement_pose(str(achievement["pose"]))

func _play_achievement_pose(pose: String) -> void:
	if not adult_content_enabled or not is_instance_valid(seller_portrait):
		return
	if sensual_tween != null and sensual_tween.is_valid():
		sensual_tween.kill()
	seller_portrait.pivot_offset = seller_portrait.size / 2.0
	sensual_tween = create_tween()
	var target_scale := Vector2(1.10, 1.10)
	var target_rotation := 0.0
	match pose:
		"book":
			target_rotation = -0.05
		"relic":
			target_scale = Vector2(1.16, 1.16)
		"queue":
			target_rotation = 0.06
		"speed":
			target_scale = Vector2(1.08, 1.08)
			target_rotation = -0.08
	sensual_tween.tween_property(seller_portrait, "scale", target_scale, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sensual_tween.tween_property(seller_portrait, "rotation", target_rotation, 0.22)
	sensual_tween.tween_property(seller_portrait, "modulate", Color(1.0, 0.72, 0.92, 1.0), 0.24)
	sensual_tween.tween_interval(0.8)
	sensual_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.28)
	sensual_tween.tween_property(seller_portrait, "rotation", 0.0, 0.18)
	sensual_tween.tween_property(seller_portrait, "modulate", Color.WHITE, 0.24)
	_show_feedback("✦ Pose de conquista desbloqueada!", Color(1.0, 0.70, 0.88))

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
			"premium_artisan": "Mão de Midas",
			"library_master": "Bibliotecária do Submundo",
			"sanctum_keeper": "Guardiã das Relíquias",
			"queue_charmer": "Ninguém sai da fila",
			"speed_demon": "Cinco vezes mais charmosa"
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
		_play_sensual_reception_moment()
	_save_game()
	_refresh_ui()

func _toggle_adult_content() -> void:
	adult_content_enabled = not adult_content_enabled
	last_event = "Cenas sensuais ativadas. As recompensas especiais estão disponíveis." if adult_content_enabled else "Cenas sensuais desativadas. A progressão e a economia continuam normalmente."
	_save_game()
	_refresh_ui()
