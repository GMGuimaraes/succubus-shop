extends RefCounted
## Idiomas: o catálogo vivo da loja. A chave de cada frase é o próprio texto em
## português usado no código, então uma língua sem tradução não quebra nada — o
## painel simplesmente continua lendo o original. É por isso que a migração pode ser
## feita em fatias: cada frase entra na tabela quando é escrita, e nada no jogo deixa
## de funcionar enquanto a tabela não tem a chave.
##
## Dois mecanismos, e os dois são medidos na sonda:
## - `register()` entrega as tabelas ao TranslationServer do motor. Rótulo e botão do
##   Godot traduzem sozinhos o texto que já está neles, então título de seção e legenda
##   de botão fixa trocam de idioma sem tocar em linha nenhuma de `main.gd`.
## - `tr()` no chamador cobre o que é montado na hora ("Ouro: %d"), porque aí o texto
##   final nunca seria achado na tabela.
##
## O idioma é preferência da pessoa, não da vida: não é apagado por reencarnar nem por
## reset de run, e é gravado em `user://locale_settings.cfg` além do save.

const SETTINGS_PATH := "user://locale_settings.cfg"
const DEFAULT: String = "pt"

## "native" é como o idioma se nomeia: no menu ele aparece sempre no próprio idioma,
## porque quem escolhe nem sempre lê o idioma atual.
const SUPPORTED: Array[Dictionary] = [
	{"id": "pt", "native": "Português", "note": "idioma original da loja"},
	{"id": "en", "native": "English", "note": "original shop language is Portuguese"},
	{"id": "es", "native": "Español", "note": "el idioma original de la tienda es el portugués"},
]

