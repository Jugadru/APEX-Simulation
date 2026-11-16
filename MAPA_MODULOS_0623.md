# Arquitetura Apex 0.6.2.3

`main.gd` mantém o objeto cena com referências de UI e estado compartilhado e delega operações por meio de métodos estáticos chamados com `self`. Os callbacks antigos continuam existindo e são wrappers. Uma próxima etapa pode migrar para instâncias com interfaces mais estritas depois de confirmar a execução em Godot.

| Script | Responsabilidade |
|---|---|
| `scripts/main.gd` | Orquestra a cena, mantém referências para UI legada e integra simulação e apresentação |
| `scripts/apex_race_session_controller.gd` | Início da corrida, setup de circuito e mudança de cena |
| `scripts/apex_race_view_controller.gd` | Modo de visualização, câmera, zoom, acompanhamento, seleção e entrada de controle |
| `scripts/apex_race_commands.gd` | Ritmo, KERS, paradas, agendamentos, modo manual/STAFF e pausa |
| `scripts/apex_telemetry_reports.gd` | Diagnósticos e relatórios de telemetria/exportação |
| `scripts/apex_pit_reports.gd` | Relatórios dos boxes e CSV |
| `scripts/apex_menu_screen.gd` | Construtor da tela inicial |
| `scripts/apex_garage_screen.gd` | Construtor visual da oficina |
| `scripts/apex_radio_feed.gd` | Filtro e atualização do feed de rádio |
| `scripts/apex_race_hud_0622.gd` | HUD visível da corrida: classificação, dois cartões, janelas e controles |
| `scripts/apex_strategy_planner_0620.gd` | Linha visual de stints do planejamento de corrida |
| `scripts/apex_session_settings.gd` | Dados da temporada e preferências de HUD (extraído em 0.6.2.1) |
| `scripts/apex_championship_flow.gd` | Progresso e resultados do campeonato (extraído em 0.6.2.1) |
| `scripts/apex_garage_presentation.gd` | Atualização de dados da oficina (extraído em 0.6.2.1) |
| `scripts/apex_race_formatting.gd` | Formatação e exibição de dados (extraído em 0.6.2.1) |

**As oito extrações nesta versão são de responsabilidade**, não alteram nem duplicam o motor de simulação. Ainda há código legado de UI dentro de `main.gd` que será migrado depois da validação desta edição pelo Godot.
