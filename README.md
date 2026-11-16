# APEX Simulation — Motorsport Manager

Projeto de simulação e gerenciamento de escuderia desenvolvido em **Godot 4.7.2 / GDScript**, com temporada histórica inicial de **Fórmula 1 de 2012**.

> **Estado desta branch `import/apex-v0668`:** o código-fonte da versão **v0.6.6.8 — HUD ReBroadcast 2.0** foi extraído das cinco partes do ZIP por GitHub Actions. A integridade de leitura/extração passou, mas a importação e execução do projeto no Godot **ainda não foram testadas nesta branch**. A versão é **experimental**, não homologada como nova base estável.

## Importação verificada

- Partes de origem: `APEX_v0.6.6.8.zip.part000` até `part004` (preservadas na `main`).
- SHA-256 do ZIP reconstruído: `7d4ff778de6e59dac01edebff9be17419ca6d90d99d5ad5e66c0777776462a5f`.
- Arquivos extraídos: 2.746; arquivos presentes na árvore Git desta branch no primeiro commit: 1.874 (itens ignorados pelo Git não foram versionados).
- Arquivo principal: [project.godot](project.godot); 368 scripts `.gd`, 1 cena `.tscn`.
- [Execução do GitHub Actions (PASS)](https://github.com/Quereni/APEX-Simulation/actions/runs/43974460022).
- [Changelog da versão](APEX_CHANGELOG_v0.6.6.8.md) e [relatório técnico do pacote](APEX_RELATORIO_TECNICO_v0.6.6.8.md).

## Segurança das versões

A `main` não foi substituída: nela permanecem as cinco partes originais e os documentos de planejamento. Não incorporar esta branch à `main` antes de verificar os arquivos, importar no Godot 4.7.2, executar testes nativos e comparar com a base estável v0.6.6.7.2.4.

## Documentação

- [Plano Mestre Unificado 2.0](docs/APEX_SIMULATION_PLANO_MESTRE_UNIFICADO_2_0_2026-11-16.md)
- [Fonte Mestra histórica](docs/APEX_SIMULATION_FONTE_MESTRA_2026-11-13.md)
- [Guia de importação](docs/IMPORTAR_PROJETO_GODOT.md)

## Próximos passos

1. Auditar a fonte importada e arquivos omitidos do histórico Git.
2. Executar Godot 4.7.2 no runner para validar parser, importação e testes headless.
3. Validar HUD ReBroadcast com testes gráficos quando possível.
4. Homologar a versão e somente então decidir sobre integração à `main`.
5. Criar a ramificação separada da Next Engine, sem misturar o seu desenvolvimento com o da HUD.
