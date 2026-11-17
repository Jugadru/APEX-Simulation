extends RefCounted
## APEX v0.6.5.0 — Soul Staff 1.0: gestão humana, contratos 0648 preservados.
## Tela nativa escalável; nenhum controle é conectado ao motor de corrida.
const UI = preload("res://scripts/apex_management_style.gd")
const ORANGE := Color("#FF7900")
const WHITE := Color("#F3F5F7")
const MUTED := Color("#B6C0CB")
const BACK := Color("#111c28")
const SURFACE := Color("#07121c")
const GREEN := Color("#8cdb34")
const StaffMarket = preload("res://scripts/core/staff_market_0648.gd")
const SoulStaff = preload("res://scripts/core/staff_soul_0650.gd")

static func _add_meter(host, parent: Control, name: String) -> ProgressBar:
    var line := HBoxContainer.new()
    line.add_theme_constant_override("separation", 8)
    parent.add_child(line)
    var caption: Label = host._label(line, name, 11, MUTED)
    caption.custom_minimum_size.x = 92
    var bar := ProgressBar.new()
    bar.min_value = 0
    bar.max_value = 100
    bar.value = 0
    bar.show_percentage = true
    bar.custom_minimum_size = Vector2(0, 16)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bar.add_theme_font_size_override("font_size", 10)
    line.add_child(bar)
    return bar

static func _build_staff(host) -> void:
    host.staff_root = host._full_cover()
    host.staff_root.theme = UI.theme()
    host.staff_root.name = "SoulStaffScreen"
    var backdrop := ColorRect.new()
    backdrop.color = BACK
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    host.staff_root.add_child(backdrop)
    host.staff_card = host._panel(host.staff_root, SURFACE)
    host.staff_card.add_theme_stylebox_override("panel", UI.box())
    host.staff_card.name = "StaffCard"
    host.staff_card.minimum_size_changed.connect(host._layout_ui, CONNECT_DEFERRED)
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 6)
    host.staff_card.add_child(outer)
    var top := HBoxContainer.new()
    outer.add_child(top)
    var title: Label = host._label(top, "EQUIPE & STAFF  /  GESTÃO HUMANA", 24, ORANGE)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._button(top, "← CENTRAL", host._open_garage, 130)
    host._button(top, "MENU", host._show_menu, 90)
    var note: Label = host._label(outer,
        "Contratos, desenvolvimento humano e cultura da equipe.", 11, MUTED)
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    host.staff_budget_label = host._label(outer, "", 17, WHITE)
    host.staff_payroll_label = host._label(outer, "", 12, MUTED)
    host.staff_culture_summary = host._label(outer, "", 15, GREEN)
    host.staff_culture_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    host.staff_factory_summary = host._label(outer, "", 12, MUTED)
    host.staff_factory_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    host._label(outer, "DECISÕES DO CHEFE DE EQUIPE  /  UMA AÇÃO ANTES DE CADA GP", 12, ORANGE)
    var decisions := HBoxContainer.new()
    decisions.add_theme_constant_override("separation", 7)
    outer.add_child(decisions)
    host.staff_soul_action_buttons.clear()
    for action_id in ["briefing", "recovery", "integration"]:
        var action: Dictionary = SoulStaff.ACTIONS[action_id]
        var caption: String = "%s  •  %s" % [str(action["label"]), SoulStaff.action_cost_label(int(action["cost"]))]
        var button: Button = host._button(decisions, caption, host._staff_soul_action.bind(action_id))
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.clip_text = true
        button.tooltip_text = str(action["reason"])
        host.staff_soul_action_buttons[action_id] = button
    host.staff_action_hint = host._label(outer, "", 11, MUTED)
    host.staff_action_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    host.staff_notice = host._label(outer, "Escolha um profissional ou uma ação de equipe.", 12, WHITE)
    host.staff_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var separator := HSeparator.new()
    outer.add_child(separator)
    var scroller := ScrollContainer.new()
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
    outer.add_child(scroller)
    var list = host._vbox(scroller, 11)
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host.staff_market_buttons.clear()
    host.staff_release_buttons.clear()
    host.staff_roster_labels.clear()
    host.staff_soul_profile_labels.clear()
    host.staff_soul_voice_labels.clear()
    host.staff_soul_meters.clear()
    host.staff_relations_label = host._label(list, "", 12, GREEN)
    host.staff_relations_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    for role in StaffMarket.ROLES:
        var section = host._panel(list, SURFACE)
        section.add_theme_stylebox_override("panel", UI.box())
        var column = host._vbox(section, 5)
        var top_row := HBoxContainer.new()
        column.add_child(top_row)
        var heading: Label = host._label(top_row, str(role).to_upper(), 17, ORANGE)
        heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var dismiss: Button = host._button(top_row, "RESCINDIR (2 salários)", host._release_staff_candidate.bind(role), 210)
        host.staff_release_buttons[role] = dismiss
        var holder: Label = host._label(column, "", 13, WHITE)
        holder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        host.staff_roster_labels[role] = holder
        var traits: Label = host._label(column, "", 12, GREEN)
        traits.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        host.staff_soul_profile_labels[role] = traits
        var voice: Label = host._label(column, "", 12, MUTED)
        voice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        host.staff_soul_voice_labels[role] = voice
        var meter_group: VBoxContainer = host._vbox(column, 2)
        host.staff_soul_meters[role] = {
            "group":meter_group,
            "morale":_add_meter(host, meter_group, "MORAL"),
            "energy":_add_meter(host, meter_group, "ENERGIA"),
            "trust":_add_meter(host, meter_group, "CONFIANÇA")
        }
        for candidate in StaffMarket.MARKET.get(role, []):
            var entry: Dictionary = candidate
            var action_button: Button = host._button(column, "", host._hire_staff_candidate.bind(role, str(entry["id"])))
            action_button.clip_text = true
            host.staff_market_buttons[str(entry["id"])] = action_button
    host.staff_history_label = host._label(list, "", 11, MUTED)
    host.staff_history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    host.staff_root.hide()

