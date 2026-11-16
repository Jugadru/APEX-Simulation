# APEX 0.6.2.6.1 — Relatório técnico de validação

- **Falha reportada:** câmera Livre não se deslocava com o mouse em Godot 4.7.2.
- **Causa verificada no código:** mouse tratado em `_unhandled_input` apesar da HUD em `Control` de tela inteira; gesto antigo exigia arraste do botão esquerdo, sem navegação passiva.
- **Alteração:** input do mouse capturado em `_input`, com bloqueio espacial dos componentes da HUD, drag esquerdo/meio, zoom com roda e pan por teclado/bordas. Atalhos de teclado seguem em `_unhandled_input`.
- **Testes estáticos novos:** 5/5 aprovados.
- **Teste de indentação:** aprovado nos 98 arquivos GDScript.
- **Integridade do motor/IA/HUD:** SHA-256 idênticos à v0.6.2.6 para os 14 componentes protegidos; hashes incluídos em `tests/0626_1_preserved_sha256.json`.
- **Teste nativo/headless e teste visual:** NÃO executados neste ambiente (Godot ausente). Executar `bash linux/validar_0626_1.sh` na máquina com Godot e testar com F5.
- **Limitação funcional:** modo Livre move posição da câmera e zoom; ainda não implementa rotação/orbita manual com o mouse.
- **Escopo:** nenhum ajuste no Diretor TV nem nos resultados, na estratégia, no clima ou na HUD.
