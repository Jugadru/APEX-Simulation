# APEX Simulation — Motorsport Manager

Projeto de simulação e gerenciamento de escuderia, desenvolvido em **Godot 4.7.2 / GDScript**, com referência histórica inicial à temporada de **Fórmula 1 de 2012**.

> **Estado da importação:** este repositório foi inicializado com documentação e preparação para controle de versão. O **código-fonte completo do jogo ainda não foi importado**. Não tratar este repositório como uma build jogável até a chegada de `project.godot`, cenas, scripts e recursos do projeto.

## Referência de desenvolvimento

- Pacote de referência preservado fora do GitHub: `APEX_MOTORSPORT_MANAGER_v0.6.6.7.2.4_PITLANE_CPU_COMPLETO.zip`
- Planejamento vigente: [Plano Mestre Unificado 2.0](docs/APEX_SIMULATION_PLANO_MESTRE_UNIFICADO_2_0_2026-11-16.md)
- Registro histórico: [Fonte Mestra (13/11/2026)](docs/APEX_SIMULATION_FONTE_MESTRA_2026-11-13.md)
- Procedimento: [Como importar o projeto Godot](docs/IMPORTAR_PROJETO_GODOT.md)

## Fluxo de trabalho proposto

- `main`: código oficial **após** importação e validação da versão estável.
- `feature/hud-rebroadcast`: redesenho de HUD, isolado do motor esportivo.
- `experiment/next-engine`: motor APEX 2 e IA experimental, sem substituir o Core 2.

As ramificações de desenvolvimento serão criadas **depois** que a base real do jogo estiver importada.

## Regras

1. Uma funcionalidade principal por versão.
2. Testes de regressão e comparação de hashes esportivos quando aplicáveis.
3. Preservar savegames, replay, Pit Wall e determinismo.
4. Não declarar benchmarks ou testes como aprovados sem execução.
5. Não incluir executáveis do Godot, instaladores, caches ou ZIPs completos no histórico Git.
6. Arquivos binários grandes do projeto devem ser tratados separadamente, com análise de Git LFS.

**Acesso:** repositório privado, destinado ao desenvolvimento do APEX Motorsport Manager.
