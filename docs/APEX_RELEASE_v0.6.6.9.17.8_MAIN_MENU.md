# v0.6.6.9.17.8 — Main Menu Rework (candidata)

Base integrada: `f2dd809d080932405a3fa19c4f66a2a294f51676` (PR #122, Race Traffic Hotfix REV4). Uma funcionalidade principal. Identidade do Plano Mestre Unificado 2.0: laranja APEX, grafite, interface clara e contextual.

## Changelog
- Central de comando reorganizada em sessão, modos de jogo e gestão; tipografia ampliada, contraste dos botões e hierarquia laranja/grafite.
- Estado real do campeonato (equipe, etapas, próxima etapa, conclusão), disponibilidade do GP em memória e indicação distinta de ausência de sessão.
- Standard, Sandbox e três treinos mantêm os callbacks originais. Simulation permanece explicitamente planejado; demonstração de delegação existente preservada.
- O menu usa layout modular separado de FrontDoor; grade e operações responsivas, rolagem e estados desabilitados. Corrige rótulo de temporada concluída que poderia persistir sem save.
- Nenhuma mudança de regras esportivas, save, replay, geometria, HUD, retratos, gerenciamento ou controlador de navegação. Sem imagens novas ou ativos externos.

## QA
Teste `main_menu_09178_test.gd`: três resoluções, todos os botões visíveis sem rolagem em 16:9, sinal único, estados vazio/salvo/concluído, callbacks de cenário e delegação, retorno de gestão, retomada da mesma corrida e hash esportivo preservado. Capturas em modo Compatibility. FAST + Test Lab e regressões direcionadas; resultados vinculados ao SHA no PR. GPU física, ultrawide e controles por gamepad não homologados. Tela de preparação do GP permanece a existente; não confundir menu com novas funcionalidades de carreira.

Rollback: base acima; preservar diretório de saves. PR Draft, sem merge ou publicação antes da homologação.
