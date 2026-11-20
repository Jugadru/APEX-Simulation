# APEX Motorsport Manager v0.6.5.4 — Racecraft

Abra `project.godot` no Godot 4.7.2 e pressione F5. No Linux, `linux/run_apex.sh` aceita `GODOT_BIN=/caminho/para/Godot`. A alternativa `linux/run_apex_compatibility.sh` continua disponível.

## Mudanças

- O atacante sai da trajetória e procura um corredor lateral para ultrapassar.
- O defensor conserva sua linha. Pode fazer um movimento defensivo pequeno antes de o adversário chegar ao lado; não troca de lado sobre um carro já emparelhado.
- Retorno à trajetória espera a liberação do espaço entre os carros.
- Retângulos orientados abrangem rodas e asas. A ocupação é verificada no destino e no movimento relativo entre quadros, inclusive em avanço acelerado.
- Sem espaço, o carro fica atrás. Em curvas, a correção percorre a linha da pista em vez de empurrar o modelo para fora dela. Movimentos conflitantes podem aguardar na última posição segura; os carros não são escondidos para disfarçar o conflito.
- HUD, modelos, materiais, DRS, rodas e regras da simulação da v0.6.5.3 foram preservados.

## Escopo

Este é um sistema de ocupação e comportamento visual da corrida 3D, não uma simulação de dinâmica de colisões. Classificação, cronômetro e resultado das disputas continuam sendo calculados pelo motor existente. Em tráfego apertado, a posição exibida pode ficar atrás do progresso lógico até existir espaço. Não foram adicionados impactos físicos ou danos. A circulação nos boxes e os carros já finalizados continuam usando o tratamento anterior.

## Evidências

Veja `qa/racecraft/regressions.json`, os logs e `source_audit.json`. Os testes incluem ultrapassagem concluída pelo atacante, defensor mantendo linha, defesa inicial limitada, fila estreita, pausa, salto de posição, ausência de alteração dos dados e pelotões em Silverstone e Mônaco. O teste nativo verifica corpos separados, todos os carros visíveis e avanço do pelotão durante 30 segundos simulados em cada pista.

`qa/racecraft/demonstracao_0654.mp4` é uma demonstração visual controlada de 8 segundos, não um replay real nem benchmark. Cada quadro verifica separação dos dois carros; também verifica que o defensor não abandona sua linha e que o atacante termina à frente. Capturas `race_*` mostram a HUD da corrida. Evidências de versões anteriores são históricas.

O ZIP contém o projeto completo; não contém um executável exportado nem o Godot.
