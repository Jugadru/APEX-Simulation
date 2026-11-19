extends SceneTree
## APEX 0.6.6.8.12 — historical data / GUI / replay invariants.
const Guide = preload("res://scripts/apex_season_guide_066812.gd")
const Hud = preload("res://scripts/apex_hud_rebroadcast_0668.gd")
var checks := 0
var errors: Array[String] = []
func verify(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		errors.append(reason)
		printerr("SEASON_GUIDE_066812_FAIL ", reason)
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var team_raw := JSON.stringify(season["teams"])
	var track_raw := JSON.stringify(season["tracks"])
	var info: Dictionary = Guide.snapshot(season["teams"], season["tracks"])
	verify(int(info["season"]) == 2012, "year 2012")
	verify(info["teams"].size() == 12, "12 teams")
	verify(info["calendar"].size() == 20, "20 rounds")
	verify(info["tyres"].size() == 6, "6 compounds")
	var known_models: Dictionary = {}
	for team in info["teams"]:
		verify(not str(team["chassis"]).is_empty() and not known_models.has(str(team["chassis"])), "unique chassis " + str(team["chassis"]))
		known_models[str(team["chassis"])] = true
		verify(team["drivers"].size() == 2, "two primary drivers")
	for model in ["RB8", "MP4-27", "F2012", "F1 W03", "E20", "VJM05", "C31", "STR7", "FW34", "CT01", "F112", "MR01"]:
		verify(known_models.has(model), "2012 chassis " + model)
	var colors: Dictionary = {"SS":"#f04c54", "S":"#f4d14c", "M":"#f0f0e7",
		"H":"#c9d0d5", "I":"#50b88b", "W":"#4aa3ed"}
	for tyre in info["tyres"]:
		var code: String = str(tyre["code"])
		verify(colors.has(code) and str(tyre["color"]) == str(colors.get(code, "")), "2012 colour " + code)
		verify(Hud.tyre_tint(code) == Color(str(tyre["color"])), "HUD tyre from actual tyre data " + code)
	verify(Hud.tyre_tint("supersoft") == Hud.tyre_tint("SS"), "supersoft code alias")
	verify(Hud.tyre_tint("hard") == Hud.tyre_tint("H"), "hard code alias")
	var codes: Dictionary = {}
	var dates: Dictionary = {}
	for i in range(info["calendar"].size()):
		var event: Dictionary = info["calendar"][i]
		verify(int(event["round"]) == i + 1, "original calendar order")
		verify(not codes.has(str(event["code"])), "unique original track")
		verify(str(event["date"]).begins_with("2012-") and not dates.has(str(event["date"])), "FIA date")
		verify(event["dry"].size() == 2, "two slick nominations")
		codes[str(event["code"])] = true
		dates[str(event["date"])] = true
	verify(str(info["calendar"][0]["date"]) == "2012-03-18", "Australia first")
	verify(str(info["calendar"][19]["date"]) == "2012-11-25", "Brazil last")
	verify(JSON.stringify(season["teams"]) == team_raw, "season team source unchanged")
	verify(JSON.stringify(season["tracks"]) == track_raw, "season track source unchanged")
	var host = load("res://scenes/main.tscn").instantiate()
	root.add_child(host)
	await process_frame
	verify(host.season_guide_button != null, "guide action exists in real menu")
	host._show_season_guide()
	var popup: AcceptDialog = host.menu_root.get_node_or_null("Season2012Guide") as AcceptDialog
	verify(popup != null, "guide dialog created in real menu")
	if popup != null:
		for tab in ["PNEUS", "CARROS E EQUIPES", "CALENDÁRIO"]:
			verify(popup.find_child(tab, true, false) != null, "tab " + tab)
		verify(popup.find_child("Season2012Selection", true, false) != null, "current selection text")
		Guide._pick_team(host, 0, popup)
		verify(host.selected_team == str(host.teams[0]["name"]), "select team real callback")
		Guide._pick_track(host, 12, popup)
		verify(host.selected_track_index == 12 and host.track_picker.selected == 12, "select Monza real callback")
		verify(host.tyre_briefing_label.text.contains("Médio") and host.tyre_briefing_label.text.contains("Duro"), "Monza nominations refresh")
	verify(JSON.stringify(host.teams) == team_raw, "guide team catalogue immutable")
	verify(JSON.stringify(host.season_tracks) == track_raw, "guide track catalogue immutable")
	host._start_race()
	await process_frame
	var before: PackedByteArray = var_to_bytes(host.race.get_state_snapshot())
	var queued: int = host.replay_session.commands.size()
	Guide.snapshot(host.teams, host.season_tracks)
	verify(before == var_to_bytes(host.race.get_state_snapshot()), "race snapshot immutable")
	verify(host.replay_session.commands.size() == queued, "no fake Replay commands")
	verify(host.race.available_pit_compounds().size() == 4, "Core2 two slicks + rain unchanged")
	print("SEASON_GUIDE_066812_", "PASS" if errors.is_empty() else "FAIL",
		" checks=", checks, " teams=12 rounds=20 tyres=6 no_sporting_mutation=true issues=", errors)
	quit(0 if errors.is_empty() else 1)
