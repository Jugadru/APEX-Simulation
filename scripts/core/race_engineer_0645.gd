extends RefCounted
## Race Engineer 2.0: evidence, alternatives and fictional driver state.
const Soul = preload("res://scripts/core/race_driver_soul_0645.gd")
static func enrich(car: Dictionary, report: Dictionary, advice: Dictionary) -> Dictionary:
	var result: Dictionary = report.duplicate(true)
	result["engineer_version"] = "2.0"
	result["confidence"] = str(advice.get("decision_confidence", "MODERADA"))
	result["tactic"] = str(advice.get("tactic", "MANTER PLANO"))
	result["alternatives"] = advice.get("alternatives", []).duplicate()
	result["soul_summary"] = Soul.summary(car)
	result["tradeoff"] = str(result.get("tradeoff", "")) + " " + str(advice.get("intelligence_note", ""))
	result["forecast_note"] = str(result.get("forecast_note", "")) + " Confiança: " + str(result["confidence"]) + ". Retorno estimado ~P%d (tráfego atual)." % int(advice.get("rejoin_position", car.get("position", 1)))
	# Explicitly suppress action on terminal state even if stale advice is supplied.
	if bool(car.get("finished", false)) or int(car.get("pit_scheduled_lap", 0)) > 0 or bool(car.get("pit_request", false)) or float(car.get("pit_left", 0.0)) > 0.0:
		result["can_call_pit"] = false
	return result
