# Instalação e testes — APEX v0.6.6.7

1. Extraia **todo** o arquivo ZIP para uma pasta nova; abra `project.godot` no **Godot 4.7.2**.
2. No menu, escolha um GP e inicie a corrida. Em velocidade **1x ou 2x** com o visual automático, selecione `Diretor TV` no modo de câmera para acompanhar os acontecimentos em 3D. Em velocidades altas, escolha `Câmera 3D` se quiser manter o 3D em vez do mapa automático.
3. O Diretor TV mostrará acontecimentos reconhecidos pelo motor como reais; nas disputas sem um evento decisivo recente, mantém a lógica de câmera e batalha anterior. A seleção manual de piloto continua disponível.
4. Para rodar a suíte nova (Linux): `godot --headless --path . --script res://tests/tv_director_highlights_0667_test.gd`. A saída `TV_DIRECTOR_HIGHLIGHTS_0667_PASS` identifica aprovação.
5. Para verificar o pacote: `sha256sum -c APEX_MOTORSPORT_MANAGER_v0.6.6.7_TV_DIRECTOR_HIGHLIGHTS_COMPLETO.zip.sha256` (com o `.zip` no mesmo diretório).
6. Rollback: manter a v0.6.6.6 em pasta separada. Não misturar arquivos de projetos de versões diferentes nem apagar saves do usuário.

**Limitações:** os testes ocorreram em Godot Linux com renderização software OpenGL Compatibility; o replay de Monza 53 voltas e 20 temporadas de carreira não foram executados na v0.6.6.7. O teste histórico Pit Wall UI apresenta falhas também na v0.6.6.6.
