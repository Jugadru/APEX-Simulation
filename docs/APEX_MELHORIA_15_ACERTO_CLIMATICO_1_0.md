# Melhoria 15 — Acerto climático pré-corrida 1.0

## Relação com a Melhoria 14
A PR #52 (largada) é a base da integração. A branch da melhoria 15 foi reconciliada com a revisão corrigida da 14, preservando as duas funcionalidades em um novo commit de integração. **Não integrar a PR 15 antes de fechar os testes da PR 14.** Caso as duas PRs modifiquem os mesmos arquivos, rebasear a 15 sobre `main` atualizado e reexecutar toda a CI. Não suprimir conflicts com substituição integral.

## Objetivo
Fundamentar uma primeira decisão de preparação pré-corrida do piloto com três variáveis abstratas independentes, capazes de produzir trade-offs diferentes de desempenho e desgaste conforme as condições REAIS do asfalto. Foco em backend do Core 2 e teste Godot; interface de garagem/STAFF, qualificação e previsão imperfeita ficam para incrementos posteriores.

## Contrato de dados
`race_setup_15` no carro: `{"wing":0.0,"brake":0.0,"suspension":0.0}` padrão neutro (componentes contínuos de -1 até 1). Configurar exclusivamente com `race.configure_pre_race_setup(car_id, settings)` antes de `running=true`, limitado aos dois pilotos da equipe do jogador e a valores completos, finitos e válidos. A alteração não troca pneus, não envia ordem de pit, não altera a chuva, nem consome RNG.

`race_weather_setup_15.gd` calcula `pace_delta_s`, `wear_scale` e explicações por componente. Usa `wetness_factor`, `surface_lateral_load`, `surface_traction` e `grip_factor` existentes no estado do asfalto. A intervenção é pequena e limitada: custo de arrasto × benefício de asa em curva, distribuição de frenagem com compromisso seco/úmido, suspensão conforme aderência mecânica e desgaste. Não se trata de calibração FIA.

## Limites
- Sem interface visual de seleção nesta versão. A API já pode ser usada por futuros painéis, mas **não** declarar configuração manual acessível no jogo sem integração da UI.
- Rivais e carros sem acerto explícito permanecem neutros; falhas ou saves legados usam padrão neutro.
- Não confundir preferência de setup com uma previsão de chuva perfeita.
- Não adicionar bônus aleatório de equipe ou posições ganhas gratuitamente.
- O efeito contínuo pode alterar hashes esportivos de corridas cujos acertos sejam deliberadamente configurados; nenhuma alteração é esperada na baseline neutra da versão 15.

## Testes obrigatórios
1. `tests/weather_setup_15_test.gd`: neutro sem alteração, validação de entrada, vantagem e desvantagem de asa/suspensão em pista seca/molhada, desgaste e bloqueio pós-largada em instância real do Core 2.
2. Importação Godot 4.7.2 e Core 2, GdUnit4, Matrix 20×2, Pit Wall 4×2, SaveGuard, Endurance e benchmark A/B.
3. Comparação com versão 14 aprovada, incluindo smoke de largada, V21≠V4, pneus FIA 2012, corrida do início ao fim e hashes com seed fixa.
4. PR em Draft até evidências reais. Não mascarar warnings nem afirmar PASS sintético.

## Rollback
Reverter a PR. Nenhuma migração obrigatória: na ausência da chave, `RacePerformance` retorna o efeito neutro por compatibilidade.
