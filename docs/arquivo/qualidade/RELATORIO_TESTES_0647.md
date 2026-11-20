# Relatório de testes — Apex Soul Driver 2.0 v0.6.4.7

**Motor:** Godot 4.7.2 Linux, renderer headless e Xvfb/Mesa (somente teste de render).
**Base:** Apex v0.6.4.6 Race Engineer 3.0 + HUD híbrida.

## Ensaios efetuados
- `tests/race_0647_soul2_test.gd`: **PASS** (2.0s). SOUL2_PASS deterministic, radio requests, protected V21, team-order request, morale, engine native lap
- `tests/race_0646_engineer_3_test.gd`: **PASS** (2.8s). RE3_0646_PASS: pure planning, staff horizon, rain 83, V21, double stack, 4 radios, UI, manual pit, 0.20 native
- `tests/race_0645_intelligence_test.gd`: **PASS** (5.9s). APEX_0645_PASS strategy, guards, soul, RNG, native ticks, manual V21, HUD UI03
- `tests/track_0644_hud_integration_test.gd`: **PASS** (2.5s). APEX_0644_HUD_PASS: scene, PNEUS panel, thermal data, HUD, weather, 2 player cars
- `tests/core_0637_reactive_radio_smoke_test.gd`: **PASS** (2.2s). APEX 0637 PASS: event, incident, wear, rain, duel, cooldown, privacy, reset, immutable race, HUD
- `tests/core_0636_soul_personality_smoke_test.gd`: **PASS** (6.3s). APEX 0636 PASS: personality, subjective wear, trust, confidence, memory, UI, filters, immutable race
- `tests/core_0635_soul_stint_smoke_test.gd`: **PASS** (4.1s). APEX 0635 PASS: subjective pilot strategy, engineer divergence, no commands, filter, cooldown, reset, HUD
- `tests/core_0622_corner_hud_smoke_test.gd`: **PASS** (6.4s). 
- `tests/race_0647_soul2_ui_test.gd` (Xvfb, Mesa/OpenGL): **PASS**; renderização de 1600×900, posicionamento testado também em 1920×1080, rádio, resposta, V21 e Engineer 3.0.
- `tests/race_0647_one_gp_native.gd -- --code BEL`: **NÃO CONCLUÍDO** (interrompido antes de obter `GP_PASS`; não conta como validação).

## Garantias verificadas

- Perfil determinístico e distinto por piloto, sem consumir o RNG da corrida.
- Atualização após cruzar uma volta em `step(0.20)` sem a interface ativa.
- Em chuva 83% com box V21 agendado, a mensagem solicita *revisão*, mas **não antecipa** a parada.
- Ao reconhecer/explicar um pedido do piloto, altera apenas confiança e moral na memória fictícia; não executa ordens de pit ou ritmo.
- Pedido de avaliação de troca de posições não faz ultrapassagem forçada.
- Regressões de Race Engineer 3.0, Race Intelligence 2.0, pneus e rádio antigo mantidas.

## Limites de validação

- **Sem validação concluída de um GP inteiro** para v0.6.4.7. A execução headless de BEL em 0,20 s foi iniciada e interrompida antes do resultado. Uma bateria completa de oito GPs **não foi executada**.
- Renderização Mesa software não é benchmark de FPS em GPU de usuário.
- A personalidade é um sistema ficcional de **comunicação e decisões consultivas**, não um multiplicador físico de habilidade e não executa estratégias.
- A simulação mantém a lógica de desgaste, clima, pit e tempos da v0.6.4.6; só o callback do motor que recebe o evento de volta foi atualizado.

## Evidências

- `qa/0647/*.log` contém logs dos testes headless.
- `docs/APEX_SOUL2_RADIO_REAL.png` e `docs/APEX_SOUL2_ENGENHEIRO_REAL.png` são capturas do Godot, não imagens conceituais.
- Manifesto `BUILD_MANIFEST_0647.json` traz os SHA-256 dos arquivos e a lista de mudanças.
