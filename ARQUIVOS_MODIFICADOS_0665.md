# Arquivos modificados — APEX v0.6.6.5

## Arquivos preexistentes intencionalmente modificados
1. `project.godot` — identificação da versão.
2. `scripts/core/race_replay_0660.gd` — política do limite de 9 checkpoints.

**Não alterar** `scripts/race_engine.gd`, UI, integração do replay de 0664,
arquivo de save, schemas ou demais sistemas. Nenhum recurso 3D substituído.

## Arquivos novos
- `tests/replay_checkpoint_0665_benchmark.gd`
- `tests/long_race_checkpoints_0665.gd`
- `tests/replay_checkpoints_visual_0665.gd`
- `qa/replay_checkpoints_0665/*`
- `LEIA_PRIMEIRO_0665.md`, `CHANGELOG_0665.md`,
  `ARQUIVOS_MODIFICADOS_0665.md`,
  `RELATORIO_TECNICO_APEX_v0.6.6.5.md`,
  `BUILD_MANIFEST_0665.json`

Os arquivos históricos são mantidos; evidências novas ficam segregadas em
`qa/replay_checkpoints_0665/`.
