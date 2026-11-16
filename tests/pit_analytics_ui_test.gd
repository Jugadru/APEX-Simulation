extends SceneTree
## Run in Godot 4: godot --headless --path . --script res://tests/pit_analytics_ui_test.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	assert(packed != null)
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	assert(app.analytics_summary_label != null)
	assert(app.analytics_chart != null)
	assert(app.analytics_history_label != null)
	assert(app.analytics_compare_label != null)
	assert(app.analytics_advice_label != null)
	app._start_race()
	assert(app.race.pit_history.is_empty())
	assert(app.analytics_summary_label.text.contains("Nenhum"))
	assert(app.tabs.get_tab_title(4) == "Análises")
	app._open_pit_analytics()
	assert(app.tabs.current_tab == 4)
	var driver: Dictionary = app.race.player_cars()[0]
	driver["progress"] = 0.949
	app.race.pit_incidents_enabled = false
	app.race.order_pit(int(driver["id"]), "Duro")
	app.race.running = true
	for tick in range(750):
		app.race.step(0.2)
		if app.race.pit_history.size() > 0:
			break
	app._refresh_pit_analytics()
	assert(app.analytics_summary_label.text.contains("1 parada"))
	assert(app.analytics_history_label.text.contains(str(driver["name"])))
	assert(app.analytics_chart.samples.size() == 1)
	assert(app.analytics_final_label.text == "Disponível na bandeirada.")
	print("APEX ANALYTICS UI OK: tab, chart, live record, pre-race state")
	quit(0)
