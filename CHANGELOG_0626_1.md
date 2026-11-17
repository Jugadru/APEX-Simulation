# APEX 0.6.2.6.1 — Hotfix da câmera Livre

Base: Apex 0.6.2.6, confirmada visualmente pelo usuário em Godot 4.7.2.

## Problema observado

O movimento do mouse estava em `_unhandled_input`, mas controles da interface ocupam toda a tela e podem consumir o evento antes dessa rotina. Além disso, a implementação anterior só movimentava a câmera enquanto o botão esquerdo estivesse pressionado; mover o cursor sozinho não era um comando de navegação.

## Correção

- Mouse passa por `main.gd::_input` para o módulo de câmera antes do consumo do evento pela GUI; atalhos de teclado permanecem em `_unhandled_input`.
- Arraste com botão esquerdo **ou botão do meio** em área livre do circuito: pan na câmera 3D e no mapa 2D.
- Rolagem do mouse fora dos painéis: zoom e alternância para câmera Livre.
- Na câmera Livre: WASD, setas ou cursor junto às bordas **livres** da tela também deslocam a visão; segurar o botão não é obrigatório para a navegação por teclado/bordas.
- Botões superiores, tabela de classificação, minimapa, cartões dos pilotos e modais não iniciam arraste de câmera.
- Movimento automático é exclusivo do modo Livre; Seguir e Diretor TV permanecem com o comportamento anterior.
- Sem alteração de IA, pneus, pit stop, geometria, ordem de classificação ou visual da HUD.

## Arquivos modificados

- `scripts/main.gd`
- `scripts/apex_race_view_controller.gd`
- `project.godot` (versão)

Arquivos novos: teste estático e smoke headless, script Linux e documentação.

## Testes e limitação

`bash linux/validar_0626_1.sh`

O teste estático verifica o roteamento de eventos, os controles e hashes de componentes que não devem mudar. O smoke nativo valida pan da câmera 3D no Godot instalado. Este ambiente não possui executável do Godot, portanto o comportamento gráfico deve ser validado no computador do jogador.
