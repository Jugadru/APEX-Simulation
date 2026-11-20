# APEX Motorsport Manager v0.6.5.5 — Simulation Racecraft

Abra `project.godot` no Godot 4.7.2 e pressione F5. Os inicializadores Linux e o modo Compatibility continuam disponíveis. O ZIP é o projeto completo, sem o executável do Godot.

## Agora no motor da corrida

O módulo `scripts/core/race_space_0655.gd` calcula as decisões a cada passo fixo do motor, a partir de uma fotografia do pelotão. A ordem do array não decide quem ganha espaço e nenhum RNG foi acrescentado.

- O atacante precisa de vantagem de ritmo, preparação e uma zona de ultrapassagem. Ele procura uma linha lateral livre e demora para alcançá-la.
- Habilidade e agressividade do defensor aumentam a exigência para atacar. O defensor protege uma linha com um movimento inicial limitado; a defesa tem um pequeno custo de ritmo.
- Largura e curvatura da rota entram no cálculo. É possível configurar setores ainda mais estreitos. Um estreitamento à frente impede a escolha de uma linha inviável e pode obrigar o atacante a aguardar para retornar.
- A ocupação das linhas e o espaço longitudinal consideram terceiros, filas e carros em voltas diferentes, inclusive perto da linha de chegada. Sem corredor livre, o progresso é limitado atrás do carro à frente.
- A ultrapassagem não recebe mais um impulso artificial de resolução. Ela acontece pelo avanço calculado do carro numa linha disponível. A classificação acompanha esse progresso; os eventos e contadores são tratados pelo motor existente.
- `race_lane` é um estado da simulação e alimenta a animação 3D. O renderizador não escolhe um lado diferente para inventar a ultrapassagem.

O grid recebeu espaçamento compatível com a ocupação dos modelos. HUD, modelos, materiais e a coordenação existente de boxes foram preservados. Os tempos e resultados podem mudar: defender e ficar preso no tráfego agora afetam o andamento real da corrida.

## Validação

`qa/sim_racecraft/regressions.json` e os logs registram as execuções desta versão. Há testes puros de espaço/defesa/retardatários e testes do motor completo sem criar um renderizador. No caso controlado, o atacante ficou atrás por 100 segundos em largura 4,2 e ultrapassou aos 27,4 segundos em largura 8,8, com defesa, classificação correta e uma única ultrapassagem creditada. As larguras são parâmetros de jogo.

Um GP curto de três voltas em Silverstone terminou com 24 carros e pit stops concluídos. Inventário, HUD e coordenação de boxes também passaram. As capturas `race_*` mostram uma disputa encontrada na simulação normal, não posições de carros impostas pelo roteiro. QA e demonstrações das versões anteriores são históricos.

## Limites

O sistema usa corredores laterais e comprimento longitudinal esquemáticos, dimensionados para a apresentação do jogo; não é dinâmica de corpos rígidos nem telemetria real de uma categoria. Não acrescenta impactos, danos ou um modelo de pneus de contato. A proteção visual da v0.6.5.4 permanece como salvaguarda geométrica nas curvas; ela não altera classificação ou resultado. A entrada, serviço e saída dos boxes continuam sob a máquina de estados existente. Não foram reexecutados campeonatos inteiros nem todos os circuitos.
