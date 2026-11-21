# APEX v0.6.6.9.2 — Changelog (proposta)

- Uma única otimização principal: reuso da lista estável de propriedades usadas no **hash esportivo** de cada tick.
- Valor de cada propriedade, ordem, serialização e função de hash preservados.
- Verificação byte-a-byte contra o método anterior em 2.400 ticks independentes de Monza seca e Spa com chuva.
- Profile opcional `replay.sporting_hash` e janelas CPU de 2.000 ticks durante a corrida completa de 53 voltas.
- Sem alteração no scheduler 32×, HUD, Core 2, sistemas de pneus/clima/IA, eventos, saves ou replay público.
- **A melhoria sustentada de velocidade 32× no computador do usuário ainda não foi demonstrada**. A/B CPU e CI precisam ser concluídos e registrados antes de aprovar.

- Metadados e distribuição: versão 9.2 no `project.godot`, identidade dinâmica no título/menu preexistente e verificação obrigatória nos `.pck` de Windows/Linux (`APEX_BUILD_ID_06692_PASS`). O diretório dos saves permanece o mesmo. Sem publicação automática de Release.
