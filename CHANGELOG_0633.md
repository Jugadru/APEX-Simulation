# Apex Motorsport Manager v0.6.3.3 — Rádio por categorias + percepção dos pilotos

**Base:** Apex v0.6.3.2, Godot 4.7.2. O motor de corrida, cenas 3D, câmeras Livre/Seguir/Diretor TV e HUD compacta foram mantidos.

## Alterações

- `scripts/apex_commentary.gd`: filtros `Todos`, `Transmissão`, `Equipe`, `Pilotos`; mantém rádio interno fora da TV; adiciona registro da consulta ao piloto com papéis CHEFE/PILOTO/ENGENHEIRO.
- `scripts/apex_race_hud_0622.gd`: quatro filtros na janela real de rádio, seleção persistente durante reabertura, estilo do filtro ativo e botão **OUVIR PILOTO**.
- `scripts/core/race_driver_perception_0633.gd`: percepção subjetiva determinística de aderência, temperatura, umidade e ar sujo, só para o diálogo. Não é alegação sobre temperamento de pilotos reais; não altera simulação.
- `scripts/apex_radio_feed.gd` e `scripts/apex_race_ui_legacy_builder.gd`: compatibilidade do painel legado com quatro categorias.
- `project.godot`: nome de versão 0.6.3.3.
- `tests/core_0633_radio_categories_soul_smoke_test.gd`: regressão nativa, escopo de canais, GUI e estado imutável.
- `tests/native_capture_0633.gd`: reprodução da captura gráfica.

## Comportamento

- **TODOS**: todos os eventos registrados no histórico.
- **TRANSMISSÃO**: narração, analista e eventos de box da transmissão; sem conversas privadas.
- **EQUIPE**: chefe, engenheiro, rádio dos pilotos e box da própria equipe.
- **PILOTOS**: somente mensagens dos pilotos do usuário.
- As quatro perguntas anteriores ao engenheiro continuam presentes. Fazer uma pergunta ou usar `OUVIR PILOTO` mostra o diálogo completo na categoria **EQUIPE**; pode-se depois escolher **PILOTOS** para isolar a fala do piloto.

**Sem mudanças intencionais:** pneus, física, IA, pits, tempo, HUD geral, pistas, câmeras, oficina, temporadas e dados das equipes.
