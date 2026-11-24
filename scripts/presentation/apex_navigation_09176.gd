extends RefCounted
## Root navigation only. No sporting commands, snapshots, RNG or save writes.
## Roots are built once by the host. Back restores visibility, not race state.
var history: Array[String] = []
var race_context: Dictionary = {}
var busy := false
var scroll_positions: Dictionary = {}

func current(host) -> String:
	if host.game_root.visible: return "race"
	if host.staff_root.visible: return "staff"
	if host.garage_root.visible: return "garage"
	return "menu"

func clear_history() -> void:
	history.clear()

func forget_race_context() -> void:
	race_context.clear()

func remember_race_context(host) -> void:
	if host.race == null or not host.game_root.visible: return
	race_context = {"race": host.race.get_instance_id(), "team": host.selected_team,
		"track": host.selected_track_index, "mode": host.team_control_mode,
		"championship": host.championship_mode, "serial": int(host.championship.state.get("serial", 0)),
		"seed": host.seed_picker.value}

func can_resume(host) -> bool:
	if host.race == null: return false
	if race_context.is_empty(): return true
	if int(race_context.get("race", -1)) != host.race.get_instance_id(): return false
	return not bool(race_context.championship) or int(race_context.serial) == int(host.championship.state.get("serial", 0))

func _scroll(host, route: String) -> ScrollContainer:
	match route:
		"menu": return host.menu_scroll
		"garage": return host.garage_root.get_node("ManagementHub").content_scroll
		"staff": return host.staff_root.find_child("StaffScroll", true, false) as ScrollContainer
	return null

func _restore_scroll(host, target: String) -> void:
	if current(host) != target or not scroll_positions.has(target): return
	var scroller := _scroll(host, target)
	if is_instance_valid(scroller): scroller.scroll_vertical = int(scroll_positions[target])

func _show(host, target: String) -> void:
	var origin := current(host)
	var scroller := _scroll(host, origin)
	if is_instance_valid(scroller): scroll_positions[origin] = scroller.scroll_vertical
	host.menu_root.visible = target == "menu"
	host.garage_root.visible = target == "garage"
	host.staff_root.visible = target == "staff"
	host.game_root.visible = target == "race"
	if target == "garage": host._update_garage()
	if target == "staff": host._refresh_staff()
	if target == "menu": host._update_championship_menu()
	host._layout_ui()
	_restore_scroll.call_deferred(host, target)

func open(host, target: String) -> void:
	if busy or target not in ["garage", "staff"]: return
	busy = true
	var origin := current(host)
	if origin != target:
		if origin == "race": remember_race_context(host)
		# Preserve existing replay-exit and inventory flush behavior on entry.
		if host.replay_ui != null and host.replay_session != null and host.replay_session.playback:
			host.replay_ui.leave()
		if target == "garage": host.garage.inventory_observe(host.race, true)
		# Returning to an earlier root truncates history instead of growing cycles.
		var previous := history.find(target)
		if previous >= 0:
			history.resize(previous)
		else:
			history.append(origin)
	_show(host, target)
	busy = false

func back(host) -> void:
	if busy or current(host) not in ["garage", "staff"]: return
	busy = true
	var target: String = history.pop_back() if not history.is_empty() else "menu"
	if target == "race" and can_resume(host):
		_restore_context(host)
	elif target == "race":
		target = "menu"
	_show(host, target)
	busy = false

func resume_race(host) -> void:
	if busy or not can_resume(host): return
	busy = true
	_restore_context(host)
	clear_history()
	_show(host, "race")
	busy = false

func _restore_context(host) -> void:
	if race_context.is_empty(): return
	# Restore host session bindings only, never engine fields or replay commands.
	host.selected_team = str(race_context.team)
	host.selected_track_index = int(race_context.track)
	host.team_control_mode = str(race_context.mode)
	host.championship_mode = bool(race_context.championship)
	for i in range(host.teams.size()):
		if str(host.teams[i].name) == host.selected_team:
			host.team_picker.select(i)
			break
	host.track_picker.select(host.selected_track_index)
	host.seed_picker.value = float(race_context.seed)
	host.pre_race_team_mode_picker.select(1 if host.team_control_mode == "Automático" else 0)
	host._update_tyre_briefing()
	host._update_weather_briefing()
	host._update_championship_menu()
	forget_race_context()
