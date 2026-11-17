# APEX MOTORSPORT MANAGER — Auditoria v0.6.5.6 e plano de engenharia v0.6.5.7+

**Base analisada:** `APEX_MOTORSPORT_MANAGER_v0.6.5.6_LIVING_FACTORY_2_COMPLETO.zip`  
**Motor validado:** Godot 4.7.2.stable.official.ed1daf0bf  
**Status:** planejamento técnico, sem alteração do código de produção da versão 0.6.5.6.

## 1. Estado real da versão recebida

- `project.godot`: identifica v0.6.5.6 / Living Factory 2.0.
- Oficina operacional implementada em `scripts/core/workshop_0656.gd`, persistência transacional em `scripts/garage.gd` e apresentação em `scripts/apex_workshop_0656.gd`.
- Já existem sistemas de ultrapassagem e espaço de corrida (`scripts/core/race_space_0655.gd`, `scripts/core/race_combat.gd`), personalidade e rádio (`race_driver_soul_0647.gd`, `race_soul_driver_0636.gd`, `race_soul_reactive_0637.gd`), Staff, estratégia, Pit Wall e simulador estratégico. **Não recriar do zero.**
- A oficina v0.6.5.6 não altera desempenho do carro em pista; sua condição é diagnosticada com base em quilometragem conhecida, conforme relatório da entrega.
- O README principal ainda abre indicando v0.6.5.5, embora o projeto e relatório identifiquem 0.6.5.6. Atualizar documentação em futura entrega.

## 2. Validação realizada neste ambiente

| Checagem | Resultado |
| --- | --- |
| Leitura CRC do ZIP | OK |
| SHA-256 dos 1.623 arquivos do `BUILD_MANIFEST_0656.json` | 1.623 corretos, 0 divergências |
| Godot 4.7.2 `--headless --editor --import --quit` | Código de saída 0 |
| `tests/workshop_0656_test.gd` | PASS |
| `tests/workshop_0656_edges.gd` | PASS |
| `tests/workshop_0656_integration.gd` | PASS |
| `tests/workshop_0656_legacy.gd` | PASS |
| `tests/sim_engine_0655_test.gd` | PASS |

**Limites:** Não foram executados nesta auditoria GPs completos, testes de desempenho em GPU física ou captura 3D em máquina do jogador. Logs locais das cinco execuções em `/mnt/data/apex_audit_0656/`.

## 3. Hipóteses de gargalo a medir (AINDA NÃO COMPROVADAS)

1. `scripts/main.gd:726–766`: a cada frame, gera `draw_cars` duplicando profundamente (`driver.duplicate(true)`) o dicionário de cada piloto e consulta a rota múltiplas vezes; trabalho repetido mesmo quando algumas vistas estão ocultas.
2. `scripts/track_map.gd:75–94`: `direction_on_track()` usa duas chamadas a `point_on_track()`, que por sua vez faz busca binária. Em `main.gd` existe ainda consulta separada de posição. Medir antes de cachear/interpolar em uma única consulta.
3. `scripts/race_engine.gd:449–510`: a cada tick da simulação (passos de 0,2 s), gera cópias profundas de estados de carros em `old_order`. Essas cópias protegem a lógica de ordem e determinismo; NÃO substituir sem provar equivalência.
4. `scripts/core/race_space_0655.gd:53–75`: avaliação de proximidade percorre os carros e os oponentes (custo quadrático). Com ~24 carros isso pode ser aceitável; medir primeiro.
5. `scripts/track_3d.gd:151+`: atualização visual por carro, animações e criação eventual de elementos de cena. Separar CPU de GPU e distinguir custo único de inicialização de custo recorrente.
6. `scripts/apex_race_hud_0622.gd` tem ~1.941 linhas. A manutenção pode ser complexa, mas tamanho de arquivo não é prova de lentidão. Antes de dividir, inspecionar frequência de refresh e sinais.

## 4. Roteiro atualizado, uma mudança principal por versão

### v0.6.5.7 — Performance Profiler 1.0 (MEDIR, NÃO OTIMIZAR)

**Objetivo:** criar instrumentação temporizável para saber onde o APEX gasta CPU e quanto tempo de jogo simulado avança por segundo real.

Novos arquivos propostos:
- `scripts/debug/apex_perf_trace_0657.gd`: cronômetro de seções com agregados (média, máximo, chamadas), **desligado por padrão**.
- `tests/perf_0657_race_cpu.gd`: benchmark de simulação sem renderização, 24 pilotos, pista seca e chuva, mesma seed.
- `tests/perf_0657_visual.gd`: diagnóstico com cena real, contagens de atualização de mapas/3D/HUD, quando houver ambiente gráfico.
- `docs/BASELINE_PERFORMANCE_0657.md`: versão do motor, hardware, renderer, FPS, tempos em ms e método de coleta.

