# Apex Motorsport Manager 0.6.2.5 — Correção de estratégia de pneus

**Base:** v0.6.2.4 validada visualmente pelo usuário no Godot 4.7.2.

## Problema reproduzido conceitualmente
- China 2012 (Macio/Médio), 56 voltas: IA da versão anterior priorizava o composto mais rápido nos próximos 8–9 giros, sem otimizar o custo total de repetidos pits.
- Nenhuma regra obrigava a utilização de ambos os compostos de seco.
- O mesmo mecanismo podia criar paradas excessivas em Melbourne.

## Mudanças reais
1. `scripts/core/race_stint_optimizer.gd` (**novo**): planejamento determinístico da distância restante para corridas secas. Examina durações de stints e sequências de compostos, cobra a perda de tempo do box em toda parada, utiliza os coeficientes de desempenho/desgaste do Apex e cumpre a obrigação de dois compostos. Limite exploratório de 5 paradas para permitir situações incomuns, sem obrigar paradas adicionais.
2. `scripts/core/race_ai_director.gd`: usa o novo plano quando pista e previsão próxima estão secas; conserva a heurística validada de cruzamentos de chuva fora dessas condições. Disponibiliza `planned_pit_lap` e `planned_stops` como **estimativas revisáveis**.
3. `scripts/core/race_tyre_regulations_2012.gd` (**novo**) e `scripts/race_engine.gd`: observa uso efetivo dos dois slicks e declaração de chuva; a ausência dos dois pneus numa prova seca gera desclassificação no encerramento. Aviso antecipado em modo manual. Uma corrida declarada molhada ou com uso de pneus de chuva tem a regra dispensada.
4. `scripts/championship_2012.gd`: um desclassificado não recebe pontos; situação é registrada no resultado de etapa.
5. Respeito a agendamento manual (ex.: V21), boxes em andamento e desativação de comando automático em modo Manual.
6. **NÃO alterado:** HUD da 0.6.2.4, geometria/câmera, física de desgaste, clima, carros 3D, entrada e animação do pit.

## Testes
- `python3 tests/test_0625_dry_strategy_static.py`: seis testes, incluindo espelho matemático independente de China, Austrália, Bahrein e Malásia, com ambas as opções de largada; os planos-modelo resultaram em 2 paradas e utilização legal dos compostos (não são corridas do motor Godot).
- `python3 tests/test_0612_indent_static.py`: inspeção de indentação.
- `bash linux/validar_0625.sh`: executa testes Python e, **caso o Godot esteja instalado**, parser/cena e smoke do planejador.
- `bash linux/validar_0625.sh --long`: adiciona uma **corrida completa** da China em modo seco no Godot, avaliando o número de pits e os pneus usados pelas equipes IA.

## Limitações e verificação do usuário
- A simulação física completa **não foi executada nesta máquina** porque não há executável Godot. Não declarar correção como validada na corrida real antes de executar os smoke tests e observar o GP.
- Previsão matemática usa os parâmetros do jogo, não a física perfeita do carro em cada volta (calor, tráfego, acidentes e chuva posterior podem alterar a melhor decisão).
- Cinco paradas ainda podem ocorrer com condições excepcionais; não existe limite artificial de três pits imposto às corridas.
- A interface da estratégia geral continua distinguindo apenas stints cumpridos e ordens **explicitamente agendadas**; não apresenta visualmente todos os pit stops sugeridos pela IA. Isso fica para outra atualização.
