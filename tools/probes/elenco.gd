extends SceneTree

## Sonda do elenco: o palco é um elenco fechado, e elenco fechado tem contas que
## fecham. Mede (1) se cada corpo tem o retrato do MESMO índice — Bárbaro entrando pela
## porta com o rosto do Bardo é o par quebrado; (2) o ciclo de cada corpo, quadro a
## quadro, e se ele fecha sem buraco (buraco no meio é gente escorregando no lugar);
## (3) a altura desenhada, porque a folha de poses normaliza todo mundo pela altura do
## palco e sem a régua de raça a fada andaria do tamanho de um elfo; (4) se o corpo que
## veste o freguês do turno é o do retrato que o painel mostra; (5) se o rodízio põe
## duas vezes o mesmo rosto em cena; (6) se os arquétipos novos chegam de fato ao
## balcão, e não só à lista; (7) se a corrida de 200 tiques com a mesma semente se
## repete igual — elenco maior não pode introduzir sorteio escondido; e (8) uma folha de
## contato com os corpos novos, para olhar o recorte.
##
## Medidas desta sonda: (1) 24 corpos • 24 retratos • 26 perfis nomeados, com o índice i
## dos corpos batendo com o i dos retratos e todo arquivo no disco; teto de transeuntes 4;
## (2) dezesseis corpos com 6 quadros de marcha + 24 poses e os oito novos com 6 + 6
## (aceno, apontar, felicidade, aprovação, desconfiança e tédio, as seis que a partida
## realmente dispara); nenhum corpo sem ciclo e nenhum buraco no meio; (3) a régua de raça
## fecha a escada: fada 115 < diabrete 145 < goblin 155 < anão 185 < humanos 250 <
## necromante 265 < órc 280; (4) o retrato i entra em cena andando com o corpo i nos 24;
## (5) 40 entradas forçadas de transeunte, pico de 5 figuras em cena e 0 rostos duplicados;
## (6) nenhum arquétipo com preferido inexistente nem retrato fora do elenco, e 600 tiradas
## cobriram 24 dos 24 corpos — nenhum ficou só na lista; (7) a corrida de 200 tiques com a
## mesma semente é IDÊNTICA (caixa 11983 • atendidos 44 • decepcionados 227 • dia 11 •
## placar 13991).
##
## Armadilha de sonda, medida na própria pele: abrir a segunda loja sem apagar o save
## descartável faz ela acordar lendo o que a primeira escreveu. Melhor placar, hall da fama
## e vínculos são da família e passam pelo `_reset_run()`, então a mesma semente rendeu
## duas lojas diferentes (caixa 11983 × 10538) por culpa da sonda, não do jogo.
##
## Uso: godot --path . --quit-after 90000 --script res://tools/probes/elenco.gd
## (sem `--headless`: a folha de contato pega a tela real, e o renderizador dummy devolve
## textura nula).

const OUT := "D:/Downloads/tmp-userdata/"
const SEED_VAL := 20261017
const Locales = preload("res://locales.gd")

var game: Node

func _initialize() -> void:
	var fresh := DirAccess.open("D:/Downloads/tmp-userdata/")
	if fresh != null:
		fresh.remove("Godot/app_userdata/Succubus Shop/succubus_shop_save.cfg")
		fresh.remove("Godot/app_userdata/Succubus Shop/locale_settings.cfg")
	game = await _loja("sonda")
	_elenco_fechado()
	_ciclos()
	_alturas()
	await _corpo_do_turno()
	await _rodizio_sem_gemeos()
	_perfis_sorteados()
	await _corrida_repetivel()
	await _folha_de_contato()
	await _fechar(game)
	quit()


func _loja(rotulo: String):
	# Sem apagar o save descartável antes de abrir, a segunda loja da corrida acorda
	# lendo o que a primeira escreveu: melhor placar, hall da fama e vínculos de
	# família passam pelo `_reset_run()` e a mesma semente renderia duas lojas
	# diferentes por culpa da sonda, não do jogo.
	_apagar_save()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)
	# Em janela a loja acorda com o portão de idioma sobre o salão (headless não abre
	# portão), e a última seção desta sonda é justamente olhar o palco: fechar o portão
	# é o mesmo caminho que o jogador usa.
	if is_instance_valid(g.menu_layer):
		g._close_menu()
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	g._refresh_ui()
	return g


