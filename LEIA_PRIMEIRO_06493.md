# Leia primeiro — Apex Motorsport Manager v0.6.4.9.3

Atualização incremental do balanceamento de pit stops em clima variável. **Não é uma reescrita do motor.**

1. Descompacte este ZIP inteiro em uma pasta nova.
2. Importe `project.godot` no **Godot 4.7.2**.
3. Execute com **F5** e inicie a corrida normalmente.
4. Para ver dados do GP de Silverstone, consulte `qa/06493/native_020/GBR.json` e `qa/06493/SILVERSTONE_COMPARACAO_06492_06493.csv`.

Saves isolados por `ApexMotorsportManager_PitWall_06493`; nenhum save anterior é sobrescrito por padrão. 

A única mudança de comportamento foi o bloqueio de **troca preditiva prematura por um novo pneu de chuva do mesmo composto**, em condições específicas com margem segura. O jogador continua podendo ordenar uma parada manualmente. A IA pode parar por desgaste crítico ou mudança efetiva de composto/clima.

Testes: consulte `RELATORIO_TESTES_06493.md` para resultados e limitações efetivamente constatados. 
