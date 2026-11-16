# Importação segura do APEX para o GitHub

## Estado atual

O repositório já pode receber documentação, mas **a árvore completa do projeto Godot ainda precisa ser importada**. O pacote de referência é `APEX_MOTORSPORT_MANAGER_v0.6.6.7.2.4_PITLANE_CPU_COMPLETO.zip`.

## Procedimento no Linux Mint

1. Guarde uma cópia intacta do ZIP fora da pasta de desenvolvimento.
2. Descompacte a versão estável do APEX em uma pasta local.
3. Confirme que existe `project.godot` na raiz do projeto real (ou identifique a subpasta que o contém).
4. Abra um terminal e execute:

```bash
git clone https://github.com/Jugadru/APEX-Simulation.git
cd APEX-Simulation
```

5. Copie **o conteúdo da pasta que contém `project.godot`** para dentro da pasta clonada, sem remover `.git`, `README.md`, `.gitignore` ou `docs/`. Não copie as pastas de cache `.godot/` ou `.import/`.
6. Verifique se há arquivos individuais grandes antes de enviar. O GitHub bloqueia arquivos Git comuns acima de 100 MiB; para binários necessários e grandes, avalie Git LFS. Evite executáveis de ferramentas, vídeos de referência e ZIPs de backups no repositório.
7. Confira as alterações e envie:

```bash
git status
git add .
git commit -m "Importar fonte estavel do APEX v0.6.6.7.2.4"
git push origin main
```

8. Verifique se `project.godot`, `scenes/` e `scripts/` (conforme a estrutura real) estão visíveis no GitHub.
9. Abra uma cópia limpa no Godot 4.7.2 e execute os testes disponíveis antes de marcar a base como validada.

## Segurança e controle de versões

- Não apague o ZIP original antes de verificar o código importado e os testes.
- Não inclua senhas, tokens ou dados privados.
- Só crie `feature/hud-rebroadcast` e `experiment/next-engine` a partir de uma base estável.
- Não assuma que o envio bem-sucedido ao GitHub equivale a um teste no Godot.
