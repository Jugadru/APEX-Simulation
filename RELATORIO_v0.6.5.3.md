# APEX v0.6.5.3 — Realistic Racing

Atualização de 11/11/2026, baseada na v0.6.5.2. As pastas anteriores foram preservadas. O objetivo desta entrega é melhorar a apresentação dos carros e das pistas mantendo a HUD e as animações de ultrapassagem existentes.

## Implementação

As novas malhas paramétricas possuem vértices indexados, normais suaves explícitas e UVs. Carroceria e sidepods passaram a usar seções curvas interpoladas. O cockpit usa paredes separadas, abertura, banco recuado e aro oval. A cobertura do motor tem perfil afilado; as asas usam perfis suaves em camadas. Os pneus têm seção arredondada e abertura central, com aros recuados, raios e faixas estreitas de composto. Pintura, borracha e peças metálicas têm materiais distintos.

A cena usa Forward+ por padrão: céu procedural, reflexos do ambiente, sombras direcionais em cascatas, SSAO e suavização temporal apenas no viewport 3D. O asfalto ganhou coordenadas longitudinais, granulação discreta e marcas de borracha. As zebras usam um padrão métrico contínuo, independente do espaçamento dos pontos da pista. Barreiras corrugadas, telas com transparência recortada e postes instanciados substituem as faixas metálicas simples. As árvores receberam copas assimétricas e variação procedural; o terreno recebeu variação de tonalidade. Superfícies planas do terreno/pista não projetam sombra sobre si mesmas, mas recebem sombras dos objetos.

A geometria da rota, larguras calculadas, progresso dos carros, boxes, IA, economia e inventário não foram redesenhados. `apex_battle_motion_0652.gd`, `race_engine.gd`, `main.gd`, `garage.gd`, módulos de core e arquivos da HUD estão idênticos à base; a auditoria de 57 arquivos está em `qa/realistic_racing/source_audit.json`.

## Uso

Importe `project.godot` no Godot 4.7.2 e pressione F5. No Linux, use `linux/run_apex.sh` com o Godot no PATH ou configure `GODOT_BIN`.

Forward+ requer suporte a Vulkan. A alternativa `linux/run_apex_compatibility.sh` inicia em OpenGL / Compatibility: conserva as malhas e animações, sem os efeitos de SSAO e suavização temporal. O projeto completo não inclui o binário do Godot nem um jogo exportado.

## Validação e evidências

Os resultados efetivamente executados e logs ficam em `qa/realistic_racing/regressions.json` e `visual_results.json`. Abrangem integridade das malhas, animação de batalha/DRS/rodas/pausa, inventário, oficina, HUD, coordenação de boxes e comparação de dois motores durante 720 segundos simulados. A auditoria da simulação compara carros e eventos a cada passo, mantendo a apresentação isolada.

As capturas `race_1600x900.png` e `race_1920x1080.png` usam um ataque encontrado na simulação real de Silverstone, pausado para inspeção. As capturas `compatibility_*` repetem esse fluxo no renderizador alternativo. O vídeo `demonstracao_0653.mp4` contém 240 quadros de uma demonstração visual controlada, claramente identificada, com cópias de dois carros: preparação, disputa lado a lado e retorno. Não é replay real nem benchmark de FPS.

O ZIP inclui manifesto SHA-256 dos arquivos; sua integridade e testes após extração são registrados em `VERIFICACAO_ZIP_0653.json`, ao lado do arquivo compactado.

## Limites

A direção visual foi refinada, mas os cenários e carros continuam procedurais e estilizados; não atingem a fidelidade de produção de F1 Manager. Não foram copiados modelos, texturas ou código dos jogos de referência. Não foram adicionados física de contato, danos visuais, chuva volumétrica ou multidões animadas. A iluminação mais sofisticada aumenta o custo de GPU. Não se promete taxa específica de FPS e não foram repetidos campeonatos completos nem todas as pistas nesta atualização visual.