func _apagar_save() -> void:
	var caminho := "user://succubus_shop_save.cfg"
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(caminho))
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
	await _frames(2)


## 1 — Elenco fechado: corpos e retratos têm o mesmo tamanho, na mesma ordem, e cada
## arquivo apontado existe no disco.
func _elenco_fechado() -> void:
	print("── 1. elenco fechado (corpos × retratos) ──")
	var bodies: Array = game.STAGE_CROWD_BODIES
	var faces: Array = game.customer_portrait_paths
	print("   corpos %d • retratos %d • perfis nomeados %d" % [
		bodies.size(), faces.size(), game.CUSTOMER_PROFILES.size()])
	print("   lista de corpos e lista de retratos do mesmo tamanho: %s" % ("OK" if bodies.size() == faces.size() else "TAMANHOS DIFERENTES"))
	var desalinhados: Array[String] = []
	var faltando: Array[String] = []
	for i in range(maxi(bodies.size(), faces.size())):
		var corpo := str(bodies[i % bodies.size()])
		var rosto := str(faces[i % faces.size()])
		if not rosto.ends_with("customer_%s.png" % corpo):
			desalinhados.append("%d: %s × %s" % [i, corpo, rosto.get_file()])
		if not ResourceLoader.exists(rosto):
			faltando.append(rosto)
		if not ResourceLoader.exists("res://assets/stage_%s.png" % corpo):
			faltando.append("stage_%s.png" % corpo)
	print("   indice i do corpo == indice i do retrato: %s" % ("OK" if desalinhados.is_empty() else "QUEBRADO %s" % ", ".join(desalinhados)))
	print("   arquivos existentes: %s" % ("OK" if faltando.is_empty() else "FALTANDO %s" % ", ".join(faltando)))
	print("   teto de transeuntes %d (o teto é de cena, não de elenco)" % int(game.STAGE_MAX_WALKERS))


## 2 — Ciclo de cada corpo: a pose parada mais cada _walkN contíguo, e as poses de
## situação desenhadas. Buraco no meio do ciclo é passo perdido.
func _ciclos() -> void:
	print("── 2. ciclo de caminhada e poses por corpo ──")
	var sem_ciclo: Array[String] = []
	var com_buraco: Array[String] = []
	var histograma: Dictionary = {}
	for i in range(game.STAGE_CROWD_BODIES.size()):
		var corpo := str(game.STAGE_CROWD_BODIES[i])
		var frames: Array = game._stage_crowd_frames(i)
		var emocoes := 0
		for emo in game.STAGE_EMOTION_POSES:
			if not str(game._stage_emotion_frame(i, str(emo))).is_empty():
				emocoes += 1
		var chave := "%d quadros + %d poses" % [frames.size(), emocoes]
		histograma[chave] = int(histograma.get(chave, 0)) + 1
		if frames.size() < 2:
			sem_ciclo.append(corpo)
		for step in range(1, frames.size()):
			var caminho := "res://assets/stage_%s_walk%d.png" % [corpo, step]
			if not ResourceLoader.exists(caminho):
				com_buraco.append("%s walk%d" % [corpo, step])
	for chave in histograma.keys():
		print("   %s: %d corpos" % [chave, histograma[chave]])
	print("   corpo sem ciclo de passo: %s" % ("nenhum" if sem_ciclo.is_empty() else ", ".join(sem_ciclo)))
	print("   buraco no meio do ciclo: %s" % ("nenhum" if com_buraco.is_empty() else ", ".join(com_buraco)))


## 3 — Altura desenhada: a folha normaliza todo mundo em 420 px, então a diferença de
## raça só existe pela régua de STAGE_BODY_HEIGHT. Medida na caixa do corpo montado.
func _alturas() -> void:
	print("── 3. altura desenhada (régua de raça) ──")
	var alturas: Dictionary = {}
	for i in range(game.STAGE_CROWD_BODIES.size()):
		var corpo := str(game.STAGE_CROWD_BODIES[i])
		var figura: Control = game._make_stage_poses(i, float(game.STAGE_FIGURE_HEIGHT))
		alturas[corpo] = figura.size.y
		figura.free()
	var ordem: Array = alturas.keys()
	ordem.sort_custom(func(a, b): return float(alturas[a]) < float(alturas[b]))
	var partes: Array[String] = []
	for corpo in ordem:
		partes.append("%s %.0f" % [corpo, float(alturas[corpo])])
	print("   do mais baixo ao mais alto: %s" % "  ".join(partes))
	var fadas := float(alturas["fairy"])
	var goblins := float(alturas["goblin"])
	var humanos := float(alturas["merchant"])
	var orcs := float(alturas["orc"])
	print("   fada < goblin < humano < órc: %s (%.0f < %.0f < %.0f < %.0f)" % [
		"OK" if fadas < goblins and goblins < humanos and humanos < orcs else "QUEBRADO",
		fadas, goblins, humanos, orcs])


