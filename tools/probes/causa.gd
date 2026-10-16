extends SceneTree

## Sonda que valida a receita "Sonda de causa" do portao: monta a loja pelo chao (o mesmo
## corpo que as sondas vivas re-declaram, nao o bancada.gd chamado por classe), roda UM
## _on_customer_tick() e imprime so as chaves que divergiriam, mais o mural linha a linha.
## Prova que as 12 chaves do bloco existem no main.gd de hoje (g.get(k) nao devolve nil).
##
## Uso:
##   env APPDATA="D:\Downloads\tmp-userdata" godot --headless --path . \
##     --quit-after 90000 --script res://tools/probes/causa.gd

const Locales := preload("res://locales.gd")

const SEED_VAL := 20261024

const CHAVES := ["gold", "reputation", "daily_gold_earned", "customers_served",
	"credit_book", "regular_bonds", "regular_arc_seen", "faction_standing",
	"player_level", "player_xp", "unlocked_achievements", "shop_day"]

func _initialize() -> void:
	var g = await _loja("causa")
	var antes := _estado(g)
	g._on_customer_tick()
	var depois := _estado(g)

	print("── inventario das 12 chaves ──")
	for k in CHAVES:
		var raw = g.get(k)
		var marca := "OK" if raw != null else "NAO EXISTE"
		var texto := str(depois[k])
		if texto.length() > 48:
			texto = texto.substr(0, 48) + "..."
		print("   %-20s %s  %s" % [k, marca, texto])

	print("── o que divergiu num unico tique ──")
	_divergiu(antes, depois)

	print("── mural linha a linha ──")
	for linha in String(g.last_event).split("\n"):
		print("   mural: ", linha)
	quit()


func _estado(g) -> Dictionary:
	var e := {}
	for k in CHAVES:
		e[k] = str(g.get(k))
	return e


func _divergiu(antes: Dictionary, depois: Dictionary) -> void:
	for k in CHAVES:
		if antes[k] != depois[k]:
			print("   %s: %s -> %s" % [k, antes[k], depois[k]])


func _loja(rotulo: String):
	var g = (load("res://main.tscn") as PackedScene).instantiate()
	g.name = rotulo
	get_root().add_child(g)
	await _frames(3)
	_fixar_locale(g)
	g.world_timer.stop()
	seed(SEED_VAL)
	g._reset_run()
	return g


func _fixar_locale(g) -> void:
	g.locale = Locales.DEFAULT
	g.locale_confirmed = true
	TranslationServer.set_locale(Locales.DEFAULT)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame
