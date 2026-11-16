extends RefCounted
## Shared contract eligibility and persistent round identifiers.
## Round numbers are 1-based; hired_round records the last completed round.
static func round_key(season_serial: int, round_number: int) -> String:
    return "%d_r%02d" % [season_serial, round_number]

static func participated(person: Dictionary, season_serial: int, round_number: int) -> bool:
    return not (int(person.get("hired_serial", 0)) == season_serial
        and round_number <= int(person.get("hired_round", -1)))
