# APEX Motorsport Manager — v0.6.6.4
## Replay Memory 1.0 — Replay Session Fork

**Base:** v0.6.6.3 Long Race Performance 1.0 (ZIP completo, intacto para rollback).

### Alterações implementadas

- `scripts/core/race_replay_0660.gd`: novo `load_live_session(recorded)` que abre a sessão local diretamente dos checkpoints compactados, comandos e hashes. O método clona os dados necessários antes de fazer `seek(0)`, sem exportar a telemetria inteira em dicionários intermediários.
- `scripts/race_replay_panel_0660.gd`: o botão **Ver gravação atual** utiliza a nova API; **Exportar gravação** e **Abrir replay** continuam pelo formato antigo.
- `project.godot`: identidade da versão.
- `tests/replay_watch_0664_test.gd`: paridade de hashes, checkpoint, replay antigo e sessão sem mutação.
- `tests/replay_watch_memory_0664_benchmark.gd`: benchmark real para o caminho antigo e o novo, com semente e configuração idênticas.

### Preservações

- `APEX_REPLAY_0660`, `simulation_revision=0661_driver_dynamics`, hashing, regras esportivas, clock, frequência de ticks e leitura de RNG não mudaram.
- Nenhuma alteração no Core 2, ultrapassagens, Racecraft, Pit Wall, Strategy Simulator, IA, pneus, HUD visual, 3D ou Living Factory.
- Checkpoints, snapshots, eventos, telemetria e comandos necessários ao replay continuam íntegros.
- **A compatibilidade de replay externo é mantida pelo método original `load_data`/`load_file`, sem novo formato.**

Os resultados e limites de aprovação encontram-se em `docs/RELATORIO_TECNICO_0664.md` e `qa/replay_memory_0664/`.
