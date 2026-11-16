# Plano técnico — 0.6.5.9 Track Geometry Optimization

## Problema e fronteira
RaceViewSnapshot 0658 elimina históricos e fornece progress absoluta, route_point e route_direction. As amostras ainda usam busca de ponto repetida; Track3D._sample_occupied_pose projeta a origem sobre todos os segmentos por carro/frame. Otimizar apenas geometria e consumo de câmera, mantendo ocupação, modelos, regras e resultados. Pesquisa nova no GitHub e documentação oficial antes da implementação.

## Arquivos e contratos
- Novo scripts/track_geometry_sampler_0659.gd, RefCounted: build(route, revision), sample(progress), sample_distance(distance), invalidate(). Dados PackedVector2Array/PackedFloat64Array para pontos, tangentes e comprimentos acumulados; retorno {point, tangent, segment, along, revision}.
- track_map.gd: criar sampler ao carregar pista; point_on_track e direction_on_track mantêm API. Reutilizar uma busca binária para ponto e tangente quando a equivalência com a direção atual estiver comprovada; não trocar tangente por conveniência se mudar visual nas curvas.
- race_view_snapshot_0658.gd: consumir sample conjunto, incluir segmento/along apenas se compatíveis com o espaço geométrico do 3D; ampliar whitelist e testes. Snapshots continuam imutáveis.
- track_3d.gd: cache próprio de comprimentos/tangentes/larguras em set_track_data. _sample_occupied_pose usa âncora conhecida/vizinhos, fallback global em descontinuidade. Não confundir rota 2D suavizada com malha 3D nem escala de 0.6.
- apex_race_view_controller.gd: reutilizar amostras por progress/revisão sem alterar cortes/zoom/pits; câmera deve acompanhar a pose apresentada quando apropriado.
- Distância/LOD: auditar MultiMesh e meshes já existentes; medir antes de reduzir frequência de detalhes distantes. Nunca omitir carros da simulação/solver.

## Sequência
1. Extrair ZIP 0658 e verificar manifesto. Rodar a mesma matriz nativa em 1600/1920 e microbenchmark de amostragem.
2. Pesquisa documentada com licenças; auditar transformação 2D→3D, pit lane, costura e revisão de pista.
3. Criar testes de equivalência antes de substituir consultas: amostras densas e aleatórias, pontos 0/1/negativos/voltas completas, curvas fechadas e segmentos degenerados. Registrar tolerância de posição e ângulo escolhida com base no algoritmo anterior.
4. Introduzir sampler 2D, medir; depois âncoras 3D, medir separadamente. Não remover fallback até cobrir reentrada, mudança de pista e teleport/reset.
5. Verificar pares sobrepostos e varredura contínua após interpolação, em 1×/16×; ambos os pilotos, boxes e retardatários. Comparar imagens de curvas e da emenda.
6. Rodar GBR, Monza, Singapura e duas pistas sorteadas com seed registrada; seco e chuva. Comparar hashes esportivos com 0658, também pit history, rank e tempos.
7. Regressões de gestão/oficina/saves e profiler; memória/objetos após repetidas reentradas. Atualizar relatórios, diário, manifesto e ZIP completo, testar extração limpa.

## Riscos e aprovação
Índice da rota 2D pode não representar segmento da malha 3D; cache incorreto deslocaria carros para outra seção. Mais memória pode anular ganho de CPU; registrar custo de construção e bytes. Direção na costura e pit exit exige teste próprio. Não declarar FPS melhor sem mediana de repetições comparáveis; melhoria localizada não implica ganho global. Nenhuma alteração no motor esportivo é permitida nesta versão.

## Dependências posteriores
0.6.6.0: comandos/ticks/checkpoints/RNG e replay; 0.6.6.1: IA de disputas; 0.6.6.2: personalidade/rádio; 0.6.6.3: estratégia e teste de chuva intensa na volta 4 versus pit 21. Permanecem pendentes, conforme prompt mestre; não estão incluídos na 0658.
