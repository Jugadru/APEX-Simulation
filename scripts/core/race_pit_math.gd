extends RefCounted
## Pure pit calculations. The state machine, RNG and pit-lane path continue in
## race_engine.gd to avoid disrupting the already-tested double-stack logic.

static func crew_effects(levels: Dictionary, service_save: float, dock_save: float, fault_prob: float, unsafe_prob: float, precision_fault_reduction: float, precision_release_reduction: float) -> Dictionary:
	var speed: int = int(levels.get("Agilidade", 0))
	var precision: int = int(levels.get("Precisão", 0))
	var coord: int = int(levels.get("Coordenação", 0))
	return {"service_saving": service_save * float(speed),
		"dock_saving": dock_save * float(coord),
		"fault_chance": fault_prob * (1.0 - precision_fault_reduction * float(precision)),
		"unsafe_chance": unsafe_prob * (1.0 - precision_release_reduction * float(precision))}

static func service_durations(nominal: float, service_begin: float, service_end: float, queue_phase: float, benefits: Dictionary) -> Dictionary:
	var service_base: float = nominal * (service_end - service_begin)
	var dock_base: float = nominal * (service_begin - queue_phase)
	var service_saving: float = minf(float(benefits["service_saving"]), maxf(0.0, service_base - 2.7))
	var dock_saving: float = minf(float(benefits["dock_saving"]), maxf(0.0, dock_base - 1.8))
	return {"service_total": service_base - service_saving,
		"dock_total": dock_base - dock_saving,
		"pit_total": nominal - service_saving - dock_saving}
