# APEX Motorsport Manager v0.6.6.7 — Relatório técnico

## Base auditada

- Fonte: `APEX_MOTORSPORT_MANAGER_v0.6.6.6_REPLAY_FAST_SEEK_COMPLETO.zip`.
- SHA-256 da fonte: `842ef5a563094140092c947de3cf35aee200111030f973de81ea4b15e42ce981`.
- O ZIP original passou no CRC; todos os **2469 arquivos originais** estão presentes. Somente **2 arquivos originais** mudaram, intencionalmente.
- Plataforma: Godot 4.7.2, Linux; visualização comprovada com OpenGL Compatibility / Mesa llvmpipe (software rendering).
- O plano mestre de 13/11/2026 e o changelog 0666 foram considerados como referência. Este ZIP contém o projeto completo, não um patch.

## Funcionalidade implementada: TV Director Highlights 1.0

O Diretor TV recebeu uma pequena fila de eventos de transmissão **somente de leitura**. A origem é sempre `race.events` do motor; tipos factuais aceitos: `pass`, `lead`, `pit`, `pit_exit`, `double_stack`, `pit_failure`, `unsafe_release`, `incident` e `contact`. Outros eventos, inclusive mensagens de rádio que apenas mencionam *PIT*, não são confundidos com acontecimentos visuais reais.

- Eventos críticos podem antecipar um corte comum; cenas em andamento e seleção manual conservam prioridade adequada.
- Eventos durante o hold ficam na fila até um corte elegível, respeitada a idade máxima de 50 s de relógio **simulado**.
- Fila efêmera de no máximo **8 destaques**; antirrepetição por piloto e categoria durante **15 s simulados**.
- Rewind de replay e mudança de instância de corrida limpam as âncoras editoriais, eventos pendentes e bloqueios da câmera.
- Não há gravação no replay nem edição de telemetria, RNG, física, IA ou estratégia.
- O `reason` da câmera já se integra à informação de direção existente no painel; não se criou HUD duplicada.

## Evidências concretas

- Silverstone, 3 voltas, seed 660, 24 pilotos: **1.668 ticks**; o Diretor TV exibiu **18 eventos reais únicos** e **26 mudanças de estilo de câmera**. Hash esportivo idêntico à versão anterior: `7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837`.
- Isolamento em Silverstone, chuva intensa, seed 660: **750 ticks** simulados em dois motores idênticos, com observador de câmera em apenas um. Hash, telemetria completa e estado do RNG iguais.
- Corridas completas de 3 voltas e **replays integrais por tick**, com pit stops de teste: Silverstone seca, Spa chuva intensa, Monza seca e Singapura chuva intensa. Todos os hashes históricos foram preservados (veja logs/JSONs).
- Capturas nativas de 1600×900 e 1920×1080, sem imagens sintéticas ou montagens.
- Smoke do Diretor TV anterior e regressão da câmera principal aprovados.

## Limitações e ocorrências de QA

1. A v0.6.6.7 não tem benchmark de ganho de FPS: foco é o **critério editorial da câmera**, não desempenho. Não afirmar ganho de FPS ou memória.
2. O teste histórico `pitwall_0649_ui_test.gd` não passou: as três falhas de agendamento também foram reproduzidas na **v0.6.6.6 intacta**, portanto não foram introduzidas por este patch. Além disso, headless não suporta sua captura PNG. Recomenda-se uma correção isolada futura.
3. A migração legado do Soul Staff falhou nesta execução, com erro de fixture/save e tempo limite. Sua causa não foi verificada; **não contabilizada como aprovada**.
4. O teste de integração pesada `replay_0660_integration.gd` excedeu o limite de tempo. Também não foi contabilizado como aprovado.
5. Não foi repetida a reprodução completa sequencial de Monza em 53 voltas, nem o estresse de 20 temporadas. Os testes curtos concluídos não são evidência desses cenários longos.
6. Somente o render 3D por software foi usado nesta sessão; validar futuramente também em GPU Linux/Windows.

## Matriz detalhada

- `source_zip_crc_integrity`: APROVADO — ZIP original CRC válido, 2.469 entradas; nenhum arquivo original ausente
- `source_preservation`: APROVADO — Somente project.godot e scripts/tv_director.gd alterados em relação ao ZIP v0.6.6.6
- `godot_472_import`: APROVADO — import.log: código 0, nenhum erro de parser
- `core_0627_tv_director_smoke`: APROVADO — core_0627_tv_director_smoke_test.log
- `camera_regression`: APROVADO — camera_regression_test.log
- `tv_highlights_0667_unit`: APROVADO — tv_director_highlights_0667_test.log
- `tv_highlights_0667_sport_isolation`: APROVADO — tv_director_0667_sporting_isolation.log
- `tv_highlights_0667_live_gp`: APROVADO — tv_director_0667_live_gp.log: 18 eventos reais, 26 tomadas, hash original
- `gp_GBR_dry_3laps_and_replay`: APROVADO — gp_GBR_final.log: 1.668 ticks, hash legado
- `gp_BEL_wet_3laps_and_replay`: APROVADO — gp_BEL_final.log: 2.067 ticks, hash legado
- `gp_ITA_dry_3laps_and_replay`: APROVADO — gp_ITA_final.log: 1.553 ticks, hash legado
- `gp_SIN_wet_3laps_and_replay`: APROVADO — gp_SIN_final.log: 2.050 ticks, hash legado
- `replay_boundaries`: APROVADO — replay_0660_boundaries.log: V21 com chuva na V4 protegido
- `replay_unit_speeds`: APROVADO — replay_0660_test.log: 1x/2x/5x/16x/32x
- `racecraft_0662_unit`: APROVADO — racecraft_0662_test.log: 1.027 verificações
- `driver_dynamics_0661`: APROVADO — driver_dynamics_0661_test.log
- `soul_driver_0647`: APROVADO — race_0647_soul2_test.log
- `godot_visual_1600x900`: APROVADO — visual_1600x900.log: imagem real, OpenGL Compatibility / Mesa
- `godot_visual_1920x1080`: APROVADO — visual_1920x1080.log: imagem real, OpenGL Compatibility / Mesa
- `pitwall_0649_historical_UI`: FALHA_HERDADA — pitwall_0649_ui_isolated.log: comandos de agendamento falham igualmente na v0.6.6.6; não causada pelas duas modificações 0667
- `staff_migration_0650_legacy`: INCONCLUSIVO — soul_staff_0650_migration_test.log: erro em save legado e timeout; não validado nesta execução
- `replay_0660_integration_heavy`: NÃO_CONCLUÍDO — replay_0660_integration.log: ultrapassou limite de tempo; sem PASS
- `monza53_full_sport_and_replay`: NÃO_EXECUTADO — Não repetido, física/replay não alterados
- `career_20_seasons`: NÃO_EXECUTADO — Estresse de 20 temporadas fora do escopo

## Rollback e integridade

- Manter o ZIP 0666 intacto e preferir substituição do diretório inteiro, nunca cópia por cima de uma instalação com arquivos extras.
- Como as duas únicas edições de arquivos existentes são `scripts/tv_director.gd` e `project.godot`, é possível fazer rollback substituindo ambos pelos originais 0666, mantendo os demais arquivos idênticos.
- O SHA-256 da entrega definitiva está no arquivo `.zip.sha256`.
