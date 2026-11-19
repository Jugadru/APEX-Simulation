# APEX — Auditoria de retratos 2012: OverTake.gg/RaceDepartment e fontes livres

Data: 2026-11-18. **Status: AUDITORIA DE FONTES, SEM IMPORTAÇÃO DE ASSETS DE MODS.** Escopo do jogo: 24 pilotos titulares de 2012.

## Resultado executivo

A disponibilidade pública de um mod para F1 Manager 2024 **não** concede o direito de recortar, converter ou redistribuir os seus recursos em outro jogo. A auditoria não encontrou **nenhum pack de fotos de 24 pilotos de 2012 com licença explícita para uso e redistribuição independente no APEX**. Portanto: **0 mods liberados para importar assets** nesta fase. É possível usar esses mods como referência conceitual e contactar seus autores sobre imagens e direitos, mas não descompactar .pak para redistribuir fotos oficiais de Frontier/F1 ou de fotógrafos não autorizados.

## Mods auditados

| Fonte | Autor / conteúdo anunciado | Pertinência para 2012 | Autorização comprovada para imagens no APEX | Decisão |
|---|---|---|---|---|
| https://www.overtake.gg/downloads/2012-season-mod.73106/ | nedzosf1gridbox; temporada 2012 no F1 Manager 2024, principalmente edição de base de dados/saves | Direta: 24 pilotos da temporada | Não localizada; discussão indica instalação via .sav, não um pack demonstrado de retratos | **Consulta apenas; NÃO extrair assets** |
| https://www.patreon.com/kevintaddo/posts/f1-2012-season-134718350 | kevintaddo; grande overhaul 2012, carros, trajes, staff, patrocinadores, só via comunidade do Patreon/Discord | Muito alta para referências visuais | Acesso por assinatura não é licença para uso em outra obra; direitos das fotos não informados | **Pedir licença escrita antes de usar qualquer asset** |
| https://www.overtake.gg/downloads/ui-racing-suits-and-photos-fix.70933/ | Grzeluuu; roupa/posição/foto de Oliver Bearman (2024). Autor exige contato para reupload | Baixa para temporada 2012 | Não, e reupload depende de contato | **Não utilizar fotos** |
| https://www.overtake.gg/downloads/better-driver-market-indycar-formula-e-f1-academy-past-junior.72208/ | Thatgingerdude15; novos pilotos, incluindo Vettel/Räikkönen, com substituições visuais; fotos descritas como ainda em evolução | Parcial; imagens não necessariamente de 2012 | Não localizada, nem proveniência fotográfica | **Referência visual; não redistribuir** |
| https://www.overtake.gg/downloads/2026-driver-faces.83510/ | ReckedGamer; faces 3D de 2026 para carreira F1 Manager 2024 | Inadequada: faces 3D e temporada 2026 | Não há licença para o APEX no texto consultado; declaração de autoria não é licença de redistribuição | **Descartar para pack 2012** |
| https://www.overtake.gg/downloads/updated-junior-driver-photos.88222/ | jtgloves99; fotos UI de categorias de base 2026 | Inadequada para os 24 de 2012 | Não localizada | **Descartar para pack 2012** |

**Critério para liberar mod posteriormente**: (1) autor da fotografia identificado, (2) permissão explícita escrita para uso, adaptação, distribuição como assets do jogo APEX, inclusive versões gratuitas/comerciais se aplicável, (3) permissão de eventuais detentores dos assets de origem, e (4) screenshot de prova e registro de créditos. Autoria do arquivo mod não prova titularidade sobre todas as fotografias incluídas.

## Alternativa realmente licenciada — fotos independentes de 2012

As seguintes **cinco fotografias** têm licença explícita CC BY 2.0 na página individual do Commons, com autoria e possibilidade declarada de compartilhamento/adaptação **mediante atribuição**. A conformidade com outros direitos de imagem/marca e a qualidade do recorte exigem revisão adicional, portanto status **LICENÇA CONFIRMADA; QA VISUAL PENDENTE**, e não pack final.

| Piloto | Foto de 2012 / resolução original | Fotógrafo | Licença | Página-fonte |
|---|---|---|---|---|
| Fernando Alonso | Italian GP - Fernando, 2468×3716 | Francesco Crippa | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:2012_Italian_GP_-_Fernando.jpg |
| Lewis Hamilton | Italian GP - Lewis, 2848×4288 | Francesco Crippa | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:2012_Italian_GP_-_Lewis.jpg |
| Michael Schumacher | Italian GP - Michael, 2848×4288 | Francesco Crippa | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:2012_Italian_GP_-_Michael.jpg |
| Felipe Massa | Italian GP press conference cropped, 871×1172 | Francesco Crippa | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:2012_Italian_GP_-_drivers_press_conference_-_Cropped_-_Felipe_Massa.jpg |
| Sebastian Vettel | Bahrain GP 2012, 648×864 | Ryan Bayona | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Sebastian_Vettel_2012_Bahrain_GP.jpg |

