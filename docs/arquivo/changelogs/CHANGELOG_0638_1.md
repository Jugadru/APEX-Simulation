# Apex Motorsport Manager v0.6.3.8.1 — Hotfix de cronometragem

## Causa raiz confirmada

Em `scripts/race_engine.gd`, `_record_lap_cross()` registrava o cruzamento válido e atualizava `lap_started`. Na sequência, `_on_lap_cross()` podia aplicar um erro de pilotagem por meio de `car["progress"] -= extra / base_lap`, recuando o carro PARA TRÁS da linha que acabara de atravessar. Ao atravessar a mesma linha novamente 1,5 a 3,5 segundos depois, o simulador registrava uma segunda volta indevida. A filtragem dos recordes da v0.6.3.8 só ocultava o sintoma.

## Mudanças efetivas

- O incidente agora adiciona `extra` segundos a `combat_hesitation_s` (suspensão da progressão enquanto o relógio continua avançando). Não altera a distância já percorrida.
- `_record_lap_cross()` não registra uma volta se o índice de volta de destino já está em `laps_done`.
- O tempo perdido continua tendo efeito na corrida, mas sem teleportar ou retroceder o carro e sem duplicar a passagem pela linha.
- `project.godot` e título da janela identificam este hotfix. Nenhum outro sistema de estratégia, HUD, pneus, KERS ou rádio foi modificado.

## Testes executados no Godot 4.7.2

- Reproduzidos no código antigo os eventos inválidos de **Vitaly Petrov (3,4s aos ~406s)** e **Narain Karthikeyan (2,6s aos ~496s)**, Interlagos, semente 321.
- `core_0638_1_timing_rootcause_test.gd`: forçado incidente após cruzar a linha, espera real de 1,5–3,5s e proibição de dupla contagem; repetição real dos primeiros 560 segundos, 24 carros, semente 321: **0 voltas inválidas**.
- `core_0638_1_mini_gp_test.gd`: **GPs completos de 4 voltas**, 4 carros, seco e chuva forte, pits agendados V2/V3: **0 voltas inválidas**, todas as paradas no momento correto.
- `core_0638_manual_warning_test.gd`, `pit_lane_regression_test.gd`, `core_0561_energy_balance_test.gd`, `core_0637_reactive_radio_smoke_test.gd`: PASSARAM.
- Godot 4.7.2 importou os scripts no editor sem erro; o jogo iniciou em tela virtual 1600 × 900 sem erro de script. O dispositivo de som virtual não estava configurado.

## Limitações

- Ainda não foi reproduzida uma corrida longa de 71 voltas nem toda a temporada de 20 GPs **após este hotfix**.
- O sistema de penalização por erro é um modelo simplificado de tempo perdido, não uma trajetória física de saída de pista.
- O filtro defensivo de tempos impossíveis da v0.6.3.8 foi mantido como segurança adicional.
- A instalação no computador Linux Mint do usuário depende de teste local.
