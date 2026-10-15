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
const Origin = preload("res://origin.gd")
const Prestige = preload("res://prestige.gd")
const Endings = preload("res://endings.gd")
const Branches = preload("res://branches.gd")
const FactionArcs = preload("res://faction_arcs.gd")
const TalentSpecs = preload("res://talent_specs.gd")
const Staff = preload("res://staff.gd")
const SteamBridge = preload("res://steam_bridge.gd")
const Diagnostics = preload("res://diagnostics.gd")

## Caixa e despensa com que a loja abre a primeira vida — e cada vida seguinte.
const BASE_GOLD := 80
const STARTING_PANTRY := {"essencia": 1, "pena": 1, "sal": 1, "vazio": 1, "tinta": 1, "po_lunar": 1}

var gold: int = BASE_GOLD
var reputation: int = 0
var customers_served: int = 0
var affection: int = 0
var fury: int = 0
var demonic_form_active: bool = false
var regular_bonds: Dictionary = {}
var regular_orders_completed: Dictionary = {}
var regular_story_progress: Dictionary = {}
var regular_story_completed: Array[String] = []
## Degrau da escada de confiança já pago por cada freguês, de zero a três.
var romance_stage: Dictionary = {}
## Freguês que saiu do balcão a fim de um convite. A oferta acende sozinha quando
## a visita rendeu vínculo e vale até a virada do dia.
var romance_pending: String = ""
## Ato mais alto já anunciado da ficha de cada freguês. Serve para a cena não se
## repetir a cada venda: o ato sobe com o progresso, e a loja só comemora uma vez.
var regular_arc_seen: Dictionary = {}
## Fila da despedida: quem ainda vai passar pelo balcão para dizer tchau depois do
## último capítulo. Entra um por tique, na ordem de quem menos visitou, para que o
## mais fiel seja o último a sair da tela.
var epilogue_pending: Array[String] = []
## True quando a fila zerou e a loja ficou só com a chefe.
var epilogue_done: bool = false
## Cenas de origem já exibidas. São a única memória da chefe e da patrona que o
## save guarda: o texto todo está em origin.gd.
var origin_seen: Array[String] = []
var origin_layer: Control
## Prestígio: vidas já trocadas, aura parada no cofre, nível de cada dote
## permanente e quantas metas da escada já foram pagas.
var prestige_runs: int = 0
var prestige_aura: int = 0
var prestige_perks: Dictionary = {}
var prestige_goals_paid: int = 0
## Finais já vistos (id de endings.gd) e o recorde de pontuação de cada temporada.
## Temporada é a vida da loja: reencarnar abre a seguinte e arquiva a anterior.
var endings_seen: Array[String] = []
var season_records: Dictionary = {}
## A reputação de facção é permanente e manda no preço; o final, não. Aqui fica o
## ponteiro de cada facção no instante em que a vida começou — o que a temporada
## conquistou acima desse ponteiro é o que decide o capítulo sete dela.
var season_baseline: Dictionary = {}
## A casa cobra todo dia, venda ou não. O que o caixa não cobre não perdoa: vira
## dívida, e dívida acima do teto leva o salão. `debt_peak` é o fundo do poço da
## vida — sair dele é tão conquistador quanto nunca ter caído.
var debt: int = 0
var debt_peak: int = 0
## Vidas que fecharam no vermelho, e as temporadas marcadas como perdidas no placar.
var ruined_lives: int = 0
var ruined_seasons: Array[String] = []
## O balanço da última virada: quanto a casa cobrou e o que as filiais devolveram.
## A linha do dia nasce e morre no mesmo tique (conquista, encomenda e diabrete
## escrevem por cima), então o resultado da conta precisa de lugar fixo na recepção.
var day_report: String = ""
## O popup do balanço: a conta da virada em uma janela que para o relógio no meio
## da rua, com o OK da chefe e a opção de ela não ter tempo nem para isso.
var day_layer: Control
var day_auto_ok: bool = false
var _day_countdown: Tween
var _day_countdown_label: Label
## Quanto o placar tinha no instante em que o dia abriu. O balanço mostra o delta da
## virada, não a conta acumulada da vida, então a régua precisa nascer com o dia.
var day_snap_gold: int = 0
var day_snap_served: int = 0
var day_snap_happy: int = 0
var day_snap_lost: int = 0
## Filiais abertas nesta vida. Cada uma paga um lucro por virada e engrossa a conta
## da casa; a mais rentável é também a que mais afunda quando o dia vira.
var branches: Array[String] = []
## Quem está no balcão nesta vida. Vaga é da vida como a filial: reencarnar devolve
## o salário e devolve a entrega, porque a folha é conta da casa e a casa recomeça
## no nome dela.
var staff_hired: Array[String] = []
## Furtos barrados pela ronda nesta vida — o número que a conquista do beco lê.
var theft_blocked: int = 0
## Pedidos de facção já entregues (facção → quantos). É nome, não ouro: fica na
## conta salva depois da ruína e da reencarnação, e o privilégio do arco fechado
## continua valendo na vida seguinte.
var faction_arc_step: Dictionary = {}
## Clientes deste tipo atendidos nesta vida. É o único número novo que o arco
## precisa medir, e ele morre com a vida como o resto do caixa.
var faction_customers: Dictionary = {}
## O que abrir quando a lembrança fechar: é como o capítulo final emenda o painel
## do império na cena do andar de cima sem empilhar os dois quadros.
var _origin_next: Callable = Callable()
var faction_standing: Dictionary = {}
var adult_content_enabled: bool = false
var adult_content_confirmed: bool = false
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
## Encomenda de longo prazo: o pedido de um patrono que se cumpre em etapas
## atravessando dias. Índice -1 é a prateleira livre: nada sobre o balcão.
var commission_index: int = -1
var commission_stage: int = 0
var commission_progress: int = 0
var commission_deadline: int = 0
var commission_next_offer: int = 3
var commissions_finished: int = 0
var alchemy_rank: int = 0
var trade_rank: int = 0
var charm_rank: int = 0
var logistics_rank: int = 0
## Quinta trilha: a chefe administrando a própria casa, e não só o balcão.
var house_rank: int = 0
## Ofício assinado em cada trilha (trilha → id da especialização). Um por trilha,
## escolhido a partir do nível 4, e é ele que destrava o quinto degrau. A escolha é
## da vida: reencarnar ou reabrir depois da ruína devolve a liberdade de montar a
## build concorrente.
var spec_choice: Dictionary = {}
## Receitas pagas na biblioteca, independentemente do nível da personagem.
var known_recipes: Array[String] = []
var world_speed_options: Array[float] = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0]
var world_speed_index: int = 1
var world_timer: Timer
var offline_dialog: AcceptDialog
var _offline_elapsed_seconds: float = 0.0
var _offline_branch_fraction: float = 0.0
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
var ingredient_stock: Dictionary = STARTING_PANTRY.duplicate()
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
## Peças Lendárias: as que saíram da bigorna e as que foram entregues no balcão.
var legendary_crafted: int = 0
var legendary_sold: int = 0
## Encomendas exclusivas do topo da forja já fechadas.
var exclusive_finished: int = 0
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
var house_button: Button
var ingredient_labels: Array = []
var ingredient_buttons: Array = []
var last_event: String = "Bem-vindo! Vamos transformar esta espelunca em um império."

const PRODUCT_ICONS := ["🧪", "🦆", "💧", "📦", "✨", "🐟", "🌀", "💎", "📜", "☕", "🗡️", "🔨"]

## Estoque com que cada produto abriu a loja na primeira manhã; é com ele que cada
## vida nova recomeça.
var _starting_shelf: Dictionary = {}

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

## Os quatro contratos do dia, um por virada. A tabela é constante justamente
## para que a virada não precise saber de cabeça quantos contratos existem.
const DAILY_QUESTS: Array[Dictionary] = [
	{"name": "Atenda 5 clientes hoje", "type": "customers", "target": 5, "gold": 45, "xp": 25},
	{"name": "Fature 100 de ouro hoje", "type": "gold", "target": 100, "gold": 55, "xp": 30},
	{"name": "Fabrique 3 produtos hoje", "type": "craft", "target": 3, "gold": 40, "xp": 35},
	{"name": "Encontre 1 evento raro hoje", "type": "rare", "target": 1, "gold": 65, "xp": 40},
]

## O que cada tipo de etapa pede, escrito para caber no painel do balcão.
const COMMISSION_STAGE_TEXTS := {
	"customers": "Atender %d clientes",
	"gold": "Faturar %d de ouro",
	"craft": "Fabricar %d peças",
	"rare": "Presenciar %d eventos raros",
	"legendary": "Entregar %d peça(s) Lendária(s) no balcão",
}

