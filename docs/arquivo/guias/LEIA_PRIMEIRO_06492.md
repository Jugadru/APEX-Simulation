# APEX Motorsport Manager 0.6.4.9.2 — Double Stack (uma correção)

**Base completa:** v0.6.4.9.1 Memória de Pit Stop. **Engine:** Godot 4.7.2 Linux.

## Única mudança funcional

A chamada automática já aceita pode encontrar o companheiro ainda ocupando a garagem quando chega à entrada do pit lane. A 0.6.4.9.2 acrescenta uma **verificação final e conservadora de fila prevista** na entrada: se o companheiro ainda vai ocupar o box por mais de ~2,5 segundos após o tempo de aproximação, a IA só pode permanecer na pista para reavaliar na próxima volta quando todas as condições abaixo forem satisfeitas.

- Chamada de box da **IA estratégica normal**, nunca ordem imediata do jogador, agendamento manual ou emergência por desgaste.
- Pista seca e previsão de três voltas ainda seca, sem chuva ativa significativa.
- Desgaste abaixo de 60%, vida estimada de pelo menos três voltas, recomendação não crítica.
- Um adiamento seguro ainda disponível no stint, após a correção da 0.6.4.9.1.
- Há outra entrada de pit válida, antes da última volta.

O segundo carro deixa de entrar na fila nessa condição; a estratégia volta a ser analisada na volta seguinte. Se chuva, emergência, pneus críticos ou ordem manual exigirem parada, **o carro entra mesmo que precise esperar**. A garagem continua exclusiva para cada equipe, sem sobreposição de serviço.

## Arquivos funcionais da alteração

- `scripts/core/race_double_stack_coordinator_06492.gd`: novo cálculo de fila prevista e filtros de segurança sem sorteio ou alteração do motor de pneus.
- `scripts/race_engine.gd`: chama a avaliação imediatamente antes de iniciar uma parada automática autorizada.
- `project.godot`: título e pasta de save separada (`ApexMotorsportManager_PitWall_06492`).

**Não foram modificados** os componentes de desgaste dos pneus, física 3D, condições climáticas, matemática do pit lane, Race Engineer, Soul Driver, Staff, código da HUD ou confiança estratégica. O total de paradas e a confiança serão tratados **somente** nas versões 0.6.4.9.3 e 0.6.4.9.4.

## Como instalar

1. Descompacte todo o ZIP em pasta nova e mantenha a versão 0.6.4.9.1 guardada.
2. No Godot 4.7.2, abra/importa `project.godot` e pressione **F5**.
3. Abra uma corrida e use **ENG. / PIT WALL 3.0** para consultar as análises.
4. Saves são isolados. Não copie por cima de uma versão anterior.

## Evidências e testes

- `tests/double_stack_06492_entry_test.gd`: cenário real de Silverstone, gate de chuva/desgaste, V21, emergência e ordens manuais.
- `tests/double_stack_06492_before_after.gd`: reprodução do comportamento antigo vs novo no mesmo caso controlado.
- `tests/pitwall_06492_silverstone_full_gp_test.gd -- --code GBR`: corrida completa com seed 6403 e 0,20s por passo.
- `qa/06492/`: resultados, comparação e logs dos 18 testes aprovados.
- `RELATORIO_TESTES_06492.md`: resultado detalhado e limitações.

**Atenção:** o teste de corrida completa em chuva variável continuou com três filas e 90 paradas, igual à versão anterior. Isso é uma preservação das decisões em condições que não passaram pelo novo gate; não é uma redução observada de filas nesse GP. A prova de melhoria é o cenário seco controlado de Silverstone com 7,4s de fila anterior e 0,0s depois.
