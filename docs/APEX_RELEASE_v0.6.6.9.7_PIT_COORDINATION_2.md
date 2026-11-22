# APEX Motorsport Manager v0.6.6.9.7 — Pit Coordination 2.0 (CANDIDATE)

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

**Status:** CANDIDATE / NOT_RUN antes da CI do head final. Não mesclar se evidência ausente ou `BLOCKED`. É proibido atribuir sucesso a um teste não executado.
