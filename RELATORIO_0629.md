# Relatório técnico da v0.6.2.9

**Ambiente de testes:** Godot 4.7.2.stable.official.ed1daf0bf, Linux x86_64, Godot recebido do usuário. Renderização gráfica com Xvfb / Mesa llvmpipe (OpenGL por software).

## Testes nativos

- Importação no editor via `--headless --editor --quit`: exit 0, sem erro de parse.
- Teste dos 4 biomas `core_0629_environment_smoke_test.gd`: exit 0.
- Teste **20/20 circuitos com geometrias reais do calendário 2012** `core_0629_calendar_smoke_test.gd`: exit 0.
- Regressões: `core_0628_1_visual_smoke_test.gd`, `core_0628_scenery_smoke_test.gd`, `core_0627_tv_director_smoke_test.gd`, `core_0626_1_freecam_smoke_test.gd` e `core_0625_dry_strategy_smoke_test.gd`: todos exit 0.
- Screenshots do Godot a 1600x900 para Bahrain, Sepang e Monaco gerados e analisados.
- Teste de hashes de 11 arquivos importantes preservados: aprovado.

## Limitações

- Testes sintéticos e de carregamento não equivalem a jogar 20 corridas inteiras. A estratégia completa da China não foi repetida; a IA não foi modificada.
- Os assets 3D são primitivas low-poly originais e não reproduzem posições precisas das estruturas dos autódromos de 2012.
- O projeto ainda possui avisos antigos de âncoras e da SubViewportContainer; o ambiente gráfico sem dispositivo de áudio gera aviso ALSA, resolvido com fallback de áudio. Não são erros novos de GDScript.
- A percepção visual deve ser testada nas tomadas reais do Diretor TV, principalmente na GPU do Linux do usuário.
