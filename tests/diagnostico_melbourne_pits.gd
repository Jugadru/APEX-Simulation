extends SceneTree
## Diagnostic, not a passing/failing strategy benchmark yet.
## In Godot: godot --headless --path . --script res://tests/diagnostico_melbourne_pits.gd
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
    var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var melbourne: Dictionary = {}
    for track in data["tracks"]:
        if str(track["code"]) == "AUS":
            melbourne = track
            break
    assert(not melbourne.is_empty())
    var race = RaceScript.new(data["teams"], "Ferrari", 42, {}, melbourne, {})
    race.configure_weather("Seco")
    for car in race.player_cars():
        race.set_pit_control_mode(int(car["id"]), "IA")
    race.running = true
    for tick in range(2200):
        if race.finished:
            break
        race.step(4.0)
    var all_stops: Array[int] = []
    for car in race.cars:
        all_stops.append(int(car.get("stops", 0)))
        print("%s: %d paradas; pneu %s" % [str(car["name"]), int(car["stops"]), str(car["tire"])])
    all_stops.sort()
    print("MELBOURNE 2012 SIMULADO: voltas %d; minimo %d; mediana %d; maximo %d" % [race.lap_count, all_stops[0], all_stops[int(all_stops.size()/2)], all_stops[-1]])
    print("NOTA: este teste nao chama a autonomia de ritmo do HUD; diagnostico de box do motor apenas.")
    quit(0)
