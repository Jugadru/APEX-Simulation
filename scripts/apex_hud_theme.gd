extends RefCounted
## Shared visual language for the v0.5.3.1 HUD refresh.
## The style leans toward the readability of F1 Manager and Motorsport Manager,
## while remaining generic/original and lightweight for the Apex prototype.

const BASE := Color("#111c28")
const PANEL := Color("#07121c")
const PANEL_ALT := Color("#17232e")
const EDGE := Color("#7b8794")
const EDGE_SOFT := Color("#607080")
const CYAN := Color("#ff7a00")
const GREEN := Color("#8cdb34")
const WHITE := Color("#edf5ff")
const MUTED := Color("#9bb6cb")
const WARNING := Color("#ffcf72")

static func panel(bg: Color, radius: int = 10, edge: Color = EDGE, padding: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(padding)
	return sb

static func build() -> Theme:
	var t := Theme.new()
	var normal := panel(Color("#17232e"), 8, EDGE, 8)
	var hover := panel(Color("#3a3026"), 8, CYAN, 8)
	var press := panel(Color("#ac4d00"), 8, CYAN.lightened(0.15), 8)
	var disabled := panel(Color("#102031"), 8, EDGE_SOFT, 8)
	for control_type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", control_type, normal)
		t.set_stylebox("hover", control_type, hover)
		t.set_stylebox("pressed", control_type, press)
		t.set_stylebox("disabled", control_type, disabled)
		t.set_color("font_color", control_type, WHITE)
		t.set_color("font_hover_color", control_type, Color.WHITE)
		t.set_color("font_pressed_color", control_type, Color.WHITE)
		t.set_color("font_disabled_color", control_type, MUTED.darkened(0.35))
		t.set_font_size("font_size", control_type, 14)
	for control_type in ["SpinBox", "LineEdit"]:
		t.set_stylebox("normal", control_type, panel(Color("#101d2a"), 8, EDGE_SOFT, 8))
		t.set_stylebox("focus", control_type, panel(Color("#13283d"), 8, CYAN, 8))
		t.set_stylebox("read_only", control_type, panel(Color("#0d1621"), 8, EDGE_SOFT, 8))
		t.set_color("font_color", control_type, WHITE)
		t.set_font_size("font_size", control_type, 14)
	t.set_stylebox("panel", "PanelContainer", panel(Color(0.06, 0.11, 0.18, 0.92), 12, EDGE, 10))
	t.set_stylebox("panel", "TabContainer", panel(Color("#0a1827"), 10, EDGE_SOFT, 6))
	t.set_stylebox("tab_selected", "TabBar", panel(Color("#ac4d00"), 7, CYAN, 6))
	t.set_stylebox("tab_unselected", "TabBar", panel(Color("#13283e"), 7, EDGE_SOFT, 6))
	t.set_stylebox("tab_hovered", "TabBar", panel(Color("#1c3850"), 7, EDGE, 6))
	t.set_color("font_selected_color", "TabBar", WHITE)
	t.set_color("font_unselected_color", "TabBar", MUTED)
	t.set_font_size("font_size", "TabBar", 13)
	t.set_stylebox("background", "ProgressBar", panel(Color("#203648"), 6, Color("#203648"), 0))
	t.set_stylebox("fill", "ProgressBar", panel(CYAN, 6, CYAN, 0))
	t.set_font_size("font_size", "Label", 13)
	t.set_color("font_color", "Label", WHITE)
	t.set_color("default_color", "RichTextLabel", WHITE)
	t.set_color("font_color", "RichTextLabel", WHITE)
	t.set_font_size("normal_font_size", "RichTextLabel", 13)
	return t
