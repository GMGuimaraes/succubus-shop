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
		"OBJETIVOS DO IMPÉRIO": "EMPIRE GOALS",
		"REENCARNAÇÃO DO IMPÉRIO": "EMPIRE REINCARNATION",
		"BOLETIM DO MERCADO": "MARKET BULLETIN",
		"FILA DE ATENDIMENTO": "SERVICE QUEUE",
		"CONSERVA DA CASA E CELA": "HOUSE KEEPING AND CELL",
		"FILIAIS DA CASA": "HOUSE BRANCHES",
		"A CONCORRÊNCIA DA PRAÇA": "THE SQUARE'S COMPETITION",
		"QUADRO DE FUNCIONÁRIOS": "STAFF ROSTER",
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
	},
	"es": {
		# ── títulos de sección ──
		"TALENTOS": "TAENTOS",
		"ESPECIALIZAÇÕES": "ESPECIALIZACIONES",
		"TOPO DA FORJA": "CUMBRE DE LA FORJA",
		"OBJETIVOS DO IMPÉRIO": "OBJETIVOS DEL IMPERIO",
		"REENCARNAÇÃO DO IMPÉRIO": "REENCARNACIÓN DEL IMPERIO",
		"BOLETIM DO MERCADO": "BOLETÍN DEL MERCADO",
		"FILA DE ATENDIMENTO": "FILA DE ATENCIÓN",
		"CONSERVA DA CASA E CELA": "CUSTODIA DE LA CASA Y CELDA",
		"FILIAIS DA CASA": "SUCURSALES DE LA CASA",
		"A CONCORRÊNCIA DA PRAÇA": "LA COMPETENCIA DE LA PLAZA",
		"QUADRO DE FUNCIONÁRIOS": "PLANTILLA DE EMPLEADOS",
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
