# Changelog — APEX 2 Next Engine 1.0 Experimental

## Incluído
- Simulation Kernel experimental com clock determinístico 200 ms, avanço em bloco, snapshots somente leitura e checkpoints restauráveis.
- Command Queue experimental com prioridade Manual, histórico, validações, conflitos e proteção da volta 21.
- Adaptador de cenário 2012/seed/circuito para pareamento com Core 2.
- Cinco testes dedicados e benchmark A/B de quatro circuitos.
- Relatório, evidências e instruções de rollback.

## Não alterado
- `project.godot`, `scripts/**`, `scenes/**`, assets, HUD, Pit Wall, Replay oficial, Diretoria TV, save/carreira, física e IA do Core 2.

## Conhecidos e pendentes
- Kinematics placeholder; sem física, Racecraft ou IA na Next 1.0.
- Benchmark não comparável em carga esportiva. Testes de FPS/GPU, alocações e saves oficiais não feitos.
- Não há seletor da Next Engine no jogo; executar apenas em test runner.
