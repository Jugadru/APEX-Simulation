# Relatório técnico — APEX Motorsport Manager v0.6.4.9.9

**Versão:** Strategy Simulator 1.0  
**Base:** v0.6.4.9.8 — Gráficos Dinâmicos  
**Motor testado:** Godot **4.7.2.stable.official.ed1daf0bf** (Linux, renderizador Compatibility/OpenGL para testes visuais).  
**Mudança funcional permitida:** cenários consultivos de parada na próxima entrada e em +1 a +5 voltas, para dois pilotos.

## 1. Entrega e integrações

Implementado `scripts/core/race_strategy_simulator_06499.gd` como módulo determinístico de leitura. Atualizada somente a apresentação da HUD híbrida em `scripts/apex_race_hud_0622.gd`, com nova janela **SIMULADOR 9.9** acessível por **ESTRAT.**, **PIT WALL 3.0**, **RACE ENGINEER 3.0** e **GRÁFICOS 9.8**.

As seis opções recalculam, na consulta, a posição de retorno estimada, o tráfego imediato e o confronto com o rival à frente, o desgaste até a entrada, a variação prevista de água, o risco de compartilhar garagem com o companheiro e a confiança qualitativa. A narração do Race Engineer deriva da alternativa selecionada.

**O simulador não emite pit requests, não agenda serviços, não modifica decisões automáticas e não injeta valores de telemetria na corrida.** Selecionar um cenário altera apenas o conteúdo visual.

## 2. Fonte de cada estimativa

| Componente | Fonte direta da simulação | Limitação assumida |
|---|---|---|
| Rejoin / posição | Progresso contínuo dos 24 carros, `last_lap`, `base_lap`, `pit_loss`, entrada a 95% da volta | Ritmo futuro congelado na última volta válida; rivais não executam paradas futuras hipotéticas |
| Desgaste na entrada | `wear` medido, observações por volta da 9.8, `advice.wear_per_lap`, `tyre_spec.cliff` | Extrapolação linear curta, não simula clima/pneu por tick |
| Clima | `weather_snapshot().wetness_factor`, previsões de água nativas em 3 e 6 voltas | Interpolação consultiva entre pontos previstos |
| Garagem | Agendamentos reais, chamada/serviço do colega, janelas do Race Engineer | Conflito potencial não é confirmação de dupla parada |
| Under/overcut | Diferença da projeção relativa ao adversário imediatamente à frente, entre cenários | Sem parada futura de rivais ou incidentes; vantagem nunca garantida |
| Confiança | Evidência de cronometração, taxa de desgaste, horizonte, tráfego, garagem e previsão de chuva | Etiqueta heurística (ALTA/MODERADA/BAIXA), não probabilidade calibrada |

## 3. Execução de corridas completas — dados observados

Teste nativo de **três corridas completas**, passo de 4,0 segundos por atualização do `RaceEngine`; configuração automática da equipe; sementes registradas no teste fonte.

| Circuito | Voltas completas | Pit stops reais (grid) | Pits da equipe | Cenários consultados | Pits comparáveis | Erro médio absoluto da posição de retorno |
|---|---:|---:|---:|---:|---:|---:|
| Silverstone (GBR) | 52/52 | 78 | 6 | 588 | 6 | 4.000 |
| Monza (ITA) | 53/53 | 24 | 2 | 604 | 2 | 2.000 |
| Singapura (SIN) | 59/59 | 96 | 8 | 666 | 8 | 4.875 |

**Total: 164 voltas, 198 pit stops reais e 1858 cenários consultados.** Foram comparadas **16** projeções de entrada imediata com a posição observada no instante do serviço: erro médio absoluto agregado de **4.19 posições**.

**Interpretação importante:** os erros (sobretudo quando vários rivais fazem pit na mesma volta) mostram que esta **v1.0 é uma comparação consultiva**, não uma previsão exata do resultado. O motor não foi calibrado para acertar todos os retornos; o painel informa riscos e incerteza. Esses erros são resultados reais do teste, não foram ocultados nem substituídos por exemplos ilustrativos.

Os relatórios JSON por circuito em `qa/06499/` incluem todas as entradas comparáveis, perdas por posição, número de cenários e contagens de alertas meteorológicos e de garagem. Como métrica, usa-se a classificação do carro observada no tick de conclusão do pit stop; não uma reconstituição futura controlada.

## 4. Integridade / regressão

A comparação SHA-256 com o ZIP de v0.6.4.9.8 constatou **1211 arquivos originais idênticos**, **somente dois arquivos originais alterados** (`project.godot` e `scripts/apex_race_hud_0622.gd`) e **zero arquivos removidos**. O código de física, Pit Lane, pneus, chuva, IA por volta, coordenação de garagem e motor de corrida está byte a byte igual ao da base.

Houve comparação determinística A/B do estado de jogo de corridas com e sem consultas ao simulador durante os primeiros 55 ticks de **cada** GP; a regressão de paridade da 9.8 também verificou 360 ticks nativos de Silverstone. Isso apoia a ausência de alteração de comportamento, sem alegar uma verificação A/B completa de todas as corridas.

| Teste de regressão | Resultado |
|---|---|
| `team_pit_06497_unit_test` | APROVADO |
| `pitwall_0649_strategy_test` | APROVADO |
| `lap_strategy_06496_auto_gate_test` | APROVADO |
| `race_0646_engineer_3_test` | APROVADO |
| `pre_race_06495_planner_test` | APROVADO |
| `dynamic_strategy_06498_data_test` | APROVADO |
| `dynamic_strategy_06498_parity_test` | APROVADO |

Testes específicos 9.9: **MODELO APROVADO** (três pistas, 6 cenários, clipping, garagem confirmada, snapshots sem alterações); **UI APROVADA** (ambos os pilotos, atalhos híbridos, seleção +3V sem pedido de pit, telas responsivas); **3 GP APROVADOS** (bandeirada, classificação validada, amostras, pits reais).

## 5. Capturas nativas reais

- `docs/APEX_06499_SIMULADOR_SILVERSTONE_1600.png` — painel inicial em **1600×900**.
- `docs/APEX_06499_SIMULADOR_SILVERSTONE_1920.png` — painel inicial em **1920×1080**.
- `docs/APEX_06499_TELEMETRIA_SILVERSTONE_1600.png` — painel após voltas reais com desgaste medido, comparação dos dois pilotos e classificação de retorno.

Estas imagens foram capturadas do viewport do **Godot 4.7.2 em execução com Xvfb/OpenGL**, não foram montadas como mockups. Os warnings de ausência de áudio/driver em ambiente virtualizado não são erros de física.

## 6. Limites e conclusão

1. As posições de retorno variam com futuros pits dos adversários, condições meteorológicas e ultrapassagens não incluídas no modelo; os níveis de confiança são qualitativos.
2. A v1.0 não deve substituir as decisões originais do Pit Wall/IA. O botão para confirmar paradas existe apenas nos painéis originais.
3. Todos os sistemas anteriores e a interface híbrida permanecem disponíveis.
4. **Nenhuma alteração da v0.6.4.9.10 foi implementada.**

**Status da entrega:** v0.6.4.9.9 integrada, importada e executada no Godot 4.7.2, com testes visuais e de corrida completos realizados e limitações documentadas.
