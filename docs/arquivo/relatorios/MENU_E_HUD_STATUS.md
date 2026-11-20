# Menu APEX — entrega parcial da solicitação de HUDs

Base: projeto 0.6.5.0 refatorado. O logotipo enviado foi incorporado sem alteração. A HUD de corrida permanece a existente: os outros 28 anexos chegaram com apenas 4 bytes cada, sem uma imagem decodificável. A reprodução dessas referências depende do reenvio dos arquivos, preferencialmente em ZIP.

## Menu implementado

- Standard: entrada na preparação da temporada com controle manual.
- Continuar: retoma a temporada salva; resultados continuam disponíveis após o encerramento.
- Simulation: apresenta o planejamento de proprietário e oferece acesso ao GP com a delegação já existente. Não implementa propriedade ou contratação de chefe de equipe.
- Sandbox: configuração de GP avulso com equipe, pista, clima e semente. Não implementa criação/compra de equipes.
- Cenários: três treinos configuráveis (Silverstone variável, Monza seco, Singapura variável). São presets novos para os recursos atuais, não desafios históricos recuperados ou com metas implementadas.
- Voltar à corrida: mantém a sessão pausada existente, sem criar outro motor de corrida.
- Acesso à oficina e ao Soul Staff.

O planejamento foi recuperado nas conversas “Implementação dos gráficos dinâmicos”, “Misturar HUDs do Apex” e “Ideia de simulador F1”. A primeira registra Standard/Simulation compartilhando o motor de corrida, propriedade/delegação, Sandbox, criação/compra de equipes e desafios históricos como expansão futura. Nenhuma lista detalhada de desafios históricos foi recuperada.

## Validação

Godot 4.7.2: `tests/front_menu_test.gd` passou com renderização nativa. Verifica entrada, navegação, estados disponíveis/planejados, três presets, partida em Monza, retorno à sessão, oficina e equipe. Capturas reais: `qa/menu/menu_home.png` e `qa/menu/menu_scenarios.png`.

Para repetir sem usar saves reais, crie um diretório temporário e execute com `XDG_DATA_HOME` apontando para ele. Com driver gráfico, o teste também grava capturas. Com `--headless`, verifica apenas os fluxos.

A validação desta etapa não repete as simulações integrais da refatoração anterior; o motor de corrida não foi modificado. Relatórios anteriores são históricos. O inventário atual está em `BUILD_MANIFEST_MENU.json`.
