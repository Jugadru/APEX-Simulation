# APEX v0.6.6.8.7 — Driver Dynamics 2.0

- **Melhoria principal:** julgamento consultivo de ritmo e pneus por piloto no diálogo existente de stint. Compara última volta versus melhor volta, percepção subjetiva, desgaste, temperatura e tolerância ao risco.
- **Rádio:** piloto pode solicitar revisão da janela devido à perda de ritmo ou sugerir permanecer na pista quando o stint está estável; engenheiro apresenta medições, incertezas e a ordem de box agendada.
- **Garantias:** módulo puro, sem RNG, alterações em `RaceEngine`, cronograma de box, política de replay, física, corrida em 3D ou saves.
- **QA:** 23 verificações puras + 12 via HUD; testes legados e quatro pistas × 750 ticks com hashes idênticos.
- **Limitações:** não instala automaticamente a opinião do piloto como ordem; tempo de volta pode variar por tráfego, clima e combustível; não é diagnóstico isolado da borracha; FPS e GP completos não foram medidos nesta atualização.
