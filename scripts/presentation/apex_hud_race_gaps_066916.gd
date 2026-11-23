extends RefCounted
## APEX v0.6.6.9.16 — Race Gaps & Overtaking 2.0 (first increment).
## Presentation ONLY: physical nearby-car observations from frozen progress.
## Progress is in completed+fractional laps; distance is in schematic APEX
## circuit units, NOT GPS/FIA metres or a measured time gap. Never emit orders,
## mutate cars, influence overtaking, query RNG or persist to a replay/save.
const PROXIMITY_WINDOW_UNITS: float = 38.0
const MIN_SEPARATION_UNITS: float = 0.000001

static func observe(sorted_cars: Array, circuit_length_units: float,
		finished: bool = false) -> Dictionary:
	var output: Dictionary = {}
	var length: float = maxf(100.0, circuit_length_units)
	for entry in sorted_cars:
		if not entry is Dictionary:
			continue
		var car: Dictionary = entry
		var car_id: int = int(car.get("id", -1))
		if car_id < 0:
			continue
		var result: Dictionary = {
			"label":"—", "hint":"Proximidade indisponível.",
			"ahead_id":-1, "behind_id":-1,
			"ahead_units":-1.0, "behind_units":-1.0,
			"active":false, "version":"0.6.6.9.16"}
		output[car_id] = result
		if finished or bool(car.get("finished", false)) 				or bool(car.get("disqualified", false)) 				or float(car.get("pit_left", 0.0)) > 0.0:
			continue
		var progress: float = float(car.get("progress", 0.0))
		var ahead_distance: float = INF
		var behind_distance: float = INF
		var ahead_name: String = ""
		var behind_name: String = ""
		for candidate in sorted_cars:
			if not candidate is Dictionary:
				continue
			var other: Dictionary = candidate
			var other_id: int = int(other.get("id", -1))
			if other_id < 0 or other_id == car_id 					or bool(other.get("finished", false)) 					or bool(other.get("disqualified", false)) 					or float(other.get("pit_left", 0.0)) > 0.0:
				continue
			# Neighbours can be on another lap. Classificatory adjacency is
			# not a physical distance; modulo handles start/finish crossings.
			var delta: float = fposmod(float(other.get("progress", 0.0)) -
					progress, 1.0)
			var front: float = delta * length
			var rear: float = fposmod(progress -
					float(other.get("progress", 0.0)), 1.0) * length
			if front > MIN_SEPARATION_UNITS and front <= PROXIMITY_WINDOW_UNITS 					and (front < ahead_distance or (is_equal_approx(front, ahead_distance) 					and other_id < int(result["ahead_id"]))):
				ahead_distance = front
				result["ahead_id"] = other_id
				ahead_name = str(other.get("name", "Piloto"))
			if rear > MIN_SEPARATION_UNITS and rear <= PROXIMITY_WINDOW_UNITS 					and (rear < behind_distance or (is_equal_approx(rear, behind_distance) 					and other_id < int(result["behind_id"]))):
				behind_distance = rear
				result["behind_id"] = other_id
				behind_name = str(other.get("name", "Piloto"))
		result["active"] = true
		var front_text: String = "sem carro próximo" if ahead_distance == INF else 				"%s a ~%.1f unidades" % [ahead_name, ahead_distance]
		var back_text: String = "sem carro próximo" if behind_distance == INF else 				"%s a ~%.1f unidades" % [behind_name, behind_distance]
		if ahead_distance != INF:
			result["ahead_units"] = ahead_distance
			result["label"] = "F %.0fu" % ahead_distance
		elif behind_distance != INF:
			result["behind_units"] = behind_distance
			result["label"] = "T %.0fu" % behind_distance
		else:
			result["label"] = "LIVRE"
		if behind_distance != INF:
			result["behind_units"] = behind_distance
		result["hint"] = "PISTA | Frente: %s; atrás: %s. Janela física de 38 unidades APEX. F=frente, T=trás. NÃO é intervalo cronometrado nem posição de classificação." % [
			front_text, back_text]
	return output

static func label_for(observation: Dictionary, car_id: int) -> String:
	var entry: Dictionary = observation.get(car_id, {})
	return str(entry.get("label", "—"))

static func hint_for(observation: Dictionary, car_id: int) -> String:
	var entry: Dictionary = observation.get(car_id, {})
	return str(entry.get("hint", "Proximidade indisponível."))
