extends SceneTree

## Sonda da trilha e do shutdown. A casa tem **duas** faixas desde que a clássica voltou
## ao salão: a herdada do protótipo (`assets/shop_theme_loop.mp3`, alegre) e a sintetizada
## pelo projeto (`audio/shop_theme_loop.wav`, grave). Prova cinco coisas que a tela não
## mostra:
##
## 1. As duas faixas carregam, cada uma com o laço do próprio formato: o `.wav` fecha o
##    laço em amostras (o importador traz `loop_end = 0`, e 0 NÃO é "até o fim"), o `.mp3`
##    liga `loop` e quem conta o fim é o decodificador. Os comprimentos medidos nesta
##    árvore são 91,64 s (clássica) e 45,71 s (sombria).
## 2. O turno escolhido pela tabela bate com a faixa no ar: os três infortúnios (alarme,
##    ruína, vigário) ouvem a sombria, o salão e os quatro setores ouvem a clássica.
## 3. Trocar de sala **não** reinicia a música: a faixa no player continua a mesma
##    instância quando só o tom muda, e só vira outra quando o turno cruza. Sem essa
##    asserção, cada troca de setor recomeçaria a trilha do zero e a loja pareceria
##    quebrada sem nenhum erro no log.
## 4. Em `--headless` a trilha fica montada (player válido, faixa carregada, volume e
##    situação aplicados), mas **nenhuma reprodução é iniciada**. Headless não tem ouvido,
##    e o `play()` criaria no AudioServer um playback (`AudioStreamPlaybackMP3` ou
##    `AudioStreamPlaybackWAV`) destruído só pela thread de áudio, alguns frames depois —
##    num processo que chama `quit()` em seguida essa destruição nunca acontece, e as duas
##    linhas de vazamento voltam ao log. Medido: forçando a reprodução, 3 vazamentos em 5
##    rodadas antes do corte e 1 em 5 depois (o `_parar_trilha()` da saída ajuda, não
##    fecha); com a clássica no ar, 1 em 2, e o `--verbose` nomeia `AudioStreamMP3` +
##    `AudioStreamPlaybackMP3` sobre `res://assets/shop_theme_loop.mp3` — o contêiner não é
##    a causa, é só o nome que aparece. Sem reprodução, 0 linhas em 9 rodadas desta árvore.
## 5. `_parar_trilha()` é idempotente e solta as **duas** faixas, então fechar a janela
##    pelo ✕ e a saída da árvore não duplicam o gesto nem deixam a faixa do turno contrário
##    contando como recurso vivo. E o corte de headless muda só o som, não a conta:
##    resfriamento, janela de rajada e `_dropped_count` de `audio.gd` continuam idênticos,
##    porque a contabilidade acontece antes do `play()`.
##
## A prova do vazamento em si é o relatório de saída do motor: rodar a sonda e grep o log.
## Zero linhas de "leaked" / "still in use" é o veredito.
##
## Dois modos, um processo cada:
##   confere  — os asserts abaixo (padrão, sem argumento)
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
var _conferencias := 0

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

	print("── as duas faixas e o laço de cada formato ──")
	var classica := game.music_classic_stream as AudioStreamMP3
	var sombria := game.music_somber_stream as AudioStreamWAV
	_confere(classica != null, "a clássica herdada carrega como AudioStreamMP3")
	_confere(sombria != null, "a sombria sintetizada carrega como AudioStreamWAV")
	if classica != null:
		_confere(bool(classica.loop), "a clássica esta com loop ligado")
		print("   clássica %.2f s • sombria %.2f s" % [classica.get_length(), sombria.get_length()])
	if sombria != null:
		_confere(int(sombria.loop_mode) == int(AudioStreamWAV.LOOP_FORWARD), "a sombria esta em LOOP_FORWARD")
		var amostras := floori(sombria.get_length() * float(sombria.mix_rate)) - 1
		_confere(int(sombria.loop_end) == amostras, "a sombria laça na ultima amostra (%d, nao 0)" % amostras)
		_confere(int(sombria.loop_begin) == 0, "a sombria laça do amostra 0")

	print("── o player em headless: montado, afinado, mudo ──")
	var headless := DisplayServer.get_name() == "headless"
	_confere(is_instance_valid(game.music_player), "a trilha fica montada mesmo sem ouvido")
	if is_instance_valid(game.music_player):
		_confere(game.music_player.stream != null, "uma faixa esta no player")
		_confere(not bool(game.music_player.is_playing()), "em headless nenhuma reprodução é iniciada")
		var esperado_db: float = game.music_base_db + linear_to_db(maxf(game.audio.volume, 0.0001))
		_confere(is_equal_approx(game.music_player.volume_db, esperado_db), "o volume da situação foi aplicado")
	_confere(is_equal_approx(game.music_base_db, game._music_situation()["db"]), "a trilha situacional le o dB da tabela")

	print("── quem manda em cada turno ──")
	var no_ar: AudioStream = game.music_player.stream if is_instance_valid(game.music_player) else null
	_confere(no_ar == classica, "o salão acordou na clássica")
	_confere(str(game._music_situation()["track"]) == "clássica", "a tabela marca o salão como clássico")
	_confere(str(game.music_track_on_air) == "clássica", "o turno no ar é o clássico")
	for caso in [
		["alarme", {"music_alarm_until": 99}],
		["ruína", {"debt": 99999}],
	]:
		game._reset_run()
		for chave in caso[1].keys():
			game[chave] = caso[1][chave]
		var tune: Dictionary = game._music_situation()
		game._apply_situation_music()
		_confere(str(tune["track"]) == "sombria", "%s pede a faixa sombria" % caso[0])
		_confere(game.music_player.stream == sombria, "%s pôs a sombria no ar" % caso[0])
		_confere(str(game.music_track_on_air) == "sombria", "%s registrou o turno sombrio" % caso[0])
		_confere(is_equal_approx(float(game.music_player.pitch_scale), float(tune["pitch"])),
				"%s afinou o pitch para %.2f" % [caso[0], float(tune["pitch"])])
	game._reset_run()
	game._set_sector("reception")
	game.music_alarm_until = 0
	game.debt = 0
	game.shop_day = 20
	game.vicar_announced_day = 20
	_confere(bool(game._vicar_waiting()), "a sonda montou o vigário à espera (dia 20, sem dízimo)")
	var tune_vigario: Dictionary = game._music_situation()
	game._apply_situation_music()
	_confere(str(tune_vigario["name"]) == "vigário na porta", "o vigário na porta é quem manda na tabela")
	_confere(str(tune_vigario["track"]) == "sombria", "o vigário na porta pede a sombria")
	_confere(game.music_player.stream == sombria, "o vigário pôs a sombria no ar")

	print("── trocar de sala não reinicia a trilha ──")
	game._reset_run()
	game.music_alarm_until = 0
	game._set_sector("reception")
	game._apply_situation_music()
	var antes_sala = game.music_player.stream
	var pitch_salao := float(game.music_player.pitch_scale)
	game._set_sector("forge")
	game._apply_situation_music()
	_confere(game.music_player.stream == antes_sala, "recepção -> forja mantém a MESMA instância de faixa")
	_confere(float(game.music_player.pitch_scale) != pitch_salao, "recepção -> forja move só o pitch (%.2f -> %.2f)" % [
		pitch_salao, float(game.music_player.pitch_scale)])
	game.debt = 99999
	game._apply_situation_music()
	_confere(game.music_player.stream != antes_sala, "a ruína, essa sim, cruza de faixa")

	print("── faixa ausente não cala a casa ──")
	var guarda_classica = game.music_classic_stream
	game.music_classic_stream = null
	_confere(game._trilha_do_turno("clássica") == sombria, "sem clássica o turno clássico cai na sombria")
	game.music_classic_stream = guarda_classica
	game.music_somber_stream = null
	_confere(game._trilha_do_turno("sombria") == classica, "sem sombria o turno sombrio cai na clássica")
	game.music_somber_stream = sombria

	# 5 — parar a trilha é seguro repetir e solta as duas referências.
	game._parar_trilha()
	_confere(not is_instance_valid(game.music_player), "_parar_trilha() largou o player")
	_confere(game.music_classic_stream == null, "_parar_trilha() largou a clássica")
	_confere(game.music_somber_stream == null, "_parar_trilha() largou a sombria")
	_confere(str(game.music_track_on_air) == "", "_parar_trilha() zerou o turno no ar")
	game._parar_trilha()
	_confere(true, "chamar _parar_trilha() duas vezes não quebra")
	game._apply_music_settings()
	_confere(true, "_apply_music_settings() com a trilha largada não quebra")
	game._apply_situation_music()
	_confere(true, "_apply_situation_music() com a trilha largada não quebra")

	# 3 — a contabilidade do modulo de audio nao depende de haver som.
	var mod: Node = game.audio
	var contagem := 0
	var derrubadas_antes := int(mod._dropped_count)
	var ultimo_antes := int(mod._last_play_ms.get("coin", -999999))
	var primeiro := bool(mod.play("coin"))
	var segundo := bool(mod.play("coin"))
	_confere(primeiro, "o primeiro moeda passa pela janela de rajada")
	_confere(not segundo, "o segundo moeda cai no resfriamento, com ouvido ou nao")
	_confere(int(mod._dropped_count) == derrubadas_antes + 1, "a janela derrubada continua sendo contada")
	_confere(int(mod._last_play_ms.get("coin", -999999)) != ultimo_antes, "o carimbo do ultimo som foi gravado")

	print("SONDA-MUSICA: veredito • modo=%s • quebras=%d • conferências=%d • headless=%s" % [
		modo, _quebras, _conferencias, str(headless)])
	quit()

func _tocando(game: Node) -> bool:
	return is_instance_valid(game.music_player) and bool(game.music_player.is_playing())


func _confere(ok: bool, rotulo: String) -> void:
	_conferencias += 1
	if ok:
		return
	_quebras += 1
	print("SONDA-MUSICA: QUEBRA • %s" % rotulo)

func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
