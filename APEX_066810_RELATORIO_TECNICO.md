# APEX Motorsport Manager v0.6.6.8.10 — Ordens de Equipe 1.0

## Escopo
Base v0.6.6.8.9, Godot 4.7.2, motor oficial **Core 2**. A APEX Next Engine permanece suspensa.

## Implementação
1. `RaceEngine.team_yield_eligible` aceita apenas companheiros da equipe do jogador, posições adjacentes, duas voltas de vantagem medida, distância até 1,5s, pneus/aderência adequados e pit inativo. Usa o avaliador consultivo de v8.9.
2. O jogador clica **RÁDIO > AUTORIZAR NÃO DEFENDER**, gerando `authorize_team_yield(leader_id, chasing_id)`. O Replay enfileira o comando para o tick seguinte e atribui ao líder `team_yield_to_id` e `team_yield_ticks` (75 ticks = até 15 segundos).
3. O solver `RaceSpace.plan` suprime **apenas a tentativa antecipada de bloqueio agressivo** contra o companheiro indicado. Mantém as travas de linha, largura de pista, ocupação do corredor, julgamento de ultrapassagem, velocidades e regras de segurança. A passagem não é garantida.
4. `cancel_team_yield` também é comando de replay, e a autorização expira se o companheiro passar, terminar ou após a janela de tempo. Nenhuma alteração em BOX V21, pneus, pit lane ou RNG.
5. Nova revisão `Replay.SIMULATION_REVISION = "066810_team_yield"`; replays de regras anteriores são recusados explicitamente. Não há migração de saves de carreira.

## Testes realizados
- Importação limpa no Godot 4.7.2: PASS, sem parse errors, repetida no ZIP reextraído.
- Contrato da nova ordem: **36 verificações PASS**, 100 ticks com replay, validação/recusa, cancelamento/expiração, eficácia na defesa antecipada e BOX V21 protegido.
- HUD real: **18 verificações PASS** em corrida iniciada na cena principal.
- Regressões: **15/15 arquivos de teste PASS**, incluindo Racecraft (1.027), Driver Dynamics, rádio, double stack, carros 3D e replay com 200 ticks em cinco velocidades.
- Quatro pistas sem ordens (Silverstone, Spa, Monza, Singapura): hashes canônicos normalizados da simulação, eventos, RNG e posições idênticos nos ticks 1, 80 e 150. Os dois campos novos neutros foram excluídos do hash para comparabilidade.
- **Não homologado:** corrida completa de 53 voltas, A/B de 750 ticks (limite do ambiente), FPS GPU real e saves de múltiplas temporadas.

## Segurança / rollback
A v8.9 deve ser preservada para abrir replays antigos. Instale a v8.10 em nova pasta e faça backup dos saves antes de usar. A integração na main depende de CI aprovado.
