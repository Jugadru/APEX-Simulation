# Apex Motorsport Manager v0.6.4.1 — RELATÓRIO DE TESTES E BALANCEAMENTO

**Base:** v0.6.4.0 — Pit Wall Intelligence. **Godot:** v4.7.2.stable.official.ed1daf0bf (execução local Linux x86_64). **Cenário:** Ferrari, temporada 2012, clima Automático, dois pilotos/STAFF e box 100% Automático, níveis de equipamento e funcionários 0, seed 321 + 7919 × índice da etapa.

## Causa raiz observada

No clima automático da v0.6.4.0 a equação de água usava precipitação `chuva * 0.0095` e drenagem `0.0013 * água`; uma única chuva moderada podia elevar a água da pista a 100%, provocando sucessivas transições slick → intermediário → chuva extrema → intermediário → slick. O cálculo de janela curta da IA também permitia recomendações de transição antes de uma aderência segura.

## Mudanças implementadas

- `scripts/core/race_weather.gd`: fator de precipitação 0.0039 e drenagem 0.0020 × água; mesmo modelo usado por previsão e simulação; chuvas automáticas com potência sorteada entre 0.28 e 0.75 (em vez de 0.28–0.93). Essas são escolhas de balanceamento do Apex, não dados FIA.
- `scripts/core/race_ai_director.gd`: evita trocas precoces entre chuva extrema e intermediário na pista ainda muito encharcada; evita slick em água alta e evita pneus molhados por previsão distante sem água na pista. Desgaste crítico continua prioritário.
- `scripts/race_engine.gd`: preservado **byte a byte**, SHA-256 `03faf04f2697d9491ab136232f0843ccbeb6fb665c0200944014cb7ca8538b6c`, mantendo a correção contra dupla passagem pela linha de chegada.
- `project.godot`, `scripts/main.gd`, `scripts/apex_race_hud_0622.gd`: atualização apenas da identificação da versão.
- `tests/core_0552_tyre_ai_smoke_test.gd`: corrigida asserção histórica já desatualizada (também falhava na v0.6.4.0), de 63% para 66% de desgaste para cenário a dois laps do cliff de pneu Chuva; nenhuma regra de desgaste foi alterada para satisfazer o teste.

## Comparação corrida a corrida — 24 carros por GP

| GP | Voltas | Vencedor | Alonso | Massa | Pits 0.6.4.0 | Pits 0.6.4.1 | Mudança | Água máx. observada |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| Austrália | 58 | Sebastian Vettel | P2 | P7 | 48 | 48 | +0 | 0% |
| Malásia | 56 | Sebastian Vettel | P2 | P14 | 180 | 95 | -85 | 89% |
| China | 56 | Sebastian Vettel | P4 | P6 | 115 | 72 | -43 | 23% |
| Bahrein | 57 | Sebastian Vettel | P4 | P9 | 48 | 48 | +0 | 0% |
| Espanha | 66 | Sebastian Vettel | P5 | P9 | 127 | 48 | -79 | 9% |
| Mônaco | 78 | Mark Webber | P4 | P9 | 72 | 72 | +0 | 0% |
| Canadá | 70 | Sebastian Vettel | P5 | P10 | 72 | 72 | +0 | 0% |
| Europa (Valência) | 57 | Sebastian Vettel | P8 | P10 | 36 | 36 | +0 | 0% |

**Resultado: 698 → 491 pits, redução de 207 (29.7%).** A média passou de 3.64 para 2.56 paradas por participante.

A água máxima foi amostrada a cada mudança de volta do líder e serve como diagnóstico; o teste de hidrologia fornece os máximos de integração diretamente. Corridas sem chuva mantiveram as paradas anteriores.

## Classificação de pilotos (modo Temporada, salva e recarregada)

