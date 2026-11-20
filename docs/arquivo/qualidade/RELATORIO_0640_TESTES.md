# APEX v0.6.4.0 — RELATÓRIO DE TESTES EFETIVAMENTE EXECUTADOS

Ambiente: Linux x86_64, Godot **4.7.2.stable.official.ed1daf0bf**. Base: ZIP completo da v0.6.3.9, com importação Godot nativa. O novo projeto também foi importado com `--headless --editor --import --quit` sem erro de parse.

## Resultado das corridas reais do simulador

| Teste | Configuração | Resultado medido |
|---|---|---|
| Interlagos, seco e pits manuais | 71 voltas, 24 carros, Ferrari, seed 321 | **PASS**; Fernando Alonso vencedor; 1.410 passos de 4s; relógio simulado ~5.640s; 0 voltas inválidas; 48 pits na grid; 4 pits Ferrari (V23/V25, V48/V50) |
| Interlagos, chuva forte e IA de pit | 71 voltas, 24 carros, Ferrari, seed 321 | **PASS**; Sebastian Vettel vencedor; 1.412 passos; relógio simulado ~5.648s; 0 voltas inválidas; 48 pits na grid |
| Interlagos, delegação mista | 71 voltas, 24 carros, Ferrari, seed 321; primeiro piloto ASSISTIDO, segundo AUTOMÁTICO | **PASS**; primeiro piloto com paradas manuais exatas **[23,48]** e segundo piloto com pits automáticos **[21,46]**; 0 voltas inválidas; KERS dentro de 0–400 kJ; classificação validada |

O teste misto executou a **cena real** e chamou o STAFF durante a corrida, verificando os modos individuais e a IA de pit no mesmo GP. O motor de física `scripts/race_engine.gd` continua **byte a byte idêntico** ao da v0.6.3.9. SHA-256: `03faf04f2697d9491ab136232f0843ccbeb6fb665c0200944014cb7ca8538b6c`.

## Demais testes

- `core_0640_pitwall_intelligence_test.gd`: **PASS** — evidências não mutáveis, clima, double stack, KERS, delegação por piloto, botões da HUD, rádio, V21 e comando global.
- **16 testes adicionais de regressão passaram** (ver `tests/results_0640/apex_0640_regressions.tsv`): rádio/Soul Driver, Race Engineer v0.6.3.9, HUD, energia KERS, pit lane, mini GPs, segurança de box e controle de equipe.
- `native_capture_0640.gd`: **PASS** — cena real no Godot, Xvfb 1600×900, painel ENG. com **primeiro piloto Assistido e segundo Automático**. Arquivo `docs/APEX_0640_PitWall_Preview.png`.
- A abertura visual em Xvfb usou áudio virtual: os avisos ALSA de dispositivo ausente são limitação do ambiente de teste, não do script do projeto.

## Itens não testados

- Instalação da v0.6.4.0 no computador pessoal Linux Mint do usuário.
- Temporada 2012 completa de 20 GPs após esta atualização.
- Jogabilidade detalhada por muitas horas, incluindo todos os circuitos ou todas as resoluções possíveis.

Não declarar esses itens como aprovados sem executá-los.
