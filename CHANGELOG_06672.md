# Changelog — APEX v0.6.6.7.2

**Base:** v0.6.6.7.1. **Tema único:** recuperação de retenções visuais persistentes durante tráfego/ultrapassagens no 3D.

- `scripts/apex_racecraft_0654.gd`: rastrear retenções consecutivas e permitir rebase apenas do histórico visual bloqueado após duas atualizações. Reduzir travamento de renderização causado por ordem espacial obsoleta; manter SAT, corpos visíveis e motor esportivo intactos.
- `scripts/track_3d.gd`: dois contadores novos para diagnóstico no profiler F8. Dados coletados somente quando profiler está ligado.
- `project.godot`: identificador da versão.
- Adicionados testes controlados 24 carros / quatro pistas, comparativo original x otimizado, contadores F8, logs de replays, importação e capturas gráficas.

**Medição destacada:** Monza 26→2 atualizações estacionárias consecutivas; Spa 96→2 em cenários de 125 passos. O problema da HUD e as regras de corrida para duelos prolongados **não** foram alterados.