## Encomendas de longo prazo: o pedido de um patrono que se cumpre em três etapas
## atravessando dias, enquanto o contrato do dia nasce e morre na mesma virada. Os
## tipos pedidos são exatamente os que a loja já mede sozinha, então não há
## mecânica nova para aprender — muda só o fôlego que a casa passa a exigir. Cada
## facção tem a sua, e fechar uma delas é o que empurra o prestígio daquela gente.
## As três marcadas com "exclusive" só sobem ao balcão quando a forja já está no
## topo: elas pedem peça Lendária entregue, e pagam como quem contrata uma lenda.
const COMMISSIONS: Array[Dictionary] = [
	{
		"faction": "aventureiros",
		"name": "Mochila cheia da Tropa",
		"days": 5,
		"stages": [
			{"type": "craft", "target": 5, "gold": 55, "xp": 40},
			{"type": "customers", "target": 8, "gold": 70, "xp": 50},
			{"type": "gold", "target": 260, "gold": 95, "xp": 70},
		],
		"bonus_gold": 170, "bonus_rep": 5, "bonus_xp": 120, "bonus_standing": 4,
	},
	{
		"faction": "mercadores",
		"name": "Vitrine do Balcão Novo",
		"days": 6,
		"stages": [
			{"type": "gold", "target": 220, "gold": 60, "xp": 45},
			{"type": "customers", "target": 12, "gold": 85, "xp": 55},
			{"type": "craft", "target": 10, "gold": 110, "xp": 75},
		],
		"bonus_gold": 210, "bonus_rep": 6, "bonus_xp": 140, "bonus_standing": 5,
	},
	{
		"faction": "guildas",
		"name": "Selo de Confiança da Guilda",
		"days": 7,
		"stages": [
			{"type": "craft", "target": 12, "gold": 90, "xp": 65},
			{"type": "rare", "target": 2, "gold": 120, "xp": 80},
			{"type": "gold", "target": 380, "gold": 150, "xp": 95},
		],
		"bonus_gold": 260, "bonus_rep": 7, "bonus_xp": 165, "bonus_standing": 6,
	},
	{
		"faction": "nobres",
		"name": "Encomenda Reservada da Corte",
		"days": 8,
		"stages": [
			{"type": "customers", "target": 16, "gold": 110, "xp": 70},
			{"type": "gold", "target": 520, "gold": 160, "xp": 100},
			{"type": "rare", "target": 3, "gold": 190, "xp": 120},
		],
		"bonus_gold": 320, "bonus_rep": 8, "bonus_xp": 190, "bonus_standing": 7,
	},
	{
		"faction": "submundo",
		"name": "Dívida de Favores do Coletor",
		"days": 9,
		"stages": [
			{"type": "rare", "target": 3, "gold": 150, "xp": 95},
			{"type": "craft", "target": 16, "gold": 185, "xp": 115},
			{"type": "gold", "target": 700, "gold": 230, "xp": 140},
		],
		"bonus_gold": 400, "bonus_rep": 10, "bonus_xp": 230, "bonus_standing": 8,
	},
	{
		"faction": "guildas",
		"name": "Obra do Grêmio-Mestre",
		"exclusive": true,
		"days": 9,
		"stages": [
			{"type": "craft", "target": 14, "gold": 200, "xp": 120},
			{"type": "legendary", "target": 1, "gold": 340, "xp": 180},
			{"type": "gold", "target": 900, "gold": 260, "xp": 150},
		],
		"bonus_gold": 540, "bonus_rep": 12, "bonus_xp": 300, "bonus_standing": 9,
	},
	{
		"faction": "nobres",
		"name": "Retábulo de Honra da Rainha",
		"exclusive": true,
		"days": 10,
		"stages": [
			{"type": "legendary", "target": 1, "gold": 360, "xp": 190},
			{"type": "customers", "target": 20, "gold": 220, "xp": 130},
			{"type": "gold", "target": 1200, "gold": 320, "xp": 180},
		],
		"bonus_gold": 660, "bonus_rep": 14, "bonus_xp": 340, "bonus_standing": 11,
	},
	{
		"faction": "submundo",
		"name": "O Encomendador Sem Rosto",
		"exclusive": true,
		"days": 11,
		"stages": [
			{"type": "rare", "target": 4, "gold": 260, "xp": 150},
			{"type": "legendary", "target": 2, "gold": 480, "xp": 240},
			{"type": "gold", "target": 1500, "gold": 380, "xp": 210},
		],
		"bonus_gold": 820, "bonus_rep": 16, "bonus_xp": 400, "bonus_standing": 13,
	},
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
var commission_label: Label
var commission_button: Button
var forge_box: VBoxContainer
var forge_mastery_label: Label
var endings_label: Label
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
var card_bonus_label: Label
var upkeep_label: Label
var day_report_label: Label
var branch_summary_label: Label
var branch_labels: Array = []
var branch_buttons: Array = []
var staff_summary_label: Label
var queue_label: Label
var staff_labels: Array = []
var staff_buttons: Array = []
var arc_summary_label: Label
var arc_labels: Array = []
var arc_desc_labels: Array = []
var arc_buttons: Array = []
var spec_summary_label: Label
var spec_labels: Array = []
var spec_state_labels: Array = []
var spec_buttons: Array = []
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
var romance_label: Label
var romance_button: Button
var arc_label: Label
var origin_label: Label
var origin_button: Button
var prestige_box: VBoxContainer
var prestige_label: Label
var prestige_perk_buttons: Array = []
var prestige_button: Button
var adult_toggle_button: Button
var save_file_dialog: FileDialog
var hard_reset_dialog: ConfirmationDialog
var recover_theft_button: Button
var fury_label: Label
var seller_portrait: TextureRect
var reaction_label: Label
var seller_speech_label: Label
var customer_tween: Tween
var _customer_walk_tween: Tween
var _timed_ui_refresh_accumulator: float = 0.0
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
## Quantos transeuntes o salão comporta ao mesmo tempo. O elenco tem dezesseis
## corpos justamente para não repetir, mas sala cheia de gente andando tapa a
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
## Móveis pintados que ficam NA FRENTE do elenco, por sala, em coordenadas normais
## batendo com o STRETCH_SCALE do fundo. Cada vaga aceita um Retângulo ou uma lista
## de quatro cantos (superior esquerdo, superior direito, inferior direito, inferior
## esquerdo): o contorno inclinado faz a borda de cima seguir o tampo pintado, que
## na perspectiva nunca é horizontal, e a figura some na linha do móvel em vez de
## dentro de um caixote. É o que faz a visita sumir de cintura para baixo ao passar
## atrás do balcão.
const STAGE_ROOM_PROPS := {
	"res://assets/shop_scene.png": [
		[Vector2(0.437, 0.487), Vector2(1.0, 0.512), Vector2(1.0, 1.0), Vector2(0.437, 1.0)],
		[Vector2(0.0, 0.575), Vector2(0.187, 0.635), Vector2(0.187, 1.0), Vector2(0.0, 1.0)],
	],
	"res://assets/forge_scene.png": [Rect2(0.0, 0.555, 0.165, 0.445), Rect2(0.77, 0.60, 0.23, 0.40), Rect2(0.655, 0.525, 0.095, 0.15)],
	"res://assets/library_room_scene.png": [Rect2(0.225, 0.42, 0.13, 0.30), Rect2(0.0, 0.52, 0.215, 0.21), Rect2(0.78, 0.525, 0.205, 0.195)],
	"res://assets/sanctum_room_scene.png": [Rect2(0.0, 0.53, 0.14, 0.17), Rect2(0.862, 0.53, 0.138, 0.17), Rect2(0.235, 0.515, 0.055, 0.15), Rect2(0.71, 0.505, 0.055, 0.15)],
}
## Móveis que ocupam uma faixa de profundidade do piso: mais ao fundo eles
## escondem a figura; mais perto da câmera, a figura passa na frente. Cada valor
## corresponde, na mesma ordem, a um recorte de STAGE_ROOM_PROPS.
const STAGE_ROOM_PROP_DEPTHS := {
	"res://assets/library_room_scene.png": [0.32, 0.40, 0.40],
	"res://assets/sanctum_room_scene.png": [0.56, 0.56, 0.39, 0.39],
}
## Quantos contornos de móvel o shader aguenta ao mesmo tempo.
const STAGE_PROP_SLOTS := 8
## Faixa de piso por onde o elenco anda em cada sala, em fração da largura. Na
## recepção o balcão cobre o resto do salão: quem passasse por ali ficaria só com
## a cabeça de fora, então o transeunte patrulha o piso visível e volta.
const STAGE_ROOM_WALK := {
	"res://assets/shop_scene.png": Vector2(0.20, 0.42),
}
## O caminho da porta até o balcão, em (fração da largura, profundidade do chão),
## sem contar o próprio balcão. É a trilha que decide o que o visitante passa por
## trás: ela recua para o fundo ao cruzar o móvel pintado e volta para a frente da
## sala no chão livre, em vez de atravessar a loja na linha de frente.
const STAGE_ROOM_DOOR := {
	"res://assets/shop_scene.png": [Vector2(0.02, 0.12), Vector2(0.24, 0.34)],
	"res://assets/forge_scene.png": [Vector2(0.02, 0.12), Vector2(0.26, 0.30)],
	"res://assets/library_room_scene.png": [Vector2(0.98, 0.12), Vector2(0.72, 0.30)],
	"res://assets/sanctum_room_scene.png": [Vector2(0.02, 0.10), Vector2(0.30, 0.30)],
}
## Profundidade da quarta parede: abaixo de 1.0 o pé ainda pisa no chão pintado;
## daqui para baixo a figura entra cortada pela beirada da tela.
const STAGE_FOURTH_WALL_DEPTH := 1.42
## A porta de verdade é a do fundo, mas a visita não entra por ela: o tapete nasce
## no pé da tela, então quem chega vem da quarta parede, entrando gigante e
## cortado pela beirada de baixo e encolhendo até o ponto de fuga do salão. A
## ordem é do mais perto da câmera até o primeiro ponto do chão da sala.
const STAGE_ROOM_ARRIVE := {
	"res://assets/shop_scene.png": [Vector2(0.34, STAGE_FOURTH_WALL_DEPTH), Vector2(0.36, 1.00), Vector2(0.40, 0.90)],
	"res://assets/forge_scene.png": [Vector2(0.42, STAGE_FOURTH_WALL_DEPTH), Vector2(0.40, 1.00), Vector2(0.42, 0.90)],
	"res://assets/library_room_scene.png": [Vector2(0.52, STAGE_FOURTH_WALL_DEPTH), Vector2(0.50, 1.00), Vector2(0.48, 0.90)],
	"res://assets/sanctum_room_scene.png": [Vector2(0.46, STAGE_FOURTH_WALL_DEPTH), Vector2(0.44, 1.00), Vector2(0.46, 0.90)],
}
## Onde a fila espera, do primeiro (mais perto do balcão) ao último degrau, na
## lateral do tapete: quem espera não tapa a chefe nem atravessa o salão, e o corpo
## que sobe para ser atendido sai exatamente deste lugar.
##
## Nenhum x desta lista pode cair sob o contorno de um móvel que a tela desenha na
## frente de tudo: a fila é o lugar onde o freguês passa meio minuto parado, e corpo
## engolido pelo balcão pintado é cliente invisível. A MEDIÇÃO manda aqui, não o
## gosto — ver `tools/probes/caminhos.gd`, que roda a Auditoria de oclusão e imprime
## a fração do corpo escondida em cada ponto de chão do jogo. O balcão esquerdo da
## loja acaba em x=0,187, o da forja em x=0,165; na biblioteca a estante direita fica
## a 0,40 de profundidade, então a fila passa toda pela esquerda dela. A porta é a
## única exceção: ela engole de propósito, porque é assim que o corpo sai da sala.
const STAGE_ROOM_QUEUE := {
	"res://assets/shop_scene.png": [Vector2(0.27, 0.70), Vector2(0.24, 0.60), Vector2(0.225, 0.50), Vector2(0.21, 0.40), Vector2(0.20, 0.30), Vector2(0.19, 0.22)],
	"res://assets/forge_scene.png": [Vector2(0.235, 0.70), Vector2(0.215, 0.60), Vector2(0.20, 0.50), Vector2(0.19, 0.40), Vector2(0.182, 0.30), Vector2(0.175, 0.22)],
	"res://assets/library_room_scene.png": [Vector2(0.62, 0.70), Vector2(0.65, 0.60), Vector2(0.68, 0.50), Vector2(0.71, 0.40), Vector2(0.73, 0.30), Vector2(0.75, 0.22)],
	"res://assets/sanctum_room_scene.png": [Vector2(0.28, 0.70), Vector2(0.245, 0.60), Vector2(0.22, 0.50), Vector2(0.20, 0.40), Vector2(0.182, 0.30), Vector2(0.168, 0.22)],
}
## Quanto o chão desce por ponto de profundidade na quarta parede, em fração da
## altura da tela. Sem isso o corpo entraria flutuando na borda em vez de subir do
## fora da cena.
const STAGE_FOURTH_FLOOR_DROP := 0.78
## Quantos pontos de fila a sala desenha e quantos batem na porta num só tique no
## teto da fama. O resto espera fora de cena: o número do painel conta todos.
const QUEUE_SPOTS := 6
## Tique que um espera antes de desistir, somado à paciência do próprio perfil.
## Fama sem balcão que dê conta é cliente perdido, e é isso que segura a porta.
const QUEUE_PATIENCE_TICKS := 4
const QUEUE_LIMIT := 12
## Vitrines de cada sala, em (fração da largura, profundidade do chão): é onde quem
## foi bem atendido se detém para olhar a mercadoria antes de sair. A profundidade
## fica na frente do móvel, para a parada não esconder o corpo inteiro.
const STAGE_ROOM_BROWSE := {
	"res://assets/shop_scene.png": [Vector2(0.26, 0.62), Vector2(0.33, 0.80)],
	"res://assets/forge_scene.png": [Vector2(0.60, 0.55), Vector2(0.20, 0.66)],
	"res://assets/library_room_scene.png": [Vector2(0.29, 0.58), Vector2(0.87, 0.48)],
	"res://assets/sanctum_room_scene.png": [Vector2(0.62, 0.50), Vector2(0.37, 0.60)],
}
## Poses que um cliente satisfeito faz parado diante de uma prateleira.
const STAGE_BROWSE_POSES := ["curiosidade", "pensativo", "aprovacao", "aponta", "risada", "felicidade"]
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
const STAGE_ROOM_LIGHTS := {
	"res://assets/shop_scene.png": [Vector2(0.08, 0.22), Vector2(0.50, 0.05), Vector2(0.91, 0.18), Vector2(0.32, 0.48), Vector2(0.64, 0.42)],
	"res://assets/forge_scene.png": [Vector2(0.52, 0.24), Vector2(0.08, 0.16), Vector2(0.91, 0.18)],
	"res://assets/library_room_scene.png": [Vector2(0.16, 0.18), Vector2(0.82, 0.20), Vector2(0.50, 0.08)],
	"res://assets/sanctum_room_scene.png": [Vector2(0.24, 0.20), Vector2(0.76, 0.20), Vector2(0.50, 0.08)],
}
## Altura de um adulto em primeiro plano. As camadas de trás escalam em cima dela
## para casar com a perspectiva da arte.
const STAGE_FIGURE_HEIGHT := 250.0
## Onde a visita nasce e onde ela encosta no balcão. Entrar lá do fundo, onde a
## estante pega, e vir até a frente da sala é o que faz o cliente passar POR TRÁS
## do móvel pintado em vez de atravessar por cima dele.
const STAGE_ENTRY_DEPTH := 0.12
const STAGE_FRONT_DEPTH := 0.82
## Janela de uma visita: ele tem de chegar ao balcão antes do próximo tique, mas
## sem correr parado.
const STAGE_ARRIVE_SECONDS := 2.8
## Quanto do tique a chegada ocupa. O resto é o respiro no balcão: sem ele o
## freguês encosta no balcão no mesmo instante em que o próximo corpo nasce na
## quarta parede, e a leitura é um boneco refazendo o trajeto sem fim.
const STAGE_ARRIVE_TICK_FRACTION := 0.62
const OFFLINE_FARM_MAX_SECONDS := 12.0 * 60.0 * 60.0
const OFFLINE_FARM_BRANCH_PERIOD := 60.0 * 60.0
const OFFLINE_REPORT_MIN_SECONDS := 60.0
## A chegada acompanha o intervalo do relógio do mundo para terminar antes da
## próxima visita; o ciclo de sprites e o passo aceleram juntos.
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
var stage_occluder: TextureRect
var _stage_depth_occluders: Array[TextureRect] = []
var ui_layer: Control
var stage_seller: Control
var stage_seller_body: Control
var stage_customer: Control
var _stage_walkers: Array[Dictionary] = []
var _stage_retired: Array[Dictionary] = []
var _stage_walker_timer: float = 2.0
var _lane_depths: Array[float] = [0.08, 0.40, 0.82, STAGE_FOURTH_WALL_DEPTH]
var _lane_scales: Array[float] = [0.56, 0.78, 1.0, 1.45]
var _lane_alphas: Array[float] = [0.90, 0.96, 1.0, 1.0]
## A fila de atendimento: quem bateu à porta e ainda não chegou ao balcão. Cada
## entrada é o perfil sorteado (nome, retrato, orçamento) mais o tique em que ela
## entrou e o limite de espera. Os corpos em cena são no máximo QUEUE_SPOTS; o
## resto espera fora da tela e só aparece no número do painel.
var service_queue: Array[Dictionary] = []
## Quantos desistiram da fila nesta vida. É o preço da fama sem balcão.
var queue_walkouts: int = 0
## Os que saíram da fila só desde a última virada do dia, para o balanço da manhã
## poder dizer quantos clientes o dia perdeu na porta.
var day_walkouts: int = 0
var _stage_waiters: Array[Dictionary] = []
var _stage_back_band: Control
var _market_top_guard: Control
var _stage_room: String = "res://assets/shop_scene.png"
var _seller_home: Vector2 = Vector2.ZERO
var _stage_layout_key := Vector2(-1.0, -1.0)
var _seller_lean_tween: Tween
## A coreografia do convite: espera a chegada, junta o par e arma as poses. Click
## repetido cancela a anterior, senão duas cenas brigariam pela mesma chefe.
var _romance_cue: Tween
var _customer_bob: Tween
## Se o balcão atendeu bem quem está no palco agora. Decide se a visita dá uma
## olhada nas prateleiras na saída ou vai direto à porta.
var _customer_served: bool = false
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
## Quem está no salão neste instante, vazio para visita avulsa. A cena de romance
## precisa saber se o par já está em cena ou se tem de chamá-lo de volta.
var current_regular_id: String = ""
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
## A escada de confiança de um freguês: cada degrau cobra visitas de balcão e
## ouro na hora, e paga de volta para sempre na conta dele. O degrau três é o
## beijo sem mostrar nada — a cena corta antes, e o que fica no save é o bônus,
## não a imagem.
const ROMANCE_STEPS: Array[Dictionary] = [
	{"name": "Convite", "bond": 5, "gold": 40, "pose": "ousadia", "price": 0.08, "tip": 0, "bond_bonus": 1, "xp": 12, "rep": 1},
	{"name": "Encontro", "bond": 9, "gold": 120, "pose": "danca", "price": 0.16, "tip": 0, "bond_bonus": 1, "xp": 25, "rep": 2},
	{"name": "Momento a dois", "bond": 15, "gold": 280, "pose": "beijo", "price": 0.25, "tip": 20, "bond_bonus": 2, "xp": 45, "rep": 3},
]
## O quadro que a tela mostra em cada degrau: as duas figuras se aproximam no
## mesmo salão, a pose bate com o texto, e a casa não filma o resto.
const ROMANCE_SCENES: Array[String] = [
	"A chefe vira a placa de FECHADO, atravessa o balcão e chama %s pelo nome: “Hoje a rodada é minha.”",
	"As luzes da loja baixam. Uma mesa aparece no meio do salão, e %s puxa a cadeira da chefe antes de sentar.",
	"O salão fica às escuras menos num canto, onde a chefe e %s riem baixo até a última vela apagar. O resto a casa não mostra."
]
## Os quatro atos da ficha de um freguês, na ordem em que a loja os descobre. Não
## há timer nem escolha: cada ato é derivado de um progresso que o jogo já mede —
## a primeira visita, o nível Conhecido, o capítulo pessoal e o convite pago. O
## prêmio cresce porque a ficha vale mais quando ela já custou dias de balcão.
const ARC_REWARDS: Array[Dictionary] = [
	{"gold": 20, "rep": 1, "xp": 10},
	{"gold": 45, "rep": 2, "xp": 20},
	{"gold": 90, "rep": 3, "xp": 35},
	{"gold": 160, "rep": 5, "xp": 60},
]

## Prateleira do primeiro dia, guardada antes de qualquer save tocar nela: é com
## esse mesmo estoque que cada vida nova abre o balcão.
func _init() -> void:
	for item in products:
		_starting_shelf[str(item["id"])] = int(item["stock"])

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
	_mark_day_start()
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
	_apply_offline_progress()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		_save_game()

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
	_timed_ui_refresh_accumulator += delta * world_speed()
	if _timed_ui_refresh_accumulator >= 0.25:
		_timed_ui_refresh_accumulator = 0.0
		_refresh_timed_ui()
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

func _world_seconds_since_tick() -> float:
	if not is_instance_valid(world_timer) or world_timer.is_stopped():
		return 0.0
	return clampf((world_timer.wait_time - world_timer.time_left) * world_speed(), 0.0, 3.0)

func _apply_offline_progress() -> void:
	if _offline_elapsed_seconds <= 0.0:
		return
	var elapsed := _offline_elapsed_seconds
	_offline_elapsed_seconds = 0.0
	var crafts_before := total_crafted
	var expeditions_before := expeditions_done
	var imp_stock_before := int(products[0].get("stock", 0))
	# Um acerto de filial por hora real evita multiplicar renda por dias de jogo de 60 segundos.
	var branch_daily_net := float(Branches.expected_profit(branches, _branch_care()) - Branches.total_upkeep(branches))
	if branches.is_empty() or branch_daily_net <= 0.0:
		_offline_branch_fraction = 0.0
	var branch_progress := maxf(0.0, branch_daily_net) * elapsed / OFFLINE_FARM_BRANCH_PERIOD + _offline_branch_fraction
	var branch_earnings := int(floor(branch_progress))
	_offline_branch_fraction = branch_progress - float(branch_earnings)
	var imp_cycles := int(floor(elapsed / 9.0))
	_advance_craft_jobs(elapsed, true)
	_advance_expeditions(elapsed, true)
	Sanctum.advance(active_buffs, elapsed)
	if imp_hired:
		for _cycle in range(imp_cycles):
			_imp_work()
	gold += branch_earnings
	_check_achievements()
	last_event = "Durante %.1f h fora da loja: %d forja(s), %d expedição(ões), %d poção(ões) do diabrete e +%d ouro líquido após a manutenção das filiais. Clientes, aluguel e salários ficaram pausados." % [
		elapsed / 3600.0,
		total_crafted - crafts_before,
		expeditions_done - expeditions_before,
		maxi(0, int(products[0].get("stock", 0)) - imp_stock_before),
		branch_earnings,
	]
	_save_game()
	_refresh_ui()
	if elapsed >= OFFLINE_REPORT_MIN_SECONDS and not day_auto_ok:
		offline_dialog = AcceptDialog.new()
		offline_dialog.title = "Resumo do período offline"
		offline_dialog.dialog_text = last_event + "\n\nO farm offline é limitado a 12 horas e não avança clientes, eventos aleatórios do salão ou dias de loja."
		offline_dialog.confirmed.connect(_close_offline_report)
		add_child(offline_dialog)
		world_timer.stop()
		offline_dialog.popup_centered(Vector2i(720, 320))

func _close_offline_report() -> void:
	if is_instance_valid(offline_dialog):
		offline_dialog.queue_free()
	offline_dialog = null
	if is_instance_valid(world_timer) and not is_instance_valid(day_layer) \
			and not is_instance_valid(origin_layer) and not is_instance_valid(ending_layer):
		world_timer.start()

func _refresh_timed_ui() -> void:
	var elapsed := _world_seconds_since_tick()
	if is_instance_valid(forge_status_label):
		if craft_jobs.is_empty():
			forge_status_label.text = "Forja: livre"
		else:
			var queue_text: Array[String] = []
			for job in craft_jobs:
				var queued_item: Dictionary = products[int(job.get("index", 0))]
				var remaining := maxf(0.0, float(job.get("remaining", 0.0)) - elapsed)
				queue_text.append("%s %.1fs" % [queued_item["name"], remaining])
			forge_status_label.text = "Forja: " + " | ".join(queue_text)
	if is_instance_valid(ritual_label):
		ritual_label.text = Sanctum.summary(active_buffs, elapsed)
	for i in range(mini(ritual_labels.size(), Sanctum.DATA.size())):
		var ritual: Dictionary = Sanctum.DATA[i]
		var ritual_id := str(ritual["id"])
		if Sanctum.is_active(active_buffs, ritual_id):
			ritual_labels[i].text = "✦ Em curso: %s" % Sanctum.remaining_label(active_buffs, ritual_id, elapsed)
	for i in range(mini(expedition_labels.size(), Expedition.size())):
		var destination: Dictionary = Expedition.DATA[i]
		var trip := _expedition_on_route(str(destination["id"]))
		if not trip.is_empty():
			var trip_summary := _expedition_trip_summary(trip, elapsed)
			expedition_labels[i].text = trip_summary
			expedition_labels[i].add_theme_color_override("font_color", Color(1.0, 0.52, 0.38) if trip_summary.contains("⚔") else Color(1.0, 0.84, 0.55))
	if is_instance_valid(expedition_active_label) and not expeditions.is_empty():
		var routes: Array[String] = []
		for trip in expeditions:
			routes.append(_expedition_trip_summary(trip, elapsed))
		expedition_active_label.text = "Vagas: %d/%d — %s" % [expeditions.size(), _expedition_slots(), "  |  ".join(routes)]

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
	for entry in _stage_waiters:
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
				if mover != null and mover.is_valid():
					mover.kill()
			break
	if crowd < 0:
		for i in range(_stage_waiters.size()):
			if _stage_waiters[i]["node"] == walker:
				var waiting: Dictionary = _stage_waiters[i]
				crowd = int(waiting.get("crowd", -1))
				_stage_waiters.remove_at(i)
				var still: Tween = waiting.get("trip", null)
				if still != null and still.is_valid():
					still.kill()
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
	# Primeiro o cliente: ele vira transeunte e entra na lista, aí o laço abaixo
	# o devolve para os bastidores junto com o resto do elenco.
	_stage_customer_leaves()
	for entry in _stage_walkers.duplicate():
		var walker := entry["node"] as Control
		if is_instance_valid(walker):
			_retire_walker(walker)
	for entry in _stage_waiters.duplicate():
		var waiting := entry["node"] as Control
		if is_instance_valid(waiting):
			_retire_walker(waiting)
	_stage_walkers.clear()
	_stage_waiters.clear()

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
	var layers: Array[Control] = [stage_layer]
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
	# A fila atravessa a porta junto com a loja: quem esperava na recepção espera no
	# mesmo degrau da sala nova, porque a espera é do balcão, não do cenário.
	_reline_waiters()

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

## O cliente do turno entra pela porta da sala e vem até o balcão seguindo a
## trilha do chão: ela recua para o fundo onde há móvel pintado, então ele passa
## POR TRÁS dele, como o resto do elenco, em vez de atravessar por cima.
func _stage_customer_arrives(portrait_index: int) -> void:
	if not is_instance_valid(stage_customer) or stage_layer.size.x <= 0:
		return
	if _customer_walk_tween != null and _customer_walk_tween.is_valid():
		_customer_walk_tween.kill()
	_customer_walk_tween = null
	var body := absi(portrait_index) % STAGE_CROWD_BODIES.size()
	_dress_stage_poses(stage_customer, body, _lane_height(2))
	# O corpo do freguês do turno é dele. Se um transeunte já o vestia, o
	# transeunte se apaga: dois do mesmo rosto na tela pareciam um sprite só
	# colado duas vezes.
	for entry in _stage_walkers.duplicate():
		if int(entry.get("crowd", -1)) == body:
			_retire_walker(entry["node"] as Control)
	for entry in _stage_waiters.duplicate():
		if int(entry.get("crowd", -1)) == body:
			_retire_walker(entry["node"] as Control)
	var front := _lane(2)
	_customer_served = false
	# O corpo é outro cliente agora: se o anterior saiu de cena com uma pose no ar,
	# a trava não pode congelar o passo deste.
	stage_customer.set_meta("emotion_pose", false)
	# Ele nasce do lado de cá da tela, grande demais para caber: a opacidade sobe
	# junto com os primeiros passos para a visita entrar andando, não piscada.
	stage_customer.modulate = Color(1.0, 0.95, 0.98, 0.0)
	stage_customer.rotation_degrees = 0.0
	stage_customer.pivot_offset = stage_customer.size / 2.0
	stage_customer.set_meta("walk_frames", _stage_crowd_frames(body).size())
	stage_customer.visible = true
	var path := _room_path()
	_place_stage_figure(stage_customer, path[0].y, path[0].x)
	if _customer_bob != null and _customer_bob.is_valid():
		_customer_bob.kill()
	# A chegada tem de caber no tique. Quando a trilha é longa, o corpo é quem
	# aperta o passo: a batida do pé encurta na mesma proporção da caminhada, e
	# ninguém desliza pelo chão nem corre com as pernas paradas.
	var arrival_window := STAGE_ARRIVE_SECONDS
	if is_instance_valid(world_timer) and not world_timer.is_stopped():
		arrival_window = minf(arrival_window, world_timer.wait_time * STAGE_ARRIVE_TICK_FRACTION)
	var path_time := _path_time(stage_customer, path)
	var pace := maxf(1.0, path_time / maxf(0.25, arrival_window))
	# Quanto falta para ele parar, guardado no corpo: uma cena que queira o
	# freguês plantado no balcão precisa esperar exatamente esse tempo.
	stage_customer.set_meta("arrive_left", path_time / pace)
	var walk := create_tween()
	_walk_path(walk, stage_customer, path, pace)
	walk.tween_callback(_stage_customer_stops)
	_customer_walk_tween = walk
	var reveal := create_tween()
	reveal.tween_property(stage_customer, "modulate:a", float(front["alpha"]), 0.5)
	var step_time := STAGE_STEP_SECONDS / pace
	_customer_bob = create_tween().set_loops()
	_customer_bob.tween_property(stage_customer, "rotation_degrees", 1.6, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_customer_bob.tween_callback(_advance_stage_frame.bind(stage_customer))
	_customer_bob.tween_property(stage_customer, "rotation_degrees", -1.6, step_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_customer_bob.tween_callback(_advance_stage_frame.bind(stage_customer))

## A trilha da quarta parede até o balcão, já em pixels. O primeiro ponto está com
## o pé fora da tela: a visita sobe do chão do lado de cá, gigante e cortada, e
## encolhe no caminho do ponto de fuga em vez de atravessar a loja na linha de
## frente. Sala sem chegada escrita entra pela porta antiga.
func _room_path() -> Array[Vector2]:
	var path: Array[Vector2] = []
	for point in STAGE_ROOM_ARRIVE.get(_stage_room, []):
		path.append(point)
	if path.is_empty():
		for point in STAGE_ROOM_DOOR.get(_stage_room, []):
			path.append(point)
	if path.is_empty():
		path.append(Vector2(0.0, STAGE_ENTRY_DEPTH))
	path.append(Vector2(_room_meet().y, STAGE_FRONT_DEPTH))
	for i in range(path.size()):
		path[i] = Vector2(path[i].x * stage_layer.size.x, path[i].y)
	return path

## A saída é pela porta simbólica do fundo, não pelo pé da tela: o corpo anda para
## dentro da sala, encolhe até o ponto de fuga e some ali, porque a loja tem uma
## porta só e quem entra pela frente tem de sair pelo fundo.
func _room_exit_path() -> Array[Vector2]:
	var door: Array = STAGE_ROOM_DOOR.get(_stage_room, [Vector2(0.02, STAGE_ENTRY_DEPTH)])
	var path: Array[Vector2] = []
	for i in range(door.size() - 1, -1, -1):
		path.append(door[i])
	var last: Vector2 = path[path.size() - 1]
	path.append(Vector2(last.x, maxf(-0.2, last.y - 0.16)))
	for i in range(path.size()):
		path[i] = Vector2(path[i].x * stage_layer.size.x, path[i].y)
	return path

## Planta uma figura num ponto do chão da sala. A profundidade decide o tamanho,
## a linha onde o pé encosta e o quanto ela some na névoa do fundo; o x é o centro
## do corpo. Guardar a profundidade no meta é o que permite a ela voltar a andar
## de onde está sem adivinhar o próprio tamanho.
func _place_stage_figure(node: Control, depth: float, center_x: float) -> void:
	var lane := _lane_at(depth)
	var figure_scale: float = lane["scale"]
	node.set_meta("stage_depth", depth)
	node.z_index = _stage_z_for_depth(depth)
	node.scale = Vector2(figure_scale, figure_scale)
	node.position = Vector2(
		center_x - node.size.x * 0.5,
		float(lane["floor_y"]) - node.size.y * (1.0 + figure_scale) * 0.5
	)

func _stage_z_for_depth(depth: float) -> int:
	return roundi(inverse_lerp(0.0, STAGE_FOURTH_WALL_DEPTH, clampf(depth, 0.0, STAGE_FOURTH_WALL_DEPTH)) * 400.0)

func _stage_step_to(t: float, node: Control, from_x: float, to_x: float, from_depth: float, to_depth: float) -> void:
	if not is_instance_valid(node):
		return
	_place_stage_figure(node, lerpf(from_depth, to_depth, t), lerpf(from_x, to_x, t))

## Quanto um corpo leva para ir de um ponto do chão a outro. A velocidade é a do
## tamanho médio do trajeto, porque o passo longe da câmera cobre menos tela.
func _stage_walk_time(from_depth: float, from_x: float, to_depth: float, to_x: float) -> float:
	var from := _lane_at(from_depth)
	var to := _lane_at(to_depth)
	var distance := Vector2(from_x, float(from["floor_y"])).distance_to(Vector2(to_x, float(to["floor_y"])))
	return distance / maxf(30.0, STAGE_WALK_SPEED * (float(from["scale"]) + float(to["scale"])) * 0.5)

## Quanto a trilha inteira leva no passo natural, de onde a figura está agora.
func _path_time(node: Control, path: Array[Vector2]) -> float:
	var total := 0.0
	var depth := float(node.get_meta("stage_depth", STAGE_FRONT_DEPTH))
	var x := node.position.x + node.size.x * 0.5
	for point in path:
		total += _stage_walk_time(depth, x, point.y, point.x)
		depth = point.y
		x = point.x
	return total

## Acrescenta a uma caminhada o percurso pela lista de pontos do chão. O ponto de
## partida é passado adiante de uma perna para a outra porque a cadeia inteira é
## montada antes do primeiro passo: quem lesse a própria posição veria o corpo
## ainda no começo do caminho, e cada perna voltaria à quarta parede em vez de
## continuar de onde a anterior parou.
func _walk_path(trip: Tween, node: Control, path: Array[Vector2], pace := 1.0, from_point := Vector2(INF, INF)) -> void:
	var from := from_point
	if is_inf(from.x):
		from = Vector2(float(node.get_meta("stage_depth", STAGE_FRONT_DEPTH)), node.position.x + node.size.x * 0.5)
	for point in path:
		_stroll_leg(trip, node, point.y, point.x, pace, from)
		from = Vector2(point.y, point.x)

## Um trecho da caminhada, com a meia-volta antes do primeiro passo. Trechos sem
## comprimento não entram na fila: tween de duração zero só emite aviso.
func _stroll_leg(trip: Tween, node: Control, to_depth: float, to_x: float, pace := 1.0, from_point := Vector2(INF, INF)) -> void:
	var from_depth := float(node.get_meta("stage_depth", to_depth)) if is_inf(from_point.x) else from_point.x
	var from_x := node.position.x + node.size.x * 0.5 if is_inf(from_point.y) else from_point.y
	var time := _stage_walk_time(from_depth, from_x, to_depth, to_x) / pace
	if time < 0.05:
		return
	trip.tween_callback(_set_stage_flip.bind(node, to_x < from_x))
	trip.tween_method(_stage_step_to.bind(node, from_x, to_x, from_depth, to_depth), 0.0, 1.0, time)

## O cliente encosta no balcão: para de andar, apruma o corpo e só então a chefe
## se debruça para atendê-lo.
func _stage_customer_stops() -> void:
	_customer_walk_tween = null
	if _customer_bob != null and _customer_bob.is_valid():
		_customer_bob.kill()
	_customer_bob = null
	if is_instance_valid(stage_customer):
		stage_customer.rotation_degrees = 0.0
		stage_customer.set_meta("arrive_left", 0.0)
		_set_stage_frame(stage_customer, 0)
		# Parado no balcão ele não tem mais ciclo de passo: o pose de emoção que
		# vier precisa devolver o corpo para as pernas juntas, não para o meio de
		# uma passada que já terminou.
		stage_customer.set_meta("walk_frames", 1)
	# Quem chega cumprimenta antes de ser atendido, e a chefe devolve o aceno.
	_show_stage_emotion(stage_customer, "aceno")
	_show_stage_emotion(stage_seller_body, "aceno")
	_seller_lean_in()

## Quem larga o balcão não evapora nem dispara para o lado: ele é devolvido ao
## salão como transeunte e anda até a porta, enquanto o corpo do turno fica livre
## para a próxima visita entrar pelo mesmo canto.
func _stage_customer_leaves() -> void:
	if not is_instance_valid(stage_customer) or not stage_customer.visible:
		return
	if _customer_walk_tween != null and _customer_walk_tween.is_valid():
		_customer_walk_tween.kill()
	_customer_walk_tween = null
	if _customer_bob != null and _customer_bob.is_valid():
		_customer_bob.kill()
	_customer_bob = null
	var body := int(stage_customer.get_meta("crowd", -1))
	var depth := float(stage_customer.get_meta("stage_depth", STAGE_FRONT_DEPTH))
	var center_x := stage_customer.position.x + stage_customer.size.x * 0.5
	var served := _customer_served
	stage_customer.visible = false
	if body < 0:
		return
	if _stage_walkers.size() >= STAGE_MAX_WALKERS:
		_retire_walker(_stage_walkers[0]["node"] as Control)
	_release_to_floor(body, depth, center_x, served)

## Quantos batem na porta neste tique: um sempre, mais um por degrau de fama, mais
## um para cada duas filiais abertas. É o que faz a loja começar quase vazia e
## terminar com gente esperando na rua — e é também o que faz a fama custar caro
## quando o balcão não dá conta.
func _arrivals_this_tick() -> int:
	var crowd := 1
	if reputation >= 12:
		crowd += 1
	if reputation >= 30:
		crowd += 1
	if reputation >= 55:
		crowd += 1
	crowd += int(float(branches.size()) / 2.0)
	return clampi(crowd, 1, QUEUE_LIMIT)

## Quanto um cliente topa esperar: o limite da casa mais a paciência do próprio
## perfil, o quanto a chefe já é querida e quantas mãos há no balcão. Charme é
## literalmente tempo de espera, e contratar também é.
func _queue_patience(profile: Dictionary) -> int:
	return QUEUE_PATIENCE_TICKS + int(profile.get("patience", 2)) + charm_rank / 2 + staff_hired.size()

## Manda para dentro quem o balcão não consegue atender agora. Cada um chega com o
## perfil sorteado na hora, então a fila é gente com retrato e orçamento, não um
## contador no painel.
func _flood_service_queue() -> int:
	var arrived := 0
	for i in range(maxi(0, _arrivals_this_tick() - 1)):
		if service_queue.size() >= QUEUE_LIMIT:
			break
		var profile: Dictionary = _draw_visitor_profile()
		var entry := {
			"profile": profile,
			"waited": 0,
			"limit": _queue_patience(profile),
		}
		service_queue.append(entry)
		_spawn_waiter(entry)
		arrived += 1
	return arrived

## A fila anda: um tique a mais para cada espera, e quem passa do próprio limite
## vai embora sem comprar. Devolve quantos saíram, para o balanço do dia saber que
## a porta também perde gente.
func _advance_service_queue() -> int:
	var gone := 0
	for entry in service_queue.duplicate():
		entry["waited"] = int(entry["waited"]) + 1
		if int(entry["waited"]) < int(entry["limit"]):
			continue
		service_queue.erase(entry)
		_desert_waiter(entry)
		gone += 1
	if gone > 0:
		# A fama cobra a virada em que o balcão não deu conta, não cobra cada corpo
		# que virou as costas: três desistências do mesmo tique valeriam três
		# pancadas e a loja nunca sairia do buraco que a própria fama cavou.
		reputation = maxi(0, reputation - 1)
		_reline_waiters()
	return gone

## Quem desistiu da fila: conta como cliente perdido e avisa no mural. Um som para
## a rajada inteira, porque a fila é justamente o que impede três visitas de
## tocarem o mesmo "sad" por cima uma da outra.
func _desert_waiter(entry: Dictionary) -> void:
	var profile: Dictionary = entry["profile"]
	var visitor_name := str(profile.get("name", "Um cliente"))
	queue_walkouts += 1
	disappointed_customers += 1
	day_walkouts += 1
	last_event = "%s esperou %d viradas na porta e foi comprar em outro beco. A chefe rangea os dentes: fila longa sem balcão que dê conta é loja com a placa de FECHADO." % [visitor_name, int(entry["waited"])]
	_show_feedback("✗ %s desistiu da fila." % visitor_name, Color(1.0, 0.55, 0.55))
	_dismiss_waiter(entry)
	audio.play("sad")

## O balcão atende primeiro quem já estava esperando: a fila não é enfeite, ela
## troca a ordem de quem entra. Sem ninguém esperando, sorteia a visita do tique.
func _next_served_profile() -> Dictionary:
	if service_queue.is_empty():
		return _draw_visitor_profile()
	var entry: Dictionary = service_queue[0]
	service_queue.pop_front()
	_dismiss_waiter(entry)
	_reline_waiters()
	return entry["profile"]

## O corpo de quem espera: entra pelo mesmo canto da visita, anda até o degrau da
## fila e fica parado ali, pensando na vida. Passou do tempo, ele se apaga.
func _spawn_waiter(entry: Dictionary) -> void:
	if not is_instance_valid(stage_layer) or stage_layer.size.x <= 0:
		return
	var spots: Array = STAGE_ROOM_QUEUE.get(_stage_room, [])
	if _stage_waiters.size() >= mini(QUEUE_SPOTS, spots.size()):
		return
	var profile: Dictionary = entry["profile"]
	var body := absi(int(profile.get("portrait", 0))) % STAGE_CROWD_BODIES.size()
	if _crowd_taken(body):
		return
	var node := _make_stage_poses(body, _lane_height(2))
	node.pivot_offset = node.size / 2.0
	node.set_meta("walk_frames", 1)
	stage_layer.add_child(node)
	stage_layer.move_child(node, stage_customer.get_index())
	_place_stage_figure(node, STAGE_FOURTH_WALL_DEPTH, float(spots[0].x) * stage_layer.size.x)
	_stage_waiters.append({"node": node, "crowd": body, "entry": entry, "trip": null})
	_show_stage_emotion(node, "pensativo")
	_reline_waiters()

## Recoloca todo mundo nos degraus da fila, na ordem de chegada: o primeiro some
## para o balcão e o resto dá um passo à frente, em vez de deixar buraco no meio.
func _reline_waiters() -> void:
	if not is_instance_valid(stage_layer) or stage_layer.size.x <= 0:
		return
	var spots: Array = STAGE_ROOM_QUEUE.get(_stage_room, [])
	if spots.is_empty():
		return
	for i in range(_stage_waiters.size()):
		var entry: Dictionary = _stage_waiters[i]
		var node := entry["node"] as Control
		if not is_instance_valid(node):
			continue
		var spot: Vector2 = spots[mini(i, spots.size() - 1)]
		var trip: Tween = entry["trip"]
		if trip != null and trip.is_valid():
			trip.kill()
		# Quem já está no degrau certo não recebe tween: uma caminhada de comprimento
		# zero só faria o motor reclamar de uma fila vazia de movimentos.
		var depth := float(node.get_meta("stage_depth", STAGE_FRONT_DEPTH))
		var here_x := node.position.x + node.size.x * 0.5
		var there_x := float(spot.x) * stage_layer.size.x
		if _stage_walk_time(depth, here_x, float(spot.y), there_x) < 0.06:
			entry["trip"] = null
			continue
		trip = create_tween()
		_stroll_leg(trip, node, float(spot.y), there_x)
		entry["trip"] = trip

## Tira o corpo da fila do cenário: quem subiu para o balcão apaga aqui, e o
## atendimento desenha o mesmo rosto no balcão.
func _dismiss_waiter(entry: Dictionary) -> void:
	for waiting in _stage_waiters.duplicate():
		if waiting.get("entry") == entry:
			_retire_walker(waiting["node"] as Control)
			return

## Aquele rosto já está em cena? A fila obedece à mesma lei do resto do elenco:
## dois do mesmo corpo na tela pareciam um sprite colado duas vezes.
func _crowd_taken(body: int) -> bool:
	for entry in _stage_walkers:
		if int(entry.get("crowd", -1)) == body:
			return true
	for entry in _stage_waiters:
		if int(entry.get("crowd", -1)) == body:
			return true
	return (
		is_instance_valid(stage_customer)
		and stage_customer.visible
		and int(stage_customer.get_meta("crowd", -1)) == body
	)

## Quantos corpos o salão está desenhando agora: transeuntes, quem espera na fila
## e quem está no balcão. É este o número do painel, para a contagem bater com a
## imagem em vez de contar a vida inteira da loja.
func _bodies_on_stage() -> int:
	var count := _stage_walkers.size() + _stage_waiters.size()
	if is_instance_valid(stage_customer) and stage_customer.visible:
		count += 1
	return count

## Apaga os corpos da fila sem mexer na fila: é o que a troca de sala e o reset
## fazem antes de desenhar a linha de novo no chão novo.
func _stage_clear_waiters() -> void:
	for waiting in _stage_waiters.duplicate():
		_retire_walker(waiting["node"] as Control)
	_stage_waiters.clear()

## Devolve um corpo ao salão. Bem atendido, ele ainda dá uma olhada nas
## prateleiras e acena antes de ir; saiu mal-humorado, atravessa sem parar.
func _release_to_floor(body: int, depth: float, center_x: float, served: bool) -> void:
	var stroller := _make_stage_poses(body, _lane_height(2))
	stroller.pivot_offset = stroller.size / 2.0
	stage_layer.add_child(stroller)
	# Um degrau abaixo de quem está no balcão agora: o recém-chegado vem vindo pelo
	# fundo e crescendo, e tem de passar na frente das costas de quem está indo.
	stage_layer.move_child(stroller, stage_customer.get_index())
	_place_stage_figure(stroller, depth, center_x)
	_set_stage_flip(stroller, false)
	var stride := create_tween().set_loops()
	stride.tween_property(stroller, "rotation_degrees", 1.6, STAGE_STEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	stride.tween_callback(_advance_stage_frame.bind(stroller))
	stride.tween_property(stroller, "rotation_degrees", -1.6, STAGE_STEP_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	stride.tween_callback(_advance_stage_frame.bind(stroller))
	var trip := create_tween()
	var from := Vector2(depth, center_x)
	var spots: Array = STAGE_ROOM_BROWSE.get(_stage_room, [])
	if served and not spots.is_empty():
		var spot: Vector2 = spots.pick_random()
		_stroll_leg(trip, stroller, spot.y, spot.x * stage_layer.size.x, 1.0, from)
		from = Vector2(spot.y, spot.x * stage_layer.size.x)
		trip.tween_callback(stroller.set_meta.bind("walk_frames", 1))
		trip.tween_callback(_show_stage_emotion.bind(stroller, str(STAGE_BROWSE_POSES.pick_random())))
		trip.tween_interval(1.7)
		trip.tween_callback(_show_stage_emotion.bind(stroller, "aceno"))
		trip.tween_interval(1.0)
		trip.tween_callback(stroller.set_meta.bind("walk_frames", _stage_crowd_frames(body).size()))
	var back := _room_exit_path()
	_walk_path(trip, stroller, back, 1.0, from)
	# No ponto de fuga o corpo some junto com a própria opacidade: sem o fade ele
	# ficaria plantado no rodapé da parede pintada, do tamanho de um boneco de
	# tabuleiro, e a sala perderia a ilusão de que a porta é longe.
	trip.tween_property(stroller, "modulate:a", 0.0, 0.55)
	trip.tween_callback(_discard_stroller.bind(stroller))
	_stage_walkers.append({"node": stroller, "crowd": body, "bob": null, "stride": stride, "trip": trip})

## O transeunte que saiu pela porta sai também da lista: ficasse, a sombra
## continuaria desenhando um corpo que já foi liberado.
func _discard_stroller(node: Control) -> void:
	for i in range(_stage_walkers.size()):
		if _stage_walkers[i]["node"] == node:
			var mover: Tween = _stage_walkers[i]["stride"]
			if mover != null and mover.is_valid():
				mover.kill()
			_stage_walkers.remove_at(i)
			break
	if is_instance_valid(node):
		node.queue_free()

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

## Profundidade contínua entre as faixas. O elenco anda por aqui: um transeunte
## pode ficar a meio caminho do fundo em vez de parar exatamente na linha onde a
## chefe atende, que é o que colava os dois corpos numa mancha só. Abaixo de 1.0
## começa a quarta parede: o chão desce para fora da tela e o corpo passa da
## escala da frente da sala, porque quem entra pelo pé do tapete chega perto
## demais para caber inteiro.
func _lane_at(depth: float) -> Dictionary:
	var floor_line: Vector2 = STAGE_ROOM_FLOOR.get(_stage_room, Vector2(0.60, 0.80))
	var floor_y := lerpf(floor_line.x, floor_line.y, clampf(depth, -0.25, 1.0))
	if depth > 1.0:
		floor_y += STAGE_FOURTH_FLOOR_DROP * (depth - 1.0)
	return {
		"floor_y": floor_y * stage_layer.size.y,
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
		stage_seller.z_index = _stage_z_for_depth(_lane_depths[1])
		# Enquanto o tween da chefe roda, ele é o dono da posição.
		if _seller_lean_tween == null or not _seller_lean_tween.is_valid():
			stage_seller.position = _seller_home
		stage_seller.pivot_offset = stage_seller.size / 2.0
		stage_seller_body.pivot_offset = stage_seller_body.size / 2.0
	if is_instance_valid(stage_customer):
		stage_customer.pivot_offset = stage_customer.size / 2.0
		# Parado no balcão ninguém é dono da posição dele, então a janela nova o
		# devolve ao chão novo; andando, o tween da chegada é quem manda.
		if stage_customer.visible and (_customer_bob == null or not _customer_bob.is_valid()):
			_place_stage_figure(
				stage_customer,
				float(stage_customer.get_meta("stage_depth", STAGE_FRONT_DEPTH)),
				_room_meet().y * stage_layer.size.x
			)

## O palco é a tela inteira: as figuras vivem sobre a arte de fundo, sem moldura e
## sem cópia da arte. A UI abre apenas um respiro largo, por onde o salão aparece.
## O elenco e os recortes de profundidade compartilham a ordem de desenho; o
## overlay final continua reservado para móveis que ficam sempre à frente, como o
## balcão da recepção.
func _build_stage(root: Control) -> void:
	_stage_back_band = Control.new()
	_stage_back_band.custom_minimum_size = Vector2(0, 186.0)
	_stage_back_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_stage_back_band)

	var insert_at := ui_layer.get_index()
	stage_layer = _make_stage_layer("StageBack")
	stage_layer.z_index = -500
	add_child(stage_layer)
	move_child(stage_layer, insert_at)
	stage_occluder = TextureRect.new()
	stage_occluder.name = "StageProps"
	stage_occluder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_occluder.stretch_mode = TextureRect.STRETCH_SCALE
	stage_occluder.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage_occluder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_occluder.z_index = -50
	stage_occluder.material = _occluder_material()
	add_child(stage_occluder)
	move_child(stage_occluder, insert_at + 1)
	_apply_room_props(_stage_room)

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
	# O cliente do turno também fica sob os móveis: entrando pelo fundo da sala ele
	# é escondido pela estante como qualquer transeunte.
	stage_layer.add_child(stage_customer)
	stage_layer.draw.connect(_draw_stage_shadows.bind(stage_layer))
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
	if _stage_occluder_material == null:
		return
	var props: Array = STAGE_ROOM_PROPS.get(scene_path, [])
	var prop_depths: Array = STAGE_ROOM_PROP_DEPTHS.get(scene_path, [])
	for i in range(STAGE_PROP_SLOTS):
		var is_depth_sorted := i < prop_depths.size()
		var corners := _prop_corners(props[i]) if i < props.size() and not is_depth_sorted else _blank_corners()
		_stage_occluder_material.set_shader_parameter("prop%da" % i, Vector4(corners[0].x, corners[0].y, corners[1].x, corners[1].y))
		_stage_occluder_material.set_shader_parameter("prop%db" % i, Vector4(corners[2].x, corners[2].y, corners[3].x, corners[3].y))
	if is_instance_valid(stage_occluder) and ResourceLoader.exists(scene_path):
		stage_occluder.texture = load(scene_path)
	_rebuild_stage_depth_occluders(scene_path, props, prop_depths)

func _rebuild_stage_depth_occluders(scene_path: String, props: Array, prop_depths: Array) -> void:
	for overlay in _stage_depth_occluders:
		if is_instance_valid(overlay):
			overlay.hide()
			overlay.queue_free()
	_stage_depth_occluders.clear()
	if not is_instance_valid(stage_layer) or not ResourceLoader.exists(scene_path):
		return
	var texture := load(scene_path) as Texture2D
	var shader := load("res://assets/stage_props_mask.gdshader") as Shader
	if texture == null or shader == null:
		push_error("Não foi possível carregar a arte ou o shader dos móveis em profundidade: %s" % scene_path)
		return
	for i in range(mini(props.size(), prop_depths.size())):
		var overlay := TextureRect.new()
		overlay.name = "StageDepthProp%d" % i
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_SCALE
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.texture = texture
		overlay.material = _depth_prop_material(shader, props[i])
		# No mesmo plano, o pé da figura já fica à frente do móvel.
		overlay.z_index = _stage_z_for_depth(float(prop_depths[i])) - 1
		stage_layer.add_child(overlay)
		_stage_depth_occluders.append(overlay)

func _depth_prop_material(shader: Shader, prop: Variant) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader
	var corners := _prop_corners(prop)
	for i in range(STAGE_PROP_SLOTS):
		var slot_corners := corners if i == 0 else _blank_corners()
		material.set_shader_parameter("prop%da" % i, Vector4(slot_corners[0].x, slot_corners[0].y, slot_corners[1].x, slot_corners[1].y))
		material.set_shader_parameter("prop%db" % i, Vector4(slot_corners[2].x, slot_corners[2].y, slot_corners[3].x, slot_corners[3].y))
	return material

## Os quatro cantos do contorno de um móvel: superior esquerdo, superior direito,
## inferior direito, inferior esquerdo. Retângulo vira quadrilátero reto; contorno
## medido na arte passa do jeito que foi desenhado.
func _prop_corners(prop: Variant) -> PackedVector2Array:
	if prop is Array:
		var traced: Array = prop
		var corners := _blank_corners()
		for i in range(mini(4, traced.size())):
			corners[i] = traced[i]
		return corners
	var rect := prop as Rect2
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])

func _blank_corners() -> PackedVector2Array:
	return PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

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
	# A batida do passo não pode atropelar uma pose de emoção no ar: sem esta trava
	# o gesto durava um ciclo de perna e ninguém via a cena acontecendo.
	if bool(figure.get_meta("emotion_pose", false)):
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

## Os dois pontos de luz que mandam na sombra de um pé: o mais perto e o segundo
## mais perto. Mais que isso mancharia o chão em vez de sombrear ninguém.
func _nearest_lights(foot: Vector2, lights: Array[Vector2]) -> Array[int]:
	var first := -1
	var second := -1
	var closest := INF
	var runner_up := INF
	for i in range(lights.size()):
		var distance := foot.distance_to(lights[i])
		if distance < closest:
			second = first
			runner_up = closest
			first = i
			closest = distance
		elif distance < runner_up:
			second = i
			runner_up = distance
	var picked: Array[int] = []
	if first >= 0:
		picked.append(first)
	if second >= 0:
		picked.append(second)
	return picked

## Onde a sala tem fogo aceso, em fração da tela: as velas pintadas na arte. O
## pavio tremula, então cada chama oscila um pouco a cada quadro e a sombra do
## elenco acompanha o balanço — é isso que faz a loja parecer iluminada por vela
## em vez de por refletor de estúdio.
func _stage_lights(now_ms: int) -> Array[Vector2]:
	var lamps: Array = STAGE_ROOM_LIGHTS.get(_stage_room, [])
	var out: Array[Vector2] = []
	for i in range(lamps.size()):
		var lamp: Vector2 = lamps[i]
		out.append(Vector2(
			(lamp.x + sin(float(now_ms) / (1129.0 + float(i) * 61.0)) * 0.006) * stage_layer.size.x,
			(lamp.y + sin(float(now_ms) / (421.0 + float(i) * 97.0)) * 0.008) * stage_layer.size.y))
	return out

## O halo de cada vela na parede e o poço de luz no chão embaixo dela. Tudo aqui é
## desenhado antes dos filhos da camada, então a luz nunca tapa um corpo.
func _draw_light_pools(layer: Control, lights: Array[Vector2], now_ms: int) -> void:
	var floor_y := float(_lane_at(0.5)["floor_y"])
	for i in range(lights.size()):
		var lamp := lights[i]
		var breath := 0.88 + 0.12 * sin(float(now_ms) / (421.0 + float(i) * 97.0))
		for ring in range(5):
			layer.draw_circle(lamp, (24.0 + float(ring) * 21.0) * breath, Color(1.0, 0.72, 0.34, 0.026))
		layer.draw_set_transform(Vector2(lamp.x, floor_y), 0.0, Vector2(78.0 * breath, 17.0))
		layer.draw_circle(Vector2.ZERO, 1.0, Color(1.0, 0.64, 0.28, 0.05))
		layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Sem sombra nenhuma figura fica de pé numa arte pintada. Cada corpo recebe duas:
## a de contato, colada no pé, e a projetada pelas velas, que deita no chão na
## direção oposta à luz. O pé é lido pela transformada global porque a chefe
## inclina e escala no meio do atendimento, e a elipse fica deitada — sombra em pé
## na tela é exatamente o que fazia o elenco flutuar sobre o próprio risco.
func _draw_stage_shadows(layer: Control) -> void:
	var now_ms := Time.get_ticks_msec()
	var lights := _stage_lights(now_ms)
	_draw_light_pools(layer, lights, now_ms)
	var figures: Array[Control] = []
	if is_instance_valid(stage_seller) and stage_seller.visible:
		figures.append(stage_seller_body)
	for entry in _stage_walkers:
		if is_instance_valid(entry["node"]):
			figures.append(entry["node"])
	for entry in _stage_waiters:
		if is_instance_valid(entry["node"]):
			figures.append(entry["node"])
	if is_instance_valid(stage_customer) and stage_customer.visible:
		figures.append(stage_customer)
	if lights.is_empty():
		lights.append(Vector2(layer.size.x * 0.5, layer.size.y * 0.1))
	var to_layer := layer.get_global_transform().affine_inverse()
	var layer_zoom := maxf(0.0001, layer.get_global_transform().get_scale().x)
	for figure in figures:
		var world := figure.get_global_transform()
		var foot: Vector2 = to_layer * world * Vector2(figure.size.x * 0.5, figure.size.y)
		var zoom := world.get_scale().x / layer_zoom
		var radius := maxf(8.0, figure.size.x * zoom * 0.40)
		var contact_tall := maxf(4.5, radius * 0.30)
		layer.draw_set_transform(foot + Vector2(0.0, contact_tall * 0.35), 0.0, Vector2(radius, contact_tall))
		layer.draw_circle(Vector2.ZERO, 1.0, Color(0.03, 0.01, 0.045, 0.40))
		layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for pick in _nearest_lights(foot, lights):
			var lamp := lights[pick]
			var above := maxf(48.0, foot.y - lamp.y)
			var dx := foot.x - lamp.x
			# Comprimento de um corpo iluminado de lado: quanto mais rasante a chama,
			# mais a sombra corre pelo chão. Ela nasce na beirada do pé e vai embora,
			# porque sombra que descola do pé é gente flutuando.
			var reach := clampf(figure.size.y * zoom * absf(dx) / above, radius * 0.4, radius * 2.2)
			var away := 1.0 if dx >= 0.0 else -1.0
			var wide := reach * 0.5 + radius * 0.6
			var cast_tall := maxf(3.5, wide * 0.2)
			layer.draw_set_transform(
				foot + Vector2(away * (wide - radius * 0.55), cast_tall * 0.3),
				-away * clampf(absf(dx) / above, 0.0, 1.2) * 0.16,
				Vector2(wide, cast_tall))
			layer.draw_circle(Vector2.ZERO, 1.0, Color(0.02, 0.005, 0.03, clampf(
				0.14 - foot.distance_to(lamp) / maxf(1.0, layer.size.x) * 0.10, 0.04, 0.14)))
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
	bg.z_index = -1000
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

	var bug_report_button := Button.new()
	bug_report_button.text = "🐞 Relatar"
	bug_report_button.custom_minimum_size = Vector2(100, 42)
	bug_report_button.tooltip_text = "Revisar um relatório com os logs recentes antes de enviá-lo ao GitHub."
	bug_report_button.pressed.connect(_show_bug_report_dialog)
	header.add_child(bug_report_button)

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
	house_button = Button.new()
	house_button.pressed.connect(_buy_talent.bind("house"))
	talent_row.add_child(house_button)

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

	library_box.add_child(_make_section_title("ESPECIALIZAÇÕES", Color(1.0, 0.80, 0.58)))
	library_box.add_child(_make_section_hint("Até o degrau 4 a trilha é só subida. No degrau 4 ela escolhe que tipo de loja a loja vai ser: são dois ofícios por trilha e a casa assina um só, porque os dois se puxam para lados opostos da mesma conta. O outro fica raspado até a próxima vida, e sem assinatura o quinto degrau não abre."))
	spec_summary_label = Label.new()
	spec_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spec_summary_label.add_theme_font_size_override("font_size", 14)
	spec_summary_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.76))
	library_box.add_child(spec_summary_label)
	for trail_id in TalentSpecs.trail_ids():
		var trail_kind := str(trail_id)
		var spec_card := _make_sector_card(Color(0.055, 0.045, 0.095, 0.94), Color(0.58, 0.34, 0.68, 0.95))
		library_box.add_child(spec_card)
		var spec_info := VBoxContainer.new()
		spec_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spec_info.add_theme_constant_override("separation", 6)
		spec_card.add_child(spec_info)
		var spec_label := Label.new()
		spec_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spec_label.add_theme_font_size_override("font_size", 15)
		spec_label.add_theme_color_override("font_color", Color(0.92, 0.80, 1.0))
		spec_info.add_child(spec_label)
		spec_labels.append(spec_label)
		var spec_options := HBoxContainer.new()
		spec_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spec_options.add_theme_constant_override("separation", 10)
		spec_info.add_child(spec_options)
		var trail_buttons: Array = []
		for option in TalentSpecs.pair(trail_kind):
			var option_box := VBoxContainer.new()
			option_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_box.add_theme_constant_override("separation", 4)
			spec_options.add_child(option_box)
			var option_button := Button.new()
			option_button.custom_minimum_size = Vector2(0, 40)
			option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			option_button.add_theme_font_size_override("font_size", 14)
			option_button.pressed.connect(_choose_spec.bind(trail_kind, str(option["id"])))
			option_box.add_child(option_button)
			trail_buttons.append(option_button)
			var option_desc := Label.new()
			option_desc.text = str(option["desc"])
			option_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			option_desc.add_theme_font_size_override("font_size", 11)
			option_desc.add_theme_color_override("font_color", Color(0.68, 0.72, 0.84))
			option_box.add_child(option_desc)
		spec_buttons.append(trail_buttons)
		var spec_state := Label.new()
		spec_state.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		spec_state.add_theme_font_size_override("font_size", 12)
		spec_state.add_theme_color_override("font_color", Color(0.74, 0.76, 0.88))
		spec_info.add_child(spec_state)
		spec_state_labels.append(spec_state)

	sanctum_upgrade_button = Button.new()
	sanctum_upgrade_button.custom_minimum_size = Vector2(220, 36)
	sanctum_upgrade_button.pressed.connect(_buy_sector_upgrade.bind("sanctum"))
	sanctum_box.add_child(sanctum_upgrade_button)

	sector_action_button = Button.new()
	sector_action_button.custom_minimum_size = Vector2(220, 40)
	sector_action_button.pressed.connect(_activate_sector_feature)
	scene_action_box.add_child(sector_action_button)

	forge_box.add_child(_make_section_title("TOPO DA FORJA", Color(1.0, 0.72, 0.42)))
	forge_mastery_label = Label.new()
	forge_mastery_label.custom_minimum_size = Vector2(820, 40)
	forge_mastery_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	forge_mastery_label.add_theme_font_size_override("font_size", 13)
	forge_mastery_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.55))
	forge_box.add_child(forge_mastery_label)

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

	reception_box.add_child(_make_section_title("REENCARNAÇÃO DO IMPÉRIO", Color(0.85, 0.7, 1.0)))
	reception_box.add_child(_make_section_hint("Fechar o império troca a vida da loja: caixa, prateleira e campanha voltam ao zero, e o que a casa aprendeu fica. Cada volta paga aura, e aura compra dote permanente."))
	prestige_box = VBoxContainer.new()
	prestige_box.add_theme_constant_override("separation", 8)
	reception_box.add_child(prestige_box)
	prestige_label = Label.new()
	prestige_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prestige_label.add_theme_font_size_override("font_size", 13)
	prestige_label.add_theme_color_override("font_color", Color(0.88, 0.78, 1.0))
	prestige_box.add_child(prestige_label)
	for perk_index in range(Prestige.PERKS.size()):
		var perk_button := Button.new()
		perk_button.custom_minimum_size = Vector2(320, 40)
		perk_button.add_theme_font_size_override("font_size", 13)
		perk_button.pressed.connect(_buy_perk.bind(perk_index))
		prestige_box.add_child(perk_button)
		prestige_perk_buttons.append(perk_button)
	prestige_button = Button.new()
	prestige_button.custom_minimum_size = Vector2(320, 46)
	prestige_button.add_theme_font_size_override("font_size", 15)
	prestige_button.pressed.connect(_reincarnate)
	prestige_box.add_child(prestige_button)

	reception_box.add_child(_make_section_title("BOLETIM DO MERCADO", Color(1.0, 0.86, 0.45)))
	reception_box.add_child(_make_section_hint("A loja reage ao que você compra e vende: estoque encalhado derruba o preço, demanda em alta empurra para cima."))
	market_label = Label.new()
	market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	market_label.add_theme_font_size_override("font_size", 14)
	market_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	reception_box.add_child(market_label)
	upkeep_label = Label.new()
	upkeep_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upkeep_label.add_theme_font_size_override("font_size", 14)
	upkeep_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.55))
	reception_box.add_child(upkeep_label)
	day_report_label = Label.new()
	day_report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	day_report_label.add_theme_font_size_override("font_size", 13)
	day_report_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.92))
	reception_box.add_child(day_report_label)

	reception_box.add_child(_make_section_title("FILA DE ATENDIMENTO", Color(0.98, 0.86, 0.55)))
	reception_box.add_child(_make_section_hint("Fama bate à porta em mais de uma visita por tique, e o balcão atende uma. Quem sobra espera na linha do tapete; passou do tempo, desiste e a reputação paga a conta."))
	queue_label = Label.new()
	queue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_label.add_theme_font_size_override("font_size", 14)
	queue_label.add_theme_color_override("font_color", Color(0.98, 0.90, 0.66))
	reception_box.add_child(queue_label)

	reception_box.add_child(_make_section_title("FILIAIS DA CASA", Color(0.72, 1.0, 0.82)))
	reception_box.add_child(_make_section_hint("Fora do salão a loja também trabalha, e também paga conta. Cada filial abre com ouro e cobra um custo por virada; a mais rentável é a que mais deve no dia ruim."))
	branch_summary_label = Label.new()
	branch_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	branch_summary_label.add_theme_font_size_override("font_size", 14)
	branch_summary_label.add_theme_color_override("font_color", Color(0.82, 0.98, 0.88))
	reception_box.add_child(branch_summary_label)
	for branch in Branches.DATA:
		var branch_card := _make_sector_card(Color(0.04, 0.08, 0.07, 0.94), Color(0.30, 0.62, 0.46, 0.95))
		reception_box.add_child(branch_card)
		var branch_row := HBoxContainer.new()
		branch_row.add_theme_constant_override("separation", 12)
		branch_card.add_child(branch_row)
		var branch_info := VBoxContainer.new()
		branch_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		branch_row.add_child(branch_info)
		var branch_label := Label.new()
		branch_label.add_theme_font_size_override("font_size", 15)
		branch_label.add_theme_color_override("font_color", Color(0.86, 1.0, 0.92))
		branch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		branch_info.add_child(branch_label)
		branch_labels.append(branch_label)
		var branch_desc := Label.new()
		branch_desc.text = str(branch["desc"])
		branch_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		branch_desc.add_theme_font_size_override("font_size", 12)
		branch_desc.add_theme_color_override("font_color", Color(0.70, 0.80, 0.75))
		branch_info.add_child(branch_desc)
		var branch_button := Button.new()
		branch_button.custom_minimum_size = Vector2(170, 40)
		branch_button.add_theme_font_size_override("font_size", 14)
		branch_button.pressed.connect(_open_branch.bind(str(branch["id"])))
		branch_row.add_child(branch_button)
		branch_buttons.append(branch_button)

	reception_box.add_child(_make_section_title("QUADRO DE FUNCIONÁRIOS", Color(1.0, 0.78, 0.62)))
	reception_box.add_child(_make_section_hint("Gente fixa não é prêmio, é conta: cada vaga cobra taxa uma vez e salário em toda virada, dentro do custo da casa. Ninguém inventa número novo — cada um mexe numa fórmula que a loja já usa, e a vaga só abre quando a loja já tem o que ela exige de quem entra no balcão."))
	staff_summary_label = Label.new()
	staff_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	staff_summary_label.add_theme_font_size_override("font_size", 14)
	staff_summary_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.76))
	reception_box.add_child(staff_summary_label)
	for seat in Staff.DATA:
		var staff_card := _make_sector_card(Color(0.08, 0.05, 0.045, 0.94), Color(0.66, 0.40, 0.28, 0.95))
		reception_box.add_child(staff_card)
		var staff_row := HBoxContainer.new()
		staff_row.add_theme_constant_override("separation", 12)
		staff_card.add_child(staff_row)
		var staff_info := VBoxContainer.new()
		staff_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		staff_row.add_child(staff_info)
		var staff_label := Label.new()
		staff_label.add_theme_font_size_override("font_size", 15)
		staff_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.80))
		staff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		staff_info.add_child(staff_label)
		staff_labels.append(staff_label)
		var staff_bg := Label.new()
		staff_bg.text = str(seat["bg"])
		staff_bg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		staff_bg.add_theme_font_size_override("font_size", 12)
		staff_bg.add_theme_color_override("font_color", Color(0.74, 0.68, 0.66))
		staff_info.add_child(staff_bg)
		var staff_does := Label.new()
		staff_does.text = str(seat["does"])
		staff_does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		staff_does.add_theme_font_size_override("font_size", 12)
		staff_does.add_theme_color_override("font_color", Color(0.86, 0.78, 0.60))
		staff_info.add_child(staff_does)
		var staff_button := Button.new()
		staff_button.custom_minimum_size = Vector2(170, 40)
		staff_button.add_theme_font_size_override("font_size", 14)
		staff_button.pressed.connect(_manage_staff.bind(str(seat["id"])))
		staff_row.add_child(staff_button)
		staff_buttons.append(staff_button)

	reception_box.add_child(_make_section_title("PEDIDOS DAS FACÇÕES", Color(1.0, 0.86, 0.45)))
	reception_box.add_child(_make_section_hint("Cada facção tem três pedidos escritos, e eles só abrem na medida em que a loja vira gente conhecida. Fechar os três deixa um privilégio permanente — nome não apaga com reencarnação."))
	arc_summary_label = Label.new()
	arc_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arc_summary_label.add_theme_font_size_override("font_size", 14)
	arc_summary_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.80))
	reception_box.add_child(arc_summary_label)
	for faction in Factions.DATA:
		var arc_card := _make_sector_card(
			Color(0.05, 0.06, 0.09, 0.94),
			Color.from_string(str(faction["color"]), Color(0.7, 0.8, 1.0)).darkened(0.32))
		reception_box.add_child(arc_card)
		var arc_row := HBoxContainer.new()
		arc_row.add_theme_constant_override("separation", 12)
		arc_card.add_child(arc_row)
		var arc_info := VBoxContainer.new()
		arc_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		arc_row.add_child(arc_info)
		var arc_label := Label.new()
		arc_label.add_theme_font_size_override("font_size", 15)
		arc_label.add_theme_color_override("font_color", Color(str(faction["color"])))
		arc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		arc_info.add_child(arc_label)
		arc_labels.append(arc_label)
		var arc_desc := Label.new()
		arc_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		arc_desc.add_theme_font_size_override("font_size", 12)
		arc_desc.add_theme_color_override("font_color", Color(0.74, 0.76, 0.86))
		arc_info.add_child(arc_desc)
		arc_desc_labels.append(arc_desc)
		var arc_button := Button.new()
		arc_button.custom_minimum_size = Vector2(170, 40)
		arc_button.add_theme_font_size_override("font_size", 14)
		arc_button.pressed.connect(_deliver_faction_arc.bind(str(faction["id"])))
		arc_row.add_child(arc_button)
		arc_buttons.append(arc_button)

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
	reception_box.add_child(_make_section_hint("Pacote lacrado no balcão. Coleção completa vira reputação, e carta repetida não sobra: três cópias deixam a arte holográfica, seis a fazem prismática — e o álbum inteiro paga bônus de balcão."))
	card_summary_label = Label.new()
	card_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_summary_label.add_theme_font_size_override("font_size", 14)
	card_summary_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.62))
	reception_box.add_child(card_summary_label)
	card_bonus_label = Label.new()
	card_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_bonus_label.add_theme_font_size_override("font_size", 13)
	card_bonus_label.add_theme_color_override("font_color", Color(0.86, 0.78, 0.96))
	reception_box.add_child(card_bonus_label)
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

	library_box.add_child(_make_section_title("ARQUIVO DE FINAIS", Color(1.0, 0.74, 0.86)))
	library_box.add_child(_make_section_hint("O capítulo sete fecha com a cara de quem mais usou o balcão nesta vida. Reencarnar zera a corrida e a próxima vida pode fechar de outro jeito. O sétimo final ninguém sorteia: ele chega no dia em que a dívida da casa passa do teto."))
	endings_label = Label.new()
	endings_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	endings_label.add_theme_font_size_override("font_size", 13)
	endings_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.9))
	library_box.add_child(endings_label)

	library_box.add_child(_make_section_title("ARQUIVO DE CARDS", Color(1.0, 0.86, 0.45)))
	library_box.add_child(_make_section_hint("Toda arte que a loja já viu. Conquista entrega pacote brinde; o resto se compra no balcão. Moldura prata é holo, moldura dourada é prismática."))
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

	arc_label = Label.new()
	arc_label.custom_minimum_size = Vector2(280, 96)
	arc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	arc_label.add_theme_font_size_override("font_size", 12)
	arc_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.78))
	right.add_child(arc_label)

	origin_label = Label.new()
	origin_label.custom_minimum_size = Vector2(280, 60)
	origin_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	origin_label.add_theme_font_size_override("font_size", 12)
	origin_label.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	right.add_child(origin_label)

	origin_button = Button.new()
	origin_button.custom_minimum_size.y = 40
	origin_button.text = "Relembrar"
	origin_button.visible = false
	origin_button.pressed.connect(_reread_origin)
	right.add_child(origin_button)

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
	commission_label = Label.new()
	commission_label.custom_minimum_size = Vector2(280, 78)
	commission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	commission_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.62))
	right.add_child(commission_label)
	commission_button = Button.new()
	commission_button.custom_minimum_size.y = 42
	commission_button.text = "Entregar etapa da encomenda"
	commission_button.pressed.connect(_deliver_commission_stage)
	right.add_child(commission_button)

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

	romance_label = Label.new()
	romance_label.custom_minimum_size = Vector2(280, 78)
	romance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	romance_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.86))
	right.add_child(romance_label)

	romance_button = Button.new()
	romance_button.custom_minimum_size.y = 44
	romance_button.pressed.connect(_advance_romance_step)
	right.add_child(romance_button)

	adult_toggle_button = Button.new()
	adult_toggle_button.custom_minimum_size.y = 40
	adult_toggle_button.pressed.connect(_toggle_adult_content)
	right.add_child(adult_toggle_button)

	var save_buttons := HBoxContainer.new()
	save_buttons.add_theme_constant_override("separation", 8)
	right.add_child(save_buttons)
	var export_button := Button.new()
	export_button.text = "Exportar save"
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.pressed.connect(_show_save_dialog.bind(true))
	save_buttons.add_child(export_button)
	var import_button := Button.new()
	import_button.text = "Importar save"
	import_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_button.pressed.connect(_show_save_dialog.bind(false))
	save_buttons.add_child(import_button)

	var reset_button := Button.new()
	reset_button.text = "Resetar todo o progresso…"
	reset_button.custom_minimum_size.y = 40
	reset_button.pressed.connect(_confirm_full_reset)
	right.add_child(reset_button)
	hard_reset_dialog = ConfirmationDialog.new()
	hard_reset_dialog.title = "Apagar todo o progresso?"
	hard_reset_dialog.dialog_text = "O save local será removido. Esta ação não pode ser desfeita; exporte uma cópia antes se quiser guardá-la."
	hard_reset_dialog.ok_button_text = "Apagar e recomeçar"
	hard_reset_dialog.confirmed.connect(_reset_all_progress)
	add_child(hard_reset_dialog)
	save_file_dialog = FileDialog.new()
	save_file_dialog.title = "Save da Succubus Shop"
	save_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_file_dialog.filters = PackedStringArray(["*.cfg ; Save Succubus Shop"])
	save_file_dialog.file_selected.connect(_on_save_file_selected)
	add_child(save_file_dialog)

	recover_theft_button = Button.new()
	recover_theft_button.custom_minimum_size.y = 42
	recover_theft_button.text = "Rastrear item roubado"
	recover_theft_button.pressed.connect(_recover_stolen_item)
	right.add_child(recover_theft_button)

	var footer := Label.new()
	footer.text = "Protótipo 0.6 • Loja mágica, negócios duvidosos • Facções, romances de balcão e contratos • Conteúdo sensual opcional"
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
	var cost: int = maxi(1, int(round(float(item["cost"]) * _craft_cost_factor())))
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
	duration *= Staff.craft_time_factor(staff_hired)
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

