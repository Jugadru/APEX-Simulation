extends Control
## Functional management UI based on reference image 04.
## Shared management shell. Data originates in Garage/Championship.
const UI = preload("res://scripts/apex_management_style.gd")
const Soul = preload("res://scripts/core/staff_soul_0650.gd")
const Market = preload("res://scripts/core/staff_market_0648.gd")
var host
var nav_buttons: Dictionary = {}
var pages: Dictionary = {}
var tabs: Dictionary = {}
var research_tabs: Dictionary = {}
var page_title: Label
var page_subtitle: Label
var team_title: Label
var round_label: Label
var project_title: Label
var project_progress: ProgressBar
var project_progress_text: Label
var project_count: Label
var team_summary: Label
var budget_paid: Label
var budget_balance: Label
var area_labels: Dictionary = {}
var area_bars: Dictionary = {}
var history_text: RichTextLabel
var calendar_text: RichTextLabel
var finance_text: RichTextLabel
var driver_text: RichTextLabel
var team_text: RichTextLabel
var reports_text: RichTextLabel
var workshop
var dashboards
var current_page := "research"
var current_tab := "active"

func setup(scene_host) -> void:
    host = scene_host
    name = "ManagementHub"
    theme = UI.theme()
    host.garage_root.add_child(self)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var background := ColorRect.new()
    background.color = UI.BG
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    var frame := VBoxContainer.new()
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame.add_theme_constant_override("separation",0)
    add_child(frame)
    _header(frame)
    var body := UI.row(frame,0)
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _sidebar(body)
    var padding := MarginContainer.new()
    padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for side in ["left","right","top","bottom"]:
        padding.add_theme_constant_override("margin_"+side,14)
    body.add_child(padding)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    padding.add_child(scroll)
    var content := UI.column(scroll,14)
    page_title = UI.label(content,"P&D — Pesquisa e Desenvolvimento",32)
    page_subtitle = UI.label(content,"Desenvolva seu carro e prepare a equipe para a próxima etapa.",18,UI.MUTED)
    _research(content)
    _other_pages(content)
    pages["factory"] = UI.column(content, 12)
    workshop = preload("res://scripts/apex_workshop_0656.gd").new()
    workshop.setup(pages["factory"], self)
    dashboards = preload("res://scripts/apex_management_dashboards.gd").new()
    dashboards.setup(self)
    host.garage_notes = UI.label(content,"Selecione uma área para acompanhar o desenvolvimento.",15,UI.ORANGE)
    show_page("research")

func _header(parent: Node) -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", UI.box(Color("#050d14"),14))
    parent.add_child(panel)
    var bar := UI.row(panel,24)
    var brand := UI.column(bar,0)
    brand.custom_minimum_size.x = 208
    UI.label(brand,"APEX",32,UI.ORANGE)
    UI.label(brand,"MOTORSPORT MANAGER",11,UI.MUTED)
    team_title = UI.label(bar,"",26)
    team_title.size_flags_stretch_ratio = 1.4
    var season := UI.column(bar,2)
    UI.label(season,"TEMPORADA",13,UI.ORANGE)
    UI.label(season,"2012",24)
    var round_column := UI.column(bar,2)
    UI.label(round_column,"CAMPEONATO",13,UI.ORANGE)
    round_label = UI.label(round_column,"GP avulso",21)
    var budget := UI.column(bar,2)
    UI.label(budget,"SALDO DA EQUIPE",13,UI.ORANGE)
    host.money_label = UI.label(budget,"",22)
    host.money_label.custom_minimum_size.x = 220

func _sidebar(parent: Node) -> void:
    var panel := PanelContainer.new()
    panel.custom_minimum_size.x = 230
    panel.add_theme_stylebox_override("panel",UI.box(Color("#07121b"),10))
    parent.add_child(panel)
    var column := UI.column(panel,8)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    var links := UI.column(scroll,8)
    for entry in [["career","Carreira","home"],["calendar","Calendário","calendar"],["team","Equipe e Staff","team"],["drivers","Pilotos","team"],["research","P&D","research"],["factory","Living Factory","research"],["performance","Desempenho","research"],["finance","Finanças","report"],["contracts","Contratos","report"],["reports","Relatórios","report"],["settings","Configurações","settings"]]:
        var key: String = entry[0]
        var item := UI.button(links,entry[1],show_page.bind(key))
        item.alignment = HORIZONTAL_ALIGNMENT_LEFT
        item.custom_minimum_size.y = 56
        item.icon = load("res://assets/ui_icons/"+str(entry[2])+".svg")
        item.expand_icon = true
        item.toggle_mode = true
        nav_buttons[key] = item
    var back := UI.button(column,"Menu principal",host._show_menu)
    back.icon = preload("res://assets/ui_icons/back.svg")
    UI.label(column,"GESTÃO • ESTRATÉGIA\nPERFORMANCE",12,UI.ORANGE)

