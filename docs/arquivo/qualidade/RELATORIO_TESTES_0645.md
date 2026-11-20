# Relatório de testes — v0.6.4.5

## Atualização: oito GPs consecutivos em carreira

**APROVADO:** AUS → MAL → CHN → BHR → ESP → MON → CAN → EUR, em uma única temporada, reiniciando o Godot entre etapas, com passo nativo de 0,20s.

231.017 ticks, 192 classificações, nenhuma volta inválida. Saves e pontuação preservados: 808 pontos de pilotos e 808 de construtores. Oito prêmios sem duplicação, quatro entregas de P&D e um cancelamento com reembolso correto. As 11 rivais acumularam 50 upgrades pagos, com 88 registros persistidos. Saldo final Ferrari: R$ 8.910.000; Motor 2, Asa 2, Chassi 1. Próximo GP salvo: GBR.

Leia **[RELATORIO_CARREIRA_0645.md](RELATORIO_CARREIRA_0645.md)** para método, resultados por etapa, auditoria financeira e reprodução. O CSV correspondente é `RESULTADOS_CARREIRA_8_GP_0645.csv`. Foi ajustada a comparação numérica do teste de saves (inteiro versus float após JSON); a carreira completa foi reexecutada. Nenhuma alteração no código de produção foi necessária.

As seções abaixo registram a validação anterior dos **oito GPs independentes**, preservada junto com seus dados.


## Revalidação integral no passo nativo — 09/11/2026

**APROVADO: oito GPs completos no Godot 4.7.2, exclusivamente por `RaceEngine.step(0.20)`.**

Binário fornecido: `Godot_v4.7.2-stable_linux.x86_64`, versão `4.7.2.stable.official.ed1daf0bf`. Execução headless em até quatro processos independentes. Sem `_advance(8.0)`, redução da distância, salto de voltas ou simplificação da física nesta bateria.

- **232.551 ticks** com incremento de relógio verificado a cada chamada: 0,20s, tolerância numérica de 0,000001s.
- **46.510,2 segundos simulados** somando as oito provas.
- **192 classificações de carros**: 24 finalizados por GP; posições 1–24 sem IDs duplicados; classificação final validada pelo motor.
- **11245 voltas na telemetria**, nenhuma abaixo do limite de plausibilidade de 70% do tempo-base do circuito.
- **Zero voltas inválidas**, zero eventos `timing_invalid`, zero desclassificações e zero violações de compostos.
- Temperaturas, desgaste e aderência amostrados a cada 20s simulados, com verificação de limites e números finitos. Verificada evolução do asfalto e ocorrência de pista molhada nos GPs de chuva intensa.
- Histórico de boxes compatível com a soma de paradas dos 24 carros em todas as provas.
- Soul atualizado no motor para todos os pilotos; os dois carros do jogador usaram controle de box IA.
- Todos os processos encerraram com código 0 e marcador PASS. Logs sem erros de script ou falhas de teste.

## Resultados nativos

Mesmos circuitos, climas, seeds 6400–6407 e upgrades Motor/Asa/Chassi nível 1 da bateria anterior. São oito GPs independentes, não uma carreira sequencial. As distâncias permanecem as do calendário herdado.

| GP | Clima | Voltas | Ticks de 0,20s | Tempo simulado (s) | Paradas do grid | Vencedor |
|---|---|---:|---:|---:|---:|---|
| AUS | Seco | 58 | 26524 | 5304.8 | 48 | Fernando Alonso |
| MAL | Chuva intensa | 56 | 33429 | 6685.8 | 76 | Sebastian Vettel |
| MON | Seco | 78 | 30712 | 6142.4 | 72 | Sebastian Vettel |
| GBR | Variável | 52 | 26600 | 5320.0 | 90 | Fernando Alonso |
| BEL | Chuva intensa | 44 | 29010 | 5802.0 | 69 | Sebastian Vettel |
| ITA | Seco | 53 | 23512 | 4702.4 | 24 | Fernando Alonso |
| SIN | Variável | 59 | 34651 | 6930.2 | 110 | Lewis Hamilton |
| BRA | Seco | 71 | 28113 | 5622.6 | 42 | Fernando Alonso |

