# Apex Motorsport Manager — v0.5.9.0 Hotfix 2 (botão Iniciar Corrida)

## Defeito relatado

Nas capturas do Linux Mint/Godot, a tela de seleção de equipe/circuito era exibida mas não mostrava o botão para começar a corrida. O script original criava `start_button` como filho da `VBoxContainer` interna de uma `ScrollContainer`, **depois** do briefing, clima, seleção manual/automático e outras opções. Por isso o botão estava abaixo da porção visível do formulário.

O menu era dimensionado para até 880 × 620 pixels, estreito/baixo para o conteúdo acrescentado em versões sucessivas. O formulário também herdava larguras mínimas de opções com textos longos.

## Correções no script principal

- **Ação fixa:** `start_button` é filho de `menu_actions`, uma `VBoxContainer` fora de `menu_scroll`, abaixo do conteúdo rolável. O texto é **INICIAR CORRIDA / ENTRAR NO GRID**, conectado à função `_start_race()` original.
- **Dimensões responsivas:** menu central com largura máxima de 1220 px e altura máxima de 760 px, limitado pelo viewport. A coluna descritiva é ocultada em larguras inferiores a 1100 px, liberando espaço para o formulário.
- **Opções sem expansão excessiva:** `fit_to_longest_item = false` nos seletores de equipe, circuito, incidentes, clima e modo Manual/Automático.
- **Área de rolagem:** formulário continua rolável sem esconder o botão principal.

## Arquivos alterados

- `scripts/main.gd` — layout do menu e posição do botão (único arquivo de gameplay alterado).

## Preservado sem mudanças

- `scripts/race_engine.gd` — cálculo e progressão de corrida;
- `scripts/track_map.gd`, `scripts/track_3d.gd` — mapas 2D e 3D;
- `scripts/tv_director.gd` — câmeras e Diretor TV;
- `scripts/garage.gd`, `scripts/core/race_team_autonomy.gd` — oficina, STAFF e modo Automático;
- `data/season_2012.json` — equipes, pilotos e circuitos;
- `project.godot` — resolução/base da versão 0.5.9.0, sem migrar para 0.6.0.

## Testes

- **30/30 testes Python aprovados**, incluindo `tests/test_0590_menu_fixed_static.py` novo.
- Verificados hashes SHA-256 de arquivos críticos preservados contra a base 0.5.9.0 Hotfix 1.
- Verificação de integridade ZIP concluída na entrega.
- Novo teste **Godot nativo** `tests/menu_0590_ui_smoke_test.gd` incluído para validar dimensões 1600×900, 1280×720 e 1024×768 e clique que inicia GP com 24 carros.
- **Limitação:** não havia executável Godot disponível no ambiente de construção, portanto esse teste nativo e a aparência final dependem da execução no Linux Mint do usuário. Não chamar a renderização de aprovada antes desse teste.

## Como usar

1. Extraia o ZIP completo em pasta nova.
2. No Godot, importe `APEX_GODOT_0.5.9.0_MENU_HOTFIX2/project.godot` e pressione F5.
3. O botão **INICIAR CORRIDA / ENTRAR NO GRID** deverá aparecer permanentemente na parte inferior do painel Grande Prêmio, sem rolagem.
4. Se preferir atualizar a pasta existente, copie somente `scripts/main.gd` do patch para a mesma pasta no seu projeto (faça backup do arquivo anterior).
5. Para testar via terminal, na raiz do projeto, rode `python3 tests/test_0590_menu_fixed_static.py` e, se o executável Godot estiver no PATH, `godot --headless --path . --script res://tests/menu_0590_ui_smoke_test.gd` (substitua `godot` pelo comando do seu executável, se necessário).
