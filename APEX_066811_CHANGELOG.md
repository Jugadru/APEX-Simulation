# APEX Motorsport Manager v0.6.6.8.11 — Driver Identity Pack 2012

**Uma melhoria principal:** identidade visual correta dos 24 pilotos titulares de 2012 com número, sigla, nacionalidade e retratos individuais de pessoas reais.

- Criado `data/driver_identity_2012.json` com 24 nomes, 24 números únicos, 12 equipes e arquivos nomeados no Wikimedia Commons.
- Substituído o gerenciador neutro por carregador **opt-in**, com validação por arquivo da licença CC BY-SA 3.0 e autoria Gussisaurio, cache JPEG local e fallback só por iniciais.
- Revelados botões de download dos retratos da equipe ou grid inteira no menu principal.
- HUD: cards dos pilotos e janela de rádio exibem retrato individual se já baixado, número/código/país e atribuição; sem foto de carro como substituição.
- Documentação e links de crédito de cada fonte em `docs/DRIVER_PORTRAITS_2012_CREDITS.md`. Nenhuma foto recortada do pôster YankeeF1 foi reutilizada.
- Sem qualquer modificação nas regras esportivas, replays, saves, ordens de equipe ou motor Core 2.
- **Limites:** fotos individuais são baixadas pelo jogador após autorização no menu; não estão embutidas no ZIP. Enquadramento e apresentação de todas as 24 fotos reais ainda exigem revisão visual manual.

- Estabilidade de rede: intervalos de 1,5 s e até quatro retentativas com backoff limitado para HTTP 429/5xx, respeitando `Retry-After`; novas tentativas não alteram o Core 2.
- Validação CI: Godot 4.7.2, 16 testes Godot, 24/24 fotos verificadas por metadados e baixadas em ambiente com rede. Recortes individuais seguem sujeitos à revisão visual humana.

## Auditoria corretiva da implementação bloqueada (18/11/2026)

- Corrigido o uso de siglas derivadas do sobrenome: o catálogo 2012 passa a alimentar o leaderboard, o fallback dos cards e do rádio e a identidade exibida nos cards. Evita conflitos como Pedro de la Rosa `DLR` × Nico Rosberg `ROS`, Schumacher `MSC`, Räikkönen `RAI` e di Resta `DIR`.
- `apex_portrait_manager.gd`: método `get_abbreviation()` acessa a tabela já carregada sem duplicar o catálogo em cada refresh.
- Testes de identidade ampliados com 24 verificações das siglas na classificação e verificações dos dois cards e rádio.
- Reintegrados três testes históricos ReBroadcast no GitHub Actions: unitário, integração de modos e estado esportivo imutável, ordens de pit em fila/confirmadas. Total configurado: **19 testes Godot**.
- Não houve alteração no motor esportivo, no Replay nem nos saves. Qualidade visual dos recortes das 24 fotografias, FPS de GPU e GPs completos continuam exigindo auditoria independente.
