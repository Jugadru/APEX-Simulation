extends SceneTree
const Traffic = preload("res://scripts/core/race_driver_traffic_06693.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
var checks := 0
func verify(ok: bool, message: String) -> void:
	checks += 1
	assert(ok, message)
func car(id: int, p: float) -> Dictionary:
	return {"id": id, "progress": p, "race_lane": 0.0,
		"pit_left": 0.0, "finished": false, "skill": 80,
		"risk_tolerance": 60.0, "spatial_awareness": 85.0,
		"defense_aggression": 60.0, "attack_charge": 1.4,
		"combat_state": "closing", "combat_target_id": -1,
		"combat_attempts": 0, "combat_pass_pending": false,
		"combat_hesitation_s": 0.0, "wear": 10.0,
		"combat_cooldown": 0.0, "race_defending_against": -1,
		"race_defense_line": 0.0}
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var fast := car(1, 1.350)
	var backmarker := car(2, 0.365)
	var weather := {"wetness_factor": 0.0}
	var blue := Traffic.evaluate(fast, backmarker, 15.0, 2.95, weather)
	verify(bool(blue.lapping), "Lapping car sees backmarker")
	verify(bool(blue.yield_early), "Clear early safe yield")
	verify(not bool(Traffic.evaluate(backmarker, fast, 15.0, 2.95, weather).lapping), "No inverted blue flags")
	verify(not bool(Traffic.evaluate(fast, backmarker, 6.0, 2.95, weather).yield_early), "No lateral move in overlap")
	verify(not bool(Traffic.evaluate(fast, backmarker, 15.0, 1.5, weather).yield_early), "No yield in narrow corners")
	verify(not bool(Traffic.evaluate(fast, backmarker, 15.0, 2.95, {"wetness_factor": 1.0}).yield_early), "Wet overlap threshold is conservative")
	backmarker.pit_left = 3.0
	verify(not bool(Traffic.evaluate(fast, backmarker, 15.0, 2.95, weather).lapping), "Pit entry ignored")
	backmarker.pit_left = 0.0
	var track := {"race_width_m": 14.0, "overtake_zones": [[0.0, 1.0]]}
	var metrics := {1: {"target": 85.0}, 2: {"target": 90.0}}
	var pair := [fast, backmarker]
	var original := pair.duplicate(true)
	var first := Space.plan(pair, metrics, 0.2, track, {"length": 1000.0}, weather)
	var second := Space.plan(pair.duplicate(true), metrics.duplicate(true), 0.2, track, {"length": 1000.0}, weather.duplicate(true))
	verify(var_to_bytes(first) == var_to_bytes(second), "Frozen inputs are deterministic")
	verify(var_to_bytes(pair) == var_to_bytes(original), "Observer never modifies input snapshot")
	verify(float(first[1].progress) >= 1.350 and float(first[2].progress) >= 0.365, "No negative progress")
	verify(first.has(1) and first.has(2), "Both cars remain simulated")
	print("DRIVER_TRAFFIC_06693_PASS ", {"checks": checks})
	quit()
