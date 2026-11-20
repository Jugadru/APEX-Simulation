# Relatório técnico — APEX v0.6.4.9.2, Double Stack

**Data:** 09/11/2026  
**Base:** ZIP completo 0.6.4.9.1; Godot 4.7.2  
**Escopo:** uma correção funcional, coordenação de dois carros no mesmo box.

## 1. Defeito e correção aplicada

Uma chamada de box automática normal, feita antes da entrada, podia encontrar a garagem ocupada quando o piloto chegava, provocando espera desnecessária em circunstâncias de pneus seguros. A correção estima a ocupação **até a liberação real da garagem** e reavalia o segundo carro imediatamente antes da entrada do pit lane. Só permite continuar na pista se a espera estimada for de pelo menos 2,5s, o desgaste for <60%, a vida do pneu for ≥3 voltas, a pista e a previsão estiverem secas e não houver ordem agendada, emergência ou adiamento anterior no mesmo stint.

Cenário de teste: Silverstone, dois pilotos Ferrari, seed 6403, pista seca, desgaste de 35% e duas chamadas de IA pré-autorizadas na aproximação da entrada.

| Medida | v0.6.4.9.1 | v0.6.4.9.2 |
|---|---:|---:|
| Primeira entrada no box | sim | sim |
| Segundo piloto entra imediatamente | sim | não |
| Espera do segundo piloto nesse instante | 7,4 s | 0,0 s |
| Marca de adiamento no segundo carro | não | sim |

Não há mágica de tempo: a segunda parada é **reavaliada na volta seguinte**, não realizada de graça. O motor preserva a sequência de entrada, espera, serviço, liberação e saída para qualquer parada que ocorra.

Testes específicos conferiram que a liberação da garagem durante o estágio de saída não provoca adiamento, que serviços prestes a terminar não geram previsão falsa e que pit manual/urgente passa mesmo com fila. V21 continua sendo uma ordem protegida.

## 2. GP Silverstone completo (comparação fixa)

| Indicador | v0.6.4.9.1 | v0.6.4.9.2 |
|---|---:|---:|
| Voltas | 52 | 52 |
| Pilotos classificados | 24 | 24 |
| Passos de 0,20s | 26600 | 26600 |
| Pit stops | 90 | 90 |
| Vencedor | Fernando Alonso | Fernando Alonso |
| Eventos idênticos | — | True |
| Histórico de paradas idêntico | — | True |

**Clima:** Variável; **seed:** 6403; **circuito:** GBR. GP concluído (código de saída 0, classificação validada, pneus e pista dentro dos limites do ensaio).

As três filas ainda ocorreram nesta corrida: Felipe Massa (1,11s, V14), Kamui Kobayashi (6,64s, V14) e Jean-Eric Vergne (7,27s, V14). Nenhum novo adiamento por fila foi acionado nesse GP. **Não afirmamos redução de filas na corrida completa**; o ganho demonstrado foi no ensaio controlado de pista seca. Em mudança de condição climática ou com risco de pneus, o sistema preserva a parada em vez de trocar a segurança por uma volta adicional.

O total de 90 paradas **não** foi recalibrado: isso será tema exclusivo da v0.6.4.9.3.

## 3. Regressões de sistemas

18 testes aprovados, com evidência individual em `qa/06492/regression_logs/`:

- `double_stack_06492_entry_test`: **PASS**.
- `double_stack_single_smoke_test`: **PASS**.
- `pitwall_06491_stint_reset_test`: **PASS**.
- `pitwall_0649_strategy_test`: **PASS**.
- `pitwall_0649_ui_test`: **PASS**.
- `race_0645_intelligence_test`: **PASS**.
- `race_0646_engineer_3_test`: **PASS**.
- `race_0647_soul2_test`: **PASS**.
- `race_0647_soul2_ui_test`: **PASS**.
- `staff_0648_contracts_test`: **PASS**.
- `staff_0648_career_integration_test`: **PASS**.
- `staff_0648_ui_test`: **PASS**.
- `core_0640_pitwall_intelligence_test`: **PASS**.
- `core_0635_soul_stint_smoke_test`: **PASS**.
- `core_0642_save_migration_test`: **PASS**.
- `core_0622_corner_hud_smoke_test`: **PASS**.
- `track_0644_hud_integration_test`: **PASS**.
- `pit_lane_regression_test`: **PASS**.

Os testes visuais foram executados com Xvfb/Mesa, pois renderizações de tela sob `--headless` podem gerar erro de screenshot mesmo quando a lógica passa. O ambiente de Xvfb não disponibilizou dispositivo de áudio real (ALSA dummy); não é erro do Race Engine.

**Limitação herdada:** `double_stack_smoke_test.gd` e `pit_incidents_double_stack_test.gd` falharam nas versões anterior e atual por asserções de sobreposição de paradas em cenário legado. Não fazem parte dos 18 testes PASS. Logs/descritivo em `qa/06492/TESTES_LEGADOS_NAO_APROVADOS.md`.

## 4. Arquivos e preservação

Modificados: `scripts/race_engine.gd` (apenas gate de pré-entrada) e `project.godot` (identificação/saves). Adicionado `scripts/core/race_double_stack_coordinator_06492.gd`; testes e documentação são novos. Os demais scripts funcionais, pit lane, fórmulas de pneus, física, clima, Staff, rádio, Soul, engenharia e HUD permaneceram idênticos aos da v0.6.4.9.1.

**Não realizado:** bateria de 8 GPs, temporada completa, testes de performance em GPU de produção, validação de todos os climas e de todas as seeds. A execução do GP completo foi feita no motor nativo `sim.step(0.20)` sem visualização 3D; testes de UI separados.

## 5. Próximas versões (não incluídas)

- 0.6.4.9.3: investigar/rebalancear frequência de pit stops usando múltiplas condições e seeds.
- 0.6.4.9.4: melhorar a qualidade do indicador qualitativo de confiança estratégica.

Recomendação: preservar a 0.6.4.9.1 e experimentar a 0.6.4.9.2 isoladamente antes de avançar.