| Pos. | Piloto | Pontos |
|---:|---|---:|
| 1 | Sebastian Vettel | 175 |
| 2 | Lewis Hamilton | 114 |
| 3 | Mark Webber | 112 |
| 4 | Jenson Button | 110 |
| 5 | Fernando Alonso | 96 |
| 6 | Kimi Räikkönen | 53 |
| 7 | Nico Rosberg | 35 |
| 8 | Michael Schumacher | 29 |
| 9 | Romain Grosjean | 27 |
| 10 | Felipe Massa | 22 |
| 11 | Nico Hulkenberg | 17 |
| 12 | Sergio Perez | 14 |
| 13 | Bruno Senna | 4 |
| 14 | Charles Pic | 0 |
| 15 | Daniel Ricciardo | 0 |
| 16 | Heikki Kovalainen | 0 |
| 17 | Jean-Eric Vergne | 0 |
| 18 | Kamui Kobayashi | 0 |
| 19 | Narain Karthikeyan | 0 |
| 20 | Pastor Maldonado | 0 |
| 21 | Paul di Resta | 0 |
| 22 | Pedro de la Rosa | 0 |
| 23 | Timo Glock | 0 |
| 24 | Vitaly Petrov | 0 |

## Construtores

| Pos. | Equipe | Pontos |
|---:|---|---:|
| 1 | Red Bull Racing Renault | 287 |
| 2 | McLaren Mercedes | 224 |
| 3 | Ferrari | 118 |
| 4 | Lotus Renault | 80 |
| 5 | Mercedes | 64 |
| 6 | Force India Mercedes | 17 |
| 7 | Sauber Ferrari | 14 |
| 8 | Williams Renault | 4 |
| 9 | Caterham Renault | 0 |
| 10 | HRT Cosworth | 0 |
| 11 | Marussia Cosworth | 0 |
| 12 | Toro Rosso Ferrari | 0 |

## Auditoria de integridade

- **8 GPs concluídos**, 498 voltas previstas somadas, 192 entradas de participantes (24 carros × 8 GPs), todos em modo Automático.
- **Zero voltas inválidas** e **zero retrocessos de progresso** nos oito relatórios.
- **KERS máximo de 400 kJ por volta** registrado no motor; teste separado dos três modos de energia passou.
- **Campeonato oficial:** oito resultados `record_result()` confirmados, save/load a cada rodada, pontuação validada, tentativa de duplicidade recusada; próximo GP **Silverstone (GBR), 9º de 20**.
- **16 regressões automatizadas passaram**, cobrindo chuva, IA, desgaste de pneus, KERS, cronometragem/hotfix, pits, rádio, Pit Wall e HUD.
- **Godot 4.7.2:** importação no editor e execução gráfica em tela virtual Xvfb (1600×900), sem erros de script. Áudio ALSA não disponível no ambiente, com fallback para dispositivo nulo.

## Pontos de atenção ainda não resolvidos

- Sebastian Vettel venceu **7 de 8 GPs** e liderou com **175 pontos**. A performance das equipes não foi modificada; testar várias sementes antes de reequilibrar os ratings.
- **Nenhum abandono** nos oito GPs. O motor ainda não oferece um sistema de falhas mecânicas e retiradas suficientemente realista; será uma etapa de engenharia separada.
- A redução de pits é demonstrada **nesta semente e nestas oito etapas**; não prova que todas as demais pistas e sementes estejam balanceadas. Uma chuva intensa real pode legitimamente exigir mais paradas.
- Cada corrida foi executada em processo Godot headless separado e **registrada pelo sistema real de Temporada**, com persistência entre rodadas. Não houve oito navegações manuais por menus com F5; tampouco foi testada uma instalação no Linux Mint do usuário.

## Evidências

Os arquivos `GP_01.json` a `GP_08.json` contêm classificação integral, pits individuais, telemetria climática resumida por volta, limites KERS e erros. `CAMPEONATO_APOS_GP_*.json`, `CAMPEONATO_CONSOLIDADO.json` e `CAMPEONATO_COMMIT.log` comprovam progressão e persistência do campeonato. Consulte também `REGRESSOES_0641.json` e logs anexos no ZIP de evidências.
