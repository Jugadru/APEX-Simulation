# Benchmarks e investigação — APEX 0.6.5.9

## Queda anterior em 1080p
A entrega 0658 registrou 41.70 → 38.64 frames/s e CPU 15.588 → 16.166 ms contra 0657, embora a montagem compacta fosse mais barata. A 0659 não descarta esse registro. Nova investigação usou os projetos 0657/0658, três pares intercalados, fullscreen real 1920×1080, saves isolados e mesmo roteiro; não houve concorrência com testes pesados.

Nesta repetição, CPU 0657 → 0658: **14.552 → 13.889 ms**; taxa frames/parede: **45.55 → 47.62**. A regressão anterior não se reproduziu. Isso não isola sua causa: há evidência de variabilidade entre séries, sem prova de thermal throttling, driver, scheduler ou outro fator específico. Não foi aplicado um suposto conserto de física para mascarar a diferença.

## Comparação principal — 0658 versus 0659
Godot 4.7.2 oficial, Linux/X11, i5-7500 (4 threads), GTX 1650, Forward+/Vulkan. Silverstone, seed 6558, 24 carros, Diretor TV, 1×. Mesmo script absoluto executado em ambos os projetos. 30 frames de aquecimento, 180 frames medidos em corrida, depois 90 pausados; host._process(1/60) com await process_frame. Três repetições sequenciais por versão/resolução, ordem base/nova alternada. As medianas abaixo são medianas das médias por execução. Todas as amostras válidas foram mantidas.

| Resolução / estado | CPU main 0658 → 0659 (ms/frame) | Projeção 3D 0658 → 0659 (ms/frame) | Frames / parede 0658 → 0659 |
|---|---:|---:|---:|
| 1600×900 / corrida | 13.832 → 9.829 | 4.040 → 0.356 | 47.62 → 59.33 |
| 1600×900 / pausa | 1.320 → 1.339 | 0.000 → 0.000 | 61.28 → 61.24 |
| 1920×1080 / corrida | 13.676 → 9.830 | 4.014 → 0.357 | 48.39 → 59.68 |
| 1920×1080 / pausa | 1.334 → 1.341 | 0.000 → 0.000 | 61.53 → 60.84 |

A taxa frames/parede inclui GPU, sincronização e scheduler, não é medição GPU isolada. O custo CPU é inclusivo: não somar pai e filho. A proximidade de 60 frames/s limita inferências sobre ganhos adicionais. Resultados são deste hardware/cenário, não garantia para todos os GPs. Não houve redução de modelos, sombras, número de carros ou resolução. O campo version do profiler permanece 0.6.5.7 (serviço herdado); os rótulos base/new identificam os projetos comparados.

## Geometria e memória
6.000 consultas com seed 6559 nos 20 circuitos: mesma projeção global e mesma direção/posição 2D, incluindo progressões fora de [0,1], emenda, deslocamentos laterais aleatórios, empates e degenerados. Índice avaliou 400.400 candidatos versus 4.056.000 da varredura antiga (~9,9%). Tolerâncias: posição 2D <0.0001, vetor direção <0.00001, along <0.00001; segmento deve ser exatamente igual. Teste também exige comprimento total equivalente <1e-8, invalidação com pista vazia e troca de rota pausada.

Construção do índice: mediana 0.337 ms, máximo 0.440 ms nas 20 pistas. Maior serialização dos arrays do índice: 38472 bytes. Serialização é proxy de tamanho dos dados, não medida de heap.

| Resolução | Memória estática Godot 0658 → 0659 (MiB, mediana em corrida) |
|---|---:|
| 1600 | 173.84 → 173.98 |
| 1920 | 171.58 → 171.66 |

Não confundir monitor estático Godot com RSS/VRAM. Caches 2D têm limite de 256 entradas por tipo; índice 3D é linear no número de segmentos; dicas por carro são removidas e invalidadas por sessão. Nenhum histórico esportivo entra nesse cache. A prova de nós estáveis cobre 12 alternâncias de vista, não temporadas longas.

## Reprodução e evidências
Scripts: tests/geometry_0659_benchmark.gd (nativo), geometry_0659_test.gd (equivalência), view_0658_race_parity.gd (corridas comparativas), geometry_0659_full_gp.gd (GP integral), geometry_0659_shadow_diagnostic.gd (ablações visuais). Parâmetros: APEX_BENCH_WIDTH=1600/1920; APEX_BENCH_OUTPUT=caminho JSON; APEX_BENCH_SCREEN=1; XDG_DATA_HOME isolado. Execute o mesmo benchmark por caminho absoluto com --path de cada release. Compatibility usa --rendering-method gl_compatibility --rendering-driver opengl3. GP integral usa APEX_FULL_GP=1 e APEX_BENCH_TRACK=GBR.

Todos os JSONs/logs/capturas estão em qa/geometry_0659. Benchmarks renderizados têm o mesmo hash esportivo (carros/eventos/RNG). Comparações de corridas, GP integral e Compatibility são relatadas separadamente; não usar uma captura de poucos segundos como evidência de GP inteiro.
