# APEX Scenario Matrix 1.0 — 12ª melhoria

## Objetivo

Laboratório de **regressão esportiva, não de renderização**, executado pelo
motor oficial **Core 2 / Godot 4.7.2**, cobrindo os **20 circuitos reais que
constam em `data/season_2012.json`**. Nenhuma física, clima, IA ou lógica
de box de produção é modificada por este PR.

## Modos e abrangência

| Perfil | Casos distintos | Execuções (2 por caso) | Onde executar |
|---|---:|---:|---|
| `smoke` (PR padrão) | 20 | 40 | Quatro jobs paralelos, cinco pistas por job |
| `full` (manual) | 180 | 360 | Quatro jobs paralelos, testes prolongados |

- `smoke`: uma combinação climática e de estratégia por circuito, distribuindo
  os três tipos de clima e os três modos ao longo de todas as pistas.
- `full`: para **cada pista** executa os três climas (`Seco`,
  `Variável`, `Chuva intensa`) × os três modos de controle
  (`Manual`, `Assistido`, `IA`).
- Cada combinação recebe uma **semente pseudoaleatória controlada e
  reproduzível**, derivada de SHA-256 da semente-mestre, pista, clima e
  estratégia. Duas execuções da **mesma** combinação usam a mesma semente.
- A semente-mestre padrão é `12012`; a execução manual aceita outro valor
  para explorar combinações diferentes, mantendo rastreabilidade.
- Cada GP tem **10 voltas de teste com 24 carros**, passo do motor de 4 s;
  não é um GP de distância oficial, nem medição de FPS ou GPU.
- **Manual:** as duas Ferraris têm ordens explícitas de box V6 e V7.
- **IA:** os dois pilotos Ferrari usam controle automático de box.
- **Assistido:** a IA real de `race_team_autonomy.gd` escolhe ritmo/KERS
  periodicamente; o box continua sob ordens manuais V6/V7. Esta sonda
  **não** instancia o HUD completo nem a equipe de carreira; não equivale
  a homologação da interface de modo Assistido.

## Falhas bloqueantes: FAIL

O runner marca falha quando encontra, por exemplo:

- Corrida que não chega ao final dentro de 1500 passos, sem validação.
- Falta de carros, posições duplicadas ou fora de 1–24, ou classificação
  incoerente de 24 pilotos.
- Tempos/quilometragens/desgaste não finitos, desgaste fora de 0–100%,
  ou composto de pneu não autorizado para o circuito em 2012.
- Pit stop registrado fora das voltas da corrida; quantidade impossível
  de paradas para a distância simulada.
- Ordem manual V6/V7 antecipada, cancelada ou executada mais de uma vez.
- Chuva intensa configurada sem umidade efetiva mínima observada.
- Mesmo cenário + mesma semente com **hash esportivo, passos, posição,
  número de pits, eventos de ultrapassagem ou histórico diferentes**.
- Falta de log de execução real, JSON inválido, marcador duplicado ou
  incompleto. O parser não pode fabricar `PASS`.

## Anomalias não conclusivas: WARN

Muitas paradas em um GP curto e desclassificações são registradas como
**avisos de revisão**, não automaticamente como bugs: clima, regras
históricas de pneus e incidentes podem explicar o resultado. Uma
classificação com desclassificados não é necessariamente incoerente.

O resultado deve distinguir:

- `PASS`: invariantes aprovados, sem avisos;
- `WARN`: invariantes aprovados com anomalias para investigação;
- `FAIL`: erro confirmado ou dado de teste inválido;
- `NOT_RUN` / `INCONCLUSIVE`: não executado ou resultado não verificável.

## Como usar

1. Abra **Actions → APEX - Scenario Matrix 1.0 (20 circuitos)** no GitHub.
2. Use **Run workflow**, branch e perfil `smoke` ou `full`.
3. Opcionalmente altere a `seed_base` (inteiro positivo até 2 bilhões).
4. Examine os **quatro jobs**, o resumo de cada grupo e os artefatos
   `apex-scenario-matrix-0` a `apex-scenario-matrix-3`.
5. Cada artefato inclui `plan.tsv`, dois logs reais de Godot para
   cada caso e `report.json` / `report.md` (ou `error.txt`).

Localmente, com Godot 4.7.2 instalado, o plano e os testes de contrato são:

```bash
python3 -m unittest discover -s tools/tests -p 'test_apex_scenario_matrix.py' -v
python3 tools/apex_scenario_matrix.py plan --profile smoke --shard 0 --shards 4
```

O workflow realiza os comandos do Godot com `HOME/XDG` isolados por
caso e confere os logs posteriormente.

## Integração e rollback

A melhoria **não altera o jogo**: acrescenta apenas fixture de teste,
planejador/verificador Python, workflow e documentação. O PR fica em
`draft` enquanto não houver **suíte real no GitHub** e Codacy aprovados.

Se for necessário reverter, basta reverter o commit que incorpora
esses quatro arquivos; nenhuma migração de saves ou revisão de replay
é necessária. O escopo desta melhoria não substitui o endurance de GPs
completos, o comparador A/B nem os testes gráficos.
