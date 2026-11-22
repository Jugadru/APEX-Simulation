# APEX v0.6.6.9.5 — Race Radio 3.0 (CANDIDATA)

**Base:** `main` v0.6.6.9.4 Driver Soul 3.0. **Regra:** não mesclar antes dos gates.
**Escopo:** rádio textual e apresentação, sem mudanças esportivas.

## Objetivo

Remover a linguagem longa e coloquial dos pilotos. As falas escritas de rádio
são curtas, originais, diferenciadas por perfil fictício e apoiadas em observações
ou pedidos **já confirmados** do motor. Ex.: uma parada V21 pré-existente pode
ser questionada pelo piloto, mas nunca criada ou antecipada pela fala.

## Contratos e responsabilidades

- `scripts/presentation/race_radio_06695.gd`: biblioteca offline e determinística
  de intenções, cinco estilos por identidade estável, emoção observada do Soul3,
  resposta técnica curta, histórico de conversa limitado a oito entradas,
  silêncio de mensagens não essenciais repetidas e pacotes estruturados.
- `scripts/apex_commentary.gd`: traduz eventos `driver_radio`/
  `engineer_reply` conhecidos para falas contextualizadas; para pedidos
  Soul3 adiciona uma **resposta meramente visual** do engenheiro. Não inventa
  telemetria ou uma ordem; eventos desconhecidos continuam inalterados.
- `scripts/apex_race_hud_0622.gd`: usa os mesmos perfis para toast,
  pedidos Soul2/Soul3, comentários espontâneos, consulta ao piloto, discussão
  de stint e respostas do piloto. O Race Engineer mantém sua análise
  estruturada em português; as novas falas de cockpit começam em inglês.
- `tests/race_radio_06695_test.gd`: testes de pureza, cinco vozes,
  contextos, compatibilidade de V21, memória, privacidade do rádio e integração
  com evento real do motor.
- `.github/workflows/apex-race-radio-ci.yml`: testes no Godot 4.7.2,
  regressões Soul3/Soul2 e reatividade do rádio.
- `project.godot`: identifica a candidata 9.5 sem publicar nova release.

## Pacotes de mensagem / futuro áudio

`{event_id, speaker_id, speaker_role, intent, emotion, intensity, text_key,
locale, text, subtitle_pt, voice_profile_id, simulation_tick, conversation_id,
priority, style}`.

`voice_profile_id` fica vazio e `subtitle_pt` aguarda localização editorial.
Nenhum áudio, serviço de LLM, imitação de voz ou citação histórica é usado.

## Invariantes

1. O compositor lê um snapshot do piloto, sem escrever em carro, RNG, física,
   estratégia, pneu, posição ou tempo.
2. Replays 017 e anteriores preservam seus hashes esportivos, sem nova
   `simulation_revision` ou alterações no codec de corrida.
3. A memória textual é só apresentação e é zerada a cada GP, não salva na carreira.
4. Recomendações e respostas não equivalem a `order_pit`, `schedule_pit`
   ou `authorize_team_yield`.
5. Mensagens privadas não vazam para a transmissão pública.
6. Uma mensagem de origem não reconhecida mantém seu texto antigo;
   a inferência não pode fabricar incidentes, falhas ou sensores.

## Estado da QA

**CANDIDATE / NOT_RUN ao criar a PR.** Executar ações do GitHub, testes nativos
do Godot, Soul3, Soul2, replay, Pit Wall, SaveGuard, GdUnit4 e visual antes do merge.
Somente marcar PASS com workflow e commit exatos. Este documento não é
certificado de liberação.

## Rollback

`main` permanece na 9.4 até Quality Gate READY real. Referência da base:
`6b4d96ecfa591da294f5d3058b7756aa122340d7`.
Issue #74 (32x sustentado) e issue #77 (dessincronização visual) permanecem
fora do escopo desta atualização.
