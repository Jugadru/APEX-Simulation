# APEX Motorsport Manager — v0.6.6.8.10.1 (candidata)

## Correção principal — Rádio do engenheiro e parada agendada

Em **RÁDIO → Vale a pena parar agora?**, a ordem explícita de parada
futura (por exemplo, **BOX V21**) tem prioridade na resposta textual
do engenheiro. Mesmo se a telemetria recomendar revisar a janela,
o rádio **não sugere uma execução imediata como ordem**: diferencia
observação, risco e comando autorizado.

- Ordem já agendada: mostrar V21 primeiro, declarar que a consulta não
  antecipa nem cancela a parada, e somente sugerir revisão se o conselho
  real indicar urgência.
- Pista com umidade observada >=38% e pneus de seco: acrescentar alerta
  contextual de aderência com dados reais do snapshot; não criar sensores.
- Chamada já feita ou parada em execução: manter precedência dessas condições.
- Sem agendamento: preservar recomendações, janela estimada e confirmação
  no controle manual conforme comportamento anterior.
- Volta agendada vencida e piloto finalizado: não apresentar a ordem como
  parada futura.

## Escopo restrito e invariantes

A alteração está somente no texto devolvido por
`scripts/core/race_engineer_interactive.gd`. O método é consultivo e
não emite comandos, não muda a IA, condições meteorológicas, física,
pneus, saves, RNG nem revisão de replay.

**Uma ordem BOX V21 não pode virar BOX V4 apenas por um aviso do rádio.**
Se o jogador quiser alterar a volta, deverá emitir outra ordem pelo
sistema de comandos já existente. Isto não é uma revisão do planejador
de estratégia e não altera o comportamento automático do Pit Wall.

## Provas exigidas antes de integrar

- Novo teste Godot `tests/radio_0668101_booked_pit_advice_test.gd`:
  urgência com V21, chuva 74%, consulta sem efeitos colaterais, box
  já solicitado, carro no pit, parada sem agendamento, previsão, ordem
  vencida e corrida encerrada.
- Integração com `RaceEngine` real em Monza 2012: agendamento V21
  mantido no snapshot, sem `pit_request` prematuro.
- O workflow Core 2 deve executar esse teste com o marcador
  `RADIO_0668101_BOOKED_PIT_PASS`, além das regressões existentes.
- Godot import, GdUnit4, replay, Pit Wall, Codacy e comparação A/B
  devem manter os respectivos resultados aprovados.

**Estado:** implementação em PR, ainda não considerar testado/aprovado
antes de inspecionar os workflows reais do SHA final.

## Compatibilidade e rollback

Sem alteração de formato de save ou replay, pois o método não escreve
estado esportivo. Reverter o commit desta correção restaura apenas a
resposta textual anterior. Não utilizar este changelog para afirmar
compatibilidade com replays históricos que já eram incompatíveis na 8.10.
