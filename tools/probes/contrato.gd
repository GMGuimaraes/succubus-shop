extends SceneTree

## Sonda do contrato medido: todo número que o README escreve sobre conteúdo do jogo
## (catálogo, elenco, cartas, capítulos, conquistas) e sobre a conta da casa tem de bater
## com a tabela que o motor carrega, na mesma rodada em que o conteúdo muda. O README é
## contrato porque outras sondas citam os números dele; tabela que cresce sem frase
## crescem as duas mentiras de uma vez.
##
## Cada linha da tabela abaixo confere duas coisas e imprime as duas:
##   codigo  — o tamanho lido da tabela viva (`Cards.DATA`, `Endings.size()`,
##             `_achievement_definitions()`…), sem adivinhação e sem grep no texto.
##   espera  — o número que esta sonda declara; se o código mudar sem ninguém ajustar
##             a frase do README, a linha vira QUEBRA e o push para.
##   frase   — o pedaço exato que o README precisa carregar, comparado sem diferenciar
##             maiúsculas (o README escreve os títulos em caixa alta e o corpo em minúscula;
##             exigir a grafia era a sonda reprovar texto que estava certo).
##
## A segunda seção mede a **conta da casa** chamando `_daily_upkeep()` na loja resetada,
## com o quadro de funcionários montado de propósito. Ela existe porque a folha de #47 foi
## publicada com quatro vagas e a criada da #53 entrou depois sem que nenhuma frase da
## economia tivesse sido relida: número de conta não se deduz de cabeça, se mede no motor.
##
## A sonda não grava nada que o jogador usa: `_reset_run()` e `_daily_upkeep()` só movem
## memória. Roda mesmo assim com o APPDATA descartável do portão.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 1800 --script res://tools/probes/contrato.gd > /d/Downloads/tmp-userdata/probe.log 2>&1

const Regulars := preload("res://regulars.gd")
const Ingredients := preload("res://ingredients.gd")
const Cards := preload("res://cards.gd")
const Origin := preload("res://origin.gd")
const Rivals := preload("res://rivals.gd")
const Campaign := preload("res://campaign.gd")
const Endings := preload("res://endings.gd")
const Branches := preload("res://branches.gd")
const Staff := preload("res://staff.gd")
const Adventurers := preload("res://adventurers.gd")
const Expedition := preload("res://expedition.gd")
const Invasions := preload("res://invasions.gd")
const Factions := preload("res://factions.gd")
const FactionArcs := preload("res://faction_arcs.gd")
const TalentSpecs := preload("res://talent_specs.gd")
const Sanctum := preload("res://sanctum.gd")
const Locales := preload("res://locales.gd")
const MainScript := preload("res://main.gd")

const READ_PATH := "res://README.md"

## Quantas leituras `_medir_conta()` deve devolver. É asserção, não contagem de cortesia:
## um case que morre no meio encolhe a lista, e sem esta régua a sonda imprimiria
## "quebras=0" para uma conta que nunca chegou a ser medida.
const CONTAS := 11

var _quebras := 0

func _initialize() -> void:
	var readme := _ler(READ_PATH)
	if readme.is_empty():
		print("CONTRATO: QUEBRA • não consegui ler o README — a sonda não prova nada às cegas")
		quit()
		return
	var linhas := readme.split("\n")
	# As conquistas moram num método da cena, e a cena precisa existir para chamar.
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(2)
	# A régua da conta é a vida zerada: sem o _reset_run() o save descartável da mesa
	# emprestaria biblioteca, filial e quadro de outra sonda para dentro da medida.
	game.world_timer.stop()
	game._reset_run()
	game._refresh_ui()
	var conta := _medir_conta(game)
	# Uma seção que aborta no meio devolve lista curta, e "quebras=0" leria como aprovação
	# de uma conta que nunca foi medida. A contagem é parte da asserção.
	if conta.size() != CONTAS:
		_quebras += 1
		print("CONTRATO: QUEBRA • a medição da conta devolveu %d linhas, deveriam ser %d — algum case morreu antes de imprimir" % [conta.size(), CONTAS])

	print("CONTRATO: tabela de conteúdo • código x README")
	for claim in _claims(game) + conta:
		_conferir(claim, linhas)
	print("CONTRATO: veredito • quebras=%d" % _quebras)
	quit()

