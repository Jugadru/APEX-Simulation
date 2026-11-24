extends RefCounted
const Garage = preload("res://scripts/garage.gd")
const STOCK_LEVELS := {"Asa":0,"Chassi":0,"Motor":0}
const DEVELOPED_LEVELS := {"Asa":2,"Chassi":0,"Motor":1}
const STOCK_STAFF := {"Engenheiro":0,"Estrategista":0}
const DEVELOPED_STAFF := {"Engenheiro":2,"Estrategista":1}
const STOCK_CREW := {"Agilidade":0,"Coordenação":0,"Precisão":0}
const DEVELOPED_CREW := {"Agilidade":1,"Coordenação":1,"Precisão":0}
static func configure(host, profile: String, seed_value: int) -> void:
	# New path never reads a real player's garage or a previous test's save.
	var folder := "user://qa_motion_%d_%d" % [OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	host.garage = Garage.new(folder.path_join("garage.json"))
	host.selected_team = "Ferrari"
	host.championship_mode = false
	host.team_control_mode = "Manual"
	host.pre_race_strategy_pending.clear()
	host.seed_picker.value = seed_value
	host.weather_mode_picker.select(0)
	host.pit_test_picker.select(0)
	var state: Dictionary = host.garage.get_team("Ferrari")
	state["levels"] = (DEVELOPED_LEVELS if profile=="developed" else STOCK_LEVELS).duplicate(true)
	state["staff_levels"] = (DEVELOPED_STAFF if profile=="developed" else STOCK_STAFF).duplicate(true)
	state["crew_levels"] = (DEVELOPED_CREW if profile=="developed" else STOCK_CREW).duplicate(true)
static func matches(host,profile: String,seed_value: int) -> bool:
	return host.race!=null and host.race.cars.size()==24 and not host.championship_race_active and host.selected_team=="Ferrari" and int(host.seed_picker.value)==seed_value and host.garage.get_team("Ferrari")["levels"]==(DEVELOPED_LEVELS if profile=="developed" else STOCK_LEVELS) and host.garage.effective_staff_levels("Ferrari")==(DEVELOPED_STAFF if profile=="developed" else STOCK_STAFF) and host.garage.effective_crew_levels("Ferrari")==(DEVELOPED_CREW if profile=="developed" else STOCK_CREW)
