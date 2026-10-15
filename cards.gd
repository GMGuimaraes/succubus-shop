extends RefCounted
## Cards colecionáveis da loja: cada carta é uma arte do jogo com raridade e
## coleção. O jogo guarda só `card_counts` em main.gd: { id_da_carta: quantidade }.
## Pacote novo sai no balcão; conquista entrega carta garantida. Repetição vira
## ouro de volta, e fechar uma coleção dá bônus de reputação.
##
## Cópia não é prêmio de consolação: três cópias da mesma carta viram ela
## holográfica e seis viram prismática. A evolução é derivada da contagem que já
## existe no save, e é ela que empurra o bônus de conjunto — o álbum passa a
## valer etiqueta melhor, sorte na forja e desconto no pacote.

const RARITIES: Array = [
	{"id": "comum", "name": "Comum", "color": "#9fb0c4", "weight": 40, "refund": 10},
	{"id": "rara", "name": "Rara", "color": "#6fd0ff", "weight": 27, "refund": 22},
	{"id": "epica", "name": "Épica", "color": "#c67bff", "weight": 21, "refund": 40},
	{"id": "lendaria", "name": "Lendária", "color": "#ffcf5c", "weight": 12, "refund": 70}
]

const DATA: Array = [
	{"id": "carta_padroeiro", "set": "fregueses", "rarity": "comum", "name": "O Padroeiro da Lança", "art": "res://assets/customer_adventurer.png", "desc": "Entrou comprando uma poção. Saiu devendo três."},
	{"id": "carta_mago", "set": "fregueses", "rarity": "comum", "name": "Mago do Quero Mana", "art": "res://assets/customer_mage.png", "desc": "Mana ele tem. Falta é educação."},
	{"id": "carta_gótica", "set": "fregueses", "rarity": "comum", "name": "A Menina das Velas", "art": "res://assets/customer_goth.png", "desc": "Comprou todas as velas. Nenhuma por alegria."},
	{"id": "carta_barbada", "set": "fregueses", "rarity": "rara", "name": "Barbárico em Liquidação", "art": "res://assets/customer_barbarian.png", "desc": "Quebrou o balcão e pagou em dentes."},
	{"id": "carta_ladra", "set": "fregueses", "rarity": "rara", "name": "A Que Leva Sem Pedir", "art": "res://assets/customer_rogue.png", "desc": "Ctrl+C não copia charme. Esse é proprietário."},
	{"id": "carta_cleriga", "set": "fregueses", "rarity": "rara", "name": "Clériga da Nota Fiscal", "art": "res://assets/customer_cleric.png", "desc": "Absolve, mas exige o cupom."},
	{"id": "carta_mercadora", "set": "fregueses", "rarity": "epica", "name": "Mercadora de Lua Cheia", "art": "res://assets/customer_merchant.png", "desc": "Preço bom é o que ela ainda não cobrou."},
	{"id": "carta_nobre", "set": "fregueses", "rarity": "epica", "name": "Fiscal do Pix Astral", "art": "res://assets/customer_noble.png", "desc": "Aproxima o cristal, querido."},
	{"id": "carta_sucubo_neutra", "set": "chefa", "rarity": "comum", "name": "Atendimento Padrão", "art": "res://assets/seller_neutral.png", "desc": "Sorriso profissional, olho em cima do caixa."},
	{"id": "carta_sucubo_feliz", "set": "chefa", "rarity": "rara", "name": "Comissão do Dia", "art": "res://assets/seller_happy.png", "desc": "Ouro no cofre, rubor na cara."},
	{"id": "carta_sucubo_surpresa", "set": "chefa", "rarity": "epica", "name": "Estoque Vazio", "art": "res://assets/seller_surprised.png", "desc": "A expressão de quem ouviu 'tem parcelado?'."},
	{"id": "carta_forma_demoneaca", "set": "chefa", "rarity": "lendaria", "name": "Forma Demoníaca", "art": "res://assets/seller_demonic.png", "desc": "Fúria cinco. Negociação seis."},
	{"id": "carta_balcon", "set": "casa", "rarity": "comum", "name": "Balcão de Recepção", "art": "res://assets/reception_scene.png", "desc": "Onde tudo é culpa do cliente."},
	{"id": "carta_forja", "set": "casa", "rarity": "rara", "name": "Bigorna Suada", "art": "res://assets/forge_close_scene.png", "desc": "Fogo alto, margem maior."},
	{"id": "carta_biblioteca", "set": "casa", "rarity": "epica", "name": "Grimório Vivo", "art": "res://assets/library_close_scene.png", "desc": "Ele lê você de volta."},
	{"id": "carta_santuario", "set": "casa", "rarity": "lendaria", "name": "Relíquia Acalmada", "art": "res://assets/sanctum_close_scene.png", "desc": "Só dorme quando convém."}
]

const SET_NAMES := {"fregueses": "Fregueses", "chefa": "A Chefa", "casa": "A Casa"}

## Degraus de evolução, medidos em cópias da mesma carta. O nome aparece no mural
## e o peso é o que entra na conta do conjunto.
const EVOLUTIONS: Array = [
	{"copies": 3, "name": "holo", "weight": 1},
	{"copies": 6, "name": "prismática", "weight": 2}
]

## O set fechado dobra o peso; enquanto ele não fecha, cada carta ainda conta.
const SET_COMPLETE_MULT := 2
## Quanto cada ponto de peso vale no jogo.
const PRICE_PER_POWER := 0.004
const LUCK_PER_POWER := 6
## Cada ponto de peso da casa pintada derruba 1 ouro do pacote. É o bastante para o
## álbum Prismático completo encostar no piso — e é por isso que o piso existe.
const DISCOUNT_PER_POWER := 1
## Desconto nenhum derruba o pacote a este piso: carta grátis não existe nem em sonho.
const PACK_FLOOR := 20

