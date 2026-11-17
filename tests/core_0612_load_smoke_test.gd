extends SceneTree
## Godot 4: godot --headless --path . --script res://tests/core_0612_load_smoke_test.gd
## A parser failure in track_map.gd also prevents main.gd and the old smoke tests from loading.
const MapScript = preload("res://scripts/track_map.gd")
const MainScript = preload("res://scripts/main.gd")
const WeatherScript = preload("res://scripts/core/race_weather.gd")

func _initialize() -> void:
	var map_instance: Node2D = MapScript.new()
	assert(map_instance != null)
	map_instance.free()
	print("APEX 0.6.1.2: GDScript load chain PASS")
	quit(0)
