# APEX MOTORSPORT MANAGER — APEX 2 NEXT ENGINE 1.0

ESTA É UMA RAMIFICAÇÃO EXPERIMENTAL, NÃO UM NOVO MOTOR DE CORRIDA JOGÁVEL.

Base: v0.6.6.8.1 HUD ReBroadcast. A interface, o replay oficial e o Core 2 continuam intactos.

O código experimental está em `experimental/apex2/`. Execute os testes headless em `tests/apex2/` no Godot 4.7.2 para examinar o Simulation Kernel, Command Queue e o adaptador Core 2.

O integrador de movimento é apenas de referência, não física realista: não suporta pit stop completo, desgaste, clima causal, Racecraft ou IA. Não usar benchmark como comparação de superioridade até igualar regras implementadas.

Documentos: `APEX2_RELATORIO_TECNICO_1.0.md`, `APEX2_TESTES_1.0.json`, `APEX2_BENCHMARK_AB_1.0.json`, `APEX2_MANIFESTO_1.0.json`, `APEX2_CHANGELOG_1.0.md`.

Para rollback, extraia novamente o ZIP da v0.6.6.8.1 numa nova pasta, sem tocar nos saves.
