# APEX Motorsport Manager v0.6.6.7.2.4 — Pit Wall & High-Speed UI Maintenance

**Base:** v0.6.6.7.2.3. **Godot:** 4.7.2, Linux. **Escopo:** posição dos engenheiros do Pit Wall no cenário e custos de atualização da HUD nas velocidades elevadas. Não foram alterados o motor esportivo, as regras de boxes, o RNG, o formato dos replays nem a IA.

## O que foi identificado

1. Em `scripts/circuit_life_0660.gd`, mesas, telas e engenheiros estavam próximos de **x=2,5–3,25**, do lado da pista principal. Foram posicionados no lado da garagem, com estação em **x=GARAGE_FRONT_X−0,50 = 12,50** na geometria local do complexo. O estacionamento das equipes, a spline de entrada/saída e os pontos de parada não mudaram.
2. `32x` nunca deixou de existir. Desde a v0.6.6.7.2.3 o orçamento por quadro pode limitar o avanço real. A UI anterior mostrava apenas a velocidade solicitada. Nesta revisão, a HUD calcula uma média móvel de **ticks esportivos realmente processados × 0,20 s / tempo decorrido** e informa `~NNx real`, com indicação `CPU` quando limitada. O contador reinicia ao mudar de velocidade.
3. No modo acelerado, a HUD e seus painéis de engenharia eram atualizados quatro vezes por segundo, mesmo no mapa estratégico. Passaram para **duas vezes por segundo em 10x/16x/32x**. Carros e mapa continuam recebendo atualização a cada quadro. Em 1x/2x/5x, a cadência anterior (4 Hz) permanece.

## Evidência de desempenho e ressalvas

O perfil de **dois carros no pit e 180 chamadas sintéticas da apresentação a delta 1/60** registrou **12 chamadas da HUD no código anterior contra 6 no atual**, totalizando ~225 ms contra ~131 ms de trabalho da HUD. O p95 do quadro foi ~33,55 ms no ensaio anterior e ~28,43 ms no ensaio novo, porém os testes concluíram quantidades diferentes de ticks (355 e 325). **Esse contraste não é um benchmark esportivo pareado nem comprova aumento de FPS**. Variações de carga e limitação do escalonador impedem afirmar ganho contínuo em 32x.

Em captura 2D 1440×810 por Godot/Mesa llvmpipe, o **32x solicitado mostrou aproximadamente 21x no indicador** durante o ensaio sintético. O 32x permanece dependente do custo dos ticks e do processador; a função NÃO acelera artificialmente nem salta ticks. Para saber a velocidade real no PC, testar o jogo com o tempo de quadro real, e não somente fixtures sintéticas.

O perfil durante pit apontou que `pit.advance` não era o maior custo dos quadros: disputas, simulação completa e painéis da HUD foram mais relevantes. O erro X11 `BadWindow` não foi reproduzido nem tratado nesta alteração.

Foi experimentada, medida e **revertida** uma pré-filtragem de pares na resolução espacial de ultrapassagens, por tornar 750 ticks mais lentos (aprox. 7,04 s contra 6,72 s, com hashes iguais). O módulo `race_space_0655.gd` definitivo é idêntico ao original. Nenhuma otimização esportiva regressiva foi entregue.

## Testes executados

- Godot 4.7.2 importação sem erros.
- Quatro corridas curtas (GBR seco, BEL chuva intensa, ITA seco, SIN chuva intensa), com replay integral tick a tick e hashes históricos idênticos: todos aprovados.
- Pit service com troca de quatro pneus, Pit Wall duas ordens no mesmo tick/double-stack, controle 2D em 10x+, e diagnóstico 32x: aprovados.
- Captura 3D real de Monza em 1440×810 demonstrando mesas junto às garagens e captura 2D 32x com velocidade efetiva.

**Ainda pendente:** medição de FPS real no PC do jogador, 53 voltas de Monza iniciadas nesta revisão, 20 temporadas completas e eliminar toda saturação em 32x. O mapa 2D continua mais barato de desenhar, mas a simulação esportiva permanece o limitador principal.