func _research(parent: Node) -> void:
    var section := UI.column(parent,14)
    pages["research"] = section
    var bar := UI.row(section,4)
    for entry in [["active","Projetos ativos"],["research","Pesquisa"],["development","Desenvolvimento"],["history","Histórico"],["training","Equipe de boxes"]]:
        var key: String = entry[0]
        var item := UI.button(bar,entry[1],show_research_tab.bind(key))
        item.toggle_mode = true
        tabs[key] = item
    var active := UI.column(section,14)
    research_tabs["active"] = active
    var columns := UI.row(active)
    var left := UI.column(columns)
    left.size_flags_stretch_ratio = 1.65
    var project := UI.card(left,"Projetos ativos")
    project_count = UI.label(project,"",14,UI.ORANGE)
    project_title = UI.label(project,"Nenhum projeto em andamento",28)
    host.garage_project_status = UI.label(project,"",17,UI.MUTED)
    project_progress = UI.meter(project)
    project_progress_text = UI.label(project,"",14,UI.GREEN)
    UI.button(project,"GERENCIAR PROJETOS",show_research_tab.bind("research"),true)
    host.garage_cancel_project = UI.button(project,"Cancelar projeto • reembolso de 75%",host._cancel_garage_research)
    var right := UI.column(columns)
    var areas := UI.card(right,"Áreas de desenvolvimento")
    for part in ["Asa","Motor","Chassi"]:
        area_labels[part] = UI.label(areas,part,17)
        area_bars[part] = UI.meter(areas,3)
    var people := UI.card(right,"Equipe de P&D")
    team_summary = UI.label(people,"",16,UI.MUTED)
    UI.button(people,"Gerenciar profissionais",host._open_staff)
    var investment := UI.card(active,"Investimento em P&D")
    var figures := UI.row(investment)
    var available := UI.column(figures)
    UI.label(available,"Saldo disponível",14,UI.MUTED)
    budget_balance = UI.label(available,"",27,UI.GREEN)
    var paid := UI.column(figures)
    UI.label(paid,"Investimento no projeto ativo • já pago",14,UI.MUTED)
    budget_paid = UI.label(paid,"",27)
    UI.button(figures,"Pesquisar melhorias",show_research_tab.bind("research"),true)
    var research := UI.column(section)
    research_tabs["research"] = research
    var options := UI.card(research,"Pesquisa / próximo nível")
    UI.label(options,"Um projeto por vez • entrega após duas etapas • 15% de desconto sobre a compra imediata. O chefe de aerodinâmica pode reduzir o custo da asa.",17,UI.MUTED)
    for part in ["Motor","Asa","Chassi"]:
        host.garage_project_buttons[part] = UI.button(options,"",host._start_garage_research.bind(part))
    UI.label(options,"P&D exige campeonato ativo e pelo menos duas etapas restantes. Para iniciar ou retomar a temporada, acesse Carreira.",16,UI.ORANGE)
    var development := UI.column(section)
    research_tabs["development"] = development
    var parts := UI.card(development,"Peças do carro / compra imediata")
    for part in ["Motor","Asa","Chassi"]:
        host.upgrade_buttons[part] = UI.button(parts,"",host._buy_part.bind(part))
    host.garage_development_summary = UI.label(parts,"",16,UI.MUTED)
    var history := UI.column(section)
    research_tabs["history"] = history
    history_text = report_box(history,"Histórico de desenvolvimento")
    var rivals := UI.card(history,"Desenvolvimento das rivais")
    host.garage_rivals_summary = UI.label(rivals,"",16,UI.MUTED)
    var training := UI.column(section)
    research_tabs["training"] = training
    var crew := UI.card(training,"Treinamento da equipe de boxes")
    for part in ["Agilidade","Precisão","Coordenação"]:
        host.crew_buttons[part] = UI.button(crew,"",host._buy_crew.bind(part))
    host.crew_summary = UI.label(crew,"",16,UI.MUTED)
    var staff := UI.card(training,"Formação técnica")
    for role in ["Estrategista","Engenheiro"]:
        host.staff_buttons[role] = UI.button(staff,"",host._hire_staff.bind(role))
    host.staff_summary = UI.label(staff,"",16,UI.MUTED)
    # Compatibility label populated by the existing Garage presenter.
    host.garage_title = Label.new()
    host.garage_title.hide()
    add_child(host.garage_title)

