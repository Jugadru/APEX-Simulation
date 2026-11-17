# Plano de refatoração do main.gd — após aprovação da HUD 0.6.2.2

Esta é uma proposta técnica, **ainda não implementada**. O objetivo não é fragmentar aleatoriamente o `main.gd`, mas separar responsabilidades para reduzir regressões e facilitar o crescimento do Apex.

## Base atual

- `scripts/main.gd` segue com aproximadamente **2.441 linhas** e funciona como orquestrador.
- Módulos já extraídos na v0.6.2.1: `apex_session_settings.gd`, `apex_championship_flow.gd`, `apex_garage_presentation.gd`, `apex_race_formatting.gd`.
- HUD de corrida isolada em `apex_race_hud_0622.gd`; estratégia/timeline em `apex_strategy_planner_0620.gd`.

## Próximos módulos propostos

1. **`apex_race_session_controller.gd`**: inicialização, mudança de status, pausa e encerramento. Não conter desenho de UI.
2. **`apex_race_view_controller.gd`**: alternância 2D/3D/TV, foco, zoom, pan e presets de câmera; separar estado do visor da HUD.
3. **`apex_race_commands.gd`**: entrada de ordens de box, ritmo, KERS e permissões STAFF; testar agendamento contra antecipação indevida.
4. **`apex_race_hud_legacy_adapter.gd`**: mapear APIs da UI antiga para a nova; só eliminar legados quando todos os usos forem migrados.
5. **`apex_garage_screen.gd`**: criação e atualização visual da garagem, distinta da simulação financeira.
6. **`apex_menu_screen.gd`**: criação de menus/seletores, calendário, seleção de temporada e campeonato.
7. **`apex_radio_feed.gd`**: apresentação de rádio e eventos, mantendo `apex_commentary.gd` como fonte.

## Método de migração

- Congelar a base testável e não modificar motores `race_engine.gd`, clima/pneus, pistas e dados junto à extração.
- Mover **um grupo por vez**, mantendo wrappers temporários no `main.gd` e equivalência de código.
- Testar pré-carregamentos, sintaxe, controles, fluxo de início e término de corrida, navegação entre modos, dados reais, saves e performance.
- Executar parser Godot 4.7.2 e abrir corrida graficamente antes de considerar aprovado.
- Documentar funções migradas, dependências circulares removidas e responsabilidades finais por arquivo.
