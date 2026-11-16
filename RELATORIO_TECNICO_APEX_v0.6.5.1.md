# APEX Motorsport Manager v0.6.5.1 — Living Factory 1.0

Data: 10/11/2026. Ambiente: Linux, Godot **4.7.2.stable.official.ed1daf0bf**, renderização OpenGL Compatibility / NVIDIA GTX 1650.

## Implementação

Projeto extraído do ZIP oficial `APEX_MOTORSPORT_MANAGER_v0.6.5.0_HUD_UNIFICADA.zip`. As pastas anteriores do workspace não foram usadas como substitutas. Entrega restrita ao inventário individual; nenhuma funcionalidade da v0.6.5.2 foi iniciada.

A oficina registra seis componentes iniciais, correspondentes aos dois carros e às categorias já existentes: Motor, Asa e Chassi. Cada componente possui ID criptográfico de 128 bits persistente, nome, categoria, especificação, conservação, integridade, distância, vínculo ao carro, estado e histórico. Não há peças extras concedidas gratuitamente: o estoque recebe componentes removidos ou substituídos.

Estados suportados: instalada, disponível, armazenada e inutilizada. A UI permite remover, instalar, substituir, armazenar e disponibilizar. O estado inutilizada é validado pelo modelo e impede instalação; não existe degradação artificial ou botão de descarte irreversível na UI.

## Arquitetura e arquivos

Novos módulos:
- `scripts/core/component_inventory_0651.gd`: migração aditiva, validação, transições, histórico e observação passiva da distância.
- `scripts/apex_component_workshop_0651.gd`: painel integrado de componentes, estoque, detalhes, ações e histórico.
- `tests/component_inventory_0651_test.gd`: migração, persistência, operações, rollback e distância real.
- `tests/component_inventory_0651_tracks.gd`: comparação A/B de GPs completos.
- `tests/component_inventory_0651_ui.gd`: ações de UI, bloqueio e capturas reais.

Arquivos existentes modificados:
- `scripts/garage.gd`: campo `component_inventory` no estado existente da equipe, transações, escrita temporária com rename, backups, observação e sincronização das especificações.
- `scripts/apex_management_hub.gd`: entrada Living Factory na navegação e integração do painel.
- `scripts/apex_race_session_controller.gd`: verificação dos seis slots antes de largar e abertura da sessão de observação.
- `scripts/main.gd`: chamada passiva após passos da simulação, salvamento ao sair/abrir gestão e identificação da versão.
- `scripts/apex_front_menu.gd`: identificação da versão.
- `project.godot`: nome e descrição da versão; mantém o diretório de dados existente.
- `README.md`, `LEIA_PRIMEIRO_0651.md`, este relatório e `linux/validar_0651.sh`: documentação atual e executor reproduzível com perfil temporário.
- Arquivos `.uid` dos novos scripts são gerados pelo importador Godot.

A auditoria completa está em `qa/living_factory/source_audit.json`. O motor e todos os módulos preexistentes de `scripts/core` são idênticos à base, byte a byte. IDs usam `Crypto`, sem consumir o RNG da corrida.

## Integração visual

O painel usa os componentes, cores, tipografia, cabeçalho, orçamento e sidebar da HUD Unificada. Inspiração das referências: abas dos carros, estoque separado, detalhes ao lado e ações contextuais. Não substitui a HUD nem incorpora imagens dos jogos enviados.

Acesso: menu de gestão / oficina → **Living Factory**. Abas CAR 01, CAR 02 e INVENTORY. O histórico possui rolagem própria; a página mantém a rolagem da HUD. Capturas reais em `qa/living_factory/living_factory_1600x900.png` e `living_factory_1920x1080.png`.

## Dados e limites deliberados