static func _refresh_staff(host) -> void:
    var state: Dictionary = host.garage.get_team(host.selected_team)
    var roster: Dictionary = state["staff_roster"]
    host.staff_budget_label.text = "%s  |  CAIXA R$ %.2f mi" % [host.selected_team.to_upper(), float(state["budget"])/1000000.0]
    host.staff_payroll_label.text = "FOLHA ESTIMADA: %s/GP de campeonato  •  Contratos em vigor: %d/4" % [
        StaffMarket.money(host.garage.staff_payroll_total(host.selected_team)), roster.size()]
    var culture: Dictionary = host.garage.staff_soul_summary(host.selected_team)
    host.staff_culture_summary.text = (
        "SOUL STAFF  /  MORAL %d%%  ·  ENERGIA %d%%  ·  CONFIANÇA %d%%  ·  COESÃO %s" % [
            int(culture["morale"]), int(culture["energy"]), int(culture["trust"]),
            "%d%%" % int(culture["cohesion"]) if int(culture["relations"]) > 0 else "N/D"]
        if int(culture["count"]) > 0 else "SOUL STAFF  /  Sem profissionais contratados — indicadores indisponíveis")
    var levels: Dictionary = state.get("levels", {})
    var proj: Dictionary = state.get("development_project", {})
    var project_name: String = str(proj.get("part", "")) if not proj.is_empty() else "nenhum projeto ativo"
    host.staff_factory_summary.text = "OFICINA VIVA (painel informativo)  •  Motor N%d  /  Asa N%d  /  Chassi N%d  •  P&D: %s" % [
        int(levels.get("Motor", 0)), int(levels.get("Asa", 0)), int(levels.get("Chassi", 0)), project_name]
    var serial: int = 0
    var next_round: int = 0
    var rounds: int = 0
    if host.championship_mode and host.championship.has_season() and not host.championship.is_complete():
        serial = int(host.championship.state.get("serial", 0))
        next_round = int(host.championship.state.get("round_index", 0)) + 1
        rounds = (host.championship.state.get("calendar", []) as Array).size()
    for action_id in host.staff_soul_action_buttons:
        var button: Button = host.staff_soul_action_buttons[action_id]
        var disabled_reason: String = SoulStaff.action_allowed(state, action_id, serial, next_round, rounds)
        button.disabled = not disabled_reason.is_empty()
        button.tooltip_text = disabled_reason if not disabled_reason.is_empty() else str(SoulStaff.ACTIONS[action_id]["reason"])
    if serial > 0:
        var status: String = SoulStaff.action_allowed(state, "briefing", serial, next_round, rounds)
        host.staff_action_hint.text = "GP %d/%d: %s" % [next_round, rounds,
            status if not status.is_empty() else "1 ação disponível; custo abatido imediatamente do caixa virtual."]
    else:
        host.staff_action_hint.text = "Ações de gestão exigem uma temporada ativa. No GP avulso, perfis e relações permanecem consultivos."
    var relationships: Array[String] = host.garage.staff_soul_relations(host.selected_team)
    host.staff_relations_label.text = "RELAÇÕES ENTRE DEPARTAMENTOS\n" + (
        "\n".join(relationships) if not relationships.is_empty() else "Contrate pelo menos dois titulares para gerar relações de equipe.")
    var history: Array = state.get("staff_log", [])
    var recent := PackedStringArray()
    for i in range(maxi(0, history.size()-4), history.size()):
        recent.append(str(history[i]))
    host.staff_history_label.text = "MOVIMENTAÇÕES RECENTES: " + (" • ".join(recent) if not recent.is_empty() else "Nenhuma ainda.")
    for role in StaffMarket.ROLES:
        var position: Dictionary = roster.get(role, {})
        var label: Label = host.staff_roster_labels[role]
        var release: Button = host.staff_release_buttons[role]
        var traits_label: Label = host.staff_soul_profile_labels[role]
        var voice_label: Label = host.staff_soul_voice_labels[role]
        var meters: Dictionary = host.staff_soul_meters[role]
        if position.is_empty():
            label.text = "VAGA  /  sem titular. Formação técnica anterior é preservada."
            traits_label.text = "Personalidade e relacionamento disponíveis após contratação."
            voice_label.text = ""
            meters["group"].hide()
            release.disabled = true
        else:
            label.text = "TITULAR  %s  |  Habilidade %d/100 • N%d  |  salário %s/GP  |  %d GP(s) restantes  |  %s" % [
                str(position.get("name", "")), int(position.get("skill", 0)),
                StaffMarket.level(int(position.get("skill", 0))), StaffMarket.money(int(position.get("salary", 0))),
                int(position.get("remaining_gps", 0)), str(position.get("specialty", ""))]
            traits_label.text = "PERSONALIDADE  %s   •   ESTILO  %s   •   Perfil %s" % [
                str(position.get("personality", "Profissional")), str(position.get("style", "Equilibrado")),
                str(position.get("trait", "equilibrado"))]
            voice_label.text = "PALAVRA DO STAFF: “%s”" % SoulStaff.staff_voice(position, int(culture["cohesion"]) if int(culture["relations"]) > 0 else 50)
            meters["group"].show()
            for key in ["morale", "energy", "trust"]:
                (meters[key] as ProgressBar).value = float(position.get(key, 0))
            release.disabled = int(state["budget"]) < int(position.get("salary", 0)) * 2
        for candidate in StaffMarket.MARKET.get(role, []):
            var entry: Dictionary = candidate
            var button: Button = host.staff_market_buttons[str(entry["id"])]
            var soul: Dictionary = SoulStaff.profile(entry)
            button.text = "CONTRATAR   %s  |  Hab. %d  |  %s / %s  |  bônus %s  |  %s/GP" % [
                str(entry["name"]), int(entry["skill"]), str(soul["personality"]), str(soul["style"]),
                StaffMarket.money(int(entry["signing"])), StaffMarket.money(int(entry["salary"]))]
            button.disabled = not position.is_empty() or int(state["budget"]) < int(entry["signing"])
