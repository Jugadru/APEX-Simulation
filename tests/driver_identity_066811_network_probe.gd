extends SceneTree
## OPTIONAL live-source smoke. Not a deterministic gate: Wikimedia may be offline
## or rate-limit a GitHub runner; never substitute a racing car if it fails.
const Manager = preload("res://scripts/apex_portrait_manager.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var manager = Manager.new()
	root.add_child(manager)
	await process_frame
	manager.status_changed.connect(func(m: String) -> void: print("PORTRAIT_NETWORK_STATUS ", m))
	var names: Array[String] = ["Fernando Alonso", "Bruno Senna"]
	manager.download_for_team(names)
	await manager.portraits_finished
	var checked := 0
	for name in names:
		var photo: Texture2D = manager.get_photo(name)
		if photo != null:
			var dims: Vector2i = photo.get_size()
			print("PORTRAIT_NETWORK_FACE_SOURCE ", name, " size=", dims,
				" credit=", manager.get_credit(name),
				" url=", manager.get_source_url(name))
			if dims.x >= 128 and dims.y >= 128:
				checked += 1
		else:
			print("PORTRAIT_NETWORK_FALLBACK ", name, " initials_only=true")
	print("PORTRAIT_NETWORK_066811_RESULT downloaded=", checked, "/", names.size(),
		" source_check=metadata_author_license image_content_visual_review_required")
	quit(0 if checked == names.size() else 1)
