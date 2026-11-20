# APEX Motorsport Manager v0.6.1 — HUD + Clima + 32×

Base: v0.6.0 experimental, que o usuário confirmou somar pontos na temporada.

## Correção principal
- Mantidos os **20 circuitos distintos** do calendário de 2012. Ao iniciar um GP da temporada, o circuito selecionado é confrontado com o código da etapa salva; se diferir, a largada é recusada com mensagem de sincronização. Essa proteção não altera a ordem do calendário nem apaga salvamentos.
- Clima automático deixou de usar **ondas sinusoidais periódicas em todos os GPs**. Passou a criar **zero, um ou dois episódios de chuva por prova**, determinados pela semente + código do circuito. Uma corrida em local úmido pode ser totalmente seca.
- Incluídos perfis de risco por GP: por exemplo Sepang 47%, Spa 44%, Silverstone 42%, Bahrain 3,5%, Abu Dhabi 2,5%. **São valores experimentais do jogo, não percentuais medidos em 2012 nem retirados dos jogos F1 2020/F1 Manager.**
- A previsão de risco e a intensidade atual de chuva permanecem separadas. Os perfis manuais Seco/Variável/Chuva intensa permanecem para testes.

## Nova HUD v0.6.1
- Viewport base 1920 × 1080, mantendo janela inicial 1600 × 900 para monitores menores.
- Nova visão "Aérea estratégica" usando câmera de helicóptero existente, não um segundo motor de simulação.
- Minimapa 2D contextual sobre o 3D, com botão ABRIR para mapa estratégico integral.
- Botão PILOTO exibe painel com pneus, desgaste, tempos, situação do box e foco de câmera. Clicar num piloto da tabela abre o painel.
- Controles de painel/esconder preservados, e posicionamento adaptativo para não sobrepor as barras laterais.
- Botão de velocidade 32× adicionado. Em Auto F1M, 5×/10×/16×/32× utiliza mapa estratégico 2D. A simulação continua dando passos internos de até 0,2s; 32× pode reduzir FPS em computadores lentos.

## Preservado
- `scripts/race_engine.gd`, `scripts/championship_2012.gd`, `scripts/track_map.gd`, `scripts/track_3d.gd`, `scripts/tv_director.gd`, `scripts/garage.gd`, `scripts/core/race_team_autonomy.gd` e dados de 2012 sem alterações.
- Pontuação 2012, carreira salva, STAFF, pit stops Manual/Automático.

## Limitações
- O ambiente de construção não tem Godot instalado e não conseguiu baixá-lo; **não foi feita execução da interface e dos testes GDScript**. O projeto é experimental.
- Probabilidades de chuva precisam de calibração com dados históricos por mês, circuito e década. Ainda não representam climatologia oficial.
- O render 3D continua simplificado e 32× depende do desempenho do computador.

## Testes
- 30 scripts Python existentes: todos passaram.
- 1 teste estático v0.6.1: passou.
- Teste Godot `tests/core_0610_weather_and_speed_test.gd`: criado, não executado aqui.
- ZIP CRC e conteúdo: verificados.

Arquivos existentes alterados: project.godot, scripts/core/race_weather.gd, scripts/main.gd.
Arquivos novos: linux/validar_0610.sh, tests/core_0610_weather_and_speed_test.gd, tests/test_0610_static.py.
