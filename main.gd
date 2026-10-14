extends Control

const SAVE_PATH := "user://succubus_shop_save.cfg"
const Regulars = preload("res://regulars.gd")
const Factions = preload("res://factions.gd")
const Ingredients = preload("res://ingredients.gd")
const Quality = preload("res://quality.gd")
const Economy = preload("res://economy.gd")
const Sanctum = preload("res://sanctum.gd")
const Expedition = preload("res://expedition.gd")
const Cards = preload("res://cards.gd")
const Campaign = preload("res://campaign.gd")
const SteamBridge = preload("res://steam_bridge.gd")

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
## Receitas pagas na biblioteca, independentemente do nível da personagem.
var known_recipes: Array[String] = []
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
var sector_action_button: Button
var queue_distractions: int = 0
var ingredient_stock: Dictionary = {"essencia": 1, "pena": 1, "sal": 1, "vazio": 1, "tinta": 1, "po_lunar": 1}
## Estoque de peças por qualidade: { id_do_produto: [torto, honesto, refinado, prima, mitico] }
var quality_stock: Dictionary = {}
## Mercado reativo: { "ingredient": {id: calor}, "product": {id: calor} }
var economy_state: Dictionary = Economy.fresh_state()
## Rituais ativos do santuário: { id_do_ritual: segundos_de_mundo_restantes }
var active_buffs: Dictionary = {}
var total_ingredients_bought: int = 0
## Peças Refinado ou melhor já fabricadas (mantém a conquista "Mão de Midas").
var premium_crafted: int = 0
var best_quality_crafted: int = -1
var rituals_performed: int = 0
## Viagens em andamento: [{ id, remaining, total }]
var expeditions: Array[Dictionary] = []
## As últimas quatro malas que voltaram, para o diário de bordo.
var expedition_log: Array[String] = []
var expeditions_done: int = 0
var rare_found: int = 0
## Peças saídas da forja com catalisador raro.
var catalyst_crafted: int = 0
## Catalisador raro ligado: a próxima forja queima uma raridade por mais sorte.
var catalyst_enabled: bool = false
## Cartas colecionáveis: { id_da_carta: quantidade }. Primeira cópia vale ponto.
var card_counts: Dictionary = {}
var packs_opened: int = 0
var completed_sets: Array[String] = []
var best_score: int = 0
var campaign_step: int = 0
var game_completed: bool = false
var total_crafted: int = 0
var steam: Node
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
	{"id": "dano_emocional", "name": "Poção de Dano Emocional", "cost": 8, "price": 15, "stock": 1, "ingredients": {"essencia": 1}, "desc": "Lembra você daquela mensagem que mandou em 2018."},
	{"id": "pato_amaldicoado", "name": "Pato Amaldiçoado Premium", "cost": 10, "price": 24, "stock": 1, "ingredients": {"pena": 1}, "desc": "Ele não faz nada. Mas julga suas decisões."},
	{"id": "lagrimas_jogador", "name": "Lágrimas de Jogador Derrotado", "cost": 12, "price": 30, "stock": 1, "ingredients": {"sal": 1}, "desc": "Ingrediente raro. Salgado. Muito salgado."},
	{"id": "caixa_misteriosa", "name": "Caixa Misteriosa Vazia", "cost": 5, "price": 12, "stock": 1, "ingredients": {"vazio": 1}, "desc": "A surpresa é perceber que você pagou por uma caixa."},
	{"id": "confianca_instantanea", "name": "Poção de Confiança Instantânea", "cost": 9, "price": 22, "stock": 1, "ingredients": {"essencia": 1, "tinta": 1}, "desc": "Funciona até alguém pedir para você explicar."},
	{"id": "elixir_memoria", "name": "Elixir de Memória de Peixe", "cost": 18, "price": 48, "stock": 0, "required_level": 3, "ingredients": {"sal": 1, "po_lunar": 1}, "desc": "Você esquece por que comprou. E compra de novo."},
	{"id": "incenso_teleporte", "name": "Incenso de Teletransporte Barato", "cost": 26, "price": 68, "stock": 0, "required_level": 5, "ingredients": {"po_lunar": 1, "tinta": 1}, "desc": "Leva você a três metros dali. Às vezes quatro."},
	{"id": "cristal_credito", "name": "Cristal de Crédito Cósmico", "cost": 42, "price": 115, "stock": 0, "required_level": 8, "ingredients": {"vazio": 1, "tinta": 2}, "desc": "Converte promessas vagas em dívidas muito concretas."},
	{"id": "pergaminho_procrastinacao", "name": "Pergaminho de Procrastinação Certificada", "cost": 55, "price": 150, "stock": 0, "required_level": 10, "ingredients": {"tinta": 2, "essencia": 1}, "desc": "Adia tarefas importantes com selo ISO de preguiça."},
	{"id": "frasco_motivacao", "name": "Frasco de Motivação de Segunda-feira", "cost": 70, "price": 195, "stock": 0, "required_level": 12, "ingredients": {"po_lunar": 2, "sal": 1}, "desc": "Efeito dura até o primeiro e-mail."},
	{"id": "adaga_charme", "name": "Adaga de Charme Duvidoso", "cost": 30, "price": 95, "stock": 0, "required_level": 2, "ingredients": {"pena": 1, "tinta": 1}, "desc": "Brilha quando alguém promete pagar amanhã."},
	{"id": "martelo_faisca", "name": "Martelo de Faísca Dramática", "cost": 45, "price": 140, "stock": 0, "required_level": 4, "ingredients": {"sal": 1, "po_lunar": 1}, "desc": "Cada golpe produz uma faísca e uma opinião não solicitada."
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
var forge_box: VBoxContainer
var reception_box: VBoxContainer
var library_box: VBoxContainer
var sanctum_box: VBoxContainer
var expedition_box: VBoxContainer
var scene_action_box: VBoxContainer
var craft_buttons: Array = []
var product_labels: Array = []
var product_margin_labels: Array = []
var counter_labels: Array = []
var counter_buttons: Array = []
var ingredient_sell_buttons: Array = []
var recipe_labels: Array = []
var recipe_buttons: Array = []
var market_label: Label
var ritual_label: Label
var ritual_labels: Array = []
var ritual_buttons: Array = []
var expedition_labels: Array = []
var expedition_buttons: Array = []
var expedition_active_label: Label
var expedition_log_label: Label
var catalyst_button: Button
var catalyst_label: Label
var card_summary_label: Label
var pack_button: Button
var card_gallery_labels: Array = []
var board_label: Label
var score_button: Button
var right_title_label: Label
var chapter_label: Label
var chapter_button: Button
var campaign_line: Label
var ending_layer: Control
var last_pack_card: String = ""
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
## Palco vivo: os personagens atravessam o salão inteiro sobre a arte de fundo,
## em três camadas de profundidade, e a súcubus se debruça sobre o balcão quando
## alguém chega. Cada figura tem três poses do MESMO personagem: perna junta e
## dois meios de passo alternados. Percorrer as três é o ciclo de caminhada.
const STAGE_HOST_SPRITES: Array[String] = [
	"res://assets/stage_seller.png",
	"res://assets/stage_seller_lean.png",
]
## Nomes dos corpos do elenco, não listas de arquivos: a animação de cada um é
## tudo que existir em assets/ seguindo a convenção stage_<corpo>.png (pernas
## juntas), stage_<corpo>_walk1.png, _walk2.png ... na ordem. Colocar um quadro
## novo na pasta já aumenta o ciclo, sem tocar neste arquivo. Pose de emoção
## obedece a mesma regra: stage_<corpo>_<emoção>.png, com as emoções de
## STAGE_EMOTION_POSES. Personagem sem arte de emoção simplesmente não a usa.
## A ordem é a mesma de customer_portrait_paths, e é ela que faz o retrato bater
## com o corpo: quando o Sir Aldric entra no salão, ele anda na tela com o rosto
## que o painel mostra. Trocar um sem o outro desfaz o par.
const STAGE_CROWD_BODIES: Array[String] = [
	"adventurer",
	"mage",
	"goth",
	"barbarian",
	"rogue",
	"cleric",
	"merchant",
	"noble",
	"goblin",
	"collector",
	"dwarf",
	"bard",
	"paladin",
	"witch",
	"druid",
	"pirate",
]
## Quantos transeuntes o salão comporta ao mesmo tempo. O elenco cresceu para
## dez corpos justamente para não repetir, mas sala cheia de gente andando tapa a
## chefe e o balcão: o teto é de cena, não de elenco.
const STAGE_MAX_WALKERS := 4
## Altura relativa de cada corpo. A folha de poses normaliza todo mundo pela
## altura do palco, então sem isto o goblin andaria do tamanho de um humano.
const STAGE_BODY_HEIGHT := {
	"goblin": 0.62,
	"dwarf": 0.74,
}
## Emoções que o elenco sabe representar quando a arte existir. Os nomes vêm dos
## momentos da partida, não de uma lista de desejos: cada um deles é chamado por
## uma cena específica adiante. Personagem sem arte de emoção simplesmente não a usa.
const STAGE_EMOTION_POSES: Array[String] = [
	"espanto",
	"felicidade",
	"ousadia",
	"desconfianca",
	"briga",
	"beijo",
	"tristeza",
	"confusao",
	"recusa",
	"aprovacao",
	"tedio",
	"medo",
	"dor",
	"vergonha",
	"vitoria",
	"sono",
	"nojo",
	"curiosidade",
	"aceno",
	"aponta",
	"risada",
	"pensativo",
	"aplausao",
	"danca",
]
## Humor da visita -> pose. Uma mesma pose cobre mais de um estado quando a
## diferença é só de cor.
const STAGE_MOOD_POSE := {
	"delighted": "felicidade",
	"content": "aprovacao",
	"disappointed": "desconfianca",
	"hurry": "tedio",
	"broke": "recusa",
	"flee": "medo",
	"flirt": "beijo",
	"anger": "briga",
	"dare": "ousadia",
}
var _stage_frame_cache: Dictionary = {}
var _stage_sequence_cache: Dictionary = {}
## Móveis pintados que ficam NA FRENTE do elenco, por sala, em coordenadas
## normais (x, y, largura, altura) batendo com o STRETCH_SCALE do fundo. É o que
## faz a figura sumir de cintura para baixo ao passar atrás do balcão.
const STAGE_ROOM_PROPS := {
	"res://assets/shop_scene.png": [Rect2(0.435, 0.495, 0.565, 0.44), Rect2(0.0, 0.585, 0.19, 0.415)],
	"res://assets/forge_scene.png": [Rect2(0.0, 0.555, 0.165, 0.445), Rect2(0.77, 0.60, 0.23, 0.40), Rect2(0.655, 0.525, 0.095, 0.15)],
	"res://assets/library_room_scene.png": [Rect2(0.225, 0.42, 0.13, 0.27), Rect2(0.0, 0.52, 0.215, 0.21), Rect2(0.78, 0.525, 0.205, 0.195)],
	"res://assets/sanctum_room_scene.png": [Rect2(0.0, 0.53, 0.14, 0.17), Rect2(0.862, 0.53, 0.138, 0.17), Rect2(0.235, 0.515, 0.055, 0.15), Rect2(0.71, 0.505, 0.055, 0.15)],
}
## Faixa de piso por onde o elenco anda em cada sala, em fração da largura. Na
## recepção o balcão cobre o resto do salão: quem passasse por ali ficaria só com
## a cabeça de fora, então o transeunte patrulha o piso visível e volta.
const STAGE_ROOM_WALK := {
	"res://assets/shop_scene.png": Vector2(0.13, 0.42),
}
## Onde a chefe espera atrás do balcão e onde o cliente do turno encosta, por sala.
const STAGE_ROOM_MEET := {
	"res://assets/shop_scene.png": Vector2(0.505, 0.37),
	"res://assets/forge_scene.png": Vector2(0.30, 0.44),
	"res://assets/library_room_scene.png": Vector2(0.42, 0.55),
	"res://assets/sanctum_room_scene.png": Vector2(0.50, 0.32),
}
## Faixa de chão pintado de cada sala, em fração da altura da tela: onde o piso
## nasce ao fundo e onde ele chega na frente. É isto que prende o pé do elenco ao
## cenário; sem ela a figura fica plantada no meio da parede.
const STAGE_ROOM_FLOOR := {
	"res://assets/shop_scene.png": Vector2(0.60, 0.80),
	"res://assets/forge_scene.png": Vector2(0.60, 0.80),
	"res://assets/library_room_scene.png": Vector2(0.655, 0.84),
	"res://assets/sanctum_room_scene.png": Vector2(0.585, 0.79),
}
## Altura de um adulto em primeiro plano. As camadas de trás escalam em cima dela
## para casar com a perspectiva da arte.
const STAGE_FIGURE_HEIGHT := 250.0
## Velocidade de caminhada em pixels por segundo na escala 1 e duração de cada
## passo. Amarra os dois: o pé que se move e o corpo que avança concordam.
const STAGE_WALK_SPEED := 215.0
const STAGE_STEP_SECONDS := 0.34
## Ordem das poses no ciclo: meio de passo, perna junta, outro meio de passo.
## Ciclo de passo de um corpo: todos os frames de caminhada e depois a pose de
## pernas juntas, um por batida. Com três artes isso é [1, 2, 0]; com doze, é o
## meio de passo passando por cada posição do passo, e a animação fica fluida.
func _stage_walk_sequence(count: int) -> Array[int]:
	if _stage_sequence_cache.has(count):
		return _stage_sequence_cache[count]
	var sequence: Array[int] = []
	for i in range(1, count):
		sequence.append(i)
	sequence.append(0)
	_stage_sequence_cache[count] = sequence
	return sequence
## Faixa da tela que o elenco pinta de cenário andável, e o pedaço dela que o
## painel lateral toma de volta para cima para as imagens não chegarem cortadas.
## A coluna do mercado devolve exatamente o mesmo respiro, então só o quadro de
## interação cresce.
const STAGE_BAND_SHARE := 0.30
const SIDE_PANEL_LIFT := 0.10
var stage_layer: Control
var stage_front_layer: Control
var stage_occluder: TextureRect
var ui_layer: Control
var stage_seller: Control
var stage_seller_body: Control
var stage_customer: Control
var _stage_walkers: Array[Dictionary] = []
var _stage_retired: Array[Dictionary] = []
var _stage_walker_timer: float = 2.0
var _lane_depths: Array[float] = [0.08, 0.40, 0.82]
var _lane_scales: Array[float] = [0.56, 0.78, 1.0]
var _lane_alphas: Array[float] = [0.90, 0.96, 1.0]
var _stage_back_band: Control
var _market_top_guard: Control
var _stage_room: String = "res://assets/shop_scene.png"
var _seller_home: Vector2 = Vector2.ZERO
var _stage_layout_key := Vector2(-1.0, -1.0)
var _seller_lean_tween: Tween
var _customer_bob: Tween
var _customer_leave_tween: Tween
var _stage_fade_tweens: Array[Tween] = []
var _stage_occluder_material: ShaderMaterial
var sector_title_label: Label
var sector_hint_label: Label
var reception_button: Button
var forge_button: Button
var library_button: Button
var sanctum_button: Button
var expedition_button: Button
var current_sector: String = "reception"
var current_customer_budget: int = 0
var current_customer_patience: int = 0
## A fila encantada por um evento raro deixa o próximo cliente mais paciente. O
## bônus fica guardado aqui porque o evento dispara antes de qualquer visita: sem
## isto ele somava paciência de um balcão vazio.
var distraction_pending: int = 0
var stolen_item_name: String = ""
var stolen_tier: int = 1
var theft_recovery_available: bool = false
var seduction_peak_triggered: bool = false
var ambient_particles: CPUParticles2D
var music_player: AudioStreamPlayer
const GameAudio = preload("res://audio.gd")
var audio: Node
var mute_button: Button
var toast_label: Label
var toast_tween: Tween
var market_panel: VBoxContainer
var market_toggle_button: Button
var sensual_tween: Tween
## Índice usado em "portrait" nos perfis e em regulars.gd. Ordem fixa:
## 0 aventureiro, 1 maga/mago, 2 gótico, 3 bárbaro, 4 ladina, 5 clérigo,
## 6 mercadora, 7 nobre, 8 goblin, 9 cobrador do submundo, 10 ferreiro anão,
## 11 barda, 12 paladina, 13 bruxa, 14 druida, 15 capitã pirata.
## Esta é a mesma ordem de STAGE_CROWD_BODIES: o corpo que anda no salão é o
## rosto que o painel mostra.
var customer_portrait_paths: Array[String] = [
	"res://assets/customer_adventurer.png",
	"res://assets/customer_mage.png",
	"res://assets/customer_goth.png",
	"res://assets/customer_barbarian.png",
	"res://assets/customer_rogue.png",
	"res://assets/customer_cleric.png",
	"res://assets/customer_merchant.png",
	"res://assets/customer_noble.png",
	"res://assets/customer_goblin.png",
	"res://assets/customer_collector.png",
	"res://assets/customer_dwarf.png",
	"res://assets/customer_bard.png",
	"res://assets/customer_paladin.png",
	"res://assets/customer_witch.png",
	"res://assets/customer_druid.png",
	"res://assets/customer_pirate.png"
]
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
const MEME_FLIRT_LINES := [
"A chefe responde ao Mago do Quero Mana: “Mana eu tenho. Quero ver se você aguenta o preço.”",
"Ela encara o Fiscal do Pix Astral: “Aproxima o cristal, querido. Se der erro, você paga com um elogio.”",
"A succubus provoca o corredor: “Só mais uma run? Então fica mais uma negociação comigo.”",
"Ela sorri para o cliente do bordão: “É sobre isso. E sobre você voltar amanhã.”",
"A chefe aponta para o ladrão: “Ctrl+C não copia meu charme. Esse é proprietário.”"
]

func _ready() -> void:
	audio = GameAudio.new()
	add_child(audio)
	audio.settings_changed.connect(_apply_music_settings)
	steam = SteamBridge.new()
	steam.name = "SteamBridge"
	add_child(steam)
	steam.boot(_achievement_ids())
	steam.connect("leaderboard_ready", _on_leaderboard_ready)
	_load_game()
	_sync_quality_stock()
	_build_ui()
	_apply_sector_visibility()
	_setup_background_music()
	_apply_music_settings()
	_refresh_ui()
	_start_ambient_animations()
	steam.call("request_leaderboard")
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
	audio.play("click")
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
	if is_instance_valid(stage_seller):
		stage_seller.pivot_offset = stage_seller.size / 2.0
		var sway := create_tween().set_loops()
		sway.tween_property(stage_seller_body, "rotation_degrees", -1.3, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway.tween_property(stage_seller_body, "rotation_degrees", 1.0, 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		sway.tween_property(stage_seller_body, "rotation_degrees", 0.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var stage_breath := create_tween().set_loops()
		stage_breath.tween_property(stage_seller_body, "scale", Vector2(1.0, 1.022), 1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		stage_breath.tween_property(stage_seller_body, "scale", Vector2.ONE, 1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	if not is_instance_valid(stage_layer) or not stage_layer.visible or stage_layer.size.x <= 0:
		return
	# Containers reposicionam o salão sem emitir sinal: o chão é conferido a cada
	# quadro para as figuras não ficarem presas num layout velho.
	var ground := Vector2(stage_layer.size.x, stage_layer.size.y)
	if ground != _stage_layout_key:
		_stage_layout_key = ground
		_layout_stage_figures()
	_stage_walker_timer -= delta
	if _stage_walker_timer <= 0.0:
		_stage_walker_timer = randf_range(2.5, 6.5)
		_spawn_stage_walker()
	stage_layer.queue_redraw()
	stage_front_layer.queue_redraw()

## Transeunte anônimo atravessa o salão em uma das camadas de profundidade. O
## elenco são as artes de corpo inteiro dos fregueses, menores e mais frias quanto
## mais longe da câmera.
func _spawn_stage_walker() -> void:
	# Um corpo fica reservado ao cliente do turno: com todos em cena nunca haveria
	# quem entrar sem repetir alguém.
	if _stage_walkers.size() >= mini(STAGE_CROWD_BODIES.size() - 1, STAGE_MAX_WALKERS):
		return
	var crowd := _free_crowd_index()
	if crowd < 0:
		return
	var depth := randf_range(0.05, 0.30)
	var lane := _lane_at(depth)
	var walker := _make_stage_poses(crowd, STAGE_FIGURE_HEIGHT)
	var figure_scale: float = lane["scale"]
	walker.scale = Vector2(figure_scale, figure_scale)
	# Mais fundo na sala: um pouco mais frio e escuro, mas nunca fantasma.
	var shade: float = lerpf(0.86, 1.0, (figure_scale - 0.5) / 0.5)
	walker.modulate = Color(shade, shade * 0.98, shade * 1.02, lane["alpha"])
	# O pivô no meio do corpo faz a respiração e o balanço girarem como gente, mas
	# obriga a entrada e a saída a descontarem a meia altura desenhada.
	walker.pivot_offset = walker.size / 2.0
	var half_drawn := walker.size * figure_scale * 0.5
	var half_body := walker.size * 0.5
	var floor_y: float = lane["floor_y"]
	var to_the_right := randi() % 2 == 0
	var span: Vector2 = STAGE_ROOM_WALK.get(_stage_room, Vector2(0.0, 1.0))
	var turns := (to_the_right and span.y < 0.99) or ((not to_the_right) and span.x > 0.01)
	# Onde o piso vai de uma borda à outra a figura entra e sai pela beirada da
	# tela. Onde o balcão ocupa o resto da sala ela nasce na ponta do piso andável,
	# patrulha até a outra ponta e se apaga ali, em vez de virar fantasma atrás do
	# móvel. Os valores abaixo são o centro do corpo desenhado.
	var first_c := span.x * stage_layer.size.x if to_the_right else span.y * stage_layer.size.x
	var last_c := span.y * stage_layer.size.x if to_the_right else span.x * stage_layer.size.x
	if not turns:
		first_c = -half_drawn.x - 20.0 if to_the_right else stage_layer.size.x + half_drawn.x + 20.0
		last_c = stage_layer.size.x + half_drawn.x + 40.0 if to_the_right else -half_drawn.x - 40.0
	walker.position = Vector2(first_c - half_body.x, floor_y - half_drawn.y - half_body.y)
	_set_stage_flip(walker, not to_the_right)
	stage_layer.add_child(walker)
	# Os transeuntes passam atrás da chefe e do cliente do turno.
	stage_layer.move_child(walker, 0)
	if turns:
		walker.modulate.a = 0.0
		var appear := create_tween()
		appear.tween_property(walker, "modulate:a", lane["alpha"], 0.6)
	# Velocidade proporcional ao tamanho do corpo: o passo cobre exatamente a
	# distância que a figura avança, então ninguém desliza nem corre parado.
	var speed := STAGE_WALK_SPEED * figure_scale
	var trip := create_tween()
	var leg := absf(last_c - first_c) / speed
	if turns:
		# Ninguém faz curva em linha reta: os últimos passos encurtam, o corpo junta
		# as pernas, vira, e só então a marcha retoma.
		var slow := leg * 0.12
		var near_last := last_c - (last_c - first_c) * 0.12
		trip.tween_property(walker, "position:x", near_last - half_body.x, leg - slow).set_trans(Tween.TRANS_LINEAR)
		trip.tween_property(walker, "position:x", last_c - half_body.x, slow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		trip.tween_callback(_turn_stage_walker.bind(walker))
		trip.tween_interval(STAGE_STEP_SECONDS)
		trip.tween_property(walker, "position:x", near_last - half_body.x, slow).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		trip.tween_property(walker, "position:x", first_c - half_body.x, leg - slow).set_trans(Tween.TRANS_LINEAR)
	else:
		trip.tween_property(walker, "position:x", last_c - half_body.x, leg).set_trans(Tween.TRANS_LINEAR)
	trip.tween_callback(_retire_walker.bind(walker))
	# Um quadro novo a cada passo, com o corpo subindo no meio dele para o pé não
	# parecer escorregando no chão.
	var base_y := walker.position.y
	var stride := create_tween().set_loops()
	stride.tween_property(walker, "rotation_degrees", 1.6, STAGE_STEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	stride.tween_callback(_advance_stage_frame.bind(walker))
	stride.tween_property(walker, "rotation_degrees", -1.6, STAGE_STEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	stride.tween_callback(_advance_stage_frame.bind(walker))
	var bob := create_tween().set_loops()
	bob.tween_property(walker, "position:y", base_y - 2.5, STAGE_STEP_SECONDS * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bob.tween_property(walker, "position:y", base_y, STAGE_STEP_SECONDS * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_stage_walkers.append({"node": walker, "crowd": crowd, "bob": bob, "stride": stride, "trip": trip})

## Que corpo do elenco já está em cena. Os personagens se revezam, e um corpo só
## pode vestir uma figura por vez: dois iguais andando juntos liam o mesmo sprite
## colado duas vezes, e repetir o freguês do turno destoava do balcão.
func _free_crowd_index() -> int:
	var taken: Array[int] = []
	for entry in _stage_walkers:
		taken.append(int(entry.get("crowd", -1)))
	for i in range(_stage_retired.size() - 1, -1, -1):
		if not is_instance_valid(_stage_retired[i]["node"]):
			_stage_retired.remove_at(i)
		else:
			taken.append(int(_stage_retired[i]["crowd"]))
	if is_instance_valid(stage_customer) and stage_customer.visible:
		taken.append(int(stage_customer.get_meta("crowd", -1)))
	var pool: Array[int] = []
	for i in range(STAGE_CROWD_BODIES.size()):
		if not taken.has(i):
			pool.append(i)
	if pool.is_empty():
		return -1
	return pool[randi() % pool.size()]

func _retire_walker(walker: Control) -> void:
	var crowd := -1
	for i in range(_stage_walkers.size()):
		if _stage_walkers[i]["node"] == walker:
			var entry: Dictionary = _stage_walkers[i]
			crowd = int(entry.get("crowd", -1))
			_stage_walkers.remove_at(i)
			for key in ["bob", "stride", "trip"]:
				var mover: Tween = entry[key]
				if mover.is_valid():
					mover.kill()
			break
	if crowd >= 0:
		# O corpo ainda some da tela durante o fade: liberado antes, entraria
		# duplicado em cena enquanto o velho se apaga.
		_stage_retired.append({"node": walker, "crowd": crowd})
	if not is_instance_valid(walker):
		return
	var fade := create_tween()
	fade.tween_property(walker, "modulate:a", 0.0, 0.5)
	fade.tween_callback(walker.queue_free)

## Troca de sala não pode apagar ninguém de repente: quem estava no salão anterior
## sai de cena e a equipe da sala nova entra pelo fundo.
func _dismiss_stage_cast() -> void:
	for entry in _stage_walkers.duplicate():
		var walker := entry["node"] as Control
		if is_instance_valid(walker):
			_retire_walker(walker)
	_stage_walkers.clear()
	_stage_customer_leaves()

func _show_stage_for_room(scene_path: String, walkable: bool) -> void:
	# Trocas rápidas de sala não podem deixar um fade velho escondendo a camada
	# que a sala nova acabou de acender.
	for stale in _stage_fade_tweens:
		if stale.is_valid():
			stale.kill()
	_stage_fade_tweens.clear()
	_apply_room_props(scene_path)
	# A sala nova tem outro ponto de encontro: sem isso a chefe ficaria parada na
	# marca da sala anterior, porque o resto do layout não mudou.
	_layout_stage_figures()
	var layers: Array[Control] = [stage_layer, stage_front_layer]
	if not walkable:
		# Sala sem chão pintado (só close-up): o elenco volta para os bastidores.
		_dismiss_stage_cast()
		stage_occluder.visible = false
		for layer in layers:
			if not layer.visible:
				continue
			var out := create_tween()
			_stage_fade_tweens.append(out)
			out.tween_property(layer, "modulate:a", 0.0, 0.3)
			out.tween_callback(layer.hide)
		return
	for layer in layers:
		layer.visible = true
		layer.modulate.a = 0.0
		var coming := create_tween()
		_stage_fade_tweens.append(coming)
		coming.tween_property(layer, "modulate:a", 1.0, 0.45)
	stage_occluder.visible = true
	stage_occluder.modulate.a = 0.0
	var props_in := create_tween()
	_stage_fade_tweens.append(props_in)
	props_in.tween_property(stage_occluder, "modulate:a", 1.0, 0.45)
	_host_enters_room()

## A chefe chega pelo lado do balcão quando a sala nova abre.
func _host_enters_room() -> void:
	if not is_instance_valid(stage_seller):
		return
	if _seller_lean_tween != null and _seller_lean_tween.is_valid():
		_seller_lean_tween.kill()
	_set_stage_frame(stage_seller_body, 0)
	_seller_lean_tween = create_tween()
	stage_seller.position = _seller_home + Vector2(96.0, 0.0)
	stage_seller.rotation_degrees = 0.0
	stage_seller.scale = Vector2.ONE
	_seller_lean_tween.tween_property(stage_seller, "position", _seller_home, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## O cliente do turno entra pela esquerda, para diante do balcão e sai quando o
## próximo tick o substitui.
func _stage_customer_arrives(portrait_index: int) -> void:
	if not is_instance_valid(stage_customer) or stage_layer.size.x <= 0:
		return
	var body := absi(portrait_index) % STAGE_CROWD_BODIES.size()
	_dress_stage_poses(stage_customer, body, _lane_height(2))
	# O corpo do freguês do turno é dele. Se um transeunte já o vestia, o
	# transeunte se apaga: dois do mesmo rosto na tela pareciam um sprite só
	# colado duas vezes.
	for entry in _stage_walkers.duplicate():
		if int(entry.get("crowd", -1)) == body:
			_retire_walker(entry["node"] as Control)
	var front := _lane(2)
	var floor_y: float = front["floor_y"] - stage_customer.size.y
	if _customer_leave_tween != null and _customer_leave_tween.is_valid():
		_customer_leave_tween.kill()
	_set_stage_flip(stage_customer, false)
	stage_customer.modulate = Color(1.0, 0.95, 0.98, front["alpha"])
	stage_customer.rotation_degrees = 0.0
	stage_customer.pivot_offset = stage_customer.size / 2.0
	stage_customer.position = Vector2(-stage_customer.size.x - 20.0, floor_y)
	stage_customer.visible = true
	var spot := Vector2(_room_meet().y * stage_layer.size.x - stage_customer.size.x * 0.5, floor_y)
	# Mesma cadência e mesma velocidade dos transeuntes: o cliente atravessa o
	# salão caminhando, não deslizando nem disparando até o balcão.
	var walk_time := absf(spot.x - stage_customer.position.x) / (STAGE_WALK_SPEED * float(front["scale"]))
	if _customer_bob != null and _customer_bob.is_valid():
		_customer_bob.kill()
	var walk := create_tween()
	walk.tween_property(stage_customer, "position:x", spot.x, walk_time * 0.78).set_trans(Tween.TRANS_LINEAR)
	walk.tween_property(stage_customer, "position:x", spot.x, walk_time * 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	walk.parallel().tween_property(stage_customer, "rotation_degrees", 0.0, walk_time * 0.22)
	walk.tween_callback(_stage_customer_stops)
	_customer_bob = create_tween().set_loops()
	_customer_bob.tween_property(stage_customer, "rotation_degrees", 1.6, STAGE_STEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_customer_bob.tween_callback(_advance_stage_frame.bind(stage_customer))
	_customer_bob.tween_property(stage_customer, "rotation_degrees", -1.6, STAGE_STEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_customer_bob.tween_callback(_advance_stage_frame.bind(stage_customer))

## O cliente encosta no balcão: para de andar, apruma o corpo e só então a chefe
## se debruça para atendê-lo.
func _stage_customer_stops() -> void:
	if _customer_bob != null and _customer_bob.is_valid():
		_customer_bob.kill()
	_customer_bob = null
	if is_instance_valid(stage_customer):
		stage_customer.rotation_degrees = 0.0
		_set_stage_frame(stage_customer, 0)
		# Parado no balcão ele não tem mais ciclo de passo: o pose de emoção que
		# vier precisa devolver o corpo para as pernas juntas, não para o meio de
		# uma passada que já terminou.
		stage_customer.set_meta("walk_frames", 1)
	# Quem chega cumprimenta antes de ser atendido, e a chefe devolve o aceno.
	_show_stage_emotion(stage_customer, "aceno")
	_show_stage_emotion(stage_seller_body, "aceno")
	_seller_lean_in()

func _stage_customer_leaves() -> void:
	if not is_instance_valid(stage_customer) or not stage_customer.visible:
		return
	if _customer_bob != null and _customer_bob.is_valid():
		_customer_bob.kill()
	_set_stage_flip(stage_customer, true)
	var exit := Vector2(-stage_customer.size.x - 30.0, stage_customer.position.y)
	var leaving := create_tween()
	_customer_leave_tween = leaving
	leaving.tween_property(stage_customer, "position", exit, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	leaving.parallel().tween_property(stage_customer, "modulate:a", 0.2, 0.7)
	leaving.tween_callback(_hide_stage_customer)

func _hide_stage_customer() -> void:
	if is_instance_valid(stage_customer):
		stage_customer.visible = false

## A chefe se debruça sobre o balcão quando alguém encosta nele: ela troca para a
## pose inclinada enquanto se aproxima.
func _seller_lean_in() -> void:
	if not is_instance_valid(stage_seller):
		return
	if _seller_lean_tween != null and _seller_lean_tween.is_valid():
		_seller_lean_tween.kill()
	var home := _seller_home
	_seller_lean_tween = create_tween()
	_seller_lean_tween.tween_callback(_set_stage_frame.bind(stage_seller_body, 1))
	_seller_lean_tween.tween_property(stage_seller, "position", home + Vector2(-18.0, 3.0), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_seller_lean_tween.parallel().tween_property(stage_seller, "rotation_degrees", -6.0, 0.3).set_trans(Tween.TRANS_SINE)
	_seller_lean_tween.parallel().tween_property(stage_seller, "scale", Vector2(1.07, 1.07), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_seller_lean_tween.tween_interval(1.15)
	_seller_lean_tween.tween_callback(_set_stage_frame.bind(stage_seller_body, 0))
	_seller_lean_tween.tween_property(stage_seller, "position", home, 0.65).set_trans(Tween.TRANS_SINE)
	_seller_lean_tween.parallel().tween_property(stage_seller, "rotation_degrees", 0.0, 0.65).set_trans(Tween.TRANS_SINE)
	_seller_lean_tween.parallel().tween_property(stage_seller, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_SINE)

## Três profundidades de salão, todas no respiro que a UI abre sobre a arte de
## fundo: quanto mais fundo, mais alto na tela, menor e mais translúcida a figura.
## A chefe fica na camada do meio, atrás dos móveis; o cliente do turno na da
## frente, encostado no balcão pelo lado do freguês.
func _lane(depth: int) -> Dictionary:
	return _lane_at(_lane_depths[clampi(depth, 0, _lane_depths.size() - 1)])

## Profundidade contínua entre as três faixas. O elenco anda por aqui: um
## transeunte pode ficar a meio caminho do fundo em vez de parar exatamente na
## linha onde a chefe atende, que é o que colava os dois corpos numa mancha só.
func _lane_at(depth: float) -> Dictionary:
	var floor_line: Vector2 = STAGE_ROOM_FLOOR.get(_stage_room, Vector2(0.60, 0.80))
	return {
		"floor_y": lerpf(floor_line.x, floor_line.y, clampf(depth, 0.0, 1.0)) * stage_layer.size.y,
		"scale": _lane_stop(depth, _lane_scales),
		"alpha": _lane_stop(depth, _lane_alphas),
	}

func _lane_stop(depth: float, values: Array[float]) -> float:
	var stops := _lane_depths
	var i := 0
	while i + 1 < stops.size() and depth > stops[i + 1]:
		i += 1
	if i + 1 >= stops.size():
		return values[stops.size() - 1]
	return lerpf(values[i], values[i + 1], inverse_lerp(stops[i], stops[i + 1], depth))

func _lane_height(depth: int) -> float:
	return STAGE_FIGURE_HEIGHT * _lane_scales[clampi(depth, 0, _lane_scales.size() - 1)]

## (x da chefe, x do cliente) em fração da largura da sala atual.
func _room_meet() -> Vector2:
	return STAGE_ROOM_MEET.get(_stage_room, Vector2(0.505, 0.37))

func _layout_stage_figures() -> void:
	if not is_instance_valid(stage_layer) or stage_layer.size.x <= 0:
		return
	# O salão respira com a janela: a faixa do palco é o cenário andável, e o
	# painel lateral ainda toma um pedaço dela de volta para cima.
	var wanted := stage_layer.size.y * STAGE_BAND_SHARE
	if is_instance_valid(_stage_back_band) and absf(_stage_back_band.custom_minimum_size.y - wanted) > 2.0:
		_stage_back_band.custom_minimum_size.y = wanted
	if is_instance_valid(_market_top_guard):
		_market_top_guard.custom_minimum_size.y = stage_layer.size.y * SIDE_PANEL_LIFT
	var host_lane := _lane(1)
	var seller_floor: float = host_lane["floor_y"]
	_seller_home = Vector2(_room_meet().x * stage_layer.size.x - stage_seller.size.x * 0.5, seller_floor - stage_seller.size.y)
	if is_instance_valid(stage_seller):
		# Enquanto o tween da chefe roda, ele é o dono da posição.
		if _seller_lean_tween == null or not _seller_lean_tween.is_valid():
			stage_seller.position = _seller_home
		stage_seller.pivot_offset = stage_seller.size / 2.0
		stage_seller_body.pivot_offset = stage_seller_body.size / 2.0
	if is_instance_valid(stage_customer):
		stage_customer.pivot_offset = stage_customer.size / 2.0

## O palco é a tela inteira: as figuras vivem sobre a arte de fundo, sem moldura e
## sem cópia da arte. A UI abre apenas um respiro largo, por onde o salão aparece.
## São três camadas empilhadas: elenco atrás dos móveis, os próprios móveis
## recortados da arte, e o cliente do turno na frente de tudo.
func _build_stage(root: Control) -> void:
	_stage_back_band = Control.new()
	_stage_back_band.custom_minimum_size = Vector2(0, 186.0)
	_stage_back_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stage_back_band)

	var insert_at := ui_layer.get_index()
	stage_layer = _make_stage_layer("StageBack")
	add_child(stage_layer)
	move_child(stage_layer, insert_at)
	stage_occluder = TextureRect.new()
	stage_occluder.name = "StageProps"
	stage_occluder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_occluder.stretch_mode = TextureRect.STRETCH_SCALE
	stage_occluder.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_occluder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_occluder.material = _occluder_material()
	add_child(stage_occluder)
	move_child(stage_occluder, insert_at + 1)
	stage_front_layer = _make_stage_layer("StageFront")
	add_child(stage_front_layer)
	move_child(stage_front_layer, insert_at + 2)

	# A chefe tem um nó externo (inclinação no balcão) e um corpo interno
	# (respiração e balanço), para as duas animações não brigarem pela mesma propriedade.
	stage_seller = Control.new()
	stage_seller.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_layer.add_child(stage_seller)
	stage_seller_body = _make_stage_figure(_stage_host_poses(), _lane_height(1))
	stage_seller_body.set_meta("stage_body", "seller")
	stage_seller_body.set_meta("walk_frames", 1)
	stage_seller.size = stage_seller_body.size
	stage_seller.add_child(stage_seller_body)
	stage_customer = _make_stage_poses(0, _lane_height(2))
	stage_customer.visible = false
	stage_front_layer.add_child(stage_customer)
	stage_layer.draw.connect(_draw_stage_shadows.bind(stage_layer, false))
	stage_front_layer.draw.connect(_draw_stage_shadows.bind(stage_front_layer, true))
	# Os respiros só têm tamanho depois do primeiro layout da UI, e a camada do
	# palco já nasce grande o bastante para não emitir resized: quem marca o chão
	# são os próprios respiros.
	for source in [stage_layer, _stage_back_band, ui_layer]:
		source.resized.connect(_layout_stage_figures)
	get_viewport().size_changed.connect(_layout_stage_figures)
	_layout_stage_figures()

func _make_stage_layer(layer_name: String) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return layer

## A mesma textura do fundo, desenhada só dentro dos retângulos dos móveis: o que
## passa por trás fica escondido pela própria arte, sem emenda nem moldura.
func _occluder_material() -> ShaderMaterial:
	if _stage_occluder_material != null:
		return _stage_occluder_material
	var shader := load("res://assets/stage_props_mask.gdshader") as Shader
	_stage_occluder_material = ShaderMaterial.new()
	_stage_occluder_material.shader = shader
	_apply_room_props(_stage_room)
	return _stage_occluder_material

func _apply_room_props(scene_path: String) -> void:
	_stage_room = scene_path
	var props: Array = STAGE_ROOM_PROPS.get(scene_path, [])
	for i in range(4):
		var rect: Rect2 = props[i] if i < props.size() else Rect2()
		_stage_occluder_material.set_shader_parameter("rect%d" % i, Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	if is_instance_valid(stage_occluder) and ResourceLoader.exists(scene_path):
		stage_occluder.texture = load(scene_path)

## Nome do corpo de um índice do elenco, com rotação: a lista pode crescer e
## qualquer índice fora dela continua desenhando alguém.
func _stage_body_name(index: int) -> String:
	return STAGE_CROWD_BODIES[absi(index) % STAGE_CROWD_BODIES.size()]

## Ciclo de caminhada do corpo: a pose parada e depois cada _walkN que existir,
## até o primeiro buraco. O resultado é memoizado porque spawns e trocas de sala
## perguntam pelos mesmos nomes o tempo todo.
func _stage_crowd_frames(index: int) -> Array[String]:
	var body := _stage_body_name(index)
	if _stage_frame_cache.has(body):
		return _stage_frame_cache[body]
	var frames: Array[String] = ["res://assets/stage_%s.png" % body]
	var step := 1
	while step <= 24:
		var candidate := "res://assets/stage_%s_walk%d.png" % [body, step]
		if not ResourceLoader.exists(candidate):
			break
		frames.append(candidate)
		step += 1
	_stage_frame_cache[body] = frames
	return frames

## Pose de emoção do corpo, ou vazio quando a arte ainda não existe.
func _stage_emotion_frame(index: int, emotion: String) -> String:
	return _body_emotion_frame(_stage_body_name(index), emotion)

static func _body_emotion_frame(body: String, emotion: String) -> String:
	if emotion.is_empty():
		return ""
	var candidate := "res://assets/stage_%s_%s.png" % [body, emotion]
	return candidate if ResourceLoader.exists(candidate) else ""

## As poses da chefe: as duas fixas do balcão e, atrás delas, cada emoção que a
## arte dela já tiver. A chefe é o "corpo zero" da mesma convenção do elenco.
static func _stage_host_poses() -> Array[String]:
	var poses: Array[String] = []
	for path in STAGE_HOST_SPRITES:
		poses.append(str(path))
	for emotion in STAGE_EMOTION_POSES:
		var path := _body_emotion_frame("seller", emotion)
		if not path.is_empty() and not poses.has(path):
			poses.append(path)
	return poses

## Todas as artes de um corpo numa lista só: o ciclo de caminhada primeiro, depois
## cada emoção desenhada. A figura veste tudo de uma vez e escolhe o quadro por
## índice, então trocar de emoção não recarrega textura nenhuma.
func _stage_pose_set(index: int) -> Array[String]:
	var poses := _stage_crowd_frames(index).duplicate()
	for emotion in STAGE_EMOTION_POSES:
		var path := _stage_emotion_frame(index, emotion)
		if not path.is_empty():
			poses.append(path)
	return poses

## Veste a figura com as poses e lembra onde a caminhada termina e a emoção começa.
func _dress_stage_poses(figure: Control, index: int, height: float) -> void:
	var body := _stage_body_name(index)
	_dress_stage_figure(figure, _stage_pose_set(index), height * float(STAGE_BODY_HEIGHT.get(body, 1.0)))
	figure.set_meta("walk_frames", _stage_crowd_frames(index).size())
	figure.set_meta("crowd", index)
	figure.set_meta("stage_body", body)

## Um corpo por pose, todos alinhados pelo pé central da caixa. Só a pose do meio
## do passo fica visível, e trocar de frame não mexe no tamanho nem no pivô.
func _dress_stage_figure(figure: Control, paths: Array[String], height: float) -> void:
	figure.set_meta("stage_step", 0)
	figure.set_meta("stage_frame", 0)
	for child in figure.get_children():
		figure.remove_child(child)
		child.queue_free()
	var bodies: Array[TextureRect] = []
	var widest := 0.0
	for path in paths:
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		if texture == null or texture.get_height() <= 0:
			continue
		var body := TextureRect.new()
		body.texture = texture
		body.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		body.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.size = Vector2(height * texture.get_width() / texture.get_height(), height)
		widest = maxf(widest, body.size.x)
		bodies.append(body)
		figure.add_child(body)
	if bodies.is_empty():
		return
	figure.size = Vector2(widest, height)
	figure.custom_minimum_size = figure.size
	for body in bodies:
		body.position = Vector2((widest - body.size.x) * 0.5, height - body.size.y)
		body.pivot_offset = body.size / 2.0
	figure.pivot_offset = figure.size / 2.0
	bodies[0].visible = true

func _make_stage_figure(paths: Array[String], height: float) -> Control:
	var figure := Control.new()
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dress_stage_figure(figure, paths, height)
	return figure

## Figura do elenco já vestida com caminhada e emoções, pronta para reagir.
func _make_stage_poses(index: int, height: float) -> Control:
	var figure := Control.new()
	figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dress_stage_poses(figure, index, height)
	return figure

func _set_stage_frame(figure: Control, index: int) -> void:
	var bodies := figure.get_children()
	if bodies.is_empty():
		return
	for i in range(bodies.size()):
		var body := bodies[i] as Control
		body.visible = i == index % bodies.size()

func _advance_stage_frame(figure: Control) -> void:
	if not is_instance_valid(figure):
		return
	# Só o ciclo de caminhada avança sozinho; as poses de emoção ficam depois dele
	# na lista e aparecem quando algo as pede.
	var frames := int(figure.get_meta("walk_frames", figure.get_child_count()))
	if frames < 3:
		var next := int(figure.get_meta("stage_frame", 0)) + 1
		figure.set_meta("stage_frame", next)
		_set_stage_frame(figure, next)
		return
	# Pose parada + todos os meios de passo desenhados, um por batida.
	var step := int(figure.get_meta("stage_step", 0)) + 1
	figure.set_meta("stage_step", step)
	var sequence := _stage_walk_sequence(frames)
	_set_stage_frame(figure, sequence[step % sequence.size()])

func _set_stage_flip(figure: Control, flipped: bool) -> void:
	figure.set_meta("stage_flip", flipped)
	for body in figure.get_children():
		(body as TextureRect).flip_h = flipped

## Meia-volta no fim do piso andável: o corpo vira de pernas fechadas, porque
## virar no meio de um passo trocaria de perna na cara do observador.
func _turn_stage_walker(walker: Control) -> void:
	if not is_instance_valid(walker):
		return
	_set_stage_frame(walker, 0)
	walker.set_meta("stage_step", 0)
	_set_stage_flip(walker, not bool(walker.get_meta("stage_flip", false)))

## Sem sombra de contato nenhuma figura fica de pé numa arte pintada. Os elipses
## acompanham o pé de cada personagem e são desenhados antes dos filhos da camada.
func _draw_stage_shadows(layer: Control, front: bool) -> void:
	var figures: Array[Control] = []
	if front:
		if is_instance_valid(stage_customer) and stage_customer.visible:
			figures.append(stage_customer)
	else:
		if is_instance_valid(stage_seller) and stage_seller.visible:
			figures.append(stage_seller_body)
		for entry in _stage_walkers:
			var walker := entry["node"] as Control
			if is_instance_valid(walker):
				figures.append(walker)
	for figure in figures:
		var parent := figure.get_parent()
		var origin: Vector2 = parent.position if parent is Control else Vector2.ZERO
		var foot := origin + Vector2(figure.position.x + figure.size.x * 0.5, figure.position.y + figure.size.y * (figure.scale.y + 1.0) * 0.5 - 2.0)
		var radius := figure.size.x * figure.scale.x * 0.40
		layer.draw_set_transform(foot, 0.0, Vector2(radius, maxf(5.0, radius * 0.17)))
		layer.draw_circle(Vector2.ZERO, 1.0, Color(0.04, 0.01, 0.05, 0.4))
		layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _build_ui() -> void:
	var bg := TextureRect.new()
	background_layer = bg
	# O salão abre vazio de propósito: quem preenche a loja é o elenco animado.
	var opening_scene := "res://assets/shop_scene.png"
	if not ResourceLoader.exists(opening_scene) and ResourceLoader.exists("res://assets/reception_scene.png"):
		opening_scene = "res://assets/reception_scene.png"
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
	# Âncoras em vez de preset de tamanho: com o preset normal o Godot estica a
	# caixa até o tamanho mínimo, e a UI inteira passava da janela em vez de rolar.
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.clip_contents = true
	margin.theme = _build_visual_theme()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	ui_layer = margin

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

	market_toggle_button = Button.new()
	market_toggle_button.text = "☰ Ocultar"
	market_toggle_button.custom_minimum_size = Vector2(104, 42)
	market_toggle_button.pressed.connect(_toggle_market_panel)
	header.add_child(market_toggle_button)

	reception_button = Button.new()
	reception_button.text = "Recepção"
	reception_button.custom_minimum_size = Vector2(96, 42)
	reception_button.pressed.connect(_set_sector.bind("reception"))
	header.add_child(reception_button)

	forge_button = Button.new()
	forge_button.text = "⚒ Forja"
	forge_button.custom_minimum_size = Vector2(96, 42)
	forge_button.pressed.connect(_set_sector.bind("forge"))
	header.add_child(forge_button)

	library_button = Button.new()
	library_button.text = "📚 Biblioteca"
	library_button.custom_minimum_size = Vector2(118, 42)
	library_button.pressed.connect(_set_sector.bind("library"))
	header.add_child(library_button)

	sanctum_button = Button.new()
	sanctum_button.text = "✦ Santuário"
	sanctum_button.custom_minimum_size = Vector2(112, 42)
	sanctum_button.pressed.connect(_set_sector.bind("sanctum"))
	header.add_child(sanctum_button)

	expedition_button = Button.new()
	expedition_button.text = "🧭 Expedições"
	expedition_button.custom_minimum_size = Vector2(126, 42)
	expedition_button.pressed.connect(_set_sector.bind("expedition"))
	header.add_child(expedition_button)

	mute_button = Button.new()
	mute_button.custom_minimum_size = Vector2(54, 42)
	mute_button.tooltip_text = "Ligar/desligar o som"
	mute_button.pressed.connect(func() -> void: audio.toggle_muted())
	header.add_child(mute_button)
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.05
	volume_slider.value = audio.volume
	volume_slider.custom_minimum_size = Vector2(90, 42)
	volume_slider.tooltip_text = "Volume"
	volume_slider.value_changed.connect(func(v: float) -> void: audio.set_volume(v))
	header.add_child(volume_slider)

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
	progression_label.add_theme_font_size_override("font_size", 16)
	progression_label.add_theme_color_override("font_color", Color(0.78, 0.95, 1.0))
	stats.add_child(progression_label)

	talent_label = Label.new()
	talent_label.add_theme_font_size_override("font_size", 14)
	talent_label.add_theme_color_override("font_color", Color(0.88, 0.83, 1.0))

	var talent_row := FlowContainer.new()
	talent_row.add_theme_constant_override("h_separation", 8)
	talent_row.add_theme_constant_override("v_separation", 6)
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

	_build_stage(root)

	var body := BoxContainer.new()
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
	body.add_child(left)

	# O respiro que o palco cedeu ao painel lateral volta aqui: o mercado começa no
	# mesmo lugar de antes e só o quadro de interação sobe.
	_market_top_guard = Control.new()
	_market_top_guard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_market_top_guard.custom_minimum_size.y = 72.0
	left.add_child(_market_top_guard)

	var product_title := Label.new()
	sector_title_label = product_title
	product_title.text = "RECEPÇÃO • MERCADO E BALCÃO"
	product_title.add_theme_font_size_override("font_size", 22)
	product_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	left.add_child(product_title)

	var hint := Label.new()
	sector_hint_label = hint
	hint.text = "Compre ingredientes e venda itens no balcão. Os clientes chegam sozinhos para negociar."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color(0.75, 0.71, 0.81))
	left.add_child(hint)

	var sector_scroll := ScrollContainer.new()
	sector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sector_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sector_scroll)

	# Cada setor mostra só a própria caixa: a recepção compra e vende, a forja
	# fabrica, a biblioteca ensina talentos e receitas, o santuário harmoniza relíquias.
	var sector_stack := VBoxContainer.new()
	sector_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sector_stack.add_theme_constant_override("separation", 10)
	sector_scroll.add_child(sector_stack)

	reception_box = _make_sector_box()
	sector_stack.add_child(reception_box)
	forge_box = _make_sector_box()
	sector_stack.add_child(forge_box)
	library_box = _make_sector_box()
	sector_stack.add_child(library_box)
	sanctum_box = _make_sector_box()
	sector_stack.add_child(sanctum_box)
	expedition_box = _make_sector_box()
	sector_stack.add_child(expedition_box)
	scene_action_box = _make_sector_box()
	sector_stack.add_child(scene_action_box)

	library_box.add_child(_make_section_title("TALENTOS", Color(0.88, 0.75, 1.0)))
	library_box.add_child(talent_label)
	library_box.add_child(talent_row)

	library_upgrade_button = Button.new()
	library_upgrade_button.custom_minimum_size = Vector2(220, 36)
	library_upgrade_button.pressed.connect(_buy_sector_upgrade.bind("library"))
	library_box.add_child(library_upgrade_button)

	sanctum_upgrade_button = Button.new()
	sanctum_upgrade_button.custom_minimum_size = Vector2(220, 36)
	sanctum_upgrade_button.pressed.connect(_buy_sector_upgrade.bind("sanctum"))
	sanctum_box.add_child(sanctum_upgrade_button)

	sector_action_button = Button.new()
	sector_action_button.custom_minimum_size = Vector2(220, 40)
	sector_action_button.pressed.connect(_activate_sector_feature)
	scene_action_box.add_child(sector_action_button)

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
		forge_box.add_child(card)

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

	reception_box.add_child(_make_section_title("OBJETIVOS DO IMPÉRIO", Color(0.82, 1.0, 0.86)))
	reception_box.add_child(_make_section_hint("A campanha da loja em capítulos. Cada capítulo concluído paga ouro, reputação, experiência e às vezes um pacote lacrado."))
	chapter_label = Label.new()
	chapter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_label.add_theme_font_size_override("font_size", 13)
	chapter_label.add_theme_color_override("font_color", Color(0.85, 0.96, 0.88))
	reception_box.add_child(chapter_label)
	chapter_button = Button.new()
	chapter_button.custom_minimum_size = Vector2(240, 42)
	chapter_button.add_theme_font_size_override("font_size", 14)
	chapter_button.pressed.connect(_claim_chapter)
	reception_box.add_child(chapter_button)

	reception_box.add_child(_make_section_title("BOLETIM DO MERCADO", Color(1.0, 0.86, 0.45)))
	reception_box.add_child(_make_section_hint("A loja reage ao que você compra e vende: estoque encalhado derruba o preço, demanda em alta empurra para cima."))
	market_label = Label.new()
	market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_label.add_theme_font_size_override("font_size", 14)
	market_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	reception_box.add_child(market_label)

	reception_box.add_child(_make_section_title("MERCADO DE INGREDIENTES", Color(0.78, 0.95, 1.0)))
	reception_box.add_child(_make_section_hint("Os preços flutuam com o dia e com o seu movimento. Compre barato, fabrique caro, e revenda o que sobrar."))

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
		reception_box.add_child(market_card)

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

		var ingredient_actions := VBoxContainer.new()
		ingredient_actions.add_theme_constant_override("separation", 4)
		market_row.add_child(ingredient_actions)

		var buy := Button.new()
		buy.custom_minimum_size = Vector2(150, 40)
		buy.add_theme_font_size_override("font_size", 14)
		buy.pressed.connect(_buy_ingredient.bind(ingredient_id))
		ingredient_actions.add_child(buy)
		ingredient_buttons.append(buy)

		var sell := Button.new()
		sell.custom_minimum_size = Vector2(150, 40)
		sell.add_theme_font_size_override("font_size", 14)
		sell.pressed.connect(_sell_ingredient.bind(ingredient_id))
		ingredient_actions.add_child(sell)
		ingredient_sell_buttons.append(sell)

	reception_box.add_child(_make_section_title("MÁQUINA DE CARTAS", Color(1.0, 0.86, 0.45)))
	reception_box.add_child(_make_section_hint("Pacote lacrado no balcão. Repetição volta em ouro, coleção completa volta em reputação."))
	card_summary_label = Label.new()
	card_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_summary_label.add_theme_font_size_override("font_size", 14)
	card_summary_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	reception_box.add_child(card_summary_label)
	pack_button = Button.new()
	pack_button.custom_minimum_size = Vector2(240, 44)
	pack_button.add_theme_font_size_override("font_size", 15)
	pack_button.pressed.connect(_grant_pack.bind(false))
	reception_box.add_child(pack_button)

	reception_box.add_child(_make_section_title("BALCÃO DE VENDAS", Color(1.0, 0.78, 0.9)))
	reception_box.add_child(_make_section_hint("Venda direta: ouro na hora por 70% do preço. Sem cliente não há vínculo, reputação nem charme."))

	for i in range(products.size()):
		var counter_card := _make_sector_card(Color(0.10, 0.045, 0.14, 0.94), Color(0.66, 0.30, 0.56, 0.95))
		reception_box.add_child(counter_card)
		var counter_row := HBoxContainer.new()
		counter_row.add_theme_constant_override("separation", 12)
		counter_card.add_child(counter_row)
		var counter_info := VBoxContainer.new()
		counter_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		counter_row.add_child(counter_info)
		var counter_label := Label.new()
		counter_label.add_theme_font_size_override("font_size", 15)
		counter_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.95))
		counter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counter_info.add_child(counter_label)
		counter_labels.append(counter_label)
		var counter_button := Button.new()
		counter_button.custom_minimum_size = Vector2(150, 40)
		counter_button.add_theme_font_size_override("font_size", 14)
		counter_button.pressed.connect(_sell_from_counter.bind(i))
		counter_row.add_child(counter_button)
		counter_buttons.append(counter_button)

	sanctum_box.add_child(_make_section_title("RELÍQUIAS", Color(0.86, 0.60, 1.0)))
	sanctum_box.add_child(_make_section_hint("Quanto mais alto o santuário, mais as relíquias acalmam o humor da chefe."))

	sanctum_box.add_child(_make_section_title("RITUAIS ATIVOS", Color(0.73, 0.30, 1.0)))
	ritual_label = Label.new()
	ritual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ritual_label.add_theme_font_size_override("font_size", 14)
	ritual_label.add_theme_color_override("font_color", Color(0.88, 0.76, 1.0))
	sanctum_box.add_child(ritual_label)

	sanctum_box.add_child(_make_section_title("RITUAIS", Color(0.86, 0.60, 1.0)))
	sanctum_box.add_child(_make_section_hint("Buffs custam ouro e queimam com o tempo de mundo. Rituais de alívio apagam penalidades já pagas."))

	for ritual in Sanctum.DATA:
		var ritual_id := str(ritual["id"])
		var ritual_card := _make_sector_card(Color(0.075, 0.04, 0.12, 0.94), Color(0.55, 0.28, 0.72, 0.95))
		sanctum_box.add_child(ritual_card)
		var ritual_row := HBoxContainer.new()
		ritual_row.add_theme_constant_override("separation", 12)
		ritual_card.add_child(ritual_row)
		var ritual_info := VBoxContainer.new()
		ritual_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ritual_row.add_child(ritual_info)
		var ritual_name := Label.new()
		ritual_name.text = "%s %s" % [ritual["icon"], ritual["name"]]
		ritual_name.add_theme_font_size_override("font_size", 16)
		ritual_name.add_theme_color_override("font_color", Color(0.93, 0.82, 1.0))
		ritual_info.add_child(ritual_name)
		var ritual_desc := Label.new()
		ritual_desc.text = str(ritual["desc"])
		ritual_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ritual_desc.add_theme_font_size_override("font_size", 13)
		ritual_desc.add_theme_color_override("font_color", Color(0.74, 0.68, 0.82))
		ritual_info.add_child(ritual_desc)
		var ritual_state := Label.new()
		ritual_state.add_theme_font_size_override("font_size", 13)
		ritual_state.add_theme_color_override("font_color", Color(0.88, 0.76, 1.0))
		ritual_info.add_child(ritual_state)
		ritual_labels.append(ritual_state)
		var ritual_button := Button.new()
		ritual_button.custom_minimum_size = Vector2(150, 44)
		ritual_button.add_theme_font_size_override("font_size", 14)
		ritual_button.pressed.connect(_perform_ritual.bind(ritual_id))
		ritual_row.add_child(ritual_button)
		ritual_buttons.append(ritual_button)

	expedition_box.add_child(_make_section_title("ROTEIROS", Color(1.0, 0.72, 0.42)))
	expedition_box.add_child(_make_section_hint("O mercado não vende raridade. Cada viagem custa ouro, leva dias de loja e só volta com o que a sorte deixar."))

	for destination in Expedition.DATA:
		var destination_id := str(destination["id"])
		var trip_card := _make_sector_card(Color(0.05, 0.075, 0.075, 0.94), Color(0.42, 0.62, 0.5, 0.95))
		expedition_box.add_child(trip_card)
		var trip_row := HBoxContainer.new()
		trip_row.add_theme_constant_override("separation", 12)
		trip_card.add_child(trip_row)
		var trip_info := VBoxContainer.new()
		trip_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		trip_row.add_child(trip_info)
		var trip_name := Label.new()
		trip_name.text = "🧭 %s" % destination["name"]
		trip_name.add_theme_font_size_override("font_size", 16)
		trip_name.add_theme_color_override("font_color", Color(0.92, 0.98, 0.9))
		trip_info.add_child(trip_name)
		var trip_desc := Label.new()
		trip_desc.text = str(destination["desc"])
		trip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trip_desc.add_theme_font_size_override("font_size", 13)
		trip_desc.add_theme_color_override("font_color", Color(0.72, 0.78, 0.76))
		trip_info.add_child(trip_desc)
		var trip_state := Label.new()
		trip_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trip_state.add_theme_font_size_override("font_size", 13)
		trip_state.add_theme_color_override("font_color", Color(1.0, 0.84, 0.55))
		trip_info.add_child(trip_state)
		expedition_labels.append(trip_state)
		var trip_button := Button.new()
		trip_button.custom_minimum_size = Vector2(150, 44)
		trip_button.add_theme_font_size_override("font_size", 14)
		trip_button.pressed.connect(_start_expedition.bind(destination_id))
		trip_row.add_child(trip_button)
		expedition_buttons.append(trip_button)

	expedition_box.add_child(_make_section_title("CATALISADORES RAROS", Color(0.86, 0.6, 1.0)))
	expedition_box.add_child(_make_section_hint("Raridade de expedição na forja queima uma peça e empurra a qualidade da peça seguinte."))
	catalyst_label = Label.new()
	catalyst_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	catalyst_label.add_theme_font_size_override("font_size", 13)
	catalyst_label.add_theme_color_override("font_color", Color(0.88, 0.76, 1.0))
	expedition_box.add_child(catalyst_label)
	catalyst_button = Button.new()
	catalyst_button.custom_minimum_size = Vector2(240, 42)
	catalyst_button.add_theme_font_size_override("font_size", 14)
	catalyst_button.pressed.connect(_toggle_catalyst)
	expedition_box.add_child(catalyst_button)

	expedition_box.add_child(_make_section_title("DIÁRIO DE BORDO", Color(0.78, 0.95, 1.0)))
	expedition_active_label = Label.new()
	expedition_active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expedition_active_label.add_theme_font_size_override("font_size", 14)
	expedition_active_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.55))
	expedition_box.add_child(expedition_active_label)
	expedition_log_label = Label.new()
	expedition_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expedition_log_label.add_theme_font_size_override("font_size", 13)
	expedition_log_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.86))
	expedition_box.add_child(expedition_log_label)

	library_box.add_child(_make_section_title("RECEITAS OCULTAS", Color(0.70, 0.90, 1.0)))
	library_box.add_child(_make_section_hint("Ouro adianta receitas presas ao nível. A biblioteca reduz o custo de cada leitura."))

	for i in range(products.size()):
		var recipe_card := _make_sector_card(Color(0.04, 0.075, 0.12, 0.94), Color(0.30, 0.52, 0.68, 0.95))
		library_box.add_child(recipe_card)
		var recipe_row := HBoxContainer.new()
		recipe_row.add_theme_constant_override("separation", 12)
		recipe_card.add_child(recipe_row)
		var recipe_info := VBoxContainer.new()
		recipe_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recipe_row.add_child(recipe_info)
		var recipe_label := Label.new()
		recipe_label.add_theme_font_size_override("font_size", 15)
		recipe_label.add_theme_color_override("font_color", Color(0.85, 0.97, 1.0))
		recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recipe_info.add_child(recipe_label)
		recipe_labels.append(recipe_label)
		var recipe_button := Button.new()
		recipe_button.custom_minimum_size = Vector2(150, 40)
		recipe_button.add_theme_font_size_override("font_size", 14)
		recipe_button.pressed.connect(_learn_recipe.bind(i))
		recipe_row.add_child(recipe_button)
		recipe_buttons.append(recipe_button)

	library_box.add_child(_make_section_title("PLACAR DO SUBMUNDO", Color(0.6, 0.95, 0.85)))
	library_box.add_child(_make_section_hint("A Steam cuida do ranking quando está aberta. Sem ela, o placar local guarda os melhores negócios da vizinhança."))
	board_label = Label.new()
	board_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	board_label.add_theme_font_size_override("font_size", 13)
	board_label.add_theme_color_override("font_color", Color(0.78, 0.9, 0.92))
	library_box.add_child(board_label)
	score_button = Button.new()
	score_button.custom_minimum_size = Vector2(240, 42)
	score_button.add_theme_font_size_override("font_size", 14)
	score_button.pressed.connect(_publish_score)
	library_box.add_child(score_button)

	library_box.add_child(_make_section_title("ARQUIVO DE CARDS", Color(1.0, 0.86, 0.45)))
	library_box.add_child(_make_section_hint("Toda arte que a loja já viu. Conquista entrega pacote brinde; o resto se compra no balcão."))
	var gallery := GridContainer.new()
	gallery.columns = 4
	gallery.add_theme_constant_override("h_separation", 8)
	gallery.add_theme_constant_override("v_separation", 8)
	library_box.add_child(gallery)
	for card in Cards.DATA:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(120, 96)
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.05, 0.04, 0.08, 0.92)
		slot_style.border_color = Cards.color_of(card)
		slot_style.set_border_width_all(1)
		slot_style.set_corner_radius_all(8)
		slot_style.content_margin_left = 6
		slot_style.content_margin_right = 6
		slot_style.content_margin_top = 4
		slot_style.content_margin_bottom = 4
		slot.add_theme_stylebox_override("panel", slot_style)
		gallery.add_child(slot)
		var slot_text := Label.new()
		slot_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_text.add_theme_font_size_override("font_size", 11)
		slot_text.clip_contents = true
		slot.add_child(slot_text)
		card_gallery_labels.append(slot_text)

	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size.x = 360
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.clip_contents = true
	body.add_child(right_scroll)

	var right_panel := PanelContainer.new()
	right_panel.clip_contents = true
	var right_panel_style := StyleBoxFlat.new()
	# Vidro fumê, não parede: o salão continua lendo-se através do quadro, mas o
	# contraste basta para ele parecer o lugar onde se lê a conversa.
	right_panel_style.bg_color = Color(0.025, 0.018, 0.055, 0.70)
	right_panel_style.border_color = Color(0.43, 0.25, 0.68, 0.85)
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
	right_title_label = shop_title
	shop_title.text = "RECEPÇÃO • A CHEFE"
	shop_title.add_theme_font_size_override("font_size", 22)
	shop_title.add_theme_color_override("font_color", Color(1.0, 0.78, 0.9))
	right.add_child(shop_title)

	# O objetivo atual mora no painel lateral: a coluna da esquerda troca de
	# setor, e o jogador precisa ver para onde a campanha está empurrando.
	campaign_line = Label.new()
	campaign_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_line.add_theme_font_size_override("font_size", 14)
	campaign_line.add_theme_color_override("font_color", Color(0.82, 1.0, 0.86))
	right.add_child(campaign_line)

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
	footer.text = "Protótipo 0.6 • Loja mágica, negócios duvidosos • Facções, fregueses e contratos • Conteúdo sensual opcional"
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

func _make_sector_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	return box

func _make_section_title(title_text: String, title_color: Color) -> Label:
	var label := Label.new()
	label.text = title_text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", title_color)
	return label

func _make_section_hint(hint_text: String) -> Label:
	var label := Label.new()
	label.text = hint_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.75, 0.71, 0.81))
	return label

func _make_sector_card(card_bg: Color, card_border: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = card_bg
	style.border_color = card_border
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	return card

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
		market_toggle_button.text = "☰ Ocultar" if market_panel.visible else "☰ Abrir"
	audio.play("click")
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

func _activate_sector_feature() -> void:
	if current_sector == "library":
		var xp_reward := 6 + library_upgrade_level * 3
		_add_xp(xp_reward)
		reputation += 1
		last_event = "Você consulta um grimório vivo. Ele revela uma margem secreta e concede +%d XP." % xp_reward
		audio.play("rare")
		_show_feedback("Conhecimento aplicado.", Color(0.70, 0.90, 1.0))
	elif current_sector == "sanctum":
		var affinity_reward := 2 + sanctum_upgrade_level
		_add_affection(affinity_reward)
		fury = maxi(0, fury - 1)
		_update_demonic_form()
		last_event = "Você acalma uma relíquia inquieta. A succubus recupera %d pontos de afinidade." % affinity_reward
		audio.play("happy")
		_show_feedback("Relíquia harmonizada.", Color(0.86, 0.60, 1.0))
	else:
		last_event = "Escolha Biblioteca ou Santuário para interagir com um cenário do fundo."
	_check_achievements()
	_save_game()
	_refresh_ui()

## Fundo do setor. Onde existe uma arte de sala vazia ela vira palco e o elenco
## anda; onde só existe o close de um rosto, o elenco fica nos bastidores, porque
## personagem caminhando por cima de uma cara enorme lê como fantasma.
func _sector_scene(sector: String) -> Dictionary:
	var room := "res://assets/shop_scene.png"
	var close := ""
	if sector == "forge":
		room = "res://assets/forge_scene.png"
		close = "res://assets/forge_close_scene.png"
	elif sector == "library":
		room = "res://assets/library_room_scene.png"
		close = "res://assets/library_close_scene.png"
	elif sector == "sanctum":
		room = "res://assets/sanctum_room_scene.png"
		close = "res://assets/sanctum_close_scene.png"
	if ResourceLoader.exists(room):
		return {"path": room, "walkable": true}
	if not close.is_empty() and ResourceLoader.exists(close):
		return {"path": close, "walkable": false}
	return {"path": "res://assets/shop_scene.png", "walkable": true}

func _set_sector(sector: String) -> void:
	current_sector = sector
	var is_forge := sector == "forge"
	var is_reception := sector == "reception"
	var is_library := sector == "library"
	var is_sanctum := sector == "sanctum"
	var is_expedition := sector == "expedition"
	if is_instance_valid(background_layer):
		# A arte pintada da chefe na vitrine continua aparecendo de vez em quando;
		# quando ela entra em cena, a chefe animada do salão sai para não duplicá-la.
		var painted_art := "res://assets/reception_scene_flirty.png" if adult_content_enabled else "res://assets/reception_scene.png"
		var painted_host := is_reception and randi() % 100 < 22 and ResourceLoader.exists(painted_art)
		var scene := _sector_scene(sector) if not painted_host else {"path": painted_art, "walkable": false}
		background_layer.texture = load(scene["path"])
		if is_instance_valid(stage_layer):
			_show_stage_for_room(str(scene["path"]), bool(scene["walkable"]))
	if is_instance_valid(ambient_particles):
		ambient_particles.color = Color(1.0, 0.43, 0.16, 0.46) if is_forge else Color(0.36, 0.72, 1.0, 0.38) if is_library else Color(0.73, 0.30, 1.0, 0.42) if is_sanctum else Color(0.45, 0.95, 0.6, 0.4) if is_expedition else Color(0.85, 0.35, 1.0, 0.34)
	_apply_sector_visibility()
	if is_instance_valid(sector_title_label):
		sector_title_label.text = "RECEPÇÃO • MERCADO E BALCÃO" if is_reception else "FORJA & OFICINA" if is_forge else "BIBLIOTECA ARCANA" if is_library else "EXPEDIÇÕES & RARIDADES" if is_expedition else "SANTUÁRIO DE ARTEFATOS"
	if is_instance_valid(sector_hint_label):
		sector_hint_label.text = "Compre ingredientes e venda itens no balcão. Os clientes chegam sozinhos para negociar." if is_reception else "Aqui apenas se fabrica: o ferreiro transforma ingredientes e ouro em mercadorias." if is_forge else "Aperfeiçoe talentos e adiante receitas presas ao nível." if is_library else "Nem tudo tem fornecedor. Mande o batedor buscar e torça pelo caminho de volta." if is_expedition else "Relíquias carregadas de magia aguardam uma negociação cuidadosa."
	if is_instance_valid(market_toggle_button):
		market_toggle_button.text = "☰ Ocultar" if is_instance_valid(market_panel) and market_panel.visible else "☰ Abrir"
	if is_instance_valid(right_title_label):
		var sector_word := "SANTUÁRIO"
		if is_reception:
			sector_word = "RECEPÇÃO"
		elif is_forge:
			sector_word = "FORJA"
		elif is_library:
			sector_word = "BIBLIOTECA"
		elif is_expedition:
			sector_word = "EXPEDIÇÕES"
		right_title_label.text = "%s • A CHEFE" % sector_word
	if is_instance_valid(reception_button):
		reception_button.disabled = is_reception
	if is_instance_valid(forge_button):
		forge_button.disabled = is_forge
	if is_instance_valid(library_button):
		library_button.disabled = is_library
	if is_instance_valid(sanctum_button):
		sanctum_button.disabled = is_sanctum
	if is_instance_valid(expedition_button):
		expedition_button.disabled = is_expedition
	var sector_message := "A forja está em atividade." if is_forge else "Os grimórios sussurram novas receitas." if is_library else "O santuário pulsa com artefatos inquietos." if is_sanctum else "O batedor está de botas calçadas." if is_expedition else "A recepção voltou ao foco."
	_show_feedback(sector_message, Color(1.0, 0.82, 0.48) if is_forge else Color(0.70, 0.90, 1.0) if is_library else Color(0.86, 0.60, 1.0) if is_sanctum else Color(0.55, 0.95, 0.7) if is_expedition else Color(1.0, 0.78, 0.9))

func _apply_sector_visibility() -> void:
	# Uma caixa por setor: fabricar só na forja, comprar e vender só na recepção,
	# talentos e receitas só na biblioteca.
	if is_instance_valid(reception_box):
		reception_box.visible = current_sector == "reception"
	if is_instance_valid(forge_box):
		forge_box.visible = current_sector == "forge"
	if is_instance_valid(library_box):
		library_box.visible = current_sector == "library"
	if is_instance_valid(sanctum_box):
		sanctum_box.visible = current_sector == "sanctum"
	if is_instance_valid(expedition_box):
		expedition_box.visible = current_sector == "expedition"
	if is_instance_valid(scene_action_box):
		scene_action_box.visible = current_sector == "library" or current_sector == "sanctum"

func _play_sensual_reception_moment() -> void:
	if not adult_content_enabled or not is_instance_valid(seller_portrait):
		return
	_seller_lean_in()
	_show_stage_emotion(stage_seller_body, "ousadia")
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
	_show_stage_emotion(stage_seller_body, "beijo")
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
	audio.play("talent")
	_show_feedback("♥ Pose especial desbloqueada!", Color(1.0, 0.62, 0.88))

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

func _apply_music_settings() -> void:
	if is_instance_valid(mute_button):
		mute_button.text = "🔇" if audio.muted else "🔊"
	if is_instance_valid(music_player):
		music_player.stream_paused = audio.muted
		music_player.volume_db = -13.0 + linear_to_db(maxf(audio.volume, 0.0001))

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
		last_event = "Essa receita ainda está bloqueada. Suba de nível ou pague a leitura na biblioteca."
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
	duration /= Sanctum.scale(active_buffs, "craft")
	var catalyst := _take_catalyst()
	var job_luck := int(catalyst.get("catalyst_luck", 0))
	craft_jobs.append({"index": index, "remaining": maxf(3.0, duration), "luck": job_luck})
	last_event = "Forja iniciada: %s levará %.1fs de tempo de mundo." % [item["name"], maxf(3.0, duration)]
	if not catalyst.is_empty():
		last_event += " %s virou pó dentro da forma: a peça sai com mais sorte." % str(catalyst["name"])
	audio.play("click")
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
		daily_crafts += 1
		total_crafted += 1
		_add_xp(5)
		_progress_daily_quest("craft", 1)
		# Alquimia, biblioteca e bênçãos do santuário empurram a rolagem de qualidade.
		var luck := alchemy_rank + Sanctum.luck_bonus(active_buffs) + int(round(float(library_upgrade_level) * 0.5)) + int(job.get("luck", 0))
		if int(job.get("luck", 0)) > 0:
			catalyst_crafted += 1
		var tier := Quality.roll(luck)
		_add_piece(index, tier)
		Economy.bump(economy_state, "product", str(item["id"]), -0.10)
		var quality_name := str(Quality.tier(tier)["name"])
		if tier >= 3:
			premium_crafted += 1
			best_quality_crafted = maxi(best_quality_crafted, tier)
			last_event = "%s saiu %s! A chefe inspeciona a peça, finge surpresa e aumenta a etiqueta." % [item["name"], quality_name]
			audio.play("rare")
			_show_feedback("✦ Peça %s!" % quality_name, Color(str(Quality.tier(tier)["color"])))
			_show_stage_emotion(stage_seller_body, "aplausao")
		else:
			last_event = "Produzido: %s (%s). O ferreiro bateu o martelo e pediu aplausos." % [item["name"], quality_name]
			audio.play("craft")
			_show_feedback("Produto pronto para vender.")
			_show_stage_emotion(stage_seller_body, "curiosidade")
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

## Vagas de batedor na folha de pagamento. Logística 2 paga o segundo de estrada.
func _expedition_slots() -> int:
	return 2 if logistics_rank >= 2 else 1

func _expedition_luck() -> int:
	return alchemy_rank + logistics_rank + Sanctum.luck_bonus(active_buffs)

func _expedition_on_route(id: String) -> Dictionary:
	for trip in expeditions:
		if str(trip.get("id", "")) == id:
			return trip
	return {}

func _bar(progress: float) -> String:
	var filled := clampi(int(round(progress * 8.0)), 0, 8)
	return "█".repeat(filled) + "░".repeat(8 - filled)

func _start_expedition(id: String) -> void:
	var destination := Expedition.find(id)
	if destination.is_empty():
		return
	if not Expedition.is_unlocked(destination, shop_day):
		last_event = "%s ainda não está no mapa da loja. %s." % [destination["name"], Expedition.locked_hint(destination)]
		_refresh_ui()
		return
	if expeditions.size() >= _expedition_slots():
		last_event = "Só há %d batedor(es) contratados. Aperfeiçoe Logística para abrir outra vaga." % _expedition_slots()
		_refresh_ui()
		return
	var cost := Expedition.cost_for(destination, logistics_rank)
	if gold < cost:
		last_event = "A passagem custa %d ouro. Sem adiantamento o batedor nem calça a bota." % cost
		_refresh_ui()
		return
	gold -= cost
	var duration := Expedition.duration_for(destination, logistics_rank)
	expeditions.append({"id": id, "remaining": duration, "total": duration})
	last_event = "%s partiu com %d ouro de passagem e volta em %s." % [destination["name"], cost, Expedition.days_label(duration)]
	audio.play("click")
	_show_feedback("🧭 Expedição iniciada.", Color(0.55, 0.95, 0.7))
	_save_game()
	_refresh_ui()

func _advance_expeditions(game_seconds: float) -> void:
	if expeditions.is_empty():
		return
	var arrived: Array[Dictionary] = []
	for trip in expeditions:
		trip["remaining"] = float(trip.get("remaining", 0.0)) - game_seconds
		if float(trip["remaining"]) <= 0.0:
			arrived.append(trip)
	for trip in arrived:
		expeditions.erase(trip)
		_finish_expedition(trip)

func _finish_expedition(entry: Dictionary) -> void:
	var destination := Expedition.find(str(entry.get("id", "")))
	if destination.is_empty():
		return
	var luck := _expedition_luck()
	var loot := Expedition.roll_loot(destination, luck)
	var mishap := Expedition.roll_mishap(destination, luck)
	if str(mishap.get("kind", "")) == "perda":
		loot.clear()
	var parts: Array[String] = []
	for drop in loot:
		var drop_id := str(drop["id"])
		var count := int(drop["count"])
		ingredient_stock[drop_id] = int(ingredient_stock.get(drop_id, 0)) + count
		# Carga extra no estoque caseiro esfria o mercado daquele ingrediente.
		Economy.bump(economy_state, "ingredient", drop_id, -0.05 * float(count))
		parts.append("%s x%d" % [Expedition.ingredient_name(drop_id), count])
		if Ingredients.is_rare(drop_id):
			rare_found += 1
	expeditions_done += 1
	_add_xp(9 + int(round(float(destination["danger"]) / 5.0)))
	var text := "%s voltou de mãos abanando. A loja finge que não viu." % destination["name"] if parts.is_empty() else "%s retornou com: %s." % [destination["name"], ", ".join(parts)]
	match str(mishap.get("kind", "")):
		"furia":
			fury = mini(5, fury + 1)
			_update_demonic_form()
		"reputacao":
			reputation = maxi(0, reputation - 2)
	if not mishap.is_empty():
		text += " " + str(mishap["text"])
		_show_stage_emotion(stage_seller_body, "dor")
	expedition_log.push_front(text)
	while expedition_log.size() > 4:
		expedition_log.pop_back()
	last_event = text
	if parts.is_empty():
		audio.play("sad")
	else:
		audio.play("rare" if mishap.is_empty() else "coin")
		_show_feedback("✦ Botim chegou!", Color(1.0, 0.86, 0.45))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Raridade mais fraca em estoque: guarda a brasa boa para peça grande.
func _catalyst_available() -> Dictionary:
	for rare in Ingredients.RARE_DATA:
		if int(ingredient_stock.get(str(rare["id"]), 0)) > 0:
			return rare
	return {}

func _toggle_catalyst() -> void:
	if not catalyst_enabled and _catalyst_available().is_empty():
		last_event = "Nenhuma raridade na prateleira. Mande uma expedição e torça pelo caminho."
		_refresh_ui()
		return
	catalyst_enabled = not catalyst_enabled
	last_event = "Catalisador armado: a próxima forja queima uma raridade por peça melhor." if catalyst_enabled else "Catalisador desarmado. A forja volta a trabalhar pelo preço de tabela."
	audio.play("click")
	_refresh_ui()

## Queima a raridade escolhida e devolve a sorte que ela entrega na rolagem.
func _take_catalyst() -> Dictionary:
	if not catalyst_enabled:
		return {}
	var picked: Dictionary = _catalyst_available()
	if picked.is_empty():
		catalyst_enabled = false
		return {}
	var picked_id := str(picked["id"])
	ingredient_stock[picked_id] = int(ingredient_stock.get(picked_id, 0)) - 1
	return picked

## Barrinha de qualidade do produto, criada sob demanda para saves antigos que
## nunca tiveram `quality_stock` e para peças ganhas por eventos.
func _quality_for(product_id: String) -> Array[int]:
	if not quality_stock.has(product_id):
		quality_stock[product_id] = Quality.empty_stock()
	return quality_stock[product_id] as Array[int]

## Peças que já existiam em saves antigos entram no registro como "Honesto";
## nenhum estoque fica órfão do espectro de qualidade.
func _sync_quality_stock() -> void:
	for i in range(products.size()):
		var item: Dictionary = products[i]
		var counts := _quality_for(str(item["id"]))
		var held := maxi(0, int(item["stock"]))
		var registered := Quality.total(counts)
		if registered < held:
			counts[1] = int(counts[1]) + (held - registered)
		elif registered > held:
			var excess := registered - held
			for level in range(Quality.size()):
				if excess <= 0:
					break
				var cut := mini(int(counts[level]), excess)
				counts[level] = int(counts[level]) - cut
				excess -= cut
			item["stock"] = Quality.total(counts)

func _add_piece(index: int, tier: int) -> void:
	var item: Dictionary = products[index]
	item["stock"] = int(item["stock"]) + 1
	var stock := _quality_for(str(item["id"]))
	stock[tier] = int(stock[tier]) + 1

## O diabrete contratado não tira poção do chapéu: ele revira a despensa e usa a
## primeira matéria-prima que encontra. Sem estoque ele reclama e não produz,
## porque fabricar do nada deixava a forja e o mercado de ingredientes sem função.
func _imp_work() -> void:
	var supply := ""
	for ingredient_id in ingredient_stock.keys():
		if int(ingredient_stock[ingredient_id]) > 0:
			supply = str(ingredient_id)
			break
	if supply.is_empty():
		last_event = "Seu diabrete deu de ombros: despensa vazia, nem ele inventa poção."
		return
	ingredient_stock[supply] = int(ingredient_stock[supply]) - 1
	_add_piece(0, 1)
	last_event = "Seu diabrete fabricou uma poção com sobras de %s. Ele perguntou se isso conta como experiência profissional." % supply

## Tira uma peça da prateleira e devolve o nível dela. Clientes comuns e o balcão
## levam a pior; ladrão e conhecedores escolhem a melhor. Peças anteriores ao
## sistema de qualidade saem como "Honesto" e não alteram o registro.
func _take_piece(index: int, mode: int) -> int:
	var item: Dictionary = products[index]
	item["stock"] = maxi(0, int(item["stock"]) - 1)
	var stock := _quality_for(str(item["id"]))
	var tier := Quality.take(stock, mode)
	return 1 if tier < 0 else tier

## Etiqueta da peça: preço base do catálogo multiplicado pelo nível de qualidade.
func _piece_price(item: Dictionary, tier: int) -> float:
	return float(item["price"]) * float(Quality.tier(tier)["mult"])

## Olha a peça que sairia sem tirar da prateleira. Serve para a fila decidir o que
## cabe no bolso antes de a venda consumir o estoque.
func _peek_tier(index: int, mode: int) -> int:
	var stock := _quality_for(str(products[index]["id"]))
	for i in range(Quality.size()):
		var candidate := i if mode == Quality.WORST else Quality.size() - 1 - i
		if int(stock[candidate]) > 0:
			return candidate
	return 1

## Preço de vitrine de um produto: peça provável vezes o humor do mercado.
func _shelf_price(index: int) -> int:
	var item: Dictionary = products[index]
	return maxi(1, int(round(_piece_price(item, _peek_tier(index, Quality.WORST)) * _market_product_factor(item))))

## O mercado reativo sobre a etiqueta: demanda do produto e escassez na prateleira.
func _market_product_factor(item: Dictionary) -> float:
	var product_id := str(item["id"])
	return Economy.factor(economy_state, "product", product_id) * Economy.stock_factor(int(item["stock"]))

## Estimativa conservadora: etiqueta de uma peça Honesta no mercado de hoje,
## menos custo de fabricação e preço atual de reposição dos ingredientes.
func _estimated_margin(item: Dictionary) -> int:
	var craft_cost := maxi(1, int(round(float(item["cost"]) * (1.0 - 0.05 * alchemy_rank))))
	var ingredient_cost := 0
	var recipe: Dictionary = item.get("ingredients", {})
	for ingredient_id in recipe.keys():
		ingredient_cost += _ingredient_price(str(ingredient_id)) * int(recipe[ingredient_id])
	return int(round(_piece_price(item, 1) * _market_product_factor(item))) - craft_cost - ingredient_cost

func _ingredient_price(ingredient_id: String) -> int:
	var base := float(Ingredients.price_for_day(ingredient_id, shop_day))
	base *= Economy.factor(economy_state, "ingredient", ingredient_id)
	base *= (1.0 - 0.05 * float(logistics_rank))
	return maxi(1, int(round(base)))

func _buy_ingredient(ingredient_id: String) -> void:
	var price := _ingredient_price(ingredient_id)
	if gold < price:
		last_event = "O fornecedor riu da sua oferta. Falta ouro para %s." % str(Ingredients.find(ingredient_id).get("name", ingredient_id))
		_refresh_ui()
		return
	gold -= price
	ingredient_stock[ingredient_id] = int(ingredient_stock.get(ingredient_id, 0)) + 1
	total_ingredients_bought += 1
	# Toda compra aquece o mercado daquele ingrediente: comprar demais encarece.
	Economy.bump(economy_state, "ingredient", ingredient_id, 0.14)
	last_event = "Comprado: %s por %d ouro. O fornecedor jurou que era o preço de amigo." % [str(Ingredients.find(ingredient_id).get("name", ingredient_id)), price]
	audio.play("buy")
	_show_feedback("Ingrediente adicionado ao estoque.", Color(0.78, 0.95, 1.0))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Revender ingrediente recupera só 60% do preço do dia: o mercado aceita tudo,
## mas paga como devolução.
func _sell_ingredient(ingredient_id: String) -> void:
	if int(ingredient_stock.get(ingredient_id, 0)) <= 0:
		last_event = "Nada para revender: %s acabou do estoque." % str(Ingredients.find(ingredient_id).get("name", ingredient_id))
		_refresh_ui()
		return
	var payout := maxi(1, int(round(float(_ingredient_price(ingredient_id)) * 0.6)))
	ingredient_stock[ingredient_id] = int(ingredient_stock.get(ingredient_id, 0)) - 1
	# Devolver material ao mercado cria oferta e derruba a etiqueta dele.
	Economy.bump(economy_state, "ingredient", ingredient_id, -0.12)
	gold += payout
	daily_gold_earned += payout
	_progress_daily_quest("gold", payout)
	last_event = "Revendido: %s por %d ouro. O fornecedor fingiu que não viu." % [str(Ingredients.find(ingredient_id).get("name", ingredient_id)), payout]
	audio.play("coin")
	_show_feedback("Material devolvido ao mercado.", Color(0.78, 0.95, 1.0))
	_save_game()
	_refresh_ui()

## Venda no balcão: ouro certo e imediato por 70% da etiqueta da peça, sem
## reputação, vínculo nem bônus de facção. Serve para girar estoque enquanto a
## fila não vem. A prateleira empurrada desvaloriza o produto.
func _sell_from_counter(index: int) -> void:
	var item: Dictionary = products[index]
	if int(item["stock"]) <= 0:
		last_event = "Prateleira vazia: %s só existe na sua imaginação." % item["name"]
		_refresh_ui()
		return
	var tier := _take_piece(index, Quality.WORST)
	var payout := maxi(1, int(round(_piece_price(item, tier) * _market_product_factor(item) * 0.7)))
	Economy.bump(economy_state, "product", str(item["id"]), 0.12)
	gold += payout
	daily_gold_earned += payout
	_progress_daily_quest("gold", payout)
	last_event = "Venda no balcão: %s %s por %d ouro. Levou sem agradecer, mas pagou." % [item["name"], str(Quality.tier(tier)["name"]).to_lower(), payout]
	audio.play("coin")
	_show_feedback("+%d ouro no balcão." % payout, Color(1.0, 0.86, 0.45))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Ouro adianta uma receita presa ao nível; cada nível da biblioteca corta 10%
## do preço da leitura.
func _recipe_cost(index: int) -> int:
	var required := int(products[index].get("required_level", 1))
	return maxi(20, int(round(float(70 + required * 55) * (1.0 - 0.10 * library_upgrade_level))))

func _learn_recipe(index: int) -> void:
	var item: Dictionary = products[index]
	var recipe_id := str(item["id"])
	if known_recipes.has(recipe_id) or _is_product_unlocked(item):
		last_event = "Essa receita já está decorada. O grimório exige novidades."
		_refresh_ui()
		return
	var cost := _recipe_cost(index)
	if gold < cost:
		last_event = "A leitura custa %d ouro. Sem ouro, a tampa fecha sozinha." % cost
		_refresh_ui()
		return
	gold -= cost
	known_recipes.append(recipe_id)
	_add_xp(6)
	last_event = "Receita aprendida: %s! O pergaminho virou faísca roxa e a prateleira anotou." % item["name"]
	audio.play("rare")
	_show_feedback("✦ Nova receita dominada!", Color(0.70, 0.90, 1.0))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Produto em alta: o mais procurado no mercado reativo. Sem demanda clara de
## ninguém, cai no sorteio determinístico do dia para sempre existir um destaque.
func _demand_index() -> int:
	var ids: Array[String] = []
	for item in products:
		ids.append(str(item["id"]))
	var hottest := Economy.hottest(economy_state, "product", ids)
	if not hottest.is_empty():
		var index := _product_index(hottest)
		if index >= 0:
			return index
	return posmod(abs(hash("demanda:%d" % shop_day)), products.size())

## Calor máximo entre os produtos: usado pela conquista do termômetro.
func _max_product_heat() -> float:
	var best := 0.0
	for item in products:
		best = maxf(best, Economy.heat(economy_state, "product", str(item["id"])))
	return best

## Ritual do santuário: buff entra na lista com a duração escalada pelo nível,
## alívio resolve a penalidade na hora.
func _perform_ritual(ritual_id: String) -> void:
	var item := Sanctum.find(ritual_id)
	if item.is_empty():
		return
	var cost := Sanctum.cost_for(item, sanctum_upgrade_level)
	if gold < cost:
		last_event = "%s custa %d de ouro. A relíquia boceja e volta a dormir." % [item["name"], cost]
		_refresh_ui()
		return
	var kind := str(item.get("kind", "buff"))
	if kind == "buff" and Sanctum.is_active(active_buffs, ritual_id):
		last_event = "%s ainda está queimando. Rezar duas vezes não acende a mesma vela." % item["name"]
		_refresh_ui()
		return
	if kind == "relief":
		var resolved := _apply_ritual_relief(item)
		if not resolved:
			return
	gold -= cost
	if kind == "buff":
		Sanctum.start(active_buffs, ritual_id, sanctum_upgrade_level)
	rituals_performed += 1
	_add_xp(4)
	last_event = "Ritual concluído: %s. O santuário estala, cheira a enxofre doce e a loja sente o efeito." % item["name"]
	audio.play("rare")
	_show_feedback("✦ %s ativo." % item["name"], Color(0.86, 0.60, 1.0))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Rituais de alívio só funcionam sobre penalidade real; cada um retorna false
## quando não há nada a consertar, e o ouro fica no bolso.
func _apply_ritual_relief(item: Dictionary) -> bool:
	var ritual_id := str(item["id"])
	if ritual_id == "penitencia":
		if fury <= 0:
			last_event = "Nenhuma fúria para dissolver: a chefe está de bom humor demais para a penitência."
			_refresh_ui()
			return false
		fury = maxi(0, fury - int(item.get("fury", 0)))
		_update_demonic_form()
		return true
	if ritual_id == "perdao_vendido":
		if reputation >= 5:
			last_event = "O perdão só vende para quem deve. Sua reputação já está acima da média."
			_refresh_ui()
			return false
		reputation += int(item.get("rep", 0))
		return true
	if ritual_id == "rastro_sagrado":
		if not theft_recovery_available or stolen_item_name.is_empty():
			last_event = "O rastro sagrado não pega cheiro de furto recente."
			_refresh_ui()
			return false
		_recover_stolen_item()
		return true
	return true

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

## Ids são estáveis; a ordem de `products` pode mudar entre versões sem quebrar
## o favorito de um freguês. Retorna -1 quando o produto não existe no catálogo.
func _product_index(product_id: String) -> int:
	for i in range(products.size()):
		if str(products[i].get("id", "")) == product_id:
			return i
	return -1

## Escolhe o freguês do próximo turno. O peso cai conforme o vínculo sobe, então
## quem ainda não foi visitado domina a fila: ampliar o elenco não dilui a
## frequência de cada personagem nem atrasa os capítulos.
func _pick_regular() -> Dictionary:
	var weights: Array[float] = []
	var total_weight := 0.0
	for candidate in Regulars.DATA:
		var candidate_bond := int(regular_bonds.get(str(candidate["id"]), 0))
		var weight := 1.0 / float(candidate_bond + 2)
		weights.append(weight)
		total_weight += weight
	var roll := randf() * total_weight
	for i in range(weights.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return Regulars.DATA[i]
	return Regulars.DATA[0]

func _on_customer_tick() -> void:
	ticks += 1
	_stage_customer_leaves()
	_advance_craft_jobs(3.0)
	Sanctum.advance(active_buffs, 3.0)
	_advance_expeditions(3.0)
	_set_seller_mood("demonic" if demonic_form_active else "neutral")
	if is_instance_valid(reaction_label):
		reaction_label.text = ""
	if ticks % 20 == 0:
		shop_day += 1
		_show_stage_emotion(stage_seller_body, "sono")
		Economy.advance_day(economy_state)
		daily_quest_index = (daily_quest_index + 1) % 4
		daily_quest_progress = 0
		daily_quest_claimed = false
		daily_gold_earned = 0
		daily_crafts = 0
		# Fechou o dia, fechou o balanço: o placar recebe o resultado da virada.
		best_score = maxi(best_score, business_score())
		if steam != null:
			steam.call("submit_score", business_score(), "Sua loja")
		# O dia vira uma vez e o recorde nasce nesse instante: sem gravar aqui,
		# quem fecha o jogo sem mover mais nada perde a virada.
		_save_game()
		last_event = "Dia %d começou! Um novo contrato está disponível; o anterior expirou. %s" % [shop_day, Economy.report(economy_state, products, Ingredients.DATA)]
	if imp_hired and ticks % 3 == 0:
		_imp_work()

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
		# Prateleira vazia também é cena: quem bate na porta é um dos fregueses,
		# e cada um deles já tem uma reclamação escrita para este momento exato.
		var visitor: Dictionary = _pick_regular()
		var grumble := str(visitor.get("empty", "“Sem nada na prateleira? Eu volto... quem sabe.”"))
		_animate_customer_arrival({
			"name": visitor["name"],
			"portrait": int(visitor.get("portrait", 2)),
			"faction": str(visitor.get("faction", "mercadores"))
		})
		_set_customer_status("CLIENTE: foi embora")
		_set_seller_mood("surprised")
		last_event = "%s entrou, viu as prateleiras vazias e foi comprar em outro plano de existência. %s Reabasteça a loja para não perder vendas." % [visitor["short"], grumble]
		_react_to_visit("disappointed", randi() % 100 < 15 * charm_rank)
	else:
		var profiles: Array[Dictionary] = [
			{"name": "Speedrunner", "favorite": "caixa_misteriosa", "line": "“Compra feita. Onde fica o botão de pular diálogo?”", "faction": "aventureiros", "portrait": 0, "budget": 75, "patience": 1},
			{"name": "Especialista em Tudo", "favorite": "dano_emocional", "line": "“Vi um tutorial de 12 segundos e agora sou consultor.”", "faction": "guildas", "portrait": 1, "budget": 48, "patience": 2},
				{"name": "Gótico Econômico", "favorite": "lagrimas_jogador", "line": "“Minhas lágrimas são artesanais. As suas têm desconto?”", "faction": "submundo", "portrait": 2, "budget": 90, "patience": 3},
				{"name": "Mago do Quero Mana", "favorite": "frasco_motivacao", "line": "“Quero manaaa! Isso aqui é uma porcaria... me vê duas poções mesmo assim.”", "faction": "guildas", "portrait": 1, "budget": 120, "patience": 2},
				{"name": "Fiscal do Pix Astral", "favorite": "incenso_teleporte", "line": "“Aceita Pix astral? Se não aceitar, vou pagar em promessa e reclamar no fórum.”", "faction": "mercadores", "portrait": 6, "budget": 115, "patience": 2},
				{"name": "Só Mais Uma Run", "favorite": "caixa_misteriosa", "line": "“É rapidinho, só mais uma compra. Dessa vez eu paro antes do amanhecer.”", "faction": "aventureiros", "portrait": 3, "budget": 100, "patience": 1},
				{"name": "Ladino do Ctrl+C", "favorite": "dano_emocional", "line": "“Vi isso em outro lugar. Vou levar o seu, porque parece mais fácil.”", "faction": "submundo", "portrait": 4, "budget": 70, "patience": 2, "thief": true},
				{"name": "Cliente do É Sobre Isso", "favorite": "confianca_instantanea", "line": "“É sobre isso e está tudo bem. Mas se tiver desconto, fica ainda mais sobre isso.”", "faction": "nobres", "portrait": 0, "budget": 150, "patience": 3},
				{"name": "Colecionador de Patos", "favorite": "pato_amaldicoado", "line": "“Este pato combina com os outros 47 que não me julgam.”", "faction": "mercadores", "portrait": 8, "budget": 42, "patience": 2},
				{"name": "Coach Interdimensional", "favorite": "confianca_instantanea", "line": "“Acredite no seu potencial! Meu boleto acredita em mim.”", "faction": "guildas", "portrait": 5, "budget": 125, "patience": 3},
				{"name": "Cliente Misterioso", "favorite": "", "line": "“Não nos conhecemos. Se nos conhecemos, não se lembra.”", "faction": "nobres", "portrait": 9, "budget": 60, "patience": 1},
				{"name": "Bardo do Duplo Sentido", "favorite": "confianca_instantanea", "line": "“Se essa poção for tão quente quanto seu sorriso, eu compro duas.”", "faction": "aventureiros", "portrait": 11, "budget": 110, "patience": 2},
				{"name": "Paladina do Caos", "favorite": "adaga_charme", "line": "“Prometi ser virtuosa hoje. Mas posso abrir uma exceção para você.”", "faction": "nobres", "portrait": 12, "budget": 145, "patience": 2},
				{"name": "Ladrão de Relíquias Sensíveis", "favorite": "pergaminho_procrastinacao", "line": "“Não estou roubando seu coração. Só testando se ele cabe no meu inventário.”", "faction": "submundo", "portrait": 4, "budget": 135, "patience": 1},
				{"name": "Bruxa em Lua de Mel", "favorite": "incenso_teleporte", "line": "“Meu familiar disse que você é perigosa. Por isso mesmo fiquei.”", "faction": "guildas", "portrait": 13, "budget": 180, "patience": 3},
				{"name": "Ferreiro do Estoque Infinito", "favorite": "martelo_faisca", "line": "“Vim comprar um martelo. Saí com três e uma opinião sobre os seus.”", "faction": "guildas", "portrait": 10, "budget": 165, "patience": 3},
				{"name": "Druida em Greve", "favorite": "elixir_memoria", "line": "“A floresta me manda dizer que está decepcionada com vocês dois.”", "faction": "aventureiros", "portrait": 14, "budget": 85, "patience": 2},
				{"name": "Capitã do Contrabando Afetivo", "favorite": "caixa_misteriosa", "line": "“Tudo que eu vendo é de procedência duvidosa e coração sincero.”", "faction": "mercadores", "portrait": 15, "budget": 210, "patience": 1, "thief": true}
			]
		var profile: Dictionary = profiles[randi() % profiles.size()]
		if randi() % 100 < 35:
			var regular: Dictionary = _pick_regular()
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
				"favorite": str(regular["favorite"]),
				"line": regular_line,
				"regular_id": regular_id,
				"portrait": int(regular["portrait"]),
				"tier": tier,
				"personal_request": personal_request,
				"faction": str(regular.get("faction", "aventureiros"))
			}
		_animate_customer_arrival(profile)
		var preferred_index: int = _product_index(str(profile["favorite"]))
		current_customer_budget = int(profile.get("budget", 50)) + trade_rank * 8
		current_customer_patience = maxi(1, int(round(float(int(profile.get("patience", 2)) + logistics_rank + Sanctum.patience_bonus(active_buffs) + distraction_pending) / world_speed())) - _fury_patience_loss())
		distraction_pending = 0
		var seduction_used := false
		if is_instance_valid(customer_emotion_label):
			customer_emotion_label.text = "🏃 pressa" if current_customer_patience <= 1 else "🙂 observando"
		if bool(profile.get("thief", false)) and current_customer_patience <= 1:
			if Sanctum.guards(active_buffs):
				last_event = "%s enfiou a mão na prateleira, mas o Selo da Cadeia estalou e a mão saiu vazia. Ele ainda pagou o que levou." % str(profile.get("name", "O cliente"))
				_show_feedback("⛓ Furto barrado pelo selo.", Color(0.75, 1.0, 0.72))
			else:
				_handle_thief_escape(profile, available)
				_check_achievements()
				_save_game()
				_refresh_ui()
				return
		var affordable: Array[int] = []
		for affordable_index in available:
			if _shelf_price(affordable_index) <= current_customer_budget:
				affordable.append(affordable_index)
		if affordable.is_empty():
			var charm_negotiation := adult_content_enabled and charm_rank > 0 and randi() % 100 < 25 + charm_rank * 12 + sanctum_upgrade_level * 5
			if charm_negotiation and available.size() > 0:
				seduction_used = true
				seduction_attempts += 1
				seduction_successes += 1
				current_customer_budget += 20 + charm_rank * 10
				_add_affection(2 + charm_rank)
				reputation += 1 + _reputation_seduction_bonus()
				last_event = "%s suspira: “Meu orçamento é curto...” %s O cliente reconsidera." % [profile["name"], SUCCUBUS_NEGOTIATION_LINES.pick_random()]
				for affordable_index in available:
					if _shelf_price(affordable_index) <= current_customer_budget:
						affordable.append(affordable_index)
			else:
				last_event = "%s não conseguiu pagar nenhum item e saiu %s: “Volto quando meu bolso parar de chorar.”" % [profile["name"], "com pressa" if current_customer_patience <= 1 else "frustrado"]
				disappointed_customers += 1
				reputation = maxi(0, reputation - 1)
				_set_customer_status("CLIENTE: saiu sem comprar")
				if is_instance_valid(customer_emotion_label):
					customer_emotion_label.text = "😤 frustração"
				_play_customer_reaction("broke")
				# O charme não bastou, e ela faz de conta que era teste de balcão.
				_show_stage_emotion(stage_seller_body, "vergonha")
				_check_achievements()
				_save_game()
				_refresh_ui()
				return
		var chosen_index: int = affordable[randi() % affordable.size()] if not affordable.is_empty() else available[randi() % available.size()]
		if preferred_index >= 0 and available.has(preferred_index) and randi() % 100 < 70:
			chosen_index = preferred_index
			# Ele viu o que queria do outro lado do salão e aponta antes de pedir.
			_show_stage_emotion(stage_customer, "aponta")
			if not seduction_used and adult_content_enabled and charm_rank > 0 and randi() % 100 < 8 + charm_rank * 5 + sanctum_upgrade_level * 3 and (preferred_index == chosen_index or current_customer_patience <= 1):
				seduction_used = true
				seduction_attempts += 1
				seduction_successes += 1
				_add_affection(1 + charm_rank + sanctum_upgrade_level)
				reputation += _reputation_seduction_bonus()

		var item: Dictionary = products[chosen_index]
		var piece_tier := _take_piece(chosen_index, Quality.WORST)
		var quality_name := str(Quality.tier(piece_tier)["name"])
		if piece_tier == 0:
			# Saiu torto da forja e o cliente viu: ninguém esconde a careta.
			_show_stage_emotion(stage_customer, "nojo")
		var base_label := _piece_price(item, piece_tier)
		var price_multiplier: float = (1.0 + 0.20 * ad_level) * (1.0 + 0.08 * trade_rank) * _reputation_price_multiplier() * _fury_price_multiplier() * Sanctum.scale(active_buffs, "price") * _market_product_factor(item)
		var preference_bonus := 0
		if preferred_index == chosen_index:
			preference_bonus = maxi(2, int(round(base_label * 0.25)))
			last_event = "%s comprou %s (%s) e pagou %d de bônus! %s" % [
				profile["name"], item["name"], quality_name, preference_bonus, profile["line"]
			]
		else:
			last_event = "%s comprou %s (%s). %s" % [
				profile["name"], item["name"], quality_name, profile["line"]
			]
		var sale_price: int = int(round(base_label * price_multiplier)) + preference_bonus
		var product_heat := Economy.heat(economy_state, "product", str(item["id"]))
		if product_heat >= 0.30:
			last_event += "\n%s está em alta: a etiqueta subiu %.0f%%." % [item["name"], product_heat * 100.0]
		elif product_heat <= -0.15:
			last_event += "\n%s está encalhado: o mercado pagou %.0f%% menos." % [item["name"], absf(product_heat) * 100.0]
		# Vender cria fila, e fila é sinal de demanda: a peça volta mais cara amanhã.
		Economy.bump(economy_state, "product", str(item["id"]), 0.22)
		var faction_id := str(profile.get("faction", ""))
		var faction_bonus := 0
		if not faction_id.is_empty():
			var faction_tier := Factions.tier_for(int(faction_standing.get(faction_id, 0)))
			faction_bonus = int(round(base_label * Factions.price_bonus(faction_tier)))
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
			reputation += 1 + (1 if seduction_used else 0)
		# A peça saiu da prateleira, o dinheiro entra no caixa. Até aqui só o
		# pedido especial pagava: a venda comum levava o item e devovia XP.
		gold += sale_price
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
		_add_affection(1 + charm_rank + sanctum_upgrade_level)
		_set_customer_status("CLIENTE: %s" % profile["name"])
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
				},
				{
					"name": "Mana, Mas Com Charme",
					"message": "O mago reclama da poção, a succubus responde com um sorriso e ele compra outra só para continuar a discussão.",
					"gold": 26, "reputation": 3, "queue_distraction": true
				},
				{
					"name": "Pix Astral Aprovado",
					"message": "O cristal de pagamento pede um elogio antes de aprovar a transação. A chefe entrega dois e a fila aplaude.",
					"gold": 24, "reputation": 2, "queue_distraction": true
				},
				{
					"name": "Última Run, Prometo",
					"message": "Um aventureiro promete que esta é a última compra. A succubus pisca: “Claro, querido. Eu também prometo.”",
					"gold": 20, "reputation": 2, "queue_distraction": true
				}
	]
	var event: Dictionary = events[randi() % events.size()]
	gold = maxi(0, gold + int(event["gold"]))
	reputation = maxi(0, reputation + int(event["reputation"]))
	rare_events_found += 1
	last_event = "EVENTO: %s! %s" % [event["name"], event["message"]]
	_show_stage_emotion(stage_customer, "confusao")
	if bool(event.get("queue_distraction", false)):
		queue_distractions += 1
		distraction_pending += 1 + sanctum_upgrade_level
		seduction_attempts += 1
		seduction_successes += 1
		_add_affection(2 + sanctum_upgrade_level)
		if is_instance_valid(customer_emotion_label):
			customer_emotion_label.text = "💘 distraído"
		_set_customer_status("CLIENTE: distraído pelo charme")
		_play_sensual_reception_moment()
	else:
		_show_stage_emotion(stage_seller_body, "pensativo")
	audio.play("rare")
	_show_feedback("Evento raro!", Color(1.0, 0.86, 0.45))
	if adult_content_enabled and affection >= 5 and randi() % 2 == 0:
		last_event += "\nA súcubo ri: “Nossa loja é um desastre adorável. Ainda bem que você está aqui, querido.”"

func _animate_customer_arrival(profile: Dictionary) -> void:
	if not is_instance_valid(customer_portrait):
		return
	var portrait_index := int(profile.get("portrait", -1))
	if portrait_index < 0 or portrait_index >= customer_portrait_paths.size():
		# Perfil sem retrato definido ainda ganha um rosto estável e próprio.
		portrait_index = abs(hash(str(profile.get("name", "")))) % customer_portrait_paths.size()
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
	# Mesmo rosto, mas em escala de cenário: ele entra andando e para no balcão.
	_stage_customer_arrives(portrait_index)

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

## Fúria tem preço: com a chefe nervosa o freguês pechincha e sai mais rápido.
## Cinco por cento de etiqueta por ponto, no máximo um quinto do balcão embora.
func _fury_price_multiplier() -> float:
	return 1.0 - 0.05 * clampi(fury, 0, 5)

func _fury_patience_loss() -> int:
	return clampi(fury, 0, 5) / 2

func _handle_thief_escape(profile: Dictionary, available: Array[int]) -> void:
	if available.is_empty():
		return
	var stolen_index := available[randi() % available.size()]
	var stolen_item: Dictionary = products[stolen_index]
	# Ladrão tem faro: leva a melhor peça da prateleira.
	stolen_tier = _take_piece(stolen_index, Quality.BEST)
	stolen_item_name = str(stolen_item["name"])
	theft_recovery_available = true
	fury = mini(5, fury + 2)
	_update_demonic_form()
	_set_customer_status("CLIENTE: ladrão escapou")
	if is_instance_valid(customer_emotion_label):
		customer_emotion_label.text = "🏃 ladrão"
	last_event = "%s pegou %s e correu! A succubus rosna: “Ninguém rouba da minha loja e sai sem deixar um recibo.”" % [profile.get("name", "O cliente"), stolen_item_name]
	_show_feedback("⚠ Roubo! O rastreador está pronto.", Color(1.0, 0.55, 0.45))
	audio.play("sad")
	_show_stage_emotion(stage_seller_body, "espanto")
	_play_customer_reaction("flee")

func _recover_stolen_item() -> void:
	if not theft_recovery_available or stolen_item_name.is_empty():
		last_event = "Nenhum item foi roubado. A succubus guarda o rastreador e finge que foi tudo planejado."
		_refresh_ui()
		return
	var stolen_index := -1
	for i in range(products.size()):
		if str(products[i].get("name", "")) == stolen_item_name:
			stolen_index = i
			break
	if stolen_index >= 0:
		_add_piece(stolen_index, clampi(stolen_tier, 0, Quality.size() - 1))
	theft_recovery_available = false
	last_event = "Rastreamento concluído: %s recuperado. O ladrão deixou um pedido de desculpas e uma gorjeta simbólica." % stolen_item_name
	stolen_item_name = ""
	fury = maxi(0, fury - 1)
	_update_demonic_form()
	audio.play("happy")
	_show_feedback("Item recuperado.", Color(0.75, 1.0, 0.72))
	_save_game()
	_refresh_ui()

## O status do balcão é a única linha que a lógica de visita escreve fora do
## refresh geral, e ela dispara em caminho que existe antes da UI montar (sonda
## headless, setor trocado). Ninguém deve travar por causa de um rótulo.
func _set_customer_status(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text

func _set_negotiation_dialogue(profile: Dictionary, item: Dictionary, seduction_used: bool, favorite_item: bool) -> void:
	if not is_instance_valid(seller_speech_label):
		return
	var customer_name := str(profile.get("name", "Aventureiro"))
	var customer_line := "“Isso parece exatamente o que eu precisava.”" if favorite_item else "“Não era meu primeiro plano, mas parece útil.”"
	if current_customer_patience <= 1:
		customer_line = "“Rápido, por favor. Tenho um dragão me esperando.”"
	if seduction_used:
		var flirt_line: String = str(MEME_FLIRT_LINES.pick_random() if customer_name in ["Mago do Quero Mana", "Fiscal do Pix Astral", "Só Mais Uma Run", "Ladino do Ctrl+C", "Cliente do É Sobre Isso"] else SUCCUBUS_NEGOTIATION_LINES.pick_random())
		seller_speech_label.text = "CHEFE: %s\n%s: %s" % [flirt_line, customer_name, customer_line]
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
			_show_stage_emotion(stage_seller_body, "risada")
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
				_show_stage_emotion(stage_seller_body, "tristeza")
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
			audio.play("happy")
			_show_feedback("♥ Cliente encantado!", Color(1.0, 0.78, 0.9))
		"disappointed":
			audio.play("sad")
			_show_feedback("Estoque vazio: cliente perdido.", Color(1.0, 0.55, 0.55))
		_:
			audio.play("coin")
			_show_feedback("Venda concluída.", Color(0.91, 1.0, 0.75))
	_play_customer_reaction("hurry" if animation == "disappointed" and current_customer_patience <= 1 else animation)
	if animation != "disappointed" and not theft_recovery_available:
		fury = maxi(0, fury - 1)
		_update_demonic_form()
	if adult_content_enabled and affection >= 100 and not seduction_peak_triggered:
		seduction_peak_triggered = true
		_play_seduction_peak_pose()

func _play_customer_reaction(mood: String) -> void:
	_stage_customer_react(mood)
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
			if is_instance_valid(stage_seller_body):
				stage_seller_body.modulate = _stage_mood_tint(mood)

## O corpo inteiro é o que está em cena: o humor da chefe aparece na luz dela, não
## num retrato colado no lugar do corpo.
func _stage_mood_tint(mood: String) -> Color:
	match mood:
		"happy":
			return Color(1.0, 0.97, 0.86)
		"surprised":
			return Color(0.9, 0.96, 1.0)
		"demonic":
			return Color(1.0, 0.62, 0.7)
		_:
			return Color.WHITE

## O cliente do cenário também sente a reação do balcão, em tintura leve.
func _stage_customer_react(mood: String) -> void:
	if not is_instance_valid(stage_customer) or not stage_customer.visible:
		return
	var tint := Color(1.0, 0.86, 0.94, 1.0)
	if mood == "disappointed":
		tint = Color(0.62, 0.66, 0.80, 1.0)
	elif mood == "hurry":
		tint = Color(1.0, 0.78, 0.60, 1.0)
	elif mood == "delighted":
		tint = Color(1.0, 0.72, 0.86, 1.0)
	_show_stage_emotion(stage_customer, str(STAGE_MOOD_POSE.get(mood, "")))
	var react := create_tween()
	react.tween_property(stage_customer, "modulate", tint, 0.18)
	react.tween_property(stage_customer, "modulate", Color.WHITE, 0.5)

## Toca a pose de emoção do corpo, se ela existir: o quadro aparece, segura um
## instante e volta para o ciclo de caminhada. Sem arte, nada muda — o reagir por
## cor e balanço continua sozinho.
func _show_stage_emotion(figure: Control, emotion: String) -> void:
	if emotion.is_empty() or not is_instance_valid(figure):
		return
	var path := _body_emotion_frame(str(figure.get_meta("stage_body", "")), emotion)
	if path.is_empty():
		return
	var frame := 0
	for i in range(figure.get_child_count()):
		if str((figure.get_child(i) as TextureRect).texture.resource_path) == path:
			frame = i
			break
	_set_stage_frame(figure, frame)
	var hold := create_tween()
	hold.tween_interval(0.9)
	hold.tween_callback(_restore_stage_walk_frame.bind(figure))

## Depois da pose de emoção o corpo retoma o passo exatamente de onde parou.
func _restore_stage_walk_frame(figure: Control) -> void:
	if not is_instance_valid(figure):
		return
	var frames := int(figure.get_meta("walk_frames", figure.get_child_count()))
	if frames < 3:
		_set_stage_frame(figure, 0)
		return
	var step := int(figure.get_meta("stage_step", 0))
	_set_stage_frame(figure, _stage_walk_sequence(frames)[step % frames])

func _update_demonic_form() -> void:
	if adult_content_enabled and fury >= 4 and not demonic_form_active:
		demonic_form_active = true
		_set_seller_mood("demonic")
		_show_stage_emotion(stage_seller_body, "briga")
		_show_stage_emotion(stage_customer, "medo")
		last_event = "A FÚRIA CHEGOU AO LIMITE! A succubus assume sua forma demoníaca: “Respirem. Eu ainda sei negociar.”"
		if is_instance_valid(seller_portrait):
			seller_portrait.modulate = Color(1.0, 0.55, 0.62, 1.0)
			var demon_tween := create_tween()
			demon_tween.tween_property(seller_portrait, "scale", Vector2(1.10, 1.10), 0.22).set_trans(Tween.TRANS_BACK)
			demon_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.34)
		audio.play("rare")
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
		fury_label.text = "Fúria: %d/5%s%s" % [fury,
			" • FORMA DEMONÍACA" if demonic_form_active else "",
			" • etiqueta -%d%%" % (clampi(fury, 0, 5) * 5) if fury > 0 else ""]
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
	if is_instance_valid(sector_action_button):
		sector_action_button.text = "Consultar grimório vivo" if current_sector == "library" else "Harmonizar relíquia" if current_sector == "sanctum" else "Interagir com o cenário"
		sector_action_button.disabled = current_sector != "library" and current_sector != "sanctum"
	if is_instance_valid(ritual_label):
		ritual_label.text = Sanctum.summary(active_buffs)
	event_label.text = last_event
	if is_instance_valid(regulars_label):
		var regular_lines: Array[String] = ["FREGUESES RECORRENTES"]
		var unseen := 0
		for regular in Regulars.DATA:
			var regular_id := str(regular["id"])
			var bond := int(regular_bonds.get(regular_id, 0))
			if bond <= 0:
				unseen += 1
				continue
			var tier := Regulars.tier_for(bond)
			var orders_done := int(regular_orders_completed.get(regular_id, 0))
			regular_lines.append("%s — %s (%d visitas, %d pedidos)" % [regular["short"], Regulars.TIER_NAMES[tier], bond, orders_done])
			if regular_story_completed.has(regular_id):
				regular_lines.append("  ✦ História concluída")
			elif bond >= 3:
				regular_lines.append("  ◇ Missão pessoal: %d/3 compras favoritas" % int(regular_story_progress.get(regular_id, 0)))
		if unseen > 0:
			regular_lines.append("  · %d ainda não pisaram aqui" % unseen)
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
		var trend := Economy.trend_marker(Economy.heat(economy_state, "ingredient", ingredient_id))
		ingredient_labels[i].text = "%s %s | Estoque: %d | Preço: %d ouro" % [ingredient["name"], trend, held, price]
		ingredient_buttons[i].text = "Comprar (%d)" % price
		ingredient_buttons[i].disabled = gold < price
		var resale := maxi(1, int(round(float(price) * 0.6)))
		ingredient_sell_buttons[i].text = "Revender (%d)" % resale
		ingredient_sell_buttons[i].disabled = held <= 0
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
		var quality := _quality_for(str(item["id"]))
		var demand_marker := "  ✦ EM ALTA" if i == _demand_index() else ""
		var heat_marker := Economy.trend_marker(Economy.heat(economy_state, "product", str(item["id"])))
		var shelf := _shelf_price(i)
		if unlocked:
			var margin := _estimated_margin(item)
			product_labels[i].text = "%s%s %s\nEstoque: %d  •  Vitrine: %d ouro\nPeças: %s" % [item["name"], demand_marker, heat_marker, item["stock"], shelf, Quality.summary(quality)]
			product_margin_labels[i].text = "Margem estimada: %s%d ouro" % ["+" if margin >= 0 else "−", abs(margin)]
			product_margin_labels[i].add_theme_color_override("font_color", Color(0.65, 1.0, 0.72) if margin >= 0 else Color(1.0, 0.55, 0.55))
		else:
			product_labels[i].text = "🔒 %s  •  Desbloqueia no nível %d" % [item["name"], required_level]
			product_margin_labels[i].text = "Receita bloqueada — evolua ou pague a leitura na biblioteca"
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
		var counter_stock := int(item["stock"])
		var counter_payout := maxi(1, int(round(float(shelf) * 0.7)))
		counter_labels[i].text = "%s | Estoque: %d | Balcão leva a pior: %s | Paga %d ouro" % [item["name"], counter_stock, str(Quality.tier(_peek_tier(i, Quality.WORST))["name"]), counter_payout]
		counter_buttons[i].text = "Vender (%d)" % counter_payout
		counter_buttons[i].disabled = counter_stock <= 0
		var recipe_id := str(item["id"])
		var recipe_cost := _recipe_cost(i)
		if required_level <= 1:
			recipe_labels[i].text = "%s • receita básica, sempre sua" % item["name"]
			recipe_buttons[i].text = "Dominada ✓"
			recipe_buttons[i].disabled = true
		elif player_level >= required_level:
			recipe_labels[i].text = "%s • nível %d alcançado" % [item["name"], required_level]
			recipe_buttons[i].text = "Dominada ✓"
			recipe_buttons[i].disabled = true
		elif known_recipes.has(recipe_id):
			recipe_labels[i].text = "%s • nível %d adiantado no grimório" % [item["name"], required_level]
			recipe_buttons[i].text = "Dominada ✓"
			recipe_buttons[i].disabled = true
		else:
			recipe_labels[i].text = "🔒 %s • exige nível %d" % [item["name"], required_level]
			recipe_buttons[i].text = "Aprender (%d)" % recipe_cost
			recipe_buttons[i].disabled = gold < recipe_cost
	if is_instance_valid(market_label):
		var hot := _demand_index()
		var hot_text := " • Em alta: %s" % str(products[hot]["name"]) if hot >= 0 else ""
		market_label.text = "Dia %d — %s%s" % [shop_day, Economy.report(economy_state, products, Ingredients.DATA), hot_text]
	for r in range(Sanctum.DATA.size()):
		var ritual: Dictionary = Sanctum.DATA[r]
		var ritual_id := str(ritual["id"])
		var ritual_cost := Sanctum.cost_for(ritual, sanctum_upgrade_level)
		var running := Sanctum.is_active(active_buffs, ritual_id)
		if r < ritual_labels.size():
			if running:
				ritual_labels[r].text = "✦ Em curso: %s" % Sanctum.remaining_label(active_buffs, ritual_id)
			elif Sanctum.is_buff(ritual):
				ritual_labels[r].text = "Em espera • duração escala com o santuário (Nv.%d)" % sanctum_upgrade_level
			else:
				ritual_labels[r].text = "Alívio de penalidade • uso imediato"
			ritual_labels[r].add_theme_color_override("font_color", Color(1.0, 0.86, 0.45) if running else Color(0.74, 0.68, 0.82))
		if r < ritual_buttons.size():
			ritual_buttons[r].text = "Ativo ✓" if running else "Rezar (%d)" % ritual_cost
			ritual_buttons[r].disabled = running or gold < ritual_cost
	for e in range(Expedition.size()):
		var destination: Dictionary = Expedition.DATA[e]
		var destination_id := str(destination["id"])
		var trip_cost := Expedition.cost_for(destination, logistics_rank)
		var open_route := Expedition.is_unlocked(destination, shop_day)
		var on_the_road := _expedition_on_route(destination_id)
		if e < expedition_labels.size():
			if on_the_road:
				expedition_labels[e].text = "🧭 Na estrada • faltam %s" % Expedition.days_label(maxf(0.0, float(on_the_road.get("remaining", 0.0))))
			elif not open_route:
				expedition_labels[e].text = "🔒 %s" % Expedition.locked_hint(destination)
			else:
				expedition_labels[e].text = "%s • risco %d%% • %s" % [Expedition.days_label(Expedition.duration_for(destination, logistics_rank)), int(destination["danger"]), Expedition.preview(destination)]
			expedition_labels[e].add_theme_color_override("font_color", Color(1.0, 0.86, 0.45) if on_the_road != {} else Color(0.74, 0.82, 0.78))
		if e < expedition_buttons.size():
			expedition_buttons[e].text = "Voltando…" if on_the_road != {} else "Mandar (%d)" % trip_cost
			expedition_buttons[e].disabled = on_the_road != {} or not open_route or gold < trip_cost or expeditions.size() >= _expedition_slots()
	if is_instance_valid(expedition_active_label):
		if expeditions.is_empty():
			expedition_active_label.text = "Nenhuma viagem na estrada. Todos os batedores estão jogando cartas nos fundos."
		else:
			var routes: Array[String] = []
			for trip in expeditions:
				var trip_destination := Expedition.find(str(trip.get("id", "")))
				var total := maxf(1.0, float(trip.get("total", 1.0)))
				var progress := clampf(1.0 - float(trip.get("remaining", 0.0)) / total, 0.0, 1.0)
				routes.append("%s [%s] %d%%" % [str(trip_destination.get("name", "?")), _bar(progress), int(round(progress * 100.0))])
			expedition_active_label.text = "Vagas: %d/%d — %s" % [expeditions.size(), _expedition_slots(), "  |  ".join(routes)]
	if is_instance_valid(expedition_log_label):
		expedition_log_label.text = "Nenhuma mala voltou ainda." if expedition_log.is_empty() else "\n".join(expedition_log)
	if is_instance_valid(catalyst_label):
		var catalyst := _catalyst_available()
		catalyst_label.text = "Disponível: %s (+%d de sorte na próxima peça)." % [str(catalyst["name"]), int(catalyst["catalyst_luck"])] if not catalyst.is_empty() else "Prateleira de raridades vazia. Expedições trazem o que o mercado não vende."
	if is_instance_valid(catalyst_button):
		catalyst_button.text = "Catalisador: ARMADO" if catalyst_enabled else "Catalisador: desarmado"
		catalyst_button.disabled = _catalyst_available().is_empty() and not catalyst_enabled
	if is_instance_valid(card_summary_label):
		card_summary_label.text = Cards.summary(card_counts)
	if is_instance_valid(pack_button):
		var pack_cost := Cards.pack_price(packs_opened)
		pack_button.text = "🂠 Abrir pacote (%d ouro)" % pack_cost
		pack_button.disabled = gold < pack_cost
	for c in range(Cards.DATA.size()):
		var card: Dictionary = Cards.DATA[c]
		var copies := int(card_counts.get(str(card["id"]), 0))
		if c < card_gallery_labels.size():
			var slot: Label = card_gallery_labels[c]
			slot.text = "%s\n%s • x%d" % [str(card["name"]), str(Cards.rarity_of(card)["name"]), copies] if copies > 0 else "?\n%s" % str(Cards.rarity_of(card)["name"])
			slot.add_theme_color_override("font_color", Cards.color_of(card) if copies > 0 else Color(0.42, 0.4, 0.48))
	if is_instance_valid(board_label):
		board_label.text = "Sua pontuação: %d • recorde %d\n%s" % [business_score(), best_score, _board_text()]
	if is_instance_valid(score_button):
		var rank := 1 if steam == null else int(steam.call("rank_of", business_score()))
		score_button.text = "Publicar resultado • você está em %dº" % rank
	if is_instance_valid(chapter_label):
		chapter_label.text = _chapter_text()
	if is_instance_valid(campaign_line):
		var shown_chapter := Campaign.chapter(campaign_step)
		if shown_chapter.is_empty():
			campaign_line.text = "★ Império fundado • o balcão segue em modo livre"
		else:
			var still_missing := Campaign.missing(_campaign_stats(), shown_chapter).size()
			campaign_line.text = "★ Objetivo %d/%d: %s%s" % [
				campaign_step + 1, Campaign.size(), str(shown_chapter["name"]),
				" • pronto para fechar!" if still_missing == 0 else " • falta %d" % still_missing]
	if is_instance_valid(chapter_button):
		var chapter := Campaign.chapter(campaign_step)
		if chapter.is_empty():
			chapter_button.text = "Campanha concluída • jogo livre"
			chapter_button.disabled = true
		else:
			var pending := Campaign.missing(_campaign_stats(), chapter).size()
			chapter_button.text = ("Fechar capítulo • faltam %d" % pending) if pending > 0 else "Fechar capítulo • receber recompensa"
			chapter_button.disabled = false
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

## Ruidos de saves antigos ou de versões diferentes do mercado: aproveita só o
## calor válido e mantém a estrutura {"ingredient": {}, "product": {}}.
func _read_economy_state(saved) -> void:
	if not saved is Dictionary:
		return
	for group in ["ingredient", "product"]:
		var saved_group = saved.get(group, {})
		if not saved_group is Dictionary:
			continue
		var table: Dictionary = economy_state[group]
		for saved_id in saved_group.keys():
			table[str(saved_id)] = clampf(float(saved_group[saved_id]), Economy.MIN_HEAT, Economy.MAX_HEAT)

func _read_buffs(saved) -> Dictionary:
	var result: Dictionary = {}
	if not saved is Dictionary:
		return result
	for saved_id in saved.keys():
		var ritual := Sanctum.find(str(saved_id))
		if ritual.is_empty() or not Sanctum.is_buff(ritual):
			continue
		var left := float(saved[saved_id])
		if left > 0.0:
			result[str(saved_id)] = left
	return result

## Viagens na estrada voltam a andar no mesmo ponto; destino desconhecido é descartado.
func _read_expeditions(saved) -> void:
	expeditions.clear()
	if not (saved is Array):
		return
	for entry in saved:
		if not (entry is Dictionary):
			continue
		var trip: Dictionary = entry
		var trip_id := str(trip.get("id", ""))
		if Expedition.find(trip_id).is_empty():
			continue
		var total := maxf(1.0, float(trip.get("total", 1.0)))
		expeditions.append({"id": trip_id, "remaining": clampf(float(trip.get("remaining", total)), 0.0, total), "total": total})

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
	config.set_value("game", "quality_stock", quality_stock)
	config.set_value("game", "economy_state", economy_state)
	config.set_value("game", "active_buffs", active_buffs)
	config.set_value("game", "stolen_tier", stolen_tier)
	config.set_value("game", "best_quality_crafted", best_quality_crafted)
	config.set_value("game", "rituals_performed", rituals_performed)
	config.set_value("game", "expeditions", expeditions)
	config.set_value("game", "expedition_log", expedition_log)
	config.set_value("game", "expeditions_done", expeditions_done)
	config.set_value("game", "rare_found", rare_found)
	config.set_value("game", "catalyst_crafted", catalyst_crafted)
	config.set_value("game", "card_counts", card_counts)
	config.set_value("game", "packs_opened", packs_opened)
	config.set_value("game", "completed_sets", completed_sets)
	config.set_value("game", "best_score", best_score)
	config.set_value("game", "campaign_step", campaign_step)
	config.set_value("game", "game_completed", game_completed)
	config.set_value("game", "total_crafted", total_crafted)
	config.set_value("game", "total_ingredients_bought", total_ingredients_bought)
	config.set_value("game", "premium_crafted", premium_crafted)
	config.set_value("game", "happy_customers", happy_customers)
	config.set_value("game", "disappointed_customers", disappointed_customers)
	config.set_value("game", "seduction_attempts", seduction_attempts)
	config.set_value("game", "seduction_successes", seduction_successes)
	config.set_value("game", "world_speed_index", world_speed_index)
	config.set_value("game", "library_upgrade_level", library_upgrade_level)
	config.set_value("game", "sanctum_upgrade_level", sanctum_upgrade_level)
	config.set_value("game", "known_recipes", known_recipes)
	config.set_value("game", "queue_distractions", queue_distractions)
	config.set_value("game", "products", products)
	# O que a forja ainda não terminou é dinheiro do jogador em andamento: perder
	# isso ao fechar o jogo era trabalhar de graça na última sessão do dia.
	config.set_value("game", "ticks", ticks)
	config.set_value("game", "craft_jobs", craft_jobs)
	config.set_value("game", "catalyst_enabled", catalyst_enabled)
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
	# Migração do save antigo: `premium_stock` guardava bonus flutuante por nome de
	# produto. As peças viram estoque real de Obra-prima no registro por id.
	var saved_quality = config.get_value("game", "quality_stock", {})
	if saved_quality is Dictionary:
		for product_id in saved_quality.keys():
			var counts: Array[int] = Quality.empty_stock()
			var saved_counts = saved_quality[product_id]
			if saved_counts is Array:
				for i in range(mini(saved_counts.size(), counts.size())):
					counts[i] = maxi(0, int(saved_counts[i]))
			quality_stock[str(product_id)] = counts
	var legacy_premium = config.get_value("game", "premium_stock", {})
	if legacy_premium is Dictionary:
		for legacy_name in legacy_premium.keys():
			var legacy_count := maxi(0, int(legacy_premium[legacy_name]))
			if legacy_count == 0:
				continue
			for i in range(products.size()):
				if str(products[i]["name"]) == str(legacy_name):
					for _repeat in range(legacy_count):
						_add_piece(i, 3)
					break
	best_quality_crafted = clampi(int(config.get_value("game", "best_quality_crafted", best_quality_crafted)), -1, Quality.size() - 1)
	rituals_performed = int(config.get_value("game", "rituals_performed", rituals_performed))
	_read_economy_state(config.get_value("game", "economy_state", {}))
	active_buffs = _read_buffs(config.get_value("game", "active_buffs", {}))
	stolen_tier = clampi(int(config.get_value("game", "stolen_tier", stolen_tier)), 0, Quality.size() - 1)
	_read_expeditions(config.get_value("game", "expeditions", []))
	expedition_log.clear()
	var saved_log = config.get_value("game", "expedition_log", [])
	if saved_log is Array:
		for saved_line in saved_log:
			expedition_log.append(str(saved_line))
	expeditions_done = int(config.get_value("game", "expeditions_done", expeditions_done))
	rare_found = int(config.get_value("game", "rare_found", rare_found))
	catalyst_crafted = int(config.get_value("game", "catalyst_crafted", catalyst_crafted))
	var saved_cards = config.get_value("game", "card_counts", {})
	card_counts = {}
	if saved_cards is Dictionary:
		for saved_card in (saved_cards as Dictionary).keys():
			if not Cards.find(str(saved_card)).is_empty():
				card_counts[str(saved_card)] = maxi(1, int((saved_cards as Dictionary)[saved_card]))
	packs_opened = int(config.get_value("game", "packs_opened", packs_opened))
	best_score = int(config.get_value("game", "best_score", best_score))
	campaign_step = clampi(int(config.get_value("game", "campaign_step", campaign_step)), 0, Campaign.size())
	game_completed = bool(config.get_value("game", "game_completed", game_completed)) or campaign_step >= Campaign.size()
	total_crafted = int(config.get_value("game", "total_crafted", total_crafted))
	completed_sets.clear()
	var saved_sets = config.get_value("game", "completed_sets", [])
	if saved_sets is Array:
		for saved_set in saved_sets:
			if Cards.SET_NAMES.has(str(saved_set)) and not completed_sets.has(str(saved_set)):
				completed_sets.append(str(saved_set))
	total_ingredients_bought = int(config.get_value("game", "total_ingredients_bought", total_ingredients_bought))
	premium_crafted = int(config.get_value("game", "premium_crafted", premium_crafted))
	happy_customers = int(config.get_value("game", "happy_customers", happy_customers))
	disappointed_customers = int(config.get_value("game", "disappointed_customers", disappointed_customers))
	seduction_attempts = int(config.get_value("game", "seduction_attempts", seduction_attempts))
	seduction_successes = int(config.get_value("game", "seduction_successes", seduction_successes))
	world_speed_index = clampi(int(config.get_value("game", "world_speed_index", world_speed_index)), 0, world_speed_options.size() - 1)
	library_upgrade_level = clampi(int(config.get_value("game", "library_upgrade_level", library_upgrade_level)), 0, 5)
	sanctum_upgrade_level = clampi(int(config.get_value("game", "sanctum_upgrade_level", sanctum_upgrade_level)), 0, 5)
	var saved_recipes = config.get_value("game", "known_recipes", [])
	if saved_recipes is Array:
		known_recipes.clear()
		for saved_recipe in saved_recipes:
			var recipe_key := str(saved_recipe)
			if not recipe_key.is_empty() and not known_recipes.has(recipe_key):
				known_recipes.append(recipe_key)
	queue_distractions = int(config.get_value("game", "queue_distractions", queue_distractions))
	ticks = maxi(0, int(config.get_value("game", "ticks", ticks)))
	catalyst_enabled = bool(config.get_value("game", "catalyst_enabled", catalyst_enabled))
	var saved_jobs = config.get_value("game", "craft_jobs", [])
	craft_jobs.clear()
	if saved_jobs is Array:
		for saved_job in saved_jobs:
			if not saved_job is Dictionary:
				continue
			var job_index := int(saved_job.get("index", -1))
			if job_index < 0 or job_index >= products.size():
				continue
			craft_jobs.append({
				"index": job_index,
				"remaining": maxf(0.5, float(saved_job.get("remaining", 0.5))),
				"luck": float(saved_job.get("luck", 0.0)),
			})
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
	if known_recipes.has(str(item.get("id", ""))):
		return true
	return player_level >= int(item.get("required_level", 1))

const TALENT_REACTIONS := {
	"alchemy": [
		"A chefe gira o dedo e a bancada borbulha sozinha: “Viu? Eu só precisava de um pouquinho mais de... concentração.”",
		"Faíscas roxas escorrem pelos frascos: “Alquimia é como sedução. Se você erra a dose, explode — se acerta, vicia.”",
		"Ela lambe o polegar e prova a poção: “Hmm... agora sim está com a minha cara. Perigosa e deliciosa.”"
	],
	"trade": [
		"A chefe estala os dedos e as moedas dançam no balcão: “Preço bom é aquele que o cliente acha que escolheu sozinho.”",
		"Ela ajeita o decote do avental e sorri: “Negociar é a arte de fazer o outro dizer sim e agradecer.”",
		"Os olhos dela brilham em dourado: “Lucro, querido, é só carinho que o mercado me deve.”"
	],
	"charm": [
		"A chefe sopra um beijo para o vazio e três clientes lá fora suspiram: “Opa. Isso saiu mais forte do que eu planejava.”",
		"Ela morde o lábio e pisca devagar: “Agora é oficial: ninguém sai daqui sem querer voltar.”",
		"A cauda dela desenha um coração no ar: “Carisma é magia que não precisa de grimório... só de você me olhando.”"
	],
	"logistics": [
		"Imps desfilam com caixas empilhadas: “Estoque organizado e fornecedor assustado. Meu tipo de manhã perfeita.”",
		"A chefe bate a prancheta no quadril: “Eficiência também é sensual. Principalmente quando chega no prazo.”",
		"Um portal minúsculo cospe ingredientes no balcão: “Entrega expressa. Reclamações com o meu chicote de planilhas.”"
	]
}
const TALENT_MAX_LINES := {
	"alchemy": "Ela abre os braços e o laboratório inteiro cintila: “Mestra alquimista! Agora os frascos é que pedem desculpas para mim.”",
	"trade": "Ela apoia o queixo na mão: “Nível máximo de negociação. Vou começar a vender até o seu 'não' de volta, com juros.”",
	"charm": "O ar fica rosado e quente: “Carisma máximo. Se eu piscar errado, vou precisar de uma fila de seguranças... e de um ventilador.”",
	"logistics": "Todos os imps batem continência ao mesmo tempo: “Logística perfeita. Até o caos agora chega pontual.”"
}

func _play_talent_reaction(kind: String, rank: int) -> void:
	var line: String
	if rank >= 5 and TALENT_MAX_LINES.has(kind):
		line = str(TALENT_MAX_LINES[kind])
	else:
		var options: Array = TALENT_REACTIONS.get(kind, [])
		if options.is_empty():
			return
		line = str(options.pick_random())
	if not adult_content_enabled:
		line = line.replace("sedução", "persuasão").replace("sensual", "elegante")
	if is_instance_valid(seller_speech_label):
		seller_speech_label.text = "CHEFE: %s" % line
	if is_instance_valid(reaction_label):
		reaction_label.text = "✦ Talento nível %d!" % rank
		reaction_label.add_theme_color_override("font_color", Color(0.88, 0.75, 1.0))
	if not demonic_form_active:
		_set_seller_mood("happy")
	if is_instance_valid(seller_portrait):
		seller_portrait.pivot_offset = seller_portrait.size / 2.0
		var pop := create_tween()
		pop.tween_property(seller_portrait, "scale", Vector2(1.08, 1.08), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.parallel().tween_property(seller_portrait, "modulate", Color(0.95, 0.85, 1.0, 1.0), 0.2)
		pop.tween_property(seller_portrait, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_SINE)
		pop.parallel().tween_property(seller_portrait, "modulate", Color.WHITE if not demonic_form_active else Color(1.0, 0.55, 0.62, 1.0), 0.35)
	_show_feedback("✦ Talento aprimorado!", Color(0.88, 0.75, 1.0))

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
	var new_rank := int(get(kind + "_rank"))
	_play_talent_reaction(kind, new_rank)

func _xp_required() -> int:
	return 40 + player_level * 25

## A afeição enche até 100 e o excedente não evapora: a cada cinco pontos que não
## cabem no coração da chefe sobe um ponto de reputação, porque freguês encantado
## comenta a loja fora dela.
func _add_affection(amount: int) -> void:
	var room := maxi(0, 100 - affection)
	affection = mini(100, affection + amount)
	var spill := amount - room
	if spill >= 5:
		reputation += int(spill / 5)

func _add_xp(amount: int) -> void:
	var previous_level := player_level
	# O Sussurro Ancestral do santuário turbinou todo XP enquanto a vela queima.
	player_xp += int(round(float(amount) * Sanctum.scale(active_buffs, "xp")))
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
		audio.play("levelup")
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

## Um único lugar define as conquistas: a checagem do jogo e o catálogo que a
## Steam precisa conhecer na inicialização.
func _achievement_definitions() -> Array[Dictionary]:
	return [
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
		{"id": "premium_artisan", "name": "Mão de Midas (3 peças de alto nível)", "condition": premium_crafted >= 3, "gold": 45, "rep": 2},
		{"id": "myth_piece", "name": "Peça Mítica (uma lenda saiu da bigorna)", "condition": best_quality_crafted >= 4, "gold": 150, "rep": 8, "pose": "relic"},
		{"id": "market_barometer", "name": "Termômetro do Balcão (produto no pico de procura)", "condition": _max_product_heat() >= 0.8, "gold": 55, "rep": 3},
		{"id": "ritual_apprentice", "name": "Aprendiz de Ritos (3 rituais)", "condition": rituals_performed >= 3, "gold": 40, "rep": 2},
		{"id": "ritual_devotee", "name": "Fiel do Santuário (10 rituais)", "condition": rituals_performed >= 10, "gold": 100, "rep": 5, "pose": "book"},
		{"id": "first_expedition", "name": "Pé na Estrada (primeira expedição)", "condition": expeditions_done >= 1, "gold": 30, "rep": 1},
		{"id": "route_regular", "name": "Corredor do Abismo (10 expedições de volta)", "condition": expeditions_done >= 10, "gold": 90, "rep": 4, "pose": "relic"},
		{"id": "rare_hoarder", "name": "Vitrine de Raridades (3 raridades no estoque)", "condition": rare_found >= 3, "gold": 70, "rep": 3},
		{"id": "catalyst_touch", "name": "Toque de Catalisador (peça rara na forja)", "condition": catalyst_crafted >= 1, "gold": 60, "rep": 3, "pose": "relic"},
		{"id": "library_master", "name": "Bibliotecária do Submundo (Biblioteca Nv.3)", "condition": library_upgrade_level >= 3, "gold": 80, "rep": 4, "pose": "book"},
		{"id": "sanctum_keeper", "name": "Guardiã das Relíquias (Santuário Nv.3)", "condition": sanctum_upgrade_level >= 3, "gold": 90, "rep": 5, "pose": "relic"},
		{"id": "queue_charmer", "name": "Ninguém sai da fila (3 distrações)", "condition": queue_distractions >= 3, "gold": 65, "rep": 4, "pose": "queue"},
		{"id": "speed_demon", "name": "Cinco vezes mais charmosa (velocidade 5x)", "condition": world_speed() >= 5.0, "gold": 50, "rep": 3, "pose": "speed"},
		{"id": "chapter_seeker", "name": "Primeiro capítulo (objetivo fechado)", "condition": campaign_step >= 1, "gold": 40, "rep": 2},
		{"id": "half_way", "name": "Meio caminho (4 capítulos)", "condition": campaign_step >= 4, "gold": 160, "rep": 7, "pose": "book"},
		{"id": "private_sanctuary", "name": "Cantinho reservado (5 momentos só da loja)", "condition": private_moments_unlocked >= 5, "gold": 90, "rep": 3},
		{"id": "empire_founded", "name": "Império fundado (campanha completa)", "condition": game_completed, "gold": 300, "rep": 15, "pose": "relic"}
	]

func _check_achievements() -> void:
	for achievement in _achievement_definitions():
		var achievement_id: String = str(achievement["id"])
		if bool(achievement["condition"]) and not unlocked_achievements.has(achievement_id):
			unlocked_achievements.append(achievement_id)
			gold += int(achievement["gold"])
			reputation += int(achievement["rep"])
			if steam != null:
				steam.call("unlock", achievement_id)
			_grant_pack(true)
			last_event = "CONQUISTA DESBLOQUEADA: %s! Recompensa: %d ouro, %d reputação e um pacote de cartas." % [
				achievement["name"], achievement["gold"], achievement["rep"]
			]
			if achievement.has("pose"):
				_play_achievement_pose(str(achievement["pose"]))

func _achievement_ids() -> Array[String]:
	var ids: Array[String] = []
	for achievement in _achievement_definitions():
		ids.append(str(achievement["id"]))
	return ids

## Abre um pacote de cartas. Brinde de conquista chega de graça; no balcão tem preço.
func _grant_pack(free: bool) -> void:
	var price := Cards.pack_price(packs_opened)
	if not free:
		if gold < price:
			last_event = "O pacote custa %d ouro. A loja não aprova fiado nem para nostalgia." % price
			_refresh_ui()
			return
		gold -= price
	var opened: Dictionary = Cards.open_pack(card_counts, alchemy_rank + Sanctum.luck_bonus(active_buffs))
	packs_opened += 1
	var card: Dictionary = opened["card"]
	var card_id := str(card["id"])
	last_pack_card = card_id
	var text := ""
	if bool(opened["duplicate"]):
		var refund := Cards.refund_of(card)
		gold += refund
		text = "Repetida: %s. A casa devolve %d ouro pelo par." % [card["name"], refund]
		audio.play("coin")
	else:
		text = "Carta nova: %s (%s)." % [card["name"], str(Cards.rarity_of(card)["name"])]
		if steam != null:
			steam.call("grant_card", card_id)
		audio.play("rare")
	for finished in Cards.newly_completed(card_counts, completed_sets):
		completed_sets.append(str(finished))
		reputation += 4
		text += " Coleção %s completa: +4 de reputação." % str(Cards.SET_NAMES[str(finished)])
	_show_feedback("🂠 Pacote aberto.", Color(1.0, 0.86, 0.45))
	last_event = text
	_play_card_flip(card_id)
	_refresh_ui()
	_save_game()

## A carta sorteada dá um pulo na parede da coleção.
func _play_card_flip(card_id: String) -> void:
	for i in range(Cards.DATA.size()):
		if str(Cards.DATA[i]["id"]) != card_id or i >= card_gallery_labels.size():
			continue
		var label: Label = card_gallery_labels[i]
		if not is_instance_valid(label):
			return
		label.pivot_offset = label.size / 2.0
		var flip := create_tween()
		flip.tween_property(label, "scale", Vector2(1.16, 1.16), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flip.tween_property(label, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		return

## Pontuação do império: caixa, fama, clientela, coleção e estrada.
func business_score() -> int:
	return gold + reputation * 20 + customers_served * 6 + Cards.owned_count(card_counts) * 40 \
		+ player_level * 25 + premium_crafted * 15 + expeditions_done * 20 + rituals_performed * 10 \
		+ campaign_step * 60 + private_moments_unlocked * 8 + (1200 if game_completed else 0)

func _publish_score() -> void:
	var score := business_score()
	best_score = maxi(best_score, score)
	if steam != null:
		steam.call("submit_score", score, "Sua loja")
		steam.call("request_leaderboard")
	last_event = "Resultado publicado no placar: %d pontos." % score
	audio.play("coin")
	_refresh_ui()
	_save_game()

func _on_leaderboard_ready(_rows: Array) -> void:
	_refresh_ui()

## Retrato numérico da loja: cada chave é um pedido possível de capítulo.
func _campaign_stats() -> Dictionary:
	return {
		"customers_served": customers_served,
		"ingredients_bought": total_ingredients_bought,
		"crafted": total_crafted,
		"gold": gold,
		"happy_customers": happy_customers,
		"regular_stories": regular_story_completed.size(),
		"expeditions": expeditions_done,
		"rare_found": rare_found,
		"premium_crafted": premium_crafted,
		"library_level": library_upgrade_level,
		"sanctum_level": sanctum_upgrade_level,
		"rituals": rituals_performed,
		"cards": Cards.owned_count(card_counts),
		"sets": completed_sets.size(),
		"packs": packs_opened,
		"level": player_level,
		"reputation": reputation,
		"faction_tier": _max_faction_tier(),
		"best_quality": maxi(best_quality_crafted, 0)
	}

func _chapter_text() -> String:
	var chapter := Campaign.chapter(campaign_step)
	if chapter.is_empty():
		return "Império fundado. O balcão continua aberto: agora é por conta própria, para subir pontuação e fechar o álbum."
	var lines: Array[String] = [
		"Capítulo %d de %d • %s" % [campaign_step + 1, Campaign.size(), str(chapter["name"])],
		str(chapter["desc"])
	]
	lines.append_array(Campaign.progress(_campaign_stats(), chapter))
	var bonus := " e pacote de cartas" if int(chapter.get("pack", 0)) > 0 else ""
	lines.append("Recompensa: %d ouro, %d reputação, %d XP%s." % [int(chapter["gold"]), int(chapter["rep"]), int(chapter["xp"]), bonus])
	return "\n".join(lines)

func _claim_chapter() -> void:
	var chapter := Campaign.chapter(campaign_step)
	if chapter.is_empty():
		return
	var stats := _campaign_stats()
	if not Campaign.complete(stats, chapter):
		last_event = "O capítulo ainda não fecha: %s." % ", ".join(Campaign.missing(stats, chapter))
		audio.play("sad")
		_refresh_ui()
		return
	gold += int(chapter["gold"])
	reputation += int(chapter["rep"])
	for i in range(int(chapter.get("pack", 0))):
		_grant_pack(true)
	_add_xp(int(chapter["xp"]))
	var is_final := bool(chapter.get("final", false))
	campaign_step += 1
	last_event = "CAPÍTULO FECHADO: %s. A chefe carimba o livro-razão e promete aumentar os preços." % str(chapter["name"])
	audio.play("levelup")
	_show_feedback("✦ Capítulo concluído!", Color(0.82, 1.0, 0.86))
	_show_stage_emotion(stage_seller_body, "vitoria")
	_show_stage_emotion(stage_customer, "danca")
	if is_final:
		game_completed = true
		_show_ending()
	_check_achievements()
	_save_game()
	_refresh_ui()

func _show_ending() -> void:
	if is_instance_valid(ending_layer):
		ending_layer.visible = true
		return
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	ending_layer = dim

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.03, 0.1, 0.98)
	panel_style.border_color = Color(1.0, 0.78, 0.35, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 26
	panel_style.content_margin_right = 26
	panel_style.content_margin_top = 22
	panel_style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)

	var title := Label.new()
	title.text = "IMPÉRIO DO BALCÃO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.45))
	box.add_child(title)

	var body_text := Label.new()
	body_text.text = "Todos os capítulos fechados. A loja de esquina virou rede, o submundo inteiro pede pelo nome, e a " \
		+ "chefe finalmente usa um vestido que custou mais que o estoque inteiro.\n\n" \
		+ "Dia %d • %d de ouro em caixa • reputação %d • nível %d\n" % [shop_day, gold, reputation, player_level] \
		+ "%d clientes atendidos • %d peças fabricadas • %d expedições\n" % [customers_served, total_crafted, expeditions_done] \
		+ "%d de %d cards no álbum • pontuação %d\n\n" % [Cards.owned_count(card_counts), Cards.size(), business_score()] \
		+ "O balcão continua aberto: dá para fechar o álbum, subir no placar e esticar o império até onde a sorte deixar."
	body_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_text.add_theme_font_size_override("font_size", 16)
	body_text.add_theme_color_override("font_color", Color(0.92, 0.88, 0.96))
	box.add_child(body_text)

	var close_button := Button.new()
	close_button.text = "Voltar a administrar"
	close_button.custom_minimum_size = Vector2(240, 46)
	close_button.pressed.connect(_close_ending)
	box.add_child(close_button)

func _close_ending() -> void:
	if is_instance_valid(ending_layer):
		ending_layer.visible = false
	audio.play("click")

func _board_text() -> String:
	if steam == null:
		return "Placar ainda não acordou."
	var rows: Array = steam.call("board")
	var lines: Array[String] = ["Origem: %s • Save na nuvem: %s" % [
		String(steam.call("board_source")),
		"ativo" if bool(steam.get("cloud_ready")) else "local"]]
	for i in range(mini(rows.size(), 8)):
		var row: Dictionary = rows[i]
		var marker := "►" if str(row["name"]) == "Sua loja" else " "
		lines.append("%s %dº  %-24s %d pts" % [marker, i + 1, str(row["name"]), int(row["score"])])
	return "\n".join(lines)

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
	var definitions := _achievement_definitions()
	var lines: Array[String] = ["CONQUISTAS: %d/%d" % [unlocked_achievements.size(), definitions.size()]]
	for achievement in definitions:
		var marker := "✓" if unlocked_achievements.has(str(achievement["id"])) else "○"
		lines.append("%s %s" % [marker, str(achievement["name"]).split(" (")[0]])
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
