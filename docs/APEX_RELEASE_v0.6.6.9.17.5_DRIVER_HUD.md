# APEX v0.6.6.9.17.5 — Driver HUD Restoration

CANDIDATA. Base integrada 9.17.4 (fd6a22d, release permanente disponível).

## Escopo autorizado
Não substituir HUD atual por versão anterior. Preservar cartões de canto, cabeçalhos, três colunas de telemetria, classificação, mapa/clima, botões e callbacks, painel expansível, modos Broadcast/Compact/Full, menus e motor esportivo 026. Modificação estritamente localizada: rail de cor de equipe de 4 px passa a um badge neutro de 34×25 com capacete vetorial original, cor real da equipe e marca do slot. Nome e código já existentes permanecem. Não é retrato real nem cópia de pintura de capacete. Sem assets externos, download ou textura nova; sem alteração na política de retratos desativados. O repositório atual não contém retratos antigos, por isso não alegar recuperação desses arquivos. Restaurar fotos/arte individualizada requer material original/licenciado ou autorização específica.

## Homologação
FAST + APEX Test Lab; teste de dois cartões, identidade por ID/equipe/slot, ausência de interceptação de comandos, quatro contextos, modos de HUD, três tamanhos de janela, integridade do hash esportivo, ordem BOX V21, troca de equipe e sessão. Capturas nativas em runner OpenGL software separadas; não comprovam FPS em hardware real. Preservar 9.17.4 e revisão 026, sem alterar scripts de corrida ou de menus. Estado inicial NOT_RUN; merge somente após CI no SHA exato e revisão do responsável.
