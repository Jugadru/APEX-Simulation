# APEX Motorsport Manager v0.6.6.8.6 — Race Performance & Stability 2.0

## Escopo efetivo
Base: v0.6.6.8.5, SHA-256 `d582bc698a235bd5f945f8bdaecd407e3f47b36715bb19c215be5e92d34ba27c`. Godot 4.7.2, Linux.
**Core 2 segue como único motor esportivo oficial.** Next Engine continua suspensa. HUD ReBroadcast, 3D, Pit Wall, radio, replay e saves não mudaram.

## Diagnóstico e alteração
O Core 2 já entrega `old_order` ordenado. A função `RaceSpace.plan` (`scripts/core/race_space_0655.gd`) fazia novamente `filter` com lambda e `sort_custom` em todos os ticks, mesmo quando os 24 carros já estavam em ordem. A v0.6.6.8.6 filtra preservando a ordem e verifica progresso/ID antes de ordenar; caso receba uma lista fora de ordem, usa **o mesmo comparador original**. Este fast path não introduz RNG, não muda física, lane rules, gaps, heurísticas, resolução de tráfego ou regra de pit.

Corrigi também um **teste legado** (`tests/car_model_smoke_test.gd`): verificava `TaperedChassis` e `Rubber`, retirados quando os modelos evoluíram para `SculptedNose` e `RoundedSlick`. O modelo 3D não foi alterado. O teste de carros agora passa.

## Resultados esportivos
- Silverstone seco, Spa chuva intensa, Monza seco e Singapura chuva intensa: 750 ticks por pista, hashes em 1/80/250/500/750, eventos, checkpoints e ordem dos 24 IDs **idênticos** entre as versões.
- Monza 53 voltas / 24 carros / **24.431 ticks**: PASS. Hash final `2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b` corresponde à referência histórica.
- Replay integral de Monza (24.431 ticks): PASS; checkpoints e estado final reproduzidos, sem divergência.
- Racecraft (1.027 checks), Driver Dynamics (17), V21 (30), câmeras (18), replay curto (200 ticks), 3D (26), double stack e ordenação com empates/carros inativos: PASS.

## Desempenho — interpretação limitada
O teste direto do `RaceSpace.plan`, 175 chamadas por repetição, 5 repetições alternadas por pista, indicou medianas de **1.572 µs** (base) e **1.536 µs** (nova), cerca de **2,2% de economia no módulo**. Houve diferenças entre circuitos (Spa ~0,3% e Singapura ~4%). O teste completo de 2.000 ticks manteve o hash, mas sua variação de tempo não demonstrou ganho global consistente. Os ensaios de 750 ticks são comparações entre processos e sofrem ruído. **Não há prova de melhoria de FPS no PC do usuário.** Dados brutos em `APEX_06686_BENCHMARK_AB.json`.

## Gráficos e memória
Uma imagem 3D real da HUD COMPACT foi salva em 1600×900 usando llvmpipe/Xvfb e inspecionada. O processo gráfico não encerrou dentro do prazo: classificação INCONCLUSIVE para encerramento, PASS para captura. Na execução da corrida + replay, o pico de RSS (VmHWM) registrado pelo SO foi de **582.312 kB (~569 MiB)**; isso não representa consumo isolado do Core 2; não foi demonstrada ausência de vazamentos em temporadas completas.

## Integridade
2895 arquivos preexistentes preservados byte a byte. Apenas quatro arquivos existentes foram modificados: project.godot, scripts/core/race_space_0655.gd, scripts/main.gd, tests/car_model_smoke_test.gd. Os arquivos adicionais são testes, evidências e documentação. Não houve migração de saves nem alteração de contratos de replay.

## Limitações / pendências
- FPS da GPU real, cena 3D prolongada com múltiplas câmeras e resolução 1366×768 não homologados.
- Corridas de distância oficial em Silverstone/Spa/Singapura não realizadas nesta release.
- Save/carreira de múltiplas temporadas não exercitado nesta release.
- A otimização reduz trabalho evitável em ordenação, mas não resolve todos os gargalos de CPU no Racecraft, FPS ou render.

## Como executar / rollback
Extraia o ZIP em nova pasta, abra `project.godot` no Godot 4.7.2. O diretório `config/custom_user_dir_name` do jogo não foi alterado. Faça backup dos saves antes de testar. Para rollback, feche o Godot e abra a pasta **v0.6.6.8.5** preservada; não sobrescreva projetos nem saves.

Testes:
```bash
Godot_v4.7.2-stable_linux.x86_64 --headless --single-threaded-scene --editor --path . --import --quit
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/core2_06686_sort_contract.gd
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://qa/core2_06686/four_circuits_750.gd
Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/long_race_full_0663.gd
```

Não declarar a versão estável até que as regressões no hardware final e os testes pendentes sejam completados.

## Verificação da cópia distribuível
O primeiro ZIP foi reextraído em diretório limpo e importado no Godot 4.7.2 com `--headless --editor --import --quit` (exit 0). Novos testes de ordenação, carro 3D, V21 e quatro pistas (750 ticks) passaram novamente na cópia reextraída, com hashes iguais aos da pasta de desenvolvimento.
