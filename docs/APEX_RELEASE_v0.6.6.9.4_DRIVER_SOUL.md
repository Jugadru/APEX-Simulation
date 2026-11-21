# APEX v0.6.6.9.4 — Driver Soul 3.0 (candidata)

Base: `main` v0.6.6.9.3, commit `53c0adf0da87a93e4b79c8a2c240c063b7c201f2`.

## Escopo esportivo

- Aproveita Soul 2.0, incluindo emoções, confiança, pressão, moral, sensação de desgaste, pedidos fundamentados e respostas sem mudanças automáticas de box.
- A nova avaliação `race_driver_soul_06694.gd` define intenção de pilotagem por **volta concluída** (atacar, gerir pneus, cautela ou manter). Sem RNG, sem velocidade inventada.
- `race_driver_dynamics_0661.gd` usa a sensação do piloto e seu foco para ajustar **somente o limiar de comprometimento com ultrapassagens**, nunca grip, velocidade ou tempo direto.
- Solicitações contextualizadas pelo Soul 2.0 são registradas uma vez como rádio fictício; HUD aproveita o histórico existente sem duplicação de mensagens.
- Controles IA/manual, pit stops agendados (ex.: V21), ordens de equipe e lógica 3D continuam com o motor original.
- Novos replays usam a revisão `017_driver_soul_v1`; replays 016 (v9.3) e anteriores usam as próprias regras antigas. Os controles de compatibilidade são excluídos dos snapshots esportivos.

## Critérios para integrar

| Teste | Estado |
|---|---|
| Godot 4.7.2 importa/compila | PENDENTE |
| Driver Soul 3.0: limiar, rádio factual, nenhuma ordem escondida | PENDENTE |
| Replay 017 e replay histórico 016 sem divergência | PENDENTE |
| Driver Traffic 9.3, Driver Dynamics 0661 e Soul 2.0 regressões | PENDENTE |
| Quality Gate e demais workflows | PENDENTE |
| SaveGuard histórico, Silverstone / 20 pistas e Monza integral 53 voltas | PENDENTE |
| Exportação Windows/Linux e identificação real do PCK | PENDENTE |
| A/B CPU contra a v9.3, sem alegar ganho sem medir | PENDENTE |

**Não mesclar nem publicar como estável sem evidências finais.** A investigação de 32× sustentados continua separada na issue #74. A implementação é uma simulação ficcional de traços de pilotos; não reproduz personalidades reais nem usa áudio histórico da F1.
