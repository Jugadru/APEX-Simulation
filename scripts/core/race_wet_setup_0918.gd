extends RefCounted
## 9.18: player-facing presets for the existing 015 sporting setup contract.
## No new physics, weather knowledge, RNG, setup bonus or in-race mutation.
const Setup = preload("res://scripts/core/race_weather_setup_15.gd")
const LABELS := ["Neutro / original", "Seco / precisão", "Misto / compromisso", "Chuva / estabilidade"]
const PRESETS := [
	{"wing":0.0,"brake":0.0,"suspension":0.0},
	{"wing":0.15,"brake":-0.55,"suspension":-0.65},
	{"wing":0.35,"brake":0.35,"suspension":0.45},
	{"wing":0.85,"brake":0.75,"suspension":0.85}
]
static func settings(index: int) -> Dictionary:
	if index<0 or index>=PRESETS.size(): return {}
	return PRESETS[index].duplicate(true)

static func roster(race) -> Array:
	# Grid order varies by qualification; catalogue IDs remain stable.
	var players: Array=race.player_cars()
	players.sort_custom(func(a,b):return int(a.id)<int(b.id))
	return players

static func apply(race, choices: Array) -> bool:
	if race==null or race.running or race.finished or race.clock>0.0 or choices.size()!=2: return false
	var players: Array=roster(race)
	if players.size()!=2: return false
	var plans: Array=[]
	for choice in choices:
		if typeof(choice)!=TYPE_INT: return false
		var plan: Dictionary=settings(int(choice))
		if not Setup.valid(plan): return false
		plans.append(plan)
	# Validate both selections first; never partially apply an invalid pair.
	for i in range(2):
		if not race.configure_pre_race_setup(int(players[i].id),plans[i]): return false
	return true

static func comparison(index: int, weather: Dictionary) -> Dictionary:
	var plan: Dictionary=settings(index)
	if plan.is_empty(): return {}
	var estimate: Dictionary=Setup.evaluate(plan,weather)
	return {"setup":plan,"pace_delta_s":estimate.pace_delta_s,"wear_scale":estimate.wear_scale}
