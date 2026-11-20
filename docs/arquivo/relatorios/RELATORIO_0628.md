# APEX 0.6.2.8 — Relatório de validação

## Base e escopo

- Base: projeto v0.6.2.7 testado pelo usuário (Diretor TV aprovado).
- Escopo: estética e objetos visuais de circuitos 3D, pequenos detalhes estáticos no modelo do carro.
- 20 traçados de 2012 permanecem inalterados, inclusive suas coordenadas e regras.
- Não foram editados: IA de pneus, estratégia, motor de corrida, clima, HUD, câmera Livre, Seguir e Diretor TV.

## Testes executados neste ambiente

- **8/8** testes específicos de cenário (`tests/test_0628_scenery_static.py`): aprovados.
- Verificação de indentação e mapa estratégico (`tests/test_0612_indent_static.py`): aprovada em **101 scripts GDScript**.
- Verificação geométrica de 20 circuitos (`tests/test_road_mesh_geometry.py`): aprovada, sem triângulos invertidos de runoff.
- Hash SHA-256 das partes do jogo mantidas: verificado pelo teste específico.
- Funções `update_motion`, `set_tire_compound`, `set_pit_wheel_swap`: hash igual à versão v0.6.2.7.

### Testes legados

Testes antigos que buscam chamadas diretamente dentro de `main.gd`, onde já foram extraídas em v0.6.2.3/v0.6.2.4, falham por estrutura anterior. Testes com hash de versões precedentes ou que esperam um rótulo exato de versão também falham; não foram classificados como aprovados. Os testes nativos Godot e a renderização **não foram executados**, pois não há executável Godot neste ambiente.

## Riscos / pontos de observação

- Modelos de baixa contagem de polígonos e placas genéricas APEX; não são reconstruções reais, nem possuem logos licenciados.
- Paletas são estilizadas por biome; não simulação exata das superfícies ou edifícios históricos.
- Checar visualmente se placas e prédios estão fora da pista em 20 circuitos e se a taxa de quadros não caiu.
- Em caso de erro vermelho no Godot, enviar a primeira mensagem e a linha do script.

## Reprodução

`bash linux/validar_0628.sh` no diretório do projeto. Com Godot disponível, testa cenário, Diretor TV, câmera Livre e estratégia seca (smokes nativos). Iniciar corrida no editor: F5.
