# APEX Motorsport Manager — Relatório técnico v0.6.6.4

**Escopo:** Replay Memory 1.0 — Replay Session Fork.  
**Base obrigatória:** v0.6.6.3 Long Race Performance 1.0.  
**SHA-256 da base:** `4d7f3d9d89980d63ae23098eb0d73446b614d49b4696c0a9dfd5191b78834dff`.  
**Godot:** 4.7.2 stable em Linux x86_64; testes nativos headless (sem GPU dedicada).

## 1. Auditoria da base e causa confirmada

O ZIP original passou CRC e continha `project.godot`, cenas, dados, recursos, testes e 322 scripts históricos da base mais adições das versões 0663. Foi extraído intacto e preservado para rollback. O projeto novo deriva do conteúdo real, não do zero.

A v0.6.6.3 passou na corrida de Monza de 53 voltas e no replay integral. Entretanto, na rotina de interface `scripts/race_replay_panel_0660.gd`, o botão *Ver gravação atual* utilizava `replay.load_data(host.replay_session.export_data())`. A exportação descompactava todos os checkpoints para dicionários completos e então o carregador validava/restaurava e compactava novamente os estados. Esse trabalho era redundante para **sessões locais já gravadas pelo motor**, mesmo que indispensável para validar arquivos externos.

A medição histórica v0.6.6.3 do processo combinado (corrida + exportação + reprodução integral, com múltiplas representações retidas) chegou a 788,2 MiB RSS; não se extrapola esse valor isolado como causa única. Não se modificou o caminho de arquivos externos.

## 2. Implementação pequena, sem alterar esporte

- `scripts/core/race_replay_0660.gd`: adicionada API `load_live_session(recorded)`. Ela duplica comandos, hashes e checkpoints internos compactados, preservando estado inicial, política, tick e ordenação. Faz `seek(0)` e valida o estado antes de expor a sessão. Se falhar, abandona o estado parcial.
- `scripts/race_replay_panel_0660.gd`: o botão de gravação atual chama a API, sem produzir `export_data` intermediário. Funciona também quando a fonte já está em playback.
- `project.godot`: identificação v0.6.6.4.
- Arquivos de teste e QA novos, sem refatorar física, IA, renderizador, staff ou persistência.

O formato de arquivo **`APEX_REPLAY_0660`** e `simulation_revision=0661_driver_dynamics` ficam intactos. `load_data`/`load_file` ainda fazem a validação completa de entradas externas. `export_data()` e `save_file()` permanecem disponíveis sem nova versão de formato. Checkpoints e telemetria não foram descartados.

## 3. Benchmark A/B, Monza 3.200 ticks

Mesma seed **660**, pista Monza em configuração oficial de 53 voltas, clima seco, 24 carros, mesmos comandos, Godot 4.7.2 headless e processo exclusivo por medição. A duração da corrida foi separada do custo de abertura da reprodução.

| Métrica | v0.6.6.3 (caminho antigo) | v0.6.6.4 (fork direto) |
|---|---:|---:|
| Tempo apenas para abrir replay | 0.809015 s | 0.013333 s |
| Pico RSS de todo o processo | 186.57 MiB | 127.22 MiB |
| Hash esportivo após 3.200 ticks | `f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90` | `f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90` |
| Estado restaurado no tick 0 | SIM | SIM |
| Busca em checkpoint intermediário | PASS | PASS |
| Checkpoints lógicos | 9 | 9 |

Ganho observado na operação de abertura: **60.68x**; redução de pico RSS: **31.81%**. O pico RSS foi amostrado a cada 0,12s, inclusive durante a corrida, fork e seek. Não confundir o tempo de fork com tempo de simulação nem considerar a redução de RSS como representativa de todas as distâncias/hardwares.

Dados brutos: `qa/replay_memory_0664/comparison_watch_3200.json`, `benchmark_watch_0663_rss.json`, `benchmark_watch_0664_rss.json` e os dois JSON de execução.

