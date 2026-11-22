extends RefCounted
## Read-only classification neighbours. Never estimates physical track proximity.

static func code(car: Dictionary) -> String:
	return str(car.get("name", "—")).strip_edges().get_slice(" ", str(car.get("name", "")).count(" ")).left(3).to_upper()

static func neighbours(order: Array, driver_id: int, final: bool) -> String:
	var index := -1
	for i in range(order.size()):
		if int(order[i].get("id", -1)) == driver_id:
			index = i
			break
	if index < 0:
		return "FRENTE —    |    ATRÁS —"
	var ahead := "LÍDER" if index == 0 else code(order[index - 1]) + " " + interval(order[index], final)
	var behind := "—" if index == order.size() - 1 else code(order[index + 1]) + " " + interval(order[index + 1], final)
	return "FRENTE %s    |    ATRÁS %s" % [ahead, behind]

static func interval(car: Dictionary, final: bool) -> String:
	if final:
		return str(car.get("interval_label", "—"))
	if not car.has("interval") or bool(car.get("disqualified", false)):
		return "—"
	return "+%.2fs" % maxf(0.0, float(car["interval"]))
