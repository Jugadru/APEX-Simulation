# Pesquisa e decisões — 0.6.5.8
Consulta em 13/11/2026; fontes primárias, sem código ou assets externos incorporados.

- [Godot Dictionary](https://docs.godotengine.org/en/stable/classes/class_dictionary.html): cópia profunda percorre containers; cópia rasa compartilha containers internos. Decisão: contrato explícito com 23 campos escalares, mais player e duas amostras de rota; nenhum histórico, Array, Dictionary ou Object do motor. Arrays/dicionários de saída somente leitura. Não substituir cegamente duplicate(true) por duplicate().
- [Testes oficiais de Dictionary no GitHub](https://github.com/godotengine/godot/blob/master/tests/core/variant/test_dictionary.cpp), [licença MIT](https://github.com/godotengine/godot/blob/master/LICENSE.txt): referência para testar isolamento e identidade de snapshots. Testes do APEX são originais; nenhuma dependência adicionada.
- [Introdução à interpolação do Godot](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html): separar estados de simulação e apresentação. APEX usa motor próprio em _process, portanto não foi ativada a interpolação física global. Aplicamos interpolação exponencial apenas a progress/race_lane, com blend comum, constante de 40 ms, sem extrapolar; o verificador espacial existente continua depois da interpolação.

## Limites deliberados
Não se promete determinismo entre FPS: isso pertence à 0.6.6.0. As cópias congeladas em race_engine._advance protegem a ordem de cálculo e continuam intactas. A busca geométrica 3D e suas estruturas não foram alteradas: serão objeto da 0.6.5.9. Não houve novas threads, pools, física, redução de carros ou de qualidade gráfica.
