# APEX — exportação automatizada PC (melhoria 6/8)

## Objetivo
Gerar **builds de teste** para Linux x86_64 e Windows x86_64 a partir do
código-fonte Godot **4.7.2-stable**, sem modificar mecânicas do APEX.

## Arquivos
- `export_presets.cfg`: dois presets (APEX Linux x86_64 e APEX Windows x86_64).
- `.github/workflows/apex-export-desktop.yml`: exportação em runner Linux
  com Godot e export templates oficiais correspondentes à versão.
- `tools/package_desktop_exports.py`: valida assinaturas ELF/PE, existência de
  pacotes PCK, ZIPs e hashes SHA256, sem alegar que a build Windows foi executada.
- `tools/tests/test_package_desktop_exports.py`: testes de contrato.

## Como baixar
No GitHub, abra **Actions → APEX - Exportacao Linux e Windows → Run workflow**.
Depois que a execução terminar verde, abra o run e baixe o artefato
`apex-pc-linux-windows-godot-4-7-2`.
Ele contém ZIPs de Linux e Windows e `manifest.json` com hashes.

Descompacte o ZIP correto para seu sistema e mantenha o **.pck** junto do
executável:
- Linux Mint x86_64: torne `APEX_Motorsport_Manager.x86_64` executável e abra.
- Windows x86_64: abra `APEX_Motorsport_Manager.exe`.

A execução manual produz **artefatos temporários (14 dias)**, vinculados ao SHA exportado (`SOURCE_COMMIT.txt`). A publicação de uma GitHub Release é outra etapa, com autorização e validação próprias. A pré-release permanente 9.17.4 permanece disponível; não é a build 9.22.

## Cobertura real dos testes
- A criação de um arquivo, ainda que seja um EXE, não comprova que o jogo
  funcionará corretamente em todas as máquinas.
- O workflow valida os dois pacotes, importa recursos e faz um **smoke de
  inicialização Linux headless**. O Windows não é executado no runner Linux.
- Falta validar em hardware real no Linux Mint, testar Windows nativo,
  renderização 3D, conteúdo exportado em partida, saves e replays.
- O executável Windows é **não assinado**. Não contornar antivírus nem
  desabilitar proteções: assinatura e distribuição pública exigem revisão.

## Recursos não importados e dados
O projeto carrega arquivos JSON em `data/` diretamente com `FileAccess`.
Por isso os presets incluem explicitamente esses arquivos no pacote. Isso
precisa ser testado em uma partida exportada, além do smoke inicial.

## Preservação e segurança
As exportações não alteram código do motor esportivo, HUD, replay ou saves.
As alterações ficam em branch isolada e requerem PR/validação antes de merge.
O workflow reutilizável não publica releases automaticamente. As releases já existentes permanecem intactas. Não são publicados instaladores, chaves ou credenciais.
