extends Control

const SAVE_PATH := "user://succubus_shop_save.cfg"
const Regulars = preload("res://regulars.gd")
const Factions = preload("res://factions.gd")
const Ingredients = preload("res://ingredients.gd")
const Products = preload("res://products.gd")

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

var products: Array = Products.DATA

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
const GameAudio = preload("res://audio.gd")
var audio: Node
var mute_button: Button
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
	audio = GameAudio.new()
	add_child(audio)
	audio.settings_changed.connect(_apply_music_settings)
	_load_game()
	_build_ui()
	_setup_feedback_audio()
	_setup_background_music()
	_apply_music_settings()
	_refresh_ui()
	_start_ambient_animations()
	var timer := Timer.new()
	world_timer = timer
	timer.wait_time = 3.0 / world_speed()
	timer.autostart = true
	timer.timeout.connect(_on_customer_tick)
	add_child(timer)

# ... rest of main.gd unchanged ...
