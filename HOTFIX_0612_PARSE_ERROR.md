# Apex Motorsport Manager v0.6.1.2 — Hotfix de carregamento Godot

## Erro reportado
A v0.6.1.1 apresentou `Failed to load script`/`Parse error` ao importar no Godot 4.7.2,
incluindo `scripts/main.gd`, `scripts/track_map.gd` e dois scripts de testes.

## Causa encontrada
Na função `_draw_strategic_circuit()` de `scripts/track_map.gd`, a atualização
0.6.1.1 usou 4/8 espaços, enquanto as demais funções do mesmo arquivo usavam
tabulação. Essa mistura impede o parser GDScript de carregar o módulo.
Os outros erros podem ser consequências dos `preload()` que dependem do mapa.

## Correção
Apenas a indentação daquela função foi alterada, sem mudar a geometria,
desenho do mapa, movimento dos carros ou motor da simulação. Incluídos um
verificador Python de indentação e um smoke test nativo Godot. O documento
original da HUD-RACE-060 foi mantido em `docs/` para orientar a futura
reformulação da interface (pista protagonista, câmera aérea, painéis sob demanda).

## Verificação local
- Validar ZIP: Python `zipfile.testzip()`.
- Rodar `python3 tests/test_0612_indent_static.py`.
- Rodar a suíte Python de regressão disponível.
- No Godot 4: `godot --headless --path . --script res://tests/core_0612_load_smoke_test.gd`.
- Abrir o projeto pelo `project.godot` e pressionar F5.

**Limitação:** neste ambiente o executável Godot não está instalado e downloads
externos estão bloqueados. A correção não pode ser descrita como compilada ou
validada visualmente antes de rodar no Godot do jogador.
