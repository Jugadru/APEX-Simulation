# APEX Motorsport Manager — v0.6.6.7.2.2 — Strategic 2D Performance

**Base:** v0.6.6.7.2.1, Godot 4.7.2 Linux. Escopo: otimizar o desenho do mapa 2D e a escolha automática de visualização; simulação esportiva intacta.

## Implementação

- `scripts/track_map_static_066722.gd` (novo): camada CanvasItem de circuito estático, desenhada apenas quando muda pista ou estilo de mapa. A textura/draw commands passam a ser retidos pelo mecanismo nativo do Godot; não redesenha mais asfalto, zebras, pits e fundo a cada alteração de posição de carro.
- `scripts/track_map.gd`: os carros e os focos ficam na camada dinâmica; `set_race_cars` invalida apenas essa camada. Ao trocar pista ou modo, o cache estático é invalidado corretamente.
- `scripts/apex_race_view_controller.gd`: somente o modo **Auto** alterna por velocidade: **1x, 2x, 5x → 3D**; **10x, 16x, 32x → mapa 2D**. Escolha manual prevalece.
- `scripts/apex_race_session_controller.gd`: cada novo GP começa no preset Auto a 1x, corrigindo o reset anterior que forçava câmera 3D manual.
- `scripts/apex_race_hud_0622.gd`: botão **AUTO** no menu CORRIDA, permitindo voltar à seleção por velocidade depois de um controle manual. Não adiciona controles à tela principal.
- `project.godot`: identidade de versão. `tests/speed_visual_066721.gd`: expectativa antiga de câmera fixa marcada explicitamente como modo manual. Novos testes visuais e de política Auto.

## Métrica reproduzível (desenho 2D)

- Em 180 atualizações de 24 carros, o renderizador antigo refazia a geometria em cada `_draw()` (180 solicitações). A camada estática otimizada foi desenhada **1 vez**, enquanto a dinâmica foi desenhada **181 vezes** (primeiro quadro e 180 mudanças).
- A geometria do teste tinha **737 pontos de rota**. Tempo total de quadro no ambiente de benchmark: **1.242,437 ms (antes)** e **1.241,948 ms (depois)**. **Não houve ganho de FPS demonstrável nesse benchmark limitado pela cadência dos quadros.** Não confundir redução de draw calls de fundo com ganho de FPS medido.
- Um ensaio separado com 10 quadros a 32x produziu 26 ticks e consumiu entre 218 e 249 ms em execuções headless. Esse número **não é FPS de hardware**, apenas prova que a CPU esportiva continua sendo custo relevante a 32x.

## Regressão esportiva

| Circuito | Condição | Ticks | Hash esportivo |
|---|---|---:|---|
| GBR | Seco | 1668 | `7bca12f99088048b747f7ac3626b635133628cb0ae57de15db4fdf072be64837` |
| BEL | Chuva intensa | 2067 | `33c7c2d71e34779fb7e74f359f2663e0bea34074aaf4c655dc678f3b97fd8c0e` |
| ITA | Seco | 1553 | `5d4c508a64dce8d1c481a3661f56c6bdf97a2a7a7bab37a5e290be5e54188592` |
| SIN | Chuva intensa | 2050 | `48085a06fed3d7761a58206673c03685043645d813ea809e0b76c968e94439c9` |

Os quatro GPs curtos terminaram com 24 carros classificados, seus replays foram reproduzidos integralmente e os hashes ficaram idênticos à versão histórica. Também passaram Pit Wall, replay, Diretor TV e a interpolação 1x–5x.

## Limitações abertas

- O mapa 2D agora evita reconstruir o circuito, **mas 10x–32x ainda exigem 50–160 ticks esportivos/s**. O simulador pode continuar reduzindo FPS quando a CPU não acompanha; pular ticks quebraria resultados e replay.
- O erro `BadWindow` do X11/editor não foi corrigido nem reproduzido em janela independente neste ambiente.
- Problemas de duelos longos, preferência geométrica nas curvas e limpeza global da HUD não pertencem a esta versão.
- Sem corrida completa de 53 voltas nem 20 temporadas jogáveis nesta atualização.

## Como conferir no jogo

Inicie um GP: o marcador deve mostrar **1x e 3D**. Mude para 5x, mantendo 3D. Passe para 10x, que alterna automaticamente para mapa 2D; 16x e 32x continuam nele. Abra CORRIDA e escolha AÉREA 3D manualmente: essa escolha deverá permanecer mesmo a 32x. Selecione **AUTO** no mesmo menu para retornar ao mapa em velocidades altas.

Para medir no seu PC, use F8 no profiler e compare 5x/10x/16x/32x em circuitos equivalentes; teste o APEX fora da janela incorporada ao editor caso apareça `BadWindow`.
