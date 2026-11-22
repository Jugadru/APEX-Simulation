extends SceneTree
## Refactor 03: construction, layout, callback and row contract in real Godot.
const Hud = preload("res://scripts/apex_race_hud_0622.gd")
const HudSkinTest = preload("res://scripts/apex_race_hud_skin_ui01.gd")
const Ranking = preload("res://scripts/presentation/apex_hud_ranking_panel.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(why: String) -> void:
	printerr("HUD_RANKING_PANEL_REFACTOR_FAIL " + why)
	quit(1)

func _run() -> void:
	var hud = Hud.new()
	var idle: StyleBoxFlat = HudSkinTest.button_style("rank")
	var selected: StyleBoxFlat = HudSkinTest.button_style("rank_selected")
	var result: Dictionary = Ranking.build(hud, idle, selected,
		Callable(hud, "_panel"), Callable(hud, "_column"), Callable(hud, "_line"),
		Callable(hud, "_text"), Callable(hud, "_btn"),
		Callable(hud, "_move_metric"), Callable(hud, "_select_grid_car"))
	if not (result.get("ranking") is PanelContainer) or not (result.get("standings_title") is Label):
		_fail("Missing panel/title")
		hud.free()
		return
	var root: PanelContainer = result["ranking"]
	var title: Label = result["standings_title"]
	var rows: Array = result["standing_rows"]
	if root.get_parent() != hud or root.get_child_count() != 1:
		_fail("Ranking root/child hierarchy changed")
		hud.free()
		return
	if title.text != "INTERVALO" or title.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
		_fail("Header text or alignment changed")
		hud.free()
		return
	if rows.size() != 24:
		_fail("Ranking should have exactly 24 rows")
		hud.free()
		return
	var left: VBoxContainer = root.get_child(0)
	if left.get_theme_constant("separation") != 3 or left.get_child_count() != 2:
		_fail("Panel columns/header/scroll structure changed")
		hud.free()
		return
	var header: HBoxContainer = left.get_child(0)
	if header.get_child_count() != 3:
		_fail("Ranking header lost previous/next controls")
		hud.free()
		return
	if not (header.get_child(0) as Button).pressed.is_connected(Callable(hud, "_move_metric").bind(-1)):
		_fail("Previous metric signal changed")
		hud.free()
		return
	if not (header.get_child(2) as Button).pressed.is_connected(Callable(hud, "_move_metric").bind(1)):
		_fail("Next metric signal changed")
		hud.free()
		return
	var scroll: ScrollContainer = left.get_child(1)
	if scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("Horizontal scroll behavior changed")
		hud.free()
		return
	var entries: VBoxContainer = scroll.get_child(0)
	if entries.get_child_count() != 24:
		_fail("Ranking row nodes were not placed in scroll")
		hud.free()
		return
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var bar: HBoxContainer = row["row"]
		if bar.get_parent() != entries or bar.get_child_count() != 6:
			_fail("Row hierarchy changed at index %d" % i)
			hud.free()
			return
		if bar.custom_minimum_size.y != 24 or bar.get_theme_constant("separation") != 3:
			_fail("Row geometry changed at %d" % i)
			hud.free()
			return
		if (row["pos"] as Label).text != str(i + 1):
			_fail("Displayed position changed at %d" % i)
			hud.free()
			return
		var driver: Button = row["driver"]
		if not driver.pressed.is_connected(Callable(hud, "_select_grid_car").bind(i)):
			_fail("Driver selection callback changed at %d" % i)
			hud.free()
			return
		if driver.get_theme_stylebox("normal") != idle or driver.get_theme_stylebox("pressed") != selected:
			_fail("Rank selection styles changed at %d" % i)
			hud.free()
			return
		if (row["tyre"] as Label).text != "—" or (row["detail"] as Label).text != "—":
			_fail("Initial labels changed at %d" % i)
			hud.free()
			return
	hud.free()
	print("HUD_RANKING_PANEL_REFACTOR_PASS")
	quit(0)
