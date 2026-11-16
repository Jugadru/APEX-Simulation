# APEX Motorsport Manager v0.6.4.9.1 — Memória de adiamento do Pit Wall

**Base:** v0.6.4.9 integral (Pit Wall & Estratégia 3.0). **Motor:** Godot 4.7.2.

## A única correção funcional desta versão

O Pit Wall 3.0 marca `car["pitwall49_held"] = true` quando adia um pit stop automático por uma volta para evitar dividir a garagem. A versão anterior não limpava a marca após a troca de pneus. Assim, uma decisão segura de adiamento em um stint posterior ficava bloqueada.

O patch adiciona **somente** a limpeza `car["pitwall49_held"] = false` no método `race_engine.gd::_finish_service()`, imediatamente após reiniciar `stint_laps`, no momento em que os pneus foram efetivamente trocados.

Consequências:

- **No mesmo stint:** uma segunda tentativa de adiamento continua proibida.
- **Apenas entrar nos boxes, fazer uma chamada ou agendar um pit:** não redefine a memória.
- **Depois do serviço de troca de pneus:** um novo stint pode receber **uma** decisão de adiamento, se as condições normais de segurança permitirem.
- **Chuva crítica e pneus ruins:** continuam sem adiamento automático pela regra existente.
- **Ordem V21:** continua sob controle do jogador, sem antecipação involuntária.

Não há nova fórmula de pneus, reequilíbrio de paradas, alteração de dupla parada/double stack, alteração de telemetria ou novo modelo de confiança nesta entrega. Essas áreas ficam para versões **0.6.4.9.2**, **0.6.4.9.3** e **0.6.4.9.4**, respectivamente.

## Instalar / executar

1. Extraia todo este ZIP para uma **pasta nova**.
2. Importe `project.godot` no **Godot 4.7.2**.
3. Execute com F5 e inicie uma corrida.
4. O Pit Wall 3.0 continua acessível pela HUD em **ENG.**, com o visual da versão anterior.

O nome de janela e o diretório do save mudaram para `ApexMotorsportManager_PitWall_06491` para não sobrescrever os arquivos da versão 0.6.4.9. Caso queira continuar uma carreira existente, faça backup e migre os saves conscientemente; o formato não foi alterado.

## Verificação do patch

Teste direcionado: `tests/pitwall_06491_stint_reset_test.gd`.
Reprodução do GP: `tests/pitwall_06491_silverstone_full_gp_test.gd -- --code GBR`.
Relatório: `RELATORIO_TESTES_06491.md`.

O GP completo é no motor nativo (Godot headless), não a captura de uma transmissão 3D em tempo real. O teste de interface permanece separado. Leia o relatório para os resultados e limitações.