func report_box(parent: Node, title: String) -> RichTextLabel:
    var card := UI.card(parent,title)
    var report := RichTextLabel.new()
    report.fit_content = true
    report.scroll_active = false
    report.custom_minimum_size.y = 150
    report.add_theme_font_size_override("normal_font_size",18)
    card.add_child(report)
    return report

func _other_pages(parent: Node) -> void:
    for key in ["career","calendar","team","drivers","performance","finance","contracts","reports","settings"]:
        pages[key] = UI.column(parent,16)
    UI.label(pages["career"],"Prepare a temporada, escolha sua equipe e acompanhe o campeonato salvo.",20,UI.MUTED)
    UI.button(pages["career"],"PREPARAR TEMPORADA / GP",open_configuration,true)
    UI.button(pages["career"],"Classificação e resultados",host._show_championship_table)
    calendar_text = report_box(pages["calendar"],"Calendário 2012")
    UI.button(pages["calendar"],"Preparar próxima corrida",open_configuration,true)
    UI.button(pages["calendar"],"Calendário de gestão: avançar 8 horas de oficina",func():
        workshop.act("advance", {"hours":8}))
    UI.button(pages["calendar"],"Abrir oficina e consultar prazo / serviços",func(): show_page("factory"))
    team_text = report_box(pages["team"],"Profissionais contratados")
    UI.button(pages["team"],"MERCADO / GESTÃO HUMANA",host._open_staff,true)
    driver_text = report_box(pages["drivers"],"Pilotos da equipe")
    UI.label(pages["drivers"],"Os pilotos pertencem ao elenco da temporada 2012. Mercado e renovação de pilotos ainda não fazem parte desta versão.",17,UI.MUTED)
    UI.label(pages["performance"],"Consulte o ganho das peças instaladas e compare o desenvolvimento das equipes.",20)
    UI.button(pages["performance"],"Desempenho das peças",show_development,true)
    UI.button(pages["performance"],"Resultados do campeonato",host._show_championship_table)
    finance_text = report_box(pages["finance"],"Orçamento e compromissos")
    UI.label(pages["finance"],"O projeto usa um caixa compartilhado da equipe em R$. Não existe uma verba separada de P&D. O investimento ativo já foi descontado do saldo.",17,UI.MUTED)
    UI.label(pages["contracts"],"Contrate ou rescinda titulares dos quatro departamentos, consulte salários e duração em GPs.",20)
    UI.button(pages["contracts"],"ABRIR CONTRATOS DE STAFF",host._open_staff,true)
    reports_text = report_box(pages["reports"],"Histórico da equipe")
    UI.button(pages["reports"],"Relatório do campeonato",host._show_championship_table)
    UI.label(pages["settings"],"Interface de corrida",25)
    for mode in [["Automática",0],["Completa",1],["Compacta",2],["Cinema",3]]:
        UI.button(pages["settings"],mode[0],host._change_hud_layout.bind(mode[1]))
    UI.label(pages["settings"],"A seleção é salva nas preferências existentes da HUD e será aplicada na corrida.",17,UI.MUTED)

func show_development() -> void:
    show_page("research")
    UI.button(pages["settings"],"Performance Profiler 1.0 (F8)",host._open_performance_profiler)
    show_research_tab("development")

func open_configuration() -> void:
    host._show_menu()
    host.menu_root.get_node("FrontDoor").open_standard()

func show_page(key: String) -> void:
    if not pages.has(key): return
    current_page = key
    if host.garage_notes != null:
        host.garage_notes.visible = key == "research"
    for id in pages:
        pages[id].visible = id == key
    for id in nav_buttons:
        nav_buttons[id].set_pressed_no_signal(id == key)
    var titles := {"factory":"Living Factory — Oficina","research":"P&D — Pesquisa e Desenvolvimento", "career":"Carreira — Central da equipe", "calendar":"Calendário da Temporada", "team":"Equipe & Staff", "drivers":"Pilotos da equipe", "performance":"Desempenho do carro", "finance":"Finanças — Orçamento da equipe", "contracts":"Contratos e profissionais", "reports":"Relatórios da equipe", "settings":"Configurações da HUD"}
    page_title.text = titles[key]
    page_subtitle.text = "Desenvolva seu carro e prepare a equipe para a próxima etapa." if key == "research" else "Acompanhe sua equipe e prepare as próximas decisões."
    show_research_tab(current_tab)
    if host.garage != null: refresh()

func show_research_tab(key: String) -> void:
    if not research_tabs.has(key): return
    current_tab = key
    for id in research_tabs:
        research_tabs[id].visible = id == key
        tabs[id].set_pressed_no_signal(id == key)

