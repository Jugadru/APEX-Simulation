extends SceneTree
## Behavioral fingerprint captured against the unmodified 0.6.5.0 ZIP.
## Includes returned messages and full state after each public operation.
const Garage = preload("res://scripts/garage.gd")
const Market = preload("res://scripts/core/staff_market_0648.gd")
const Soul = preload("res://scripts/core/staff_soul_0650.gd")
const EXPECTED_PATH := "res://tests/staff_refactor_expected.sha256"
var snapshots: Array[String] = []

func record(game, team: String, result: Variant) -> void:
    snapshots.append(JSON.stringify({"result": result, "state": game.team_data}, "", true))
    snapshots.append(JSON.stringify(game.staff_soul_summary(team), "", true))
    snapshots.append(JSON.stringify(game.staff_soul_relations(team), "", true))

func _initialize() -> void:
    var game = Garage.new()
    game.team_data = {}
    for action in ["briefing", "recovery", "integration"]:
        for position in [1, 3, 4, 10, 11, 22]:
            for candidate_index in range(3):
                var team: String = "%s_%d_%d" % [action, position, candidate_index]
                var state: Dictionary = game.get_team(team)
                record(game, team, game.staff_hire_candidate(team, "invalid", "invalid"))
                for role in Market.ROLES:
                    var candidate_id: String = str(Market.MARKET[role][candidate_index]["id"])
                    record(game, team, game.staff_hire_candidate(team, role, candidate_id, 2, 2))
                    record(game, team, game.staff_hire_candidate(team, role, candidate_id, 2, 2))
                    snapshots.append(Soul.staff_voice(state["staff_roster"][role]))
                record(game, team, game.staff_settle_round(team, 0, 0))
                record(game, team, game.staff_settle_round(team, 2, 2))
                record(game, team, game.staff_soul_settle_round(team, 2, 2, position))
                for round_number in range(3, 12):
                    record(game, team, game.staff_soul_action(team, action, 2, round_number, 20))
                    record(game, team, game.staff_soul_action(team, action, 2, round_number, 20))
                    record(game, team, game.staff_soul_settle_round(team, 2, round_number, position))
                    record(game, team, game.staff_soul_settle_round(team, 2, round_number, position))
                    record(game, team, game.staff_settle_round(team, 2, round_number))
                    record(game, team, game.staff_settle_round(team, 2, round_number))
                state["budget"] = 0
                record(game, team, game.staff_hire_candidate(team, "Engenheiro", "eng_a", 3, 0))
                state["budget"] = 12000000
                record(game, team, game.staff_hire_candidate(team, "Engenheiro", "eng_a", 3, 0))
                state["budget"] = 0
                record(game, team, game.staff_release(team, "Engenheiro"))
                record(game, team, game.staff_soul_action(team, action, 3, 1, 20))
                state["budget"] = 12000000
                record(game, team, game.staff_release(team, "Engenheiro"))
                record(game, team, game.staff_release(team, "Engenheiro"))
                game.team_data.clear()
    var digest: String = "\n".join(snapshots).sha256_text()
    print("STAFF_REFACTOR_FINGERPRINT ", digest, " snapshots=", snapshots.size())
    if OS.get_cmdline_user_args().has("--capture"):
        quit(0)
        return
    var expected: String = FileAccess.get_file_as_string(EXPECTED_PATH).strip_edges()
    if digest != expected:
        printerr("STAFF_REFACTOR_PARITY_FAIL: state/messages differ from original ZIP")
        quit(1)
        return
    print("STAFF_REFACTOR_PARITY_PASS")
    quit(0)
