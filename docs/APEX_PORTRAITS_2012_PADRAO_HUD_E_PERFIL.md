# APEX Motorsport Manager — Padrão de retratos 2012 (decisão visual)

**Estado:** especificação aprovada em conversa, 19/11/2026. **Somente documentação**; nenhuma fotografia foi incluída ou redistribuída neste commit. Próxima implementação isolada de retratos, após auditoria de direitos e testes.

## Regra principal

**Usar a mesma fotografia histórica de 2012 como origem para os recortes usados nas telas.** Não substituir a imagem por um retrato moderno, nem criar versões fotorrealistas inventadas. O enquadramento aprovado pelo usuário é o exemplo do **Lewis Hamilton com macacão branco/vermelho Vodafone McLaren de 2012**, em fundo cinza, com o rosto frontal destacado e recorte justo **do topo da cabeça até a parte superior do peito** para a tabela da corrida.

## Quatro contextos

| Contexto | Enquadramento | Objetivo |
|---|---|---|
| **Leaderboard / tabela da corrida** | **Close-up:** cabeça, pescoço, ombros e parte superior do peito, como na referência enviada pelo usuário em 19/11. Sem capacete e sem grandes áreas vazias. | Leitura instantânea de rosto mesmo em miniatura; usar crop da mesma sessão/foto histórica. |
| **Rádio / evento rápido da corrida** | Mesmo close-up, com ligeira ampliação do elemento no card | Coerência entre lista e rádio; não mostrar retratos incompatíveis. |
| **Perfil do piloto no menu** | **Recorte até a cintura**: rosto, ombros, tronco do macacão e capacete na mão quando a foto de origem permitir. | Identidade histórica da equipe 2012, patrocinadores e personalidade do piloto. |
| **Apresentação especial / ficha expandida** | Fotografia original de corpo inteiro | Material histórico completo para visualização em tamanho grande. |

## Convenções técnicas recomendadas

- Preservar foto original sem alterações em armazenamento autorizado; derivar tamanhos de UI por crop centralizado no rosto, com variação manual para pilotos diferentes. Não reconstruir, trocar rosto, macacão, patrocinador nem contexto histórico.
- Nunca aplicar upscaling artificial sem autorização; usar o arquivo individual de maior resolução disponível e seus recortes derivados para HUD, mantendo nitidez em 40–96 px.
- Criar crops independentes sem redimensionar destrutivamente o arquivo mestre; usar proporção de destino configurável pela UI. O exemplo enviado é quase quadrado para classificação, com a face no centro e espaço vertical para ombros.
- **Nome, abreviação, nacionalidade/bandeira e número são componentes da UI renderizados separadamente**, não texto gravado dentro dos pixels do retrato. Garantir legibilidade deles antes de aplicar cortes agressivos.
- Ao renderizar equipe e macacão, respeitar **2012**, inclusive Lewis Hamilton **McLaren**, não Mercedes, e número **4** no ano.
- O fundo cinza da fotografia histórica permanece no perfil/menu; o fundo gráfico APEX é um tratamento opcional de **apresentação da HUD**, jamais motivo para trocar a pessoa ou sua roupa.
- Para piloto sem fotografia licenciada ou que não passe inspeção visual, usar fallback de sigla previsto no pack de identidade 8.11. **Não redistribuir imagens editoriais, imprensa/Getty/AFP/F1, Sky, F1 Manager ou OverTake/RaceDepartment sem autorização documentada.**
- Fazer revisão de contato 24 retratos close-up em tamanho real de classificação + 24 retratos até a cintura + full bodies; registrar qualidade, disponibilidade e licença por piloto. Fotos fornecidas na conversa são **referência de recorte**, não licença de redistribuição automaticamente comprovada.

## Registro da escolha

**Preferência explícita do usuário:** para a tabela de corrida, dar zoom na **mesma foto**, como no recorte enviado do Hamilton em 19/11/2026, em vez de trocar para outra fotografia de rosto. No perfil/menu, manter o recorte da cabeça até a cintura, incluindo capacete quando possível. A mesma identidade fotográfica deve ligar HUD, rádio e perfil.

## QA antes de integração

1. Confirmar que os 24 titulares batem com season_2012 e driver_identity_2012.json.
2. Inspecionar legibilidade do rosto e nome/bandeira na classificação real.
3. Testar rádio, card do menu e escala em 1600×900 e 1920×1080.
4. Regressão Core 2, comando de pit manual V21, saves e replay.
5. Auditar permissão/atribuição de **cada imagem** antes de gerar ZIP público.

**Nota:** esta decisão não modifica a v0.6.6.8.12 nem autoriza automaticamente o uso de fotografias protegidas.
