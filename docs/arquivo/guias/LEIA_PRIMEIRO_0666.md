# APEX Motorsport Manager v0.6.6.6 — Replay Fast Seek 1.0

## Base e requisitos

- Projeto **completo** derivado do ZIP `APEX_MOTORSPORT_MANAGER_v0.6.6.5_REPLAY_CHECKPOINTS_COMPLETO.zip`.
- Godot 4.7.2 stable Linux x86_64; Linux Mint recomendado.
- Carreira e corrida com temporada F1 2012 preservadas, sem mudança de física/IA.

## A melhoria

Ao clicar em **Ir ao tick** diversas vezes durante a reprodução, o replay pode reutilizar o estado atual ou uma das últimas quatro âncoras de navegação em memória. Elas são comprimidas com ZSTD, não alteram hashes esportivos nem entram nos arquivos exportados. A memória usada por esses buffers é limitada a 12 MiB no total.

**Resultado medido em 18 movimentos iguais de navegação, Monza 3.200 ticks:** 114,79 s (v0.6.6.5) → **35,37 s (v0.6.6.6)**, aproximadamente 3,25× mais rápido, sem divergência em hashes/contadores Racecraft. A primeira busca fria em área distante não está garantida como mais rápida; a memória estática do Godot foi ~0,90 MB maior no teste.

## Como jogar e testar

1. Extraia todo o ZIP em **pasta nova**, sem misturar arquivos de versões diferentes.
2. Abra `project.godot` no **Godot 4.7.2** e aguarde a importação inicial.
3. Abra uma corrida F1 2012 e use o painel **Replay / F9** → **Ver gravação atual**.
4. Use **Ir ao tick** para navegar; visite o mesmo trecho novamente para sentir o ganho do cache. É possível abrir gravações antigas `APEX_REPLAY_0660` com revisão esportiva `0661_driver_dynamics`.
5. **Voltar à corrida** mantém a sessão original; o replay não transfere comandos para o campeonato.

## Cuidados

- Faça cópia da pasta `user://` antes de alternar versões.
- O perfil permanece `APEX_0650_SOUL_STAFF`; não foram criadas novas migrações.
- Não suponha ganho de desempenho global de corrida, redução de consumo de RAM ou aceleração de seeks frios grandes. Esta é uma otimização de **navegação de replay**.
- Para retornar, use o ZIP completo v0.6.6.5 numa pasta separada; não combine scripts.

## Evidências

Consulte `RELATORIO_TECNICO_APEX_v0.6.6.6.md` e `qa/replay_fast_seek_0666/` para benchmarks, testes e eventuais ressalvas. O teste longo pode ser repetido com `APEX_0666_MONZA_PATH` apontando para uma gravação íntegra de Monza 53 voltas produzida na v0.6.6.5.
