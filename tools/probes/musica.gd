extends SceneTree

## Sonda da trilha e do shutdown. Prova três coisas que a tela não mostra:
##
## 1. Em `--headless` a trilha fica montada (player válido, `.wav` carregado, volume e
##    situação aplicados), mas **nenhuma reprodução é iniciada**. Headless não tem
##    ouvido, e o `play()` criaria no AudioServer um `AudioStreamPlaybackWAV` destruído
##    só pela thread de áudio, alguns frames depois — num processo que chama `quit()`
##    em seguida essa destruição nunca acontece, e as duas linhas de vazamento
##    (`AudioStreamPlaybackWAV` + `AudioStreamWAV` "ainda em uso") voltam ao log.
##    Medido com esta sonda: forçando a reprodução, 3 vazamentos em 5 rodadas antes do
##    corte e 1 em 5 depois (o `_parar_trilha()` da saída ajuda, não fecha); nunca
##    tocando, 0 em 6.
## 2. `_parar_trilha()` é idempotente e solta a referência do `.wav`, então fechar a
##    janela pelo ✕ e a saída da árvore não duplicam o gesto nem quebram um ao outro.
## 3. O corte de headless muda só o som, não a conta: resfriamento, janela de rajada e
##    `_dropped_count` de `audio.gd` continuam rodando identicos, porque a contabilidade
##    acontece antes do `play()`.
##
## A prova do vazamento em si é o relatório de saída do motor: rodar a sonda em battery
## e grep o log. Zero linhas de "leaked" / "still in use" é o veredito.
##
## Dois modos, um processo cada:
##   confere  — os três asserts abaixo (padrão, sem argumento)
##   tocando  — força a reprodução direto no player, pulando o corte de headless, e cai
##              no `quit()` sem dar um frame à thread de áudio. Instrumento de
##              reprodução, não portão: esta modalidade ainda pode imprimir as duas
##              linhas de vazamento, e é justamente o que se espera dela. Nunca entra na
##              bateria do push — o que o portão mede é o modo `confere`.
##
## Uso:
##   env APPDATA="D:\\Downloads\\tmp-userdata" godot --headless --path . \
##     --quit-after 1800 --script res://tools/probes/musica.gd > /d/Downloads/tmp-userdata/probe.log 2>&1
##   grep -niE "leaked|still in use" /d/Downloads/tmp-userdata/probe.log   # vazio = aprovado
##   # com o modo: acrescentar " -- tocando" no fim da linha

var _quebras := 0

func _initialize() -> void:
	var modos := OS.get_cmdline_user_args()
	var modo := "confere" if modos.is_empty() else str(modos[0])
	var game := (load("res://main.tscn") as PackedScene).instantiate()
	get_root().add_child(game)
	await _frames(3)
	game.world_timer.stop()
	game._reset_run()
	game._refresh_ui()

	if modo == "tocando":
		if is_instance_valid(game.music_player):
			game.music_player.play()
		print("SONDA-MUSICA: modo=tocando • tocando=%s" % str(_tocando(game)))
		quit()
		return

	var headless := DisplayServer.get_name() == "headless"
	_confere(is_instance_valid(game.music_player), "a trilha fica montada mesmo sem ouvido")
	if is_instance_valid(game.music_player):
		_confere(game.music_player.stream != null, "a trilha da casa continua carregada no player")
		_confere(not bool(game.music_player.is_playing()), "em headless nenhuma reprodução é iniciada")
		var esperado_db: float = game.music_base_db + linear_to_db(maxf(game.audio.volume, 0.0001))
		_confere(is_equal_approx(game.music_player.volume_db, esperado_db), "o volume da situação foi aplicado")
		# 1b — o laço. `loop_end = 0` nao e "ate o fim": com LOOP_FORWARD ligado o player
		# volta ao inicio na primeira amostra e a trilha emperra. A sonda confere contra a
		# conta do motor (comprimento x taxa), nao contra o tamanho de `data` — `data` e o
		# payload ja codificado e encolhe com compressao, o que cortaria a musica no meio.
		var trilha := game.music_player.stream as AudioStreamWAV
		_confere(trilha != null, "a trilha e um AudioStreamWAV")
		if trilha != null:
			_confere(int(trilha.loop_mode) == int(AudioStreamWAV.LOOP_FORWARD), "o laço esta em LOOP_FORWARD")
			var amostras := floori(trilha.get_length() * float(trilha.mix_rate)) - 1
			_confere(int(trilha.loop_end) == amostras, "o laço fecha na ultima amostra (%d, nao 0)" % amostras)
			_confere(int(trilha.loop_begin) == 0, "o laço comeca no amostra 0")
	_confere(is_equal_approx(game.music_base_db, game._music_situation()["db"]), "a trilha situacional le o dB da tabela")

	# 2 — parar a trilha é seguro repetir e solta a referência.
	game._parar_trilha()
	_confere(not is_instance_valid(game.music_player), "_parar_trilha() largou o player")
	game._parar_trilha()
	_confere(true, "chamar _parar_trilha() duas vezes não quebra")
	game._apply_music_settings()
	_confere(true, "_apply_music_settings() com a trilha largada não quebra")

	# 3 — a contabilidade do modulo de audio nao depende de haver som.
	var mod: Node = game.audio
	var antes := int(mod._dropped_count)
	var ultimo_antes := int(mod._last_play_ms.get("coin", -999999))
	var primeiro := bool(mod.play("coin"))
	var segundo := bool(mod.play("coin"))
	_confere(primeiro, "o primeiro moeda passa pela janela de rajada")
	_confere(not segundo, "o segundo moeda cai no resfriamento, com ouvido ou nao")
	_confere(int(mod._dropped_count) == antes + 1, "a janela derrubada continua sendo contada")
	_confere(int(mod._last_play_ms.get("coin", -999999)) != ultimo_antes, "o carimbo do ultimo som foi gravado")

	print("SONDA-MUSICA: veredito • modo=%s • quebras=%d • headless=%s" % [modo, _quebras, str(headless)])
	quit()

func _tocando(game: Node) -> bool:
	return is_instance_valid(game.music_player) and bool(game.music_player.is_playing())

func _confere(ok: bool, rotulo: String) -> void:
	if ok:
		return
	_quebras += 1
	print("SONDA-MUSICA: QUEBRA • %s" % rotulo)

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
