extends SceneTree
const Styles = preload("res://scripts/apex_race_hud_skin_ui01.gd")
const Hud = preload("res://scripts/apex_hud_rebroadcast_0668.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	assert(Hud.MODES == ["BROADCAST", "COMPACT", "FULL"])
	assert(Hud.tyre_tint("I") == Color("#42BE89"))
	assert(Hud._order_status({"pit_scheduled_lap": 21}) == "V21")
	assert(Hud._order_status({"pit_request": true, "pit_scheduled_lap": 21}) == "BOX")
	assert(Hud._order_status({"pit_left": 1.5, "pit_scheduled_lap": 21}) == "PIT")
	assert(Hud._order_status({"disqualified": true}) == "DSQ")
	var label := Label.new()
	assert(Hud.set_text_if_changed(label, "ABC") == 1)
	assert(Hud.set_text_if_changed(label, "ABC") == 0)
	assert(Hud.set_text_if_changed(label, "XYZ") == 1)
	assert(Styles.ORANGE == Color("#FF8A21"))
	label.free()
	print("PASS HUD_REBROADCAST_0668_UNIT palette, status and incremental text")
	quit(0)
