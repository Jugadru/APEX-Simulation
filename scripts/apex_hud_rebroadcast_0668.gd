extends RefCounted
## APEX 0.6.6.8: purely presentational modes and incremental ranking updates.
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
	match code.to_upper():
		"S", "SOFT": return Color("#E65D60")
		"M", "MEDIUM": return Color("#F2BE49")
		"H", "HARD": return Color("#F3F5F6")
		"I", "INTER", "INTERMEDIATE": return Color("#42BE89")
		"W", "WET", "EXTREME": return Color("#75D7DE")
	return Color("#B7C3CC")

static func _order_status(car: Dictionary) -> String:
	if bool(car.get("disqualified", false)):
		return "DSQ"
	if bool(car.get("classified_no_finish", false)):
		return "NC"
	if float(car.get("pit_left", 0.0)) > 0.0:
		return "PIT"
	if bool(car.get("pit_request", false)):
		return "BOX"
	if int(car.get("pit_scheduled_lap", 0)) > 0:
		return "V%d" % int(car.get("pit_scheduled_lap", 0))
	return ""

static func update_row(row: Dictionary, car: Dictionary, index: int, own_team: String,
		detail: String, tire: String, selected_id: int, idle_style: StyleBoxFlat,
		active_style: StyleBoxFlat) -> int:
	# Update only the properties whose displayed values have changed; row nodes
	# are allocated just once per 24-car grid, never recreated per refresh.
	var changes := 0
	var name: String = str(car.get("name", "Piloto"))
	var pieces: PackedStringArray = name.split(" ", false)
	var abbr: String = (name if pieces.is_empty() else pieces[pieces.size() - 1]).left(3).to_upper()
	changes += set_text_if_changed(row["pos"], "%02d" % (index + 1))
	changes += set_text_if_changed(row["driver"], abbr)
	changes += set_text_if_changed(row["detail"], detail)
	changes += set_text_if_changed(row["tyre"], tire)
	changes += set_text_if_changed(row["state"], _order_status(car))
	var hint: String = "%s • %s • %d%% desgaste" % [name, str(car.get("tire", "")), int(round(float(car.get("wear", 0.0))))]
	if int(car.get("pit_scheduled_lap", 0)) > 0:
		hint += " • pit V%d (%s)" % [int(car.get("pit_scheduled_lap", 0)), str(car.get("pit_order_source", "agendado"))]
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
