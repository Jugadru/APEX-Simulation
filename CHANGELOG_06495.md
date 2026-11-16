# Changelog 0.6.4.9.5 — Pré-Corrida

- Adicionado `race_pre_race_strategy_06495.gd`: otimizador puro com programação dinâmica para dois pneus secos, custo de pit, limites conservadores de desgaste e janelas de stint.
- Adicionado `apex_pre_race_tyre_chart_06495.gd`: gráfico de condição dos pneus por stint.
- Adicionado `apex_pre_race_screen_06495.gd`: tela com duas estratégias e confirmação explícita da primeira parada MANUAL.
- Integração mínima em `scripts/main.gd`, `scripts/apex_menu_screen.gd`, `scripts/apex_race_session_controller.gd`; configuração de pasta de saves separada em `project.godot`.
- Sem mudanças no motor de corrida, física, IA de box, Pit Wall 3.0 ou regras de corrida. As atualizações por volta e coordenação automática preventiva ficam para versões futuras.
