# Apex Motorsport Manager v0.6.3.8 — Correções da simulação

**Origem:** projeto Godot 4.7.2 da v0.6.3.7, sem reiniciar a implementação nem substituir o motor existente.

## Correções

- **Chegada e classificação:** tempo real de cruzamento armazenado por carro; diferenças calculadas a partir dos registros de chegada; retardatários aparecem por voltas atrasadas; carros classificados sem passagem não recebem tempo de cruzamento fictício.
- **Melhor volta:** passagens inferiores a 70% do tempo-base do circuito deixam de entrar no recorde. Ocorrências são anotadas no log como `timing_invalid` para investigação do cálculo original; o dado é rejeitado, não reescrito artificialmente.
- **Ultrapassagem vs mudança de posição:** eventos de disputa em pista (`pass`) separados de posições ganhas por boxes/ritmo (`position_gain`). O rádio não comemora automaticamente cada troca de posição como ultrapassagem.
- **Pit stops / IA:** janela de avaliação com prevenção de decisões consecutivas logo após troca de pneus e verificação de condições de chuva; desgaste normal recalibrado; intermediários e pneus de chuva rebalanceados; ordens manuais agendadas têm precedência e só são executadas na entrada prevista.
- **Modo Manual:** alertas de pneus aos 75%, 90% e 98% de desgaste, mantendo a decisão de parar nas mãos do jogador; indicação mais clara de composto atual na área de estratégia.
- **Tabela:** seis páginas alternáveis: INTERVALO, LÍDER, PITS, MELHOR VOLTA, PNEUS e ATRÁS; intervalos finais para retardatários em voltas, não em segundos falsos.
- **Temporada:** progressão simples do desenvolvimento dos carros rivais conforme as etapas do calendário. É um balanceamento inicial, não um sistema completo de projetos de engenharia da IA.
- **HUD:** removeu ajustes de tamanho conflitantes com âncoras, evitando avisos gráficos reportados; painel lateral de estratégia respeita as diferenças de chegada.
- **Rádio e Soul Driver:** história e personalidade da v0.6.3.7 preservadas, com filtro para mensagens repetitivas de disputa.

## O que ficou intocado

Pistas e cenários 2D/3D, Godot 4.7.2, KERS/DRS 2012, controle da oficina, orçamento, pilotos, calendário com 20 GPs e arquivos de carreira continuam nas suas estruturas originais.

## Limitações honestas

- Os números dos pneus são **coeficientes de equilíbrio do jogo** e não uma reprodução de telemetria histórica.
- As voltas inválidas são filtradas para não estragar a classificação; a investigação do evento de cruzamento anômalo continua aberta.
- A verificação gráfica foi feita em Linux virtual, não diretamente na máquina do jogador.
- Uma bateria completa de oito GPs com todas as condições climáticas ainda é necessária para aprovar o equilíbrio de uma temporada inteira. A validação inclui um GP integral seco e outro integral com chuva forte, mais testes de regressão.
