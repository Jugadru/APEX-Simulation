# v0.6.9 — Braking & Acceleration Physics 1.0 (candidato)

Roadmap Unificado 3.0, antiga 9.25. Base integrada v0.6.8, 8e9046a0e2ab38af53e4898782e3458d8ae1149d. PR separada da consolidação de identificação 0.6.8 (#171).

## Diagnóstico
RacePerformance produz tempo-alvo de volta, RaceSpace converte diretamente em deslocamento dt/pace. A trajetória local tem redistribuição esquemática de tempo, mas não há estado longitudinal persistente. Não substituir o motor esportivo, estratégias, trajetória ou pit-lane.

## Modelo
- Nova revisão esportiva exata 041_longitudinal_physics_v1. 040 e anteriores permanecem na sequência original, inclusive gates, RNG, hashes e campos de carro; o motor sem sessão conserva o contrato legado. Sessões de corrida novas, com gravação ligada ou desligada, usam 041.
- A partir de 24 s, após a largada existente, converte ritmo final em m/s usando a distância declarada do GP (não a geometria esquemática). Retira o fator local legado somente da proposta longitudinal, substituindo por alvo dependente da carga de curva existente. O ritmo tático, desgaste e previsões continuam legados nesta etapa. Preview de 60m, limite de frenagem sqrt(v_f²+2bd), aceleração decrescente e frenagem dependente da velocidade, grip/clima/composto/desgaste. Coeficientes experimentais, não medidos em telemetria oficial.
- Integra a rampa de velocidade e distância em SI com cruzeiro quando atinge o alvo; a resolução de tráfego, ocupação, aproximação de box e segurança permanece soberana. Velocidade terminal persistida por carro só na revisão nova; redução pelo solver alimenta a velocidade do próximo tick. Pit-lane conserva sua própria máquina de estados; reset de velocidade na entrada e saída com aproximação 80 km/h (não regra universal de limite de boxes).
- Nenhum sorteio adicional, nenhum campo de nível de engine, nenhum schema novo. A chave do carro entra naturalmente nos checkpoints e hashes 041; versões antigas não recebem a chave. Lista de revisões inclui 040 explicitamente, sem renomear aliases anteriores. Novos testes de 041 acrescentados, testes de 040 mantidos.
- Não é simulação de motor V8/torque/marchas, transferência de carga, aderência lateral detalhada ou temperatura de freio; fases futuras 0.7.0+ preservadas. Ainda não se afirma ganho de realismo quantitativo, tempos de volta calibrados, FPS ou benchmark nativo.

## Aceitação
Oráculos de aceleração/frenagem/distância, cruzeiro, grip, restrições do solver; 24 carros em Silverstone chuva e Monza seco, 330 ticks por cenário, 041 gravação ON/OFF hash a hash, 040 arquivo e seek, largada idêntica, avanço positivo e estado de velocidade limitado, ordem BOX V21. Regressões direcionadas existentes de erro, chuva, RNG, pit, revisões, replay e FAST obrigatório. FAST pendente, sem FULL. Rollback antes de merge: descartar PR; depois: preservar leitor 041 caso já haja arquivos 041 distribuídos. Identificação permanece 0.6.8 até homologação. Consolidação #171 integrada em 5f1f641689d102d21aeec94b91d30ca943518fa4 (FAST 45906676619 PASS). Changelog e roadmap sincronizados na branch da PR #172; novo FAST obrigatório no SHA combinado.

## Complemento de frenagem antecipada e ápice (candidato 041)
- Preserva o preview local de 60 m e acrescenta restrições de velocidade pelos ápices do perfil de trajetória existente, com distância longitudinal em metros e continuidade na linha de chegada. A distância necessária de frenagem varia com velocidade, alvo e aderência; o limite mais restritivo prevalece. Não há novos campos persistentes nem RNG adicional.
- O alvo de ápice usa a severidade esquemática da curva, não raio físico medido. A aceleração após o ápice continua limitada pelo modelo existente. O solver de tráfego conserva a autoridade final; não se promete atingir exatamente o alvo em toda condição.
- O cronômetro existente mede a passagem real por volta, com resolução de tick e filtro de plausibilidade preservados. Acrescentados oráculos de distância, antecipação acima de 60 m na chuva, continuidade na linha de chegada, alvo no ápice, saída e teste de cruzamento real em Monza. Resultados pendentes de CI.
- A revisão 041 continua em desenvolvimento, sem merge; replays experimentais criados por candidatos 041 anteriores podem divergir. Revisões 040 e anteriores não recebem a nova restrição. Nenhuma alteração de engine gráfica, saves, regras ou demais sistemas.
