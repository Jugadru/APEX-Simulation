# APEX Motorsport Manager v0.6.2.6 — Câmeras

Esta é a pasta completa do projeto Godot. Não substitua scripts isolados da v0.6.2.5: extraia em pasta nova e abra `project.godot`.

**Godot:** o usuário está usando a série 4.7.2. A execução aqui não foi possível por falta de executável.

## Como validar

```bash
bash linux/validar_0626.sh
```

Para repetir a corrida longa da China no Godot, depois dos testes de câmera:

```bash
bash linux/validar_0626.sh --long
```

## Modos

- **AÉREA 3D:** acompanha a ação com elevação estratégica. Considera o rival próximo quando houver.
- **DIRETOR TV:** seleciona disputas, eventos e algumas tomadas da equipe; usa alternância de ângulos.
- **SEGUIR:** prende a câmera ao piloto escolhido.
- **LIVRE:** permite passear pela pista sem recuar automaticamente ao centro ao assumir controle.
- **MAPA 2D:** preservado, com pontos coloridos.

Em `CORRIDA`, os modos de visual e câmera são controles distintos. Use o visual para escolher 2D / Aérea / TV e a câmera para escolher Livre / Seguir / Diretor.

Histórico detalhado: `CHANGELOG_0626.md`.
