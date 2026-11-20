# APEX Portrait Pack 2012 — QA e instalação experimental (v0.6.6.8.41)

Status: **NÃO PRONTO PARA MERGE / DISTRIBUIÇÃO**.

- O pacote local v0.6.6.8.40 possui 24 pilotos e 48 arquivos PNG (24 de 384×400; 24 de 640×800).
- Em Godot 4.7.2 isolado, os 48 arquivos foram importados e testados com `tests/apex_portraits_2012_strict_066841_smoke.gd`; **PASS**. O smoke antigo com fallback podia passar sem nenhum retrato.
- O menu oficial mantém a imagem **A: grafite com laranja suave**. Os retratos de piloto mantêm o **fundo geométrico azul**, escolhido durante os lotes.
- A revisão v0.6.6.8.40 danificou áreas dos macacões/pernas em quatro perfis ao tentar remover o cinza: Nico Hülkenberg, Pedro de la Rosa, Narain Karthikeyan e Timo Glock. **Não aprovar estes perfis ainda**. A v0.6.6.8.39 também requer acabamento (piso cinza).
- Os quatro retratos iniciais foram parcialmente obtidos de imagens editadas por IA; não presumir identidade fotográfica pixel a pixel.
- Direitos de redistribuição das fotos NÃO verificados. Não publicar comercialmente.
- O zip de assets e os fundos estão na conversa; **arquivos binários não foram enviados à branch GitHub**. É obrigatório colocá-los em `assets/portraits_2012/hud`, `assets/portraits_2012/profile` e `assets/menu` antes de testar.
- O zip de QA/integração v0.6.6.8.41 inclui 48 texturas, fundos A/B, manifesto SHA-256, instalador com backup e relatório.
- Pendente: jogo completo Godot; FPS 1600×900/1920×1080, perfil/radio/classificação, troca de tela, pit stops, replay/save, verificação de licenças e acabamento visual.
- Não mexer no motor de corrida, estratégia, saves, HUD estrutural ou física enquanto o lote visual estiver em revisão.

## Teste estrito
```bash
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/apex_portraits_2012_strict_066841_smoke.gd
```

O resultado só é aprovado com a frase `APEX_PORTRAIT_PACK_2012_STRICT_PASS: 48 textures / 24 identities`. O teste de carregamento não substitui QA visual.
