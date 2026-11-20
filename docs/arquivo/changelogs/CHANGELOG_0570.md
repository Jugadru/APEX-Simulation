# APEX v0.5.7.0 — IA Estratégica / Engenheiro de Corrida

## O que foi implementado

- **Planejador de stints determinístico** (`race_ai_director.gd`): prevê vida útil aproximada do pneu, janela de pit, composto do próximo stint, tendência de chuva para 3 e 6 voltas, além de um ganho estimado para uma troca imediata.
- **Comparação econômica** entre permanecer no stint atual e iniciar um novo: ganho previsto em até 9 voltas menos o custo real parametrizado do pit lane. Estimativas são de gameplay, não telemetria oficial.
- **Previsão de água sem mutar o clima da corrida** (`race_weather.gd`): os mesmos fatores de chuva, evaporação e drenagem do motor são integrados à frente, sem gerar números aleatórios ou alterar o estado real da pista.
- **IA com coordenação de equipe**: opcionalmente adia um pit não urgente se o companheiro está com o box ocupado, reduzindo double stacks evitáveis. A proteção de desgaste crítico e a troca W→W/I→I da v0.5.5.2 permanecem prioritárias.
- **Engenheiro do jogador somente consultivo**: Pit Wall e aba ESTRATÉGIA mostram recomendação, janela, composto e previsão. Avisos de pit no rádio são limitados a uma vez a cada duas voltas; o jogador continua chamando boxes pelos cartões inferiores.
- **KERS e DRS da v0.5.6.1 preservados exatamente**: também não há alterações nas fórmulas de desgaste e chuva, tempos de box, HUD dos comandos, double stack, geometria 3D e telemetria.

## Limitações e transparência

Esta é a **primeira etapa** de uma IA estratégica preditiva. Não existem ainda previsão perfeita de Safety Car, simulação de tráfego após o pit, equipes com personalidade, rádio por voz ou um otimizador completo de 44 voltas. As janelas são estimativas que se recalculam com as condições reais. As recomendações não garantem vitória ou o melhor pit em toda situação.

## Testes

```bash
python3 tests/test_0570_ai_strategy_static.py
bash linux/validar_core_0570.sh
```

Validação prolongada opcional no Godot:

```bash
godot --headless --path . --script res://tests/core_0570_long_strategy_run.gd
```

Testes estáticos não garantem parsing ou execução correta no Godot 4.7.2. A versão deve ser importada e testada no computador do jogador.
