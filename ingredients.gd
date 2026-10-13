extends RefCounted
## Ingredientes da cadeia de produção: estoque próprio e mercado com preços
## que flutuam a cada dia de loja. O jogo guarda só o estoque por id
## (ingredient_stock em main.gd); os preços são derivados do dia, sem save.

const DATA: Array = [
	{"id": "essencia", "name": "Essência Emocional", "base_price": 4, "desc": "Destilada de sentimentos não resolvidos."},
	{"id": "pena", "name": "Pena de Pato Amaldiçoado", "base_price": 6, "desc": "Cai sozinha. O pato não sente falta. Ele julga."},
	{"id": "sal", "name": "Sal Gamer Refinado", "base_price": 5, "desc": "Colhido em partidas ranqueadas."},
	{"id": "vazio", "name": "Vazio Certificado", "base_price": 3, "desc": "Nada, mas com selo de qualidade."},
	{"id": "po_lunar", "name": "Pó Lunar de Terça-feira", "base_price": 9, "desc": "Só funciona em dias úteis."},
	{"id": "tinta", "name": "Tinta de Contrato Infernal", "base_price": 7, "desc": "Seca rápido. As cláusulas, nunca."}
]

static func find(id: String) -> Dictionary:
	for ingredient in DATA:
		if str(ingredient["id"]) == id:
			return ingredient
	return {}

## Preço do dia: varia entre 70% e 140% do preço base, determinístico por dia,
## para que o mercado seja igual ao recarregar o save no mesmo dia.
static func price_for_day(id: String, day: int) -> int:
	var ingredient := find(id)
	if ingredient.is_empty():
		return 1
	var base := int(ingredient["base_price"])
	var seed_value: int = absi(hash("%s:%d" % [id, day]))
	var factor := 0.7 + float(seed_value % 71) / 100.0
	return maxi(1, int(round(float(base) * factor)))
