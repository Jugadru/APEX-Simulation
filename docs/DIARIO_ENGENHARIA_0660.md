# Diário de engenharia — v0.6.6.0

## 14/11/2026 — Auditoria e contratos
- ZIP 0659 preservado; SHA-256, CRC e 1995 arquivos conferidos antes de extrair nova pasta.
- Confirmada dependência de delta/FPS no main, decisões de Staff fora dos ticks e chamadas diretas da HUD ao motor.
- Pesquisa em documentação e repositório Godot. Sem código/assets proprietários incorporados.
- Contratos separados: codec de estado, sessão/log/scheduler/replay e painel F9. Motor e sistemas existentes reutilizados.

## Implementação e ajustes
- Interceptação central dos seis comandos esportivos do motor. Validação e ordem tick/sequence; modos individuais e anotações explícitas também registrados.
- Checkpoints contêm RNG, clima, pista, carros, boxes e telemetria. Cache de aconselhamento é derivado, excluído e limpo antes de cada tick para não depender das consultas da HUD.
- Teste inicial a 0,05 s mostrou custo alto de motor/hash. Adotado passo fixo de 0,20 s, já usado como máximo pelo Core 2. Acumulador retém backlog, até 16 ticks por frame; aceleração é solicitada, não promessa de throughput em qualquer hardware.
- Avisos periódicos do engenheiro saíram da frequência de UI e passaram para cadência de 1 s da simulação. Questões/aceites manuais entram como comandos. Relatório de HUD continua disponível.
- Replay em sessão isolada; guardas no campeonato e observador de inventário, inclusive saída da aplicação. Retorno à sessão original preserva seu motor e estado.
- Painel F9 oferece exportação/importação, play/pause, seek por tick e retorno. Arquivos tipados sem objetos, checksum, limite de tamanho, schema/runtime e validação de estrutura.

## Visual autorizado nesta versão
- Campus com edifícios de apoio, estacionamento e veículos por MultiMesh; variação de terreno para reduzir o plano verde uniforme.
- Consoles e monitores, 24 engenheiros com headsets, molduras/luzes nos boxes; capacetes arredondados e viseiras da equipe de pit.
- Zebras com cor, relevo de normal e bordas. Apenas apresentação, sem alteração de aderência ou trajetória.
- Faixas planas de acesso ao pit deixam de projetar sombras; conferir captura da junção antes de declarar o artefato corrigido.

## Testes e ocorrências
- Unidade: hashes por tick iguais com velocidades 1/2/5/16/32, FPS variáveis, pausa, backlog; round-trip e replay em arquivo; divergência injetada detectada no tick 18.
- Integração: render 2D/3D e consultas de HUD iguais ao headless; seek e retorno sem efeito em inventário.
- Seis provas de três voltas: GBR/BEL/ITA/SIN/CHN/GER com seco/chuva/automático, replay do início à bandeirada, hashes e telemetria iguais. Restore em approach/dock/service/queue/repair/safety_hold/exit.
- Primeira fixture de GP usou pit_phase numérico como nome de estágio e coletou checkpoints demais; execução interrompida e corrigida para pit_stage. Não era divergência de produção.
- Primeira execução de GP integral não terminou antes da continuação da sessão; sem processo ativo nem resultado final. Reexecução isolada registrada como full_GBR_retry. Não contar tentativa incompleta como aprovada.
- Resultados finais, medições e validação do ZIP constarão nos relatórios/JSONs correspondentes.

## Fechamento — 14/11/2026
- GP integral de 52 voltas aprovado: 26855 ticks, hashes e telemetria equivalentes na reprodução; sete restaurações de fases de pit. Uma tentativa anterior interrompida não foi contada como aprovação.
- Regressão inicial nativa isolada no cache de aconselhamento da HUD. Cache visual preservado; decisões esportivas usam cache fresco por tick. Unitário, integração e GP curto repetidos após a correção, com hash do GP curto idêntico.
- Artefato preto do pit persistia sem sombras. Corrigidos winding e continuidade da malha. Captura final inspecionada confirma remoção do leque preto; consoles, equipe, zebras e campus também inspecionados.
- Matrizes anteriores mantidas em before_cache_fix. Medições finais detalhadas em BENCHMARK_0660.md. GP integral não repetido após a otimização do cache visual.
- Empacotamento e testes da extração limpa possuem registro externo VERIFICACAO_ZIP_0660.json; verificar complete/pass antes de considerar entrega concluída.
