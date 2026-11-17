# APEX Motorsport Manager — HUD Híbrida 0.6.3.5 + 0.6.4.5

**Base funcional:** v0.6.4.5 Race Intelligence & Driver Soul.
**Origem visual:** HUD UI01 da v0.6.3.5 (pacote UI02).
**Godot:** 4.7.2.

## O que realmente foi misturado

- A **paleta grafite/laranja** e o tema de controles da v0.6.3.5 foram aplicados à **HUD real** da v0.6.4.5, com bordas discretas, modais escuros, classificação transparente, destaque laranja e botões consistentes.
- Mantidos **seis atalhos superiores**, inclusive `ENG.` da UI03, em vez dos cinco atalhos da 0.6.3.5.
- Conservados os dois cartões compactos dos pilotos, ranking, clima, minimapa, controle flutuante de velocidade, abas de estratégia, rádio e Discussão de Stint.
- A UI03 continua exibindo **Race Engineer 2.0, IA Estratégica 2.0, estado Apex Soul, alternativas, confiança, pit/ritmo/KERS e ordens Manual/Assistido/Automático**.
- A cor técnica verde-água foi mantida em detalhes da análise tática, combinando as identidades.
- As telas da central **UI02 da 0.6.3.5 não foram substituídas na v0.6.4.5**: este merge se limita à HUD durante a corrida, conforme solicitado.

## Base intacta

Não houve alteração em `scripts/race_engine.gd`, `scripts/core/`, circuitos, IA, física, pneus, calendário, interface principal, cenas, gráficos 3D, oficina, liga, carreiras, pit stops ou saves do motor.
Os arquivos realmente modificados no jogo são `scripts/apex_race_hud_0622.gd`, `project.godot` (título e isolamento dos saves).
O script de tema `scripts/apex_race_hud_skin_ui01.gd` e seu UID vieram da UI01 0.6.3.5.
Também foram acrescentados teste visual e capturas em `docs/`.

**Saves seguros:** esta variante usa `ApexMotorsportManager_HUD_Hibrida` em `config/custom_user_dir_name` e, por padrão, não sobrescreve os saves do Apex original. Para reutilizar os saves antigos, faça backup e transfira-os para a pasta de dados correspondente ou ajuste essa opção conscientemente. Formato de save não foi modificado.

## Como abrir

1. Extraia **todo** o ZIP em uma nova pasta.
2. No Godot **4.7.2**, importe o arquivo `project.godot`.
3. Execute com **F5**, configure uma corrida e entre na pista.
4. Na corrida, use **ENG.** para abrir o Race Engineer 2.0 com visual grafite/laranja.
5. Use os demais botões para Corrida, Estratégia, Dados, Eventos e Rádio.

## Testes executados (Godot 4.7.2)

- Editor/importação headless: **PASS**, sem erros de script.
- `core_0622_corner_hud_smoke_test.gd`: **PASS**.
- `track_0644_hud_integration_test.gd`: **PASS**.
- `race_0645_intelligence_test.gd`: **PASS** (compatibilidade UI03).
- `hud_hibrida_0635_0645_visual_test.gd`: **PASS** em renderização real Xvfb/Mesa; verifica atalhos, 2 pilotos, rádio, Race Engineer, tema, layout em 1600×900 e 1920×1080, e que a abertura do painel não executa pit stops.
- Capturas reais: `docs/HUD_HIBRIDA_CORRIDA_1600.png` e `docs/HUD_HIBRIDA_ENGENHEIRO_1600.png`.

Observações: renderização no Xvfb/Mesa não substitui teste de FPS na GPU de destino; não reexecutamos uma temporada inteira apenas por esta modificação visual. Os manifestos e logs históricos da v0.6.4.5 permanecem como histórico, não como verificação de hash deste novo ZIP. Consulte `BUILD_MANIFEST_HUD_HIBRIDA.json`.

## Arquivos da mesclagem
- `scripts/apex_race_hud_0622.gd` — tema, classificação, cores e apresentação UI03.
- `scripts/apex_race_hud_skin_ui01.gd` (+ UID) — skin original da 0635.
- `project.godot` — identificação e saves isolados.
- `tests/hud_hibrida_0635_0645_visual_test.gd` — regressão visual e comportamental.
- `docs/HUD_HIBRIDA_*.png` — capturas reais do jogo.

