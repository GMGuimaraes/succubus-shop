extends RefCounted
## Filiais: a loja cresce para fora do salão. Cada filial é um investimento de uma
## vez, que paga um lucro por virada de dia e também engrossa a conta da casa — é
## isso que torna expansão uma decisão e não um botão de dinheiro infinito. A
## filial mais rentável é também a mais instável: em dia ruim ela não vende, quebra
## o próprio balcão e cobra o conserto.
##
## O jogo guarda só `branches` (Array[String] com os ids abertos). Toda tabela aqui
## é fixa, e o lucro esperado de cada filial deriva dela.

## "chapter" são capítulos já fechados; "standing" é fama de facção no patamar
## pedido (5 = Notada, 15 = Respeitada, 30 = Lenda). "tilt" é a chance do dia ruim.
const DATA: Array[Dictionary] = [
	{
		"id": "feira", "name": "Balcão da Feira", "cost": 400, "chapter": 1,
		"faction": "", "standing": 0, "profit": 20, "upkeep": 6, "tilt": 0.15,
		"desc": "Uma mesa emprestada no ponto mais movimentado do bairro.",
		"open": "A loja agora tem mesa na feira. O feirante do lado já reclama do barulho e já pediu emprego.",
		"good": "Na feira o balcão não para: a fila dobra a esquina e ninguém pergunta preço de nada.",
		"bad": "Um temporal levantou a lona do Balcão da Feira. Vendeu nada e ainda cobrou o conserto da armação.",
	},
	{
		"id": "oficina", "name": "Oficina das Guildas", "cost": 1500, "chapter": 3,
		"faction": "guildas", "standing": 15, "profit": 70, "upkeep": 18, "tilt": 0.20,
		"desc": "Bancada própria dentro do pátio da guilda, com contrato de fornecimento.",
		"open": "A guilda abriu portão e bancada. Agora a loja fabrica onde o cliente já está esperando.",
		"good": "A oficina entregou o lote do dia antes do prazo. O mestre da guilda fingiu que isso é normal.",
		"bad": "Um aprendiz derrubou o forno da Oficina das Guildas. A guilda não perdoa atraso, e o desconto veio na hora.",
	},
	{
		"id": "cais", "name": "Depósito do Cais", "cost": 2600, "chapter": 4,
		"faction": "mercadores", "standing": 15, "profit": 120, "upkeep": 28, "tilt": 0.25,
		"desc": "Galpão úmido onde a mercadoria chega antes de o cliente saber que quer.",
		"open": "O cais tem chave nova e o nome da loja na tábua. Quem desembarca já sabe onde gastar.",
		"good": "O navio adiantou a carga. O Depósito do Cais vendeu o que ainda não tinha chegado.",
		"bad": "Subiu maré no Depósito do Cais. Caixa molhada é caixa perdida, e o segurador mandou dizer que não.",
	},
	{
		"id": "corte", "name": "Vitrine da Corte", "cost": 4200, "chapter": 5,
		"faction": "nobres", "standing": 15, "profit": 190, "upkeep": 42, "tilt": 0.30,
		"desc": "Vidro, ouro e um atendente treinado para não olhar ninguém nos olhos.",
		"open": "A corte autorizou a vitrine. O preço dobrou de uma hora para outra e ninguém ousou pechinchar.",
		"good": "Uma dama da corte levou a peça sem perguntar o preço. A Vitrine da Corte existe por causa disso.",
		"bad": "Um lacaio achou o brilho dele inferior ao da concubina. A Vitrine da Corte pagou a reconciliação.",
	},
	{
		"id": "beco", "name": "Anexo do Beco", "cost": 6000, "chapter": 6,
		"faction": "submundo", "standing": 30, "profit": 320, "upkeep": 60, "tilt": 0.45,
		"desc": "Porta sem placa no beco atrás da loja. Entra quem sabe a hora.",
		"open": "O beco abriu a porta sem placa. Ninguém anota o que sai dali, e é exatamente por isso que rende.",
		"good": "O Anexo do Beco esvaziou o estoque em uma noite. Ninguém pediu nota, ninguém pediu desconto.",
		"bad": "Ronda no beco. O Anexo fechou as portas na hora certa, mas o balcão de trás não foi tão rápido.",
	},
]

## O dia ruim não é só falta de venda: a filial paga o estrago. O número é o
## tamanho do rombo como fração do lucro que ela deixaria de dar.
const DAMAGE_SHARE := 0.3

static func size() -> int:
	return DATA.size()

static func find(id: String) -> Dictionary:
	for branch in DATA:
		if str(branch["id"]) == id:
			return branch
	return {}

static func knows(id: String) -> bool:
	return not find(id).is_empty()

## "" quer dizer que a filial está aberta para negócio. Qualquer outra resposta é
## o motivo escrito para o botão, e é a mesma frase que o painel mostra.
static func gate(branch: Dictionary, campaign_step: int, faction_standing: Dictionary) -> String:
	if int(campaign_step) < int(branch["chapter"]):
		return "fecha %d capítulo(s) antes" % (int(branch["chapter"]) - campaign_step)
	var faction_id := str(branch["faction"])
	if faction_id != "" and int(faction_standing.get(faction_id, 0)) < int(branch["standing"]):
		return "%s a %d de fama (tem %d)" % [
			faction_id, int(branch["standing"]), int(faction_standing.get(faction_id, 0))]
	return ""

static func total_upkeep(ids: Array) -> int:
	var sum := 0
	for id in ids:
		var branch := find(str(id))
		if not branch.is_empty():
			sum += int(branch["upkeep"])
	return sum

## Lucro cheio da carteira, sem sorteio: é o número que o painel promete antes de
## a rolagem acontecer.
static func total_profit(ids: Array) -> int:
	var sum := 0
	for id in ids:
		var branch := find(str(id))
		if not branch.is_empty():
			sum += int(branch["profit"])
	return sum

## Expectativa de lucro por dia, já descontado o dia ruim. É o número honesto para
## o painel: a filial boa não é a que mais paga, é a que mais paga em média.
static func expected_for(branch: Dictionary) -> int:
	return int(round(float(branch["profit"]) * (1.0 - float(branch["tilt"]) * (1.0 + DAMAGE_SHARE))))

static func expected_profit(ids: Array) -> int:
	var sum := 0
	for id in ids:
		var branch := find(str(id))
		if not branch.is_empty():
			sum += expected_for(branch)
	return sum

## O dia de uma filial: ou paga o lucro, ou não paga e ainda cobra o conserto.
static func roll(branch: Dictionary, luck: int = 0) -> int:
	if branch.is_empty():
		return 0
	var profit := int(branch["profit"])
	## Sorte empurra a régua para baixo: cada ponto de sorte derruba 4% da chance
	## de dia ruim, com piso de 2% para nenhuma filial virar garantia.
	var tilt := maxf(0.02, float(branch["tilt"]) - float(luck) * 0.04)
	if randf() < tilt:
		return -int(round(profit * DAMAGE_SHARE))
	return profit

## A linha do dia, escrita com o nome das filiais que trabalharam.
static func ledger(ids: Array, results: Array[int]) -> String:
	var parts: Array[String] = []
	for i in range(ids.size()):
		var branch := find(str(ids[i]))
		if branch.is_empty():
			continue
		parts.append("%s %+d" % [str(branch["name"]), results[i]])
	return " • ".join(parts)
