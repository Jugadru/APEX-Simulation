# v0.6.2.1 — Hotfix de parse + primeira modularização

## Falha reproduzida pela inspeção do código
- `scripts/apex_race_hud_0620.gd`: função `_create_driver_card()`, linha 287 da v0.6.2.0, tinha um nível de tabulação excedente na instrução `heading_label.size_flags_horizontal = ...`.
- Isso causa erro de análise sintática; `main.gd` também pode falhar porque faz `preload()` da HUD.

## Correção
- Removido **somente** o tab extra nessa instrução, sem modificar a mecânica da HUD.
- Extraídos de `main.gd` quatro módulos: `apex_session_settings.gd`, `apex_championship_flow.gd`, `apex_garage_presentation.gd`, `apex_race_formatting.gd`.
- `main.gd` mantém wrappers/assinaturas originais para preservar conexões de botões, chamadas de outras rotinas e cena existente.
- `main.gd` passou de 2.703 para 2.441 linhas. A modularização integral permanece futura.
- Inclusos teste estático específico e smoke test Godot para inicialização de corrida, dois cartões, expansão **para cima** e janela geral de estratégia.
- Versionamento em `project.godot` atualizado para 0.6.2.1.

## Não modificados
- `scripts/race_engine.gd`, `scripts/core/race_team_autonomy.gd`, `scripts/core/race_weather.gd`, `scripts/track_3d.gd`, `scripts/track_map.gd`, `data/season_2012.json` (comparação binária com v0.6.2.0).
- Sem alteração intencional da IA de pneus/box, evolução do clima ou campeonato.

## Testes e limitação
- O teste de módulos, caminhos, wrappers e integridade estática passou.
- O teste de indentação do projeto passou.
- A suíte estática histórica tem falhas herdadas de versões antigas (hashes do mapa e verificações de código em localizações anteriores), agravadas por parte do código ter sido movida dos arquivos antigos. Consultar `RELATORIO_0621.md`.
- **Não há Godot instalado neste ambiente:** não foi possível compilar/abrir graficamente a cena; a validação efetiva de importação e F5 deve ser feita no editor do usuário.

## Como verificar no Linux
1. Extrair o pacote numa **pasta nova** e importar o `project.godot` dessa pasta.
2. Abrir a cena `scenes/main.tscn` e pressionar F5.
3. Se disponível no PATH, executar `bash linux/validar_0621.sh` na pasta do projeto. Para binário portátil: `GODOT_BIN=/caminho/Godot_v4.x bash linux/validar_0621.sh`.
4. Testar abas T/D/E/C dos cartões, abertura para cima, classificação e tela de estratégia.
