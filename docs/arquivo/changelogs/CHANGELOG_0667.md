# APEX Motorsport Manager — Changelog v0.6.6.7

**Funcionalidade única:** TV Director Highlights 1.0 — seleção factual e fila limitada de acontecimentos no Diretor TV.

### Modificado

- `scripts/tv_director.gd`: cobertura de eventos confirmados, interrupção de tomada por incidente/ultrapassagem, antirrepetição, expiração, limite de 8 eventos, reset de sessão e replay rewind.
- `project.godot`: título e descrição atualizados para a versão 0.6.6.7.

### Adicionado

- Testes `tv_director_highlights_0667_test.gd`, `tv_director_0667_sporting_isolation.gd`, `tv_director_0667_live_gp.gd`, `racecraft_0667_gp.gd`, `tv_director_visual_0667.gd`.
- Relatórios, logs, matrizes e capturas em `qa/tv_director_0667/`.

### Preservado

- Física F1 2012, RNG, IA, campeonato, radio, Pit Wall, staff, inventário e projetos.
- Replays `APEX_REPLAY_0660`, checkpoints 0665 e Fast Seek 0666.
- HUD unificada, cenas 3D e controles manuais. Nenhum arquivo de áudio ou imagem de terceiros incluído.

### Não concluído

- Integração longa de replay e estresse 20 temporadas; teste histórico de Pit Wall já falha na base 0666; migração staff não validada nesta execução. Ver relatório completo.
