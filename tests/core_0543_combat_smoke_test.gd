extends SceneTree
## Headless integration test for Core 2-only v0.5.4.3.
## Run: godot --headless --path . --script res://tests/core_0543_combat_smoke_test.gd

const RaceScript = preload("res://scripts/race_engine.gd")
const Combat = preload("res://scripts/core/race_combat.gd")

func _initialize() -> void:
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	assert(typeof(season) == TYPE_DICTIONARY)
	var teams: Array = season["teams"]
	var spa: Dictionary = {}
	for item in season["tracks"]:
		if str(item.get("code", "")) == "BEL":
			spa = item
			break
	assert(not spa.is_empty())
	var first = RaceScript.new(teams, "Ferrari", 84, {"Motor": 0, "Asa": 0, "Chassi": 0}, spa)
	var twin = RaceScript.new(teams, "Ferrari", 84, {"Motor": 0, "Asa": 0, "Chassi": 0}, spa)
	assert(first.simulation_profile == "core2")
	assert(first.available_pit_compounds() == ["Médio", "Duro", "Intermediário", "Chuva"])
	assert(first.cars.size() == 24)
	for car in first.cars:
		assert(first.available_pit_compounds().has(car["tire"]))
		assert(car.has("combat_state"))
		assert(car.has("combat_attempts"))
	var pit_driver: int = int(first.player_cars()[0]["id"])
	var target: String = str(first.available_pit_compounds()[1])
	first.order_pit(pit_driver, target)
	twin.order_pit(pit_driver, target)
	first.running = true
	twin.running = true
	for tick in range(100):
		first.step(4.0)
		twin.step(4.0)
	for idx in range(first.cars.size()):
		var a: Dictionary = first.cars[idx]
		var b: Dictionary = twin.cars[idx]
		assert(is_equal_approx(float(a["progress"]), float(b["progress"])))
		assert(is_equal_approx(float(a["wear"]), float(b["wear"])))
		assert(int(a["stops"]) == int(b["stops"]))
		assert(int(a["combat_attempts"]) == int(b["combat_attempts"]))
	assert(first.get_pit_history().size() == twin.get_pit_history().size())
	assert(first.telemetry != null)
	_test_contested_pass()
	print("APEX 0.5.4.3 COMBAT CORE 2 OK — determinismo, pneus, boxes, combate")
	quit(0)

func _test_contested_pass() -> void:
	var leader: Dictionary = {"id": 99, "progress": 0.20, "skill": 78, "wear": 30.0,
		"pit_left": 0.0, "finished": false}
	var attacker: Dictionary = {"id": 98, "progress": 0.199, "skill": 93, "wear": 10.0,
		"combat_target_id": -1, "combat_state": Combat.CLEAR, "combat_duel_time": 0.0,
		"combat_cooldown": 0.0, "attack_charge": 0.0, "combat_attempts": 0}
	var attempted: bool = false
	var completed: bool = false
	for tick in range(180):
		var prior: float = float(attacker["progress"])
		var result: Dictionary = Combat.advance(attacker, prior, prior + 0.2 / 98.0,
			leader, 105.0, 98.0, 105.0, 0.2, {"overtake_zones": [[0.0, 1.0]]})
		attacker["progress"] = float(result["progress"])
		leader["progress"] = float(leader["progress"]) + 0.2 / 105.0
		if str(result["event"]) == "attack":
			attempted = true
		if float(attacker["progress"]) > float(leader["progress"]):
			completed = true
			break
	assert(attempted)
	assert(completed)
	assert(int(attacker["combat_attempts"]) > 0)
