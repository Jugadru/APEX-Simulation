# Testes nativos — Apex v0.6.3.7

**Engine:** Godot 4.7.2 oficial Linux x86_64, importação nativa e execução `--headless` para testes; `xvfb-run` com OpenGL3 para captura de interface a 1600×900.

## Aprovados
- Importação e parser GDScript, sem novo erro de sintaxe.
- Smoke 0.6.3.7: incidentes, falha nos boxes, aviso de chuva em slicks, desgaste acima de limiar, mudança de pneus, reação a ultrapassagem, tráfego persistente, perda de ritmo em duas voltas, cooldown por piloto, filtro privativo, reset ao iniciar GP, e instantâneo da corrida imutável.
- Regressão 0.6.3.6 / 0.6.3.5 / 0.6.3.4 / 0.6.3.3 / 0.6.3.2 / 0.6.3.1 / 0.6.3.0 / 0.6.2.5 / 0.6.2.7: **9/9 retornos 0**.
- Execução gráfica da cena, alerta espontâneo clicável disponível na HUD, histórico de rádio e resposta do engenheiro, captura 1600×900.
- A ordem de box agendada para a volta 21 não muda ao consultar o rádio reativo.
- `race_engine.gd` e arquivos de física, clima, estratégia, câmeras, circuitos e dados não alterados.

## Pendências / limites
- Corrida completa até a bandeirada **não revalidada** nesta entrega.
- Não testado diretamente no Linux Mint do jogador.
- Warnings antigos de âncoras e `SubViewportContainer.stretch` continuam presentes; não são novos erros de compilação.
- Rádio e personalidades são ficcionais e não dublados; comunicação não altera desempenho físico dos carros.
