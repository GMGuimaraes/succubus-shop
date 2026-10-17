extends Control

const SAVE_PATH := "user://succubus_shop_save.cfg"
const Regulars = preload("res://regulars.gd")
const Factions = preload("res://factions.gd")
const Ingredients = preload("res://ingredients.gd")
const Quality = preload("res://quality.gd")
const Economy = preload("res://economy.gd")
const Sanctum = preload("res://sanctum.gd")
const Expedition = preload("res://expedition.gd")
const Adventurers = preload("res://adventurers.gd")
const Invasions = preload("res://invasions.gd")
const Cards = preload("res://cards.gd")
const Campaign = preload("res://campaign.gd")
const Origin = preload("res://origin.gd")
const Prestige = preload("res://prestige.gd")
const Endings = preload("res://endings.gd")
const Branches = preload("res://branches.gd")
const Rivals = preload("res://rivals.gd")
const FactionArcs = preload("res://faction_arcs.gd")
const TalentSpecs = preload("res://talent_specs.gd")
const Staff = preload("res://staff.gd")
const Locales = preload("res://locales.gd")
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
## A regra da casa nesta vida: etiqueta, conta e rua escalam por ela. O que a
## reencarnação paga é a média dos dias efetivamente vividos em cada regra, então trocar
## de modo no meio do caminho dilui o bônus em vez de comprá-lo.
var difficulty: String = "calcada"
## Dias de balcão vividos sob cada regra nesta vida ({ id_do_modo: dias }).
var difficulty_days: Dictionary = {}
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
## Quem já teve a placa comprada. A lista é da vida: reencarnar devolve as rivais
## para a rua, porque a praça recomeça com as portas dela.
var rivals_absorbed: Array[String] = []
## Quem está no balcão nesta vida. Vaga é da vida como a filial: reencarnar devolve
## o salário e devolve a entrega, porque a folha é conta da casa e a casa recomeça
## no nome dela.
var staff_hired: Array[String] = []
## Quem está no cadastro da estrada. Diferente do balcão, o batedor não tem salário
## de virada: ele cobra taxa uma vez e cachê por viagem, e sobe de nível pela estrada
## que pisou (`adventurer_xp`), não pelo ouro que a loja tem.
var adventurers_hired: Array[String] = []
var adventurer_xp: Dictionary = {}
## Mochila armada quer dizer "a melhor peça do gosto dele sai do estoque e vai na
## viagem". É escolha, não automatismo: o balcão perde a etiqueta que venderia e a
## estrada ganha a sorte que o painel promete.
var pack_gear: bool = true
var gear_packed: int = 0
## Nome escrito à mão em cada roteiro. Vazio quer dizer "manda o mais capaz"; a
## loja pode teimar num iniciante, e a estrada cobra o preço da teimosia.
var route_pick: Dictionary = {}
## Fregueses que caíram de amores pela casa e pediram para trabalhar nela. Não
## recebem salário — o pagamento é o próprio balcão —, e é por isso que a chefe tem
## de sustentar a simpatia: um dia ruim demais manda um deles embora.
var servants: Array[String] = []
## Cada servo segura a loja em três pontas: um tique a mais de espera na fila,
## SERVANT_PRICE_SHARE na etiqueta e SERVANT_UPKEEP_RELIEF de conta da casa por
## virada. Ele não custa salário — custa temperamento, ver `_servant_quits`.
const SERVANT_PRICE_SHARE := 0.02
const SERVANT_UPKEEP_RELIEF := 8
const SERVANT_GUARD_CHANCE := 6
## Degraus de sedução provada que abrem uma vaga atrás do balcão. Ninguém larga a
## própria vida para trabalhar de graça numa loja de poções por um sorriso só: a
## casa só oferece lugar depois de ter virado mania no bairro.
const SERVANT_LADDER := [4, 10, 18, 30]
## Furtos barrados pela ronda nesta vida — o número que a conquista do beco lê.
var theft_blocked: int = 0
## Sujeira do salão, de 0 a MESS_LIMIT. Cada visita que sai pela porta leva sola
## um pouco de barro, e cada barro deixado no chão é um cliente que espera menos,
## paga menos e um vândalo que acha a casa fácil. Não é enfeite de painel: é a
## conta que a chefe paga em varrição ou em reputação.
var mess: int = 0
## Quantas varridas a própria chefe fez nesta vida — o número que a conquista da
## vassoura lê, e a única defesa contra a sujeira que custa ouro em vez de salário.
var sweeps_done: int = 0
## Quem está na cela do santuário: nome e, quando for freguês de casa, o id. Entra
## por furto e vandalismo, rende um frasco de sangue por virada e comida na conta.
var prisoners: Array[Dictionary] = []
## Fregueses expulsos do bairro. Quem sai pela porta dos fundos some do sorteio de
## visitas para sempre — e leva junto o vínculo que a casa já tinha nele.
var banned_regulars: Array[String] = []
## Frascos de sangue colhidos na cela nesta vida, só para a conquista contar.
var blood_harvested: int = 0
## O livro de fiado desta vida. Degrau zero = gaveta fechada, e com a gaveta fechada
## nenhuma conta de antes se move. A nota é `id do freguês -> quanto deve, dia do
## prazo e dias de atraso`, e a cobrança roda na virada, junto com casa e filiais.
var credit_rank: int = 0
var credit_book: Dictionary = {}
## Contadores da vida que as conquistas lêem: nota quitada, nota riscada e o ouro que
## a casa emprestou e nunca viu voltar.
var credit_paid: int = 0
var credit_written: int = 0
var credit_lost_gold: int = 0
## A bancada de ensaios desta vida. Um ensaio é um punhado de ingrediente na mesa e
## uma pergunta: será que essa mistura casa com alguma receita que o nível ainda prende?
## A resposta é tabela, não sorteio — o `randi()` da loja não é tocado aqui. `lab_trials`
## guarda a assinatura canônica da mistura ("po_lunar:1+sal:1") -> o id que ela entregou,
## ou "" para beco sem saída; `lab_mix` é o que está em brasa agora, `lab_hints` são as
## fichas que o grimório já vendeu, e `lab_discovered` só conta o que a bancada entregou,
## porque a escada do nível e a leitura da biblioteca também abrem receita.
var lab_trials: Dictionary = {}
var lab_mix: Dictionary = {}
var lab_hints: Array[String] = []
var lab_discovered: Array[String] = []
var lab_flops: int = 0
## O salão das capas finas desta vida. O cordão de veludo é um degrau comprado na
## recepção: com ele guardado na gaveta (`vip_rank == 0`) nenhuma visita é sorteada como
## capa fina, nenhum número de balcão se move e nenhum sorteio extra é consumido. Cada
## degrau traz mais visitas que pagam mais, exigem o topo da barra de qualidade e devolvem
## gorjeta — e quando a estante não tem o degrau que elas aceitam, elas vão embora falando.
var vip_rank: int = 0
var vip_served: int = 0
var vip_refusals: int = 0
var vip_tips_gold: int = 0
## O que a rua conta da casa nesta vida. `complaints` é o livro aberto (sobe quando a casa
## erra, desce uma linha por virada e some quando a voz é comprada); `complaints_written` e
## `complaints_hushed` são a história do livro, para o painel saber quantas linhas já entraram
## e quantas saíram pagas. Livro em branco é loja normal: nenhum número se move.
var complaints: int = 0
var complaints_written: int = 0
var complaints_hushed: int = 0
## O ritmo do balcão nesta vida. `combo_streak` conta as vendas seguidas de hoje (morre na
## virada e morre em quem sai sem comprar); `combo_day_best` e `combo_day_gold` são o dia
## que está acabando, para o balanço; `combo_best` e `combo_gold` são a história da vida,
## que as conquistas lêem. Com o cartaz guardado (`combo_rank == 0`) nada daqui vira ouro:
## a casa conta a sequência, mas não cobra nem paga por ela.
var combo_rank: int = 0
var combo_streak: int = 0
var combo_day_best: int = 0
var combo_day_gold: int = 0
var combo_best: int = 0
var combo_gold: int = 0
## Conserva da casa: cada visita pisa barro, a vassoura custa ouro, e a etiqueta
## despenca no salão imundo. Os números são a única novidade; todos caem em
## fórmulas que o jogo já usava (paciência de fila, multiplicador de preço, conta
## da virada).
const MESS_LIMIT := 100
const MESS_PER_VISIT := 2
const MESS_PER_WALKOUT := 3
const MESS_VANDAL := 18
## Custo de um balde e uma tarde de trabalho: sobe com a marcha da Administração,
## porque casa grande suja mais e a chefe não varre de graça.
const MOP_COST := 18
## A cada MESS_PATIENCE_STEP de barro a fila perde um tique de paciência, e a
## etiqueta perde MESS_PRICE_PENALTY por ponto até o teto.
const MESS_PATIENCE_STEP := 34
const MESS_PRICE_PENALTY := 0.0015
## O que limpa sozinho: a criada da folha varre SWEEP do quadro, e cada servo da
## casa dá uma mão por afeto.
const SERVANT_SWEEP := 4
## Cela do santuário: sangue no frasco e prato na conta. O teto é a reforma do
## santuário — ninguém guarda vândalo em loja que não tem porta trancada.
const CELL_BLOOD := 1
const CELL_FOOD := 3
## Rodada de vândalos na virada: a chance cresce com o salão imundo e cai com a
## fama que já pagou alguém do beco.
const VANDAL_CHANCE_PER_MESS := 0.14
## Abaixo desta reputação o beco entende que a casa não tem quem a defenda, e cada
## ponto que falta vira convite.
const VANDAL_REP_SHIELD := 8
## As três regras da casa. Nenhum número aqui é enfeite: cada fator é consumido no
## lugar onde o jogo já media aquela grandeza — a etiqueta sai por `_piece_price`, a
## conta por `_daily_upkeep`, a rua por `_vandal_chance` e `_invasion_chance`, e o que a
## vida paga na reencarnação por `_aura_gain`. O modo de risco muda o **limiar** do
## sorteio, nunca o sorteio: a mesma semente continua sacando a mesma sequência, só bate
## em paredes diferentes. O Calçada é identidade pura (1.0 em tudo), então nenhuma medida
## antiga muda de valor enquanto ninguém escolhe outra regra.
const DIFFICULTIES := [
	{
		"id": "calcada",
		"name": "Calçada",
		"note": "A loja como sempre foi medida: conta cheia, etiqueta cheia, rua no ritmo de sempre.",
		"price": 1.0,
		"upkeep": 1.0,
		"risk": 1.0,
		"aura": 1.0,
	},
	{
		"id": "juro_alto",
		"name": "Juro Alto",
		"note": "A casa cobra mais, o freguês paga menos e o beco bate duas vezes: a aura vem depois do risco.",
		"price": 0.9,
		"upkeep": 1.3,
		"risk": 1.5,
		"aura": 1.6,
	},
	{
		"id": "poco_sem_fundo",
		"name": "Poço Sem Fundo",
		"note": "Etiqueta curta, conta quase dobrada, rua sempre à porta — e o dobro e meio de aura para quem atravessa.",
		"price": 0.8,
		"upkeep": 1.8,
		"risk": 2.0,
		"aura": 2.5,
	},
]
## Quantos dias de balcão na regra mais dura valem o selo da casa.
const HARDEST_LIFE_DAYS := 10
## O livro de fiado, em três degraus — e o degrau zero é a loja de sempre, com o
## livro na gaveta e nenhuma medida antiga se movendo. Cada fator aqui é consumido no
## lugar onde o jogo já media a grandeza: a nota nasce do preço que o balcão acabou de
## calcular (`_shelf_price`), a cobrança roda na mesma virada que cobra filial e casa,
## e a porta de abrir é ouro + fama, igual ao depósito de sal. Zero quer dizer livro
## na gaveta: a venda que o bolso não paga continua perdida, exatamente como as sondas
## antigas medem.
const CREDIT_TIERS := [
	{"rank": 0, "cost": 0, "rep": 0, "limit": 0, "seats": 0, "due": 0},
	{"rank": 1, "cost": 150, "rep": 8, "limit": 90, "seats": 3, "due": 6},
	{"rank": 2, "cost": 380, "rep": 20, "limit": 180, "seats": 5, "due": 8},
	{"rank": 3, "cost": 720, "rep": 35, "limit": 320, "seats": 8, "due": 12},
]
## Juro sobre a nota que a casa teve de esperar. É pequeno de propósito: fiado bom é
## o que volta, não o que castiga.
const CREDIT_INTEREST := 0.15
## Dias de atraso antes de a casa riscar a nota: o ouro vai embora, a reputação também
## um pouco, e o vínculo do devedor desce um degrau.
const CREDIT_WRITEOFF_DAYS := 3
## A bancada de ensaios. Os números são todos de mesa de trabalho, não de painel: o
## ensaio queima os ingredientes que estão na brasa **e** cobra carvão por unidade, porque
## avental e brasa não vêm de graça. O teto de unidades é o da receita mais gorda da
## estante (2 + 1) arredondado para cima, para existir margem de erro sem a bancada virar
## uma forja secreta.
const LAB_FEE_PER_UNIT := 12
const LAB_MAX_UNITS := 4
## Duas espécies por ensaio: é o tamanho da pergunta. Três espécies seria outra
## mecânica, e a pessoa tem uma loja para tocar.
const LAB_MAX_KINDS := 2
## Barro que um ensaio sem saída deixa no salão: a mistura falha, estoura, e a casa
## pisca isso no chão até a criada passar.
const LAB_FIZZLE_MESS := 3
## Experiência do que não deu: beco errado também ensina, só que pouco.
const LAB_FIZZLE_XP := 2
## Experiência do acerto — mais que um degrau de leitura, menos que uma forja lendária.
const LAB_DISCOVERY_XP := 12
## Palpite do grimório: ouro pela ficha de ingredientes de uma receita travada, uma por
## vez, na mesma ordem da escada de leitura. Segue o desconto da biblioteca (#biblioteca)
## porque é a mesma estante falando, só que do lado da bancada.
const LAB_HINT_COST := 60
## Os três cordões do salão. `chance` é a fatia das visitas que chegam de capa fina,
## `budget` multiplica o bolso do perfil, `standard` é o degrau mínimo da barra de
## qualidade que a visita aceita levar (0 aceita tudo, 2 é Refinado, 3 Obra-prima, 4
## Mítico) e `tip` é a gorjeta sobre o preço de tabela da peça. O cordão não compra
## respeito: servir mal é fama que vai embora junto com a visita.
const VIP_TIERS := [
	{"rank": 0, "cost": 0, "rep": 0, "chance": 0, "budget": 1.0, "standard": 0, "tip": 0.0},
	{"rank": 1, "cost": 220, "rep": 10, "chance": 8, "budget": 2.0, "standard": 2, "tip": 0.15},
	{"rank": 2, "cost": 520, "rep": 24, "chance": 14, "budget": 2.6, "standard": 3, "tip": 0.22},
	{"rank": 3, "cost": 1100, "rep": 45, "chance": 22, "budget": 3.4, "standard": 4, "tip": 0.30},
]
## Uma capa fina tem tempo próprio: ela não disputa o último degrau da fila correndo, e
## por isso espera um tique a mais que o perfil sorteado.
const VIP_PATIENCE_BONUS := 1
## O livro de reclamações da rua: a casa pode estar no topo da fama e ainda assim estar
## malquista, porque queixa não é desconhecimento — é serviço ruim que a rua conta uma à
## outra. Com o livro em branco nenhum número do balcão se move: etiqueta, paciência e
## porta só cobram a partir da sexta linha, e nada aqui consome sorteio.
const COMPLAINT_LINE := 6
const COMPLAINT_SCANDAL := 12
const COMPLAINT_CAP := 24
## Etiqueta que a rua cobra por linha acima da sexta, com teto: quem ouve falar mal da
## loja pechincha, e pechincha até um piso.
const COMPLAINT_LABEL_STEP := 0.02
const COMPLAINT_LABEL_MAX := 0.20
## A fila e a porta sentem o livro em degraus, não em linhas: boca pequena atrasa um tique,
## escândalo atrasa dois e tira um corpo da calçada.
const COMPLAINT_PATIENCE_LOSS := [0, 1, 2]
const COMPLAINT_CROWD_LOSS := [0, 0, 1]
## Pagar a voz da rua apaga três linhas de uma vez e custa mais quanto mais o livro lê.
const COMPLAINT_HUSH_ERASE := 3
const COMPLAINT_HUSH_BASE := 40
const COMPLAINT_HUSH_PER_LINE := 12
## As três fontes: peça torto na mão de alguém, capa fina devolvida no lugar e nota riscada
## no livro de fiado. São as três vezes em que a casa erra e a rua percebe.
const COMPLAINT_FROM_TORTO := 1
const COMPLAINT_FROM_VIP_REFUSAL := 2
const COMPLAINT_FROM_WRITE_OFF := 1
## O cartaz do combo, em três degraus — e o degrau zero é a loja de sempre: a sequência
## de vendas acontece, o balcão continua contando dela para o painel ninguém, e nenhum
## centavo muda de lado. `start` é a venda seguida a partir da qual a casa paga, `step`
## é o acréscimo por venda acima disso e `cap` é o teto da etiqueta: combo bom é ritmo,
## não segunda economia. A sequência morre no dia que vira e morre na visita que sai sem
## comprar — é por isso que o cartaz é o prêmio de quem tem balcão que dá conta.
const COMBO_TIERS := [
	{"rank": 0, "cost": 0, "rep": 0, "start": 0, "step": 0.0, "cap": 0.0},
	{"rank": 1, "cost": 180, "rep": 6, "start": 3, "step": 0.02, "cap": 0.06},
	{"rank": 2, "cost": 460, "rep": 18, "start": 3, "step": 0.03, "cap": 0.12},
	{"rank": 3, "cost": 980, "rep": 38, "start": 2, "step": 0.05, "cap": 0.25},
]
## Teto da contagem: acima de doze vendas seguidas o bônus já está no teto de qualquer
## degrau, então o painel para de contar e o save não precisa de um número sem fundo.
const COMBO_CEIL := 12
## Meta da segunda conquista do cartaz: quanto o combo já precisa ter posto no caixa na
## mesma vida para a casa admitir que o cartaz se pagou sozinho.
const COMBO_PRIZE_GOLD := 600
## Os nomes que a casa enxerga quando a ronda segura um braço no ar. Ninguém aqui é
## freguês de casa: vândalo sorteado é gente de fora do elenco, e por isso vai para
## a cela sem levar vínculo junto.
const VANDAL_NAMES: Array[String] = [
	"Rufino Meia-Noite", "Boca-Salgada Vera", "Caco Tiracolo",
	"Nino do Beco Sem Nome", "Zeca Pé-de-Ferro", "Amparo Mão-Leve",
]
## O que a casa responde quando o vigário bate na porta com a lista de cobrança na
## mão: "" é silêncio, "pago" é o dízimo em dia, "subornado" é o endereço apagado da
## listagem por um tempo, "recusado" é a porta na cara dele — sobe a reputação hoje e
## a visita da rua no mês seguinte. `tithe_until` é o último dia em que a resposta
## ainda vale, porque escudo que não vence não é decisão.
var tithe_stance: String = ""
var tithe_until: int = 0
var tithe_demands: int = 0
var tithe_paid_total: int = 0
var vicar_refusals: int = 0
## Quantas vezes a casa pagou para apagar o próprio endereço da lista. É história da
## família com a paróquia, não da vida: reencarnar não lava o suborno.
var vicar_bribes: int = 0
## Quantas portas a casa segurou e quantas arrombaram. Carimbo de porta segurada é a
## régua da campanha de defesa (`Invasions.PRIVILEGES`) e o número que a rua lê para
## mandar visita mais forte — segurar demais também custa.
var invasions_repelled: int = 0
var invasions_lost: int = 0
## Os privilégios que a campanha já pagou. Diferente da folha e da filial, eles são
## da família: reencarnar não arranca a dobradiça nova nem o sino do caixilho.
var defense_privileges: Array[String] = []
## A última visita escrita por extenso, para o painel não precisar de prosa solta.
var last_invasion: String = ""
## Até que dia de loja o alarme da última porta (segurada ou arrombada) ainda pesa na
## trilha: a mesma faixa, afinada pelo que a rua acabou de fazer com a maçaneta.
var music_alarm_until: int = 0
## O dia em que a cobrança do vigário foi escrita no mural. Sem essa trava, a mesma
## visita bateria na porta duas manhãs seguidas enquanto espera a resposta.
var vicar_announced_day: int = 0
## Faixas de progresso que mudam a cara do salão. A régua é o mesmo placar que o
## painel já mostra (`business_score`), então a loja não ganha meta nova: ela ganha
## consequência visível do que já é.
const PROGRESS_BAND_SCORES: Array[int] = [0, 900, 2400, 5200, 9000]
const PROGRESS_BAND_NAMES: Array[String] = [
	"casa em obras", "balcão arrumado", "casa respeitada", "endereço no bairro", "império da rua",
]
## A luz de cada faixa, aplicada sobre o mesmo PNG. A escada começa ABAIXO da cor
## original de propósito: o estado pintado da arte é o meio da escada (faixa 2, "casa
## respeitada"), não o ponto de partida. Quem abre o jogo pela primeira vez vê um salão
## cru e sem luz acesa; quem fecha a vida no império vê a mesma pintura mais quente do
## que ela jamais foi. Um valor por faixa, sem fórmula, para a escada poder ter degrau
## torto onde a sensação pedir.
##
## O degrau 0 é medido na tela, não no papel: a 0,58 o salão continuava mobiliado e
## aceso, e "casa em obras" tem de constranger antes de premiar. Abaixo de 0,5 o
## painel de texto fica ilegível, e é por isso que a luz só desce até aí.
const PROGRESS_BAND_LIGHT: Array[Color] = [
	Color(0.46, 0.46, 0.62),
	Color(0.72, 0.72, 0.85),
	Color(1.00, 1.00, 1.00),
	Color(1.06, 1.03, 0.96),
	Color(1.12, 1.07, 0.93),
]
## O que cada faixa acende. É a mesma lista que a camada desenhada em código lê,
## escrita para o painel: ninguém decora o que a chefe não consegue nomear.
const PROGRESS_BAND_GIFTS: Array[String] = [
	"o salão em obras: poeira no ar, massa crua na parede, lona no piso e uma lâmpada no fio",
	"piso encerado e tapete realçado na faixa de passeio",
	"+ cordão de velas acesas nas paredes do salão",
	"+ caixilho dourado na moldura da tela",
	"+ lustre aceso no teto e poeira dourada no ar",
]
## A obra da faixa 0, em fração da tela. Nada aqui desenha um cenário novo nem emoldura
## a arte que já existe: são demãos que faltam na parede, pano no piso, prancha de
## andaime, entulho ancorado na linha do chão e o fio da lâmpada. Os móveis cobertos de
## lona não usam coordenada nenhuma: é a própria cor do recorte dos móveis que fica
## lavada (ver `_apply_progress_decor`), porque a oclusão repinta o móvel POR CIMA da
## camada e comeria qualquer pano desenhado ali.
##
## A gramática é escura por medida, não por gosto: a arte do salão é saturada e no
## escuro, e o probe `tools/probes/cara.gd` mostrou que retângulo claro por cima dela lê
## como vidro fosco de interface, não como obra. Falta é sombra.
##
## A geometria fica na faixa de passeio da recepção (x 0,20 a 0,42), que é o piso livre
## da sala principal. Sala onde uma peça colide com o contorno de um móvel mostra o que
## sobra — mesma regra do tapete e do caixilho.
const RENOVATION_WALL_PATCHES: Array[Rect2] = [
	Rect2(0.185, 0.055, 0.175, 0.135),
	Rect2(0.44, 0.02, 0.135, 0.095),
	Rect2(0.675, 0.095, 0.165, 0.115),
	Rect2(0.30, 0.235, 0.105, 0.085),
	Rect2(0.78, 0.275, 0.12, 0.075),
]
## Pares de pé-direito do escoramento (dois por cavalete) e a altura da prancha.
const RENOVATION_POLES: Array[float] = [0.222, 0.268, 0.352, 0.398]
const RENOVATION_PLANK_Y := 0.455
## A lona estendida no piso, em quatro cantos: superior esquerdo, superior direito,
## inferior direito, inferior esquerdo. É o único claro grande da cena, e por isso é
## chumbo, não branco.
const RENOVATION_CLOTH: Array[Vector2] = [
	Vector2(0.185, 0.795), Vector2(0.415, 0.772), Vector2(0.475, 0.905), Vector2(0.150, 0.928),
]
## Montículos de entulho, em deslocamento a partir do ponto do chão pintado: o pé
## prende no piso da sala, não numa altura arbitrária da tela.
const RENOVATION_RUBBLE: Array[Vector2] = [
	Vector2(-0.375, -0.008), Vector2(-0.295, 0.012), Vector2(-0.225, -0.018),
]
## Balde de tinta no pé do andaime, em deslocamento do ponto do chão.
const RENOVATION_BUCKET := Vector2(-0.185, 0.004)
## Quantas faixas de progresso ainda mostram a obra. A lona some antes do luxo chegar,
## senão a casa "respeitada" continuaria com o balcão tapado.
const RENOVATION_LAST_BAND := 1
## Sala sem entrada aqui recebe a faixa de passeio no lugar.
const PROGRESS_RUG := {
	"res://assets/shop_scene.png": [
		Vector2(0.30, 0.72), Vector2(0.70, 0.72), Vector2(0.83, 1.0), Vector2(0.19, 1.0),
	],
	"res://assets/library_room_scene.png": [
		Vector2(0.26, 0.78), Vector2(0.74, 0.78), Vector2(0.86, 1.0), Vector2(0.14, 1.0),
	],
}
## Faixa atual e a camada que a desenha. Camada própria, acima do fundo pintado e
## abaixo do elenco: a decoração não compete com corpo nem come o clique de ninguém.
var _progress_band: int = 0
## O primeiro painel da sessão não comemora: a casa pode abrir já crescida, e
## festa de carregamento é festa falsa.
var _progress_quiet: bool = true
var _progress_layer: Control
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
## Diferencia o `visibility_changed` que abre a janela do que a fecha; ver
## `_close_offline_report()`.
var offline_report_shown: bool = false
var _offline_elapsed_seconds: float = 0.0
var _offline_branch_fraction: float = 0.0
## Idioma e menu do ESC. A língua é preferência da pessoa, não da vida: ela não é
## apagada por reencarnar nem por `_reset_run()`, e mora tanto no arquivo de
## preferências (`user://locale_settings.cfg`) quanto no save, para um save exportado
## levar o idioma junto. `locale_confirmed` marca que alguém escolheu de verdade — é
## ela que decide se a loja abre direto ou com o seletor de idioma na frente.
var locale: String = Locales.DEFAULT
var locale_confirmed: bool = false
var menu_layer: Control
var menu_start_mode: bool = false
## A tela aberta dentro do menu. `root` é a única que fecha com ESC; as outras voltam
## para a raiz, como em jogo moderno.
var menu_screen: String = "root"
var menu_language_buttons: Array[Button] = []
var menu_status_label: Label
var menu_volume_label: Label
## Onde a tela atual é montada dentro da moldura.
var menu_box: VBoxContainer
var menu_button: Button
## Janela e desenho são da pessoa que joga, não da vida: moram no mesmo arquivo do
## idioma e sobrevivem a reencarnar e a apagar o progresso.
var window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var ui_scale: float = 1.0
var vsync_mode: int = DisplayServer.VSYNC_ENABLED
## O arquivo de preferências respondeu? Se sim, ele manda sobre o save: o save é a conta
## da loja, e a loja pode ser exportada para outra máquina sem arrastar o idioma dela.
var _locale_from_settings: bool = false
var speed_label: Label
var speed_button: Button
var forge_status_label: Label
var craft_jobs: Array[Dictionary] = []
var library_upgrade_level: int = 0
var sanctum_upgrade_level: int = 0
var library_upgrade_button: Button
var sanctum_upgrade_button: Button
var cold_storage_button: Button
var sector_action_button: Button
var queue_distractions: int = 0
var ingredient_stock: Dictionary = STARTING_PANTRY.duplicate()
## Estoque de peças por qualidade: { id_do_produto: [torto, honesto, refinado, prima, mitico] }
var quality_stock: Dictionary = {}
## Idade de cada peça que vence: { id_do_produto: [{tier, day}] }, da mais antiga
## para a mais nova. Sem registro a peça entra como recém-posta — save antigo nunca
## acorda com a despensa virada.
var shelf_batches: Dictionary = {}
## Depósito de sal (0..3): cada nível soma uma validade inteira ao relógio da
## prateleira. Não muda preço nem sorte — muda só o prazo.
var cold_storage_level: int = 0
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
	{"id": "dano_emocional", "name": "Poção de Dano Emocional", "cost": 8, "price": 15, "stock": 1, "validade": 6, "ingredients": {"essencia": 1}, "desc": "Lembra você daquela mensagem que mandou em 2018."},
	{"id": "pato_amaldicoado", "name": "Pato Amaldiçoado Premium", "cost": 10, "price": 24, "stock": 1, "ingredients": {"pena": 1}, "desc": "Ele não faz nada. Mas julga suas decisões."},
	{"id": "lagrimas_jogador", "name": "Lágrimas de Jogador Derrotado", "cost": 12, "price": 30, "stock": 1, "validade": 14, "ingredients": {"sal": 1}, "desc": "Ingrediente raro. Salgado. Muito salgado."},
	{"id": "caixa_misteriosa", "name": "Caixa Misteriosa Vazia", "cost": 5, "price": 12, "stock": 1, "ingredients": {"vazio": 1}, "desc": "A surpresa é perceber que você pagou por uma caixa."},
	{"id": "confianca_instantanea", "name": "Poção de Confiança Instantânea", "cost": 9, "price": 22, "stock": 1, "validade": 4, "ingredients": {"essencia": 1, "tinta": 1}, "desc": "Funciona até alguém pedir para você explicar."},
	{"id": "elixir_memoria", "name": "Elixir de Memória de Peixe", "cost": 18, "price": 48, "stock": 0, "required_level": 3, "validade": 8, "ingredients": {"sal": 1, "po_lunar": 1}, "desc": "Você esquece por que comprou. E compra de novo."},
	{"id": "incenso_teleporte", "name": "Incenso de Teletransporte Barato", "cost": 26, "price": 68, "stock": 0, "required_level": 5, "validade": 5, "ingredients": {"po_lunar": 1, "tinta": 1}, "desc": "Leva você a três metros dali. Às vezes quatro."},
	{"id": "cristal_credito", "name": "Cristal de Crédito Cósmico", "cost": 42, "price": 115, "stock": 0, "required_level": 8, "ingredients": {"vazio": 1, "tinta": 2}, "desc": "Converte promessas vagas em dívidas muito concretas."},
	{"id": "pergaminho_procrastinacao", "name": "Pergaminho de Procrastinação Certificada", "cost": 55, "price": 150, "stock": 0, "required_level": 10, "ingredients": {"tinta": 2, "essencia": 1}, "desc": "Adia tarefas importantes com selo ISO de preguiça."},
	{"id": "frasco_motivacao", "name": "Frasco de Motivação de Segunda-feira", "cost": 70, "price": 195, "stock": 0, "required_level": 12, "validade": 3, "ingredients": {"po_lunar": 2, "sal": 1}, "desc": "Efeito dura até o primeiro e-mail."},
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
var expedition_pick_buttons: Array = []
var adventurer_labels: Array = []
var adventurer_buttons: Array = []
var adventurer_summary_label: Label
var pack_gear_button: Button
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
var rival_summary_label: Label
var rival_labels: Array = []
var rival_buttons: Array = []
var staff_summary_label: Label
var queue_label: Label
var mess_label: Label
var progress_label: Label
var sweep_button: Button
var cell_label: Label
var release_button: Button
var deliver_button: Button
var banish_button: Button
var staff_labels: Array = []
var staff_buttons: Array = []
var defense_label: Label
var defense_lines_label: Label
var invasion_label: Label
var vicar_label: Label
var tithe_button: Button
var bribe_button: Button
var refuse_button: Button
var arc_summary_label: Label
var arc_labels: Array = []
var arc_desc_labels: Array = []
var arc_buttons: Array = []
var spec_summary_label: Label
var spec_labels: Array = []
var spec_state_labels: Array = []
var spec_buttons: Array = []
var pack_button: Button
var credit_button: Button
var credit_label: Label
var lab_label: Label
var lab_add_buttons: Array = []
var lab_clear_button: Button
var lab_fire_button: Button
var lab_hint_button: Button
var vip_label: Label
var vip_button: Button
var complaint_label: Label
var complaint_button: Button
var combo_label: Label
var combo_button: Button
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
var difficulty_button: Button
var difficulty_label: Label
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
## Se a sala atual tem chão andável. A camada de progresso respeita a flag: sem
## chão pintado (close-up de cena), não há tapete nem lustre onde desenhar.
var _stage_walkable: bool = true
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
## O volume da trilha antes do ajuste mestre, em dB. A faixa é uma só, mas a situação
## afina esse número (`_music_situation`) e a config geral continua por cima dele.
var music_base_db: float = -13.0
const GameAudio = preload("res://audio.gd")
var audio: Node
var toast_label: Label
var toast_tween: Tween
var market_panel: VBoxContainer
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
const MEME_CUSTOMER_NAMES := ["Mago do Quero Mana", "Fiscal do Pix Astral", "Só Mais Uma Run", "Ladino do Ctrl+C", "Cliente do É Sobre Isso"]
const MEME_FLIRT_LINES := [
"A chefe responde ao Mago do Quero Mana: “Mana eu tenho. Quero ver se você aguenta o preço.”",
"Ela encara o Fiscal do Pix Astral: “Aproxima o cristal, querido. Se der erro, você paga com um elogio.”",
"A succubus provoca o corredor: “Só mais uma run? Então fica mais uma negociação comigo.”",
"Ela sorri para o cliente do bordão: “É sobre isso. E sobre você voltar amanhã.”",
"A chefe aponta para o ladrão: “Ctrl+C não copia meu charme. Esse é proprietário.”"
]
## O mesmo balcão dito em outra voz: com o filtro de cenas desligado a negociação
## continua sendo confiança e ficha no caderno, nunca menos negócio. O interruptor
## troca o texto, jamais a chance, o efeito ou a porta que ele abre.
const TRUST_NEGOTIATION_LINES := [
"A chefe anota o nome no caderno: “Leva agora e paga na volta. Confiança também é moeda aqui.”",
"Ela apoia o cotovelo no balcão: “Para um freguês tão constante, eu sempre arrumo um jeito.”",
"A chefe assente devagar: “Não é magia. É você voltar toda manhã desde aquele primeiro dia.”",
"Ela desliza o item pelo balcão: “Leve. O preço é pequeno perto da propaganda que você vai fazer.”"
]
const MEME_TRUST_LINES := [
"A chefe responde ao Mago do Quero Mana: “Mana eu tenho. Quero ver se você sustenta a etiqueta.”",
"Ela encara o Fiscal do Pix Astral: “Aproxima o cristal. Se der erro, você resolve com a própria banca.”",
"A chefe conta as runas do corredor: “Só mais uma run? Então fica mais uma compra consignada.”",
"Ela anota o bordão do cliente: “É sobre isso. E sobre você voltar amanhã com o bolso cheio.”",
"A chefe aponta para o ladrão: “Ctrl+C não copia ficha de fidelidade. Essa é proprietária.”"
]
## A escada de momentos só da casa, em doze degraus. A fala sobe a lista em vez de
## reciclar: cada momento liberado mostra o próximo degrau do tom, e o topo é o
## quarto andar — a casa corta antes de mostrar qualquer coisa. Nada aqui muda
## economia, porta ou placar: é só a voz.
const SENSUAL_MOMENTS: Array[String] = [
	"A súcubo inclina a cabeça, dá uma piscadela e puxa você para mais perto: “Esse é nosso segredinho, combinado?”",
	"Ela gira uma moeda entre os dedos e sorri de lado: “Talvez eu revele mais de mim quando nossa parceria ficar ainda mais lucrativa.”",
	"A chefe faz uma pose provocante e ri baixinho: “Você desbloqueou meu lado favorito: o que não aparece para qualquer cliente.”",
	"Ela vira a placa de FECHADO antes da hora e não explica para quem: “Senta atrás do balcão. Hoje eu quero ver como você atende.”",
	"A chefe sopra a vela que fica do seu lado e a luz cai pela metade: “Aqui dentro ninguém cobra gorjeta de quem fica até o fim.”",
	"Ela pendura o avental no gancho e cruça os braços, de camiseta de trabalho: “Fica tranquilo. Hoje eu não quero freguês, quero companhia.”",
	"A chefe derrama dois copos e empurra um na sua direção: “Ninguém bebe aqui sem me contar um fracasso. Começa pelo seu.”",
	"Ela deixa a porta dos fundos entreaberta de propósito: “Se quiser ver onde a casa guarda o que não está à venda, é só pedir.”",
	"A chefe tira a chave do bolso, deixa passar entre os dedos dela e devolve: “O porão tem mais uma porta. Ainda não decidimos se você é gente de abrir.”",
	"Ela se encosta na moldura da tela pintada e mostra o piso riscado: “Essa casa já foi um casebre com uma vela só. Você é o terceiro que eu deixo chegar aqui.”",
	"A chefe apaga todas as luzes menos uma e ri no escuro: “Não se aproxima tanto. Eu gosto de deixar o cliente escolhendo onde parar.”",
	"Ela puxa a cadeira, senta de frente para você, e a loja fica em silêncio: “Fica até a última vela. Depois do apagão a casa não conta nada — nem para mim.”"
]
## Os momentos só da loja na versão sem cena: a chefe baixa a voz do mesmo jeito,
## só que o que ela entrega é a confiança da casa, não o flerte. Espelho degrau a
## degrau da escada de cima — mesma porta, mesmo contador, só a voz trocando.
const TRUST_MOMENTS: Array[String] = [
	"A chefe inclina a cabeça, puxa a cadeira para perto e abaixa a voz: “Isso aqui não sai da loja, combinado?”",
	"Ela gira uma moeda entre os dedos e sorri de lado: “Talvez eu revele mais da casa quando nossa parceria ficar ainda mais lucrativa.”",
	"A chefe bate o punho no balcão e ri baixo: “Você desbloqueou meu lado favorito: o que não aparece para qualquer cliente.”",
	"Ela vira a placa de FECHADO antes da hora e não explica para quem: “Senta atrás do balcão. Hoje eu quero ver como você atende.”",
	"A chefe acende a segunda vela da sala e aponta o banquinho do balcão: “Quem fica até o fim do dia ganha nome no caderno. O seu acabou de entrar.”",
	"Ela pendura o avental no gancho e senta no degrau da porta, de camiseta de trabalho: “Fica tranquilo. Hoje eu não quero freguês, quero uma conversa honesta.”",
	"A chefe derrama dois copos e empurra um na sua direção: “Ninguém bebe aqui sem me contar um fracasso. Começa pelo seu.”",
	"Ela deixa a porta dos fundos aberta e chama você para ver: “É aqui que a casa guarda o que não está à venda: o estoque e a própria palavra.”",
	"A chefe mostra a chave do porão e devolve o bolso: “Lá embaixo tem mais uma porta. Ela abre para quem já provou que volta.”",
	"Ela se encosta na moldura da tela pintada e mostra o piso riscado: “Essa casa já foi um casebre com uma vela só. Você é o terceiro que eu deixo chegar aqui.”",
	"A chefe apaga todas as luzes menos uma e ri no escuro: “Fica aí. Eu gosto de deixar o cliente medindo sozinho até onde a confiança vai.”",
	"Ela puxa a cadeira, senta de frente para você, e a loja fica em silêncio: “Fica até a última vela. Depois do apagão a casa não conta nada — nem para mim.”"
]
## As falas do marco de afeição (a cada 10 pontos do medidor), na mesma lógica da
## escada de momentos: o degrau sobe com o medidor em vez de reciclar.
const SENSUAL_AFFECTION_MILESTONES: Array[String] = [
	"A súcubo se aproxima com um sorriso cúmplice: “Você está conquistando minha confiança… e isso pode render recompensas bem interessantes.”",
	"Ela ajeita a mecha de cabelo e não se afasta do balcão: “Olha o tanto que você já subiu aqui dentro. E olha o que ainda falta.”",
	"Ela se inclina até a voz virar sussurro: “Poucos clientes chegaram onde você está. Nenhum ficou quando eu pedi para ficar.”",
	"A chefe mede o salão vazio, apaga a última vela da vitrine e ri baixo no escuro: “Cheio demais, querido. Agora você já não cabe no lado de cá do balcão.”"
]
## Espelho sem cena do bloco de cima: a chefe continua descendo a voz no mesmo
## degrau do medidor, só que o que ela entrega é a conta da casa, não o flerte.
const TRUST_AFFECTION_MILESTONES: Array[String] = [
	"A chefe anota a linha nova do caderno e vira a página para você ver: “Você está conquistando a confiança da casa… e isso rende consequência boa.”",
	"Ela apoia as duas mãos no balcão e olha a fila inteira: “Olha o tanto que você já subiu aqui dentro. E olha o que ainda falta.”",
	"Ela baixa a voz para ninguém mais na sala ouvir: “Poucos clientes chegaram onde você está. Nenhum ficou quando eu pedi para ficar.”",
	"A chefe mede o salão vazio, apaga a última vela da vitrine e ri baixo no escuro: “Confiança cheia. Agora você já não cabe no lado de cá do balcão.”"
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
	Locales.register()
	_load_person_settings()
	_apply_player_settings()
	_load_game()
	TranslationServer.set_locale(locale)
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
	# Ninguém escolheu idioma ainda: a loja abre com o seletor na frente, como em jogo
	# moderno. Em headless não existe quem clique, e uma janela que para a rua sem poder
	# ser fechada seria um beco sem saída — ali a loja abre direto e a sonda chama o menu
	# sozinha.
	if not locale_confirmed and DisplayServer.get_name() != "headless":
		_open_menu(true)

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
		# O botão OK é um jeito de fechar a janela; ESC, o X da janela e hide() são outros.
		# Preso só ao `confirmed`, o relógio ficava parado para sempre em qualquer um desses
		# caminhos — loja congelada com um freguês plantado no balcão.
		offline_dialog.visibility_changed.connect(_close_offline_report)
		add_child(offline_dialog)
		offline_report_shown = false
		# Depois do popup, não antes: com a janela ainda escondida o `_sync_clock()`
		# não a veria e a rua continuaria andando atrás do resumo.
		offline_dialog.popup_centered(Vector2i(720, 320))
		offline_report_shown = true
		_sync_clock()

## O resumo fecha por quatro caminhos: o OK, que emite `confirmed` com a janela ainda na
## tela, e o ESC, o X e um hide(), que só escondem o Window. Preso só ao `confirmed`, o
## relógio ficava parado para sempre nos outros três — loja congelada com um freguês
## plantado no balcão. A marca `offline_report_shown` separa o visibility_changed da
## abertura do do fechamento; sem ela a janela se fecharia no frame em que nasce.
func _close_offline_report() -> void:
	if offline_dialog == null:
		return
	if offline_dialog.visible and not offline_report_shown:
		return
	offline_dialog.queue_free()
	offline_dialog = null
	offline_report_shown = false
	_sync_clock()

# ── Idioma e menu do ESC ──

## Toda janela que segura a rua parada neste instante. VISÍVEL é a palavra-chave: o
## painel do final é escondido e reusado em vez de liberado, e um nó escondido na árvore
## não tem o direito de fechar a loja. O painel do final também não está na lista porque
## ele nunca parou a rua — no modo livre o dia continua correndo atrás dele.
func _modal_holds_clock() -> bool:
	if offline_dialog != null and offline_dialog.visible:
		return true
	for layer in [day_layer, origin_layer, menu_layer]:
		if is_instance_valid(layer) and layer.visible:
			return true
	return false

## O relógio obedece a uma frase só: anda enquanto nenhuma janela estiver na tela. Cada
## janela decidia isso sozinha, do seu próprio jeito, sem saber das outras — era assim
## que a loja acordava parada para sempre.
func _sync_clock() -> void:
	if not is_instance_valid(world_timer):
		return
	if _modal_holds_clock():
		if not world_timer.is_stopped():
			world_timer.stop()
	elif world_timer.is_stopped():
		world_timer.start()

## ESC abre e fecha o menu, como em jogo moderno, e a janela para a rua: enquanto a
## chefe está no menu, nenhum cliente bate na porta. O diálogo de escolha de idioma da
## primeira abertura é o mesmo menu com menu_start_mode ligado — uma janela, dois papéis.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != KEY_ESCAPE:
		return
	if is_instance_valid(menu_layer):
		# Dois toques, dois papéis: o ESC primeiro desfaz a submenu e só depois fecha o
		# menu. Quem está dentro de "Opções" quer voltar, não sair da loja.
		if menu_start_mode or menu_screen == "root":
			_close_menu()
		else:
			_show_menu_screen("root")
	else:
		_open_menu(false)
	get_viewport().set_input_as_handled()

func _open_menu(start_mode: bool) -> void:
	menu_start_mode = start_mode
	menu_screen = "idioma" if start_mode else "root"
	_build_menu_layer()
	_sync_clock()

## Navegar dentro do menu é redesenhar a mesma janela, não abrir outra: o relógio continua
## parado porque continua havendo uma janela na tela, e é `_sync_clock()` que garante isso
## em vez de cada tela decidir por conta.
func _show_menu_screen(screen: String) -> void:
	menu_screen = screen
	_build_menu_layer()
	_sync_clock()

func _close_menu() -> void:
	var was_start := menu_start_mode
	_free_menu_layer()
	menu_start_mode = false
	if was_start and not locale_confirmed:
		# Fechar o seletor sem escolher também é resposta: a loja fica no idioma que já
		# tinha, e o seletor não volta a cada abertura do jogo.
		locale_confirmed = true
		_save_person_settings()
	_save_game()
	_sync_clock()

func _free_menu_layer() -> void:
	if is_instance_valid(menu_layer):
		menu_layer.queue_free()
	menu_layer = null
	menu_language_buttons.clear()
	menu_status_label = null
	menu_volume_label = null
	menu_box = null

## A moldura: fundo escuro, painel, título fixo e uma caixa rolável onde a tela atual é
## montada. Os textos são literais em português porque o catálogo traduz o rótulo pronto —
## é por isso que dar mais idioma ao jogo não pede tocar em nenhuma destas funções.
func _build_menu_layer() -> void:
	_free_menu_layer()
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	menu_layer = dim

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)

	var panel := PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.03, 0.11, 0.99)
	panel_style.border_color = Color(0.85, 0.62, 1.0, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var frame := VBoxContainer.new()
	frame.custom_minimum_size = Vector2(560, 0)
	frame.add_theme_constant_override("separation", 10)
	panel.add_child(frame)

	var title := Label.new()
	title.text = _menu_title()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.85, 0.62, 1.0))
	frame.add_child(title)

	# A conquista são umas cinquenta linhas; sem rolagem a tela ficaria maior que a loja.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 420)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)

	menu_box = VBoxContainer.new()
	menu_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_box.add_theme_constant_override("separation", 8)
	scroll.add_child(menu_box)

	match menu_screen:
		"opcoes":
			_menu_screen_opcoes()
		"save":
			_menu_screen_save()
		"conquistas":
			_menu_screen_conquistas()
		"creditos":
			_menu_screen_creditos()
		"idioma":
			_menu_screen_idioma()
		_:
			_menu_screen_root()

