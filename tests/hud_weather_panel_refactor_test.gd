extends SceneTree
## Refatoração 05: valida o painel climático real sem depender da simulação.
const Hud = preload("res://scripts/apex_race_hud_0622.gd")
const WeatherPanel = preload("res://scripts/presentation/apex_hud_weather_panel.gd")
const HudSkinTest = preload("res://scripts/apex_race_hud_skin_ui01.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	printerr("HUD_WEATHER_PANEL_REFACTOR_FAIL " + message)
	quit(1)

func _run() -> void:
	var hud = Hud.new()
	var result: Dictionary = WeatherPanel.build(hud, Callable(hud, "_panel"),
		Callable(hud, "_column"), Callable(hud, "_text"))
	if not (result.get("weather_box") is PanelContainer) or not (result.get("weather_line") is Label):
		hud.free()
		_fail("Painel ou label climático ausente")
		return
	var panel: PanelContainer = result["weather_box"]
	var line: Label = result["weather_line"]
	if panel.get_parent() != hud or panel.get_child_count() != 1:
		hud.free()
		_fail("Hierarquia do painel alterada")
		return
	var column: VBoxContainer = panel.get_child(0)
	if column.get_theme_constant("separation") != 4 or column.get_child_count() != 2:
		hud.free()
		_fail("Coluna ou espaçamento alterado")
		return
	var heading: Label = column.get_child(0)
	if heading.text != "CONDIÇÕES DA PISTA" or heading.get_theme_font_size("font_size") != 11:
		hud.free()
		_fail("Título do painel alterado")
		return
	if heading.get_theme_color("font_color") != HudSkinTest.ORANGE:
		hud.free()
		_fail("Cor do título alterada")
		return
	if line.get_parent() != column or line.text != "Aguardando clima":
		hud.free()
		_fail("Texto inicial ou posição da linha alterados")
		return
	if line.get_theme_font_size("font_size") != 12 or line.get_theme_color("font_color") != HudSkinTest.WHITE:
		hud.free()
		_fail("Aparência do texto climático alterada")
		return
	if line.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
		hud.free()
		_fail("Quebra de linha climática alterada")
		return
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null or style.bg_color != HudSkinTest.SURFACE:
		hud.free()
		_fail("Estilo do painel alterado")
		return
	# A conexão de relayout permanece responsabilidade da HUD.
	panel.minimum_size_changed.connect(Callable(hud, "layout_hud"), CONNECT_DEFERRED)
	if not panel.minimum_size_changed.is_connected(Callable(hud, "layout_hud")):
		hud.free()
		_fail("Contrato de callback de relayout indisponível")
		return
	hud.free()
	print("HUD_WEATHER_PANEL_REFACTOR_PASS")
	quit(0)
