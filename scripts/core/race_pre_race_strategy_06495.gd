extends RefCounted
## 0.6.4.9.5: deterministic advisory optimisation before the GP.
## Does not read future rival actions, mutate cars or drive an automatic pit call.
const Tyres = preload("res://scripts/core/race_tyres_2012.gd")
const INF: float = 1.0e20
const MIN_STINT := 5
const MAX_STOPS := 4
const WEAR_LIMIT := 86.0

static func stint_cost(compound: String, laps: int, factor: float, catalog: Dictionary) -> float:
	var specs: Dictionary = Tyres.compound(catalog, compound)
	if specs.is_empty() or laps <= 0:
		return INF
	var rate: float = maxf(0.1, float(specs.get("wear", 3.5)) * factor)
	var cliff: float = float(specs.get("cliff", 75.0))
	if float(laps) * rate > WEAR_LIMIT + 0.00001:
		return INF
	var total: float = 0.0
	for i in range(laps):
		var wear: float = float(i+1) * rate
		# The coefficients are illustrative gameplay estimates, not physical telemetry.
		total += float(specs.get("delta", 0.0)) + 2.8 * pow(wear / 100.0, 1.8) + maxf(0.0, wear-cliff) * 0.25
	return total

static func _optimise(remaining: int, active: int, used: int, stops_left: int,
		options: Array, factor: float, pit_loss: float, catalog: Dictionary, memo: Dictionary) -> Dictionary:
	var key: String = "%d:%d:%d:%d" % [remaining,active,used,stops_left]
	if memo.has(key):
		return memo[key]
	var best: Dictionary = {"cost": INF, "stints": []}
	for length in range(MIN_STINT, remaining + 1):
		var stint_cost_value: float = stint_cost(str(options[active]), length, factor, catalog)
		if stint_cost_value >= INF:
			break
		if length == remaining:
			if used == 3 and stint_cost_value < float(best["cost"]):
				best = {"cost": stint_cost_value, "stints": [{"compound":str(options[active]),"laps":length}]}
		elif stops_left > 0 and remaining-length >= MIN_STINT:
			for next_tyre in range(options.size()):
				var next_result: Dictionary = _optimise(remaining-length,next_tyre,used | (1 << next_tyre),stops_left-1,options,factor,pit_loss,catalog,memo)
				var candidate: float = stint_cost_value+pit_loss+float(next_result["cost"])
				if candidate < float(best["cost"]):
					var blocks: Array = [{"compound":str(options[active]),"laps":length}]
					blocks.append_array(next_result["stints"])
					best = {"cost":candidate,"stints":blocks}
	memo[key] = best
	return best

static func _decorate(stints: Array, factor: float, catalog: Dictionary) -> Array:
	var result: Array = []
	var until: int = 0
	for s in stints:
		var start: int = until+1
		until += int(s["laps"])
		var spec: Dictionary = Tyres.compound(catalog,str(s["compound"]))
		var end_wear: float = minf(100.0,float(s["laps"])*float(spec.get("wear",3.5))*factor)
		result.append({"compound":str(s["compound"]),"laps":int(s["laps"]),
			"from":start,"to":until,"wear_end":end_wear})
	return result

static func _plan_total(raw: Array, factor: float, pit_loss: float, catalog: Dictionary) -> float:
	var total: float = 0.0
	for stint in raw:
		total += stint_cost(str(stint["compound"]),int(stint["laps"]),factor,catalog)
	total += float(maxi(0,raw.size()-1))*pit_loss
	return total

static func _shift_first_stop(plan: Dictionary, other_lap: int, catalog: Dictionary, pit_loss: float) -> Dictionary:
	var old: Array = plan.get("stints",[])
	if old.size() < 2 or int(old[0]["to"]) != other_lap:
		return plan
	var raw: Array = []
	for s in old:
		raw.append({"compound":s["compound"],"laps":int(s["laps"])})
	var factor: float = float(plan["factor"])
	var base_cost: float = _plan_total(raw,factor,pit_loss,catalog)
	var best_cost: float = INF
	var best: Array = []
	for delta in [1,-1,2,-2]:
		var check: Array = raw.duplicate(true)
		check[0]["laps"] = int(check[0]["laps"]) + delta
		check[1]["laps"] = int(check[1]["laps"]) - delta
		if int(check[0]["laps"]) < MIN_STINT or int(check[1]["laps"]) < MIN_STINT:
			continue
		var score: float = _plan_total(check,factor,pit_loss,catalog)
		if score < best_cost:
			best_cost = score
			best = check
	if not best.is_empty() and best_cost < base_cost+4.0:
		var revised: Dictionary = plan.duplicate(true)
		revised["stints"] = _decorate(best,factor,catalog)
		revised["adjustment"] = "Primeira janela deslocada %s volta(s) para reduzir conflito inicial de garagem." % str(int(best[0]["laps"])-int(raw[0]["laps"]))
		revised["cost_estimate"] = best_cost
		return revised
	return plan

static func generate(race) -> Dictionary:
	var catalog: Dictionary = Tyres.catalog()
	var options: Array = Tyres.available(catalog,str(race.track.get("code","")))
	var laps: int = int(race.lap_count)
	if options.size() != 2 or laps < 12:
		return {"valid":false,"reason":"Pista ou nomeação de pneus indisponível."}
	var rain: float = float(race.weather_snapshot().get("wetness_factor",0.0))
	var plans: Array = []
	for car in race.player_cars():
		var tire: String = str(car.get("tire",""))
		var identity: Dictionary = {"id":int(car["id"]),"name":str(car["name"]),"start":tire}
		if not options.has(tire):
			identity["valid"] = false
			identity["reason"] = "Largada molhada: plano seco não é aplicável. Acompanhe o clima ao vivo."
			plans.append(identity)
			continue
		var factor: float = maxf(0.2,float(car.get("track_wear_factor",1.0)))
		var memo: Dictionary = {}
		var raw: Dictionary = _optimise(laps,options.find(tire),1 << options.find(tire),MAX_STOPS,options,factor,float(race.pit_loss),catalog,memo)
		if float(raw["cost"]) >= INF or (raw["stints"] as Array).size() < 2:
			identity["valid"] = false
			identity["reason"] = "Não existe um plano seco seguro com os limites atuais."
		else:
			identity["valid"] = true
			identity["stints"] = _decorate(raw["stints"],factor,catalog)
			identity["factor"] = factor
			identity["cost_estimate"] = float(raw["cost"])
			identity["reason"] = "Estimativa sem tráfego futuro e sem mudança de clima."
		plans.append(identity)
	if plans.size() == 2 and bool(plans[0].get("valid",false)) and bool(plans[1].get("valid",false)):
		plans[1] = _shift_first_stop(plans[1],int(plans[0]["stints"][0]["to"]),catalog,float(race.pit_loss))
	var overlap: bool = plans.size() == 2 and bool(plans[0].get("valid",false)) and bool(plans[1].get("valid",false)) and int(plans[0]["stints"][0]["to"]) == int(plans[1]["stints"][0]["to"])
	return {"valid":plans.size()==2,"plans":plans,"laps":laps,"track":str(race.track.get("name","")),
		"options":options,"wetness":rain,"first_stop_overlap":overlap,
		"scope":"Projeção pré-largada estimada; a corrida real pode exigir paradas antes/depois."}
