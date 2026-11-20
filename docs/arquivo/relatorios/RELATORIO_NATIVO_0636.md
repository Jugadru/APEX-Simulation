# Relatório de validação — APEX 0.6.3.6

**Ambiente:** Godot oficial `4.7.2.stable` Linux x86_64, sandbox; modo `--headless` e interface via Xvfb/OpenGL 1600×900.

## Aprovados

- Importação nativa e parser GDScript (não surgiram erros de sintaxe).
- Teste v0.6.3.6: perfis independentes e determinísticos, sensação x desgaste medido, divergência com 80% de desgaste, memória da escolha, uma resposta por discussão, limite de repetição e reset por GP.
- Testes de regressão 0.6.3.5, 0.6.3.4, 0.6.3.3, 0.6.3.2, 0.6.3.1, 0.6.3.0, 0.6.2.5 (estratégia seca) e 0.6.2.7 (Diretor TV): **retorno 0**.
- Execução gráfica com cena da corrida e janela de RÁDIO, contendo novos controles, parâmetros Soul e mensagens privadas. Captura: `Apex_0636_SoulDriver_Preview.png` (arquivo à parte).
- Conferência SHA-256: código original de `race_engine.gd`, geometria/câmeras, cenas, IA, regras e dados de circuitos preservado.
- O botão de alinhamento não altera o instantâneo da corrida, inclusive pit agendado para V21.

## Limites e avisos

- Os avisos de âncoras de Control e de SubViewportContainer seguem da base anterior.
- O backend ALSA não estava presente no Xvfb e o áudio usou modo dummy; a captura gráfica foi gerada mesmo assim.
- **Não foi executada uma corrida completa até a bandeirada** nesta entrega e não houve teste no computador Linux Mint do jogador.
- 2012 usa pilotos reais nos nomes, mas personalidade e conversas internas são totalmente ficcionais.
