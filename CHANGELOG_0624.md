# APEX v0.6.2.4 — Refatoração da interface (sem redesenho)

## Objetivo

Atender ao pedido de **mais uma refatoração antes de trabalhar nas câmeras**, mantendo a HUD compacta que o jogador aprovou na v0.6.2.3.

## Código reorganizado

Vinte e duas funções do `scripts/main.gd` foram transferidas para quatro módulos de responsabilidade definida:

| Arquivo | Responsabilidade |
|---|---|
| `scripts/apex_race_ui_legacy_builder.gd` | Construção das instâncias e referências da UI antiga, hoje ocultada pela HUD nova |
| `scripts/apex_race_ui_layout.gd` | Posicionamento responsivo dos elementos legados e alternância de visibilidade |
| `scripts/apex_race_ui_presenter.gd` | Atualização de dados da sessão, classificação legada, estratégia e resumo de boxes |
| `scripts/apex_race_ui_legacy_cards.gd` | Cartões antigos, seleção de piloto, KERS e controles de box da UI legada |

As funções antigas em `main.gd` foram mantidas como wrappers para compatibilidade com as conexões de sinais existentes. Os novos módulos recebem `host` (a cena) e não alteram a máquina de corrida.

- `main.gd`: **1.782 → 746 linhas** (redução de 1.036 linhas).
- **22 métodos extraídos**.
- As funções e o layout da HUD visível (`apex_race_hud_0622.gd`) permaneceram **byte a byte iguais**.
- O motor de corrida, as pistas, a meteorologia, a IA, o controlador de câmera e a cena principal também permanecem iguais.
- Versão e descrição do projeto atualizadas para `0.6.2.4`.

## Fora deste escopo

- Melhoria dos ângulos de câmera ou do Diretor TV.
- Novo desenho do mapa, carros ou ambiente 3D.
- Mudança do tamanho dos cartões, das fontes ou dos painéis da HUD.
- Correções da lógica de pit stops e previsões de desgaste.
- Refatoração completa para estado encapsulado: os módulos ainda são adaptadores estáticos ligados ao `main`.

## Validação

- `python3 tests/test_0624_refactor_static.py`: **10/10 aprovados**.
- `python3 tests/test_0612_indent_static.py`: **aprovado (92 scripts)**.
- Suíte histórica `tests/run_all_static.py`: **6/37 aprovados**; vários testes exigem strings específicas dentro de `main.gd` e versões anteriores, por isso não são compatíveis com a nova disposição do código. Essas falhas NÃO significam que o projeto foi validado funcionalmente.
- A verificação da sintaxe pelo interpretador Godot, navegação em runtime e renderização visual **não foram executadas aqui**, pois não existe Godot instalado neste ambiente.

## Como validar no Linux Mint

1. Extrair em pasta nova e importar `project.godot` no Godot 4.7.2.
2. Executar `bash linux/validar_0624.sh` no terminal (ou definir `GODOT_BIN` para o caminho do Godot instalado).
3. Pressionar F5 e testar: menu → garagem → corrida → 2D/3D → seguir pilotos → cartões T/D/E/C → estratégia → rádio → voltar ao menu.
4. Se houver erro, registrar a primeira mensagem vermelha com arquivo e número da linha.
