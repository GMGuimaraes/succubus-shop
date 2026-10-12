extends Node
## Sons e música do jogo. Os arquivos em res://audio/ são gerados por
## tools/generate_audio.py (síntese própria, sem direitos de terceiros).
## Volume e mudo ficam em user://audio_settings.cfg, separado do save do jogo.

const SETTINGS_PATH := "user://audio_settings.cfg"
const SFX_POOL := 6
const MUSIC_OFFSET_DB := -9.0

var muted: bool = false
var volume: float = 0.7

var _streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _next_sfx: int = 0

func _ready() -> void:
	for i in range(SFX_POOL):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)
	_load_settings()
	_apply_volume()
	start_music()

func play(sound: String) -> void:
	if muted or _sfx_players.is_empty():
		return
	var stream := _get_stream(sound)
	if stream == null:
		return
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % SFX_POOL
	player.stream = stream
	player.volume_db = _volume_db()
	player.play()

func start_music() -> void:
	if muted or _music_player == null or _music_player.playing:
		return
	var stream := _get_stream("music_tavern")
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = _volume_db() + MUSIC_OFFSET_DB
	_music_player.play()

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		if _music_player != null:
			_music_player.stop()
	else:
		start_music()
	_save_settings()

func toggle_muted() -> void:
	set_muted(not muted)

func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save_settings()

func _volume_db() -> float:
	return linear_to_db(maxf(volume, 0.0001))

func _apply_volume() -> void:
	if _music_player != null:
		_music_player.volume_db = _volume_db() + MUSIC_OFFSET_DB

func _on_music_finished() -> void:
	if not muted:
		_music_player.play()

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
