# APEX Motorsport Manager v0.6.6.9.7 — Pit Coordination 2.0 (INTEGRADA À MAIN)

**Base imutável:** v0.6.6.9.6 em `main`, commit `917cba8e0df38861fb8f43bb8a4b9249cfea2a99`.
**Uma funcionalidade principal:** coordenação operacional de garagem compartilhada, double stack e liberação de segurança.

## Comportamento da corrida

- A antiga estratégia preventiva em `race_team_pit_coordination_06497.gd` permanece intacta; a novidade pertence à **fila física no pit lane**.
- `race_pit_coordination_06697.gd` calcula quem chega primeiro ao ponto de serviço pelo tempo de entrada `pit_entered_at` e duração da fase de aproximação `pit_nominal_total * PIT_QUEUE_PHASE`. Empates têm desempate pelo ID fixo do carro, não pela ordem do array de carros.
- Somente carros que já alcançaram a garagem podem concorrer; quem está em `approach` pode participar no mesmo tick se o instante previsto de chegada já ocorreu, impedindo que a ordem de execução conceda acesso injusto.
- O pit continua usando **uma única equipe de mecânicos por garagem**. A fila conserva seu tempo real `pit_wait`, incluindo atrasos causados pelo atendimento ou retenção de segurança do companheiro. Nenhum tempo, composto, incidente ou risco foi inventado.
- A liberação continua sendo regida pelo fluxo homologado `dock → service → repair/safety_hold → exit`; não existem retenções mágicas adicionais por tráfego. O novo painel exibe etapa do proprietário, retenção de segurança factual, posição FIFO na fila e **estimativa conservadora** de tempo adicional. A estimativa não é promessa de duração nem nova regra esportiva.
- Controle Manual, Assistido, IA, agendamento V21 e cancelamentos não são modificados. Conflitos continuam visíveis, sem substituir uma ordem manual por comando automático.

## Replay e compatibilidade

A ordenação FIFO pode alterar resultados esportivos de um double stack simultâneo. Por isso a nova revisão de simulação é `018_pit_coordination_v1`. Replays `017_driver_soul_v1` usam exatamente a regra anterior por meio do sinalizador **de sessão** `pit_coordination2_enabled=false` (fora dos checkpoints e hashes), preservando replay antigo. O codec permanece com `SCHEMA=1` e não altera o formato do save.

## Testes de aprovação obrigatórios

- FIFO com prioridade cronológica, desempate estável e independência da ordem de armazenamento
- Garagem ocupada, retenção de segurança, fila e medidas reais de espera
- Integridade de pit e posição após os pits, histórico 9.6 e HUD existente
- Agendamento manual V21 não executado na V4, mesmo em chuva e com coordenador ativo
- Determinismo: mesma semente + mesmas ordens + mesmos ticks gera hash esportivo idêntico
- Replay `017` e `018`, compatibilidade SaveGuard e regressões do Core 2
- Monza 53 voltas, 20 circuitos, benchmarking, Linux/Windows e Quality Gate READY

**Status final:** `RELEASE INTEGRADA`. A [PR #81](https://github.com/Jugadru/APEX-Simulation/pull/81) foi mesclada na `main` no commit `6c6560bd36f2eecda82cf7959b884464054bc03c`, sem descartar critérios de validação. Cabeça candidata testada: `689aaf7522002a3d8c385dd70a1ac5eb8b07f851`.

## Evidências de liberação

- **20/20 workflows PASS** no commit candidato. [Ver checks](https://github.com/Jugadru/APEX-Simulation/commit/689aaf7522002a3d8c385dd70a1ac5eb8b07f851/checks).
- **Quality Gate READY 10/10**, auditado novamente após conclusão de todos os testes, [workflow 44973100063](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100063). O primeiro relatório `BLOCKED 6/10` era um diagnóstico legítimo de evidências ainda pendentes e não foi aceito como aprovação.
- Teste dedicado [Pit Coordination 2.0](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100021) **PASS, 41 verificações**. Inclui FIFO e desempate independente de array, garagem exclusiva, retenção de segurança, espera real, V21 e reprodução da revisão 017; regressões das versões 9.6 e 9.4 incluídas.
- **SaveGuard 53 verificações PASS**, replays cross-revision, arquivos de carreira e garage originais imutáveis. [Workflow](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100160).
- **Matriz de 20 circuitos 4/4 grupos PASS**, [workflow](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100015).
- **Monza 53 voltas** com **24.229 ticks**, replay esportivo integral com hash idêntico (`715912b4a7413c3cbdbd83a133d646a80a622b94077223f465ab28e10fc895a2`), teste longo PASS e provas repetidas em Itália e Silverstone. [Workflow](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100029).
- Exportação Linux/Windows **PASS**, smoke Linux e artefato [temporário](https://github.com/Jugadru/APEX-Simulation/actions/runs/44973100017/artifacts/14734451599), previsto até 06/12/2026; benchmark headless não equivale a FPS 3D nativo do PC do jogador.

## Questão em acompanhamento

O Pit Wall Intelligence Analyzer aprovou 4 cenários e 8 execuções (determinismo confirmado), porém emitiu 7 **REVIEW / PIT_QUEUE** para esperas observadas de 3,16 a 8,23 s. Não são falhas de CI; as causas de filas evitáveis pela IA ainda precisam ser investigadas. Registro aberto na [issue #82](https://github.com/Jugadru/APEX-Simulation/issues/82). A v9.7 não promete eliminar todos os double stacks nem alterar janelas manuais.

## Rollback

A alteração foi integrada com squash no commit `6c6560bd36f2eecda82cf7959b884464054bc03c`. Se houver regressão esportiva comprovada, realizar `git revert 6c6560bd36f2eecda82cf7959b884464054bc03c` numa branch corretiva e abrir nova PR com regressões; não apagar o histórico da `main`.
