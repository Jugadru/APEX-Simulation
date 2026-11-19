extends RefCounted
## APEX visual only: menu option A is official. B is an offline alternative.
const OFFICIAL_PATH := "res://assets/menu/apex_menu_background_a.png"

static func install(parent: Control) -> Control:
	var background: Control = null
	if ResourceLoader.exists(OFFICIAL_PATH, "Texture2D"):
		var texture := load(OFFICIAL_PATH) as Texture2D
		if texture != null:
			var picture := TextureRect.new()
			picture.texture = texture
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			background = picture
	if background == null:
		var fallback := ColorRect.new()
		fallback.color = Color("#101115")
		background = fallback
	background.name = "ApexMenuBackground"
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return background
