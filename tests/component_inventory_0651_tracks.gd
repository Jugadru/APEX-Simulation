extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const I = preload("res://scripts/core/component_inventory_0651.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL " + message)
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	for code in ["GBR","ITA","SIN"]:
		if not OS.get_cmdline_user_args().is_empty() and code not in OS.get_cmdline_user_args(): continue
		var track: Dictionary = {}
		for t in season.tracks:
			if t.code == code: track = t
		var a = Race.new(season.teams,"Ferrari",6511,{},track,{})
		var b = Race.new(season.teams,"Ferrari",6511,{},track,{})
		a.configure_weather("Variável"); b.configure_weather("Variável")
		for r in [a,b]:
			for c in r.player_cars(): c.pit_control_mode = "IA"
		var state := {"levels":{}}
		I.ensure(state,["Motor","Asa","Chassi"])
		a.running = true; b.running = true
		var ticks := 0
		while not a.finished and ticks < 4000:
			a.step(4.0); b.step(4.0)
			I.observe(state.component_inventory,code,b,{"season":1,"round":1})
			ticks += 1
			if ticks % 100 == 0:
				check(JSON.stringify(a.get_state_snapshot()) == JSON.stringify(b.get_state_snapshot()),code+" snapshot parity")
		check(a.finished and b.finished,code+" full GP completed")
		check(JSON.stringify(a.cars) == JSON.stringify(b.cars),code+" complete cars parity")
		check(JSON.stringify(a.events) == JSON.stringify(b.events),code+" events parity")
		var players: Array = b.player_cars()
		players.sort_custom(func(x,y): return int(x.id)<int(y.id))
		for index in range(2):
			var id := I.installed(state.component_inventory,index+1,"Motor")
			var km: float = state.component_inventory.parts[id].km
			check(absf(km-maxf(0,float(players[index].progress))*b.lap_km)<0.00001,code+" measured km")
		var before := JSON.stringify(state.component_inventory)
		I.observe(state.component_inventory,code,b,{})
		check(before == JSON.stringify(state.component_inventory),code+" duplicate observation idempotent")
		print("TRACK_0651 ",code," finished=",b.finished," ticks=",ticks," clock=",b.clock," errors=",failures)
	quit(0 if failures == 0 else 1)