func _menu_title() -> String:
	if menu_start_mode:
		return "ESCOLHA O IDIOMA"
	match menu_screen:
		"opcoes":
			return "OPÇÕES"
		"save":
			return "SALVAR E CARREGAR"
		"conquistas":
			return "CONQUISTAS"
		"creditos":
			return "CRÉDITOS"
		"idioma":
			return "IDIOMA"
	return "MENU"

func _menu_button(text: String, callback: Callable, height: int = 44) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, height)
	button.pressed.connect(callback)
	menu_box.add_child(button)

func _menu_note(text: String, color := Color(0.78, 0.72, 0.86), size := 13) -> void:
	var note := Label.new()
	note.text = text
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", size)
	note.add_theme_color_override("font_color", color)
	menu_box.add_child(note)

func _menu_back_button() -> void:
	_menu_button("← Voltar ao menu", _show_menu_screen.bind("root"))

## Raiz: tudo que a loja tinha espalhado pelo topo e nas abas cabe agora aqui, e o que é
## conta da pessoa (som, tela, escala) está uma camada abaixo, nunca na frente do balcão.
func _menu_screen_root() -> void:
	_menu_note("O balcão continua aqui. Este é o menu da loja — o mesmo que o ESC abre.",
			Color(0.72, 0.66, 0.8), 13)
	_menu_button("Continuar a loja", _close_menu, 48)
	_menu_button("⚙ Opções", _show_menu_screen.bind("opcoes"))
	_menu_button("💾 Salvar e carregar", _show_menu_screen.bind("save"))
	_menu_button(tr("🏆 Conquistas (%d/%d)") % [unlocked_achievements.size(), _achievement_definitions().size()],
			_show_menu_screen.bind("conquistas"))
	_menu_button("✨ Créditos", _show_menu_screen.bind("creditos"))
	_menu_button("🌐 Idioma", _show_menu_screen.bind("idioma"))
	_menu_button("🐞 Relatar um problema", _show_bug_report_dialog, 40)
	_menu_note("Fechar menu (ESC)", Color(0.62, 0.56, 0.74), 12)

func _menu_screen_idioma() -> void:
	if menu_start_mode:
		_menu_note("O jogo abre em português, sua língua de origem. Trocar de idioma não muda nenhuma conta da loja: nem a porta, nem o bolso, nem o placar.")
	for supported in Locales.SUPPORTED:
		var id := str(supported["id"])
		var button := Button.new()
		button.text = _locale_button_text(id)
		button.custom_minimum_size = Vector2(0, 44)
		button.pressed.connect(_pick_locale.bind(id))
		menu_box.add_child(button)
		menu_language_buttons.append(button)
	if menu_start_mode:
		_menu_button("Entrar na loja", _close_menu, 48)
	else:
		_menu_note("A prosa montada durante a partida — falas de cliente, balanço da virada, eventos — ainda sai no idioma original.",
				Color(0.72, 0.66, 0.8), 12)
		_menu_back_button()

func _menu_screen_opcoes() -> void:
	var volume_row := HBoxContainer.new()
	volume_row.add_theme_constant_override("separation", 12)
	menu_box.add_child(volume_row)
	menu_volume_label = Label.new()
	menu_volume_label.text = _menu_volume_text()
	menu_volume_label.custom_minimum_size = Vector2(150, 42)
	menu_volume_label.add_theme_color_override("font_color", Color(0.85, 0.78, 0.95))
	volume_row.add_child(menu_volume_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = audio.volume
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 42)
	slider.value_changed.connect(_menu_volume_changed)
	volume_row.add_child(slider)

	_menu_button("🔥 Cenas sensuais: LIBERADAS" if adult_content_enabled else "🌸 Cenas sensuais: CONTIDAS",
			_menu_toggle_adult)
	_menu_button("🔇 Som: DESLIGADO" if audio.muted else "🔊 Som: LIGADO", _menu_toggle_mute)
	_menu_button("Ocultar o painel da loja" if is_instance_valid(market_panel) and market_panel.visible
			else "Mostrar o painel da loja", _menu_toggle_market)
	_menu_button("Balanço do dia: automático" if day_auto_ok else "Balanço do dia: pede OK",
			_menu_toggle_day_auto)
	_menu_button(_menu_window_mode_label(), _cycle_window_mode)
	_menu_button(_menu_scale_label(), _cycle_ui_scale)
	_menu_button(_menu_vsync_label(), _cycle_vsync)
	_menu_note("Nada aqui é conta da loja: som, tela e o tom das cenas são preferência de quem joga. Dotes, servos e o resto da administração ficam na Biblioteca e no Santuário.",
			Color(0.66, 0.6, 0.76), 12)
	_menu_back_button()

## O tom das cenas é a preferência mais sensível do menu, e por isso ela mora embaixo de
## um toque de distância do balcão, nunca no meio da fila: ligar e desligar troca a voz da
## loja, os dotes e as poses, mas não mexe em caixa, reputação nem freguês atendido.
func _menu_toggle_adult() -> void:
	_toggle_adult_content()
	_show_menu_screen("opcoes")

func _menu_screen_save() -> void:
	_menu_button("Salvar agora", _menu_save_now)
	menu_status_label = Label.new()
	menu_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_status_label.add_theme_font_size_override("font_size", 13)
	menu_status_label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.72))
	menu_box.add_child(menu_status_label)
	_menu_note(tr("Save da vida: dia %d, nível %d, %d de ouro.") % [shop_day, player_level, gold],
			Color(0.72, 0.66, 0.8), 12)
	_menu_button("Exportar save para arquivo", _show_save_dialog.bind(true), 40)
	_menu_button("Importar save de arquivo", _show_save_dialog.bind(false), 40)
	_menu_button("Carregar o último save do disco", _reload_from_disk, 40)
	_menu_button("Apagar todo o progresso", _confirm_full_reset, 40)
	_menu_note("Importar e apagar reabrem a loja: nada é escrito sem a janela de confirmação aparecer antes.",
			Color(0.66, 0.6, 0.76), 12)
	_menu_back_button()

func _menu_screen_conquistas() -> void:
	var definitions := _achievement_definitions()
	_menu_note(tr("Desbloqueadas: %d de %d.") % [unlocked_achievements.size(), definitions.size()],
			Color(0.85, 0.78, 0.95), 15)
	var shown := 0
	for achievement in definitions:
		if unlocked_achievements.has(str(achievement["id"])):
			shown += 1
			_menu_note(tr("✓ %s  (+%d ouro, +%d fama)") % [str(achievement["name"]),
					int(achievement["gold"]), int(achievement["rep"])], Color(0.72, 0.95, 0.8), 13)
	if shown == 0:
		_menu_note("Nenhuma ainda. A primeira chega com o primeiro atendimento do dia.",
				Color(0.66, 0.6, 0.76), 13)
	else:
		_menu_note(tr("Trancadas neste balcão: %d — os nomes ficam escondidos para não estragar a surpresa.")
				% (definitions.size() - shown), Color(0.66, 0.6, 0.76), 12)
	_menu_back_button()

func _menu_screen_creditos() -> void:
	_menu_note("SUCCUBUS SHOP", Color(1.0, 0.67, 0.88), 20)
	_menu_note("Concepção, código, escrita e arte: GMGuimaraes.", Color(0.85, 0.78, 0.95), 14)
	var engine_version := str(Engine.get_version_info().get("string", "4"))
	_menu_note("Motor: Godot %s (gl_compatibility)." % engine_version, Color(0.85, 0.78, 0.95), 14)
	_menu_note("Trilha e efeitos gravados no próprio projeto; retratos e poses desenhados para a loja, sem arte explícita.",
			Color(0.78, 0.72, 0.86), 13)
	_menu_note("As IAs que revisaram este repositório no mesmo ritmo das madrugadas: Claude, ChatGPT, Copilot e Manus.",
			Color(0.72, 0.66, 0.8), 13)
	_menu_note(tr("Obrigado por jogar — e por relatar o que quebrou."), Color(0.85, 0.62, 1.0), 14)
	_menu_back_button()

func _menu_volume_text() -> String:
	return tr("Volume: %d%%") % int(round(audio.volume * 100.0))

## Arrastar a barra não pode redesenhar a tela: o slider sumiria debaixo do dedo a cada
## passo. Só a legenda atrás dele se atualiza.
func _menu_volume_changed(value: float) -> void:
	audio.set_volume(value)
	if is_instance_valid(menu_volume_label):
		menu_volume_label.text = _menu_volume_text()

func _menu_toggle_mute() -> void:
	audio.toggle_muted()
	_apply_music_settings()
	_show_menu_screen("opcoes")

func _menu_toggle_market() -> void:
	_toggle_market_panel()
	_show_menu_screen("opcoes")

func _menu_toggle_day_auto() -> void:
	_on_day_auto_ok_toggled(not day_auto_ok)
	_show_menu_screen("opcoes")

const WINDOW_MODES: Array[int] = [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_MAXIMIZED,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
]
const UI_SCALES: Array[float] = [1.0, 1.25, 1.5, 0.85]
const VSYNC_MODES: Array[int] = [
	DisplayServer.VSYNC_ENABLED,
	DisplayServer.VSYNC_ADAPTIVE,
	DisplayServer.VSYNC_DISABLED,
]

## Cada rótulo entra inteiro na tabela, e não como "Tela: %s" com a palavra solta
## costurada depois: "Janela" traduzida sozinha seria um termo de menu órfão, e o
## genêro e a ordem das palavras mudam de idioma para idioma.
func _menu_window_mode_label() -> String:
	if window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		return tr("Tela: Maximizada")
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return tr("Tela: Tela cheia")
	return tr("Tela: Janela")

func _menu_scale_label() -> String:
	return tr("Escala da interface: %d%%") % int(round(ui_scale * 100.0))

func _menu_vsync_label() -> String:
	if vsync_mode == DisplayServer.VSYNC_DISABLED:
		return tr("Sincronismo vertical: Desligado")
	if vsync_mode == DisplayServer.VSYNC_ADAPTIVE:
		return tr("Sincronismo vertical: Adaptativo")
	return tr("Sincronismo vertical: Ligado")

func _cycle_window_mode() -> void:
	window_mode = WINDOW_MODES[(WINDOW_MODES.find(window_mode) + 1) % WINDOW_MODES.size()]
	_apply_player_settings()
	_save_person_settings()
	_show_menu_screen("opcoes")

func _cycle_ui_scale() -> void:
	ui_scale = UI_SCALES[(UI_SCALES.find(ui_scale) + 1) % UI_SCALES.size()]
	_apply_player_settings()
	_save_person_settings()
	_show_menu_screen("opcoes")

func _cycle_vsync() -> void:
	vsync_mode = VSYNC_MODES[(VSYNC_MODES.find(vsync_mode) + 1) % VSYNC_MODES.size()]
	_apply_player_settings()
	_save_person_settings()
	_show_menu_screen("opcoes")

## As três trocas de janela são do sistema, não da loja: em headless elas apenas são
## aceitas e ignoradas, e a sonda lê o valor guardado, não o pixel na tela. Aplicar não
## grava em disco — o boot aplica o que já está gravado sem reescrever o arquivo.
func _apply_player_settings() -> void:
	DisplayServer.window_set_mode(window_mode)
	var window := get_window()
	if is_instance_valid(window):
		window.content_scale_factor = ui_scale
	DisplayServer.window_set_vsync_mode(vsync_mode)

## Voltar ao disco sem apagar a conta: a cena reinicia e lê o que está gravado.
func _reload_from_disk() -> void:
	audio.play("click")
	get_tree().reload_current_scene()

func _locale_button_text(id: String) -> String:
	var line := Locales.display_name(id)
	var note := Locales.coverage(id)
	if note != "":
		line = "%s — %s" % [line, note]
	if id == Locales.DEFAULT:
		line = "%s (%s)" % [line, tr("idioma original")]
	if id == locale:
		line = "%s  ✓" % line
	return line

func _menu_save_now() -> void:
	_save_game()
	audio.play("coin")
	if is_instance_valid(menu_status_label):
		menu_status_label.text = tr("progresso salvo")

## Troca de idioma no vivo. O menu se redesenha porque as legendas dele são literais, e
## o resto da loja passa pelo refresh: trocar a língua e ver meia tela traduzida é o bug
## que este botão existe para não ter.
func _pick_locale(id: String) -> void:
	if not Locales.knows(id):
		return
	locale = id
	locale_confirmed = true
	TranslationServer.set_locale(locale)
	_save_person_settings()
	_save_game()
	_build_menu_layer()
	_sync_clock()
	_refresh_ui()
	audio.play("click")

## A preferência mora fora do save de propósito: reencarnar, resetar a vida e até apagar
## o progresso são contas da loja, e o idioma e a tela são da pessoa que joga. Um arquivo
## só, lido antes de escrito: salvar o idioma sem ler apagava a seção da tela, e vice-versa.
func _save_person_settings() -> void:
	var config := ConfigFile.new()
	config.load(Locales.SETTINGS_PATH)
	config.set_value("locale", "language", locale)
	config.set_value("locale", "confirmed", locale_confirmed)
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "ui_scale", ui_scale)
	config.set_value("display", "vsync_mode", vsync_mode)
	config.save(Locales.SETTINGS_PATH)

func _load_person_settings() -> void:
	var config := ConfigFile.new()
	if config.load(Locales.SETTINGS_PATH) != OK:
		return
	var saved := str(config.get_value("locale", "language", ""))
	if Locales.knows(saved):
		locale = saved
		locale_confirmed = bool(config.get_value("locale", "confirmed", false))
		_locale_from_settings = true
	if WINDOW_MODES.has(int(config.get_value("display", "window_mode", window_mode))):
		window_mode = int(config.get_value("display", "window_mode", window_mode))
	if UI_SCALES.has(float(config.get_value("display", "ui_scale", ui_scale))):
		ui_scale = float(config.get_value("display", "ui_scale", ui_scale))
	if VSYNC_MODES.has(int(config.get_value("display", "vsync_mode", vsync_mode))):
		vsync_mode = int(config.get_value("display", "vsync_mode", vsync_mode))

## O rótulo do botão de um produto que está na bancada. É aqui que quem joga olha para
## saber quanto falta, então o número tem de cair no ritmo do relógio do mundo e não no
## ritmo dos eventos: `_refresh_timed_ui()` reescreve só estes botões a cada quarto de
## segundo de mundo, enquanto `_refresh_ui()` continua desenhando o resto quando algo muda.
func _forge_button_label(index: int) -> String:
	var job := _craft_job_of(index)
	if job.is_empty():
		return "⏳ Na fila"
	var remaining := maxf(0.0, float(job.get("remaining", 0.0)) - _world_seconds_since_tick())
	var total := maxf(1.0, float(job.get("total", remaining)))
	var progress := clampf(1.0 - remaining / total, 0.0, 1.0)
	return "⏳ %s • %s" % [tr("Forjando %.1fs") % remaining, _bar(progress)]


## O trabalho em bancada de um produto, se ele estiver lá.
func _craft_job_of(index: int) -> Dictionary:
	for job in craft_jobs:
		if int(job.get("index", -1)) == index:
			return job
	return {}


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
	# O botão do produto é onde a pessoa olha; a faixa do topo é só o resumo da fila.
	for i in range(mini(craft_buttons.size(), products.size())):
		if not is_instance_valid(craft_buttons[i]):
			continue
		if _craft_job_of(i).is_empty():
			continue
		craft_buttons[i].text = _forge_button_label(i)
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
	# A decoração por faixa é desenhada na geometria da sala: mudou a sala, muda o
	# chão, muda o tapete.
	_stage_walkable = walkable
	if is_instance_valid(_progress_layer):
		_progress_layer.queue_redraw()
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

## O tempo que a rua faz hoje, e o preço de cada um deles: movimento na porta,
## paciência na fila e a etiqueta do produto que a cidade acordou querendo. A rolagem
## acontece uma vez por virada e consome sorteio sempre, então a mesma semente desenha
## a mesma sequência de dias — clima é consequência do calendário da loja, não enfeite
## de painel.
const WEATHER := {
	"limpo": {"name": "dia limpo", "crowd": 0, "patience": 0,
		"line": "A rua acordou limpa: movimento normal de calçada."},
	"chuva": {"name": "chuva fina", "crowd": -1, "patience": 1,
		"line": "Chove fino: menos gente passando, quem entra fica debaixo do toldo sem pressa."},
	"nevoa": {"name": "névoa preguiçosa", "crowd": -1, "patience": 1,
		"line": "Névoa na vitrine: quase ninguém vê a placa, quem vê entra devagar."},
	"tempestade": {"name": "tempestade", "crowd": -2, "patience": -1,
		"line": "Tempestade na rua: a porta abre pouco e quem entra quer resolver logo."},
	"calor": {"name": "calor de fundo de inferno", "crowd": 1, "patience": -1,
		"line": "Calor pesado: a fila cresce e a paciência encolhe junto com o nervo."},
	"feirao": {"name": "feira na praça", "crowd": 2, "patience": 0,
		"line": "Feira na praça: a calçada está cheia de bolso solto."},
}
const WEATHER_ORDER: Array[String] = ["limpo", "chuva", "nevoa", "tempestade", "calor", "feirao"]
## O produto do dia sai mais caro porque é atrás dele que a cidade acordou.
const WEATHER_STAR_PRICE := 1.25
var weather: String = "limpo"
var weather_star: String = ""
var weather_seen: Dictionary = {}

func _weather() -> Dictionary:
	return WEATHER.get(weather, WEATHER["limpo"])

## Sorteia o tempo da manhã e o produto que a rua quer. Os dois dados giram sempre, e o
## segundo aponta para a lista inteira, com ou sem prateleira: se o calendário
## dependesse do estoque de hoje, a mesma semente deixaria de render a mesma loja — e
## querer o que não tem é justamente o empurrão para fabricar.
func _roll_weather() -> void:
	weather = WEATHER_ORDER[randi() % WEATHER_ORDER.size()]
	weather_seen[weather] = true
	weather_star = str(products[randi() % products.size()]["id"])

## A linha que a manhã lê no mural: o tempo de hoje e a etiqueta que ele empurrou.
func _weather_line() -> String:
	var star := _product_name(weather_star)
	if star.is_empty():
		return "Tempo: %s." % str(_weather()["name"])
	return "Tempo: %s • a rua atrás de %s (+%d%% na etiqueta)." % [
		str(_weather()["name"]), star, int(round((WEATHER_STAR_PRICE - 1.0) * 100.0))]

## Nome de um produto pelo id, vazio quando o id não é da casa.
func _product_name(product_id: String) -> String:
	for item in products:
		if str(item["id"]) == product_id:
			return str(item["name"])
	return ""

## Quantos batem na porta neste tique: um sempre, mais um por degrau de fama, mais
## um para cada duas filiais abertas, menos o que as placas dos rivais levam da
## calçada. É o que faz a loja começar quase vazia e
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
	crowd += int(_weather()["crowd"])
	crowd -= _rival_crowd_loss()
	# Escândalo no livro de reclamações e um corpo a menos batendo na porta por tique,
	# mesmo na loja famosa: a rua que fala mal também segura gente em casa.
	crowd -= _complaint_crowd_loss()
	return clampi(crowd, 1, QUEUE_LIMIT)

## Quem está de placa acesa na praça hoje. A lista é lida do calendário da loja
## contra a tabela, sem sorteio e sem estado escondido: mesma semente, mesma rua.
func _rivals_active_ids() -> Array[String]:
	return Rivals.active_ids(shop_day, rivals_absorbed)

## O corpo que a rival bebe antes de ele chegar à porta é o corpo que passeia. Na
## feira a casa rival dobra a vez; com chuva, névoa ou tempestade ninguém passeia
## e ela leva metade. Fama de bairro já está descontada dentro da tabela.
func _rival_crowd_loss() -> int:
	var ids := _rivals_active_ids()
	if ids.is_empty():
		return 0
	var loss := Rivals.crowd_loss(ids, reputation)
	match weather:
		"feirao":
			loss *= 2
		"chuva", "nevoa", "tempestade":
			loss /= 2
	return loss

## Quanto do bolso já chegou gasto na placa do vizinho. O corte é aplicado no
## orçamento do freguês com piso, em vez de zerar quem já entrou pobre: a guerra
## aperta o balcão e empurra a casa a absorver a rival, não a fechar a loja.
func _rival_undercut() -> int:
	var ids := _rivals_active_ids()
	if ids.is_empty():
		return 0
	return Rivals.undercut(ids, reputation)

## O bolso que chega à loja: o orçamento do perfil, mais o que o ofício abre, menos
## o que a placa do vizinho já bebeu. Piso de 10 de propósito — quem chega com 42
## ainda leva a coisa de doze ouro da prateleira.
func _visit_budget(profile: Dictionary) -> int:
	return maxi(10, int(profile.get("budget", 50)) + trade_rank * 8 - _rival_undercut())

