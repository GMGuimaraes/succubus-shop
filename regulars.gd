extends RefCounted
## Aventureiros recorrentes da loja: nomes, personalidades e falas por nível de amizade.
## O jogo guarda só o número de visitas/amizade de cada um (regular_bond em main.gd).

const THRESHOLDS: Array[int] = [0, 3, 8, 15]
const TIER_NAMES: Array[String] = ["Novo rosto", "Conhecido", "Freguês", "Devoto"]

# "favorite" é o índice do produto em main.gd (0 Dano Emocional, 1 Pato, 2 Lágrimas,
# 3 Caixa Vazia, 4 Confiança). "portrait" é o índice do retrato do cliente.
# "lines" tem uma lista de falas por nível; a primeira fala do nível 0 é a apresentação.
const DATA: Array = [
	{
		"id": "aldric", "name": "Sir Aldric, o Nível 1", "short": "Aldric", "portrait": 0, "favorite": 4,
		"lines": [
			["“Disseram que esta loja vende confiança em frasco. Eu aceito dois. Ontem eu morri para uma porta.”",
			 "“Sir Aldric, paladino nível 1! E antes que perguntem: sim, ainda é o tutorial.”"],
			["“Voltei! Dessa vez morri só duas vezes. A senhora vendedora tem algum feitiço para melhorar minha pontaria?”",
			 "“Aquele pato que você me vendeu salvou minha vida. Eu o joguei no dragão. Ele julgou o dragão.”"],
			["“Mestra da loja, minha armadura rangeu quando você sorriu. Ou fui eu. Difícil saber.”",
			 "“Falei para o grupo que conheço uma maga de negócios. Perguntaram se você era de verdade. Fiquei vermelho.”"],
			["“Por você eu juraria lealdade eterna. Mas já jurei para três reinos e uma assinatura de streaming.”",
			 "“Se eu morrer de novo, quero que você seja a última coisa que eu veja. Ou o recibo. Qualquer um dos dois.”"]
		],
		"request": "“Hoje eu não quero qualquer poção. Eu quero a minha. E pago com gratidão eterna... e um pouco de ouro.”",
		"empty": "“Cadê as poções? Meu grupo me espera na masmorra e eu sem frasco nenhum, de novo.”",
		"tier_up": [
			"“Você sabe meu nome de cabeça? Ninguém sabe meu nome de cabeça.”",
			"“Eu tenho um lugar fixo na sua loja agora? Tipo uma cadeira? Posso trazer uma cadeira.”",
			"“Juro por minha espada, meu escudo e esta poção: nunca mais compro em outra loja.”"
		]
	},
	{
		"id": "lyra", "name": "Lyra Cinzalume", "short": "Lyra", "portrait": 1, "favorite": 0,
		"lines": [
			["“Só vim buscar uma poção. Não olhe para mim. Não fale comigo. ...O que você recomenda?”",
			 "“Dizem que esta loja é cheia de gente esquisita. Já me sinto em casa.”"],
			["“N-não pense que voltei por sua causa. A poção é que é boa. Só isso.”",
			 "“Você sempre sorri desse jeito para todo mundo? ...Esquece. Esqueça que perguntei.”"],
			["“Passei a noite lendo um grimório e pensando em... ingredientes. Ingredientes! Pare de sorrir.”",
			 "“Se um dia eu enfeitiçar alguém, juro que não será você. Você já faz isso sozinha.”"],
			["“Escrevi seu nome no meu grimório. Na lista de fornecedores. Só na lista de fornecedores!”",
			 "“Fica comigo mais um minuto? Para... conferir o troco. Sim. O troco.”"]
		],
		"request": "“Preciso da poção especial. A que só você prepara. E, hã, faça com capricho. Por favor.”",
		"empty": "“Estoque vazio? Atravessei a cidade debaixo de chuva para isso?! ...Tudo bem. Você me deve um chá.”",
		"tier_up": [
			"“Você lembrou meu nome. Que... estranho. Que bom. Quer dizer, tanto faz.”",
			"“Eu trouxe um presente. É só um marcador de livro. Não é nada. Pegue logo.”",
			"“Pronto, falei! Eu gosto daqui. E do... atendimento. Do atendimento!”"
		]
	},
	{
		"id": "korvax", "name": "Korvax, o Bárbaro Sensível", "short": "Korvax", "portrait": 2, "favorite": 2,
		"lines": [
			["“GRAAAH! ...Desculpa. Assustei alguém? Eu só queria comprar uma coisa bonita.”",
			 "“Um bárbaro forte também precisa de cuidados. Você tem hidratante para armadura?”"],
			["“Escrevi um poema sobre a sua loja. É curto: ‘Poção, ouro, poção.’ Ainda estou editando.”",
			 "“Chorei na batalha de ontem. O orc também chorou. Fizemos as pazes.”"],
			["“Seus olhos brilham mais que minha machadinha polida. E olha que eu poli muito.”",
			 "“Meu grupo diz que eu fico bobo quando venho aqui. Eu disse que é o cheiro dos incensos. Mentira.”"],
			["“Por você, mestra, eu deixaria o machado em casa. Só não conte a ninguém: é o meu melhor machado.”",
			 "“Se você pedir, eu carrego a loja nas costas. Hoje, se quiser. Eu aguento.”"]
		],
		"request": "“Hoje a dor está grande e só as Lágrimas resolvem. Pago em dobro, mestra. Pago em verso também.”",
		"empty": "“Sem estoque... *funga* ...Eu estou bem. É só poeira. Muita poeira.”",
		"tier_up": [
			"“Você sabe meu nome! Isso vai para o meu diário de campanha.”",
			"“Posso te chamar de amiga? Ou de mestra? Ou... dos dois?”",
			"“Eu juro: se alguém falar mal da sua loja, eu choro na frente dele. Isso dói mais que machado.”"
		]
	},
	{
		"id": "mina", "name": "Mina Duas-Adagas", "short": "Mina", "portrait": 2, "favorite": 3,
		"lines": [
			["“Olá, bonita. Quanto custa o desconto? Brincadeira. Mais ou menos.”",
			 "“Não me olhe assim. Meu bolso só está vazio por motivos estratégicos.”"],
			["“Se eu comprar três, o quarto sai de graça? E um beijo de brinde? Estou testando os termos.”",
			 "“Prometo que não roubei nada hoje. Quase nada. Praticamente zero.”"],
			["“Você é a única comerciante que me faz querer pagar o preço cheio. Essa é a minha forma de declaração.”",
			 "“Me ensina o segredo? Esse olhar que faz o cliente largar a carteira. Eu só sei fazer o contrário.”"],
			["“Se a guilda soubesse que a melhor ladra da cidade se rendeu a uma lojista... Deixa pra lá, eu me rendo com prazer.”",
			 "“Hoje não vim roubar nada. Só vim ficar por perto. O que é um tipo de roubo, mas dos bons.”"]
		],
		"request": "“Quero a caixa vazia. A de sempre. Dizem que o que tem dentro vale mais... e eu sei que está vazia. Que romântico.”",
		"empty": "“Sem estoque? Bom, então não tenho o que roubar. Digo, comprar. Comprar!”",
		"tier_up": [
			"“Gostei de você. Isso é perigoso. Para os dois.”",
			"“Pode pôr meu nome no caderno de fregueses. A lápis, para eu poder fugir da dívida.”",
			"“Minha reputação de ladra está arruinada. E sabe de uma coisa? Eu adorei.”"
		]
	},
	{
		"id": "tuck", "name": "Frei Tuck Sem-Mana", "short": "Tuck", "portrait": 0, "favorite": 1,
		"lines": [
			["“Que a luz o abençoe! E o desconto também, se possível. Estou sem mana desde terça.”",
			 "“Sou clérigo de cura. Estou curando uma ressaca. Ela se recusa a sair.”"],
			["“Abençoei o pato que comprei. Ele não gostou. Mas melhorou o humor do grupo.”",
			 "“Minha fé é forte, mas meu orçamento é fraco. Você tem algum milagre em promoção?”"],
			["“Rezei por você ontem. Pedi que a loja prospere... e que você aceite um café comigo. Em nome da fé.”",
			 "“Meus votos dizem que não posso olhar para tentações, mas minha vista é ruim mesmo. Chega mais perto?”"],
			["“Os deuses falaram. Disseram: ‘Compre mais um pato.’ Acho que foi minha consciência. Ou o seu sorriso.”",
			 "“Se eu largar o sacerdócio, abro uma loja ao lado. Só para ficar perto da concorrência. Perto, perto.”"]
		],
		"request": "“Preciso de um pato. O abençoado, o premium. É para uma cerimônia. Muito íntima, só eu e o pato.”",
		"empty": "“Sem patos? Meu estoque de fé acabou junto. Que a luz proteja esta loja da falência.”",
		"tier_up": [
			"“Que honra! Ser lembrado numa loja tão... movimentada.”",
			"“Posso abençoar a sua porta? De graça. Meu primeiro serviço sem cobrar.”",
			"“Eu trairia meu deus por um desconto seu. Mas é só o dízimo de volta. Só o dízimo.”"
		]
	}
]

static func tier_for(bond: int) -> int:
	var tier := 0
	for i in range(THRESHOLDS.size()):
		if bond >= THRESHOLDS[i]:
			tier = i
	return tier

static func find(id: String) -> Dictionary:
	for reg in DATA:
		if str(reg["id"]) == id:
			return reg
	return {}