func refresh() -> void:
    var state: Dictionary = host.garage.get_team(host.selected_team)
    team_title.text = host.selected_team
    host.money_label.text = money(int(state["budget"]))
    var active_season: bool = host.championship.has_season()
    var round_index: int = int(host.championship.state.get("round_index",0)) if active_season else 0
    var calendar: Array = host.championship.state.get("calendar",[]) if active_season else host.season_tracks
    round_label.text = "Etapa %d / %d" % [mini(round_index+1,calendar.size()),calendar.size()] if host.championship_mode else "GP avulso"
    if active_season and host.championship.is_complete() and host.championship_mode:
        round_label.text = "Concluído • %d GPs" % calendar.size()
    var project: Dictionary = state.get("development_project",{})
    project_count.text = "%d / 1 PROJETO EM ANDAMENTO" % (0 if project.is_empty() else 1)
    project_title.text = "Nenhum projeto em andamento" if project.is_empty() else str(project["part"]) + " / próximo nível"
    var elapsed: int = maxi(0,round_index-int(project.get("started_round",round_index)))
    var duration: int = maxi(1,int(project.get("ready_round",round_index+2))-int(project.get("started_round",round_index)))
    project_progress.value = clampf(float(elapsed)/duration*100.0,0,100) if not project.is_empty() else 0
    project_progress_text.text = "%d de %d etapas concluídas • %.0f%%" % [mini(elapsed,duration),duration,project_progress.value] if not project.is_empty() else "Escolha Motor, Asa ou Chassi na aba Pesquisa."
    for part in area_bars:
        var level: int = int(state["levels"].get(part,0))
        area_bars[part].value = level
        area_labels[part].text = "%s  •  nível %d / 3" % [part,level]
    var summary: Dictionary = Soul.summary(state)
    var aero: Dictionary = state["staff_roster"].get("Chefe de Aerodinâmica",{})
    team_summary.text = "%s • %d / 4 titulares\nMoral %d / 100 • Energia %d / 100\nCoesão %d / 100" % [str(aero.get("name","Chefe de aerodinâmica não contratado")),int(summary["count"]),int(summary["morale"]),int(summary["energy"]),int(summary["cohesion"])]
    budget_balance.text = money(int(state["budget"]))
    budget_paid.text = money(int(project.get("cost",0)))
    var histories: Array[String] = []
    for entry in state.get("development_history",[]):
        histories.append("%s • %s%s" % [entry.get("part",""),entry.get("status","")," • etapa %d" % int(entry["round"]) if entry.has("round") else " • reembolso " + money(int(entry.get("refund",0)))])
    history_text.text = "\n\n".join(histories) if not histories.is_empty() else "Nenhum projeto entregue ou cancelado nesta equipe."
    var lines: Array[String] = []
    for index in range(calendar.size()):
        var track: Dictionary = calendar[index]
        lines.append("%02d   %s — %s%s" % [index+1,track.get("country",""),track.get("name",""),"   / CONCLUÍDO" if active_season and index < round_index else ""])
    calendar_text.text = "\n".join(lines)
    lines.clear()
    for role in Market.ROLES:
        var person: Dictionary = state["staff_roster"].get(role,{})
        lines.append(role+"\n"+("Sem titular contratado" if person.is_empty() else "%s • habilidade %d • %d GPs restantes\nSalário: %s / GP" % [person.get("name",""),int(person.get("skill",0)),int(person.get("remaining_gps",0)),money(int(person.get("salary",0)))]))
    team_text.text = "\n\n".join(lines)
    lines.clear()
    for team in host.teams:
        if str(team["name"]) != host.selected_team: continue
        for driver in team["drivers"]:
            lines.append("%s\nHabilidade na simulação: %d / 100" % [driver["name"],int(driver.get("skill",0))])
    driver_text.text = "\n\n".join(lines)
    finance_text.text = "SALDO DISPONÍVEL\n%s\n\nINVESTIMENTO ATIVO (JÁ PAGO)\n%s\n\nFOLHA POR GP\n%s\n\nREEMBOLSO EM CASO DE CANCELAMENTO\n%s" % [money(int(state["budget"])),money(int(project.get("cost",0))),money(host.garage.staff_payroll_total(host.selected_team)),money(int(round(float(project.get("cost",0))*0.75)))]
    dashboards.refresh(state)
    if current_page == "factory": workshop.refresh()
    var logs: Array = state.get("staff_log",[])
    reports_text.text = "\n\n".join(logs) if not logs.is_empty() else "Nenhum registro de staff nesta equipe. Contratações, ações e folhas aparecerão aqui."

static func money(value: int) -> String:
    return "R$ %.2f mi" % (float(value)/1000000.0)