Seções instrumentadas: `race.step`, `RaceSpace.plan`, snapshot/cópias de `old_order`, montagem `draw_cars`, projeção na rota, `world_view.set_race_cars` e `_update_game_ui`.

**Critérios de aprovação:** import Godot limpa; teste Silverstone consistente; testes Living Factory preservados; instrumento OFF não altera física, resultados, RNG ou saves; resultados registrados e reprodutíveis (mesmas seeds, mesmo hardware).

**Esboço de código (não integrado):**
```gdscript
extends RefCounted
class_name ApexPerfTrace

var enabled := false
var totals_us: Dictionary = {}
var calls: Dictionary = {}
var peaks_us: Dictionary = {}

func begin() -> int:
    return Time.get_ticks_usec() if enabled else 0

func end(section: String, started_us: int) -> void:
    if not enabled:
        return
    var duration := maxi(0, Time.get_ticks_usec() - started_us)
    totals_us[section] = int(totals_us.get(section, 0)) + duration
    calls[section] = int(calls.get(section, 0)) + 1
    peaks_us[section] = maxi(int(peaks_us.get(section, 0)), duration)

func mean_ms(section: String) -> float:
    var n := int(calls.get(section, 0))
    return 0.0 if n == 0 else float(totals_us[section]) / float(n) / 1000.0
```

### v0.6.5.8 — Apresentação de estado eficiente

**Só implementar se o profiler confirmar custo relevante.** Evitar cópias profundas para a camada visual usando um estado compacto apenas com chaves realmente consumidas pelos mapas/câmeras; verificar todas as referências antes de reduzir campos. Mapas invisíveis não devem refazer trabalho desnecessário. Manter estado matemático do motor intacto.

**Critério:** mesma saída de simulação, tempos de render medidos antes/depois na mesma máquina; regressões de HUD e câmeras.

### v0.6.5.9 — Geometria da pista com cache seguro

Calcular posição e direção em uma única rotina de amostragem, evitar consultas repetidas, armazenar amostras estáticas da pista e testar o fechamento da volta, boxes, diferentes GPs e geometria procedural. Não alterar distâncias reais de ultrapassagem por conveniência visual.

**Critério:** tolerância geométrica documentada; câmera, mapa e carros sincronizados.

### v0.6.6.0 — Race State Replay e testes determinísticos

Reproduzir seeds, comandos e eventos (pit, chuva, ultrapassagens), comparar hashes do estado esportivo, medir variação entre 1× e aceleração sem depender de FPS. Garantir que o replay não repita decisões aleatórias não registradas.

### v0.6.6.1 — Racecraft avançado sobre `race_space_0655.gd`

Refinar oportunidades de ataque, defesa, espaço para dois carros e retorno à linha ideal sem recriar o núcleo já existente. Animação deve refletir estado da simulação. Proteger Silverstone e pelo menos dois circuitos aleatórios.

### v0.6.6.2 — Driver Soul e Race Radio avançados

Evoluir os módulos já existentes: degradação percebida, pedidos de pit, disputas com companheiro e ordens contextualizadas. Separar intenção do piloto, sugestão do engenheiro e decisão da IA; preservar controle Manual/Automático.

### v0.6.6.3 — Estratégias e Pit Wall

Instrumentar qualidade de previsão de pits em chuva, custos de fila/double stack, undercut e overcut; medir acertos em GPs completos. Não misturar correções de probabilidade e novas funcionalidades na mesma versão.

### v0.6.7.x — Carreira persistente

Progredir em versões separadas: calendário e múltiplas temporadas; academia/scouting; regulação e pesquisa; histórico de campeões/dinastias; equipe adversária autônoma. Reusar os sistemas de Staff, Garage e Rival Development existentes.

## 5. Regras fixas de engenharia

1. Uma funcionalidade principal por versão, com comparação da base anterior.
2. Nenhuma otimização que mude classificação, tempo, pits ou eventos sem justificativa e teste explícitos.
3. Godot 4.7.2 como alvo; medir CPU e GPU separadamente.
4. Registrar seed, pista, clima, renderer, hardware e tempo de execução nos benchmarks.
5. Usar GitHub e documentação oficial como referência técnica; verificar licenças e compatibilidade antes de incorporar código.
6. Manter saves pessoais fora do ambiente de testes (usar `XDG_DATA_HOME` isolado no Linux).
7. Corrida 3D representa decisões reais da simulação; não fabricar ultrapassagens na apresentação visual.

## 6. Prioridade imediata

**Começar pela v0.6.5.7 Performance Profiler 1.0.** Só após obter linha de base decidir se o maior ganho virá de snapshots compactos, amostragem de pista, redução de refresh de HUD, otimizações de mesh, instâncias ou shaders.
