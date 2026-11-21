# APEX — Organização e refatoração incremental do repositório

Este documento atualiza, sem substituir, o mapa histórico [MAPA_MODULOS_0624](../arquivo/relatorios/MAPA_MODULOS_0624.md). As divisões abaixo refletem os arquivos reais da `main` após as Melhorias 14 e 15. Esta é a **etapa 1**, não uma promessa de reorganização integral.

## Diagnóstico do código em novembro de 2026

| Arquivo | Tamanho aproximado | Responsabilidade atual | Próxima separação recomendada |
|---|---:|---|---|
| `scripts/apex_race_hud_0622.gd` | 109 KB | HUD principal e comportamento visual | componentes de HUD por painel, preservando nós e sinais |
| `scripts/race_engine.gd` | 68 KB | estado/ciclo de corrida, estratégias, pit e apresentação | separar apenas funções puras, uma API por PR |
| `scripts/track_3d.gd` | 36 KB | desenho e cenas 3D da pista | geometria, decoração, atualização visual |
| `scripts/apex_race_hud_0620.gd` | 36 KB | HUD legado/auxiliar | mapear todos os chamadores antes de alterar |
| `scripts/main.gd` | 33 KB | coordenador de cena e integrações | reduzir encadeamento por host, sem perder sinais |
| `scripts/core/race_replay_0660.gd` | 24 KB | gravação, validação e reprodução | isolar validação sem alterar formato esportivo |

Os números foram arredondados a partir da árvore do GitHub; não são benchmarks de performance.

## Estrutura-alvo incremental

- `scripts/core/`: física esportiva, clima, pneus, Pit Wall, corrida, regras e replay. Os caminhos públicos atuais devem permanecer até migração explícita.
- `scripts/presentation/`: somente formatação textual ou adaptadores visuais sem efeitos esportivos.
- `scripts/apex_*.gd`: telas, controladores existentes, gerenciamento e integração com cenas; mover com cautela devido a preloads, nós e sinais.
- `tests/`: testes Godot reais, com marcadores de PASS e comparação de saída histórica.
- `tools/` e `tools/tests/`: analisadores CI Python e seus testes.
- `docs/architecture/`: mapa atualizado, contratos de extração e roteiro de refatoração.
- `docs/arquivo/`: relatórios e documentação histórica mantidos como referência, sem exclusões.

## Etapa 1 — classificação textual

A formatação de `RaceEngine.standings_text(limit)` é delegada a `scripts/presentation/race_standings_text.gd`. A seleção e a classificação esportiva permanecem em `RaceEngine.get_sorted()`; conversão de compostos permanece em `RaceEngine.tyre_code()`. A API `standings_text(limit = 24)`, espaçamento, acentos, posição, limite e gaps permanecem idênticos, inclusive a semântica para limites negativos. Nenhum dado esportivo, seed, RNG, checkpoint ou replay é alterado.

`tests/standings_refactor_test.gd` recalcula a saída antiga em situações de corrida e pós-corrida, com múltiplos limites, e compara byte a byte com a implementação extraída. O Core 2 CI executa o teste em Godot 4.7.2.

## Portões de segurança das próximas etapas

1. **Inventariar dependências reais primeiro:** `preload`, `load`, `res://`, referências a nós, sinais, snapshots e ferramentas de teste.
2. **Uma extração por PR:** manter fachada pública e nomes de métodos, não migrar arquivos em massa; testes de equivalência antes/depois.
3. **Não tocar em comportamento esportivo durante refatorações:** motor, RNG, estratégias V21/V4, regulamento 2012, pneus, clima, save, replay e tempos de corrida devem conservar os contratos.
4. **Validar com o Godot verdadeiro:** importação, Core 2, GdUnit4, Matrix 20 circuitos em duas repetições, SaveGuard, Pit Wall e testes de longa duração. Reexecutar importações 139 antes de atribuir falha ao código.
5. **Evitar reorganização destrutiva:** não apagar arquivos legados, assets ou versões históricas sem prova de ausência de referências.
6. **Comparar baseline:** não exigir hash diferente; refatoração sem alteração esportiva deve preservar hashes, além de saída de interface.

## Sequência futura sugerida (não implementada nesta PR)

1. Agrupar apenas outras funções de **apresentação pura** do `race_engine.gd`, mantendo a fachada.
2. Examinar `apex_race_hud_0622.gd` por painel independente e extrair **um painel** por PR, preservando a árvore de nós.
3. Auditar se `apex_race_hud_0620.gd` e os arquivos legados ainda têm dependências ativas, antes de qualquer remoção.
4. Separar construção e renderização de `track_3d.gd` em módulos próprios, com regressão de capturas 2D/3D.
5. Organizar as suítes Python por domínio sem alterar classificações de WARN/FAIL.

**Rollback:** reverter somente esta PR; o método `standings_text` continua com a assinatura histórica, e a formatação original pode ser restaurada sem migração de arquivos de jogo.
