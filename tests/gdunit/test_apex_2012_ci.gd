extends GdUnitTestSuite
## Gate inicial de dados e integridade do grid do APEX 2012.
## Nao altera estado esportivo, saves nem apresentacao.

const Race = preload("res://scripts/race_engine.gd")
const SEASON_PATH := "res://data/season_2012.json"


func test_season_catalog_2012() -> void:
    var raw: String = FileAccess.get_file_as_string(SEASON_PATH)
    assert_bool(not raw.is_empty()).is_true()
    var parsed: Variant = JSON.parse_string(raw)
    assert_bool(parsed is Dictionary).is_true()
    if not (parsed is Dictionary):
        return
    assert_int(parsed["teams"].size()).is_equal(12)
    assert_int(parsed["tracks"].size()).is_equal(20)


func test_race_initializes_24_cars() -> void:
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SEASON_PATH))
    assert_bool(parsed is Dictionary).is_true()
    if not (parsed is Dictionary):
        return
    var track: Dictionary = parsed["tracks"][0].duplicate(true)
    var race = Race.new(parsed["teams"], "Ferrari", 6557, {}, track, {})
    assert_int(race.cars.size()).is_equal(24)
