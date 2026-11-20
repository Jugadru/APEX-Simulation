# Relatório técnico — v0.6.4.9.5

**Objeto:** validação isolada do novo planejador pré-corrida, com base imutável v0.6.4.9.4.

## Silverstone — pré-largada, Ferrari, seed 6403, cenário seco

| Piloto | Projeção calculada | Primeira parada prevista |
|---|---|---|
| Fernando Alonso | Macio 16v → Duro 20v → Macio 16v | V16 → Duro |
| Felipe Massa | Macio 17v → Macio 15v → Duro 20v | V17 → Macio |

As curvas de desgaste são estimativas de um modelo simplificado, não medições. O segundo plano sofreu deslocamento de +1 volta na primeira janela para evitar sobreposição com Alonso; o ajuste estimado ficou dentro da tolerância de 4s e conservou os limites de desgaste.

## Validações

- Godot 4.7.2 import headless: **exit 0**, sem erros de parser.
- Novo teste de otimizador: **exit 0**, 2 pilotos, 52 voltas por plano, dois pneus nomeados, wear projetado até 86%, previsão sem modificar o estado real, largada molhada desabilita agendamento seco.
- Novo teste de menu renderizado (Xvfb, 1600×900 / 1920×1080): **exit 0**, gráficos, menu, confirmação do jogador, duas ordens no início do GP, dados invalidados se a seed for alterada, proteção do modo automático.
- Corrida nativa até V5: **exit 0**, 1.899 ticks de 0,20s, ambas reservas futuras preservadas, nenhuma chamada de pit antecipada.
- Corrida nativa até V21: **PASS gravado no log**, 9.542 ticks de 0,20s, dois pits efetivos em **V16 e V17** com compostos previstos. O processo executor externo excedeu o prazo total de encerramento, de modo que **não** se dispõe de status final de execução nesse ensaio longo.
- 11 regressões originais: todas com **exit 0** — `pitwall_06494_confidence_test`, `pit_balance_06493_threshold_test`, `pitwall_06491_stint_reset_test`, `double_stack_06492_entry_test`, `race_0645_intelligence_test`, `core_0622_corner_hud_smoke_test`, `race_0647_soul2_test`, `staff_0648_contracts_test`, `track_0644_native_tick_smoke_test`, `pitwall_0649_strategy_test`, `staff_0648_career_integration_test`.

## Preservação e riscos

- Os 4 sistemas de correção 0.6.4.9.1–.4 foram preservados; nenhuma regra de pits do motor ou equilíbrio de pneus foi alterada.
- A tela não altera decisões automáticas. Apenas a confirmação MANUAL de duas primeiras paradas pode modificar a estratégia real.
- Os planos são provisórios e **não respondem automaticamente a mudanças meteorológicas e de tráfego**. Caso escolha agendar a primeira parada, o jogador precisará revisar o plano em caso de chuva.
- Não foi realizada validação de 52 voltas inteiras ou bateria de oito corridas para esta versão. Teste nativo integral da temporada não está aprovado.
- Xvfb dependeu de software render/driver de áudio dummy; áudio e FPS numa GPU real não foram avaliados.
- Planos são estimados sem prever adversários; a qualidade estratégica será ampliada incrementalmente.

## Próxima versão

v0.6.4.9.6: reanálise por volta com replanejamento (sem confundir este trabalho de pré-largada com os sistemas seguintes).