- Conservação e integridade são `null`, exibidas como **Indisponível**. O motor atual não fornece desgaste dessas três categorias. O desgaste dos pneus não é reutilizado como desgaste de motor, asa ou chassi.
- Quilometragem = incremento positivo de `car.progress` × `race.lap_km`. É distância equivalente no circuito, incluindo o progresso que o motor atribui à passagem pelos boxes; não é distância GPS independente do pit lane. Progresso negativo do grid é excluído.
- O uso anterior à migração é desconhecido. O zero inicial significa nenhum quilômetro registrado pelo inventário, não uma peça nova.
- CAR 01/02 seguem a ordem estável dos IDs dos pilotos da equipe, não a classificação do grid. O histórico de uso informa piloto, carro, circuito, sessão, temporada e etapa.
- A especificação continua seguindo os níveis compartilhados de P&D da base. Atualizações existentes sincronizam a identificação da especificação com histórico. Trocar peças não cria ganhos ou perdas de performance individual nesta versão.
- Não foram criados fabricação, compra de sobressalentes, protótipos, nova pesquisa nem efeitos humanos sobre o carro.
- As operações ficam bloqueadas durante a sessão, mesmo pausada. Consultar é permitido; ao concluir a corrida, a oficina é liberada. Slots vazios impedem iniciar uma nova corrida e direcionam para a oficina.
- A quilometragem é salva a cada mudança de volta, ao concluir, ao abrir a gestão/menu e no encerramento normal. Encerramento forçado do processo pode perder a fração ainda não salva da volta atual.
- Datas do histórico são UTC, provenientes do relógio do sistema, não do calendário fictício de 2012.

## Salvamentos

Mantém `apex_garage_050.json` e o perfil `APEX_0650_SOUL_STAFF`, preservando a compatibilidade com o carregamento e com o arquivo de campeonato existentes. Não modifica o formato do campeonato. Migração ocorre por equipe ao primeiro acesso, é idempotente e não reprocessa corridas antigas.

Os campos anteriores, inclusive campos desconhecidos, são preservados. Mantém contratos, moral, energia, confiança, folha, orçamento, níveis, projetos e histórico. A primeira migração cria `.pre0651`; escritas seguintes mantêm `.bak` e usam arquivo `.tmp` seguido de rename. Transações de peças operam numa cópia, validam o resultado e revertem o estado em memória se a persistência falhar. O save antigo pode ser recuperado a partir de `.pre0651`; abrir o save novo numa versão anterior pode descartar os campos que aquela versão desconhece.

IDs inválidos, categorias desconhecidas, estados inconsistentes, quilometragem inválida e dois componentes ocupando o mesmo slot são rejeitados. A mesma peça não pode ser instalada em dois carros. A substituição retorna a peça anterior ao estoque, sem removê-la do inventário.

Todos os testes desta entrega usam `XDG_DATA_HOME` temporário isolado. Os saves pessoais do usuário não foram usados nem modificados durante a validação.

## Problemas corrigidos durante a validação

- Ordem dos carros inicialmente dependia da posição de classificação: corrigida para IDs estáveis antes de atribuir quilometragem.
- Comparações de dicionários após JSON diferenciavam inteiros e floats: testes normalizam o round-trip JSON, mantendo checagem dos valores e IDs.
- Gerenciador de janelas limitou a janela solicitada de 1920×1080: captura refeita em tela cheia e dimensões reais verificadas.
- Carregamento anterior filtrava campos desconhecidos: migração preserva os campos adicionais além dos normalizados pela base.

## Próximas possibilidades — não implementadas

Telemetria física de integridade por categoria, suprimento de sobressalentes, comparação de especificações individuais e efeitos técnicos de funcionários exigem escopo e autorização futuros. A versão atual não antecipa essas mecânicas.

## Testes funcionais e regressões curtas executados

Todos os itens abaixo concluíram com código 0 e marcador PASS nos logs desta entrega:

