> **Arquivo histórico:** descreve versões anteriores com motor Clássico. Na v0.5.4.3 o modo Clássico foi removido; consulte `README.md` e `docs/CORE2_COMBATE_0543.md` para instruções atuais.

# APEX Core 2 — arquitetura de transição

## Objetivo da fase 0.5.4.0

Reduzir o acoplamento entre a simulação e a interface **sem jogar fora o simulador, a telemetria e os sistemas de boxes testados**. A versão 0.5.4.0 é uma primeira migração funcional. Não representa a física final do Apex.

## Limites e módulos

| Módulo | Responsabilidade | Conectado em |
|---|---|---|
| `core/race_rules.gd` | perfis e dados de compostos/ritmos | `race_engine.gd`, módulos |
| `core/race_performance.gd` | ritmo, desgaste, calor de pneu e ar sujo | `_advance` |
| `core/race_combat.gd` | carro da frente e limites de ultrapassagem | `_advance` |
| `core/race_strategy.gd` | escolha do composto de parada da IA | `_on_lap_cross` |
| `core/race_pit_math.gd` | durações e bônus da equipe | `_begin_pit`, `get_pit_crew_effects` |
| `race_engine.gd` | estado central, integração temporal, parada em boxes e eventos | consumo por HUD/TV/telemetria |
| `apex_telemetry.gd` | observador; CSV e JSON | motor + Pit Wall |
| `main.gd` | entrada de comandos e exibição; não calcula posições | interface |

`get_state_snapshot()` retorna uma cópia independente do estado da corrida. O padrão a consolidar é: *simulação produz estado -> telemetria e HUD leem estado -> ações do jogador alteram a simulação via métodos públicos.*

## Dois perfis

**Clássico:** preserva as fórmulas da 0.5.3.3. O teste de regressão compara a corrida antiga, incorporada como fixture, com a nova (mesma seed, equipes, pista e ordens). A comparação deve cobrir progresso, desgaste, stints, paradas, classificação e histórico de eventos.

**Core 2 experimental:** habilita uma contribuição reversível de calor no desgaste e no tempo por volta, ar sujo e carregamento de ataque antes da ultrapassagem, além de estratégia de pit baseada em desgaste. Coeficientes iniciais são **hipóteses de balanceamento**, não telemetria FIA. O modo é determinístico para a mesma seed e mesmas ordens.

O clima **não influencia** o tempo por volta em 0.5.4.0. Não anunciar "pista molhada real" até haver sistema de pneus intermediários, chuva e físicas correspondentes.

## Dependências mantidas

- Animação de boxes, double stack, falhas e serviço continuam no `race_engine.gd` por compatibilidade, agora com matemática do pit isolada.
- `track_map.gd`, `track_3d.gd`, `pit_complex_3d.gd`, `car_model_3d.gd`, `tv_director.gd`, `garage.gd` e o sistema de telemetria não foram alterados.
- O renderizador **Compatibility** permanece padrão para funcionar em Linux Mint com mais GPUs. `tools/choose_renderer.py` ativa Forward+ opcionalmente, com backup local de `project.godot`.

## Mapa das próximas migrações

1. **0.5.4.1**: migrar fluxo de Pit Lane para máquina de estados independente, com regressão visual e temporal.
2. **0.5.4.2**: pistas com parâmetros declarativos de aderência/abrasão e pneus por temporada (não chamar C4/C3/C2 de históricos em 2012).
3. **0.5.4.3**: ações e coordenadas por trecho; substituir ultrapassagem por um estado de ataque/defesa com distância e tempo contínuos.
4. **0.5.5.0**: chuva e água de pista com influência física, calibradas com dados apropriados.
5. **Depois**: benchmark C#/.NET se o profiler do Godot apontar gargalo real; áudio de comentário e SNS podem ouvir eventos já consolidados.

## Como validar

```bash
# Offline
python3 tests/test_0540_static.py
python3 tests/test_0540_math.py

# No Godot 4, dentro da pasta do projeto
# Comparação paritária entre o motor original e o modular (sem renderização)
godot --headless --path . --script res://tests/core_0540_parity_test.gd
# Duplicação determinística e invariantes de Core 2 experimental
godot --headless --path . --script res://tests/core_0540_experimental_test.gd
# Testes anteriores de telemetria e pit
godot --headless --path . --script res://tests/telemetry_0533_smoke_test.gd
```

Não misture pastas de versões diferentes durante a verificação. O script de benchmark no Godot deve registrar a versão, seed, modo e caminho da pasta antes da execução.


## Continuação 0.5.4.1 — Pit Lane independente

O avanço temporal dos pit stops foi transferido para `scripts/core/race_pit_lane.gd`. O motor principal mantém as responsabilidades sensíveis à seed: incidentes, posse de garagem, eventos e conclusão de troca.

A comparação estática usa uma cópia imutável do motor 0.5.4.0. A comparação **em execução** usa os mesmos comandos, seeds e perfis nos dois motores (`tests/core_0541_pit_parity_test.gd`).

O próximo estágio não deve alterar a física sem antes executar e aprovar esses testes no Godot. A conexão da chuva com a aderência continua planejada, não concluída.
