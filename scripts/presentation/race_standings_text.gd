extends RefCounted
## Presentation-only standings text. Never changes race ranking or sporting state.
## The Race Engine owns ordering, gap labels and tyre catalog.
## Keep layout identical to the historic RaceEngine.standings_text contract.

static func format(order: Array, finished: bool, limit: int, tyre_label: Callable) -> String:
	var output := ""
	for i in range(mini(limit, order.size())):
		var car: Dictionary = order[i]
		var gap := (str(car.get("gap_label", "")) if finished
			else ("LÍDER" if i == 0 else "+%.1fs" % float(car["gap"])))
		if bool(car.get("fuel_dnf_0701",false)): gap="DNF"
		output += "%02d  %-18s  %-5s %s\n" % [
			i + 1, car["name"], tyre_label.call(str(car["tire"])), gap]
	return output
