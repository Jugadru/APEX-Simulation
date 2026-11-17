# APEX Motorsport Manager — Relatório técnico v0.6.6.7.2.1

**Origem:** ZIP integral da v0.6.6.7.2. **Natureza:** hotfix de velocidade e apresentação visual, sem alterações nas decisões esportivas.

## Diagnóstico comprovado no código

- A velocidade `sim_speed` estava inicializada em `5.0`; o seletor antigo também começava no índice 2 (`5x`). Nova corrida podia herdar a velocidade anterior.
- O replay executa passos determinísticos de `STEP = 0.20` segundo de simulação. O filtro anterior aproximava o carro do último tick usando amortecimento exponencial (`SMOOTH_SECONDS = 0.04`), com deslocamento visual não uniforme em taxa constante de quadros.
- O modo visual Auto trocava entre 3D e mapa 2D baseado na velocidade: `1x/2x` versus `5x+`.
- O transportador compacto mostrava somente um número entre setas; o 1x existia no código, mas não era selecionável numa lista visível.

## Alterações incluídas

1. **1x inicial e por GP:** valor principal e cada nova corrida começam em `1x`; o utilizador pode selecionar 2x, 5x, 10x, 16x e 32x.
2. **Seleção explícita no HUD:** o indicador passa a ser um menu compacto de seis velocidades, sincronizado com os controles preexistentes.
3. **Câmera independente:** aumentar/diminuir velocidade não alterna o modo de apresentação; Auto preserva 3D e a seleção de mapa 2D continua disponível manualmente.
4. **Interpolação por ticks reais:** `RaceViewSnapshot.build` aceita `tick_phase` opcional; entre duas atualizações esportivas completas, a pose visual é calculada entre as duas posições reais. Não estima ultrapassagens nem modifica o estado de corrida, RNG, comandos ou formato do replay.
5. **Proteções visuais:** pausa conserva a pose; regressão/seek volta imediatamente à nova posição quando os dados são descontínuos. O uso legado de `build` sem fase permanece compatível.

**Trade-off:** a imagem apresenta um atraso visual de até um tick completo (aprox. 0,20s em 1x ou 0,04s em 5x, assumindo que o motor consegue manter o ritmo). Se o processador não sustentar o processamento em 5x, o FPS real ainda pode cair.

## Ensaios controlados (120 quadros a 60 Hz, progresso artificial linear)

| Multiplicador | Variabilidade relativa da velocidade visual — antes | Depois | Ticks esportivos sintéticos |
|---|---:|---:|---:|
| 1x | 1.251 | 0.0000000 | 9 |
| 5x | 0.279 | 0.0000000 | 49 |

A variabilidade é o coeficiente de variação do deslocamento entre quadros em uma sequência sintética de velocidade constante, **não é FPS medido na placa de vídeo**. A primeira fase do ensaio é excluída do cálculo.

## Teste com tela real e relógio determinístico

A cena de corrida rodou `_process(1/60)` durante 120 quadros em 1x e novamente em 5x: **10 e 50 ticks respectivamente**, sem mudança da câmera 3D. O menu foi verificado nas duas velocidades. Capturas feitas pelo Godot 4.7.2 sob Xvfb/Mesa (1600x900 e 1920x1080).

## Integridade esportiva e regressões

| GP | Clima | Ticks | Hash final histórico |
|---|---|---:|---|
| GBR | Seco | 1668 | `7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837` |
| BEL | Chuva intensa | 2067 | `33c7c2d71e34779fb7e74f359f2663e0bea34074aaf4c655dc678f3b97fd8c0e` |
| ITA | Seco | 1553 | `5d4c508a64dce8d1c481a3661f56c6bdf97a2a7a7bab37a5e290be5e54188592` |
| SIN | Chuva intensa | 2050 | `48085a06fed3d7761a58206673c03685043645d813ea809e0b76c968e94439c9` |

As quatro corridas curtas foram **reproduzidas integralmente pelo replay**. Replay legado, Pit Wall, Diretor TV, integração de apresentação e importação Godot passaram.

**Matriz:** 12 verificações aprovadas, zero reprovadas; não foram repetidos nesta correção Monza 53 voltas com replay integral nem uma carreira completa de 20 temporadas.

## Limites que permanecem

- Não há medição de FPS em hardware do usuário, nem comprovação de que 5x sustentará a taxa desejada em sua GPU/CPU.
- O erro Linux/X11 `BadWindow` da execução dentro do editor não está resolvido por este hotfix; não apareceu na captura sob Xvfb.
- Duelo longo, preferências geométricas de curva, motor de ultrapassagens e revisão geral de HUD permanecem fora do escopo.
- Se a simulação acumular atraso sob carga extrema, poderá haver saltos: a interpolação não cria quadros reais extras, nem acelera o cálculo físico.

## Integridade do pacote

A comparação por CRC confirma **2591 arquivos existentes preservados**, **8 arquivos existentes modificados intencionalmente** e nenhum ausente; a física, o motor de corrida e o replay são byte-a-byte iguais à versão anterior.

Os scripts de teste foram preservados no projeto e os logs em `qa/speed_visual_066721/`.
