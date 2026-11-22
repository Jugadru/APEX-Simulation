extends SceneTree
## Refatoração 06 final: contrato visual do minimapa, sem simulação esportiva.
const Hud = preload("res://scripts/apex_race_hud_0622.gd")
const MiniMap = preload("res://scripts/apex_mini_map.gd")
const MiniMapPanel = preload("res://scripts/presentation/apex_hud_minimap_panel.gd")
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("HUD_MINIMAP_PANEL_REFACTOR_FAIL " + message)
	quit(1)

func _run() -> void:
	var hud = Hud.new()
	var result: Dictionary = MiniMapPanel.build(hud, MiniMap,
		Callable(hud, "_panel"), Callable(hud, "_column"),
		Callable(hud, "_line"), Callable(hud, "_text"),
		Callable(hud, "_btn"), Callable(hud, "_set_view"))
	if not (result.get("map_box") is PanelContainer) or not (result.get("minimap") is MiniMap):
		hud.free()
		_fail("Painel ou minimapa ausente")
		return
	var panel: PanelContainer = result["map_box"]
	var minimap: Control = result["minimap"]
	if panel.get_parent() != hud or panel.get_child_count() != 1:
		hud.free()
		_fail("Hierarquia principal alterada")
		return
	var body: VBoxContainer = panel.get_child(0)
	if body.get_theme_constant("separation") != 2 or body.get_child_count() != 2:
		hud.free()
		_fail("Coluna ou espaco alterados")
		return
	var heading: HBoxContainer = body.get_child(0)
	if heading.get_theme_constant("separation") != 5 or heading.get_child_count() != 2:
		hud.free()
		_fail("Cabecalho alterado")
		return
	var title: Label = heading.get_child(0)
	if title.text != "MAPA DA CORRIDA" or title.get_theme_font_size("font_size") != 12:
		hud.free()
		_fail("Titulo alterado")
		return
	if title.get_theme_color("font_color") != HudSkin.MUTED or title.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
		hud.free()
		_fail("Aparencia do titulo alterada")
		return
	var action: Button = heading.get_child(1)
	if action.text != "2D ↗" or action.custom_minimum_size.x != 52:
		hud.free()
		_fail("Botao 2D alterado")
		return
	if not action.pressed.is_connected(Callable(hud, "_set_view").bind(0)):
		hud.free()
		_fail("Callback do botao 2D perdido")
		return
	if minimap.get_parent() != body or minimap.custom_minimum_size != Vector2(190, 143):
		hud.free()
		_fail("Localizacao ou dimensoes do minimapa alteradas")
		return
	if minimap.size_flags_vertical != Control.SIZE_EXPAND_FILL or minimap.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
		hud.free()
		_fail("Flags de layout alteradas")
		return
	hud.free()
	print("HUD_MINIMAP_PANEL_REFACTOR_PASS")
	quit(0)
