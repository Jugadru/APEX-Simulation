# Pesquisa técnica — 0.6.5.9
Fontes primárias consultadas em 13/11/2026. Implementação original sobre os algoritmos existentes do APEX; nenhum pacote, código ou recurso externo incorporado.

- [Godot CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html): medir antes/depois, distinguir tempos inclusivos e custo de acesso aos dados. Aplicação: investigação 0657/0658 separada da comparação 0658/0659, mesma cena, seeds e resolução real; preservar amostras desfavoráveis.
- [Godot PackedFloat32Array](https://docs.godotengine.org/en/stable/classes/class_packedfloat32array.html): busca binária em dados ordenados e semântica de inserção. Decisão conservadora: preservar a busca original com comparação double contra acumulados Float32, sem conversão da consulta para Float32, e preservar a diferença central de direção. Trocar tangente ou precisão não é necessário para otimizar.
- [GitHub Godot geometry_2d.h](https://github.com/godotengine/godot/blob/master/core/math/geometry_2d.h) e [aabb.h](https://github.com/godotengine/godot/blob/master/core/math/aabb.h), repositório MIT: referência de projeção limitada sobre segmento e limites geométricos. Aplicação: broadphase de caixas conservadoras e projeção original na fase exata; dica do frame anterior só fornece limite superior, nunca restringe busca a vizinhos.

## Escolhas
Índice por blocos contíguos de 16 segmentos, construído uma vez por pista. Caixa expandida em 0.001 unidade para evitar exclusão por arredondamento; se sua distância mínima supera o melhor candidato, nenhum segmento desse bloco pode vencer. Todos os blocos ainda são consultados: cruzamentos e saltos não precisam de heurística local nem fallback aproximado. Empates usam o menor índice, como a varredura antiga.

Cache 2D limitado a 256 pontos e 256 direções por revisão; preserva a parametrização e direção anteriores. Revisão invalida também amostras de apresentação durante pausa. O 3D deixa de avaliar argumentos default de Dictionary.get que calculavam rota mesmo quando route_point/route_direction já existiam. Nenhuma redução de qualidade, frequência esportiva ou quantidade de carros.

Não foi criado LOD nem simplificação de câmeras: o custo comprovado era projeção global e repetição de amostras. Interpolação, ocupação, física, estratégia e HUD mantêm suas responsabilidades anteriores.
