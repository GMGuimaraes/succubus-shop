extends RefCounted
## Economia reativa: o mercado responde ao que a loja faz, e não só ao calendário.
## Cada ingrediente e cada produto tem um "calor" (heat) que sobe com a demanda
## e desce com o excesso de oferta. O estado é um Dictionary salvo no jogo:
## { "ingredient": {id: heat}, "product": {id: heat} }.

const DECAY := 0.7
const MIN_HEAT := -1.0
const MAX_HEAT := 1.6
const PRICE_FLOOR := -0.40
const PRICE_CEIL := 0.85

static func fresh_state() -> Dictionary:
	return {"ingredient": {}, "product": {}}

static func bump(state: Dictionary, group: String, id: String, amount: float) -> void:
	if not state.has(group):
		return
	var table: Dictionary = state[group]
	table[id] = clampf(float(table.get(id, 0.0)) + amount, MIN_HEAT, MAX_HEAT)

## Um dia de loja novo: metade do burburinho evapora.
static func advance_day(state: Dictionary) -> void:
	for group in ["ingredient", "product"]:
		var table: Dictionary = state[group]
		for id in table.keys():
			table[id] = float(table[id]) * DECAY

static func heat(state: Dictionary, group: String, id: String) -> float:
	if not state.has(group):
		return 0.0
	return float((state[group] as Dictionary).get(id, 0.0))

## Fator de preço do mercado para um id. Comprar muito de um ingrediente encarece
## aquele ingrediente; vender muito de um produto cria fila, e fila sobe o preço.
static func factor(state: Dictionary, group: String, id: String) -> float:
	return 1.0 + clampf(heat(state, group, id), PRICE_FLOOR, PRICE_CEIL)

## Prateleira vazia é escassez: vale mais. Prateleira entupida desvaloriza.
static func stock_factor(stock: int) -> float:
	if stock <= 0:
		return 1.30
	if stock <= 2:
		return 1.10
	if stock <= 5:
		return 1.0
	if stock <= 9:
		return 0.88
	return 0.78

static func trend_marker(value: float) -> String:
	if value >= 0.55:
		return "▲▲"
	if value >= 0.15:
		return "▲"
	if value <= -0.30:
		return "▼▼"
	if value <= -0.08:
		return "▼"
	return "•"

static func hottest(state: Dictionary, group: String, ids: Array[String]) -> String:
	var best_id := ""
	var best_heat := 0.18
	for id in ids:
		if heat(state, group, id) > best_heat:
			best_heat = heat(state, group, id)
			best_id = id
	return best_id

## Boletim de uma linha para a recepção: o que está caro e o que está sobrando.
static func report(state: Dictionary, products: Array, ingredients: Array) -> String:
	var lines: Array[String] = []
	var best_product := ""
	var best_product_heat := 0.0
	for product in products:
		var product_heat := heat(state, "product", str(product["id"]))
		if product_heat > best_product_heat:
			best_product_heat = product_heat
			best_product = str(product["name"])
	var cheapest := ""
	var cheapest_factor := 2.0
	for ingredient in ingredients:
		var ingredient_id := str(ingredient["id"])
		var factor_value := factor(state, "ingredient", ingredient_id)
		if factor_value < cheapest_factor:
			cheapest_factor = factor_value
			cheapest = str(ingredient["name"])
	if best_product_heat > 0.15:
		lines.append("Procura alta por %s: fabrique e cobre." % best_product)
	if cheapest != "":
		lines.append("%s em oferta a %.0f%%: hora de estocar." % [cheapest, cheapest_factor * 100.0])
	if lines.is_empty():
		lines.append("Mercado calmo. Compre, fabrique e volte amanhã.")
	return " ".join(lines)