## Lê a conta da casa nas onze leituras que o README cita, na loja recém-resetada, e devolve
## as claims já com o número medido (`CONTAS` é a régua). Cada estado é montado e desmontado
## na mão para a medida não herdar nada do lado anterior.
func _medir_conta(game: Node) -> Array:
	var quadro: Array[String] = []
	for seat in Staff.DATA:
		quadro.append(str(seat["id"]))
	var folha: Array[String] = []
	var sem_cozinha: Array[String] = []
	for id in quadro:
		if id != "cozinha":
			sem_cozinha.append(id)
		folha.append(str(Staff.find(id)["wage"]))

	var claims: Array = []
	# 1 — o piso: esquina crua, ninguém no quadro.
	var quadro_vazio: Array[String] = []
	game.staff_hired = quadro_vazio
	game.house_rank = 0
	var piso: int = game._daily_upkeep()
	_claim(claims, "conta-piso", piso, 12, "12 de ouro na esquina")
	# 2 — a folha inteira, lida da tabela de salários.
	var total_folha: int = Staff.total_wage(quadro)
	_claim(claims, "folha-cheia", total_folha, 122, "A folha inteira é **122** por virada")
	# 2b — o salário mais barato da folha é o que a cláusula da ruína cita como piso da
	# faixa; foi ele que a quinta vaga mudou sem ninguém reler a frase.
	var menor_salario := 9999
	for seat in Staff.DATA:
		menor_salario = mini(menor_salario, int(seat["wage"]))
	_claim(claims, "salario-minimo", menor_salario, 20, "(**20** a 30 por pessoa)")
	# 3 — o quadro cheio na conta da casa.
	game.staff_hired = quadro
	var cheia: int = game._daily_upkeep()
	_claim(claims, "conta-quadro", cheia, 134, "a conta sai de 12 para **134**")
	# 4 — Administração da Casa no degrau 3 encolhe a conta toda, salário incluído.
	game.house_rank = 3
	var administrada: int = game._daily_upkeep()
	_claim(claims, "conta-degrau3", administrada, 102, "no degrau 3 custa **102**")
	game.house_rank = 0
	# 5 — demitir a cozinha: a cobrança para no mesmo instante.
	game.staff_hired = sem_cozinha
	var sem_prato: int = game._daily_upkeep()
	_claim(claims, "conta-sem-cozinha", sem_prato, 112, "folha 122 → 100, conta 134 → 112")
	# 6 — reencarnar demite o quadro inteiro: a volta ao piso é a mesma conta do item 1.
	game._reset_run()
	var reencarnada: int = game._daily_upkeep()
	_claim(claims, "conta-vida-nova", reencarnada, 12, "folha 122 → 0, conta 134 → 12")
	# 7 — a "casa grande" que a cláusula da ruína cita: uma marcha em cada leitura, o
	# diabrete contratado e o quadro cheio. O número só vale com a definição escrita.
	game.library_upgrade_level = 1
	game.sanctum_upgrade_level = 1
	game.ad_level = 1
	game.imp_hired = true
	game.staff_hired = quadro
	var grande: int = game._daily_upkeep()
	_claim(claims, "casa-grande", grande, 169, "ou seja, **169** numa casa grande")
	# 7b — a mesma casa grande, agora com Administração da Casa no nível máximo. É a
	# leitura que a cláusula da quinta trilha cita, e ela tem de valer sobre a MESMA
	# definição do item 7: duas "casas grandes" com números diferentes no README é a
	# segunda mentira, não a correção da primeira.
	game.house_rank = 5
	var administrada_grande: int = game._daily_upkeep()
	game.house_rank = 0
	_claim(claims, "casa-grande-degrau5", administrada_grande, 101,
		"a mesma casa grande de **169** por virada cai para **101**")
	# 8 — as cinco filiais abertas cobram 154 por virada sobre a conta de 12.
	var ids_filiais: Array[String] = []
	for b in Branches.DATA:
		ids_filiais.append(str(b["id"]))
	var zelo: int = Branches.total_upkeep(ids_filiais)
	_claim(claims, "filiais-cobram", zelo, 154, "as cinco juntas cobram 154")
	# 9 — a cela come por cabeça, medida pela diferença de conta entre zero e dois presos:
	# é o número que a cláusula da casa suja publica, e ele mora em `CELL_FOOD`.
	game._reset_run()
	game.staff_hired = quadro_vazio
	var dois: Array[Dictionary] = [
		{"name": "Preso Um", "regular_id": ""},
		{"name": "Preso Dois", "regular_id": ""},
	]
	var antes_cela: int = game._daily_upkeep()
	game.prisoners = dois
	var depois_cela: int = game._daily_upkeep()
	game.prisoners.clear()
	_claim(claims, "cela-por-cabeca", depois_cela - antes_cela, 6, "**3 de conta por cabeça**")
	game._refresh_ui()
	print("CONTRATO: conta da casa medida no motor • piso=%d folha=%s=%d quadro=%d degrau3=%d sem-prato=%d vida-nova=%d grande=%d cela=%d" % [
		piso, folha, total_folha, cheia, administrada, sem_prato, reencarnada, grande,
		depois_cela - antes_cela,
	])
	return claims