## Quanto um cliente topa esperar: o limite da casa mais a paciência do próprio
## perfil, o quanto a chefe já é querida, quantas mãos há no balcão e o tempo lá fora
## — debaixo de chuva ninguém olha no relógio, no calor todo mundo olha. Charme é
## literalmente tempo de espera, e contratar também é.
func _queue_patience(profile: Dictionary) -> int:
	return maxi(1, QUEUE_PATIENCE_TICKS + int(profile.get("patience", 2)) + charm_rank / 2 + staff_hired.size() + servants.size() - _mess_patience_loss() - _complaint_patience_loss() + int(_weather()["patience"]))

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
	# E o ritmo do balcão morre aqui: quem esperou demais e virou as costas leva a
	# sequência junto, porque combo é prêmio de quem deu conta, não de quem sorteou.
	_break_combo()
	# Quem espera na porta em pé sobre o próprio barro bate o pé no chão antes de
	# bater a porta: a fila suja e a sujeira atrasa a fila.
	_add_mess(MESS_PER_WALKOUT)
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

	# A camada da faixa de progresso fica entre o fundo pintado e as figuras: o
	# tapete no chão, as velas na parede e o lustre no teto são desenhados por
	# código, sobre a arte que a casa já tinha.
	_progress_layer = Control.new()
	_progress_layer.name = "ProgressDecor"
	_progress_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_progress_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_layer.z_index = -900
	_progress_layer.draw.connect(_draw_progress_decor)
	_progress_layer.resized.connect(_progress_layer.queue_redraw)
	add_child(_progress_layer)

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

	# O ☰ é o mesmo menu do ESC, e é a porta de entrada de tudo que antes estava
	# espalhado pelo topo: som, volume, ocultar o painel, salvar, relatar bug.
	menu_button = Button.new()
	menu_button.text = "☰"
	menu_button.tooltip_text = tr("Menu (ESC)")
	menu_button.custom_minimum_size = Vector2(52, 42)
	menu_button.pressed.connect(_open_menu.bind(false))
	header.add_child(menu_button)

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
	cold_storage_button = Button.new()
	cold_storage_button.custom_minimum_size = Vector2(820, 36)
	cold_storage_button.pressed.connect(_buy_cold_storage)
	forge_box.add_child(cold_storage_button)

	forge_box.add_child(_make_section_title("A BANCADA DE ENSAIOS", Color(0.78, 0.96, 0.60)))
	forge_box.add_child(_make_section_hint("Alquimia experimental: o atalho de ouro e ingrediente para a receita que o nível ainda prende. Ponha até %d unidades de no máximo %d espécies na mesa, acenda, e a bancada responde pela tabela — ou a mistura casa com uma receita travada, que aí passa a ser sua sem subir degrau e sem pagar a leitura, ou vira beco riscado no caderno. Beco riscado não se paga duas vezes, e o grimório vende a ficha de uma receita por vez." % [LAB_MAX_UNITS, LAB_MAX_KINDS]))
	var lab_card := _make_sector_card(Color(0.05, 0.075, 0.048, 0.94), Color(0.56, 0.82, 0.46, 0.95))
	forge_box.add_child(lab_card)
	var lab_row := HBoxContainer.new()
	lab_row.add_theme_constant_override("separation", 12)
	lab_card.add_child(lab_row)
	lab_label = Label.new()
	lab_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab_label.add_theme_font_size_override("font_size", 13)
	lab_label.add_theme_color_override("font_color", Color(0.86, 0.96, 0.78))
	lab_row.add_child(lab_label)
	var lab_side := VBoxContainer.new()
	lab_side.add_theme_constant_override("separation", 6)
	lab_row.add_child(lab_side)
	var lab_adds := HFlowContainer.new()
	lab_adds.add_theme_constant_override("h_separation", 6)
	lab_adds.add_theme_constant_override("v_separation", 6)
	lab_side.add_child(lab_adds)
	for ingredient in Ingredients.DATA:
		var add := Button.new()
		add.custom_minimum_size = Vector2(132, 34)
		add.add_theme_font_size_override("font_size", 12)
		add.pressed.connect(_lab_add.bind(str(ingredient["id"])))
		lab_adds.add_child(add)
		lab_add_buttons.append(add)
	var lab_actions := HBoxContainer.new()
	lab_actions.add_theme_constant_override("separation", 6)
	lab_side.add_child(lab_actions)
	lab_clear_button = Button.new()
	lab_clear_button.custom_minimum_size = Vector2(132, 40)
	lab_clear_button.add_theme_font_size_override("font_size", 13)
	lab_clear_button.pressed.connect(_lab_clear)
	lab_actions.add_child(lab_clear_button)
	lab_fire_button = Button.new()
	lab_fire_button.custom_minimum_size = Vector2(200, 40)
	lab_fire_button.add_theme_font_size_override("font_size", 14)
	lab_fire_button.pressed.connect(_lab_fire)
	lab_actions.add_child(lab_fire_button)
	lab_hint_button = Button.new()
	lab_hint_button.custom_minimum_size = Vector2(200, 40)
	lab_hint_button.add_theme_font_size_override("font_size", 13)
	lab_hint_button.pressed.connect(_lab_buy_hint)
	lab_actions.add_child(lab_hint_button)

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
	# A regra da casa mora ao lado de quem a paga: o painel que mostra a aura é o mesmo
	# que escolhe a dificuldade que multiplicou essa aura.
	difficulty_label = Label.new()
	difficulty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	difficulty_label.add_theme_font_size_override("font_size", 13)
	difficulty_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.96))
	prestige_box.add_child(difficulty_label)
	difficulty_button = Button.new()
	difficulty_button.custom_minimum_size = Vector2(320, 42)
	difficulty_button.add_theme_font_size_override("font_size", 14)
	difficulty_button.pressed.connect(_cycle_difficulty)
	prestige_box.add_child(difficulty_button)

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

	reception_box.add_child(_make_section_title("CONSERVA DA CASA E CELA", Color(0.86, 0.80, 1.0)))
	reception_box.add_child(_make_section_hint("Barro no chão é conta, não cenário: encurta a paciência da fila, derruba a etiqueta e chama vândalo para a porta. A criada varre por salário, o servo apaixonado varre por afeto e a chefe varre em ouro. Quem é pego com a mão na prateleira pode acabar na cela do santuário — que rende sangue para a forja e prato na conta da virada. O placar da casa também acende o salão: piso encerado, velas, caixilho dourado e lustre entram no palco conforme a loja sobe de faixa."))
	var house_card := _make_sector_card(Color(0.06, 0.05, 0.09, 0.94), Color(0.46, 0.42, 0.68, 0.95))
	reception_box.add_child(house_card)
	var house_row := HBoxContainer.new()
	house_row.add_theme_constant_override("separation", 12)
	house_card.add_child(house_row)
	var house_info := VBoxContainer.new()
	house_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	house_row.add_child(house_info)
	mess_label = Label.new()
	mess_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mess_label.add_theme_font_size_override("font_size", 15)
	mess_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.72))
	house_info.add_child(mess_label)
	cell_label = Label.new()
	cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cell_label.add_theme_font_size_override("font_size", 13)
	cell_label.add_theme_color_override("font_color", Color(0.82, 0.80, 0.96))
	house_info.add_child(cell_label)
	progress_label = Label.new()
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.60))
	house_info.add_child(progress_label)
	var house_buttons := VBoxContainer.new()
	house_buttons.add_theme_constant_override("separation", 8)
	house_row.add_child(house_buttons)
	sweep_button = Button.new()
	sweep_button.custom_minimum_size = Vector2(190, 40)
	sweep_button.add_theme_font_size_override("font_size", 14)
	sweep_button.text = "🧹 Varrer o salão"
	sweep_button.pressed.connect(_sweep_floor)
	house_buttons.add_child(sweep_button)
	release_button = Button.new()
	release_button.custom_minimum_size = Vector2(190, 40)
	release_button.add_theme_font_size_override("font_size", 14)
	release_button.text = "🕊 Soltar o mais velho"
	release_button.pressed.connect(_release_prisoner)
	house_buttons.add_child(release_button)
	deliver_button = Button.new()
	deliver_button.custom_minimum_size = Vector2(190, 40)
	deliver_button.add_theme_font_size_override("font_size", 14)
	deliver_button.text = "⚖ Entregar à guilda"
	deliver_button.pressed.connect(_deliver_prisoner)
	house_buttons.add_child(deliver_button)
	banish_button = Button.new()
	banish_button.custom_minimum_size = Vector2(190, 40)
	banish_button.add_theme_font_size_override("font_size", 14)
	banish_button.text = "🚪 Expulsar do bairro"
	banish_button.pressed.connect(_banish_prisoner)
	house_buttons.add_child(banish_button)

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

	reception_box.add_child(_make_section_title("A CONCORRÊNCIA DA PRAÇA", Color(1.0, 0.86, 0.60)))
	reception_box.add_child(_make_section_hint("A praça tem outras portas abertas, e cada placa acesa tira corpo da sua porta e ouro do bolso de quem entra. Nada aqui é sorteio: é a rua cobrando o seu preço. Fama de bairro segura metade do estrago, e a outra metade se cala comprando a placa — que encarece a cada virada de espera."))
	rival_summary_label = Label.new()
	rival_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rival_summary_label.add_theme_font_size_override("font_size", 14)
	rival_summary_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.76))
	reception_box.add_child(rival_summary_label)
	for rival in Rivals.DATA:
		var rival_card := _make_sector_card(Color(0.08, 0.07, 0.04, 0.94), Color(0.68, 0.56, 0.26, 0.95))
		reception_box.add_child(rival_card)
		var rival_row := HBoxContainer.new()
		rival_row.add_theme_constant_override("separation", 12)
		rival_card.add_child(rival_row)
		var rival_info := VBoxContainer.new()
		rival_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rival_row.add_child(rival_info)
		var rival_label := Label.new()
		rival_label.add_theme_font_size_override("font_size", 15)
		rival_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.80))
		rival_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rival_info.add_child(rival_label)
		rival_labels.append(rival_label)
		var rival_desc := Label.new()
		rival_desc.text = str(rival["desc"])
		rival_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rival_desc.add_theme_font_size_override("font_size", 12)
		rival_desc.add_theme_color_override("font_color", Color(0.78, 0.76, 0.66))
		rival_info.add_child(rival_desc)
		var rival_button := Button.new()
		rival_button.custom_minimum_size = Vector2(170, 40)
		rival_button.add_theme_font_size_override("font_size", 14)
		rival_button.pressed.connect(_absorb_rival.bind(str(rival["id"])))
		rival_row.add_child(rival_button)
		rival_buttons.append(rival_button)

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

	reception_box.add_child(_make_section_title("O LIVRO DE FIADO", Color(0.95, 0.80, 0.55)))
	reception_box.add_child(_make_section_hint("Fiado é nome, não moeda: a casa só anota para quem já é freguês de casa, e o ouro da venda fica na rua até a cobrança — que pode não voltar. Cada degrau abre teto, páginas e prazo; a nota riscada no terceiro dia de atraso custa reputação e vínculo, e a conta da casa chega igualmente na virada."))
	var credit_card := _make_sector_card(Color(0.08, 0.05, 0.045, 0.94), Color(0.86, 0.66, 0.34, 0.95))
	reception_box.add_child(credit_card)
	var credit_hrow := HBoxContainer.new()
	credit_hrow.add_theme_constant_override("separation", 12)
	credit_card.add_child(credit_hrow)
	credit_label = Label.new()
	credit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credit_label.add_theme_font_size_override("font_size", 13)
	credit_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.62))
	credit_hrow.add_child(credit_label)
	credit_button = Button.new()
	credit_button.custom_minimum_size = Vector2(190, 44)
	credit_button.add_theme_font_size_override("font_size", 14)
	credit_button.pressed.connect(_buy_credit_rank)
	credit_hrow.add_child(credit_button)

	reception_box.add_child(_make_section_title("O SALÃO DAS CAPAS FINAS", Color(0.82, 0.70, 0.96)))
	reception_box.add_child(_make_section_hint("Cordão de veludo é escada de três degraus: cada degrau traz mais visitas de capa fina, com bolso maior, tempo próprio e a exigência de levar o topo da barra de qualidade. Quando a estante não tem o degrau que elas aceitam, elas devolvem a peça na prateleira e a fama paga a fofoca — a recusa não queima estoque e não cobra sorteio."))
	var vip_card := _make_sector_card(Color(0.055, 0.045, 0.075, 0.94), Color(0.62, 0.50, 0.86, 0.95))
	reception_box.add_child(vip_card)
	var vip_hrow := HBoxContainer.new()
	vip_hrow.add_theme_constant_override("separation", 12)
	vip_card.add_child(vip_hrow)
	vip_label = Label.new()
	vip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vip_label.add_theme_font_size_override("font_size", 13)
	vip_label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.96))
	vip_hrow.add_child(vip_label)
	vip_button = Button.new()
	vip_button.custom_minimum_size = Vector2(190, 44)
	vip_button.add_theme_font_size_override("font_size", 14)
	vip_button.pressed.connect(_buy_vip_rank)
	vip_hrow.add_child(vip_button)

	reception_box.add_child(_make_section_title("O LIVRO DE RECLAMAÇÕES DA RUA", Color(1.0, 0.66, 0.52)))
	reception_box.add_child(_make_section_hint("Fama alta não quer dizer bemquista: a rua conta as vezes em que a casa errou — a peça torto que saiu da forja, a capa fina devolvida na prateleira, a nota riscada no fiado. Sexta linha em diante a etiqueta encolhe e a fila emagrece; da décima segunda, um corpo a menos bate na porta a cada tique. Uma linha se apaga a cada virada, e a voz da rua tem preço."))
	var complaint_card := _make_sector_card(Color(0.075, 0.04, 0.038, 0.94), Color(0.88, 0.52, 0.40, 0.95))
	reception_box.add_child(complaint_card)
	var complaint_hrow := HBoxContainer.new()
	complaint_hrow.add_theme_constant_override("separation", 12)
	complaint_card.add_child(complaint_hrow)
	complaint_label = Label.new()
	complaint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	complaint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	complaint_label.add_theme_font_size_override("font_size", 13)
	complaint_label.add_theme_color_override("font_color", Color(0.96, 0.80, 0.72))
	complaint_hrow.add_child(complaint_label)
	complaint_button = Button.new()
	complaint_button.custom_minimum_size = Vector2(190, 44)
	complaint_button.add_theme_font_size_override("font_size", 14)
	complaint_button.pressed.connect(_hush_street)
	complaint_hrow.add_child(complaint_button)

	reception_box.add_child(_make_section_title("O CARTAZ DO COMBO", Color(1.0, 0.78, 0.45)))
	reception_box.add_child(_make_section_hint("Venda puxa venda: três degraus de cartaz pagam a sequência do mesmo dia, e a sequência morre na visita que sai sem comprar e na virada da manhã. Com o cartaz guardado o balcão continua contando a sequência para si — sem pagar um centavo por ela, exatamente como sempre contou."))
	var combo_card := _make_sector_card(Color(0.075, 0.05, 0.03, 0.94), Color(0.92, 0.66, 0.34, 0.95))
	reception_box.add_child(combo_card)
	var combo_hrow := HBoxContainer.new()
	combo_hrow.add_theme_constant_override("separation", 12)
	combo_card.add_child(combo_hrow)
	combo_label = Label.new()
	combo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combo_label.add_theme_font_size_override("font_size", 13)
	combo_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.70))
	combo_hrow.add_child(combo_label)
	combo_button = Button.new()
	combo_button.custom_minimum_size = Vector2(190, 44)
	combo_button.add_theme_font_size_override("font_size", 14)
	combo_button.pressed.connect(_buy_combo_rank)
	combo_hrow.add_child(combo_button)

	reception_box.add_child(_make_section_title("A PORTA DA CASA", Color(0.62, 0.86, 1.0)))
	reception_box.add_child(_make_section_hint("Loja que dá lucro tem alvo na porta. Cada visita é resolvida com a mão que a casa já tem: a ronda da folha, os servos do salão, os batedores do cadastro, o santuário reformado e a Administração. O vigário passa na frente para cobrar — dízimo, suborno ou porta na cara dele, e as três respostas têm preço."))
	defense_label = Label.new()
	defense_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	defense_label.add_theme_font_size_override("font_size", 14)
	defense_label.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	reception_box.add_child(defense_label)
	var vicar_row := HBoxContainer.new()
	vicar_row.add_theme_constant_override("separation", 12)
	reception_box.add_child(vicar_row)
	vicar_label = Label.new()
	vicar_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vicar_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vicar_label.add_theme_font_size_override("font_size", 13)
	vicar_label.add_theme_color_override("font_color", Color(0.90, 0.84, 0.70))
	vicar_row.add_child(vicar_label)
	tithe_button = Button.new()
	tithe_button.custom_minimum_size = Vector2(148, 40)
	tithe_button.add_theme_font_size_override("font_size", 13)
	tithe_button.pressed.connect(_answer_vicar.bind("dizimo"))
	vicar_row.add_child(tithe_button)
	bribe_button = Button.new()
	bribe_button.custom_minimum_size = Vector2(148, 40)
	bribe_button.add_theme_font_size_override("font_size", 13)
	bribe_button.pressed.connect(_answer_vicar.bind("suborno"))
	vicar_row.add_child(bribe_button)
	refuse_button = Button.new()
	refuse_button.custom_minimum_size = Vector2(148, 40)
	refuse_button.add_theme_font_size_override("font_size", 13)
	refuse_button.pressed.connect(_answer_vicar.bind("recusa"))
	vicar_row.add_child(refuse_button)
	invasion_label = Label.new()
	invasion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	invasion_label.add_theme_font_size_override("font_size", 12)
	invasion_label.add_theme_color_override("font_color", Color(0.78, 0.80, 0.90))
	reception_box.add_child(invasion_label)
	defense_lines_label = Label.new()
	defense_lines_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	defense_lines_label.add_theme_font_size_override("font_size", 12)
	defense_lines_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.88))
	reception_box.add_child(defense_lines_label)

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
	expedition_box.add_child(_make_section_hint("O mercado não vende raridade. Cada viagem custa ouro, leva dias de loja e só volta com o que a sorte deixar — e a sorte agora tem nome: o batedor mais capaz do cadastro desce do balcão com a passagem."))

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
		var pick_button := Button.new()
		pick_button.custom_minimum_size = Vector2(150, 44)
		pick_button.add_theme_font_size_override("font_size", 12)
		pick_button.pressed.connect(_cycle_route_pick.bind(destination_id))
		trip_row.add_child(pick_button)
		expedition_pick_buttons.append(pick_button)

	expedition_box.add_child(_make_section_title("CADASTRO DE BATEDORES", Color(0.55, 0.95, 0.7)))
	expedition_box.add_child(_make_section_hint("Gente com nome na estrada: taxa uma vez, cachê por viagem e nível que só a rota percorrida dá. O mais capaz do cadastro é quem parte, a menos que a loja escolha outro — e o que ele leva na mochila sai do estoque que o balcão venderia."))
	adventurer_summary_label = Label.new()
	adventurer_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	adventurer_summary_label.add_theme_font_size_override("font_size", 14)
	adventurer_summary_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.88))
	expedition_box.add_child(adventurer_summary_label)
	for candidate in Adventurers.DATA:
		var adv_card := _make_sector_card(Color(0.045, 0.07, 0.06, 0.94), Color(0.42, 0.72, 0.52, 0.95))
		expedition_box.add_child(adv_card)
		var adv_row := HBoxContainer.new()
		adv_row.add_theme_constant_override("separation", 12)
		adv_card.add_child(adv_row)
		var adv_info := VBoxContainer.new()
		adv_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		adv_row.add_child(adv_info)
		var adv_label := Label.new()
		adv_label.add_theme_font_size_override("font_size", 15)
		adv_label.add_theme_color_override("font_color", Color(0.92, 0.98, 0.92))
		adv_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		adv_info.add_child(adv_label)
		adventurer_labels.append(adv_label)
		var adv_bg := Label.new()
		adv_bg.text = str(candidate["bg"])
		adv_bg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		adv_bg.add_theme_font_size_override("font_size", 12)
		adv_bg.add_theme_color_override("font_color", Color(0.70, 0.76, 0.72))
		adv_info.add_child(adv_bg)
		var adv_does := Label.new()
		adv_does.text = str(candidate["does"])
		adv_does.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		adv_does.add_theme_font_size_override("font_size", 12)
		adv_does.add_theme_color_override("font_color", Color(0.86, 0.82, 0.62))
		adv_info.add_child(adv_does)
		var adv_button := Button.new()
		adv_button.custom_minimum_size = Vector2(170, 40)
		adv_button.add_theme_font_size_override("font_size", 14)
		adv_button.pressed.connect(_manage_adventurer.bind(str(candidate["id"])))
		adv_row.add_child(adv_button)
		adventurer_buttons.append(adv_button)
	pack_gear_button = Button.new()
	pack_gear_button.custom_minimum_size = Vector2(260, 42)
	pack_gear_button.add_theme_font_size_override("font_size", 14)
	pack_gear_button.pressed.connect(_toggle_pack_gear)
	expedition_box.add_child(pack_gear_button)

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
	# A trilha segue a sala e a rua: a mesma gravação, afinada pelo setor, pela visita
	# que acabou de bater na porta e pela conta que a casa deve.
	_apply_situation_music()
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

