# Changelog v0.6.4.2

Base: ZIP completo da v0.6.4.1.

- **NOVO** `scripts/core/rival_development_0642.gd`: finanças e evolução de 11 equipes rivais, orçamento, prioridades, níveis e histórico de investimento determinísticos por semente.
- **NOVO** `scripts/core/race_rain_hysteresis_0642.gd`: filtro climático com água atual e previsão de três voltas; não bloqueia desgaste crítico.
- `scripts/championship_2012.gd`: rivais persistidos junto do campeonato com migração de saves antigos e sem duplicar upgrades ao registrar mesmo GP duas vezes.
- `scripts/race_engine.gd`, `scripts/core/race_performance.gd`: cada rival usa níveis de suas próprias peças na física. As funções de cruzamento e chegada e do pit lane não foram alteradas.
- `scripts/garage.gd`: P&D com 15% de desconto, dois GPs de espera, débito de orçamento, salvamento, entrega, cancelamento e restituição de 75%.
- `scripts/apex_championship_flow.gd`: entrega dos projetos depois da prova, segura contra dupla contabilização; novo campeonato lida com P&D antigo.
- `scripts/apex_race_session_controller.gd`: passa os níveis das rivais do campeonato ao motor da corrida.
- `scripts/apex_garage_screen.gd`, `scripts/apex_garage_presentation.gd`, `scripts/apex_race_ui_layout.gd`, `scripts/main.gd`: oficina maior, estado de P&D, resumo de investimento, todas as rivais e preços/custos.
- `scripts/core/race_ai_director.gd`: usa o novo filtro para recomendações de pit relacionadas ao clima.
- `project.godot` e HUD: identificação da nova versão.
- **NOVOS TESTES**: `tests/core_0642_rival_workshop_weather_test.gd`, `tests/core_0642_save_migration_test.gd`, `tests/season_0642_auto_rival_career_worker.gd` e `tests/native_capture_0642_garage.gd`.

Ainda não foram implementados abandonos por falha mecânica, contratos de engenharia multi-temporada ou perfis psicológicos reais de engenheiros/pilotos.