## 4 — O corpo do freguês do turno: vestir a visita com cada retrato do elenco e ler o
## meta do palco. É aqui que o par retrato-corpo deixa de ser comentário e vira tela.
func _corpo_do_turno() -> void:
	print("── 4. quem entra pelo retrato i anda com o corpo i ──")
	var trocados: Array[String] = []
	for i in range(game.STAGE_CROWD_BODIES.size()):
		game._stage_customer_arrives(i)
		var corpo := str(game.stage_customer.get_meta("stage_body", "?"))
		if corpo != str(game.STAGE_CROWD_BODIES[i]):
			trocados.append("%d: retrato andou como %s" % [i, corpo])
		var frames := int(game.stage_customer.get_meta("walk_frames", 0))
		if frames < 2 and not trocados.has(corpo):
			trocados.append("%d: ciclo de %d quadros" % [i, frames])
	await _frames(2)
	print("   indice do retrato == indice do corpo em cena: %s" % ("OK nos %d" % game.STAGE_CROWD_BODIES.size() if trocados.is_empty() else "QUEBRADO %s" % ", ".join(trocados)))


## 5 — Rodízio: encher o salão de transeuntes e conferir, a cada entrada, se sobrou
## alguém com o mesmo rosto em cena. Dois iguais é o elenco sendo um só sprite.
func _rodizio_sem_gemeos() -> void:
	print("── 5. rodízio sem gêmeos em cena ──")
	var repetidos := 0
	var picos := 0
	for rodada in range(40):
		game._spawn_stage_walker()
		var vivos: Array[int] = []
		for entry in game._stage_walkers:
			vivos.append(int(entry.get("crowd", -1)))
		for entry in game._stage_waiters:
			vivos.append(int(entry.get("crowd", -1)))
		if is_instance_valid(game.stage_customer) and game.stage_customer.visible:
			vivos.append(int(game.stage_customer.get_meta("crowd", -1)))
		var vistos: Dictionary = {}
		for c in vivos:
			if vistos.has(c):
				repetidos += 1
			vistos[c] = true
		picos = maxi(picos, vivos.size())
		if int(game._stage_walkers.size()) >= int(game.STAGE_MAX_WALKERS):
			for entry in game._stage_walkers.duplicate():
				game._retire_walker(entry["node"] as Control)
		await _frames(1)
	print("   40 entradas forçadas • pico de figuras em cena %d • rostos duplicados %d" % [picos, repetidos])
	print("   veredito: %s" % ("OK" if repetidos == 0 else "DOIS IGUAIS EM CENA"))


## 6 — Os perfis: cada arquétipo novo precisa chegar ao balcão de verdade, com item
## preferido que existe na prateleira. Perfil com id torto é visita que entra, vê a
## prateleira e vai embora sem comprar nada — parece conteúdo, é bug.
func _perfis_sorteados() -> void:
	print("── 6. os perfis sorteados e o item preferido ──")
	var quebrados: Array[String] = []
	for profile in game.CUSTOMER_PROFILES:
		var favorito := str(profile.get("favorite", ""))
		if not favorito.is_empty() and int(game._product_index(favorito)) < 0:
			quebrados.append("%s → %s" % [str(profile["name"]), favorito])
		var retrato := int(profile.get("portrait", -1))
		if retrato < 0 or retrato >= game.customer_portrait_paths.size():
			quebrados.append("%s → retrato %d fora do elenco" % [str(profile["name"]), retrato])
	print("   perfil com preferido inexistente ou retrato fora do elenco: %s" % ("nenhum" if quebrados.is_empty() else ", ".join(quebrados)))
	seed(SEED_VAL)
	var vistos: Dictionary = {}
	for i in range(600):
		var tirada: Dictionary = game._draw_visitor_profile()
		vistos[int(tirada.get("portrait", -1))] = true
	var ausentes: Array[String] = []
	for i in range(game.STAGE_CROWD_BODIES.size()):
		if not vistos.has(i):
			ausentes.append("%s (%d)" % [str(game.STAGE_CROWD_BODIES[i]), i])
	print("   600 tiradas: %d dos %d corpos apareceram • nunca aparecem: %s" % [
		vistos.size(), game.STAGE_CROWD_BODIES.size(),
		"nenhum" if ausentes.is_empty() else ", ".join(ausentes)])