static func size() -> int:
	return DATA.size()

static func find(id: String) -> Dictionary:
	for card in DATA:
		if str(card["id"]) == id:
			return card
	return {}

static func rarity_of(card: Dictionary) -> Dictionary:
	for rarity in RARITIES:
		if str(rarity["id"]) == str(card.get("rarity", "comum")):
			return rarity
	return RARITIES[0]

static func color_of(card: Dictionary) -> Color:
	return Color(str(rarity_of(card)["color"]))

static func refund_of(card: Dictionary) -> int:
	return int(rarity_of(card)["refund"])

static func owned_count(counts: Dictionary) -> int:
	var total := 0
	for id in counts.keys():
		if int(counts[id]) > 0:
			total += 1
	return total

static func pack_price(opened: int, counts: Dictionary) -> int:
	return maxi(PACK_FLOOR, 40 + mini(opened, 10) * 3 - pack_discount(counts))

## Abre um pacote. Sorte empurra a raridade e, com bastante sorte, fura a
## repetição: enquanto houver carta nova, a nova vence o empate.
static func open_pack(counts: Dictionary, luck: int) -> Dictionary:
	var pool: Array[Dictionary] = []
	for card in DATA:
		var weight := int(rarity_of(card)["weight"]) + luck * (4 if int(counts.get(str(card["id"]), 0)) == 0 else 0)
		pool.append({"card": card, "weight": maxi(1, weight)})
	var total := 0
	for entry in pool:
		total += int(entry["weight"])
	var picked := randi() % maxi(1, total)
	for entry in pool:
		picked -= int(entry["weight"])
		if picked < 0:
			var card: Dictionary = entry["card"]
			var had := int(counts.get(str(card["id"]), 0))
			counts[str(card["id"])] = had + 1
			return {"card": card, "duplicate": had > 0}
	var last: Dictionary = pool[pool.size() - 1]["card"]
	return {"card": last, "duplicate": int(counts.get(str(last["id"]), 0)) > 0}

## Progresso por coleção: serve para o bônus de fechar um baralho inteiro.
static func sets(counts: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for set_id in SET_NAMES.keys():
		var total := 0
		var have := 0
		for card in DATA:
			if str(card["set"]) != set_id:
				continue
			total += 1
			if int(counts.get(str(card["id"]), 0)) > 0:
				have += 1
		result.append({"id": set_id, "name": str(SET_NAMES[set_id]), "have": have, "total": total, "complete": have == total})
	return result

static func newly_completed(counts: Dictionary, before: Array[String]) -> Array[String]:
	var done: Array[String] = []
	for info in sets(counts):
		if bool(info["complete"]) and not before.has(str(info["id"])):
			done.append(str(info["id"]))
	return done

static func summary(counts: Dictionary) -> String:
	return "%d/%d cartas • %s" % [owned_count(counts), size(), " | ".join(set_lines(counts))]

static func set_lines(counts: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for info in sets(counts):
		lines.append("%s %d/%d" % [str(info["name"]), int(info["have"]), int(info["total"])])
	return lines

## 0 = normal, 1 = holográfica, 2 = prismática. Derivado da cópia, sem estado novo.
static func evolution(copies: int) -> int:
	var level := 0
	for i in range(EVOLUTIONS.size()):
		if copies >= int(EVOLUTIONS[i]["copies"]):
			level = i + 1
	return level

static func evolution_name(copies: int) -> String:
	var level := evolution(copies)
	return "" if level == 0 else str(EVOLUTIONS[level - 1]["name"])

## Peso da carta no conjunto: existir vale 1 e o degrau soma o resto.
static func power_of(copies: int) -> int:
	if copies <= 0:
		return 0
	var level := evolution(copies)
	return 1 if level == 0 else 1 + int(EVOLUTIONS[level - 1]["weight"])

static func set_power(counts: Dictionary, set_id: String) -> int:
	var power := 0
	for card in DATA:
		if str(card["set"]) != set_id:
			continue
		power += power_of(int(counts.get(str(card["id"]), 0)))
	if power <= 0:
		return 0
	for info in sets(counts):
		if str(info["id"]) == set_id and bool(info["complete"]):
			return power * SET_COMPLETE_MULT
	return power

## Etiqueta: a freguesia do álbum paga mais caro em toda venda.
static func price_bonus(counts: Dictionary) -> float:
	return float(set_power(counts, "fregueses")) * PRICE_PER_POWER

## Sorte: a chefa desenhada ajuda na forja, na estrada e no próprio pacote.
static func luck_bonus(counts: Dictionary) -> int:
	return set_power(counts, "chefa") / LUCK_PER_POWER

## Desconto: a casa pintada barateia o próximo pacote.
static func pack_discount(counts: Dictionary) -> int:
	return set_power(counts, "casa") / DISCOUNT_PER_POWER

static func bonus_lines(counts: Dictionary) -> Array[String]:
	return [
		"Fregueses %d → etiqueta +%.1f%%" % [set_power(counts, "fregueses"), price_bonus(counts) * 100.0],
		"A Chefa %d → sorte +%d na forja, na estrada e no pacote" % [set_power(counts, "chefa"), luck_bonus(counts)],
		"A Casa %d → −%d de ouro no pacote" % [set_power(counts, "casa"), pack_discount(counts)],
	]

## Quantas cartas já chegaram ao degrau indicado (1 holo, 2 prismática).
static func evolved_count(counts: Dictionary, level: int) -> int:
	var total := 0
	for id in counts.keys():
		if evolution(int(counts[id])) >= level:
			total += 1
	return total
