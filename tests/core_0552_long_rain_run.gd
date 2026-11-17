extends SceneTree
## Optional long integration test (~30 simulated laps, not a quick static check).
## godot --headless --path . --script res://tests/core_0552_long_rain_run.gd
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var spa: Dictionary = {}
    for circuit in season["tracks"]:
        if str(circuit.get("code", "")) == "BEL":
            spa = circuit
            break
    assert(not spa.is_empty())
    var sim = RaceScript.new(season["teams"], "Ferrari", 63, {}, spa, {})
    sim.configure_weather("Chuva intensa")
    sim.running = true
    var worn_streaks: Dictionary = {}
    var maximum_worn_streak: float = 0.0
    var seen_full_wet: bool = false
    var wet_pit_stops: int = 0
    var prior_stops: Dictionary = {}
    for driver in sim.cars:
        prior_stops[int(driver["id"])] = int(driver.get("stops", 0))
        worn_streaks[int(driver["id"])] = 0.0
    for i in range(940):
        if sim.finished:
            break
        sim.step(4.0)
        for driver in sim.cars:
            if str(driver.get("team", "")) == "Ferrari":
                continue
            var driver_id: int = int(driver["id"])
            if str(driver.get("tire", "")) == "Chuva":
                seen_full_wet = true
            if int(driver.get("stops", 0)) > int(prior_stops[driver_id]):
                if str(driver.get("tire", "")) == "Chuva":
                    wet_pit_stops += 1
                prior_stops[driver_id] = int(driver["stops"])
            if str(driver.get("tire", "")) == "Chuva" and float(driver.get("wear", 0.0)) >= 99.9 and float(driver.get("pit_left", 0.0)) <= 0.0:
                worn_streaks[driver_id] = float(worn_streaks[driver_id]) + 4.0
                maximum_worn_streak = maxf(maximum_worn_streak, float(worn_streaks[driver_id]))
            else:
                worn_streaks[driver_id] = 0.0
    assert(seen_full_wet, "Scenario never reached full wet tyre phase")
    assert(wet_pit_stops > 0, "No AI full-wet replacements were observed")
    assert(maximum_worn_streak < 310.0,
        "AI stayed on 100% worn W for too long: %.1f simulated seconds" % maximum_worn_streak)
    print("APEX v0.5.5.2 LONG RAIN PASS — %.1fs simulated, %d W pit stops, maximum W 100%% streak %.1fs" % [
        sim.clock, wet_pit_stops, maximum_worn_streak])
    quit(0)
