# Apex Motorsport Manager v0.6.4.1 — Weather Strategy Balance

Base: **v0.6.4.0 — Pit Wall Intelligence**, importada do ZIP completo fornecido. O jogo não foi reconstruído.

## Defeito investigado

A simulação em modo Temporada automática (2012, semente 321) produziu 180 pits na Malásia, 115 na China e 127 na Espanha, todos com 24 carros. O gerador criava pancadas de chuva relativamente leves/moderadas, mas a equação de água na pista somava precipitação com fator `0.0095`, contra drenagem `0.0013 * wetness`. Até chuvas pouco intensas acumulavam água até 100%, impondo sucessivas trocas de slick, intermediário, chuva extrema e vice-versa.

## Correções no motor já existente

- `scripts/core/race_weather.gd`: intensidade de chuva *no modo Automático* limitada à faixa dinâmica de 0.28–0.75, em vez de 0.28–0.93; alteração de balanceamento do gerador, não teto no número de pits. Chuva intensa escolhida explicitamente e clima variável continuam disponíveis.
- Dinâmica de água e previsão: precipitação `0.0039`, drenagem `0.0020 * wetness`. `advance` e `forecast` usam os **mesmos coeficientes**, evitando divergências entre engenheiro e pista.
- `scripts/core/race_ai_director.gd`: recomendasções de transição de compostos exigem aderência compatível com a água atual: não sair precocemente de chuva extrema com pista ainda encharcada; não mudar para slick quando a pista continua muito molhada; não antecipar troca de slick para pneus de chuva por previsão remota em pista ainda seca e chuva fraca. Desgaste crítico continua podendo exigir pit.
- Preservação expressa de `scripts/race_engine.gd`: nenhuma alteração no hotfix contra cruzamento duplo da linha, na cronometragem, no KERS, nos pits manuais ou na classificação.
- Identificação atualizada para v0.6.4.1; Painel Pit Wall e modos Manual/Assistido/Automático mantidos.

## O que esta versão não faz

Não impõe máximo artificial de paradas; não altera ratings dos pilotos; não adiciona abandonos mecânicos ou pessoais. Esses assuntos exigem testes de balanceamento e regras dedicadas. Valores de clima e pneus são **parâmetros fictícios do Apex**, não telemetria oficial.

## Testes e evidências

Consultar `RELATORIO_0641_TESTES.md`, `tests/core_0641_weather_strategy_test.gd` e, no pacote de evidências separado, os oito resultados das corridas automáticas e os estados oficiais de campeonato.
