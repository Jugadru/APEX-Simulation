# Relatório de validação — Apex v0.6.4.9.4

**Objetivo exclusivo:** corrigir a calibração textual/qualitativa da confiança do Pit Wall 3.0, mantendo toda a simulação da v0.6.4.9.3.

## Defeito reproduzido

No código de referência, a atribuição terminava em `"MODERADA"` nos dois ramos das situações não críticas. Portanto, o Pit Wall não emitia `"ALTA"`, mesmo em pista seca, previsão estável e sem tráfego.

## Correção aplicada

Foi acrescentada uma função pura `_confidence_assessment` no módulo `race_pitwall_strategy_0649.gd`. Ela usa somente os dados já disponíveis e devolve o nível **BAIXA / MODERADA / ALTA** e a justificativa, exibidos no campo `forecast_note` da interface existente. O indicador é heurístico, sem probabilidades numéricas e sem qualquer comando de pit.

**Critérios de projeto:** precipitação prevista alterando em 3v 18 pontos percentuais ou em 6v 24 pontos → BAIXA; incompatibilidade de pneu/condição crítica e conflito de garagem → BAIXA. Condições parcialmente incertas ou tráfego → MODERADA. ALTA só em ambiente seco e estável, sem conflitos, com dados suficientes.

## Testes

17 testes headless e 4 testes renderizados em Xvfb passaram; os nomes individuais e logs estão no arquivo `qa/06494/RESULTADOS_TESTES_06494.json`. Entre os casos: ALTA em seca estável, MODERADA em tráfego ou chuva parcial, BAIXA em mudança importante de chuva, conflito e desgaste crítico, rebaixamento quando faltam dados, imutabilidade da consulta e preservação de V21.

O teste gráfico exibe o motivo na HUD em 1600×900 e valida o layout em 1920×1080; nenhuma chamada ou agendamento de pit é criado ao abrir o painel.

A importação final no Godot 4.7.2 não gerou erros de script ou parse. Em Xvfb houve fallback ALSA para áudio dummy, comum em ambiente sem dispositivo de som.

## Preservação verificada

O arquivo `scripts/race_engine.gd` permaneceu byte a byte igual à 0.6.4.9.3; nenhum outro script de produção foi modificado. Projeto permanece com HUD híbrida, Race Engineer 3.0, Soul Driver 2.0, Team & Staff e correções das v0.6.4.9.1–0.6.4.9.3.

## Limites

A v0.6.4.9.4 **não reexecutou GP completo de 52 voltas nem oito GPs**: teste de unidade, integração com Silverstone no início do GP e regressões são evidências desta entrega. A redução de 90 para 78 paradas ocorreu na v0.6.4.9.3, não é uma medição nova.

A confiança é uma classificação **qualitativa e determinística de risco no estado atual**, não uma frequência de sucesso calibrada com dados históricos. A previsão de tráfego não contempla paradas futuras, acidentes ou voltas inesperadas de rivais.
