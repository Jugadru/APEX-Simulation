# APEX Core 2 v0.6.6.8.7 — Relatório de engenharia

## Base
Código-fonte derivado da Release Core 2 v0.6.6.8.6. ZIP da base SHA-256: `8e097c251738df8b58a71943c834a8fd9951e4e9deebf37b13fc9ec934347fb8`. A Next Engine permanece suspensa.

## Alteração de escopo
O projeto já tinha o rádio espontâneo, Soul Driver 2.0 e **RÁDIO > DISCUTIR STINT**. A nova versão adiciona o módulo **puro e consultivo** `scripts/core/race_driver_tyre_judgement_06687.gd` e integra essa avaliação à conversa em `race_stint_dialogue_0635.gd`.

O piloto considera a diferença entre última volta e melhor volta, desgaste, aquecimento, percepção subjetiva, tolerância fictícia ao risco e iniciativa. Há filtros para timing inválido, voltas de saída e pit ativo. O engenheiro contextualiza sem afirmar que ritmo lento seja causado exclusivamente pelos pneus. Quando o piloto quer ficar mais uma volta, o engenheiro pode concordar ou pedir cautela. A decisão **não altera** física, estratégia, ordens, RNG, replay ou saves.

## Evidências — execução local no Godot 4.7.2
- Importação inicial: PASS.
- Driver Dynamics 2.0: 23 verificações PASS.
- UI/Rádio: 12 verificações PASS, incluindo V21 aplicado via fila de comandos do replay.
- Testes legados de diálogo 0635 e rádio 0630/0631: PASS.
- Racecraft: 1.027 verificações; Driver Dynamics original: 17; Core 2 ordenação: 4; double stack, carro 3D e replay (200 ticks, velocidades 1×/2×/5×/16×/32×): PASS.
- Silverstone seco, Spa chuva intensa, Monza seco e Singapura chuva intensa: 750 ticks por pista, hashes, posições, eventos e checkpoints idênticos à versão-base em 1/80/250/500/750.
- Reextração do ZIP: CRC PASS. Uma tentativa de importação limpa sofreu falha intermitente do processo Godot; a repetição com renderização de compatibilidade terminou em código 0, sem erro de GDScript. Os testes novos e o teste legado 0635 passaram novamente na cópia extraída.

## Limites
O novo comportamento só aparece quando o jogador solicita uma discussão de stint, não cria parada automática. Não foram repetidos GP integral de 53 voltas, FPS em GPU real ou temporadas completas nesta atualização. Compatibilidade esportiva de replay foi observada nos cenários de comparação; não há promessa de identidade de desempenho entre máquinas.

## Rollback
Manter a Release v0.6.6.8.6 preservada e fazer backup dos saves antes de testar versões novas.
