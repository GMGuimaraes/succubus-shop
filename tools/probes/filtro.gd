extends SceneTree

## Sonda do filtro: prova que o interruptor de cenas sensuais segura a voz e a arte,
## nunca a porta. Cada medida acontece numa loja recém-instalada com o save
## descartável apagado — sem isso uma vida vaza na outra e o A/B lê sorte onde havia
## sujeira. Roda A/A (ligado vs ligado, 400 tiques) para provar que o sorteio é
## reproduzível, depois A/B (ligado vs desligado) exigindo as mesmas contas: caixa,
## fama, afeição, seduções provadas, servos, momentos, XP e placar. Confere ainda que
## o pico de sedução e o momento privado pagam nos dois modos, que a pose de conquista
## roda com o filtro desligado, que a única imagem exclusiva do modo ligado é a
## vitrine de flerte, que a fala de negociação troca de array sem trocar de efeito,
## que a forma demoníaca voltou a ser consequência de fúria e não de conteúdo (o estado
## e o selo do painel correm nos dois modos; a arte do retrato é do filtro, e troca na
## mesma batida do botão), que o save carrega a preferência só com a confirmação de
## idade, que reencarnar destrava o pico e o que a mensagem do botão promete.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/filtro.gd
##
## Veredito medido nesta rodada: A/A fecha 400 tiques idênticos e o A/B (ligado ×
## desligado) fecha as MESMAS contas — nenhum tique divergiu: caixa 2182, fama 0,
## afeição 53, 14 seduções em 14 tentativas, 0 momentos, 0 servos, 5 atendidos, 138
## decepções, XP 105 no nível 6, placar 2594. Voz: 120 falas desligado nunca saem do
## array de flerte, 120 ligado nunca saem do de confiança, nenhuma palavra provocativa
## sobrevive nos arrays do modo desligado, e os arrays são espelhados (4/4 e 5/5) com o
## meme continuando meme nos dois modos. Pico: +1 momento, +4 de fama e +15 XP de
## qualquer forma; o tween da pose só nasce ligado (subida de 7,1 px em 6 fotogramas,
## 0 px desligado). Momento privado: +1 e o mesmo placar (133) nos dois modos; afinidade
## 4 ainda não paga. Pose de conquista: roda desligado (retrato x1,09 nos dois).
## Vitrine: 120 entradas desligado = 0 flerte, 120 ligado = 29 flerte (24%). Fúria: a
## forma acende false→true nos dois modos com o selo no painel, e o retrato demoníaco
## aparece só com o filtro ligado — bater no botão com fúria 4 troca a pintura e não o
## estado. Save: preferência, momentos, seduções e afeição atravessam; sem
## `adult_content_confirmed` o filtro acorda desligado. Reencarnar libera o pico de novo.
## Se alguma coluna numérica do A/B divergir, o filtro voltou a cortar progressão.

const SEED_VAL := 20261015
const TICKS := 400
const FLIRTY := "res://assets/reception_scene_flirty.png"
const PLAIN_ART := "res://assets/reception_scene.png"
const DEMONICA := "res://assets/seller_demonic.png"
## Palavras que só o modo ligado pode dizer. Se uma aparecer no texto do modo
## desligado, o filtro deixou vazar cena junto com a progressão.
const PROVOCATIVAS := ["seduç", "sensual", "provoc", "querido", "flerte", "beij"]

