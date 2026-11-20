# Relatório de testes — Apex v0.6.4.9.6

**Foco único:** reavaliação de estratégia por volta concluída. Projeto Godot 4.7.2, base v0.6.4.9.5.

## Implementação

- Módulo novo `scripts/core/race_lap_reassessment_06496.gd` calcula uma análise determinística em cada volta concluída, com desgaste, vida de pneu, ritmo relativo observado, projeção de retorno aos boxes, tendência de água e janela do plano-base.
- O motor armazena a última análise e um histórico limitado a 16 voltas por piloto; a HUD Race Engineer / Pit Wall exibe a justificativa sem executar uma ordem.
- A IA automática pode mudar um pit em **uma única volta** quando encontra condições secas e seguras, desempenho relativo convincente e janela próxima; a mudança passa pelo portão original do motor e pelas demais proteções.
- Manual/Assistido são consultivos, e agendamentos V21, estado crítico, chuva instável, colega usando garagem e pit em andamento continuam protegidos.

## Validação nativa completa de quatro GPs

| Circuito | Clima | Seed | Voltas | Pilotos | Pits | Revisões por volta | Vencedor |
|---|---|---:|---:|---:|---:|---:|---|
| Silverstone | Variável | 6403 | 52/52 | 24 | 78 | 1145 | Fernando Alonso |
| Spa-Francorchamps | Chuva intensa | 6404 | 44/44 | 24 | 70 | 962 | Sebastian Vettel |
| Monza | Seco | 6405 | 53/53 | 24 | 24 | 1224 | Sebastian Vettel |
| Singapura | Variável | 6406 | 59/59 | 24 | 97 | 1295 | Sebastian Vettel |

**Total:** 4 GPs completos, 96 classificações, 269 pits, 4.626 reavaliações por volta. Os passos foram de `step(0.20)`; verificadas conclusão, classificação, desgaste e limites da pista.

Nas três corridas com arquivos originais comparáveis da v0.6.4.9.5 (Spa, Monza e Singapura), a classificação e o histórico de paradas permaneceram **idênticos**. Em Silverstone, os 78 pit stops e Fernando Alonso vencedor repetiram os números de referência; não é possível afirmar igualdade byte a byte da telemetria sem o arquivo-base integral.

**Achado relevante:** nenhuma das quatro corridas apresentou uma oportunidade que passasse todos os filtros para **ANTECIPAR** ou **ESTENDER**. Portanto, o teste de corridas completas valida a reavaliação contínua e a ausência de regressões, mas **não prova melhora no tempo de corrida**. A ação automática foi validada em cenário controlado abaixo.

## Validação do portão automático e proteções

- `lap_strategy_06496_test.gd`: PASS — pureza, undercut/overcut hipotéticos, clima, criticidade de pneus, agendamento manual V21, conflito de garagem, uma alteração por stint, histórico limitado, leitura imutável e avanço nativo.
- `lap_strategy_06496_auto_gate_test.gd`: PASS — no cenário de Silverstone, o plano-base dizia **V18** e o portão automático passou a solicitar **V17** mediante ritmo desfavorável, janela legal e ar livre; sem ordem em Manual e sem antecipar V21.
- `lap_strategy_06496_ui_test.gd`: PASS — Godot real em Xvfb com **1600×900 e 1920×1080**, 2 pilotos, revisão mostrada no Race Engineer e no Pit Wall, sem envio oculto de pit. Captura em `docs/APEX_06496_REVISAO_PITWALL_1600.png`.

## Regressões preservadas

- `race_0645_intelligence_test.gd`: PASS (IA 2.0, Soul e HUD UI03).
- `core_0622_corner_hud_smoke_test.gd`: PASS (HUD compacta).
- `pitwall_06494_confidence_test.gd`: PASS (confiança informativa).
- `double_stack_06492_entry_test.gd`: PASS (controle de fila na entrada).
- `pre_race_06495_planner_test.gd`: PASS (planejador pré-corrida).
- `staff_0648_contracts_test.gd`: PASS (contratos de Staff).
- `race_0647_soul2_test.gd`: PASS (Soul 2.0).
- `core_0639_race_engineer_test.gd`: PASS (engenheiro).
- `pitwall_0649_strategy_test.gd`: PASS (análise estratégica).

## Limitações e avisos

- Os limites de ritmo/tráfego são **heurísticas de jogo**, não dados calibrados de F1 real.
- O planejador pré-corrida continua consultivo no modo automático; a revisão apenas considera a janela viva do motor.
- Replanejamento global conjunto dos dois pilotos está reservado à **v0.6.4.9.7**; gráficos dinâmicos de desgaste, à **v0.6.4.9.8**.
- As 97 paradas de Singapura e possíveis esperas de double stack não foram corrigidas nesta versão; seu balanceamento permanece fora do escopo.
- Uma primeira importação headless do editor apresentou falha SIGSEGV durante importação de recursos; uma execução posterior do mesmo comando concluiu com **exit 0**, sem erros de script. A causa da falha transitória não foi determinada.
- Em Xvfb não havia dispositivo ALSA funcional; o Godot usou saída de áudio dummy. Não constitui teste de áudio real em Linux Mint.
- Não foi repetida a bateria consecutiva de oito GPs de carreira nesta alteração. Foram executados quatro GPs independentes completos.

## Evidências

`qa/06496/silverstone/GBR.json`, `BEL.json`, `ITA.json`, `SIN.json` (carros, stints, histórico de box, limites de pista, revisões por volta e erros).

Arquivos de testes reproduzíveis em `tests/lap_strategy_06496_*.gd`, `tests/auditoria_06496_silverstone.gd`, `tests/auditoria_06496_outros_gps.gd`. Execute com Godot 4.7.2; veja `linux/validar_06496.sh`.
