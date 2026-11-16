# Auditoria — 0.6.5.8
Base: APEX_MOTORSPORT_MANAGER_v0.6.5.7_PERFORMANCE_PROFILER_COMPLETO.zip, SHA256 d72806ea3cd924c14892fbf7196d124e975d4078213822eeaba3e7256054df6a. CRC e 1719 hashes do manifesto conferidos antes da extração. ZIP anterior retido como backup. Diretório novo; sem sobrescrever releases anteriores. project.godot confirmou 0.6.5.7. Relatório técnico, baseline e plano futuro lidos. Base importada e testes unitários do profiler, RNG, motor espacial e save legado repetidos com sucesso.

## Consumidores do estado por frame
- main._process: antes copiava cada carro profundamente, inclusive históricos; depois projetava player e rota.
- track_map: id, progress, name, position, color, player, pit_left; sem gravação no motor.
- apex_mini_map: id, route_point, player, color. update_map do HUD delega a este controle; o restante do HUD consulta race diretamente na frequência existente.
- track_3d: identidade/cor, progress/rota, estados e tempos de pit, composto, DRS e player.
- apex_racecraft_0654: id/grid/progress, finished/pit_left, race_lane, combat_state/target, route_point/direction. Resolve ocupação após a suavização.

## Mudanças delimitadas
Novo race_view_snapshot_0658.gd; main integra contrato e revisão por sessão/foco; track_map e apex_mini_map ignoram chamadas ocultas e estados iguais. Três scripts de produção existentes modificados. Motor, estratégia, ocupação, modelos 3D, HUD e garagem não editados. Metadados/README atualizados.

## Invalidação e suavização
Nova identidade de RaceEngine limpa o cache. IDs removidos não ficam retidos. Mudança de pit stage, finished, regressão de progress ou salto de >=0.05 volta usa o estado atual diretamente. A progressão é absoluta, evitando interpolação para trás na emenda da volta. Pausa mantém a pose e permite alterações de seleção. Reentrada de mapa recebe estado atual no próximo envio; minimapas legados mantêm seu intervalo anterior de 0.25 s. O estado 3D continua sendo atualizado por frame durante corrida para rodas/DRS/boxes; na pausa, somente mudança visual, seleção ou reentrada o atualiza. Câmeras continuam com a lógica anterior.

## Correção de fixture
pit_incidents_double_stack_test solicitava Macio em Spa, composto indisponível. O teste agora escolhe um composto legal; não se alterou o motor nem o atraso mecânico. A cópia de validação corrigida já passava em ambas as versões na 0.6.5.7.
