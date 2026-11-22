# APEX Motorsport Manager v0.6.6.9.8 — Wet Strategy Intelligence

**Base:** main commit 46b7b661d6c0fd4c11bd5702c1c12aaae3e32f61, incluindo v0.6.6.9.7.1.
**Status:** CANDIDATA em PR; não marcar como estável antes dos testes.
**Escopo único:** previsões meteorológicas imperfeitas para escolhas automáticas de pneus.

## O que muda

- Novo módulo puro: scripts/core/race_wet_strategy_intelligence_06698.gd. Usa somente chuva, lâmina de água, umidade, vento, temperatura e drenagem observados. Não lê eventos futuros, não chama weather.forecast() nem consome RNG.
- Integra-se à função original _build_strategy_plan() do Core 2, alcançando a mesma IA do Pit Wall e dos rivais. O modo Manual recebe sugestões sem executar automaticamente.
- Nowcast com faixa de incerteza **heurística**, sem fingir probabilidade calibrada. A habilidade do estrategista afeta a margem reportada, não o conhecimento de eventos futuros.
- Trocas automáticas não críticas que dependem de atravessar o limiar entre pneus podem aguardar quando a faixa cruza esse limiar. Desgaste crítico e slicks em pista perigosamente molhada não são bloqueados.
- Nenhuma alteração da física da chuva, progressão do carro, HDR, HUD 2D/3D, regulamento 2012 ou cálculo da fila de pit.
- Ordens manuais V21 e chamadas imediatas continuam sob controle do jogador. Double stack, FIFO e prevenção de filas da versão 9.7.1 permanecem preservados.

## Replays e saves

A mudança pode alterar os tempos das paradas e, portanto, hashes esportivos. O replay novo utiliza a revisão 020_wet_strategy_intelligence_v1. Arquivos da revisão 019_last_legal_pit_queue_v1 e anteriores preservam o algoritmo antigo de previsão por sinalizador apenas de sessão: wet_strategy_intelligence_enabled=false. O sinalizador foi excluído do codec, com SCHEMA=1 e sem novos campos persistidos.

**Limitação:** uma tempestade que ainda não começou não será prevista com precisão. A faixa é uma medida de incerteza heurística, não intervalo estatístico. A nova estratégia exige testes de balanceamento completos em corridas molhadas, variáveis e secas.

## Matriz de aprovação

| Verificação | Status antes do CI |
|---|---|
| Forecast puro, determinístico, sem acesso à chuva futura | NOT_RUN |
| Efeito de intensidade da chuva e drenagem | NOT_RUN |
| Troca incerta versus pit crítico | NOT_RUN |
| Proteção da ordem manual V21 em chuva forte | NOT_RUN |
| Revisões de replay 019 e 020 | NOT_RUN |
| Weather 0641, Pit Coordination 9.7, Pit Queue 9.7.1 e Prediction Ledger 9.6 | NOT_RUN |
| Monza 53 voltas / 20 circuitos / SaveGuard / Quality Gate | NOT_RUN |
| FPS real no PC do jogador | NOT_RUN |

O workflow apex-wet-strategy-ci.yml executa o teste dirigido e regressões. Marcador de sucesso: WET_STRATEGY_06698_PASS. Não inferir liberação estável apenas de CI headless.

## Execução

    godot --headless --single-threaded-scene --path . --import
    godot --headless --single-threaded-scene --path . --script res://tests/wet_strategy_06698_test.gd

## Rollback

Reverter os commits desta PR sobre o estado anterior. Não substituir nem renomear arquivos de replay 020 como 019.
