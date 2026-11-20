# APEX v0.6.3.9 — RELATÓRIO DE EXECUÇÃO REAL (Godot 4.7.2)

Ambiente: Linux x86_64, **Godot v4.7.2.stable.official.ed1daf0bf** retirado do ZIP fornecido pelo projeto.
Projeto original `APEX_0638_1_GODOT.zip`: `ZipFile.testzip() == None` (478 entradas), extração íntegra.
O código em `scripts/race_engine.gd` manteve o mesmo hash SHA-256 da v0.6.3.8.1; **hotfix de dupla linha preservado**.

## Testes efetivamente executados

| Teste | Cenário | Resultado |
|---|---|---|
| Importação Godot (`--headless --editor --import --quit`) | projeto completo | passou; zero erros de parse |
| Root cause 0638.1 | erro após cruzar a linha + replay de 560s, semente 321 | passou; 0 voltas inválidas |
| GP completo de Interlagos | BRA, 71 voltas, 24 carros, SECO, pit MANUAL, semente 321 | passou; Fernando Alonso vencedor, 0 voltas inválidas, 4 pits Ferrari exatos (V23/V25 e V48/V50) |
| GP completo de Interlagos | BRA, 71 voltas, 24 carros, CHUVA FORTE, pit AUTO, semente 321 | passou; Sebastian Vettel vencedor, 0 voltas inválidas |
| Integridade KERS/DRS | 3 modos, 400kJ, 3 zonas, uso e ganho de ritmo | passou |
| Regressão dos pits | geometria, temporização, continuidade e saída do pit lane | passou |
| Mini GP 0638.1 | 4 voltas, seco e chuva forte, pits V2 e V3 | passou; 0 voltas inválidas |
| Advertência de desgaste/manual | não executar box sem ordem | passou |
| Race Engineer 0639 | relatório imutável, V21, IA STAFF, modos manual/automático, botões reais de HUD e rádio | passou |
| Rádios 0630/0631/0632/0637 | histórico, pergunta, privacidade, eventos e cooldown | passaram |
| Controle de STAFF 0590 | manual/auto; pit V21 permanece | passou |
| Painel de estratégia expandido 0622 | posicionamento sem sobrepor cartões, estratégias | passou **após correção** |
| Tela real do jogo | Xvfb 1600×900, cena Godot, painel Race Engineer | abriu, captura nativa registrada, sem erros de script |

**Dados do teste de 71 voltas, SECO:** duração de corrida simulada ~5640 s; 1410 passos de 4s; 48 pits na grid; P2 +4,00s; 84 ultrapassagens registradas pelo motor.
**CHUVA FORTE:** ~5648 s, 1412 passos de 4s; 48 pits na grid; P2 +1,80s; 92 ultrapassagens registradas.
A IA de corrida e pit não foi reimplementada na v0.6.3.9; os números acima são resultados de execução, não telemetria FIA.

## Defeito adicional identificado e corrigido

O teste histórico `core_0622_corner_hud_smoke_test.gd` falhava **também na versão original v0.6.3.8.1** (exit 6). O painel de estratégia solicitava 337 pixels, mas seu conteúdo exigia mínimo real de 369 pixels, sobrepondo o cartão 24 pixels. A v0.6.3.9 usa a altura mínima real para posicionar o painel **8 pixels acima** do cartão. Teste reexecutado com sucesso.

## Limitações

- Abertura real testada em **tela virtual Xvfb**; não equivale a instalar no computador pessoal do jogador.
- O servidor X virtual não possui áudio ALSA padrão: Godot apresentou avisos de áudio e usou dispositivo de som nulo. Isso **não** foi um erro de GDScript.
- Não foi executada uma campanha inteira de 20 GPs após o hotfix; as duas corridas de 71 voltas acima, sim.
- A camada de estratégia é heurística e não usa modelo generativo.