func _initialize() -> void:
	print("── a voz: o filtro troca o array de fala, não o efeito ──")
	var game = await _loja("voz", false)
	var flirt: Array = game.SUCCUBUS_NEGOTIATION_LINES + game.MEME_FLIRT_LINES
	var confianca: Array = game.TRUST_NEGOTIATION_LINES + game.MEME_TRUST_LINES
	var off_vazou := ""
	var on_vazou := ""
	var off_amostra := ""
	var on_amostra := ""
	var off_meme := ""
	var on_meme := ""
	for i in range(120):
		game.adult_content_enabled = false
		var line_off: String = game._negotiation_line("Aventureiro")
		if line_off in flirt:
			off_vazou = line_off
		if off_amostra.is_empty():
			off_amostra = line_off
		off_meme = game._negotiation_line("Mago do Quero Mana")
		game.adult_content_enabled = true
		var line_on: String = game._negotiation_line("Aventureiro")
		if line_on in confianca:
			on_vazou = line_on
		if on_amostra.is_empty():
			on_amostra = line_on
		on_meme = game._negotiation_line("Mago do Quero Mana")
	print("   120 falas desligado: nenhuma do array de flerte? %s" % (
		"ok" if off_vazou.is_empty() else "VAZOU: " + off_vazou))
	print("   120 falas ligado: nenhuma do array de confiança? %s" % (
		"ok" if on_vazou.is_empty() else "VAZOU: " + on_vazou))
	print("   desligado (amostra): %s" % off_amostra.substr(0, 92))
	print("   ligado (amostra):    %s" % on_amostra.substr(0, 92))
	print("   o meme continua meme nos dois modos? desligado: %s • ligado: %s" % [
		"ok" if off_meme.find("Mana eu tenho") >= 0 else "PERDIDO",
		"ok" if on_meme.find("Mana eu tenho") >= 0 else "PERDIDO"])
	print("   palavras provocativas nos arrays do modo desligado: %s" % (
		"nenhuma" if not _tem_provocacao(game) else "VAZOU (linhas acima)"))
	var trust_size: int = game.TRUST_NEGOTIATION_LINES.size()
	var flirt_size: int = game.SUCCUBUS_NEGOTIATION_LINES.size()
	var meme_trust: int = game.MEME_TRUST_LINES.size()
	var meme_flirt: int = game.MEME_FLIRT_LINES.size()
	print("   arrays espelhados: confiança %d / flerte %d • meme %d / %d" % [
		trust_size, flirt_size, meme_trust, meme_flirt])
	await _fechar(game)

	print("── %d tiques de loja: a mesma sorte nos dois modos ──" % TICKS)
	var traco_on: Array = await _vida("A/A ligado 1", true, TICKS)
	var traco_on2: Array = await _vida("A/A ligado 2", true, TICKS)
	var traco_off: Array = await _vida("A/B desligado", false, TICKS)
	var aa := _primeiro_desvio(traco_on, traco_on2)
	if aa < 0:
		print("   controle A/A: %d tiques idênticos -> o sorteio é reproduzível" % TICKS)
	else:
		print("   controle A/A DIVERGIU no tique %d -> a harness não é confiável" % aa)
		print("      1ª: %s" % str(traco_on[aa]))
		print("      2ª: %s" % str(traco_on2[aa]))
	var ab := _primeiro_desvio(traco_on, traco_off)
	print("   A/B (ligado vs desligado): %s" % (
		"nenhum tique divergiu nas contas" if ab < 0 else "DIVERGIU no tique %d" % ab))
	if ab >= 0:
		print("      LIGADO   : %s" % str(traco_on[ab]))
		print("      DESLIGADO: %s" % str(traco_off[ab]))
	print("   tique final ligado   : %s" % str(traco_on[TICKS - 1]))
	print("   tique final desligado: %s" % str(traco_off[TICKS - 1]))

	print("── o pico de sedução paga nos dois modos ──")
	for ligado_ago in [true, false]:
		game = await _loja("pico", ligado_ago)
		game.affection = 100
		game.seduction_peak_triggered = false
		game.player_xp = 0
		var momentos: int = game.private_moments_unlocked
		var rep: int = game.reputation
		if game.sensual_tween != null and game.sensual_tween.is_valid():
			game.sensual_tween.kill()
		if is_instance_valid(game.seller_portrait):
			game.seller_portrait.scale = Vector2.ONE
		game._react_to_visit("delighted", false)
		await _frames(6)
		var ganho: String = "+%d momento(s) • +%d fama • XP %d" % [
			game.private_moments_unlocked - momentos, game.reputation - rep, game.player_xp]
		print("   %s: disparou=%s • %s" % [
			"LIGADO" if ligado_ago else "DESLIGADO", game.seduction_peak_triggered, ganho])
		print("      texto: %s" % str(game.last_event).replace("\n", " ").substr(0, 108))
		if game.sensual_tween != null and game.sensual_tween.is_valid():
			game.sensual_tween.kill()
		await _fechar(game)
		# A pose desenhada é medida em loja recém-nascida: o respirar ambiente do retrato
		# e o tween do próprio pico mexem nas mesmas propriedades, então girar e subir só
		# contam como prova quando nada mais estava animando o balcão antes da chamada.
		game = await _loja("pico-pose", ligado_ago)
		if is_instance_valid(game.seller_portrait):
			game.seller_portrait.rotation = 0.0
			game.seller_portrait.position = Vector2.ZERO
		var tween_antes: bool = game.sensual_tween != null and game.sensual_tween.is_valid()
		game._play_seduction_peak_pose()
		await _frames(6)
		var giro := 0.0
		var subida := 0.0
		if is_instance_valid(game.seller_portrait):
			giro = game.seller_portrait.rotation
			subida = game.seller_portrait.position.y
		print("      pose desenhada: tween criado=%s (antes %s) • giro %.4f rad • subida %.1f px" % [
			str(game.sensual_tween != null and game.sensual_tween.is_valid()), str(tween_antes), giro, subida])
		await _fechar(game)

	print("── o momento privado conta nos dois modos ──")
	for ligado_ago in [true, false]:
		game = await _loja("momento", ligado_ago)
		game.affection = 20
		var momentos: int = game.private_moments_unlocked
		game._show_private_moment()
		print("   %s: +%d momento(s) • placar com ele: %d" % [
			"LIGADO" if ligado_ago else "DESLIGADO",
			game.private_moments_unlocked - momentos, game.business_score()])
		print("      texto: %s" % str(game.last_event).replace("\n", " ").substr(0, 108))
		await _fechar(game)
	game = await _loja("recusa", false)
	game.affection = 4
	var antes: int = game.private_moments_unlocked
	game._show_private_moment()
	print("   afinidade 4 (pede 5): +%d momento(s) (esperado 0)" % (
		game.private_moments_unlocked - antes))
	await _fechar(game)

	print("── a pose de conquista roda com o filtro desligado ──")
	for ligado_ago in [true, false]:
		game = await _loja("pose", ligado_ago)
		if game.sensual_tween != null and game.sensual_tween.is_valid():
			game.sensual_tween.kill()
		if is_instance_valid(game.seller_portrait):
			game.seller_portrait.scale = Vector2.ONE
			game.seller_portrait.rotation = 0.0
		game._play_achievement_pose("relic")
		await _frames(6)
		var escala := 1.0
		if is_instance_valid(game.seller_portrait):
			escala = game.seller_portrait.scale.x
		print("   %s: retrato x%.2f -> pose %s" % [
			"LIGADO" if ligado_ago else "DESLIGADO", escala,
			"rodou" if escala > 1.001 else "NÃO RODOU"])
		await _fechar(game)

	print("── a única imagem exclusiva do modo ligado ──")
	game = await _loja("vitrine", false)
	var flirty_desligado := 0
	game.adult_content_enabled = false
	seed(SEED_VAL)
	for i in range(120):
		game._set_sector("reception")
		if is_instance_valid(game.background_layer) \
				and str(game.background_layer.texture.resource_path) == FLIRTY:
			flirty_desligado += 1
	var flirty_ligado := 0
	game.adult_content_enabled = true
	seed(SEED_VAL)
	for i in range(120):
		game._set_sector("reception")
		if is_instance_valid(game.background_layer) \
				and str(game.background_layer.texture.resource_path) == FLIRTY:
			flirty_ligado += 1
	print("   120 entradas desligado: vitrine de flerte %d vez(es) (esperado 0)" % flirty_desligado)
	print("   120 entradas ligado: vitrine de flerte %d vez(es) (%d%%) • arte simples existe: %s" % [
		flirty_ligado, flirty_ligado * 100 / 120, str(ResourceLoader.exists(PLAIN_ART))])
	await _fechar(game)

	print("── a fúria manda a forma demoníaca nos dois modos, a arte é do filtro ──")
	for ligado_ago in [true, false]:
		game = await _loja("furia", ligado_ago)
		game.fury = 0
		game._update_demonic_form()
		var forma_vazia: bool = game.demonic_form_active
		game.fury = 4
		game._update_demonic_form()
		game._refresh_ui()
		print("   %s: fúria 0 forma %s • fúria 4 forma %s (esperado false/true) • selo no painel: %s" % [
			"LIGADO" if ligado_ago else "DESLIGADO", str(forma_vazia),
			str(game.demonic_form_active),
			"FORMA DEMONÍACA" if is_instance_valid(game.fury_label) and str(game.fury_label.text).find("FORMA") >= 0 else "AUSENTE (esperado presente)"])
		print("      texto: %s" % str(game.last_event).replace("\n", " ").substr(0, 108))
		print("      retrato demoníaco na tela: %s (esperado %s)" % [
			str(_arte_demonica(game)), str(ligado_ago)])
		# Mexer no interruptor com a fúria ainda no teto tem de trocar só a pintura: o
		# estado continua o mesmo, e a arte dele aparece ou some na mesma batida.
		game._toggle_adult_content()
		var arte_trocada := _arte_demonica(game)
		game._toggle_adult_content()
		print("      bater no botão com fúria 4: arte %s (esperado %s) • estado depois das duas batidas %s" % [
			str(arte_trocada), str(not ligado_ago), str(game.demonic_form_active)])
		game.fury = 1
		game._update_demonic_form()
		print("      fúria volta a 1: forma %s • arte %s (esperado false/false)" % [
			str(game.demonic_form_active), str(_arte_demonica(game))])
		await _fechar(game)
	await _fechar(game)

	print("── o save carrega a preferência, e só com a confirmação ──")
	game = await _loja("save", true)
	game.adult_content_confirmed = true
	game.adult_content_enabled = true
	game.private_moments_unlocked = 4
	game.seduction_successes = 11
	game.affection = 37
	game._save_game()
	var leitura = await _reload("reload")
	print("   preferência: %s • momentos lidos: %d • seduções: %d • afeição: %d" % [
		leitura.adult_content_enabled, leitura.private_moments_unlocked,
		leitura.seduction_successes, leitura.affection])
	await _fechar(leitura)
	_gravar_sem_confirmacao()
	var sem_idade = await _reload("reload sem confirmação")
	print("   save com adult_content_confirmed=false acorda: %s (esperado desligado)" % (
		str(sem_idade.adult_content_enabled)))
	await _fechar(sem_idade)
	await _fechar(game)

	print("── reencarnar destrava o pico da vida nova ──")
	game = await _loja("reencarnar", true)
	game.seduction_peak_triggered = true
	game._reset_run()
	print("   pico depois de reencarnar: %s" % (
		"liberado" if not game.seduction_peak_triggered else "TRAVADO para sempre"))
	await _fechar(game)

	print("── o que o botão promete ──")
	game = await _loja("botao", true)
	game._toggle_adult_content()
	print("   desligando: %s" % str(game.last_event))
	game._toggle_adult_content()
	print("   ligando: %s" % str(game.last_event))
	print("   estado depois das duas batidas: %s" % str(game.adult_content_enabled))
	await _fechar(game)

	print("VEREDITO: as contas do A/B têm de fechar iguais nos dois modos; divergência de caixa, servo, momento ou placar é progressão cortada pelo filtro.")
	quit()


