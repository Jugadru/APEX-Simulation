# APEX Motorsport Manager — Changelog v0.6.6.7.2.2

**Strategic 2D Performance**

- Cache de pista estática com camada `Node2D` própria; redesenho apenas ao mudar geometria ou estilo.
- Posicionamento dos 24 carros separado da pintura do circuito.
- Modo Auto 3D até 5x e 2D em 10x, 16x e 32x; comandos manuais têm prioridade.
- Novo botão AUTO no menu CORRIDA para devolver a gestão de câmera ao sistema.
- Novo GP inicia em Auto com 1x; seleção manual permanece disponível.
- Testes novos de cache, política de velocidade e capturas reais de mapa 2D.
- Não altera arquivos de física, IA, engenharia esportiva, pit, serialização ou replay.

**Limitação:** FPS melhor não foi demonstrado no benchmark de parede com cadência controlada; velocidades altas continuam limitadas pelo custo da simulação.
