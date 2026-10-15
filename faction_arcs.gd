extends RefCounted
## Capítulos narrativos por facção. Cada uma das cinco facções tem três pedidos
## escritos, que só abrem na medida em que a loja vira gente conhecida daquele
## público: o primeiro precisa de fama de "Notada", o segundo de "Respeitada" e o
## terceiro de "Lenda", sempre com o capítulo da campanha já fechado junto.
##
## O pedido não sorteia nada: ele cobra uma coisa que a loja já faz por outro
## motivo — fabricar, expedir, atender, pagar conta — e paga em ouro, fama,
## experiência e fama de facção, o que empurra o degrau seguinte. Fechar os três
## entrega um **privilégio permanente** daquela facção, que mexe numa fórmula que
## já existia. É a parte duradoura: o arco é da conta salva, não da vida, e
## reencarnar não apaga nome nenhum na parede.
##
## O jogo guarda só `arc_step` (facção → quantos pedidos já foram entregues) e
## `faction_customers` (clientes daquele tipo atendidos nesta vida). Toda tabela
## aqui é fixa.

## Cada pedido: `stat` é a chave que `main.gd` já mede, `amount` o número cobrado,
## `standing` a fama de facção pedida e `chapter` o capítulo da campanha fechado.
const DATA := {
	"guildas": [
		{
			"id": "g1", "title": "O teste da bancada",
			"ask": "Haskar, mestre da Guilda dos Artesãos, põe uma peça torta sobre o balcão e quer vê-la sair direita da sua bigorna antes de emprestar o nome da guilda.",
			"stat": "pecas", "amount": 6, "unit": "peças fabricadas",
			"standing": 5, "chapter": 1,
			"reward": {"gold": 120, "rep": 2, "xp": 30, "standing": 1},
			"done": "Haskar gira a peça contra a luz, procura a emenda, não acha e assina o papel. A bancada da loja agora tem selo de guilda.",
			"voice": "“Fabricar bonito é isto: o defeito some e ninguém precisa saber como.”",
		},
		{
			"id": "g2", "title": "Três peças de catálogo",
			"ask": "A guilda só imprime catálogo com peça Refinada para cima. Haskar quer três, e quer ver o orgulho na cara de quem as fez.",
			"stat": "primas", "amount": 3, "unit": "peças Refinada ou melhor",
			"standing": 15, "chapter": 2,
			"reward": {"gold": 260, "rep": 4, "xp": 60, "standing": 2},
			"done": "As três peças entram no catálogo da guilda com o nome da loja embaixo. Haskar deixa escapar que o tesoureiro chorou um pouco.",
			"voice": "“Lê direito: o seu nome, impresso, antes de qualquer preço. Isso é caro de vender.”",
		},
		{
			"id": "g3", "title": "O contrato do mestre",
			"ask": "Uma encomenda de longo prazo, com prazo de verdade: a guilda quer ver a casa entregar três etapas sem atrasar nenhuma.",
			"stat": "encomendas", "amount": 1, "unit": "encomenda de longo prazo entregue",
			"standing": 30, "chapter": 3,
			"reward": {"gold": 480, "rep": 6, "xp": 110, "standing": 3},
			"done": "A encomenda fecha no prazo, e a guilda risca a loja da lista de fornecedores a vigiar. Haskar aperta a sua mão duas vezes.",
			"voice": "“Contrato cumprido é feitiçaria rara, querido. Guarda essa mão: eu apertei ela por motivo.”",
		},
	],
	"nobres": [
		{
			"id": "n1", "title": "Cinco visitas com nome",
			"ask": "A dama Ophélia Vane desceu à loja sem anúncio. Quer ver se cinco clientes do tipo dela saem daqui achando a casa suportável.",
			"stat": "clientes", "amount": 5, "unit": "clientes da facção atendidos",
			"standing": 5, "chapter": 1,
			"reward": {"gold": 140, "rep": 3, "xp": 35, "standing": 1},
			"done": "Ophélia conta cinco conhecidos que saíram contentes e declara a loja 'suportável em público'. Da boca dela, é um título.",
			"voice": "“Suportável em público. Vá se vestir de orgulho, que a corte já fez o resto.”",
		},
		{
			"id": "n2", "title": "O que a rua comenta",
			"ask": "A corte não olha para loja pequena: olha para loja da qual se fala. Ophélia pede 25 de reputação no bairro antes de citar o seu nome.",
			"stat": "fama", "amount": 25, "unit": "reputação no bairro",
			"standing": 15, "chapter": 3,
			"reward": {"gold": 300, "rep": 5, "xp": 70, "standing": 2},
			"done": "O nome da loja circula entre sobremesas. Ophélia manda dizer que foi ela quem começou o boato, e cobra o elogio.",
			"voice": "“Fofoca com pedigree é marketing, querido. E eu cobro caro por ela.”",
		},
		{
			"id": "n3", "title": "Vitrine dentro do círculo",
			"ask": "Nada de vidro novo no salão: a corte só aceita a loja dentro dele. Abrir a Vitrine da Corte é o penúltimo favor que Ophélia pede.",
			"stat": "filial_corte", "amount": 1, "unit": "Vitrine da Corte aberta",
			"standing": 30, "chapter": 5,
			"reward": {"gold": 620, "rep": 8, "xp": 130, "standing": 3},
			"done": "A vitrine da corte acende com o nome da loja em ouro fino. Ophélia manda a conta do letreiro para a tesouraria — e a tesouraria paga.",
			"voice": "“Agora a casa tem endereço onde a gente não pede licença para entrar. Isso é quase casamento.”",
		},
	],
	"aventureiros": [
		{
			"id": "a1", "title": "Trazer o mapa de volta",
			"ask": "Ruka Meio-Escudo não confia em loja que nunca saiu da esquina. Duas expedições completas, com gente e carga voltando.",
			"stat": "expedicoes", "amount": 2, "unit": "expedições concluídas",
			"standing": 5, "chapter": 1,
			"reward": {"gold": 130, "rep": 2, "xp": 35, "standing": 1},
			"done": "Ruka confere as duas rotas no mapa e risca a palavra 'turista' do lado do nome da loja.",
			"voice": "“Quem conhece o caminho não cobra caro por susto. Aprende isso e eu ensino o resto.”",
		},
		{
			"id": "a2", "title": "Pó de coisa rara",
			"ask": "A tropa só compra poção de quem já viu o que tem do outro lado da trilha. Três raridades no balcão, trazidas na mão.",
			"stat": "raridades", "amount": 3, "unit": "raridades trazidas de expedição",
			"standing": 15, "chapter": 2,
			"reward": {"gold": 280, "rep": 4, "xp": 65, "standing": 2},
			"done": "Ruka cheira o pó, cospe, e mesmo assim aprova. A tropa passa a marcar a loja como ponto de reabastecimento.",
			"voice": "“Isso aqui é raridade de verdade ou poeira de sapo? Tanto faz: eles vão comprar igual.”",
		},
		{
			"id": "a3", "title": "Quatro histórias sem testemunha",
			"ask": "Aventureiro só jura pela sua prateleira depois de ouvir quatro absurdo que a loja sobreviveu. Eventos raros, contados na taberna.",
			"stat": "eventos", "amount": 4, "unit": "eventos raros presenciados",
			"standing": 30, "chapter": 4,
			"reward": {"gold": 520, "rep": 6, "xp": 120, "standing": 3},
			"done": "Quatro histórias, quatro rodadas, e a guilda de aventureiros adota a loja como a sua segunda casa. A primeira pegou fogo.",
			"voice": "“Eles acreditam em qualquer coisa depois da terceira caneca. Vende poção de coragem pra eles.”",
		},
	],
	"mercadores": [
		{
			"id": "m1", "title": "Quem compra em volume",
			"ask": "Sabet Corvo, camelô de cartão de visita, quer ver seis clientes de banca comprando na sua loja antes de abrir o caderno de fornecedores.",
			"stat": "clientes", "amount": 6, "unit": "clientes da facção atendidos",
			"standing": 5, "chapter": 1,
			"reward": {"gold": 150, "rep": 2, "xp": 35, "standing": 1},
			"done": "Sabet anota seis nomes de banca no caderno e devolve o lápis: 'a partir de agora você escreve as suas próprias condições'.",
			"voice": "“Volume é conversa de gente grande. Eles falaram, você anotou, e o lucro é seu.”",
		},
		{
			"id": "m2", "title": "Provar que o caixa aguenta",
			"ask": "Fornecedor não financia loja quebrada. Sabet quer ver 1200 de ouro no caixa no mesmo instante em que ele bater na porta.",
			"stat": "caixa", "amount": 1200, "unit": "ouro no caixa",
			"standing": 15, "chapter": 2,
			"reward": {"gold": 320, "rep": 4, "xp": 70, "standing": 2},
			"done": "Sabet vê o caixa, conta duas vezes e muda o tratamento: 'sócio' soa melhor que 'freguesa'.",
			"voice": "“Dinheiro parado também trabalha, querida. Ele fica olhando o concorrente passar.”",
		},
		{
			"id": "m3", "title": "Trinta compras no mesmo fornecedor",
			"ask": "Parceria de verdade é fidelidade chata: trinta compras de matéria-prima feitas na banca dele, sem pechinchar por trás.",
			"stat": "compras", "amount": 30, "unit": "ingredientes comprados",
			"standing": 30, "chapter": 4,
			"reward": {"gold": 560, "rep": 6, "xp": 120, "standing": 3},
			"done": "Trinta compras depois, a banca do Sabet tem a sua placa ao lado da sua. O cais inteiro aprende o nome da loja.",
			"voice": "“Fidelidade é cara, mas o fornecedor devolve em preço. É o único casamento que dá lucro.”",
		},
	],
	"submundo": [
		{
			"id": "s1", "title": "Quatro que não deixam nome",
			"ask": "A Senhora das Contas manda perguntar se a loja atende bem quem não pode dar o próprio nome. Quatro clientes, sem nota, sem reclamar.",
			"stat": "clientes", "amount": 4, "unit": "clientes da facção atendidos",
			"standing": 5, "chapter": 2,
			"reward": {"gold": 160, "rep": 2, "xp": 35, "standing": 1},
			"done": "Quatro saíram com a mercadoria e sem a conversa. O beco passa a tratar a loja como casa de família.",
			"voice": "“Discrição é o produto mais caro da loja, e você acabou de vender quatro.”",
		},
		{
			"id": "s2", "title": "Sair do vermelho uma vez",
			"ask": "O submundo empresta para quem já provou que consegue pagar. Quitar 120 de dívida sem quebrar no meio é a única prova aceita.",
			"stat": "quites", "amount": 1, "unit": "dívida de 120 quitada pagando em dia",
			"standing": 15, "chapter": 4,
			"reward": {"gold": 340, "rep": 5, "xp": 75, "standing": 2},
			"done": "A Senhora das Contas confere o livro, fecha sem barulho e diz a frase que ninguém disse ainda: 'essa loja paga'.",
			"voice": "“Quem já esteve no buraco e saiu andando sabe o preço do chão. É isso que eu compro.”",
		},
		{
			"id": "s3", "title": "A casa em ordem é a melhor máscara",
			"ask": "Nada denuncia mais uma loja do que a própria bagunça. Dois níveis de Administração da Casa, e o beco confia o resto do estoque a você.",
			"stat": "casa", "amount": 2, "unit": "níveis de Administração da Casa",
			"standing": 30, "chapter": 6,
			"reward": {"gold": 640, "rep": 8, "xp": 140, "standing": 3},
			"done": "O beco entrega a chave da porta sem placa. A loja agora guarda coisa dos outros — e ninguém mais pergunta qual é a mercadoria.",
			"voice": "“Confiança é isto: eu guardo o seu segredo e você nem precisa saber o meu. Duas vezes por semana.”",
		},
	],
}