func _advance_craft_jobs(game_seconds: float, offline: bool = false) -> void:
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
		_progress_contracts("craft", 1)
		# Alquimia, biblioteca e bênçãos do santuário empurram a rolagem de qualidade.
		var luck := _forge_luck() + int(job.get("luck", 0))
		if int(job.get("luck", 0)) > 0:
			catalyst_crafted += 1
		var tier := Quality.roll(luck, _forge_mastery())
		_add_piece(index, tier)
		Economy.bump(economy_state, "product", str(item["id"]), -0.10)
		var quality_name := str(Quality.tier(tier)["name"])
		if tier == Quality.LEGENDARY:
			legendary_crafted += 1
		if tier >= 3:
			premium_crafted += 1
			best_quality_crafted = maxi(best_quality_crafted, tier)
			last_event = "%s saiu %s! A chefe inspeciona a peça, finge surpresa e aumenta a etiqueta." % [item["name"], quality_name]
			if not offline:
				audio.play("rare")
				_show_feedback("✦ Peça %s!" % quality_name, Color(str(Quality.tier(tier)["color"])))
				_show_stage_emotion(stage_seller_body, "aplausao")
		else:
			last_event = "Produzido: %s (%s). O ferreiro bateu o martelo e pediu aplausos." % [item["name"], quality_name]
			if not offline:
				audio.play("craft")
				_show_feedback("Produto pronto para vender.")
				_show_stage_emotion(stage_seller_body, "curiosidade")
	if not offline:
		_check_achievements()
	if not offline:
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

