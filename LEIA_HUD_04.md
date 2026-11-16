# APEX — Central de gestão baseada no esboço 04

Abra `project.godot` no Godot 4.7.2 e pressione F5. No menu inicial, escolha **CENTRAL / P&D**. A oficina também abre esta central.

## Estrutura implementada

A imagem 04 (`68a5ef05-5b3b-4bcc-81fb-cf19f0573f2e.png`) orientou a estrutura: cabeçalho com equipe/temporada/etapa/saldo, navegação lateral fixa, título, abas horizontais, faixa ilustrativa, projeto à esquerda, níveis e equipe à direita e investimento no rodapé. Paleta escura, botões laranja, contornos claros e barras de progresso nativas do Godot.

As abas Projetos ativos, Pesquisa, Desenvolvimento, Histórico e Equipe de boxes são funcionais. As compras, treinamento, pesquisa e cancelamento usam os comandos existentes e persistem na garagem. Uma pesquisa por vez continua sendo a regra atual; não foram introduzidos os três projetos simultâneos fictícios do esboço.

A navegação lateral oferece Carreira, Calendário, Equipe e Staff, Pilotos, P&D, Desempenho, Finanças, Contratos, Relatórios e Configurações. As páginas usam dados da temporada, elenco, garagem e histórico de staff. O mercado de funcionários e o relatório completo do campeonato continuam acessíveis pelos respectivos botões. A alteração de layout da HUD em Configurações usa as preferências já existentes.

## Dados e arte

Equipe, saldo, folha, projetos, progresso por etapas, níveis, pilotos e histórico são reais do save. A moeda continua R$, com caixa compartilhado da equipe. O custo do projeto ativo já foi pago: não é descontado novamente na apresentação do saldo.

A faixa de fábrica é uma região da própria imagem de referência, exibida como arte conceitual e identificada na tela; a marca da arte não representa necessariamente a equipe selecionada. Os outros elementos são controles e textos nativos, não uma captura de tela usada como interface inteira. Ícones Adwaita incluídos com sua licença em `assets/ui_icons/LICENSE.txt`, com cor adaptada ao fundo escuro.

A central de gestão foi implementada nesta entrega. Os esboços de negociação de pilotos, fornecedores, instalações detalhadas, múltiplas eras e outras mecânicas futuras não foram convertidos em funcionalidades novas. A HUD durante a corrida continua sendo a versão existente.

## Validação

- Importação no Godot 4.7.2 sem erros.
- `management_hud04_test.gd`: início de P&D, cobrança real, bloqueio de segundo projeto, progresso 0%/50%, cancelamento com reembolso de 75%, compra imediata, atualização do nível, navegação exclusiva por página, retorno à preparação e entrega de projeto.
- Capturas reais em 1600×900 e 1920×1080. A segunda usa tela cheia para evitar a limitação do gerenciador de janelas observada anteriormente.
- Regressões do menu, modelo Soul Staff e contratos executadas em diretórios temporários de dados.
- Motor de corrida e lógica da garagem comparados byte a byte com a base e preservados.

Logs e imagens desta entrega: `qa/hud04/`. Os relatórios anteriores são históricos; a pendência de anexos registrada na entrega MENU foi resolvida com as novas imagens fornecidas. Inventário atual: `BUILD_MANIFEST_HUD04.json`.
