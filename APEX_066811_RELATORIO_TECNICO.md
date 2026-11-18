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
Importação Godot 4.7.2 e testes automatizados no GitHub Actions necessários antes de merge. Fluxo de download on-line das 24 fotos, licenças e enquadramentos requer teste manual ou integração em ambiente com rede, além do smoke test headless. As fotografias não estão embutidas no ZIP de fontes; são armazenadas localmente em cache após download.

A imagem do catálogo identifica a pessoa pela página de origem; o código não realiza reconhecimento facial. Fotos que não apresentem rosto de forma satisfatória precisam de substituição por retratos mais próximos antes de distribuição de um pack de imagens offline.
