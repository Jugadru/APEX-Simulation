extends SceneTree
## Run after optional portrait assets have been placed at res://assets/portraits_2012.
## Headless: godot --headless --path . --script res://tests/apex_portraits_menu_066815_smoke.gd
const Local = preload("res://scripts/apex_portrait_local_2012.gd")
const MenuBackground = preload("res://scripts/apex_menu_background.gd")
const NAMES := [
	"Sebastian Vettel", "Mark Webber", "Jenson Button", "Lewis Hamilton",
	"Fernando Alonso", "Felipe Massa", "Michael Schumacher", "Nico Rosberg",
	"Kimi Räikkönen", "Romain Grosjean", "Paul di Resta", "Nico Hülkenberg",
	"Kamui Kobayashi", "Sergio Pérez", "Daniel Ricciardo", "Jean-Éric Vergne",
	"Pastor Maldonado", "Bruno Senna", "Heikki Kovalainen", "Vitaly Petrov",
	"Pedro de la Rosa", "Narain Karthikeyan", "Timo Glock", "Charles Pic"
]

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var errors: Array[String] = []
	for name in NAMES:
		for kind in ["hud", "profile"]:
			var path: String = Local.texture_path(name, kind)
			if path.is_empty():
				errors.append("Unknown driver: " + name)
				continue
			var texture: Texture2D = Local.get_texture(name, kind)
			if texture != null:
				var size: Vector2i = Vector2i(384, 400) if kind == "hud" else Vector2i(640, 800)
				if texture.get_size() != Vector2(size):
					errors.append("Wrong image dimensions: " + path)
	var hud_count: int = Local.available_count("hud")
	var profile_count: int = Local.available_count("profile")
	# No user pack in git: fallback must keep running without any images.
	if (hud_count != 0 or profile_count != 0) and (hud_count != 24 or profile_count != 24):
		errors.append("Partial local pack: %d HUD and %d profiles" % [hud_count, profile_count])
	var canvas := Control.new()
	root.add_child(canvas)
	var menu_bg: Control = MenuBackground.install(canvas)
	if menu_bg == null or menu_bg.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		errors.append("Menu background is missing or intercepts mouse")
	if menu_bg is TextureRect and menu_bg.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		errors.append("Menu background stretch mode changed")
	if errors.is_empty():
		print("APEX_066815_PASS: portrait ID and assets + menu fallback")
	else:
		for message in errors:
			printerr("APEX_066815_FAIL: " + message)
	quit(0 if errors.is_empty() else 1)
