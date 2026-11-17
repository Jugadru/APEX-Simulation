# APEX Motorsport Manager — v0.6.6.2 Racecraft Telemetry 1.0

## Objetivo
Observar, classificar e auditar as disputas que **o motor realmente produziu**.
Nenhuma alteração de física, velocidade, pista, pneus, IA, RNG ou representação 3D.

## Interface programática
O controlador `scripts/core/race_replay_0660.gd` mantém um observador independente,
`scripts/core/racecraft_audit_0662.gd`, ativado por padrão. Ao fim de cada tick
com hash esportivo verificado, `racecraft_audit.observe(race, tick)` apenas lê o
estado. O resultado pode ser consultado por `session.racecraft_report()`.
O relatório é um `Dictionary` com schema `APEX_RACECRAFT_AUDIT_0662`.
As amostras recentes estão limitadas a 256 registros; os contadores continuam
acumulando durante o intervalo observado. Desligar a coleta com
`session.racecraft_audit_enabled = false` é permitido sem alterar o resultado.

## Métricas e interpretação
- `approaches`: transições de um piloto para estado `closing`, não uma tentativa.
- `attack_signals`, `defense_signals`, `yield_signals`: mensagens táticas
  já emitidas pelo motor, diferenciadas pela categoria no texto presente na
  v0.6.6.1; se o texto for alterado no futuro, revisar o interpretador.
- `duel_entries`: transições para `duel` (podem ocorrer várias vezes por batalha).
- `blocked_ticks`: somatório de observações dos carros bloqueados por corredor,
  em intervalos de 0,20 s; **não** corresponde a incidentes distintos.
- `confirmed_passes`: somente eventos `pass` sinalizados pelo motor após
  `combat_pass_pending`, com classificação alterada.
- `position_gains_other`: ganhos por boxes/ritmo distintos dos `pass`.
- `contacts` e `driving_errors`: eventos `contact` e `incident`, respectivamente.
- `drivers`: agrupamento por `driver_id`, nome e risco da ficha (baixo <40,
  equilibrado 40–69, alto >=70). `weather_and_risk` separa pista seca/molhada
  pelo mesmo limiar de 0,17 utilizado pelo motor para declaração de pista molhada.

O jogo pode registrar vários sinais de ataque antes de uma ultrapassagem, e
ultrapassagens não têm correspondência um a um com `attack_signals`. **Não**
interpretar `confirmed_passes / attack_signals` como probabilidade calibrada
nem usar as métricas para justificar mudanças artificiais da física.

## Replay e cobertura
- Mantido `simulation_revision=0661_driver_dynamics` e `format=APEX_REPLAY_0660`:
  novos campos **não são adicionados** ao save nem ao hash.
- `seek(0)` zera a análise; `seek(tick)` recalcula o trecho percorrido.
- Ao buscar um checkpoint intermediário, o relatório contém
  `coverage="since_checkpoint"` e `start_tick` diferente de zero. Para análise
  estatística da **corrida inteira**, reexecutar desde o checkpoint inicial.
- Um replay originalmente gravado na 0660 continua incompatível com 0661/0662,
  devido à mudança já realizada nas regras esportivas da versão anterior.

## Testes reproduzíveis no Linux
No diretório da instalação Godot 4.7.2:

```bash
./Godot_v4.7.2-stable_linux.x86_64 --headless --path /caminho/do/projeto --script res://tests/racecraft_0662_test.gd
APEX_TRACK=GBR APEX_WEATHER=Seco ./Godot_v4.7.2-stable_linux.x86_64 --headless --path /caminho/do/projeto --script res://tests/racecraft_0662_gp.gd
APEX_TRACK=ITA APEX_FULL=1 ./Godot_v4.7.2-stable_linux.x86_64 --headless --path /caminho/do/projeto --script res://tests/racecraft_0662_gp.gd
```

Os testes de GP registram os resultados em `qa/racecraft_0662` e comparam o
hash das corridas curtas com **os hashes guardados da 0661**.
A v0.6.6.1 original continua sendo o rollback e não foi modificada.
