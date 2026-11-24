# v0.6.6.9.17.9 — Season Preparation Rework (candidata)

Base: `dc6ad3469301bb5019e13998944332c3324c00eb` / PR #123. Uma funcionalidade principal: preparação de temporada e GP. Identidade grafite/laranja da 9.17.8.

## Changelog
- Standard abre rascunho explícito de temporada, sem iniciar GP avulso nem sobrescrever campeonato. Primeira etapa do calendário fixa; equipe e semente base configuráveis; clima e incidentes são do GP atual, não regras persistidas de toda a temporada.
- Criar temporada abre confirmação com equipe, seed e aviso de substituição do save. Cancelar preserva estado e arquivo. Após confirmação, controlador existente cria calendário e bloqueia equipe/circuito/seed; ação passa a disputar etapa. Temporada concluída não permite largada.
- Painel de equipe mostra cor, atributo base do carro, dupla oficial e habilidade dos pilotos com retratos locais opcionais. A escolha de equipe seleciona a dupla fixa de 2012; transferências e contratação de pilotos não foram implementadas. Sem download de fotografias.
- Resumo reativo de circuito, voltas, distância por volta, clima, modo de controle e seed. Sandbox, treinos, STAFF e oficina mantêm rotas e callbacks existentes. Identidade visual local e botão de ação fixo fora da rolagem. Reaplica limites do painel após ajuste de tamanho mínimo de textos.
- Não modifica o Core 2, regras esportivas, geometria, HUD, Pit Wall, replays, formato de saves, contratos, navegação ou lógica de clima. Usa os controladores existentes, sem introduzir novo sistema de persistência.

## QA
`season_preparation_09179_test.gd`: todas as 12 equipes / 24 pilotos, retratos opcionais, rascunho, criação, cancelamento e save em disco, campeonato concluído, Staff, presets, lançamento e retomada com hash esportivo, três resoluções e CTA fora da rolagem. FAST, Test Lab e regressões direcionadas, CI gráfica própria. Capturas com retratos privados somente no ZIP privado. GPU física, ultrawide, gamepad e GPs completos não fazem parte do ensaio desta revisão visual. Rollback: base acima; manter backup de saves. Sem merge antes da homologação.
