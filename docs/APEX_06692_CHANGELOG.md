# APEX v0.6.6.9.2 — Changelog (validado)

- Uma única otimização principal: reuso da lista estável de propriedades usadas no **hash esportivo** de cada tick.
- Valor de cada propriedade, ordem, serialização e função de hash preservados.
- Verificação byte-a-byte contra o método anterior em 2.400 ticks independentes de Monza seca e Spa com chuva.
- Profile opcional `replay.sporting_hash` e janelas CPU de 2.000 ticks durante a corrida completa de 53 voltas.
- Sem alteração no scheduler 32×, HUD, Core 2, sistemas de pneus/clima/IA, eventos, saves ou replay público.
- **A melhoria sustentada de velocidade 32× no computador do usuário ainda não foi demonstrada**. A/B CPU e CI precisam ser concluídos e registrados antes de aprovar.

- Metadados e distribuição: versão 9.2 no `project.godot`, identidade dinâmica no título/menu preexistente e verificação obrigatória nos `.pck` de Windows/Linux (`APEX_BUILD_ID_06692_PASS`). O diretório dos saves permanece o mesmo. Sem publicação automática de Release.

## Resultado final

- Merge PR #70 na `main`: `4c9d05db2fe1fff4c4048bfe46c2f0714940a67b`.
- 15/15 workflows PASS e Quality Gate READY 10/10; 2.400 hashes iguais ao método anterior, 53 voltas de Monza e replay integral 24.409 ticks com hash igual à v9.1.
- A/B CPU esportiva −1,38% e live Monza headless 210,77 s → 206,80 s (−1,88%), medições sem significância estatística demonstrada.
- Janelas da corrida reproduzem queda de ~26,59× para ~21× nas voltas finais em CPU headless. Essa perda **ainda precisa ser investigada/corrigida**; FPS no GPU físico NOT_RUN.
- ZIP desktop com nome `v0.6.6.9.2` correto; código da HUD do Work não foi alterado.
