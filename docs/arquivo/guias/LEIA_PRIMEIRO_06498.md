# APEX Motorsport Manager v0.6.4.9.8 — Gráficos Dinâmicos de Desgaste e Estratégia

**Base:** projeto integral v0.6.4.9.7 — Coordenação Automática. **Godot:** 4.7.2 stable Linux.

## Como abrir

1. Extraia **todo** o pacote ZIP para uma nova pasta.
2. Abra `project.godot` no Godot **4.7.2**, espere a importação e execute com F5.
3. Escolha Silverstone (ou outro circuito), configure os controles da equipe e inicie o GP.
4. Na HUD híbrida, abra **ESTRAT.** → **GRÁFICOS DINÂMICOS 9.8**. O acesso também está nos painéis **PIT WALL 3.0** e **ENG. / Race Engineer 3.0**.
5. Observe a evolução da curva verde-água (desgaste real) a cada volta concluída e a previsão tracejada amarela. As faixas INI/ATUAL comparam o plano original e a execução da corrida.

A abertura dos gráficos **não agenda** nem chama pit stop. O acesso por Pit Wall/Engineer mantém os botões e decisões de origem. Há duas leituras lado a lado, uma para cada piloto.

## Leitura dos dados

- **Verde-água, pontos unidos:** histórico **observado** da simulação, por volta concluída e por stint. Sem preenchimento inventado de voltas que a interface não observou.
- **Amarelo tracejado:** previsão de desgaste a partir das últimas voltas consecutivas do stint; antes de haver histórico suficiente, usa `wear_per_lap` da IA consultiva existente. Não prevê chuva futura nem degradação após o próximo pit.
- **Linha tracejada da cor do composto:** estimativa inicial do planejador v0.6.4.9.5, congelada ao iniciar o GP; não são medições.
- **Laranja vertical:** janela consultiva indicada pelo motor (`window_start` / `window_end`). Frequentemente é uma volta exata, e não uma faixa imaginária.
- **Rosa vertical:** parada **realmente agendada** (`pit_scheduled_lap`). Paradas executadas são lidas exclusivamente do `pit_history`.
- **INI:** segmentos estimados no planejamento pré-corrida. **ATUAL:** stints realizados, com marcação de parada confirmada ou da janela consultiva.
- **GARAGEM:** conflito confirmado apenas quando há agendamento dos dois carros na mesma volta; coincidência consultiva é identificada como potencial.

A projeção é uma referência tática, não um relógio de ordem nem garantia de resultado. O desgaste instantâneo no cartão avança dentro da volta; os pontos históricos são colhidos na primeira atualização de HUD depois de uma volta concluída. Uma etapa perdida pelo monitor de tela não será interpolada artificialmente.

## Escopo deliberadamente preservado

Não houve alterações em `scripts/race_engine.gd`, `scripts/core/race_ai_director.gd`, `scripts/core/race_performance.gd`, nos módulos de coordenação 9.7 nem em quaisquer outros arquivos da simulação. Gráficos, representação de estratégia e relatório de garagem são somente leitura. O botão superior da HUD continua com **6 atalhos**.

Saves isolados sob `APEX_06498_DYNAMIC_STRATEGY_GRAPHS`; nenhuma migração automática ou sobrescrita de saves anteriores.

## Evidências e testes

Consulte `RELATORIO_TECNICO_06498.md`, `qa/06498/` e capturas PNG nativas em `docs/APEX_06498_*.png`. Os PNGs foram obtidos diretamente do framebuffer do Godot 4.7.2 por Xvfb/Mesa (software), não são mockups.

**Próxima versão:** não iniciada. v0.6.4.9.9 requer autorização expressa.
