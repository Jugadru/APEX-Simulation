extends RefCounted
## Refatoração 05: apenas construção visual do painel de condições da pista.
## O RaceEngine e a HUD continuam responsáveis pelos dados e atualizações.

const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")

static func build(parent: Node, panel: Callable, column: Callable,
		label: Callable) -> Dictionary:
	var weather_box: PanelContainer = panel.call(parent)
	var weather_column: VBoxContainer = column.call(weather_box, 4)
	label.call(weather_column, "CLIMA  /  PREVISÃO", 13, HudSkin.MUTED)
	var weather_line: Label = label.call(weather_column, "Aguardando clima", 15, HudSkin.WHITE)
	weather_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weather_column.add_child(HSeparator.new())
	label.call(weather_column, "CONDIÇÕES DA PISTA", 13, HudSkin.MUTED)
	var weather_track_line: Label = label.call(weather_column, "Aguardando pista", 14, HudSkin.WHITE)
	weather_track_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return {"weather_track_line": weather_track_line, "weather_box": weather_box, "weather_line": weather_line}
