extends Node
## Neutral identity policy: never load cached photos or request new images.
## Keep the public interface for the existing menus and HUD.
signal status_changed(message: String)
signal portraits_finished()
var status := "Identidade visual neutra • retratos desativados"
var download_state := "idle"
func has_photo(_driver_name: String) -> bool:
    return false
func get_photo(_driver_name: String) -> Texture2D:
    return null
func download_for_team(_driver_names: Array[String]) -> void:
    status_changed.emit(status)
    portraits_finished.emit()
