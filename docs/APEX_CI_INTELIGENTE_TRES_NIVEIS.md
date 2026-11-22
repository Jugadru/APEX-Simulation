# APEX — Desenvolvimento FAST permanente

O projeto recebe atualizações pequenas e sequenciais. **FAST é o único ciclo
automático**: um workflow Godot 4.7.2 em PR e push para main, sem etiquetar
versões com `ci:full` ou iniciar baterias de homologação.

## FAST
O arquivo `.github/workflows/godot-setup.yml` faz uma importação real do
Godot, executa o **APEX Test Lab** (24 carros, clima seco/chuva, hash
reproduzível, CPU/p95/memória) e os testes direcionados que o diff realmente
acionar. Os casos são selecionados em `tools/apex_ci_tiers.py` e no
manifesto `.github/apex-quality-suites.json`. Um erro ou um teste selecionado
sem PASS permanece uma falha real; não se usa job `skipped` como sucesso.

**Não há circuito inteiro ou matriz de 20/180 corridas no FAST.** Pode existir
checagem leve de que as 20 pistas reais estejam cadastradas: isso só
verifica dados e não simula GPs. Alguns regressivos especializados antigos
podem consultar um circuito real para reproduzir um bug específico; eles
não integram a matriz e não substituem o Lab como bancada padrão.

## Não há um workflow por versão

Removidos os workflows de versões 9.3–9.14 e os publicadores fixos de
releases antigas. **Os scripts de teste históricos foram mantidos** para
detectar regressões selecionadas pelo subsistema; novos sistemas devem
adicionar um caso ao seletor/manifesto existente, não mais um workflow com
nome de versão. O jogo atual inclui sistemas anteriores, mas isso não
dispensa testar a compatibilidade deles quando o código compartilhado muda.

## Homologação somente sob pedido explícito

Disponível manualmente em GitHub Actions, sem disparos automáticos:

- Core 2: `workflow_dispatch(tier=full)`;
- Matriz de 20 ou 180 cenários: `apex-scenario-matrix-ci.yml`;
- Endurance, saves/replays, benchmark, captura, exportação e Quality Gate:
  seus workflows genéricos, sob demanda.

A homologação não é pré-requisito operacional para alterar scripts ou
integrar PRs que passaram no FAST. Pode ser pedida antes de um lançamento,
após mudança esportiva arriscada ou para reproduzir bug concreto.

## Limitações

O Lab sintético não mede FPS da GPU nem reproduz toda a geometria de Mônaco,
Silverstone ou as regras de chuva em cada pista real. Se uma falha depender
desses fatores, usamos uma pista real **apenas naquele teste**, sem exigir
novamente uma homologação de todo o projeto. Os logs e hashes da CI ficam
disponíveis para diagnosticar problemas sem aguardar uma hora.
