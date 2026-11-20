# Changelog — v0.6.4.9.7

**Foco único:** coordenação preventiva de duas janelas de pit simultâneas no modo automático.

Mudou:
- `scripts/race_engine.gd`: aplicação conservadora de desvio de uma volta antes da entrada de pit, com eventos e limite por stint.
- `scripts/core/race_team_pit_coordination_06497.gd` (novo): avaliação determinística, sem mutação de dados, da equipe e da prioridade de garagem.
- `scripts/apex_race_hud_0622.gd`: justificativa textual nos painéis do engenheiro e Pit Wall.
- `project.godot`: nome e diretório de saves isolados.
- Testes, scripts de validação, logs e documentação.

Não mudou: física, circuito, pneus, dados de 2012, clima, cronometragem, incidentes do pit, IA por volta 0.6.4.9.6, controle manual, ordens V21, preço/Staff, câmera e parâmetros de desgaste.

Observação: a prevenção é limitada a **pista seca e cenário elegível**. Uma condição crítica pode justificar double stack real, e a atualização não o proíbe.
