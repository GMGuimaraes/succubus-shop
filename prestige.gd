extends RefCounted
## Prestígio: fechar o império não fecha a loja, fecha a *vida* da loja. Reencarnar
## zera o caixa, a prateleira e a campanha, mas mantém as pessoas, o álbum e as
## lembranças — e paga aura, a moeda que não se gasta em mercadoria, e sim em dote
## permanente.
##
## O jogo guarda só `prestige_runs` (vidas já trocadas), `prestige_aura` (saldo),
## `prestige_perks` ({id_do_dote: nível}) e `prestige_goals_paid` (metas já pagas).
## Toda tabela aqui é fixa.

## Dotes permanentes. "cost" é o preço do primeiro nível; cada nível seguinte cobra
## um a mais. "step" é o que um nível entrega, na unidade do dote.
const PERKS: Array[Dictionary] = [
	{
		"id": "berco", "name": "Ouro de berço", "max": 5, "cost": 1, "step": 300,
		"unit": "de ouro na abertura", "desc": "A casa reabre com caixa feito.",
	},
	{
		"id": "pregao", "name": "Pregão da casa", "max": 5, "cost": 2, "step": 6, "suffix": "%",
		"unit": "em toda etiqueta", "desc": "Quem já foi lenda não precisa pechinchar.",
	},
	{
		"id": "sorte", "name": "Mão de baralho", "max": 4, "cost": 2, "step": 1,
		"unit": "de sorte na forja, na estrada e no pacote", "desc": "A casa já sabe onde a peça cai torta.",
	},
	{
		"id": "memoria", "name": "Memória de balcão", "max": 4, "cost": 3, "step": 12, "suffix": "%",
		"unit": "de experiência", "desc": "Segunda vida aprende mais rápido que a primeira.",
	},
]

## Aura de uma vida encerrada: o tamanho do império que ela deixou, com piso para
## que nem a volta mais magra saia da loja de mãos vazias.
static func aura_for(score: int) -> int:
	return maxi(2, int(round(float(score) / 1200.0)))

## Custo do próximo nível. Nivel zero paga o preço de tabela; cada degrau seguinte
## custa um a mais, para o último nível do último dote doer.
static func level_cost(perk: Dictionary, current_level: int) -> int:
	if current_level >= int(perk["max"]):
		return -1
	return int(perk["cost"]) + current_level

## A escada de metas. É ela que dá meta nova à vida seguinte: o dinheiro volta a
## zero, e o que a loja precisa provar cresce a cada degrau pago.
static func goal_for(index: int) -> Dictionary:
	return {"score": 5000 + index * 2500, "aura": 3 + index}

## Temporada do placar: cada vida da loja é uma temporada. Reencarnar não apaga a
## anterior — o recorde dela fica arquivado e a corrida recomeça do zero.
static func season(runs: int) -> int:
	return runs + 1

static func perk(id: String) -> Dictionary:
	for candidate in PERKS:
		if str(candidate["id"]) == id:
			return candidate
	return {}

## O que um dote entrega no nível informado, na unidade da própria tabela.
static func effect(id: String, level: int) -> int:
	return int(perk(id).get("step", 0)) * level

## O mesmo número escrito para o painel: "+12% em toda etiqueta".
static func effect_text(id: String, level: int) -> String:
	var candidate := perk(id)
	return "+%d%s %s" % [effect(id, level), str(candidate.get("suffix", "")), str(candidate.get("unit", ""))]
