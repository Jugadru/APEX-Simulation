# Recortes de fotografias dos 24 pilotos — v0.6.6.8.13 (ferramenta)

**Importante:** este branch contém **a ferramenta pronta, não as 48 imagens nem o ZIP final**. As 48 fotos enviadas nesta conversa não puderam ser abertas pelo ambiente de edição de arquivos da sessão, por isso nenhuma imagem de piloto foi inserida no repositório. Não marcar o pack como gerado.

### Entradas

Os 48 originais são os 24 retratos próximos e 24 retratos de corpo inteiro enviados em três mensagens em 19/11/2026. Mapeamento de nomes e fotos por ordem de upload em `data/portrait_source_uploads_2012.json`. Recomenda-se conferir a atribuição de nomes antes de qualquer distribuição.

### Produção exata, sem IA

```sh
python3 -m pip install Pillow
python3 tools/build_portraits_2012.py --inputs /mnt/data --output APEX_PORTRAITS_2012_24_PILOTOS_REVIEW.zip
```

O script usa **somente os pixels originais**, gera 24 imagens de HUD (384×400) e 24 de perfil (640×800), duas folhas de contato, metadados de coordenadas e hashes e valida a integridade do ZIP.

As fotos de HUD derivam dos retratos próximos enviados, e as de perfil dos retratos de corpo inteiro do mesmo piloto e uniforme 2012. Preservam foto de 2012 e fundo cinza; nome, nacionalidade e bandeira devem ser renderizados pela UI e não inseridos dentro do PNG. As imagens continuam sujeitas à revisão visual final, e a permissão de redistribuição não foi demonstrada.

Se uma fonte estiver ausente, o script falha com lista explícita em vez de criar um ZIP incompleto.
