extends Node
## Efeitos sonoros do jogo. Os arquivos em res://audio/ sao gerados por
## tools/generate_audio.py (sintese propria, sem direitos de terceiros).
## Volume e mudo ficam em user://audio_settings.cfg, separado do save do jogo.
## A musica de fundo e controlada pelo main.gd; ele consulta `muted`/`volume`.

signal settings_changed

const SETTINGS_PATH := "user://audio_settings.cfg"
const SFX_POOL := 6

## Corte em dB por som, medido no arquivo: o RMS de cada wav cai em torno de
## -17 dBFS depois do corte, para a notificação deixar de gritar mais alto que o
## clique e para o "buy" (-9.9 dBFS) não atropelar a música.
const SFX_TRIM_DB := {
	"buy": -7.0,
	"sad": -6.0,
	"craft": -4.0,
	"coin": -3.0,
	"happy": -2.0,
	"levelup": -2.0,
	"rare": -1.5,
	"talent": -1.0,
	"click": 0.0,
}
const SFX_DEFAULT_TRIM_DB := -3.0

## Quanto um som fica quieto antes de poder tocar de novo, em segundos. Os longos
## (conquista, nível, evento) são os que mais se empilham quando vários clientes
## batem na porta no mesmo tique, então são os que mais esperam.
const SFX_COOLDOWN_SECONDS := {
	"levelup": 1.4,
	"rare": 1.4,
	"talent": 1.4,
	"sad": 0.8,
	"happy": 0.8,
	"coin": 0.6,
	"buy": 0.6,
	"craft": 0.6,
	"click": 0.05,
}
const SFX_DEFAULT_COOLDOWN_SECONDS := 0.4
## O clique é o gesto da mão: ele responde sempre, porque fila de som não pode
## engolir o feedback de um botão que foi apertado.
const SFX_NEVER_QUEUED := ["click"]
## Janela de rajada: no máximo dois sons novos por meia segunda, não importa de
## quantos fregueses a fila precise ao mesmo tempo.
const SFX_BURST_LIMIT := 2
const SFX_BURST_WINDOW_MS := 500

var muted: bool = false
var volume: float = 0.7

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0
var _last_play_ms: Dictionary = {}
var _burst_start_ms: int = -999999
var _burst_count: int = 0
var _dropped_count: int = 0

func _ready() -> void:
	for i in range(SFX_POOL):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)
	_load_settings()

## Toca um efeito, se a janela de rajada e o resfriamento do som permitirem.
## `force` é para o gesto da mão (clique, botão), que tem de responder sempre. O
## retorno diz se soou: quem empilha visitas usa isso para saber que ficou na
## fila silenciosa.
func play(sound: String, force: bool = false) -> bool:
	if muted or _sfx_players.is_empty():
		return false
	var now := Time.get_ticks_msec()
	if not _allows(sound, now, force):
		_dropped_count += 1
		return false
	var stream := _get_stream(sound)
	if stream == null:
		return false
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_POOL
	player.stream = stream
	var trim := float(SFX_TRIM_DB.get(sound, SFX_DEFAULT_TRIM_DB))
	player.volume_db = linear_to_db(maxf(volume, 0.0001)) + trim
	# Headless nao tem ouvido: o `play()` criaria um playback na thread de audio que
	# so e destruido alguns frames depois, e a sonda que chama `quit()` em seguida
	# devolve essa criacao como vazamento no fim do log. A contabilidade de resfriamento
	# e de janela de rajada segue identica -- o que falta e apenas o som.
	if DisplayServer.get_name() != "headless":
		player.play()
	_last_play_ms[sound] = now
	# O clique é o eco do botão, não um concorrente: ele toca e não gasta a janela
	# que os avisos de verdade disputam pelo ouvido.
	if not SFX_NEVER_QUEUED.has(sound) and not force:
		if now - _burst_start_ms > SFX_BURST_WINDOW_MS:
			_burst_start_ms = now
			_burst_count = 0
		_burst_count += 1
	return true

## Quantos sons a janela derrubou desde o último carregamento: é o número que a
## fila mostra para provar que cliente em espera não significa som em dobro.
func dropped_count() -> int:
	return _dropped_count

## O corte aplicado a um som, em dB. Existe para o painel de áudio e para o probe
## poderem ler o número em vez de adivinhar o que a orelha vai ouvir.
func trim_of(sound: String) -> float:
	return float(SFX_TRIM_DB.get(sound, SFX_DEFAULT_TRIM_DB))

func _allows(sound: String, now: int, force: bool) -> bool:
	# Forçado é o som que a interface prometeu ao clique do jogador: esse toca, não
	# importa quantos avisos a fila do balcão já tenha empurrado para a janela.
	if force:
		return true
	if SFX_NEVER_QUEUED.has(sound):
		return true
	var cooldown := float(SFX_COOLDOWN_SECONDS.get(sound, SFX_DEFAULT_COOLDOWN_SECONDS))
	var last := int(_last_play_ms.get(sound, -999999))
	if now - last < int(cooldown * 1000.0):
		return false
	return not (_burst_count >= SFX_BURST_LIMIT and now - _burst_start_ms <= SFX_BURST_WINDOW_MS)

func set_muted(value: bool) -> void:
	muted = value
	_save_settings()
	settings_changed.emit()

func toggle_muted() -> void:
	set_muted(not muted)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_save_settings()
	settings_changed.emit()

func _get_stream(sound: String) -> AudioStream:
	if not _streams.has(sound):
		var path := "res://audio/%s.wav" % sound
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sound]

## Sair com um efeito ainda tocando deixa para tras o `AudioStreamPlaybackWAV` que o
## AudioServer criou naquela reproducao, e com ele o `.wav` continuando "em uso" no
## cache de recursos -- e sao exatamente as duas linhas de vazamento que todo smoke
## vinha tolerando por nome no portao. Parar os players e soltar o cache na saida da
## arvore devolve os dois antes de o AudioServer fechar.
func _exit_tree() -> void:
	for player in _sfx_players:
		if is_instance_valid(player):
			player.stop()
	_sfx_players.clear()
	_streams.clear()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	muted = bool(config.get_value("audio", "muted", muted))
	volume = clampf(float(config.get_value("audio", "volume", volume)), 0.0, 1.0)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.set_value("audio", "volume", volume)
	config.save(SETTINGS_PATH)