## Quanto pesa hoje o custo de fabricação: a trilha de Alquimia derruba 5% por
## nível, o selo das Guildas derruba mais 10% em cima do que sobrou, e a Linha de
## montagem derruba 12% — o ofício que a Destilaria fina não pode ter junto. A
## conta é uma só para a forja, para a margem estimada e para o painel não
## prometerem números diferentes.
func _craft_cost_factor() -> float:
	var factor := 1.0 - 0.05 * float(alchemy_rank)
	if _faction_arc_closed("guildas"):
		factor *= 0.9
	if _has_spec("alchemy", "linha"):
		factor *= 0.88
	return maxf(0.3, factor)

## A carta que a corte deixou na parede: a etiqueta inteira sobe 6%, porque agora a
## loja tem quem responda pelo seu nome. Multiplica a mesma conta do balcão, não uma
## linha nova — o painel, a margem e o recibo continuam lendo o mesmo número.
func _recommendation_price_factor() -> float:
	return 1.06 if _faction_arc_closed("nobres") else 1.0

## O pacto de estrada dos aventureiros: +1 de sorte em todo sorteio da casa. Entra
## pela mesma porta da sorte do álbum, para a forja, a estrada e o pacote subirem
## juntos em vez de cada um ter o seu privilégio secreto.
func _road_pact_luck() -> int:
	return 1 if _faction_arc_closed("aventureiros") else 0

## Vagas de batedor na folha de pagamento. Logística 2 paga o segundo de estrada.
func _expedition_slots() -> int:
	return 2 if logistics_rank >= 2 else 1

## Quantos segundos de relógio a estrada leva. A rota dá a distância, a Logística
## encurta, e a Estrada curta — o ofício que a Compra em volume tranca — corta mais
## 15% com piso de dez segundos de mundo, para nenhuma viagem virar teleportar.
func _expedition_duration(destination: Dictionary) -> float:
	var days := Expedition.duration_for(destination, logistics_rank)
	if _has_spec("logistics", "estrada"):
		days = maxf(10.0, days * 0.85)
	return days

func _expedition_luck() -> int:
	return alchemy_rank + logistics_rank + Sanctum.luck_bonus(active_buffs) + _prestige_luck() + _card_luck() + _road_pact_luck()

## Sorte que o álbum paga: a coleção da chefa entra na forja, na estrada e no
## próprio pacote — e cresce com cada carta evoluída.
func _card_luck() -> int:
	return Cards.luck_bonus(card_counts)

## Sorte da bigorna sem catalisador na mão: a mesma que rola a peça, menos o pó da
## raridade do momento. Serve para o painel prometer uma chance honesta.
func _forge_luck() -> int:
	return alchemy_rank + Sanctum.luck_bonus(active_buffs) + int(round(float(library_upgrade_level) * 0.5)) + _prestige_luck() + _card_luck() + _road_pact_luck() + (1 if _has_spec("alchemy", "destilaria") else 0)

## Mestria da forja: os degraus que a casa já subiu nas duas trilhas que mexem na
## bigorna, mais a memória das vidas anteriores. É ela que destrava o Lendário —
## sorte não basta, porque sorte só inclina a curva dos níveis que já existem.
func _forge_mastery() -> int:
	return alchemy_rank + library_upgrade_level + prestige_runs

func _forge_mastery_text() -> String:
	var mastery := _forge_mastery()
	var chance := Quality.chance(_forge_luck(), mastery, Quality.LEGENDARY)
	var lines: Array[String] = []
	if mastery < Quality.MASTERY_GATE:
		lines.append("Topo da forja: %d/%d degraus. A peça Lendária ainda está selada — Alquimia + Biblioteca + vidas já vividas precisam somar %d." % [
			mastery, Quality.MASTERY_GATE, Quality.MASTERY_GATE])
	else:
		lines.append("Topo da forja: %d/%d degraus. Lendário no rolo de hoje: %d%% das peças, uma a cada %d." % [
			mastery, Quality.MASTERY_GATE, int(round(chance * 100.0)), maxi(1, int(round(1.0 / chance))) if chance > 0.0 else 0])
	lines.append("Lendárias na bigorna: %d • entregues no balcão: %d • exclusivas fechadas: %d." % [
		legendary_crafted, legendary_sold, exclusive_finished])
	return "\n".join(lines)

func _expedition_on_route(id: String) -> Dictionary:
	for trip in expeditions:
		if str(trip.get("id", "")) == id:
			return trip
	return {}

func _bar(progress: float) -> String:
	var filled := clampi(int(round(progress * 8.0)), 0, 8)
	return "█".repeat(filled) + "░".repeat(8 - filled)

func _expedition_trip_summary(trip: Dictionary, elapsed: float) -> String:
	var destination := Expedition.find(str(trip.get("id", "")))
	if destination.is_empty():
		return "Rota desconhecida"
	var total := maxf(1.0, float(trip.get("total", 1.0)))
	var remaining := maxf(0.0, float(trip.get("remaining", 0.0)) - elapsed)
	var progress := clampf(1.0 - remaining / total, 0.0, 1.0)
	var safe_return := 100 - Expedition.mishap_chance(destination, _expedition_luck())
	return "%s [%s] %d%% • %s • retorno sem contratempo: %d%%" % [
		str(destination.get("name", "?")),
		_bar(progress),
		int(round(progress * 100.0)),
		Expedition.journey_event(destination, progress),
		safe_return,
	]

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
	var duration := _expedition_duration(destination)
	expeditions.append({"id": id, "remaining": duration, "total": duration})
	last_event = "%s partiu com %d ouro de passagem e volta em %s." % [destination["name"], cost, Expedition.days_label(duration)]
	audio.play("click")
	_show_feedback("🧭 Expedição iniciada.", Color(0.55, 0.95, 0.7))
	_save_game()
	_refresh_ui()

func _advance_expeditions(game_seconds: float, offline: bool = false) -> void:
	if expeditions.is_empty():
		return
	var arrived: Array[Dictionary] = []
	for trip in expeditions:
		trip["remaining"] = float(trip.get("remaining", 0.0)) - game_seconds
		if float(trip["remaining"]) <= 0.0:
			arrived.append(trip)
	for trip in arrived:
		expeditions.erase(trip)
		_finish_expedition(trip, offline)

func _finish_expedition(entry: Dictionary, offline: bool = false) -> void:
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
		if not offline:
			_show_stage_emotion(stage_seller_body, "dor")
	expedition_log.push_front(text)
	while expedition_log.size() > 4:
		expedition_log.pop_back()
	last_event = text
	if not offline:
		if parts.is_empty():
			audio.play("sad")
		else:
			audio.play("rare" if mishap.is_empty() else "coin")
			_show_feedback("✦ Botim chegou!", Color(1.0, 0.86, 0.45))
	if not offline:
		_check_achievements()
	if not offline:
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
	var stored = quality_stock.get(product_id, null)
	if stored is Array[int] and (stored as Array[int]).size() == Quality.size():
		return stored
	# Save antigo: barra de cinco casas, lista solta ou produto sem registro entram
	# aqui rearranjados no espectro de hoje, sem órfão e sem estouro de índice.
	var counts := Quality.empty_stock()
	if stored is Array:
		for i in range(mini(stored.size(), counts.size())):
			counts[i] = maxi(0, int(stored[i]))
	quality_stock[product_id] = counts
	return counts

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

## Peça que sai pela porta é peça entregue: só ela conta para a etapa Lendária da
## encomenda exclusiva. O ladrão que leva a melhor do estoque não conta — a
## rainha quer ver a nota fiscal.
func _register_sold_piece(tier: int) -> void:
	if tier != Quality.LEGENDARY:
		return
	legendary_sold += 1
	_progress_commission("legendary", 1)

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
	var craft_cost := maxi(1, int(round(float(item["cost"]) * _craft_cost_factor())))
	var ingredient_cost := 0
	var recipe: Dictionary = item.get("ingredients", {})
	for ingredient_id in recipe.keys():
		ingredient_cost += _ingredient_price(str(ingredient_id)) * int(recipe[ingredient_id])
	return int(round(_piece_price(item, 1) * _market_product_factor(item))) - craft_cost - ingredient_cost

func _ingredient_price(ingredient_id: String) -> int:
	var base := float(Ingredients.price_for_day(ingredient_id, shop_day))
	base *= Economy.factor(economy_state, "ingredient", ingredient_id)
	base *= (1.0 - 0.05 * float(logistics_rank))
	# O caderno do Sabet aberto: fornecedor fiel cobra menos por confiar no volume.
	if _faction_arc_closed("mercadores"):
		base *= 0.88
	# Compra em volume é o ofício da Logística que a Estrada curta não pode ter.
	if _has_spec("logistics", "volume"):
		base *= 0.9
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
	_progress_contracts("gold", payout)
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
	var payout := maxi(1, int(round(_piece_price(item, tier) * _market_product_factor(item) * _prestige_price_factor() * 0.7)))
	_register_sold_piece(tier)
	Economy.bump(economy_state, "product", str(item["id"]), 0.12)
	gold += payout
	daily_gold_earned += payout
	_progress_contracts("gold", payout)
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

