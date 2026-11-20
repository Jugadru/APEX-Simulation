# Inventário de mudanças — APEX Motorsport Manager v0.6.6.6

## Arquivos preexistentes deliberadamente modificados

1. `project.godot`: identificação v0.6.6.6.
2. `scripts/core/race_replay_0660.gd`: cache efêmero, restauração auditável e seleção de fonte para seek.

**Não modificados:** `scripts/race_engine.gd`, cenas, HUD, recursos visuais/3D, dados históricos 2012, regras esportivas, controladores de IA, scripts Racecraft, persistência de saves e demais sistemas.

## Novos arquivos

- `tests/replay_fast_seek_0666_benchmark.gd`
- `tests/replay_fast_seek_0666_contract.gd`
- `tests/replay_fast_seek_0666_monza53.gd`
- `tests/racecraft_0666_gp.gd`
- `tests/replay_checkpoints_visual_0666.gd`
- `qa/replay_fast_seek_0666/*`
- `CHANGELOG_0666.md`, `ARQUIVOS_MODIFICADOS_0666.md`, `LEIA_PRIMEIRO_0666.md`, `RELATORIO_TECNICO_APEX_v0.6.6.6.md`, `BUILD_MANIFEST_0666.json`.

A integridade de arquivos históricos é verificada diretamente contra o ZIP completo da v0.6.6.5. O teste unitário de replay sobrescreve temporariamente `qa/replay_0660/unit.json`; esse fixture histórico é restaurado do ZIP original antes do empacotamento.
