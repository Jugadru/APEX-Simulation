# APEX SaveGuard — Melhoria 10/10

## Escopo real

O SaveGuard é uma **bateria de testes de compatibilidade, integridade e recuperação manual simulada**.
Ele **não** modifica o código de produção nem acrescenta recuperação automática no jogo.

O workflow `.github/workflows/apex-saveguard-ci.yml` faz checkout de duas revisões
e usa **Godot 4.7.2-stable** para produzir arquivos reais com a revisão de
referência (`main`, por padrão) e abri-los na versão candidata.

| Fonte anterior | Arquivo real gerado pela base | Verificação na candidata |
|---|---|---|
| `career_0667_20_season_data_stress.gd` | Campeonato JSON, serial 20 com 20 resultados no último ano | Temporada, 24 pilotos, 12 equipes, pontos e rodada final |
| `core_0642_save_migration_test.gd` | Garagem JSON legado, R$ 6,5 mi, melhorias, staff | Orçamento, níveis de peça e equipe, inventário e roundtrip |
| `replay_0663_legacy_fixture.gd` | Arquivo binário `APEX_REPLAY_0660` com 350 ticks | Load/seek completo, hash esportivo, checksum e revisão física |

O SaveGuard gera os arquivos **com o código da própria referência**, em vez de
usar objetos falsificados. O replay é lido pelo teste legado de compatibilidade
e pelo novo teste da candidata. As verificações produzem hashes SHA256 dos
três arquivos originais, que devem permanecer imutáveis.

## Corrupção e segurança

O teste `tests/ci/apex_saveguard_cross_revision.gd` opera exclusivamente em
**cópias criadas em diretórios temporários**. Os arquivos originais da versão
de referência jamais são abertos para escrita:

- Campanha: rejeita JSON inválido, número de formato incompatível e
  `round_index` divergente; valida restauração de uma cópia manual.
- Garagem: confirma o backup `.bak` produzido pelo `Garage.save()`,
  a preservação do orçamento anterior e a capacidade de restaurar manualmente
  uma cópia após corrupção do principal.
- Replay: rejeita hash SHA256 incorreto no envelope binário e versões com
  revisão de física incompatível, sem classificar incompatibilidade legítima
  como corrupção.

**Limitação importante:** o jogo atualmente não restaura automaticamente
uma garagem corrompida a partir de `.bak`. A leitura de JSON inválido não
significa recuperação da última versão salva. Não prometemos proteção
automática que não esteja implementada. Esse comportamento pode ser
endereçado em uma versão de produção própria com backup validado, interface
de recuperação e confirmação do jogador.

## Como executar

- GitHub → **Actions → APEX - SaveGuard Compatibilidade → Run workflow**.
- A execução manual oferece `baseline_ref` e `candidate_ref`.
- Em PR, a base é o commit da branch de destino e a candidata é o commit
  do PR; ambos têm os dados gerados por testes reais.
- Artefato `apex-saveguard-compatibilidade` contém somente logs e relatórios
  JSON/Markdown. **Não inclui arquivos de saves/replays**, que são destruídos
  quando a sandbox de CI termina. Retenção de relatórios: 14 dias.

A ferramenta deve sinalizar qualquer incompatibilidade detectada, mas cada
incompatibilidade exige triagem: uma revisão esportiva nova pode rejeitar
corretamente um replay antigo. O objetivo é não haver aceitação silenciosa
de arquivos incoerentes nem perda inadvertida de dados.

## Limites

- A compatibilidade testada é **entre dois commits selecionados**, não
  com todas as versões já distribuídas do APEX.
- Os 400 resultados da fixture de 20 temporadas são **administrativos**,
  não 400 Grandes Prêmios simulados.
- O teste não mede resiliência a quedas de energia nem garante integridade
  de mídia física e armazenamento do usuário.
- Não verifica arquivos reais dos jogadores, não instala sistema de
  restauração na interface, não altera saves nem realiza release automático.

## Preservação

Adiciona apenas workflow, script Python, testes GDScript e Python e
documentação. Física, IA, garagem, campeonatos e replay de produção ficam
inalterados. Merge somente após testes verdes e revisão manual.


**Execução segura em CI:** os cinco comandos Godot são executados diretamente no GitHub Actions, usando diretórios HOME/XDG isolados. O Python apenas confere logs reais e snapshots SHA256 dos três arquivos-base, gravados antes dos testes na candidata. Os saves e replays de exemplo não são publicados como artefatos.
