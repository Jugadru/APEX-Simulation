# Arquivos modificados — v0.6.6.4

Arquivos existentes com mudanças:
- `scripts/core/race_replay_0660.gd`: adição de `load_live_session()` (fork de sessão compactada).
- `scripts/race_replay_panel_0660.gd`: trocar apenas `watch()` para usar o fork.
- `project.godot`: número da versão e descrição.

Todos os outros arquivos de produção (`scripts/race_engine.gd`, `scripts/core/race_combat.gd`, física, IA, estratégia, pneus, telemetria, apresentações, HUD e oficina) foram preservados intactos.

Novos testes:
- `tests/replay_watch_0664_test.gd`
- `tests/replay_watch_memory_0664_benchmark.gd`
- `tests/long_race_full_fork_0664.gd`
- `tests/replay_memory_visual_0664.gd`

Novos documentos e QA:
- `CHANGELOG_0664.md`
- `LEIA_PRIMEIRO_0664.md`
- `RELEASE_NOTES_0664.md`
- `ARQUIVOS_MODIFICADOS_0664.md`
- `docs/RELATORIO_TECNICO_0664.md`
- `docs/REPLAY_MEMORY_0664.md`
- `qa/replay_memory_0664/` (logs, perf, replays, capturas e matrizes reais)

Os artefatos originais da v0.6.6.3 permanecem no pacote, inclusive histórico e evidências. Nada foi removido propositalmente.
