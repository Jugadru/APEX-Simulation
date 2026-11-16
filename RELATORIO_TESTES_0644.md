# Relatório de verificação — Apex v0.6.4.4

**Fonte:** `APEX_0643_DYNAMIC_TRACK_WEATHER_GODOT(1).zip`, SHA-256 `cc1d2ff5f13177e2ecd57a5c7693887beca1760d13e04f7b5730b738243f2f96`.

**Godot instalado e efetivamente executado:** `4.7.2.stable.official.ed1daf0bf`, Linux x86_64, `--headless` e importação por editor. Nenhum erro de parser/importação na nova base.

## Rodada de oito GPs automáticos completos — 2012

Todas as oito provas terminaram, com **24 carros** cada. A bateria de carga chama `_advance(8.0)` diretamente, apenas para acelerar a verificação; a função `step()` do jogo segue subdividindo em **0,20 s**. O teste nativo verificou também 640 s de corrida com esse subpasso padrão.

| Circuito | Voltas | Asfalto °C (mín/máx) | Aderência (mín/máx) | Pits totais (24 carros) | Vencedor simulado |
|---|---:|---:|---:|---:|---|
| AUS | 58 | 33.3 / 37.2 | 1.075 / 1.110 | 44 | Sebastian Vettel |
| MAL | 56 | 26.5 / 37.4 | 0.742 / 0.758 | 70 | Sebastian Vettel |
| MON | 78 | 34.7 / 38.8 | 1.132 / 1.177 | 66 | Sebastian Vettel |
| GBR | 52 | 16.6 / 34.1 | 0.942 / 1.096 | 84 | Lewis Hamilton |
| BEL | 44 | 15.4 / 26.3 | 0.818 / 0.849 | 63 | Mark Webber |
| ITA | 53 | 37.8 / 41.7 | 1.027 / 1.062 | 22 | Sebastian Vettel |
| SIN | 59 | 25.7 / 43.9 | 0.919 / 1.031 | 104 | Sebastian Vettel |
| BRA | 71 | 35.6 / 40.2 | 1.061 / 1.110 | 38 | Sebastian Vettel |

Estas vitórias são da **simulação**, não os resultados históricos de 2012. Os perfis de abrasividade, tração e carga lateral são parâmetros de equilíbrio autorais do Apex, e não medições oficiais.

## Regressões efetivamente executadas (Godot 4.7.2)

- `track_0644_unit_test.gd`: 20 perfis, inércia térmica e borracha determinística, chuva lava borracha, seis compostos, slick/inter.
- `track_0644_native_tick_smoke_test.gd`: resolução real 0,20 s, 24 carros, tempo crescente, limites de temperatura/desgaste.
- `track_0644_hud_integration_test.gd`: cena completa, painel PNEUS com superfície/carcaça/graining e dados da pista.
- `core_0643_dynamic_track_weather_test.gd`: hidrologia, previsão, crossover slick/inter, emergência e BOX V21.
- `core_0642_rival_workshop_weather_test.gd`: orçamento, oficina, P&D e onze rivais, salvamento e evolução.
- `core_0638_1_timing_rootcause_test.gd`: hotfix de linha de chegada, ordem temporal, ausência de voltas impossíveis.
- `core_0631_radio_engineer_smoke_test.gd`: rádio, recomendações sem executar BOX V21, filtros e cooldown.
- `--headless --editor --import --quit`: importação e compilação bem-sucedidas.

Logs originais em `qa/`. O manifesto `BUILD_MANIFEST_0644.json` inclui hashes SHA-256 para 15 arquivos críticos preservados idênticos à v0.6.4.3.

## Limitações honestas

- Os GPs usam passo de 8 s para a bateria de carga; os resultados de pit/ultrapassagens **não** são calibração histórica e diferem em detalhe dos passos de 0,20 s. Apenas o smoke parcial usa a resolução normal.
- O modelo térmico é fenomenológico e usa janelas/sensibilidades de jogo; não é equivalente a um modelo físico profissional de seis graus de liberdade/temperaturas por roda.
- Não houve verificação visual manual em uma GPU do usuário, embora cena e HUD tenham sido instanciadas no Godot headless.
- Condições variáveis geraram muitas paradas, especialmente em Singapura e Silverstone. Balanceamento futuro recomendado, sem declarar as estratégias históricas como reproduzidas.
