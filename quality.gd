extends RefCounted
## Espectro de qualidade das mercadorias fabricadas na forja.
## Cada peça cai em um nível, e o valor de venda é o preço base vezes o
## multiplicador do nível. O jogo guarda `quality_stock` em main.gd:
## { id_do_produto: [torto, honesto, refinado, obra_prima, mitico] }.

const QUALITIES: Array = [
	{"id": "torto", "name": "Torto", "mult": 0.7, "color": "#8d8794", "weight": 26},
	{"id": "honesto", "name": "Honesto", "mult": 1.0, "color": "#c9d6e4", "weight": 38},
	{"id": "refinado", "name": "Refinado", "mult": 1.35, "color": "#8ef0b4", "weight": 21},
	{"id": "prima", "name": "Obra-prima", "mult": 1.85, "color": "#ffd76a", "weight": 11},
	{"id": "mitico", "name": "Mítico", "mult": 2.5, "color": "#e88bff", "weight": 4},
	## Peso zero não é descuido: é o degrau selado. Ele só entra no rolo quando a
	## forja chega ao topo, e aí cada ponto acima da porta pesa na balança.
	{"id": "lendario", "name": "Lendário", "mult": 3.4, "color": "#ff8a3d", "weight": 0}
]

const BEST := 0
const WORST := 1
## O degrau selado do espectro e a mestria que a forja precisa juntar para ele
## aparecer no rolo (alquimia + biblioteca, os dois no teto dão 10).
## LEGENDARY é o último índice de QUALITIES — quem acrescentar degrau move os dois.
const LEGENDARY := 5
const MASTERY_GATE := 6

static func size() -> int:
	return QUALITIES.size()

static func tier(index: int) -> Dictionary:
	return QUALITIES[clampi(index, 0, QUALITIES.size() - 1)]

static func color_of(index: int) -> Color:
	return Color(str(tier(index)["color"]))

static func price_for(base_price: int, index: int) -> int:
	return maxi(1, int(round(float(base_price) * float(tier(index)["mult"]))))

static func empty_stock() -> Array[int]:
	var counts: Array[int] = []
	for i in range(QUALITIES.size()):
		counts.append(0)
	return counts

## Rola o nível de uma peça recém-fabricada. Alquimia e bênçãos empurram a
## curva: cada ponto de sorte deixa as peças ruins mais raras e as boas mais comuns.
## O degrau selado só pesa na balança quando a mestria da forja passa da porta.
static func roll(luck: int, mastery: int = 0) -> int:
	var weights := weights_for(luck, mastery)
	var total := 0
	for weight in weights:
		total += weight
	var picked := randi() % total
	for i in range(weights.size()):
		picked -= weights[i]
		if picked < 0:
			return i
	return 1

## A balança de um rolo, nível por nível. Serve para sortear e para o painel dizer
## com honestidade com que frequência o topo sai da bigorna.
static func weights_for(luck: int, mastery: int = 0) -> Array[int]:
	var weights: Array[int] = []
	for i in range(QUALITIES.size()):
		var base := float(QUALITIES[i]["weight"])
		if base <= 0.0:
			weights.append(sealed_weight(mastery))
			continue
		var shaped := base * pow(1.30, float(luck)) if i >= 2 else base * pow(0.80, float(luck))
		weights.append(maxi(1, int(round(shaped))))
	return weights

## Chance real de sair com a peça do nível informado, hoje, nesta forja.
static func chance(luck: int, mastery: int, index: int) -> float:
	var weights := weights_for(luck, mastery)
	var total := 0
	for weight in weights:
		total += weight
	if total <= 0:
		return 0.0
	return float(weights[clampi(index, 0, weights.size() - 1)]) / float(total)

## Quanto o topo selado pesa no rolo de uma forja com a mestria informada. Zero
## abaixo da porta; acima dela, cada degrau extra pesa quatro vezes mais.
static func sealed_weight(mastery: int) -> int:
	if mastery < MASTERY_GATE:
		return 0
	return (mastery - MASTERY_GATE + 1) * 4

## O nível que a forja alcança hoje, para o painel dizer se o Lendário está
## trancado ou já está no rolo.
static func open(mastery: int) -> bool:
	return sealed_weight(mastery) > 0

## Escolhe qual peça sai do estoque numa venda. Clientes comuns levam a pior
## (guarda o melhor para quem paga mais); conhecedores escolhem a melhor.
static func take(stock: Array[int], mode: int) -> int:
	for i in range(QUALITIES.size()):
		if mode == WORST and int(stock[i]) > 0:
			stock[i] = int(stock[i]) - 1
			return i
		if mode == BEST and i >= 0 and int(stock[QUALITIES.size() - 1 - i]) > 0:
			var best := QUALITIES.size() - 1 - i
			stock[best] = int(stock[best]) - 1
			return best
	return -1

static func total(stock: Array[int]) -> int:
	var sum := 0
	for count in stock:
		sum += int(count)
	return sum

static func summary(stock: Array[int]) -> String:
	var parts: Array[String] = []
	for i in range(QUALITIES.size()):
		if int(stock[i]) > 0:
			parts.append("%s x%d" % [str(tier(i)["name"]), int(stock[i])])
	return "sem peças" if parts.is_empty() else " | ".join(parts)
