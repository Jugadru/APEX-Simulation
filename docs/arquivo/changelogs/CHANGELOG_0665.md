# APEX Motorsport Manager — Changelog v0.6.6.5

**Uma mudança principal:** Replay Checkpoint Coverage 1.0.

### Alterado
- `scripts/core/race_replay_0660.gd`: introduz `MAX_CHECKPOINTS=9` e
  seleciona, a cada 300 ticks e quando necessário, qual checkpoint intermediário
  pode ser removido com menor aumento de custo de busca pelo histórico.
  Mantém obrigatoriamente o checkpoint de tick 0 e o mais recente.
- `project.godot`: identificador e descrição v0.6.6.5.

### Acrescentado
- `tests/replay_checkpoint_0665_benchmark.gd`: A/B de 3.200 ticks, buscas
  em 750/1500/2800, integridade do hash, arquivo externo e replay antigo.
- `tests/long_race_checkpoints_0665.gd`: corrida de 53 voltas, hashes,
  checkpoints distribuídos, buscas históricas e exportação/importação.
- `tests/replay_checkpoints_visual_0665.gd`: capturas reais Godot 1600×900/1920×1080.
- `qa/replay_checkpoints_0665/`: medições, evidências e logs.
- Relatórios, instruções, testes e manifestos v0.6.6.5.

### Não modificado
- Física, IA, pit stops, pilotos, staff, Racecraft Audit, Race Engine, HUD e
  formatos existentes de saves e replay (`APEX_REPLAY_0660`).

### Experimento descartado
O descarte por intervalos duplicados reduziu o peso dos arquivos, porém
regrediu o tempo de algumas buscas (tick 1500: 0,055 s → 12,091 s). **Não integra
o release**; substituído por seleção equilibrada de checkpoints.
