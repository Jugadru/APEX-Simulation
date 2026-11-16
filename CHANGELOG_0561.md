# Apex Motorsport Manager v0.5.6.1 — KERS por rajadas e DRS recalibrado

## Problema informado pelo jogador

No Core 2 0.5.6.0, o KERS drenava os 400 kJ praticamente na primeira reta, mesmo alternando de modo. O DRS era mostrado na HUD mas produzia efeito local pequeno, difícil de observar.

## Correções

- `race_kers_2012.gd`: reserva **cotas independentes de energia** para três zonas de aceleração por volta, evitando gasto total na primeira reta.
- Potência por perfil: **Economizar 18 kW**, **Equilibrado 40 kW**, **Atacar 60 kW**. As durações aproximadas de ativação distribuída pela volta, com orçamento por perfil, são 17,8 / 10,0 / 6,7 segundos, respectivamente.
- O modo Economizar usa até 320 kJ; o Equilibrado e o Atacar usam até 400 kJ. Trocar de modo no meio da volta respeita a energia e a cota já usadas; o motor não gera carga artificial.
- `race_performance.gd`: o impulso é proporcional à potência efetivamente aplicada e ao perfil. O ganho de KERS em uma volta ideal de referência de 110 s fica na ordem de 0,2 a 0,5 s (balanceamento do jogo, sujeito a tráfego e diferenças de pista).
- DRS: o efeito local sobre o ritmo foi aumentado de -1,10 para **-3,40 segundos por volta equivalente DURANTE a ativação**; não é um benefício de 3,4 s por volta completa. O acionamento continua exigindo janela válida, diferença de até 1 s na detecção, duas voltas concluídas e ausência de suspensão por chuva.
- Telemetria: inclui potência real do KERS por instante, ganho estimado de KERS e de DRS na volta, e exporta esses campos no CSV de posições.
- HUD: botão do KERS acende enquanto ele fornece potência, mostra kW atuais e energia restante; passe o mouse para ver ganhos estimados. DRS apresenta status claro, com informação estimada na dica do indicador.

## Preservados

Pneus, IA que troca W/I desgastados, física de chuva, pit lane, double stack, circuito 3D e modo Core 2 único. Não altera as regras dos compostos nem os tempos dos boxes.

## Limitações

- Zonas de KERS e de DRS são **aproximações de gameplay**, não telemetria homologada de 2012.
- O KERS histórico tem no máximo 60 kW/400 kJ por volta, portanto **não pode fornecer potência máxima durante uma reta longa inteira**. A distribuição em rajadas dá duração visual ao longo da volta sem violar esse limite.
- Ganhos e durações são calibrados para a simulação; não são medições de velocidade ou de potência na roda.
- Testes offline não substituem a validação de execução no Godot 4.7.2.

## Testes recomendados

```bash
python3 tests/test_0561_energy_balance.py
GODOT_BIN=/caminho/para/Godot.AppImage bash linux/validar_core_0561.sh
```

Teste em Spa, corrida seca: o botão muda entre ECO, EQ e ATQ. KERS deve voltar a funcionar em outras partes da volta sem esgotar na primeira reta; o DRS só abre com elegibilidade. Teste com Chuva intensa: DRS continua suspenso.