func _claim(claims: Array, rotulo: String, codigo: int, espera: int, frase: String) -> void:
	claims.append({"rotulo": rotulo, "codigo": codigo, "espera": espera, "frase": frase})

func _conferir(claim: Dictionary, linhas: Array) -> void:
	var rotulo := str(claim["rotulo"])
	var codigo: int = int(claim["codigo"])
	var espera: int = int(claim["espera"])
	var frase := str(claim["frase"])
	var alvo := frase.to_lower()
	var achadas: int = 0
	for linha in linhas:
		if str(linha).to_lower().find(alvo) >= 0:
			achadas += 1
	var ok_codigo := codigo == espera
	var ok_texto := achadas > 0
	print("CONTRATO: %-18s codigo=%3d espera=%3d %-4s • frase lida %d x %s" % [
		rotulo, codigo, espera, "ok" if ok_codigo else "DESVIO", achadas,
		"ok" if ok_texto else "FALTA",
	])
	if not ok_codigo or not ok_texto:
		_quebras += 1
		if not ok_codigo:
			print("CONTRATO: QUEBRA • %s: a tabela tem %d e a sonda declara %d" % [rotulo, codigo, espera])
		if not ok_texto:
			print("CONTRATO: QUEBRA • %s: nenhuma linha do README carrega \"%s\"" % [rotulo, frase])