## 4. Determinismo, compatibilidade e QA

A fixture `tests/replay_watch_0664_test.gd` validou uma corrida de 650 ticks, fork local, busca intermediária, reprodução integral tick a tick, hash esportivo idêntico, gravação anterior exportada/importada e imutabilidade da corrida original. A fixture `replay_0660_integration.gd` exercitou o botão da UI com 2D/3D, pausa, busca, retorno à corrida e proteção do inventário. As velocidades 1x, 2x, 5x, 16x e 32x e o pit V21 em chuva mantiveram testes PASS.

### Quatro GPs curtos, hashes históricos preservados

| Circuito | Clima | Ticks | Hash original/atual | Status |
|---|---|---:|---|---|
| GBR | Seco | 1668 | `7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837` | APROVADO |
| BEL | Chuva intensa | 2067 | `33c7c2d71e34779fb7e74f359f2663e0bea34074aaf4c655dc678f3b97fd8c0e` | APROVADO |
| ITA | Seco | 1553 | `5d4c508a64dce8d1c481a3661f56c6bdf97a2a7a7bab37a5e290be5e54188592` | APROVADO |
| SIN | Chuva intensa | 2050 | `48085a06fed3d7761a58206673c03685043645d813ea809e0b76c968e94439c9` | APROVADO |

Os contadores Racecraft também foram idênticos em cada GP. A mudança da 0664 não altera o motor de corrida; `scripts/race_engine.gd` permanece byte a byte igual à v0.6.6.3.

## 5. Monza completo + replay integral por fork

**Monza 53 voltas:** APROVADO, 24/24 classificações exclusivas, 24431 ticks, 549.37s. **Replay completo pelo novo fork:** APROVADO, 24431 ticks reproduzidos, 548.59s. **Fork antes da reprodução:** 0.059s. **Hash final:** `2a7e27179177858b8754a0c65666b325499e4aa13d423de060181b11d9ae1c4b`. **RSS pico do processo integrado:** 168.4 MiB (amostragem 1s).

## 6. Matriz de testes

Até a última revisão: 26 **aprovados**, 0 **em execução**, 1 **não executado(s)**. Resultados definitivos com status e log em `qa/replay_memory_0664/test_results_0664.json`. A categoria de estresse de 20 temporadas não foi executada; nenhum PASS inventado.

Testes cobertos incluem importação Godot, unitário do fork, os quatro GPs, integração UI com replay e inventário, replay de chuva, Racecraft, Driver Dynamics, RaceSpace, pit lane, save migration, inventário, oficina, Soul Staff, velocidade e comando V21.

## 7. Arquivos e rollback

**Arquivos existentes modificados:**
- `scripts/core/race_replay_0660.gd`
- `scripts/race_replay_panel_0660.gd`
- `project.godot`

**Arquivos acrescentados:** `tests/replay_watch_0664_test.gd`, `tests/replay_watch_memory_0664_benchmark.gd`, `tests/long_race_full_fork_0664.gd`, documentações e evidências em `qa/replay_memory_0664/`. Nenhuma alteração nos scripts de física/IA, schemas de save, cenas, 2D/3D e sistemas Living Factory.

Para rollback, encerre o Godot, salve cópia dos dados em `user://` (diretório customizado `APEX_0650_SOUL_STAFF`), e extraia **o ZIP original v0.6.6.3** em outra pasta. Não misture código de versões. Veja `LEIA_PRIMEIRO_0664.md`.

## 8. Limitações

O ganho A/B principal está **comprovado para o caminho local de abrir replay**, não para importação/exportação externa e não significa que todas as cópias de dados foram eliminadas. O teste longo exercita o fork ao finalizar Monza. CPU/GPU de hardware consumidor e estresse de vinte temporadas não foram avaliados. A versão 0.6.6.5 não foi iniciada.
