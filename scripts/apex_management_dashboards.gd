extends RefCounted
## Cards share one visual language and read only the existing simulation state.
const UI = preload("res://scripts/apex_management_style.gd")
const Soul = preload("res://scripts/core/staff_soul_0650.gd")
const Market = preload("res://scripts/core/staff_market_0648.gd")
var hub
var host
var roster_cards: Dictionary = {}
var driver_cards: Array = []
var figures: Dictionary = {}
var culture: Dictionary = {}
var performance: Dictionary = {}
var career: Label
var calendar_grid: GridContainer
var contracts: Label

func metric(parent: Node, title: String, large := false) -> Label:
    var card := UI.card(parent,title)
    return UI.label(card,"—",30 if large else 20,UI.GREEN)

func clear_page(key: String) -> void:
    for child in hub.pages[key].get_children(): child.hide()

func setup(shell) -> void:
    hub = shell
    host = hub.host
    for key in ["team","drivers","finance","career","calendar","performance","contracts"]:
        clear_page(key)
    var page: Node = hub.pages["team"]
    var tabs := UI.row(page,6)
    UI.button(tabs,"Visão da equipe",hub.show_page.bind("team"),true)
    UI.button(tabs,"Staff e recrutamento",host._open_staff)
    UI.button(tabs,"Contratos",hub.show_page.bind("contracts"))
    var split := UI.row(page)
    var grid := GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.size_flags_stretch_ratio = 1.8
    grid.add_theme_constant_override("h_separation",14)
    grid.add_theme_constant_override("v_separation",14)
    split.add_child(grid)
    for role in Market.ROLES:
        var card := UI.card(grid,role)
        var name_label := UI.label(card,"",24)
        var skill := UI.meter(card)
        var details := UI.label(card,"",16,UI.MUTED)
        roster_cards[role] = {"name":name_label,"skill":skill,"details":details}
    var side := UI.column(split)
    var team_culture := UI.card(side,"Moral e cultura")
    for key in ["morale","energy","cohesion"]:
        culture[key] = {"label":UI.label(team_culture,"",18),"bar":UI.meter(team_culture)}
    UI.label(side,"As decisões de gestão influenciam a moral, a energia e as relações entre profissionais.",16,UI.MUTED)
    UI.button(page,"GERENCIAR STAFF E DECISÕES DA EQUIPE",host._open_staff,true)
    page = hub.pages["drivers"]
    UI.label(page,"ELENCO DA TEMPORADA  /  DOIS PILOTOS TITULARES",15,UI.ORANGE)
    var drivers := UI.row(page)
    for index in range(2):
        var card := UI.card(drivers,"PILOTO %d" % (index+1))
        var initials := UI.label(card,"—",48,UI.ORANGE)
        var name_label := UI.label(card,"",26)
        var team := UI.label(card,"",17,UI.MUTED)
        var skill := UI.label(card,"",22,UI.GREEN)
        var bar := UI.meter(card)
        driver_cards.append({"initials":initials,"name":name_label,"team":team,"skill":skill,"bar":bar})
    var info := UI.card(page,"Preparação e acompanhamento")
    UI.label(info,"Compare a habilidade dos titulares e prepare a próxima sessão. Durante a corrida, acompanhe pneus, combustível, ritmo e rádio de cada piloto.",18,UI.MUTED)
    UI.label(info,"O elenco é fixo nesta versão. Contratação e renovação de pilotos ainda não estão disponíveis.",16,UI.MUTED)
    UI.button(info,"PREPARAR CORRIDA",hub.open_configuration,true)
    page = hub.pages["finance"]
    var finances := UI.row(page)
    figures["balance"] = metric(finances,"Saldo disponível",true)
    figures["project"] = metric(finances,"P&D ativo • já pago",true)
    figures["payroll"] = metric(finances,"Folha por GP",true)
    var lower := UI.row(page)
    var commitments := UI.card(lower,"Compromissos da equipe")
    figures["contracts"] = UI.label(commitments,"",18)
    figures["refund"] = UI.label(commitments,"",18,UI.GREEN)
    UI.button(commitments,"VER CONTRATOS",hub.show_page.bind("contracts"))
    var investments := UI.card(lower,"Investimentos e prioridades")
    UI.label(investments,"Planeje melhorias do carro e a formação da equipe usando o saldo disponível.",18,UI.MUTED)
    UI.button(investments,"PESQUISA E DESENVOLVIMENTO",hub.show_page.bind("research"),true)
    UI.button(investments,"TREINAMENTO DOS BOXES",open_training)
    var accounting := UI.card(page,"Leitura do orçamento")
    UI.label(accounting,"Todos os departamentos usam o mesmo caixa em R$. O custo do projeto ativo já foi descontado. A folha é cobrada por GP; o valor exibido não é uma despesa mensal.",18,UI.MUTED)
    UI.label(accounting,"Esta versão não registra um extrato financeiro completo. Receitas mensais, patrocínios e projeções não são estimados nesta tela.",16,UI.MUTED)
    page = hub.pages["career"]
    var overview := UI.card(page,"Central da equipe")
    career = UI.label(overview,"",27)
    UI.label(overview,"Prepare o próximo GP, acompanhe o elenco e invista no desenvolvimento do carro.",18,UI.MUTED)
    var shortcuts := UI.row(page)
    for item in [["team","EQUIPE"],["drivers","PILOTOS"],["research","P&D"],["finance","FINANÇAS"]]:
        UI.button(shortcuts,item[1],hub.show_page.bind(item[0]))
    UI.button(page,"PREPARAR TEMPORADA / PRÓXIMO GP",hub.open_configuration,true)
    UI.button(page,"CLASSIFICAÇÃO E RESULTADOS",host._show_championship_table)
    page = hub.pages["calendar"]
    calendar_grid = GridContainer.new()
    calendar_grid.columns = 3
    calendar_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    calendar_grid.add_theme_constant_override("h_separation",12)
    calendar_grid.add_theme_constant_override("v_separation",12)
    page.add_child(calendar_grid)
    UI.button(page,"PREPARAR PRÓXIMA CORRIDA",hub.open_configuration,true)
    page = hub.pages["performance"]
    var areas := UI.card(page,"Desenvolvimento instalado")
    for part in ["Motor","Asa","Chassi"]:
        performance[part] = {"label":UI.label(areas,"",22),"bar":UI.meter(areas,3)}
    UI.label(areas,"Os níveis refletem as peças instaladas na equipe. Projetos em andamento só entram nesta comparação depois da entrega.",17,UI.MUTED)
    UI.button(page,"DESENVOLVER PEÇAS",hub.show_development,true)
    UI.button(page,"RESULTADOS DO CAMPEONATO",host._show_championship_table)
    page = hub.pages["contracts"]
    contracts = UI.label(UI.card(page,"Contratos de staff"),"",19)
    UI.label(page,"A rescisão custa dois salários. Consulte as condições e os candidatos antes de contratar.",17,UI.MUTED)
    UI.button(page,"GERENCIAR CONTRATOS E MERCADO",host._open_staff,true)

