# Pacotes históricos — APEX 0.6.6.8

As cinco partes `APEX_v0.6.6.8.zip.part000` a `part004` foram movidas da raiz para esta pasta, sem modificação do conteúdo binário.

Este conjunto representa um arquivo dividido em cinco fragmentos ordenados e deve ser preservado completo para reconstituição do ZIP. Não é a versão mais recente do código na `main`; consulte a página de Releases e o README principal para versões distribuíveis.

**Importação histórica:** o script `.github/scripts/import_apex_archive.py` agora lê as partes daqui. Seus testes direcionados permanecem em `tools/tests/test_import_apex_archive.py`.

**Reconstituição manual (Linux):**
```bash
cat docs/arquivo/pacotes/APEX_v0.6.6.8.zip.part{000..004} > /tmp/APEX_v0.6.6.8.zip
unzip -t /tmp/APEX_v0.6.6.8.zip
```
Use essa reconstituição apenas em uma pasta segura e descartável; não sobreponha a branch `main`.

Mover estes arquivos limpa a navegação do GitHub, mas **não reduz o armazenamento Git**. Os arquivos continuam versionados, preservando hashes e possibilidade de rollback.
