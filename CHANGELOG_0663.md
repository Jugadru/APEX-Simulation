# APEX Motorsport Manager — Changelog v0.6.6.3

**Long Race Performance 1.0** · Base comprovada: v0.6.6.2 · Godot 4.7.2 · F1 2012

## Otimizações implementadas
- `scripts/core/race_replay_0660.gd`: checkpoints periódicos da memória residente passam a guardar o estado serializado e compactado com ZSTD (Godot), mantendo o checkpoint inicial e o método público `checkpoint()` no formato legado. Estados compactados são descompactados durante `seek` e durante exportação.
- Exportação e gravação continuam em `APEX_REPLAY_0660` com `simulation_revision=0661_driver_dynamics`; a representação compactada é exclusivamente interna. O carregamento de gravações antigas foi testado.
- `scripts/core/racecraft_audit_0662.gd`: observador de disputas passa a localizar apenas eventos inéditos a partir do fim do buffer cronológico, preservando a ordem de contabilização.
- `project.godot`: versão e descrição v0.6.6.3.

## QA acrescentada
- `tests/long_race_benchmark_0663.gd`: benchmark fixo, comparativo 4.500 ticks, por circuito/seed/clima.
- `tests/long_race_full_0663.gd`: distância oficial Monza 53 voltas e replay integral tick a tick, com progresso e relatório.
- `tests/replay_0663_legacy_fixture.gd`: gravação pela versão anterior e carregamento na atual.
- `qa/long_race_0663/`: resultados e evidências efetivamente produzidos.

## Escopo que NÃO foi modificado
- Física/Core 2, IA, pneus, Pit Wall, estratégia, áudio/rádio, HUD, fábrica, oficinas, modelos 3D, cenas e assets.
- Regras 2012, geração de números aleatórios, comandos, tick `0.2s`, velocidade do relógio esportivo e hashes.

## Experimento rejeitado
- Foi ensaiada uma duplicação superficial das estruturas de carros no tick do motor. Ela manteve o hash de 4.500 ticks, mas foi **mais lenta** (137,69s contra 131,63s da candidata); o motor original foi restaurado sem essa alteração.

**Aviso:** Esta versão só pode ser chamada de estável depois da validação nativa e da corrida longa integral. Consulte `docs/RELATORIO_TECNICO_0663.md` para o resultado observado.