const MESSAGES: Dictionary = {
	"en": {
		# ── títulos de seção ──
		"TALENTOS": "TALENTS",
		"ESPECIALIZAÇÕES": "SPECIALIZATIONS",
		"TOPO DA FORJA": "FORGE PEAK",
		"A BANCADA DE ENSAIOS": "THE TEST BENCH",
		"OBJETIVOS DO IMPÉRIO": "EMPIRE GOALS",
		"REENCARNAÇÃO DO IMPÉRIO": "EMPIRE REINCARNATION",
		"BOLETIM DO MERCADO": "MARKET BULLETIN",
		"FILA DE ATENDIMENTO": "SERVICE QUEUE",
		"CONSERVA DA CASA E CELA": "HOUSE KEEPING AND CELL",
		"FILIAIS DA CASA": "HOUSE BRANCHES",
		"A CONCORRÊNCIA DA PRAÇA": "THE SQUARE'S COMPETITION",
		"QUADRO DE FUNCIONÁRIOS": "STAFF ROSTER",
		"O LIVRO DE FIADO": "THE CREDIT BOOK",
		"O SALÃO DAS CAPAS FINAS": "THE PARLOR OF FINE CLOAKS",
		"O LIVRO DE RECLAMAÇÕES DA RUA": "THE STREET'S COMPLAINT BOOK",
		"O CARTAZ DO COMBO": "THE COMBO SIGN",
		"A PORTA DA CASA": "THE FRONT DOOR",
		"PEDIDOS DAS FACÇÕES": "FACTION REQUESTS",
		"MERCADO DE INGREDIENTES": "INGREDIENT MARKET",
		"MÁQUINA DE CARTAS": "CARD MACHINE",
		"BALCÃO DE VENDAS": "SALES COUNTER",
		"RELÍQUIAS": "RELICS",
		"RITUAIS ATIVOS": "ACTIVE RITUALS",
		"RITUAIS": "RITUALS",
		"ROTEIROS": "SCRIPTS",
		"CADASTRO DE BATEDORES": "SCOUT ROSTER",
		"CATALISADORES RAROS": "RARE CATALYSTS",
		"DIÁRIO DE BORDO": "LOGBOOK",
		"RECEITAS OCULTAS": "HIDDEN RECIPES",
		"PLACAR DO SUBMUNDO": "UNDERWORLD LEADERBOARD",
		"ARQUIVO DE FINAIS": "ENDINGS ARCHIVE",
		"ARQUIVO DE CARDS": "CARD ARCHIVE",
		# ── rótulos do topo e abas ──
		# A aba carrega o pictograma na legenda, então a chave é a legenda inteira:
		# "Forja" sozinho nunca seria achado no botão "⚒ Forja".
		"Recepção": "Reception",
		"⚒ Forja": "⚒ Forge",
		"📚 Biblioteca": "📚 Library",
		"✦ Santuário": "✦ Sanctum",
		"🧭 Expedições": "🧭 Expeditions",
		"Ouro: 0": "Gold: 0",
		"Reputação: 0": "Reputation: 0",
		"Clientes: 0": "Customers: 0",
		"Afinidade: 0/100": "Affinity: 0/100",
		"Fúria: 0/5": "Fury: 0/5",
		"Ouro: %d": "Gold: %d",
		"Reputação: %d • %s (+%d%%)": "Reputation: %d • %s (+%d%%)",
		"No salão: %d • Fila: %d  ♥%d  ✗%d  •  Atendidos: %d": "In the shop: %d • Queue: %d  ♥%d  ✗%d  •  Served: %d",
		"Afinidade: %d/100 • Seduções: %d/%d": "Affinity: %d/100 • Seductions: %d/%d",
		"TEMPO DO MUNDO: %.1fx": "WORLD CLOCK: %.1fx",
		"Fúria: %d/5": "Fury: %d/5",
		" • FORMA DEMONÍACA": " • DEMON FORM",
		" • etiqueta -%d%%": " • price -%d%%",
		# Os títulos de fama são conteúdo de painel, e painel em duas línguas na mesma
		# frase seria pior que painel em português.
		"Desconhecida": "Unknown",
		"Boa Fama": "Good Name",
		"Loja Promissora": "Promising Shop",
		"Nome Quente": "Hot Name",
		"Lenda do Submundo": "Underworld Legend",
		# As faixas da casa são o mesmo caso dos títulos de fama: nome e presente
		# chegam montados ao painel, então a chave é a peça inteira.
		"casa em obras": "house under repair",
		"balcão arrumado": "tidied counter",
		"casa respeitada": "respectable house",
		"endereço no bairro": "an address in the neighborhood",
		"império da rua": "the street's empire",
		"o salão cru: parede sem tinta, prancha sobre cavaletes no lugar do balcão e uma lâmpada no fio": "the bare hall: unpainted wall, a plank on trestles instead of the counter and a bulb on a wire",
		"balcão de madeira entalhada, o primeiro tapete e duas prateleiras de frascos": "a carved wooden counter, the first rug and two shelves of bottles",
		"estantes de vitrine até o teto, letreiro de asas aceso e o balcão de honra": "showcase shelves to the ceiling, the lit wing sign and the counter of honour",
		"+ dourado nas molduras, lustre no teto e o sofá da frente": "+ gilded mouldings, a chandelier overhead and the sofa up front",
		"+ o teto inteiro aceso, relíquias transbordando e tapete bordado até a porta": "+ the whole ceiling lit, relics overflowing and an embroidered rug to the door",
		"A CASA ESTÁ: %s (placar %d) — %s": "THE HOUSE IS: %s (score %d) — %s",
		" Próxima faixa em %d de placar.": " Next band needs %d more score.",
		"ofício cru": "bare trade",
		"bancada arrumada": "bench tidied",
		"ofício respeitado": "trade respected",
		"casa do ofício": "the trade's house",
		"banco de mestre": "master's bench",
		"lenda do ofício": "trade legend",
		"bigorna nua, brasa apagada e o martelo pendurado na parede": "bare anvil, dead embers and the hammer on a nail",
		"o banco de trabalho montado e a primeira forma de ferro": "the workbench up and the first iron mould",
		"fole duplo, templeira acesa e a prateleira de peças prontas": "double bellows, lit quench trough and a shelf of finished pieces",
		"a forja de cúpula alta e o sino de acabamento no pátio": "the high-domed forge and the finishing bell in the yard",
		"dois aprendizes na bigorna e o rack de peças de mestre": "two apprentices on the anvil and the master-work rack",
		"+ brasa que não apaga, estandarte do ofício e a peça lendária exposta": "+ embers that never go out, the trade's banner and the legendary piece on show",
		"caixote de grimórios no chão e uma vela na leitura": "a crate of grimoires on the floor and one candle for reading",
		"as duas primeiras estantes e o banco de estudo": "the first two shelves and the study bench",
		"estantes até a metade da parede e o globo de mapas": "shelves to half the wall and the map globe",
		"a escada rolante da estante alta e a sala de cópias": "the rolling ladder up high and the copying room",
		"o teto de vitrines e o atril do grimório vivo": "the glass-case ceiling and the living grimoire's lectern",
		"+ estantes até o forro, correntes nas raridades e a luz que não se apaga": "+ shelves to the rafters, chains on the rarities and a light that stays on",
		"uma pedra no chão e tocha fumegando": "a stone on the floor and a smoking torch",
		"o altar baixo montado e as duas primeiras velas": "the low altar set and the first two candles",
		"retábulo de relíquias e a pia de purificação": "the relic reredos and the purification font",
		"as três naves de nichos e o vitral fechado": "three naves of niches and the sealed stained glass",
		"o coro de anjos pendurado e a urna de prata": "the hung angel choir and the silver urn",
		"+ relíquias transbordando, ouro no piso e a colunata acesa": "+ relics overflowing, gold in the floor and the colonnade lit",
		"A SALA ESTÁ: %s — degrau %d/%d (%s)": "THE ROOM IS: %s - step %d/%d (%s)",
		" Próxima arte da sala em %d de ofício.": " Next room art needs %d more trade.",
		"A forja tem telhado de brasa (forja no degrau 30)": "The forge has an ember roof (forge at step 30)",
		"Estante até o forro (biblioteca no degrau 30)": "Shelves to the rafters (library at step 30)",
		"Colunata acesa (santuário no degrau 30)": "The colonnade lit (sanctum at step 30)",
		"A casa virou %s: %s": "The house became %s: %s",
		# ── botões de legenda fixa ──
		"Acelerar relógio ▶": "Speed up clock ▶",
		"Exportar save": "Export save",
		"Importar save": "Import save",
		"Resetar todo o progresso…": "Reset all progress…",
		"Apagar e recomeçar": "Erase and start over",
		"Rastrear item roubado": "Track stolen item",
		"Comprar propaganda infernal": "Buy infernal advertising",
		"Contratar diabrete estagiário": "Hire intern imp",
		"Diabrete contratado ✓": "Intern hired ✓",
		"Momento especial (afinidade 5)": "Special moment (affinity 5)",
		"Resgatar contrato": "Claim contract",
		"Contrato resgatado ✓": "Contract claimed ✓",
		"Contrato em andamento": "Contract in progress",
		"Entregar etapa da encomenda": "Deliver commission stage",
		"Relembrar": "Revisit",
		"ABERTA": "OPEN",
		"PLACA COMPRADA": "SIGN BOUGHT",
		"Fechado ✓": "Closed ✓",
		"Catalisador: ARMADO": "Catalyst: ARMED",
		"Catalisador: desarmado": "Catalyst: disarmed",
		# ── menu do ESC e escolha de idioma ──
		"MENU": "MENU",
		"Continuar a loja": "Back to the shop",
		"Idioma": "Language",
		"Salvar agora": "Save now",
		"Fechar menu (ESC)": "Close menu (ESC)",
		"ESCOLHA O IDIOMA": "CHOOSE YOUR LANGUAGE",
		"O jogo abre em português, sua língua de origem. Trocar de idioma não muda nenhuma conta da loja: nem a porta, nem o bolso, nem o placar.": "The shop opens in Portuguese, its original language. Changing language never changes a single account of the shop: not the door, not the purse, not the score.",
		"Entrar na loja": "Enter the shop",
		"progresso salvo": "progress saved",
		"idioma original": "original language",
		# ── cronômetro da forja no botão do produto ──
		"⏳ Na fila": "⏳ In queue",
		"Forjando %.1fs": "Forging %.1fs",
		# ── o menu em camadas: ☰ e ESC abrem a mesma janela ──
		"Menu (ESC)": "Menu (ESC)",
		"OPÇÕES": "OPTIONS",
		"SALVAR E CARREGAR": "SAVE AND LOAD",
		"CONQUISTAS": "ACHIEVEMENTS",
		"CRÉDITOS": "CREDITS",
		"IDIOMA": "LANGUAGE",
		"O balcão continua aqui. Este é o menu da loja — o mesmo que o ESC abre.": "The counter stays right here. This is the shop menu — the same one ESC opens.",
		"⚙ Opções": "⚙ Options",
		"💾 Salvar e carregar": "💾 Save and load",
		"🏆 Conquistas (%d/%d)": "🏆 Achievements (%d/%d)",
		"✨ Créditos": "✨ Credits",
		"🌐 Idioma": "🌐 Language",
		"🐞 Relatar um problema": "🐞 Report a problem",
		# ── o guia da loja ──
		"COMO SE JOGA": "HOW TO PLAY",
		"📖 Como se joga": "📖 How to play",
		"Entendi, abrir o balcão": "Got it, open the counter",
		"Não mostrar de novo": "Don't show this again",
		"O QUE FAZER AGORA": "WHAT TO DO NOW",
		"O BALCÃO": "THE COUNTER",
		"A FORJA E A PRATELEIRA": "THE FORGE AND THE SHELF",
		"O DIA": "THE DAY",
		"A PROGRESSÃO": "PROGRESSION",
		"AS CINCO SALAS": "THE FIVE ROOMS",
		"Dois minutos de leitura e a loja deixa de ser um menu de botões.": "Two minutes of reading and the shop stops being a menu of buttons.",
		"Leia sem pressa: com o menu aberto o relógio da rua para, e nenhum freguês bate à porta enquanto você está aqui.": "Read at ease: with the menu open the street clock stops, and no customer knocks while you are here.",
		"O freguês entra sozinho, procura o que quer e paga o que está na prateleira. Seu trabalho não é clicar em ninguém: é manter a estante com o que a fama manda buscar.": "The customer walks in on their own, looks for what they want and pays for what is on the shelf. Your job is not clicking on anyone: it is keeping the shelf stocked with whatever fame sends to the door.",
		"Um tique do mundo a cada três segundos, e o balcão atende uma visita por tique. As outras esperam na linha do tapete; quem passa da própria paciência vai embora, e a fama paga a conta da fila.": "One tick of the world every three seconds, and the counter serves one visitor per tick. The rest wait on the doormat; whoever outlasts their own patience walks away, and reputation pays for the queue.",
		"O botão Vender do balcão tira a peça do estoque por 70% do preço de tabela. É dinheiro rápido sem freguês: serve para o dia apertado, não para a vida da casa.": "The counter's Sell button takes a piece off the stock for 70% of list price. It is quick money without a customer: good for a tight day, not for the life of the shop.",
		"Compre ingrediente no mercado, fabrique a peça e espere o cronômetro. São até três peças ao mesmo tempo na forja.": "Buy ingredients at the market, craft the piece and wait for the timer. The forge holds up to three pieces at once.",
		"Qualidade é o que decide o preço: ela sobe com o nível, com o dote de alquimia e com o catalisador queimado dentro da forma.": "Quality is what sets the price: it rises with level, with the alchemy talent and with the catalyst burned inside the mould.",
		"Estoque tem prazo. Peça parada desce de degrau e, vencida, sai pela porta — a conserva e o depósito de sal existem para comprar tempo.": "Stock has an expiry date. A resting piece drops a grade and, once spoiled, leaves through the door — preserves and the salt cellar exist to buy time.",
		"Vinte tiques viram o dia. Na virada a casa cobra a conta, as filiais pagam ou devem, o fiado corre juros e o combo do dia recomeça.": "Twenty ticks turn the day. At the turn the house pays its bill, branches pay or owe, credit accrues interest and the day's combo restarts.",
		"O balanço fecha a conta e o placar guarda o melhor dia que a loja já teve.": "The balance closes the books and the scoreboard keeps the best day the shop ever had.",
		"Sem você a loja trabalha até doze horas: o que passar disso fica para a próxima visita.": "Without you the shop works for up to twelve hours: anything past that waits for the next visit.",
		"Venda, contrato do dia, pedido pessoal e capítulo dão experiência. Cada nível paga ouro, fama e um ponto de talento.": "Sales, the daily contract, personal requests and chapters give experience. Each level pays gold, fame and one talent point.",
		"O ponto de talento espera na Biblioteca, nas trilhas de alquimia, comércio, charme, logística e administração da casa. No degrau 4 cada trilha faz a loja assinar um ofício e raspar o outro até a próxima vida.": "The talent point waits in the Library, in the alchemy, trade, charm, logistics and house-management tracks. At rung 4 each track makes the shop sign one craft and scratch the other until the next life.",
		"Conquista paga ouro, fama e um pacote de cartas, e carta boa é bônus no balcão, não enfeite de colecionador.": "Achievements pay gold, fame and a sealed pack of cards, and a good card is a bonus at the counter, not a collector's ornament.",
		"Fechar o império troca de vida: caixa, prateleira e campanha voltam ao zero e ficam a aura, os dotes, os vínculos e o que as facções já sabem de você.": "Closing the empire swaps lives: cash, shelf and campaign return to zero, and what stays is the aura, the perks, the bonds and what the factions already know about you.",
		"Recepção: a campanha, a fila, a conta da casa, a conservação, as filiais, a concorrência da praça, o livro de fiado e o VIP.": "Reception: the campaign, the queue, the house bill, upkeep, branches, the square's competition, the credit book and the VIP.",
		"Forja: as receitas, o mercado de ingredientes, o topo da forja e a bancada de ensaios.": "Forge: recipes, the ingredient market, the forge peak and the test bench.",
		"Biblioteca: o nível, os talentos, as especializações e a leitura que adianta uma receita presa ao nível.": "Library: level, talents, specializations and the reading that unlocks a recipe still tied to level.",
		"Santuário: os rituais, as relíquias, as bênçãos e a cela que rende para a forja.": "Sanctum: rituals, relics, blessings and the cell that feeds the forge.",
		"Expedição: a estrada, os batedores e o ingrediente que a praça não vende.": "Expedition: the road, the scouts and the ingredient the square does not sell.",
		"Comece pela Forja: fabrique uma peça já liberada. Sem estoque no balcão, a fila olha para a prateleira vazia e vai embora.": "Start at the Forge: craft a piece already unlocked. With no stock at the counter, the queue looks at the empty shelf and leaves.",
		"A forja já trabalha: espere o cronômetro e a prateleira enche sozinha.": "The forge is already working: wait for the timer and the shelf fills itself.",
		"Pouca peça na estante e forja parada: fabrique antes de a fila crescer.": "Few pieces on the shelf and the forge idle: craft before the queue grows.",
		"Há %d ponto(s) de talento parado(s) na gaveta. Gaste na Biblioteca — talento não gasto é loja parada.": "There are %d idle talent point(s) in the drawer. Spend them in the Library — an unspent talent is a stalled shop.",
		"Aguarde a primeira virada do dia: é nela que a casa cobra conta, o fiado corre juros e o contrato do dia paga.": "Wait for the first turn of the day: that is when the house charges its bill, credit accrues interest and the day's contract pays out.",
		"A casa está redonda: o balcão corre sozinho e o seu trabalho agora é escolher para onde vai o ouro.": "The house is in good shape: the counter runs itself and your job now is choosing where the gold goes.",
		"Primeiro dia na loja: o balcão vende sozinho o que está na prateleira. O guia explica o resto em dois minutos.": "First day in the shop: the counter sells on its own whatever is on the shelf. The guide explains the rest in two minutes.",
		"← Voltar ao menu": "← Back to menu",
		"Volume: %d%%": "Volume: %d%%",
		"🔇 Som: DESLIGADO": "🔇 Sound: OFF",
		"🔊 Som: LIGADO": "🔊 Sound: ON",
		"Ocultar o painel da loja": "Hide the shop panel",
		"Mostrar o painel da loja": "Show the shop panel",
		"Balanço do dia: automático": "Daily report: automatic",
		"Balanço do dia: pede OK": "Daily report: asks for OK",
		"Tela: Janela": "Window: Windowed",
		"Tela: Maximizada": "Window: Maximized",
		"Tela: Tela cheia": "Window: Fullscreen",
		"Escala da interface: %d%%": "Interface scale: %d%%",
		"Sincronismo vertical: Ligado": "VSync: On",
		"Sincronismo vertical: Adaptativo": "VSync: Adaptive",
		"Sincronismo vertical: Desligado": "VSync: Off",
		"Nada aqui é conta da loja: som, tela e o tom das cenas são preferência de quem joga. Dotes, servos e o resto da administração ficam na Biblioteca e no Santuário.": "Nothing here is a shop account: sound, window and the tone of the scenes are the player's own preference. Dowries, servants and the rest of the administration stay in the Library and the Sanctum.",
		"🔥 Cenas sensuais: LIBERADAS": "🔥 Sensual scenes: ALLOWED",
		"🌸 Cenas sensuais: CONTIDAS": "🌸 Sensual scenes: MODEST",
		"Exportar save para arquivo": "Export save to a file",
		"Importar save de arquivo": "Import save from a file",
		"Carregar o último save do disco": "Load the last save from disk",
		"Apagar todo o progresso": "Erase all progress",
		"Save da vida: dia %d, nível %d, %d de ouro.": "Life save: day %d, level %d, %d gold.",
		"Importar e apagar reabrem a loja: nada é escrito sem a janela de confirmação aparecer antes.": "Importing and erasing reopen the shop: nothing is written before the confirmation window appears.",
		"Desbloqueadas: %d de %d.": "Unlocked: %d of %d.",
		"✓ %s  (+%d ouro, +%d fama)": "✓ %s  (+%d gold, +%d fame)",
		"Nenhuma ainda. A primeira chega com o primeiro atendimento do dia.": "None yet. The first one arrives with the first customer of the day.",
		"Trancadas neste balcão: %d — os nomes ficam escondidos para não estragar a surpresa.": "Still locked at this counter: %d — the names stay hidden so they don't spoil the surprise.",
		"Concepção, código, escrita e arte: GMGuimaraes.": "Concept, code, writing and art: GMGuimaraes.",
		"Motor: Godot %s (gl_compatibility).": "Engine: Godot %s (gl_compatibility).",
		"Trilha e efeitos gravados no próprio projeto; retratos e poses desenhados para a loja, sem arte explícita.": "Soundtrack and effects recorded inside the project; portraits and poses drawn for the shop, with no explicit art.",
		"As IAs que revisaram este repositório no mesmo ritmo das madrugadas: Claude, ChatGPT, Copilot e Manus.": "The AIs that reviewed this repository at the same pace as the late nights: Claude, ChatGPT, Copilot and Manus.",
		"Obrigado por jogar — e por relatar o que quebrou.": "Thanks for playing — and for reporting what broke.",
		"A prosa montada durante a partida — falas de cliente, balanço da virada, eventos — ainda sai no idioma original.": "Prose assembled during the run — customer lines, the turnover report, events — still comes out in the original language.",
	},
	"es": {
		# ── títulos de sección ──
		"TALENTOS": "TAENTOS",
		"ESPECIALIZAÇÕES": "ESPECIALIZACIONES",
		"TOPO DA FORJA": "CUMBRE DE LA FORJA",
		"A BANCADA DE ENSAIOS": "LA BANCADA DE ENSAYOS",
		"OBJETIVOS DO IMPÉRIO": "OBJETIVOS DEL IMPERIO",
		"REENCARNAÇÃO DO IMPÉRIO": "REENCARNACIÓN DEL IMPERIO",
		"BOLETIM DO MERCADO": "BOLETÍN DEL MERCADO",
		"FILA DE ATENDIMENTO": "FILA DE ATENCIÓN",
		"CONSERVA DA CASA E CELA": "CUSTODIA DE LA CASA Y CELDA",
		"FILIAIS DA CASA": "SUCURSALES DE LA CASA",
		"A CONCORRÊNCIA DA PRAÇA": "LA COMPETENCIA DE LA PLAZA",
		"QUADRO DE FUNCIONÁRIOS": "PLANTILLA DE EMPLEADOS",
		"O LIVRO DE FIADO": "EL LIBRO DE FIAS",
		"O SALÃO DAS CAPAS FINAS": "EL SALÓN DE LAS CAPAS FINAS",
		"O LIVRO DE RECLAMAÇÕES DA RUA": "EL LIBRO DE RECLAMACIONES DE LA CALLE",
		"O CARTAZ DO COMBO": "EL CARTEL DEL COMBO",
		"A PORTA DA CASA": "LA PUERTA DE LA CASA",
		"PEDIDOS DAS FACÇÕES": "ENCARGOS DE LAS FACCIÓNES",
		"MERCADO DE INGREDIENTES": "MERCADO DE INGREDIENTES",
		"MÁQUINA DE CARTAS": "MÁQUINA DE CARTAS",
		"BALCÃO DE VENDAS": "MOSTRADOR DE VENTAS",
		"RELÍQUIAS": "RELIQUIAS",
		"RITUAIS ATIVOS": "RITUALES ACTIVOS",
		"RITUAIS": "RITUALES",
		"ROTEIROS": "GUIONES",
		"CADASTRO DE BATEDORES": "REGISTRO DE EXPLORADORES",
		"CATALISADORES RAROS": "CATALIZADORES RAROS",
		"DIÁRIO DE BORDO": "DIARIO DE A BORDO",
		"RECEITAS OCULTAS": "RECETAS OCULTAS",
		"PLACAR DO SUBMUNDO": "MARCADOR DEL INFRAMUNDO",
		"ARQUIVO DE FINAIS": "ARCHIVO DE FINALES",
		"ARQUIVO DE CARDS": "ARCHIVO DE CARTAS",
		# ── rótulos superiores y pestañas ──
		"Recepção": "Recepción",
		"⚒ Forja": "⚒ Forja",
		"📚 Biblioteca": "📚 Biblioteca",
		"✦ Santuário": "✦ Santuario",
		"🧭 Expedições": "🧭 Expediciones",
		"Ouro: 0": "Oro: 0",
		"Reputação: 0": "Reputación: 0",
		"Clientes: 0": "Clientes: 0",
		"Afinidade: 0/100": "Afinidad: 0/100",
		"Fúria: 0/5": "Ira: 0/5",
		"Ouro: %d": "Oro: %d",
		"Reputação: %d • %s (+%d%%)": "Reputación: %d • %s (+%d%%)",
		"No salão: %d • Fila: %d  ♥%d  ✗%d  •  Atendidos: %d": "En el salón: %d • Cola: %d  ♥%d  ✗%d  •  Atendidos: %d",
		"Afinidade: %d/100 • Seduções: %d/%d": "Afinidad: %d/100 • Seducciones: %d/%d",
		"TEMPO DO MUNDO: %.1fx": "RELOJ DEL MUNDO: %.1fx",
		"Fúria: %d/5": "Ira: %d/5",
		" • FORMA DEMONÍACA": " • FORMA DEMONÍACA",
		" • etiqueta -%d%%": " • etiqueta -%d%%",
		"Desconhecida": "Desconocida",
		"Boa Fama": "Buena Fama",
		"Loja Promissora": "Tienda Prometedora",
		"Nome Quente": "Nombre Candente",
		"Lenda do Submundo": "Leyenda del Inframundo",
		# Las franjas de la casa son el mismo caso que los títulos de fama: nombre y
		# detalle llegan montados al panel, así que la clave es la frase entera.
		"casa em obras": "casa en obras",
		"balcão arrumado": "mostrador arreglado",
		"casa respeitada": "casa respetable",
		"endereço no bairro": "una dirección en el barrio",
		"império da rua": "imperio de la calle",
		"o salão cru: parede sem tinta, prancha sobre cavaletes no lugar do balcão e uma lâmpada no fio": "el salón crudo: pared sin pintar, un tablón sobre caballetes en lugar del mostrador y una bombilla en el cable",
		"balcão de madeira entalhada, o primeiro tapete e duas prateleiras de frascos": "mostrador de madera tallada, la primera alfombra y dos estantes de frascos",
		"estantes de vitrine até o teto, letreiro de asas aceso e o balcão de honra": "estantes de vitrina hasta el techo, letrero de alas encendido y el mostrador de honor",
		"+ dourado nas molduras, lustre no teto e o sofá da frente": "+ dorado en las molduras, lámpara de techo y el sofá del frente",
		"+ o teto inteiro aceso, relíquias transbordando e tapete bordado até a porta": "+ el techo entero encendido, reliquias desbordando y alfombra bordada hasta la puerta",
		"A CASA ESTÁ: %s (placar %d) — %s": "LA CASA ES: %s (puntos %d) — %s",
		" Próxima faixa em %d de placar.": " Próximo tramo en %d puntos.",
		"ofício cru": "oficio en bruto",
		"bancada arrumada": "banco ordenado",
		"ofício respeitado": "oficio respetado",
		"casa do ofício": "la casa del oficio",
		"banco de mestre": "banco de maestro",
		"lenda do ofício": "leyenda del oficio",
		"bigorna nua, brasa apagada e o martelo pendurado na parede": "yunque desnudo, brasas apagadas y el mazo colgado en la pared",
		"o banco de trabalho montado e a primeira forma de ferro": "el banco de trabajo montado y el primer molde de hierro",
		"fole duplo, templeira acesa e a prateleira de peças prontas": "fuelle doble, temple encendido y la estantería de piezas listas",
		"a forja de cúpula alta e o sino de acabamento no pátio": "la forja de cúpula alta y la campana de acabado en el patio",
		"dois aprendizes na bigorna e o rack de peças de mestre": "dos aprendices en el yunque y el estante de piezas de maestro",
		"+ brasa que não apaga, estandarte do ofício e a peça lendária exposta": "+ brasas que no se apagan, estandarte del oficio y pieza legendaria expuesta",
		"caixote de grimórios no chão e uma vela na leitura": "una caja de grimorios en el suelo y una vela para leer",
		"as duas primeiras estantes e o banco de estudo": "las dos primeras estanterías y el banco de estudio",
		"estantes até a metade da parede e o globo de mapas": "estanterías hasta media pared y el globo de mapas",
		"a escada rolante da estante alta e a sala de cópias": "la escalera móvil de la estantería alta y la sala de copias",
		"o teto de vitrines e o atril do grimório vivo": "el techo de vitrinas y el atril del grimorio vivo",
		"+ estantes até o forro, correntes nas raridades e a luz que não se apaga": "+ estanterías hasta el techo, cadenas en las rarezas y la luz que no se apaga",
		"uma pedra no chão e tocha fumegando": "una piedra en el suelo y una antorcha humeante",
		"o altar baixo montado e as duas primeiras velas": "el altar bajo montado y las dos primeras velas",
		"retábulo de relíquias e a pia de purificação": "el retablo de reliquias y la pila de purificacion",
		"as três naves de nichos e o vitral fechado": "las tres naves de nichos y la vidriera cerrada",
		"o coro de anjos pendurado e a urna de prata": "el coro de ángeles colgado y la urna de plata",
		"+ relíquias transbordando, ouro no piso e a colunata acesa": "+ reliquias desbordando, oro en el suelo y la columnata encendida",
		"A SALA ESTÁ: %s — degrau %d/%d (%s)": "LA SALA ESTA: %s - escalon %d/%d (%s)",
		" Próxima arte da sala em %d de ofício.": " Proxima arte de la sala en %d de oficio.",
		"A forja tem telhado de brasa (forja no degrau 30)": "La forja tiene techo de brasas (forja en el escalon 30)",
		"Estante até o forro (biblioteca no degrau 30)": "Estanteria hasta el techo (biblioteca en el escalon 30)",
		"Colunata acesa (santuário no degrau 30)": "Columnata encendida (santuario en el escalon 30)",
		"A casa virou %s: %s": "La casa se volvió %s: %s",
		# ── botones de rótulo fijo ──
		"Acelerar relógio ▶": "Acelerar reloj ▶",
		"Exportar save": "Exportar partida",
		"Importar save": "Importar partida",
		"Resetar todo o progresso…": "Reiniciar todo el progreso…",
		"Apagar e recomeçar": "Borrar y empezar",
		"Rastrear item roubado": "Rastrear objeto robado",
		"Comprar propaganda infernal": "Comprar propaganda infernal",
		"Contratar diabrete estagiário": "Contratar diablillo becario",
		"Diabrete contratado ✓": "Diablillo contratado ✓",
		"Momento especial (afinidade 5)": "Momento especial (afinidad 5)",
		"Resgatar contrato": "Rescatar contrato",
		"Contrato resgatado ✓": "Contrato rescatado ✓",
		"Contrato em andamento": "Contrato en curso",
		"Entregar etapa da encomenda": "Entregar etapa del pedido",
		"Relembrar": "Revivir",
		"ABERTA": "ABIERTA",
		"PLACA COMPRADA": "LETRERO COMPRADO",
		"Fechado ✓": "Cerrado ✓",
		"Catalisador: ARMADO": "Catalizador: ARMADO",
		"Catalisador: desarmado": "Catalizador: desarmado",
		# ── menú de ESC y elección de idioma ──
		"MENU": "MENÚ",
		"Continuar a loja": "Volver a la tienda",
		"Idioma": "Idioma",
		"Salvar agora": "Guardar ahora",
		"Fechar menu (ESC)": "Cerrar menú (ESC)",
		"ESCOLHA O IDIOMA": "ELIGE TU IDIOMA",
		"O jogo abre em português, sua língua de origem. Trocar de idioma não muda nenhuma conta da loja: nem a porta, nem o bolso, nem o placar.": "La tienda abre en portugués, su idioma original. Cambiar de idioma no cambia ninguna cuenta de la tienda: ni la puerta, ni el bolsillo, ni el marcador.",
		"Entrar na loja": "Entrar en la tienda",
		"progresso salvo": "progreso guardado",
		"idioma original": "idioma original",
		# ── cronómetro de la forja en el botón del producto ──
		"⏳ Na fila": "⏳ En cola",
		"Forjando %.1fs": "Forjando %.1fs",
		# ── el menú en capas: ☰ y ESC abren la misma ventana ──
		"Menu (ESC)": "Menú (ESC)",
		"OPÇÕES": "OPCIONES",
		"SALVAR E CARREGAR": "GUARDAR Y CARGAR",
		"CONQUISTAS": "LOGROS",
		"CRÉDITOS": "CRÉDITOS",
		"IDIOMA": "IDIOMA",
		"O balcão continua aqui. Este é o menu da loja — o mesmo que o ESC abre.": "El mostrador sigue aquí. Este es el menú de la tienda — el mismo que abre ESC.",
		"⚙ Opções": "⚙ Opciones",
		"💾 Salvar e carregar": "💾 Guardar y cargar",
		"🏆 Conquistas (%d/%d)": "🏆 Logros (%d/%d)",
		"✨ Créditos": "✨ Créditos",
		"🌐 Idioma": "🌐 Idioma",
		"🐞 Relatar um problema": "🐞 Reportar un problema",
		# ── la guía de la tienda ──
		"COMO SE JOGA": "CÓMO SE JUEGA",
		"📖 Como se joga": "📖 Cómo se juega",
		"Entendi, abrir o balcão": "Entendido, abrir el mostrador",
		"Não mostrar de novo": "No mostrar de nuevo",
		"O QUE FAZER AGORA": "QUÉ HACER AHORA",
		"O BALCÃO": "EL MOSTRADOR",
		"A FORJA E A PRATELEIRA": "LA FORJA Y LA ESTANTERÍA",
		"O DIA": "EL DÍA",
		"A PROGRESSÃO": "LA PROGRESIÓN",
		"AS CINCO SALAS": "LAS CINCO SALAS",
		"Dois minutos de leitura e a loja deixa de ser um menu de botões.": "Dos minutos de lectura y la tienda deja de ser un menú de botones.",
		"Leia sem pressa: com o menu aberto o relógio da rua para, e nenhum freguês bate à porta enquanto você está aqui.": "Lea sin prisa: con el menú abierto el reloj de la calle se detiene, y ningún cliente llama a la puerta mientras usted está aquí.",
		"O freguês entra sozinho, procura o que quer e paga o que está na prateleira. Seu trabalho não é clicar em ninguém: é manter a estante com o que a fama manda buscar.": "El cliente entra solo, busca lo que quiere y paga lo que hay en la estantería. Su trabajo no es hacer clic a nadie: es mantener la estantería con lo que la fama manda buscar.",
		"Um tique do mundo a cada três segundos, e o balcão atende uma visita por tique. As outras esperam na linha do tapete; quem passa da própria paciência vai embora, e a fama paga a conta da fila.": "Un tick del mundo cada tres segundos, y el mostrador atiende una visita por tick. Las demás esperan en la línea del felpudo; quien supera su propia paciencia se marcha, y la fama paga la cuenta de la fila.",
		"O botão Vender do balcão tira a peça do estoque por 70% do preço de tabela. É dinheiro rápido sem freguês: serve para o dia apertado, não para a vida da casa.": "El botón Vender del mostrador saca la pieza del stock por el 70% del precio de tabla. Es dinero rápido sin cliente: sirve para el día apurado, no para la vida de la casa.",
		"Compre ingrediente no mercado, fabrique a peça e espere o cronômetro. São até três peças ao mesmo tempo na forja.": "Compre ingredientes en el mercado, fabrique la pieza y espere el cronómetro. Hay hasta tres piezas a la vez en la forja.",
		"Qualidade é o que decide o preço: ela sobe com o nível, com o dote de alquimia e com o catalisador queimado dentro da forma.": "La calidad decide el precio: sube con el nivel, con el don de alquimia y con el catalizador quemado dentro del molde.",
		"Estoque tem prazo. Peça parada desce de degrau e, vencida, sai pela porta — a conserva e o depósito de sal existem para comprar tempo.": "El stock caduca. La pieza parada baja de escalón y, vencida, sale por la puerta — las conservas y el depósito de sal existen para comprar tiempo.",
		"Vinte tiques viram o dia. Na virada a casa cobra a conta, as filiais pagam ou devem, o fiado corre juros e o combo do dia recomeça.": "Veinte ticks voltean el día. En la vuelta la casa cobra la cuenta, las sucursales pagan o deben, el fiado corre intereses y el combo del día recomienza.",
		"O balanço fecha a conta e o placar guarda o melhor dia que a loja já teve.": "El balance cierra la cuenta y el marcador guarda el mejor día que la tienda ha tenido.",
		"Sem você a loja trabalha até doze horas: o que passar disso fica para a próxima visita.": "Sin usted la tienda trabaja hasta doce horas: lo que pase de eso queda para la próxima visita.",
		"Venda, contrato do dia, pedido pessoal e capítulo dão experiência. Cada nível paga ouro, fama e um ponto de talento.": "La venta, el contrato del día, el pedido personal y el capítulo dan experiencia. Cada nivel paga oro, fama y un punto de talento.",
		"O ponto de talento espera na Biblioteca, nas trilhas de alquimia, comércio, charme, logística e administração da casa. No degrau 4 cada trilha faz a loja assinar um ofício e raspar o outro até a próxima vida.": "El punto de talento espera en la Biblioteca, en las sendas de alquimia, comercio, encanto, logística y administración de la casa. En el escalón 4 cada senda hace que la tienda firme un oficio y borre el otro hasta la próxima vida.",
		"Conquista paga ouro, fama e um pacote de cartas, e carta boa é bônus no balcão, não enfeite de colecionador.": "El logro paga oro, fama y un paquete de cartas, y una buena carta es bonus en el mostrador, no adorno de coleccionista.",
		"Fechar o império troca de vida: caixa, prateleira e campanha voltam ao zero e ficam a aura, os dotes, os vínculos e o que as facções já sabem de você.": "Cerrar el imperio cambia de vida: caja, estantería y campaña vuelven a cero, y se quedan el aura, los dotes, los vínculos y lo que las facciones ya saben de usted.",
		"Recepção: a campanha, a fila, a conta da casa, a conservação, as filiais, a concorrência da praça, o livro de fiado e o VIP.": "Recepción: la campaña, la fila, la cuenta de la casa, la conservación, las sucursales, la competencia de la plaza, el libro de fiado y el VIP.",
		"Forja: as receitas, o mercado de ingredientes, o topo da forja e a bancada de ensaios.": "Forja: las recetas, el mercado de ingredientes, la cima de la forja y el banco de ensayos.",
		"Biblioteca: o nível, os talentos, as especializações e a leitura que adianta uma receita presa ao nível.": "Biblioteca: el nivel, los talentos, las especializaciones y la lectura que adelanta una receta atada al nivel.",
		"Santuário: os rituais, as relíquias, as bênçãos e a cela que rende para a forja.": "Santuario: los rituales, las reliquias, las bendiciones y la celda que rinde para la forja.",
		"Expedição: a estrada, os batedores e o ingrediente que a praça não vende.": "Expedición: el camino, los exploradores y el ingrediente que la plaza no vende.",
		"Comece pela Forja: fabrique uma peça já liberada. Sem estoque no balcão, a fila olha para a prateleira vazia e vai embora.": "Empiece por la Forja: fabrique una pieza ya liberada. Sin stock en el mostrador, la fila mira la estantería vacía y se marcha.",
		"A forja já trabalha: espere o cronômetro e a prateleira enche sozinha.": "La forja ya trabaja: espere el cronómetro y la estantería se llena sola.",
		"Pouca peça na estante e forja parada: fabrique antes de a fila crescer.": "Pocas piezas en la estantería y la forja parada: fabrique antes de que la fila crezca.",
		"Há %d ponto(s) de talento parado(s) na gaveta. Gaste na Biblioteca — talento não gasto é loja parada.": "Hay %d punto(s) de talento parado(s) en el cajón. Gástelo(s) en la Biblioteca — talento sin gastar es tienda parada.",
		"Aguarde a primeira virada do dia: é nela que a casa cobra conta, o fiado corre juros e o contrato do dia paga.": "Espere la primera vuelta del día: es en ella cuando la casa cobra cuenta, el fiado corre intereses y el contrato del día paga.",
		"A casa está redonda: o balcão corre sozinho e o seu trabalho agora é escolher para onde vai o ouro.": "La casa está redonda: el mostrador corre solo y su trabajo ahora es elegir a dónde va el oro.",
		"Primeiro dia na loja: o balcão vende sozinho o que está na prateleira. O guia explica o resto em dois minutos.": "Primer día en la tienda: el mostrador vende solo lo que hay en la estantería. La guía explica el resto en dos minutos.",
		"← Voltar ao menu": "← Volver al menú",
		"Volume: %d%%": "Volumen: %d%%",
		"🔇 Som: DESLIGADO": "🔇 Sonido: APAGADO",
		"🔊 Som: LIGADO": "🔊 Sonido: ENCENDIDO",
		"Ocultar o painel da loja": "Ocultar el panel de la tienda",
		"Mostrar o painel da loja": "Mostrar el panel de la tienda",
		"Balanço do dia: automático": "Balance del día: automático",
		"Balanço do dia: pede OK": "Balance del día: pide OK",
		"Tela: Janela": "Pantalla: Ventana",
		"Tela: Maximizada": "Pantalla: Maximizada",
		"Tela: Tela cheia": "Pantalla: Pantalla completa",
		"Escala da interface: %d%%": "Escala de la interfaz: %d%%",
		"Sincronismo vertical: Ligado": "Sincronización vertical: Activada",
		"Sincronismo vertical: Adaptativo": "Sincronización vertical: Adaptativa",
		"Sincronismo vertical: Desligado": "Sincronización vertical: Desactivada",
		"Nada aqui é conta da loja: som, tela e o tom das cenas são preferência de quem joga. Dotes, servos e o resto da administração ficam na Biblioteca e no Santuário.": "Nada de aquí es cuenta de la tienda: sonido, ventana y el tono de las escenas son preferencia de quien juega. Los dotes, los sirvientes y el resto de la administración se quedan en la Biblioteca y el Santuario.",
		"🔥 Cenas sensuais: LIBERADAS": "🔥 Escenas sensuales: PERMITIDAS",
		"🌸 Cenas sensuais: CONTIDAS": "🌸 Escenas sensuales: PUDOROSAS",
		"Exportar save para arquivo": "Exportar la partida a un archivo",
		"Importar save de arquivo": "Importar la partida de un archivo",
		"Carregar o último save do disco": "Cargar la última partida del disco",
		"Apagar todo o progresso": "Borrar todo el progreso",
		"Save da vida: dia %d, nível %d, %d de ouro.": "Partida de la vida: día %d, nivel %d, %d de oro.",
		"Importar e apagar reabrem a loja: nada é escrito sem a janela de confirmação aparecer antes.": "Importar y borrar vuelven a abrir la tienda: nada se escribe antes de que aparezca la ventana de confirmación.",
		"Desbloqueadas: %d de %d.": "Desbloqueados: %d de %d.",
		"✓ %s  (+%d ouro, +%d fama)": "✓ %s  (+%d oro, +%d fama)",
		"Nenhuma ainda. A primeira chega com o primeiro atendimento do dia.": "Ninguno todavía. El primero llega con la primera atención del día.",
		"Trancadas neste balcão: %d — os nomes ficam escondidos para não estragar a surpresa.": "Cerrados en este mostrador: %d — los nombres se esconden para no arruinar la sorpresa.",
		"Concepção, código, escrita e arte: GMGuimaraes.": "Concepto, código, escritura y arte: GMGuimaraes.",
		"Motor: Godot %s (gl_compatibility).": "Motor: Godot %s (gl_compatibility).",
		"Trilha e efeitos gravados no próprio projeto; retratos e poses desenhados para a loja, sem arte explícita.": "Banda sonora y efectos grabados en el propio proyecto; retratos y poses dibujados para la tienda, sin arte explícita.",
		"As IAs que revisaram este repositório no mesmo ritmo das madrugadas: Claude, ChatGPT, Copilot e Manus.": "Las IAs que revisaron este repositorio al mismo ritmo que las madrugadas: Claude, ChatGPT, Copilot y Manus.",
		"Obrigado por jogar — e por relatar o que quebrou.": "Gracias por jugar — y por reportar lo que se rompió.",
		"A prosa montada durante a partida — falas de cliente, balanço da virada, eventos — ainda sai no idioma original.": "La prosa armada durante la partida — frases de cliente, balance del cambio de día, eventos — todavía sale en el idioma original.",
	},
}

