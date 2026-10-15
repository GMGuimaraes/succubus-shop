extends RefCounted
## Finais alternados: o sétimo capítulo fecha do jeito da gente que a loja mais
## serviu. A estrutura da tela é a mesma — o que muda é quem senta no balcão na
## manhã seguinte, quem paga a festa e quem passa a dar as ordens no bairro.
##
## O jogo guarda só `endings_seen` (ids já vistos). A escolha é sempre derivada da
## reputação de facção, então o mesmo save reabre com o mesmo final.
##
## Quem chama `for_standing()` é o `main.gd`, e com a conta da vida atual — a fama
## acumulada entre reencarnações manda no preço, não no desfecho.
##
## A ruína mora nesta tabela por um motivo: ela é um final, não um game over com
## tela própria. Ela nunca sai do sorteio de reputação — só o `main.gd` a reclama,
## no dia em que a dívida da casa passa do teto.

const Factions := preload("res://factions.gd")

## O final sem dono: cinco facções empatadas no mesmo ponto ninguém pesou mais
## que a loja, e a loja fecha com as próprias pernas.
const HOUSE := "casa"
## O final que a reputação não escolhe: o caixa que não fechou.
const RUIN := "ruina"

const ENDINGS: Array[Dictionary] = [
	{
		"id": "casa", "faction": "", "title": "Império do Balcão",
		"lines": [
			"Nenhuma casa pesou mais que as outras. A loja fecha o capítulo sete devendo favor a todo mundo e obediência a ninguém — o balcão é da chefe, e só.",
			"Na manhã seguinte a fila dobra a esquina, cada facção manda um puxa-saco com a mesma proposta, e as cinco cartas ficam no caixa até a chefe decidir qual delas rasgar primeiro.",
		],
	},
	{
		"id": "guildas", "faction": "guildas", "title": "Selo de Ouro da Guilda",
		"lines": [
			"Foi a guilda que segurou a casa quando o bairro ainda desconfiava. No dia do último capítulo, o selo deles vai na porta — e a porta agora é grande demais para uma loja de esquina.",
			"Mestre da guilda é título que se paga em brinde: a chefe entra em toda oficina do reino sem bater, e toda oficina do reino manda primeiro pedido para cá. O preço da cortesias chega em cota anual, e ela chega pontual.",
			"O balcão continua aberto. Só que agora atende em nome de uma casa muito maior.",
		],
	},
	{
		"id": "nobres", "faction": "nobres", "title": "Casa Aclamada pela Coroa",
		"lines": [
			"A corte venceu porque a corte paga adiantado. No último capítulo chega o pergaminho: a loja é oficialmente fornecedora da casa real, e o selo vem com um laço que custa mais que a reforma inteira.",
			"Moda é o imposto mais caro do reino, e a loja agora cobra ele. Nobre que entra sem convite espera na fila como qualquer um — e comenta que adorou.",
			"O que a coroa não perdoa é esquecimento. Enquanto a casa lembrar de quem a vestiu, o balcão não fecha.",
		],
	},
	{
		"id": "aventureiros", "faction": "aventureiros", "title": "Torre dos Que Voltam",
		"lines": [
			"Quem compra de quem volta da masmorra aprende uma coisa: estoque é questão de vida. A tropa fez da loja o ponto de encontro do reino, e o quadro de contratos na parede vale mais que qualquer anúncio.",
			"Eles pagam pouco, atrasam muito e voltam sempre. Foi o bastante. No último capítulo a loja tem mais herói cadastrado que cliente comum.",
			"A torre que dá nome ao final é a do fundo do salão: ninguém mais sobe a escada sem descer com três poções e uma história que ninguém pediu.",
		],
	},
	{
		"id": "mercadores", "faction": "mercadores", "title": "Balcão que Virou Feira",
		"lines": [
			"Mercador não tem gratidão, tem tabela. E na tabela do último capítulo a loja é o nome que todo mundo copia — o que significa que a loja é quem define o preço da rua inteira.",
			"A feira do bairro virou extensão do caixa. Cada concorrente que abre do outro lado da esquina já nasce pagando royalties em forma de favor.",
			"O submundo reclama, a guilda negocia, a coroa finge que não vê. Mercado é assim: quem dita o preço não precisa de exército.",
		],
	},
	{
		"id": "submundo", "faction": "submundo", "title": "A Casa do Coletor",
		"lines": [
			"Foi o submundo que cobrou menos e protegeu mais. No último capítulo a loja não tem alvará novo: tem um nome na lista de quem não se mexe.",
			"Cliente bom não faz pergunta e não sai sem levar. A freguesia dobrou sem que ninguém fizesse propaganda — propaganda, aqui, é o que os outros fazem para não vir parar aqui.",
			"A chefe jura que continua independente. Todo mundo finge que acredita, inclusive a chefe. O balcão, esse, continua abrindo na hora de sempre.",
		],
	},
	{
		"id": "ruina", "faction": "", "title": "As Portas Que Não Abrem Mais",
		"lines": [
			"A casa não caiu num dia. Caiu em vinte cobranças pequenas, cada uma paga com a promessa de que amanhã o balcão vende mais. No dia em que a dívida estourou, o coletor não pediu a chave — pediu o salão, e levou o salão.",
			"O que sobra é inventário e favor. A guilda anota a queda nos estatutos, a coroa manda um pêsame em pergaminho caro, o submundo manda dizer que ainda lembra de quem abriu com ela. Ninguém empresta ouro para loja fechada, e mesmo assim todo mundo passa na calçada para ver se tem prateleira sobrando.",
			"A chefe fica com as mãos no balcão, que ainda é dela por baixo da dívida. Loja não quebra contrato de conteúdo: as pessoas continuam lembrando de quem as atendeu, o álbum continua na parede, e a porta reabre. O que não reabre é o cofre — quem fecha no vermelho recomeça com o que aprendeu, e aprendizado não enche caixa.",
		],
	},
]

static func size() -> int:
	return ENDINGS.size()

static func find(id: String) -> Dictionary:
	for candidate in ENDINGS:
		if str(candidate["id"]) == id:
			return candidate
	return {}

static func house() -> Dictionary:
	return find(HOUSE)

## O desfecho de ruína não sai da conta de reputação: quem o chama é o `main.gd`,
## e só no dia em que a dívida da casa passa do teto.
static func ruin() -> Dictionary:
	return find(RUIN)

static func text(ending: Dictionary) -> String:
	return "\n\n".join(PackedStringArray(ending.get("lines", [])))

## O final do império é da facção que sozinho passou as outras. Empate, ou
## ninguém servido, é o final da própria casa.
static func for_standing(standing: Dictionary) -> Dictionary:
	var best_id := HOUSE
	var best := 0
	var tied := false
	for faction in Factions.DATA:
		var value := int(standing.get(str(faction["id"]), 0))
		if value > best:
			best = value
			best_id = str(faction["id"])
			tied = false
		elif value == best and value > 0:
			tied = true
	if tied or best <= 0:
		return house()
	return find(best_id)
