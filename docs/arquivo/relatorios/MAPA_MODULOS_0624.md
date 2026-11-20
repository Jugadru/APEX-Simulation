# Organização do código — APEX v0.6.2.4

O script `scripts/main.gd` está com 746 linhas e atua como coordenador da cena, mantendo referências e estado compartilhado. Ainda não é um controlador totalmente independente: as rotinas extraídas são chamadas por métodos estáticos com `host`, para preservar a integração com as cenas existentes sem reescrever o simulador.

## Áreas extraídas na v0.6.2.4

| Componente | Responsabilidade |
|---|---|
| `apex_race_ui_legacy_builder.gd` | Criação da UI legada que continua oculta na corrida |
| `apex_race_ui_layout.gd` | Regras de layout e visibilidade |
| `apex_race_ui_presenter.gd` | Atualização de placar, condições e dados da UI legada |
| `apex_race_ui_legacy_cards.gd` | Cartões da UI antiga e respectivos callbacks |

## Módulos preservados da v0.6.2.3

- `apex_race_session_controller.gd`: início, saída e ciclo de sessão
- `apex_race_view_controller.gd`: câmeras, zoom, panorâmica, modos 2D/3D/TV
- `apex_race_commands.gd`: ritmo, KERS, boxes e STAFF
- `apex_telemetry_reports.gd` e `apex_pit_reports.gd`: diagnósticos e relatórios
- `apex_menu_screen.gd` e `apex_garage_screen.gd`: montagem do menu e da garagem
- `apex_radio_feed.gd`: filtro e feed de rádio
- `apex_session_settings.gd`, `apex_championship_flow.gd`, `apex_garage_presentation.gd`, `apex_race_formatting.gd`: configurações, campeonato, garagem e formatação
- `apex_race_hud_0622.gd`: **única HUD de corrida visível** (não alterada)
- `apex_strategy_planner_0620.gd`: planejamento visual de stints

## Passos futuros, após validar esta versão no Godot

1. Remover gradualmente os elementos legados que já não são necessários, depois de confirmar dependências reais de telemetria, relatórios, menus e comandos.
2. Separar estado de UI da simulação (evitar atributos compartilhados via `host`).
3. Melhorar a câmera aérea, enquadramento de disputas e Diretor TV, sem aumentar a HUD desnecessariamente.
4. Atualizar a suíte histórica para verificar as APIs modulares em vez de procurar código literal em `main.gd`.
