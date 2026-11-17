# Núcleo de disputas — v0.5.4.3

## Contrato

`race_engine.gd` calcula o estado da prova e expõe `get_state_snapshot()`. Para cada tick de até 0,2s:

1. Congela o ranking dos carros via `duplicate(true)`.
2. Obtém os gaps e o ritmo estimado de cada carro no mesmo instante.
3. Executa a máquina de combate de cada piloto com a mesma base de dados, sem consumir RNG.
4. Move os carros, processa os boxes e registra voltas.
5. Atualiza posição, contador de manobras e eventos; o observador recebe o estado.

## Estados

| Estado | Significado |
|---|---|
| `clear` | Sem ameaça próxima |
| `closing` | Aproximação, ainda sem ataque pronto |
| `preparing` | Carga de ataque suficiente e vantagem de ritmo |
| `attacking` | Duelo em zona possível |
| `duel` | Etapa final da tentativa |
| `defending` | Carro da frente respondendo a uma tentativa |
| `recovering` | Intervalo entre ataques |

O resultado é **determinístico** (mesma semente, pista, parâmetros e comandos), mas não usa trajetória lateral. A posição é uma fração contínua do circuito. Um pequeno impulso de resolução, limitado a aproximadamente 0,06 segundo por volta, representa a manobra final após um duelo sustentado; **não** é uma simulação aerodinâmica exata ou um modelo de frenagem em cada curva.

## Parâmetros iniciais para calibrar

- Distância mínima de acompanhamento: `MIN_FOLLOW_DISTANCE = 0.00076` frações de volta.
- Energia de ataque mínima: `ATTACK_READY = 1.15`.
- Duração do duelo: `DUEL_SECONDS = 1.25`.
- Cooldown: `3.5` segundos após tentativa concluída.
- Zonas padrão: `[0.09,0.24]`, `[0.43,0.57]`, `[0.77,0.91]` da volta. Estas posições são **fictícias**, não correspondem a zonas oficiais FIA.
- Para especificar oportunidades por pista no futuro, preencher `track.overtake_zones` com faixas numéricas.

## Dados de telemetria e interface

Cada carro passa a expor `combat_state`, `combat_target_id`, `combat_attempts`, `combat_passes`, `combat_cooldown` e `attack_charge`. Apenas ataques efetivos geram `battle` no rádio. Ultrapassagens de posição continuam criando o evento de ranking `pass`; ganhos durante paradas não incrementam automaticamente o contador de duelos vencidos.

## Testes de aceite

- GDScript: `tests/core_0543_combat_smoke_test.gd`: duas corridas com semente igual produzem o mesmo progresso/desgaste/paradas; verifica pneus de Spa e faz uma tentativa de ultrapassagem isolada.
- Python: `tests/test_0543_static.py`: não há seletor Clássico nem regras alternativas; arquivos do Pit Lane/3D têm hashes esperados; novos contratos estão presentes.
- Manual: comparar corridas com mesma semente em 1× e 5×, conferir se o Pit Wall mantém comandos e se o 3D segue carros durante batalhas.

### Próxima etapa

v0.5.5.0: integração de clima e aderência real, só depois de estabilizar o motor único e validar os resultados do teste atual no Godot.
