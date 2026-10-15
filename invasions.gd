extends RefCounted
## A rua bate na porta. Loja que dá lucro tem alvo na porta, e aqui o alvo vem
## buscar o que a casa mostra: o caixa, a prateleira e a fama. Cada visita dessas é
## resolvida com a defesa que a loja já tem — a ronda da folha, os servos que dormem
## no salão, os batedores que voltaram da estrada e sabem fechar uma porta, o
## santuário reformado e a Administração da Casa. Nada de número paralelo: a chance
## de segurar a porta é a mesma régua de sorte que o jogo já rolava, e a conta de
## quem arromba cai em ouro, barro, fúria, reputação e peça que sai do estoque.
##
## Junto mora o vigário: ele não abençoa de graça nem condena de graça. Dízimo pago é
## porta menos visada, suborno é porta invisível por um tempo, e a recusa é a única
## resposta que sobe a reputação no dia e a chance de visita no mês. O jogo guarda só
## a postura (`tithe_stance`), o dia até onde ela vale (`tithe_until`), quantos
## carimbos de porta segurada a casa tem (`invasions_repelled`) e quais privilégios
## de defesa ela já ganhou (`defense_privileges`). Poder, chance e preço derivam.

## As visitas, na ordem em que a rua as manda. `day` é o primeiro dia em que a
## visita é possível, `power` é a defesa que empata com ela, `share` é a fração do
## caixa que vai no saco, `mess` é o barro que deixam no salão, `rep` é o que o
## bairro comenta depois, `pieces` é quantas peças somem da prateleira e `leader` é o
## nome que a ronda pode segurar pelo colarinho — e mandar para a cela do santuário.
const DATA: Array[Dictionary] = [
	{
		"id": "farrapeiros", "name": "Farrapeiros da Ponte Quebrada",
		"leader": "Tico Bala-Um",
		"day": 6, "power": 22, "share": 0.05, "mess": 14, "rep": 1, "pieces": 0,
		"bg": "Seis com sacos, nenhum com plano. Passaram pela ponte porque a ponte era o caminho e a loja estava acesa.",
		"quote": "\"Só estamos de passagem\", dizem cinco pares de bota que param exatamente na frente da porta.",
	},
	{
		"id": "cobranca", "name": "Cobrança sem Assinatura",
		"leader": "Doutor Sem-Assinatura",
		"day": 11, "power": 34, "share": 0.07, "mess": 18, "rep": 1, "pieces": 1,
		"bg": "Trazem um recibo em branco, preenchem na hora e chamam isso de contrato antigo. Ninguém nunca viu quem assinou.",
		"quote": "\"Fechou com a gente em outra vida\", diz o magro, batendo no balcão com a unha. É sempre outra vida.",
	},
	{
		"id": "comitiva", "name": "Comitiva do Halfling Faminto",
		"leader": "Nico Pé-Rápido",
		"day": 16, "power": 46, "share": 0.09, "mess": 22, "rep": 2, "pieces": 1,
		"bg": "Cinche na porta: um anão sem paciência para fila, um magro que só fala em \"minha vez\" e alguém que já entrou pela janela antes do resto.",
		"quote": "\"Deixa eu rolar a porta\", pede o do meio, e antes da resposta a porta já rolou sozinha.",
	},
	{
		"id": "anel", "name": "Bando do Anel Velho",
		"leader": "Senhor Vaz Presente",
		"day": 21, "power": 60, "share": 0.11, "mess": 26, "rep": 2, "pieces": 2,
		"bg": "Querem emprestar de volta uma coisa que alguém deixou guardada aqui há três eras. A casa não sabe o que é, eles fingem saber.",
		"quote": "\"Um anel, pequeno, dourado, você deve ter\". O balcão tem nove caixas de anéis e a conversa não anda.",
	},
	{
		"id": "pretorianos", "name": "Guarda Pretoriana do Consórcio",
		"leader": "Centurião Décio Fatura",
		"day": 27, "power": 76, "share": 0.13, "mess": 30, "rep": 3, "pieces": 2,
		"bg": "Vêm em formação, com contrato de três páginas e o carimbo do Consórcio no brasão. Cobram o que a cidade inteira deve.",
		"quote": "Pedem licença três vezes. Na quarta já estão dentro, e o relatório deles diz que a casa resistiu.",
	},
	{
		"id": "tavola", "name": "Cavaleiros da Távola do Fim",
		"leader": "Sir Três-Perguntas",
		"day": 34, "power": 94, "share": 0.15, "mess": 34, "rep": 3, "pieces": 3,
		"bg": "Três perguntas na porta, todas sem resposta possível, e uma espada que só sabe a terceira alternativa. É a velha história do rei Arthur com fome.",
		"quote": "\"Quantas luas cabem numa moeda?\" Se a resposta não for a que eles querem, o balcão vira trincheira.",
	},
	{
		"id": "coisa", "name": "Aquela Coisa do Pântano",
		"leader": "O Guia de Botas Molhadas",
		"day": 42, "power": 112, "share": 0.17, "mess": 38, "rep": 4, "pieces": 3,
		"bg": "Não tem plano, não tem bando, não tem nome que caiba na placa. Tem fome e um guia que jura que a loja cheira bem daqui.",
		"quote": "O guia abre a porta e diz \"aqui é o lugar\". Ninguém pergunta mais o que ele quis dizer com isso.",
	},
]

