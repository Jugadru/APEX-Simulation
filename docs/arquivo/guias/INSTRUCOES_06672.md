# APEX v0.6.6.7.2 — Instalação, medição e rollback

1. Faça backup do projeto atual e de seus saves. Mantenha o ZIP v0.6.6.7.1 arquivado.
2. Extraia o ZIP completo v0.6.6.7.2. Abra a pasta que contém `project.godot` no Godot **4.7.2**. Aguarde a importação dos assets antes do primeiro uso.
3. Execute o jogo em **janela independente**, não incorporada ao editor, especialmente para investigar o erro X11 `BadWindow`. Faça corrida 3D em Monza e Spa com o grid cheio e repita na chuva; teste 1x e 2x e o Diretor TV.
4. Use **F8** (Profiler) para registrar os contadores `visual.occupancy_stalled_car_frames` e `visual.occupancy_recovered_car_frames`, além dos tempos de `visual.occupancy` e `visual.world_3d`. Exporte o JSON e compare cenários equivalentes. Relate FPS, p95/p99 do frame no **seu** hardware se possível.
5. Se aparecer o X11 `BadWindow`, informe se a execução era no editor ou separada, X11 ou Wayland, GPU/driver e envie a saída de `--verbose`. A ausência do erro em Xvfb não garante correção na máquina real.
6. Para rollback, feche o Godot, restaure a pasta original v0.6.6.7.1 e os saves feitos antes da atualização. Não misture scripts de versões diferentes.

**Não alterado:** IA de ultrapassagem, regras de defesa, HUD, gráficos e lógica esportiva; são tarefas posteriores. Esta revisão não garante estabilidade universal de FPS em GPU real.
