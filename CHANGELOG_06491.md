# v0.6.4.9.1 — Correção única: memória de adiamento de pit

- **Corrigido:** flag `pitwall49_held` rearmada após troca **real** de pneus (`race_engine.gd::_finish_service`).
- **Preservado:** bloqueio de segundo adiamento no mesmo stint; chuva crítica; ordem manual V21; lógica original de duplo serviço, clima, física, rádio, Staff, Soul e HUD.
- **Novo:** teste específico `pitwall_06491_stint_reset_test.gd`, teste nativo Silverstone 52 voltas e relatório de regressão.
- **Projeto:** nome da versão e save em diretório próprio.
- **Não abordado:** fila de double stack (0.6.4.9.2), frequência de pit stops (0.6.4.9.3) e confiança do engenheiro (0.6.4.9.4).
