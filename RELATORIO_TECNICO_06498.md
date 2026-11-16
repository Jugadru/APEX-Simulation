# RELATÓRIO TÉCNICO — APEX MOTORSPORT MANAGER v0.6.4.9.8

**Versão-base inspecionada:** APEX v0.6.4.9.7 — Coordenação Automática Completo, upload fornecido pelo usuário.

**Escopo:** exclusivamente os gráficos e a apresentação consultiva dos estados de desgaste e estratégia. Não foram emitidas ordens, nem alterados os modelos físicos ou os algoritmos de pit.

## Arquitetura

| Área | Implementação | Fonte de dados |
|---|---|---|
| Desgaste real | Histórico por piloto/stint, 1 amostra para cada volta efetivamente observada | `car.laps_done`, `car.wear`, `car.stops`, `car.tire` |
| Desgaste previsto | Projeção linear limitada ao próximo evento de pit e 100% de desgaste | Variação real das últimas 1–4 voltas consecutivas do stint, ou `get_engineer_advice().wear_per_lap` enquanto ainda não há delta medido |
| Estratégia inicial | Snapshot imutável do planejamento v0.6.4.9.5 na entrada do GP | `race_pre_race_strategy_06495.generate(race)` |
| Estratégia atual | Stints executados, paradas registradas e próxima ordem/janela | `race.pit_history`, `car.pit_scheduled_lap`, `advice.window_start/window_end` |
| Conflitos | Agendamento idêntico = confirmado; sobreposição de sugestões = potencial | Dois carros da equipe; status real do pit |
| Integração | Janela de gráficos aberta a partir de Estratégia, Pit Wall 3.0 e Race Engineer 3.0 | HUD híbrida de `apex_race_hud_0622.gd` |

A opção de abrir os gráficos não altera o motor. A coleta é por polling da HUD e não cria valores para voltas saltadas no monitor. A curva prevista é **estimativa**, não medição nem decisão de box. `get_engineer_advice` já existe na base e é consultivo. A previsão usa condições atuais: não modela antecipadamente mudanças de clima, tráfego futuro ou penalizações ainda não ocorridas.

## Ambiente e evidências

- Godot `v4.7.2.stable.official.ed1daf0bf`.
- Visual: Xvfb 1920×1080, Mesa llvmpipe OpenGL 4.5 compatibilidade (renderização de software).
- `docs/APEX_06498_GRAFICOS_SILVERSTONE_1600.png`: tela inicial real a 1600×900.
- `docs/APEX_06498_GRAFICOS_SILVERSTONE_1920.png`: tela inicial real a 1920×1080.
- `docs/APEX_06498_DESGASTE_REAL_SILVERSTONE_1600.png`: curvas de desgaste real após 7 voltas dos carros da equipe em Silverstone, 1600×900.
- `docs/APEX_06498_PIT_REAL_SILVERSTONE_1600.png`: evolução após pit real na V14; o gráfico separa parada concluída de serviço do colega ainda em andamento.
- Limite: desempenho FPS na placa gráfica do usuário não foi aferido com Xvfb/Mesa; teste visual não substitui validação com monitor/GPU de destino.

## Validações executadas

| Teste | Resultado |
|---|---|
| Importação de scripts Godot 4.7.2 | PASS (exit 0) |
| `dynamic_strategy_06498_data_test.gd` | PASS — origem real, nenhum dado de volta inventado, sem alteração do motor, casos de conflito |
| `dynamic_strategy_06498_ui_test.gd` | PASS — Silverstone, ambas resoluções, dois pilotos, 6 atalhos, integrações, amostras reais e PNG do framebuffer |
| `dynamic_strategy_06498_parity_test.gd` | PASS — 360 passos nativos de 4,0 s em duas corridas idênticas; o monitor de gráficos não alterou a evolução do motor, incluindo IA, RNG, pit stops ou física |
| `dynamic_strategy_06498_pit_visual_test.gd` | PASS — serviço real em Silverstone na V14, registro equivalente no gráfico, captura PNG nativa 1600×900 |
| `team_pit_06497_unit_test.gd` | PASS — coordenação 9.7, 16 condições |
| `lap_strategy_06496_auto_gate_test.gd` | PASS — auto/manual, janela de 1 volta e V21 |
| `pitwall_0649_strategy_test.gd` | PASS — cenários e coordenação de pit |
| `race_0646_engineer_3_test.gd` | PASS — Engineer 3.0, controle e caixa de rádios |
| `pre_race_06495_planner_test.gd` | PASS — plano 52 voltas, dois carros, somente leitura |
| `auditoria_06497_gp.gd -- --code GBR` | PASS — **Silverstone 52/52 voltas, 24 pilotos, 78 paradas, 0 erros**, 26.440 passos nativos de 0,20 s; cenário 'Variável' e seed 6403 |

O teste gráfico registra avisos de V-Sync e um erro ALSA `ERR_CANT_OPEN` ao tentar abrir um dispositivo de áudio ausente; o próprio Godot utiliza o driver de áudio dummy, e os testes do jogo terminam com PASS. Isso é uma limitação da máquina virtual, não uma falha de pit stop. Logs estão em `qa/06498/`.

## Preservação e compatibilidade

- Todos os arquivos de `scripts/core/` e `scripts/race_engine.gd` permanecem byte a byte iguais aos fornecidos na v0.6.4.9.7.
- Nenhuma cena 3D, recurso de pista, equipe, pneus ou cálculo da IA foi modificado.
- A HUD conserva os seis atalhos superiores, a estética grafite/laranja, os dois cartões de pilotos e os painéis Race Engineer/Pit Wall existentes.
- Pasta de saves desta variante isolada por `config/custom_user_dir_name`.
- Não há avanço para a versão 0.6.4.9.9.
