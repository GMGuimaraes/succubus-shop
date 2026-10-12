extends RefCounted
## Facções da clientela: reputação persistente, bônus de preço e falas de capítulo.
## O jogo guarda só o número de negócios concluídos com cada id (faction_standing).

const THRESHOLDS: Array[int] = [0, 5, 15, 30]
const TIER_NAMES: Array[String] = ["Desconhecida", "Notada", "Respeitada", "Lenda"]

const DATA: Array = [
	{
		"id": "guildas",
		"name": "Guildas",
		"short": "Guildas",
		"color": "#c5e8ff",
		"tier_up": [
			"Um mensageiro da guilda deixa um selo de cera: vocês estão no caderno de fornecedores.",
			"A guilda reserva uma mesa para vocês. A conta, claro, ainda é de vocês.",
			"Vocês viram lenda da guilda. Até o tesoureiro sorriu. Foi assustador."
		]
	},
	{
		"id": "nobres",
		"name": "Nobres",
		"short": "Nobres",
		"color": "#ffe6a8",
		"tier_up": [
			"Uma carta com perfume de lírio chega: “A corte notou a sua loja. Que ousadia encantadora.”",
			"Um barão envia um convite. O verso pede desconto. Nobreza é isso.",
			"A corte murmura o nome da loja. Vocês são moda. E moda cobra caro."
		]
	},
	{
		"id": "aventureiros",
		"name": "Aventureiros",
		"short": "Aventureiros",
		"color": "#c8f5c4",
		"tier_up": [
			"Um grupo marca a loja no mapa da taverna. “Poções honestas. Relativamente.”",
			"Aventureiros passam a recomendar vocês entre uma morte e outra.",
			"A guilda de aventureiros jura pela sua prateleira. Juraram pela anterior também, mas desta vez é sério."
		]
	},
	{
		"id": "mercadores",
		"name": "Mercadores",
		"short": "Mercadores",
		"color": "#ffd9b0",
		"tier_up": [
			"Um camelô deixa um cartão: “Parceria? Ou pelo menos não copie minhas placas.”",
			"A feira reserva um canto para vocês. O aluguel é simbólico. O símbolo é ouro.",
			"Os mercadores copiam suas ofertas. Imitação é o imposto do sucesso."
		]
	},
	{
		"id": "submundo",
		"name": "Submundo",
		"short": "Submundo",
		"color": "#e8c4ff",
		"tier_up": [
			"Alguém deixa uma adaga e um recado: “A casa agora tem proteção. Não pergunte de quem.”",
			"O submundo passa a pagar em moeda limpa. Relativamente limpa.",
			"Criaturas das sombras chamam vocês de família. Família cobra juros, mas também traz clientes."
		]
	}
]

static func tier_for(standing: int) -> int:
	var tier := 0
	for i in range(THRESHOLDS.size()):
		if standing >= THRESHOLDS[i]:
			tier = i
	return tier

static func find(id: String) -> Dictionary:
	for faction in DATA:
		if str(faction["id"]) == id:
			return faction
	return {}

static func price_bonus(tier: int) -> float:
	var bonuses: Array[float] = [0.0, 0.06, 0.12, 0.20]
	return bonuses[clampi(tier, 0, bonuses.size() - 1)]