## 7 — Corrida repetível: duzentos tiques com a mesma semente, duas lojas abertas na
## mesma sessão. Elenco maior não pode mover o caixa nem trocar a freguesia.
func _corrida_repetivel() -> void:
	print("── 7. corrida de 200 tiques, mesma semente, duas vezes ──")
	var a := await _corrida()
	var b := await _corrida()
	print("   A: caixa %d • fama %d • atendidos %d • decepcionados %d • fila %d • dia %d • placar %d" % [
		a["caixa"], a["fama"], a["servidos"], a["desanimados"], a["fila"], a["dia"], a["placar"]])
	print("   B: caixa %d • fama %d • atendidos %d • decepcionados %d • fila %d • dia %d • placar %d" % [
		b["caixa"], b["fama"], b["servidos"], b["desanimados"], b["fila"], b["dia"], b["placar"]])
	var iguais := true
	for chave in ["caixa", "fama", "servidos", "desanimados", "fila", "dia", "placar"]:
		if int(a[chave]) != int(b[chave]):
			iguais = false
	print("   veredito: %s" % ("IDÊNTICA" if iguais else "A MESMA SEMENTE RENDEU DUAS LOJAS DIFERENTES"))


func _corrida() -> Dictionary:
	var g = await _loja("corrida")
	for definition in g._achievement_definitions():
		var badge_id := str(definition["id"])
		if not g.unlocked_achievements.has(badge_id):
			g.unlocked_achievements.append(badge_id)
	g.player_level = 60
	g.gold = 5000
	g.reputation = 60
	for i in range(g.products.size()):
		g.products[i]["stock"] = 6
	g._refresh_ui()
	for i in range(200):
		g._on_customer_tick()
	var marca := {
		"caixa": int(g.gold),
		"fama": int(g.reputation),
		"servidos": int(g.customers_served),
		"desanimados": int(g.disappointed_customers),
		"fila": int(g.service_queue.size()),
		"dia": int(g.shop_day),
		"placar": int(g.business_score()),
	}
	await _fechar(g)
	return marca


## 8 — Folha de contato: os corpos novos lado a lado, recorte contra fundo neutro. É o
## que a sonda não mede sozinha — borda neon, pé solto, braço comido pelo corte.
func _folha_de_contato() -> void:
	print("── 8. folha de contato dos corpos novos ──")
	var novos: Array[String] = ["alchemist", "necromancer", "bounty", "elf", "orc", "fairy", "vampire", "imp"]
	var altura := 420
	var largura := 190 * novos.size()
	var folha := Image.create(largura, altura + 26, false, Image.FORMAT_RGBA8)
	folha.fill(Color(0.16, 0.14, 0.18))
	for i in range(novos.size()):
		var caminho := "res://assets/stage_%s.png" % str(novos[i])
		if not ResourceLoader.exists(caminho):
			continue
		var tex := load(caminho) as Texture2D
		var src := tex.get_image()
		src.convert(Image.FORMAT_RGBA8)
		var escala := float(altura) / float(src.get_height())
		var rec := src.duplicate()
		rec.resize(maxi(1, int(float(src.get_width()) * escala)), altura, Image.INTERPOLATE_LANCZOS)
		folha.blend_rect(rec, Rect2i(0, 0, rec.get_width(), rec.get_height()), Vector2i(i * 190 + (190 - rec.get_width()) / 2, 0))
	folha.save_png(OUT + "elenco_novos.png")
	print("   folha salva em %selenco_novos.png (%dx%d)" % [OUT, largura, altura + 26])
	for corpo in novos:
		var ciclos := (game._stage_crowd_frames(game.STAGE_CROWD_BODIES.find(corpo)) as Array).size()
		print("      %-12s ciclo %d quadros" % [corpo, ciclos])
	get_root().get_texture().get_image().save_png(OUT + "elenco_tela.png")
