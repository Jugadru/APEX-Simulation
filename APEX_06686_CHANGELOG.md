# Changelog — v0.6.6.8.6 Core 2 Race Performance & Stability

- **Optimização direcionada:** `scripts/core/race_space_0655.gd` evita ordenar novamente a fila se já estiver em ordem correta; mantém o comparador original como fallback para entradas desordenadas/empates.
- **Manutenção da suíte de testes:** expectativas do teste `car_model_smoke_test.gd` atualizadas para as peças de 3D realmente existentes, sem modificar modelo.
- **QA:** teste de ordem e fallback, A/B quatro pistas 750 ticks, Monza 53 voltas com replay integral, perfil de tempo por chamada e captura real 3D.
- **Sem alteração:** física, estratégia, Pit Wall, HUD, renderizador, assets 3D, salvamentos, formatos de replay, Next Engine.

**Não interpretar o benchmark de uma função como FPS do jogo inteiro.**
