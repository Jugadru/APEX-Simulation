# APEX Race Intelligence Tester — Melhoria 9/10

## Objetivo
Detectar **regressões mensuráveis** nas decisões do Pit Wall, estratégia de pneus,
controle manual e consistência da IA. Os testes não alegam julgar a inteligência
de um piloto humano ou comprovar realismo esportivo completo.

## Cenários reais

No Godot 4.7.2, sem HUD, testamos **10 voltas com 24 carros** por cenário:
- **Monza seco, seed 660, jogadores com pit automático (IA)**.
- **Silverstone chuva intensa, seed 661, pit automático (IA)**.
- **Monza seco, seed 662, controle manual**, com reserva explícita de box
  na **volta 7**, que não pode ser antecipada.

Cada cenário roda **duas vezes**, com diretórios de usuário Godot isolados.
Comparamos hash esportivo, ticks, pits, ultrapassagens registradas e rádio
observado. Divergência de resultados determinísticos reprova a CI.

Antes da corrida, executamos quatro testes existentes no repositório:
1. `core_0552_tyre_ai_smoke_test.gd`: desgaste e escolhas de compostos.
2. `core_0570_ai_director_smoke_test.gd`: planejamento, previsão, chuva e
   bloqueio de double stack quando seguro.
3. `lap_strategy_06496_auto_gate_test.gd`: IA pode agir quando elegível;
   controle manual e agendamentos permanecem protegidos.
4. `pitwall_0667_same_tick_regression.gd`: comandos manuais simultâneos
   e fila de agendamento de dois carros.

## O que é bloqueante
- Falha de execução, cenário ou marcador de resultado ausente.
- Não terminar a corrida; classificação incompleta ou pneus com valores inválidos.
- Inexistência de chuva no cenário molhado.
- Reserva manual V7 executada antes ou em outra volta.
- Hash esportivo ou outros resultados determinísticos diferentes nas 2 repetições.
- Falha das quatro provas existentes do Pit Wall/IA.

## O que é somente observacional
- Quantidade de ultrapassagens e mensagens de rádio.
- Número de pits dos adversários; distribuição de decisões automáticas.
- Frequência dos planos de estratégia e de eventos.
  Um número baixo não é automaticamente bug ou ausência de personalidade;
  é preciso investigar com evidências da corrida.

## Como executar
Após disponibilizar o PR, abra no GitHub **Actions → APEX - Race Intelligence
Tester** e execute o workflow pela interface, ou acione por alteração de
código no PR. O artefato `apex-race-intelligence-relatorios` contém
`report.json`, `report.md` e logs de cada execução, com retenção de 14 dias.

**Limites:** testes headless curtos em duas pistas; não cobrem 3D,
câmeras, locução gravada, FPS, campeonato inteiro, mercado de pilotos ou
cobertura estatística de centenas de seeds.

## Preservação
Esta melhoria só adiciona teste GDScript, ferramentas Python, documentação
e workflow. Não altera os scripts de produção, saves, replays ou dados
históricos. Revisão e merge seguem manuais.


**Execução segura em CI:** o GitHub Actions inicia os cenários Godot como comandos explícitos, com perfis HOME/XDG isolados. O código Python apenas lê logs nomeados e valida resultados e hashes, sem iniciar processos externos. A regressão visual só é acionada quando forem alterados arquivos de apresentação ou a fixture de captura.
