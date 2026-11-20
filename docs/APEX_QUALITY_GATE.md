# APEX Quality Gate 1.0 — melhoria 11

## Objetivo e condição de verdade
Painel de readiness centralizado, baseado nas **dez melhorias anteriores**.
O status READY só pode ser emitido se **todos os dez workflows estiverem
instalados na revisão examinada** e se seus jobs esperados tiverem
concluído com SUCCESS **para o SHA exato do candidato**.

**NÃO** aprove a revisão usando um run antigo de outra branch, outro commit,
uma execução ignorada/skipped ou o histórico verde de PR ainda não integrado.

## Modos de operação

| Modo | Quando | Resultado BLOCKED |
|---|---|---|
| `audit` | Todos os PRs (padrão) ou execução manual | Relatório verdadeiro; job de auditoria conclui normalmente, mas **não autoriza merge** |
| `enforce` | Execução manual `Actions → APEX - Quality Gate 1.0 → Run workflow` | Job termina com código 1; não é possível considerar o candidato READY |

**Importante:** o GitHub não irá impedir o botão de merge só por existir um
workflow. Para aplicar uma política obrigatória é necessário um administrador
configurar em **Settings → Branches / Rulesets** o check apropriado, levando
em conta que o modo padrão `audit` é apenas diagnóstico.
Não habilitar branch protection antes de integrar e estabilizar os workflows.

## As 10 evidências exigidas

| # | Arquivo do workflow | Job obrigatório |
|---:|---|---|
| 1 | `gdunit4-ci.yml` | Testes de logica 2012 |
| 2 | `apex-benchmark-ab.yml` | A-B CPU / mesmo seed e hash |
| 3 | `apex-capturas-ci.yml` | Silverstone 2012 - HUD 2D e corrida 3D |
| 4 | `apex-gdscript-toolkit.yml` | gdlint + gdformat (informativo) |
| 5 | `apex-seguranca-python.yml` | Bandit / auditoria gratuita informativa |
| 6 | `apex-export-desktop.yml` | Exportar desktop Godot 4.7.2 |
| 7 | `apex-regressao-visual-ab.yml` | Comparar HUD 2D e corrida 3D / Silverstone 2012 |
| 8 | `apex-endurance-ci.yml` | Determinismo, GPs, memoria e 20 temporadas de dados |
| 9 | `apex-race-intelligence-ci.yml` | Pit Wall, chuva, manual e IA / 2012 |
| 10 | `apex-saveguard-ci.yml` | Saves / Replay / corrupcao — baseline vs candidata |

O CodeQL é **opcional** nesta política porque repositórios privados podem
precisar de GitHub Code Security. Um job CodeQL skipped não reprova Bandit,
mas **não significa** que uma análise CodeQL ocorreu.

As verificações GDScript Toolkit e Bandit são **informativas segundo seus
workflows existentes**. Um SUCCESS nesses jobs não prova código livre de
avisos, vulnerabilidades ou erros de estilo.

## Estados possíveis

- `MISSING_WORKFLOW`: ainda não incorporado no commit.
- `NO_RUN`: não existe execução elegível no SHA exato.
- `PENDING`: execução em andamento.
- `FAILED`: última execução correspondente falhou, foi cancelada, etc.
- `JOB_NOT_SUCCESSFUL`: workflow pode estar verde, mas job exigido
  não teve sucesso; skipped não conta.
- `PASSED`: workflow e job correspondente concluídos com sucesso.

Ao escolher uma execução, prioriza a **hora do início da tentativa mais
recente**, inclusive quando um workflow antigo for reexecutado após outro,
e não apenas a data em que a execução foi criada. Dados da API ausentes,
malformados ou fora do host HTTPS oficial `api.github.com` causam erro ou
bloqueio, não aprovação.

Para os **comparadores** A/B, regressão visual e SaveGuard, o Gate aceita
somente runs de `pull_request` vinculados ao **mesmo número do PR, SHA do
candidato e SHA da base**. Uma execução de outro PR ou contra outra base
é considerada sem evidência, mesmo que seu próprio job esteja verde.
Na execução manual é necessário informar `pr_number` e `base_sha` para
que essas três comparações sejam elegíveis; sem esse contexto, o Gate
bloqueia por segurança. Executar os comparadores manualmente não é prova
de que suas opções `baseline_ref`/`candidate_ref` coincidam com o PR.

O Gate audita **todos os PRs**, sem filtro de caminhos, e pode repetir
a consulta durante até **90 segundos** enquanto houver jobs pendentes
ou ainda não iniciados. Depois desse limite mantém `NO_RUN`/`PENDING`
e informa a pendência; reexecute a auditoria quando os workflows terminarem.
Nunca repete automaticamente workflows de terceiros nem considera jobs
não executados como aprovação.

## Dependências e integração

No estado atual do projeto, os workflows 1–10 foram implementados em PRs
separados (números #8 a #17), ainda não integrados à `main`.
Por isso, uma auditoria feita agora deverá reportar **BLOCKED**, e não READY.
Isso é resultado correto, não uma falha da ferramenta.

A regressão visual do PR #14 tem dependência explícita das capturas do
PR #10: integrar o PR #10 antes de redirecionar/integrar o PR #14.

Somente depois de integrar os PRs em ordem e executar novamente os
workflows **na mesma revisão candidata** será possível obter READY.
O Gate não faz merge, não dispara/repete outros workflows, não muda regras
de segurança nem altera o jogo.

## Arquivos de saída

Artefato `apex-quality-gate-matriz` (14 dias):
- `report.json`: estado individual e URL de evidência por workflow,
  resultado completo, SHA e limitações;
- `report.md`: tabela resumida e ações pendentes;
- `error.txt`: falha de acesso a GitHub API, configuração ou execução.

## Testes
`python3 -m unittest discover -s tools/tests -p 'test_apex_quality_gate.py' -v`

Eles verificam tentativas de falsos positivos (outra revisão, skipped,
status pendente, falha recente após sucesso antigo, workflows faltantes,
comparadores manuais), além de READY somente com dez jobs bem-sucedidos.

## Limites

- Qualidade testada não é sinônimo de ausência de bugs ou de jogo pronto.
- Alguns workflows possuem filtros de caminhos. É necessário confirmar que
  foram realmente executados no SHA do candidato antes de tentar enforce.
- GitHub Actions de repositório privado pode consumir minutos do plano.
- A consulta usa o `GITHUB_TOKEN` do próprio workflow com permissão
  `actions: read`, sem token pessoal ou credenciais gravadas.