## Loja recém-instalada, com o save descartável apagado antes de nascer: é o que faz
## as três medidas A/A e A/B partirem do mesmo zero. Devolve a cena pronta, com o
## relógio do mundo parado, a semente cravada e a vida resetada.
func _loja(rotulo: String, ligado: bool):
	_apagar_save()
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	g.adult_content_enabled = ligado
	return g


## O retrato da chefe está vestido com a arte demoníaca agora? É a única forma de
## medir a pintura sem depender do tempo real do tween na tela.
func _arte_demonica(g) -> bool:
	if not is_instance_valid(g.seller_portrait):
		return false
	var textura: Texture2D = g.seller_portrait.texture
	return textura != null and str(textura.resource_path) == DEMONICA


## Reabre a loja lendo o save que está no disco, sem apagar nada, sem resetar a vida e
## sem tocar na preferência: só assim a medida mostra o que _load_game() restaurou de
## verdade, em vez do que a própria sonda escreveu por cima.
func _reload(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	g.world_timer.stop()
	return g


func _fechar(g) -> void:
	if is_instance_valid(g):
		g.queue_free()
		await _frames(2)


## Uma vida medida tique a tique, em loja própria, devolvendo só as contas — o texto
## do mural muda com o filtro de propósito e não é divergência.
func _vida(rotulo: String, ligado: bool, ticks: int) -> Array:
	var g = await _loja(rotulo, ligado)
	g.charm_rank = 4
	g.gold = 1500
	g.reputation = 20
	var traco: Array = []
	for i in range(ticks):
		g._on_customer_tick()
		traco.append("gold %d • rep %d • af %d • att %d/%d • mnt %d • servos %d • at %d • dis %d • xp %d/%d • pla %d" % [
			g.gold, g.reputation, g.affection, g.seduction_attempts, g.seduction_successes,
			g.private_moments_unlocked, g.servants.size(), g.customers_served,
			g.disappointed_customers, g.player_xp, g.player_level, g.business_score()
		])
	await _fechar(g)
	return traco


func _primeiro_desvio(a: Array, b: Array) -> int:
	for i in range(mini(a.size(), b.size())):
		if str(a[i]) != str(b[i]):
			return i
	return -1


## Varre os três arrays que só o modo desligado usa e as duas falas fixas que ele
## escreve (pico e recusa por afinidade).
func _tem_provocacao(game) -> bool:
	var textos: Array = game.TRUST_NEGOTIATION_LINES + game.MEME_TRUST_LINES + game.TRUST_MOMENTS
	textos.append("MEDIDOR DE CONFIANÇA CHEIO! A chefe abre o caderno da casa na sua frente: “Agora você entende por que ninguém fecha a conta daqui sem voltar.”")
	textos.append("“Paciência. Primeiro conquiste minha confiança: o caderno da casa registra quem volta.”")
	for line in textos:
		for word in PROVOCATIVAS:
			if str(line).find(word) >= 0:
				print("      [%s] em: %s" % [word, str(line).substr(0, 80)])
				return true
	return false


## Reescreve o save descartável sem a confirmação de idade, para provar que a
## preferência sozinha não liga a cena.
func _gravar_sem_confirmacao() -> void:
	var config := ConfigFile.new()
	if config.load("user://succubus_shop_save.cfg") != OK:
		print("      (não deu para abrir o save descartável)")
		return
	config.set_value("game", "adult_content_confirmed", false)
	config.save("user://succubus_shop_save.cfg")


func _apagar_save() -> void:
	var caminho: String = ProjectSettings.globalize_path("user://") + "succubus_shop_save.cfg"
	if FileAccess.file_exists(caminho):
		DirAccess.remove_absolute(caminho)
		if FileAccess.file_exists(caminho):
			print("      (o save descartável não apagou: %s)" % caminho)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
