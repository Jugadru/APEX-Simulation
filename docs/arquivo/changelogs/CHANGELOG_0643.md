# CHANGELOG 0.6.4.3 — Dynamic Track Weather

**Base:** v0.6.4.2 Rival Development & Garage, sem reconstrução.

1. `scripts/core/race_weather.gd`: novo integrador hidrológico com chuva separada de água acumulada, umidade residual, drenagem por circuito, evaporação conforme clima e secagem acelerada na linha de corrida. `forecast()` integra as mesmas equações com cópia local.
2. `scripts/core/race_rain_hysteresis_0642.gd`: transições de pneus por água em mm e tendência, com entrada de dados compatível com versões antigas; chuva forte isolada não autoriza full-wet.
3. `scripts/core/race_ai_director.gd`: novas informações de água e umidade na validação das recomendações, sem modificar o sistema de box manual.
4. `scripts/core/race_performance.gd`: pequena contribuição da água fora da linha para refrigerar pneus intermediários/de chuva, sem fingir simulação de trajetória lateral.
5. `scripts/race_engine.gd`: evento de condição da pista distingue agora mm, umidade e precipitação. A matemática de cronometragem, linha de chegada e pit lane continua preservada.
6. `scripts/apex_race_hud_0622.gd`: indicador ao vivo de água/umidade/chuva e projeção da quantidade de água ~3 voltas adiante na Central de Dados.
7. Perfil `Chuva intensa`: chuva forte mais contínua, sem o seno de amplitude exagerada que fazia a pista alternar entre intermediários e chuva repetidamente.
8. `tests/core_0643_dynamic_track_weather_test.gd`, `tests/core_0643_heavy_pits_trace.gd`, `tests/core_0643_mal_pits_trace.gd` e `tests/core_0643_seed8240_gp_test.gd`: novos testes executáveis.

**Preservado:** desenvolvimento e orçamento das rivais, pesquisa P&D na oficina, controle por engenheiro, KERS/DRS e hotfix de voltas impossíveis.
