# Apex Motorsport Manager v0.6.3.5 — Apex Soul Driver: Discussão de Stint

Data: 07/11/2026. Base preservada: v0.6.3.4, Godot 4.7.2.

## Implementado

- Novo botão **DISCUTIR STINT** na janela de rádio, sem criar uma segunda janela.
- Resposta subjetiva ficcional do piloto, seguida de avaliação técnica do engenheiro usando o estado de corrida (pneus, desgaste, temperatura, pista, volta, projeção e box agendado).
- Divergências possíveis quando o piloto acredita que ainda pode continuar, mas a avaliação técnica sinaliza risco. Nenhuma fala constitui atributo psicológico factual do piloto histórico.
- Uma conversa repetida em menos de 60 segundos simulados, sem alteração relevante de dados, não aumenta o histórico.
- Histórico preserva os filtros TODOS, TRANSMISSÃO, EQUIPE e PILOTOS e o filtro por piloto.
- Ao iniciar outro GP, a memória da discussão é reiniciada.
- A discussão não envia ordens, não altera estratégia, pneus, tempo ou posições.

## Arquivos de código alterados

- `scripts/apex_race_hud_0622.gd`: botão, diálogo, memória de consulta e reinício.
- `scripts/apex_commentary.gd`: evento de diálogo interno CHEFE/PILOTO/ENGENHEIRO.
- `scripts/core/race_stint_dialogue_0635.gd`: novo mecanismo consultivo e determinístico, sem RNG.
- `project.godot`: nome/versão.
- `tests/core_0635_soul_stint_smoke_test.gd` e `tests/native_capture_0635.gd`: novos testes.

## Preservação

O código do motor da corrida (`scripts/race_engine.gd`), simulação, IA, HUD de classificação, câmera 3D, circuitos, calendário e pneus **não foi alterado** nesta atualização.

## Limitações

- As preferências dos pilotos são **ficcionais**, calculadas por regras simples; ainda não existe um sistema de personalidade de carreira persistente.
- Engenheiro interpreta dados já existentes; não simula previsão probabilística nova.
- A decisão do jogador e a IA de boxes seguem as permissões existentes, separadas do rádio.
- A corrida inteira ainda não foi validada nesta entrega.
