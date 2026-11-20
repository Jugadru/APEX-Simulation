# APEX Motorsport Manager v0.6.4.9.6 — Reavaliação Estratégica por Volta

Base funcional: **v0.6.4.9.5 — Planejamento Estratégico Pré-Corrida**. Engine: **Godot 4.7.2**.

## Única funcionalidade principal

- Novo módulo puro `scripts/core/race_lap_reassessment_06496.gd`: ao concluir uma volta, cada piloto recebe uma avaliação atualizada de desgaste, vida estimada do pneu, ritmo real próprio e do rival à frente, proximidade, projeção instantânea de saída do pit e tendência de água em 3/6 voltas.
- Cada avaliação registra uma das recomendações: **MANTER**, **PARAR NA JANELA**, **ANTECIPAR**, **ESTENDER** ou **ORDEM PROTEGIDA**, com razão e alternativas. Histórico de até 16 revisões por piloto, sem atualizar a cada frame.
- Motor: o modo **Automático** pode antecipar ou estender em **no máximo uma volta** frente ao plano-base, somente com evidência de ritmo/tráfego e condições secas, estáveis, pneus seguros, sem reserva manual, sem pit em andamento e sem conflito de garagem. **Uma alteração por stint**.
- A decisão usa a janela do planejador já existente; não cria parada em volta arbitrária, não contorna proteção de chuva nem a histerese de compostos e não modifica `schedule_pit`, `order_pit`, física, desgaste ou IA de pilotagem.
- **Manual e Assistido** recebem apenas avaliação; não executam pit. A V21 agendada permanece protegida e só o jogador pode cancelá-la ou substituí-la.
- Painéis **Race Engineer 3.0** e **Pit Wall 3.0** mostram a última reavaliação por volta, com o motivo da decisão. Sem novos gráficos (reservados à versão posterior).
- Nome do projeto e pasta de saves independentes (`ApexMotorsportManager_PitWall_06496`).

## Não incluído

- Coordenação preventiva entre os dois pilotos antes da largada e entre janelas futuras: **v0.6.4.9.7**.
- Gráficos dinâmicos de curvas de desgaste e previsão de stints durante a corrida: **v0.6.4.9.8**.
- Nenhuma mudança nas regras climáticas, cálculo de pneu, custo de pit, física, carreira ou contratos.
- As projeções são heurísticas simuladas e não garantem a posição pós-parada; corrida real, tráfego futuro e mudanças climáticas podem variar.

## Arquivos de produção

- NOVO: `scripts/core/race_lap_reassessment_06496.gd`
- ALTERADO: `scripts/race_engine.gd` (registro por volta + portão de decisão automática)
- ALTERADO: `scripts/apex_race_hud_0622.gd` (exibição textual de revisão)
- ALTERADO: `project.godot` (versão e saves isolados)

Testes específicos e relatório: `tests/lap_strategy_06496_*.gd`, `RELATORIO_TESTES_06496.md`.
