# Relatório técnico — Apex Motorsport Manager v0.6.4.9.1

**Correção única:** memória de adiamento automático de pit stop entre stints.  
**Data:** 09/11/2026. **Engine executado:** Godot 4.7.2 stable oficial (Linux, headless e testes de interface via Xvfb/Mesa).  
**Base:** ZIP completo v0.6.4.9 — Pit Wall & Estratégia 3.0.

## 1. Causa e correção

**Causa confirmada na v0.6.4.9:** `_request_ai_pit` escreve `car["pitwall49_held"] = true` quando uma análise autoriza segurar o carro por uma volta para evitar double stack. O código do planejador recusa um novo adiamento quando o valor está `true`, mas a base anterior não limpava essa marca após a troca real de pneus. Resultado: uma única postergação bloqueava todas as posteriores no GP, mesmo após novo stint.

**Mudança de produção:** somente em `scripts/race_engine.gd`, dentro de `_finish_service`, logo após `car["stint_laps"] = 0`:

```gdscript
# v0.6.4.9.1: allow at most one automatic double-stack hold per stint.
# Rearm ONLY after genuine tyre service, not when a pit is requested,
# scheduled or entered, so repeated evaluations cannot re-defer it.
car["pitwall49_held"] = false
```

A marca é restaurada somente após pneus instalados, em vez de ser redefinida prematuramente quando o carro entra ou agenda parada. A proteção de um adiamento por stint continua na `race_pitwall_strategy_0649.gd`, **que não foi alterada**. Mudança adicional de configuração: `project.godot` apenas renomeia a variante e isola os saves (`ApexMotorsportManager_PitWall_06491`).

## 2. Reprodução antes/depois

- **Base 0.6.4.9 original:** o teste novo falhou como esperado em `hold cleared after tyre service` e `new stint permits a fresh hold` (código de saída 1). Registro: `qa/06491/OLD_0649_BUG_REPRO.log`.
- **Nova 0.6.4.9.1:** o mesmo fluxo passou: adiamento permitido uma vez, bloqueado no mesmo stint; início da parada não remove a marca; serviço real de pneus remove a marca; no segundo stint o novo adiamento seguro volta a ser permitido, mas apenas uma vez. Ordem manual V21 mantida. Registro: `qa/06491/pitwall_06491_stint_reset_test.log`.

O teste usa piloto e garagem do motor de corrida real em Silverstone, com cenário controlado de stints. Não deduz que o cenário da corrida-base deveria obrigatoriamente gerar adiantamentos estratégicos.

## 3. Silverstone — GP completo de referência

| Indicador | v0.6.4.9 | v0.6.4.9.1 |
|---|---:|---:|
| Circuito | Silverstone/GBR | Silverstone/GBR |
| Seed | 6403 | 6403 |
| Clima | Variável | Variável |
| Voltas | 52 | 52 |
| Pilotos classificados | 24 | 24 |
| Passos de 0,20 s | 26.600 | 26.600 |
| Pit stops | 90 | 90 |
| Vencedor | Fernando Alonso | Fernando Alonso |
| Eventos do motor | 1.408 | 1.408 |

**Comparação de conteúdo:** histórico de pit stops: **idêntico**; eventos: **idênticos**; telemetria de voltas: **idêntica**; estados finais dos 24 pilotos: idênticos **exceto** pelo novo atributo `pitwall49_held = false` gravado após cada serviço. Classificação, clima e tempos preservados. Essa coincidência mostra que a correção isolada não perturbou o cenário do GP automático de referência; não representa um reequilíbrio de estratégia.

Arquivo bruto: `qa/06491/native_020/GBR.json` (24 carros, eventos, voltas, pit history). Classificação: `qa/06491/SILVERSTONE_06491_CLASSIFICACAO.csv`.

## 4. Regressões

**15 testes PASS**, além do GP nativo de Silverstone:

- `pitwall_06491_stint_reset_test`: PASS
- `pitwall_0649_strategy_test`: PASS
- `race_0645_intelligence_test`: PASS
- `race_0646_engineer_3_test`: PASS
- `race_0647_soul2_test`: PASS
- `staff_0648_contracts_test`: PASS
- `staff_0648_career_integration_test`: PASS
- `core_0640_pitwall_intelligence_test`: PASS
- `core_0635_soul_stint_smoke_test`: PASS
- `core_0642_save_migration_test`: PASS
- `core_0622_corner_hud_smoke_test`: PASS
- `track_0644_hud_integration_test`: PASS
- `pitwall_0649_ui_test`: PASS
- `race_0647_soul2_ui_test`: PASS
- `staff_0648_ui_test`: PASS

Os ensaios cobriram: Pit Wall 3.0 e HUD, Race Engineer 3.0, Soul Driver 2.0, Staff e contratos, continuidade dos saves, pneus, regras de box e controles da HUD. A UI foi testada em display virtual (Xvfb), não em GPU física do jogador.

## 5. Não alterado / riscos pendentes

- **v0.6.4.9.2 (futura):** coordenação e filas double stack. Nesta execução houve 3 esperas, exatamente como na 0.6.4.9, portanto este problema **não foi corrigido** nesta versão.
- **v0.6.4.9.3 (futura):** frequência/balanceamento de pit stops (90 no GP de referência).
- **v0.6.4.9.4 (futura):** confiança estratégica BAIXA/MODERADA/ALTA.
- IA, pneus, simulação térmica, clima, pit lane, motores de Staff/Soul e cálculos de cronometragem foram preservados.
- Não foi reexecutada bateria de 8 GPs consecutivos ou temporada completa nesta entrega. Foi reexecutado **1 GP completo em passo nativo 0,20 s** e 15 testes de regressão; isso limita o alcance das conclusões.

## 6. Recomendações

Aprovar a 0.6.4.9.1 como correção específica, guardar o ZIP e o relatório; na v0.6.4.9.2 atacar exclusivamente a coordenação entre companheiros, comparando os dados desta mesma corrida com idêntica seed e clima.
