# Refatoração da gestão de equipe — 0.6.5.0

Esta entrega refatora a camada de contratos e Soul Staff do projeto enviado. A API pública da garagem, os textos, os custos, a duração dos contratos e o formato dos saves permanecem compatíveis. Não é uma reescrita integral do simulador.

## Organização

- `scripts/garage.gd`: fachada pública, normalização de equipes e persistência. Salva contratações/rescisões somente quando a transação informa uma alteração.
- `scripts/core/staff_contracts.gd`: contratação, rescisão, folha, vencimento de contratos e histórico limitado a 40 entradas; recebe o estado já normalizado pela garagem, sem acesso a arquivos.
- `scripts/core/staff_round_rules.gd`: regra compartilhada de participação no GP e chave persistente de temporada/etapa. Elimina a duplicação entre a folha e a atualização humana.
- `scripts/core/staff_soul_catalog.gd`: ações, perfis e falas contextuais, separados da mutação do estado.
- `scripts/core/staff_soul_0650.gd`: migração e evolução humana; mantém aliases e delegações para os consumidores existentes.

O caminho `user://`, os identificadores de versão e as chaves dos saves não mudaram. O ZIP de origem e os saves reais não foram alterados. Os testes usaram diretórios temporários exclusivos.

## Validação reproduzível

Com Godot 4.7.2 disponível:

```bash
GODOT_BIN=/caminho/para/godot bash tools/verify_staff_refactor.sh
```

Para incluir os testes gráficos existentes, acrescente `--ui`. Eles exigem uma sessão gráfica que permita janelas de 1920 × 1080 reais. A execução headless não fornece as texturas necessárias para capturas.

O teste `tests/staff_refactor_parity_test.gd` compara uma impressão digital de 11.880 registros de estados e retornos com a versão original, executada separadamente a partir do ZIP. Abrange 54 cenários (três ações, seis posições de chegada e três conjuntos de candidatos), cobranças repetidas, contratação no meio da temporada, vencimento, saldo insuficiente e rescisão. A referência está em `tests/staff_refactor_expected.sha256`; não a regenere automaticamente ao alterar regras.

As evidências desta entrega ficam em `qa/refactor/`. Os relatórios e manifests de versões anteriores foram preservados como histórico; o inventário desta entrega é `BUILD_MANIFEST_REFACTOR_0650.json`.

## Limite observado no teste gráfico

O teste Soul Staff de captura em 1920 × 1080 falhou tanto no projeto original quanto no refatorado: a janela foi limitada a 1786 × 1005 neste ambiente. O teste gráfico legado de equipe passou. Não houve alteração no layout para contornar essa condição; os logs original e refatorado foram mantidos.

## Resultados desta entrega

| Verificação | Resultado |
| --- | --- |
| Importação do projeto no editor Godot 4.7.2 | Passou, sem erros de parsing/importação |
| Paridade com o ZIP original | Passou: 11.880 registros, SHA-256 idêntico |
| Modelo Soul Staff | Passou |
| Migração de saves 0.6.4.9.9 | Passou |
| Contratos, salários, vencimento e persistência | Passou |
| Integração da carreira e reconciliação de prêmios/folha | Passou |
| Corrida determinística em GBR, ITA e SIN | Passou nos três circuitos |
| Interface legada de equipe | Passou |
| Captura Soul Staff em 1920 × 1080 | Falha de resolução reproduzida no original; ver limitação acima |
| GP completo e fechamento da temporada | Passou: 58 voltas, 1.328 ticks, resultado/folha/Soul Staff/idempotência/próxima ação |

A primeira tentativa do teste de GP completo atingiu o limite de 180 segundos. A repetição com limite de 600 segundos passou, conforme `qa/refactor/soul_staff_0650_season_full.log`. O executor fornecido usa 600 segundos por teste, ajustáveis por `TEST_TIMEOUT_SECONDS`.
