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