## Quanto cada mão na casa vale em defesa. A ronda entra com a porcentagem da própria
## tabela de funcionários (é a mesma que barra furto), porque segurar braço na porta é
## a mesma arte de segurar braço no balcão.
const DEF_SERVANT := 6
const DEF_ADVENTURER := 7
const DEF_SANCTUM := 4
const DEF_RANK := 3

## A visita aparece quando a casa tem o que levar. Base mais o placar (a régua que o
## painel já mostra), mais o que o vigário cobra de quem o dispensou, menos o escudo
## da postura atual e o sino da campanha.
const INVASION_BASE_CHANCE := 4
const INVASION_SCORE_STEP := 900
const INVASION_SCORE_CAP := 8
## Porcentagem que cada postura arranca da chance: dízimo em dia é aviso de que a
## casa paga a conta da rua; suborno é a rua perdendo o endereço por um tempo.
const INVASION_TITHE_SHIELD := 4
const INVASION_BRIBE_SHIELD := 9
## Recusa não é de graça: cada "não" dito na cara do vigário sobe a visita seguinte.
const INVASION_REFUSAL_STING := 3

## O chão da repulsa: com defesa igual à da visita, a casa segura a porta em 55%.
const REPEL_BASE := 55
const REPEL_FLOOR := 5
const REPEL_CEILING := 95

## Os três degraus da campanha de defesa, na ordem em que a casa os ganha. Cada um é
## uma entrega dentro das fórmulas desta folha, não um número novo em painel novo.
const PRIVILEGES: Array[Dictionary] = [
	{"id": "dobradica", "need": 3, "name": "Porta com dobradiça nova",
	"does": "+10 de defesa permanente: a porta aguenta o ombro de quem chega sem convite."},
	{"id": "sino", "need": 6, "name": "Sino de alarma no caixilho",
	"does": "-4% de chance de visita: o beco ouve o sino antes de encostar na maçaneta."},
	{"id": "milicia", "need": 10, "name": "Milícia do beco",
	"does": "Porta segurada vira lucro: a rua devolve metade do que veio buscar e o bairro sobe 2 em vez de 1."},
]

## O vigário: quem cobra, quando chega a primeira vez e por quantos dias cada
## resposta segura a rua. O suborno é o único que some do endereço — e é o único que
## o Submundo aplaude.
const VICAR_NAME := "Vigário Bento Sete-Selos"
const VICAR_FIRST_DAY := 9
const TITHE_WEEK := 7
const BRIBE_DAYS := 24
const BRIBE_MULTIPLIER := 6
const REFUSAL_RETRY := 5

static func vicar_name() -> String:
	return VICAR_NAME

static func first_visit_day() -> int:
	return VICAR_FIRST_DAY

## O save só aceita privilégio que está na tabela: nome raspado não pode entrar na
## casa e nem o "sino" de alguém que inventou degrau.
static func knows_privilege(id: String) -> bool:
	for privilege in PRIVILEGES:
		if str(privilege["id"]) == id:
			return true
	return false

## A visita da vez: sempre a mais recente que o calendário da loja já permite, e a
## cada três portas seguradas a rua manda a seguinte mais forte. Repelir demais não é
## vitória barata — é currículo.
static func wave_for(day: int, repelled: int) -> Dictionary:
	var unlocked := 0
	for wave in DATA:
		if day >= int(wave["day"]):
			unlocked += 1
	if unlocked == 0:
		return {}
	var wave: Dictionary = DATA[unlocked - 1]
	var scaled: Dictionary = wave.duplicate(true)
	scaled["power"] = int(wave["power"]) + escalation(repelled)
	return scaled

## O carimbo da campanha na força da visita: dez de poder por degrau de três portas.
static func escalation(repelled: int) -> int:
	return int(repelled / 3.0) * 10

