# APEX v0.6.2.8.1 — Teste nativo de Godot e correções visuais

**Validação executada com Godot 4.7.2.stable.official.ed1daf0bf, binário Linux fornecido pelo usuário.**

Ambiente: Linux x86_64, Mesa llvmpipe (OpenGL por software) em Xvfb. Isso testa execução real, scripts GDScript, carregamento da cena e renderização gráfica, mas não reproduz necessariamente todos os drivers de GPU do Linux do usuário.

## Resultado

- Godot `--version`: `4.7.2.stable.official.ed1daf0bf`.
- Importação em modo editor: **EXIT 0**, sem erros de parser.
- Cena principal (v0.6.2.8): **EXIT 0**, avisos legados sobre âncoras/`SubViewport`, mas sem erro de script.
- Testes nativos da **v0.6.2.8.1**: **5/5 EXIT 0**, sem mensagens `ERROR:`:
  1. `core_0628_1_visual_smoke_test.gd`
  2. `core_0628_scenery_smoke_test.gd`
  3. `core_0627_tv_director_smoke_test.gd`
  4. `core_0626_1_freecam_smoke_test.gd`
  5. `core_0625_dry_strategy_smoke_test.gd`
- Renderização do circuito Bahrain em 1600×900, pelo próprio Godot: imagem capturada com sucesso.
- Câmera com `near=0.1` tinha lacunas no asfalto em distância elevada; em comparação controlada, `near=2.0` eliminou essas lacunas nas capturas usadas.
- O teste de China corrida completa (`core_0625_china_long_run.gd`) foi iniciado, mas excedeu o limite de 90 segundos e **não foi concluído**. Não contar como aprovado.

## Problemas reais encontrados e resolvidos

1. `track_3d.gd`: `finish_line.look_at()` antes de `course_root.add_child()` gerava erro `Node not inside tree`, mesmo com o smoke antigo relatando OK. Corrigida ordem de operações.
2. `Camera3D.near = 0.1`: resolução insuficiente de profundidade em tomadas muito altas. Ajustado a `2.0`, sem mudar FOV/câmera/direção.
3. `PlaneMesh 950×950` no terreno: pequenas partes de céu ficavam visíveis no panorama. Ajustado para `2200×2200`.

## Escopo

Apenas `scripts/track_3d.gd` mudou comportamento. `scripts/main.gd` e `project.godot` mudaram rótulos de versão. Os arquivos de estratégia de pneus, core de corrida, HUD, Diretor TV e câmera livre estão byte a byte iguais aos da v0.6.2.8.

## Pendências conhecidas

- Testes da janela principal podem emitir avisos de UI sobre tamanho/âncoras e `SubViewportContainer.stretch`.
- Os modelos 3D são low-poly, e os detalhes ambientais ainda são procedurais simples.
- A câmera Livre/TV precisa continuar sendo conferida no Linux real do jogador e no driver gráfico dele.
- Teste longo da China não concluído nesta validação.
