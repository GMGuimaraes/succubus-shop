extends RefCounted
## Quadro de funcionários: gente fixa não é prêmio, é conta. Cada vaga tem taxa de
## contratação, **salário cobrado a cada virada de dia dentro da conta da casa** e
## uma única entrega, sempre dentro de uma fórmula que o jogo já tinha: a ronda
## barra furto, o aprendiz encurta a forja, a escrevente abate a dívida e a cozinha
## derruba a fúria. Ninguém fabrica número novo em painel novo — o salário entra na
## mesma conta que a Biblioteca e as filiais já engrossavam, então contratar é
## decisão com risco, não botão de melhoria.
##
## O jogo guarda só `staff_hired` (Array[String] com os ids no balcão). Toda tabela
## aqui é fixa; o efeito de cada vaga é derivado dela.

## Porta: `chapter` são capítulos fechados, `rep` é reputação no bairro, `standing`
## é fama da facção indicada, `rank` é o degrau da trilha nomeada, `affection` é o
## coração da chefe.
const DATA: Array[Dictionary] = [
	{
		"id": "ronda", "name": "Gerta Meio-Casco", "role": "Ronda de balcão",
		"hire": 260, "wage": 26, "chapter": 1, "faction": "submundo", "standing": 5,
		"bg": "Doze anos de escolta de caravana e um olho que mede a saída antes de a porta abrir. O beco conhece o passo dela e não testa.",
		"does": "Barra 40% dos furtos antes de a peça sair pela porta.",
		"block": 40,
	},
	{
		"id": "aprendiz", "name": "Tobe Bilro", "role": "Aprendiz de forja",
		"hire": 320, "wage": 30, "chapter": 2, "trail": "alchemy", "rank": 2,
		"bg": "Expulso de duas oficinas por perguntar demais ao mestre. Agora ele pergunta ao carvão, e o carvão responde mais rápido.",
		"does": "Encurta 20% de cada fabricação em curso — a fila de três vagas rende uma a mais por turno.",
		"craft": 0.8,
	},
	{
		"id": "escriba", "name": "Benedita Tinta", "role": "Escrevente do livro-caixa",
		"hire": 300, "wage": 24, "chapter": 2, "rep": 25,
		"bg": "Contou a receita de dois coletores de impostos aposentados. Sabe de cor o preço do vexame e odeia número redondo sem origem.",
		"does": "Na virada paga em dia, o caixa abate 18% da dívida em vez de 10%.",
		"dig": 0.18,
	},
	{
		"id": "cozinha", "name": "Morna Caldo", "role": "Cozinha do fundo",
		"hire": 240, "wage": 22, "chapter": 1, "affection": 30,
		"bg": "Fez sopa para três exércitos e nenhuma guerra. Diz que fúria de balcão é fome disfarçada de opinião.",
		"does": "Um ponto de fúria a menos a cada virada — e fúria custa 5% de etiqueta por ponto.",
		"calm": 1,
	},
]

static func size() -> int:
	return DATA.size()

static func find(id: String) -> Dictionary:
	for seat in DATA:
		if str(seat["id"]) == id:
			return seat
	return {}

static func knows(id: String) -> bool:
	return not find(id).is_empty()

## "" quer dizer que a vaga está aberta para conversa. Qualquer outra resposta é o
## motivo escrito, e é a mesma frase que o painel mostra antes de o botão apagar.
static func gate(seat: Dictionary, now: Dictionary) -> String:
	if int(now.get("chapter", 0)) < int(seat["chapter"]):
		return "fecha %d capítulo(s) antes" % (int(seat["chapter"]) - int(now.get("chapter", 0)))
	var faction_id := str(seat.get("faction", ""))
	if faction_id != "":
		var standing := int((now.get("standing", {}) as Dictionary).get(faction_id, 0))
		if standing < int(seat["standing"]):
			return "%s a %d de fama (a loja tem %d)" % [faction_id, int(seat["standing"]), standing]
	if seat.has("rep") and int(now.get("rep", 0)) < int(seat["rep"]):
		return "o bairro ainda não a conhece: %d de reputação (a loja tem %d)" % [int(seat["rep"]), int(now.get("rep", 0))]
	if seat.has("rank") and int((now.get("ranks", {}) as Dictionary).get(str(seat["trail"]), 0)) < int(seat["rank"]):
		return "a trilha %d chega ao degrau %d (está no %d)" % [
			str(seat["trail"]), int(seat["rank"]),
			int((now.get("ranks", {}) as Dictionary).get(str(seat["trail"]), 0))]
	if seat.has("affection") and int(now.get("affection", 0)) < int(seat["affection"]):
		return "a chefe tem %d de coração, e ela só aceita com %d" % [int(now.get("affection", 0)), int(seat["affection"])]
	return ""

## A folha salarial: quanto os do balcão somam na conta de cada virada.
static func total_wage(ids: Array) -> int:
	var sum := 0
	for id in ids:
		var seat := find(str(id))
		if not seat.is_empty():
			sum += int(seat["wage"])
	return sum

static func block_chance(ids: Array) -> int:
	return int(find("ronda")["block"]) if ids.has("ronda") else 0

static func craft_time_factor(ids: Array) -> float:
	return float(find("aprendiz")["craft"]) if ids.has("aprendiz") else 1.0

## Fração do caixa que escava a dívida na virada paga em dia.
static func debt_dig_share(ids: Array) -> float:
	return float(find("escriba")["dig"]) if ids.has("escriba") else 0.1

static func calm_per_turn(ids: Array) -> int:
	return int(find("cozinha")["calm"]) if ids.has("cozinha") else 0

## A folha escrita para o painel: quem está no balcão e quanto cobra por virada.
static func roster_line(ids: Array) -> String:
	var parts: Array[String] = []
	for id in ids:
		var seat := find(str(id))
		if not seat.is_empty():
			parts.append("%s %d" % [str(seat["name"]), int(seat["wage"])])
	return " • ".join(parts)
