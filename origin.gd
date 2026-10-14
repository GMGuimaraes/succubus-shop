extends RefCounted
## Cenas de origem: quem é a chefe e quem é a patrona, contadas entre capítulos.
## O jogo guarda só `origin_seen` (lista de ids já exibidos). Cada capítulo fechado
## libera a cena do índice correspondente; a última é do pós-campanha.
##
## "who" é quem fala na cena: "chefe", "patrona" ou "as duas". "chapter" é o índice
## do capítulo que a libera (Campaign.size() para a cena final).

const DATA: Array = [
	{
		"id": "origem_porta", "who": "chefe", "chapter": 0,
		"title": "A primeira porta",
		"lines": [
			"A chefe chegou à esquina num terça-feira de chuva, com uma licença comercial falsificada em três reinos e um vestido comprado a prazo.",
			"Ela não abriu a loja porque sabia fazer poção. Abriu porque foi a única esquina da cidade cujo aluguel ninguém quis: dizem que o andar de cima tem dono, e dono demais.",
			"No primeiro dia vendeu um frasco de água com corante para um paladino faminto. Ele voltou. Isso foi o bastante para ela ficar."
		]
	},
	{
		"id": "origem_contrato", "who": "patrona", "chapter": 1,
		"title": "A letra no contrato",
		"lines": [
			"O dinheiro do primeiro mês não saiu do caixa. Saiu de um envelope sem remetente, entregue por um cobrador que não olhou para a chefe nem uma vez.",
			"A patrona nunca apareceu na loja. Escreve em papel timbrado, corrige a pontuação dos contratos e paga adiantado — que é a forma mais educada de dizer que manda.",
			"A chefe leu o contrato quatro vezes. Na quinta parou de procurar a cláusula de saída, porque não havia nenhuma, e entendeu que aquilo era convite."
		]
	},
	{
		"id": "origem_sorriso", "who": "chefe", "chapter": 2,
		"title": "O preço do sorriso",
		"lines": [
			"Sorriso de súcubo não é de graça: cada vez que ela encanta um freguês, guarda o recibo do que deixou de sentir naquele minuto.",
			"Foi assim que aprendeu a cobrar caro de quem voltava só para conversar. Era a única forma de não cobrar sozinha.",
			"O primeiro cliente que voltou sem feitiço nenhum a deixou nervosa. Ainda hoje não sabe explicar por quê."
		]
	},
	{
		"id": "origem_estrada", "who": "patrona", "chapter": 3,
		"title": "A estrada que ela não anda",
		"lines": [
			"A patrona foi batedora antes de ser sombra: atravessou o abismo três vezes carregando caixa, e na quarta voltou de mãos vazias e com um nome novo.",
			"Ela financia lojas de esquina porque foi numa delas que aprendeu o ofício — e porque nenhuma loja de esquina jamais teve coragem de perguntar de onde vem o envelope.",
			"Quando a chefe mandou o primeiro batedor da casa, a patrona escreveu de volta uma única linha: “Não esquece de conferir a volta dele.”"
		]
	},
	{
		"id": "origem_santuario", "who": "chefe", "chapter": 4,
		"title": "O santuário emprestado",
		"lines": [
			"As relíquias do santuário não foram compradas. Vieram na chave da loja, embrulhadas em jornal de trinta anos atrás, com um bilhete: “Cuida delas melhor do que eu cuidei.”",
			"A loja anterior pegou fogo por causa de uma peça que ninguém soube guardar. A chefe nunca descobriu qual era, e guarda todas do mesmo jeito.",
			"Foi a primeira vez que ela entendeu que o andar de cima não era ameaça. Era herança."
		]
	},
	{
		"id": "origem_cartas", "who": "patrona", "chapter": 5,
		"title": "As cartas são dela",
		"lines": [
			"A máquina de cartas é propriedade da patrona, estacionada no balcão como quem estaciona um carro na porta de alguém: por enquanto.",
			"Cada carta impressa sai com um retrato que a chefe não reconhece e um nome que ela já ouviu em sonho.",
			"“Colecione”, escreveu a patrona. “Quem coleciona, volta. Quem volta, paga.” Foi o conselho mais sincero que a loja já recebeu."
		]
	},
	{
		"id": "origem_andar", "who": "as duas", "chapter": 6,
		"title": "A conversa no andar de cima",
		"lines": [
			"A escada que a chefe limpava todo dia sem nunca subir deu num único cômodo: uma mesa, um livro-razão e uma mulher mais velha usando o vestido dela.",
			"A patrona não é sócia nem cobrança. É a chefe daqui a trinta anos, tendo aprendido que o único jeito de salvar a loja era financiá-la sem nunca pisar nela.",
			"“Você vai errar o estoque três vezes”, disse a mais velha. “Eu errei. É por isso que o envelope chega sempre na terça.”",
			"A chefe desceu a escada sem olhar para trás, comprou o estoque inteiro na quarta e nunca mais deixou um envelope sem abrir."
		]
	},
	{
		"id": "origem_recibo", "who": "chefe", "chapter": 7,
		"title": "O recibo do andar de cima",
		"lines": [
			"No fim do império, a chefe encontrou na gaveta o primeiro recibo da loja: água com corante, pago por um paladino nível um que jurou voltar.",
			"Ela devolveu o papel à gaveta e não emoldurou. É a coisa mais adulta que o império inteiro já viu ela fazer."
		]
	}
]

static func size() -> int:
	return DATA.size()

static func chapter_scene(chapter_index: int) -> Dictionary:
	for scene in DATA:
		if int(scene["chapter"]) == chapter_index:
			return scene
	return {}

static func find(id: String) -> Dictionary:
	for scene in DATA:
		if str(scene["id"]) == id:
			return scene
	return {}

static func who_label(scene: Dictionary) -> String:
	match str(scene.get("who", "chefe")):
		"patrona":
			return "A PATRONA"
		"as duas":
			return "A CHEFE E A PATRONA"
	return "A CHEFE"
