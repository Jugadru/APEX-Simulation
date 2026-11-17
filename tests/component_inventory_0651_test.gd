extends SceneTree
const Garage = preload("res://scripts/garage.gd")
const I = preload("res://scripts/core/component_inventory_0651.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		printerr("FAIL: " + message)
func _initialize() -> void:
	var path := "user://inventory_test.json"
	var legacy := {"Ferrari":{"budget":9123456,"levels":{"Motor":2,"Asa":1,"Chassi":0},"future_field":{"keep":true},"staff_roster":{},"staff_log":["preservar"],"development_project":{"part":"Asa","cost":100,"ready_round":3}}}
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy)); f.close()
	var garage = Garage.new(path)
	var state: Dictionary = garage.get_team("Ferrari")
	var inv: Dictionary = state.component_inventory
	check(state.future_field.keep, "unknown legacy fields preserved")
	check(inv.parts.size() == 6, "migration creates six unique parts")
	check(state.budget == 9123456 and state.staff_log == ["preservar"] and state.development_project.cost == 100, "legacy data preserved")
	check(I.validate(inv,Garage.PARTS).is_empty(), "valid migrated inventory")
	var id := I.installed(inv,1,"Motor")
	var other := I.installed(inv,2,"Motor")
	check(inv.parts[id].condition == null and inv.parts[id].prior_km_unknown, "unknown telemetry explicit")
	var loaded = Garage.new(path)
	check(loaded.get_team("Ferrari").component_inventory == JSON.parse_string(JSON.stringify(inv)), "migration persisted IDs and data")
	garage.component_action("Ferrari",id,"remove",0)
	check(not I.ready(state.component_inventory,Garage.PARTS), "missing component blocks start")
	garage.component_action("Ferrari",id,"store",0)
	check(state.component_inventory.parts[id].status == "stored", "store")
	garage.component_action("Ferrari",id,"install",2)
	check(I.installed(state.component_inventory,2,"Motor") == id and state.component_inventory.parts[other].status == "available", "replace moves displaced part to stock")
	garage.component_action("Ferrari",other,"install",1)
	check(I.ready(state.component_inventory,Garage.PARTS), "swap across cars")
	var before := JSON.stringify(state.component_inventory)
	garage.component_action("Ferrari",id,"install",1)
	check(before == JSON.stringify(state.component_inventory), "duplicate installation rejected")
	garage.inventory_locked = true
	garage.component_action("Ferrari",id,"remove",0)
	check(before == JSON.stringify(state.component_inventory), "session locked")
	garage.inventory_locked = false
	garage.save_path = "/nonexistent/apex/test.json"
	check(garage.component_action("Ferrari",id,"remove",0).contains("revertida"), "write failure reported")
	check(before == JSON.stringify(state.component_inventory), "write failure rollback")
	garage.save_path = path
	loaded = Garage.new(path)
	check(loaded.get_team("Ferrari").component_inventory == JSON.parse_string(JSON.stringify(state.component_inventory)), "save reload after swap")
	garage.component_action("Ferrari",id,"remove",0)
	garage.component_action("Ferrari",id,"retire",0)
	before = JSON.stringify(state.component_inventory)
	garage.component_action("Ferrari",id,"install",2)
	check(before == JSON.stringify(state.component_inventory), "unusable part rejected")
	var bad: Dictionary = state.component_inventory.duplicate(true)
	bad.parts[id].id = "duplicate"
	check(not I.validate(bad,Garage.PARTS).is_empty(), "corrupt identifier rejected")
	# Persist real engine distance without changing its state.
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var sim = load("res://scripts/race_engine.gd").new(season.teams,"Ferrari",6511,{},season.tracks[0],{})
	garage.inventory_begin("Ferrari", {"season":1,"round":1})
	sim.running = true
	sim.step(4.0)
	var snapshot := JSON.stringify(sim.cars)
	garage.inventory_observe(sim, true)
	check(snapshot == JSON.stringify(sim.cars), "observer does not mutate engine")
	loaded = Garage.new(path)
	check(loaded.get_team("Ferrari").component_inventory == JSON.parse_string(JSON.stringify(state.component_inventory)), "real mileage save reload")
	check(FileAccess.file_exists(path+".bak"), "save backup exists")
	if failures.is_empty(): print("INVENTORY_0651_PASS migration / IDs / swap / status / lock / rollback / persistence")
	quit(0 if failures.is_empty() else 1)