## Quem bate na porta sem ser freguês de casa: retrato, orçamento e paciência.
## É a mesma lista que alimenta a fila de espera, então quem espera na porta é
## alguém com rosto próprio, não um número de painel.
const CUSTOMER_PROFILES: Array[Dictionary] = [
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

## Sorteia a visita de um tique: um nome avulso da lista ou, quando a loja já tem
## nome, um freguês de sempre no degrau de confiança em que ele está. A fila de
## espera chama a mesma função, então quem fica na porta é gente com retrato e
## orçamento próprios. Quem é o freguês do palco fica no próprio perfil.
func _draw_visitor_profile() -> Dictionary:
	var profile: Dictionary = CUSTOMER_PROFILES[randi() % CUSTOMER_PROFILES.size()]
	if randi() % 100 >= 35:
		return profile
	var regular: Dictionary = _pick_regular()
	var regular_id := str(regular["id"])
	var bond := int(regular_bonds.get(regular_id, 0))
	var tier := Regulars.tier_for(bond)
	var lines_by_tier: Array = regular["lines"][tier]
	var personal_request := tier >= 1 and randi() % 100 < 35
	var regular_line := str(regular["request"]) if personal_request else str(lines_by_tier[randi() % lines_by_tier.size()])
	return {
		"name": regular["name"],
		"favorite": str(regular["favorite"]),
		"line": regular_line,
		"regular_id": regular_id,
		"portrait": int(regular["portrait"]),
		"tier": tier,
		"personal_request": personal_request,
		"faction": str(regular.get("faction", "aventureiros")),
		"budget": 60 + tier * 30,
		"patience": 2 + (1 if tier >= 2 else 0),
	}

func _on_customer_tick() -> void:
	ticks += 1
	_stage_customer_leaves()
	_advance_service_queue()
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
		daily_quest_index = (daily_quest_index + 1) % DAILY_QUESTS.size()
		daily_quest_progress = 0
		daily_quest_claimed = false
		daily_gold_earned = 0
		daily_crafts = 0
		# O convite esperou o dia todo e não foi aceito: ele tem orgulho próprio.
		romance_pending = ""
		# Fechou o dia, fechou o balanço: o placar recebe o resultado da virada.
		best_score = maxi(best_score, business_score())
		_bank_season()
		if steam != null:
			steam.call("submit_score", business_score(), "Sua loja")
		# O dia vira uma vez e o recorde nasce nesse instante: sem gravar aqui,
		# quem fecha o jogo sem mover mais nada perde a virada.
		_save_game()
		# A casa cobra antes de alguém comemorar o dia novo: quem acorda sem caixa
		# já acorda devendo, e dívida tem teto.
		var bill_line := _pay_upkeep()
		var branch_line := _collect_branches()
		# A cozinha serve no fim do turno: fúria é fome disfarçada de opinião, e cada
		# ponto a menos é 5% de etiqueta que volta para a próxima venda.
		var calm_line := ""
		var calm := Staff.calm_per_turn(staff_hired)
		if calm > 0 and fury > 0:
			fury = maxi(0, fury - calm)
			_update_demonic_form()
			calm_line = " %s levou %d de fúria da chefe com um prato no fim do turno." % [
				str(Staff.find("cozinha")["name"]), calm]
		# A fila que desistiu também fecha o dia: é o número que o balanço da manhã
		# precisa mostrar para a fama ter preço visível.
		var lost_line := ""
		if day_walkouts > 0:
			lost_line = " %d saíram da fila sem comprar." % day_walkouts
		day_report = bill_line + (" " + branch_line if branch_line != "" else "") + calm_line + lost_line
		last_event = "Dia %d começou! Um novo contrato está disponível; o anterior expirou. %s\n%s%s" % [
			shop_day, Economy.report(economy_state, products, Ingredients.DATA), bill_line,
			("\n" + branch_line) if branch_line != "" else ""]
		# A encomenda do patrono vence e chega no mesmo instante da virada, e o
		# resultado é gravado junto: quem fecha o jogo nessa manhã não acorda com o
		# prazo de um dia que já passou.
		_advance_commission()
		_save_game()
		# A conta da virada fecha depois de todo mundo ter pago e recebido: casa,
		# filiais e encomenda do patrono entram no mesmo número que a chefe vai ler.
		var balance := _close_day_balance()
		# A última lembrança não depende de capítulo nenhum: ela chega na manhã
		# seguinte a ter fechado o império, quando a loja já não tem meta nova.
		if game_completed:
			_reveal_origin(Origin.chapter_scene(Campaign.size()))
		# A conta foi paga ou foi para a dívida; o teto é checado depois, para a
		# conquista de sair do buraco bater antes de a vida fechar no vermelho.
		_check_achievements()
		if debt >= _debt_limit():
			_claim_ruin()
		else:
			_show_day_report(balance)
	if imp_hired and ticks % 3 == 0:
		_imp_work()

	# A última rodada não é venda. Um freguês por tique entra, olha o salão, acena e
	# volta a sair pela porta; a loja segue fabricando e expedindo enquanto isso.
	if not epilogue_pending.is_empty():
		_stage_farewell_visit(str(epilogue_pending.pop_front()))
		if epilogue_pending.is_empty():
			epilogue_done = true
			_show_stage_emotion(stage_seller_body, "sono")
			# A frase de quem saiu por último é a manchete, e a conquista que ela
			# acende não pode apagar a despedida: o texto volta depois da checagem.
			var headline := last_event
			_check_achievements()
			last_event = headline + "\nEPILOGO: a última rodada acabou. A chefe apaga uma vela, vira a placa e deixa a porta destrancada mesmo assim."
			_save_game()
		_refresh_ui()
		return

	# Eventos raros podem acontecer mesmo quando a loja está sem estoque.
	if randi() % 100 < 7 + library_upgrade_level * 2:
		_trigger_random_event()
		_add_xp(20)
		_progress_contracts("rare", 1)
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
		_react_to_visit("disappointed", randi() % 100 < 15 * charm_rank + (15 if _has_spec("charm", "boca") else 0))
	else:
		_flood_service_queue()
		var profile: Dictionary = _next_served_profile()
		current_regular_id = str(profile.get("regular_id", ""))
		_animate_customer_arrival(profile)
		var preferred_index: int = _product_index(str(profile["favorite"]))
		current_customer_budget = int(profile.get("budget", 50)) + trade_rank * 8
		current_customer_patience = maxi(1, int(round(float(int(profile.get("patience", 2)) + logistics_rank + Sanctum.patience_bonus(active_buffs) + distraction_pending) / world_speed())) - _fury_patience_loss())
		distraction_pending = 0
		var seduction_used := false
		if is_instance_valid(customer_emotion_label):
			customer_emotion_label.text = "🏃 pressa" if current_customer_patience <= 1 else "🙂 observando"
		if bool(profile.get("thief", false)) and current_customer_patience <= 1:
			var round_block := Staff.block_chance(staff_hired)
			if Sanctum.guards(active_buffs):
				last_event = "%s enfiou a mão na prateleira, mas o Selo da Cadeia estalou e a mão saiu vazia. Ele ainda pagou o que levou." % str(profile.get("name", "O cliente"))
				_show_feedback("⛓ Furto barrado pelo selo.", Color(0.75, 1.0, 0.72))
			elif round_block > 0 and randi() % 100 < round_block:
				theft_blocked += 1
				last_event = "%s levou a mão à prateleira e a ronda não precisou levar a mão a ele: %s ficou olhando até a peça voltar para o lugar." % [
					str(profile.get("name", "O cliente")), str(Staff.find("ronda")["name"])]
				_show_feedback("⛔ A ronda viu primeiro.", Color(0.75, 1.0, 0.72))
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
		_register_sold_piece(piece_tier)
		if piece_tier == 0:
			# Saiu torto da forja e o cliente viu: ninguém esconde a careta.
			_show_stage_emotion(stage_customer, "nojo")
		var base_label := _piece_price(item, piece_tier)
		var price_multiplier: float = (1.0 + 0.20 * ad_level) * (1.0 + 0.08 * trade_rank) * _reputation_price_multiplier() * _fury_price_multiplier() * Sanctum.scale(active_buffs, "price") * _market_product_factor(item) * _romance_price_factor(str(profile.get("regular_id", ""))) * _prestige_price_factor() * _recommendation_price_factor() * (1.08 if _has_spec("trade", "cartel") else 1.0)
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
		# O Varejo humilde vende a mesma peça sem empurrar o mercado duas vezes.
		Economy.bump(economy_state, "product", str(item["id"]), 0.11 if _has_spec("trade", "varejo") else 0.22)
		var faction_id := str(profile.get("faction", ""))
		var faction_bonus := 0
		if not faction_id.is_empty():
			var faction_tier := Factions.tier_for(int(faction_standing.get(faction_id, 0)))
			faction_bonus = int(round(base_label * Factions.price_bonus(faction_tier)))
			sale_price += faction_bonus
			faction_customers[faction_id] = int(faction_customers.get(faction_id, 0)) + 1
		# O mural da loja também pesa na etiqueta. É bônus de balcão, não de conversa:
		# a máquina de cartas mostra a porcentagem, o cliente não precisa ler rodapé.
		sale_price += int(round(base_label * Cards.price_bonus(card_counts)))
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
			var new_bond := old_bond + 1 + (2 if fulfilled_personal_request else 0) + _romance_bond_bonus(regular_id)
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
			var romance_tip := _romance_tip(regular_id)
			if romance_tip > 0:
				gold += romance_tip
				daily_gold_earned += romance_tip
				last_event += "\n%s deixa uma gorjeta de coração sobre o balcão: +%d ouro." % [
					regular_data.get("short", "O freguês"), romance_tip
				]
			_offer_romance(regular_id, new_bond)
			_check_regular_acts(regular_id)
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
		_progress_contracts("customers", 1)
		_progress_contracts("gold", sale_price)
		_add_affection(1 + charm_rank + sanctum_upgrade_level + (1 if _has_spec("charm", "coracao") else 0))
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

## O balcão ouve a campanha. Cada capítulo muda o que a rua comenta e o que a
## chefe responde, então a mesma venda soa diferente na loja vazia do primeiro dia
## e no império do sétimo. A chave é o id do capítulo em campaign.gd;
## "pos_campanha" vale depois que a história fecha.
const CHAPTER_CUSTOMER_LINES := {
	"portas_abertas": [
		"Ouvi que a casa abriu ontem. Vim ver se era boato.",
		"Ninguém nesta rua conhece o balcão ainda.",
		"Entrei porque a chuva lá fora não pede licença.",
	],
	"primeira_fornada": [
		"Dizem que a bigorna daqui esfriou semana passada.",
		"Vim pela fornada nova, antes que acabe.",
		"Cheiro de poção fresca. Valeu a caminhada.",
	],
	"freguesia": [
		"Terceira vez que piso aqui. Já tenho cupom?",
		"Meus amigos mandaram perguntar se você lembra deles.",
		"A fila cresceu. Perdi meu lugar por sua culpa.",
	],
	"estrada_e_bigorna": [
		"Mandaram gente pela estrada. Trouxeram coisa boa?",
		"Item de expedição custa caro. Eu sei, eu esperei.",
		"A caravana voltou? Então quero o que ela trouxe.",
	],
	"casa_arrumada": [
		"Agora tem arquivo, santuário e ritual? Que casa.",
		"Dizem que aqui se harmoniza relíquia. Meu anel, talvez?",
		"Loja arrumada assusta mais que a bagunça.",
	],
	"colecionadora": [
		"Todo mundo na guilda trocando carta. Você tem o álbum?",
		"Trouxe duas repetidas. Aceita troca ou é só venda?",
		"Falta uma carta pra fechar a coleção da casa, hein.",
	],
	"imperio": [
		"A corte fala desta loja. Cuidado com o que vou pedir.",
		"Se o império é seu, por que a fila é minha?",
		"Vim de longe. Espero preço de quem veio de longe.",
	],
	"pos_campanha": [
		"Estava aqui quando isto era só uma mesa.",
		"Todo mundo conhece a casa agora. Inclusive a cobrança.",
		"Voltei só pra ver se era tão bom quanto contam.",
	],
}

const CHAPTER_SELLER_LINES := {
	"portas_abertas": [
		"Casa nova, preço de quem ainda precisa da freguesia",
		"Ainda estamos aprendendo o gosto da rua",
	],
	"primeira_fornada": [
		"Saí da bigorna agora. Está quente, literalmente",
		"Fornada nova: a primeira leva sai com desconto moral",
	],
	"freguesia": [
		"Você já é de casa. Casa que cobra, mas de casa",
		"Freguesia boa é a que volta. Você voltou",
	],
	"estrada_e_bigorna": [
		"Voltei da estrada com isto aqui. E com histórias que não",
		"Ingrediente de expedição tem preço de expedição",
	],
	"casa_arrumada": [
		"Casa arrumada, preço ajustado. Tudo no lugar",
		"Ritual feito, prateleira cheia. Pode perguntar",
	],
	"colecionadora": [
		"Repetida vira ouro, ouro vira pacote. Matemática de loja",
		"Complete a coleção que a casa comemora junto",
	],
	"imperio": [
		"Império não se anuncia. Cobra",
		"Aqui é balcão, não embaixada — mas atendo os dois",
	],
	"pos_campanha": [
		"Fechar o império foi a parte fácil. Manter é o preço",
		"A casa é lendária. O troco é real",
	],
}

func _set_negotiation_dialogue(profile: Dictionary, item: Dictionary, seduction_used: bool, favorite_item: bool) -> void:
	if not is_instance_valid(seller_speech_label):
		return
	var customer_name := str(profile.get("name", "Aventureiro"))
	var chapter_key := "pos_campanha" if game_completed else str(Campaign.chapter(campaign_step).get("id", ""))
	var customer_line := "“Isso parece exatamente o que eu precisava.”" if favorite_item else "“Não era meu primeiro plano, mas parece útil.”"
	var chapter_customer: Array = CHAPTER_CUSTOMER_LINES.get(chapter_key, [])
	if not chapter_customer.is_empty() and randi() % 100 < 55:
		customer_line = "“%s”" % str(chapter_customer.pick_random())
	if current_customer_patience <= 1:
		customer_line = "“Rápido, por favor. Tenho um dragão me esperando.”"
	if seduction_used:
		var flirt_line: String = str(MEME_FLIRT_LINES.pick_random() if customer_name in ["Mago do Quero Mana", "Fiscal do Pix Astral", "Só Mais Uma Run", "Ladino do Ctrl+C", "Cliente do É Sobre Isso"] else SUCCUBUS_NEGOTIATION_LINES.pick_random())
		seller_speech_label.text = "CHEFE: %s\n%s: %s" % [flirt_line, customer_name, customer_line]
	else:
		var offer := "“%s por %d ouro. Quer levar?”" % [str(item.get("name", "isto")), int(item.get("price", 0))]
		var chapter_seller: Array = CHAPTER_SELLER_LINES.get(chapter_key, [])
		if not chapter_seller.is_empty() and randi() % 100 < 40:
			offer = "“%s” — %d ouro" % [str(chapter_seller.pick_random()), int(item.get("price", 0))]
		seller_speech_label.text = "CHEFE: %s\n%s: %s" % [offer, customer_name, customer_line]

func _react_to_visit(mood: String, charm_save: bool = false) -> void:
	# O humor do balcão é o que ele faz ao virar as costas: atendido com gosto,
	# ainda passeia pela loja antes de sair.
	_customer_served = mood != "disappointed" or charm_save
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
	figure.set_meta("emotion_pose", true)
	var hold := create_tween()
	hold.tween_interval(0.9)
	## O callback leva o id, não o corpo: se ele sair de cena antes do intervalo
	## acabar, o objeto liberado não converte para o parâmetro tipado e a guarda
	## dentro da função nem chega a rodar — sobra um erro no log a cada virada.
	hold.tween_callback(_restore_stage_walk_frame.bind(figure.get_instance_id()))

## Depois da pose de emoção o corpo retoma o passo exatamente de onde parou.
func _restore_stage_walk_frame(figure_id: int) -> void:
	var figure := instance_from_id(figure_id) as Control
	if figure == null:
		return
	figure.set_meta("emotion_pose", false)
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
	# O número do painel é o corpo desenhado no salão agora, e a fila à parte:
	# contar a vida inteira fazia "Clientes: 12" com três visitas na tela.
	customers_label.text = "No salão: %d • Fila: %d  ♥%d  ✗%d  •  Atendidos: %d" % [
		_bodies_on_stage(), service_queue.size(), happy_customers, disappointed_customers, customers_served]
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
		_refresh_timed_ui()
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
		ritual_label.text = Sanctum.summary(active_buffs, _world_seconds_since_tick())
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
			var courted := _romance_stage_of(regular_id)
			regular_lines.append("%s — %s (%d visitas, %d pedidos)%s • Ato %d" % [
				regular["short"], Regulars.TIER_NAMES[tier], bond, orders_done,
				" ♥%d" % courted if courted > 0 else "",
				_arc_act(regular_id)
			])
			if regular_story_completed.has(regular_id):
				regular_lines.append("  ✦ História concluída")
			elif bond >= 3:
				regular_lines.append("  ◇ Missão pessoal: %d/3 compras favoritas" % int(regular_story_progress.get(regular_id, 0)))
		if unseen > 0:
			regular_lines.append("  · %d ainda não pisaram aqui" % unseen)
		regulars_label.text = "\n".join(regular_lines)
	if is_instance_valid(faction_label):
		var faction_lines: Array[String] = ["REPUTAÇÃO POR FACÇÃO"]
		var life_standing := _life_standing()
		for faction in Factions.DATA:
			var faction_id := str(faction["id"])
			var standing := int(faction_standing.get(faction_id, 0))
			var tier := Factions.tier_for(standing)
			var bonus_pct := int(round(Factions.price_bonus(tier) * 100.0))
			var bonus_text := "  +%d%%" % bonus_pct if bonus_pct > 0 else ""
			# O número da vida é o que corre para o capítulo sete; a fama total é o
			# que fica e manda na etiqueta.
			faction_lines.append("%s — %s (%d) • nesta vida %d%s" % [
				faction["short"], Factions.TIER_NAMES[tier], standing, int(life_standing[faction_id]), bonus_text,
			])
		faction_label.text = "\n".join(faction_lines)
	if is_instance_valid(progression_label):
		progression_label.text = "NÍVEL %d  •  XP: %d/%d  •  Pontos de talento: %d  •  Dia %d" % [player_level, player_xp, _xp_required(), skill_points, shop_day]
	if is_instance_valid(talent_label):
		talent_label.text = "TALENTOS • Alquimia %d/5 | Comércio %d/5 | Carisma %d/5 | Logística %d/5 | Casa %d/5" % [alchemy_rank, trade_rank, charm_rank, logistics_rank, house_rank]
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
	if is_instance_valid(house_button):
		house_button.text = "Administração da Casa %d/5" % house_rank
		house_button.disabled = skill_points <= 0 or house_rank >= 5
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
	if is_instance_valid(commission_label):
		commission_label.text = _commission_summary()
	if is_instance_valid(commission_button):
		var stage_ready := _commission_ready()
		commission_button.visible = commission_index >= 0
		commission_button.disabled = not stage_ready
		commission_button.text = "Entregar etapa %d da encomenda" % (commission_stage + 1) if stage_ready else "Etapa %d em andamento" % (commission_stage + 1)
	if is_instance_valid(achievement_label):
		achievement_label.text = _get_achievement_summary()
	if is_instance_valid(forge_mastery_label):
		forge_mastery_label.text = _forge_mastery_text()
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
		var craft_cost := maxi(1, int(round(float(item["cost"]) * _craft_cost_factor())))
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
	if is_instance_valid(upkeep_label):
		# A conta do dia é a única razão para o caixa ter teto: sem ela, loja grande
		# só cresce e nunca precisa de freguês.
		upkeep_label.text = "CUSTO DA CASA: %d de ouro a cada virada (biblioteca, santuário, propaganda, diabrete e a folha dos funcionários pesam na conta).%s%s" % [
			_daily_upkeep(),
			" Administração da casa derruba %d%% da conta. " % int(round(8.0 * float(house_rank))) if house_rank > 0 else "",
			" Dívida aberta de %d — a casa leva o salão aos %d." % [debt, _debt_limit()] if debt > 0 else "",
		]
	if is_instance_valid(day_report_label):
		day_report_label.text = "ÚLTIMA VIRADA: %s" % day_report if day_report != "" \
			else "Ainda não houve cobrança: a casa apresenta a conta na primeira virada de dia."
	if is_instance_valid(branch_summary_label):
		# O painel promete média, não pico: a filial que mais paga é também a que
		# mais cobra conserto, e o jogador precisa ver o saldo esperado.
		if branches.is_empty():
			branch_summary_label.text = "Nenhuma filial aberta. A primeira custa 400 de ouro e pede um capítulo fechado."
		else:
			var expected := Branches.expected_profit(branches, _branch_care())
			var extra := Branches.total_upkeep(branches)
			var de_onde: Array[String] = []
			if house_rank >= 2:
				de_onde.append("%d da casa" % (house_rank - 1))
			if _has_spec("house", "porteiro"):
				de_onde.append("2 do porteiro")
			if _faction_arc_closed("submundo"):
				de_onde.append("3 do beco")
			branch_summary_label.text = "CASAS ABERTAS: %d de %d • lucro esperado %+d por virada • custo extra %d • saldo médio %+d.%s" % [
				branches.size(), Branches.size(), expected, extra, expected - extra,
				" Cuidado com as filiais: -%d%% de dia ruim (%s)." % [
					_branch_care(), " + ".join(de_onde)] if _branch_care() > 0 else ""]
	for i in range(Branches.DATA.size()):
		var branch: Dictionary = Branches.DATA[i]
		var branch_id := str(branch["id"])
		var opened := branches.has(branch_id)
		var blocked := Branches.gate(branch, campaign_step, faction_standing)
		var branch_cost := int(branch["cost"])
		if i < branch_labels.size():
			(branch_labels[i] as Label).text = "%s — %s\n%s • paga %d por virada, custa %d • dia ruim em %d%% das viradas" % [
				str(branch["name"]),
				"ABERTA" if opened else ("disponível" if blocked == "" else "trancada"),
				_branch_faction_label(branch), int(branch["profit"]), int(branch["upkeep"]),
				int(round(Branches.risk_for(branch, 0, _branch_care()) * 100.0)),
			]
		if i < branch_buttons.size():
			var branch_button := branch_buttons[i] as Button
			branch_button.disabled = opened or blocked != "" or gold < branch_cost
			branch_button.text = "ABERTA" if opened else (
				"Abrir por %d" % branch_cost if blocked == "" else "Trancada: %s" % blocked)
	if is_instance_valid(queue_label):
		if service_queue.is_empty():
			queue_label.text = "A porta está quieta: ninguém espera do lado de fora. %s" % (
				"Com %d de fama, %d batem no mesmo tique." % [reputation, _arrivals_this_tick()]
				if reputation >= 12 else "Com a loja desconhecida, um cliente por tique é o teto.")
		else:
			var waiting: Array[String] = []
			for entry in service_queue.slice(0, 4):
				waiting.append("%s (%d/%d)" % [
					str(entry["profile"].get("name", "?")), int(entry["waited"]), int(entry["limit"])])
			queue_label.text = "ESPERANDO: %d na fila • %s%s • saíram sem comprar: %d. O balcão atende um por tique; o resto é fila." % [
				service_queue.size(), " • ".join(waiting),
				" …" if service_queue.size() > 4 else "", queue_walkouts]
	if is_instance_valid(staff_summary_label):
		# A folha é a conta: o painel diz quanto os do balcão somam por virada e onde
		# esse dinheiro aparece — no custo da casa, não numa linha separada.
		if staff_hired.is_empty():
			staff_summary_label.text = "Ninguém no balcão além da chefe e do diabrete. A folha é zero e a conta também."
		else:
			var payroll := Staff.total_wage(staff_hired)
			staff_summary_label.text = "NO BALCÃO: %d de %d • folha %d por virada, dentro do custo da casa (hoje %d). %s%s" % [
				staff_hired.size(), Staff.size(), payroll, _daily_upkeep(), Staff.roster_line(staff_hired),
				" • %d furtos barrados pela ronda." % theft_blocked if staff_hired.has("ronda") else ""]
	for i in range(Staff.DATA.size()):
		var seat: Dictionary = Staff.DATA[i]
		var seat_id := str(seat["id"])
		var hired := staff_hired.has(seat_id)
		var blocked_by := Staff.gate(seat, _staff_gate_state())
		var hire_fee := int(seat["hire"])
		if i < staff_labels.size():
			(staff_labels[i] as Label).text = "%s — %s • %s" % [
				str(seat["name"]), str(seat["role"]),
				"NO BALCÃO" if hired else ("disponível" if blocked_by == "" else "trancada")]
		if i < staff_buttons.size():
			var staff_button := staff_buttons[i] as Button
			staff_button.disabled = not hired and (blocked_by != "" or gold < hire_fee)
			staff_button.text = "Demitir • corta %d/dia" % int(seat["wage"]) if hired else (
				"Contratar por %d • %d por virada" % [hire_fee, int(seat["wage"])]
				if blocked_by == "" else "Sem vaga: %s" % blocked_by)
	if is_instance_valid(arc_summary_label):
		arc_summary_label.text = "PEDIDOS ENTREGUES: %d de %d • arcos fechados %d de %d.%s" % [
			_faction_asks_delivered(), FactionArcs.total(), _faction_arcs_closed(), Factions.DATA.size(),
			" " + _faction_perks_text() if _faction_arcs_closed() > 0 else ""]
	for i in range(Factions.DATA.size()):
		var faction: Dictionary = Factions.DATA[i]
		var faction_id := str(faction["id"])
		var arc_progress := int(faction_arc_step.get(faction_id, 0))
		var ask_step := FactionArcs.step(faction_id, arc_progress)
		var closed_arc := ask_step.is_empty()
		var why := "" if closed_arc else FactionArcs.reason(
			_faction_arc_stats(faction_id), ask_step, int(faction_standing.get(faction_id, 0)), campaign_step)
		if i < arc_labels.size():
			var arc_label := arc_labels[i] as Label
			var arc_desc := arc_desc_labels[i] as Label
			if closed_arc:
				var perk := FactionArcs.perk(faction_id)
				arc_label.text = "%s — ARCO FECHADO: %s" % [str(faction["name"]), str(perk.get("name", ""))]
				arc_desc.text = "%s • a parede da loja guarda o nome de quem fez isso." % str(perk.get("desc", ""))
			else:
				arc_label.text = "%s — pedido %d de %d: %s" % [
					str(faction["name"]), arc_progress + 1, FactionArcs.size(faction_id), str(ask_step["title"])]
				var reward: Dictionary = ask_step["reward"]
				arc_desc.text = "%s\nCobra: %s (%s) • exige %s e %s • paga %d de ouro, +%d de fama, +%d XP, +%d de facção" % [
					str(ask_step["ask"]), FactionArcs.goal_text(ask_step),
					"%d/%d" % [FactionArcs.progress(_faction_arc_stats(faction_id), ask_step), int(ask_step["amount"])],
					"%s (%d de fama)" % [
						Factions.TIER_NAMES[Factions.tier_for(int(ask_step["standing"]))], int(ask_step["standing"])],
					"capítulo %d" % int(ask_step["chapter"]),
					int(reward["gold"]), int(reward["rep"]), int(reward["xp"]), int(reward["standing"])]
		if i < arc_buttons.size():
			var arc_button := arc_buttons[i] as Button
			arc_button.disabled = closed_arc or why != ""
			arc_button.text = "Fechado ✓" if closed_arc else (
				"Entregar pedido" if why == "" else "Trancado: %s" % why)
	if is_instance_valid(spec_summary_label):
		var assinados := spec_choice.size()
		spec_summary_label.text = "OFÍCIOS ASSINADOS: %d de %d.%s" % [
			assinados, TalentSpecs.count(), " " + _spec_names_text() if assinados > 0 else ""]
	var trails := TalentSpecs.trail_ids()
	for i in range(trails.size()):
		var trail_kind := str(trails[i])
		var trail_rank := int(get(trail_kind + "_rank"))
		var signed := str(spec_choice.get(trail_kind, ""))
		var options: Array = TalentSpecs.pair(trail_kind)
		var signed_name := str(TalentSpecs.find(signed).get("name", signed)) if signed != "" else ""
		var rival_name := ""
		for arc_option in options:
			if signed != "" and str(arc_option["id"]) != signed:
				rival_name = str(arc_option["name"])
		if i < spec_labels.size():
			var trail_title := str(TalentSpecs.TRAILS.get(trail_kind, trail_kind))
			var trail_suffix := ""
			if signed != "":
				trail_suffix = " • ofício: %s" % signed_name
			elif trail_rank >= TalentSpecs.CHOICE_RANK:
				trail_suffix = " • falta escolher ofício"
			(spec_labels[i] as Label).text = "%s — degrau %d/5%s" % [trail_title, trail_rank, trail_suffix]
		if i < spec_state_labels.size():
			var state_text := ""
			if signed != "":
				state_text = "A casa assinou %s. %s fica trancada até a próxima vida — raspar a tinta não dá." % [signed_name, rival_name]
			elif trail_rank >= TalentSpecs.CHOICE_RANK:
				state_text = "A trilha está no ombro do último degrau: assine um dos dois para o quinto ponto de talento abrir. O que ficar de fora dorme raspado até a vida seguinte."
			else:
				state_text = "Trancado: o ofício aparece no degrau %d da trilha (a casa está no %d)." % [TalentSpecs.CHOICE_RANK, trail_rank]
			var state_label := spec_state_labels[i] as Label
			state_label.text = state_text
			state_label.add_theme_color_override("font_color", Color(0.72, 0.98, 0.80) if signed != "" else Color(1.0, 0.84, 0.55) if trail_rank >= TalentSpecs.CHOICE_RANK else Color(0.66, 0.66, 0.78))
		if i < spec_buttons.size():
			var row_buttons: Array = spec_buttons[i]
			for j in range(options.size()):
				if j >= row_buttons.size():
					break
				var spec_data: Dictionary = options[j]
				var option_button := row_buttons[j] as Button
				var option_id := str(spec_data["id"])
				if signed == option_id:
					option_button.text = "✓ %s" % str(spec_data["name"])
					option_button.disabled = true
				elif signed != "":
					option_button.text = "✕ %s" % str(spec_data["name"])
					option_button.disabled = true
				else:
					option_button.text = str(spec_data["name"])
					option_button.disabled = trail_rank < TalentSpecs.CHOICE_RANK
	for r in range(Sanctum.DATA.size()):
		var ritual: Dictionary = Sanctum.DATA[r]
		var ritual_id := str(ritual["id"])
		var ritual_cost := Sanctum.cost_for(ritual, sanctum_upgrade_level)
		var running := Sanctum.is_active(active_buffs, ritual_id)
		if r < ritual_labels.size():
			if running:
				ritual_labels[r].text = "✦ Em curso: %s" % Sanctum.remaining_label(active_buffs, ritual_id, _world_seconds_since_tick())
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
				var trip_summary := _expedition_trip_summary(on_the_road, _world_seconds_since_tick())
				expedition_labels[e].text = trip_summary
				expedition_labels[e].add_theme_color_override("font_color", Color(1.0, 0.52, 0.38) if trip_summary.contains("⚔") else Color(1.0, 0.84, 0.55))
			elif not open_route:
				expedition_labels[e].text = "🔒 %s" % Expedition.locked_hint(destination)
				expedition_labels[e].add_theme_color_override("font_color", Color(0.74, 0.82, 0.78))
			else:
				expedition_labels[e].text = "%s • risco %d%% • %s" % [Expedition.days_label(_expedition_duration(destination)), int(destination["danger"]), Expedition.preview(destination)]
				expedition_labels[e].add_theme_color_override("font_color", Color(0.74, 0.82, 0.78))
		if e < expedition_buttons.size():
			expedition_buttons[e].text = "Voltando…" if on_the_road != {} else "Mandar (%d)" % trip_cost
			expedition_buttons[e].disabled = on_the_road != {} or not open_route or gold < trip_cost or expeditions.size() >= _expedition_slots()
	if is_instance_valid(expedition_active_label):
		if expeditions.is_empty():
			expedition_active_label.text = "Nenhuma viagem na estrada. Todos os batedores estão jogando cartas nos fundos."
		else:
			var routes: Array[String] = []
			for trip in expeditions:
				routes.append(_expedition_trip_summary(trip, _world_seconds_since_tick()))
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
	if is_instance_valid(card_bonus_label):
		card_bonus_label.text = "BÔNUS DO ÁLBUM\n" + "\n".join(Cards.bonus_lines(card_counts))
	if is_instance_valid(pack_button):
		var pack_cost := Cards.pack_price(packs_opened, card_counts)
		pack_button.text = "🂠 Abrir pacote (%d ouro)" % pack_cost
		pack_button.disabled = gold < pack_cost
	for c in range(Cards.DATA.size()):
		var card: Dictionary = Cards.DATA[c]
		var copies := int(card_counts.get(str(card["id"]), 0))
		if c < card_gallery_labels.size():
			var slot: Label = card_gallery_labels[c]
			var evolved := Cards.evolution(copies)
			slot.text = "%s\n%s • x%d%s" % [
				str(card["name"]), str(Cards.rarity_of(card)["name"]), copies,
				(" ✦ %s" % Cards.evolution_name(copies)) if evolved > 0 else "",
			] if copies > 0 else "?\n%s" % str(Cards.rarity_of(card)["name"])
			slot.add_theme_color_override("font_color", Cards.color_of(card) if copies > 0 else Color(0.42, 0.4, 0.48))
			# A moldura acompanha o degrau: holo clareia em prata, prismática queima em ouro.
			var panel_style := ((slot.get_parent() as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat)
			if panel_style != null:
				panel_style.border_color = Cards.color_of(card) if evolved == 0 else (Color(0.85, 0.95, 1.0, 0.95) if evolved == 1 else Color(1.0, 0.78, 0.35, 0.95))
				panel_style.set_border_width_all(1 if evolved == 0 else 2 + evolved)
	if is_instance_valid(board_label):
		board_label.text = "Sua pontuação: %d • recorde %d\n%s\n%s" % [
			business_score(), best_score, _season_text(), _board_text(),
		]
	if is_instance_valid(endings_label):
		endings_label.text = _endings_text()
	if is_instance_valid(score_button):
		var rank := 1 if steam == null else int(steam.call("rank_of", business_score()))
		score_button.text = "Publicar resultado • você está em %dº" % rank
	if is_instance_valid(chapter_label):
		chapter_label.text = _chapter_text()
		# A pontuação da vida é o que a meta de prestígio cobra, e ela muda a cada
		# venda: atualizar aqui é o que faz a barra da meta andar sem tique novo.
		_refresh_prestige()
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
	if is_instance_valid(prestige_label):
		_refresh_prestige()
	var ad_cost := 75 + ad_level * 60
	upgrade_button.text = "Propaganda infernal • %d ouro (nível %d)" % [ad_cost, ad_level]
	upgrade_button.disabled = gold < ad_cost
	private_button.text = "Momento especial (afinidade 5)" if affection >= 5 else "Momento especial • afinidade %d/5" % affection
	private_button.disabled = affection < 5
	if is_instance_valid(romance_label):
		romance_label.text = _romance_text()
	if is_instance_valid(arc_label):
		arc_label.text = _arc_text()
	if is_instance_valid(origin_label):
		origin_label.text = _origin_text()
	if is_instance_valid(origin_button):
		var has_memory := not origin_seen.is_empty()
		origin_button.visible = has_memory and not is_instance_valid(origin_layer)
		if has_memory:
			origin_button.text = "Relembrar: %s" % str(Origin.find(origin_seen[origin_seen.size() - 1]).get("title", "lembrança"))
	if is_instance_valid(romance_button):
		var invited: Dictionary = Regulars.find(romance_pending)
		var next_step := _romance_stage_of(romance_pending)
		if romance_pending.is_empty() or invited.is_empty():
			romance_button.text = "Convidar freguês • nenhum convite pendente"
			romance_button.disabled = true
		elif next_step >= ROMANCE_STEPS.size():
			romance_button.text = "%s • coração completo" % invited.get("short", "Freguês")
			romance_button.disabled = true
		else:
			var step_data: Dictionary = ROMANCE_STEPS[next_step]
			romance_button.text = "%s de %s • %d ouro • %d visitas" % [
				step_data["name"], invited.get("short", ""), step_data["gold"], step_data["bond"]
			]
			romance_button.disabled = gold < int(step_data["gold"]) \
				or int(regular_bonds.get(romance_pending, 0)) < int(step_data["bond"])
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
	config.set_value("game", "romance_stage", romance_stage)
	config.set_value("game", "regular_arc_seen", regular_arc_seen)
	config.set_value("game", "epilogue_pending", epilogue_pending)
	config.set_value("game", "epilogue_done", epilogue_done)
	config.set_value("game", "origin_seen", origin_seen)
	config.set_value("game", "prestige_runs", prestige_runs)
	config.set_value("game", "prestige_aura", prestige_aura)
	config.set_value("game", "prestige_perks", prestige_perks)
	config.set_value("game", "prestige_goals_paid", prestige_goals_paid)
	config.set_value("game", "endings_seen", endings_seen)
	config.set_value("game", "season_records", season_records)
	config.set_value("game", "season_baseline", season_baseline)
	config.set_value("game", "debt", debt)
	config.set_value("game", "debt_peak", debt_peak)
	config.set_value("game", "ruined_lives", ruined_lives)
	config.set_value("game", "ruined_seasons", ruined_seasons)
	config.set_value("game", "branches", branches)
	config.set_value("game", "staff_hired", staff_hired)
	config.set_value("game", "theft_blocked", theft_blocked)
	config.set_value("game", "queue_walkouts", queue_walkouts)
	config.set_value("game", "day_report", day_report)
	config.set_value("game", "day_auto_ok", day_auto_ok)
	config.set_value("game", "faction_standing", faction_standing)
	config.set_value("game", "faction_arc_step", faction_arc_step)
	config.set_value("game", "faction_customers", faction_customers)
	config.set_value("game", "spec_choice", spec_choice)
	config.set_value("game", "adult_content_enabled", adult_content_enabled)
	config.set_value("game", "adult_content_confirmed", adult_content_confirmed)
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
	config.set_value("game", "commission_index", commission_index)
	config.set_value("game", "commission_stage", commission_stage)
	config.set_value("game", "commission_progress", commission_progress)
	config.set_value("game", "commission_deadline", commission_deadline)
	config.set_value("game", "commission_next_offer", commission_next_offer)
	config.set_value("game", "commissions_finished", commissions_finished)
	config.set_value("game", "daily_gold_earned", daily_gold_earned)
	config.set_value("game", "daily_crafts", daily_crafts)
	config.set_value("game", "alchemy_rank", alchemy_rank)
	config.set_value("game", "trade_rank", trade_rank)
	config.set_value("game", "charm_rank", charm_rank)
	config.set_value("game", "logistics_rank", logistics_rank)
	config.set_value("game", "house_rank", house_rank)
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
	config.set_value("game", "legendary_crafted", legendary_crafted)
	config.set_value("game", "legendary_sold", legendary_sold)
	config.set_value("game", "exclusive_finished", exclusive_finished)
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
	config.set_value("game", "last_save_unix", int(Time.get_unix_time_from_system()))
	config.set_value("game", "offline_branch_fraction", _offline_branch_fraction)
	config.save(SAVE_PATH)

func _load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_offline_branch_fraction = clampf(float(config.get_value("game", "offline_branch_fraction", 0.0)), 0.0, 0.999999)
	var saved_at := int(config.get_value("game", "last_save_unix", 0))
	if saved_at > 0:
		_offline_elapsed_seconds = clampf(
			maxf(0.0, Time.get_unix_time_from_system() - float(saved_at)),
			0.0,
			OFFLINE_FARM_MAX_SECONDS)
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
	# O caderno de pedidos é da família, não da vida: reencarnar não apaga nome
	# nenhum na parede. Vem clampado — save antigo ou adulterado não ganha arco
	# pronto nem passo fora da tabela.
	var saved_arc_steps = config.get_value("game", "faction_arc_step", {})
	if saved_arc_steps is Dictionary:
		for step_id in saved_arc_steps.keys():
			var step_faction := str(step_id)
			var total := FactionArcs.size(step_faction)
			if total > 0:
				faction_arc_step[step_faction] = clampi(int(saved_arc_steps[step_id]), 0, total)
	var saved_customers = config.get_value("game", "faction_customers", {})
	if saved_customers is Dictionary:
		for customer_id in saved_customers.keys():
			faction_customers[str(customer_id)] = maxi(0, int(saved_customers[customer_id]))
	# Ofício é da vida, mas a vida pode ser cortada no meio e retomada: o que volta
	# do save tem de ser assinatura válida. Trilha que não existe e ofício que não é
	# daquela trilha são raspados na leitura, senão a build ficaria com dois lados.
	var saved_specs = config.get_value("game", "spec_choice", {})
	if saved_specs is Dictionary:
		for saved_kind in saved_specs.keys():
			var spec_kind := str(saved_kind)
			var spec_id := str(saved_specs[saved_kind])
			if TalentSpecs.has(spec_kind, spec_id):
				spec_choice[spec_kind] = spec_id
	var saved_romance = config.get_value("game", "romance_stage", {})
	if saved_romance is Dictionary:
		for saved_id in saved_romance.keys():
			romance_stage[str(saved_id)] = clampi(int(saved_romance[saved_id]), 0, ROMANCE_STEPS.size())
	# A ficha é nova neste save: quem já tinha visitas e capítulo não ganha o prêmio
	# do ato atrasado no primeiro tique, só entra no placar com o ato já alcançado.
	var saved_arcs = config.get_value("game", "regular_arc_seen", {})
	if saved_arcs is Dictionary:
		for arc_id in saved_arcs.keys():
			regular_arc_seen[str(arc_id)] = clampi(int(saved_arcs[arc_id]), 0, ARC_REWARDS.size())
	for regular in Regulars.DATA:
		var arc_id := str(regular["id"])
		regular_arc_seen[arc_id] = maxi(int(regular_arc_seen.get(arc_id, 0)), _arc_act(arc_id))
	# A fila da despedida é a única coisa do epílogo que precisa sobreviver ao
	# fechamento do jogo: quem saiu no meio da última rodada não pode perder a vez.
	epilogue_pending.clear()
	var saved_epilogue = config.get_value("game", "epilogue_pending", [])
	if saved_epilogue is Array:
		for queued_id in saved_epilogue:
			if not Regulars.find(str(queued_id)).is_empty():
				epilogue_pending.append(str(queued_id))
	epilogue_done = bool(config.get_value("game", "epilogue_done", epilogue_done))
	var saved_origins = config.get_value("game", "origin_seen", [])
	if saved_origins is Array:
		for scene_id in saved_origins:
			var known: Dictionary = Origin.find(str(scene_id))
			if not known.is_empty() and not origin_seen.has(str(known["id"])):
				origin_seen.append(str(known["id"]))
	var saved_endings = config.get_value("game", "endings_seen", [])
	if saved_endings is Array:
		for ending_id in saved_endings:
			var known_ending: Dictionary = Endings.find(str(ending_id))
			if not known_ending.is_empty() and not endings_seen.has(str(known_ending["id"])):
				endings_seen.append(str(known_ending["id"]))
	var saved_seasons = config.get_value("game", "season_records", {})
	if saved_seasons is Dictionary:
		for season in saved_seasons.keys():
			season_records[str(season)] = maxi(0, int(saved_seasons[season]))
	var saved_baseline = config.get_value("game", "season_baseline", {})
	if saved_baseline is Dictionary:
		for faction_id in saved_baseline.keys():
			season_baseline[str(faction_id)] = maxi(0, int(saved_baseline[faction_id]))
	# Save antigo não tem conta da casa: ele acorda devendo nada, porque o aluguel
	# começa a correr na primeira virada depois de carregar.
	debt = maxi(0, int(config.get_value("game", "debt", debt)))
	debt_peak = maxi(0, int(config.get_value("game", "debt_peak", debt_peak)))
	ruined_lives = maxi(0, int(config.get_value("game", "ruined_lives", ruined_lives)))
	var saved_ruined = config.get_value("game", "ruined_seasons", [])
	if saved_ruined is Array:
		for season in saved_ruined:
			if str(season).is_valid_int() and int(str(season)) > 0 and not ruined_seasons.has(str(season)):
				ruined_seasons.append(str(season))
	# Id que não está mais na tabela não reabre: a filial some do save em vez de
	# continuar cobrando conta sem existir no painel.
	var saved_branches = config.get_value("game", "branches", [])
	branches.clear()
	if saved_branches is Array:
		for branch_id in saved_branches:
			if Branches.knows(str(branch_id)) and not branches.has(str(branch_id)):
				branches.append(str(branch_id))
	# Save antigo não tem folha: o balcão acorda só com a chefe, sem salário nenhum
	# na conta, exatamente como era antes de a loja contratar gente.
	var saved_staff = config.get_value("game", "staff_hired", [])
	staff_hired.clear()
	if saved_staff is Array:
		for seat_id in saved_staff:
			if Staff.knows(str(seat_id)) and not staff_hired.has(str(seat_id)):
				staff_hired.append(str(seat_id))
	theft_blocked = maxi(0, int(config.get_value("game", "theft_blocked", theft_blocked)))
	queue_walkouts = maxi(0, int(config.get_value("game", "queue_walkouts", queue_walkouts)))
	day_report = str(config.get_value("game", "day_report", day_report))
	day_auto_ok = bool(config.get_value("game", "day_auto_ok", day_auto_ok))
	prestige_runs = int(config.get_value("game", "prestige_runs", prestige_runs))
	prestige_aura = int(config.get_value("game", "prestige_aura", prestige_aura))
	var saved_perks = config.get_value("game", "prestige_perks", {})
	prestige_perks.clear()
	if saved_perks is Dictionary:
		for perk_id in saved_perks.keys():
			var perk := Prestige.perk(str(perk_id))
			if int(perk.get("max", 0)) > 0:
				prestige_perks[str(perk_id)] = clampi(int(saved_perks[perk_id]), 0, int(perk["max"]))
	prestige_goals_paid = int(config.get_value("game", "prestige_goals_paid", prestige_goals_paid))
	adult_content_confirmed = bool(config.get_value("game", "adult_content_confirmed", false))
	adult_content_enabled = adult_content_confirmed and bool(config.get_value("game", "adult_content_enabled", false))
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
	commission_index = int(config.get_value("game", "commission_index", commission_index))
	commission_stage = int(config.get_value("game", "commission_stage", commission_stage))
	commission_progress = int(config.get_value("game", "commission_progress", commission_progress))
	commission_deadline = int(config.get_value("game", "commission_deadline", commission_deadline))
	commission_next_offer = int(config.get_value("game", "commission_next_offer", commission_next_offer))
	commissions_finished = int(config.get_value("game", "commissions_finished", commissions_finished))
	# Save antigo não tinha encomenda nenhuma, e um índice lido de um catálogo que
	# mudou de tamanho apontaria para fora da tabela: na dúvida, o balcão fica livre.
	if commission_index < 0 or commission_index >= COMMISSIONS.size():
		commission_index = -1
		_clear_commission()
	if commission_next_offer <= 0:
		commission_next_offer = shop_day + 1
	daily_gold_earned = int(config.get_value("game", "daily_gold_earned", daily_gold_earned))
	daily_crafts = int(config.get_value("game", "daily_crafts", daily_crafts))
	alchemy_rank = int(config.get_value("game", "alchemy_rank", alchemy_rank))
	trade_rank = int(config.get_value("game", "trade_rank", trade_rank))
	charm_rank = int(config.get_value("game", "charm_rank", charm_rank))
	logistics_rank = int(config.get_value("game", "logistics_rank", logistics_rank))
	house_rank = int(config.get_value("game", "house_rank", house_rank))
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
	legendary_crafted = int(config.get_value("game", "legendary_crafted", legendary_crafted))
	legendary_sold = int(config.get_value("game", "legendary_sold", legendary_sold))
	exclusive_finished = int(config.get_value("game", "exclusive_finished", exclusive_finished))
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
	],
	"house": [
		"Ela risca três contratos e a conta do dia encolhe sozinha no balcão: “Viu? Administrar a casa também é feitiçaria.”",
		"A cadeira velha vira estofada com o que a loja deixou de pagar: “Economia doméstica é isto: comprar conforto com o dinheiro que ia embora.”",
		"As planilhas voam do balcão e aterrassam em fila: “Cada moeda que a casa não gasta é um presente que eu me dou à noite.”"
	]
}
const TALENT_MAX_LINES := {
	"alchemy": "Ela abre os braços e o laboratório inteiro cintila: “Mestra alquimista! Agora os frascos é que pedem desculpas para mim.”",
	"trade": "Ela apoia o queixo na mão: “Nível máximo de negociação. Vou começar a vender até o seu 'não' de volta, com juros.”",
	"charm": "O ar fica rosado e quente: “Carisma máximo. Se eu piscar errado, vou precisar de uma fila de seguranças... e de um ventilador.”",
	"logistics": "Todos os imps batem continência ao mesmo tempo: “Logística perfeita. Até o caos agora chega pontual.”",
	"house": "Ela põe os pés sobre a mesa cheia de contratos já assinados: “Administração máxima. O teto da dívida subiu, o custo do dia caiu, e o coletor agora bate na porta pedindo desculpas antes de entrar.”"
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
	# O quinto degrau não é mais um ponto: é a conta de uma escolha. Sem ofício
	# assinado a trilha para no nível 4, e é o painel que diz quais são os dois.
	if int(get(kind + "_rank")) >= TalentSpecs.CHOICE_RANK and str(spec_choice.get(kind, "")) == "":
		last_event = "A trilha está no ombro do último degrau, mas falta escolher ofício: %s. Assine um dos dois na seção \"Especializações\" e a casa volta a subir." % TalentSpecs.names(kind)
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
		"house":
			if house_rank >= 5:
				return
			house_rank += 1
			last_event = "Talento Administração da Casa melhorado! A conta diária da loja fica 8% mais leve por nível."
			if house_rank >= 2:
				last_event += " Do nível 2 em diante, cada nível corta 1% do dia ruim das filiais."
			if house_rank >= 5:
				last_event += " No máximo, o teto da dívida sobe para %d." % _debt_limit()

	skill_points -= 1
	audio.play("talent")
	_save_game()
	_refresh_ui()
	var new_rank := int(get(kind + "_rank"))
	_play_talent_reaction(kind, new_rank)

## A pergunta que as fórmulas da loja fazem: esta trilha assinou este ofício?
func _has_spec(kind: String, spec_id: String) -> bool:
	return str(spec_choice.get(kind, "")) == spec_id

func _spec_names_text() -> String:
	var names: Array[String] = []
	for kind in TalentSpecs.trail_ids():
		var signed := str(spec_choice.get(str(kind), ""))
		if signed != "":
			names.append(str(TalentSpecs.find(signed).get("name", signed)))
	if names.is_empty():
		return ""
	return "Ofícios desta vida: %s." % ", ".join(names)

## Assinar ofício é de graça e não custa ponto — o preço é o outro lado da moeda,
## que fica trancado até a vida seguinte. Por isso a recusa também explica o que
## ainda falta, em vez de só apagar o botão.
func _choose_spec(kind: String, spec_id: String) -> void:
	if not TalentSpecs.has(kind, spec_id):
		return
	var chosen := str(spec_choice.get(kind, ""))
	if chosen != "":
		last_event = "A casa já assinou %s nesta vida. Raspar a tinta não dá: a outra fica para a próxima." % str(TalentSpecs.find(chosen).get("name", chosen))
		_refresh_ui()
		return
	if int(get(kind + "_rank")) < TalentSpecs.CHOICE_RANK:
		last_event = "%s ainda não tem ombro para carregar ofício: chegue ao nível %d da trilha." % [
			str(TalentSpecs.TRAILS.get(kind, kind)), TalentSpecs.CHOICE_RANK]
		_refresh_ui()
		return
	var spec := TalentSpecs.find(spec_id)
	spec_choice[kind] = spec_id
	last_event = "ESPECIALIZAÇÃO — %s: %s" % [str(spec["name"]), str(spec["line"])]
	audio.play("talent")
	_show_feedback("✦ %s" % str(spec["name"]), Color(0.72, 1.0, 0.82))
	if not demonic_form_active:
		_set_seller_mood("happy")
	_check_achievements()
	_save_game()
	_refresh_ui()

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
	player_xp += int(round(float(amount) * Sanctum.scale(active_buffs, "xp") * _prestige_xp_factor()))
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
	return DAILY_QUESTS[posmod(daily_quest_index, DAILY_QUESTS.size())]

## Um tique só alimenta as duas escalas de contrato: o do dia, que expira na
## virada, e a encomenda do patrono, que atravessa dias. Manter os dois num único
## ponto é o que impede uma venda de contar para um e esquecer o outro.
func _progress_contracts(kind: String, amount: int) -> void:
	if not daily_quest_claimed and str(_get_daily_quest()["type"]) == kind:
		daily_quest_progress += amount
	_progress_commission(kind, amount)

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

func _get_commission() -> Dictionary:
	if commission_index < 0 or commission_index >= COMMISSIONS.size():
		return {}
	return COMMISSIONS[commission_index]

func _commission_stages() -> Array:
	var commission := _get_commission()
	if commission.is_empty():
		return []
	return commission["stages"]

func _commission_stage() -> Dictionary:
	var stages := _commission_stages()
	if commission_stage < 0 or commission_stage >= stages.size():
		return {}
	return stages[commission_stage]

func _commission_stage_text(stage: Dictionary) -> String:
	return COMMISSION_STAGE_TEXTS.get(str(stage["type"]), "Cumprir %d tarefas") % int(stage["target"])

func _commission_ready() -> bool:
	var stage := _commission_stage()
	return not stage.is_empty() and commission_progress >= int(stage["target"])

func _progress_commission(kind: String, amount: int) -> void:
	var stage := _commission_stage()
	if commission_index < 0 or stage.is_empty() or str(stage["type"]) != kind:
		return
	commission_progress += amount

func _commission_summary() -> String:
	if commission_index < 0:
		return "ENCOMENDA DE LONGO PRAZO\nNada sobre o balcão. O próximo patrono chega no dia %d." % commission_next_offer
	var commission := _get_commission()
	var stage := _commission_stage()
	var target: int = int(stage["target"])
	return "ENCOMENDA DE LONGO PRAZO%s\n%s (%s)\nEtapa %d/%d — %s (%d/%d)\nRestam %d dia(s) de prazo." % [
		" • EXCLUSIVA DO TOPO DA FORJA" if bool(commission.get("exclusive", false)) else "",
		commission["name"],
		Factions.find(str(commission["faction"])).get("short", commission["faction"]),
		commission_stage + 1,
		_commission_stages().size(),
		_commission_stage_text(stage),
		mini(commission_progress, target),
		target,
		maxi(0, commission_deadline - shop_day),
	]

## Entrega a etapa pronta e, se era a última, fecha a encomenda. O ouro da etapa
## cresce com o dia da loja para que uma encomenda antiga não valha menos que uma
## recém-chegada.
func _deliver_commission_stage() -> void:
	if not _commission_ready():
		return
	var commission := _get_commission()
	var stage := _commission_stage()
	var gold_reward: int = int(stage["gold"]) + shop_day * 2
	gold += gold_reward
	_add_xp(int(stage["xp"]))
	commission_progress = 0
	commission_stage += 1
	if commission_stage >= _commission_stages().size():
		_finish_commission(commission)
	else:
		last_event = "Etapa %d da encomenda “%s” entregue: +%d ouro, +%d XP. Próxima: %s." % [
			commission_stage, commission["name"], gold_reward, int(stage["xp"]),
			_commission_stage_text(_commission_stage()),
		]
	_save_game()
	_refresh_ui()

func _finish_commission(commission: Dictionary) -> void:
	commissions_finished += 1
	var exclusive := bool(commission.get("exclusive", false))
	if exclusive:
		exclusive_finished += 1
	gold += int(commission["bonus_gold"])
	reputation += int(commission["bonus_rep"])
	_add_xp(int(commission["bonus_xp"]))
	var faction_id := str(commission["faction"])
	faction_standing[faction_id] = int(faction_standing.get(faction_id, 0)) + int(commission["bonus_standing"])
	_clear_commission()
	commission_next_offer = shop_day + 2
	_show_stage_emotion(stage_seller_body, "aplausao")
	last_event = "ENCOMENDA %sFECHADA: “%s” entregue por inteiro. +%d ouro, +%d XP, +%d reputação e a %s agora confia mais na casa." % [
		"EXCLUSIVA " if exclusive else "",
		commission["name"], int(commission["bonus_gold"]), int(commission["bonus_xp"]),
		int(commission["bonus_rep"]), Factions.find(faction_id).get("short", faction_id),
	]
	_check_achievements()

func _clear_commission() -> void:
	commission_index = -1
	commission_stage = 0
	commission_progress = 0
	commission_deadline = 0

## A encomenda vive no relógio da virada: atrasar custa reputação, e o balcão livre
## recebe o pedido do dia seguinte sem precisar de aceitação — o patrono simplesmente
## deixa o envelope sobre o caixa.
func _advance_commission() -> void:
	if commission_index >= 0 and shop_day > commission_deadline:
		var late := _get_commission()
		reputation = maxi(0, reputation - 4)
		_clear_commission()
		commission_next_offer = shop_day + 1
		last_event += "\nENCOMENDA ATRASADA: “%s” venceu. A %s cobrou o prejuízo em reputação (-4)." % [
			late["name"], Factions.find(str(late["faction"])).get("short", "casa"),
		]
		return
	if commission_index < 0 and shop_day >= commission_next_offer:
		var mastery := _forge_mastery()
		var pool: Array[int] = []
		for i in range(COMMISSIONS.size()):
			# O pedido exclusivo não aparece para quem não tem bigorna que o cumpra.
			if bool(COMMISSIONS[i].get("exclusive", false)) and not Quality.open(mastery):
				continue
			pool.append(i)
		if pool.is_empty():
			return
		commission_index = pool[randi() % pool.size()]
		var commission := _get_commission()
		commission_stage = 0
		commission_progress = 0
		commission_deadline = shop_day + int(commission["days"])
		last_event += "\nNOVA ENCOMENDA DE LONGO PRAZO: “%s”, da %s. Primeira etapa: %s. Prazo até o dia %d." % [
			commission["name"], Factions.find(str(commission["faction"])).get("short", commission["faction"]),
			_commission_stage_text(_commission_stage()), commission_deadline,
		]

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
		{"id": "legendary_piece", "name": "Lendário (o topo do espectro tem sua assinatura)", "condition": best_quality_crafted >= Quality.LEGENDARY, "gold": 300, "rep": 12, "pose": "relic"},
		{"id": "legendary_three", "name": "Mestra da Bigorna (3 peças Lendárias)", "condition": legendary_crafted >= 3, "gold": 420, "rep": 15},
		{"id": "exclusive_patron", "name": "Casa das Obras Raras (encomenda exclusiva fechada)", "condition": exclusive_finished >= 1, "gold": 350, "rep": 14, "pose": "book"},
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
		{"id": "commission_first", "name": "Palavra de loja (primeira encomenda fechada)", "condition": commissions_finished >= 1, "gold": 60, "rep": 3},
		{"id": "commission_five", "name": "Casa de confiança (5 encomendas fechadas)", "condition": commissions_finished >= 5, "gold": 200, "rep": 8},
		{"id": "romance_first", "name": "Primeiro convite (um freguês na escada)", "condition": _romance_steps_paid() >= 1, "gold": 50, "rep": 3},
		{"id": "romance_dates", "name": "Coração ocupado (3 degraus pagos)", "condition": _romance_steps_paid() >= 3, "gold": 120, "rep": 6},
		{"id": "romance_devoted", "name": "Amor de balcão (3 fregueses no degrau final)", "condition": _romance_at_least(3) >= 3, "gold": 260, "rep": 10, "pose": "relic"},
		{"id": "arc_second", "name": "Ficha aberta (um freguês no Ato II)", "condition": _arc_at_least(2) >= 1, "gold": 40, "rep": 3},
		{"id": "arc_faces", "name": "Casa cheia (nove fichas no Ato I)", "condition": _arc_at_least(1) >= Regulars.DATA.size(), "gold": 120, "rep": 6},
		{"id": "arc_stories", "name": "Contadora de histórias (3 fichas no Ato III)", "condition": _arc_at_least(3) >= 3, "gold": 200, "rep": 9, "pose": "book"},
		{"id": "arc_finals", "name": "Elenco completo (3 fichas no Ato IV)", "condition": _arc_at_least(4) >= 3, "gold": 240, "rep": 11, "pose": "relic"},
		{"id": "epilogue_farewell", "name": "A última rodada (despedida encerrada)", "condition": epilogue_done, "gold": 150, "rep": 8, "pose": "relic"},
		{"id": "origin_first", "name": "Andar de cima (primeira lembrança)", "condition": origin_seen.size() >= 1, "gold": 40, "rep": 2},
		{"id": "origin_all", "name": "Duas vidas no mesmo balcão (todas as lembranças)", "condition": origin_seen.size() >= Origin.size(), "gold": 220, "rep": 9, "pose": "book"},
		{"id": "prestige_first", "name": "Segunda vida (primeira reencarnação)", "condition": prestige_runs >= 1, "gold": 60, "rep": 3},
		{"id": "prestige_round5", "name": "Casa de muitas portas (cinco reencarnações)", "condition": prestige_runs >= 5, "gold": 220, "rep": 10, "pose": "vitoria"},
		{"id": "prestige_perks", "name": "Aura bem gasta (cinco níveis de dote)", "condition": _perk_levels_total() >= 5, "gold": 120, "rep": 5, "pose": "book"},
		{"id": "prestige_goal", "name": "Meta batida (primeira meta de vida)", "condition": prestige_goals_paid >= 1, "gold": 80, "rep": 4},
		{"id": "ending_first", "name": "Primeiro final (o balcão fechou um capítulo sete)", "condition": endings_seen.size() >= 1, "gold": 120, "rep": 6},
		{"id": "ending_faction", "name": "Final com dono (uma facção fechou a loja)", "condition": _has_faction_ending(), "gold": 180, "rep": 8, "pose": "relic"},
		{"id": "endings_three", "name": "Três despedidas (três finais diferentes)", "condition": endings_seen.size() >= 3, "gold": 300, "rep": 12},
		{"id": "endings_all", "name": "Todos os finais deste balcão", "condition": endings_seen.size() >= Endings.size(), "gold": 600, "rep": 20, "pose": "vitoria"},
		{"id": "ruin_first", "name": "Cheiro de mofo no caixa (uma vida fechou em ruína)", "condition": ruined_lives >= 1, "gold": 60, "rep": 2},
		{"id": "debt_escaped", "name": "Saindo do buraco (quitar 120 de dívida pagando em dia)", "condition": debt == 0 and debt_peak >= 120, "gold": 200, "rep": 8, "pose": "vitoria"},
		{"id": "branch_first", "name": "Endereço fora do bairro (primeira filial)", "condition": not branches.is_empty(), "gold": 120, "rep": 4},
		{"id": "branch_self_made", "name": "A casa se paga (filiais cobrem a conta da casa)", "condition": not branches.is_empty() and Branches.expected_profit(branches, _branch_care()) >= _daily_upkeep(), "gold": 300, "rep": 10, "pose": "book"},
		{"id": "branch_all", "name": "Império de esquina a beco (todas as filiais abertas)", "condition": branches.size() >= Branches.size(), "gold": 500, "rep": 15, "pose": "danca"},
		{"id": "staff_full", "name": "Quadro cheio (as quatro vagas do balcão pagando salário juntas)", "condition": staff_hired.size() >= Staff.size(), "gold": 340, "rep": 12, "pose": "vitoria"},
		{"id": "staff_rounds", "name": "A ronda conhece o beco (três furtos barrados na mesma vida)", "condition": theft_blocked >= 3, "gold": 220, "rep": 8, "pose": "book"},
		{"id": "queue_lost", "name": "A porta também chora (cinco visitas que desistiram da fila)", "condition": queue_walkouts >= 5, "gold": 180, "rep": 6, "pose": "recusa"},
		{"id": "house_talent_max", "name": "A casa no cabresto (Administração da Casa no nível máximo)", "condition": house_rank >= 5, "gold": 260, "rep": 9, "pose": "book"},
		{"id": "faction_arc_first", "name": "Primeira assinatura no caderno (um pedido de facção entregue)", "condition": _faction_asks_delivered() >= 1, "gold": 100, "rep": 3},
		{"id": "faction_arc_all", "name": "As cinco fachadas assinadas (todas as facções com arco fechado)", "condition": _faction_arcs_closed() >= Factions.DATA.size(), "gold": 700, "rep": 22, "pose": "vitoria"},
		{"id": "spec_all", "name": "Cinco ofícios na parede (todas as trilhas com especialização assinada)", "condition": spec_choice.size() >= TalentSpecs.count(), "gold": 420, "rep": 16, "pose": "vitoria"},
		{"id": "spec_destilaria_legend", "name": "A destilaria pagou a peça (sorte de ofício e um Lendário vendido no balcão)", "condition": _has_spec("alchemy", "destilaria") and legendary_sold >= 1, "gold": 360, "rep": 13, "pose": "relic"},
		{"id": "card_holo", "name": "Brilho de coleção (primeira carta holográfica)", "condition": Cards.evolved_count(card_counts, 1) >= 1, "gold": 90, "rep": 4},
		{"id": "card_prism", "name": "Prisma no mural (uma carta em seis cópias)", "condition": Cards.evolved_count(card_counts, 2) >= 1, "gold": 240, "rep": 10, "pose": "vitoria"},
		{"id": "card_album_working", "name": "Álbum trabalhando (os três conjuntos pagando bônus)", "condition": Cards.luck_bonus(card_counts) >= 1 and Cards.price_bonus(card_counts) >= 0.04 and Cards.pack_discount(card_counts) >= 2, "gold": 150, "rep": 6},
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
	_check_prestige_goal()

func _achievement_ids() -> Array[String]:
	var ids: Array[String] = []
	for achievement in _achievement_definitions():
		ids.append(str(achievement["id"]))
	return ids

## Abre um pacote de cartas. Brinde de conquista chega de graça; no balcão tem preço.
func _grant_pack(free: bool) -> void:
	var price := Cards.pack_price(packs_opened, card_counts)
	if not free:
		if gold < price:
			last_event = "O pacote custa %d ouro. A loja não aprova fiado nem para nostalgia." % price
			_refresh_ui()
			return
		gold -= price
	var opened: Dictionary = Cards.open_pack(card_counts, alchemy_rank + Sanctum.luck_bonus(active_buffs) + _prestige_luck() + _card_luck() + _road_pact_luck())
	packs_opened += 1
	var card: Dictionary = opened["card"]
	var card_id := str(card["id"])
	var copies := int(card_counts.get(card_id, 0))
	last_pack_card = card_id
	var text := ""
	if bool(opened["duplicate"]):
		# A cópia que fecha um degrau não devolve ouro: ela sobe a carta de nível,
		# e é o degrau que pesa no bônus do conjunto.
		if Cards.evolution(copies) > Cards.evolution(copies - 1):
			text = "%s virou %s na %dª cópia. O mural inteiro sente o peso." % [
				card["name"], Cards.evolution_name(copies), copies
			]
			audio.play("levelup")
		else:
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
		text += " Coleção %s completa: +4 de reputação e o bônus do set dobra de peso." % str(Cards.SET_NAMES[str(finished)])
	_show_feedback("🂠 Pacote aberto.", Color(1.0, 0.86, 0.45))
	last_event = text
	_play_card_flip(card_id)
	# O pacote é o único lugar onde o álbum cresce: é aqui, e não no próximo
	# freguês, que a conquista de evolução tem de bater.
	_check_achievements()
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
		+ campaign_step * 60 + private_moments_unlocked * 8 + _romance_steps_paid() * 20 \
		+ _arc_acts_announced() * 12 + origin_seen.size() * 25 + (1200 if game_completed else 0) \
		+ legendary_crafted * 60 + exclusive_finished * 120 + endings_seen.size() * 30 \
		+ branches.size() * 90 + staff_hired.size() * 30 \
		+ prestige_runs * 150 + _perk_levels_total() * 20 + prestige_goals_paid * 40

func _publish_score() -> void:
	var score := business_score()
	best_score = maxi(best_score, score)
	_bank_season()
	if steam != null:
		steam.call("submit_score", score, "Sua loja")
		steam.call("request_leaderboard")
	last_event = "Resultado publicado no placar: %d pontos." % score
	audio.play("coin")
	_refresh_ui()
	_save_game()

## Temporada é a vida da loja. Cada virada de balanço arquiva o melhor resultado
## dela; reencarnar não apaga a temporada anterior, só abre a próxima.
func _bank_season() -> void:
	var season := str(Prestige.season(prestige_runs))
	season_records[season] = maxi(int(season_records.get(season, 0)), business_score())

func _season_best(season: int) -> int:
	return int(season_records.get(str(season), 0))

## O resumo da corrida em curso e das que já fecharam, para o placar da biblioteca.
func _season_text() -> String:
	var current := Prestige.season(prestige_runs)
	var lines: Array[String] = ["Temporada %d aberta • recorde da temporada: %d" % [current, _season_best(current)]]
	lines.append("· o capítulo sete desta vida fecha com: %s" % str(Endings.for_standing(_life_standing())["title"]))
	for run in range(prestige_runs):
		# A temporada perdida não some do placar: ela aparece como o que foi.
		var how := "fechou no vermelho com" if ruined_seasons.has(str(run + 1)) else "fechou com"
		lines.append("· temporada %d %s %d" % [run + 1, how, _season_best(run + 1)])
	if prestige_runs == 0:
		lines.append("· reencarnar o balcão fecha esta temporada e abre a próxima")
	return "\n".join(lines)

## O que a temporada atual pesou em cada facção, descontado o ponteiro que a vida
## herdou da anterior. É essa conta, e não a fama total, que decide o final.
func _life_standing() -> Dictionary:
	var life: Dictionary = {}
	for faction in Factions.DATA:
		var faction_id := str(faction["id"])
		life[faction_id] = maxi(0, int(faction_standing.get(faction_id, 0)) - int(season_baseline.get(faction_id, 0)))
	return life

## A mesma conta, escrita para o jogador ver por que o capítulo fechou daquele jeito.
func _life_standing_text() -> String:
	var life := _life_standing()
	var parts: Array[String] = []
	for faction in Factions.DATA:
		parts.append("%s %d" % [str(faction["short"]), int(life[str(faction["id"])])])
	return " • ".join(parts)

## O final do império é da facção que mais usou o balcão nesta vida. Registrar o
## final é o que faz ele entrar no arquivo e valer conquista — uma vez por id.
func _claim_ending() -> Dictionary:
	var ending := Endings.for_standing(_life_standing())
	var ending_id := str(ending["id"])
	if not endings_seen.has(ending_id):
		endings_seen.append(ending_id)
		_check_achievements()
	return ending

## Arquivo dos finais já conquistados, na ordem da tabela.
func _endings_text() -> String:
	var lines: Array[String] = []
	for ending in Endings.ENDINGS:
		var id := str(ending["id"])
		lines.append("· %s — %s" % [str(ending["title"]), "visto" if endings_seen.has(id) else "ainda não"])
	return "\n".join(lines)

## Algum capítulo sete já fechou com o selo de uma facção, em vez de fechar com o
## selo da própria casa ou com o carimbo da ruína?
func _has_faction_ending() -> bool:
	for id in endings_seen:
		if str(id) != Endings.HOUSE and str(id) != Endings.RUIN:
			return true
	return false

## O custo da casa: loja grande custa mais que loja de esquina, e é isso que impede
## o caixa de ser um número que só sobe.
const DEBT_LIMIT := 240

## O teto da dívida é negociável: a chefe que aprende a administrar a casa ganha
## folga no vermelho antes de o coletor levar o salão.
func _debt_limit() -> int:
	return DEBT_LIMIT + (60 if house_rank >= 5 else 0)

## Da segunda marcha para cima, a administração acompanha as filiais de perto e
## cada ponto derruba um ponto percentual da chance de dia ruim. A porta sem placa
## do beco vale mais três pontos na mesma conta: proteção de rua também é zelo.
func _branch_care() -> int:
	return maxi(0, house_rank - 1) + (3 if _faction_arc_closed("submundo") else 0) + (2 if _has_spec("house", "porteiro") else 0)

func _daily_upkeep() -> int:
	var bill := 12 + library_upgrade_level * 6 + sanctum_upgrade_level * 6 + ad_level * 5 \
		+ (18 if imp_hired else 0) + Branches.total_upkeep(branches) \
		+ Staff.total_wage(staff_hired)
	## Conta de casa bem administrada encolhe 8% por marcha, e a conta é o que
	## segura o império: por isso a trilha mexe nela e não na receita.
	return maxi(1, int(round(float(bill) * (1.0 - 0.08 * float(house_rank)) * (0.9 if _has_spec("house", "livro") else 1.0))))

## A virada de dia cobra a conta. Pagar em dia usa o que sobrou de caixa para
## escavar a dívida; não pagar não perdoa — o faltante entra no vermelho da casa.
func _pay_upkeep() -> String:
	var bill := _daily_upkeep()
	var paid := mini(gold, bill)
	gold -= paid
	var short := bill - paid
	if short > 0:
		debt += short
		debt_peak = maxi(debt_peak, debt)
		if debt >= _debt_limit():
			return "A casa cobrou %d e o caixa tinha só %d. Faltaram %d: a dívida estourou em %d e o coletor já está na calçada." % [
				bill, paid, short, debt]
		if debt >= _debt_limit() / 2:
			return "A casa cobrou %d e o caixa tinha só %d. Faltaram %d, e a dívida de %d já passa da metade do teto." % [
				bill, paid, short, debt]
		return "A casa cobrou %d e o caixa tinha só %d. A loja foi dormir devendo %d." % [bill, paid, debt]
	# Ouro que sobra depois da conta é o único que escava: um décimo do caixa, e a
	# escrevente do livro-caixa sabe achar mais na mesma sobra.
	var dig := mini(debt, int(gold * Staff.debt_dig_share(staff_hired)))
	debt -= dig
	if dig > 0:
		return "A casa cobrou %d, pago em dia — e a loja ainda abateu %d da dívida, que agora é %d." % [bill, dig, debt]
	if debt > 0:
		return "A casa cobrou %d, pago em dia. O caixa zerado não abateu a dívida de %d." % [bill, debt]
	return "A casa cobrou %d de custo do dia, pago em dia." % bill

## As filiais trabalham na virada: cada uma paga o lucro do dia ou cobra o
## conserto. O saldo entra no caixa, e o que o caixa não cobre vira dívida — é
## exatamente assim que a expansão afunda quem mediu mal a própria conta.
func _collect_branches() -> String:
	if branches.is_empty():
		return ""
	var results: Array[int] = []
	var net := 0
	var damaged := false
	for id in branches:
		var gain := Branches.roll(Branches.find(str(id)), _card_luck(), _branch_care())
		results.append(gain)
		net += gain
		damaged = damaged or gain < 0
	gold += net
	if gold < 0:
		debt += -gold
		gold = 0
		debt_peak = maxi(debt_peak, debt)
	if damaged:
		audio.play("sad")
	return "FILIAIS: %s • saldo %+d no caixa." % [Branches.ledger(branches, results), net]

## Abrir filial é gastar o caixa de uma vez para trocar de renda por virada — e de
## conta por virada também. Os três motivos de recusa são as três portas do gate.
func _open_branch(id: String) -> void:
	var branch := Branches.find(id)
	if branch.is_empty():
		return
	if branches.has(id):
		last_event = "%s já está de portas abertas. Duas chaves do mesmo endereço não vendem o dobro." % str(branch["name"])
		return
	var blocked := Branches.gate(branch, campaign_step, faction_standing)
	if blocked != "":
		last_event = "%s ainda não é para hoje: %s." % [str(branch["name"]), blocked]
		audio.play("sad")
		return
	var cost := int(branch["cost"])
	if gold < cost:
		last_event = "%s custa %d de ouro. Faltam %d — a banca da feira não é fiado." % [
			str(branch["name"]), cost, cost - gold]
		audio.play("sad")
		return
	gold -= cost
	branches.append(id)
	last_event = str(branch["open"])
	audio.play("levelup")
	_show_feedback("✦ %s aberta." % str(branch["name"]), Color(0.72, 1.0, 0.82))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Quem banca a filial: sem padrinho de facção a porta não abre, e o painel precisa
## dizer o nome do padrinho e o quanto de fama ele cobra.
func _branch_faction_label(branch: Dictionary) -> String:
	var faction_id := str(branch["faction"])
	if faction_id == "":
		return "qualquer loja de bairro dá o endereço"
	return "padrinho: %s, %d de fama" % [str(Factions.find(faction_id).get("name", faction_id)), int(branch["standing"])]

## ── Quadro de funcionários ─────────────────────────────────────────────────────

## As portas que uma vaga lê: capítulo fechado, fama de facção, reputação no bairro,
## degrau de trilha e o coração da chefe. Nada aqui é chave nova de save — é tudo
## número que a loja já carrega.
func _staff_gate_state() -> Dictionary:
	return {
		"chapter": campaign_step,
		"standing": faction_standing,
		"rep": reputation,
		"ranks": {"alchemy": alchemy_rank, "trade": trade_rank, "charm": charm_rank,
			"logistics": logistics_rank, "house": house_rank},
		"affection": affection,
	}

## O mesmo botão serve para entrar e sair: a folha é despesa, e demitir tem de ser
## tão barato quanto contratar é caro — senão a vaga vira melhoria permanente e a
## conta deixa de ser decisão.
func _manage_staff(id: String) -> void:
	var seat := Staff.find(id)
	if seat.is_empty():
		return
	if staff_hired.has(id):
		staff_hired.erase(id)
		last_event = "%s pegou a chave e o resto do mês. A loja agradece, e a conta deixa de cobrar %d por virada." % [
			str(seat["name"]), int(seat["wage"])]
		audio.play("click")
		_show_feedback("✕ %s fora do balcão." % str(seat["name"]), Color(0.86, 0.72, 0.62))
		_save_game()
		_refresh_ui()
		return
	var blocked := Staff.gate(seat, _staff_gate_state())
	if blocked != "":
		last_event = "%s não entra hoje: %s." % [str(seat["name"]), blocked]
		audio.play("sad")
		_refresh_ui()
		return
	var fee := int(seat["hire"])
	if gold < fee:
		last_event = "%s pede %d de ouro na entrada. Faltam %d — e ela não começa de graça." % [
			str(seat["name"]), fee, fee - gold]
		audio.play("sad")
		_refresh_ui()
		return
	gold -= fee
	staff_hired.append(id)
	last_event = "%s entrou no balcão. A taxa foi %d e o salário é %d em toda virada, dentro da conta da casa." % [
		str(seat["name"]), fee, int(seat["wage"])]
	audio.play("levelup")
	_show_feedback("✦ %s contratada." % str(seat["name"]), Color(1.0, 0.78, 0.62))
	_check_achievements()
	_save_game()
	_refresh_ui()

## ── Pedidos de facção ──────────────────────────────────────────────────────────

## Os números que um pedido lê. Tudo aqui é coisa que a loja já faz por outro
## motivo: o arco cobra caminho percorrido, não tarefa nova de sentar e clicar.
func _faction_arc_stats(faction_id: String) -> Dictionary:
	return {
		"pecas": total_crafted,
		"primas": premium_crafted,
		"encomendas": commissions_finished,
		"expedicoes": expeditions_done,
		"raridades": rare_found,
		"eventos": rare_events_found,
		"fama": reputation,
		"caixa": gold,
		"compras": total_ingredients_bought,
		"casa": house_rank,
		"quites": 1 if debt == 0 and debt_peak >= 120 else 0,
		"filial_corte": 1 if branches.has("corte") else 0,
		"clientes": int(faction_customers.get(faction_id, 0)),
	}

## O caderno da facção: quantos dos três pedidos ela já viu serem entregues.
func _faction_arc_progress(faction_id: String) -> int:
	return int(faction_arc_step.get(faction_id, 0))

## Arco fechado quer dizer privilégio permanente na conta da loja — é por isso que
## as fórmulas de custo, etiqueta, sorte e filial perguntam isto antes de rolar.
func _faction_arc_closed(faction_id: String) -> bool:
	return FactionArcs.closed(faction_id, _faction_arc_progress(faction_id))

func _faction_arcs_closed() -> int:
	var sum := 0
	for faction in Factions.DATA:
		if _faction_arc_closed(str(faction["id"])):
			sum += 1
	return sum

## Quantos pedidos o caderno já registrou, somando as cinco facções. Serve de
## régua para a primeira conquista e para o resumo do painel.
func _faction_asks_delivered() -> int:
	var sum := 0
	for faction in Factions.DATA:
		sum += _faction_arc_progress(str(faction["id"]))
	return sum

func _faction_perks_text() -> String:
	var names: Array[String] = []
	for faction in Factions.DATA:
		var faction_id := str(faction["id"])
		if _faction_arc_closed(faction_id):
			names.append(str(FactionArcs.perk(faction_id).get("name", "")))
	if names.is_empty():
		return ""
	return "Privilégios da casa: %s." % ", ".join(names)

## Entregar um pedido é a única forma de fechar um capítulo de facção: o botão só
## libera quando a fama, o capítulo da campanha e o número cobrado batem juntos.
func _deliver_faction_arc(faction_id: String) -> void:
	var progress := _faction_arc_progress(faction_id)
	var ask_step := FactionArcs.step(faction_id, progress)
	if ask_step.is_empty():
		return
	var faction := Factions.find(faction_id)
	var standing_antes := int(faction_standing.get(faction_id, 0))
	var why := FactionArcs.reason(_faction_arc_stats(faction_id), ask_step, standing_antes, campaign_step)
	if why != "":
		last_event = "Ainda não: %s quer %s antes de assinar. Falta %s." % [
			str(faction.get("name", faction_id)), str(ask_step["title"]), why]
		_refresh_ui()
		return
	var reward: Dictionary = ask_step["reward"]
	gold += int(reward["gold"])
	reputation += int(reward["rep"])
	faction_arc_step[faction_id] = progress + 1
	faction_standing[faction_id] = standing_antes + int(reward["standing"])
	_add_xp(int(reward["xp"]))
	last_event = "PEDIDO DE %s ENTREGADO (%d/%d): %s %s" % [
		str(faction.get("name", faction_id)).to_upper(), progress + 1, FactionArcs.size(faction_id),
		str(ask_step["done"]), str(ask_step["voice"])]
	if Factions.tier_for(int(faction_standing[faction_id])) > Factions.tier_for(standing_antes):
		last_event += "\nA loja subiu de patamar na facção: %s." % Factions.TIER_NAMES[
			Factions.tier_for(int(faction_standing[faction_id]))]
	if is_instance_valid(seller_speech_label):
		seller_speech_label.text = "CHEFE: %s" % str(ask_step["voice"])
	if not demonic_form_active:
		_set_seller_mood("happy")
	audio.play("levelup")
	_show_feedback("✦ %s" % str(ask_step["title"]), Color(1.0, 0.86, 0.45))
	# O terceiro pedido não paga só ouro: paga o nome na parede, para sempre, e um
	# pacote de cartas para a coleção acompanhar a história.
	if _faction_arc_closed(faction_id):
		var perk := FactionArcs.perk(faction_id)
		last_event += "\nPRIVILÉGIO PERMANENTE — %s: %s" % [
			str(perk.get("name", "")), str(perk.get("desc", ""))]
		_grant_pack(true)
	_check_achievements()
	_save_game()
	_refresh_ui()

## A dívida estourou: a vida fecha no vermelho. O painel não oferece saída além de
## reabrir as portas, porque ruína que se dispensa com um clique não é consequência.
func _claim_ruin() -> void:
	ruined_lives += 1
	var ending := Endings.ruin()
	var ending_id := str(ending["id"])
	if not endings_seen.has(ending_id):
		endings_seen.append(ending_id)
	audio.play("sad")
	_show_ending(ending, true)
	_save_game()
	_refresh_ui()

## Reabrir é reencarnar sem prêmio: a temporada vai para o placar marcada como
## perdida e a vida seguinte começa com a banca na calçada e aura nenhuma.
func _reopen_after_ruin() -> void:
	var score := business_score()
	var temporada := Prestige.season(prestige_runs)
	_bank_season()
	if not ruined_seasons.has(str(temporada)):
		ruined_seasons.append(str(temporada))
	prestige_runs += 1
	_reset_run()
	last_event = "REABERTURA: a casa tomou o salão, a chefe botou a banca de volta na calçada e recomeçou do zero. A temporada %d fechou no vermelho com %d pontos e não trouxe aura nenhuma." % [
		temporada, score]
	audio.play("levelup")
	_show_feedback("✦ Portas reabertas.", Color(1.0, 0.62, 0.55))
	_check_achievements()
	_save_game()
	_refresh_ui()

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
		_start_epilogue()
		# A cena do andar de cima vem antes dos créditos: o final da campanha é a
		# resposta para a pergunta que as lembranças vinham fazendo.
		_reveal_origin(Origin.chapter_scene(campaign_step - 1), _show_ending)
	else:
		_reveal_origin(Origin.chapter_scene(campaign_step - 1))
	_check_achievements()
	_save_game()
	_refresh_ui()

func _show_ending(ending: Dictionary = {}, ruined := false) -> void:
	if ending.is_empty():
		ending = _claim_ending()
	if is_instance_valid(ending_layer):
		if bool(ending_layer.get_meta("ruined", false)) == ruined:
			ending_layer.visible = true
			return
		# Fechar o painel só esconde a tela, e o modo livre deixa o dia continuar
		# rolando: quem fecha o capítulo sete e depois toma o calote do coletor tem
		# de ver o painel do calote, não o do capítulo com o botão trocado.
		ending_layer.queue_free()
		ending_layer = null
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.04, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_meta("ruined", ruined)
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
	title.text = str(ending["title"]).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.45))
	box.add_child(title)

	var who_label := Label.new()
	who_label.text = "Fim de vida no vermelho" if ruined else ("Final de %s" % str(Factions.find(str(ending["faction"])).get("name", "casa inteira")) \
		if str(ending["faction"]) != "" else "Final da própria casa")
	who_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who_label.add_theme_font_size_override("font_size", 15)
	who_label.add_theme_color_override("font_color", Color(1.0, 0.74, 0.86))
	box.add_child(who_label)

	var body_text := Label.new()
	# A ruína não tem corrida de facção para mostrar: o que afundou a vida foi a
	# conta da casa, e é a conta que o painel lê em voz alta.
	var ledger := "Nesta vida, quem mais usou o balcão: %s\n\n" % _life_standing_text()
	var closing := "O balcão continua aberto: dá para fechar o álbum, subir no placar e esticar o império até onde a sorte deixar."
	if ruined:
		ledger = "A vida afundou no dia em que a casa cobrava %d e a dívida passou de %d. O fundo do poço desta vida foi %d.%s%s\n\n" % [
			_daily_upkeep(), _debt_limit(), debt_peak,
			(" E a loja ainda mantinha %d filial(is) aberta(s), custando %d por virada." % [
				branches.size(), Branches.total_upkeep(branches)]) if not branches.is_empty() else "",
			(" O balcão tinha %d funcionário(s) na folha, %d por virada." % [
				staff_hired.size(), Staff.total_wage(staff_hired)]) if not staff_hired.is_empty() else ""]
		closing = "O balcão reabre no mesmo lugar, com a freguesia lembrando da loja e o cofre vazio: quem fecha no vermelho recomeça sem aura nenhuma."
	body_text.text = Endings.text(ending) + "\n\n" \
		+ "Dia %d • %d de ouro em caixa • reputação %d • nível %d\n" % [shop_day, gold, reputation, player_level] \
		+ "%d clientes atendidos • %d peças fabricadas • %d expedições\n" % [customers_served, total_crafted, expeditions_done] \
		+ "%d de %d cards no álbum • pontuação %d\n\n" % [Cards.owned_count(card_counts), Cards.size(), business_score()] \
		+ ledger \
		+ closing \
		+ "\n\nHá %d finais diferentes neste balcão, e a loja já viu %d deles." % [Endings.size(), endings_seen.size()]
	body_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_text.add_theme_font_size_override("font_size", 16)
	body_text.add_theme_color_override("font_color", Color(0.92, 0.88, 0.96))
	# A prosa do final é longa e o quadro não pode empurrar o botão para fora da
	# tela: o corpo rola dentro do próprio painel.
	var body_scroll := ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(560, 250)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(body_scroll)
	body_scroll.add_child(body_text)

	# A despedida do elenco pertence ao capítulo sete. Quem quebra no meio da vida
	# não leva freguês ao balcão: leva o coletor.
	if not ruined:
		var farewell_title := Label.new()
		farewell_title.text = "A DESPEDIDA DO BALCÃO"
		farewell_title.add_theme_font_size_override("font_size", 18)
		farewell_title.add_theme_color_override("font_color", Color(1.0, 0.74, 0.86))
		box.add_child(farewell_title)

		# A lista cresce com o elenco atendido e o painel não pode estourar a tela: o
		# rolamento fica dentro do próprio quadro do final.
		var farewell_scroll := ScrollContainer.new()
		farewell_scroll.custom_minimum_size = Vector2(560, 140)
		farewell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(farewell_scroll)
		var farewell_text := Label.new()
		farewell_text.text = _epilogue_text()
		farewell_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		farewell_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		farewell_text.add_theme_font_size_override("font_size", 14)
		farewell_text.add_theme_color_override("font_color", Color(0.9, 0.84, 0.94))
		farewell_scroll.add_child(farewell_text)

		var farewell_note := Label.new()
		farewell_note.text = "Eles ainda passam um por vez no salão para acenar. Pode fechar esta tela e ficar olhando."
		farewell_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		farewell_note.add_theme_font_size_override("font_size", 13)
		farewell_note.add_theme_color_override("font_color", Color(0.72, 0.66, 0.8))
		box.add_child(farewell_note)

	# O final é a vitrine do prestígio: é aqui que a loja diz quanto a vida seguinte
	# paga. A ruína é o momento em que ela diz que não paga nada.
	var prestige_note := Label.new()
	prestige_note.text = "Esta vida não deixou aura: reabrir as portas recomeça do zero com o que a loja aprendeu, e o que ela aprendeu não enche caixa." if ruined \
		else "Esta vida vale %d de aura na reencarnação. A recepção mostra o que fica e o que volta a zero." % Prestige.aura_for(business_score())
	prestige_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prestige_note.add_theme_font_size_override("font_size", 13)
	prestige_note.add_theme_color_override("font_color", Color(1.0, 0.62, 0.55) if ruined else Color(0.85, 0.7, 1.0))
	box.add_child(prestige_note)

	var close_button := Button.new()
	close_button.text = "Reabrir as portas" if ruined else "Voltar a administrar"
	close_button.custom_minimum_size = Vector2(240, 46)
	close_button.pressed.connect(_reopen_after_ruin if ruined else _close_ending)
	box.add_child(close_button)

