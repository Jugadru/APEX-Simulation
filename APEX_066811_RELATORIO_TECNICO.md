# APEX v0.6.6.8.11 — Relatório técnico (Driver Identity Pack 2012)

## Objetivo
Mostrar a **pessoa correta**, não um carro ou uma identidade inventada, quando um piloto aparece na HUD ou no rádio da temporada 2012. Este é um incremento de apresentação e não de física.

## Dados e fonte
O repositório já possui 12 equipes/24 titulares e os 20 GPs 2012. A nova tabela `data/driver_identity_2012.json` associa cada nome existente ao número, abreviação, país, bandeira, equipe e nome de uma fotografia individual no Wikimedia Commons. Fotos da coleção "2012 United States Grand Prix drivers parade" são identificadas por nomes completos; autorização CC BY-SA 3.0 e autoria Gussisaurio são verificadas **na API de cada arquivo** antes de baixar.

A imagem de referência YankeeF1 não é incluída no produto nem redistribuída; uma publicação/repostagem em rede social não confirma licença por si só. Atribuições individuais em `docs/DRIVER_PORTRAITS_2012_CREDITS.md`.

## Implementação
- `scripts/apex_portrait_manager.gd`: baixa mediante clique, examina metadados, aceita apenas foto JPEG licenciada vinda de upload.wikimedia.org, cacheia em `user://apex_driver_portraits_2012` e expõe imagem por nome; se ausente, `null`.
- `scripts/apex_menu_screen.gd`: dois botões antes ocultos voltam a ser exibidos.
- `scripts/apex_race_hud_0622.gd`: cards existentes agora têm fotografia/tamanho padronizado ou iniciais, número e país; rádio tem retrato individual do piloto selecionado com atribuição quando carregado.
- `scripts/main.gd`: atualização após download e identificação da versão.
- Testes de catálogo (24 pilotos, 12 equipes, autoria, licença e sem substituição por carro) e teste de UI que impede mutação do estado esportivo.

## Proteções
Sem mudança nos scripts `scripts/race_engine.gd`, `scripts/core/race_replay_0660.gd`, `scripts/core/race_space_0655.gd`. Revisão de replay mantida, V21 e ordens manuais intactas. Toda fotografia precisa ser explicitamente solicitada pelo usuário, e é possível apagar o cache.

## Validação e limites
Importação real Godot 4.7.2 e **16/16 testes automatizados PASS** no GitHub Actions (run 44376594269). O teste de integração com rede baixou **24/24 fotografias** após uma correção de backoff HTTP 429 com intervalo de 1,5 s entre retratos; autor e licença foram validados por arquivo. Testes adicionais: catálogo 253 checks, HUD 18 checks e backoff 14 checks. As fotografias não estão embutidas no ZIP de fontes; são armazenadas localmente em cache após download voluntário do jogador.

**Estado de release:** código e pacote de fontes tecnicamente validados; enquadramento individual dos 24 rostos permanece **NOT_RUN** em avaliação humana. Duas folhas de contato (originais e recortes verticais da HUD) estão disponíveis no artefato `apex-2012-driver-face-review` da execução [44376594269](https://github.com/Quereni/APEX-Simulation/actions/runs/44376594269). A imagem do catálogo identifica a pessoa pela página de origem; o código não realiza reconhecimento facial. Fotos que não apresentem rosto de forma satisfatória precisam de substituição antes de distribuição de um pack de imagens offline.

## Pacote testado
O GitHub Actions gerou ZIP fonte com 2.304 arquivos, 14.133.827 bytes e SHA-256 `51176108796e699a3ac669d00713f4b16e0e59ffe44f125965b63c1203dec0c8` (build de código anterior a esta atualização documental). Para baixar o pacote atualizado, usar o artefato mais recente do [PR #23](https://github.com/Quereni/APEX-Simulation/pull/23). Não confundir a aprovação dos testes headless com inspeção visual dos rostos no PC do usuário.

## Auditoria de retomada — 18/11/2026

O trabalho anteriormente bloqueado por `ClientError` na v0.6.6.8 (HUD ReBroadcast 2.0) foi reconstituído a partir dos arquivos e relatórios do próprio repositório. O relatório da v0.6.6.8 registra CRC de 2.710 entradas, importação real no Godot 4.7.2 e testes unitários/integrados da HUD. A revisão v0.6.6.8.1 registra teste de Monza de 53 voltas em modo headless, integração da fila de comandos V21 e o limite de não homologação em GPU real. Essas evidências são históricas e não substituem os testes da versão corrente.

**Achado da revisão v0.6.6.8.11:** `apex_hud_rebroadcast_0668.gd` gerava siglas por três letras do último sobrenome, embora `driver_identity_2012.json` já definisse 24 códigos oficiais exclusivos. A correção passa `get_abbreviation()` para a classificação e reutiliza os códigos nos cards e no rádio. Exemplo: Pedro de la Rosa `DLR` não é confundido com Rosberg `ROS`.

**Cobertura adicional:** o workflow CI ganhou `hud_rebroadcast_0668_unit.gd`, `hud_rebroadcast_0668_integration.gd` e `hud_rebroadcast_06681_pending_orders.gd`; a suite configurada foi de 16 para 19 testes. As verificações de abreviações cobrem os 24 pilotos da grid. A aprovação final da revisão deve ser consultada no [histórico do PR #23](https://github.com/Quereni/APEX-Simulation/pull/23/checks), pois esta nota não antecipa o resultado do último commit.

**Pendências obrigatórias para homologação visual:** inspeção humana de cada enquadramento fotográfico, regressão em GPU Linux Mint real, saves e GPs integrais em pistas adicionais. A `main` não foi alterada e a revisão permanece em branch isolada.
