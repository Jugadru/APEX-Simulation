# Desempenho — APEX 0.6.5.8

## Método nativo comparável
Base 0.6.5.7 versus 0.6.5.8; Godot 4.7.2 oficial, build debug, Linux/X11, Forward+/Vulkan, GTX 1650, i5-7500 (4 threads). Silverstone, seed 6558, 24 carros, Diretor TV, 1×. Mesmo script absoluto sobre os dois projetos, saves isolados, execuções sequenciais alternando base/nova. Por execução: 30 frames de aquecimento, 180 medidos em corrida, depois 90 pausados. host._process recebe 1/60 fixo e cada chamada aguarda process_frame. Três repetições por versão/resolução; valores abaixo são medianas das médias de cada execução.

| Resolução / estado | CPU main antes → depois (ms) | Montagem visual antes → depois (ms) | Frames / tempo de parede antes → depois |
|---|---:|---:|---:|
| 1600×900 / corrida | 14.396 → 13.845 | 1.064 → 0.694 | 46.23 → 47.41 |
| 1600×900 / pausa | 3.442 → 1.401 | 1.129 → 0.638 | 61.13 → 60.98 |
| 1920×1080 / corrida | 15.588 → 16.166 | 1.235 → 0.832 | 41.70 → 38.64 |
| 1920×1080 / pausa | 4.399 → 1.426 | 1.375 → 0.661 | 57.94 → 60.92 |

Não se deve somar seções inclusivas. A taxa frames/parede inclui render, sincronização e scheduler; não é FPS isolado da GPU. O ganho demonstrado é redução de CPU da montagem dos estados. Em 1080p, CPU total subiu de 15.588 para 16.166 ms (+3.7%) e frames/parede caíram de 41.70 para 38.64 (-7.3%): portanto não houve melhora global nessa série. Também aumentaram tempos de race.step e race.overtaking, cujo código e resultados não mudaram; isso sugere variabilidade de execução, mas a causa não foi isolada. Não descartar essa regressão nem atribuí-la automaticamente ao ambiente. Três repetições não sustentam garantia de FPS em outros computadores ou corridas longas. Sem resolução dinâmica ou remoção de recursos. Memória é o monitor estático do Godot, não RSS/VRAM; snapshots com zero órfãos não são prova geral de ausência de vazamento.

A série inicial solicitada em 1920 foi limitada pelo gerenciador de janelas a 1786×1005. Foi excluída e está em qa/race_state_0658/excluded_window_1786x1005. A série válida usa fullscreen e assert da resolução real. Capturas válidas acompanham os JSONs. O script final verifica dimensões em ambas as resoluções. O perfil mantém o campo version=0.6.5.7 do serviço de profiler herdado; os nomes base/new e project.godot identificam as versões comparadas.

## Históricos — microbenchmark separado
Mesmo campo de 24 carros, 120 montagens por amostra, 3 repetições, ordem alternada. Compara o laço antigo duplicate(true)+rota com RaceViewSnapshot.build, inclusive interpolação e comparação de estados. Históricos artificiais adicionados apenas à fixture, sem alterar o jogo. Cada entrada contém lap, time e array de pneus. A repetição usada foi sequencial, sem outras regressões simultâneas.

| Entradas artificiais por carro | Antes ms/frame | Depois ms/frame |
|---|---:|---:|
| 0 | 0.782 | 0.484 |
| 500 | 15.836 | 0.484 |

Este teste demonstra que a montagem compacta não percorre históricos. Não representa uma corrida com 500 voltas nem permite converter a redução em aumento equivalente de FPS.

## Paridade e limites
Todos os 12 hashes esportivos do benchmark nativo são iguais, incluindo estado dos carros, eventos e RNG. Quatro corridas comparativas de 3 voltas (24 carros) também produziram hashes idênticos: GBR seco, GBR chuva intensa, UAE seco e GER chuva intensa. UAE/GER foram sorteadas com random.Random(6558); as corridas usam seed 6557. Os hashes incluem clock/cars/events/pits. Verificados 24 finalizados, classificação sem duplicatas, tempos de volta positivos e as duas paradas da Ferrari. Não é benchmark de GP de 52 voltas nem de temporada; determinismo entre taxas diferentes continua pendente para 0.6.6.0.

## Reprodução
No diretório do projeto, com saves isolados:

```bash
XDG_DATA_HOME=/tmp/apex0658-check /caminho/Godot --headless --path . --script res://tests/view_0658_copy_benchmark.gd
XDG_DATA_HOME=/tmp/apex0658-native APEX_BENCH_WIDTH=1600 APEX_BENCH_OUTPUT=/tmp/native.json /caminho/Godot --path . --script res://tests/view_0658_benchmark.gd
```

Para comparar, use o mesmo arquivo absoluto view_0658_benchmark.gd com --path apontando à base 0657; repita com APEX_BENCH_WIDTH=1920. APEX_BENCH_SCREEN=1 grava captura. Paridade usa view_0658_race_parity.gd, APEX_BENCH_TRACK=GBR/UAE/GER, APEX_BENCH_WEATHER='Seco'/'Chuva intensa' e APEX_BENCH_OUTPUT. Evidências brutas e ambientes completos em qa/race_state_0658.