## A cena da recepção. `intensidade` (0 a 1) é o degrau da escada de momentos: quanto
## mais alto, mais ela se aproxima, mais quente fica o retrato e mais tempo ela segura
## antes de voltar para o balcão. Não muda economia nem porta — é só a respiração.
func _play_sensual_reception_moment(intensidade: float = 0.0) -> void:
	if not adult_content_enabled or not is_instance_valid(seller_portrait):
		return
	var peso := clampf(intensidade, 0.0, 1.0)
	_seller_lean_in()
	_show_stage_emotion(stage_seller_body, "ousadia")
	if sensual_tween != null and sensual_tween.is_valid():
		sensual_tween.kill()
	seller_portrait.pivot_offset = seller_portrait.size / 2.0
	sensual_tween = create_tween()
	sensual_tween.tween_property(seller_portrait, "scale", Vector2.ONE * lerpf(1.07, 1.14, peso), 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sensual_tween.tween_property(seller_portrait, "modulate", Color(1.0, lerpf(0.82, 0.72, peso), lerpf(0.95, 0.90, peso), 1.0), 0.32)
	sensual_tween.tween_interval(lerpf(1.6, 2.4, peso))
	sensual_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	sensual_tween.tween_property(seller_portrait, "modulate", Color.WHITE, 0.42)

func _play_seduction_peak_pose() -> void:
	if adult_content_enabled and is_instance_valid(seller_portrait):
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
	# O medidor cheio paga igual nos dois modos: o interruptor segura a pose desenhada
	# na tela, nunca o degrau, o XP ou o momento que entra no placar da casa.
	if adult_content_enabled:
		last_event = "MEDIDOR DE SEDUÇÃO CHEIO! A chefe sobe no balcão por um instante: “Agora você entende por que ninguém sai daqui pensando direito.”"
	else:
		last_event = "MEDIDOR DE CONFIANÇA CHEIO! A chefe abre o caderno da casa na sua frente: “Agora você entende por que ninguém fecha a conta daqui sem voltar.”"
	private_moments_unlocked += 1
	reputation += 3
	_add_xp(15)
	audio.play("talent")
	if adult_content_enabled:
		_show_feedback("♥ Pose especial desbloqueada!", Color(1.0, 0.62, 0.88))
	else:
		_show_feedback("♥ Confiança da casa conquistada!", Color(1.0, 0.62, 0.88))

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
	music_player.volume_db = music_base_db
	add_child(music_player)
	music_player.play()
	_apply_situation_music()

func _apply_music_settings() -> void:
	if is_instance_valid(music_player):
		music_player.stream_paused = audio.muted
		music_player.volume_db = music_base_db + linear_to_db(maxf(audio.volume, 0.0001))

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
	craft_jobs.append({"index": index, "remaining": maxf(3.0, duration), "total": maxf(3.0, duration), "luck": job_luck})
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

## Sorte da viagem: a da casa, mais a mão de quem partiu. O número da bota é o que
## estava congelado na hora em que a porta bateu — a loja pode crescer enquanto o
## batedor anda, e a mala responde pelo nível que saiu, não pelo que a casa virou.
func _trip_luck(trip: Dictionary) -> int:
	return _expedition_luck() + int(trip.get("skill", 0))

func _adventurer_xp(id: String) -> int:
	return int(adventurer_xp.get(id, 0))

## O cadastro entra na régua da casa: vaga ocupada vale menos que estrada pisada,
## porque nível é tempo de viagem, não ouro gasto na entrada.
func _adventurer_score() -> int:
	var learned := 0
	for id in adventurer_xp.keys():
		learned += int(adventurer_xp.get(id, 0))
	return adventurers_hired.size() * 40 + learned * 6

## O degrau mais alto que a casa já teve no cadastro. Só quem está com contrato
## aberto conta: dispensado volta à rua, e a conquista é da casa, não da pessoa.
func _adventurer_top_level() -> int:
	var top := 0
	for hired in adventurers_hired:
		top = maxi(top, Adventurers.level_of(_adventurer_xp(str(hired))))
	return top

func _adventurer_on_road(id: String) -> bool:
	for trip in expeditions:
		if str(trip.get("who", "")) == id:
			return true
	return false

## Quem está no cadastro e com as botas livres.
func _free_adventurers() -> Array[String]:
	var free: Array[String] = []
	for hired in adventurers_hired:
		var id := str(hired)
		if _adventurer_on_road(id) or Adventurers.find(id).is_empty():
			continue
		free.append(id)
	return free

## A peça que a mochila leva: a melhor do gosto dele que ainda está na prateleira.
## Sem mochila armada, sem peça, sem bônus — a escolha é do balcão.
func _packable_gear(candidate: Dictionary) -> Dictionary:
	var gear_id := str(candidate.get("gear", ""))
	if gear_id.is_empty() or not pack_gear:
		return {}
	for i in range(products.size()):
		if str(products[i]["id"]) != gear_id:
			continue
		var counts := _quality_for(gear_id)
		for tier in range(Quality.size() - 1, -1, -1):
			if int(counts[tier]) > 0:
				return {"index": i, "tier": tier, "id": gear_id, "name": str(products[i]["name"])}
	return {}

## O nome que parte: o roteiro pode ter teimosia escrita à mão, e sem teimosia vai
## o mais capaz. Ninguém no cadastro é o batedor anônimo de sempre — sem bônus, sem
## memória, sem cachê.
func _pick_adventurer(route_id: String) -> Dictionary:
	var free := _free_adventurers()
	if free.is_empty():
		return {}
	var chosen := ""
	var named := str(route_pick.get(route_id, ""))
	if named != "" and free.has(named):
		chosen = named
	else:
		var best := -1
		for id in free:
			var seat := Adventurers.find(id)
			var skill := Adventurers.skill_of(seat, _adventurer_xp(id), route_id, -1)
			if skill > best:
				best = skill
				chosen = id
	if chosen.is_empty():
		return {}
	var candidate := Adventurers.find(chosen)
	var gear := _packable_gear(candidate)
	return {
		"id": chosen,
		"name": str(candidate["name"]),
		"level": Adventurers.level_of(_adventurer_xp(chosen)),
		"fee": Adventurers.fee_for(candidate),
		"gear": int(gear.get("tier", -1)),
		"gear_index": int(gear.get("index", -1)),
		"gear_name": str(gear.get("name", "")),
		"skill": Adventurers.skill_of(candidate, _adventurer_xp(chosen), route_id, int(gear.get("tier", -1))),
	}

## Nome da peça que a pessoa exige levar, para o cadastro e para o diário.
func _gear_label(candidate: Dictionary) -> String:
	var gear_id := str(candidate.get("gear", ""))
	if gear_id.is_empty():
		return "mochila vazia"
	for item in products:
		if str(item["id"]) == gear_id:
			return str(item["name"])
	return gear_id

func _adventurer_gate_state() -> Dictionary:
	return {
		"day": shop_day,
		"trips": expeditions_done,
		"rep": reputation,
		"rank": logistics_rank,
	}

## O mesmo botão serve para entrar e sair do cadastro. A estrada lembra do que
## ensinou: quem volta mais tarde não recomeça no zero, porque o nível é memória de
## viagem, não vaga paga.
func _manage_adventurer(id: String) -> void:
	var candidate := Adventurers.find(id)
	if candidate.is_empty():
		return
	if adventurers_hired.has(id):
		if _adventurer_on_road(id):
			last_event = "%s está na estrada. Dispensa se faz na volta da mala." % str(candidate["name"])
			audio.play("sad")
			_refresh_ui()
			return
		adventurers_hired.erase(id)
		last_event = "%s voltou para a rua. O que a estrada lhe ensinou fica no caderno." % str(candidate["name"])
		audio.play("click")
		_show_feedback("✕ %s fora do cadastro." % str(candidate["name"]), Color(0.80, 0.86, 0.78))
		_check_achievements()
		_save_game()
		_refresh_ui()
		return
	var blocked := Adventurers.gate(candidate, _adventurer_gate_state())
	if blocked != "":
		last_event = "%s não assina hoje: %s." % [str(candidate["name"]), blocked]
		audio.play("sad")
		_refresh_ui()
		return
	var fee := int(candidate["hire"])
	if gold < fee:
		last_event = "%s pede %d de ouro na entrada. Faltam %d, e estrada não se paga com promessa." % [
			str(candidate["name"]), fee, fee - gold]
		audio.play("sad")
		_refresh_ui()
		return
	gold -= fee
	adventurers_hired.append(id)
	last_event = "%s entrou no cadastro: %d de taxa, %d de cachê por viagem, e %s na mochila quando a prateleira tiver." % [
		str(candidate["name"]), fee, int(candidate["fee"]), _gear_label(candidate)]
	audio.play("levelup")
	_show_feedback("✦ %s no cadastro." % str(candidate["name"]), Color(0.55, 0.95, 0.7))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Teimosia do roteiro: quem a loja quer ver subir de nível. Ciclo livre do cadastro,
## e o último passo volta para "manda o mais capaz".
func _cycle_route_pick(route_id: String) -> void:
	var candidates: Array[String] = [""]
	for hired in adventurers_hired:
		var id := str(hired)
		if not Adventurers.find(id).is_empty():
			candidates.append(id)
	var now := str(route_pick.get(route_id, ""))
	var step := candidates.find(now)
	route_pick[route_id] = candidates[(step + 1) % candidates.size()]
	var label := "o mais capaz" if str(route_pick[route_id]) == "" else str(Adventurers.find(str(route_pick[route_id]))["name"])
	last_event = "Roteiro anotado: %s manda %s." % [str(Expedition.find(route_id)["name"]), label]
	audio.play("click")
	_save_game()
	_refresh_ui()

func _toggle_pack_gear() -> void:
	pack_gear = not pack_gear
	last_event = "Mochila %s: a melhor peça do gosto deles sai da prateleira e vai na viagem." % (
		"armada" if pack_gear else "guardada")
	audio.play("click")
	_save_game()
	_refresh_ui()

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
	var safe_return := 100 - Expedition.mishap_chance(destination, _trip_luck(trip))
	return "%s [%s] %d%% • %s • %s • retorno sem contratempo: %d%%" % [
		str(destination.get("name", "?")),
		_bar(progress),
		int(round(progress * 100.0)),
		_party_label(trip),
		Expedition.journey_event(destination, progress),
		safe_return,
	]

## Quem partiu, no nível em que partiu, com a mochila que levou. É a frase que o
## painel lê a cada segundo de relógio, então o número ali é sempre o congelado na
## saída — o que a casa virou depois não muda a aposta de quem já na estrada.
func _party_label(trip: Dictionary) -> String:
	var who := str(trip.get("who", ""))
	if who.is_empty():
		return "batedor anônimo (+0)"
	var seat := Adventurers.find(who)
	if seat.is_empty():
		return "batedor sem nome (+%d)" % int(trip.get("skill", 0))
	var pack := " e %s" % str(trip.get("gear_name", "")) if int(trip.get("gear", -1)) >= 0 else ""
	return "%s Nv.%d (+%d)%s" % [str(seat["name"]), int(trip.get("level", 1)), int(trip.get("skill", 0)), pack]

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
	var runner := _pick_adventurer(id)
	var fee := int(runner.get("fee", 0))
	if gold < cost + fee:
		last_event = "A passagem custa %d ouro%s. Sem adiantamento o batedor nem calça a bota." % [
			cost, " e %s pede %d de cachê" % [str(runner["name"]), fee] if not runner.is_empty() else ""]
		_refresh_ui()
		return
	gold -= cost + fee
	var duration := _expedition_duration(destination)
	var trip := {
		"id": id,
		"remaining": duration,
		"total": duration,
		"who": str(runner.get("id", "")),
		"level": int(runner.get("level", 1)),
		"skill": int(runner.get("skill", 0)),
		"gear": int(runner.get("gear", -1)),
		"gear_name": str(runner.get("gear_name", "")),
	}
	if int(trip["gear"]) >= 0:
		_take_piece(int(runner["gear_index"]), Quality.BEST)
		gear_packed += 1
	expeditions.append(trip)
	if runner.is_empty():
		last_event = "%s partiu com %d ouro de passagem e volta em %s." % [destination["name"], cost, Expedition.days_label(duration)]
	else:
		last_event = "%s (Nv.%d, sorte +%d) partiu por %s: %d de passagem e %d de cachê%s. Volta em %s." % [
			str(runner["name"]), int(runner["level"]), int(runner["skill"]), str(destination["name"]),
			cost, fee, ", mochila com %s" % str(runner["gear_name"]) if int(trip["gear"]) >= 0 else "",
			Expedition.days_label(duration)]
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
	var luck := _trip_luck(entry)
	var loot := Expedition.roll_loot(destination, luck)
	var pieces := loot.size()
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
	## A mochila é despesa de viagem, não empréstimo: a peça foi embora com quem a
	## levou, e uma mala perdida leva junto o que o balcão venderia.
	if int(entry.get("gear", -1)) >= 0:
		text += " %s ficou na estrada com quem a levou." % str(entry.get("gear_name", "a peça"))
	## O único degrau que a loja não compra: XP de rota. Estrada difícil ensina mais,
	## e voltar inteiro ensina o que o contratempo não deixa aprender.
	var who := str(entry.get("who", ""))
	if not who.is_empty() and Adventurers.knows(who):
		var seat := Adventurers.find(who)
		var gained := Adventurers.mission_xp(destination, mishap.is_empty(), pieces)
		var before := Adventurers.level_of(_adventurer_xp(who))
		var xp := _adventurer_xp(who) + gained
		adventurer_xp[who] = xp
		var after := Adventurers.level_of(xp)
		if after > before:
			text += " %s subiu ao Nv.%d e passou a cobrar %d por viagem." % [
				str(seat["name"]), after, Adventurers.fee_for(seat, xp)]
			if not offline:
				audio.play("levelup")
				_show_feedback("⚔ %s Nv.%d." % [str(seat["name"]), after], Color(0.55, 0.95, 0.7))
		else:
			text += " %s voltou com %d XP de rota." % [str(seat["name"]), gained]
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
	if _shelf_life(index) > 0:
		_batches_for(str(item["id"])).append({"tier": tier, "day": shop_day})

## Quantos dias de balcão a peça aguenta antes de começar a virar. Zero quer dizer
## "não vence": lâmina, pergaminho e caixa vazia não apodrecem. O depósito de sal
## soma uma validade inteira por nível, então o prazo cresce sem mexer em preço.
func _shelf_life(index: int) -> int:
	var days := int(products[index].get("validade", 0))
	if days <= 0:
		return 0
	return days * (1 + cold_storage_level)

func _batches_for(product_id: String) -> Array:
	var stored = shelf_batches.get(product_id, null)
	if stored is Array:
		return stored
	var fresh: Array = []
	shelf_batches[product_id] = fresh
	return fresh

## A prateleira e o registro de idade têm de bater antes de a virada cobrar: peça
## que chegou por save antigo, migração ou carga avulso entra como recém-posta no
## degrau dela, e sobra de registro sem peça correspondente é podada. Sem isso uma
## peça órfã apodrecia sozinha, uma peça real nunca estragava, ou — pior —
## a virada re-escrevia o estoque e derrubava o nível de quem só estava guardado.
func _reconcile_batches(index: int) -> void:
	var product_id := str(products[index]["id"])
	var life := _shelf_life(index)
	var batches := _batches_for(product_id)
	if life <= 0:
		batches.clear()
		return
	var counts := _quality_for(product_id)
	var tracked := Quality.empty_stock()
	for batch in batches:
		var tier := clampi(int(batch["tier"]), 0, Quality.size() - 1)
		batch["tier"] = tier
		tracked[tier] = int(tracked[tier]) + 1
	for tier in range(Quality.size()):
		var missing := int(counts[tier]) - int(tracked[tier])
		for _added in range(maxi(0, missing)):
			batches.append({"tier": tier, "day": shop_day})
		var extra := int(tracked[tier]) - int(counts[tier])
		for _cut in range(maxi(0, extra)):
			for position in range(batches.size()):
				if int(batches[position]["tier"]) == tier:
					batches.remove_at(position)
					break

## Vence é descer um degrau, não sumir: a peça mais antiga da prateleira perde uma
## casa de qualidade, e a que já está no fundo sai pela porta. Sem sorteio nenhum,
## porque a mesma semente tem de fechar o mesmo estoque. Devolve quanto virou e
## quanto se perdeu para o balanço da manhã poder contar.
func _age_shelf() -> Dictionary:
	var turned := 0
	var lost := 0
	for index in range(products.size()):
		var life := _shelf_life(index)
		if life <= 0:
			continue
		var product_id := str(products[index]["id"])
		_reconcile_batches(index)
		var batches := _batches_for(product_id)
		var kept: Array = []
		for batch in batches:
			if shop_day - int(batch["day"]) < life:
				kept.append(batch)
				continue
			turned += 1
			var tier := int(batch["tier"])
			if tier <= 0:
				lost += 1
				continue
			batch["tier"] = tier - 1
			batch["day"] = shop_day
			kept.append(batch)
		batches.assign(kept)
		var counts := _quality_for(product_id)
		for tier in range(Quality.size()):
			counts[tier] = 0
		for batch in batches:
			var tier := int(batch["tier"])
			counts[tier] = int(counts[tier]) + 1
		products[index]["stock"] = Quality.total(counts)
	return {"turned": turned, "lost": lost}

## Quantos dias faltam para a peça mais antiga da prateleira começar a virar.
func _shelf_countdown(index: int) -> int:
	var life := _shelf_life(index)
	if life <= 0:
		return 0
	var product_id := str(products[index]["id"])
	var batches := _batches_for(product_id)
	if batches.is_empty():
		return life
	var oldest := shop_day
	for batch in batches:
		oldest = mini(oldest, int(batch["day"]))
	return clampi(life - (shop_day - oldest), 0, life)

## A linha de prazo que a forja mostra embaixo da peça. Prateleira vazia não vence
## nada, e o que não tem validade ganha o ∞ para a lista ter leitura igual.
func _shelf_marker(index: int) -> String:
	var life := _shelf_life(index)
	if life <= 0:
		return "∞ Não vence"
	if int(products[index]["stock"]) <= 0:
		return "⏳ %d dias de prazo • nada vencendo na prateleira vazia" % life
	var dias := _shelf_countdown(index)
	if dias <= 1:
		return "⏳ Vira HOJE: a peça mais antiga desce um degrau"
	return "⏳ Vence em %d dias de balcão" % dias

## O depósito de sal é compra de vida, como a biblioteca e o santuário: cada nível
## soma uma validade inteira ao relógio da prateleira. Não mexe em preço, sorte nem
## porta — só no prazo, que é justamente o que a ruína de quem esquece a poção
## na estante cobra.
func _cold_storage_cost() -> int:
	return 120 + cold_storage_level * 180

func _buy_cold_storage() -> void:
	if cold_storage_level >= 3:
		last_event = "Três baús de sal é o que a casa guarda. Mais que isso, poção velha vira história de balcão."
		audio.play("click")
		_refresh_ui()
		return
	var cost := _cold_storage_cost()
	if gold < cost:
		last_event = "Depósito de sal Nv.%d custa %d ouro. O sal é barato; a porta com chave, não." % [
			cold_storage_level + 1, cost]
		audio.play("sad")
		_refresh_ui()
		return
	gold -= cost
	cold_storage_level += 1
	reputation += 1
	_add_xp(10)
	if cold_storage_level == 1:
		last_event = "Primeiro baú de sal no fundo da forja: toda mercadoria perecível agora tem o dobro de prazo na prateleira."
	elif cold_storage_level == 2:
		last_event = "Segundo baú: a despensa respira três validades antes de a primeira peça descer de degrau."
	else:
		last_event = "Depósito cheio. A chefe tranca a porta e joga a chave no bolso: “Agora o que vence aqui é porque eu deixei.”"
	_check_achievements()
	_save_game()
	_refresh_ui()

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
	var product_id := str(item["id"])
	var stock := _quality_for(product_id)
	var tier := Quality.take(stock, mode)
	if tier >= 0 and _shelf_life(index) > 0:
		# Saiu pela porta, sai também da idade: a mais antiga daquele degrau, que é
		# justamente a que o balcão empurra primeiro. A ordem do registro não garante
		# idade — peça que desceu de degrau na virada mantém o lugar que tinha na lista
		# e reescreve o dia — então quem manda é o dia, não a posição.
		var batches := _batches_for(product_id)
		var pick := -1
		var oldest := 0
		for position in range(batches.size()):
			if int(batches[position]["tier"]) != tier:
				continue
			var day := int(batches[position]["day"])
			if pick < 0 or day < oldest:
				pick = position
				oldest = day
		if pick >= 0:
			batches.remove_at(pick)
	return 1 if tier < 0 else tier

## Peça que sai pela porta é peça entregue: só ela conta para a etapa Lendária da
## encomenda exclusiva. O ladrão que leva a melhor do estoque não conta — a
## rainha quer ver a nota fiscal.
func _register_sold_piece(tier: int) -> void:
	if tier != Quality.LEGENDARY:
		return
	legendary_sold += 1
	_progress_commission("legendary", 1)

## Etiqueta da peça: preço base do catálogo, nível de qualidade e a regra da casa. É o
## único lugar onde o preço nasce, então vitrine, balcão e margem estimada escalam
## juntas — e no Calçada o fator é 1.0, o que deixa toda medida antiga de pé.
func _piece_price(item: Dictionary, tier: int) -> float:
	return float(item["price"]) * float(Quality.tier(tier)["mult"]) * _difficulty_price_factor()

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

## O mercado reativo sobre a etiqueta: demanda do produto, escassez na prateleira e o
## produto que a rua acordou querendo hoje.
func _market_product_factor(item: Dictionary) -> float:
	var product_id := str(item["id"])
	return Economy.factor(economy_state, "product", product_id) * Economy.stock_factor(int(item["stock"])) * (
		WEATHER_STAR_PRICE if product_id == weather_star else 1.0)

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

## ── A BANCADA DE ENSAIOS ──────────────────────────────────────────────────────────
## Alquimia experimental: o atalho de ouro e ingrediente para a receita que o nível
## ainda prende. Nada aqui sorteia — a resposta é a tabela de receitas contra a mistura
## da mesa —, então a bancada pode ser lida e escrita no meio de uma corrida sem mover
## um `randi()` da loja.

## Assinatura canônica: "id:unidades" em ordem de id, para que sal+pó e pó+sal sejam o
## mesmo ensaio. A bancada não cobra duas contas pelo mesmo punhado.
func _lab_signature(mix: Dictionary) -> String:
	var ids: Array[String] = []
	for ingredient_id in mix.keys():
		if int(mix[ingredient_id]) > 0:
			ids.append(str(ingredient_id))
	ids.sort()
	var parts: Array[String] = []
	for ingredient_id in ids:
		parts.append("%s:%d" % [ingredient_id, int(mix[ingredient_id])])
	return "+".join(parts)

## Assinatura assinada: aceita só id de ingrediente do mercado e quantidade inteira
## positiva. É a tesoura do load: arquivo podre não entra na bancada.
func _lab_signature_valid(signature: String) -> bool:
	if signature.is_empty():
		return false
	for chunk in signature.split("+"):
		var bits := str(chunk).split(":")
		if bits.size() != 2:
			return false
		if Ingredients.find(str(bits[0])).is_empty():
			return false
		if int(bits[1]) <= 0:
			return false
	return true

## Nome de bancada para a assinatura: "Sal Gamer Refinado×1 + Pó Lunar de Terça-feira×1".
func _lab_readable(signature: String) -> String:
	if signature.is_empty():
		return "nada"
	var parts: Array[String] = []
	for chunk in signature.split("+"):
		var bits := str(chunk).split(":")
		if bits.size() != 2:
			continue
		parts.append("%s×%d" % [Ingredients.any_name(str(bits[0])), int(bits[1])])
	return " + ".join(parts)

func _lab_units(mix: Dictionary) -> int:
	var units := 0
	for ingredient_id in mix.keys():
		units += maxi(0, int(mix[ingredient_id]))
	return units

## Carvão do ensaio: ouro por unidade na brasa, além do ingrediente que ele queima.
func _lab_fee(units: int) -> int:
	return maxi(0, units * LAB_FEE_PER_UNIT)

## Receitas ainda presas ao nível: é só contra elas que a bancada testa. Uma receita já
## sua não tem o que descobrir — misturar por misturar seria fabricar de atravessado.
func _lab_locked_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in products:
		if int(item.get("required_level", 1)) > 1 and not _is_product_unlocked(item):
			ids.append(str(item["id"]))
	return ids

## O tamanho da escada, fixo: quantas receitas nasceram presas ao nível no catálogo. É o
## denominador do selo da bancada, e não muda conforme a loja sobe degrau — senão o selo
## seria "descubra as que ainda não caíram sozinhas", que é outra frase.
func _lab_targets_total() -> int:
	var total := 0
	for item in products:
		if int(item.get("required_level", 1)) > 1:
			total += 1
	return total

## As receitas travadas cuja ficha de ingredientes é exatamente o que está na mesa. Pode
## devolver mais de uma: sal + pó lunar é a ficha do Elixir de Memória de Peixe e do
## Martelo de Faísca Dramática, e a bancada entrega as duas na mesma faísca.
func _lab_matches(mix: Dictionary) -> Array[String]:
	var signature := _lab_signature(mix)
	var found: Array[String] = []
	if signature.is_empty():
		return found
	for item in products:
		if int(item.get("required_level", 1)) <= 1 or _is_product_unlocked(item):
			continue
		if _lab_signature(item.get("ingredients", {})) == signature:
			found.append(str(item["id"]))
	return found

## O palpite que o grimório vende: a ficha da receita travada de nível mais baixo, uma por
## vez. O alvo não é escolha da pessoa porque a escada é da casa: primeiro o que o nível
## entregaria logo, que é também a ordem em que a leitura cobra.
func _lab_hint_target() -> String:
	var best_level := 999999
	var best_id := ""
	for item in products:
		var required := int(item.get("required_level", 1))
		var recipe_id := str(item["id"])
		if required <= 1 or lab_hints.has(recipe_id) or _is_product_unlocked(item):
			continue
		if required < best_level:
			best_level = required
			best_id = recipe_id
	return best_id

func _lab_hint_cost() -> int:
	return maxi(20, int(round(float(LAB_HINT_COST) * (1.0 - 0.10 * float(library_upgrade_level)))))

## Unidades da mistura que o estoque não tem: a brasa é reservada no ato, mas o freguês
## pode revender o frasco enquanto ele espera, e o ensaio não pode acender a crédito.
func _lab_unbacked() -> Array[String]:
	var missing: Array[String] = []
	for ingredient_id in lab_mix.keys():
		if int(ingredient_stock.get(ingredient_id, 0)) < int(lab_mix[ingredient_id]):
			missing.append(Ingredients.any_name(str(ingredient_id)))
	return missing

func _lab_lacks(kind: String) -> String:
	var units := _lab_units(lab_mix)
	var held := int(ingredient_stock.get(kind, 0))
	if Ingredients.find(kind).is_empty():
		return "A bancada só aceita o que o mercado vende: raridade é catalisador da forja, não ingrediente de ensaio."
	if units >= LAB_MAX_UNITS:
		return "A bancada comporta %d unidades por ensaio. Mais que isso é forja disfarçada." % LAB_MAX_UNITS
	if not lab_mix.has(kind) and lab_mix.size() >= LAB_MAX_KINDS:
		return "São %d espécies por ensaio, e a mesa já tem duas: %s." % [
			LAB_MAX_KINDS, _lab_readable(_lab_signature(lab_mix))]
	if held <= int(lab_mix.get(kind, 0)):
		return "Falta %s no estoque para pôr na brasa (tem %d, a bancada já separou %d)." % [
			str(Ingredients.find(kind)["name"]), held, int(lab_mix.get(kind, 0))]
	return ""

## Põe uma unidade na mesa. Não queima nada ainda: separa.
func _lab_add(kind: String) -> void:
	var reason := _lab_lacks(kind)
	if reason != "":
		last_event = reason
		_refresh_ui()
		return
	lab_mix[kind] = int(lab_mix.get(kind, 0)) + 1
	audio.play("click")
	_show_feedback("⚗ %s na brasa." % str(Ingredients.find(kind)["name"]), Color(0.82, 0.95, 0.68))
	_refresh_ui()

func _lab_clear() -> void:
	if lab_mix.is_empty():
		last_event = "A bancada já está limpa: nada em brasa, nada queimado."
		_refresh_ui()
		return
	var back := _lab_readable(_lab_signature(lab_mix))
	lab_mix.clear()
	last_event = "A mesa foi raspada de volta para o pote: %s." % back
	audio.play("click")
	_refresh_ui()

## Acender a bancada: queima o carvão e os ingredientes de uma vez e devolve a resposta da
## tabela. Beco já riscado não cobra de novo — a casa não vende duas vezes a mesma porta
## fechada.
func _lab_fire() -> void:
	var units := _lab_units(lab_mix)
	var signature := _lab_signature(lab_mix)
	if units < 2:
		last_event = "Um ensaio pede ao menos duas unidades na brasa. Sozinho, isso é só estoque pegando fogo."
		_refresh_ui()
		return
	if signature.is_empty() or not _lab_signature_valid(signature):
		last_event = "A mesa tem mistura a mais e receita a menos: esvazia a bancada e recomeça."
		_refresh_ui()
		return
	if lab_trials.has(signature):
		last_event = "Esse ensaio já foi escrito no caderno: %s." % _lab_trial_line(signature)
		_refresh_ui()
		return
	var fee := _lab_fee(units)
	if gold < fee:
		last_event = "O carvão custa %d de ouro, e a caixa tem %d. A bancada não acende fiado." % [fee, gold]
		_refresh_ui()
		return
	var unbacked := _lab_unbacked()
	if not unbacked.is_empty():
		last_event = "A brasa pede %s que o estoque não tem mais. Esvazia a bancada e refaz a mistura." % ", ".join(unbacked)
		_refresh_ui()
		return
	gold -= fee
	for ingredient_id in lab_mix.keys():
		ingredient_stock[ingredient_id] = int(ingredient_stock.get(ingredient_id, 0)) - int(lab_mix[ingredient_id])
	var burned := _lab_readable(signature)
	var matches := _lab_matches(lab_mix)
	lab_mix.clear()
	if matches.is_empty():
		lab_flops += 1
		lab_trials[signature] = ""
		_add_mess(LAB_FIZZLE_MESS)
		_add_xp(LAB_FIZZLE_XP)
		last_event = "Ensaio sem saída: %s virou fuligem no salão (−%d de carvão, %d de barro no chão). A banca riscou o beco no caderno: esse punhado não casa com nada que esteja preso ao nível." % [
			burned, fee, LAB_FIZZLE_MESS]
		audio.play("sad")
		_show_feedback("✖ Beco riscado no caderno.", Color(1.0, 0.62, 0.52))
		_show_stage_emotion(stage_seller_body, "espanto")
	else:
		var names: Array[String] = []
		for recipe_id in matches:
			if not known_recipes.has(recipe_id):
				known_recipes.append(recipe_id)
			if not lab_discovered.has(recipe_id):
				lab_discovered.append(recipe_id)
			names.append(str(_product_by_id(recipe_id).get("name", recipe_id)))
		lab_trials[signature] = ",".join(matches)
		_add_xp(LAB_DISCOVERY_XP)
		reputation += 1
		last_event = "ACERTO NA BANCADA: %s casa com %s! %d de carvão pago, e a receita passa a ser sua sem subir um degrau de nível (+%d de experiência, +1 de fama)." % [
			burned, ", ".join(names), fee, LAB_DISCOVERY_XP]
		audio.play("rare")
		_show_feedback("✦ Receita arrancada do nível!", Color(0.86, 1.0, 0.70))
		_show_stage_emotion(stage_seller_body, "aplausao")
	_check_achievements()
	_save_game()
	_refresh_ui()

## O que o caderno responde sobre uma assinatura: "nada" ou o nome do que ela entregou.
func _lab_trial_line(signature: String) -> String:
	var outcome := str(lab_trials.get(signature, ""))
	if outcome.is_empty():
		return "%s: beco riscado" % _lab_readable(signature)
	var names: Array[String] = []
	for recipe_id in outcome.split(","):
		names.append(str(_product_by_id(str(recipe_id)).get("name", str(recipe_id))))
	return "%s: %s" % [_lab_readable(signature), ", ".join(names)]

## Palpite comprado: a ficha de ingredientes de uma receita travada, revelada para sempre
## no painel do grimório. É ouro por informação, não ouro por receita — a banca continua
## cobrando o ensaio.
func _lab_buy_hint() -> void:
	var target := _lab_hint_target()
	if target.is_empty():
		last_event = "O grimório não tem mais o que sussurrar: toda receita travada já tem ficha na mão."
		_refresh_ui()
		return
	var cost := _lab_hint_cost()
	if gold < cost:
		last_event = "O palpite custa %d de ouro e a caixa tem %d. A estante fecha a tampa." % [cost, gold]
		_refresh_ui()
		return
	gold -= cost
	lab_hints.append(target)
	_add_xp(2)
	last_event = "Palpite comprado: %s leva %s. A ficha fica no grimório — e a bancada continua cobrando o ensaio." % [
		str(_product_by_id(target).get("name", target)),
		_lab_readable(_lab_signature(_product_by_id(target).get("ingredients", {})))]
	audio.play("buy")
	_show_feedback("📖 Ficha revelada.", Color(0.70, 0.90, 1.0))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Resumo do painel: o que está em brasa, o que o caderno já sabe e quanto falta.
func _lab_summary() -> String:
	var units := _lab_units(lab_mix)
	var head := "MESA: %d de %d unidades, %d de %d espécies (%s) • carvão: %d de ouro" % [
		units, LAB_MAX_UNITS, lab_mix.size(), LAB_MAX_KINDS,
		_lab_readable(_lab_signature(lab_mix)) if units > 0 else "nada", _lab_fee(units)]
	head += "\nCADERNO: %d beco(s) riscado(s) • %d acerto(s) • %d de %d receitas travadas já caíram na bancada • %d ainda presas ao nível" % [
		lab_flops, lab_discovered.size(), lab_discovered.size(), _lab_targets_total(),
		_lab_locked_ids().size()]
	var lines: Array[String] = []
	for signature in lab_trials.keys():
		lines.append(" • " + _lab_trial_line(str(signature)))
	if not lines.is_empty():
		head += "\n" + "\n".join(lines)
	else:
		head += "\n • o caderno está em branco: nenhum ensaio acendido nesta vida"
	return head

## Lista que volta do arquivo só com id de receita travada: id inventado, receita básica
## de todo dia e duplicata não reentram na bancada. É a mesma tesoura do livro de fiado.
func _lab_ids_from_file(saved_ids: Variant) -> Array[String]:
	var kept: Array[String] = []
	if not saved_ids is Array:
		return kept
	for saved_id in saved_ids:
		var recipe_id := str(saved_id)
		var item := _product_by_id(recipe_id)
		if item.is_empty() or int(item.get("required_level", 1)) <= 1 or kept.has(recipe_id):
			continue
		kept.append(recipe_id)
	return kept

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

## Ficha do produto pelo id, ou vazio para quem não está no catálogo. É a leitura que a
## bancada usa para escrever nome de receita no mural sem indexar na mão.
func _product_by_id(product_id: String) -> Dictionary:
	var index := _product_index(product_id)
	return products[index] if index >= 0 else {}

## Escolhe o freguês do próximo turno. O peso cai conforme o vínculo sobe, então
## quem ainda não foi visitado domina a fila: ampliar o elenco não dilui a
## frequência de cada personagem nem atrasa os capítulos.
func _pick_regular() -> Dictionary:
	var picks: Array[Dictionary] = []
	var weights: Array[float] = []
	var total_weight := 0.0
	for candidate in Regulars.DATA:
		# Banido é banido: o nome sai do sorteio junto com a confiança que ele deixou
		# na casa, e nada traz ele de volta para dentro da loja.
		if _regular_banned(str(candidate["id"])):
			continue
		var candidate_bond := int(regular_bonds.get(str(candidate["id"]), 0))
		var weight := 1.0 / float(candidate_bond + 2)
		picks.append(candidate)
		weights.append(weight)
		total_weight += weight
	if picks.is_empty():
		return Regulars.DATA[0]
	var roll := randf() * total_weight
	for i in range(weights.size()):
		roll -= weights[i]
		if roll <= 0.0:
			return picks[i]
	return picks[picks.size() - 1]

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
		return _maybe_vip(profile)
	var regular: Dictionary = _pick_regular()
	var regular_id := str(regular["id"])
	var bond := int(regular_bonds.get(regular_id, 0))
	var tier := Regulars.tier_for(bond)
	var lines_by_tier: Array = regular["lines"][tier]
	var personal_request := tier >= 1 and randi() % 100 < 35
	var regular_line := str(regular["request"]) if personal_request else str(lines_by_tier[randi() % lines_by_tier.size()])
	return _maybe_vip({
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
	})

func _on_customer_tick() -> void:
	ticks += 1
	_stage_customer_leaves()
	_advance_service_queue()
	_advance_craft_jobs(3.0)
	Sanctum.advance(active_buffs, 3.0)
	_advance_expeditions(3.0)
	_set_seller_mood(_fury_mood())
	if is_instance_valid(reaction_label):
		reaction_label.text = ""
	if ticks % 20 == 0:
		shop_day += 1
		# O caderno de regra marca o dia no modo que a loja efetivamente morou: é ele, e
		# não o botão batido na hora da reencarnação, que decide o multiplicador de aura.
		difficulty_days[difficulty] = int(difficulty_days.get(difficulty, 0)) + 1
		_show_stage_emotion(stage_seller_body, "sono")
		Economy.advance_day(economy_state)
		_roll_weather()
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
		# A casa acorda com a chefe: chão varrido por quem foi pago para isso (ou por
		# quem ama a chefe de graça) e cela que pingou no frasco durante a noite.
		var clean_line := _clean_house_turn()
		var blood_line := _harvest_cell()
		# E a rua acorda com ela: barro na vitrine é convite, e convite vem cobrar.
		var vandal_line := ""
		if randi() % 100 < _vandal_chance():
			_trigger_vandal()
			vandal_line = "\n" + last_event
		# Vândalo é o beco testando a vitrine; visita em bando é a rua batendo no caixa
		# inteiro, com lista na mão. Uma desgraça por manhã, para o balanço ter leitura:
		# se o barro já chamou vândalo nesta virada, a porta grande fica para amanhã.
		var invasion_line := ""
		if vandal_line == "":
			if randi() % 100 < _invasion_chance():
				invasion_line = "\n" + _roll_invasion()
		# O vigário cobra na virada, não no meio do balcão: resposta de dízimo é decisão
		# de chefe com painel aberto, não sorteio de fila. A mensagem aparece uma vez por
		# dia de loja e o botão fica esperando até ela ser dada.
		var vicar_line := ""
		if _vicar_waiting() and vicar_announced_day != shop_day:
			vicar_announced_day = shop_day
			vicar_line = "\n✝ %s bate na porta com a lista da paróquia: %d de dízimo, ou %d para apagar este endereço da lista por um tempo. A resposta fica no painel até ele sair." % [
				Invasions.vicar_name(), _vicar_demand(), _vicar_bribe()]
		# A fila que desistiu também fecha o dia: é o número que o balanço da manhã
		# precisa mostrar para a fama ter preço visível.
		var lost_line := ""
		if day_walkouts > 0:
			lost_line = " %d saíram da fila sem comprar." % day_walkouts
		# A placa que acendeu hoje entra no balanço: a loja lê o rombo antes de a
		# primeira batida pegar menos corpo na calçada.
		var rival_line := _rival_opening_line()
		# A despensa vira depois de todos os sorteios da manhã: estrago de prazo não
		# consome sorte, senão a mesma semente mudaria de vândalo só porque havia
		# poção velha na prateleira.
		var spoil := _age_shelf()
		var spoil_line := ""
		if int(spoil["turned"]) > 0:
			spoil_line = " A prateleira virou: %d peça(s) desceu(ram) de qualidade" % int(spoil["turned"])
			if int(spoil["lost"]) > 0:
				spoil_line += " e %d saiu(ram) do fundo da estante pela porta." % int(spoil["lost"])
			else:
				spoil_line += "."
		# A rua esquece uma linha por virada, antes de o fiado riscar as suas: a queixa
		# escrita hoje é a que amanhã começa a doer. Memória curta, sem dado e sem conta.
		var esquecida_na_virada := complaints
		_complaints_forget()
		esquecida_na_virada -= complaints
		# O livro de fiado vira junto com a prateleira: atraso é dia morado, não sorteio,
		# e a nota riscada dói na conta uma única vez por virada.
		var credit_line := _age_credit_book()
		var credit_report := (" " + credit_line) if credit_line != "" else ""
		var credit_event := ("\n📖 " + credit_line) if credit_line != "" else ""
		# Combo é do dia: a virada recomeça a contagem para todo mundo, cartaz pendurado
		# ou não. O que fica na vida é o recorde premiado e o ouro já pago.
		combo_streak = 0
		var combo_line := ""
		var combo_event := ""
		if combo_rank > 0 and combo_day_gold > 0:
			combo_line = " 🔥 O cartaz pagou %d de ouro em combo, com %d venda(s) seguidas de recorde do dia." % [
				combo_day_gold, combo_day_best]
			combo_event = "\n🔥 O cartaz pagou %d de ouro em combo, com %d venda(s) seguidas de recorde do dia." % [
				combo_day_gold, combo_day_best]
		# Só quem tem livro aberto (ou acabou de apagar uma linha) lê a rua no balanço:
		# com o caderno em branco a manhã continua com exatamente os números de sempre.
		var complaint_line := ""
		var complaint_event := ""
		if complaints > 0 or esquecida_na_virada > 0:
			var fala_da_rua := "murmúrio"
			if _complaint_stage() == 1:
				fala_da_rua = "boato"
			elif _complaint_stage() == 2:
				fala_da_rua = "escândalo"
			var cobraca := ""
			if _complaint_stage() > 0:
				cobraca = " e cobra etiqueta %s, paciência −%d, porta −%d" % [
					_label_word(), _complaint_patience_loss(), _complaint_crowd_loss()]
			complaint_line = " 📙 A rua chama a casa de %s: %d linha(s) no livro%s%s." % [
				fala_da_rua, complaints, cobraca,
				", uma apagada pela virada" if esquecida_na_virada > 0 else ""]
			complaint_event = "\n📙 A rua chama a casa de %s: %d linha(s) no livro%s%s." % [
				fala_da_rua, complaints, cobraca,
				", uma apagada pela virada" if esquecida_na_virada > 0 else ""]
		day_report = str(_weather()["line"]) + " " + bill_line + (" " + branch_line if branch_line != "" else "") + calm_line + clean_line + blood_line + lost_line + invasion_line + rival_line + spoil_line + credit_report + complaint_line + combo_line
		last_event = "Dia %d começou! Um novo contrato está disponível; o anterior expirou. %s • %s\n%s%s%s%s%s%s%s%s%s" % [
			shop_day, Economy.report(economy_state, products, Ingredients.DATA), _weather_line(), bill_line,
			("\n" + branch_line) if branch_line != "" else "", vandal_line, invasion_line, vicar_line, rival_line,
			credit_event, complaint_event, combo_event]
		# A manhã também afina a faixa: alarme novo, vigário na porta ou ruína velha
		# mudam o tom da mesma gravação antes de a chefe abrir o balcão.
		_apply_situation_music()
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
		current_customer_budget = _visit_budget(profile)
		# Quem deve à casa paga antes de comprar: o bolso que a visita trouxe é o
		# mesmo que quita a nota, e o que sobra é o que ele leva hoje. Quitar não dá
		# direito a uma nota nova no mesmo balcão — senão a casa giraria o próprio
		# ouro e chamaria isso de freguês fiel.
		var credit_note: Dictionary = _settle_credit_note(str(profile.get("regular_id", "")))
		var credit_settled := not credit_note.is_empty()
		if credit_settled:
			current_customer_budget = maxi(0, current_customer_budget - int(credit_note["purse"]))
		var credit_lending := false
		var credit_choice := -1
		current_customer_patience = maxi(1, int(round(float(int(profile.get("patience", 2)) + logistics_rank + Sanctum.patience_bonus(active_buffs) + distraction_pending) / world_speed())) - _fury_patience_loss() - _mess_patience_loss())
		distraction_pending = 0
		var seduction_used := false
		if is_instance_valid(customer_emotion_label):
			customer_emotion_label.text = "🏃 pressa" if current_customer_patience <= 1 else "🙂 observando"
		if bool(profile.get("thief", false)) and current_customer_patience <= 1:
			var round_block := Staff.block_chance(staff_hired) + servants.size() * SERVANT_GUARD_CHANCE
			if Sanctum.guards(active_buffs):
				last_event = "%s enfiou a mão na prateleira, mas o Selo da Cadeia estalou e a mão saiu vazia. Ele ainda pagou o que levou." % str(profile.get("name", "O cliente"))
				_show_feedback("⛓ Furto barrado pelo selo.", Color(0.75, 1.0, 0.72))
			elif round_block > 0 and randi() % 100 < round_block:
				theft_blocked += 1
				var caught_id := str(profile.get("regular_id", ""))
				var caught_name := str(profile.get("name", "O cliente"))
				if not caught_id.is_empty() and not Regulars.find(caught_id).is_empty():
					caught_name = str(Regulars.find(caught_id).get("short", caught_name))
				_catch_culprit(caught_name, caught_id)
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
			var charm_negotiation := charm_rank > 0 and randi() % 100 < 25 + charm_rank * 12 + sanctum_upgrade_level * 5
			if charm_negotiation and available.size() > 0:
				seduction_used = true
				seduction_attempts += 1
				seduction_successes += 1
				current_customer_budget += 20 + charm_rank * 10
				_add_affection(2 + charm_rank)
				reputation += 1 + _reputation_seduction_bonus()
				var plea := "suspira: “Meu orçamento é curto...”" if adult_content_enabled else "bate no bolso: “Meu orçamento é curto...”"
				last_event = "%s %s %s O cliente reconsidera." % [profile["name"], plea, _negotiation_line(str(profile["name"]))]
				for affordable_index in available:
					if _shelf_price(affordable_index) <= current_customer_budget:
						affordable.append(affordable_index)
			else:
				var fiado_index := _cheapest_index(available)
				var fiado_valor := 0 if fiado_index < 0 else _shelf_price(fiado_index)
				if not credit_settled and _can_lend(str(profile.get("regular_id", "")), fiado_valor):
					# O bolso não chega, mas o nome chega: a casa anota no livro e a
					# peça sai. O ouro fica na rua até a virada cobrar — e é isso que
					# faz o fiado doer quando a conta da casa chega antes do pagamento.
					credit_lending = true
					credit_choice = fiado_index
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
		# A segunda porta do fiado é o pedido pessoal: quem veio pela peça que a casa
		# tem na estante, e não chega na etiqueta dela, hoje levaria outra e o pedido
		# continuaria por fazer. No livro ele leva a que pediu, a casa marca a
		# encomenda concluída e recebe amanhã — com o risco da riscada. Degrau zero não
		# empresta, então nenhuma visita de loja nova passa por aqui.
		if not credit_lending and not credit_settled and not seduction_used \
				and not affordable.is_empty() and bool(profile.get("personal_request", false)):
			if preferred_index >= 0 and available.has(preferred_index) and not affordable.has(preferred_index):
				var pedido_valor := _shelf_price(preferred_index)
				if _can_lend(str(profile.get("regular_id", "")), pedido_valor):
					# O fiado aqui não é um presente nem um desconto: é o mesmo preço
					# honesto do balcão, cobrado um dia depois. O que a casa troca é o
					# dia, e o risco passa a ser seu — a riscada mora na virada.
					credit_lending = true
					credit_choice = preferred_index
		var chosen_index: int = credit_choice if credit_lending else (affordable[randi() % affordable.size()] if not affordable.is_empty() else available[randi() % available.size()])
		# A capa fina não compra peça de degrau baixo: ela examina o topo da barra daquele
		# produto e, se a estante não tem o que ela aceita, devolve no lugar e sai falando.
		# A recusa não queima unidade nenhuma e não consome um sorteio — o preço é o balcão
		# perder a venda e a fama perder o ponto.
		if bool(profile.get("vip", false)):
			var exigencia := _vip_standard()
			var topo := _best_tier_for(chosen_index)
			if topo < exigencia:
				vip_refusals += 1
				disappointed_customers += 1
				day_walkouts += 1
				# Saiu falando e levou o ritmo junto: o cartaz paga sequência sem porta
				# batida, e uma capa fina devolvida é exatamente a porta batida.
				_break_combo()
				reputation = maxi(0, reputation - 1)
				# A fofoca de capa fina devolvida é barulhenta: duas linhas no livro da rua,
				# não uma. Quem sai sem comprar pelo segundo cartão conta para duas mesas.
				var linhas_da_recusa := _add_complaint(COMPLAINT_FROM_VIP_REFUSAL)
				_set_customer_status("CLIENTE: saiu sem comprar")
				if is_instance_valid(customer_emotion_label):
					customer_emotion_label.text = "🙄 desprezo"
				last_event = "🎩 %s examina o topo da barra de %s, encontra %s e devolve no lugar: uma capa fina não compra degrau baixo. A casa perde a venda e a fofoca vai junto (−1 de fama).\n📙 %s" % [
					str(profile["name"]), str(products[chosen_index]["name"]),
					str(Quality.tier(maxi(0, topo))["name"]), _complaint_tail(linhas_da_recusa)]
				_show_stage_emotion(stage_customer, "nojo")
				_play_customer_reaction("broke")
				_check_achievements()
				_save_game()
				_refresh_ui()
				return
		if preferred_index >= 0 and available.has(preferred_index) and not credit_lending and randi() % 100 < 70:
			# O dedo aponta a vitrine, mas quem decide a compra é o bolso. Este `if` trocava
			# o escolhido pela favorita sem consultar `affordable`, e a loja recebia o preço
			# cheio de quem tinha menos da metade no bolso — medido: 143 de ouro na mão de 60.
			var leva_a_favorita := affordable.has(preferred_index)
			if leva_a_favorita:
				chosen_index = preferred_index
				# Ele viu o que queria do outro lado do salão e aponta antes de pedir.
				_show_stage_emotion(stage_customer, "aponta")
			if not seduction_used and charm_rank > 0 and randi() % 100 < 8 + charm_rank * 5 + sanctum_upgrade_level * 3 and (leva_a_favorita or current_customer_patience <= 1):
				seduction_used = true
				seduction_attempts += 1
				seduction_successes += 1
				_add_affection(1 + charm_rank + sanctum_upgrade_level)
				reputation += _reputation_seduction_bonus()

		var item: Dictionary = products[chosen_index]
		# Quem entra pelo cordão escolhe pelo topo da barra: sai a melhor peça do produto,
		# não a mais velha do degrau — e a exigência de cima já garantiu que ela existe.
		var piece_tier := _take_piece(chosen_index, Quality.BEST if bool(profile.get("vip", false)) else Quality.WORST)
		var quality_name := str(Quality.tier(piece_tier)["name"])
		_register_sold_piece(piece_tier)
		var linha_torta := 0
		if piece_tier == 0:
			# Saiu torto da forja e o cliente viu: ninguém esconde a careta — e a careta
			# atravessa a praça. A casa paga a linha no livro da rua.
			_show_stage_emotion(stage_customer, "nojo")
			linha_torta = _add_complaint(COMPLAINT_FROM_TORTO)
		var base_label := _piece_price(item, piece_tier)
		var price_multiplier: float = (1.0 + 0.20 * ad_level) * (1.0 + 0.08 * trade_rank) * _reputation_price_multiplier() * _complaint_label_factor() * _fury_price_multiplier() * _mess_price_multiplier() * Sanctum.scale(active_buffs, "price") * _market_product_factor(item) * _romance_price_factor(str(profile.get("regular_id", ""))) * _prestige_price_factor() * _recommendation_price_factor() * (1.0 + SERVANT_PRICE_SHARE * servants.size()) * (1.08 if _has_spec("trade", "cartel") else 1.0)
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
		if linha_torta > 0:
			last_event += "\n📙 A peça torto foi entregue na mão dele, e ele saiu falando: %s" % _complaint_tail(linha_torta)
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
		# O cartaz paga o ritmo no mesmo molde do mural de cartas e da facção: bônus sobre a
		# etiqueta de tabela, somado depois. Com o cartaz guardado a taxa é zero cravado, o
		# `if` nem roda e o centavo não entra — é assim que a régua antiga continua medindo a
		# mesma venda de sempre, centavo a centavo.
		var combo_bonus := int(round(base_label * _combo_rate()))
		if combo_bonus > 0:
			sale_price += combo_bonus
		var fulfilled_personal_request := profile.has("personal_request") and bool(profile["personal_request"]) and preferred_index == chosen_index
		var headline_locked := false
		if fulfilled_personal_request:
			var request_bonus := maxi(8, int(round(float(item["price"]) * 0.5)))
			sale_price += request_bonus
			var completed_id := str(profile["regular_id"])
			regular_orders_completed[completed_id] = int(regular_orders_completed.get(completed_id, 0)) + 1
			if credit_lending:
				# No fiado o pedido sai concluído e o prêmio vai na nota junto com a
				# peça: a casa anota o preço honesto e cobra na virada.
				last_event = "PEDIDO ESPECIAL concluído para %s no fiado: o prêmio de %d ouro entra na nota, e a casa cobra na virada. +10 XP. %s" % [profile["name"], request_bonus, profile["line"]]
			else:
				last_event = "PEDIDO ESPECIAL concluído para %s! +%d ouro e +10 XP. %s" % [profile["name"], request_bonus, profile["line"]]
			_add_xp(10)
			headline_locked = true
			reputation += 1 + (1 if seduction_used else 0)
		# A peça saiu da prateleira. No balcão de sempre o dinheiro entra no caixa; no
		# fiado ele entra no livro, e o caixa fica esperando a virada — a mesma virada
		# em que a casa cobra conta e filial. É aí que o crédito dói: emprestar é fechar
		# o dia com a conta pronta e o ouro na rua.
		if credit_lending:
			# O livro anota o preço honesto da peça, não a etiqueta de vitrine: a casa
			# empresta o ouro de hoje e cobra amanhã o que cobraria no balcão — inclusive
			# o prêmio do pedido pessoal. O que muda é o dia, nunca o valor. E o teto do
			# degrau é teto da nota: fiado acima do que a casa aceita ter na rua não é
			# crédito, é aposta.
			var fiado_devido := mini(sale_price, _credit_limit())
			_lend_note(str(profile.get("regular_id", "")), str(profile["name"]), str(item["name"]), fiado_devido)
			var nota := "📖 %s levou %s (%s) no fiado: %d de ouro anotados no livro, prazo no dia %d. %s" % [
				profile["name"], item["name"], quality_name, fiado_devido,
				shop_day + _credit_due_days(), str(profile["line"])
			]
			# Quem veio pelo pedido e levou no fiado tem dois motivos para ler: a encomenda
			# saiu feita e a casa anotou o prêmio junto. A nota é a manchete, o pedido fica
			# na linha de cima — sem isso o balcão emprestava sem avisar do favor.
			if fulfilled_personal_request:
				nota = "%s\n%s" % [str(last_event), nota]
			last_event = nota
			# A nota é o recibo do ouro que saiu pela porta: vira manchete trancada, e
			# nenhuma festa de balcão (degrau de freguês, faixa da reforma) pode apagá-la
			# no mesmo turno em que ela foi escrita.
			headline_locked = true
		else:
			gold += sale_price
		if credit_settled:
			last_event = "%s\n%s" % [str(credit_note["line"]), last_event]
		customers_served += 1
		# A sequência conta para o balcão inteiro, mas só vira ouro e recorde quando o
		# cartaz está pendurado e o dinheiro entrou no caixa de fato: nota de fiado leva o
		# bônus anotado junto, e o pagamento é na virada — o combo não conta duas vezes.
		if combo_bonus > 0 and not credit_lending:
			last_event += "\n" + _combo_tail(combo_bonus, combo_streak + 1)
		_bump_combo(combo_bonus if not credit_lending else 0)
		_add_mess(MESS_PER_VISIT)
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
				var escada := "%s agora é %s! %s" % [regular_data.get("short", regular_data.get("name", "Freguês")), Regulars.TIER_NAMES[new_tier], tier_line]
				# O degrau novo é a notícia maior, mas não apaga o recibo do balcão: num
				# balcão de fiado o pedido sobe de degrau justamente na visita em que a
				# nota é escrita, e perder a nota aqui é o ouro emprestado sumir do mural.
				last_event = escada if not headline_locked else "%s\n%s" % [escada, str(last_event)]
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
					var capitulo := "CAPÍTULO CONCLUÍDO: a história de %s avança! Recompensa: %d ouro, +30 XP e +2 reputação." % [regular_data.get("short", regular_data.get("name", "Freguês")), story_reward]
					last_event = capitulo if not headline_locked else "%s\n%s" % [capitulo, str(last_event)]
					headline_locked = true
				else:
					last_event += "\nMissão pessoal: %d/3 compras favoritas." % story_progress
			var romance_tip := _romance_tip(regular_id)
			# quem leva no fiado não deixa gorjeta no mesmo turno: a dívida é a gorjeta.
			if romance_tip > 0 and not credit_lending:
				gold += romance_tip
				daily_gold_earned += romance_tip
				last_event += "\n%s deixa uma gorjeta de coração sobre o balcão: +%d ouro." % [
					regular_data.get("short", "O freguês"), romance_tip
				]
			_offer_romance(regular_id, new_bond)
			_check_regular_acts(regular_id)
			_offer_servant(regular_id)
		# A capa fina fecha a conta com gorjeta sobre a tabela e um ponto de fama para a
		# casa — o convite puxa convite. No fiado ela sai servida, mas a gorjeta fica para
		# amanhã: dívida é a gorjeta de quem leva o ouro da loja na mão.
		if bool(profile.get("vip", false)):
			vip_served += 1
			reputation += 1
			if not credit_lending:
				var gorjeta := maxi(4, int(round(float(base_label) * float(_vip_row(vip_rank)["tip"]))))
				gold += gorjeta
				daily_gold_earned += gorjeta
				vip_tips_gold += gorjeta
				last_event += "\n🎩 A capa fina deixa %d de ouro de gorjeta no balcão e leva %s — o topo da barra que a estante tinha." % [
					gorjeta, str(Quality.tier(piece_tier)["name"])]
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
		if not credit_lending:
			daily_gold_earned += sale_price
		_add_xp(12)
		_progress_contracts("customers", 1)
		# A meta de ouro do dia é o que entrou no caixa. No fiado a peça saiu, o cliente
		# saiu satisfeito e o ouro saiu pela porta — a conta dele é do livro, e só entra
		# no balanço na virada em que a casa recebe. Somar a etiqueta aqui era o dia
		# bater cheio com a gaveta vazia.
		if not credit_lending:
			_progress_contracts("gold", sale_price)
		_add_affection(1 + charm_rank + sanctum_upgrade_level + (1 if _has_spec("charm", "coracao") else 0))
		_set_customer_status("CLIENTE: %s" % profile["name"])
		_set_seller_mood("happy")
		_react_to_visit("delighted" if preferred_index == chosen_index else "content", seduction_used)
		_set_negotiation_dialogue(profile, item, seduction_used, preferred_index == chosen_index)

	if affection >= 10 and affection % 10 == 0:
		var marco := _affection_milestone_index()
		var topo_m: float = float(maxi(SENSUAL_AFFECTION_MILESTONES.size() - 1, 1))
		if adult_content_enabled:
			last_event = str(SENSUAL_AFFECTION_MILESTONES[marco])
			_play_sensual_reception_moment(float(marco) / topo_m)
		else:
			last_event = str(TRUST_AFFECTION_MILESTONES[marco])
	elif affection > 0 and affection % 5 == 0:
		last_event = "A chefe pisca para você: “Olha só, estamos nos entendendo melhor, querido.”" if adult_content_enabled else "A chefe assina o caderno: “Olha só, estamos nos entendendo melhor.”"

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
		_play_sensual_reception_moment(float(_private_moment_index()) / float(maxi(SENSUAL_MOMENTS.size() - 1, 1)))
	else:
		_show_stage_emotion(stage_seller_body, "pensativo")
	audio.play("rare")
	_show_feedback("Evento raro!", Color(1.0, 0.86, 0.45))
	# A moeda do complemento gira nos dois modos: se ela só girasse com o filtro
	# ligado, a sorte da loja passaria a depender do interruptor e a mesma semente
	# deixaria de render a mesma partida.
	if affection >= 5 and randi() % 2 == 0:
		if adult_content_enabled:
			last_event += "\nA súcubo ri: “Nossa loja é um desastre adorável. Ainda bem que você está aqui, querido.”"
		else:
			last_event += "\nA chefe ri: “Nossa loja é um desastre adorável. Ainda bem que você está aqui.”"

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

## A fala da negociação de charme depende só do filtro de cenas: o meme continua meme
## nas duas versões e o que muda é a voz da chefe, nunca o que a fala paga em ouro,
## reputação ou vaga de servo.
func _negotiation_line(customer_name := "") -> String:
	var meme := customer_name in MEME_CUSTOMER_NAMES
	if adult_content_enabled:
		return str(MEME_FLIRT_LINES.pick_random() if meme else SUCCUBUS_NEGOTIATION_LINES.pick_random())
	return str(MEME_TRUST_LINES.pick_random() if meme else TRUST_NEGOTIATION_LINES.pick_random())

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
		seller_speech_label.text = "CHEFE: %s\n%s: %s" % [_negotiation_line(customer_name), customer_name, customer_line]
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
				# A fúria que subiu agora é a cena que ele viu de graça demais.
				_servant_quits()
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
	if affection >= 100 and not seduction_peak_triggered:
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

## O humor que a fúria manda para o retrato. A forma demoníaca é consequência de fúria
## e não de conteúdo: o estado, o selo no painel e o preço da etiqueta correm nos dois
## modos. O que o filtro segura é a arte provocante do retrato, que volta inteira ao
## ligar o interruptor no meio da fúria.
func _fury_mood() -> String:
	return "demonic" if (demonic_form_active and adult_content_enabled) else "neutral"

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
	if fury >= 4 and not demonic_form_active:
		demonic_form_active = true
		_set_seller_mood(_fury_mood())
		_show_stage_emotion(stage_seller_body, "briga")
		_show_stage_emotion(stage_customer, "medo")
		last_event = "A FÚRIA CHEGOU AO LIMITE! A succubus assume sua forma demoníaca: “Respirem. Eu ainda sei negociar.”" if adult_content_enabled else "A FÚRIA CHEGOU AO LIMITE! A chefe assume a forma demoníaca: “Respirem. Eu ainda sei negociar.”"
		if is_instance_valid(seller_portrait):
			seller_portrait.modulate = Color(1.0, 0.55, 0.62, 1.0)
			var demon_tween := create_tween()
			demon_tween.tween_property(seller_portrait, "scale", Vector2(1.10, 1.10), 0.22).set_trans(Tween.TRANS_BACK)
			demon_tween.tween_property(seller_portrait, "scale", Vector2.ONE, 0.34)
		audio.play("rare")
		_show_feedback("Forma demoníaca ativada.", Color(1.0, 0.48, 0.58))
	elif demonic_form_active and fury <= 1:
		demonic_form_active = false
		_set_seller_mood(_fury_mood())
		last_event = "A succubus respira fundo e retorna à forma habitual. A loja sobreviveu ao drama." if adult_content_enabled else "A chefe respira fundo e retorna à forma habitual. A loja sobreviveu ao drama."

func _refresh_ui() -> void:
	if not is_instance_valid(gold_label):
		return
	gold_label.text = tr("Ouro: %d") % gold
	rep_label.text = tr("Reputação: %d • %s (+%d%%)") % [reputation, tr(_reputation_title()), int(round((_reputation_price_multiplier() - 1.0) * 100.0))]
	# O número do painel é o corpo desenhado no salão agora, e a fila à parte:
	# contar a vida inteira fazia "Clientes: 12" com três visitas na tela.
	customers_label.text = tr("No salão: %d • Fila: %d  ♥%d  ✗%d  •  Atendidos: %d") % [
		_bodies_on_stage(), service_queue.size(), happy_customers, disappointed_customers, customers_served]
	affection_label.text = tr("Afinidade: %d/100 • Seduções: %d/%d") % [affection, seduction_successes, seduction_attempts]
	if is_instance_valid(fury_label):
		var fury_line := tr("Fúria: %d/5") % fury
		if demonic_form_active:
			fury_line += tr(" • FORMA DEMONÍACA")
		if fury > 0:
			fury_line += tr(" • etiqueta -%d%%") % (clampi(fury, 0, 5) * 5)
		fury_label.text = fury_line
	if is_instance_valid(speed_label):
		speed_label.text = tr("TEMPO DO MUNDO: %.1fx") % world_speed()
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
	if is_instance_valid(cold_storage_button):
		cold_storage_button.text = "❄ Depósito de sal Nv.%d • %d ouro" % [cold_storage_level, _cold_storage_cost()] if cold_storage_level < 3 else "❄ Depósito de sal Nv.3 • Máximo"
		cold_storage_button.disabled = cold_storage_level >= 3 or gold < _cold_storage_cost()
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
	if is_instance_valid(lab_label) and not lab_add_buttons.is_empty():
		lab_label.text = _lab_summary()
		for i in range(Ingredients.DATA.size()):
			var ingredient: Dictionary = Ingredients.DATA[i]
			var kind := str(ingredient["id"])
			lab_add_buttons[i].text = "⚗ %s (%d/%d)" % [
				str(ingredient["name"]), int(lab_mix.get(kind, 0)), int(ingredient_stock.get(kind, 0))]
			lab_add_buttons[i].disabled = _lab_lacks(kind) != ""
		lab_clear_button.text = "Esvaziar a mesa"
		lab_clear_button.disabled = lab_mix.is_empty()
		var lab_units := _lab_units(lab_mix)
		var lab_fee := _lab_fee(lab_units)
		var lab_repeat := (
			lab_units >= 2 and lab_trials.has(_lab_signature(lab_mix))
		)
		lab_fire_button.text = "🔥 Acender a bancada (%d)" % lab_fee
		lab_fire_button.disabled = (
			lab_units < 2 or gold < lab_fee or lab_repeat or not _lab_unbacked().is_empty()
		)
		lab_hint_button.text = (
			"📖 Palpite do grimório (%d)" % _lab_hint_cost()
			if not _lab_hint_target().is_empty() else "📖 Grimório sem fichas novas"
		)
		lab_hint_button.disabled = _lab_hint_target().is_empty() or gold < _lab_hint_cost()
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
			product_labels[i].text = "%s%s %s\nEstoque: %d  •  Vitrine: %d ouro\nPeças: %s\n%s" % [item["name"], demand_marker, heat_marker, item["stock"], shelf, Quality.summary(quality), _shelf_marker(i)]
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
		craft_buttons[i].text = _forge_button_label(i) if already_queued else "Fabricar (%d)" % craft_cost if unlocked and missing_ingredients.is_empty() else "Faltam ingredientes" if unlocked else "Receita bloqueada"
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
			var ficha := " — ficha do palpite: %s" % _lab_readable(_lab_signature(item.get("ingredients", {}))) if lab_hints.has(recipe_id) else ""
			recipe_labels[i].text = "🔒 %s • exige nível %d%s" % [item["name"], required_level, ficha]
			recipe_buttons[i].text = "Aprender (%d)" % recipe_cost
			recipe_buttons[i].disabled = gold < recipe_cost
	if is_instance_valid(market_label):
		var hot := _demand_index()
		var hot_text := " • Em alta: %s" % str(products[hot]["name"]) if hot >= 0 else ""
		market_label.text = "Dia %d — %s%s\n%s" % [
			shop_day, Economy.report(economy_state, products, Ingredients.DATA), hot_text, _weather_line()]
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
	if is_instance_valid(rival_summary_label):
		rival_summary_label.text = "HOJE NA PRAÇA: %s" % _rival_pressure_line()
	for i in range(Rivals.DATA.size()):
		var rival: Dictionary = Rivals.DATA[i]
		var rival_id := str(rival["id"])
		var absorbed := rivals_absorbed.has(rival_id)
		var not_yet := shop_day < int(rival["day"])
		var rival_cost := Rivals.price_for(rival, shop_day)
		if i < rival_labels.size():
			(rival_labels[i] as Label).text = "%s — %s\nRouba %d da porta por batida e %d do bolso de quem entra • placa acende no dia %d • fama %d %s" % [
				str(rival["name"]),
				"SUA" if absorbed else ("de placa acesa na praça" if not not_yet else "ainda sem placa"),
				int(rival["crowd"]), int(rival["undercut"]), int(rival["day"]),
				reputation, "segura metade" if reputation >= Rivals.FAME_HOLD else "ainda não segura"]
		if i < rival_buttons.size():
			var rival_button := rival_buttons[i] as Button
			rival_button.disabled = absorbed or not_yet or gold < rival_cost
			rival_button.text = "PLACA COMPRADA" if absorbed else (
				"Comprar a placa (%d)" % rival_cost if not not_yet else "Abre no dia %d" % int(rival["day"]))
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
	if is_instance_valid(mess_label):
		mess_label.text = _mess_line()
	if is_instance_valid(sweep_button):
		var mop := _mop_cost()
		sweep_button.text = "🧹 Varrer o salão (%d)" % mop
		sweep_button.disabled = mess <= 0 or gold < mop
	if is_instance_valid(cell_label):
		cell_label.text = _cell_line()
	_apply_progress_decor()
	if is_instance_valid(progress_label):
		progress_label.text = _progress_line()
	var has_prisoner := not prisoners.is_empty()
	for seat_button in [release_button, deliver_button, banish_button]:
		if is_instance_valid(seat_button):
			seat_button.disabled = not has_prisoner
	if is_instance_valid(staff_summary_label):
		# A folha é a conta: o painel diz quanto os do balcão somam por virada e onde
		# esse dinheiro aparece — no custo da casa, não numa linha separada.
		if staff_hired.is_empty():
			staff_summary_label.text = "Ninguém no balcão além da chefe e do diabrete. A folha é zero e a conta também.%s" % _servants_line()
		else:
			var payroll := Staff.total_wage(staff_hired)
			staff_summary_label.text = "NO BALCÃO: %d de %d • folha %d por virada, dentro do custo da casa (hoje %d). %s%s%s" % [
				staff_hired.size(), Staff.size(), payroll, _daily_upkeep(), Staff.roster_line(staff_hired),
				" • %d furtos barrados pela ronda." % theft_blocked if staff_hired.has("ronda") else "",
				_servants_line()
			]
	if is_instance_valid(credit_label):
		credit_label.text = _credit_summary()
	if is_instance_valid(credit_button):
		var credit_next := _credit_next_row()
		if credit_next.is_empty():
			credit_button.text = "📖 Livro no degrau máximo"
			credit_button.disabled = true
		else:
			credit_button.text = "📖 Abrir o fiado — degrau %d (%d)" % [
				int(credit_next["rank"]), int(credit_next["cost"])]
			credit_button.disabled = false
	if is_instance_valid(vip_label):
		vip_label.text = _vip_summary()
	if is_instance_valid(vip_button):
		var vip_next := _vip_next_row()
		if vip_next.is_empty():
			vip_button.text = "🎩 Salão no degrau máximo"
			vip_button.disabled = true
		else:
			vip_button.text = "🎩 Estender o cordão — degrau %d (%d)" % [
				int(vip_next["rank"]), int(vip_next["cost"])]
			vip_button.disabled = false
	if is_instance_valid(complaint_label):
		complaint_label.text = _complaint_summary()
	if is_instance_valid(complaint_button):
		if complaints <= 0:
			complaint_button.text = "🗣 A rua está quieta"
			complaint_button.disabled = true
		else:
			complaint_button.text = "🗣 Pagar a voz da rua (%d)" % _hush_cost()
			complaint_button.disabled = gold < _hush_cost()
	if is_instance_valid(combo_label):
		combo_label.text = _combo_summary()
	if is_instance_valid(combo_button):
		var combo_next := _combo_next_row()
		if combo_next.is_empty():
			combo_button.text = "🔥 Cartaz no degrau máximo"
			combo_button.disabled = true
		else:
			combo_button.text = "🔥 Pendurar o cartaz — degrau %d (%d)" % [
				int(combo_next["rank"]), int(combo_next["cost"])]
			combo_button.disabled = gold < int(combo_next["cost"])
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
	if is_instance_valid(defense_label):
		var snapshot := _defense_snapshot()
		var wave := _next_wave()
		var chance := _invasion_chance()
		if wave.is_empty():
			defense_label.text = "MÃO NA PORTA: %d. A rua ainda não tem alvo aqui — loja com vitrine vazia não recebe visita (%d%% de chance por virada). %s" % [
				Invasions.defense_power(snapshot), chance, Invasions.campaign_line(invasions_repelled)]
		else:
			defense_label.text = "MÃO NA PORTA: %d • a rua bate em %d%% das viradas • %s (%s) pede %d, e a casa segura em %d%%. %s" % [
				Invasions.defense_power(snapshot), chance, str(wave["name"]), str(wave["leader"]),
				int(wave["power"]), Invasions.repel_chance(snapshot, wave),
				Invasions.campaign_line(invasions_repelled)]
	if is_instance_valid(defense_lines_label):
		defense_lines_label.text = _defense_breakdown_line()
	if is_instance_valid(vicar_label):
		vicar_label.text = _vicar_panel_line()
	if is_instance_valid(invasion_label):
		invasion_label.text = last_invasion
	for answer_button in [[tithe_button, "dizimo"], [bribe_button, "suborno"], [refuse_button, "recusa"]]:
		var vicar_button := answer_button[0] as Button
		if not is_instance_valid(vicar_button):
			continue
		var waiting := _vicar_waiting()
		match str(answer_button[1]):
			"dizimo":
				var tithe := _vicar_demand()
				vicar_button.text = "✝ Dízimo (%d)" % tithe
				vicar_button.disabled = not waiting or gold < tithe
			"suborno":
				var bribe := _vicar_bribe()
				vicar_button.text = "🤝 Suborno (%d)" % bribe
				vicar_button.disabled = not waiting or gold < bribe
			"recusa":
				vicar_button.text = "🚪 Recusar (0)"
				vicar_button.disabled = not waiting
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
		var would_go := _pick_adventurer(destination_id)
		var would_fee := int(would_go.get("fee", 0))
		if e < expedition_labels.size():
			if on_the_road:
				var trip_summary := _expedition_trip_summary(on_the_road, _world_seconds_since_tick())
				expedition_labels[e].text = trip_summary
				expedition_labels[e].add_theme_color_override("font_color", Color(1.0, 0.52, 0.38) if trip_summary.contains("⚔") else Color(1.0, 0.84, 0.55))
			elif not open_route:
				expedition_labels[e].text = "🔒 %s" % Expedition.locked_hint(destination)
				expedition_labels[e].add_theme_color_override("font_color", Color(0.74, 0.82, 0.78))
			else:
				# A linha de espera mostra o risco honesto de quem partiria agora: o
				# perigo cru da tabela, e o que sobra depois da mão do batedor.
				var bare_risk := Expedition.mishap_chance(destination, _expedition_luck())
				var armed_risk := Expedition.mishap_chance(destination, _expedition_luck() + int(would_go.get("skill", 0)))
				var pack_line := " sem batedor" if would_go.is_empty() else (
					" com %s" % str(would_go["gear_name"]) if int(would_go["gear"]) >= 0 else " de mochila vazia")
				expedition_labels[e].text = "%s • risco %d%% • %s: risco %d%%%s • %s" % [
					Expedition.days_label(_expedition_duration(destination)), bare_risk,
					"batedor anônimo" if would_go.is_empty() else "%s Nv.%d (+%d)" % [
						str(would_go["name"]), int(would_go["level"]), int(would_go["skill"])],
					armed_risk, pack_line, Expedition.preview(destination)]
				expedition_labels[e].add_theme_color_override("font_color", Color(0.74, 0.82, 0.78))
		if e < expedition_buttons.size():
			expedition_buttons[e].text = "Voltando…" if on_the_road != {} else (
				"Mandar (%d)" % (trip_cost + would_fee) if would_fee > 0 else "Mandar (%d)" % trip_cost)
			expedition_buttons[e].disabled = on_the_road != {} or not open_route \
				or gold < trip_cost + would_fee or expeditions.size() >= _expedition_slots()
		if e < expedition_pick_buttons.size():
			var pick_button := expedition_pick_buttons[e] as Button
			var picked_id := str(route_pick.get(destination_id, ""))
			var picked_seat := Adventurers.find(picked_id)
			var picked_name := "o mais capaz" if picked_id.is_empty() else str(picked_seat.get("name", "?"))
			pick_button.text = "Quem: %s ▸" % picked_name
			pick_button.disabled = adventurers_hired.is_empty()
	# O cadastro: quem tem bota, o que a estrada já lhe ensinou e o que ele levaria.
	for b in range(Adventurers.DATA.size()):
		var batedor: Dictionary = Adventurers.DATA[b]
		var batedor_id := str(batedor["id"])
		var no_cadastro := adventurers_hired.has(batedor_id)
		var na_estrada := _adventurer_on_road(batedor_id)
		var porta := Adventurers.gate(batedor, _adventurer_gate_state())
		var xp_guardada := _adventurer_xp(batedor_id)
		var peca := _packable_gear(batedor)
		var sorte := Adventurers.skill_of(batedor, xp_guardada, str(batedor.get("route", "")), int(peca.get("tier", -1)))
		if b < adventurer_labels.size():
			var route_name := "sem rota de casa" if str(batedor.get("route", "")).is_empty() else str(
				Expedition.find(str(batedor["route"])).get("name", "?"))
			var mochila := "mochila vazia"
			if str(batedor.get("gear", "")).is_empty():
				mochila = "não aceita peça"
			elif not pack_gear:
				mochila = "mochila guardada"
			elif not peca.is_empty():
				mochila = "%s (%s)" % [_gear_label(batedor), str(Quality.tier(int(peca["tier"]))["name"])]
			else:
				mochila = "sem %s na prateleira" % _gear_label(batedor)
			var estado := ""
			if na_estrada:
				estado = " • NA ESTRADA"
			elif no_cadastro:
				estado = " • no cadastro"
			elif porta != "":
				estado = " • %s" % porta
			else:
				estado = " • livre"
			(adventurer_labels[b] as Label).text = "%s — %s • %s • sorte %s • conhece: %s • mochila: %s%s" % [
				str(batedor["name"]), str(batedor["role"]), Adventurers.level_line(xp_guardada),
				"%d" % sorte if no_cadastro else "até %d" % sorte, route_name, mochila, estado]
		if b < adventurer_buttons.size():
			var adv_button := adventurer_buttons[b] as Button
			var fee_atual := Adventurers.fee_for(batedor, xp_guardada)
			adv_button.disabled = not no_cadastro and (porta != "" or gold < int(batedor["hire"]))
			adv_button.text = "Estrada, voltando…" if na_estrada else (
				"Dispensar • economiza %d/viagem" % fee_atual if no_cadastro else (
					"Contratar (%d) • %d/viagem" % [int(batedor["hire"]), fee_atual]
					if porta == "" else "Sem vaga: %s" % porta))
	if is_instance_valid(adventurer_summary_label):
		var na_rota := 0
		for trip in expeditions:
			if not str(trip.get("who", "")).is_empty():
				na_rota += 1
		adventurer_summary_label.text = "NO CADASTRO: %d de %d • %d com nome na estrada • %d peça(s) já foram na mochila. %s%s" % [
			adventurers_hired.size(), Adventurers.size(), na_rota, gear_packed,
			Adventurers.roster_line(adventurers_hired, adventurer_xp) if not adventurers_hired.is_empty() else "ninguém com bota amarrada",
			" • mochila armada" if pack_gear else " • mochila guardada"]
	if is_instance_valid(pack_gear_button):
		pack_gear_button.text = "🎒 Mochila: ARMADA (a peça sai do estoque)" if pack_gear else "🎒 Mochila: guardada (a peça fica à venda)"
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
		var rebuilt := {
			"id": trip_id,
			"remaining": clampf(float(trip.get("remaining", total)), 0.0, total),
			"total": total,
			"who": str(trip.get("who", "")),
			"level": int(trip.get("level", 1)),
			"skill": int(trip.get("skill", 0)),
			"gear": int(trip.get("gear", -1)),
			"gear_name": str(trip.get("gear_name", "")),
		}
		# Save de antes da mecânica acorda sem nome na bota, e nome que saiu da
		# tabela não pode continuar viajando com a sorte emprestada de outro.
		if not str(rebuilt["who"]).is_empty() and not Adventurers.knows(str(rebuilt["who"])):
			rebuilt["who"] = ""
			rebuilt["level"] = 1
			rebuilt["skill"] = 0
			rebuilt["gear"] = -1
			rebuilt["gear_name"] = ""
		expeditions.append(rebuilt)

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "gold", gold)
	config.set_value("game", "reputation", reputation)
	config.set_value("game", "customers_served", customers_served)
	config.set_value("game", "affection", affection)
	config.set_value("game", "fury", fury)
	config.set_value("game", "weather", weather)
	config.set_value("game", "weather_star", weather_star)
	config.set_value("game", "weather_seen", weather_seen)
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
	config.set_value("game", "rivals_absorbed", rivals_absorbed)
	config.set_value("game", "staff_hired", staff_hired)
	config.set_value("game", "servants", servants)
	# A cela via em duas listas paralelas: ConfigFile lê aninhamento como Variant e
	# um dicionário dentro de Array é exatamente o tipo que se perde no carregamento.
	var prisoner_names: Array[String] = []
	var prisoner_ids: Array[String] = []
	for held in prisoners:
		prisoner_names.append(str(held.get("name", "")))
		prisoner_ids.append(str(held.get("regular_id", "")))
	config.set_value("game", "prisoner_names", prisoner_names)
	config.set_value("game", "prisoner_ids", prisoner_ids)
	config.set_value("game", "mess", mess)
	config.set_value("game", "sweeps_done", sweeps_done)
	config.set_value("game", "blood_harvested", blood_harvested)
	config.set_value("game", "banned_regulars", banned_regulars)
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
	config.set_value("game", "locale", locale)
	config.set_value("game", "locale_confirmed", locale_confirmed)
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
	config.set_value("game", "shelf_batches", shelf_batches)
	config.set_value("game", "cold_storage_level", cold_storage_level)
	config.set_value("game", "difficulty", difficulty)
	config.set_value("game", "difficulty_days", difficulty_days)
	config.set_value("game", "credit_rank", credit_rank)
	config.set_value("game", "credit_book", credit_book)
	config.set_value("game", "credit_paid", credit_paid)
	config.set_value("game", "credit_written", credit_written)
	config.set_value("game", "credit_lost_gold", credit_lost_gold)
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
	config.set_value("game", "lab_trials", lab_trials)
	config.set_value("game", "lab_mix", lab_mix)
	config.set_value("game", "lab_hints", lab_hints)
	config.set_value("game", "lab_discovered", lab_discovered)
	config.set_value("game", "lab_flops", lab_flops)
	config.set_value("game", "vip_rank", vip_rank)
	config.set_value("game", "vip_served", vip_served)
	config.set_value("game", "vip_refusals", vip_refusals)
	config.set_value("game", "vip_tips_gold", vip_tips_gold)
	config.set_value("game", "complaints", complaints)
	config.set_value("game", "complaints_written", complaints_written)
	config.set_value("game", "complaints_hushed", complaints_hushed)
	config.set_value("game", "combo_rank", combo_rank)
	config.set_value("game", "combo_streak", combo_streak)
	config.set_value("game", "combo_best", combo_best)
	config.set_value("game", "combo_gold", combo_gold)
	config.set_value("game", "queue_distractions", queue_distractions)
	config.set_value("game", "products", products)
	# O que a forja ainda não terminou é dinheiro do jogador em andamento: perder
	# isso ao fechar o jogo era trabalhar de graça na última sessão do dia.
	config.set_value("game", "ticks", ticks)
	config.set_value("game", "craft_jobs", craft_jobs)
	config.set_value("game", "catalyst_enabled", catalyst_enabled)
	config.set_value("game", "adventurers_hired", adventurers_hired)
	config.set_value("game", "adventurer_xp", adventurer_xp)
	config.set_value("game", "route_pick", route_pick)
	config.set_value("game", "pack_gear", pack_gear)
	config.set_value("game", "gear_packed", gear_packed)
	config.set_value("game", "tithe_stance", tithe_stance)
	config.set_value("game", "tithe_until", tithe_until)
	config.set_value("game", "tithe_demands", tithe_demands)
	config.set_value("game", "tithe_paid_total", tithe_paid_total)
	config.set_value("game", "vicar_refusals", vicar_refusals)
	config.set_value("game", "vicar_bribes", vicar_bribes)
	config.set_value("game", "invasions_repelled", invasions_repelled)
	config.set_value("game", "invasions_lost", invasions_lost)
	config.set_value("game", "defense_privileges", defense_privileges)
	config.set_value("game", "last_invasion", last_invasion)
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
	weather = str(config.get_value("game", "weather", weather))
	if not WEATHER.has(weather):
		weather = "limpo"
	weather_star = str(config.get_value("game", "weather_star", weather_star))
	var saved_weather_seen = config.get_value("game", "weather_seen", {})
	if saved_weather_seen is Dictionary:
		for seen_weather in saved_weather_seen.keys():
			if WEATHER.has(str(seen_weather)):
				weather_seen[str(seen_weather)] = true
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
	# A praça só lembra de quem você comprou. Uma placa que sumiu da tabela é
	# absorvida de novo em vez de travar o carregamento.
	var saved_rivals = config.get_value("game", "rivals_absorbed", [])
	rivals_absorbed.clear()
	if saved_rivals is Array:
		for rival_id in saved_rivals:
			if Rivals.knows(str(rival_id)) and not rivals_absorbed.has(str(rival_id)):
				rivals_absorbed.append(str(rival_id))
	# Save antigo não tem folha: o balcão acorda só com a chefe, sem salário nenhum
	# na conta, exatamente como era antes de a loja contratar gente.
	var saved_staff = config.get_value("game", "staff_hired", [])
	staff_hired.clear()
	if saved_staff is Array:
		for seat_id in saved_staff:
			if Staff.knows(str(seat_id)) and not staff_hired.has(str(seat_id)):
				staff_hired.append(str(seat_id))
	# Cadastro de estrada: nome que não existe mais na tabela cai fora, e o XP só é
	# lido para os nomes que ficaram — sem contrato aberto, XP vira memória guardada.
	var saved_adventurers = config.get_value("game", "adventurers_hired", [])
	adventurers_hired.clear()
	if saved_adventurers is Array:
		for adv_id in saved_adventurers:
			if Adventurers.knows(str(adv_id)) and not adventurers_hired.has(str(adv_id)):
				adventurers_hired.append(str(adv_id))
	var saved_xp = config.get_value("game", "adventurer_xp", {})
	adventurer_xp.clear()
	if saved_xp is Dictionary:
		for adv_id in saved_xp.keys():
			var key := str(adv_id)
			if Adventurers.knows(key):
				adventurer_xp[key] = maxi(0, int(saved_xp[adv_id]))
	var saved_pick = config.get_value("game", "route_pick", {})
	route_pick.clear()
	if saved_pick is Dictionary:
		for route_id in saved_pick.keys():
			var route := str(route_id)
			if Expedition.find(route).is_empty():
				continue
			var picked := str(saved_pick[route_id])
			if picked.is_empty() or Adventurers.knows(picked):
				route_pick[route] = picked
	pack_gear = bool(config.get_value("game", "pack_gear", pack_gear))
	gear_packed = maxi(0, int(config.get_value("game", "gear_packed", gear_packed)))
	# A porta é da casa, então a resposta dada ao vigário atravessa o save — mas só
	# quando ainda faz sentido: postura que não está na lista é silêncio, e dia vencido
	# não ganha escudo eterno por um número adulterado. Carimbo e privilégio vêm
	# clampados na tabela, porque save antigo acorda sem campanha nenhuma.
	var saved_stance := str(config.get_value("game", "tithe_stance", ""))
	tithe_stance = saved_stance if saved_stance in ["", "pago", "subornado", "recusado"] else ""
	tithe_until = maxi(0, int(config.get_value("game", "tithe_until", 0)))
	tithe_demands = maxi(0, int(config.get_value("game", "tithe_demands", 0)))
	tithe_paid_total = maxi(0, int(config.get_value("game", "tithe_paid_total", 0)))
	vicar_refusals = maxi(0, int(config.get_value("game", "vicar_refusals", 0)))
	vicar_bribes = maxi(0, int(config.get_value("game", "vicar_bribes", 0)))
	invasions_repelled = maxi(0, int(config.get_value("game", "invasions_repelled", 0)))
	invasions_lost = maxi(0, int(config.get_value("game", "invasions_lost", 0)))
	var saved_privileges = config.get_value("game", "defense_privileges", [])
	defense_privileges.clear()
	if saved_privileges is Array:
		for privilege_id in saved_privileges:
			if Invasions.knows_privilege(str(privilege_id)) and not defense_privileges.has(str(privilege_id)):
				defense_privileges.append(str(privilege_id))
	last_invasion = str(config.get_value("game", "last_invasion", ""))
	# O afeto atravessa a vida, mas só com nome que ainda existe na lista: um save
	# de antes da mecânica acorda sem servo nenhum, e um nome raspado de Regulars
	# não pode continuar trabalhando de graça.
	var saved_servants = config.get_value("game", "servants", [])
	servants.clear()
	if saved_servants is Array:
		for servant_id in saved_servants:
			if not Regulars.find(str(servant_id)).is_empty() and not servants.has(str(servant_id)):
				servants.append(str(servant_id))
	mess = clampi(int(config.get_value("game", "mess", mess)), 0, MESS_LIMIT)
	sweeps_done = maxi(0, int(config.get_value("game", "sweeps_done", sweeps_done)))
	blood_harvested = maxi(0, int(config.get_value("game", "blood_harvested", blood_harvested)))
	var saved_banned = config.get_value("game", "banned_regulars", [])
	banned_regulars.clear()
	if saved_banned is Array:
		for banned_id in saved_banned:
			if not Regulars.find(str(banned_id)).is_empty() and not banned_regulars.has(str(banned_id)):
				banned_regulars.append(str(banned_id))
	# Cela e banido atravessam o carregamento pelas paralelas: nome na linha de
	# frente, id atrás, e o que não for freguês de casa vem com id vazio.
	var saved_names = config.get_value("game", "prisoner_names", [])
	var saved_ids = config.get_value("game", "prisoner_ids", [])
	prisoners.clear()
	if saved_names is Array and saved_ids is Array:
		for held in range(mini(saved_names.size(), saved_ids.size())):
			prisoners.append({"name": str(saved_names[held]), "regular_id": str(saved_ids[held])})
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
	# O idioma do save só entra em cena quando o arquivo de preferências não falou:
	# é o caminho do save importado em outra máquina, que traz a língua junto.
	if not _locale_from_settings:
		var saved_locale := str(config.get_value("game", "locale", ""))
		if Locales.knows(saved_locale):
			locale = saved_locale
		locale_confirmed = bool(config.get_value("game", "locale_confirmed", false))
	demonic_form_active = fury >= 4
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
	cold_storage_level = clampi(int(config.get_value("game", "cold_storage_level", cold_storage_level)), 0, 3)
	# A idade da prateleira vem depois do `shop_day` e do registro de qualidade: peça
	# sem dia registrado, ou com dia no futuro, entra como recém-posta. Save antigo
	# acorda com a despensa fresca, não com ela virada.
	var saved_batches = config.get_value("game", "shelf_batches", {})
	shelf_batches = {}
	if saved_batches is Dictionary:
		for product_id in (saved_batches as Dictionary).keys():
			var kept: Array = []
			var saved_list = (saved_batches as Dictionary)[product_id]
			if saved_list is Array:
				for entry in saved_list:
					if not (entry is Dictionary):
						continue
					var day := int((entry as Dictionary).get("day", shop_day))
					if day > shop_day or day < 1:
						day = shop_day
					kept.append({
						"tier": clampi(int((entry as Dictionary).get("tier", 1)), 0, Quality.size() - 1),
						"day": day,
					})
			shelf_batches[str(product_id)] = kept
	# A regra da casa é escolha, não conta: id fora da tabela (save adulterado, ou modo
	# que deixou de existir) volta ao Calçada, e dia de modo fantasma some do caderno.
	# Save antigo não tem as chaves e acorda no Calçada com o caderno vazio.
	var saved_difficulty := str(config.get_value("game", "difficulty", difficulty))
	difficulty = str(_difficulty_row(saved_difficulty)["id"])
	var saved_days = config.get_value("game", "difficulty_days", {})
	difficulty_days = {}
	if saved_days is Dictionary:
		for id in (saved_days as Dictionary).keys():
			var dia := maxi(0, int((saved_days as Dictionary)[id]))
			if dia <= 0 or str(_difficulty_row(str(id))["id"]) != str(id):
				continue
			difficulty_days[str(id)] = dia
	# O livro de fiado volta como estava, mas sem nota impossível: deve quem a casa
	# conhece, deve ouro de verdade e vence num dia que ainda existe. Payload lixo
	# (id fantasma, owed 0, prazo negativo) é riscado na entrada, não cobrado para sempre.
	credit_rank = clampi(int(config.get_value("game", "credit_rank", credit_rank)), 0, CREDIT_TIERS.size() - 1)
	credit_paid = maxi(0, int(config.get_value("game", "credit_paid", credit_paid)))
	credit_written = maxi(0, int(config.get_value("game", "credit_written", credit_written)))
	credit_lost_gold = maxi(0, int(config.get_value("game", "credit_lost_gold", credit_lost_gold)))
	var saved_book = config.get_value("game", "credit_book", {})
	credit_book = {}
	if saved_book is Dictionary:
		for debtor_id in (saved_book as Dictionary).keys():
			var id := str(debtor_id)
			var raw = (saved_book as Dictionary)[debtor_id]
			if id.is_empty() or Regulars.find(id).is_empty() or not (raw is Dictionary):
				continue
			var entry: Dictionary = raw
			var owed := int(entry.get("owed", 0))
			var due_day := int(entry.get("due_day", 0))
			if owed <= 0 or due_day <= 0:
				continue
			credit_book[id] = {
				"name": str(entry.get("name", Regulars.find(id).get("short", "O devedor"))),
				"item": str(entry.get("item", "uma peça do balcão")),
				"owed": owed,
				"due_day": due_day,
				"late": clampi(int(entry.get("late", 0)), 0, CREDIT_WRITEOFF_DAYS - 1),
			}
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
	# A bancada lê o arquivo com tesoura: assinatura que não é de ingrediente do mercado
	# não entra, id de receita inventado cai do resultado do ensaio, e a mesa em brasa
	# volta limitada ao que a casa comporta e ao que o estoque ainda tem. Um save antigo,
	# sem nenhuma destas chaves, acorda com a mesa raspada e o caderno em branco.
	var saved_trials = config.get_value("game", "lab_trials", {})
	lab_trials.clear()
	if saved_trials is Dictionary:
		for saved_key in saved_trials.keys():
			var trial_key := str(saved_key)
			if not _lab_signature_valid(trial_key):
				continue
			var trial_outcome := str(saved_trials[saved_key])
			var kept_outcomes: Array[String] = []
			if not trial_outcome.is_empty():
				for saved_recipe_id in trial_outcome.split(","):
					var outcome_id := str(saved_recipe_id)
					if not _product_by_id(outcome_id).is_empty() and not kept_outcomes.has(outcome_id):
						kept_outcomes.append(outcome_id)
			lab_trials[trial_key] = ",".join(kept_outcomes)
	var saved_mix = config.get_value("game", "lab_mix", {})
	lab_mix.clear()
	if saved_mix is Dictionary:
		var mix_units := 0
		# Percorre o catálogo, não as chaves do arquivo: a ordem do dicionário lido do
		# disco não é garantida, e a mesa tem de montar a mesma mistura duas cargas seguidas.
		for ingredient in Ingredients.DATA:
			var mix_kind := str(ingredient["id"])
			if not saved_mix.has(mix_kind):
				continue
			var planned := clampi(int(saved_mix[mix_kind]), 0, int(ingredient_stock.get(mix_kind, 0)))
			if planned <= 0 or lab_mix.size() >= LAB_MAX_KINDS or mix_units + planned > LAB_MAX_UNITS:
				continue
			lab_mix[mix_kind] = planned
			mix_units += planned
	lab_hints = _lab_ids_from_file(config.get_value("game", "lab_hints", []))
	lab_discovered = _lab_ids_from_file(config.get_value("game", "lab_discovered", []))
	lab_flops = maxi(0, int(config.get_value("game", "lab_flops", lab_flops)))
	vip_rank = clampi(int(config.get_value("game", "vip_rank", vip_rank)), 0, VIP_TIERS.size() - 1)
	vip_served = maxi(0, int(config.get_value("game", "vip_served", vip_served)))
	vip_refusals = maxi(0, int(config.get_value("game", "vip_refusals", vip_refusals)))
	vip_tips_gold = maxi(0, int(config.get_value("game", "vip_tips_gold", vip_tips_gold)))
	complaints = clampi(int(config.get_value("game", "complaints", complaints)), 0, COMPLAINT_CAP)
	complaints_written = maxi(0, int(config.get_value("game", "complaints_written", complaints_written)))
	complaints_hushed = clampi(maxi(0, int(config.get_value("game", "complaints_hushed", complaints_hushed))), 0, complaints_written)
	combo_rank = clampi(int(config.get_value("game", "combo_rank", combo_rank)), 0, COMBO_TIERS.size() - 1)
	combo_streak = clampi(int(config.get_value("game", "combo_streak", combo_streak)), 0, COMBO_CEIL)
	combo_best = clampi(maxi(0, int(config.get_value("game", "combo_best", combo_best))), 0, COMBO_CEIL)
	combo_gold = maxi(0, int(config.get_value("game", "combo_gold", combo_gold)))
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
			var saved_remaining := maxf(0.5, float(saved_job.get("remaining", 0.5)))
			craft_jobs.append({
				"index": job_index,
				"remaining": saved_remaining,
				"total": maxf(saved_remaining, float(saved_job.get("total", 0.0))),
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
		{"id": "weather_six", "name": "Previsão da casa (seis tempos diferentes na porta)", "condition": weather_seen.size() >= WEATHER.size(), "gold": 60, "rep": 3},
		{"id": "ritual_apprentice", "name": "Aprendiz de Ritos (3 rituais)", "condition": rituals_performed >= 3, "gold": 40, "rep": 2},
		{"id": "ritual_devotee", "name": "Fiel do Santuário (10 rituais)", "condition": rituals_performed >= 10, "gold": 100, "rep": 5, "pose": "book"},
		{"id": "first_expedition", "name": "Pé na Estrada (primeira expedição)", "condition": expeditions_done >= 1, "gold": 30, "rep": 1},
		{"id": "route_regular", "name": "Corredor do Abismo (10 expedições de volta)", "condition": expeditions_done >= 10, "gold": 90, "rep": 4, "pose": "relic"},
		{"id": "adventurer_hired", "name": "Nome na bota (primeiro batedor no cadastro)", "condition": not adventurers_hired.is_empty(), "gold": 110, "rep": 3},
		{"id": "adventurer_maxed", "name": "Teto da estrada (um batedor no nível máximo)", "condition": _adventurer_top_level() >= Adventurers.max_level(), "gold": 320, "rep": 11, "pose": "vitoria"},
		{"id": "adventurer_roster", "name": "Cadastro cheio (os cinco nomes com bota amarrada)", "condition": adventurers_hired.size() >= Adventurers.size(), "gold": 460, "rep": 15, "pose": "aplausos"},
		{"id": "gear_three", "name": "Três peças na estrada (estoque virou mochila)", "condition": gear_packed >= 3, "gold": 200, "rep": 6, "pose": "desconfianca"},
		{"id": "first_door", "name": "Porta de madeira (primeira visita barrada)", "condition": invasions_repelled >= 1, "gold": 90, "rep": 3},
		{"id": "door_three", "name": "Três portas seguradas (o beco já decorou o endereço)", "condition": invasions_repelled >= 3, "gold": 200, "rep": 6, "pose": "vitoria"},
		{"id": "defense_campaign", "name": "A casa tem milícia (os três degraus da defesa)", "condition": defense_privileges.size() >= Invasions.PRIVILEGES.size(), "gold": 520, "rep": 16, "pose": "aplausos"},
		{"id": "door_breach", "name": "Piso molhado (a porta já cedeu)", "condition": invasions_lost >= 1, "gold": 40, "rep": 1},
		{"id": "tithe_paid", "name": "Dízimo em dia (a paróquia cita o balcão)", "condition": tithe_paid_total > 0, "gold": 60, "rep": 2},
		{"id": "vicar_bribed", "name": "Pastoral, não simonia (o vigário no bolso)", "condition": vicar_bribes >= 1, "gold": 130, "rep": 4, "pose": "ousadia"},
		{"id": "vicar_refused", "name": "Porta na cara do céu (uma recusa)", "condition": vicar_refusals >= 1, "gold": 75, "rep": 3},
		{"id": "rare_hoarder", "name": "Vitrine de Raridades (3 raridades no estoque)", "condition": rare_found >= 3, "gold": 70, "rep": 3},
		{"id": "catalyst_touch", "name": "Toque de Catalisador (peça rara na forja)", "condition": catalyst_crafted >= 1, "gold": 60, "rep": 3, "pose": "relic"},
		{"id": "library_master", "name": "Bibliotecária do Submundo (Biblioteca Nv.3)", "condition": library_upgrade_level >= 3, "gold": 80, "rep": 4, "pose": "book"},
		{"id": "sanctum_keeper", "name": "Guardiã das Relíquias (Santuário Nv.3)", "condition": sanctum_upgrade_level >= 3, "gold": 90, "rep": 5, "pose": "relic"},
		{"id": "salt_shelf", "name": "Sal na prateleira (Depósito de sal Nv.3)", "condition": cold_storage_level >= 3, "gold": 70, "rep": 4},
		{"id": "poco_atravessado", "name": "Poço Sem Fundo por %d dias de balcão" % HARDEST_LIFE_DAYS, "condition": int(difficulty_days.get("poco_sem_fundo", 0)) >= HARDEST_LIFE_DAYS, "gold": 90, "rep": 5},
		{"id": "credit_paid_five", "name": "Quem deve, paga (5 notas quitadas no balcão)", "condition": credit_paid >= 5, "gold": 75, "rep": 4},
		{"id": "credit_red_ink", "name": "Tinta vermelha no livro (3 notas riscadas)", "condition": credit_written >= 3, "gold": 50, "rep": 0},
		{"id": "lab_first_spark", "name": "Primeira faísca na bancada (receita travada descoberta por ensaio)", "condition": lab_discovered.size() >= 1, "gold": 60, "rep": 3, "pose": "book"},
		{"id": "lab_full_bench", "name": "A bancada venceu o nível (%d receitas travadas arrancadas por ensaio)" % _lab_targets_total(), "condition": lab_discovered.size() >= _lab_targets_total(), "gold": 300, "rep": 12, "pose": "aplausos"},
		{"id": "vip_first_robe", "name": "Capa fina no balcão (1 visita do salão servida com o topo da barra)", "condition": vip_served >= 1, "gold": 40, "rep": 2, "pose": "ousadia"},
		{"id": "vip_full_salon", "name": "Salão de capas (10 visitas do salão servidas)", "condition": vip_served >= 10, "gold": 220, "rep": 8, "pose": "vitoria"},
		{"id": "claims_first_line", "name": "A rua abriu o livro (primeira reclamação anotada)", "condition": complaints_written >= 1, "gold": 0, "rep": 0},
		{"id": "claims_quiet_street", "name": "Boca calada (%d queixas apagadas pagando o cartório)" % (COMPLAINT_HUSH_ERASE * 3), "condition": complaints_hushed >= COMPLAINT_HUSH_ERASE * 3, "gold": 90, "rep": 3, "pose": "book"},
		{"id": "combo_three", "name": "Ritmo de balcão (três vendas seguidas premiadas no mesmo dia)", "condition": combo_best >= 3, "gold": 70, "rep": 2, "pose": "danca"},
		{"id": "combo_paid_back", "name": "O cartaz se paga (%d de ouro pagos em combo nesta vida)" % COMBO_PRIZE_GOLD, "condition": combo_gold >= COMBO_PRIZE_GOLD, "gold": 240, "rep": 9, "pose": "aplausos"},
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
		{"id": "rival_first", "name": "Placa desligada (primeira rival comprada)", "condition": not rivals_absorbed.is_empty(), "gold": 150, "rep": 5},
		{"id": "rival_all", "name": "A praça é sua (todas as rivais absorvidas)", "condition": rivals_absorbed.size() >= Rivals.size(), "gold": 600, "rep": 12, "pose": "danca"},
		{"id": "staff_full", "name": "Quadro cheio (as quatro vagas do balcão pagando salário juntas)", "condition": staff_hired.size() >= Staff.size(), "gold": 340, "rep": 12, "pose": "vitoria"},
		{"id": "staff_rounds", "name": "A ronda conhece o beco (três furtos barrados na mesma vida)", "condition": theft_blocked >= 3, "gold": 220, "rep": 8, "pose": "book"},
		{"id": "servant_first", "name": "Coração atrás do balcão (um freguês apaixonado entrando para a casa)", "condition": not servants.is_empty(), "gold": 140, "rep": 5, "pose": "beijo"},
		{"id": "servant_three", "name": "A casa tem coração (três servos trabalhando sem salário)", "condition": servants.size() >= 3, "gold": 380, "rep": 12, "pose": "aplausos"},
		{"id": "clean_five", "name": "A chefe conhece o peso da vassoura (cinco salões varridos em ouro)", "condition": sweeps_done >= 5, "gold": 90, "rep": 3, "pose": "felicidade"},
		{"id": "cell_blood", "name": "A cela paga o próprio prato (três frascos de sangue colhidos)", "condition": blood_harvested >= 3, "gold": 160, "rep": 4, "pose": "desconfianca"},
		{"id": "banish_one", "name": "Tem porta que tranca por fora (um freguês expulso do bairro)", "condition": not banned_regulars.is_empty(), "gold": 120, "rep": 2, "pose": "recusa"},
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
			last_event = "O pacote custa %d ouro. Fiado é para mercadoria, não para nostalgia." % price
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
		+ branches.size() * 90 + staff_hired.size() * 30 + servants.size() * 55 \
		+ rivals_absorbed.size() * 70 \
		+ _adventurer_score() \
		+ invasions_repelled * 45 + defense_privileges.size() * 70 \
		+ prisoners.size() * 10 + (MESS_LIMIT - mess) / 5 \
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
		+ Staff.total_wage(staff_hired) + CELL_FOOD * prisoners.size() \
		- SERVANT_UPKEEP_RELIEF * servants.size()
	## Conta de casa bem administrada encolhe 8% por marcha, e a conta é o que
	## segura o império: por isso a trilha mexe nela e não na receita. A regra da casa
	## multiplica o mesmo número — sob Juro Alto e Poço o aluguel chega maior.
	return maxi(1, int(round(float(bill) * (1.0 - 0.08 * float(house_rank)) * (0.9 if _has_spec("house", "livro") else 1.0) * _difficulty_upkeep_factor())))

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
## ── O livro de fiado ────────────────────────────────────────────────────────────
## Nenhum sorteio mora aqui embaixo. A nota nasce do preço que o balcão acabou de
## calcular, a quitação depende do bolso que a visita já tinha sorteado, e o atraso
## depende do dia que virava de qualquer jeito. Com o degrau zero a gaveta fica
## fechada: `_can_lend()` devolve false e a venda perdida continua perdida exatamente
## como as sondas antigas mediram.

## A etiqueta mais barata da prateleira: é a que a casa aceita no fiado, porque é a
## que o devedor tem mais chance de pagar. Empate fica com a que veio primeiro.
func _cheapest_index(candidates: Array[int]) -> int:
	var best := -1
	var best_price := 0
	for candidate in candidates:
		var price := _shelf_price(candidate)
		if best < 0 or price < best_price:
			best = candidate
			best_price = price
	return best


func _credit_row() -> Dictionary:
	return CREDIT_TIERS[clampi(credit_rank, 0, CREDIT_TIERS.size() - 1)]


func _credit_next_row() -> Dictionary:
	if credit_rank >= CREDIT_TIERS.size() - 1:
		return {}
	return CREDIT_TIERS[credit_rank + 1]


func _credit_limit() -> int:
	return int(_credit_row()["limit"])


func _credit_seats() -> int:
	return int(_credit_row()["seats"])


func _credit_due_days() -> int:
	return int(_credit_row()["due"])


## Fiado é nome, não moeda: só entra no livro quem já é freguês de casa (tem vínculo
## onde a cobrança pode bater), a etiqueta caiba no teto do degrau e sobre página no
## livro. Uma nota por freguês — a casa não empresta duas vezes para o mesmo nome.
func _can_lend(regular_id: String, price: int) -> bool:
	if credit_rank <= 0 or regular_id.is_empty():
		return false
	if price > _credit_limit():
		return false
	if credit_book.has(regular_id):
		return false
	return credit_book.size() < _credit_seats()


func _lend_note(regular_id: String, debtor: String, item_name: String, price: int) -> void:
	credit_book[regular_id] = {
		"name": debtor,
		"item": item_name,
		"owed": price,
		"due_day": shop_day + _credit_due_days(),
		"late": 0,
	}


## O devedor voltou ao balcão com o bolso na mão: paga primeiro a casa, e o que sobra
## é o que ele leva hoje. É por isso que quitar pode custar a venda do dia — o preço
## honesto de quem emprestou. Sem nota aberta, a visita segue o balcão de sempre.
func _settle_credit_note(regular_id: String) -> Dictionary:
	if regular_id.is_empty() or not credit_book.has(regular_id):
		return {}
	var note: Dictionary = credit_book[regular_id]
	var owed := int(note.get("owed", 0))
	if owed > current_customer_budget:
		return {}
	var late := int(note.get("late", 0))
	var interest := int(round(float(owed) * CREDIT_INTEREST)) if late > 0 else 0
	var purse := owed + interest
	gold += purse
	# O ouro da nota é caixa do dia em que chega, não do dia em que a peça saiu. Sem
	# esta linha o fiado saía do balanço duas vezes: a etiqueta contava como ganha na
	# venda e o pagamento, quando vinha, não aparecia em lugar nenhum.
	daily_gold_earned += purse
	_progress_contracts("gold", purse)
	credit_paid += 1
	credit_book.erase(regular_id)
	reputation += 1
	regular_bonds[regular_id] = int(regular_bonds.get(regular_id, 0)) + 1
	_add_xp(4)
	var tail := " (juro de %d por ter atrasado %d dia(s))" % [interest, late] if interest > 0 else ""
	return {
		"purse": purse,
		"line": "📖 %s quitou %d de fiado no balcão%s." % [str(note.get("name", "O devedor")), purse, tail],
	}


## A virada só envelhece o livro: quem não voltou ao balcão entra em atraso, e no
## terceiro dia de atraso a casa risca a nota. O ouro não volta, a reputação paga o
## prejuízo junto, e o vínculo do devedor desce um degrau — a praça inteira aprende o
## nome de quem não paga.
func _age_credit_book() -> String:
	if credit_book.is_empty():
		return ""
	var lines: Array[String] = []
	var riscadas: Array[String] = []
	for id in credit_book:
		var note: Dictionary = credit_book[id]
		if shop_day <= int(note.get("due_day", shop_day)):
			continue
		note["late"] = int(note.get("late", 0)) + 1
		if int(note["late"]) < CREDIT_WRITEOFF_DAYS:
			continue
		var debtor_id := str(id)
		var owed := int(note.get("owed", 0))
		credit_written += 1
		credit_lost_gold += owed
		reputation = maxi(0, reputation - 2)
		regular_bonds[debtor_id] = maxi(0, int(regular_bonds.get(debtor_id, 0)) - 1)
		# A nota riscada é a queixa mais barulhenta das três fontes: quem emprestou ouro e
		# não recebeu conta para a praça inteira, e a casa perde o nome junto com o dinheiro.
		_add_complaint(COMPLAINT_FROM_WRITE_OFF)
		lines.append("a casa riscou a nota de %s: %d de ouro que não voltam" % [
			str(note.get("name", "O devedor")), owed])
		riscadas.append(debtor_id)
	for id in riscadas:
		credit_book.erase(str(id))
	if lines.is_empty():
		return ""
	audio.play("sad")
	return "FIADO: %s • %d nota(s) no livro, %d de ouro na rua • %s" % [
		"; ".join(lines), credit_book.size(), _credit_on_street(), _complaint_tail(complaints)]


func _credit_on_street() -> int:
	var total := 0
	for id in credit_book:
		total += int((credit_book[id] as Dictionary).get("owed", 0))
	return total


## Abrir o livro é decisão de caixa e de fama: a casa só empresta para quem já a
## conhece, e o degrau seguinte custa o preço inteiro, sem desconto de entusiasmo.
func _buy_credit_rank() -> void:
	var next_row := _credit_next_row()
	if next_row.is_empty():
		last_event = "O livro já está no último degrau: %d notas de até %d, prazo de %d dias." % [
			_credit_seats(), _credit_limit(), _credit_due_days()]
		_show_feedback("📖 O livro está aberto até a última página.", Color(0.90, 0.82, 0.60))
		_refresh_ui()
		return
	if reputation < int(next_row["rep"]):
		last_event = "Abrir o fiado até o degrau %d pede %d de fama; a casa tem %d. Fiado é nome, não moeda." % [
			int(next_row["rank"]), int(next_row["rep"]), reputation]
		_show_feedback("✕ Falta fama para emprestar.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	var cost := int(next_row["cost"])
	if gold < cost:
		last_event = "O livro de fiado custa %d de ouro, e o caixa tem %d. Quem deve com a mão vazia não cobra." % [
			cost, gold]
		_show_feedback("✕ Falta ouro para abrir o livro.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	gold -= cost
	credit_rank = int(next_row["rank"])
	reputation += 1
	_add_xp(12)
	last_event = "📖 Livro de fiado no degrau %d: notas de até %d, %d lugares na rua e %d dias de prazo (−%d de ouro)." % [
		credit_rank, _credit_limit(), _credit_seats(), _credit_due_days(), cost]
	_show_feedback("✦ Fiado liberado no balcão.", Color(0.90, 0.82, 0.60))
	audio.play("coin")
	_check_achievements()
	_save_game()
	_refresh_ui()


func _credit_summary() -> String:
	if credit_rank <= 0:
		return "O livro está na gaveta: quem não tem com que pagar sai da loja sem a peça, como sempre saiu. Abrir o caderno custa %d de ouro e pede %d de fama." % [
			int(CREDIT_TIERS[1]["cost"]), int(CREDIT_TIERS[1]["rep"])]
	var head := "DEGRAU %d • nota de até %d • %d de %d lugares ocupados • %d de ouro na rua • prazo %d dias • %d quitada(s), %d riscada(s) (%d de prejuízo)." % [
		credit_rank, _credit_limit(), credit_book.size(), _credit_seats(),
		_credit_on_street(), _credit_due_days(), credit_paid, credit_written, credit_lost_gold]
	var notas: Array[String] = []
	for id in credit_book:
		var note: Dictionary = credit_book[id]
		var atraso := int(note.get("late", 0))
		notas.append(" • %s deve %d (vence dia %d%s)" % [
			str(note.get("name", "O devedor")), int(note.get("owed", 0)), int(note.get("due_day", 0)),
			", %d dia(s) de atraso" % atraso if atraso > 0 else "",
		])
	if not notas.is_empty():
		head += "\n" + "\n".join(notas)
	return head


## A linha de rodapé que toda fonte de queixa puxa: quantas linhas o livro tem agora e o que
## elas já cobram. Chamada por texto, sem emoji: quem imprime escolhe o marcador.
func _complaint_tail(depois: int) -> String:
	if _complaint_stage() == 0:
		return "O livro de reclamações da rua lê %d linha(s): faltam %d para a rua começar a cobrar, e cada virada de dia apaga uma." % [
			depois, COMPLAINT_LINE - depois]
	return "O livro de reclamações da rua lê %d linha(s) e cobra: etiqueta %s, paciência −%d, porta −%d por tique." % [
		depois, _label_word(), _complaint_patience_loss(), _complaint_crowd_loss()]


## ── O SALÃO DAS CAPAS FINAS ──────────────────────────────────────────────────────
## A fileira de trás do balcão: quem entra pelo cordão de veludo traz bolso maior, escolhe
## pelo topo da barra de qualidade e deixa gorjeta. Quem não paga nada disso é a visita com
## o cordão guardado — degrau zero devolve o perfil sorteado intacto e não consome um
## sorteio a mais, porque salão fechado tem de medir exatamente o balcão de sempre.

func _vip_row(rank: int) -> Dictionary:
	return VIP_TIERS[clampi(rank, 0, VIP_TIERS.size() - 1)]


func _vip_next_row() -> Dictionary:
	if vip_rank >= VIP_TIERS.size() - 1:
		return {}
	return VIP_TIERS[vip_rank + 1]


func _vip_standard() -> int:
	return int(_vip_row(vip_rank)["standard"])


func _vip_chance() -> int:
	return int(_vip_row(vip_rank)["chance"])


## Carimba a visita sorteada como capa fina: bolso, tempo de espera e o flag que o balcão
## lê para exigir o topo da barra.
func _maybe_vip(profile: Dictionary) -> Dictionary:
	if vip_rank <= 0:
		return profile
	if randi() % 100 >= _vip_chance():
		return profile
	var stamped := profile.duplicate(true)
	stamped["vip"] = true
	stamped["budget"] = int(round(float(int(stamped.get("budget", 60))) * float(_vip_row(vip_rank)["budget"])))
	stamped["patience"] = int(stamped.get("patience", 2)) + VIP_PATIENCE_BONUS
	return stamped


## O topo real da estante daquele produto: o maior degrau com peça em estoque, ou -1 se a
## prateleira está vazia. Lê registro, não sorteia e não tira peça nenhuma.
func _best_tier_for(index: int) -> int:
	if index < 0 or index >= products.size():
		return -1
	var stock := _quality_for(str(products[index]["id"]))
	for tier in range(Quality.size() - 1, -1, -1):
		if int(stock[tier]) > 0:
			return tier
	return -1


func _buy_vip_rank() -> void:
	var next_row := _vip_next_row()
	if next_row.is_empty():
		last_event = "O salão tem três cordões, e o terceiro já está estendido: %d%% das visitas chegam de capa e exigem %s no topo da barra." % [
			_vip_chance(), str(Quality.tier(_vip_standard())["name"])]
		_show_feedback("🎩 O cordão já está no último degrau.", Color(0.86, 0.78, 0.95))
		_refresh_ui()
		return
	if reputation < int(next_row["rep"]):
		last_event = "Estender o cordão até o degrau %d pede %d de fama; a casa tem %d. Capa fina entra por convite, não por caixa." % [
			int(next_row["rank"]), int(next_row["rep"]), reputation]
		_show_feedback("✕ Falta fama para o salão.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	var cost := int(next_row["cost"])
	if gold < cost:
		last_event = "O cordão de veludo custa %d de ouro, e o caixa tem %d. Salão sem moeda é salão sem espelho." % [cost, gold]
		_show_feedback("✕ Falta ouro para o salão.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	gold -= cost
	vip_rank = int(next_row["rank"])
	reputation += 1
	_add_xp(12)
	last_event = "🎩 Salão das capas finas no degrau %d: %d%% das visitas chegam de capa, bolso ×%.1f e a barra exige %s no topo (−%d de ouro)." % [
		vip_rank, _vip_chance(), float(_vip_row(vip_rank)["budget"]),
		str(Quality.tier(_vip_standard())["name"]), cost]
	_show_feedback("✦ O cordão de veludo está estendido.", Color(0.86, 0.78, 0.95))
	audio.play("coin")
	_check_achievements()
	_save_game()
	_refresh_ui()


func _vip_summary() -> String:
	if vip_rank <= 0:
		return "O cordão de veludo está enrolado na gaveta: nenhuma visita chega de capa fina, e o balcão atende como sempre atendeu. O primeiro cordão custa %d de ouro e pede %d de fama." % [
			int(VIP_TIERS[1]["cost"]), int(VIP_TIERS[1]["rep"])]
	return "DEGRAU %d • %d%% das visitas de capa fina • bolso ×%.1f • exige %s no topo da barra • gorjeta de %.0f%% sobre a tabela • %d servida(s), %d recusada(s), %d de ouro em gorjeta." % [
		vip_rank, _vip_chance(), float(_vip_row(vip_rank)["budget"]),
		str(Quality.tier(_vip_standard())["name"]), float(_vip_row(vip_rank)["tip"]) * 100.0,
		vip_served, vip_refusals, vip_tips_gold]


## ── O LIVRO DE RECLAMAÇÕES DA RUA ────────────────────────────────────────────────
## Queixa não é falta de fama: é a casa errando e a rua contando. As três linhas que o livro
## aceita são as três vezes em que o erro aparece na mão de alguém — a peça torto que saiu da
## forja, a capa fina devolvida na prateleira e a nota riscada no fiado. Até a sexta linha a
## rua só murmura: etiqueta, paciência e porta devolvem exatamente os números de sempre, e
## nada aqui consome sorteio. Da sexta a casa paga etiqueta e fila; da décima segunda, paga
## também a batida na porta. Apagar custa ouro e nunca compra fama.

## Anota `quanto` linhas e devolve o livro já atualizado. O teto é do livro, não da história:
## `complaints_written` continua contando tudo que a rua já ouviu.
func _add_complaint(quanto: int) -> int:
	if quanto <= 0:
		return complaints
	complaints_written += quanto
	complaints = mini(COMPLAINT_CAP, complaints + quanto)
	return complaints


## 0 = ainda não cobra nada, 1 = boato (etiqueta e fila), 2 = escândalo (etiqueta, fila e porta).
func _complaint_stage() -> int:
	if complaints >= COMPLAINT_SCANDAL:
		return 2
	if complaints >= COMPLAINT_LINE:
		return 1
	return 0


## O desconto que a rua arranca da etiqueta. Abaixo da sexta linha é exatamente 1.0 — e
## multiplicar por 1.0 não move um centavo de nenhuma conta já medida neste repo.
func _complaint_label_factor() -> float:
	if _complaint_stage() == 0:
		return 1.0
	return 1.0 - minf(COMPLAINT_LABEL_MAX, float(complaints - COMPLAINT_LINE + 1) * COMPLAINT_LABEL_STEP)


func _complaint_patience_loss() -> int:
	return COMPLAINT_PATIENCE_LOSS[_complaint_stage()]


func _complaint_crowd_loss() -> int:
	return COMPLAINT_CROWD_LOSS[_complaint_stage()]


## A rua esquece uma linha por virada. Sem dado, sem conta, sem ouro: só a memória curta.
func _complaints_forget() -> void:
	if complaints > 0:
		complaints -= 1


func _hush_cost() -> int:
	return COMPLAINT_HUSH_BASE + COMPLAINT_HUSH_PER_LINE * complaints


func _hush_street() -> void:
	if complaints <= 0:
		last_event = "O livro está em branco: não há o que a rua cobrar de você nesta vida."
		_show_feedback("📗 Ninguém fala mal da casa.", Color(0.72, 0.90, 0.74))
		_refresh_ui()
		return
	var cost := _hush_cost()
	if gold < cost:
		last_event = "Calar a boca da rua com %d linha(s) no livro custa %d de ouro, e o caixa tem %d. A rua espera." % [
			complaints, cost, gold]
		_show_feedback("✕ Falta ouro para o cartório.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	gold -= cost
	var antes := _complaint_stage()
	var apagadas := mini(COMPLAINT_HUSH_ERASE, complaints)
	complaints -= apagadas
	complaints_hushed += apagadas
	last_event = "🗣 A casa paga %d de ouro ao cartório da praça e risca %d linha(s): restam %d no livro, e a etiqueta volta a %s." % [
		cost, apagadas, complaints, _label_word()]
	if _complaint_stage() < antes:
		_show_feedback("✦ A rua baixa o tom.", Color(0.86, 0.72, 0.58))
	else:
		_show_feedback("✦ O cartório risca a linha.", Color(0.86, 0.72, 0.58))
	audio.play("coin")
	_check_achievements()
	_save_game()
	_refresh_ui()


## Como a etiqueta está de pé agora, do jeito que o balcão a lê.
func _label_word() -> String:
	var corte := int(round((1.0 - _complaint_label_factor()) * 100.0))
	if corte <= 0:
		return "cheia"
	return "%d%% abaixo" % corte


func _complaint_summary() -> String:
	var stage := _complaint_stage()
	var base := "%d linha(s) já escritas, %d apagadas pagando." % [complaints_written, complaints_hushed]
	if complaints <= 0:
		return "📗 O livro está em branco: a rua não tem o que contar da sua casa. Peça torto na mão de alguém, capa fina devolvida e nota riscada no fiado são as três linhas que ele aceita — e cada virada de dia apaga o que estiver escrito."
	if stage == 0:
		return "📙 MURMÚRIO • %d linha(s) no livro: a rua ainda não cobra nada (%d para a sexta). Cada virada de dia esquece uma linha, e a voz da rua custa %d de ouro por %d apagada(s). %s" % [
			complaints, COMPLAINT_LINE - complaints, _hush_cost(), COMPLAINT_HUSH_ERASE, base]
	return "📕 %s • %d linha(s) no livro • etiqueta %s • paciência −%d • porta −%d por tique • cada virada esquece uma linha, e a voz da rua custa %d de ouro por %d apagada(s). %s" % [
		"BOATO" if stage == 1 else "ESCÂNDALO", complaints, _label_word(),
		_complaint_patience_loss(), _complaint_crowd_loss(), _hush_cost(),
		COMPLAINT_HUSH_ERASE, base]


## ── O CARTAZ DO COMBO ───────────────────────────────────────────────────────────
## O ritmo do balcão no mesmo dia: vendas seguidas, sem ninguém batendo a porta no
## meio. O cartaz é escada de três degraus e o degrau zero é inerte por desenho — a
## casa conta a sequência, mas só paga quem pendurou o cartaz, porque a régua do
## README e as sondas antigas medem exatamente o balcão sem ele.

func _combo_row(rank: int) -> Dictionary:
	return COMBO_TIERS[clampi(rank, 0, COMBO_TIERS.size() - 1)]


func _combo_next_row() -> Dictionary:
	if combo_rank >= COMBO_TIERS.size() - 1:
		return {}
	return COMBO_TIERS[combo_rank + 1]


## Fatia da etiqueta de tabela que o ritmo paga agora. Zero com o cartaz guardado e
## zero antes da `start`-ésima venda seguida; nada aqui toca o `randi()` da loja.
func _combo_rate() -> float:
	if combo_rank <= 0:
		return 0.0
	var row := _combo_row(combo_rank)
	if combo_streak < int(row["start"]):
		return 0.0
	return minf(float(row["cap"]), float(row["step"]) * float(combo_streak - int(row["start"]) + 1))


## Quem bate a porta no meio da sequência corta o ritmo na hora, com cartaz ou sem
## ele: combo é prêmio de balcão que dá conta, não contagem de tiques.
func _break_combo() -> void:
	combo_streak = 0


## A venda que acabou de sair. `pago` é o ouro que o combo entrou no caixa — zero no
## degrau zero e zero na nota do fiado, que ainda vai cobrar. Recorde e cofre da vida
## só mexem quando houve pagamento, para a conquista ler dinheiro de verdade.
func _bump_combo(pago: int) -> void:
	combo_streak = mini(combo_streak + 1, COMBO_CEIL)
	combo_day_best = maxi(combo_day_best, combo_streak)
	if pago <= 0:
		return
	combo_gold += pago
	combo_day_gold += pago
	combo_best = maxi(combo_best, combo_streak)


func _buy_combo_rank() -> void:
	var next_row := _combo_next_row()
	if next_row.is_empty():
		last_event = "O cartaz já está no último degrau: paga %d por cento na etiqueta a partir da %dª venda seguida, com teto de %d por cento." % [
			int(round(float(_combo_row(combo_rank)["step"]) * 100.0)),
			int(_combo_row(combo_rank)["start"]),
			int(round(float(_combo_row(combo_rank)["cap"]) * 100.0))]
		_show_feedback("🔥 O cartaz já é o maior da rua.", Color(1.0, 0.72, 0.45))
		_refresh_ui()
		return
	if reputation < int(next_row["rep"]):
		last_event = "O cartaz do degrau %d pede %d de fama; a casa tem %d. Combo é boca que espalha, não ouro que se compra sozinho." % [
			int(next_row["rank"]), int(next_row["rep"]), reputation]
		_show_feedback("✕ Falta fama para pendurar o cartaz.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	var cost := int(next_row["cost"])
	if gold < cost:
		last_event = "O cartaz custa %d de ouro, e o caixa tem %d. Prometer bônus sem caixa para pagá-lo é fila de promessa." % [
			cost, gold]
		_show_feedback("✕ Falta ouro para o cartaz.", Color(0.80, 0.60, 0.55))
		_refresh_ui()
		return
	gold -= cost
	combo_rank = int(next_row["rank"])
	reputation += 1
	_add_xp(12)
	var row := _combo_row(combo_rank)
	last_event = "🔥 Cartaz no degrau %d: a partir da %dª venda seguida do dia a etiqueta sai %d por cento mais cara, subindo %d por cento por venda até %d por cento de teto (−%d de ouro)." % [
		combo_rank, int(row["start"]), int(round(float(row["step"]) * 100.0)),
		int(round(float(row["step"]) * 100.0)), int(round(float(row["cap"]) * 100.0)), cost]
	_show_feedback("✦ Cartaz pendurado: o balcão agora paga ritmo.", Color(1.0, 0.72, 0.45))
	audio.play("coin")
	_check_achievements()
	_save_game()
	_refresh_ui()


func _combo_summary() -> String:
	var row := _combo_row(combo_rank)
	var vida := "Recorde premiado da vida: %d venda(s) seguidas • %d de ouro pago em combo." % [
		combo_best, combo_gold]
	if combo_rank <= 0:
		return "🔕 Sem cartaz na parede: a casa conta a sequência (agora em %d venda(s) seguidas), mas não paga nem cobra por ela. Pendurar o cartaz custa %d de ouro e pede %d de fama. %s" % [
			combo_streak, int(COMBO_TIERS[1]["cost"]), int(COMBO_TIERS[1]["rep"]), vida]
	var rate := _combo_rate()
	if rate <= 0.0:
		return "🔕 Cartaz no degrau %d: paga a partir da %dª venda seguida do dia e a sequência está em %d. Uma visita que sai sem comprar corta o ritmo, e a virada recomeça o dia. %s" % [
			combo_rank, int(row["start"]), combo_streak, vida]
	return "🔥 COMBO DE %d • etiqueta +%d por cento (teto %d) • %d de ouro pago hoje em combo. A sequência morre na virada e morre em quem sai sem comprar. %s" % [
		combo_streak, int(round(rate * 100.0)), int(round(float(row["cap"]) * 100.0)),
		combo_day_gold, vida]


## O rodapé que toda festa de balcão puxa quando o combo paga: qual venda do dia foi esta,
## quanto a etiqueta subiu e o que a casa já embolsou com o ritmo. A etiqueta é lida antes
## de a venda entrar no contador — é por isso que a sequência vem de fora, somada, e o
## total do dia aparece já com esta venda dentro.
func _combo_tail(pago: int, sequencia: int) -> String:
	return "🔥 Combo de %d venda(s) seguidas no dia: %d de ouro a mais na etiqueta (%d por cento), %d pago(s) hoje no cartaz." % [
		sequencia, pago, int(round(_combo_rate() * 100.0)), combo_day_gold + pago]


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

## ── Concorrência ──────────────────────────────────────────────────────────────

## A placa que acendeu hoje é notícia da manhã, não sorteio de fila: o mural avisa
## antes de a loja descobrir que tem menos corpo na calçada.
func _rival_opening_line() -> String:
	for rival in Rivals.DATA:
		if int(rival["day"]) != shop_day or rivals_absorbed.has(str(rival["id"])):
			continue
		return "\n☗ " + str(rival["open"])
	return ""

## Comprar a placa é a única resposta que fecha o rombo em vez de disfarçá-lo: o
## caixa sai de uma vez, a praça perde a concorrência e o estoque da rival sobe na
## prateleira como peça honesta — rival nenhum entrega obra-prima. O preço sobe a
## cada virada de espera, porque o que ela construiu na rua é obra que se paga.
func _absorb_rival(id: String) -> void:
	var rival := Rivals.find(id)
	if rival.is_empty():
		return
	if rivals_absorbed.has(id):
		last_event = "%s já é sua. Duas placas no mesmo lugar só engordam a conta da casa." % str(rival["name"])
		return
	if shop_day < int(rival["day"]):
		last_event = "%s ainda não tem placa na praça: abre no dia %d. Comprar o que não existe é o tipo de erro que o beco comenta." % [
			str(rival["name"]), int(rival["day"])]
		audio.play("sad")
		return
	var cost := Rivals.price_for(rival, shop_day)
	if gold < cost:
		last_event = "A placa de %s custa %d de ouro hoje. Faltam %d — e cada virada de espera encarece a obra que ela fez na rua." % [
			str(rival["name"]), cost, cost - gold]
		audio.play("sad")
		return
	gold -= cost
	rivals_absorbed.append(id)
	reputation += int(rival["rep"])
	var gained := ""
	var index := _product_index(str(rival["gain"]["product"]))
	if index >= 0:
		for i in range(int(rival["gain"]["count"])):
			_add_piece(index, 1)
		gained = " A prateleira recebeu %d× %s." % [
			int(rival["gain"]["count"]), str(products[index]["name"])]
	last_event = str(rival["bought"]) + gained
	audio.play("levelup")
	_show_feedback("☗ %s absorvida." % str(rival["name"]), Color(0.72, 1.0, 0.82))
	_check_achievements()
	_save_game()
	_refresh_ui()

## A conta que o painel mostra antes de a loja decidir: quantos corpos e quanto
## bolso a praça já bebeu hoje, e o que a fama segura.
func _rival_pressure_line() -> String:
	var ids := _rivals_active_ids()
	if not ids.is_empty():
		return "%s • porta −%d por batida • bolso −%d (fama %d %s)" % [
			Rivals.names(ids), _rival_crowd_loss(), _rival_undercut(), reputation,
			"segura metade" if reputation >= Rivals.FAME_HOLD else "ainda não segura"]
	if rivals_absorbed.is_empty():
		return "Nenhuma placa rival acesa na praça ainda."
	return "A praça é sua: %d rival(es) com a placa comprada." % rivals_absorbed.size()

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
		else "Esta vida vale %d de aura na reencarnação. A recepção mostra o que fica e o que volta a zero." % _aura_gain(business_score())
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
	_sync_clock()
	audio.play("rare")
	_refresh_ui()

## Fechar a lembrança devolve o relógio à loja e emenda o que a cena estava
## segurando — o painel do final, no último capítulo.
func _close_origin() -> void:
	if is_instance_valid(origin_layer):
		origin_layer.queue_free()
	origin_layer = null
	_sync_clock()
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
		"combo_best": combo_day_best,
		"combo_gold": combo_day_gold,
	}
	_mark_day_start()
	day_walkouts = 0
	combo_day_best = 0
	combo_day_gold = 0
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

	# A linha do cartaz só nasce quando houve ouro de combo no dia: com o cartaz guardado
	# o balanço continua sendo exatamente o mesmo popup que as sondas antigas lêem.
	if int(balance["combo_gold"]) > 0:
		var combo_counts := Label.new()
		combo_counts.text = "🔥 Combo do dia: %d de ouro pago no cartaz, recorde de %d venda(s) seguidas" % [
			int(balance["combo_gold"]), int(balance["combo_best"])]
		combo_counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combo_counts.add_theme_font_size_override("font_size", 14)
		combo_counts.add_theme_color_override("font_color", Color(1.0, 0.78, 0.45))
		box.add_child(combo_counts)

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

	_sync_clock()
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
	_sync_clock()
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
	return "Reencarnar o balcão: esta vida vale +%d de aura" % _aura_gain(business_score())

## O painel do prestígio desenhado. A meta é medida em pontuação, e pontuação muda
## a cada venda, por isso isto roda em todo refresco e não só no tique do mundo.
func _refresh_prestige() -> void:
	prestige_label.text = _prestige_text()
	# A regra da casa é painel do prestígio porque é o prestígio que ela paga: o texto
	# mostra os fatores e os dias morados em cada um, para o bônus ter proveniência.
	if is_instance_valid(difficulty_label):
		difficulty_label.text = _difficulty_summary()
	if is_instance_valid(difficulty_button):
		difficulty_button.text = "🏠 Regra da casa: %s ▶" % str(_difficulty_row()["name"])
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

## A linha da tabela que a casa segue hoje. Id desconhecido — save adulterado, ou modo
## que saiu da lista — cai no Calçada: a loja nunca acorda sem regra.
func _difficulty_row(id: String = "") -> Dictionary:
	var wanted := id if id != "" else difficulty
	for row in DIFFICULTIES:
		if str(row["id"]) == wanted:
			return row
	return DIFFICULTIES[0]


## Etiqueta: o freguês paga a regra da casa, não o preço de tabela. Consumido em
## `_piece_price`, que é onde vitrine, balcão e fila já mediam a mesma peça.
func _difficulty_price_factor() -> float:
	return float(_difficulty_row()["price"])


## Conta da casa: sob regra dura o aluguel do inferno pesa mais.
func _difficulty_upkeep_factor() -> float:
	return float(_difficulty_row()["upkeep"])


## Pressão da rua: o limiar é que muda, nunca o sorteio.
func _difficulty_risk_factor() -> float:
	return float(_difficulty_row()["risk"])


## Dias de balcão já vividos sob alguma regra nesta vida.
func _difficulty_days_total() -> int:
	var total := 0
	for id in difficulty_days:
		total += maxi(0, int(difficulty_days[id]))
	return total


## O pagamento da regra: a média dos dias efetivamente morados em cada modo. Quem passa
## a vida inteira no Poço leva o multiplicador inteiro; quem troca de regra no meio do
## caminho leva a fração que de fato viveu — é o dia na prateleira que prova a regra, não
## o botão batido na hora de reencarnar. Vida sem dia virado ainda não morou nada, então
## paga a regra do momento.
func _difficulty_aura_factor() -> float:
	var total := _difficulty_days_total()
	if total <= 0:
		return float(_difficulty_row()["aura"])
	var peso := 0.0
	for row in DIFFICULTIES:
		peso += float(row["aura"]) * float(maxi(0, int(difficulty_days.get(str(row["id"]), 0))))
	return peso / float(total)


## Aura que a vida de hoje paga: o número de sempre da tabela, escalado pela regra
## vivida. Um único lugar para o cofre, o botão e o final lerem.
func _aura_gain(score: int) -> int:
	return maxi(1, int(round(float(Prestige.aura_for(score)) * _difficulty_aura_factor())))


## O ciclista de regra da casa. Trocar vale desde a próxima batida de fila — e custa a
## diluição do bônus, porque o dia já vivido em outra regra continua no caderno.
func _cycle_difficulty() -> void:
	var index := 0
	for i in range(DIFFICULTIES.size()):
		if str(DIFFICULTIES[i]["id"]) == difficulty:
			index = i
			break
	difficulty = str(DIFFICULTIES[(index + 1) % DIFFICULTIES.size()]["id"])
	last_event = "Regra da casa: %s. %s" % [_difficulty_row()["name"], _difficulty_row()["note"]]
	_show_feedback("🏠 Regra: %s" % _difficulty_row()["name"], Color(0.86, 0.92, 1.0))
	audio.play("click")
	_save_game()
	_refresh_ui()


## O painel da regra: o nome, o que cada alavanca faz de verdade e os dias morados em
## cada uma — sem ler o caderno de dias a loja não teria como provar o bônus.
func _difficulty_summary() -> String:
	var row := _difficulty_row()
	var parts: Array[String] = []
	for id in difficulty_days:
		var dias := maxi(0, int(difficulty_days[id]))
		if dias <= 0:
			continue
		parts.append("%s %d" % [str(_difficulty_row(str(id))["name"]), dias])
	var caderno := " • dias morados: %s" % ", ".join(parts) if not parts.is_empty() else " • nenhum dia de balcão nesta regra ainda"
	return "REGRA DA CASA: %s — etiqueta ×%.2f, conta ×%.2f, rua ×%.2f, aura ×%.2f%s\n%s" % [
		str(row["name"]), float(row["price"]), float(row["upkeep"]), float(row["risk"]),
		_difficulty_aura_factor(), caderno, str(row["note"])]


## Trocar a vida é o prestígio em si: o caixa, a prateleira e a campanha voltam ao
## zero, e o que a loja aprendeu — povo, álbum, lembranças, dotes e conquistas —
## atravessa com a chefe.
func _reincarnate() -> void:
	if not game_completed:
		return
	var score := business_score()
	var gain := _aura_gain(score)
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
	# A praça também recomeça com as placas dela: o que foi comprado numa vida não
	# cala a rival da vida seguinte.
	rivals_absorbed.clear()
	_offline_branch_fraction = 0.0
	# O quadro também é da vida: a folha sai com a loja velha, e a vida nova contrata
	# quem quiser do zero. Os servos não: quem largou a própria rotina por afeto à
	# chefe continua na casa depois da reencarnação — vínculo é da família, não do
	# CNPJ. Só o reset total, que apaga o save, desfaz o que eles escolheram.
	staff_hired.clear()
	theft_blocked = 0
	# O cadastro de estrada vence junto com a loja velha — contrato é da vida —, mas
	# o XP não: a rota que alguém pisou fica na memória da pessoa, não no CNPJ da
	# casa. Recontratar custa taxa de novo e entrega o batedor no nível que a estrada
	# lhe deixou. Só o reset total desfaz o aprendizado.
	adventurers_hired.clear()
	route_pick.clear()
	# Conserva e cela são da vida que está fechando: o chão novo nasce limpo, quem
	# estava preso escapa no meio da mudança, e o bairro perdoa o banido junto com a
	# loja — a vida nova é justamente a chance de não repetir a mesma porta.
	mess = 0
	sweeps_done = 0
	blood_harvested = 0
	prisoners.clear()
	banned_regulars.clear()
	# A resposta dada ao vigário é da loja que fecha: a vida nova recebe a cobrança na
	# primeira semana e decide de novo. Os carimbos não — porta segurada é história do
	# beco com esta família, e a dobradiça, o sino e a milícia continuam no caixilho.
	tithe_stance = ""
	tithe_until = 0
	vicar_announced_day = 0
	last_invasion = ""
	music_alarm_until = 0
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
	# O dia um de uma vida nova acorda sem tempo sorteado e sem rua atrás de nada: a
	# primeira previsão chega na primeira virada. O caderno de tempos já vistos é da
	# conta da chefe, não da vida, e atravessa a reencarnação.
	weather = "limpo"
	weather_star = ""
	demonic_form_active = false
	seduction_peak_triggered = false
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
	# A bancada é da vida: o caderno de becos e a mesa em brasa são o que esta tentativa
	# aprendeu, e a vida nova existe justamente para aprender outros.
	lab_trials.clear()
	lab_mix.clear()
	lab_hints.clear()
	lab_discovered.clear()
	lab_flops = 0
	vip_rank = 0
	vip_served = 0
	vip_refusals = 0
	vip_tips_gold = 0
	# O livro de reclamações é da vida, não da dinastia: a rua esquece quem fechou a loja
	# anterior, e a vida nova começa com a boca limpa — cobrança inclusive.
	complaints = 0
	complaints_written = 0
	complaints_hushed = 0
	combo_rank = 0
	combo_streak = 0
	combo_day_best = 0
	combo_day_gold = 0
	combo_best = 0
	combo_gold = 0
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
	shelf_batches.clear()
	cold_storage_level = 0
	# O caderno de regra é da vida: a escolha da próxima vida continua a mesma, mas os
	# dias morados voltam ao zero junto com o caixa — senão a aura herdaria dias alheios.
	difficulty_days.clear()
	# Fiado é desta vida e deste balcão: reencarnar apaga as notas da rua, o degrau do
	# caderno e as duas contagens. Quem começou do zero não herda cobrança de outra chefe.
	credit_rank = 0
	credit_book.clear()
	credit_paid = 0
	credit_written = 0
	credit_lost_gold = 0
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
	if not is_instance_valid(seller_portrait):
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

## Quantas vagas o balcão tem para quem trabalha de graça: é o número de degraus
## de sedução provada que a casa já subiu, não um teto inventado.
func servant_cap() -> int:
	var cap := 0
	for rung in SERVANT_LADDER:
		if seduction_successes >= int(rung):
			cap += 1
	return cap

## Um apaixonado pede para ficar tomando conta da loja. O tom da cena muda com o
## interruptor de conteúdo; a porta não: com o conteúdo sensual desligado ele deve
## a vaga à fidelidade, e ninguém tem a progressão cortada por causa do filtro.
func _offer_servant(regular_id: String) -> void:
	if servants.has(regular_id) or servants.size() >= servant_cap():
		return
	var stage := _romance_stage_of(regular_id)
	if stage < 1:
		return
	if randi() % 100 >= 24 + charm_rank * 10 + stage * 12:
		return
	servants.append(regular_id)
	var short := str(Regulars.find(regular_id).get("short", "O freguês"))
	last_event = "%s largou a própria rotina para tomar conta do balcão: “%s” Ele não quer ouro, quer ficar perto. A casa ganha uma mão sem salário — e a chefe ganha o cuidado de não perder nenhuma das duas." % [
		short,
		"Eu já não penso direito quando você sorri, então pensei: trabalho aqui."
		if adult_content_enabled else
		"Confio nesta casa mais do que na minha própria banca. Me põe para trabalhar."
	]
	_show_feedback("♥ %s entrou para a casa." % short, Color(1.0, 0.78, 0.9))
	_show_stage_emotion(stage_seller_body, "aprovacao")

## O afeto tem preço em temperamento: um dia em que a loja trata mal o bairro faz
## quem trabalhava de graça lembrar que trabalhava, e ele volta para a própria
## vida. A vaga abre de novo para o próximo.
func _servant_quits() -> void:
	if servants.is_empty() or fury < 3:
		return
	var seat := randi() % servants.size()
	var gone := str(Regulars.find(servants[seat]).get("short", "Um dos da casa"))
	servants.remove_at(seat)
	last_event = "%s passou a manhã limpando o balcão que a chefe quase virou e desistiu: “Eu trabalho aqui, mas ninguém me deve gritar.” A casa perde uma mão e a folha não sente — era de graça mesmo." % gone
	_show_feedback("💔 %s saiu da casa." % gone, Color(1.0, 0.55, 0.55))

## A linha do painel: quem está no balcão por afeto e o que isso muda na conta.
func _servants_line() -> String:
	if servants.is_empty():
		return ""
	var names: Array[String] = []
	for regular_id in servants:
		names.append(str(Regulars.find(str(regular_id)).get("short", "?")))
	return " • SERVOS DA CASA (%d de %d, sem salário): %s — +%d tique de fila, +%d%% na etiqueta, -%d de conta por virada." % [
		servants.size(), servant_cap(), ", ".join(names), servants.size(),
		int(round(SERVANT_PRICE_SHARE * servants.size() * 100.0)),
		SERVANT_UPKEEP_RELIEF * servants.size()
	]

## ── conserva do salão, vândalos e cela ──────────────────────────────────────

## Barro que ninguém varre é anúncio: a fila espera menos, a etiqueta vale menos e o
## beco entende que a casa anda ocupada demais para se defender.
func _add_mess(amount: int) -> void:
	mess = clampi(mess + amount, 0, MESS_LIMIT)

## Tiques de paciência que um salão imundo come da fila — a mesma moeda que o
## charme, a logística e os servos já pagavam, só que do lado da dívida.
func _mess_patience_loss() -> int:
	return int(float(mess) / float(MESS_PATIENCE_STEP))

## Desconto que o cliente faz na própria cabeça antes de abrir a carteira.
func _mess_price_multiplier() -> float:
	return 1.0 - float(mess) * MESS_PRICE_PENALTY

## Preço do balde: cresce com o tamanho da casa, nunca com a marcha de quem a
## administra — investir em Administração não pode engrossar a própria conta.
func _mop_cost() -> int:
	return MOP_COST + branches.size() * 6 + (library_upgrade_level + sanctum_upgrade_level) * 3

## A chefe pega na vassoura ela mesma. Custa ouro e zera o chão na hora: é a defesa
## de quem ainda não tem criada na folha, e continua sendo a defesa rápida de quem
## já tem, porque a criada só varre uma vez por virada.
func _sweep_floor() -> void:
	if mess <= 0:
		last_event = "O salão já está varrido. A chefe guarda a vassoura e jura que foi teste de chão."
		_refresh_ui()
		return
	var cost := _mop_cost()
	if gold < cost:
		last_event = "Balde, vassoura e sabão custam %d e o caixa tem %d. A casa vai sujar mais antes de poder pagar pela própria limpeza." % [cost, gold]
		_show_feedback("✗ Sem caixa para varrer.", Color(1.0, 0.55, 0.55))
		_refresh_ui()
		return
	var swept := mess
	gold -= cost
	mess = 0
	sweeps_done += 1
	last_event = "%d de barro fora do chão por %d ouro. A entrada range de limpa e quem estava de costas olha as prateleiras de novo." % [swept, cost]
	_show_feedback("🧹 Salão varrido.", Color(0.82, 0.98, 0.86))
	_show_stage_emotion(stage_seller_body, "felicidade")
	_check_achievements()
	_save_game()
	_refresh_ui()

## O que a casa limpa sozinha na virada: a criada contratada varre o chão e cada
## servo apaixonado dá uma mão sem cobrar. Devolve a linha do balanço da manhã.
func _clean_house_turn() -> String:
	var maid := Staff.sweep_per_turn(staff_hired)
	var loving := SERVANT_SWEEP * servants.size()
	var swept := maid + loving
	if swept <= 0 or mess <= 0:
		return ""
	var before := mess
	mess = maxi(0, mess - swept)
	var taken := before - mess
	# A frase é escrita por caso, não montada com um verbo só: a criada varre
	# "ela", o servo varre "eles", e as duas mãos juntas não cabem numa
	# concordância só.
	if maid > 0 and loving > 0:
		return " %s e os %d servos da casa varreram %d de barro (%d -> %d no chão)." % [
			str(Staff.find("createda")["name"]), servants.size(), taken, before, mess]
	if maid > 0:
		return " %s varreu %d de barro (%d -> %d no chão)." % [
			str(Staff.find("createda")["name"]), taken, before, mess]
	return " Os %d servos da casa varreram %d de barro (%d -> %d no chão)." % [
		servants.size(), taken, before, mess]

## Quantos vândalos a casa consegue guardar: é reforma de santuário, não número de
## painel — sem porta trancada ninguém prende ninguém.
func _cell_capacity() -> int:
	return sanctum_upgrade_level

## Chance de o beco testar a loja numa virada: o barro chama, a fama afasta, e a regra da
## casa decide o tamanho da parede. Só o limiar muda — o sorteio continua o mesmo.
func _vandal_chance() -> int:
	var base := int(round(float(mess) * VANDAL_CHANCE_PER_MESS)) \
		+ maxi(0, VANDAL_REP_SHIELD - reputation)
	return clampi(int(round(float(base) * _difficulty_risk_factor())), 0, 40)

## A guilda leva o preso embora e paga a escolta: é o único destino de quem é pego
## antes de a casa ter cela, e é por isso que a cela existe.
func _hand_to_guild(culprit: String) -> void:
	var fee := 15 + player_level
	gold += fee
	reputation += 2
	last_event = "%s foi entregue à guilda de escolta, que cobra %d para levar problema embora e diz \"bom trabalho\" na saída. A rua aprende o nome da casa." % [culprit, fee]
	_show_feedback("⚖ %s entregue à guilda." % culprit, Color(0.86, 0.92, 1.0))

## Quem é pego em flagrente vira preso ou conta. Sem cela, a casa chama a guilda.
func _catch_culprit(culprit: String, regular_id: String) -> void:
	var who := str(Staff.find("ronda")["name"]) if staff_hired.has("ronda") else (
		"um servo da casa" if not servants.is_empty() else "a casa, acordada na hora errada")
	if prisoners.size() >= _cell_capacity():
		_hand_to_guild(culprit)
		last_event = "%s segurou %s pelo colarinho antes de a peça sair da loja, e a guilda levou o problema cobrando. %s" % [
			who, culprit, last_event]
		return
	prisoners.append({"name": culprit, "regular_id": regular_id})
	# Quem está na cela não está no balcão: o servo apaixonado que passou da conta
	# perde a vaga enquanto responde pelo que fez.
	servants.erase(regular_id)
	last_event = "%s segurou %s pelo colarinho antes de a peça sair da loja. ⛓ Cela do santuário agora com %d de %d: come %d por virada e rende um frasco de sangue morno por virada." % [
		who, culprit, prisoners.size(), _cell_capacity(), CELL_FOOD
	]
	_show_feedback("⛓ %s na cela." % culprit, Color(0.78, 0.88, 1.0))
	_show_stage_emotion(stage_seller_body, "aprovacao")

## Rodada de vândalos: entram rindo, deixam lama e levam peça. A ronda e os servos
## decidem se alguém sai de lá com as próprias pernas.
func _trigger_vandal() -> void:
	var culprit := VANDAL_NAMES[randi() % VANDAL_NAMES.size()]
	_add_mess(MESS_VANDAL)
	fury = mini(5, fury + 1)
	_update_demonic_form()
	var guard := Staff.block_chance(staff_hired) + servants.size() * SERVANT_GUARD_CHANCE
	if guard > 0 and randi() % 100 < guard:
		theft_blocked += 1
		_catch_culprit(culprit, "")
		return
	var loot := mini(gold, 20 + player_level * 3)
	gold -= loot
	reputation = maxi(0, reputation - 1)
	var broke := ""
	if not craft_jobs.is_empty():
		craft_jobs.pop_back()
		broke = " Uma peça pela metade virou pó no chão."
	last_event = "%s passou com um saco de esterco na mão e três amigos atrás: %d de lama no salão, %d ouro no bolso deles e o balcão ainda cheira. A casa não tem quem segure braço." % [
		culprit, MESS_VANDAL, loot] + broke
	_show_feedback("🪣 Vândalos na loja.", Color(1.0, 0.55, 0.45))
	_show_stage_emotion(stage_seller_body, "espanto")
	audio.play("sad")

## A casa vista de fora: todas as mãos que ela tem para fechar a porta, linha por
## linha. Cada fonte é uma conta que o jogo já media — a ronda da folha, o servo que
## dorme no salão, o batedor que voltou da estrada, a reforma do santuário, o degrau
## da Administração e o que a própria campanha de defesa já pagou.
func _defense_snapshot() -> Dictionary:
	return {
		"ronda": Staff.block_chance(staff_hired),
		"servants": servants.size(),
		"adventurers": adventurers_hired.size(),
		"sanctum": sanctum_upgrade_level,
		"rank": house_rank,
		"privileges": defense_privileges,
	}

func _defense_power() -> int:
	return Invasions.defense_power(_defense_snapshot())

## A mão na porta escrita por extenso, na ordem em que a casa a contratou. Sem linha
## nenhuma é a loja com a maçaneta e nada mais — e o painel diz isso em vez de mostrar
## um número órfão.
func _defense_breakdown_line() -> String:
	var parts: Array[String] = []
	for line in Invasions.defense_lines(_defense_snapshot()):
		parts.append("%s +%d" % [str(line["name"]), int(line["value"])])
	if parts.is_empty():
		return "Nenhuma mão além da chefe na porta: %d de defesa e a rua sabe medir vitrine." % _defense_power()
	return "Quem fecha a porta: %s." % [" • ".join(parts)]

## A linha do vigário: quem ele é, o que quer, há quanto tempo a casa responde e o que
## as recusas já acumularam contra a porta.
func _vicar_panel_line() -> String:
	if shop_day < Invasions.first_visit_day():
		return "%s ainda não passou por este quarteirão. A lista da paróquia chega no dia %d." % [
			Invasions.vicar_name(), Invasions.first_visit_day()]
	if _vicar_waiting():
		return "%s está na calçada com a lista: %d de dízimo (%d dia(s) de escudo) ou %d para apagar o endereço por %d dia(s). Recusar não custa ouro e custa visita." % [
			Invasions.vicar_name(), _vicar_demand(), Invasions.TITHE_WEEK, _vicar_bribe(), Invasions.BRIBE_DAYS]
	return "%s: %s. Cobranças respondidas: %d, ouro pago à paróquia: %d.%s" % [
		Invasions.vicar_name(), Invasions.stance_line(tithe_stance, tithe_until, shop_day),
		tithe_demands, tithe_paid_total,
		" %d recusa(s) na conta da rua (+%d%% de visita)." % [vicar_refusals,
			vicar_refusals * Invasions.INVASION_REFUSAL_STING] if vicar_refusals > 0 else ""]

## Chance de a rua testar a porta numa virada: o alvo é o placar que a vitrine mostra,
## o escudo é a resposta dada ao vigário e o sino da campanha.
func _invasion_chance() -> int:
	var base := Invasions.invasion_chance(business_score(), tithe_stance, tithe_until, shop_day,
		vicar_refusals, _defense_snapshot())
	return clampi(int(round(float(base) * _difficulty_risk_factor())), 0, 100)

## A visita que o calendário da loja já permite, com o poder escalado pelos carimbos de
## porta segurada. Vazio quer dizer "loja nova demais para ter alvo na porta".
func _next_wave() -> Dictionary:
	return Invasions.wave_for(shop_day, invasions_repelled)

## A virada testa a maçaneta. Devolve a linha para o balanço da manhã, ou "" quando a
## rua não bateu — por isso o painel mostra a chance antes, em vez de só o susto.
func _roll_invasion() -> String:
	var wave := _next_wave()
	if wave.is_empty():
		return ""
	if randi() % 100 < Invasions.repel_chance(_defense_snapshot(), wave):
		return _repel_invasion(wave)
	return _breach_invasion(wave)

## Porta segurada: a visita bate, encontra mão na madeira e volta com o recibo de que
## a casa tem quem a defenda. O bairro anota, a campanha carimba, e com a milícia o
## saco volta para o balcão.
func _repel_invasion(wave: Dictionary) -> String:
	invasions_repelled += 1
	var snapshot := _defense_snapshot()
	var gain := 2 if Invasions.has_militia(snapshot) else 1
	reputation += gain
	music_alarm_until = shop_day + 2
	var parts: Array[String] = []
	parts.append("🛡 %s (%s) veio buscar o que a vitrine mostra e encontrou %d de mão na porta; a visita pedia %d. Ninguém passou." % [
		str(wave["name"]), str(wave["leader"]), Invasions.defense_power(snapshot), int(wave["power"])])
	if gain == 2:
		var reclaim := Invasions.militia_reclaim(wave, gold)
		gold += reclaim
		parts.append(" A milícia do beco tomou o saco de volta: +%d ouro." % reclaim)
	if prisoners.size() < _cell_capacity() and randi() % 100 < 45:
		_catch_culprit(str(wave["leader"]), "")
		parts.append(" " + last_event)
	parts.append(" %s O bairro anota a porta dura (+%d reputação). %s" % [
		str(wave["quote"]), gain, Invasions.campaign_line(invasions_repelled)])
	parts.append(_claim_defense_privilege())
	last_invasion = "".join(parts)
	_show_feedback("🛡 Porta segurada.", Color(0.72, 1.0, 0.86))
	_show_stage_emotion(stage_seller_body, "aprovacao")
	_apply_situation_music()
	_check_achievements()
	return last_invasion

## O degrau da campanha que os carimbos acabaram de pagar. Privilégio de defesa é da
## família, não da vida: reencarnar não arranca a dobradiça nova nem o sino do caixilho.
func _claim_defense_privilege() -> String:
	var privilege := Invasions.privilege_for(invasions_repelled)
	if privilege.is_empty() or defense_privileges.has(str(privilege["id"])):
		return ""
	defense_privileges.append(str(privilege["id"]))
	audio.play("levelup")
	_show_feedback("🔔 %s" % str(privilege["name"]), Color(0.72, 1.0, 0.86))
	return " CAMPANHA DE DEFESA (%d portas): \"%s\" — %s" % [
		invasions_repelled, str(privilege["name"]), str(privilege["does"])]

## Porta arrombada: o caixa, o chão, a fúria, a fama e a prateleira pagam juntos. É a
## primeira visita da rua que mexe no inventário, e mexe no mesmo estoque que o furto e
## a expedição já mexiam — a melhor peça do produto sorteado sai pela porta e não volta.
func _breach_invasion(wave: Dictionary) -> String:
	invasions_lost += 1
	var taken := Invasions.plunder_for(wave, gold)
	gold = maxi(0, gold - taken)
	_add_mess(int(wave["mess"]))
	fury = mini(5, fury + 1)
	_update_demonic_form()
	reputation = maxi(0, reputation - int(wave["rep"]))
	music_alarm_until = shop_day + 3
	var stolen := _steal_stock(int(wave["pieces"]))
	last_invasion = "💥 %s (%s) arrombou a porta: %d de barro no salão, %d ouro no saco, %d de reputação no boca-a-boca e um ponto de fúria no balcão.%s %s A casa tinha %d de mão na porta e a visita pedia %d." % [
		str(wave["name"]), str(wave["leader"]), int(wave["mess"]), taken, int(wave["rep"]),
		stolen, str(wave["quote"]), _defense_power(), int(wave["power"])]
	audio.play("sad")
	_show_feedback("💥 Porta arrombada.", Color(1.0, 0.5, 0.44))
	_show_stage_emotion(stage_seller_body, "medo")
	_apply_situation_music()
	_check_achievements()
	return last_invasion

## Peças que somem quando a porta cede: cada uma sai do mesmo estoque que a venda
## consome, na mesma ordem de qualidade (a melhor primeiro).
func _steal_stock(count: int) -> String:
	var taken: Array[String] = []
	for i in range(count):
		var options: Array[int] = []
		for p in range(products.size()):
			if int(products[p]["stock"]) > 0:
				options.append(p)
		if options.is_empty():
			break
		var pick := options[randi() % options.size()]
		var tier := _take_piece(pick, Quality.BEST)
		taken.append("%s (%s)" % [str(products[pick]["name"]), str(Quality.tier(tier)["name"])])
	if taken.is_empty():
		return ""
	return " Levaram da prateleira: %s." % ", ".join(taken)

## O vigário não abençoa de graça nem condena por decreto: ele cobra para escrever o
## endereço numa coluna menor da lista. Bate na porta a partir do dia 9 e a resposta
## vale por dias contados — escudo que não vence não é escolha, é decoração.
func _vicar_waiting() -> bool:
	if shop_day < Invasions.first_visit_day():
		return false
	return tithe_stance.is_empty() or shop_day > tithe_until

func _vicar_demand() -> int:
	return Invasions.tithe_for(shop_day, reputation)

func _vicar_bribe() -> int:
	return Invasions.bribe_for(shop_day, reputation)

## As três respostas possíveis, todas com preço: o dízimo come o caixa, o suborno come
## o dobro e compra silêncio longo, e a recusa não custa ouro — custa visita.
func _answer_vicar(answer: String) -> void:
	if not _vicar_waiting():
		last_event = "%s já tem resposta valendo até o dia %d. Ele volta quando o papel vencer." % [
			Invasions.vicar_name(), tithe_until]
		audio.play("click")
		_refresh_ui()
		return
	var paid := 0
	if answer == "dizimo":
		paid = _vicar_demand()
		if gold < paid:
			_vicar_no_cash("o dízimo", paid)
			return
		tithe_stance = "pago"
		tithe_until = shop_day + Invasions.TITHE_WEEK - 1
		vicar_refusals = maxi(0, vicar_refusals - 1)
		reputation += 1
		last_event = "✝ %s recebe %d de dízimo e escreve a casa na coluna de \"paga em dia\": -%d%% de visita na porta por %d dia(s), e o sermão de domingo cita o balcão (+1 reputação)." % [
			Invasions.vicar_name(), paid, Invasions.INVASION_TITHE_SHIELD, Invasions.TITHE_WEEK]
	elif answer == "suborno":
		paid = _vicar_bribe()
		if gold < paid:
			_vicar_no_cash("o suborno", paid)
			return
		tithe_stance = "subornado"
		tithe_until = shop_day + Invasions.BRIBE_DAYS - 1
		vicar_refusals = 0
		vicar_bribes += 1
		_gain_standing("submundo", 1)
		last_event = "🤝 %d na mão de %s, e a paróquia perde este endereço por %d dia(s): -%d%% de visita na porta, +1 de fama com o Submundo, que acha o capricho bonito. Ele sai dizendo que \"não é simonia, é pastoral\"." % [
			paid, Invasions.vicar_name(), Invasions.BRIBE_DAYS, Invasions.INVASION_BRIBE_SHIELD]
	else:
		tithe_stance = "recusado"
		tithe_until = shop_day + Invasions.REFUSAL_RETRY - 1
		vicar_refusals += 1
		reputation += 2
		last_event = "🚪 %s ouve \"não\" no balcão e dobra a lista: o bairro aplaude a porta dura (+2 reputação) e o papel vale %d dia(s), mas recusa é tinta — cada \"não\" soma +%d%% na chance de visita." % [
			Invasions.vicar_name(), Invasions.REFUSAL_RETRY, Invasions.INVASION_REFUSAL_STING]
	if paid > 0:
		gold = maxi(0, gold - paid)
		tithe_paid_total += paid
		audio.play("coin")
	else:
		audio.play("sad")
	tithe_demands += 1
	_show_feedback("✝ Resposta dada ao vigário.", Color(0.86, 0.92, 1.0))
	_apply_situation_music()
	_check_achievements()
	_save_game()
	_refresh_ui()

## Resposta honesta quando a bolsa não alcança a resposta: o vigário anota o número e
## vai embora, e a cobrança volta na semana seguinte sem mudar de valor por isso.
func _vicar_no_cash(what: String, cost: int) -> void:
	last_event = "%s veio cobrar %s de %d e a casa tem %d no caixa. Ele anota na manga do hábito e volta quando a loja puder pagar — a rua inteira vê a conta." % [
		Invasions.vicar_name(), what, cost, gold]
	audio.play("sad")
	_show_feedback("💸 Sem caixa para %s." % what, Color(1.0, 0.6, 0.5))
	_refresh_ui()

## Fama de facção ganha fora do balcão. Suborno é serviço que o Submundo reconhece, e a
## fama que sobe é a mesma que já barateia o dia ruim das filiais.
func _gain_standing(faction_id: String, amount: int) -> void:
	if Factions.find(faction_id).is_empty():
		return
	faction_standing[faction_id] = maxi(0, int(faction_standing.get(faction_id, 0)) + amount)

## Trilha situacional com a única faixa gravada que a casa tem: a mesma gravação,
## afinada pelo que está acontecendo no salão. Alarme de porta acelera, ruína arrasta,
## vigário na porta puxa para o grave e cada setor tem o próprio tom. `_music_situation`
## é a resposta pura, medida na sonda; `_apply_situation_music` é quem move o player.
func _music_situation() -> Dictionary:
	if music_alarm_until > 0 and shop_day <= music_alarm_until:
		return {"name": "alarme na porta", "pitch": 1.12, "db": -8.0}
	if debt >= _debt_limit():
		return {"name": "casa na ruína", "pitch": 0.84, "db": -18.0}
	if _vicar_waiting() and vicar_announced_day == shop_day:
		return {"name": "vigário na porta", "pitch": 0.92, "db": -14.0}
	match current_sector:
		"forge":
			return {"name": "forja", "pitch": 1.06, "db": -11.0}
		"library":
			return {"name": "biblioteca", "pitch": 0.95, "db": -15.0}
		"sanctum":
			return {"name": "santuário", "pitch": 0.88, "db": -17.0}
		"expedition":
			return {"name": "estrada", "pitch": 1.02, "db": -12.0}
	return {"name": "salão", "pitch": 1.0, "db": -13.0}

func _apply_situation_music() -> void:
	if not is_instance_valid(music_player):
		return
	var tune := _music_situation()
	music_player.pitch_scale = float(tune["pitch"])
	music_base_db = float(tune["db"])
	_apply_music_settings()

## A cela gota no frasco e come na cozinha: cada preso é insumo e conta ao mesmo
## tempo, e é por isso que a casa pensa duas vezes antes de prender quem conhece.
func _harvest_cell() -> String:
	if prisoners.is_empty():
		return ""
	var jars := CELL_BLOOD * prisoners.size()
	ingredient_stock["sangue"] = int(ingredient_stock.get("sangue", 0)) + jars
	blood_harvested += jars
	return " A cela rendeu %d frasco(s) de sangue morno para a forja." % jars

## Soltar custa o sangue e devolve a rua: quem sai da cela volta a comprar, e um
## freguês de casa ainda ganha vínculo pela humilhação que a casa lhe fez.
func _release_prisoner() -> void:
	if prisoners.is_empty():
		return
	var freed: Dictionary = prisoners.pop_front()
	reputation += 1
	var culprit := str(freed["name"])
	var regular_id := str(freed.get("regular_id", ""))
	if regular_id != "" and not Regulars.find(regular_id).is_empty():
		regular_bonds[regular_id] = int(regular_bonds.get(regular_id, 0)) + 1
		culprit = str(Regulars.find(regular_id).get("short", culprit))
		last_event = "%s sai da cela com a promessa de que nunca mais encosta na prateleira, e volta a ser freguês: a casa perdoa, e o bairro vê quem manda no perdão." % culprit
	else:
		last_event = "%s sai da cela antes do escuro e jura que a loja é grande demais para ele. Todo mundo finge que acredita." % culprit
	_show_feedback("🕊 %s solto." % culprit, Color(0.86, 0.98, 0.86))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Expulsar do bairro é o oposto do perdão: resolve para sempre e fecha a porta
## para sempre. Um freguês banido nunca mais aparece no sorteio de visitas.
func _banish_prisoner() -> void:
	if prisoners.is_empty():
		return
	var out: Dictionary = prisoners.pop_front()
	var culprit := str(out["name"])
	var regular_id := str(out.get("regular_id", ""))
	if regular_id != "" and not Regulars.find(regular_id).is_empty() and not banned_regulars.has(regular_id):
		banned_regulars.append(regular_id)
		servants.erase(regular_id)
		if romance_pending == regular_id:
			romance_pending = ""
		culprit = str(Regulars.find(regular_id).get("short", culprit))
		last_event = "%s é expulso do bairro: a placa na porta tem o nome dele e o sorteio de visitas nunca mais o sorteia. A casa ganha silêncio e perde um freguês inteiro — vínculo, encomenda e servo, tudo junto." % culprit
	else:
		last_event = "%s é posto para fora com a conta na mão e a ordem de não voltar. O beco anota que a casa não perdoa duas vezes." % culprit
	reputation += 1
	fury = maxi(0, fury - 1)
	_update_demonic_form()
	_show_feedback("🚪 %s banido do bairro." % culprit, Color(1.0, 0.72, 0.6))
	_check_achievements()
	_save_game()
	_refresh_ui()

## Um freguês banido não volta: é a única porta da casa que tranca por fora.
func _regular_banned(regular_id: String) -> bool:
	return banned_regulars.has(regular_id)

## Faixa atual, medida no placar que o painel já mostra.
func _progress_band_now() -> int:
	var score := business_score()
	var band := 0
	for i in range(PROGRESS_BAND_SCORES.size()):
		if score >= PROGRESS_BAND_SCORES[i]:
			band = i
	return band

## Quanto da obra ainda está de pé numa faixa: 1.0 no canteiro, quase seca na
## primeira reforma, 0.0 quando a casa já tem piso encerado. A lona não pode morar
## numa loja "respeitada" — quem reformou tirou o pano, e a faixa tem de dizer isso.
func _renovation_alpha(band: int) -> float:
	if band > RENOVATION_LAST_BAND:
		return 0.0
	return 1.0 if band <= 0 else 0.45


## Aplica a faixa: esquenta o fundo pintado do mesmo salão, lava a cor dos móveis
## enquanto há lona, engorda a poeira do ar e, na mudança de faixa, redesenha a
## camada. A luz e o pó acompanham a faixa em todo painel — trocar `modulate` não
## custa nada, e é o que faz a casa abrir já em obras sem que ninguém tenha subido
## a escada (faixa 0 nunca é "mudança"). O redraw e o aviso da chefe, esses ficam só
## na mudança: redesenhar o salão a cada tique é redesenhar a mesma coisa.
func _apply_progress_decor() -> void:
	var band := _progress_band_now()
	var antes := _progress_band
	var quiet := _progress_quiet
	_progress_quiet = false
	# O mesmo PNG, um degrau mais quente e mais aceso: a casa não troca de arte,
	# troca de luz, e é a luz que o olho lê como "essa loja cresceu". A obra começa
	# abaixo da cor original — fria e apagada, parede sem última demão e nenhuma vela
	# acesa — e a faixa 0 é justamente o canteiro. O aquecimento é o prêmio.
	if is_instance_valid(background_layer):
		background_layer.modulate = PROGRESS_BAND_LIGHT[
			clampi(band, 0, PROGRESS_BAND_LIGHT.size() - 1)]
	# O elenco mora na sala, então a luz da sala o atinge. Sem isso o corpo entra
	# num salão a 0,46 queimando a 1,0 e vira desenho colado por cima da foto. O
	# matiz vai a 0,78 do degradê e não 1,0: rosto precisa continuar lendo como
	# rosto, e o escuro da obra é mais funda atrás do que em cima de quem trabalha.
	# Só se troca o rgb — o alfa é do fade de troca de sala.
	if is_instance_valid(stage_layer):
		var luz: Color = PROGRESS_BAND_LIGHT[clampi(band, 0, PROGRESS_BAND_LIGHT.size() - 1)]
		var corpo := Color(1.0, 1.0, 1.0).lerp(luz, 0.78)
		stage_layer.modulate = Color(corpo.r, corpo.g, corpo.b, stage_layer.modulate.a)
	# O móvel coberto tem outra cor: os móveis voltam ao tom de tinta quando a lona
	# sai. A lona é clara porque pega a lâmpada, mas mora num salão escuro — clara
	# demais, ela vira o objeto mais aceso da sala e a obra some. Só se troca o
	# matiz aqui — o alfa é do fade de troca de sala, e mexer nele seria cortar a
	# animação de outra.
	if is_instance_valid(stage_occluder):
		var washed := Color(1.0, 1.0, 1.0).lerp(Color(0.66, 0.68, 0.80), _renovation_alpha(band))
		stage_occluder.modulate = Color(
			washed.r, washed.g, washed.b, stage_occluder.modulate.a)
	if is_instance_valid(ambient_particles):
		# No canteiro o ar é grosso de pó de gesso; depois, a poeira dourada do luxo.
		ambient_particles.amount = 52 if band <= 0 else 24 + band * 12
	if band == antes:
		return
	_progress_band = band
	if is_instance_valid(_progress_layer):
		_progress_layer.queue_redraw()
	# A faixa sobe sozinha, mas quem avisa é a chefe: ninguém pode descobrir o
	# salão novo por acidente no meio de uma venda.
	if band > antes and not quiet:
		var anuncio := tr("A casa virou %s: %s") % [
			tr(PROGRESS_BAND_NAMES[band]), tr(PROGRESS_BAND_GIFTS[band])]
		# A faixa nova é a notícia maior, mas não apaga o que o balcão acabou de dizer:
		# quem levou no fiado, quem pagou o capítulo, quem levou a encomenda. Perder essa
		# linha no meio de uma reforma é o jogador fazer a conta da casa sem ler o
		# recibo. A obra entra por cima, o recibo fica embaixo.
		var recibo := str(last_event)
		last_event = anuncio if recibo.is_empty() else "%s\n%s" % [anuncio, recibo]
		_show_stage_emotion(stage_seller_body, "felicidade")

## A obra em si, desenhada na camada entre o fundo pintado e o elenco: poeira no ar,
## massa crua na parede, lona no piso, escoramento de madeira, entulho com o pé na
## linha do chão, balde de tinta e uma única lâmpada no fio. Nenhum pixel de cenário
## novo, nenhuma moldura, nenhuma arte duplicada — é a mesma sala, inacabada.
func _draw_progress_works(wide: float, tall: float, ground: Vector2, alpha: float) -> void:
	var stroke := maxf(1.0, wide * 0.0018)
	# 1) Teto sem luz: a meia-luz da obra mora em cima, onde não há lustre nem vela
	# acesa. São três faixas horizontais de carga decrescente, e não um gradiente — a
	# camada só sabe retângulo, e retângulo escuro de carga baixa ninguém vê como régua.
	for demao in range(3):
		_progress_layer.draw_rect(Rect2(0.0, tall * float(demao) / 3.0, wide, tall / 3.0),
			Color(0.10, 0.09, 0.16, (0.11 - float(demao) * 0.04) * alpha))
	# 2) Parede sem última demão: onde a massa ainda não recebeu tinta é MAIS ESCURA que
	# a parede. Cada remendo são dois retângulos deslocados, sem contorno — um traço de
	# régua na beirada seria o suficiente para virar janela.
	for i in RENOVATION_WALL_PATCHES.size():
		var patch: Rect2 = RENOVATION_WALL_PATCHES[i]
		var area := Rect2(wide * patch.position.x, tall * patch.position.y,
			wide * patch.size.x, tall * patch.size.y)
		_progress_layer.draw_rect(area, Color(0.10, 0.09, 0.13, 0.42 * alpha))
		_progress_layer.draw_rect(Rect2(area.position.x + area.size.x * 0.12,
			area.position.y + area.size.y * 0.16, area.size.x * 0.7, area.size.y * 0.62),
			Color(0.17, 0.15, 0.20, 0.34 * alpha))
		# A borda de baixo do remendo é a única parte clara: é onde a massa termina e a
		# tinta começa, e sem esse degrau o retângulo escuro é só sombra de interface.
		_progress_layer.draw_rect(Rect2(area.position.x, area.end.y - tall * 0.008,
			area.size.x, tall * 0.008), Color(0.44, 0.41, 0.44, 0.20 * alpha))
	# 3) Lona no piso: o pano que a obra estende para receber tinta e gesso. Fica no
	# piso livre da frente da sala, onde o elenco passa por cima — corpo na frente do
	# pano é o que faz o pano estar no chão e não flutuando.
	var cloth := PackedVector2Array([])
	for canto in RENOVATION_CLOTH.size():
		var aqui: Vector2 = RENOVATION_CLOTH[canto]
		cloth.append(Vector2(wide * aqui.x, tall * aqui.y))
	_progress_layer.draw_colored_polygon(cloth, Color(0.52, 0.51, 0.58, 0.30 * alpha))
	for vinco in range(3):
		var t := 0.22 + float(vinco) * 0.26
		_progress_layer.draw_line(cloth[0].lerp(cloth[1], t), cloth[3].lerp(cloth[2], t),
			Color(0.18, 0.17, 0.22, 0.26 * alpha), stroke)
	# 4) Escoramento: cavaletes de dois pés com prancha por cima. Os pés batem na linha
	# do chão pintado, então o andaime pertence à sala, não à tela, e o elenco passa na
	# frente dele porque a camada é mais funda que o palco. O pé é largo o bastante para
	# ter duas bordas legíveis: a 5 pixels de traço ele era linha verde flutuando na
	# sala, e linha não é móvel de obra.
	var pole_w := maxf(3.0, wide * 0.0075)
	var plank_y := tall * RENOVATION_PLANK_Y
	var plank_w := maxf(2.0, tall * 0.014)
	for i in range(0, RENOVATION_POLES.size(), 2):
		var left := RENOVATION_POLES[i]
		var right: float = RENOVATION_POLES[mini(i + 1, RENOVATION_POLES.size() - 1)]
		for par in [left, right]:
			var head := Vector2(wide * par, plank_y)
			var foot := Vector2(wide * par, ground.y)
			_progress_layer.draw_line(head, foot, Color(0.20, 0.15, 0.11, 0.92 * alpha), pole_w)
			# O pé só existe na meia-luz porque tem aresta iluminada pela lâmpada: um
			# fio claro do lado que dá para a luz, e a madeira volta a ser objeto.
			_progress_layer.draw_line(head + Vector2(-pole_w * 0.5, 0.0),
				foot + Vector2(-pole_w * 0.5, 0.0),
				Color(0.62, 0.50, 0.36, 0.62 * alpha), maxf(1.5, stroke * 1.2))
			_progress_layer.draw_circle(foot, pole_w * 1.4, Color(0.05, 0.04, 0.07, 0.45 * alpha))
		var board := Rect2(wide * (left - 0.014), plank_y - plank_w * 0.5,
			wide * (right - left + 0.028), plank_w)
		_progress_layer.draw_rect(board, Color(0.30, 0.23, 0.15, 0.92 * alpha))
		_progress_layer.draw_rect(Rect2(board.position.x, board.position.y,
			board.size.x, plank_w * 0.26), Color(0.66, 0.54, 0.38, 0.55 * alpha))
		_progress_layer.draw_rect(Rect2(board.position.x, board.end.y - plank_w * 0.3,
			board.size.x, plank_w * 0.3), Color(0.10, 0.07, 0.06, 0.85 * alpha))
		_progress_layer.draw_line(
			Vector2(board.position.x + board.size.x * 0.5, board.position.y),
			Vector2(board.position.x + board.size.x * 0.5, board.end.y),
			Color(0.08, 0.06, 0.05, 0.60 * alpha), stroke)
	# 5) Entulho: montículo após montículo com a base na linha do chão. Três arcos de
	# raio diferente fazem pilha de gesso sem desenho novo, e o tijolo dá o canto duro
	# que a pilha arredondada sozinha não tem.
	for i in RENOVATION_RUBBLE.size():
		var offset: Vector2 = RENOVATION_RUBBLE[i]
		_draw_rubble_mound(ground + Vector2(wide * offset.x, tall * offset.y), wide * 0.050, alpha)
	var bucket := ground + Vector2(wide * RENOVATION_BUCKET.x, tall * RENOVATION_BUCKET.y)
	var bucket_w := wide * 0.022
	_progress_layer.draw_colored_polygon(PackedVector2Array([
		bucket + Vector2(-bucket_w, -tall * 0.028),
		bucket + Vector2(bucket_w * 1.15, -tall * 0.028),
		bucket + Vector2(bucket_w * 0.8, 0.0),
		bucket + Vector2(-bucket_w * 0.7, 0.0),
	]), Color(0.18, 0.18, 0.24, 0.80 * alpha))
	_progress_layer.draw_line(bucket + Vector2(-bucket_w, -tall * 0.028),
		bucket + Vector2(bucket_w * 1.15, -tall * 0.028),
		Color(0.62, 0.62, 0.70, 0.40 * alpha), stroke)
	# 6) A lâmpada do fio: enquanto não há lustre, a casa inteira depende de uma só
	# lâmpada na altura de trabalho. O centro é a luz pintada mais próxima do meio do
	# teto, porque é ali que o olho já procura o cabo.
	var lamps: Array = STAGE_ROOM_LIGHTS.get(_stage_room, [])
	var bulb_x := wide * 0.5
	var best := 9.9
	for lamp in lamps:
		var aqui_luz: Vector2 = lamp
		var score := absf(aqui_luz.x - 0.5) + aqui_luz.y
		if score < best:
			best = score
			bulb_x = wide * aqui_luz.x
	var bulb := Vector2(bulb_x, tall * 0.245)
	_progress_layer.draw_line(Vector2(bulb_x, 0.0),
		Vector2(bulb_x + wide * 0.006, bulb.y - tall * 0.010),
		Color(0.07, 0.06, 0.08, 0.85 * alpha), stroke)
	_progress_layer.draw_rect(Rect2(bulb + Vector2(-wide * 0.0035, -tall * 0.016),
		Vector2(wide * 0.007, tall * 0.008)), Color(0.16, 0.15, 0.15, 0.85 * alpha))
	_progress_layer.draw_circle(bulb, wide * 0.055, Color(1.0, 0.78, 0.40, 0.06 * alpha))
	_progress_layer.draw_circle(bulb, wide * 0.026, Color(1.0, 0.82, 0.46, 0.12 * alpha))
	_progress_layer.draw_circle(bulb, wide * 0.009, Color(1.0, 0.94, 0.72, 0.85 * alpha))
	_progress_layer.draw_colored_polygon(PackedVector2Array([
		bulb + Vector2(-wide * 0.012, tall * 0.007),
		bulb + Vector2(wide * 0.012, tall * 0.007),
		Vector2(bulb_x + wide * 0.16, ground.y),
		Vector2(bulb_x - wide * 0.16, ground.y),
	]), Color(1.0, 0.84, 0.50, 0.055 * alpha))

## Um montículo de entulho: meia-cúpula chata, em três tamancos, com a base exatamente
## na linha do chão. Sem RNG — o salão tem de sair igual de um redraw para o outro.
func _draw_rubble_mound(center: Vector2, radius: float, alpha: float) -> void:
	# A sombra no pé é o que prega a pilha no chão: sem ela o montículo flutua. Vem
	# antes das cúpulas, para sobrar dela só a borda em volta da base.
	_progress_layer.draw_circle(center, radius * 0.9, Color(0.05, 0.04, 0.07, 0.34 * alpha))
	for tier in range(3):
		var r := radius * (1.0 - float(tier) * 0.26)
		var pe := center + Vector2(radius * 0.42 * float(tier - 1), -r * 0.06 * float(tier))
		var shell := PackedVector2Array([pe + Vector2(-r, 0.0)])
		for step in range(1, 6):
			var angle := PI - float(step) * PI / 6.0
			shell.append(pe + Vector2(cos(angle) * r, sin(angle) * -r * 0.58))
		shell.append(pe + Vector2(r, 0.0))
		_progress_layer.draw_colored_polygon(shell,
			Color(0.36, 0.34, 0.38, (0.50 + float(tier) * 0.15) * alpha))
	for tijolo in range(2):
		var canto := center + Vector2(radius * (0.62 - float(tijolo) * 1.24), -radius * 0.2 * float(tijolo))
		_progress_layer.draw_rect(Rect2(canto, Vector2(radius * 0.36, radius * 0.16)),
			Color(0.34, 0.20, 0.16, 0.75 * alpha))

## A camada em si: tudo desenhado em código, em coordenadas normalizadas da sala,
## para funcionar nas quatro salas sem arte nova e sem arquivo novo no repositório.
func _draw_progress_decor() -> void:
	if not _stage_walkable or _progress_layer.size.x <= 0.0:
		return
	var wide := _progress_layer.size.x
	var tall := _progress_layer.size.y
	var floor_line: Vector2 = STAGE_ROOM_FLOOR.get(_stage_room, Vector2(0.60, 0.80))
	var ground := Vector2(wide * floor_line.x, tall * floor_line.y)
	var obras := _renovation_alpha(_progress_band)
	# A faixa 0 é o canteiro: nada de tapete, porque o piso ainda não foi encerado.
	# Faixa 1 — o piso encerado: a camada não desenha um tapete novo por cima do
	# que a arte já pintou, ela realça o tapete que está lá. Uma lavagem quente e
	# outra funda na mesma silhueta, e o brilho da borda de trás.
	if _progress_band >= 1:
		var mat := PackedVector2Array([])
		var rug: Array = PROGRESS_RUG.get(_stage_room, [])
		if rug.size() == 4:
			for corner in rug:
				mat.append(Vector2(wide * (corner as Vector2).x, tall * (corner as Vector2).y))
		else:
			var w := wide * 0.30
			var deep := tall * 0.055
			mat = PackedVector2Array([
				ground + Vector2(-w * 0.55, -deep * 2.0),
				ground + Vector2(w * 0.55, -deep * 2.0),
				ground + Vector2(w, deep),
				ground + Vector2(-w, deep),
			])
		_progress_layer.draw_colored_polygon(mat, Color(1.0, 0.70, 0.36, 0.09))
		_progress_layer.draw_colored_polygon(mat, Color(0.20, 0.02, 0.09, 0.16))
		_progress_layer.draw_line(mat[0], mat[1], Color(0.88, 0.70, 0.34, 0.28), 2.0)
	# A obra por último: prancha, pé de escoramento e entulho têm de aparecer na
	# frente do tapete, senão o andaime afunda no piso encerado.
	if obras > 0.0:
		_draw_progress_works(wide, tall, ground, obras)
	if _progress_band < 2:
		return
	# Faixa 2 — velas acesas: cada luz que a sala já tem na arte ganha o próprio
	# halo, largo e fraco, para parecer chama e não mancha.
	var lamps: Array = STAGE_ROOM_LIGHTS.get(_stage_room, [])
	for lamp in lamps:
		var here := Vector2(wide * (lamp as Vector2).x, tall * (lamp as Vector2).y)
		_progress_layer.draw_circle(here, wide * 0.055, Color(1.0, 0.72, 0.30, 0.05))
		_progress_layer.draw_circle(here, wide * 0.030, Color(1.0, 0.76, 0.34, 0.07))
		_progress_layer.draw_circle(here, wide * 0.010, Color(1.0, 0.88, 0.55, 0.30))
	if _progress_band < 3:
		return
	# Faixa 3 — caixilho dourado: a moldura nasce na beirada da tela, então ela
	# emoldura o salão em vez de entrar dentro dele.
	var trim := maxf(2.0, wide * 0.0022)
	for edge_y in [0.0, tall - trim]:
		_progress_layer.draw_rect(Rect2(Vector2(0.0, edge_y), Vector2(wide, trim)),
			Color(0.82, 0.66, 0.30, 0.42))
	for edge_x in [0.0, wide - trim]:
		_progress_layer.draw_rect(Rect2(Vector2(edge_x, 0.0), Vector2(trim, tall)),
			Color(0.82, 0.66, 0.30, 0.42))
	for corner_x in [0.03, 0.97]:
		_progress_layer.draw_circle(Vector2(wide * corner_x, tall * 0.03), wide * 0.008,
			Color(1.0, 0.84, 0.46, 0.18))
	if _progress_band < 4:
		return
	# Faixa 4 — lustre aceso: a luz principal desce do teto em cone fraco e ganha
	# corpo de brilho, sem ferragem desenhada por cima do lustre que a arte já tem.
	# O centro é a luz pintada mais próxima do meio do teto, não o meio geométrico
	# da tela — é ali que o olho já procura o lustre.
	var crown := Vector2(ground.x, tall * 0.05)
	var best := 9.9
	for lamp in lamps:
		var score := absf((lamp as Vector2).x - 0.5) + (lamp as Vector2).y
		if score < best:
			best = score
			crown = Vector2(wide * (lamp as Vector2).x, tall * (lamp as Vector2).y)
	_progress_layer.draw_colored_polygon(PackedVector2Array([
		crown + Vector2(-wide * 0.05, 0.0),
		crown + Vector2(wide * 0.05, 0.0),
		crown + Vector2(wide * 0.13, tall * 0.30),
		crown + Vector2(-wide * 0.13, tall * 0.30),
	]), Color(1.0, 0.84, 0.46, 0.06))
	for ring in range(4):
		_progress_layer.draw_circle(crown, wide * (0.09 - float(ring) * 0.022),
			Color(1.0, 0.82, 0.44, 0.05 + float(ring) * 0.05))
	# Poeira dourada suspensa: pontos fixos por posição derivada do índice, sem
	# RNG, para o salão continuar o mesmo entre dois redraws.
	for mote in range(26):
		var mx := fmod(float(mote) * 0.137, 1.0)
		var my := fmod(float(mote) * 0.311, 1.0)
		_progress_layer.draw_circle(Vector2(wide * mx, tall * (0.12 + my * 0.62)),
			wide * 0.0022, Color(1.0, 0.86, 0.48, 0.42))

## O que o painel diz da faixa: nome, o que ela acendeu e quanto falta para a
## próxima — a decoração precisa ter número, senão é enfeite sem meta.
func _progress_line() -> String:
	var band := _progress_band_now()
	var next_score: int = PROGRESS_BAND_SCORES[band + 1] if band + 1 < PROGRESS_BAND_SCORES.size() else 0
	var missing: int = next_score - business_score()
	# Nome e presente de faixa são conteúdo montado na hora, então passam pelo `tr()`
	# do chamador: a frase final nunca existiria na tabela para o motor achar sozinha.
	var linha := tr("A CASA ESTÁ: %s (placar %d) — %s") % [
		tr(PROGRESS_BAND_NAMES[band]), business_score(), tr(PROGRESS_BAND_GIFTS[band])]
	if missing > 0:
		linha += tr(" Próxima faixa em %d de placar.") % missing
	return linha

## Entregar à guilda é o meio-termo que existe só porque a cela existe: a casa
## ganha a rua como aliada e abre mão do sangue que aquele prisioneiro daria.
func _deliver_prisoner() -> void:
	if prisoners.is_empty():
		return
	var handed: Dictionary = prisoners.pop_front()
	_hand_to_guild(str(handed["name"]))
	_save_game()
	_refresh_ui()

## Painel da conserva: barro no chão, preço do balde e o que a rua acha disso.
func _mess_line() -> String:
	return "\n".join([
		"SALÃO: %d/%d de barro — fila -%d tique, etiqueta -%.1f%%." % [
			mess, MESS_LIMIT, _mess_patience_loss(), float(mess) * MESS_PRICE_PENALTY * 100.0],
		" • Balde e vassoura: %d ouro. Criada na folha: -%d por virada. Servo: -%d cada." % [
			_mop_cost(), Staff.sweep_per_turn(staff_hired), SERVANT_SWEEP],
		" • Chance de vândalo na próxima virada: %d%% (o barro puxa, a reputação de %d empurra)." % [
			_vandal_chance(), reputation],
	])

## Painel da cela: quem está preso, o que rende, o que custa e quem já foi embora
## do bairro de vez.
func _cell_line() -> String:
	var lines: Array[String] = []
	if prisoners.is_empty():
		lines.append("CELA DO SANTUÁRIO vazia (0 de %d). Cada reforma do santuário abre uma porta trancada — e um prato na conta." % _cell_capacity())
	else:
		var seats: Array[String] = []
		for held in prisoners:
			seats.append(str(held["name"]))
		lines.append("CELA (%d de %d): %s" % [prisoners.size(), _cell_capacity(), ", ".join(seats)])
		lines.append(" • Por virada: +%d frasco(s) de sangue morno para a forja, -%d de conta. O mais velho é o primeiro a sair." % [
			CELL_BLOOD * prisoners.size(), CELL_FOOD * prisoners.size()])
	if not banned_regulars.is_empty():
		var gone: Array[String] = []
		for banned_id in banned_regulars:
			gone.append(str(Regulars.find(str(banned_id)).get("short", "?")))
		lines.append(" • BANIDOS DO BAIRRO (%d): %s — nunca mais batem nesta porta." % [
			banned_regulars.size(), ", ".join(gone)])
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
	_play_sensual_reception_moment(float(step) / float(maxi(ROMANCE_STEPS.size() - 1, 1)))
	var wait := _summon_romance_partner(regular_id, int(invited["portrait"]))
	var pose := str(requirement["pose"])
	if not adult_content_enabled:
		# Com o filtro desligado o salão aperta a mão em vez de beijar: o corpo muda,
		# o degrau, o vínculo e o bônus permanente são os mesmos.
		pose = "aprovacao"
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

## O degrau da escada de momentos, sem reciclar: o primeiro momento puxa a primeira
## fala e o último degrau fica parado no topo para sempre. Os dois modos usam o mesmo
## índice, porque o espelho é da voz, não da porta.
func _private_moment_index() -> int:
	return clampi(private_moments_unlocked - 1, 0, SENSUAL_MOMENTS.size() - 1)

## O degrau do medidor de afeição: um quarto da escada a cada 10 pontos, com topo em
## 40. Serve aos dois modos, porque a fala é a mesma subida nos dois lados.
func _affection_milestone_index() -> int:
	return clampi(int(float(affection) / 10.0) - 1, 0, SENSUAL_AFFECTION_MILESTONES.size() - 1)

func _show_private_moment() -> void:
	if affection < 5:
		last_event = "“Paciência, querido. Primeiro conquiste minha confiança.”" if adult_content_enabled else "“Paciência. Primeiro conquiste minha confiança: o caderno da casa registra quem volta.”"
		_save_game()
		_refresh_ui()
		return
	private_moments_unlocked += 1
	var degrau := _private_moment_index()
	if adult_content_enabled:
		last_event = str(SENSUAL_MOMENTS[degrau])
		var topo: float = float(maxi(SENSUAL_MOMENTS.size() - 1, 1))
		_play_sensual_reception_moment(float(degrau) / topo)
	else:
		last_event = str(TRUST_MOMENTS[degrau])
	_show_feedback("♥ Momento %d/%d só da casa." % [degrau + 1, SENSUAL_MOMENTS.size()], Color(1.0, 0.62, 0.88))
	_save_game()
	_refresh_ui()

func _toggle_adult_content() -> void:
	adult_content_enabled = not adult_content_enabled
	adult_content_confirmed = true
	_set_seller_mood(_fury_mood())
	_set_sector(current_sector)
	last_event = "Cenas sensuais ativadas: a arte da recepção, as poses e o tom de flerte voltam para a tela." if adult_content_enabled else "Cenas sensuais desativadas: nenhuma arte provocante, pose ou flerte aparece no balcão. Progressão, economia, servos, momentos e conquistas seguem exatamente as mesmas — o que muda é a voz, nunca a porta."
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
