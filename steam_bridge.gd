extends Node
## Ponte opcional com a Steam. O jogo funciona sem ela: se não houver o plugin
## Steamworks como singleton, cada chamada vira no-op e o ranking cai na versão
## local de `user://hall_of_fame.cfg`.
##
## Conquistas: cada id do catálogo vira uma stat da Steam (`ACH_<id>`), liberada
## quando o jogo a desbloqueia. Cards: cada carta é um item do inventário
## (`CARD_<id>`), entregue na primeira cópia.
## Save na nuvem: o Auto-Cloud da Steam sincroniza a pasta `user://` inteira,
## então `succubus_shop_save.cfg` sobe junto sem código extra — `cloud_ready()`
## só diz se isso está de fato ativo.

signal leaderboard_ready(rows: Array)

const HALL_PATH := "user://hall_of_fame.cfg"
const LEADERBOARD_NAME := "succubus_shop_melhor_negocio"

## Rivais fixos para o placar nunca nascer vazio enquanto a Steam não chega.
const GHOSTS: Array[Dictionary] = [
	{"name": "Boteco do Belial", "score": 2400},
	{"name": "Empório Mafalda", "score": 1750},
	{"name": "Toca da Vendedora", "score": 1180},
	{"name": "Feira de Almas 24h", "score": 760},
	{"name": "Cabana do Estoque", "score": 410}
]

var steam_available := false
var cloud_ready := false
var _steam: Object = null
var _catalog: Array[String] = []
var _board: Array[Dictionary] = []
var _steam_rows: Array[Dictionary] = []

func boot(catalog: Array[String]) -> void:
	_catalog = catalog.duplicate()
	_load_hall()
	if not Engine.has_singleton("Steam"):
		return
	var singleton = Engine.get_singleton("Steam")
	if singleton == null:
		return
	_steam = singleton
	if not _steam.has_method("steamInit"):
		_steam = null
		return
	var init_result = _steam.call("steamInit", true)
	if not _init_ok(init_result):
		_steam = null
		return
	steam_available = true
	cloud_ready = true
	if _steam.has_method("requestCurrentStats"):
		_steam.call("requestCurrentStats")

func _init_ok(result) -> bool:
	if result is Dictionary:
		return int((result as Dictionary).get("status", 1)) == 0
	return bool(result)

## Libera a conquista na Steam. O jogo já deu a recompensa local antes de chamar.
func unlock(achievement_id: String) -> void:
	if not steam_available or not _steam.has_method("setAchievement"):
		return
	_steam.call("setAchievement", "ACH_%s" % achievement_id)
	if _steam.has_method("storeStats"):
		_steam.call("storeStats")

## Registra a primeira cópia de um card como item do inventário.
func grant_card(card_id: String) -> void:
	if not steam_available or not _steam.has_method("generateItem"):
		return
	_steam.call("generateItem", "STORE", "CARD_%s" % card_id)

## Envia pontuação ao placar da Steam e grava o recorde local na mesma hora.
func submit_score(score: int, label: String) -> void:
	_record_local(score, label)
	if not steam_available or not _steam.has_method("uploadLeaderboardScore"):
		return
	_steam.call("uploadLeaderboardScore", LEADERBOARD_NAME, score, false, 0, "int")
	if _steam.has_method("storeLeaderboardScores"):
		_steam.call("storeLeaderboardScores")

func request_leaderboard() -> void:
	if not steam_available or not _steam.has_method("requestLeaderboardScores"):
		emit_signal("leaderboard_ready", board())
		return
	if _steam.has_signal("leaderboardScoresDownloaded") and not _steam.is_connected(
		"leaderboardScoresDownloaded", Callable(self, "_on_scores_downloaded")):
		_steam.connect("leaderboardScoresDownloaded", Callable(self, "_on_scores_downloaded"))
	_steam.call("requestLeaderboardScores", LEADERBOARD_NAME, 0, 20, 20, 1)

## Resposta da Steam ao pedido de placar. Sem linhas novas, mantém o que já havia.
func _on_scores_downloaded(leaderboard_id: int, leaderboard_count: int) -> void:
	if not _steam.has_method("getLeaderboardEntry"):
		return
	var rows: Array[Dictionary] = []
	for i in range(leaderboard_count):
		var entry = _steam.call("getLeaderboardEntry", leaderboard_id, i)
		if not (entry is Dictionary):
			continue
		var record: Dictionary = entry
		rows.append({"name": str(record.get("name", "Loja sem nome")), "score": int(record.get("score", 0))})
	if rows.is_empty():
		return
	_steam_rows = rows
	emit_signal("leaderboard_ready", board())

func board() -> Array[Dictionary]:
	if not _steam_rows.is_empty():
		return _steam_rows.duplicate(true)
	return _board.duplicate(true)

## Onde o placar mora: Steam real, vizinhança local, nada ainda.
func board_source() -> String:
	if not _steam_rows.is_empty():
		return "Steam"
	if steam_available:
		return "Steam (pedindo placar)"
	return "Placar local"

func rank_of(score: int) -> int:
	var rows := board()
	for i in range(rows.size()):
		if int(rows[i]["score"]) < score:
			return i + 1
	return rows.size() + 1

func _record_local(score: int, label: String) -> void:
	for row in _board:
		if str(row["name"]) != label:
			continue
		if int(row["score"]) >= score:
			return
		row["score"] = score
		_sort_board()
		_save_hall()
		return
	_board.append({"name": label, "score": score})
	_sort_board()
	while _board.size() > 20:
		_board.pop_back()
	_save_hall()

func _sort_board() -> void:
	_board.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]))

func _load_hall() -> void:
	_board = []
	var config := ConfigFile.new()
	if config.load(HALL_PATH) != OK:
		for ghost in GHOSTS:
			_board.append(ghost.duplicate(true))
		return
	var saved = config.get_value("hall", "rows", [])
	if saved is Array:
		for row in saved:
			if row is Dictionary:
				_board.append({"name": str((row as Dictionary).get("name", "?")), "score": int((row as Dictionary).get("score", 0))})
	if _board.is_empty():
		for ghost in GHOSTS:
			_board.append(ghost.duplicate(true))

func _save_hall() -> void:
	var config := ConfigFile.new()
	config.set_value("hall", "rows", _board)
	config.save(HALL_PATH)
