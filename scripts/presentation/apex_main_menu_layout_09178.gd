extends RefCounted
## Main-menu presentation only. All routes remain owned by FrontDoor.
const MenuTheme = preload("res://scripts/apex_hud_theme.gd")
const BG := Color("#101216")
const PANEL := Color("#1b1e24")
const EDGE := Color("#343943")
const ORANGE := Color("#ff8126")
const WHITE := Color("#f2f3f5")
const MUTED := Color("#adb4bf")

static func column(parent: Node, spacing: int = 10) -> VBoxContainer:
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", spacing)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(box)
    return box

static func panel(parent: Node, padding: int = 18, accent: bool = false) -> VBoxContainer:
    var frame := PanelContainer.new()
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    frame.add_theme_stylebox_override("panel", MenuTheme.panel(PANEL, 6, ORANGE if accent else EDGE, padding))
    parent.add_child(frame)
    return column(frame)

static func primary(button: Button) -> void:
    button.add_theme_stylebox_override("normal", MenuTheme.panel(ORANGE, 4, ORANGE, 10))
    button.add_theme_stylebox_override("hover", MenuTheme.panel(Color("#ffa15a"), 4, ORANGE, 10))
    button.add_theme_stylebox_override("pressed", MenuTheme.panel(Color("#db6722"), 4, ORANGE, 10))
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        button.add_theme_color_override(state, BG)

static func build(menu) -> void:
    var bg := ColorRect.new()
    bg.color = BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu.add_child(bg)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["left", "right", "top", "bottom"]:
        margin.add_theme_constant_override("margin_" + side, 40)
    menu.add_child(margin)
    menu.home_scroll = ScrollContainer.new()
    menu.home_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    margin.add_child(menu.home_scroll)
    var content := column(menu.home_scroll, 24)
    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 18)
    content.add_child(header)
    var brand := menu.label(header, "APEX", 64, ORANGE) as Label
    brand.autowrap_mode = TextServer.AUTOWRAP_OFF
    var identity := column(header, 0)
    menu.label(identity, "MOTORSPORT MANAGER", 25, WHITE)
    menu.label(identity, "CENTRAL DE COMANDO  /  SIMULAÇÃO DE GESTÃO", 15, MUTED)
    var era := column(header, 2)
    era.size_flags_horizontal = Control.SIZE_SHRINK_END
    var year := menu.label(era, "TEMPORADA 2012", 20, WHITE) as Label
    year.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    year.autowrap_mode = TextServer.AUTOWRAP_OFF
    var stats := menu.label(era, "%d EQUIPES  /  %d CIRCUITOS" % [menu.host.teams.size(), menu.host.season_tracks.size()], 15, MUTED) as Label
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    stats.autowrap_mode = TextServer.AUTOWRAP_OFF
    var stripe := ColorRect.new()
    stripe.color = ORANGE
    stripe.custom_minimum_size.y = 4
    stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_child(stripe)
    menu.landing = column(content, 20)
    var intro := column(menu.landing, 4)
    menu.label(intro, "SEU TIME. SUAS DECISÕES. SUA HISTÓRIA.", 36, WHITE)
    menu.label(intro, "Da fábrica ao pit wall: comande a equipe, prepare o carro e defina a estratégia.", 18, MUTED)
    menu.body = BoxContainer.new()
    menu.body.add_theme_constant_override("separation", 20)
    menu.landing.add_child(menu.body)
    var session := panel(menu.body, 24, true)
    (session.get_parent() as Control).size_flags_stretch_ratio = 1.0
    menu.label(session, "01  /  SUA SESSÃO", 15, ORANGE)
    menu.session_title = menu.label(session, "TEMPORADA 2012", 34, WHITE)
    menu.session_info = menu.label(session, "", 19, MUTED)
    menu.session_info.custom_minimum_size.y = 70
    menu.continue_button = menu.button(session, "CONTINUAR TEMPORADA", menu.continue_season)
    primary(menu.continue_button)
    session.add_child(HSeparator.new())
    menu.label(session, "GP ATUAL", 15, ORANGE)
    menu.race_info = menu.label(session, "", 18, MUTED)
    menu.race_info.custom_minimum_size.y = 55
    menu.resume_race_button = menu.button(session, "VOLTAR À CORRIDA", menu.resume_race)
    var modes := column(menu.body, 12)
    modes.size_flags_stretch_ratio = 1.8
    menu.label(modes, "02  /  MODOS DE JOGO", 15, ORANGE)
    menu.mode_grid = GridContainer.new()
    menu.mode_grid.columns = 2
    menu.mode_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    menu.mode_grid.add_theme_constant_override("h_separation", 16)
    menu.mode_grid.add_theme_constant_override("v_separation", 16)
    modes.add_child(menu.mode_grid)
    menu.mode_card("01", "STANDARD", "DISPONÍVEL", "Assuma o comando da equipe e dispute o campeonato de 2012.", "PREPARAR TEMPORADA", menu.open_standard)
    menu.mode_card("02", "SANDBOX", "DISPONÍVEL", "Configure um GP avulso: equipe, circuito, clima e semente.", "CONFIGURAR GP", menu.open_sandbox)
    menu.mode_card("03", "CENÁRIOS", "TREINOS DISPONÍVEIS", "Experimente condições predefinidas em três circuitos.", "ESCOLHER CENÁRIO", menu.show_scenarios)
    menu.mode_card("04", "SIMULATION", "MODO PROPRIETÁRIO PLANEJADO", "Conheça a proposta de proprietário e experimente um GP delegado ao staff.", "VER MODO", menu.show_simulation)
    var operations := panel(menu.landing, 18)
    menu.label(operations, "03  /  GESTÃO DA EQUIPE", 15, ORANGE)
    menu.operations_row = BoxContainer.new()
    menu.operations_row.add_theme_constant_override("separation", 12)
    operations.add_child(menu.operations_row)
    menu.button(menu.operations_row, "CENTRAL / P&D", menu.host._open_garage)
    menu.button(menu.operations_row, "EQUIPE / SOUL STAFF", menu.host._open_staff)
    menu.detail = column(content, 16)
    var back := menu.button(menu.detail, "VOLTAR AO MENU", menu.show_home) as Button
    back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    var info := panel(menu.detail, 22)
    menu.detail_title = menu.label(info, "", 28, WHITE)
    menu.detail_text = menu.label(info, "", 17, MUTED)
    menu.detail_actions = column(info, 12)
    var build_title: String = str(ProjectSettings.get_setting("application/config/name", "APEX Motorsport Manager"))
    menu.label(content, "%s  /  CORE 2  /  GODOT 4.7.2" % build_title.get_slice(" — ", 0).to_upper(), 14, MUTED)
