extends RefCounted
## Especializações de fim de trilha. Cada uma das cinco trilhas de talento tem
## dois ofícios que se puxam para lados opostos da mesma conta, e a casa só pode
## assinar **um** deles por vida. É aqui que o ponto de talento vira decisão: até
## o nível 4 a trilha é só subida, no nível 4 ela escolhe que tipo de loja a loja
## vai ser, e sem essa escolha o quinto degrau fica trancado na estante.
##
## Nada dos efeitos inventa fórmula nova: cada ofício entra numa conta que o jogo
## já fazia — sorte da forja, custo de fabricar, etiqueta, o quanto uma venda
## empurra o mercado, afeição por venda, a chance de salvar uma visita, a duração
## da estrada, o preço da matéria-prima, a conta da casa e o zelo com as filiais.
##
## A escolha é da vida, não da família: reencarnar ou reabrir depois da ruína
## apaga o ofício assinado, porque a vida seguinte é justamente a chance de
## montar a outra build com o que aprendeu.

const DATA := {
	"alchemy": [
		{
			"id": "destilaria",
			"name": "Destilaria fina",
			"desc": "+1 de sorte na forja: a peça sai melhor, não mais barata.",
			"line": "Ela fecha a porta do depósito e deixa a bigorna acesa a noite inteira: “A partir de hoje o que sai daqui é fino. Barato é o que o concorrente vende.”",
		},
		{
			"id": "linha",
			"name": "Linha de montagem",
			"desc": "Fabricar peça custa 12% menos, em cima do que a Alquimia já derrubou.",
			"line": "Ela risca o quadro de tarefas em três colunas e põe o diabrete na primeira: “Beleza é caro. A gente vende volume e dorme igual.”",
		},
	],
	"trade": [
		{
			"id": "cartel",
			"name": "Cartel de etiqueta",
			"desc": "+8% em toda etiqueta da loja, para sempre.",
			"line": "Ela troca todos os cartões da prateleira numa manhã: “Preço baixo foi a mentira que contaram sobre nós. Agora é a verdade que eles repetem.”",
		},
		{
			"id": "varejo",
			"name": "Varejo humilde",
			"desc": "Cada venda empurra o mercado pela metade: o preço da sua própria peça não sobe tão rápido.",
			"line": "Ela vende duas caixas a menos do que podia: “Deixa o freguês sair achando justo. Amanhã ele volta com a prima.”",
		},
	],
	"charm": [
		{
			"id": "coracao",
			"name": "Coração cheio",
			"desc": "+1 de afeição em cada venda, e afeição que não cabe vira reputação.",
			"line": "Ela decorou o nome de todo mundo antes do balcão: “Cliente que se lembra pelo nome não pede desconto. Pede para voltar.”",
		},
		{
			"id": "boca",
			"name": "Boca de ouro",
			"desc": "+15 pontos percentuais na chance de salvar a visita com a prateleira vazia.",
			"line": "Ela treinou o sorriso no espelho do fundo da loja: “Estoque é uma coisa. Freguês indo embora é outra, e essa eu não deixo acontecer.”",
		},
	],
	"logistics": [
		{
			"id": "estrada",
			"name": "Estrada curta",
			"desc": "Expedições voltam 15% mais rápido, com piso de dez segundos de mundo.",
			"line": "Ela compra o mapa velho do carregador bêbado: “Não é pressa. É que eu já sei onde a estrada encurta.”",
		},
		{
			"id": "volume",
			"name": "Compra em volume",
			"desc": "Matéria-prima sai 10% mais barata, em cima do desconto da Logística.",
			"line": "Ela fecha a compra do mês inteiro num papel só: “Volume é a única palavra que o fornecedor aprende depressa.”",
		},
	],
	"house": [
		{
			"id": "livro",
			"name": "Livro-caixa",
			"desc": "A conta diária da casa cai mais 10% sobre o que a Administração já cortou.",
			"line": "Ela relápis cada contrato velho e risca o que ninguém lembrava de assinar: “A loja não está quebrada. Está mal contada.”",
		},
		{
			"id": "porteiro",
			"name": "Porteiro atento",
			"desc": "+2 de zelo nas filiais, somado ao que a Casa e o beco já cuidam.",
			"line": "Ela põe alguém de olho em cada porta da loja: “Dia ruim acontece. O que não acontece mais é dia ruim sem testemunha.”",
		},
	],
}

## Em que nível a trilha ganha direito de escolher ofício. O quinto degrau só abre
## para quem já assinou um dos dois.
const CHOICE_RANK := 4

## As cinco trilhas na ordem do painel, com o nome que a loja usa em voz alta.
const TRAILS := {
	"alchemy": "Alquimia",
	"trade": "Comércio",
	"charm": "Carisma",
	"logistics": "Logística",
	"house": "Administração da Casa",
}

static func trail_ids() -> Array:
	return TRAILS.keys()

static func pair(kind: String) -> Array:
	return DATA.get(kind, [])

static func find(spec_id: String) -> Dictionary:
	for kind in DATA.keys():
		for spec in DATA[kind]:
			if str(spec["id"]) == spec_id:
				return spec
	return {}

static func has(kind: String, spec_id: String) -> bool:
	for spec in pair(kind):
		if str(spec["id"]) == spec_id:
			return true
	return false

static func names(kind: String) -> String:
	var parts: Array[String] = []
	for spec in pair(kind):
		parts.append(str(spec["name"]))
	return " ou ".join(parts)

static func count() -> int:
	return DATA.size()
