extends SceneTree
## Refatoração 04: contrato real do painel Pit Wall — hierarquia, textos e sinais.
const Hud = preload("res://scripts/apex_race_hud_0622.gd")
const QuickPanel = preload("res://scripts/presentation/apex_hud_pitwall_quick_panel.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	printerr("HUD_PITWALL_QUICK_PANEL_REFACTOR_FAIL " + reason)
	quit(1)

func _run() -> void:
	var hud = Hud.new()
	var panel: PanelContainer = QuickPanel.build(hud, Callable(hud, "_panel"),
		Callable(hud, "_column"), Callable(hud, "_line"), Callable(hud, "_text"),
		Callable(hud, "_btn"), Callable(hud, "_open_window"))
	if panel.get_parent() != hud or panel.get_child_count() != 1:
		hud.free()
		_fail("Painel perdeu hierarquia ou parentesco")
		return
	var column: VBoxContainer = panel.get_child(0)
	if column.get_theme_constant("separation") != 5 or column.get_child_count() != 3:
		hud.free()
		_fail("Coluna e espacamento mudaram")
		return
	var heading: Label = column.get_child(0)
	if heading.text != "PIT WALL / CENTRO DE DECISÕES":
		hud.free()
		_fail("Titulo do painel mudou")
		return
	var names: Array = ["RESUMO", "PLANO", "DECISÃO", "ANÁLISE"]
	var destinations: Array = ["pitwall3", "estrategia", "engineer", "graficos"]
	var tooltips: Array = [
		"Pit Wall 3.0 e situações dos dois carros",
		"Planejar stints e agendar paradas",
		"Ordens e análises do engenheiro",
		"Gráficos dinâmicos baseados na simulação"]
	var widths: Array = [101.0, 99.0, 101.0, 99.0]
	for row_index in range(2):
		var row: HBoxContainer = column.get_child(row_index + 1)
		if row.get_theme_constant("separation") != 4 or row.get_child_count() != 2:
			hud.free()
			_fail("Estrutura de atalhos mudou no grupo %d" % row_index)
			return
		for slot in range(2):
			var i: int = row_index * 2 + slot
			var action: Button = row.get_child(slot)
			if action.text != names[i] or action.tooltip_text != tooltips[i]:
				hud.free()
				_fail("Texto ou tooltip alterado no atalho %d" % i)
				return
			if action.custom_minimum_size.x != widths[i] or action.custom_minimum_size.y != 29.0:
				hud.free()
				_fail("Geometria do botao mudou no atalho %d" % i)
				return
			if not action.pressed.is_connected(Callable(hud, "_open_window").bind(destinations[i])):
				hud.free()
				_fail("Callback desconectado no atalho %d" % i)
				return
	hud.free()
	print("HUD_PITWALL_QUICK_PANEL_REFACTOR_PASS")
	quit(0)