func _close_ending() -> void:
	if is_instance_valid(ending_layer):
		ending_layer.visible = false
	audio.play("click")

## O prêmio de uma lembrança é fixo: quem descobre de onde vem a loja cobra em caixa,
## mas não é a cena que paga o aluguel — é o capítulo que a liberou.
const ORIGIN_REWARD := {"gold": 45, "rep": 2, "xp": 35}

## Abre a cena, paga uma única vez e emenda no que vier depois (o painel do final,
## por exemplo). Cena já vista não abre de novo sozinha: só pelo botão de relembrar.
func _reveal_origin(scene: Dictionary, after: Callable = Callable()) -> void:
	if scene.is_empty() or origin_seen.has(str(scene["id"])):
		if after.is_valid():
			after.call()
		return
	origin_seen.append(str(scene["id"]))
	gold += int(ORIGIN_REWARD["gold"])
	daily_gold_earned += int(ORIGIN_REWARD["gold"])
	reputation += int(ORIGIN_REWARD["rep"])
	_add_xp(int(ORIGIN_REWARD["xp"]))
	_show_origin(scene)
	_origin_next = after
	_check_achievements()
	_save_game()

## O quadro da lembrança: texto parado na tela, sem balcão, sem tique, sem venda. É
## o único momento da loja em que a leitura manda no relógio.
func _show_origin(scene: Dictionary) -> void:
	if scene.is_empty():
		return
	if is_instance_valid(origin_layer):
		origin_layer.queue_free()
	origin_layer = null
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.05, 0.93)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	origin_layer = dim

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.03, 0.11, 0.99)
	panel_style.border_color = Color(0.85, 0.62, 1.0, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 22
	panel_style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(600, 0)
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var who := Label.new()
	who.text = "LEMBRANÇA • %s" % Origin.who_label(scene)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.add_theme_font_size_override("font_size", 14)
	who.add_theme_color_override("font_color", Color(0.78, 0.62, 0.92))
	box.add_child(who)

	var title := Label.new()
	title.text = str(scene["title"])
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.83, 0.45))
	box.add_child(title)

	var body := Label.new()
	body.text = "\n\n".join(PackedStringArray(scene["lines"]))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color(0.93, 0.89, 0.96))
	box.add_child(body)

	var cost := Label.new()
	cost.text = "Anotado no livro-razão: +%d ouro, +%d fama, +%d XP." % [
		int(ORIGIN_REWARD["gold"]), int(ORIGIN_REWARD["rep"]), int(ORIGIN_REWARD["xp"])
	]
	cost.add_theme_font_size_override("font_size", 13)
	cost.add_theme_color_override("font_color", Color(0.72, 0.66, 0.8))
	box.add_child(cost)

	var close_button := Button.new()
	close_button.text = "Voltar ao balcão"
	close_button.custom_minimum_size = Vector2(240, 46)
	close_button.pressed.connect(_close_origin)
	box.add_child(close_button)
	world_timer.stop()
	audio.play("rare")
	_refresh_ui()

