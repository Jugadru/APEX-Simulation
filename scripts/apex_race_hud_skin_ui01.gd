extends RefCounted
## APEX Manager HUD: original presentation inspired by management race broadcasts.
## The geometry, event bindings and RaceEngine stay in apex_race_hud_0622.gd.

const BASE := Color("#191A23")
const SURFACE := Color(0.105, 0.110, 0.150, 0.92)
const SURFACE_SOLID := Color("#23242F")
const SURFACE_ALT := Color("#30313F")
const HEADER := Color("#ECEDEB")
const HEADER_INK := Color("#222430")
const ORANGE := Color("#FF8A21")
const ORANGE_LITE := Color("#FFB066")
const WHITE := Color("#F3F5F6")
const MUTED := Color("#B7C3CC")
const BORDER := Color("#646573")
const BORDER_SOFT := Color("#454652")
const WARNING := Color("#F2BE49")
const TYRE_GREEN := Color("#8cdb34")

static func panel(bg: Color = SURFACE, radius: int = 7, edge: Color = BORDER_SOFT, pad: int = 8, accent_left: bool = false) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = edge
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(clampi(radius, 0, 3))
    sb.set_content_margin_all(pad)
    if accent_left:
        # Only the left rail is orange; avoid a distracting full orange outline.
        sb.set_border_width_all(0)
        sb.border_width_left = 3
        sb.border_color = ORANGE
    return sb

static func button_style(state: String = "normal") -> StyleBoxFlat:
    match state:
        "hover":
            return panel(Color("#454654"), 2, WHITE, 6)
        "pressed", "selected":
            return panel(Color("#555665"), 2, ORANGE, 6)
        "disabled":
            return panel(Color("#20212B"), 2, BORDER_SOFT, 6)
        "rank":
            return panel(Color.TRANSPARENT, 0, Color.TRANSPARENT, 2)
        "rank_hover":
            return panel(Color("#3C3D4C"), 0, BORDER_SOFT, 2)
        "rank_selected":
            return panel(Color("#4A4B5C"), 0, Color("#A0A1AA"), 2)
    return panel(SURFACE_ALT, 2, BORDER_SOFT, 6)

static func build() -> Theme:
    var t := Theme.new()
    for control_type in ["Button", "OptionButton"]:
        for state in ["normal", "hover", "pressed", "disabled"]:
            t.set_stylebox(state, control_type, button_style(state))
        t.set_stylebox("focus", control_type, panel(Color.TRANSPARENT, 5, ORANGE, 0))
        t.set_color("font_color", control_type, WHITE)
        t.set_color("font_hover_color", control_type, WHITE)
        t.set_color("font_pressed_color", control_type, WHITE)
        t.set_color("font_focus_color", control_type, WHITE)
        t.set_color("font_disabled_color", control_type, MUTED.darkened(0.35))
        t.set_font_size("font_size", control_type, 12)
    for control_type in ["LineEdit", "SpinBox"]:
        t.set_stylebox("normal", control_type, panel(SURFACE_ALT, 5, BORDER_SOFT, 6))
        t.set_stylebox("focus", control_type, panel(SURFACE_ALT, 5, ORANGE, 6))
        t.set_stylebox("read_only", control_type, panel(BASE, 5, BORDER_SOFT, 6))
        t.set_color("font_color", control_type, WHITE)
        t.set_font_size("font_size", control_type, 12)
    t.set_stylebox("panel", "PanelContainer", panel())
    t.set_stylebox("background", "ProgressBar", panel(Color("#2F3944"), 3, Color("#2F3944"), 0))
    t.set_stylebox("fill", "ProgressBar", panel(TYRE_GREEN, 3, TYRE_GREEN, 0))
    t.set_color("font_color", "Label", WHITE)
    t.set_color("default_color", "RichTextLabel", WHITE)
    t.set_color("font_color", "RichTextLabel", WHITE)
    t.set_font_size("font_size", "Label", 12)
    t.set_font_size("normal_font_size", "RichTextLabel", 12)
    t.set_stylebox("panel", "TabContainer", panel(BASE, 7, BORDER_SOFT, 6))
    t.set_stylebox("tab_selected", "TabBar", panel(Color("#ac4d00"), 5, ORANGE, 5))
    t.set_stylebox("tab_unselected", "TabBar", panel(SURFACE_ALT, 5, BORDER_SOFT, 5))
    t.set_stylebox("tab_hovered", "TabBar", panel(Color("#293340"), 5, BORDER, 5))
    t.set_color("font_selected_color", "TabBar", WHITE)
    t.set_color("font_unselected_color", "TabBar", MUTED)
    t.set_font_size("font_size", "TabBar", 12)
    return t
