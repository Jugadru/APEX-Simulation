extends RefCounted
## APEX 0.6.2.3 — extracted responsibility; main.gd remains the scene host.
## The wrapper preserves legacy signals and callbacks.

const RaceEngineerScript = preload("res://scripts/core/race_engineer_0639.gd")
static func _select_pre_race_team_mode(host, index: int) -> void:
	host.team_control_mode = "Automático" if index == 1 else "Manual"


static func _select_live_team_mode(host, index: int) -> void:
	host._apply_team_control("Automático" if index == 1 else "Manual")
	host._update_game_ui()


static func _apply_team_control(host, mode: String) -> void:
	if mode not in ["Manual", "Automático"]:
		return
	host.team_control_mode = mode
	host.autonomy_fingerprints.clear()
	if host.pre_race_team_mode_picker != null:
		host.pre_race_team_mode_picker.select(1 if mode == "Automático" else 0)
	if host.live_team_mode_picker != null:
		host.live_team_mode_picker.select(1 if mode == "Automático" else 0)
	if host.race == null:
		return
	for car in host.race.player_cars():
		var car_id: int = int(car["id"])
		host.engineer_driver_modes[car_id] = mode
		if host.replay_session != null:
			host.replay_session.enqueue("driver_control", [car_id, mode], -1, mode)
		else:
			host.race.set_pit_control_mode(car_id, "IA" if mode == "Automático" else "Manual")
	if mode == "Automático":
		host._autonomy_tick()


static func engineer_mode_for(host, car_id: int) -> String:
	return str(host.engineer_driver_modes.get(car_id, "Automático" if host.team_control_mode == "Automático" else "Manual"))


static func set_engineer_driver_mode(host, car_id: int, mode: String) -> void:
	if host.race == null or mode not in ["Manual", "Assistido", "Automático"]:
		return
	var found: bool = false
	for car in host.race.player_cars():
		if int(car["id"]) == car_id and not bool(car.get("finished", false)):
			found = true
			break
	if not found:
		return
	host.engineer_driver_modes[car_id] = mode
	host.autonomy_fingerprints.erase(car_id)
	# Assistido = STAFF decides pace/KERS, player retains pit authority.
	# A scheduled manual stop is protected by RaceEngine regardless of mode.
	if host.replay_session != null:
		host.replay_session.enqueue("driver_control", [car_id, mode], -1, mode)
		return
	host.race.set_pit_control_mode(car_id, "IA" if mode == "Automático" else "Manual")
	host.race._event("strategy", car_id, "STAFF | controle individual: %s." % mode, 45)
	if mode != "Manual":
		_autonomy_tick(host)


static func _autonomy_tick(host) -> void:
	# After session initialization only fixed ticks may execute autonomy.
	if host.replay_session != null: return
	if host.race == null or host.race.finished:
		return
	var staff: Dictionary = host.garage.effective_staff_levels(host.selected_team)
	var weather: Dictionary = host.race.weather_snapshot()
	var wet_bucket: int = int(float(weather.get("wetness_factor", 0.0)) * 5.0)
	for car in host.race.player_cars():
		if bool(car.get("finished", false)):
			continue
		var car_id: int = int(car["id"])
		if engineer_mode_for(host, car_id) == "Manual":
			continue
		var fingerprint: String = "%d/%d/%s/%d" % [int(car.get("laps_done", 0)), wet_bucket, str(car.get("tire", "")), int(float(car.get("wear", 0.0)) / 15.0)]
		if str(host.autonomy_fingerprints.get(car_id, "")) == fingerprint:
			continue
		host.autonomy_fingerprints[car_id] = fingerprint
		var advice: Dictionary = host.race.get_engineer_advice(car_id)
		var decision: Dictionary = RaceEngineerScript.evaluate(car, advice, weather, staff, host.race.lap_count)
		var old_pace: String = str(car.get("pace", "Normal"))
		var old_kers: String = str(car.get("kers_mode", "Equilibrado"))
		host.race.set_pace(car_id, str(decision["pace"]))
		host.race.set_kers_mode(car_id, str(decision["kers"]))
		if old_pace != str(car.get("pace", "Normal")) or old_kers != str(car.get("kers_mode", "Equilibrado")):
			host.race._event("strategy", car_id, "STAFF | %s: ritmo %s, KERS %s (%s)." % [str(car.get("name", "Piloto")), str(car.get("pace", "Normal")), str(car.get("kers_mode", "Equilibrado")), str(decision.get("reason", "decisao automatica"))], 46)
		# IA de pit da 0.5.8.0 continua responsável pela chamada no cruzamento de volta.


static func _change_pace(host, index: int, id: int) -> void:
	if host.race != null and engineer_mode_for(host, id) == "Manual":
		host.race.set_pace(id, ["Conservar", "Normal", "Atacar"][index])


static func _request_pit(host, id: int, tire_select: OptionButton) -> void:
	if host.race != null:
		if tire_select.selected < 0:
			return
		host.race.order_pit(id, tire_select.get_item_text(tire_select.selected))
		host._update_game_ui()


static func _change_pit_mode(host, index: int, car_id: int) -> void:
	if host.race != null and engineer_mode_for(host, car_id) != "Automático":
		host.race.set_pit_control_mode(car_id, "IA" if index == 1 else "Manual")
		host._update_game_ui()


static func _schedule_pit(host, id: int, tire_select: OptionButton, lap_select: SpinBox) -> void:
	if host.race != null and tire_select.selected >= 0:
		host.race.schedule_pit(id, tire_select.get_item_text(tire_select.selected), int(lap_select.value))
		host._update_game_ui()


static func _cancel_scheduled_pit(host, id: int) -> void:
	if host.race != null:
		host.race.cancel_scheduled_pit(id)
		host._update_game_ui()


static func _toggle_race(host) -> void:
	if host.race == null:
		return
	if host.replay_session != null and host.replay_session.playback:
		if host.replay_session.tick < host.replay_session.end_tick:
			host.race.running = not host.race.running
		return
	if host.race.finished:
		if host.championship_race_active and not host.championship_result_saved:
			host._commit_championship_result()
			return
		if host.championship_race_active and host.championship_result_saved:
			host._show_menu()
			if host.championship.is_complete():
				host._show_championship_table()
			else:
				host._resume_championship()
		return
	host.race.running = not host.race.running
	host.run_button.text = "⏸ PAUSAR" if host.race.running else "▶ CONTINUAR"

