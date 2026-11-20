# RESULTADOS VERIFICADOS — v0.6.4.3

Motor de testes: **Godot 4.7.2 estável para Linux x86_64**. Base extraída e conferida do ZIP original v0.6.4.2.

## Resultado da reengenharia

O Apex v0.6.4.2 já possuía `wetness` (0–1), mas representava a água com **um único escalar**, sem separar filme residual, água em mm e diferença entre a linha de corrida e o restante do asfalto. A v0.6.4.3 introduz estados independentes para os quatro fenômenos, todos presentes em snapshots e previsões.

O engenheiro continua decidindo pelas mesmas estruturas de estratégias existentes; foi alterada somente a política de transição para exigir água mensurada no estado simulado. A umidade residual afeta a indicação de pista e a aderência; a água da linha influencia pneus, ritmo e pit stops. A área fora da linha contribui modestamente para resfriar pneus molhados.

## Testes reais no Godot

- `core_0643_dynamic_track_weather_test.gd`: PASSOU — chuva não equivale à água acumulada; após a chuva a água permanece; linha seca mais rápido; previsão não modifica estado real e reproduz integração; IA evita trocas por chuva isolada, permite trocas com água suficiente, mantém emergência e protege BOX V21; HUD nativa mostra umidade e mm.
- `core_0641_weather_strategy_test.gd`: PASSOU — faixas de probabilidade/nível, chuva forte, previsão e estratégia com desgaste crítico.
- `core_0642_rival_workshop_weather_test.gd`: PASSOU — P&D, orçamento e desenvolvimento das rivais mantidos.
- `core_0640_pitwall_intelligence_test.gd`: PASSOU **em perfil de salvamento isolado**, para evitar herdar uma carreira criada pelo teste anterior.
- `core_0638_1_timing_rootcause_test.gd`: PASSOU — teste de dupla passagem pela linha e replay do incidente; 0 voltas inválidas.
- `core_0638_1_mini_gp_test.gd`: PASSOU — mini-GPs no seco e chuva com pits agendados nas voltas corretas.
- `core_0561_energy_balance_test.gd`: PASSOU — KERS dentro do limite e modo de energia funcional.
- `core_0570_ai_director_smoke_test.gd`: PASSOU — plano de stint, box e previsão.
- `core_0551_wet_balance.gd`: PASSOU — cruzamento de pneus e vantagem relativa de intermediários/chuva.
- `core_0552_tyre_ai_smoke_test.gd`: PASSOU — pneus e box por desgaste (reexecutado após o ajuste final de clima).
- `pit_lane_regression_test.gd`: PASSOU — continuidade da pit lane.
- `core_0622_corner_hud_smoke_test.gd`: PASSOU — painéis/câmera e layout.
- `core_0632_engineer_interactive_smoke_test.gd`: PASSOU — rádio consultivo e HUD.
- `core_0639_race_engineer_test.gd`: PASSOU — integração do Race Engineer com ordens manuais, automáticas e rádio.
- `core_0637_reactive_radio_smoke_test.gd`: PASSOU — rádio reativo e proteções de estado.
- Abertura gráfica em **Xvfb 1600×900** e captura nativa da Central de Dados: PASSOU; sem dispositivos de áudio no ambiente virtual, com aviso ALSA e fallback de áudio.

## Corridas completas de verificação

- **Interlagos/BRA, 71 voltas, 24 carros, chuva intensa, auto, seed 321:** corrida concluída; 90 pits; 0 voltas inválidas; KERS e cronometragem regressão mantida. Vencedor Mark Webber; 1694 passos, tempo de simulação 6776 segundos. O perfil anterior de chuva intensa da **mesma build de trabalho antes do ajuste** registrou 120 pits; nova versão = **25% menos**.
- **Interlagos/BRA, 71 voltas, 4 carros, chuva intensa, auto, seed 321:** 20 pits antes do ajuste e 15 após (mesma redução de 25%); nenhuma limitação arbitrária de número de paradas.
- **Malásia/MAL, 56 voltas, 24 carros, Automático, seed 8240 (semente da 2ª etapa da carreira):** corrida concluída, 96 pits, 0 voltas inválidas, 1522 passos de simulação, vencedor Sebastian Vettel. Cada carro parou em média quatro vezes; dois períodos separados de chuva explicam os cruzamentos secos/intermediários.
- **Malásia/MAL, 56 voltas, 24 carros, Automático, seed 321:** 24 pits; zero voltas inválidas, corrida concluída. Esta semente produziu condições diferentes. Não é correto comparar seus 24 pits diretamente com a semente 8240.
- **Interlagos/BRA, 71 voltas, 24 carros, SECO, pits manuais, seed 321:** corrida concluída, 48 pits na grid; 0 voltas inválidas; Ferrari parou exatamente V23/V25 e V48/V50; vencedor Fernando Alonso. Confirmado após reconstrução da hidrologia.

Todos esses GPs foram executados pelo Godot (scripts de testes incluídos), não por inspeção estática. São simulações de jogo, não resultados históricos da temporada 2012.

## Análise importante dos pits

Malásia com semente de campeonato **8240**, perfil automático: o modelo criou **duas pancadas de chuva distintas**; num teste com quatro carros, cada um parou quatro vezes, de forma coerente com os períodos de pista seca/molhada/seca/molhada/seca. O objetivo não é impor um máximo artificial de pit stops e sim evitar trocas de pneus sem água suficiente ou oscilações meteorológicas artificiais. Em chuva intensa contínua o teste específico melhorou a estabilidade de pneus.

## Limitações verificáveis

Não foi executada a temporada inteira de 20 GPs na v0.6.4.3 nem uma inspeção presencial no Linux Mint do usuário. A pista mantém uma aproximação global, não um mapa físico de poças por curva. O modelo é inspirado em **conceitos de gameplay** dos jogos F1, sem copiar software, assets ou parâmetros proprietários.

## Integridade da base

Funções `_record_lap_cross()` e `_on_lap_cross()` idênticas às da v0.6.4.2; o único ajuste em `scripts/race_engine.gd` foi a mensagem textual do evento meteorológico. O hotfix de cronometragem não foi reimplementado.
