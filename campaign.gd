extends RefCounted
## Campanha principal: capítulos encadeados que dão direção à loja e terminam
## no império. Cada capítulo só cobra sistemas que já existem no jogo, então
## "zerar" é fazer o que o balcão já permite, só que até o fim.
##
## O jogo guarda apenas `campaign_step` (índice do capítulo atual) e
## `game_completed`; tudo aqui é catálogo fixo, sem estado.

const STAT_LABELS := {
	"customers_served": "clientes atendidos",
	"ingredients_bought": "ingredientes comprados",
	"crafted": "peças fabricadas",
	"gold": "ouro em caixa",
	"happy_customers": "clientes encantados",
	"regular_stories": "capítulos de fregueses",
	"expeditions": "expedições de volta",
	"rare_found": "raridades colhidas",
	"premium_crafted": "peças de alto nível",
	"library_level": "nível da biblioteca",
	"sanctum_level": "nível do santuário",
	"rituals": "rituais feitos",
	"cards": "cards únicos no álbum",
	"sets": "coleções completas",
	"packs": "pacotes abertos",
	"level": "nível da chefe",
	"reputation": "reputação",
	"faction_tier": "melhor patamar de facção",
	"best_quality": "melhor qualidade fabricada"
}

const DATA: Array = [
	{
		"id": "portas_abertas",
		"name": "Abrir as portas",
		"desc": "A loja existe quando alguém passa do batente. Atenda os primeiros clientes e aprenda a repor prateleira.",
		"conditions": {"customers_served": 5, "ingredients_bought": 3},
		"gold": 50, "rep": 3, "xp": 25
	},
	{
		"id": "primeira_fornada",
		"name": "Primeira fornada",
		"desc": "Ingrediente parado é dinheiro parado. Tire peças da bigorna e faça caixa girar.",
		"conditions": {"crafted": 5, "gold": 150},
		"gold": 70, "rep": 4, "xp": 40
	},
	{
		"id": "freguesia",
		"name": "Freguesia feita",
		"desc": "Cliente que volta conta história. Encante a clientela e feche o capítulo de um freguês.",
		"conditions": {"happy_customers": 5, "regular_stories": 1},
		"gold": 95, "rep": 5, "xp": 60, "pack": 1
	},
	{
		"id": "estrada_e_bigorna",
		"name": "Estrada e bigorna",
		"desc": "O mercado não vende raridade. Mande o batedor, traga material e deixe a forja trabalhar.",
		"conditions": {"expeditions": 3, "rare_found": 1, "premium_crafted": 2},
		"gold": 140, "rep": 6, "xp": 90
	},
	{
		"id": "casa_arrumada",
		"name": "Casa arrumada",
		"desc": "Biblioteca e santuário andam juntos: um ensina a receita, o outro doma a relíquia.",
		"conditions": {"library_level": 2, "sanctum_level": 2, "rituals": 5},
		"gold": 200, "rep": 8, "xp": 140, "pack": 1
	},
	{
		"id": "colecionadora",
		"name": "Colecionadora",
		"desc": "A máquina de cartas virou atração no balcão. Encha metade do álbum e feche uma coleção.",
		"conditions": {"cards": 10, "sets": 1, "packs": 6},
		"gold": 260, "rep": 10, "xp": 180
	},
	{
		"id": "imperio",
		"name": "Império do balcão",
		"desc": "O último capítulo não é uma tarefa: é a loja inteira funcionando junta, no alto.",
		"conditions": {"level": 12, "reputation": 60, "gold": 2500, "faction_tier": 2, "best_quality": 4},
		"gold": 600, "rep": 20, "xp": 400, "pack": 2, "final": true
	}
]

static func size() -> int:
	return DATA.size()

static func chapter(index: int) -> Dictionary:
	if index < 0 or index >= DATA.size():
		return {}
	return DATA[index]

static func is_final(index: int) -> bool:
	return bool(chapter(index).get("final", false))

static func complete(stats: Dictionary, chapter_data: Dictionary) -> bool:
	return missing(stats, chapter_data).is_empty()

## Linhas de conferência: o que cada capítulo pede e o quanto já foi.
static func progress(stats: Dictionary, chapter_data: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var conditions: Dictionary = chapter_data.get("conditions", {})
	var keys: Array = conditions.keys()
	keys.sort()
	for key in keys:
		var need := int(conditions[key])
		var have := int(stats.get(String(key), 0))
		var mark := "✔" if have >= need else "✘"
		lines.append("%s %s: %d/%d" % [mark, String(STAT_LABELS.get(String(key), String(key))), have, need])
	return lines

static func missing(stats: Dictionary, chapter_data: Dictionary) -> Array[String]:
	var pending: Array[String] = []
	var conditions: Dictionary = chapter_data.get("conditions", {})
	var keys: Array = conditions.keys()
	keys.sort()
	for key in keys:
		if int(stats.get(String(key), 0)) < int(conditions[key]):
			pending.append(String(STAT_LABELS.get(String(key), String(key))))
	return pending
