# APEX Motorsport Manager v0.6.6.8.9 — Relatório técnico

## Escopo
A versão parte do Core 2 v0.6.6.8.8 e mantém a Next Engine suspensa. O Soul Driver 2.0 já emitia pedidos espontâneos de troca de equipe após vantagem de ritmo. Esta versão adiciona uma avaliação **sob demanda** do engenheiro na janela **RÁDIO > COMPARAR COMPANHEIRO**, sem duplicar esses pedidos.

## Implementação
- Novo módulo puro scripts/core/race_team_radio_advice_06689.gd: compara última volta, requer duas voltas completas, carros da mesma equipe em posições adjacentes, distância até 1,5s e o histórico de ritmo (team_streak) do Soul 2.0. Chuva, composto, desgaste e pit ativo condicionam o parecer.
- scripts/apex_race_hud_0622.gd: novo botão que usa snapshot copiado de RaceEngine e não emite comandos.
- Dois novos testes: tests/team_radio_06689_advice_test.gd (28 checks) e tests/team_radio_06689_ui_test.gd (11 checks).
- Atualizados identificação do jogo, README e CI para executar os testes em Pull Requests.

**Comportamento deliberadamente consultivo:** nenhuma ordem automática de passagem, alteração de pit, RNG, física, Soul persistido ou formato de replay. A última volta é indicativa, não prova isolada de desempenho ou desgaste. O BOX V21 fica intacto.

## Evidências executadas — Godot 4.7.2
Importação headless PASS; dois novos testes 28+11 PASS; Soul 0647 e rádios legados 0630/0631/0634/0635 PASS; Core 2 sorting 4, Driver Dynamics 17 + 23, HUD Dynamics 12, Racecraft 2.0 27, Racecraft unitário 1.027, double stack, car 3D e replay 200 ticks/5 velocidades PASS.

**A/B v8.8 → v8.9:** Silverstone seco, Spa chuva intensa, Monza seco e Singapura chuva intensa: 750 ticks por pista; hashes em 1/80/250/500/750, posições dos 24 carros, eventos e checkpoints iguais nos quatro casos; BOX V21 preservado em Spa. Arquivos esportivos principais conferidos byte a byte, idênticos à base 8.8.

## Limites e rollback
Nenhuma nova corrida completa de 53 voltas, campanhas de múltiplas temporadas ou FPS em GPU real. Faça backup dos saves, instale em pasta nova e conserve o projeto 8.8 para rollback. O CI do GitHub deverá passar antes de atualizar a main.