- Álbum complementar: https://commons.wikimedia.org/wiki/Category:Files_from_Francesco_Crippa_Flickr_stream (contém outros registros de 2012; NÃO pressupor que sejam todos bons retratos).
- Diretório para completar a escala: https://commons.wikimedia.org/wiki/Category:Formula_One_drivers_in_2012 (24 titulares e material adicional; verificar **cada** página/autor/licença).
- Licenciamento: https://commons.wikimedia.org/wiki/Licenses ; CC BY: https://creativecommons.org/licenses/by/2.0/
- **Não confundir qualidade fotográfica / alta resolução com aprovação de rosto:** foto frontal, face central, posição na HUD e corte de cabeça e ombros precisam de QA individual.
- Atenção: fotos do Commons só podem ser usadas sob a licença efetiva de **cada arquivo**, não sob a licença do site. Arquivos com dúvida de autoria, origem Reuters/Getty, NC ou ND, ou sem licença livre verificada NÃO são liberados.
- Cada crop deve trazer fotógrafo, fonte, link CC, tipo de modificação ("recorte 4:5; fundo uniforme"), comprovante/manifesto de autoria. CC BY-SA exige manter a adaptação licenciada nos termos ShareAlike. Evitar selo de endosso e observar direitos da personalidade e marcas em qualquer lançamento.

## Plano técnico de execução para pack 2012 v2

1. **Não usar as fotos antigas de Austin como qualidade homologada.** Na UI, fallback por sigla e foto só após QA. Preservar a 8.11 como referência rollback; não mexer em RaceEngine/Replay nem em downloads anteriores sem controle de versionamento.
2. Montar shortlist de uma ou mais fotos para **cada** titular. Preferir retratos verticais de rosto/ombros, boa luz, identidade e figurino de 2012.
3. Auditar os 24 pares licença/autor/source URL e guardar prova da licença; classificar PASS / REJEITADO / REQUER AUTORIZAÇÃO.
4. Propor crop 4:5 por imagem com foco controlado pelo curador; gerar contact sheet 24×2 (antes/depois), revisar as 24 no tamanho REAL dos cards e do rádio; não confiar em checagem só de nome ou no teste automático de download.
5. Publicar asset pack **opcional** separado do jogo apenas quando as 24 imagens passarem auditoria de licenças e QA. Se algum piloto falhar, manter siglas sem trocar por imagem errada.

**Nenhuma alteração de código ou extração de mod foi efetuada por esta auditoria.** O PR 8.12 permanece isolado da main e depende da versão 8.11.

## Atualização: referências específicas enviadas para o APEX — Parte 1

**Foto coletiva Sky Sports / “Class of 2012”.** URL fornecida: https://e0.365dm.com/12/05/1600x900/F1-class-of-2012_2773667.jpg . A publicação editorial [Sky Sports, avaliação piloto a piloto de dezembro/2012](https://www.skysports.com/f1/news/8293985/driver-by-driver-review-of-the-season) exibe uma imagem com essa identificação. **Status: referência histórica editorial, NÃO AUTORIZADA para redistribuição no APEX.** O URL do CDN é um endereço de imagem, não um contrato de licenciamento. Também não é suficiente para produzir retratos individuais de qualidade: cortar 24 rostos de uma fotografia 1600×900 resultaria em poucos pixels por pessoa; não usar como fonte de portraits.

**Sebastian Vettel, Bahrein 2012 — arquivo indicado.** https://commons.wikimedia.org/wiki/File:Sebastian_Vettel_2012_Bahrain_GP.jpg . Página individual do Commons verificada: autor Ryan Bayona, data 21/04/2012, 648×864, Creative Commons [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/), revisão de licença histórica do Flickr. **Status: licença fotográfica comprovada e rosto nítido; candidato visual prioritário**, sem status de aprovado até teste em cards/radio com crop real. A fotografia mostra boné Red Bull, rosto em 3/4 e roupa branca identificada com a equipe; não declarar que constitui retrato de lançamento frontal nem que mostra corpo e macacão integral. Créditos obrigatórios e registro da adaptação.

**Fernando Alonso, Lewis Hamilton, Schumacher e demais pilotos.** As descrições de launch, Getty, Ferrari Media, W03/E20 e Melbourne 2012 são indicações de busca, **não** arquivos com permissão concedida. Para cada piloto, buscar fotos autorais em 2012, capturar URL individual, autor, licença e confirmar visualmente antes de incluir. Não fazer download de Getty, Sky, XPB, equipes ou imprensa para incorporar no APEX sem licenciamento específico.

