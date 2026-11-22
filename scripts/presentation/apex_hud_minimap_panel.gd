extends RefCounted
## Refatoração 06 (final): somente montagem visual do minimapa na HUD.
## A HUD continua responsável pela rota, pelo layout e pelos comandos.
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")

static func build(parent: Node, mini_map_script: Script, panel: Callable,
		column: Callable, line: Callable, label: Callable, button: Callable,
		set_view: Callable) -> Dictionary:
	var map_box: PanelContainer = panel.call(parent)
	map_box.add_theme_stylebox_override("panel", HudSkin.panel(Color(0.105, 0.110, 0.150, 0.50), 3, Color.TRANSPARENT, 8))
	var map_column: VBoxContainer = column.call(map_box, 2)
	var map_heading: HBoxContainer = line.call(map_column, 5)
	var mini_heading: Label = label.call(map_heading, "MAPA DA CORRIDA", 12,
		HudSkin.MUTED)
	mini_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.call(map_heading, "2D ↗", set_view.bind(0), 52)
	var minimap: Control = mini_map_script.new()
	minimap.show_background = false
	minimap.custom_minimum_size = Vector2(190, 143)
	minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	minimap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_column.add_child(minimap)
	return {"map_box": map_box, "minimap": minimap}
