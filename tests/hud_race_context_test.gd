extends SceneTree
const Context = preload("res://scripts/presentation/apex_hud_race_context.gd")
const WeatherPanel = preload("res://scripts/presentation/apex_hud_weather_panel.gd")
const Hud = preload("res://scripts/apex_race_hud_0622.gd")
func _initialize() -> void:
	var order := [{"id":1,"name":"Sebastian Vettel","interval":0.0}, {"id":2,"name":"Fernando Alonso","interval":1.25}, {"id":3,"name":"Felipe Massa","interval":2.5,"interval_label":"+1 VOLTA"}]
	assert(Context.neighbours(order, 2, false) == "FRENTE VET +1.25s    |    ATRÁS MAS +2.50s")
	assert(Context.neighbours(order, 1, false).contains("LÍDER"))
	assert(Context.neighbours(order, 3, false).ends_with("ATRÁS —"))
	assert(Context.neighbours(order, 2, true).contains("+1 VOLTA"))
	assert(Context.neighbours([], 42, false) == "FRENTE —    |    ATRÁS —")
	var hud = Hud.new()
	var ui: Dictionary = WeatherPanel.build(hud, Callable(hud,"_panel"),Callable(hud,"_column"),Callable(hud,"_text"))
	var observed := {"track_code":"GBR","mode":"Chuva intensa","rain_intensity":0.8,"water_mm":0.5}
	var before := observed.duplicate(true)
	WeatherPanel.refresh_timeline(ui, observed, 100.0)
	assert(ui["cells"][0]["value"].text == "0.50 mm")
	assert(ui["cells"][3]["bar"].value > 0.5)
	assert(observed == before)
	WeatherPanel.refresh_timeline(ui, {"track_code":"GBR","mode":"Seco","water_mm":0.0}, 0.0)
	assert(ui["cells"][3]["value"].text == "0.00 mm", "replay seek/session invalidates forecast")
	hud.free()
	print("HUD_RACE_CONTEXT_PASS")
	quit()
