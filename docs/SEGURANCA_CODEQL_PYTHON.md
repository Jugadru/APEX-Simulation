# APEX — Segurança de código Python (melhoria 5/8)

## Status e escopo

Este repositório é **privado**. A automação `.github/workflows/apex-seguranca-python.yml`
foi desenhada para não presumir uma licença do GitHub Code Security.

- **Bandit 1.9.4:** executa no GitHub Actions sem habilitar CodeQL; varre
  `.github/scripts/` e `tools/` (excluindo `tools/tests/`, onde há assertivas de teste), e salva JSON, logs e resumo.
- **CodeQL (Python):** configurado, porém o job é **omitido por padrão**.
  Só executa se `APEX_ENABLE_CODEQL=true` estiver definido nas variáveis de
  repositório **e** o GitHub Code Security estiver disponível e ativado.
- **GDScript:** não é linguagem suportada pelo CodeQL ou pelo Bandit.
  O projeto Godot continua sujeito aos testes específicos de GDScript.

## Ativar o CodeQL (somente se houver licença)

1. Abra **Settings → Security and quality → Advanced Security** do repositório.
2. Confira se o **GitHub Code Security** está disponível e habilitado. Para
   repositórios privados, isso pode exigir um plano/licença paga. Não altere
   a visibilidade do repositório para habilitar o scanner.
3. Se estiver habilitado, abra **Settings → Secrets and variables → Actions
   → Variables** e crie a variável de repositório:
   `APEX_ENABLE_CODEQL` = `true`.
4. Rode manualmente **Actions → APEX - Seguranca Python (Bandit + CodeQL opcional)**
   e confira o job **CodeQL Python**, junto ao relatório na guia **Security**.
5. Se o CodeQL falhar por elegibilidade/licença, mantenha a variável desativada
   até resolver esse requisito no GitHub. A auditoria Bandit continuará útil.

A mudança de variável é um passo **manual e explícito**: o workflow não
contrata serviços, não altera configurações de segurança e não torna o
repositório público.

## Como interpretar resultados

- `CLEAN`: não houve achados Bandit nas regras executadas. Isso **não**
  significa que o programa inteiro é seguro.
- `FINDINGS`: possíveis problemas de segurança Python foram encontrados.
  O relatório é informativo neste primeiro estágio para que problemas
  antigos não bloqueiem mudanças de jogo por padrão.
- **Falha da automação**: teste do gerador de relatórios, ferramenta ou
  JSON incompleto/incorreto. Esses casos não podem ser tratados como CLEAN.
- CodeQL não executado: não há resultados nem cobertura de CodeQL; o job
  aparece como *skipped* no GitHub Actions.

O workflow usa permissões mínimas por função: Bandit lê código e publica
artefatos; somente o job opcional CodeQL pede `security-events: write`.

## Preservação

Nenhuma alteração foi feita em física, IA, HUD, saves, replays ou renderização.
As recomendações do scanner devem virar PRs separados, com revisão e testes de
regressão antes de corrigir o código.
