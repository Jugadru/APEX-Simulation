# v0.6.4.9.9 — Strategy Simulator 1.0

**Mudança funcional única:** nova camada de comparação consultiva de cenários de pit stop, com horizonte de **agora a +5 voltas**, para os dois pilotos.

- Reutiliza progresso e classificação da corrida, tempos de volta registrados, perda do pit lane, especificação real de pneus, desgaste e previsão de chuva do motor.
- Calcula a posição de retorno e o tráfego próximo em cada cenário. Compara o confronto com o rival real mais próximo à frente.
- Mostra risco de desgaste, instabilidade meteorológica e conflito no box compartilhado, diferenciando **ordem confirmada** de **sobreposição hipotética**.
- Fornece explicação textual do Race Engineer para cada alternativa e confiança qualitativa (não probabilidade estatística).
- Mantém janelas originais de ESTRATÉGIA, Pit Wall 3.0, Race Engineer 3.0, HUD híbrida e gráficos 9.8.
- **Proibido por desenho:** alterar física, desgaste do motor, RNG, decisão da IA, ordem automática, solicitação/agendamento de pit ou resultado da corrida.

## Arquivos modificados em relação à 9.8

- `project.godot` — somente nome e identificação de versão.
- `scripts/apex_race_hud_0622.gd` — atalhos, apresentação e atualização da janela de cenários.

Novo: `scripts/core/race_strategy_simulator_06499.gd`, testes, documentação, capturas e dados de QA. Todos os demais arquivos originais são idênticos, de acordo com SHA-256.
