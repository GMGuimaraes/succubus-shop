extends RefCounted
## Expedições: a loja manda um batedor buscar o que o mercado não vende.
## Cada destino tem custo em ouro, duração em segundos de mundo e tabela de
## botim. Sorte (alquimia, rituais, catalisadores) aumenta a quantidade e afasta
## os contratempos; logística barateia e acelera a viagem.
## Um dia de loja tem 60 segundos de mundo, por isso as durações abaixo viram dias.

const Ingredients = preload("res://ingredients.gd")

const DATA: Array = [
	{
		"id": "beco",
		"name": "Beco dos Restos",
		"min_day": 1,
		"cost": 25,
		"duration": 45.0,
		"danger": 8,
		"desc": "Lixo de nobre ainda é lixo, mas tem lixo que vale ouro.",
		"encounter": "Disputa com catadores armados",
		"loot": [
			{"id": "vazio", "chance": 100, "min": 2, "max": 4},
			{"id": "sal", "chance": 70, "min": 1, "max": 3},
			{"id": "essencia", "chance": 45, "min": 1, "max": 2},
			{"id": "lagrima", "chance": 6, "min": 1, "max": 1}
		]
	},
	{
		"id": "pantano",
		"name": "Pântano das Moedas Perdidas",
		"min_day": 4,
		"cost": 55,
		"duration": 90.0,
		"danger": 18,
		"desc": "Dizem que o fundo é feito de quem desceu para buscar moeda.",
		"encounter": "Emboscada entre a lama e as raízes",
		"loot": [
			{"id": "pena", "chance": 95, "min": 2, "max": 4},
			{"id": "tinta", "chance": 70, "min": 1, "max": 3},
			{"id": "po_lunar", "chance": 45, "min": 1, "max": 2},
			{"id": "lagrima", "chance": 18, "min": 1, "max": 2}
		]
	},
	{
		"id": "catacumba",
		"name": "Catacumba do Contrato",
		"min_day": 9,
		"cost": 95,
		"duration": 150.0,
		"danger": 30,
		"desc": "Os mortos assinaram embaixo. Ainda cobram juros.",
		"encounter": "O guardião desperta junto ao contrato",
		"loot": [
			{"id": "essencia", "chance": 100, "min": 3, "max": 6},
			{"id": "tinta", "chance": 80, "min": 2, "max": 3},
			{"id": "po_lunar", "chance": 60, "min": 1, "max": 3},
			{"id": "brasa", "chance": 28, "min": 1, "max": 2}
		]
	},
	{
		"id": "fenda",
		"name": "Fenda do Abismo",
		"min_day": 16,
		"cost": 150,
		"duration": 240.0,
		"danger": 45,
		"desc": "Não é loja, mas tem tudo o que a loja não tem.",
		"encounter": "A fenda distorce o campo de batalha",
		"loot": [
			{"id": "essencia", "chance": 90, "min": 4, "max": 7},
			{"id": "vazio", "chance": 60, "min": 3, "max": 5},
			{"id": "brasa", "chance": 70, "min": 1, "max": 3},
			{"id": "lagrima", "chance": 45, "min": 1, "max": 2}
		]
	}
]

const MISHAPS: Array[Dictionary] = [
	{"kind": "perda", "text": "O batedor voltou de mãos vazias: perdeu a bolsa na travessia."},
	{"kind": "furia", "text": "Voltou só metade da equipe. A outra metade ficou empenhada em jogo."},
	{"kind": "reputacao", "text": "Cobraram pedágio gritando o nome da loja na frente de todo mundo."}
]

static func size() -> int:
	return DATA.size()

static func find(id: String) -> Dictionary:
	for destination in DATA:
		if str(destination["id"]) == id:
			return destination
	return {}

static func is_unlocked(destination: Dictionary, day: int) -> bool:
	return day >= int(destination.get("min_day", 1))

static func locked_hint(destination: Dictionary) -> String:
	return "Libera no dia %d" % int(destination.get("min_day", 1))

static func cost_for(destination: Dictionary, logistics: int) -> int:
	return maxi(8, int(round(float(destination["cost"]) * (1.0 - 0.05 * float(logistics)))))

static func duration_for(destination: Dictionary, logistics: int) -> float:
	return maxf(12.0, float(destination["duration"]) * (1.0 - 0.07 * float(logistics)))

static func days_label(seconds: float) -> String:
	var days := seconds / 60.0
	return "%.1f dias de loja" % days if days >= 1.0 else "%.0f turnos de loja" % (days * 20.0)

static func journey_event(destination: Dictionary, progress: float) -> String:
	if progress < 0.12:
		return "Preparando a partida"
	if progress < 0.40:
		return "Avançando pela rota"
	if progress < 0.68:
		return "⚔ " + str(destination.get("encounter", "Confronto"))
	if progress < 0.88:
		return "Vasculhando o local"
	return "Voltando à loja"

static func mishap_chance(destination: Dictionary, luck: int) -> int:
	return clampi(int(destination.get("danger", 0)) - luck * 4, 2, 90)

## O que costuma voltar na mala: só os itens com chance relevante.
static func preview(destination: Dictionary) -> String:
	var parts: Array[String] = []
	for drop in destination["loot"]:
		if int(drop["chance"]) < 40:
			continue
		parts.append("%s x%d" % [ingredient_name(str(drop["id"])), int(drop["max"])])
	return "até " + ", ".join(parts)

static func ingredient_name(id: String) -> String:
	var common := Ingredients.find(id)
	if not common.is_empty():
		return str(common["name"])
	var rare := Ingredients.rare_find(id)
	return str(rare["name"]) if not rare.is_empty() else id

## Rola o botim. Cada ponto de sorte abre mais portas e pode acrescentar peça.
static func roll_loot(destination: Dictionary, luck: int) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for drop in destination["loot"]:
		var chance := clampi(int(drop["chance"]) + luck * 5, 0, 96)
		if randi() % 100 >= chance:
			continue
		var count := randi_range(int(drop["min"]), int(drop["max"]))
		if luck > 0 and randi() % 100 < luck * 12:
			count += 1
		if count > 0:
			found.append({"id": str(drop["id"]), "count": count})
	return found

## Viagem perigosa pode voltar com menos carga, menos moral ou menos reputação.
static func roll_mishap(destination: Dictionary, luck: int) -> Dictionary:
	var risk := mishap_chance(destination, luck)
	if randi() % 100 >= risk:
		return {}
	return MISHAPS[randi() % MISHAPS.size()]