## A defesa escrita linha a linha, na ordem em que o painel a lê. Recebe os números
## crus que a casa já tem: a porcentagem da ronda, quantos servos dormem no salão,
## quantos batedores estão no cadastro, o degrau da reforma do santuário, o degrau da
## Administração e quais privilégios a campanha já pagou.
static func defense_lines(now: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var ronda := int(now.get("ronda", 0))
	if ronda > 0:
		lines.append({"name": "Ronda do balcão", "value": ronda})
	var servants := int(now.get("servants", 0))
	if servants > 0:
		lines.append({"name": "Servos da casa (%d)" % servants, "value": servants * DEF_SERVANT})
	var scouts := int(now.get("adventurers", 0))
	if scouts > 0:
		lines.append({"name": "Batedores no cadastro (%d)" % scouts, "value": scouts * DEF_ADVENTURER})
	var sanctum := int(now.get("sanctum", 0))
	if sanctum > 0:
		lines.append({"name": "Santuário reformado (%d)" % sanctum, "value": sanctum * DEF_SANCTUM})
	var rank := int(now.get("rank", 0))
	if rank > 0:
		lines.append({"name": "Administração da Casa (%d)" % rank, "value": rank * DEF_RANK})
	for line in privilege_lines(now):
		lines.append(line)
	return lines

## O que a campanha já deu, em linhas de painel. Só entram as que somam defesa: sino
## e milícia agem na chance e no resultado, não no número da porta.
static func privilege_lines(now: Dictionary) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var owned = now.get("privileges", [])
	for privilege in PRIVILEGES:
		var power := privilege_power(str(privilege["id"]))
		if power > 0 and owned.has(str(privilege["id"])):
			lines.append({"name": str(privilege["name"]), "value": power})
	return lines

static func privilege_power(id: String) -> int:
	return 10 if id == "dobradica" else 0

## O escudo que os privilégios dão na chance de visita, e o que eles fazem no resultado.
static func privilege_shield(now: Dictionary) -> int:
	var owned = now.get("privileges", [])
	return 4 if owned.has("sino") else 0

static func has_militia(now: Dictionary) -> bool:
	return (now.get("privileges", []) as Array).has("milicia")

static func defense_power(now: Dictionary) -> int:
	var sum := 0
	for line in defense_lines(now):
		sum += int(line["value"])
	return sum

## Chance de segurar a porta: a defesa da casa contra o poder da visita. Empate é 55%,
## e nenhum lado leva tudo — a rua sempre consegue empurrar alguém se repetir.
static func repel_chance(now: Dictionary, wave: Dictionary) -> int:
	return clampi(REPEL_BASE + defense_power(now) - int(wave["power"]), REPEL_FLOOR, REPEL_CEILING)

## Chance de a visita aparecer numa virada: a casa rica é alvo, a casa em dia com o
## vigário é alvo menos visado, e a casa que o dispensou colhe o que disse.
static func invasion_chance(score: int, stance: String, until_day: int, today: int,
		refusals: int, now: Dictionary) -> int:
	var chance := INVASION_BASE_CHANCE + mini(INVASION_SCORE_CAP, int(round(float(score) / float(INVASION_SCORE_STEP))))
	if stance == "pago" and today <= until_day:
		chance -= INVASION_TITHE_SHIELD
	elif stance == "subornado" and today <= until_day:
		chance -= INVASION_BRIBE_SHIELD
	chance += refusals * INVASION_REFUSAL_STING
	chance -= privilege_shield(now)
	return clampi(chance, 0, 35)

## O saco: fração do caixa que cabe na mão de quem entra. Nunca leva a loja inteira —
## invasão é despesa dolorida, não botão de game over.
static func plunder_for(wave: Dictionary, gold: int) -> int:
	return int(round(float(gold) * float(wave["share"])))

## A devolução da milícia: metade do que a visita veio buscar volta para o balcão.
static func militia_reclaim(wave: Dictionary, gold: int) -> int:
	return int(round(plunder_for(wave, gold) / 2.0))

## O dízimo da vez: cresce com o calendário e com a fama, porque a igreja cobra de
## quem o bairro já conhece.
static func tithe_for(day: int, reputation: int) -> int:
	return 20 + day * 4 + reputation

## O preço de apagar o endereço da lista: seis dízimos de uma vez e a rua esquece a
## porta pelo dobro do tempo de uma semana de dízimo.
static func bribe_for(day: int, reputation: int) -> int:
	return tithe_for(day, reputation) * BRIBE_MULTIPLIER

## A linha da postura atual, para o painel não ter de inventar prosa.
static func stance_line(stance: String, until_day: int, today: int) -> String:
	if stance.is_empty():
		return "sem resposta dada"
	if today > until_day:
		return "%s venceu no dia %d (a rua já esqueceu o acordo)" % [stance, until_day]
	var left := until_day - today + 1
	match stance:
		"pago":
			return "dízimo em dia (%d dia(s) de escudo)" % left
		"subornado":
			return "endereço apagado (%d dia(s) sem visita)" % left
		"recusado":
			return "porta na cara dele (%d dia(s) de cobraça marcada)" % left
	return stance

## O degrau da campanha que os carimbos de porta seguradas acabam de pagar. "" quando
## ainda não fecha nada.
static func privilege_for(repelled: int) -> Dictionary:
	for privilege in PRIVILEGES:
		if repelled == int(privilege["need"]):
			return privilege
	return {}

static func campaign_line(repelled: int) -> String:
	var next := {}
	for privilege in PRIVILEGES:
		if repelled < int(privilege["need"]):
			next = privilege
			break
	if next.is_empty():
		return "campanha de defesa completa (%d portas seguradas)" % repelled
	return "%d porta(s) segurada(s) • falta(m) %d para \"%s\"" % [
		repelled, int(next["need"]) - repelled, str(next["name"])]
