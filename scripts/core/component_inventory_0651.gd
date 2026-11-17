extends RefCounted
## Passive inventory. Never writes to race cars, RNG, levels or strategy.
const SCHEMA := 1

static func ensure(state: Dictionary, categories: Array) -> bool:
	if state.has("component_inventory"):
		return false
	var inventory := {"schema": SCHEMA, "parts": {}, "sessions": {}}
	for car in [1, 2]:
		for category in categories:
			var id := Crypto.new().generate_random_bytes(16).hex_encode()
			while inventory.parts.has(id):
				id = Crypto.new().generate_random_bytes(16).hex_encode()
			inventory.parts[id] = {"id": id, "name": category, "category": category,
				"specification": int(state.levels.get(category, 0)), "condition": null,
				"integrity": null, "km": 0.0, "prior_km_unknown": true,
				"car": car, "status": "installed", "history": []}
			_event(inventory.parts[id], "migration", "Inventário iniciado; uso anterior indisponível", {})
	state.component_inventory = inventory
	return true

static func validate(inventory: Dictionary, categories: Array) -> String:
	if int(inventory.get("schema", 0)) != SCHEMA or typeof(inventory.get("parts")) != TYPE_DICTIONARY:
		return "Inventário incompatível. Dados preservados; operações bloqueadas."
	if typeof(inventory.get("sessions")) != TYPE_DICTIONARY:
		return "Histórico de sessões inválido."
	var occupied := {}
	for id in inventory.parts:
		var p = inventory.parts[id]
		if typeof(p) != TYPE_DICTIONARY:
			return "Registro inválido."
		for field in ["id", "name", "category", "specification", "condition", "integrity", "km", "car", "status", "history", "prior_km_unknown"]:
			if not p.has(field): return "Registro incompleto; dados preservados."
		if str(p.get("id", "")) != str(id) or not categories.has(p.get("category")):
			return "Identificador ou categoria inválidos."
		if not ["installed", "available", "stored", "unusable"].has(p.get("status")):
			return "Estado inválido."
		if not is_finite(float(p.get("km", -1))) or float(p.get("km", -1)) < 0 or typeof(p.get("history")) != TYPE_ARRAY:
			return "Quilometragem ou histórico inválidos."
		var car := int(p.get("car", 0))
		if p.status == "installed":
			var slot := "%d:%s" % [car, p.category]
			if car not in [1,2] or occupied.has(slot):
				return "Instalação duplicada ou carro inválido."
			occupied[slot] = id
		elif car != 0:
			return "Peça fora do carro com vínculo inválido."
	return ""

static func installed(inventory: Dictionary, car: int, category: String) -> String:
	for id in inventory.get("parts", {}):
		var p: Dictionary = inventory.parts[id]
		if int(p.car) == car and p.category == category and p.status == "installed":
			return id
	return ""

static func operate(inventory: Dictionary, categories: Array, id: String, action: String, car: int, context: Dictionary) -> String:
	var error := validate(inventory, categories)
	if not error.is_empty(): return error
	if not inventory.parts.has(id): return "Peça não encontrada."
	var p: Dictionary = inventory.parts[id]
	if action == "install":
		if car not in [1,2] or p.status not in ["available", "stored"]:
			return "Remova a peça do carro de origem antes de instalar."
		var old_id := installed(inventory, car, str(p.category))
		if not old_id.is_empty():
			var old: Dictionary = inventory.parts[old_id]
			old.car = 0
			old.status = "available"
			_event(old, "replacement", "Removida do CAR %02d; substituta %s" % [car, id], context)
		p.car = car
		p.status = "installed"
		_event(p, "installation", "Instalada no CAR %02d" % car, context)
	elif action == "remove":
		if p.status != "installed": return "A peça não está instalada."
		_event(p, "removal", "Removida do CAR %02d" % int(p.car), context)
		p.car = 0
		p.status = "available"
	elif action in ["store", "release", "retire"]:
		if p.status not in ["available", "stored"]: return "Operação exige peça removida e utilizável."
		p.status = {"store":"stored", "release":"available", "retire":"unusable"}[action]
		_event(p, action, "Estado alterado: " + str(p.status), context)
	else:
		return "Operação desconhecida."
	return validate(inventory, categories)

static func ready(inventory: Dictionary, categories: Array) -> bool:
	if not validate(inventory, categories).is_empty(): return false
	for car in [1,2]:
		for category in categories:
			if installed(inventory, car, category).is_empty(): return false
	return true

static func observe(inventory: Dictionary, session: String, race, context: Dictionary) -> bool:
	# progress is the engine's cumulative lap fraction, including pit-lane progress.
	# This measures simulated circuit-equivalent km, not a GPS pit-lane trajectory.
	if not inventory.sessions.has(session): inventory.sessions[session] = {}
	var checkpoints: Dictionary = inventory.sessions[session]
	var cars: Array = race.player_cars()
	cars.sort_custom(func(a, b): return int(a.id) < int(b.id))
	var changed := false
	for index in range(cars.size()):
		var car: Dictionary = cars[index]
		var key := str(car.id)
		var progress := maxf(0.0, float(car.progress))
		var previous := float(checkpoints.get(key, 0.0))
		var delta := maxf(0.0, progress - previous) * float(race.lap_km)
		if delta <= 0.0: continue
		checkpoints[key] = progress
		for p in inventory.parts.values():
			if p.status != "installed" or int(p.car) != index + 1: continue
			p.km = float(p.km) + delta
			var history: Array = p.history
			if history.is_empty() or history[-1].get("session", "") != session:
				_event(p, "usage", "Uso em " + str(race.track_name), context)
				history[-1]["session"] = session
				history[-1]["km"] = 0.0
				history[-1]["driver"] = str(car.name)
				history[-1]["car"] = index + 1
			history[-1]["km"] = float(history[-1].km) + delta
		changed = true
	return changed

static func _event(part: Dictionary, kind: String, message: String, context: Dictionary) -> void:
	var event := context.duplicate(true)
	event.merge({"type": kind, "message": message, "at": Time.get_datetime_string_from_system(true)}, true)
	part.history.append(event)
