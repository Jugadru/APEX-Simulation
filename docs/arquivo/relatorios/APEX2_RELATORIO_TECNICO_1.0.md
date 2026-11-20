# APEX 2 — Next Engine 1.0 EXPERIMENTAL
## Relatório técnico — 16/11/2026

**Classificação:** PROTÓTIPO FUNCIONAL / EXPERIMENTAL; NÃO substituir Core 2; NÃO classificá-lo como física de corrida pronta.

**Base verificada:** APEX v0.6.6.8.1 HUD ReBroadcast QA, SHA-256 `41df3cf8cc42b75ac30786f2ce18a0f0e1630c8e2f2ec39f4d6a0efc4cfa2056`; íntegra em leitura CRC (2.798 membros). Godot 4.7.2.stable.official.ed1daf0bf no Linux.

### Implementado e testado

- `experimental/apex2/simulation_kernel.gd`: relógio esportivo de 200 ms por tick, estado encapsulado, avanço individual e agrupado, registros causais de eventos, hashes SHA-256 sobre estruturas canonizadas, checkpoint e restore com validação do conteúdo.
- `experimental/apex2/command_queue.gd`: fila autoritativa para intenção, validação de tipos e autoridade, tick agendado, priorização Manual no mesmo tick, rejeições registradas, cancelamento, proteção V21 e opção explícita para cenário de double stack (sem modelar mecânica da garagem).
- `experimental/apex2/scenario_adapter.gd`: converte **o mesmo grid inicial do Core 2** (circuito/2012, seed, IDs, equipes, compostos, clima observado) para entrada da engine experimental. Este adaptador é a única fronteira que importa `race_engine.gd`.
- Os testes Godot em `tests/apex2`, com cenários reais fornecidos pela base. Testes executados em processo Godot 4.7.2, não apenas inspeção de texto.
- Arquivos originais `project.godot`, `scripts/**`, HUD, saves/replay oficial: **zero alterações de código**. A tela inicial do jogo ainda indica 0.6.6.8.1 deliberadamente, porque o motor oficial continua idêntico.

### O que o modelo experimental NÃO faz

O avanço do carro neste protótipo é um **integrador de referência em inteiros**, não física de corrida calibrada. Ainda **não** há aceleração, setores, dinâmica de pneus, chuva dinâmica, consumo, Racecraft, IA de estratégia, incidentes, pneus compostos trocados ou box completo. O uso de seed aqui garante identidade da entrada/registro, **não** alimenta ainda decisões estocásticas. `set_pace` registra escolha, mas ainda não muda velocidade no integrador de referência. A chegada ao limite de entrada da pit lane gera um evento sem executar serviço de garagem, saída, classificação ou custo. Não usar seus resultados como resultados reais de GP.

### Invariantes comprovados

- Tick de 200 ms independente da atualização visual, 500 ticks agrupados versus individuais idênticos.
- Snapshots públicos e replay restaurado não modificam estado/hashes originais.
- Eventos sequenciais com IDs únicos, comandos estáveis por tick/sequência/autoridade.
- Em Spa com chuva, manual V21 persistiu após passagem pela volta 4 e produziu exatamente uma observação do limite de entrada da V21 no tick **11.871**.
- Monza **53 voltas** no integrador de referência: **23.310 ticks**, 24/24 concluídos, hash repetido `918067c2f03fcc3c4f1fc9d13134e4475279c06e79fee9bc166309535d98e30b`. É distinto do Core 2, e isso é esperado.

### Benchmark inicial A/B — NÃO é ranking de desempenho

Cada cenário teve 128 ticks, mesmo grid inicial 2012, mesma seed 6701 e pista/clima. O Core 2 executou todas suas regras; o Next 1.0 só avançou cinemática de referência e fila. Medições por tick (microssegundos) são de execução headless, não FPS.

| Cenário | Core 2 µs/tick | Next 1.0 µs/tick | Eventos Core 2 | Eventos Next 1.0 |
|---|---:|---:|---:|---:|
| GBR / Seco | 8083.9 | 36.6 | 11 | 0 |
| BEL / Chuva intensa | 8146.1 | 37.7 | 1 | 0 |
| ITA / Seco | 8276.1 | 41.4 | 7 | 0 |
| SIN / Chuva intensa | 8579.2 | 39.7 | 1 | 0 |

Na bateria completa: tempo de parede observado 5.198 s, **pico de RSS do processo** 128.1 MiB, CPU total amostrada 5.16 s. Não atribuir essa memória a uma engine individual. `rss_*_kb = -1` no arquivo bruto significa métrica indisponível por acesso interno do Godot; a medição externa por psutil substitui esse campo no arquivo `benchmark_os_process.json`. Alocações e FPS: NOT_RUN. Diferença nos resultados esportivos entre engines: **não comparável** nesta fase.

### Testes

Matriz completa: `APEX2_TESTES_1.0.json`, resumo de {'PASS': 18, 'FAIL': 0, 'INCONCLUSIVE': 2, 'BLOCKED': 0, 'NOT_RUN': 7}. Logs nativos em `qa/apex2_next_engine_10/logs/`. Os casos conhecidos de replay, Pit Wall e HUD da 0.6.6.8.1 voltaram a passar.

### Limites e riscos

- Fila experimental **não é** substituto da fila oficial e não foi conectada à UI.
- Somente ponto de entrada no pit, não simulação de pit stop.
- Hash do Core 2 **não** é idêntico ao hash Next; integridade independente é exigida.
- Modelo de tráfego/velocidade ainda não observa efeitos de pneus ou comportamento individual; evitar alegação de corrida simulada com qualidade equivalente.
- Persistência de checkpoints experimentais tem esquema próprio e não migra saves oficiais.
- Teste real de monitor/GPU e regressões de GP completo em outras pistas permanecem pendentes.

### Execução

No diretório com `project.godot`, em Godot **4.7.2**:

```bash
godot --headless --editor --path . --quit
for t in test_kernel test_pit_queue test_replay test_pit_entry_21 test_long_monza benchmark_ab; do
  godot --headless --path . --script "res://tests/apex2/$t.gd"
done
```

Para jogar normalmente, abra `project.godot`, cujo Core 2, HUD e saves são os mesmos da 0.6.6.8.1. A Next Engine **não está disponível como modo de jogo**.

### Rollback

Feche Godot, preserve qualquer save do usuário, e reabra o ZIP original `APEX_MOTORSPORT_MANAGER_v0.6.6.8.1_HUD_REBROADCAST_QA_COMPLETO.zip`. Como nenhum script ou configuração esportiva foi modificado, o rollback é somente troca de pasta; o diretório de saves `APEX_0650_SOUL_STAFF` permanece intocado.

### Próximas versões (NÃO implementadas)

Next 1.1 Vehicle Dynamics; 1.2 Driver Brain; 1.3 Racecraft; 1.4 Strategy Brain; 1.5 Replay/Telemetry; 1.6 Benchmarks de equivalência por cobertura de regras. Dependem de validação desta infraestrutura.
