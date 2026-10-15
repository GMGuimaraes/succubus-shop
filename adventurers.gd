extends RefCounted
## Batedores de estrada: quem desce do balcão para buscar a mercadoria. A loja já
## mandava um batedor anônimo — qualquer um, sem nome e sem memória — e a única
## resposta da viagem era a sorte geral da casa. Aqui entra gente com nome, que
## **sobe de nível pela estrada que pisou** e que cobra um preço por isso: taxa de
## contratação uma vez, cachê por viagem, e a peça que leva na mochila sai do
## estoque que o balcão venderia.
##
## Toda a fórmula mora nesta folha e é pura. O jogo guarda só duas coisas:
## `adventurers_hired` (Array[String] com os ids no cadastro) e `adventurer_xp`
## (Dictionary id → XP acumulado). Nível, habilidade, risco e botim derivam delas,
## então nenhuma viagem precisa de painel novo para ser medida.
##
## A habilidade entra no mesmo número que a sorte da casa já usava
## (`danger - sorte*4` para o contratempo, `chance + sorte*5` para o botim), só que
## congelada no momento em que o batedor parte: a viagem responde pelo que quem
## saiu de bota era capaz de fazer naquela hora, não pelo que a loja virou depois.

## XP acumulado necessário para cada nível. O degrau 5 é o teto da estrada: quem
## chega lá já não sobe, só cobra mais caro pelo que sabe.
const LEVEL_XP: Array[int] = [0, 3, 8, 15, 25]
const MAX_LEVEL := 5

## Quanto a peça na mochila empurra a sorte, por degrau de qualidade. Torto não
## ajuda ninguém; Lendário na mão de um batedor vale mais que qualquer reza.
const GEAR_LUCK: Array[int] = [0, 1, 1, 2, 2, 3]

## `route` é o destino que a pessoa conhece de cor (+1 de habilidade lá dentro),
## `gear` é a peça que ela exige levar, `fee` é o cachê por viagem. As portas de
## entrada (`day`, `trips`, `rep`, `rank`) são contas que a loja já mede sozinha.
const DATA: Array[Dictionary] = [
	{
		"id": "corva", "name": "Corva Sete-Dias", "role": "Batedora de beco",
		"hire": 90, "fee": 4, "base": 1, "route": "beco", "gear": "adaga_charme",
		"day": 2,
		"bg": "Passou sete dias no Beco dos Restos procurando um anel e voltou com os dois dentes do dono. Diz que o lixo de nobre cria afeto.",
		"does": "Conhece o Beco de cor e aceita a Adaga de Charme na mochila. Cobra pouco e ensina o ofício a quem a acompanha.",
	},
	{
		"id": "torvald", "name": "Torvald Meia-Paga", "role": "Estradeiro de lama",
		"hire": 180, "fee": 8, "base": 2, "route": "pantano", "gear": "martelo_faisca",
		"trips": 3,
		"bg": "Cobrou metade adiantado em três caravanas diferentes e nunca devolveu a outra metade. No Pântano ele anda onde a lama ainda não sabe o nome dele.",
		"does": "Furou o Pântano das Moedas Perdidas tantas vezes que a emboscada já o cumprimenta. Martelo na cintura, preço na boca.",
	},
	{
		"id": "bilesca", "name": "Bilesca Sem-Juro", "role": "Ladrão de catacumba",
		"hire": 320, "fee": 14, "base": 3, "route": "catacumba", "gear": "cristal_credito",
		"rank": 2,
		"bg": "Assinou três contratos postumamente e sobreviveu a todos. Diz que o guardião da Catacumba é um sócio antigo, não um inimigo.",
		"does": "Sabe quais túmulos têm juros e quais têm botim. Com o Cristal de Crédito Cósmico no bolso, os mortos aceitam parcelamento.",
	},
	{
		"id": "marola", "name": "Irmã Marola do Último Copo", "role": "Capelã de fenda",
		"hire": 520, "fee": 22, "base": 4, "route": "fenda", "gear": "pergaminho_procrastinacao",
		"rep": 40,
		"bg": "Serviu vinte anos numa ordem que acabou por inadimplência. Hoje ela batiza por fora, cobra por dentro, e desce na Fenda porque a fenda também deve a ela.",
		"does": "A única que voltou da Fenda do Abismo com as duas mãos e a bolsa. Pergaminho de Procrastinação na capa: o abismo espera, ela não.",
	},
	{
		"id": "nabo", "name": "Nabo Dois-Contratos", "role": "Faz-tudo de estrada",
		"hire": 240, "fee": 10, "base": 2, "route": "", "gear": "incenso_teleporte",
		"trips": 6,
		"bg": "Fez dois contratos simultâneos com facções que se odeiam e sobreviveu explicando a ambos que o outro começaria a briga. Nenhuma rota é dele, todas ele já andou.",
		"does": "Sem especialidade nenhuma e habilidade sobrando de tanto andar. Levá-lo é pagar mais caro por quem aceitou qualquer estrada.",
	},
]

