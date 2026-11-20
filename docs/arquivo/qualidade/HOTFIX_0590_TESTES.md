# Hotfix 1 de validação — Apex Motorsport Manager v0.5.9.0

Base: `Apex_0590_Completo_EXPERIMENTAL.zip`. Não incorpora o protótipo de HUD v0.6.0.

## Seis falhas reproduzidas na base e tratamento

1. `test_0530_static.py`: teste antigo aceitava versões apenas até 0.5.7.0 → comparação numérica de versão mínima e coerência entre `main.gd`/`project.godot`.
2. `test_0531_static.py`: mesmo problema com rótulos da HUD e Godot → verificação por versão mínima.
3. `test_0532_static.py`: mesmo problema → verificação por versão mínima.
4. `test_05324_static.py`: hash de `garage.gd` da v0.5.4 ignorava adição de STAFF → protege com fingerprints as funções antigas que continuam intactas e valida campos/migração de save.
5. `test_0543_static.py`: mesmo hash completo da garagem obsoleto → mesmo contrato compatível, preservando os hashes físicos de pit lane/pit math/3D.
6. `test_0570_ai_strategy_static.py`: dependia de caminho `/mnt/data/APEX_GODOT_0.5.6.1` inexistente fora do ambiente de criação → hashes fixos das 11 mecânicas aprovadas na base 0.5.8.0, coletados do ZIP enviado pelo usuário.

**Nenhuma das seis falhas era evidência de erro de execução no Godot.** Atualizar testes não prova a ausência de bugs visuais ou de GDScript. As verificações mantêm o contrato de física, estrutura e persistência. Há ainda testes estáticos adicionais para detectar regressões no comando de equipe.

## Godot (teste pendente)

No Linux Mint, com o projeto extraído e Godot 4 instalado:

```bash
godot --headless --path . --script res://tests/core_0590_team_control_smoke_test.gd
```

Abertura visual: importe `project.godot` e pressione F5. Teste alternar Manual → Automático → Manual, agendar BOX V21, chuva e troca de KERS. A engine não está instalada no ambiente de geração, então nenhum runtime Godot foi homologado.
