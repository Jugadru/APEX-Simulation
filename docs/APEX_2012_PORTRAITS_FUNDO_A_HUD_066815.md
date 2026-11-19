# APEX 2012 — fundo A nos 24 pilotos e HUD (v0.6.6.8.15 visual)

## Entrega de código
Branch: `feature/apex-orange-portraits-hud-066815`, derivada de `feature/portraits-2012-exact-crops-066813` (PR #25). Não alterar `main` ou marcar release estável antes de integrar a base e executar regressões.

- `scripts/apex_portrait_local_2012.gd`: 24 IDs estáveis e mapeamento HUD/perfil com normalização de acentos.
- `scripts/apex_portrait_manager.gd`: prioriza foto local, preserva fallback Wikimedia previamente licenciado e iniciais; créditos deixam explícita a origem local e a licença não verificada.
- `scripts/apex_race_hud_0622.gd`: pequena miniatura de piloto na classificação de 24 carros, além de cartões e rádio existentes, **sem refatorar a HUD**. Texturas em cache, nenhuma alteração esportiva.
- `scripts/apex_menu_background.gd`, `apex_menu_screen.gd`, `apex_front_menu.gd`: carregam fundo A atrás dos menus, painéis grafite legíveis e bloqueio de eventos do mouse; B preservado como alternativa.

## Imagens binárias necessárias (não versionadas neste PR)
O ZIP gerado na conversa se chama `APEX_2012_Fundo_A_PortraitPack_48_Assets_v0.6.6.8.15.zip` e deve ser extraído na raiz do checkout Godot, onde fica `project.godot`. Estrutura:
```
assets/menu/apex_menu_background_a.png
assets/menu/apex_menu_background_b.png
assets/portraits_2012/hud/<piloto>_hud_2012.png        (24 × 384×400)
assets/portraits_2012/profile/<piloto>_profile_2012.png  (24 × 640×800)
assets/portraits_2012/manifest_2012_orange_a.json
```
Os 48 PNGs foram compostos a partir dos recortes de fotografias fornecidas pelo usuário, com substituição do fundo por composição de pixels. Há pequenas imperfeições de segmentação que exigem QA visual em tamanho integral. A autorização para redistribuição das fotografias **não foi comprovada**: manter o uso para revisão privada até verificar os direitos. Não substituí-las por fotografias aleatórias da internet.

Sem o ZIP de imagens, o código exibe a cor grafite de fallback no menu e mantém o mecanismo anterior de retratos licenciados ou iniciais.

## Teste
```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/apex_portraits_menu_066815_smoke.gd
```
Em ambiente isolado Godot 4.7.2 com os PNGs, a importação dos 48 retratos, os nomes com acentos e a textura A resultaram em PASS. Não afirmar isso como teste completo da árvore de jogo.

## Critérios de revisão pendentes
- Visual do menu e dos cartões HUD em 1600×900 e 1920×1080.
- Corrida completa/replay e save/load em Silverstone/Monza.
- Verificar bordas de cabelo, capacetes e mangas dos 48 retratos; risco de artefatos.
- Medir o custo de 24 miniaturas na classificação versus a versão anterior.
- Confirmar que todos os assets de terceiros podem ser redistribuídos antes de publicar o jogo.
