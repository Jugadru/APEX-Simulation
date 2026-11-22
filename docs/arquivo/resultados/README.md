# Resultados históricos do APEX

Esta pasta reúne os **42 arquivos de resultados antes armazenados na raiz** do projeto, provenientes dos ensaios de oito GPs e da carreira 0.6.4.4/0.6.4.5.

- `RESULTADOS_8_GP_0644.csv`: ensaio da v0.6.4.4.
- `RESULTADOS_8_GP_0645.csv`: ensaio da v0.6.4.5.
- `RESULTADOS_CARREIRA_8_GP_0645.csv`: carreira de oito GPs.
- Arquivos `.translation`: artefatos binários de importação histórica do Godot, preservados byte a byte.
- Arquivos `.csv.import`: preservados com caminhos `res://` atualizados para a nova pasta.

**Escopo**: organização de arquivos, sem modificação de física, IA, estratégia, HUD, simulação ou formatos CSV. Os manifestos antigos em `docs/arquivo/manifestos/` documentam o layout histórico da raiz e não devem ser reescritos como se fossem manifestos atuais.

**Reprodução**: relatórios históricos podem citar os nomes dos CSVs sem o novo prefixo; resolva-os a partir desta pasta. Para investigar regressões, usar os testes e artefatos de CI atuais, não depender dos caminhos originais.
