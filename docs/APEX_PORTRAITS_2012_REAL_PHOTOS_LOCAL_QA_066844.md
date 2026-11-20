# APEX Portrait Pack 2012 — QA com 48 fotografias reais (v0.6.6.8.44 Beta)

## O que foi montado localmente
- Branch de referência: `feature/apex-orange-portraits-hud-066815`, PR #26 (rascunho).
- Checkout experimental completo obtido de um artefato temporário do GitHub Actions.
- Instalado o ZIP privado `APEX_PORTRAIT_PACK_2012_v0.6.6.8.42_CORRIGIDO_24_PILOTOS_48_IMAGENS.zip`.
- **48 fotografias reais**: 24 HUD PNG 384×400 e 24 perfis PNG 640×800. Todos os SHA-256, tamanhos e identidades batem com o manifesto original.
- Fundo de menu oficial A (grafite/laranja suave) carregado. B preservado como alternativa.
- **Novo botão VER PERFIL** no painel Rádio abre o PNG 640×800 do piloto selecionado. Alteração exclusiva de apresentação.
- A beta tem pasta de saves isolada `APEX_066844_PORTRAITS_BETA`, sem compartilhar dados com a versão estável.

## Testes executados contra as fotografias verdadeiras
| Item | Resultado |
|---|---|
| Importação de projeto completo no Godot 4.7.2 | PASS na repetição sem `--single-threaded-scene` |
| Arquivos PNG SHA-256 e resolução correta | PASS 48/48 |
| Smoke estrito dos 24 IDs | PASS 48/48 |
| HUD real, menu de rádio, ranking, 1600×900 e 1920×1080 | PASS (20 checks) |
| Perfil 640×800 na cena real e invariância de corrida | PASS (21 checks) |
| Identidade e atribuição correta da fotografia do usuário | PASS (46 checks) |
| Modos da HUD real | PASS (34 checks) |
| Rádio e ordem pit manual na volta 21 | PASS |
| Replay determinístico | PASS (1622 verificações) |
| Silverstone, clima variável, 52 voltas e 24 pilotos | PASS; 78 pit stops; 0 erros; vencedor Hamilton; 26.749 ticks |
| Fundo do menu oficial A em 1600×900 | PASS |
| FPS na GPU do usuário | NOT_RUN |
| Aceitação artística final de cada máscara | REVIEW |
| Direitos de distribuição pública dos retratos | NOT_VERIFIED |

Observação: uma primeira importação com a opção `--single-threaded-scene` encerrou com falha de segmentação. A repetição sem essa opção concluiu normalmente, e os testes subsequentes passaram. O renderizador de captura foi **Mesa llvmpipe (software)**, não a GPU do usuário. O driver de áudio usou fallback dummy por ausência de dispositivo no ambiente de teste.

## Artefatos gerados localmente
- `APEX_MOTORSPORT_MANAGER_v0.6.6.8.44_PORTRAITS_REAIS_BETA.zip`: **cópia jogável experimental**, contendo projeto completo, assets reais, visualizador, capturas e QA. SHA-256: `e1ef76fbd0a4ef01c674c8d2eab2ce05f2c6120c9c7976fc42b87787fa093714`.
- Capturas: `qa/portraits_ci/real_hud_1600x900.png`, `...1920x1080.png`, `qa/portraits_final/real_radio_*.png`, `real_profile_*.png`, `real_menu_A_1600x900.png`.
- Comparativo visual: `qa/portraits_final/PREVIA_24_HUD_066844.jpg` e `PREVIA_24_PROFILE_066844.jpg`.

**Importante:** o ZIP com fotografias não está anexado ao GitHub. Permanece disponibilizado apenas ao usuário na conversa, para evitar redistribuição pública sem licenças verificadas. O PR #26 recebe somente código e testes. Não mesclar ou distribuir imagens comercialmente antes da verificação de direitos.

## Teste na branch sem fotos
O workflow `.github/workflows/apex-portraits-real-qa.yml` continua utilizando 48 imagens temporárias (fixtures) para permitir CI sem publicar as fotos. Acrescentado o teste `tests/apex_portraits_2012_profile_viewer_066844.gd` para o novo botão.

## Próximo limite
A validação visual das 24 pessoas, sobretudo cabelo, braços, espaços entre braços e tronco, bifurcação e pés, deve ser revisada pelo usuário antes da aprovação artística. FPS em GPU Linux Mint/NVIDIA real requer execução no próprio computador de destino.
