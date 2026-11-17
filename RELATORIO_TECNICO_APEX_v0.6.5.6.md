# APEX v0.6.5.6 — Living Factory 2.0

## Entrega
Projeto derivado por extração direta do ZIP obrigatório v0.6.5.5. CRC conferido antes das alterações. SHA-256 da base: `5fe4e6f2d1c53468a346edbed07a0ecf7886db238aa1fd64539b6b6d8c72aa43`.

Auditoria anterior à implementação: `AUDITORIA_0656.md`. Não foi iniciada a v0.6.5.7.

## Operação
Em **Living Factory**, use Visão geral, Fila de tarefas, Equipe técnica, Componentes e Histórico. Contrate o chefe de mecânica e/ou engenheiro pelo sistema existente de Equipe e Staff. Nenhum funcionário é concedido gratuitamente.

No Manual, selecione carro, peça, serviço, responsável e prioridade; reserve o serviço e inicie a fila. Avance 1 ou 8 horas para consumir tempo. O Calendário também permite avançar 8 horas. O automático requer chefe contratado: planeja serviços conforme condição conhecida, orçamento, disponibilidade e prazo operacional. Não compra peças, contrata pessoas ou cancela tarefas manuais. As decisões aparecem no histórico.

A saída para a corrida exige concluir ou cancelar serviços **em execução**. Tarefas ainda pendentes podem permanecer para depois do GP. Nenhum trabalho avança durante uma sessão, inclusive pausada. A troca pela tela de componentes abre o formulário de serviço; a instalação acontece apenas ao concluir a substituição.

## Arquitetura
- `scripts/core/workshop_0656.gd`: modelo de tarefas, escalonamento por prioridade, profissionais, reservas, tempo, recuperação e planejamento automático. Sem acesso ao motor ou RNG da corrida.
- `scripts/garage.gd`: dono da persistência e API transacional `workshop_action`. Operações usam cópia de segurança em memória; falha de gravação reverte orçamento, inventário e oficina. Bloqueia ações LF1 sobre componentes reservados ou slots de destino reservados.
- `scripts/apex_workshop_0656.gd`: cinco abas integradas na página factory da HUD existente, formulário e progressos reais.
- `scripts/apex_component_workshop_0651.gd`: preserva consulta e histórico LF1; apresenta condição diagnosticada e encaminha instalação para a fila.
- `scripts/apex_management_hub.gd`: integra nova apresentação e avanço de tempo no Calendário.
- `scripts/apex_race_session_controller.gd`: apenas preflight de serviços em execução; não altera corrida.
- `project.godot`: identificação v0.6.5.6; mantém o diretório persistente de saves.
- Testes novos `tests/workshop_0656_*.gd`; teste de UI LF1 adaptado à apresentação aninhada.

### Dados e invariantes
`team.workshop`: schema, hora de gestão, prazo, modo, sequência de IDs, tarefas e log. Cada tarefa contém ID único, carro, ID da peça e peça substituída, serviço, prioridade, responsável/nome, duração estimada/restante, custo, status, proteção manual e marcos de início/fim.

Custo integral reservado na criação; cancelamento devolve somente a fração ainda não trabalhada. Não existe segunda cobrança na conclusão. Um profissional executa apenas um serviço simultâneo; profissionais diferentes podem trabalhar em paralelo. O escalonador avança até a próxima conclusão e redistribui o tempo restante, independentemente de FPS ou tamanho do passo de calendário. Expiração/rescisão do contrato suspende o serviço; o jogador pode reatribuir uma tarefa pendente.

A oficina usa exclusivamente `component_inventory.parts`. Reserva a peça de entrada e a peça instalada que será substituída. Instalação utiliza `Inventory.operate`; conserva IDs, quilometragem e históricos, devolvendo a peça anterior ao estoque. Sem geração de componentes. Movimento de estoque/remover/armazenar já existente continua disponível para peças sem reservas.

### Competências e consequências
Adaptação mínima dos contratos individuais existentes: chefe de mecânica e engenheiro também prestam serviços técnicos. Atributos derivados do skill do contrato são apresentados. Velocidade ajusta horas pelo fator `1.15 - speed * 0.003`; precisão limita ganho de recuperação pelo fator `0.65 + quality * 0.30`. Técnica, diagnóstico, experiência e resistência são indicadores informativos nesta versão; não foi introduzida simulação adicional de fadiga nem mercado paralelo de mecânicos.

LF1 não simulava condição: campos eram nulos. A primeira inspeção usa uma estimativa inicial de 95%, descontando 0,002 ponto por km conhecido. Serviços posteriores consideram somente km desde o último diagnóstico. O teto de recuperação considera km e número de reparos (`98 - km*0.0005 - repairs*0.8`, limitado a 65–98). Manutenção/ reparação recuperam parcialmente, nunca garantem peça nova, nunca zeram km. Uso anterior desconhecido permanece explicitamente desconhecido. Preparação e verificação registram prontidão por componente, válida para a quilometragem observada.