## Fechar a lembrança devolve o relógio à loja e emenda o que a cena estava
## segurando — o painel do final, no último capítulo.
func _close_origin() -> void:
	if is_instance_valid(origin_layer):
		origin_layer.queue_free()
	origin_layer = null
	# Duas janelas na mesma manhã: o balanço do dia e a lembrança seguram o relógio,
	# e quem fecha uma não tem o direito de reabrir a loja por cima da outra.
	if not is_instance_valid(day_layer) and not is_instance_valid(ending_layer):
		world_timer.start()
	audio.play("click")
	# O botão de relembrar abre o quadro sem prêmio: a cena já foi paga no dia em
	# que a loja a descobriu.
	_refresh_ui()
	if _origin_next.is_valid():
		var next := _origin_next
		_origin_next = Callable()
		next.call()

## Marca a régua do dia: tudo que o balanço da virada vai subtrair.
func _mark_day_start() -> void:
	day_snap_gold = gold
	day_snap_served = customers_served
	day_snap_happy = happy_customers
	day_snap_lost = disappointed_customers

## A conta da virada em números. Fecha também a fila do dia, porque o mesmo
## balanço que mostra quem saiu é o que zera o contador da próxima manhã.
func _close_day_balance() -> Dictionary:
	var balance := {
		"gold": gold - day_snap_gold,
		"served": customers_served - day_snap_served,
		"happy": happy_customers - day_snap_happy,
		"lost": disappointed_customers - day_snap_lost,
		"walkouts": day_walkouts,
	}
	_mark_day_start()
	day_walkouts = 0
	return balance

## O popup do balanço: a rua para, e a chefe vê o dia em números antes de dormir.
## A linha do mural se apaga na virada seguinte; o caixa, não.
func _show_day_report(balance: Dictionary) -> void:
	if is_instance_valid(day_layer):
		day_layer.queue_free()
	day_layer = null
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.05, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	day_layer = dim

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.03, 0.11, 0.99)
	panel_style.border_color = Color(0.85, 0.62, 1.0, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 28
	panel_style.content_margin_right = 28
	panel_style.content_margin_top = 22
	panel_style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(520, 0)
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var who := Label.new()
	who.text = "BALANÇO • DIA %d" % (shop_day - 1)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.add_theme_font_size_override("font_size", 14)
	who.add_theme_color_override("font_color", Color(0.78, 0.62, 0.92))
	box.add_child(who)

	var net := int(balance["gold"])
	var title := Label.new()
	title.text = "%+d de ouro no caixa" % net
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.62, 1.0, 0.72) if net >= 0 else Color(1.0, 0.55, 0.55))
	box.add_child(title)

	var counts := Label.new()
	counts.text = "Atendidos: %d  •  Saíram felizes: %d  •  Saíram sem comprar: %d (destes, %d da fila)" % [
		int(balance["served"]), int(balance["happy"]), int(balance["lost"]), int(balance["walkouts"])]
	counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counts.add_theme_font_size_override("font_size", 15)
	counts.add_theme_color_override("font_color", Color(0.93, 0.89, 0.96))
	box.add_child(counts)

	var prose := Label.new()
	prose.text = day_report
	prose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prose.add_theme_font_size_override("font_size", 13)
	prose.add_theme_color_override("font_color", Color(0.72, 0.66, 0.8))
	box.add_child(prose)

	var auto := CheckBox.new()
	auto.text = "Fechar o balanço sozinho em 5 segundos"
	auto.button_pressed = day_auto_ok
	auto.add_theme_font_size_override("font_size", 13)
	auto.toggled.connect(_on_day_auto_ok_toggled)
	box.add_child(auto)

	_day_countdown_label = Label.new()
	_day_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_day_countdown_label.add_theme_font_size_override("font_size", 12)
	_day_countdown_label.add_theme_color_override("font_color", Color(0.62, 0.56, 0.74))
	box.add_child(_day_countdown_label)

	var close_button := Button.new()
	close_button.text = "Fechar o dia"
	close_button.custom_minimum_size = Vector2(240, 46)
	close_button.pressed.connect(_close_day_report)
	box.add_child(close_button)

	world_timer.stop()
	audio.play("coin" if net >= 0 else "sad", true)
	_refresh_ui()
	if day_auto_ok:
		_start_day_countdown()

func _start_day_countdown() -> void:
	if _day_countdown != null and _day_countdown.is_valid():
		_day_countdown.kill()
	_day_countdown = create_tween()
	_day_countdown.tween_method(_tick_day_countdown, 5.0, 0.0, 5.0)
	_day_countdown.tween_callback(_close_day_report)

func _tick_day_countdown(left: float) -> void:
	if is_instance_valid(_day_countdown_label):
		_day_countdown_label.text = "A chefe já virou a página: fecha em %d…" % int(ceil(left))

func _on_day_auto_ok_toggled(pressed: bool) -> void:
	day_auto_ok = pressed
	_save_game()
	if _day_countdown != null and _day_countdown.is_valid():
		_day_countdown.kill()
		_day_countdown = null
	if is_instance_valid(_day_countdown_label):
		_day_countdown_label.text = ""
	if pressed:
		_start_day_countdown()

## Fechar o balanço devolve a rua ao relógio — mas só se não houver outra janela
## segurando a loja parada em cima dele.
func _close_day_report() -> void:
	if _day_countdown != null and _day_countdown.is_valid():
		_day_countdown.kill()
	_day_countdown = null
	if is_instance_valid(day_layer):
		day_layer.queue_free()
	day_layer = null
	_day_countdown_label = null
	if is_instance_valid(origin_layer) or is_instance_valid(ending_layer):
		return
	world_timer.start()
	audio.play("click", true)

## Painel das memórias: o que a loja já contou de si e o que ainda está trancado
## em capítulo.
func _origin_text() -> String:
	var lines: Array[String] = ["LEMBRANÇAS DO ANDAR DE CIMA"]
	if origin_seen.is_empty():
		lines.append("· feche um capítulo e a loja conta de onde veio")
		return "\n".join(lines)
	for scene in Origin.DATA:
		if origin_seen.has(str(scene["id"])):
			lines.append("✦ %s — %s" % [scene["title"], Origin.who_label(scene)])
	var left := Origin.size() - origin_seen.size()
	if left > 0:
		lines.append("· %d lembranças ainda trancadas em capítulo" % left)
	return "\n".join(lines)

## Reler é de graça: reabre a última cena descoberta sem pagar o prêmio outra vez.
func _reread_origin() -> void:
	if origin_seen.is_empty():
		return
	_show_origin(Origin.find(origin_seen[origin_seen.size() - 1]))

## Nível pago de um dote permanente, sempre dentro do teto da tabela.
func _perk_level(id: String) -> int:
	return clampi(int(prestige_perks.get(id, 0)), 0, int(Prestige.perk(id).get("max", 0)))

func _perk_levels_total() -> int:
	var total := 0
	for perk in Prestige.PERKS:
		total += _perk_level(str(perk["id"]))
	return total

## Pregão da casa: a etiqueta sai mais alta em toda venda, sem mexer no custo.
func _prestige_price_factor() -> float:
	return 1.0 + float(Prestige.effect("pregao", _perk_level("pregao"))) / 100.0

## Mão de baralho: a mesma aura empurra forja, estrada e pacote lacrado.
func _prestige_luck() -> int:
	return Prestige.effect("sorte", _perk_level("sorte"))

## Memória de balcão: a segunda vida aprende mais rápido que a primeira.
func _prestige_xp_factor() -> float:
	return 1.0 + float(Prestige.effect("memoria", _perk_level("memoria"))) / 100.0

