# Apex v0.5.9.0 — Relatório de correção das seis falhas

**Base original:** `Apex_0590_Completo_EXPERIMENTAL.zip`, derivada de `Apex_0580_Completo(2).zip`.

## Resultado comprovado

- **Antes:** 21/27 scripts Python concluíam sem erro; seis falhavam (três listas fechadas de versões, duas comparações de hash integral da oficina após a adição de STAFF, uma referência absoluta a uma pasta 0.5.6.1 não distribuída).
- **Depois:** **29/29 scripts Python concluíram com código 0** no ambiente de execução Linux/Python 3.13.5. São os mesmos 27 scripts, com as seis correções, mais dois novos testes de regressão.
- **Conservação dos arquivos do jogo:** `project.godot`, `scripts/` (incluindo `main.gd`, `garage.gd` e `race_engine.gd`), `scenes/`, `data/` e `assets/` mantidos **byte a byte** da versão 0.5.9.0 experimental. Não há ajuste de jogabilidade neste hotfix.
- **Novas verificações:** comparação semântica de versões, funções históricas da garagem protegidas por fingerprints, salvamentos antigos com níveis padrão de STAFF e 11 componentes de física/3D/KERS/DRS com hash fixo da v0.5.8.0. Testes negativos demonstram que alterações em métodos antigos ou mecânicas preservadas provocam falha.
- **Aviso sobre SKIP:** alguns scripts legados imprimem `SKIP` de comparações opcionais com pastas anteriores não distribuídas, mas executam suas verificações locais; por isso, **29/29 significa sucesso dos scripts**, não que todos os testes legados opcionais foram executados.
- **Não executado:** parser, smoke tests e interface no Godot (o binário não está instalado e não foi possível baixá-lo aqui). Não há comprovação de correção de eventuais falhas do jogo em runtime.

## As seis falhas

| Script | Causa na base | Correção |
|---|---|---|
| `test_0530_static.py` | Lista de versões terminava na 0.5.7.0 | Valida versão mínima numericamente |
| `test_0531_static.py` | Mesmo problema na HUD e no projeto | Valida versão mínima numericamente |
| `test_0532_static.py` | Mesmo problema | Valida versão mínima numericamente |
| `test_05324_static.py` | Hash da garagem pré-STAFF | Preserva funções antigas e verifica migração de dados |
| `test_0543_static.py` | Hash da garagem pré-STAFF | Mesmo contrato; preserva hashes de mecânicas não afetadas |
| `test_0570_ai_strategy_static.py` | `/mnt/data/APEX_GODOT_0.5.6.1` ausente | Hashes imutáveis dos módulos preservados na v0.5.8.0 fornecida |

## Como testar no Linux Mint

Entre na pasta extraída do projeto e execute:

```bash
bash linux/validar_0590_python.sh
GODOT_BIN=godot bash linux/validar_core_0590.sh
```

No editor: importar `project.godot`, pressionar **F5**, iniciar Spa e alternar Manual ↔ Automático, agendar pit para volta 21, verificar KERS/ritmo e retorno ao Manual. Conferir salvamento da oficina após reabrir. Se houver erro vermelho, a mensagem exata ajudará a descobrir uma falha **real** de GDScript.
