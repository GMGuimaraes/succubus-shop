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
		"o salão em obras: poeira no ar, massa crua na parede, lona no piso e uma lâmpada no fio": "the hall under repair: dust in the air, raw plaster on the wall, drop cloth on the floor and a bulb on a wire",
		"piso encerado e tapete realçado na faixa de passeio": "waxed floor and the rug picked out along the walk band",
		"+ cordão de velas acesas nas paredes do salão": "+ a string of lit candles along the hall walls",
		"+ caixilho dourado na moldura da tela": "+ a gilded frame on the painting",
		"+ lustre aceso no teto e poeira dourada no ar": "+ a lit chandelier overhead and golden dust in the air",
		"A CASA ESTÁ: %s (placar %d) — %s": "THE HOUSE IS: %s (score %d) — %s",
		" Próxima faixa em %d de placar.": " Next band needs %d more score.",
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
		"o salão em obras: poeira no ar, massa crua na parede, lona no piso e uma lâmpada no fio": "el salón en obras: polvo en el aire, yeso crudo en la pared, lona en el suelo y una bombilla en el cable",
		"piso encerado e tapete realçado na faixa de passeio": "suelo encerado y alfombra resaltada en la franja de paso",
		"+ cordão de velas acesas nas paredes do salão": "+ cordón de velas encendidas en las paredes del salón",
		"+ caixilho dourado na moldura da tela": "+ marco dorado en la moldura del cuadro",
		"+ lustre aceso no teto e poeira dourada no ar": "+ lámpara de techo encendida y polvo dorado en el aire",
		"A CASA ESTÁ: %s (placar %d) — %s": "LA CASA ES: %s (puntos %d) — %s",
		" Próxima faixa em %d de placar.": " Próximo tramo en %d puntos.",
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
