# APEX 0.6.2.3 — Refatoração incremental + HUD legível

Base: projeto Godot 0.6.2.2, validado visualmente pelo jogador em capturas anteriores.

## Mudanças

- Extrai 36 funções antes residentes no `scripts/main.gd`, preservando wrappers de callbacks/sinais.
- Move o acompanhamento de câmera por quadro para `apex_race_view_controller.gd`, sem alterar o algoritmo das tomadas 3D.
- Cria oito módulos separados: sessão, câmera, comandos, relatórios de telemetria, relatórios de pit, menu, garagem e feed de rádio.
- Reduz `scripts/main.gd` de **2441 para 1782 linhas**; ele continua sendo o coordenador da cena.
- Mantém os dois cartões nos cantos inferiores e o controle central flutuante; aumenta a altura dos cartões de 150 para 166 unidades de interface, fontes de informações essenciais e botões de seleção.
- Preserva a expansão dos detalhes exclusivamente para cima, classificação compacta e cinco acessos superiores.
- Atualiza versão da aplicação, scripts, teste de regressão estática e validador Linux.

## Não mudou

- Motor e IA da corrida, lógica de pit, pneus, clima, campeonato e geometria das pistas: hashes SHA-256 idênticos aos da 0.6.2.2.
- Algoritmos de enquadramento da câmera e modelos 3D: **sem redesenho visual de câmeras** nesta entrega; apenas isolamento em módulo para evolução posterior.
- Problemas históricos do balanceamento de paradas e chuvas: continuam em aberto, sem declaração de correção.

## Validação

- `python3 tests/test_0623_modularization_static.py`: testes estáticos novos.
- `bash linux/validar_0623.sh`: testa com Godot 4 instalado no computador do jogador.
- Godot não está disponível no ambiente onde o ZIP foi produzido: parser e visual **não executados** aqui.

## Itens posteriores

- Extrair `main.gd`/`_build_game_ui` legado e separar a apresentação da HUD antiga com segurança.
- Melhorar presets/enquadramento e modo Diretor TV, comparando com as novas capturas.
- Priorizar bug de boxes excessivos e comunicação de rádio.
