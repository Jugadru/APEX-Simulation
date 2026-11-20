# 13ª melhoria — APEX Pit Wall Intelligence Analyzer 1.0

## Objetivo

Investigar **decisões estratégicas observáveis**, sem reduzir toda decisão
não ideal a bug e sem transformar a IA em um estrategista perfeito.
O analisador é uma ferramenta **headless de QA**, não uma mecânica nova de
erros probabilísticos, reputação de staff, personalidade ou aprendizagem.

Ele não modifica `scripts/race_engine.gd`, física, clima, pneus,
Pit Wall de produção, interface, saves ou replay.

## Provas reais (Godot 4.7.2)

O workflow `APEX - Pit Wall Intelligence Analyzer 1.0` executa:

| Caso | Circuito | Clima | Autoridade de box |
|---|---|---|---|
| `ita_dry_auto` | Monza | Seco | IA |
| `gbr_wet_auto` | Silverstone | Chuva intensa | IA |
| `bra_variable_auto` | Interlagos | Variável | IA |
| `ita_manual_v7` | Monza | Seco | Manual (ordem V7 protegida) |

**4 cenários × 2 repetições = 8 corridas reais de 10 voltas cada**, com
24 carros, seed idêntica entre repetições, perfil HOME/XDG isolado,
hash esportivo e histórico reproduzíveis. Não confundir com os
20 circuitos do **Scenario Matrix 1.0** nem com um GP completo.

## Dados coletados, sem interferência nas decisões

Por volta do líder, observa até três carros: as duas Ferraris do jogador
e, se houver, um rival controlado pela IA. Registra:

- Volta, tempo, posição, composto, desgaste, umidade, ritmo e nº de pits.
- Autoridade Manual/IA; ordem futura, pedido de parada e procedência.
- Plano de IA realmente exposto no carro (`ai_plan`): `pit_now`,
  janela, composto e justificativa (quando houver). A falta de plano
  fica explícita, sem inventar recomendação.
- Coordenação de equipe, quando registrada.
- Histórico de paradas: volta, composto anterior/novo, fonte da ordem,
  fila de box, atraso por incidente e posição antes/depois.
- Eventos de rádio já existentes (`driver_radio`, `engineer_reply`,
  `radio`, `strategy`, `team_coordination`, `double_stack`), coletados
  do histórico completo `race.telemetry.event_history` em vez do buffer
  de até 140 mensagens da HUD.

O teste **não chama novas ordens de box ou corrige estratégias**. Apenas
o caso manual agenda V7 no início como estímulo controlado do laboratório.

## Interpretação cuidadosa

- **FAIL** — violação objetiva de contrato: carro não termina corretamente,
  posições incoerentes, pneu não autorizado, pit fora das voltas, erro
  de dados, marcador falso/ausente ou divergência na mesma seed.
- **REVIEW** — hipótese para investigação, **não** bug confirmado:
  pneus secos persistentemente em pista muito molhada, pneus de chuva
  extrema mantidos após a pista secar, três ou mais paradas em dez
  voltas, ou fila de box observada superior a três segundos.
- **OBSERVATION** — contexto da decisão humana: exposição a risco de
  pneu ou clima quando o piloto está em modo Manual. Não atribuir falha
  a uma IA sem autoridade sobre aquela ordem.
- **PASS_WITH_REVIEW** — todas as provas objetivas passaram, mas há
  perguntas estratégicas a aprofundar; não significa que a IA errou.
- **PASS** — provas objetivas aprovadas, sem os sinais específicos
  do analisador. Não significa que a estratégia foi ótima.

Os indicadores de posição antes/depois do pit **não provam causalidade**
ou tempo perdido: podem existir tráfego, incidentes, disputa e mudança
meteorológica. A equipe técnica deve inspecionar o contexto antes de
criar um bug corretivo.

## Limites

- Amostras por volta do líder, não filmagem ou telemetria contínua por
  setor; justificativas ausentes não devem ser preenchidas artificialmente.
- O analisador confere hashes, eventos e decisão registrada, mas não
  consegue inferir intenção pessoal, inteligência humana, classificação
  de qualidade de estratégia ou a veracidade histórica de decisões F1.
- Não simula funcionários com competência, personalidade ou falhas
  probabilísticas. Isso precisará de melhoria de gameplay separada.
- Não substitui o Scenario Matrix, Race Intelligence Tester,
  Endurance, SaveGuard, benchmark A/B ou testes visuais.

## Como reproduzir

Em Actions → **APEX - Pit Wall Intelligence Analyzer 1.0**, execute o
workflow manualmente ou abra PR que altere scripts relevantes.
Resultados: resumo de execução e artefato
`apex-pitwall-intelligence-report` contendo logs reais dos oito testes,
`report.json` e `report.md`, ou `error.txt` em caso de falha.

O verificador de contrato também pode ser executado localmente:

```bash
python3 -m unittest discover -s tools/tests -p test_apex_pitwall_intelligence.py -v
```

**Rota alternativa independente do GitHub Actions**, para quando o runner
remoto estiver bloqueado: em um **checkout completo do APEX**, com Godot
4.7.2 e Python 3 disponíveis no Linux, executar:

```bash
GODOT_BIN=/caminho/para/Godot_v4.7.2-stable_linux.x86_64 \\
  bash tools/run_pitwall_local.sh
```

O script valida a versão, roda os testes de contrato, importa o projeto
no Godot, executa os quatro cenários duas vezes com `HOME/XDG` isolados,
então usa **o mesmo analisador Python** para comparar hashes/decisões e
produzir `ci_artifacts/pitwall_intelligence_local/report.json` e
`report.md`. Falhas não são convertidas em PASS; logs ficam no diretório
de saída. **Executar somente o binário Godot, sem o checkout do jogo, não
constitui prova.** Uma execução local PASS também não deve ser confundida
com CI verde no commit final.

Para aceitar merge: novo teste Godot PASS, contratos Python PASS,
Codacy 0 novos problemas e regressões da branch aplicáveis PASS.
Não editar a IA real para fazer um teste artificial passar.

## Rollback

A atualização adiciona somente fixture, relatório/analisador, testes,
workflow e documentação. Reverter o commit remove o laboratório;
nenhum save de jogador é migrado ou modificado.
