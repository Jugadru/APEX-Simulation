# Relatório técnico — APEX 0.6.2.5

## Evidência de causa no código 0.6.2.4
- `race_ai_director.gd` elegia composto por horizonte de 8 voltas, depois previa ganhos em 9 voltas; custo dos pits futuros ausente.
- `race_strategy.gd` tinha regras de desgaste e chuva, mas sem planejamento conjunto de stints até a bandeirada.
- `race_engine.gd` mantinha `used_tires` e nomeações sem validar o uso de ambos os slicks no resultado seco.

## Mudanças / preservação
- Alterados: `race_engine.gd`, `core/race_ai_director.gd`, `championship_2012.gd`, `scripts/main.gd` (etiqueta de versão), `project.godot` (etiqueta).
- Criados: `core/race_stint_optimizer.gd`, `core/race_tyre_regulations_2012.gd`, smoke tests e testes estáticos da estratégia.
- Arquivos HUD, câmera, geometria 3D, física de desgaste, meteorologia e animação de pit preservados sem alteração de bytes em relação à v0.6.2.4.

## Resultados locais
- Seis testes específicos aprovados, inclusive verificação matemática dos stints em China/Melbourne/Bahrein/Malásia.
- Checagem de indentação aprovada.
- Testes de integridade dos arquivos compactados: consultar verificação final ao empacotar.
- A suíte estática legada não é uma validação apropriada da v0.6.2.5, pois exige versões antigas, conteúdo agora separado do `main.gd` e preservação de hashes de arquivos deliberadamente alterados nesta correção. Não substituir nem apagar as falhas históricas.
- Godot não instalado no ambiente de execução: nenhum teste gráfico / nativo realizado. Os testes nativos foram **fornecidos** ao jogador, não declarados aprovados.

## Resultado esperado após o usuário rodar o Godot
- China com pista **Seco**, IA deverá escolher entre Macio/Médio e usar ambos, com número de boxes mais próximo da estratégia otimizada (a curva de custos de referência sugeriu 2 paradas em caso simples).
- Melbourne com pista seca também tende a estratégia de ~2 paradas no modelo; o resultado depende da física e de eventos efetivos.
- Quando chove, o planejador atual de chuva continua ativo, com trocas conforme condições.
- Jogadores em controle Manual continuam podendo ordenar boxes e selecionar pneus; ausência de ambos os slicks em corrida totalmente seca gera desclassificação no resultado.
