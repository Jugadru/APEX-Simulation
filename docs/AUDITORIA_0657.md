# Auditoria pré-instrumentação
Base extraída do ZIP v0.6.5.6; CRC e todos os 1623 hashes do manifesto verificados. Plano recebido lido e preservado em PLANO_RECEBIDO_0657.md.

## Dependências e frequências
- `scenes/main.tscn` hospeda `main.gd`, controladores de sessão, comandos, presenters e vistas. `project.godot` usa Forward+ e viewport lógico 1920×1080. Dados de equipes/circuitos em `data/season_2012.json`; meshes e materiais procedurais, shaders em assets/scripts. Godot 4.7.2, sem dependência externa nova.
- `main._process`: por frame chama autonomia antes/depois dos batches, motor, observação LF1, tracking/câmera, cópias profundas draw_cars, projeções 2D, mapas e apresentação 3D. HUD principal a cada 0,25s. Mapas recebem dados por frame ou conforme next_ui.
- `race_engine.step`: subdivide até 4s em ticks de no máximo 0,2s. `_advance` produz snapshot profundo old_order, contexto meteorológico/térmico, performance e `RaceSpace.plan`; classifica, atualiza desgaste e pits. Cópias congeladas protegem independência da ordem de atualização. Não removê-las sem equivalência demonstrada.
- `race_space_0655.plan`: proximidade e espaço com buscas entre pares. Custo potencial quadrático; com 24 carros, relevância precisa ser medida.
- `_build_strategy_plan`: forecast, AIDirector e RaceIntelligence, chamado por estratégia/engenheiro; `_request_ai_pit` contém retornos antecipados e decisões condicionais. `_advance_pit` delega para máquina de estados PitLane. Instrumentar entrada/retorno sem modificar condições, ordem nem RNG.
- Soul Driver/radio em módulos core existentes, eventos recebidos pelos presenters. O tamanho de `apex_race_hud_0622.gd` não prova gargalo. Staff/Soul Staff, Garage e oficina têm transações próprias, não entram em resultados de corrida pelo profiler.
- `track_map.point_on_track`: busca binária em distâncias acumuladas; direção faz duas projeções. Uma solicitação de posição+direção envolve três buscas. `track_3d` já tem amostragem e caches próprios e usa MultiMesh na vegetação/props. Não implementar um segundo cache nesta versão.
- `track_3d.set_race_cars`: atualiza nós/poses/ocupação e animações; criação de geometria em setup é custo distinto. Mediremos custo CPU da entrega de estados, sem chamá-lo de tempo GPU.
- HUD, mapa, minimapas e 3D são consumidores dos mesmos estados; instrumentação compartilhada precisa nomes de seção claros e tempos inclusivos, sem somar pai e filhos.

## Riscos identificados, ainda hipóteses
Cópias profundas de históricos crescentes podem aumentar CPU/memória temporária; atualização de vistas ocultas pode ser redundante; consultas repetidas podem merecer amostragem conjunta. Não foram comprovados vazamentos por inspeção. `queue_free` e caches existentes não serão alterados. Medir contagem de objetos/órfãos e memória em execução não prova sozinho ausência de vazamentos.

## Mudanças autorizadas nesta etapa
Profiler diagnóstico estático com agregados limitados, OFF por padrão; painel de abertura explícita, exportação JSON; benchmarks repetíveis. Instrumentar pontos da chamada, preservando funções matemáticas. Não mudar frequência, cache, pooling, LOD, performance de pilotos ou resultados. Não persistir configuração do profiler em saves. Planejar versões seguintes separadamente.