## Compatibilidade e limites explícitos
- O calendário herdado contém etapas, sem datas/horas. Foi acrescentado relógio de gestão persistente; prazo até GP é uma **meta operacional ajustável**, inicialmente 72h, não uma reconstrução das datas reais de 2012. O avanço é explícito e não progride P&D por horas (P&D mantém regra por etapas).
- Preparação/verificação são por componente. Condição de oficina não se injeta em performance ou falhas da corrida: preserva a natureza passiva da LF1 e a exigência de não alterar fórmulas esportivas. Consequências implementadas: custo, tempo, disponibilidade, restrição de saída e recuperação limitada.
- Não há compra de novos sobressalentes nesta atualização. Substituição requer uma peça já existente em estoque. O inventário original começa com seis peças instaladas.
- Automático planeja ao acionar o chefe; não realiza gastos periódicos ocultos. O log não é truncado nesta versão.
- Saves anteriores ganham apenas a seção de oficina ao serem usados; o caminho `APEX_0650_SOUL_STAFF` permanece. Arquivos existentes continuam protegidos pelo mecanismo temporário/backup/rename. Não foram alterados saves pessoais nos testes.

## Testes reais
Executados com Godot **4.7.2.stable.official.ed1daf0bf**, saves isolados via `XDG_DATA_HOME`.

Aprovados:
1. `workshop_0656_test`: criação, início, término, cancelamento/reembolso, orçamento, tempo, concorrência, peça reservada, troca entre carros sem duplicação, save com pendências e reversão em falha de persistência.
2. `workshop_0656_edges`: orçamento no automático, proteção manual, invariância 8h versus 8×1h, profissional desligado, reatribuição, desgaste permanente, ausência de prazo.
3. `workshop_0656_integration`: formulário na HUD, serviços de inspeção/preventiva/reparo/preparação/verificação, prontidão, bloqueio de saída, corrida iniciada após conclusão, bloqueio durante sessão.
4. `workshop_0656_legacy`: save gerado executando a v0.6.5.5, aberto na v0.6.5.6; todos os campos anteriores preservados.
5. `workshop_0656_capture`: cinco abas nativas em **1600×900 e 1920×1080**, dimensões e limite horizontal conferidos no espaço lógico do viewport. Captura adicional de histórico concluído. Rolagem vertical é intencional para listas extensas.
6. `component_inventory_0651_test` e `component_inventory_0651_ui`: inventário, navegação, instalações e bloqueio de sessão.
7. `unified_hud_test`: páginas, dados reais, identidade da equipe e início de corrida.
8. `sim_space_0655_test`, `sim_engine_0655_test`, `sim_gp_0655_test`: espaço, defesa, ultrapassagens, determinismo e GP curto.
9. `team_pit_06497_unit_test`, `team_pit_06497_integration_test`: pit stops.
10. `soul_staff_0650_model_test`, `soul_staff_0650_migration_test`: Staff e migração.
11. `strategy_simulator_06499_model_test`, `core_0639_race_engineer_test`: estratégia e engenheiro.
12. **Silverstone completo**, 52 voltas, seco, Ferrari, semente **6552**, executado na base e na versão nova. Tempo final `5451.99999999723`. JSON completo de carros, eventos e pit history idêntico byte a byte. Hash de ambas as saídas: `aab60f259edac18fd2694b7b8431f3d682dd3aad165eaee5fe7413f310f3254e`.

O primeiro limite de 160 segundos para o GP completo expirou; as duas execuções foram repetidas com limite adequado e concluíram. Falhas iniciais de assertivas de teste (normalização JSON, ordem de IDs e coordenadas lógicas da HUD) foram corrigidas antes das execuções aprovadas. Não foram tratados testes interrompidos como aprovados.

Motor `race_engine.gd`, `race_space_0655.gd`, `track_3d.gd` e `car_model_3d.gd` permanecem byte a byte iguais à base. Evidência em `qa/living_factory_2/source_audit.json`.

## Evidências
Logs e resultados novos em `qa/living_factory_2/`. Capturas PNG reais das cinco abas nas duas resoluções, mais `servicos_concluidos_1920.png`. Evidências de versões antigas foram preservadas, mas não são contadas como testes desta entrega.

Manifesto SHA-256 dos arquivos: `BUILD_MANIFEST_0656.json`. Verificação externa de CRC, extração, manifesto e execução da entrega: `VERIFICACAO_ZIP_0656.json` ao lado do ZIP.
