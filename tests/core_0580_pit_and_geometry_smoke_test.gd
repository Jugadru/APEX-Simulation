extends SceneTree
## v0.5.8.0 headless integration: no premature pit, overrides, geometry, determinism.
const RaceScript = preload("res://scripts/race_engine.gd")
const Geometry = preload("res://scripts/core/race_battle_geometry.gd")
const Combat = preload("res://scripts/core/race_combat.gd")

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var spa: Dictionary = {}
	for venue in data["tracks"]:
		if str(venue.get("code", "")) == "BEL":
			spa = venue
			break
	assert(not spa.is_empty())
	var sim = RaceScript.new(data["teams"], "Ferrari", 580, {}, spa, {})
	var our: Dictionary = sim.player_cars()[0]
	var car_id: int = int(our["id"])
	var tire: String = str(sim.available_pit_compounds()[1])
	assert(sim.schedule_pit(car_id, tire, 21))
	assert(int(our["pit_scheduled_lap"]) == 21)
	assert(not bool(our["pit_request"]))
	assert(not sim.schedule_pit(car_id, tire, 44))
	assert(int(our["pit_scheduled_lap"]) == 21)
	# Even if the car is explicitly positioned near the PIT entry of V4,
	# the scheduled V21 pit MUST NOT take place.
	our["progress"] = 3.940
	our["laps_done"] = 3
	sim.running = true
	sim.step(4.0)
	assert(int(our["stops"]) == 0, "V21 was executed early at V4")
	assert(int(our["pit_scheduled_lap"]) == 21)
	assert(not bool(our["pit_request"]))
	# Directly position for the scheduled entry, without running 20 full laps.
	our["progress"] = 20.940
	our["laps_done"] = 20
	sim.step(4.0)
	assert(int(our["stops"]) == 1, "V21 did not trigger at the selected entry")
	assert(int(our["pit_scheduled_lap"]) == 0)
	assert(str(our["pit_order_source"]) == "agendamento_manual")
	var first_history_event: bool = false
	for item in sim.events:
		if str(item.get("message", "")).contains("BOX AGENDADO V21"):
			first_history_event = true
	assert(first_history_event, "There must be an auditable log for the planned stop")
	var second = RaceScript.new(data["teams"], "Ferrari", 581, {}, spa, {})
	var car2: Dictionary = second.player_cars()[0]
	assert(second.schedule_pit(int(car2["id"]), tire, 21))
	assert(second.cancel_scheduled_pit(int(car2["id"])))
	assert(not second.cancel_scheduled_pit(int(car2["id"])))
	assert(int(car2["pit_scheduled_lap"]) == 0)
	assert(second.schedule_pit(int(car2["id"]), tire, 21))
	second.order_pit(int(car2["id"]), tire)
	assert(bool(car2["pit_request"]))
	assert(int(car2["pit_scheduled_lap"]) == 0)
	assert(str(car2["pit_order_source"]) == "ordem_imediata")
	var third = RaceScript.new(data["teams"], "Ferrari", 582, {}, spa, {})
	var car3: Dictionary = third.player_cars()[0]
	var id3: int = int(car3["id"])
	car3["wear"] = 98.0
	car3["stint_laps"] = 18
	car3["laps_done"] = 12
	third._request_ai_pit(car3, true)
	assert(not bool(car3["pit_request"]), "Manual mode must be consultative")
	assert(third.set_pit_control_mode(id3, "IA"))
	assert(third.schedule_pit(id3, tire, 21))
	third._request_ai_pit(car3, true)
	assert(not bool(car3["pit_request"]) and int(car3["pit_scheduled_lap"]) == 21,
		"AI must respect manually scheduled lap")
	assert(third.cancel_scheduled_pit(id3))
	third._request_ai_pit(car3, true)
	assert(bool(car3["pit_request"]), "AI mode must allow an urgent autonomous pit")
	var attacker: Dictionary = {"id": 1, "combat_attempts": 1, "risk_tolerance": 40.0, "spatial_awareness": 90.0}
	var defender: Dictionary = {"id": 2, "defense_aggression": 50.0}
	var clear: Dictionary = Geometry.evaluate(attacker, defender, {"race_width_m": 12.0})
	assert(str(clear["outcome"]) == "clear")
	var narrow: Dictionary = {"race_width_m": 5.3, "corner_convergence": 0.6, "overtake_zones": [[0.0, 1.0]]}
	var caution: Dictionary = Geometry.evaluate(attacker, defender, narrow)
	assert(str(caution["outcome"]) == "yield")
	var monaco: Dictionary = Geometry.evaluate(attacker, {"defense_aggression": 65.0}, {"code": "MON"})
	assert(str(monaco["outcome"]) == "yield", "Narrow street circuit should demand extra space")
	attacker["risk_tolerance"] = 95.0
	attacker["spatial_awareness"] = 40.0
	var insistent: Dictionary = Geometry.evaluate(attacker, defender, narrow)
	assert(str(insistent["outcome"]) == "contact")
	assert(insistent == Geometry.evaluate(attacker, defender, narrow), "Geometry must be deterministic")
	assert(float(insistent["attacker_loss_s"]) > float(insistent["defender_loss_s"]))
	# No old combat regression: normal-width overtakes still succeed.
	var lead: Dictionary = {"id": 42, "progress": 0.20, "skill": 75, "wear": 30.0, "finished": false, "pit_left": 0.0}
	var chase: Dictionary = {"id": 43, "progress": 0.199, "skill": 95, "wear": 15.0,
		"combat_target_id": -1, "combat_duel_time": 0.0, "combat_cooldown": 0.0,
		"attack_charge": 0.0, "combat_attempts": 0, "combat_state": "clear"}
	var overtook: bool = false
	for tick in range(200):
		var prev: float = float(chase["progress"])
		var result: Dictionary = Combat.advance(chase, prev, prev + 0.20 / 98.0, lead, 105.0, 98.0, 105.0, 0.2, {"overtake_zones": [[0.0, 1.0]]})
		chase["progress"] = float(result["progress"])
		lead["progress"] = float(lead["progress"]) + 0.2 / 105.0
		if float(chase["progress"]) > float(lead["progress"]):
			overtook = true
			break
	assert(overtook, "Normal passing must not be disabled by clearance checks")
	print("APEX 0.5.8.0 OK: V21/V4, manual override, cancel, lane clearance, contact and passing")
	quit(0)
