extends RefCounted
## Aventureiros recorrentes da loja: nomes, personalidades e falas por nível de amizade.
## O jogo guarda só o número de visitas/amizade de cada um (regular_bond em main.gd).

const THRESHOLDS: Array[int] = [0, 3, 8, 15]
const TIER_NAMES: Array[String] = ["Novo rosto", "Conhecido", "Freguês", "Devoto"]

# "favorite" é o id do produto em main.gd (dano_emocional, pato_amaldicoado,
# lagrimas_jogador, caixa_misteriosa, confianca_instantanea, elixir_memoria,
# incenso_teleporte, cristal_credito, pergaminho_procrastinacao, frasco_motivacao,
# adaga_charme, martelo_faisca). "portrait" é o índice do retrato em main.gd
# (customer_portrait_paths): 0 aventureiro, 1 maga, 2 gótico, 3 bárbaro,
# 4 ladina, 5 clérigo, 6 mercadora, 7 nobre, 8 goblin, 9 cobrador.
# "faction" aponta para um id em factions.gd.
# "lines" tem uma lista de falas por nível; a primeira fala do nível 0 é a apresentação.
# "romance" são as três falas da escada de confiança: convite, encontro e momento a dois.
# "background" é a ficha curta do painel direito. "arc" são os quatro atos da ficha,
# no formato "ATO N — TÍTULO: corpo"; o ato é derivado do progresso da loja (visita,
# nível Conhecido, capítulo pessoal e convite pago), então a ordem dos textos importa.
# "farewell" é a despedida do epílogo, uma por ato, na mesma ordem do "arc".
# Mantenha o favorito em um produto de nível baixo: capítulos pedem três compras favoritas.
const DATA: Array = [
	{
		"id": "aldric", "name": "Sir Aldric, o Nível 1", "short": "Aldric", "portrait": 0, "favorite": "confianca_instantanea", "faction": "nobres",
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
		],
		"romance": [
			"“Um convite? Eu enfrentei um dragão sem tremer. Por que estou tremendo por um café?”",
			"“Ficamos até o sol nascer. Eu jurei proteger a loja. Ninguém atacou. Ataquei só o bolo.”",
			"“Sir Aldric, nível um, de joelhos, e não foi numa batalha. A senhora pode guardar a minha espada.”"
		],
		"background": "Filho caçula de uma casa de cavaleiros mortos em batalhas gloriosas. Aldric entrou na ordem para ter um teto e saiu dela para ter uma história. Ainda não conseguiu nenhum dos dois, mas paga em dia.",
		"arc": [
			"ATO I — O NÍVEL UM: o paladino que não passa do nível 1 chega com a armadura de um herdeiro e o mapa de um perdido. Ele não compra poção: compra a chance de voltar inteiro.",
			"ATO II — A ESPADA EMPRESTADA: Aldric conta que o grupo o chama de 'o reserva', mesmo sem grupo. Pela primeira vez ele riu de si mesmo antes de alguém rir dele.",
			"ATO III — O JURAMENTO DE BALCÃO: ele jurou proteger a loja como se fosse uma cidade. São um balcão e uma cadeira, e ele levou o juramento a sério.",
			"ATO IV — O PAPEL NA CARTEIRA: Aldric guarda o recibo da primeira compra dobrado em quatro. É o único papel desta cidade com o nome dele escrito por outra pessoa."
		],
		"farewell": [
			"“Ouvi que a loja ia fechar de vez. Vim ver se a senhora ainda precisava de um escudo.”",
			"“Se eu passar do nível um um dia, a culpa é do seu balcão. Eu volto. Prometo voltar.”",
			"“Jurei proteger uma cidade e descobri que bastava guardar uma porta de loja. Guardei. Foi meu melhor nível.”",
			"“Vou embora com a sua espada emprestada de mentira. Um dia eu devolvo. Um dia.”"
		]
	},
	{
		"id": "lyra", "name": "Lyra Cinzalume", "short": "Lyra", "portrait": 1, "favorite": "dano_emocional", "faction": "guildas",
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
		],
		"romance": [
			"“Um café? Óbvio que eu aceito. Não é por você. É pela cafeína.”",
			"“Conjurei duas estrelas para iluminar a mesa. Foi profissional. Só profissional. Para de olhar.”",
			"“Apaguei todas as velas menos uma. O grimório ficou fechado a noite inteira.”"
		],
		"background": "Expulsa da academia por excesso de iniciativa — a iniciativa era salvar gente. Trabalha como maga de campo autônoma e finge que prefere assim.",
		"arc": [
			"ATO I — A MAGA SEM OLHOS: ela entra sem olhar na cara de ninguém e sai com três frascos e uma desculpa. Jura que é pela poção.",
			"ATO II — O CADERNO DE RECUSAS: Lyra anota toda vez que a loja a fez sorrir, para provar depois que não aconteceu. O caderno está na página quarenta.",
			"ATO III — O FEITIÇO QUE NINGUÉM ENSINA: salvou o grupo inteiro com uma receita comprada aqui. Ninguém acreditou quando ela disse que foi compra, não magia.",
			"ATO IV — A PORTA ABERTA: ela deixou o ombro encostar no balcão. Para Lyra, isso é um discurso de quatro páginas."
		],
		"farewell": [
			"“Só passei para dizer que a sua loja não é ruim. Foi o que eu disse. Tchau.”",
			"“Se eu sumir, procura. Não que eu vá sumir. Mas se eu sumir, é aqui que eu estou.”",
			"“Publiquei o tratado com o seu nome nos agradecimentos. Não reli. Relê você.”",
			"“Fechei o grimório na página do seu nome. É a única que eu não preciso reler.”"
		]
	},
	{
		"id": "korvax", "name": "Korvax, o Bárbaro Sensível", "short": "Korvax", "portrait": 3, "favorite": "lagrimas_jogador", "faction": "aventureiros",
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
		],
		"romance": [
			"“Convidar o bárbaro? O bárbaro obedece. O bárbaro também está corando, não conte a ninguém.”",
			"“Levei flores. Grandes. Arranquei a árvore inteira, mas as flores ficaram presas, então isso conta como ramalhete.”",
			"“Deitei a machadinha no chão pela primeira vez em doze anos. Fica aí. Hoje eu não vou precisar dela.”"
		],
		"background": "Último da tribo que parou de guerrear para virar caravana. Korvax carrega machado por herança e lenço por gosto, e já decidiu qual dos dois lhe serve melhor.",
		"arc": [
			"ATO I — CABEÇA BAIXA NO BATENTE: o bárbaro entra devagar para não quebrar a porta e pede a coisa mais bonita da loja. Ele sempre pede a mais bonita.",
			"ATO II — O DIÁRIO DE CAMPANHA: escreve cada visita com data, hora e o que vestia. Reserva a última página e não diz para quem.",
			"ATO III — A TRIBO QUE PAROU: mandou dizer à caravana que encontrou um lugar onde 'o grande faz sentido'. A caravana respondeu pedindo lista de compras.",
			"ATO IV — O MACHADO DO LADO DE DENTRO: deixou a arma encostada na parede da loja, dentro. Primeira vez em doze anos que entra num lugar desarmado."
		],
		"farewell": [
			"“GRAAAH... digo, obrigado pela poção. Adeus. *funga*”",
			"“Levo o machado, deixo o lenço. É assim que a tribo se despede de quem gosta.”",
			"“Terminei o poema. São quatro linhas. Rimei o seu nome com abismo. Ficou bom.”",
			"“Eu carregaria a loja nas costas mais uma vez. Você disse que não. Carreguei mesmo assim.”"
		]
	},
	{
		"id": "mina", "name": "Mina Duas-Adagas", "short": "Mina", "portrait": 4, "favorite": "caixa_misteriosa", "faction": "submundo",
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
		],
		"romance": [
			"“Convite com hora e lugar? Quer que eu invada a loja? ...Posso invadir a loja?”",
			"“Roubei um beijo e devolvi com juros. Está virando um negócio péssimo para o meu histórico.”",
			"“Pela primeira vez na vida entrei num quarto pela porta e não levei nada. Só fiquei.”"
		],
		"background": "Ladra da Guilda Silenciosa com o melhor histórico de devoluções da cidade. Mina rouba uma vez e paga duas, porque diz que crédito vale mais que produto.",
		"arc": [
			"ATO I — A DECLARAÇÃO DE INOCÊNCIA: entra anunciando que não vai roubar nada, com a mão já no bolso. O bolso está vazio de propósito.",
			"ATO II — O CADERNINHO DE DÍVIDAS: anota quanto deve a cada comerciante da cidade. O seu nome é o único com estrela.",
			"ATO III — O GOLPE RECUSADO: podia abrir o caixa da loja e não abriu. Contou para a guilda, que abriu uma investigação sobre o caráter dela. Ninguém nunca tinha pedido.",
			"ATO IV — PORTA DA FRENTE: entrou, pagou e saiu sem levar nada além da companhia. A guilda chama de perda. Ela chama de terça-feira."
		],
		"farewell": [
			"“Não levei nada. Está anotado. Um dia ainda levo, hein. Tchau.”",
			"“Sua ficha está no meu bolso, com o meu número do lado. É ameaça e convite.”",
			"“Devolvi tudo que roubei desta loja. Foi a única coisa que eu roubei de você, e eu devolvi.”",
			"“Roubei um beijo e deixei o ouro em cima. A conta fecha. A dívida não.”"
		]
	},
	{
		"id": "tuck", "name": "Frei Tuck Sem-Mana", "short": "Tuck", "portrait": 5, "favorite": "pato_amaldicoado", "faction": "guildas",
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
		],
		"romance": [
			"“Café a duas luzes? Posso benzer a mesa. É minha desculpa favorita para ficar mais perto.”",
			"“Perdoei todos os pecados da cidade hoje. Cheguei em casa e cometi três por conta própria.”",
			"“Renunciei por uma noite. Os deuses são compreensivos. Ou estavam olhando para o outro lado.”"
		],
		"background": "Clérigo auto-ordenado depois de um voto que a própria fé não confirmou. Frei Tuck cura o que pode com o que tem, e o que tem é conversa, paciência e um pato de brinquedo.",
		"arc": [
			"ATO I — SEM MANA, COM FÉ: abençoa a prateleira antes de perguntar o preço. A loja é o único lugar da cidade onde ele não precisa fingir certeza.",
			"ATO II — O DÍZIMO DELE: guarda moedas para doar 'a quem entende de milagres'. O caderno de doações tem uma única beneficiária.",
			"ATO III — A RESPOSTA: rezou pedindo um sinal sobre a loja. O sinal veio como um recibo. Ele decidiu que era resposta suficiente.",
			"ATO IV — A VIGÍLIA FALTADA: faltou à vigília para ficar até o fechamento. No caminho de volta não se confessou. Guardou para si."
		],
		"farewell": [
			"“Que a luz guie os seus preços. Amém, e obrigado pelo pato.”",
			"“Abençoei a porta. De graça. É a primeira coisa desta cidade que faço sem cobrar.”",
			"“Rezei pelos deuses e por você. Eles responderam menos que a senhora.”",
			"“Larguei o sacerdócio e abri banca ao lado. Ficou perto, perto, como eu prometi.”"
		]
	},
	{
		"id": "bruna", "name": "Bruna Preço-Certo", "short": "Bruna", "portrait": 6, "favorite": "pato_amaldicoado", "faction": "mercadores",
		"lines": [
			["“Só passando para conferir seus preços. É amizade. É pesquisa de mercado. São as duas coisas.”",
			 "“Uma colega lojista! Relaxa, não vim copiar nada. Vim olhar bem de perto, com carinho.”"],
			["“Seu pato está 12% mais barato que o meu. Isso é maldade ou é planilha?”",
			 "“Trouxe biscoito para a reunião. Seu cliente comeu meu biscoito. Estamos bem entre nós?”"],
			["“Nossa planilha compartilhada está bonita demais. Eu chamo de fundo de investimento afetivo.”",
			 "“Se você subir o preço, eu subo junto. Combinamos sem combinar. É quase romance.”"],
			["“Oficialmente você é minha consultora. Extraoficialmente, meu contador pediu demissão por sua causa.”",
			 "“Registrei a loja como patrimônio. Não é amor, é contabilidade. Mas fica perto do amor.”"]
		],
		"request": "“Me vende outro pato. O meu julga minhas decisões contábeis e eu preciso dessa honestidade toda manhã.”",
		"empty": "“Sem estoque? Anotado: dia 47 sem estoque. Sua concorrência agradece. Eu agradeço. Todo mundo agradece.”",
		"tier_up": [
			"“Vou te chamar de sócia. Não responde nada, que fica estranho escrito.”",
			"“Você é a única pessoa desta cidade que me empresta planilha de graça.”",
			"“Se a guilda dos mercadores souber que a gente se dá bem, eu perco meu cargo.”"
		],
		"romance": [
			"“Encontro comercial ou pessoal? Preciso registrar direito, pela contabilidade do meu coração.”",
			"“Jantamos dividindo a conta e a planilha. Nunca dividi nada tão bem.”",
			"“Fechei o escritório, apaguei o quadro de horários e ainda assim marquei ponto. Melhor dia fiscal da minha vida.”"
		],
		"background": "Terceira geração da Casa Preço-Certo e a primeira a sentir tédio. Bruna compete com toda a rua e se audita com o dobro da crueldade.",
		"arc": [
			"ATO I — PESQUISA DE MERCADO: a concorrente que entra para 'só olhar os preços' e sai com três itens e uma planilha nova. Toda semana.",
			"ATO II — A ABA COMPARTILHADA: abriu uma aba só com os números da sua loja e chamou de fundo de investimento afetivo. O contador pediu demissão.",
			"ATO III — A DENÚNCIA NÃO ENTREGUE: a guilda pediu provas de preço abusivo na sua loja. Bruna devolveu um relatório elogiando o atendimento.",
			"ATO IV — O BALANÇO: registrou a loja como patrimônio pessoal, o que é fraude e declaração ao mesmo tempo. Assinou duas vezes."
		],
		"farewell": [
			"“Pesquisa encerrada. Seus preços são desonestos. Assinado: a concorrência.”",
			"“Fechei o trimestre com o seu nome no rodapé. Ninguém nunca entrou no meu rodapé.”",
			"“Nossa planilha compartilhada virou patrimônio. Você virou passivo. Dos bons.”",
			"“Registrei a loja como sociedade, comigo dentro. Não pergunte ao contador.”"
		]
	},
	{
		"id": "ondina", "name": "Condessa Ondina Esquecida", "short": "Ondina", "portrait": 7, "favorite": "elixir_memoria", "faction": "nobres",
		"lines": [
			["“Juro que nunca pisei aqui. Que loja encantadora. Já nos vimos em algum salão?”",
			 "“Meu cocheiro diz que é a quarta vez hoje. Eu discordo veementemente e exijo desconto.”"],
			["“Voltei! Para comprar a mesma coisa de ontem. E de anteontem. Não conte para minha família.”",
			 "“Esquecimento sai caro na corte. Aqui eu compro memória a preço justo. É poético, não é?”"],
			["“Bebi seu elixir e acordei com o nome do meu advogado escrito na mão. Ele nega tudo.”",
			 "“Chame minha criada quando eu esquecer o preço. Ela finge que também esqueceu. Time.”"],
			["“Sei que esqueço. Sei que volto. E sei que você é o único lugar onde isso é negócio.”",
			 "“Mudei o testamento. Não pergunte o quê. Só me vende mais um elixir e esquece junto.”"]
		],
		"request": "“O elixir, querida. O mesmo elixir. Sim, sei que já comprei. Não, não lembro do sabor.”",
		"empty": "“Vazio? Que alívio, então eu não estava enlouquecendo. Anote aí: a condessa tinha razão.”",
		"tier_up": [
			"“Você lembra do meu nome. Minha família não lembra, mas você lembra.”",
			"“Vim de carruagem hoje. Na nobreza isso é praticamente uma declaração.”",
			"“Não direi a ninguém que volto tanto. Isso arruína todo o meu mistério.”"
		],
		"romance": [
			"“Um convite? Aceito três, se precisar que eu lembre de dizer sim.”",
			"“Saímos e eu esqueci o guarda-chuva, o cocheiro e o meu próprio nome. Lembrei do seu dez vezes.”",
			"“Bebi o elixir da memória de propósito, para escolher lembrar só desta noite. É a primeira coisa que decido guardar.”"
		],
		"background": "Terceira filha de uma casa que só registra herdeiros homens. Ondina apareceu em dezesseis registros e em nenhum retrato. Esquecer, para ela, é o único inventário que ninguém auditou.",
		"arc": [
			"ATO I — A QUARTA VISITA: a condessa jura que nunca pisou na loja enquanto o cocheiro conta as idas em voz alta. Ela quer ser novidade porque ser lembrada nunca funcionou.",
			"ATO II — O NOME NA MÃO: volta no dia seguinte com o nome da loja escrito na palma e diz que foi o remédio. O remédio não escreve nada; ela sabe, e ninguém corrige.",
			"ATO III — O TESTEMUNHO ESQUECIDO: assina o livro de fregueses e some com a página. A loja inteira finge que foi o esquecimento dela, o que é a gentileza mais cara da cidade.",
			"ATO IV — O QUE ELA ESCOLHE: bebe o elixir tendo estoque cheio, só para lembrar por vontade própria. É a primeira lembrança da vida dela que não foi um acidente."
		],
		"farewell": [
			"“Desculpe, já nos vimos? ...Desculpe, eu sei que vimos. Anota que eu esqueço, mas volto.”",
			"“Perdi o cocheiro, o leque e a semana inteira. Do endereço daqui eu não perdi.”",
			"“Contei à minha mãe que tenho um lugar favorito. Ela perguntou qual. Eu acertei de primeira.”",
			"“Bebi o elixir para esquecer tudo menos esta noite. Foi a única conta que quis pagar cheia.”"
		]
	},
	{
		"id": "rax", "name": "Rax, o Estagiário Goblin", "short": "Rax", "portrait": 8, "favorite": "adaga_charme", "faction": "aventureiros",
		"lines": [
			["“Eu sou MUITO perigoso. Tenho até uma adaga. Ah, ela ficou na loja do lado. Me vende outra?”",
			 "“Estágio não remunerado, mas o currículo agradece. Quero algo que pareça violência elegante.”"],
			["“Aprendi a pronunciar 'sinergia' e a furtar poção. A loja ainda me deixa trabalhar aqui.”",
			 "“Meu chefe disse que você é referência de mercado. Não sei se é elogio. Obedeço mesmo assim.”"],
			["“Consegui a vaga no grupo de aventureiros! Fui reprovado, mas a vaga foi minha.”",
			 "“Sua adaga brilha quando alguém promete pagar amanhã. Eu prometi a mim mesmo. Brilha o dia todo.”"],
			["“Quando eu comandar o sindicato, você será a fornecedora oficial. Já falei do seu currículo pro espelho.”",
			 "“Aceito trabalhar de graça só aqui. Não é você. É o estágio. O estágio vence sempre.”"]
		],
		"request": "“Me vende a adaga bonita. Se o grupo perguntar, eu consegui com desconto de herói.”",
		"empty": "“Estoque zerado? Meu mentor disse que isso é aprendizado. Mentira. É prejuízo mesmo.”",
		"tier_up": [
			"“Você lembrou que eu sou um goblin e não um entregador!”",
			"“Ganhei um crachá da loja. É de papel. Vou carregar para sempre.”",
			"“Te apresentei como 'minha contato no setor'. Soa mais honesto assim.”"
		],
		"romance": [
			"“Me convidou? Isso é networking ou é sério? Meu chefe diz que é sério quando você paga a conta.”",
			"“Reservei a mesa do VIP. Era a única mesa. Mas o garçom chorou, então no fim consegui.”",
			"“Tenho vinte anos e sou estagiário há dois. Ainda assim, fui eu quem apagou a luz.”"
		],
		"background": "Foi apadrinhado pelo sindicato aos doze para não virar carga de navio. Rax aceita qualquer trabalho que venha com um crachá, porque um nome impresso é a única coisa que nunca lhe pediram de volta.",
		"arc": [
			"ATO I — O ESTAGIÁRIO: chega pedindo algo que \"pareça violência elegante\" e paga com moedas contadas três vezes. Ninguém na loja ri dele, o que o deixa desconfiado.",
			"ATO II — O CRACHÁ DE PAPEL: a loja emite um crachá de freguês e ele usa nos três turnos seguintes. O sindicato pergunta onde ele arrumou emprego; ele não sabe responder, mas também não corrige.",
			"ATO III — A VAGA REPROVADA: é recusado pelo grupo de aventureiros pela quinta vez e compra mesmo assim, \"para o currículo\". Na semana seguinte volta como fornecedor credenciado da própria mentira.",
			"ATO IV — O SINDICATO: apresenta a lojista como \"minha contato no setor\" para o chefe dele, que anota o nome da loja em lugar nenhum. Pela primeira vez alguém mentiu para cima."
		],
		"farewell": [
			"“Aprendi que aqui não se rouba. Anotei no manual do estagiário, página uma.”",
			"“Crachá no bolso, meta cumprida. O seu nome está no meu plano de cinco anos.”",
			"“Passei no grupo. Recusei. Fui embora com a adaga e a minha dignidade.”",
			"“Quando eu comandar o sindicato, a senhora é a fornecedora oficial. Já avisei o espelho.”"
		]
	},
	{
		"id": "vespertino", "name": "Vespertino, Cobrador de Favores", "short": "Vespertino", "portrait": 9, "favorite": "confianca_instantanea", "faction": "submundo",
		"lines": [
			["“Boa tarde. Não vim cobrar você. Vim cobrar um cliente seu, que insiste que você garante a dívida.”",
			 "“Trabalho com favores. Não funcionam em dinheiro. Funcionam em constrangimento.”"],
			["“Seu nome apareceu em três contratos hoje. Dois são legíveis. O terceiro também é seu.”",
			 "“Aceito pagamento em ouro, joia ou simpatia. A simpatia paga melhor, dizem por aí.”"],
			["“Recomendei a loja para a casa. Agora eles cobram com educação, o que é infinitamente pior.”",
			 "“Compro confiança. Ironia à parte, é o único cliente desta cidade que paga em dia.”"],
			["“A sombra da sua loja está no meu livro de favores. No submundo, isso é quase contrato de casamento.”",
			 "“Se um dia eu precisar de álibi, você é a primeira página. Não queira saber da segunda.”"]
		],
		"request": "“Uma poção de confiança, por favor. Preciso cobrar um anjo. É meu caso mais difícil do semestre.”",
		"empty": "“Sem estoque. Terei de anotar seu nome como fiador. É meu plano B padrão, sem malícia.”",
		"tier_up": [
			"“Você paga antes de eu pedir. Raro. Comovente. Registrado em triplicata.”",
			"“Minha chefe quer conhecer você. Não é convite. É auditoria.”",
			"“Chamam sua loja de 'seguro' no submundo. Não é elogio. É política.”"
		],
		"romance": [
			"“Recebi o convite. Está em triplicata, com firma reconhecida e a data do nosso primeiro encontro.”",
			"“Cobrei a noite inteira. Na última casa, confessei que só trabalhava tanto para ter com quem voltar.”",
			"“Assinei o único contrato desta cidade sem cláusula de saída. E o meu nome está na sua página.”"
		],
		"background": "Criou a irmã dentro da tabela de dívidas da Casa e aprendeu que favor cobrado com educação dói mais que punho. Vespertino nunca quebrou um contrato — e já quebrou quatro por caridade.",
		"arc": [
			"ATO I — A COBRANÇA EDUCADA: aparece para cobrar um cliente seu e passa a tarde inteira elogiando a loja. A Casa acha que ele foi simpático; ele foi profissional.",
			"ATO II — TRÊS CONTRATOS: anota o nome da lojista em três contratos e confessa que o terceiro ilegível também é dela. Ela pede cópia. Ele já tinha trazido, em triplicata.",
			"ATO III — A AUDITORIA: a chefe manda verificar se a loja é fiador ou fachada. Vespertino aprova com um relatório de duas páginas, das quais uma é sobre o sorriso.",
			"ATO IV — SEM CLÁUSULA DE SAÍDA: registra a loja como endereço fixo no livro de favores, o que no submundo vale mais que certidão. Ninguém cobra; ninguém pode."
		],
		"farewell": [
			"“Não achei dívida nenhuma aqui. Fica a impressão de que a loja é honesta. Raro.”",
			"“Seu nome saiu em três contratos hoje. Paguei os três. Não pergunte por quê.”",
			"“Entreguei a auditoria. Deu tudo certo. Menti na carreira pela primeira vez, e foi pela senhora.”",
			"“Sem cláusula de saída. Assinei. No submundo isso tem um nome, e não é contrato.”"
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