static func knows(id: String) -> bool:
	for supported in SUPPORTED:
		if str(supported["id"]) == id:
			return true
	return false

static func display_name(id: String) -> String:
	for supported in SUPPORTED:
		if str(supported["id"]) == id:
			return str(supported["native"])
	return id

static func note_for(id: String) -> String:
	for supported in SUPPORTED:
		if str(supported["id"]) == id:
			return str(supported["note"])
	return ""

## Quantas frases cada idioma já tem, contra a maior tabela do catálogo. É o número que
## o menu mostra: catálogo pela metade é honesto, catálogo silencioso não. O idioma
## original devolve vazio — quem escreve a frase não precisa de contador dela.
static func coverage(id: String) -> String:
	if id == DEFAULT:
		return ""
	var maior := 0
	for locale_id in MESSAGES.keys():
		maior = maxi(maior, (MESSAGES[str(locale_id)] as Dictionary).size())
	return "%d/%d" % [(MESSAGES.get(id, {}) as Dictionary).size(), maior]

## Carga todas as tabelas no TranslationServer do motor. Rótulo e botão do Godot
## traduzem o texto que já carregam, então esta chamada sozinha troca o idioma de tudo
## que é literal fixo — sem reescrever nenhum `.text =` do jogo.
##
## O idioma original entra no motor com uma tabela identidade, e isso não é excesso: o
## Godot escolhe o "melhor ajuste" entre as traduções registradas e, se o português não
## estiver lá, a única tabela viva (inglês) ganha de qualquer locale pedido — a loja
## trocaria para português e continuaria lendo inglês.
static func register() -> void:
	var sources := _sources()
	for id in _locale_ids():
		var existing := _find_existing(str(id))
		if existing != null:
			TranslationServer.remove_translation(existing)
		var translation := Translation.new()
		translation.locale = str(id)
		if str(id) == DEFAULT:
			for source in sources:
				translation.add_message(source, source)
		else:
			for source in (MESSAGES[str(id)] as Dictionary).keys():
				translation.add_message(str(source), str((MESSAGES[str(id)] as Dictionary)[source]))
		TranslationServer.add_translation(translation)

static func _locale_ids() -> Array[String]:
	var ids: Array[String] = [DEFAULT]
	for locale_id in MESSAGES.keys():
		ids.append(str(locale_id))
	return ids

## Toda frase que existe em alguma tabela: é o estoque da tabela identidade do original.
static func _sources() -> Array[String]:
	var seen := {}
	for locale_id in MESSAGES.keys():
		for source in (MESSAGES[str(locale_id)] as Dictionary).keys():
			seen[str(source)] = true
	var list: Array[String] = []
	for source in seen.keys():
		list.append(str(source))
	return list

static func _find_existing(locale_id: String) -> Translation:
	for current in TranslationServer.get_translations():
		var translation := current as Translation
		if translation != null and str(translation.locale) == locale_id:
			return translation
	return null
