extends RefCounted
## Local-first diagnostics. Reports are never sent until the player reviews them
## in GitHub and presses its public Issue submission button.

const MAX_LOG_CHARACTERS := 1500
const ISSUE_URL := "https://github.com/GMGuimaraes/succubus-shop/issues/new"

static func build_report(player_name: String) -> String:
	var engine_version := Engine.get_version_info()
	var log_excerpt := _recent_log()
	var static_memory_mib := float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0
	var display_name := player_name.strip_edges()
	if display_name.is_empty():
		display_name = "Anônimo"
	display_name = display_name.left(40).replace("\n", " ").replace("\r", " ")
	return "\n".join([
		"## Relatório de bug — Succubus Shop Alpha",
		"",
		"**Nome informado pelo jogador:** %s" % display_name,
		"**Versão:** %s" % str(ProjectSettings.get_setting("application/config/version", "alpha")),
		"**Sistema:** %s" % OS.get_name(),
		"**Godot:** %s" % str(engine_version.get("string", "desconhecida")),
		"**FPS no momento do relatório:** %d" % Engine.get_frames_per_second(),
		"**Memória estática estimada:** %.1f MiB" % static_memory_mib,
		"",
		"### O que aconteceu?",
		"_Descreva o problema e como reproduzi-lo._",
		"",
		"### Log recente",
		"```text",
		log_excerpt,
		"```",
		"",
		"_Este relatório foi preparado no dispositivo. Nenhum dado é enviado automaticamente._",
	])

static func issue_url(player_name: String) -> String:
	var title := "Bug report — Succubus Shop Alpha"
	return "%s?title=%s&body=%s" % [
		ISSUE_URL,
		title.uri_encode(),
		build_report(player_name).uri_encode(),
	]

static func _recent_log() -> String:
	var path := ProjectSettings.globalize_path("user://logs/godot.log")
	if not FileAccess.file_exists(path):
		return "O arquivo de log ainda não foi criado nesta sessão."
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return "Não foi possível ler o log local (erro %d)." % FileAccess.get_open_error()
	var log_length := file.get_length()
	file.seek(maxi(0, log_length - MAX_LOG_CHARACTERS * 4))
	var log_text := file.get_buffer(mini(log_length, MAX_LOG_CHARACTERS * 4)).get_string_from_utf8()
	if log_text.length() > MAX_LOG_CHARACTERS:
		log_text = log_text.substr(log_text.length() - MAX_LOG_CHARACTERS)
	return log_text.strip_edges()
