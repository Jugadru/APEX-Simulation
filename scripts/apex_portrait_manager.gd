extends Node
## Local-only portrait adapter restored from PR #26. No HTTP, user:// writes,
## race state access or automatic redistribution. Cache shared with card UI.
const PortraitLocal = preload("res://scripts/apex_portrait_local_2012.gd")
signal status_changed(message: String)
signal portraits_finished()
var status := "Retratos 2012: pack local opcional; reinicie após instalar."
var download_state := "idle"

func has_photo(driver_name: String) -> bool:
	return get_photo(driver_name) != null

func get_photo(driver_name: String) -> Texture2D:
	return PortraitLocal.get_texture(driver_name, "hud")

func get_profile_photo(driver_name: String) -> Texture2D:
	return PortraitLocal.get_texture(driver_name, "profile")

func download_for_team(_driver_names: Array[String]) -> void:
	# Preserve existing callers without re-enabling network downloads.
	status_changed.emit(status)
	portraits_finished.emit()
