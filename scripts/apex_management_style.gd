extends RefCounted
const BG := Color("#111c28")
const PANEL := Color("#07121c")
const BORDER := Color("#7b8794")
const ORANGE := Color("#ff7a00")
const TEXT := Color("#f1f4f7")
const MUTED := Color("#aebdca")
const GREEN := Color("#8cdb34")
static func box(color: Color = PANEL, padding: int = 12) -> StyleBoxFlat:
    var result := StyleBoxFlat.new()
    result.bg_color = color
    result.border_color = BORDER
    result.set_border_width_all(1)
    result.set_corner_radius_all(10)
    result.set_content_margin_all(padding)
    result.shadow_color = Color(0,0,0,0.25)
    result.shadow_size = 4
    return result
static func theme() -> Theme:
    var result := Theme.new()
    result.default_font_size = 17
    result.set_color("font_color", "Label", TEXT)
    result.set_color("default_color", "RichTextLabel", TEXT)
    for type in ["Button", "OptionButton"]:
        result.set_stylebox("normal", type, box(Color("#17232e"), 12))
        var active := box(ORANGE, 12)
        active.border_color = Color("#ffba54")
        result.set_stylebox("pressed", type, active)
        result.set_stylebox("hover", type, box(Color("#3a3026"), 12))
        result.set_stylebox("disabled", type, box(Color("#18212a"), 12))
        var focus := box(Color(0,0,0,0), 0)
        focus.border_color = ORANGE
        focus.set_border_width_all(2)
        result.set_stylebox("focus", type, focus)
        result.set_color("font_color", type, TEXT)
        result.set_color("font_pressed_color", type, Color.WHITE)
        result.set_color("font_disabled_color", type, Color("#71808d"))
        result.set_color("icon_normal_color", type, TEXT)
        result.set_constant("icon_max_width", type, 24)
        result.set_constant("h_separation", type, 14)
    result.set_stylebox("panel", "PanelContainer", box())
    result.set_stylebox("background", "ProgressBar", box(Color("#303c48"),0))
    var fill := box(ORANGE,0)
    fill.set_border_width_all(0)
    result.set_stylebox("fill", "ProgressBar", fill)
    return result
static func label(parent: Node, text: String, font_size: int = 17, color: Color = TEXT) -> Label:
    var node := Label.new()
    node.text = text
    node.add_theme_font_size_override("font_size", font_size)
    node.add_theme_color_override("font_color", color)
    node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(node)
    return node
static func column(parent: Node, gap: int = 8) -> VBoxContainer:
    var node := VBoxContainer.new()
    node.add_theme_constant_override("separation",gap)
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(node)
    return node
static func row(parent: Node, gap: int = 16) -> HBoxContainer:
    var node := HBoxContainer.new()
    node.add_theme_constant_override("separation",gap)
    parent.add_child(node)
    return node
static func card(parent: Node, title: String) -> VBoxContainer:
    var node := PanelContainer.new()
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(node)
    var body := column(node)
    label(body,title,21)
    body.add_child(HSeparator.new())
    return body
static func button(parent: Node, title: String, action: Callable, primary: bool = false) -> Button:
    var node := Button.new()
    node.text = title
    node.custom_minimum_size.y = 46
    node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    node.pressed.connect(action)
    if primary:
        var active := box(ORANGE,12)
        active.border_color = Color("#ffbc62")
        node.add_theme_stylebox_override("normal",active)
    parent.add_child(node)
    return node
static func meter(parent: Node, maximum: float = 100.0) -> ProgressBar:
    var node := ProgressBar.new()
    node.max_value = maximum
    node.show_percentage = false
    node.custom_minimum_size.y = 12
    parent.add_child(node)
    return node
