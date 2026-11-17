# APEX v0.6.6.3 — Arquivos modificados

## Arquivos existentes com mudanças funcionais
- `scripts/core/race_replay_0660.gd` — compactação de checkpoints residentes; restauração e exportação binária histórica compatível.
- `scripts/core/racecraft_audit_0662.gd` — coleta incremental de eventos em ordem preservada.
- `project.godot` — título e descrição de versão.

## Arquivos existentes preservados
- `scripts/race_engine.gd` — **idêntico ao da v0.6.6.2** (teste de cópia rasa rejeitado).
- Cenas, recursos de mídia, assets, temporada F1 2012, regras, pneus, estratégia, HUD, oficina, IA e persistência — sem mudanças funcionais.

## Novos testes
- `tests/long_race_benchmark_0663.gd`
- `tests/long_race_full_0663.gd`
- `tests/long_race_visual_0663.gd`
- `tests/replay_0663_legacy_fixture.gd`

## Documentação e QA
- `CHANGELOG_0663.md`, `LEIA_PRIMEIRO_0663.md`, `RELEASE_NOTES_0663.md`, `docs/RELATORIO_TECNICO_0663.md`, `docs/LONG_RACE_PERFORMANCE_0663.md`.
- `qa/long_race_0663/`: logs reais, JSON do benchmark, replay antigo e novo para comparação binária, relatórios de testes e capturas nativas.
- Registros gerados pelos testes em `qa/racecraft_0662/` foram atualizados (são evidências, não código).

**Cobertura da base:** nenhum dos 2.234 arquivos originais foi removido.
