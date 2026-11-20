# Segurança do importador APEX: B108 — 2026-11-20

## Correção e changelog

O ZIP temporário tinha nome fixo em `RUNNER_TEMP` ou `/tmp`, com risco de
colisão/sobrescrita e alerta Bandit B108. Agora cada execução possui um
`TemporaryDirectory` privado. `RUNNER_TEMP` não vazio é respeitado; ausente/vazio
usa a seleção padrão de `tempfile`; valor inválido falha sem fallback silencioso.
O temporário é limpo em sucesso e exceções Python, inclusive `SystemExit`.

Destinos com componentes simbólicos são recusados, inclusive links internos ou
pendentes. A criação exclusiva (`xb`) impede sobrescrever um arquivo surgido
após o planejamento. Mantidos reunião das cinco partes, SHA-256, filtros,
limites, validação de projeto Godot, CRC, resumos e preservação das partes.
Nenhum conteúdo do ZIP é executado.

## Origem e integração

- Remoto verificado: `https://github.com/Quereni/APEX-Simulation.git`.
- Base: `main`, SHA `553a42eaecfc7b829c7c3c34fa5fc5098aca3eab`.
- Branch exclusiva: `fix/importer-b108-secure-temp-20261120`.
- Clone novo, inicialmente limpo; nenhuma alteração preexistente sobrescrita.
- Patch anterior aplicado com `git apply --check` seguido de `git apply`.
- A pasta de Downloads correspondia à branch
  `infra/pitwall-intelligence-analyzer-13-v1`; suas funcionalidades não foram
  incorporadas. A main já contém o importador e os utilitários de auditoria.
- O código e os testes do patch validado foram preservados; este relatório foi
  atualizado para refletir a integração no clone legítimo.

## Arquivos do PR

1. `.github/scripts/import_apex_archive.py`: temporário seguro e proteção de destinos.
2. `tools/tests/test_import_apex_archive.py`: 17 regressões direcionadas.
3. `.github/workflows/apex-seguranca-python.yml`: execução dos testes do importador.
4. `docs/APEX_IMPORTER_SECURITY_VALIDATION.md`: relatório/changelog.

Motor esportivo, HUD, replay, fábrica, IA e código GDScript permanecem inalterados.

## Resultados locais no clone Git

Python 3.12.3 e Bandit 1.9.4, ambiente já existente; sem atualizar dependências.

| Verificação | Resultado |
|---|---|
| Importador: temporários privados/únicos, fallback, limpeza, CLI, digest, partes, path traversal, symlinks, sobrescrita concorrente, filtros, duplicatas, limites, projeto inválido e CRC | PASS — 17 testes |
| Gerador de relatório Bandit | PASS — 9 testes |
| Gerador de relatório GDScript | PASS — 10 testes |
| Total solicitado | PASS — 36/36 |
| Bandit, escopo `.github/scripts tools`, excluindo `tools/tests` | PASS — saída 0, zero achados, zero erros, 2.260 linhas |
| Aplicabilidade do patch | PASS — `git apply --check` |
| Whitespace do diff | PASS — `git diff --check` |
| Conectividade de objetos Git | PASS — `git fsck --connectivity-only`, saída 0; objetos dangling informativos |
| Integridade de arquivos protegidos durante os testes | PASS — hashes SHA-256 de 2.350 arquivos rastreados inalterados |
| Godot/GdUnit4, saves, replay, pits, determinismo, física e IA | NOT_RUN localmente — não se declara aprovação do jogo |
| CI remoto e CodeQL | Não fazem parte dos resultados locais; consultar checks do SHA final do PR |

A contagem de linhas do Bandit difere da rodada em Downloads porque este clone
usa main, sem o analisador de Pit Wall daquela branch. A rodada anterior
reproduziu B108 e demonstrou que o teste do link no nome temporário fixo falha
contra o original e passa contra o corrigido.

Os logs desta rodada estão no clone em `.git/security-validation/` (não entram
no commit): três logs de unittest, `bandit.json` e `results.json`.

Comandos reproduzíveis na raiz com Python 3.12 e Bandit 1.9.4:

```sh
python -m unittest discover -s tools/tests -p 'test_import_apex_archive.py' -v
python -m unittest discover -s tools/tests -p 'test_security_bandit_report.py' -v
python -m unittest discover -s tools/tests -p 'test_gdscript_style_audit.py' -v
python -m bandit -q -r .github/scripts tools --exclude tools/tests -f json -o bandit.json
git diff --check
git fsck --connectivity-only
```

## Segurança, compatibilidade e limitações

- Continuam recusados caminhos absolutos POSIX, `..`, barras invertidas e NUL;
  destinos resolvidos devem ficar dentro da raiz. Linux/Ubuntu é o alvo validado;
  Windows não foi validado. Links ZIP e links no destino são recusados.
- Arquivos existentes são ignorados e diretórios/arquivos protegidos continuam
  filtrados. A recusa de symlinks internos antes aceitos é intencional.
- Mantidos limites de 100.000 entradas, 2 GiB descompactados e 95 MB por arquivo
  importado, duplicatas normalizadas, projeto único, scripts/cenas, CRC e tamanho.
- Extração não transacional: falhas podem deixar arquivos novos parciais no
  worktree. Usar checkout descartável; nunca integrar importação com saída não zero.
- Pressupõe runner e checkout confiáveis: a validação de diretórios pais e a
  abertura não constituem operação atômica baseada em descritores contra um
  processo local hostil. RUNNER_TEMP, partes e GITHUB_STEP_SUMMARY vêm do runner.
- Não adiciona limites de partes/tamanho comprimido, CPU, memória da tabela
  central ou tempo de leitura. Sem fuzzing ou ensaio de exaustão em escala real.
- Encerramento forçado pode impedir limpeza. Não houve reimportação do pacote real
  sobre o jogo. Bandit limpo não prova ausência de todas as vulnerabilidades.
- gdlint e gdformat não foram reexecutados: preservado diagnóstico anterior
  informativo (saídas 1, 1.366 linhas reconhecidas de gdlint). Não houve formatação
  automática nem mudança da política do workflow GDScript.

## Revisão e rollback

Revisar os quatro arquivos, os resultados locais e os checks do SHA final antes
da integração. As verificações Godot/GdUnit4/regressões exigidas pelo AGENTS.md
continuam necessárias antes de aprovar a atualização completa. Não habilitar
merge automático. Reverter o commit isolado restaura o comportamento anterior,
inclusive B108 e o risco do nome temporário fixo.