func _prestige_start_gold() -> int:
	return BASE_GOLD + Prestige.effect("berco", _perk_level("berco"))

## O quadro da vida: quantas voltas a loja já deu, quanta aura está parada no
## cofre, o que cada dote entrega hoje e qual é a meta que paga a próxima aura.
func _prestige_text() -> String:
	var lines: Array[String] = []
	lines.append("Vida %d da loja • aura no cofre: %d" % [prestige_runs + 1, prestige_aura])
	var goal := Prestige.goal_for(prestige_goals_paid)
	lines.append("Meta %d: %d pontos de pontuação (+%d de aura) — a loja tem %d." % [
		prestige_goals_paid + 1, int(goal["score"]), int(goal["aura"]), business_score()
	])
	for perk in Prestige.PERKS:
		var level := _perk_level(str(perk["id"]))
		lines.append("· %s (nv %d/%d): %s" % [
			str(perk["name"]), level, int(perk["max"]),
			Prestige.effect_text(str(perk["id"]), level) if level > 0 else "ainda sem efeito"
		])
	if not game_completed:
		lines.append("· feche o último capítulo para poder reencarnar o balcão")
	return "\n".join(lines)

func _prestige_button_text() -> String:
	if not game_completed:
		return "Reencarnar o balcão (trancado: falta o império)"
	return "Reencarnar o balcão: esta vida vale +%d de aura" % Prestige.aura_for(business_score())

## O painel do prestígio desenhado. A meta é medida em pontuação, e pontuação muda
## a cada venda, por isso isto roda em todo refresco e não só no tique do mundo.
func _refresh_prestige() -> void:
	prestige_label.text = _prestige_text()
	var aura_open := game_completed or prestige_runs > 0 or prestige_aura > 0
	for i in range(Prestige.PERKS.size()):
		if i >= prestige_perk_buttons.size():
			break
		var perk: Dictionary = Prestige.PERKS[i]
		var level := _perk_level(str(perk["id"]))
		var cost := Prestige.level_cost(perk, level)
		var perk_button: Button = prestige_perk_buttons[i]
		perk_button.visible = aura_open
		if cost < 0:
			perk_button.text = "%s • nível %d (no teto)" % [str(perk["name"]), level]
		else:
			perk_button.text = "%s • nível %d→%d: %s — %d de aura" % [
				str(perk["name"]), level, level + 1,
				Prestige.effect_text(str(perk["id"]), level + 1), cost
			]
		perk_button.disabled = cost < 0 or prestige_aura < cost
	prestige_button.visible = aura_open
	prestige_button.text = _prestige_button_text()
	prestige_button.disabled = not game_completed

## A meta da escada é o que dá fôlego novo à vida seguinte: pontuação é medida
## contínua, então ela pode vir no meio de um capítulo, não só no fim.
func _check_prestige_goal() -> void:
	var goal := Prestige.goal_for(prestige_goals_paid)
	if business_score() < int(goal["score"]):
		return
	prestige_goals_paid += 1
	prestige_aura += int(goal["aura"])
	last_event += "\nMETA DE VIDA %d cumprida: %d pontos pagaram +%d de aura. A próxima pede %d." % [
		prestige_goals_paid, int(goal["score"]), int(goal["aura"]),
		int(Prestige.goal_for(prestige_goals_paid)["score"])
	]
	audio.play("coin")
	_show_feedback("✦ Meta de vida cumprida.", Color(0.85, 0.7, 1.0))

func _buy_perk(index: int) -> void:
	if index < 0 or index >= Prestige.PERKS.size():
		return
	var perk: Dictionary = Prestige.PERKS[index]
	var id := str(perk["id"])
	var level := _perk_level(id)
	var cost := Prestige.level_cost(perk, level)
	if cost < 0:
		return
	if prestige_aura < cost:
		last_event = "Aura não chega: %s nv %d custa %d e o cofre tem %d." % [
			str(perk["name"]), level + 1, cost, prestige_aura
		]
		audio.play("sad")
		_refresh_ui()
		return
	prestige_aura -= cost
	prestige_perks[id] = level + 1
	last_event = "DOTE PERMANENTE: %s nível %d. %s" % [
		str(perk["name"]), level + 1, str(perk["desc"])
	]
	audio.play("talent")
	_show_feedback("✦ Dote comprado.", Color(0.85, 0.7, 1.0))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Trocar a vida é o prestígio em si: o caixa, a prateleira e a campanha voltam ao
## zero, e o que a loja aprendeu — povo, álbum, lembranças, dotes e conquistas —
## atravessa com a chefe.
func _reincarnate() -> void:
	if not game_completed:
		return
	var score := business_score()
	var gain := Prestige.aura_for(score)
	var temporada := Prestige.season(prestige_runs)
	_bank_season()
	prestige_runs += 1
	prestige_aura += gain
	_reset_run()
	last_event = "REENCARNAÇÃO %d: a loja fechou uma vida de %d pontos e abriu a seguinte com %d de ouro no caixa. +%d de aura no cofre. A temporada %d ficou no placar com %d." % [
		prestige_runs, score, _prestige_start_gold(), gain, temporada, _season_best(temporada)
	]
	audio.play("levelup")
	_show_feedback("✦ Nova vida.", Color(0.85, 0.7, 1.0))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Só o que a vida construiu cai: a ficha das pessoas, o álbum, as lembranças, as
## conquistas, o prestígio e as opções continuam no lugar.
func _reset_run() -> void:
	gold = _prestige_start_gold()
	# A vida nova não herda o vermelho da anterior: a casa recomeça no nome dela.
	debt = 0
	debt_peak = 0
	# Filial é patrimônio da vida, não da família: reencarnar fecha as portas todas.
	branches.clear()
	_offline_branch_fraction = 0.0
	# O quadro também é da vida: a folha sai com a loja velha, e a vida nova contrata
	# quem quiser do zero.
	staff_hired.clear()
	theft_blocked = 0
	# A fila é da loja velha: reencarnar abre a porta vazia, e o corpo que esperava
	# sai de cena junto com o balcão anterior.
	for waiting in _stage_waiters.duplicate():
		_retire_walker(waiting["node"] as Control)
	_stage_waiters.clear()
	service_queue.clear()
	queue_walkouts = 0
	day_walkouts = 0
	day_report = ""
	reputation = 0
	customers_served = 0
	happy_customers = 0
	disappointed_customers = 0
	seduction_attempts = 0
	seduction_successes = 0
	affection = 0
	fury = 0
	demonic_form_active = false
	private_moments_unlocked = 0
	ad_level = 0
	imp_hired = false
	ticks = 0
	shop_day = 1
	rare_events_found = 0
	queue_distractions = 0
	player_level = 1
	player_xp = 0
	skill_points = 0
	alchemy_rank = 0
	trade_rank = 0
	charm_rank = 0
	logistics_rank = 0
	house_rank = 0
	# Ofício é da vida: a vida nova é justamente a chance de montar a build que
	# ficou de fora, então a tinta velha some toda.
	spec_choice.clear()
	known_recipes.clear()
	daily_quest_index = 0
	daily_quest_progress = 0
	daily_quest_claimed = false
	daily_gold_earned = 0
	daily_crafts = 0
	commission_index = -1
	commission_stage = 0
	commission_progress = 0
	commission_deadline = 0
	commission_next_offer = 3
	craft_jobs.clear()
	library_upgrade_level = 0
	sanctum_upgrade_level = 0
	active_buffs.clear()
	ingredient_stock = STARTING_PANTRY.duplicate()
	total_ingredients_bought = 0
	total_crafted = 0
	premium_crafted = 0
	best_quality_crafted = -1
	legendary_crafted = 0
	legendary_sold = 0
	exclusive_finished = 0
	rituals_performed = 0
	expeditions.clear()
	expedition_log.clear()
	expeditions_done = 0
	rare_found = 0
	catalyst_crafted = 0
	catalyst_enabled = false
	economy_state = Economy.fresh_state()
	quality_stock.clear()
	for item in products:
		var held := int(_starting_shelf.get(str(item["id"]), 0))
		item["stock"] = held
		if held > 0:
			var counts := Quality.empty_stock()
			counts[1] = held
			quality_stock[str(item["id"])] = counts
	campaign_step = 0
	game_completed = false
	epilogue_pending.clear()
	epilogue_done = false
	romance_pending = ""
	current_regular_id = ""
	current_customer_budget = 0
	current_customer_patience = 0
	if is_instance_valid(ending_layer):
		ending_layer.queue_free()
		ending_layer = null
	# A fama das facções atravessa a vida, mas o placar dela recomeça do zero: o
	# ponteiro de agora é o chão contra o qual o próximo capítulo sete é medido.
	season_baseline = faction_standing.duplicate(true)
	# Quem encheu o balcão na vida anterior não está na fila desta: a contagem de
	# clientes por facção é da temporada, o pedido já entregue no caderno não é.
	faction_customers.clear()
	# A régua do balanço nasce no fim, depois de todo mundo ter zerado: marcada no
	# meio da limpeza, o primeiro popup da vida nova contaria o caixa inteiro como
	# se fosse lucro de um dia só.
	_mark_day_start()

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

## Degrau já pago por este freguês; zero quando ele ainda é só um rosto no balcão.
func _romance_stage_of(regular_id: String) -> int:
	return clampi(int(romance_stage.get(regular_id, 0)), 0, ROMANCE_STEPS.size())

## Quanto o apaixonado paga a mais, para sempre.
func _romance_price_factor(regular_id: String) -> float:
	var stage := _romance_stage_of(regular_id)
	return (1.0 + float(ROMANCE_STEPS[stage - 1]["price"])) if stage > 0 else 1.0

## Visita de quem já tem história vale mais vínculo que visita comum.
func _romance_bond_bonus(regular_id: String) -> int:
	var stage := _romance_stage_of(regular_id)
	return int(ROMANCE_STEPS[stage - 1]["bond_bonus"]) if stage > 0 else 0

## Só o degrau final deixa gorjeta no balcão, e ela cresce com a loja.
func _romance_tip(regular_id: String) -> int:
	var stage := _romance_stage_of(regular_id)
	if stage < ROMANCE_STEPS.size():
		return 0
	return int(ROMANCE_STEPS[stage - 1]["tip"]) + player_level

## A oferta acende sozinha quando a visita rendeu vínculo suficiente: o convite
## espera no painel até a virada do dia. Quem chegou primeiro fica no lugar — a
## promessa de um freguês não é trocada no meio pela de outro.
func _offer_romance(regular_id: String, bond: int) -> void:
	if not romance_pending.is_empty() and romance_pending != regular_id:
		return
	var step := _romance_stage_of(regular_id)
	if step < ROMANCE_STEPS.size() and bond >= int(ROMANCE_STEPS[step]["bond"]):
		romance_pending = regular_id

func _romance_steps_paid() -> int:
	var total := 0
	for regular_id in romance_stage.keys():
		total += _romance_stage_of(str(regular_id))
	return total

func _romance_at_least(step: int) -> int:
	var total := 0
	for regular_id in romance_stage.keys():
		if _romance_stage_of(str(regular_id)) >= step:
			total += 1
	return total

## Painel da escada: quem subiu degrau e quanto isso muda a conta dele.
func _romance_text() -> String:
	var lines: Array[String] = ["CORAÇÃO DO BALCÃO"]
	var any := false
	for regular in Regulars.DATA:
		var stage := _romance_stage_of(str(regular["id"]))
		if stage <= 0:
			continue
		any = true
		lines.append("♥ %s — %s (+%d%% na conta)%s" % [
			regular["short"], ROMANCE_STEPS[stage - 1]["name"],
			int(round(float(ROMANCE_STEPS[stage - 1]["price"]) * 100.0)),
			" • gorjeta a cada compra" if stage >= ROMANCE_STEPS.size() else ""
		])
	if any:
		return "\n".join(lines)
	lines.append("· nenhum freguês caiu de amores ainda")
	lines.append("· atenda bem, chegue a 5 visitas e o convite acende aqui")
	return "\n".join(lines)

## Ato atual da ficha de um freguês. Nada aqui é contador novo: os quatro atos são
## lidos de progresso que a loja já mede — a primeira visita, o nível Conhecido, o
## capítulo pessoal fechado e o convite pago.
func _arc_act(regular_id: String) -> int:
	var bond := int(regular_bonds.get(regular_id, 0))
	if bond <= 0:
		return 0
	if _romance_stage_of(regular_id) >= 1:
		return 4
	if regular_story_completed.has(regular_id):
		return 3
	if bond >= Regulars.THRESHOLDS[1]:
		return 2
	return 1

## A linha inteira do ato, como está escrita na ficha do freguês.
func _arc_line(regular_id: String, act: int) -> String:
	var arcs: Array = Regulars.find(regular_id).get("arc", [])
	return str(arcs[act - 1]) if act >= 1 and arcs.size() >= act else ""

## Só o título do ato, sem o "ATO IV —" de cabeçalho e sem o corpo: o número já vai
## na manchete, e o texto inteiro está na ficha do painel.
func _arc_head(line: String) -> String:
	var cut := line.find(":")
	var title := line.substr(0, cut).strip_edges() if cut > 0 else line
	var dash := title.find("— ")
	return title.substr(dash + 2).strip_edges() if dash >= 0 else title

## O que falta para o ato seguinte, dito na ficha para o jogador não adivinhar.
func _arc_next_hint(regular_id: String) -> String:
	var short_name := str(Regulars.find(regular_id).get("short", "O freguês"))
	match _arc_act(regular_id):
		0:
			return "Próximo ato: atenda %s uma vez." % short_name
		1:
			return "Próximo ato: %d visitas para o Ato II." % Regulars.THRESHOLDS[1]
		2:
			return "Próximo ato: 3 compras do item favorito dele para o Ato III."
		3:
			return "Próximo ato: pague o Convite para o Ato IV."
	return "Ficha completa: não há ato novo a descobrir."

## Anuncia cada ato que o freguês acabou de alcançar e paga a ficha por ele. Uma
## vez só por ato: o save guarda o teto já anunciado de cada um.
func _check_regular_acts(regular_id: String) -> void:
	var act := _arc_act(regular_id)
	var seen := int(regular_arc_seen.get(regular_id, 0))
	if act <= seen:
		return
	regular_arc_seen[regular_id] = act
	var regular: Dictionary = Regulars.find(regular_id)
	for i in range(seen + 1, act + 1):
		var reward: Dictionary = ARC_REWARDS[i - 1]
		var purse := int(reward["gold"]) + player_level * 4
		gold += purse
		daily_gold_earned += purse
		reputation += int(reward["rep"])
		_add_xp(int(reward["xp"]))
		var arc_msg := "FICHA DE %s • ato %d: %s (+%d ouro, +%d XP, +%d fama)" % [
			regular.get("short", "Freguês"), i, _arc_head(_arc_line(regular_id, i)),
			purse, int(reward["xp"]), int(reward["rep"])
		]
		# A ficha nunca troca a manchete da venda: o ato chega como rodapé da
		# mesma visita, junto do nível de amizade e do capítulo que subiram.
		last_event = last_event + "\n" + arc_msg
	_check_achievements()

func _arc_at_least(act: int) -> int:
	var total := 0
	for regular in Regulars.DATA:
		if _arc_act(str(regular["id"])) >= act:
			total += 1
	return total

func _arc_acts_announced() -> int:
	var total := 0
	for regular_id in regular_arc_seen.keys():
		total += clampi(int(regular_arc_seen[regular_id]), 0, ARC_REWARDS.size())
	return total

## A ficha do freguês que está no balcão agora: quem ele é, o ato em que a loja o
## deixou e quanto falta para o próximo. Sem ninguém conhecido na cena, a ficha
## explica como se abre a primeira.
func _arc_text() -> String:
	var regular: Dictionary = Regulars.find(current_regular_id)
	if regular.is_empty() or int(regular_bonds.get(current_regular_id, 0)) <= 0:
		return "\n".join([
			"FICHA DO FREGUÊS",
			"· ninguém conhecido no balcão",
			"· atenda o mesmo rosto e a ficha dele abre aqui",
		])
	var regular_id := str(regular["id"])
	var act := _arc_act(regular_id)
	var lines: Array[String] = ["FICHA DE %s • Ato %d" % [regular["short"], act]]
	lines.append(str(regular.get("background", "")))
	var line := _arc_line(regular_id, act)
	if not line.is_empty():
		lines.append(line)
	lines.append(_arc_next_hint(regular_id))
	return "\n".join(lines)

## Ordena a despedida por vínculo: quem pouco apareceu sai primeiro e o mais fiel é
## o último corpo a atravessar a porta.
func _compare_bond(a: Dictionary, b: Dictionary) -> bool:
	return int(a["bond"]) < int(b["bond"])

## Monta a fila da despedida com quem realmente pisou na loja. Quem nunca veio não
## tem despedida: o epílogo registra o vazio em vez de fingir um elenco.
func _start_epilogue() -> void:
	epilogue_pending.clear()
	epilogue_done = false
	var met: Array = []
	for regular in Regulars.DATA:
		var regular_id := str(regular["id"])
		var bond := int(regular_bonds.get(regular_id, 0))
		if bond > 0:
			met.append({"id": regular_id, "bond": bond})
	met.sort_custom(_compare_bond)
	for entry in met:
		epilogue_pending.append(str(entry["id"]))

## A frase de despedida é a do ato em que o freguês ficou, então a cena final depende
## de tudo que a loja construiu com ele e não de um texto genérico.
func _farewell_line(regular_id: String) -> String:
	var regular: Dictionary = Regulars.find(regular_id)
	var lines: Array = regular.get("farewell", [])
	if lines.is_empty():
		return "“%s passou, acenou da porta e não deixou nome.”" % regular.get("short", "O freguês")
	var act := clampi(_arc_act(regular_id), 1, lines.size())
	return str(lines[act - 1])

## O texto corrido do epílogo, para o painel do final e para a fila da cena.
func _epilogue_text() -> String:
	var lines: Array[String] = []
	var met := 0
	for regular in Regulars.DATA:
		var regular_id := str(regular["id"])
		if int(regular_bonds.get(regular_id, 0)) <= 0:
			continue
		met += 1
		lines.append("♥ %s (Ato %d) — %s" % [regular["short"], _arc_act(regular_id), _farewell_line(regular_id)])
	if met == 0:
		lines.append("· ninguém ficou. A chefe fecha a loja com o balcão vazio e o nome de nenhum freguês na ponta da língua.")
	var missing := Regulars.DATA.size() - met
	if missing > 0:
		lines.append("· %d rostos nunca passaram por aqui, e a despedida deles fica escrita só no caderno de estoque." % missing)
	return "\n".join(lines)

## A despedida não tem preço nem venda: o freguês entra pelo canto de sempre, olha o
## salão uma última vez, acena para a chefe e sai pela porta com a frase do ato dele.
func _stage_farewell_visit(regular_id: String) -> void:
	var regular: Dictionary = Regulars.find(regular_id)
	if regular.is_empty():
		return
	var bye := _farewell_line(regular_id)
	current_regular_id = regular_id
	_animate_customer_arrival({
		"name": regular["name"],
		"portrait": int(regular.get("portrait", 0)),
		"faction": str(regular.get("faction", "aventureiros")),
		"line": bye,
	})
	# Contar como atendido é o que faz o corpo dar a volta pelo salão antes de ir,
	# em vez de atravessar a tela reto como quem fugiu sem pagar.
	_customer_served = true
	_set_customer_status("CLIENTE: %s" % regular["short"])
	_set_seller_mood("happy")
	if is_instance_valid(seller_speech_label):
		seller_speech_label.text = "CHEFE: até logo, %s.\n%s: %s" % [regular["short"], regular["short"], bye]
	if is_instance_valid(customer_emotion_label):
		customer_emotion_label.text = " despedida"
	last_event = "EPILOGO • %s: %s" % [regular["short"], bye]
	audio.play("click")

## O par precisa estar em cena para a tela registrar os dois. Se quem já está no
## salão é o convidado, a cena começa já; senão ele volta pela porta, e a cena
## espera o tempo da caminhada dele antes de pôr os dois lado a lado.
func _summon_romance_partner(regular_id: String, portrait_index: int) -> float:
	if is_instance_valid(stage_customer) and stage_customer.visible and current_regular_id == regular_id:
		return clampf(float(stage_customer.get_meta("arrive_left", 0.0)), 0.0, STAGE_ARRIVE_SECONDS)
	if is_instance_valid(stage_customer) and stage_customer.visible:
		_stage_customer_leaves()
	current_regular_id = regular_id
	_stage_customer_arrives(portrait_index)
	return clampf(float(stage_customer.get_meta("arrive_left", 0.0)), 0.0, STAGE_ARRIVE_SECONDS)

## A chefe contorna o balcão e vai até o freguês: o par aparece junto no mesmo
## salão, sem moldura e sem cenário novo.
func _seller_joins_customer() -> void:
	if not is_instance_valid(stage_seller) or not is_instance_valid(stage_layer):
		return
	if _seller_lean_tween != null and _seller_lean_tween.is_valid():
		_seller_lean_tween.kill()
	var partner := _room_meet().y * stage_layer.size.x
	var gap := stage_seller.size.x * 0.30
	# Ela para de lado dele, do lado de casa, sem passar por cima do corpo.
	var side := partner + gap if partner < _seller_home.x else partner - gap
	_seller_lean_tween = create_tween()
	_seller_lean_tween.tween_property(stage_seller, "position", Vector2(side, _seller_home.y), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_seller_lean_tween.parallel().tween_property(stage_seller, "rotation_degrees", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	_seller_lean_tween.parallel().tween_property(stage_seller, "scale", Vector2(1.05, 1.05), 0.5).set_trans(Tween.TRANS_SINE)
	_seller_lean_tween.tween_interval(2.2)
	_seller_lean_tween.tween_property(stage_seller, "position", _seller_home, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_seller_lean_tween.parallel().tween_property(stage_seller, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)

## Sobe um degrau da escada do freguês convidado: cobra o vínculo e o ouro, põe o
## par lado a lado no salão e trava o bônus econômico permanente dele.
func _advance_romance_step() -> void:
	var invited: Dictionary = Regulars.find(romance_pending)
	if romance_pending.is_empty() or invited.is_empty():
		last_event = "Ninguém saiu do balcão a fim de um convite. Venda bem primeiro, depois converse."
		_refresh_ui()
		return
	var step := _romance_stage_of(romance_pending)
	if step >= ROMANCE_STEPS.size():
		romance_pending = ""
		last_event = "%s já subiu a escada inteira com a chefe. Não há degrau novo para pagar." % invited.get("short", "O freguês")
		_refresh_ui()
		return
	var requirement: Dictionary = ROMANCE_STEPS[step]
	var bond := int(regular_bonds.get(romance_pending, 0))
	if bond < int(requirement["bond"]):
		last_event = "%s ainda não confia o bastante: %s pede %d visitas, e vocês têm %d." % [
			invited.get("short", "O freguês"), requirement["name"], requirement["bond"], bond
		]
		_refresh_ui()
		return
	var cost := int(requirement["gold"])
	if gold < cost:
		last_event = "%s custa %d ouro. A conta de um encontro não fica no fiado." % [requirement["name"], cost]
		_refresh_ui()
		return
	var regular_id := romance_pending
	gold -= cost
	romance_pending = ""
	romance_stage[regular_id] = step + 1
	_play_sensual_reception_moment()
	var wait := _summon_romance_partner(regular_id, int(invited["portrait"]))
	var pose := str(requirement["pose"])
	# A cena acontece quando ele para no balcão, não antes: por isso a chefe espera
	# o tempo da caminhada antes de contornar o balcão e os dois assumirem a pose.
	if _romance_cue != null and _romance_cue.is_valid():
		_romance_cue.kill()
	_romance_cue = create_tween()
	_romance_cue.tween_interval(wait)
	_romance_cue.tween_callback(_seller_joins_customer)
	_romance_cue.tween_callback(_show_stage_emotion.bind(stage_seller_body, pose))
	_romance_cue.tween_callback(_show_stage_emotion.bind(stage_customer, pose))
	reputation += int(requirement["rep"])
	_add_affection(4 + step * 2)
	_add_xp(int(requirement["xp"]))
	var reached_top := step + 1 >= ROMANCE_STEPS.size()
	if reached_top:
		private_moments_unlocked += 1
	last_event = "%s\n%s  A conta dele agora sai %d%% mais cara, para sempre." % [
		str(ROMANCE_SCENES[step]) % invited["short"], str(invited["romance"][step]),
		int(round(float(requirement["price"]) * 100.0))
	]
	_check_regular_acts(regular_id)
	audio.play("talent" if reached_top else "happy")
	_show_feedback("♥ %s • %s" % [requirement["name"], invited["short"]], Color(1.0, 0.62, 0.88))
	_check_achievements()
	_save_game()
	_refresh_ui()

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
	adult_content_confirmed = true
	if not adult_content_enabled:
		demonic_form_active = false
		_set_seller_mood("neutral")
	_set_sector(current_sector)
	last_event = "Cenas sensuais ativadas. As recompensas especiais estão disponíveis." if adult_content_enabled else "Cenas sensuais desativadas. A progressão e a economia continuam normalmente."
	_save_game()
	_refresh_ui()

func _show_save_dialog(exporting: bool) -> void:
	save_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
	save_file_dialog.current_dir = OS.get_user_data_dir()
	save_file_dialog.current_file = "succubus_shop_save.cfg" if exporting else ""
	save_file_dialog.popup_centered(Vector2i(760, 520))

func _on_save_file_selected(path: String) -> void:
	var config := ConfigFile.new()
	if save_file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		var load_error := config.load(SAVE_PATH)
		if load_error != OK:
			_show_save_feedback("Não foi possível abrir o save atual para exportar (erro %d)." % load_error)
			return
		var save_error := config.save(path)
		if save_error != OK:
			_show_save_feedback("Não foi possível exportar o save (erro %d)." % save_error)
			return
		_show_save_feedback("Save exportado com sucesso.")
		return

	var load_error := config.load(path)
	if load_error != OK:
		_show_save_feedback("Não foi possível importar esse arquivo de save (erro %d)." % load_error)
		return
	var saved_gold: Variant = config.get_value("game", "gold", null)
	if not config.has_section("game") or not config.has_section_key("game", "gold") or not (saved_gold is int or saved_gold is float):
		_show_save_feedback("Arquivo inválido: não encontrei um saldo de ouro válido.")
		return
	var current_path := ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := DirAccess.copy_absolute(current_path, current_path + ".backup")
		if backup_error != OK:
			_show_save_feedback("Não foi possível criar uma cópia de segurança antes da importação (erro %d)." % backup_error)
			return
	var save_error := config.save(SAVE_PATH)
	if save_error != OK:
		_show_save_feedback("Não foi possível gravar o save importado (erro %d)." % save_error)
		return
	get_tree().reload_current_scene()

func _show_save_feedback(message: String) -> void:
	last_event = message
	_show_feedback(message, Color(1.0, 0.82, 0.48))
	_refresh_ui()

func _show_bug_report_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Relatar um problema"
	dialog.dialog_text = "O relatório inclui nome opcional, versão, sistema operacional, FPS, uso estimado de memória e até 1.500 caracteres do log recente. Ao publicar, ele ficará visível publicamente no GitHub. Nada será enviado antes da sua confirmação no navegador."
	dialog.get_ok_button().text = "Revisar no GitHub"
	dialog.get_ok_button().disabled = true
	var report_fields := VBoxContainer.new()
	report_fields.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.text = "Nome no relatório (opcional):"
	report_fields.add_child(name_label)
	var player_name := LineEdit.new()
	player_name.placeholder_text = "Anônimo"
	player_name.max_length = 40
	report_fields.add_child(player_name)
	var consent := CheckBox.new()
	consent.text = "Entendo que o issue publicado será público."
	report_fields.add_child(consent)
	consent.toggled.connect(func(checked: bool) -> void:
		dialog.get_ok_button().disabled = not checked
	)
	dialog.add_child(report_fields)
	dialog.confirmed.connect(func() -> void:
		var open_error := OS.shell_open(Diagnostics.issue_url(player_name.text))
		if open_error != OK:
			_show_save_feedback("Não foi possível abrir o navegador para o relatório (erro %d)." % open_error)
		else:
			_show_feedback("Relatório aberto para revisão. O envio só acontece quando você publicar o issue no GitHub.", Color(0.75, 1.0, 0.82))
		dialog.queue_free()
	)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 300))

func _confirm_full_reset() -> void:
	hard_reset_dialog.popup_centered()

func _reset_all_progress() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		if remove_error != OK:
			_show_save_feedback("Não foi possível apagar o save local (erro %d)." % remove_error)
			return
	get_tree().reload_current_scene()
