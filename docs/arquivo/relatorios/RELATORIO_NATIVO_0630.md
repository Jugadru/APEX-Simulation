# Validação nativa — v0.6.3.0

**Executável:** Godot 4.7.2.stable.official.ed1daf0bf (Linux x86_64) fornecido pelo usuário.

| Verificação | Resultado |
|---|---|
| Importação no editor, `--headless --editor --quit` | EXIT 0, sem erro de parse |
| `core_0630_driver_radio_smoke_test.gd` | PASS, incluindo clima, desgaste, cooldown, filtros e box manual V21 |
| `core_0625_dry_strategy_smoke_test.gd` | PASS, estratégia China/Austrália |
| `core_0627_tv_director_smoke_test.gd` | PASS, modos TV e Livre |
| `core_0629_environment_smoke_test.gd` | PASS, ambientes Bahrain/Sepang/Monaco/Silverstone |
| Inicialização gráfica em Xvfb, OpenGL por software | EXIT 0, sem erros de script, avisos de layout preexistentes |
| Comparação com v0.6.2.9: 240 etapas de 4 s em Spa, seed 141, tempo variável | IGUAL nos 24 carros: posições físicas, desgaste, pneus, pedidos e paradas; alcança a volta 9 |
| Comparação longa de 800 etapas | Inconclusiva: execução excedeu o limite do ambiente |

A mudança adiciona eventos de rádio ficcionais e dois campos de controle de frequência de relatório nos carros. O motor original continua responsável por todo o cálculo da corrida. Não foram modificados: mapas, circuitos, modelos de carro, oficina, KERS, DRS, estratégia, clima, chuva, IA dos boxes, pit-lane ou as três câmeras.
