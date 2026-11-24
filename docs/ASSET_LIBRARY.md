# APEX Asset Library — acervo visual reutilizável

Atualizado em 24/11/2026. Este catálogo não altera o jogo nem representa uma nova versão integrada.

## Armazenamento

Acervo privado do responsável pelo projeto no Google Drive: **Meu Drive / APEX Asset Library**.
Os binários não devem ser incluídos neste repositório público enquanto a procedência e as licenças de redistribuição não estiverem verificadas. O acesso ao acervo requer autorização do responsável; não usar links públicos nem credenciais no código.

| Pasta no acervo | Conteúdo |
|---|---|
| 2012/Retratos | APEX_PORTRAIT_PACK_2012_v0.6.6.8.42_CORRIGIDO_24_PILOTOS_48_IMAGENS.zip — revisão de referência, 24 HUD (384×400), 24 perfis (640×800), fundos e materiais de integração conforme entrega original |
| 2012/Retratos | APEX_PORTRAIT_PACK_2012_v0.6.6.8.13_COMPLETO_24_PILOTOS.zip — recortes históricos, alternativa de referência |
| 2012/Originais | Imagem.tar.gz e cinco imagens complementares originais; preservar sem edição |
| 2012/Previews | Prévias gerais v8.42 e HUD/perfis v8.44 |
| Interface/Fundos | APEX_Menu_Fundo_Oficial_A_Laranja_Suave.png; APEX_Menu_Fundo_Alternativo_B_Estrelinhas_Laranja.png; ZIP A/B |
| Backups | APEX_MOTORSPORT_MANAGER_v0.6.6.8.44_PORTRAITS_REAIS_BETA.zip — snapshot histórico completo da integração, NÃO substitui a main atual |

15 arquivos copiados e presença verificada no Drive em 24/11/2026. O armazenamento está separado dos códigos e o acervo não foi compartilhado publicamente.

## Reutilização em versões futuras

1. Consultar a main atual e este catálogo antes de criar novos retratos, fundos ou interfaces.
2. Recuperar uma cópia do ZIP de referência com autorização do responsável.
3. Conferir manifesto, integridade, dimensões e correspondência de identidades. A revisão v8.42 teve validação técnica anteriormente relatada, mas o acabamento artístico e as licenças ainda exigem revisão. Alguns retratos iniciais tiveram edição por IA.
4. Verificar os caminhos e APIs na versão atual do jogo antes de copiar somente os assets necessários. Caminhos históricos: `assets/portraits_2012/hud/` e `assets/portraits_2012/profile/`; fundos do menu separados em `assets/menu/`.
5. Preservar as imagens-mestre. Gerar variantes derivadas em pasta/versionamento separado; nunca sobrescrever os originais. Fundo A laranja suave é a escolha do menu; B é alternativa. Os retratos do pack final usam fundo azul geométrico.
6. Não extrair o projeto beta histórico por cima da main. Não migrar saves, física, replay ou código da beta para a versão atual apenas para recuperar imagens.
7. Para uma futura integração, executar os testes de recursos, identidade, HUD, rádio, perfil e regressões pertinentes, respeitando FAST + APEX Test Lab no SHA exato. Sem medir FPS na máquina do usuário, não alegar ganho de desempenho.
8. Antes de publicar em releases ou no GitHub público, verificar direitos e autorização. Manter alternativas e originais privados.

## Estado

Acervo preservado para desenvolvimento futuro; não é solicitação de integração imediata. As fotografias e os fundos não foram enviados a este GitHub público. Não foram feitos novos testes de Godot nesta operação de arquivamento.

## Entrada rápida para agentes e novas conversas

No Drive conectado, abrir `Meu Drive / APEX Asset Library / 00 — APEX Asset Library — Índice mestre e recuperação`. Esse índice contém os links exatos dos arquivos, versões de referência, dimensões e protocolo de recuperação. Pesquisar pelo título exato se necessário. Não copiar os links privados para o GitHub público. Se o Drive não estiver conectado, solicitar acesso ao responsável, sem recriar os assets.

Ao adicionar ou substituir um recurso de referência, atualizar o índice mestre e este catálogo na mesma entrega. Distinguir backup histórico, asset de referência e asset efetivamente integrado.