O CSV `RESULTADOS_8_GP_0645.csv` foi substituído pelos resultados nativos, incluindo temperaturas, aderência, borracha, ticks, classificados e contadores de falha. Os JSONs por circuito contêm os 24 carros, todas as voltas registradas, eventos e histórico de pit stops.

## Problemas encontrados e alterações

**Nenhuma falha do jogo foi encontrada nesta bateria; não foi necessário alterar a implementação do motor.** Scripts de produção, dados e cenas foram comparados com os hashes do pacote v0.6.4.5 anterior e permanecem idênticos.

A correção foi no procedimento de validação: o teste principal usava passos laboratoriais de 8s e agora chama `step(0.20)` em cada avanço. Acrescentados limite de 100.000 ticks por GP, verificações de incremento exato do relógio/números finitos/melhor volta plausível e exportação de evidências detalhadas. O executor Linux aponta para esse teste e permite até quatro horas por processo em máquinas mais lentas, mantendo saves isolados.

A análise do histórico confirmou que o menor intervalo entre paradas em GBR, de três voltas, foi uma troca de slick para intermediário após a chegada da chuva (Charles Pic, V22→V25), e não uma alternância repetida de compostos. SIN completou com 110 paradas no grid e no máximo cinco por piloto; o menor intervalo entre paradas foi de cinco voltas. Não foram afrouxados os limites de 90 paradas em seco e 120 nos demais climas, nem as verificações de classificação.

Os resultados não precisam coincidir com o ensaio de 8s: reduzir o passo altera a integração, a sequência de eventos e o consumo de RNG. Malásia, Singapura e Brasil tiveram vencedores diferentes. O ensaio grosso não é mais apresentado como evidência principal desta versão.

## Evidências e reprodução

- `qa/0645/native_020/AUS.log` até `BRA.log`: andamento e resultados individuais.
- Arquivos `.exit`: código de saída de cada processo.
- Arquivos `.json` por circuito: parâmetros, ticks, tempo, classificação, voltas, eventos e boxes.
- `qa/0645/native_020/audit.json`: consolidação das oito corridas e hashes dos arquivos de teste/motor utilizados.
- `qa/0645/eight_gp.log`: logs nativos consolidados; marcador final de oito GPs aprovados.
- `qa/0645/coarse_8s/`: relatório, CSV e log anteriores, mantidos somente para histórico.

Para repetir toda a validação:

```sh
GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_0645.sh
```

Para repetir um GP isolado:

```sh
/caminho/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script tests/race_0645_eight_gp_test.gd -- --code BRA
```

## Validações anteriores preservadas

Na entrega inicial desta mesma versão passaram o teste integrado de IA/Soul/ordens/HUD, 13 testes de regressão (física, pneus, clima, oficina/rivais, saves, engenheiro, rádio, controle da equipe e cronometragem) e a captura OpenGL da HUD UI03 em 1600×900. Esses resultados não foram reexecutados nesta etapa, pois os arquivos de produção não mudaram. Seus logs e a captura continuam em `qa/0645/`. A revalidação desta etapa cobre os oito GPs completos pelo passo nativo, além da auditoria de todos os resultados.

O histórico original registra uma chamada incorreta de método no teste novo, já corrigida, e interferência de saves no teste Pit Wall, resolvida com execução isolada. Nenhuma dessas ocorrências reapareceu na bateria nativa.

## Preservação, integridade e limites

As implementações da v0.6.4.5 anterior foram preservadas. Em relação à base v0.6.4.4, continuam 140 arquivos de scripts/dados/cenas idênticos; a lógica do hotfix de cronometragem permanece preservada.

O manifesto `BUILD_MANIFEST_0645.json` é regenerado com os hashes de todo o pacote, exceto o próprio manifesto. O ZIP atualizado passa por CRC, verificação de nomes/caminhos e comparação de todos os hashes internos. O arquivo `.sha256` externo verifica o ZIP completo. Caches `.godot` e saves temporários dos testes não são distribuídos.

Os GPs foram executados headless com a física de produção, sem renderização contínua da HUD. Aprovação valida os invariantes testados; não demonstra estratégia ótima, precisão histórica de cada resultado ou ausência de qualquer bug possível. A projeção de tráfego continua estimativa; Soul é ficcional, local ao GP e sem efeitos na física.
