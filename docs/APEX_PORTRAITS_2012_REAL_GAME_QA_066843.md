# APEX Portrait Pack 2012 — QA no projeto real (v0.6.6.8.43)

## Execução comprovada
- GitHub Actions: https://github.com/Quereni/APEX-Simulation/actions/runs/44658393367
- Commit testado: \`df2aa135e0191aff950394ff4cc8865e073f83d8\`
- Ramo experimental: \`feature/apex-orange-portraits-hud-066815\`
- Engine: Godot 4.7.2, Linux Ubuntu CI; renderizador virtual Xvfb/Mesa llvmpipe
- Status geral da execução: **PASS**.
- Capturas e logs: https://github.com/Quereni/APEX-Simulation/actions/runs/44658393367/artifacts/14595060489

## Matriz de resultados verificados
| Verificação | Resultado | Evidência |
|---|---|---|
| Importação integral do projeto | PASS | etapa 5 do workflow |
| Fallback com nenhum retrato local | PASS | \`APEX_066815_PASS\` |
| HUD real / modos / rádio | PASS | \`HUD_REBROADCAST_0668_INTEGRATION_PASS checks=34 issues=[]\` e teste do rádio |
| Pit manual solicitado na volta 21 | PASS | \`APEX2_PIT_ENTRY_21_PASS tick=11871 lap=21 events=1\` |
| Replay determinístico / checkpoint | PASS | \`APEX2_REPLAY_PASS checks=1622 failures=[]\` |
| Importação de 48 PNGs temporários | PASS | \`APEX_PORTRAIT_PACK_2012_STRICT_PASS: 48 textures / 24 identities\` |
| HUD na cena **real** em 1600×900 e 1920×1080 | PASS | \`APEX_PORTRAITS_REAL_SCENE_PASS checks=20 ... fixture_only=true\` |
| Corrida real completa em Silverstone (GBR) | PASS | \`AUDIT_PASS code=GBR laps=52/52 drivers=24 stops=78 ... errors=0\` |

**Silverstone:** seed 6403; clima Variável; 26.749 ticks; 1.146 revisões de estratégia; 24 pilotos chegaram ao final; 78 pit stops; vencedor Lewis Hamilton; zero erros de auditoria.

## Limites muito importantes
1. **Não são as fotos finais testadas na CI:** como os binários do Portrait Pack permanecem fora do repositório, a execução criou 48 imagens temporárias coloridas como *fixtures* para validar carregamento, nomes e conexão da interface. O conjunto final de retratos em fundo azul geométrico está no ZIP v0.6.6.8.42 da conversa.
2. As capturas do artefato são da **HUD real**, mas com imagens temporárias de teste; não devem ser apresentadas como screenshots de fotografias finais integradas.
3. O cenário gráfico foi executado com Mesa llvmpipe: tempo/FPS desse renderizador de software **não equivale à GPU do jogador**. Não foi medido FPS real no Linux Mint com a placa do usuário.
4. A auditoria Silverstone passou, mas não é execução de todas as pistas/condições climáticas. Save persistente de usuário e testes visuais com o ZIP definitivo continuam pendentes.
5. Licenças de redistribuição das imagens não verificadas.
6. O PR deve permanecer em **rascunho** e **sem merge** até os 48 PNGs definitivos serem instalados numa cópia do APEX, revisados visualmente e submetidos a testes na máquina final.

## Histórico
- Primeira execução https://github.com/Quereni/APEX-Simulation/actions/runs/44657698345: falhou por **erro do próprio teste**, que tentava avançar uma corrida ainda pausada. Não é defeito confirmado no produto.
- O teste foi corrigido para habilitar a simulação durante a auditoria e limitar os quadros renderizados por software.
- Segunda execução #44658393367: todas as etapas PASS.

Não houve alterações no motor esportivo, controle de pit, replay, física ou saves; as alterações ficaram restritas a arquivos de testes, workflow e documentação.
