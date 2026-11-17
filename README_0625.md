# APEX v0.6.2.5 — Projeto Godot completo

1. Extraia este ZIP **numa pasta nova**, sem misturar com a v0.6.2.4.
2. Importe `project.godot` pelo Godot 4.7.2 e execute F5.
3. Teste GP da China, modo `Seco`. Compare stints e boxes realizados pela IA em toda a prova.
4. Validação opcional em Linux:
   - `bash linux/validar_0625.sh`: testes estáticos e smoke nativo (se existir Godot no PATH).
   - `bash linux/validar_0625.sh --long`: inclui corrida completa da China no modo headless.

**Aviso:** o planejamento matemático não é uma previsão infalível. Clima, incidentes, temperatura, tráfego, ordens manuais e dupla parada podem mudar o resultado.

A nova lógica foi implementada em `scripts/core/race_stint_optimizer.gd`, mantendo a HUD anterior.
