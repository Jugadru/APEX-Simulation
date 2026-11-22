extends RefCounted
## Refatoração 05: apenas construção visual do painel de condições da pista.
## O RaceEngine e a HUD continuam responsáveis pelos dados e atualizações.

const WetForecast = preload("res://scripts/core/race_wet_strategy_intelligence_06698.gd")
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")

static func build(parent: Node, panel: Callable, column: Callable,
		label: Callable) -> Dictionary:
	var weather_box: PanelContainer = panel.call(parent)
	var weather_column: VBoxContainer = column.call(weather_box, 4)
	label.call(weather_column, "CLIMA  /  PREVISÃO", 13, HudSkin.MUTED)
	var weather_line: Label = label.call(weather_column, "Aguardando clima", 15, HudSkin.WHITE)
	weather_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var timeline := HBoxContainer.new()
	timeline.add_theme_constant_override("separation", 5)
	weather_column.add_child(timeline)
	var cells: Array = []
	for title in ["AGORA", "+5 MIN", "+10 MIN", "+15 MIN"]:
		var cell: VBoxContainer = column.call(timeline, 3)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.call(cell, title, 11, HudSkin.MUTED)
		var value: Label = label.call(cell, "— mm", 13, HudSkin.WHITE)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 6
		bar.max_value = 7.0
		bar.show_percentage = false
		bar.add_theme_stylebox_override("fill", HudSkin.panel(Color("#64B8DF"), 0, Color.TRANSPARENT, 0))
		cell.add_child(bar)
		cells.append({"value":value, "bar":bar})
	var details := Button.new()
	details.text = "ÁGUA NA LINHA · ESTIMATIVA / DETALHES"
	details.add_theme_font_size_override("font_size", 11)
	weather_column.add_child(details)
	weather_column.add_child(HSeparator.new())
	label.call(weather_column, "CONDIÇÕES DA PISTA", 13, HudSkin.MUTED)
	var weather_track_line: Label = label.call(weather_column, "Aguardando pista", 14, HudSkin.WHITE)
	weather_track_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return {"cells": cells, "details":details, "weather_track_line": weather_track_line, "weather_box": weather_box, "weather_line": weather_line}

static func refresh_timeline(ui: Dictionary, observed: Dictionary, clock_seconds: float) -> void:
	# Recompute at most once per five simulated seconds. Also invalidate on
	# session/track changes and backwards replay seeks.
	var stamp := [int(clock_seconds / 5.0), observed.get("track_code"), observed.get("mode")]
	if ui.get("stamp", []) == stamp:
		return
	ui["stamp"] = stamp
	for i in range(4):
		var data: Dictionary = observed if i == 0 else WetForecast.forecast(observed, float(i * 300), str(observed.get("track_code", "")))
		var cell: Dictionary = ui["cells"][i]
		cell["value"].text = "%.2f mm" % float(data.get("water_mm", 0.0))
		cell["bar"].value = float(data.get("water_mm", 0.0))
		cell["value"].tooltip_text = "Água medida na linha de corrida" if i == 0 else "Estimativa por observações atuais. Confiança %s. Pode não antecipar novas pancadas; não é probabilidade calibrada." % str(data.get("confidence", "—"))
