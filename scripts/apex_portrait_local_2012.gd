extends RefCounted
## APEX v0.6.6.8.15 — optional user-supplied 2012 portrait pack.
## Only presentation assets. Does not access or modify the race simulation.
const BASE := "res://assets/portraits_2012"
const DRIVER_IDS := [
	"sebastian_vettel", "mark_webber", "jenson_button", "lewis_hamilton",
	"fernando_alonso", "felipe_massa", "michael_schumacher", "nico_rosberg",
	"kimi_raikkonen", "romain_grosjean", "paul_di_resta", "nico_hulkenberg",
	"kamui_kobayashi", "sergio_perez", "daniel_ricciardo", "jean_eric_vergne",
	"pastor_maldonado", "bruno_senna", "heikki_kovalainen", "vitaly_petrov",
	"pedro_de_la_rosa", "narain_karthikeyan", "timo_glock", "charles_pic"
]

# Cache positive and negative lookups for the fixed 24 x 2 local resources.
# Installing the pack requires restarting/importing the project.
static var _textures: Dictionary = {}

static func driver_id(driver_name: String) -> String:
	var normalized := driver_name.strip_edges().to_lower()
	# Godot string replacement is explicit: no dependency on locale or accents.
	for replacement in [
		["ä", "a"], ["á", "a"], ["à", "a"], ["â", "a"], ["ã", "a"],
		["é", "e"], ["è", "e"], ["ê", "e"], ["ë", "e"],
		["í", "i"], ["ï", "i"], ["ó", "o"], ["ö", "o"],
		["ú", "u"], ["ü", "u"], ["ç", "c"]
	]:
		normalized = normalized.replace(str(replacement[0]), str(replacement[1]))
	return normalized.replace("-", "_").replace(" ", "_")

static func texture_path(driver_name: String, kind: String = "hud") -> String:
	var key := driver_id(driver_name)
	if not key in DRIVER_IDS or not kind in ["hud", "profile"]:
		return ""
	return "%s/%s/%s_%s_2012.png" % [BASE, kind, key, kind]

static func has_texture(driver_name: String, kind: String = "hud") -> bool:
	var path := texture_path(driver_name, kind)
	return get_texture(driver_name, kind) != null

static func get_texture(driver_name: String, kind: String = "hud") -> Texture2D:
	var path := texture_path(driver_name, kind)
	if path.is_empty():
		return null
	if _textures.has(path):
		return _textures[path] as Texture2D
	var texture: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		texture = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	_textures[path] = texture
	return texture

static func available_count(kind: String = "hud") -> int:
	var present := 0
	for key in DRIVER_IDS:
		if has_texture(str(key).replace("_", " "), kind):
			present += 1
	return present
