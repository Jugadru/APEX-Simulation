extends RefCounted
## APEX v0.6.4.2 — fictional rival R&D market; persistent, deterministic.
## No real-life 2012 engineering budget or performance assertions.
const PARTS := ["Motor", "Asa", "Chassi"]
const COSTS := {"Motor": 1800000, "Asa": 1550000, "Chassi": 1300000}
const MAX_LEVEL: int = 3
const GAINS := {"Motor": 0.12, "Asa": 0.10, "Chassi": 0.07}

static func _stable_hash(value: String) -> int:
	var state: int = 101
	for n in range(value.length()):
		state = posmod(state * 31 + value.unicode_at(n), 2147483647)
	return state

static func create(teams: Array, player_team: String) -> Dictionary:
	var accounts: Dictionary = {}
	for team in teams:
		var name: String = str(team.get("name", ""))
		if name.is_empty() or name == player_team:
			continue
		var rating: float = float(team.get("car", 75))
		# Flat, transparent fictional budget tier; weaker teams still receive income.
		var initial: int = 1900000 + int(clampf(rating - 68.0, 0.0, 32.0) * 105000.0)
		accounts[name] = {"budget": initial, "rating": rating,
			"levels": {"Motor": 0, "Asa": 0, "Chassi": 0},
			"history": [], "invested": 0}
	return accounts

static func cost(part: String, level: int) -> int:
	if not COSTS.has(part) or level >= MAX_LEVEL:
		return -1
	return int(COSTS[part]) * (level + 1)

static func gain(levels: Dictionary) -> float:
	var seconds: float = 0.0
	for part in PARTS:
		seconds += float(clampi(int(levels.get(part, 0)), 0, MAX_LEVEL)) * float(GAINS[part])
	return seconds

static func advance(previous: Dictionary, round_number: int, seed: int,
		constructors: Dictionary, player_team: String) -> Dictionary:
	var accounts: Dictionary = previous.duplicate(true)
	var sorted: Array = accounts.keys()
	sorted.sort()
	for key in sorted:
		var name: String = str(key)
		if name == player_team:
			continue
		var account: Dictionary = accounts[name]
		var levels: Dictionary = account.get("levels", {}).duplicate(true)
		var budget: int = maxi(0, int(account.get("budget", 0)))
		var score: int = int(constructors.get(name, 0))
		var received: int = 720000 + mini(520000, int(clampf(float(score) / maxf(1.0, round_number * 23.0), 0.0, 1.0) * 520000.0))
		# Catch-up budgets: poor machinery gets a *slightly* larger base grant.
		received += int(clampf(85.0 - float(account.get("rating", 80.0)), 0.0, 18.0) * 19000.0)
		budget += received
		var event: Dictionary = {"round": round_number, "revenue": received,
			"action": "economizou", "part": "", "cost": 0}
		# Max one investment per team per GP: predictable, no arbitrary boosting.
		# Seed and team name diversify focus; every candidate has a real expense.
		var preference: Array = PARTS.duplicate()
		var offset: int = posmod(_stable_hash(name) + seed + round_number * 7, 3)
		var best_part: String = ""
		var best_priority: float = -INF
		for part in preference:
			var level: int = clampi(int(levels.get(part, 0)), 0, MAX_LEVEL)
			var price: int = cost(str(part), level)
			if price < 0 or price > budget:
				continue
			var rotation: float = float((PARTS.find(part) - offset + 3) % 3)
			var priority: float = float(GAINS[part]) / (float(price) / 1000000.0) * 100.0 - float(level) * 0.25 - rotation * 0.27
			if priority > best_priority:
				best_priority = priority
				best_part = str(part)
		if best_part != "":
			var spent: int = cost(best_part, int(levels.get(best_part, 0)))
			levels[best_part] = int(levels.get(best_part, 0)) + 1
			budget -= spent
			account["invested"] = int(account.get("invested", 0)) + spent
			event["action"] = "melhoria"
			event["part"] = best_part
			event["cost"] = spent
			event["new_level"] = int(levels[best_part])
		account["budget"] = budget
		account["levels"] = levels
		var history: Array = account.get("history", [])
		history.append(event)
		account["history"] = history
		accounts[name] = account
	return accounts

static func migrate(state: Dictionary) -> Dictionary:
	# Old careers retain all racing results. Reconstruct only fictional R&D
	# from existing round results, not actual historical engineering records.
	var teams: Array = []
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	if typeof(season) == TYPE_DICTIONARY:
		teams = season.get("teams", [])
	var player: String = str(state.get("team", ""))
	var accounts: Dictionary = create(teams, player)
	var scores: Dictionary = {}
	for key in state.get("constructors", {}).keys():
		scores[str(key)] = 0
	var num: int = 0
	for result in state.get("results", []):
		num += 1
		for position in result.get("positions", []):
			var place: int = int(position.get("position", 99))
			var amount: int = [25,18,15,12,10,8,6,4,2,1][place - 1] if place >= 1 and place <= 10 else 0
			var name: String = str(position.get("team", ""))
			scores[name] = int(scores.get(name, 0)) + amount
		accounts = advance(accounts, num, int(state.get("seed", 42)), scores, player)
	return accounts