static func size() -> int:
	return DATA.size()

static func find(id: String) -> Dictionary:
	for candidate in DATA:
		if str(candidate["id"]) == id:
			return candidate
	return {}

static func knows(id: String) -> bool:
	return not find(id).is_empty()

## "" quer dizer que a pessoa está livre para ser contratada. Qualquer outra
## resposta é o motivo escrito, na mesma ordem em que o painel a lê.
static func gate(candidate: Dictionary, now: Dictionary) -> String:
	if candidate.has("day") and int(now.get("day", 1)) < int(candidate["day"]):
		return "só desce do beco no dia %d (hoje é %d)" % [int(candidate["day"]), int(now.get("day", 1))]
	if candidate.has("trips") and int(now.get("trips", 0)) < int(candidate["trips"]):
		return "anda com quem já voltou %d vez(es) da estrada (a casa tem %d)" % [
			int(candidate["trips"]), int(now.get("trips", 0))]
	if candidate.has("rep") and int(now.get("rep", 0)) < int(candidate["rep"]):
		return "precisa de %d de reputação no bairro (a loja tem %d)" % [
			int(candidate["rep"]), int(now.get("rep", 0))]
	if candidate.has("rank") and int(now.get("rank", 0)) < int(candidate["rank"]):
		return "não viaja com logística no degrau %d (está no %d)" % [
			int(candidate["rank"]), int(now.get("rank", 0))]
	return ""

## Nível do caderno: quantos degraus de XP a pessoa já pisou.
static func level_of(xp: int) -> int:
	var level := 1
	for i in range(1, LEVEL_XP.size()):
		if xp >= LEVEL_XP[i]:
			level = i + 1
	return level

## XP que falta para o próximo nível, ou 0 no teto da estrada.
static func xp_to_next(xp: int) -> int:
	var level := level_of(xp)
	if level >= MAX_LEVEL:
		return 0
	return LEVEL_XP[level] - xp

static func max_level() -> int:
	return MAX_LEVEL

## O empurrão da peça na mochila. -1 quer dizer mochila vazia.
static func gear_luck(tier: int) -> int:
	if tier < 0 or tier >= GEAR_LUCK.size():
		return 0
	return GEAR_LUCK[tier]

## Habilidade que a pessoa leva para a estrada: o ofício próprio, os níveis que a
## estrada já lhe deu, o conhecimento do destino e a peça que ela carrega.
static func skill_of(candidate: Dictionary, xp: int, route_id: String, gear_tier: int) -> int:
	var level := level_of(xp)
	var specialty := 1 if str(candidate.get("route", "")) == route_id and route_id != "" else 0
	return int(candidate["base"]) + (level - 1) + specialty + gear_luck(gear_tier)

## Aulas da viagem: estrada perigosa ensina mais, e voltar intacto ensina uma coisa
## a mais que mala perdida. É o único jeito de subir de nível — não se compra degrau
## com ouro.
static func mission_xp(destination: Dictionary, clean_return: bool, loot_pieces: int) -> int:
	var danger := float(destination.get("danger", 0))
	var gained := 1 + int(round(danger / 12.0)) + mini(2, loot_pieces)
	return gained + (1 if clean_return else 0)

## Cachê da viagem: o preço da tabela mais um ouro por degrau que a estrada já deu.
## Batedor bom cobra mais caro, e é assim que o nível pesa na conta em vez de pesar
## só no dado.
static func fee_for(candidate: Dictionary, xp: int = 0) -> int:
	return int(candidate["fee"]) + (level_of(xp) - 1)

## A linha do caderno: quem é, até onde a estrada a trouxe e quanto ela cobra.
static func level_line(xp: int) -> String:
	var level := level_of(xp)
	if level >= MAX_LEVEL:
		return "Nv.%d • teto da estrada" % level
	return "Nv.%d • %d XP para o Nv.%d" % [level, xp_to_next(xp), level + 1]

## Cadastro escrito para o painel: nome, nível e cachê de quem está no livro.
static func roster_line(ids: Array, xp: Dictionary) -> String:
	var parts: Array[String] = []
	for id in ids:
		var candidate := find(str(id))
		if candidate.is_empty():
			continue
		parts.append("%s %s (Nv.%d, %d/viagem)" % [
			str(candidate["name"]), str(candidate["role"]),
			level_of(int(xp.get(str(id), 0))), fee_for(candidate, int(xp.get(str(id), 0)))])
	return " • ".join(parts)
