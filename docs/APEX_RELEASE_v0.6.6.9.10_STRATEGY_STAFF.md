# APEX v0.6.6.9.10 — Strategy Staff Intelligence 1.0

**Status:** implementação candidata em branch/PR; **não homologada nem publicada**.
**Base:** v0.6.6.9.9, Godot 4.7.2, Core 2, F1 2012.
**Escopo:** uma funcionalidade principal; v0.6.6.9.11 continua exclusivamente reservada a Race Start Intelligence 1.0.

## O que o código acrescenta

- Serviço determinístico `race_strategy_staff_intelligence_066910.gd`, sem RNG, sem consulta ao cronograma secreto de chuva e sem escrita direta na simulação.
- Perfil congelado no início do GP a partir do estrategista realmente contratado/treinado e de campos existentes de Soul Staff: habilidade, energia, confiança e coordenação com engenheiro. Não modifica o save da garagem.
- Análise contextual de parada imediata versus extensão de **uma volta**, reutilizando a projeção já existente do Pit Wall 3.0 e usando exclusivamente condições presentes e nowcasts imperfeitos.
- Explicação qualitativa acessível no contexto **Estratégia** da HUD, com evidências, ressalvas, alternativas e nível de confiança não probabilístico.
- **IA automática, somente para o carro da equipe do jogador com STAFF ativo:** pode adiar uma parada não crítica por uma volta quando a projeção mostra tráfego agora e ar livre depois, com pneus secos, pista estável e janela segura. Nenhuma ordem manual é cancelada ou antecipada.
- Limite de um adiamento por stint e proteções contra segunda alteração pelo sistema de reavaliação por volta ou coordenação de garagens.
- Revisão esportiva de replay `021_strategy_staff_intelligence_v1`; a revisão `020_wet_strategy_intelligence_v1` permanece aceita e executada sem a nova decisão. Snapshot do STAFF fica na política de replay, e não nas propriedades do motor/checkpoint.

## Limitações declaradas

- Não representa probabilidade estatística calibrada, previsão perfeita de clima, futuros pits de rivais ou simulação física exata de pneus.
- A experiência inicial é **deliberadamente limitada**: não altera globalmente todos os algoritmos do Pit Wall, não adiciona nova tela de contratação e não implementa Strategy Staff 2.0.
- Rivais conservam a lógica estratégica anterior. Não há STAFF rival inventado.
- Não modifica valores de física, probabilidades de incidentes, regras de KERS/DRS 2012 nem diretório legado de save.
- A nova decisão do STAFF só é considerada quando o motor já recomendou pit, não emite nova ordem fora da janela e não executa nada no modo Manual.
- O módulo de decisão é puro; aplicação, registro de evento e proteção contra repetição são responsabilidade do RaceEngine.

## QA a executar

`godot --headless --single-threaded-scene --path . --import`

`godot --headless --single-threaded-scene --path . --script res://tests/strategy_staff_066910_test.gd`

O workflow `.github/workflows/apex-strategy-staff-ci.yml` também executa regressões de chuva, previsão, fila e coordenação.

**Matriz de testes (antes da CI):**
- Modelo de STAFF, imutabilidade e determinismo: NOT_RUN
- Decisão +1V: NOT_RUN
- Proteções V21, chuva, desgaste, gerente e double stack: NOT_RUN
- Replay novo 021, replay legado 020 e hashes: NOT_RUN
- Corrida integral de Silverstone/Monza/Spa/Singapura: NOT_RUN
- Importação headless Godot 4.7.2: NOT_RUN
- UI real 1600×900 e 1920×1080: NOT_RUN
- Benchmarks 10×/16×/32×: NOT_RUN
- Build Windows/Linux e ZIP completo: NOT_RUN

**Gate:** somente após CI verde, revisão das regressões visuais e performance, comparação dos replays e teste de corrida completa, a identidade do `project.godot` será alterada para 9.10 e será permitida publicação de ZIP/Release. A versão 9.9 publicada permanece imutável.

## Rollback

O branch `main` e a tag `v0.6.6.9.9` não são alterados por esta PR. Reverter a PR inteira restaura o algoritmo anterior. Replays 021 só devem ser reproduzidos por versões que conheçam a revisão 021; arquivos 020 permanecem compatíveis.
