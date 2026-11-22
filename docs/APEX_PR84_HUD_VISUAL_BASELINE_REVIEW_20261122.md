# PR #84 — revisão do desvio visual e nova referência da HUD (22/11/2026)

**Escopo:** validação e documentação; sem alteração de layout, física, estratégias, saves, IA ou comparador por pixels.

## Proveniência verificável

- PR #84: https://github.com/Jugadru/APEX-Simulation/pull/84
- Integração na `main`: `4f95ec66f8999535bd21703a68cd73f4b4107178`
- Referência anterior no teste original: `8e5f176892ad20c4dd75889e830500e0ae989831`
- Candidata original: `73eceb23bd0fc50244513e5aed78e682e654aed2`
- Falha A/B legítima (não apagada nem reclassificada): https://github.com/Jugadru/APEX-Simulation/actions/runs/44979498193
- Artefato original `apex-regressao-visual-ab`, ID GitHub Actions `14737033366`, contendo PNGs before/after/diff, manifestos e relatório.
- CI pós-merge do motor: https://github.com/Jugadru/APEX-Simulation/actions/runs/44979603184 — PASS no commit integrado.
- Dados de implementação e capturas do HUD novo: `docs/HUD_MANAGER_20261121_VALIDACAO.md`, `qa/hud_manager_20261121/after/`.

## Comparação visual original e interpretação técnica

Fixture idêntica: Godot **4.7.2**, Silverstone GBR, seed **660**, **24 carros**, **1600×900**, capturas reais via Xvfb/llvmpipe. O teste original compara **código antigo** com o novo e deve acusar as diferenças: não é uma falha de renderização que se resolve mudando a tolerância.

| Cena | Pixels alterados | MAE RGB | Limites (fração, MAE) | Resultado original |
|---|---:|---:|---|---|
| 2D Broadcast | 5,813% | 4,734 | 1,0%, 1,5 | FAIL |
| 2D Compact | 15,903% | 12,086 | 1,0%, 1,5 | FAIL |
| 3D Compact | 20,095% | 17,392 | 2,5%, 3,0 | FAIL |

Análise das três imagens originais, das respectivas versões novas e dos mapas de diferença:

1. **Torre de classificação:** redesenhada à esquerda; mantém 24 posições, indicação de pneus, seleção de piloto e intervalos.
2. **Clima + pista + minimapa:** reorganizados à direita; o painel de clima apresenta condição do céu e da pista; o minimapa tem fundo mais transparente. No frame amostrado não se observa sobreposição entre os dois painéis.
3. **Cards de pilotos:** em COMPACT, os dois cards inferiores são significativamente maiores para informações de pneus, ritmo, KERS e ações. Em BROADCAST, os cards permanecem ocultos conforme o modo.
4. **3D:** o cenário da pista permanece reconhecível; as alterações destacadas se concentram principalmente nos painéis. Esta inspeção de pixels não comprova qualidade de FPS, toda interação, acessibilidade, nem ausência de problemas ao longo do GP.

**Conclusão técnica:** as diferenças grandes são consistentes com a reforma visual intencional descrita na PR #84. O **FAIL do teste original permanece correto como detecção de mudança**, e exige revisão; não deve ser convertido artificialmente em PASS, suprimido ou apagado. O usuário pode revisar as imagens do artefato do workflow e solicitar ajustes visuais adicionais.

## Nova referência e prevenção de regressão

Após o merge, a **`main` no commit `4f95ec66` passa a ser a base visual de comparação** das próximas PRs, pela lógica já existente no workflow `apex-regressao-visual-ab.yml` (`github.event.pull_request.base.sha`). Nenhuma configuração de tolerância foi relaxada, e os testes da fixture e do SHA esportivo permanecem ativos.

A PR de validação que inclui este documento executa o comparador com duas revisões que contêm **o mesmo layout novo**, sem modificação funcional; a diferença esperada entre imagens cai para o ruído normal de renderização, dentro dos limites originais. Portanto, seu A/B pode ser **PASS sem reescrever o diagnóstico histórico da PR #84**.

O arquivo `tools/tests/test_visual_regression_ab.py` ganhou verificações para garantir que os limiares sejam preservados e que um redesenho de proporção comparável ainda seja sinalizado como **FAIL** contra o baseline antigo.

## Critério de encerramento

- [x] Identificar e preservar a evidência original da diferença.
- [x] Revisar os três pares reais de PNG e os mapas de alteração.
- [x] Não alterar física, HUD, replay ou limites para ocultar o evento.
- [x] Manter a `main` pós-merge como nova referência por revisão de código.
- [ ] Executar e registrar A/B na PR de validação (a ser preenchido após o workflow).
- [ ] Confirmar verificações completas aplicáveis na PR (Quality Gate só pode indicar READY com todas as evidências exigidas, jamais inferido do status do job).
- [ ] Aceitação visual final pelo responsável pelo projeto, caso haja novas solicitações de design.

**Nota:** o Quality Gate da PR #84 originalmente imprimiu `BLOCKED 0/10` antes de concluir outras pipelines e não vira READY sem reexecução e evidência válida. Um relatório do gate em modo AUDIT pode concluir o job com sucesso e continuar com `BLOCKED`. A existência da falha visual original impede 10/10 nessa revisão histórica; somente uma nova PR com comparação válida contra a base atual pode completar esse critério.