func open_training() -> void:
    hub.show_page("research")
    hub.show_research_tab("training")

func refresh(state: Dictionary) -> void:
    var summary: Dictionary = Soul.summary(state)
    var labels := {"morale":"Moral","energy":"Energia","cohesion":"Coesão"}
    for key in culture:
        culture[key].label.text = "%s  /  %d%%" % [labels[key],int(summary[key])]
        culture[key].bar.value = int(summary[key])
    if int(summary["count"]) < 2:
        culture.cohesion.label.text = "Coesão  /  Aguardando 2 titulares"
        culture.cohesion.bar.value = 0
    var lines: Array[String] = []
    for role in roster_cards:
        var person: Dictionary = state["staff_roster"].get(role,{})
        var card: Dictionary = roster_cards[role]
        card.name.text = str(person.get("name","Vaga disponível"))
        card.skill.value = int(person.get("skill",0))
        card.details.text = "Contrate um titular no mercado de staff." if person.is_empty() else "Habilidade %d / 100\n%d GPs restantes\nSalário %s / GP" % [int(person.get("skill",0)),int(person.get("remaining_gps",0)),hub.money(int(person.get("salary",0)))]
        lines.append("%s\n%s\n%s" % [role,card.name.text,card.details.text])
    contracts.text = "\n\n".join(lines)
    for team in host.teams:
        if str(team["name"]) != host.selected_team: continue
        for index in range(mini(2,team["drivers"].size())):
            var driver: Dictionary = team["drivers"][index]
            var card: Dictionary = driver_cards[index]
            var driver_name: String = driver["name"]
            var initials := ""
            for word in driver_name.split(" ",false): initials += word.left(1)
            card.initials.text = initials
            card.name.text = driver_name
            card.team.text = host.selected_team + "  /  Temporada 2012"
            card.skill.text = "Habilidade  %d / 100" % int(driver.get("skill",0))
            card.bar.value = int(driver.get("skill",0))
    var project: Dictionary = state.get("development_project",{})
    figures.balance.text = hub.money(int(state["budget"]))
    figures.project.text = hub.money(int(project.get("cost",0)))
    figures.payroll.text = hub.money(host.garage.staff_payroll_total(host.selected_team))
    figures.contracts.text = "%d / 4 titulares contratados\n%s" % [int(summary["count"]),"Nenhum projeto de P&D ativo." if project.is_empty() else "Projeto ativo: " + str(project["part"])]
    figures.refund.text = "Reembolso ao cancelar P&D: " + hub.money(int(round(float(project.get("cost",0))*0.75)))
    career.text = "%s\n%s  •  %s" % [host.selected_team,hub.round_label.text,figures.balance.text]
    for part in performance:
        var level: int = int(state["levels"].get(part,0))
        performance[part].label.text = "%s  /  nível %d de 3" % [part,level]
        performance[part].bar.value = level
    for child in calendar_grid.get_children():
        calendar_grid.remove_child(child)
        child.queue_free()
    var active: bool = host.championship.has_season()
    var calendar: Array = host.championship.state.get("calendar",[]) if active else host.season_tracks
    var round_index: int = int(host.championship.state.get("round_index",0)) if active else 0
    for index in range(calendar.size()):
        var track: Dictionary = calendar[index]
        var card := UI.card(calendar_grid,"%02d  /  %s" % [index+1,track.get("country","")])
        UI.label(card,str(track.get("name","")),17)
        UI.label(card,"CONCLUÍDO" if active and index < round_index else ("PRÓXIMA ETAPA" if active and index == round_index else "CALENDÁRIO"),13,UI.GREEN if index < round_index and active else UI.ORANGE)