| Teste | Evidência em `qa/living_factory/` |
|---|---|
| Inventário: IDs, migração aditiva, campos antigos/desconhecidos, troca entre carros, estados, duplicação, bloqueio, rollback, distância real e recarga | `functional.log` |
| Interface: CAR 01/02, estoque, remoção/instalação, slots vazios impedem corrida, bloqueio em sessão e largura do painel | `final_ui.log` |
| Capturas reais e dimensão exata 1600×900 / 1920×1080 | `visual.log` e dois PNGs |
| Soul Staff: moral, energia, confiança, relações, contratação e economia | `soul_staff_0650_model_test.log` |
| Importação de perfil legado, oficina, temporada e contratos | `soul_staff_0650_migration_test.log` |
| Strategy Simulator 1.0: três pistas, telemetria, previsões e double stack | `strategy_simulator_06499_model_test.log` |
| Pit Wall 3.0: cenários, undercut/overcut, chuva e agendamento seguro | `pitwall_0649_strategy_test.log` |
| Race Engineer 3.0: previsão, staff, chuva, rádio, UI e pit manual | `race_0646_engineer_3_test.log` |
| IA por volta: antecipação/extensão segura, chuva, parada agendada e consulta pura | `lap_strategy_06496_test.log` |
| Double stack: regras e integração | `team_pit_06497_unit_test.log`, `team_pit_06497_integration_test.log` |
| Pneus e integração com IA | `core_0552_tyre_ai_smoke_test.log` |
| Física dinâmica, água na pista, linhas e crossover | `core_0643_dynamic_track_weather_test.log` |
| HUD Unificada, identidade, dados e navegação de corrida | `unified_hud_test.log` |
| Gestão existente: P&D, reembolso, compra, progresso e entrega | `management_hud04_test.log` |

`short_runs.json` consolida esses resultados. A importação no editor também foi executada; `import.log` não contém erro de script. Testes históricos não listados não são declarados aprovados nesta versão.

## GPs completos e temporada — resultados finais

Reexecuções finais em processos separados concluídas com código **0** em todos os casos; `qa/living_factory/long_runs.json` registra os códigos de saída.

| Circuito | Semente | Passos externos de 4 s | Relógio final simulado | Resultado |
|---|---:|---:|---:|---|
| Silverstone / GBR | 6511 | 1369 | 5476 s | GP completo, paridade exata, 0 divergências |
| Monza / ITA | 6511 | 1254 | 5016 s | GP completo, paridade exata, 0 divergências |
| Singapura / SIN | 6511 | 1766 | 7064 s | GP completo, paridade exata, 0 divergências |

Cada caso usa dois motores com configurações equivalentes, clima Variável e controle de pit por IA. O primeiro roda sem observador; o segundo com o inventário. O motor de ambos é byte a byte o da base oficial, conforme auditoria. O teste compara snapshots periódicos e, ao final, todos os dados dos carros e eventos. Valida também distância acumulada por carro e idempotência ao observar novamente o mesmo estado. Os passos de 4 s passam pelo `step` de produção, que subdivide o tempo internamente; não substituem a física por simulação simplificada.

Logs finais: `track_GBR.log`, `track_ITA.log`, `track_SIN.log`, cada qual com seu `.result.json`. O observador não produziu divergências na corrida nem nas decisões estratégicas desses cenários. Isso é evidência para as configurações e sementes executadas, não prova de todas as combinações possíveis.

O teste `soul_staff_0650_season_test` concluiu um GP de 58 voltas em 1328 passos, validando resultado, avanço da temporada, folha salarial, efeitos humanos, reconciliação idempotente e liberação de ações da próxima etapa. Código final 0.

Uma tentativa inicial de temporada excedeu 180 segundos. As execuções longas iniciais também tiveram retorno 143 do executor, embora os logs contivessem as verificações finais. Essas tentativas não são usadas como aprovação final: foram repetidas sem o limite curto e com saída 0 confirmada. `tracks.log` é o registro preliminar; os logs separados são as evidências finais.

## Entrega e verificação do pacote

Pacote: `APEX_MOTORSPORT_MANAGER_v0.6.5.1_LIVING_FACTORY_COMPLETO.zip`. Contém projeto, scripts, cenas, assets, dados, testes, documentação e capturas reais. Exclui cache `.godot`, caches Python e saves pessoais. `BUILD_MANIFEST_0651.json` registra hashes SHA-256 dos arquivos do pacote, exceto o próprio manifesto.

A verificação pós-compactação é registrada ao lado do ZIP em `VERIFICACAO_ZIP_0651.json`: CRC de todas as entradas, conferência do manifesto após extração, importação no Godot 4.7.2, teste funcional do inventário e teste da UI da cópia extraída. O SHA-256 do ZIP é publicado no arquivo `.zip.sha256` adjacente. O relatório técnico também é entregue separadamente na pasta principal.
