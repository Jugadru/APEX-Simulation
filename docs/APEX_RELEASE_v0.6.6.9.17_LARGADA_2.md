# APEX v0.6.6.9.17 — Largada 2.0

**Estado:** candidata em PR; não confundir código-fonte com ZIP jogável homologado.
**Base verificada:** `main` 23c98c769b65, v9.16; Godot 4.7.2, Core 2 e F1 2012.
**Escopo único:** congestionamento de largada e aproximação da primeira curva.

## Implementação
- `race_start_spatial_066917.gd`: avalia distância longitudinal ao carro mais próximo **no mesmo corredor ocupado**, a partir do snapshot esportivo congelado, comprimento esquemático da pista, chuva, consciência espacial, risco e estreitamento do primeiro setor.
- A decisão é **causal e limitada**: o serviço acrescenta um custo positivo e transitório ao tempo-alvo. Não acelera um carro, não concede posição, não inventa incidente, não cria RNG, não altera trajetória nem substitui o solver de RaceSpace.
- A janela de precaução termina em **18 segundos de tempo simulado ou ao ultrapassar a fração 0,14 da pista**, o que vier primeiro. A tração/reação original da v9.11 continua exatamente dentro dos seus oito segundos. Distâncias e coeficientes são estimativas do jogo, não grandezas físicas calibradas.
- Com o corredor livre (inclusive lado a lado com separação lateral suficiente), nenhum custo novo é acrescentado. Chuva e estreitamento justificam mais cautela; uma melhor percepção espacial atenua o custo.
- `race_performance.gd` aplica o custo ao ritmo oficial; `race_engine.gd` fornece apenas snapshots, hora simulada, revisão e contexto. HUD, câmera, pneus e estratégias não foram refeitos.

## Replay e saves
- Nova revisão esportiva `024_race_start_spatial_v1`.
- Replay `023_overtaking_intelligence_v1` mantém v9.11 e ultrapassagens v9.12, **sem o custo 9.17**.
- Replays `022`, `021` e anteriores permanecem roteados para seus contratos de física/estratégia existentes. A verificação da revisão acontece antes de qualquer aplicação do custo.
- A flag `race_start20_enabled` é exclusiva da sessão e está fora de checkpoints, saves e hashes esportivos. Ao restaurar ou buscar um tick, o replay reaplica a política de revisão correta.
- Nenhum campo foi acrescentado às entidades dos carros; a estrutura de salvamento continua igual.

## Testes e aceitação
- `tests/race_start_066917_test.gd`: headway, mesma faixa, carros lado a lado, chuva, gargalo, riscos, habilidade, limite temporal/espacial, ausência de mutação, 24 carros, determinismo de seed, revisão 024, import/seek e legado 023, além de BOX manual V21 sob chuva.
- FAST obrigatório via workflow consolidado, `tools/apex_ci_tiers.py` e `.github/apex-quality-suites.json`: 9.17, 9.11, 9.12, replay, teste de pistas e APEX Test Lab.
- Validar Godot 4.7.2 no SHA exato do PR. Antes de resultado do Actions, testes são **NOT_RUN**; somente logs e status finais autorizam PASS.
- Não acionar FULL, matriz 20/180 ou publicar binários sem solicitação expressa. CI FAST não prova FPS ou qualidade visual no PC real.

## Riscos conhecidos e rollback
- Sensibilidade dos 24 carros ao congestionamento durante os primeiros ticks: conferir ordem física, tempos e engarrafamentos de Mônaco/Silverstone em teste real; o custo permanece limitado a cinco segundos de volta-equivalente.
- O tempo de volta é uma abstração simplificada; não divulgar parâmetros como medições de 2012.
- Rollback: reverter esta PR como unidade; os serviços de largada 9.11 e ultrapassagem 9.12 foram preservados.
- Builds binárias disponíveis da 9.16 continuam sendo a última prévia jogável até exportação e validação separadas da 9.17.
