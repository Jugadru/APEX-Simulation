extends RefCounted
## Historical 2012 race-weekend slick nominations. See data/tyres_2012.json.
## Actual performance coefficients are tunable game rules, not Pirelli measurements.
const CATALOG_PATH := "res://data/tyres_2012.json"
const LEGACY_OPTIONS := ["Macio", "Médio", "Duro"]

static func catalog() -> Dictionary:
	var text: String = FileAccess.get_file_as_string(CATALOG_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("APEX: tyres_2012.json is missing or invalid")
		return {}
	return parsed

static func track_profile(catalog_data: Dictionary, code: String) -> Dictionary:
	var tracks: Dictionary = catalog_data.get("tracks", {})
	var info: Dictionary = tracks.get(code, {})
	if info.is_empty():
		# LAB is a reserved synthetic CI circuit, not a historical nomination.
		# Preserve the former fallback exactly; other missing circuits still warn.
		if code == "LAB":
			return {"dry": ["Médio", "Duro"], "severity": 1.0}
		push_warning("APEX 2012: no tyre nomination for circuit %s" % code)
		return {"dry": ["Médio", "Duro"], "severity": 1.0}
	return info.duplicate(true)

static func available(catalog_data: Dictionary, code: String) -> Array:
	var profile: Dictionary = track_profile(catalog_data, code)
	var options: Array = profile.get("dry", [])
	return options.duplicate()

static func compound(catalog_data: Dictionary, compound_name: String) -> Dictionary:
	var specs: Dictionary = catalog_data.get("compounds", {})
	return specs.get(compound_name, {}).duplicate(true)

static func is_available(catalog_data: Dictionary, code: String, compound_name: String) -> bool:
	return available(catalog_data, code).has(compound_name)
