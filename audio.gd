extends Node
## Efeitos sonoros do jogo. Os arquivos em res://audio/ sao gerados por
## tools/generate_audio.py (sintese propria, sem direitos de terceiros).
## Volume e mudo ficam em user://audio_settings.cfg, separado do save do jogo.
## A musica de fundo e controlada pelo main.gd; ele consulta `muted`/`volume`.

signal settings_changed

const SETTINGS_PATH := "user://audio_settings.cfg"
const SFX_POOL := 6

var muted: bool = false
var volume: float = 0.7

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx: int = 0

func _ready() -> void:
	for i in range(SFX_POOL):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)
	_load_settings()

func play(sound: String) -> void:
	if muted or _sfx_players.is_empty():
		return
	var stream := _get_stream(sound)
	if stream == null:
		return
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_POOL
	player.stream = stream
	player.volume_db = linear_to_db(maxf(volume, 0.0001))
	player.play()

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
