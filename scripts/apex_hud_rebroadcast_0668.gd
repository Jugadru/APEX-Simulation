extends RefCounted
## APEX 0.6.6.8.1: presentation modes, incremental ranks and pending-order visibility.
## No access to RaceEngine mutation, RNG, replay or race tick progression.

const MODES := ["BROADCAST", "COMPACT", "FULL"]
const PREFS := "user://hud_rebroadcast_0668.cfg"

static func load_mode() -> int:
	var settings := ConfigFile.new()
	if settings.load(PREFS) != OK:
		return 1 # Compact is the first-run default.
	return clampi(int(settings.get_value("rebroadcast", "mode", 1)), 0, 2)

static func save_mode(mode: int) -> Error:
	var settings := ConfigFile.new()
	settings.load(PREFS)
	settings.set_value("rebroadcast", "mode", clampi(mode, 0, 2))
	return settings.save(PREFS)

static func set_text_if_changed(control, value: String) -> int:
	if control.text == value:
		return 0
	control.text = value
	return 1

static func tyre_tint(code: String) -> Color:
	# 2012 Pirelli historical visuals, aligned to data/tyres_2012.json.
	match code.to_upper():
		"SS", "SUPERSOFT", "SUPERMACIO": return Color("#f04c54")
		"S", "SOFT", "MACIO": return Color("#f4d14c")
		"M", "MEDIUM", "MÉDIO": return Color("#f0f0e7")
		"H", "HARD", "DURO": return Color("#c9d0d5")
		"I", "INTER", "INTERMEDIATE", "INTERMEDIÁRIO": return Color("#50b88b")
		"W", "WET", "EXTREME", "CHUVA": return Color("#4aa3ed")
	return Color("#B7C3CC")

static func pending_pit_by_driver(session) -> Dictionary:
	# Read-only projection of the existing validated replay queue. Reading this
	# list never executes a command or affects race hashes/checkpoints. A future
	# command recorded during replay playback is *not* a new UI order.
	var result: Dictionary = {}
	if session == null or bool(session.playback):
		return result
	for i in range(int(session.cursor), session.commands.size()):
		var cmd: Dictionary = session.commands[i]
		var kind: String = str(cmd.get("type", ""))
		if kind not in ["schedule_pit", "order_pit", "cancel_scheduled_pit"]:
			continue
		var actor: int = int(cmd.get("actor", -1))
		var args: Array = cmd.get("payload", [])
		if actor < 0 or args.is_empty() or int(cmd.get("tick", 0)) <= int(session.tick):
			continue
		# The last queued command for a driver represents the latest intent.
		var previous: Dictionary = result.get(actor, {})
		if not previous.is_empty() and int(previous.get("sequence", 0)) > int(cmd.get("sequence", 0)):
			continue
		result[actor] = {
			"type": kind, "tick": int(cmd.get("tick", 0)),
			"sequence": int(cmd.get("sequence", 0)),
			"compound": str(args[1]) if args.size() > 1 else "",
			"lap": int(args[2]) if args.size() > 2 else 0
		}
	return result

static func pending_label(pending: Dictionary) -> String:
	match str(pending.get("type", "")):
		"schedule_pit": return "P%d" % int(pending.get("lap", 0))
		"order_pit": return "PBOX"
		"cancel_scheduled_pit": return "CANC"
	return ""

static func pending_description(pending: Dictionary) -> String:
	match str(pending.get("type", "")):
		"schedule_pit": return "PENDENTE: parada V%d / %s (aplicar no tick %d)" % [
			int(pending.get("lap", 0)), str(pending.get("compound", "")), int(pending.get("tick", 0))]
		"order_pit": return "PENDENTE: ordem de box imediato / %s (tick %d)" % [
			str(pending.get("compound", "")), int(pending.get("tick", 0))]
		"cancel_scheduled_pit": return "PENDENTE: cancelamento de agendamento (tick %d)" % int(pending.get("tick", 0))
	return ""

static func _order_status(car: Dictionary) -> String:
	if bool(car.get("disqualified", false)):
		return "DSQ"
	if bool(car.get("classified_no_finish", false)):
		return "NC"
	if bool(car.get("finished", false)):
		return "FIN"
	if float(car.get("pit_left", 0.0)) > 0.0:
		return "PIT"
	if bool(car.get("pit_request", false)):
		return "BOX"
	if int(car.get("pit_scheduled_lap", 0)) > 0:
		return "V%d" % int(car.get("pit_scheduled_lap", 0))
	return ""

static func update_row(row: Dictionary, car: Dictionary, index: int, own_team: String,
		detail: String, tire: String, selected_id: int, idle_style: StyleBoxFlat,
		active_style: StyleBoxFlat, pending: Dictionary = {}, official_abbr: String = "") -> int:
	# Update only the properties whose displayed values have changed; row nodes
	# are allocated just once per 24-car grid, never recreated per refresh.
	var changes := 0
	var name: String = str(car.get("name", "Piloto"))
	var pieces: PackedStringArray = name.split(" ", false)
	var fallback_abbr: String = (name if pieces.is_empty() else pieces[pieces.size() - 1]).left(3).to_upper()
	var abbr: String = official_abbr.to_upper() if official_abbr.length() == 3 else fallback_abbr
	changes += set_text_if_changed(row["pos"], "%02d" % (index + 1))
	changes += set_text_if_changed(row["driver"], abbr)
	changes += set_text_if_changed(row["detail"], detail)
	changes += set_text_if_changed(row["tyre"], tire)
	var pending_text: String = pending_label(pending)
	changes += set_text_if_changed(row["state"], pending_text if not pending_text.is_empty() else _order_status(car))
	var hint: String = "%s • %s • %d%% desgaste" % [name, str(car.get("tire", "")), int(round(float(car.get("wear", 0.0))))]
	if int(car.get("pit_scheduled_lap", 0)) > 0:
		hint += " • pit V%d (%s)" % [int(car.get("pit_scheduled_lap", 0)), str(car.get("pit_order_source", "agendado"))]
	if not pending.is_empty():
		hint += " • " + pending_description(pending)
	if row["driver"].tooltip_text != hint:
		row["driver"].tooltip_text = hint
		changes += 1
	var stripe: Color = Color.from_string(str(car.get("color", "#ffffff")), Color.WHITE)
	if row["stripe"].color != stripe:
		row["stripe"].color = stripe
		changes += 1
	var tyre_color := tyre_tint(tire)
	if row["tyre"].get_theme_color("font_color") != tyre_color:
		row["tyre"].add_theme_color_override("font_color", tyre_color)
		changes += 1
	var own: bool = str(car.get("team", "")) == own_team
	if not row["driver"].has_meta("own_team") or bool(row["driver"].get_meta("own_team")) != own:
		row["driver"].set_meta("own_team", own)
		row["driver"].add_theme_color_override("font_color", Color("#FF8A21") if own else Color("#F3F5F6"))
		changes += 1
	var selected: bool = int(car.get("id", -1)) == selected_id
	if not row["driver"].has_meta("selected") or bool(row["driver"].get_meta("selected")) != selected:
		row["driver"].set_meta("selected", selected)
		row["driver"].add_theme_stylebox_override("normal", active_style if selected else idle_style)
		changes += 1
	return changes
