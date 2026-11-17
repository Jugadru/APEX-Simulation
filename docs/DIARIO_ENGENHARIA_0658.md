# Diário de engenharia — 13/11/2026
1. Confirmada entrega 0.6.5.7 e manifesto completo; extraída base para 0.6.5.8, preservando backup.
2. Inspeção encontrou históricos inteiros copiados a cada frame. Auditoria dos quatro consumidores permitiu contrato com somente valores simples. HUD de gestão e telemetria não passam por este contrato.
3. Pesquisa oficial orientou isolamento dos containers e separação de animação. Não foi ativada interpolação física global porque o motor do APEX não usa o tick físico padrão do Godot.
4. Implementada suavização com blend comum antes do solver de ocupação. Não suavizar transforms depois do solver: isso poderia invalidar suas garantias de espaço. Progress absoluta trata a emenda; pit/fim/seek são descontinuidades explícitas.
5. Visibilidade e igualdade evitam redesenho sem remover controles. Estado 3D parado usa revisão e foco. Rodas/DRS e serviços continuam ativos durante corrida.
6. Primeiro teste unitário teve erro de inferência de tipo na variável frozen; corrigido com float explícito. Primeiro teste de foco falhou porque Diretor TV substituía o ID manual: fixture mudou para Seguir piloto e manual_driver, como a interface real. Testes corrigidos passaram.
7. Fixture histórica de double stack corrigida para composto disponível. Regressões mantêm física e parâmetros anteriores.
8. Medições nativas usam execuções sequenciais e alternam base/nova. O primeiro microbenchmark coincidiu com regressões; descartado para conclusões e repetido isoladamente. Benchmark de históricos é sintético, explicitamente separado de FPS.
9. Próximo passo: cache geométrico 0.6.5.9, sem antecipar mudanças esportivas ou replay nesta entrega.

10. Teste longo KERS/DRS excedeu timeout de 90 s; repetido sem alterações, com orçamento de 300 s, passou. Não houve assert falho no motor.
11. Medição solicitada em 1920 foi limitada a 1786×1005 pelo gerenciador de janelas; série arquivada e excluída. Fixture corrigida para fullscreen e assert das dimensões.
12. Capturas 1600/1920 revisadas: HUD e os dois pilotos visíveis. Artefato escuro serrilhado junto à junção da pista também reproduzido na base 0657; registrar para revisão geométrica, sem atribuí-lo a esta otimização.

13. Série 1080p válida mostrou regressão de taxa global apesar de menor montagem visual; tempos também aumentaram no motor inalterado. Causa não isolada, sem repetir medições para selecionar apenas resultados favoráveis. Ganho localizado e limitação publicados juntos.
