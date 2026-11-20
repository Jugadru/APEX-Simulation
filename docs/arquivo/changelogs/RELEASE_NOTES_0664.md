# APEX Motorsport Manager — Release Notes v0.6.6.4

**Replay Memory 1.0 — Replay Session Fork**  
**Godot 4.7.2 · Temporada F1 2012**

## Principal melhoria
O botão **Ver gravação atual** abre a corrida gravada diretamente dos checkpoints comprimidos já existentes, em vez de reconstruir em memória um arquivo completo de replay. A reprodução usa os mesmos comandos, hashes por tick, estado inicial e determinismo da v0.6.6.3.

## Resultados A/B (Monza, 3.200 ticks)
- Abertura do replay pelo caminho antigo: **0.809s**.
- Abertura pelo fork direto: **0.013s** — 60.7 vezes mais rápido no teste.
- Pico RSS do processo: **186.6 MiB** antes versus **127.2 MiB** depois — redução observada de 31.8%.
- Hash esportivo final: **idêntico**, `f771fab5025055653075f853b4a06370097d5af74843d2deea4cc8dc17be9b90`.

Este ganho refere-se **à abertura de replay local**, não a um aumento artificial do ritmo de corrida.

## Compatibilidade
- Não há mudanças no `APEX_REPLAY_0660` nem na revisão esportiva `0661_driver_dynamics`.
- Arquivos antigos continuam abrindo com validação normal; exportações continuam disponíveis.
- Corrida e replay compartilham resultados do mesmo motor, sem que a apresentação interfira no RNG.
- Foram preservados Pit Wall, estratégia, IA, Racecraft, telemetria, oficina, inventário, salvamento e HUD unificada.

## Testes
Regressões com seeds fixas: Silverstone, Spa, Monza e Singapura curtas, hashes esportivos idênticos, testes de replay, chuva, pit manual V21, oficina/inventário e integração da HUD. **Monza 53 voltas e replay integral por fork: APROVADOS.** A corrida completou 24.431 ticks, 24 carros e 24 posições sem duplicação. A nova abertura levou **0,059 s** e o replay integral dos 24.431 ticks levou **548,59 s**, com hash final idêntico à v0.6.6.3. O pico RSS observado do processo combinado (sem exportação intermediária) foi **168,4 MiB**. A comparação histórica de 788,2 MiB da v0.6.6.3 incluía outro caminho de exportação, e não é um A/B de corrida longa realizado sob as mesmas condições.

**Matriz final:** 26 testes aprovados, 0 reprovados, 1 não executado (estresse de 20 temporadas). Evidências em `qa/replay_memory_0664/` e no relatório.

## Rollback
Fechar o Godot, copiar os saves de `user://` e reabrir a cópia completa v0.6.6.3 (ZIP SHA-256 `4d7f3d9d89980d63ae23098eb0d73446b614d49b4696c0a9dfd5191b78834dff`). Não misturar scripts de versões diferentes.

**Nenhuma v0.6.6.5 iniciada.**
