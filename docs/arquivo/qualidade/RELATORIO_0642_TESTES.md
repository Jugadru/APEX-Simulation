# APEX v0.6.4.2 — Relatório técnico de testes

**Engine:** Godot 4.7.2 stable Linux x86_64 executado nesta sessão. **Origem:** ZIP completo v0.6.4.1 testado antes de qualquer modificação.

## Mudanças e testes funcionais

1. Oficina e P&D: custo reduzido em 15%, pagamento debitado imediatamente, entrega após duas etapas salvas, indisponibilidade de compra duplicada, cancelamento/restiuição de 75%, persistência e interface verificados via `core_0642_rival_workshop_weather_test.gd`: **PASS**.
2. Mercado rival: 11 equipes inicializadas, caixa não negativo, compras registradas no campeonato oficial, efeito no cálculo de tempo de volta, save/load, proibição de duplicar GP e upgrade: **PASS**.
3. Migração v0.6.4.1 → v0.6.4.2: temporada mantém rodada/pontos e oficina mantém orçamento, níveis e staff: `core_0642_save_migration_test.gd` **PASS**.
4. Clima: `core_0641_weather_strategy_test.gd` **PASS**, `core_0550_weather_smoke_test.gd` **PASS**, nova proteção de crossover por água atual, chuva e previsão foi exercitada no novo teste **PASS**.
5. Cronometragem: `_record_lap_cross`, `_on_lap_cross`, `_mark_finish`, `_advance_pit` e `_finish_service` preservados byte a byte em relação à v0.6.4.1; `core_0638_1_timing_rootcause_test.gd` **PASS** (0 voltas impossíveis).
6. Editor: Godot `--editor --import --quit` **PASS**, sem erros de parse. A cena de oficina abriu em tela Xvfb 1600×900 com três botões de P&D e 11 rivais, com duas capturas PNG reais (**PASS**).

## 3 GPs completos, 100% AUTOMÁTICO, modo Temporada real

Ferrari, ano 2012, 24 carros em cada GP, clima Automático, semente 321 + 7919 × rodada, sem upgrades iniciais na Ferrari. Ambos pilotos usam IA de pit, ritmo e KERS. Cada resultado foi gravado no campeonato; as rivais compraram peças após cada etapa, com efeito na próxima prova.

| GP | Voltas | Vencedor v0.6.4.2 | Pits v0.6.4.1 (controle) | Pits v0.6.4.2 | Voltas inválidas |
|---|---:|---|---:|---:|---:|
| AUS | 58 | Sebastian Vettel | 48 | 48 | 0 |
| MAL | 56 | Lewis Hamilton | 95 | 97 | 0 |
| CHN | 56 | Sebastian Vettel | 72 | 57 | 0 |

**Comparação:** 215 → 202 pits nos 3 GPs (-13). A China reduziu 72 → 57; a Malásia teve 95 → 97 (não foi melhorada). Não é honesto afirmar que o excesso de trocas está inteiramente corrigido.

Após o 3º GP: **11 rivais** acompanhadas, **33 níveis de melhorias** adquiridos e **R$ 51.15 milhões** investidos no total fictício da simulação. O campeonato salvo avançou até o GP3; a próxima etapa é Bahrein.

### Integridade e evidências

- Concluídas as três corridas com **0 voltas impossíveis**, **0 retrocessos**, classificação válida de 24 carros, KERS dentro do intervalo de 0 a 400 kJ.
- Persistência: `tests/results_0642/CAMPEONATO_APOS_GP3.json`, relatórios completos `GP_01.json` a `GP_03.json` e logs de execução.
- Rotina de regressões: 16 testes da versão anterior foram exercitados; 14 passaram na primeira execução, o teste de clima v0.6.4.1 foi corrigido no novo código e reexecutado com êxito e o teste antigo de clima (três simuladores) completou em uma segunda execução com limite maior (65,7 segundos). **Resultado final: 16/16**, com logs dos retestes, mais os 2 novos testes v0.6.4.2.
- Teste de uma corrida longa com chuva forte ainda segue nos testes históricos existentes; a temporada completa de oito GPs **não foi repetida nesta versão**. Apenas os três primeiros GPs foram realmente reexecutados.

## Limitações e próximos aprimoramentos

- A Malásia ainda exige revisão do ciclo de molhado → chuva extrema → intermediário → seco; algumas mudanças são legítimas para as condições dinâmicas. Não aplicamos limite arbitrário de pits.
- A política de desenvolvimento permite em geral até uma melhoria por rival a cada GP, conforme caixa e prioridade. Cadência de engenharia, tempos de fabricação e staff rival aprofundado poderão ser refinados depois.
- O equilíbrio de Vettel/Red Bull e os abandonos mecânicos ainda não foram corrigidos nesta entrega.
- O teste GUI ocorreu no Linux com Xvfb e GPU por software; não substitui execução no computador Linux Mint do usuário.
- Todos os atributos e ganhos de carro aqui são regras do jogo, não alegações históricas de desempenho real de equipes/pilotos de 2012.
