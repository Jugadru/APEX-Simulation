extends RefCounted
## Module extracted from main.gd v0.6.2.0. Works through the live scene host.
## Keeps existing callbacks while separating responsibilities.
const HudThemeScript = preload("res://scripts/apex_hud_theme.gd")
const WHITE := Color("#e9f4fd")
const MUTED := Color("#9eb8c8")
const YELLOW := Color("#ffce76")
const GREEN := Color("#46dcc0")

static func _best_lap(host, order: Array) -> float:
	var best := 9999.0
	for car in order:
		best = minf(best, float(car["best_lap"]))
	return best

static func _format_lap(host, value: float) -> String:
	if value <= 0.0 or value >= 9998.0:
		return "—"
	var minutes := int(value / 60.0)
	var seconds := int(value) % 60
	var millis := int(round((value - floor(value)) * 1000.0))
	return "%d:%02d.%03d" % [minutes, seconds, millis]

static func _icon_for_car(host, car: Dictionary, order: Array, index: int) -> String:
	if str(car.get("pit_stage", "")) == "queue":
		return "⌛"
	if str(car.get("combat_state", "")) in ["attacking", "duel"]:
		return "⚔"
	if str(car.get("combat_state", "")) == "defending":
		return "⛨"
	if int(car["id"]) == host.focused_id:
		return "▶"
	if str(car["team"]) == host.selected_team:
		return "★"
	if index == 0:
		return "◆"
	if float(car["pit_left"]) > 0.0:
		return "⛽"
	return "•"

static func _row_detail(host, order: Array, idx: int) -> String:
	var car: Dictionary = order[idx]
	match host.table_mode:
		0:
			return "LÍDER" if idx == 0 else (str(car.get("gap_label", "")) if host.race != null and bool(host.race.finished) else "+%.1fs" % float(car["gap"]))
		1:
			return "—" if idx == 0 else (str(car.get("interval_label", "")) if host.race != null and bool(host.race.finished) else "+%.1fs" % float(car["interval"]))
		2:
			return "—" if idx >= order.size() - 1 else (str(order[idx + 1].get("interval_label", "")) if host.race != null and bool(host.race.finished) else "+%.1fs" % float(order[idx + 1]["interval"]))
		3:
			return "%s %d%%" % [host._compound_code(str(car["tire"])), int(round(float(car["wear"])))]
		4:
			return host._format_lap(float(car["best_lap"]))
		_:
			return "—"

static func _compound_code(host, name: String) -> String:
	return host.race.tyre_code(name) if host.race != null else name

static func _tyre_color(host, compound: String) -> Color:
	if host.race != null:
		var tyre_info: Dictionary = host.race.tyre_spec(compound)
		return Color.from_string(str(tyre_info.get("color", "#ffffff")), WHITE)
	return MUTED

static func _wear_color(host, wear: float) -> Color:
	if wear >= 72.0:
		return Color("#ff7b77")
	if wear >= 45.0:
		return YELLOW
	return GREEN

static func _update_telemetry(host, order: Array) -> void:
	if host.telemetry_name == null or order.is_empty():
		return
	var driver: Dictionary = host._car_by_id(host.manual_driver)
	if driver.is_empty():
		driver = order[0]
	var position: int = int(driver.get("position", 0))
	var wear: float = float(driver.get("wear", 0.0))
	var tyre_name: String = str(driver.get("tire", "Médio"))
	host.telemetry_name.text = "P%02d  %s" % [position, str(driver.get("name", "Piloto"))]
	host.telemetry_name.add_theme_color_override("font_color", Color.from_string(str(driver.get("color", "#ffffff")), GREEN).lightened(0.3))
	host.telemetry_tire.text = "%s  %d%%" % [host._compound_code(tyre_name), int(round(wear))]
	host.telemetry_tire.add_theme_color_override("font_color", host._tyre_color(tyre_name))
	host.telemetry_wear.value = wear
	var wear_style := HudThemeScript.panel(host._wear_color(wear), 5, host._wear_color(wear), 0)
	host.telemetry_wear.add_theme_stylebox_override("fill", wear_style)
	var gap_caption: String = "LÍDER" if position <= 1 else (str(driver.get("gap_label", "")) if host.race != null and bool(host.race.finished) else "+%.2fs" % float(driver.get("gap", 0.0)))
	host.telemetry_stats.text = "ÚLT. %s   /   MELHOR %s   /   LÍDER %s" % [host._format_lap(float(driver.get("last_lap", 9999.0))), host._format_lap(float(driver.get("best_lap", 9999.0))), gap_caption]
	var status: String = "NA PISTA"
	var pit_left: float = float(driver.get("pit_left", 0.0))
	var stage: String = str(driver.get("pit_stage", ""))
	if pit_left > 0.001:
		status = "BOX • %s" % ("FILA" if stage == "queue" else "ATENDIMENTO")
	elif bool(driver.get("pit_request", false)):
		status = "BOX SOLICITADO"
	elif bool(driver.get("finished", false)):
		status = "BANDEIRADA"
	host.telemetry_pit.text = status
	host.telemetry_pit.add_theme_color_override("font_color", Color("#ff968e") if stage == "queue" else YELLOW)
	host.telemetry_subtitle.text = "RITMO %s   •   %d PARADA(S)   •   VOLTA %d" % [str(driver.get("pace", "Normal")).to_upper(), int(driver.get("stops", 0)), int(driver.get("laps_done", 0)) + 1]
	host.telemetry_camera.text = "MAPA" if host.render_mode == 0 else ("DIRETOR TV" if host.camera_mode == "Diretor TV" else "3D / PILOTO")

