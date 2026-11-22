# Pista de laboratório sintética — APEX Test Lab

A fixture `tests/fixtures/apex_lab_track.json` define um oval fechado de 32 segmentos,
4 voltas e 2,8 km/volta, com geometria criada exclusivamente para testes. **Não**
faz parte de `data/season_2012.json`, não aparece no calendário e não utiliza
tempos históricos oficiais. O teste `tests/apex_lab_track_smoke.gd` executa o
motor real Godot com 24 carros, duas condições climáticas, dois runs por
condição com seed fixa, hash esportivo repetível e proteção de ordem BOX manual.

O teste entra no FAST e no FULL do Core 2. Serve para encontrar falhas
óbvias em uma bancada reprodutível sem percorrer 20 circuitos. **Não substitui**
FULL-20, FULL-180, Mônaco, Silverstone, replays longos, comparações A/B e
resistência em GPs completos. O atraso de ~70 minutos observado no Gate
9.13 veio do polling de evidências inválidas e foi tratado no PR #99,
independentemente desta fixture.

## Perfilador de desempenho 2.0 (CPU headless)

O novo `tests/apex_lab_performance_probe.gd` usa **24 carros reais do Core 2**
no mesmo circuito sintético isolado, em 30 voltas de configuração de stress
(sem integrar o calendário). Executa `500 ticks x 2 repetições x 2 climas`
com seed fixa e coleta **custo médio por tick, p95, máximo, blocos inicial/final,
memória estática observada e segundos simulados por segundo de parede**.
Compara o hash esportivo entre as duas repetições de cada clima e reprova
nondeterminismo; não reprova por pequenas oscilações de CPU do runner.

O relatório validado por `tools/apex_lab_perf_report.py` é exportado como
artefato e resumo do Core CI, tanto em FAST como FULL, **sem mais um download
do Godot**. O perfilador mede CPU headless, não GPU, VRAM, FPS real ou
desempenho do computador do jogador. Benchmark A/B independente continua
necessário para regressões de custo entre commits.

### Otimização da matriz

No perfil de 20 pistas, os quatro shards agora podem executar em paralelo.
O perfil ampliado de 180 cenários conserva no máximo dois simultâneos para
limitar a pressão no runner. Nenhuma pista, hash, repetição, pit ou modo
manual/assistido/IA foi removido. A avaliação FULL continua obrigatória
para alterações esportivas críticas e releases que exigem cobertura 2012.

## Política FAST permanente

O Lab é o cenário sintético automático padrão em cada PR. A matriz 2012 e
homologações históricas agora só são acionadas quando solicitadas.
Os arquivos de testes antigos não são apagados; o seletor único de
subsistemas reaproveita os que realmente se aplicam à alteração.