## O que fica para sempre quando os três pedidos da facção são entregues. Cada
## privilégio mexe numa fórmula que a loja já usava — nada de número novo solto.
const PERKS := {
	"guildas": {
		"name": "Selo de bancada",
		"desc": "Fabricar peça sai 10% mais barato na casa que tem o selo das Guildas.",
	},
	"nobres": {
		"name": "Carta de recomendação",
		"desc": "Toda etiqueta da loja sobe 6% quando a corte recomenda.",
	},
	"aventureiros": {
		"name": "Pacto de estrada",
		"desc": "+1 de sorte na forja, na estrada e no sorteio do pacote.",
	},
	"mercadores": {
		"name": "Fornecedor fiel",
		"desc": "Matéria-prima sai 12% mais barata com o caderno do Sabet aberto.",
	},
	"submundo": {
		"name": "Porta sem placa",
		"desc": "Cada filial tem 3% menos chance de dia ruim quando o beco protege a loja.",
	},
}

static func size(faction_id: String) -> int:
	return steps(faction_id).size()

static func total() -> int:
	var sum := 0
	for faction_id in DATA.keys():
		sum += steps(str(faction_id)).size()
	return sum

static func steps(faction_id: String) -> Array:
	return DATA.get(faction_id, [])

static func step(faction_id: String, index: int) -> Dictionary:
	var list := steps(faction_id)
	if index < 0 or index >= list.size():
		return {}
	return list[index]

static func perk(faction_id: String) -> Dictionary:
	return PERKS.get(faction_id, {})

static func closed(faction_id: String, progress: int) -> bool:
	var total := size(faction_id)
	return total > 0 and progress >= total

## O número que a loja já tem daquela facção, na moeda que o pedido cobra.
static func progress(stats: Dictionary, st: Dictionary) -> int:
	return int(stats.get(str(st["stat"]), 0))

## "" quer dizer que o pedido pode ser entregue. Qualquer outra resposta é o
## motivo escrito no botão, na ordem do que falta primeiro.
static func reason(stats: Dictionary, st: Dictionary, standing: int, chapter: int) -> String:
	if standing < int(st["standing"]):
		return "fama de facção %d/%d" % [standing, int(st["standing"])]
	if chapter < int(st["chapter"]):
		return "fecha %d capítulo(s) antes" % (int(st["chapter"]) - chapter)
	if progress(stats, st) < int(st["amount"]):
		return "%s %d/%d" % [str(st["unit"]), progress(stats, st), int(st["amount"])]
	return ""

## A linha curta que o painel lê: o que o pedido cobra, em número.
static func goal_text(st: Dictionary) -> String:
	return "%d %s" % [int(st["amount"]), str(st["unit"])]
