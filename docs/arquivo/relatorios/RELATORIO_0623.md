# Relatório técnico v0.6.2.3

## Escopo

Base 0.6.2.2 funcional em capturas fornecidas pelo usuário. Refatoração incremental (36 métodos + bloco de acompanhamento de câmera), pequeno aumento de fontes/cartões inferiores; nenhum novo modelo, pista, IA ou física.

## Validação

- Testes específicos novos: **9/9**, incluindo integridade dos scripts, preloads, callbacks, captura do estado `host`, preservação de SHA-256 do motor, posição dos painéis e controle de pausa.
- Suíte antiga `python3 tests/run_all_static.py`: **13/36**. Essa suíte contém expectativas rígidas de versões anteriores (hashes antigos do mapa, nomes e funções apenas no `main.gd`, strings literais da HUD antiga), inclusive falhas que já existiam na 0.6.2.2. As extrações causaram novas incompatibilidades de localização estática (o código agora está nos módulos), por isso NÃO é correto considerar o legado como aprovado.
- Binário Godot 4/4.7.2: **inexistente no ambiente da construção**; testes do parser e de runtime gráfico não foram executados.
- ZIP: precisa ser verificado após empacotamento.

## Limitações

- Aumentos de legibilidade estimados em código, ainda sem confirmação visual.
- Os controladores são funções estáticas que recebem o `main` como `host`. A separação por responsabilidade foi concluída, mas o estado ainda não está encapsulado. O `main.gd` não está totalmente modularizado.
- Sem alteração de algoritmo de câmera. O próximo trabalho visual é calibrar o enquadramento das câmeras com capturas reais.
- Falhas anteriores de estratégia/pits não foram resolvidas nesta versão.

## Teste local no Linux

1. Descompacte em pasta nova e importe `project.godot`.
2. Execute `bash linux/validar_0623.sh` (instale Godot 4.7.2 ou informe `GODOT_BIN`).
3. Abra no Godot e pressione F5.
4. Teste corrida, pausa, troca de velocidade, 2D/3D, cartões, menu Corrida, estratégias e retorno ao menu.
5. Em caso de erro, envie a primeira linha vermelha com arquivo e linha exatos.
