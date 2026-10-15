extends RefCounted
## Rituais do santuário: buffs temporários pagos em ouro e rituais de alívio,
## que reduzem penalidades já acumuladas (fúria, reputação, item roubado).
## O jogo guarda `active_buffs` em main.gd: { id_do_ritual: segundos_de_mundo }.
## Um tick de mundo vale 3 segundos, então as durações abaixo são lidas assim.
##
## Campos de efeito (todos opcionais, somados sobre os rituais ativos):
##   price    fração de acréscimo no preço de venda (0.18 = +18%)
##   craft    fração de aceleramento da forja
##   luck     empurra a rolagem de qualidade para cima
##   xp       fração de acréscimo de experiência
##   patience paciência extra do cliente
##   guard    1 = nenhuma peça é furtada enquanto ativo
##   fury     (alívio) pontos de fúria removidos
##   rep      (alívio) pontos de reputação devolvidos
##   theft    (alívio) recupera o item roubado sem pagar o rastreador

const DATA: Array = [
	{
		"id": "charme_abissal",
		"name": "Charme Abissal",
		"icon": "🍷",
		"kind": "buff",
		"cost": 70,
		"duration": 90,
		"price": 0.18,
		"desc": "Ela se debruça sobre o balcão e a fila concorda com qualquer etiqueta. Preços +18%."
	},
	{
		"id": "forja_veloz",
		"name": "Forja Veloz",
		"icon": "🔥",
		"kind": "buff",
		"cost": 55,
		"duration": 90,
		"craft": 0.35,
		"luck": 1,
		"desc": "Runas quentes na bigorna: fabricação 35% mais rápida e a peça sai caprichada."
	},
	{
		"id": "sussurro_ancestral",
		"name": "Sussurro Ancestral",
		"icon": "🕯️",
		"kind": "buff",
		"cost": 65,
		"duration": 90,
		"xp": 0.30,
		"desc": "As estátuas velhas contam os erros delas de graça. XP ganho +30%."
	},
	{
		"id": "paciencia_do_cordeiro",
		"name": "Paciência do Cordeiro",
		"icon": "🐑",
		"kind": "buff",
		"cost": 40,
		"duration": 120,
		"patience": 2,
		"desc": "A fila respira em vez de rosna. Clientes esperam +2 turnos antes de ir embora."
	},
	{
		"id": "selo_da_cadeia",
		"name": "Selo da Cadeia",
		"icon": "⛓️",
		"kind": "buff",
		"cost": 50,
		"duration": 120,
		"guard": 1,
		"desc": "Nenhuma peça sai da loja sem paga. Ladrões voltam as mãos vazias."
	},
	{
		"id": "penitencia",
		"name": "Penitência Curta",
		"icon": "🩸",
		"kind": "relief",
		"cost": 45,
		"fury": 3,
		"desc": "A ira da chefe desce para um pote de sangue e volta ao trabalho. Fúria −3."
	},
	{
		"id": "perdao_vendido",
		"name": "Perdão Vendido",
		"icon": "📜",
		"kind": "relief",
		"cost": 80,
		"rep": 5,
		"desc": "Absolvição com taxa de serviço e recibo carimbado. Reputação +5."
	},
	{
		"id": "rastro_sagrado",
		"name": "Rastro Sagrado",
		"icon": "👁️",
		"kind": "relief",
		"cost": 60,
		"theft": 1,
		"desc": "A relíquia sussurra para onde o ladrão correu. Recupera o item roubado na hora."
	}
]

static func find(id: String) -> Dictionary:
	for ritual in DATA:
		if str(ritual["id"]) == id:
			return ritual
	return {}

static func is_buff(item: Dictionary) -> bool:
	return str(item.get("kind", "buff")) == "buff"

## O santuário evoluido cobra menos e segura o efeito por mais tempo.
static func cost_for(item: Dictionary, level: int) -> int:
	return maxi(10, int(round(float(item.get("cost", 50)) * (1.0 - 0.06 * float(level)))))

static func duration_for(item: Dictionary, level: int) -> float:
	if not is_buff(item):
		return 0.0
	return float(item.get("duration", 0)) * (1.0 + 0.15 * float(level))

static func is_active(active: Dictionary, id: String) -> bool:
	return float(active.get(id, 0.0)) > 0.0

## Segundos restantes viram leitura humana no card do santuário.
static func remaining_label(active: Dictionary, id: String, elapsed_game_seconds: float = 0.0) -> String:
	var seconds := float(active.get(id, 0.0)) - elapsed_game_seconds
	if seconds <= 0.0:
		return "encerrado"
	return "%ds" % int(ceil(seconds))

static func start(active: Dictionary, id: String, level: int) -> void:
	var item := find(id)
	if item.is_empty() or not is_buff(item):
		return
	active[id] = duration_for(item, level)

## Um passo do tempo de mundo: vela queima, ritual apaga.
static func advance(active: Dictionary, game_seconds: float) -> void:
	for id in active.keys():
		var left := float(active[id]) - game_seconds
		if left <= 0.0:
			active.erase(id)
		else:
			active[id] = left

## Soma de um campo numérico sobre os rituais ativos (0 quando ninguém reza).
static func sum(active: Dictionary, key: String) -> float:
	var total := 0.0
	for id in active.keys():
		var item := find(str(id))
		if item.is_empty():
			continue
		total += float(item.get(key, 0.0))
	return total

## Fator multiplicativo 1.0 + soma do campo, com teto para nada quebrar a economia.
## O piso existe porque "craft" vira divisor do tempo de forja: um ritual futuro de
## penalidade não pode deixar o resultado zero e a fabricação virar infinita.
static func scale(active: Dictionary, key: String, ceiling: float = 1.0, floor: float = 0.25) -> float:
	return clampf(1.0 + sum(active, key), floor, 1.0 + ceiling)

static func guards(active: Dictionary) -> bool:
	return sum(active, "guard") >= 1.0

static func luck_bonus(active: Dictionary) -> int:
	return int(round(sum(active, "luck")))

static func patience_bonus(active: Dictionary) -> int:
	return int(round(sum(active, "patience")))

static func summary(active: Dictionary, elapsed_game_seconds: float = 0.0) -> String:
	if active.is_empty():
		return "Nenhum ritual em curso. O santuário está só decorando poeira."
	var parts: Array[String] = []
	for id in active.keys():
		var item := find(str(id))
		if item.is_empty():
			continue
		parts.append("%s %s (%s)" % [item.get("icon", "✦"), item["name"], remaining_label(active, str(id), elapsed_game_seconds)])
	return " | ".join(parts)
