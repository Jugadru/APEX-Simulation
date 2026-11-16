# Relatório técnico — APEX v0.6.2.7

**Escopo:** somente direção de câmera e composição das tomadas 3D. **Base:** v0.6.2.6.1.

## Testes executados neste ambiente

- `python3 tests/test_0627_broadcast_static.py`: **7/7 aprovados**.
- `python3 tests/test_0612_indent_static.py`: **99 scripts GDScript** aprovados na checagem estática de indentação.
- Geometria: para câmera 16:9, verificação aproximada das duas posições em situações de separação de 4, 10, 22, 38, 60 e 80 unidades, também com deslocamento lateral, nas tomadas Battle/Corner/Trackside.
- Hash SHA-256: **244 arquivos herdados** confrontados com a base de referência; motor de corrida, IA, pneus, clima, calendário, HUD, mapa e cena principal permanecem idênticos. As **5 funções de entrada/navegação da câmera Livre** têm os mesmos hashes da v0.6.2.6.1.
- Os scripts e dados para `tests/core_0627_tv_director_smoke_test.gd` estão no pacote.

## Limitações

- **Godot não está instalado neste ambiente**, logo não foi possível compilar GDScript, rodar o teste nativo, validar a cena, FPS, movimentos ou aparência gráfica.
- A suíte histórica do Apex contém testes que exigem versões anteriores/hashes antigos ou arquivos fora da pasta; eles não foram considerados evidência de aprovação desta mudança. O novo teste é portátil e usa hashes de referência internos, sem depender de outra versão instalada.
- Os testes matemáticos modelam projeção de dois pontos. Não simulam obstáculos, terreno, curvas arbitrárias, oclusão ou a qualidade estética final.

## Verificação obrigatória no computador do jogador

1. Godot 4.7.2 abre a cena e inicia a prova sem erros de parser.
2. Em 1× e 5×, o Diretor TV mantém tomadas durante tempo suficiente, evitando trocas excessivas.
3. A disputa aparece no quadro quando os dois carros estão próximos, sem se limitar a tomadas aéreas.
4. Mudanças de setor usam cortes; dentro do mesmo trecho, a câmera acompanha os pilotos sem solavancos.
5. Câmera Livre arrasta, desloca e amplia normalmente; Seguir mantém o enquadramento aprovado.
6. HUD e estratégia 2012 continuam iguais à versão anterior.
