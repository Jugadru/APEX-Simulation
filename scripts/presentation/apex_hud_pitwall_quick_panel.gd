extends RefCounted
## Refatoração 04: construtor visual dos atalhos do Pit Wall na HUD completa.
## Apenas UI: os callbacks continuam sendo fornecidos pela HUD principal.
const HudSkin = preload("res://scripts/apex_race_hud_skin_ui01.gd")

static func build(parent: Node, panel: Callable, column: Callable, line: Callable,
		label: Callable, button: Callable, open_window: Callable) -> PanelContainer:
	var quick_panel: PanelContainer = panel.call(parent, HudSkin.SURFACE)
	var quick_column: VBoxContainer = column.call(quick_panel, 5)
	label.call(quick_column, "PIT WALL / CENTRO DE DECISÕES", 11, HudSkin.ORANGE)
	var quick_first: HBoxContainer = line.call(quick_column, 4)
	var summary: Button = button.call(quick_first, "RESUMO", open_window.bind("pitwall3"), 101)
	summary.tooltip_text = "Pit Wall 3.0 e situações dos dois carros"
	var plan: Button = button.call(quick_first, "PLANO", open_window.bind("estrategia"), 99)
	plan.tooltip_text = "Planejar stints e agendar paradas"
	var quick_second: HBoxContainer = line.call(quick_column, 4)
	var decision: Button = button.call(quick_second, "DECISÃO", open_window.bind("engineer"), 101)
	decision.tooltip_text = "Ordens e análises do engenheiro"
	var analysis: Button = button.call(quick_second, "ANÁLISE", open_window.bind("graficos"), 99)
	analysis.tooltip_text = "Gráficos dinâmicos baseados na simulação"
	return quick_panel