**Local de pesquisa alternativo para completar os 24:** [categoria de pilotos da F1 em 2012 no Wikimedia Commons](https://commons.wikimedia.org/wiki/Category:Formula_One_drivers_in_2012), que lista 25 subcategorias incluindo o substituto Jérôme d'Ambrosio. Verificar cuidadosamente cada arquivo — uma categoria pode misturar imagens de pista, retratos e licenças distintas.

**Regra de aceite no APEX:** pelo menos uma imagem individual lícita, com enquadramento/roupa 2012 verificados, por titular; cenário de visualização 4:5 com foco no rosto; QA em tamanho real no card e rádio; autorização e créditos registradas. Não fazer mudança de arquivos do jogo antes de concluir a curadoria.


## Atualização: investigação das origens do infográfico Yankee F1 2012

**Fontes verificadas (2026-11-18):**

1. Daniel Seliger realmente exibe um projeto chamado **"Yankee F1 Branding & Design"** em seu portfólio, https://www.danielseliger.com/ . O artigo da Autoblog de 17/04/2012 identifica o *YankeeF1 spotter's guide* e mostra o grid de 2012, https://www.autoblog.com/news/spotters-guide-makes-sense-of-the-2012-formula-one-grid . **Não foi encontrada uma ficha de crédito que identifique qual fotógrafo produziu cada retrato incluído na colagem**. Não confundir autoria do design com titularidade das fotografias.
2. **Galeria de rostos e capacetes, publicada em 15/03/2012**, https://motorsport.nextgen-auto.com/en/formula-1/pics/Photos-2012-F1-drivers-portraits-and-helmets,38309.html . É uma pista cronologicamente muito compatível com o infográfico, mas não se comprovou que Yankee F1 utilizou seus arquivos. Direitos de reutilização não localizados: **REFERÊNCIA APENAS**.
3. **Galeria de 24 fotos individuais**, https://www.periodicodeibiza.es/fotogaleria/pilotos-de-formula-1-en-2012.html , publicada em 17/03/2012. O veículo identifica principalmente créditos **Reuters/EFE**. Cobertura completa do grid, porém essas fotografias editoriais não são licença aberta para uso dentro do APEX: **REFERÊNCIA APENAS**.
4. Galeria **F1 al Día**, https://www.f1aldia.com/fotos/galerias/parrilla-2012-formula-1/ , identifica individualmente 24 pilotos e equipes, incluindo HRT e Marussia. Licença explícita para assets não localizada: **REFERÊNCIA APENAS**.
5. **Sessão fotográfica oficial de Melbourne 15/03/2012**, registro Getty https://www.gettyimages.fi/detail/uutiskuva/sebastian-vettel-of-germany-and-red-bull-racing-attends-the-uutiskuva/141361086 : fotógrafo **Andrew Hone**, retrato de Sebastian Vettel, alta resolução original **3744×5616**, direitos geridos por licença editorial e restrição expressa para uso comercial, portanto **NÃO APROVADO PARA O PACK DO APEX** sem contratação de licença que permita redistribuição em jogos. A publicação prova a existência e autoria desta sessão, NÃO que a foto seja uma das usadas por Seliger.
6. **Retratos oficiais Force India 2012**: fotógrafo **James Moy** documenta a sessão de estúdio de **Paul di Resta e Nico Hülkenberg** na sede da equipe; https://jamesmoyphotography.blogspot.com/2013/ , trecho "Force India Driver Photo Shoot, UK, 2012". Fotos identificadas como **copyright James Moy** e não livres para incorporar sem autorização. O site registra contato público de licenciamento **james@jamesmoy.com**, mas nada foi enviado, negociado ou autorizado.
7. O próprio [arquivo Yankee F1](https://www.yankeef1.com/guide/2015) contém link para a edição 2012, https://www.yankeef1.com/guide/2012 , e outras edições. O link 2012 não pôde ser inspecionado integralmente no acesso atual; **não afirmar que o PDF contém licença livre**.

**Conclusão atual:** há confirmação direta de sessões de fotos originais, autores e datas. Porém nenhum desses arquivos editoriais foi liberado. A pista mais próxima da estética procurada é a sessão Getty/Andrew Hone de março de 2012 (e James Moy no caso Force India). A solução juridicamente viável sem licença proprietária ainda é priorizar equivalentes Wikimedia individualmente licenciados CC BY/CC BY-SA, com teste de crop padronizado. Não importar arquivos Reuters, EFE, Getty, XPB, F1, Sky, ou capturas do pôster apenas porque são exibidos publicamente. **Nenhum asset de terceiros foi modificado ou empacotado pelo registro desta auditoria.**
