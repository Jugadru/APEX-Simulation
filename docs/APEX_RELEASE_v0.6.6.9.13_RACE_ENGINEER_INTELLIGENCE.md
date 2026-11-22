# APEX v0.6.6.9.13 — Race Engineer Intelligence 1.0

**Estado:** candidata em branch/PR, **não homologada nem integrada**.  
**Base:** `main` após homologação e merge da v0.6.6.9.12.  
**Único objetivo:** tornar a leitura do engenheiro de corrida mais contextual e compreensível ao jogador, mantendo todas as decisões esportivas e autorizações existentes.

## Contrato de segurança

- `scripts/core/race_engineer_intelligence_066913.gd` é puro e determinístico: recebe apenas carro, companheiro, plano, clima, nível de engenheiro e número de voltas. Não acessa motor, RNG, ponteiro de HUD ou saves.
- Condições priorizadas: carro finalizado, box em andamento, **BOX manual agendado**, incompatibilidade pneu/pista, desgaste, graining/blistering, previsão de chuva, comparação de voltas realmente cronometradas e tráfego conhecido.
- A previsão do estrategista é apresentada como incerta, nunca como previsão perfeita. A diferença última/melhor volta não é apresentada como perda causal comprovada; parâmetros são heurísticas do jogo.
- O nível do engenheiro muda apenas o grau de detalhe da fala, **não** velocidade, risco esportivo, posição, probabilidades de incidente, regras de boxes ou resultado da corrida.
- A recomendação `staff_strategy_066910` é citada quando presente, sem substituí-la.
- `RaceEngineer 3.0` continua sendo a autoridade de `pit_gate` e `can_call_pit`. `intelligence_066913.can_call_pit` é sempre `false`, indicativo de **consulta somente**.
- Uma pergunta extra **ENGENHEIRO IA** aparece no painel existente, emitindo apenas o mesmo evento consultivo de rádio. As ordens manuais, incluindo **V21 sob chuva 83%**, continuam intactas.
- Sem arquivos esportivos modificados em `RaceEngine`, `RaceSpace`, `Replay`, `RaceStateCodec`, pneus, Pit Wall ou Strategy Staff. O replay esportivo permanece na revisão `023_overtaking_intelligence_v1`; não há mudança de fórmula de corrida, checkpoint ou schema salvo.

## Evidências necessárias antes de integrar

1. Importar o projeto com **Godot 4.7.2** sem Parse Error.
2. Testes dirigidos `ENGINEER_066913_PASS` de pureza, determinismo, fontes reais, clima, prioridade de segurança, personalidade, Staff, BOX V21, HUD e rádio, com teste de 24 pilotos e snapshot imutável.
3. Regressões do Race Engineer 3.0, Race Radio 3.0, Strategy Staff 9.10 e Overtaking 9.12.
4. FAST e FULL (todos os gates da branch no SHA exato), matriz 2012, SaveGuard, replay, benchmarks, visual, exportação e corrida longa.
5. Testes visuais/áudio no PC-alvo continuam separados do CI headless; não afirmar FPS/GPU observados sem medição real.

**Resultado inicial:** CI e homologação **NOT_RUN** no momento da implementação. A PR deve permanecer DRAFT até aprovação completa. Não avançar à 9.14 antes do encerramento da 9.13.
