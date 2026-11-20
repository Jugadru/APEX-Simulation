# APEX 0.6.2.2 — HUD com cartões nos cantos

## Feedback incorporado

Capturas reais da v0.6.2.1 mostraram cartões agrupados no rodapé central, barra horizontal excessiva, informações miúdas e janelas grandes demais e quase vazias. O último mockup aprovado foi usado como referência de **organização**, não como screenshot real do jogo.

## Mudanças nesta versão

- Substitui a barra inferior de ponta a ponta por um painel flutuante **255×48 px** ao centro inferior, com **pausa, seta anterior, velocidade e seta seguinte**.
- Cartão do piloto 1 no **canto inferior esquerdo**; cartão do piloto 2 no **canto inferior direito**, com largura responsiva (até 428 px cada).
- Em cada cartão: quatro botões T/D/E/C, avatar opcional (foto livre já baixada pelo jogador, senão sigla na cor da equipe), posição, nome, composto/idade/desgaste do pneu, ritmo, barra visual de vida do pneu, Seguir e Chamar Box.
- Cada botão contextual usa **um único painel de detalhes**, sem uma segunda navegação de abas. Os painéis aparecem acima dos cartões, deslocados para dentro da pista para **não cobrir classificação e minimapa**. Em telas menores, abrir o segundo fecha o primeiro para evitar sobreposição.
- Menu **CORRIDA** centraliza configurações removidas da barra: mapa 2D, aérea 3D, diretor TV, modos de câmera, zoom, centralizar, controle Manual/Auto e retorno ao menu.
- Outras janelas contextuais agora possuem dimensões próprias; a antiga modal de quase toda tela foi eliminada. Estratégia continua maior porque compara os dois pilotos.
- Câmera aérea inicial passou de zoom 1.20 para 0.95, visando enquadramento mais aberto. Ainda requer ajuste visual em Godot.
- Classificação preserva alternância com setas (intervalo, líder, pits, melhor volta, pneus/idade).
- Continuidade de funções existentes: chamadas de pit e agendamento, velocidade até 32×, modos visuais e a cena do mapa 2D.

## Escopo e pendências

- **A refatoração maior do main.gd ficou separada para a próxima versão**. Esta versão preserva os quatro módulos iniciais da v0.6.2.1.
- Não houve mudança no motor de corrida, IA, lógica de pneus, clima, campeonato ou geometria da pista.
- HUD não foi compilada/renderizada em Godot neste ambiente; o teste nativo `tests/core_0622_corner_hud_smoke_test.gd` fica para execução pelo jogador.
- Não corrige paradas excessivas, decisões de chuva nem realismo gráfico dos circuitos/câmeras.
