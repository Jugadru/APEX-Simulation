extends RefCounted
## Career-only pairing, using existing fictional staff contracts.
## No sporting state or RNG access. Only completed championship GPs settle.
const MAX_PAIRS := 96
const MAX_ROUNDS := 160

static func staff_context(team: Dictionary, levels: Dictionary) -> Dictionary:
	var person: Dictionary = (team.get("staff_roster", {}) as Dictionary).get("Engenheiro", {})
	var result: Dictionary = levels.duplicate(true)
	var id: String = str(person.get("id", ""))
	result["engineer_contract_id"] = id
	result["engineer_name"] = str(person.get("name", "Race Engineer"))
	result["engineer_radio_style"] = {"eng_a":"CALM","eng_b":"TECHNICAL","eng_c":"DEADPAN"}.get(id, "")
	result["engineer_skill"] = clampi(int(person.get("skill", 50)), 0, 100)
	result["engineer_energy"] = clampi(int(person.get("energy", 78)), 0, 100)
	result["engineer_trust"] = clampi(int(person.get("trust", 65)), 0, 100)
	return result

static func pair_key(staff: Dictionary, car: Dictionary) -> String:
	var id: String = str(staff.get("engineer_contract_id", ""))
	if id.is_empty():
		return ""
	return "%s|%d" % [id, int(car.get("id", -1))]

static func read_bonds(team: Dictionary) -> Dictionary:
	var soul: Dictionary = team.get("staff_soul", {})
	var store: Variant = soul.get("radio_bonds_0922", {})
	if store is Dictionary:
		return store.duplicate(true)
	return {}

static func settle(team: Dictionary, staff: Dictionary, cars: Array, relations: Dictionary, season: int, round_number: int) -> bool:
	if season <= 0 or round_number <= 0 or str(staff.get("engineer_contract_id", "")).is_empty():
		return false
	var soul: Dictionary = team.get("staff_soul", {})
	var rounds: Dictionary = soul.get("radio_rounds_0922", {}) if soul.get("radio_rounds_0922", {}) is Dictionary else {}
	var key: String = "%d:%d" % [season, round_number]
	if rounds.has(key):
		return false
	var bonds: Dictionary = read_bonds(team)
	var updated: bool = false
	for car in cars:
		var pair: String = pair_key(staff, car)
		var record: Dictionary = relations.get(int(car.get("id", -1)), {})
		# Count meaningful follow-ups, not radio volume or sporting results.
		var completed: int = clampi(int(record.get("followups", 0)), 0, 3)
		var exchanges: int = clampi(int(record.get("exchanges", 0)), 0, 2)
		if completed + exchanges == 0:
			continue
		var previous: int = clampi(int(bonds.get(pair, 50)), 0, 100)
		bonds[pair] = clampi(previous + completed + exchanges, 0, 100)
		updated = true
	if not updated:
		return false
	rounds[key] = true
	while rounds.size() > MAX_ROUNDS:
		rounds.erase(rounds.keys()[0])
	while bonds.size() > MAX_PAIRS:
		bonds.erase(bonds.keys()[0])
	soul["radio_bonds_0922"] = bonds
	soul["radio_rounds_0922"] = rounds
	team["staff_soul"] = soul
	return true