func _claims(game: Node) -> Array:
	var oficios := 0
	for kind in TalentSpecs.trail_ids():
		oficios += TalentSpecs.pair(str(kind)).size()
	return [
		{"rotulo": "conquistas", "codigo": game._achievement_definitions().size(),
			"espera": 100, "frase": "Cem conquistas"},
		{"rotulo": "conquistas-lista", "codigo": game._achievement_definitions().size(),
			"espera": 100, "frase": "**100 definições**"},
		{"rotulo": "produtos", "codigo": game.products.size(), "espera": 12,
			"frase": "Doze produtos no catálogo atual"},
		{"rotulo": "cards", "codigo": Cards.size(), "espera": 16,
			"frase": "dezesseis cards em três coleções"},
		{"rotulo": "raridades", "codigo": Cards.RARITIES.size(), "espera": 4,
			"frase": "quatro raridades"},
		{"rotulo": "recorrentes", "codigo": Regulars.DATA.size(), "espera": 9,
			"frase": "nove personagens nomeados"},
		{"rotulo": "atos", "codigo": Regulars.THRESHOLDS.size(), "espera": 4,
			"frase": "quatro atos"},
		{"rotulo": "lembrancas", "codigo": Origin.DATA.size(), "espera": 8,
			"frase": "Oito lembranças de origem"},
		{"rotulo": "rivais", "codigo": Rivals.DATA.size(), "espera": 3,
			"frase": "três rivais"},
		{"rotulo": "ingredientes", "codigo": Ingredients.DATA.size(), "espera": 6,
			"frase": "seis ingredientes básicos"},
		{"rotulo": "faccoes", "codigo": Factions.DATA.size(), "espera": 5,
			"frase": "cinco facções"},
		{"rotulo": "pedidos-faccao", "codigo": FactionArcs.total(), "espera": 15,
			"frase": "quinze no caderno inteiro"},
		{"rotulo": "capitulos", "codigo": Campaign.size(), "espera": 7,
			"frase": "sete capítulos"},
		{"rotulo": "finais", "codigo": Endings.size(), "espera": 7,
			"frase": "Sete finais"},
		{"rotulo": "finais-titulo", "codigo": Endings.size(), "espera": 7,
			"frase": "cinco de facção, o da casa e o da ruína, e placar"},
		{"rotulo": "finais-alpha", "codigo": Endings.size(), "espera": 7,
			"frase": "desfechos (cinco de facção, o da casa e o da ruína)"},
		{"rotulo": "trilhas", "codigo": TalentSpecs.trail_ids().size(), "espera": 5,
			"frase": "cinco trilhas"},
		{"rotulo": "oficios", "codigo": oficios, "espera": 10,
			"frase": "dois ofícios concorrentes por trilha"},
		{"rotulo": "filiais", "codigo": Branches.size(), "espera": 5,
			"frase": "cinco filiais fixas"},
		{"rotulo": "funcionarios", "codigo": Staff.size(), "espera": 5,
			"frase": "São **cinco vagas**"},
		{"rotulo": "funcionarios-alpha", "codigo": Staff.size(), "espera": 5,
			"frase": "cinco vagas de funcionários com taxa"},
		{"rotulo": "batedores", "codigo": Adventurers.size(), "espera": 5,
			"frase": "Cinco batedores"},
		{"rotulo": "rotas", "codigo": Expedition.size(), "espera": 4,
			"frase": "quatro rotas"},
		{"rotulo": "invasoes", "codigo": Invasions.DATA.size(), "espera": 7,
			"frase": "Sete visitas"},
		{"rotulo": "rituais", "codigo": Sanctum.DATA.size(), "espera": 8,
			"frase": "oito rituais"},
		{"rotulo": "rituais-buff", "codigo": _contar_kind("buff"), "espera": 5,
			"frase": "cinco **buffs**"},
		{"rotulo": "rituais-alivio", "codigo": _contar_kind("relief"), "espera": 3,
			"frase": "três **alívios**"},
		{"rotulo": "chaves-idioma", "codigo": Locales.MESSAGES["en"].size(), "espera": 216,
			"frase": "mesmas 216 chaves na mesma ordem"},
		{"rotulo": "idiomas", "codigo": Locales.SUPPORTED.size(), "espera": 6,
			"frase": "A loja atende em seis idiomas"},
		{"rotulo": "pereciveis", "codigo": _contar_pereciveis(game), "espera": 6,
			"frase": "seis dos doze"},
		{"rotulo": "scenery-degraus", "codigo": MainScript.SECTOR_SCENERY_STEPS, "espera": 30,
			"frase": "**30 degraus por sala**"},
	]

func _contar_kind(kind: String) -> int:
	var n := 0
	for ritual in Sanctum.DATA:
		if str(ritual.get("kind", "")) == kind:
			n += 1
	return n

## Quantos produtos do catálogo têm validade. É a conta que a cláusula da despensa
## publica ("seis dos doze"), e ela é lida do mesmo `validade` que `_shelf_life()` usa.
func _contar_pereciveis(game: Node) -> int:
	var n := 0
	for p in game.products:
		if int((p as Dictionary).get("validade", 0)) > 0:
			n += 1
	return n

func _ler(caminho: String) -> String:
	var file := FileAccess.open(caminho, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
