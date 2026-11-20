# APEX Portrait Pack 2012 v0.6.6.8.42 — QA incremental

**Status: DRAFT / não fazer merge.** Esta atualização não altera motor de corrida nem físicas, estratégias ou saves.

## Correção visual
- Restaurados os perfis de Nico Hülkenberg, Pedro de la Rosa, Narain Karthikeyan e Timo Glock a partir da **v8.39**, preservando os uniformes que tinham sido indevidamente apagados na v8.40.
- Limpeza conservadora do fundo cinza somente em trechos de piso fora da silhueta e em pequenos vãos sob os braços.
- As outras **44 imagens** do pacote de 48 PNGs permaneceram byte a byte idênticas à QA v8.41. Os quatro perfis corrigidos ainda exigem aceitação visual final.

## Verificações executadas
- PNGs: 24 HUD 384×400 e 24 profile 640×800, nomes compatíveis com `scripts/apex_portrait_local_2012.gd`.
- **Godot 4.7.2 isolado:** importação PASS; `APEX_PORTRAIT_PACK_2012_STRICT_PASS: 48 textures / 24 identities`.
- **Mock de binding:** 24 miniaturas de ranking, rádio e perfil vinculadas em objetos Godot, para configurações 1600×900 e 1920×1080: PASS. **Isso não é validação da HUD real durante corrida**.
- Instalador em projeto de teste: 50 PNGs copiados, backup e rollback validados: PASS.
- ZIP e checksums: PASS. Fundo do menu A laranja suave continua separado do fundo dos retratos azul geométrico.

## Não testado
- Projeto APEX completo não estava disponível como checkout local nesta sessão.
- **NOT_RUN:** corrida real em Silverstone/pista aleatória, replay/save, pits, FPS, telas do jogo e captura da HUD verdadeira.
- Direitos de reprodução/distribuição das fotografias ainda não verificados.

## Instalação experimental
O pacote binário completo `APEX_PORTRAIT_PACK_2012_v0.6.6.8.42_CORRIGIDO_24_PILOTOS_48_IMAGENS.zip` permanece na conversa, **não está commitado neste repositório**.
Em uma cópia do projeto contendo PR #26, extrair o ZIP, rodar `python3 install_portraits_2012.py /copia/projeto`, importar no Godot e executar `tests/apex_portraits_2012_strict_066841_smoke.gd`. O ZIP também contém o smoke de UI isolado para inspeção.

**Não fazer merge até teste real no jogo e aprovação visual dos retratos.**
