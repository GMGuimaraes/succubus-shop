extends RefCounted
## Concorrência: a praça tem outras portas abertas, e cada uma delas cobra a sua
## parte do movimento. Uma rival tirando corpo da porta e dinheiro do bolso é o
## contrário de buff: é a rua respondendo ao preço da casa. Nada aqui sorteia — é
## aritmeta pura sobre o dia, o tempo e a fama, então a mesma semente continua
## desenhando a mesma loja.
##
## O jogo guarda só `rivals_absorbed` (Array[String] de quem já foi comprado). A
## abertura é lida do `shop_day` contra a tabela, e a absorção é o único estado.

## "day" é o dia de loja em que a placa acende. "crowd" é quantos corpos a menos
## batem na sua porta por tique, "undercut" quanto o bolso do freguês já chegou
## gasto. "cost" é o preço de calar a placa de uma vez; "gain" é o que sobe na
## prateleira quando a loja dela vira anexo seu.
const DATA: Array[Dictionary] = [
	{
		"id": "botica", "name": "Botica do Velho Arrabal", "day": 4,
		"crowd": 1, "undercut": 10, "cost": 520, "rep": 3,
		"gain": {"product": "frasco_motivacao", "count": 3},
		"desc": "Banqueta, balança e um velho que sabe o nome de cada freguês do beco.",
		"open": "A Botica do Velho Arrabal acendeu a placa. O velho atende na calçada e cobra menos só para não andar.",
		"war": "A Botica do Velho Arrabal chama o corpo antes de ele chegar à sua porta.",
		"bought": "Você comprou a Botica do Velho Arrabal. O velho agora atende no seu balcão e ensina o nome dos fregueses.",
	},
	{
		"id": "alambique", "name": "Alambique da Dona Corvo", "day": 13,
		"crowd": 1, "undercut": 18, "cost": 1350, "rep": 5,
		"gain": {"product": "incenso_teleporte", "count": 2},
		"desc": "Destila barato, entrega rápido e fala do preço da vizinha em voz alta.",
		"open": "O Alambique da Dona Corvo abriu as duas janelas. O cheiro do alambique dela é propaganda, e o preço é a segunda.",
		"war": "O Alambique da Dona Corvo leva quem já saiu de casa decidido a gastar pouco.",
		"bought": "Você comprou o Alambique da Dona Corvo. A placa dela desceu e o alambique dela subiu no seu fundo de loja.",
	},
	{
		"id": "vitrine", "name": "Vitrine Irmã Doroteia", "day": 27,
		"crowd": 2, "undercut": 30, "cost": 3200, "rep": 8,
		"gain": {"product": "adaga_charme", "count": 1},
		"desc": "Vidro limpo, crédito na hora e uma sorridente que conhece o padrinho de todo mundo.",
		"open": "A Vitrine Irmã Doroteia iluminou a calçada inteira. Ela dá crédito, e a rua inteira aceitou.",
		"war": "A Vitrine Irmã Doroteia leva dois corpos por batida e ainda cobra antes de você.",
		"bought": "Você comprou a Vitrine Irmã Doroteia. A praça agora tem uma placa só, e é a sua.",
	},
]

## A partir desta fama o bairro já sabe onde é a loja certa, e o preço da rival
## pesa metade no bolso de quem passa.
const FAME_HOLD := 50
const FAME_HOLD_DIVISOR := 2.0

static func size() -> int:
	return DATA.size()

static func find(id: String) -> Dictionary:
	for rival in DATA:
		if str(rival["id"]) == id:
			return rival
	return {}

static func knows(id: String) -> bool:
	return not find(id).is_empty()

## Quem está de placa acesa na praça nesta manhã.
static func active_ids(shop_day: int, absorbed: Array) -> Array[String]:
	var list: Array[String] = []
	for rival in DATA:
		var id := str(rival["id"])
		if shop_day >= int(rival["day"]) and not absorbed.has(id):
			list.append(id)
	return list

static func names(ids: Array) -> String:
	var parts: Array[String] = []
	for id in ids:
		var rival := find(str(id))
		if not rival.is_empty():
			parts.append(str(rival["name"]))
	return " • ".join(parts)

static func has(ids: Array, id: String) -> bool:
	return find(id).is_empty() or not ids.has(id)

## Quantos corpos a mais ficam do lado de fora. Fama de bairro segura metade do
## estrago: quem conhece a casa atravessa a calçada mesmo assim.
static func crowd_loss(ids: Array, fame: int) -> int:
	var sum := 0
	for id in ids:
		var rival := find(str(id))
		if not rival.is_empty():
			sum += int(rival["crowd"])
	return _hold(sum, fame)

## Quanto do orçamento já chegou gasto. Mesma régua da fama.
static func undercut(ids: Array, fame: int) -> int:
	var sum := 0
	for id in ids:
		var rival := find(str(id))
		if not rival.is_empty():
			sum += int(rival["undercut"])
	return _hold(sum, fame)

## O preço da placa, corrigido pelo que a loja já cresceu: quem espera até ter
## caixa compra barato, quem compra tarde paga a obra que a rival fez na rua.
static func price_for(rival: Dictionary, shop_day: int) -> int:
	var days := maxi(0, shop_day - int(rival["day"]))
	return int(round(float(rival["cost"]) * (1.0 + float(days) * 0.01)))

static func _hold(value: int, fame: int) -> int:
	if fame >= FAME_HOLD:
		return int(round(float(value) / FAME_HOLD_DIVISOR))
	return value
