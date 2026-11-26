# v0.6.8 — Race Randomness & Simulation Integrity 1.0

Base v0.6.7 e63213d9d5026f2e3ed0c2b24328cd6a5016a7db. Roadmap Unificado 3.0, antiga 9.24: RNG controlado, causalidade, incerteza e hashes/replay.

## Auditoria e contrato

- RaceEngine.rng: Godot RandomNumberGenerator, seed original, draws sequenciais em qualificação, compostos, tempo e incidentes de box e erro legado por volta (cadência mantida inclusive na revisão 040).
- Weather: seed derivada de circuito e seed original, gerador local apenas para o calendário de chuva. Forecast é observação sem sorteio.
- DriverError 040: amostras por seed/ID/tick/canal (1 gatilho, 2 tipo, 3 severidade) com avalanche inteira de 32 bits, sem consumir RaceEngine.rng.
- Codec: persiste seed e state como inteiros e inclui ambos no sporting hash; nenhuma mudança ao formato ou revisão 040.

## Implementação única

Centralizar as duas funções puras legadas sem alteração das operações; manter wrappers públicos e canais exatos. Não remover ou adicionar sorteios sequenciais. Criar API independente para eventos futuros: chave de 40 bytes, cinco inteiros assinados de 64 bits little-endian (seed, ator, tick, domínio, canal); SHA-256, palavra inicial uint32 dividida por 2^32. O domínio é explícito e os canais devem ter significado estável por revisão. Preserva todos os bits da seed, diferentemente do sampler legado. Não é garantia de ausência de colisão, nem validação estatística de probabilidades. Não usar o novo sampler para replays históricos ou para eventos sem elegibilidade causal. API não ativa nova falha ou novo risco esportivo nesta versão. Custo do SHA não está no hot path atual.

## Aceitação

Oráculos literais pré-refatoração para seed climática e amostra legada, inclusive sementes negativas e de 64 bits; formato de chave e separação de domínios; sequência de pit incidents comparada ao gerador independente; override e disabled sem draws; consultas extras sem alteração de RNG/clima; hashes tick a tick em seco/chuva, checkpoint/restauração e draws futuros, seek e regressões existentes de erro/clima/profiler/save. FAST exato obrigatório. Não alegar calibração, FULL, benchmark nativo ou novas falhas mecânicas. Rollback revert PR; nenhum campo persistente novo. Próxima etapa após homologação: v0.6.9, Braking & Acceleration Physics 1.0.

## Complementação dos cinco requisitos (REV2)
- Seeds automáticas em nova temporada e GP avulso (inclusive delegação), botão de regeneração, edição manual, valor visível no resumo. Não gerar durante a corrida, retomada, navegação interna, carregamento ou replay. Presets mantêm seeds fixas. Temporada preserva seed base persistida e offsets existentes. Limite automático 999849538 reserva os 19 offsets de 7919 dentro do SpinBox existente; não reduz faixa manual. Não promete unicidade global. A seed efetiva também alimenta a apresentação de rádio.
- Geradores independentes: preservados clima/erros/stream sequencial histórico, nova API isolada para domínios futuros. Não dividir retroativamente o stream legado dos boxes e qualificação (quebraria replays).
- Probabilidades condicionais: clima por circuito, risco de erro por pressão, habilidade, pneus, chuva e fase de curva; risco de box por competência/crew. Coeficientes de gameplay existentes, sem recalibração nem novos incidentes mecânicos. Testes anteriores intactos.
- Reprodução de erro: comparar hash esportivo e RNG após o mesmo gatilho natural a partir do checkpoint pré-erro; além da recuperação, telemetria, rádio e ordem BOX V21 já testados.
- Determinismo: seed real armazenada pelos formatos existentes, nenhum campo novo. Testes de menu, seed automática e restore somados às regressões anteriores.
- REV1 importação resolvida e 12 jobs de Driver Error PASS (45902176680); FAST 45902176675 falhou no contrato histórico de nome de versão, não no RNG. REV2 aceita ambas as convenções e exige consistência do número com project.godot. Novo FAST necessário. Nenhuma aprovação antecipada.
