# Carreira — oito GPs consecutivos — v0.6.4.5

Data: 09/11/2026. **APROVADO no Godot 4.7.2.stable.official.ed1daf0bf.**

## Método

Uma única temporada Ferrari, seed inicial 321, clima Automático e controle Automático dos dois pilotos. Calendário real do projeto nas primeiras oito etapas: AUS, MAL, CHN, BHR, ESP, MON, CAN e EUR. Corridas completas, cada avanço exclusivamente por `RaceEngine.step(0.20)`, com conferência de incremento do relógio a cada tick.

O teste carrega `scenes/main.tscn` e usa os callbacks reais de nova/retomada de temporada, oficina, início de corrida, autonomia do STAFF, gravação de resultado, reconciliação dos prêmios e retorno ao menu. O `_process` gráfico é desativado para evitar avanço simultâneo pelo relógio da interface. A física e a autonomia são executadas diretamente pelos métodos de produção, em headless.

Cada etapa roda em um **novo processo do Godot**. Um único diretório `XDG_DATA_HOME` temporário e isolado persiste entre os oito processos. Os estados carregados antes de cada nova etapa são comparados com os estados salvos ao final da anterior. Seus saves pessoais não são usados nem alterados.

## Resultado consolidado

- Oito etapas consecutivas, **231.017 ticks de 0,20s**, total de **46.203,4 segundos simulados**.
- **1.458 verificações explícitas** no worker, além da verificação de cada avanço do relógio, das amostras de valores finitos e da auditoria independente dos resultados.
- 24 finalizados por GP, 192 classificações, nenhuma desclassificação ou volta inválida.
- Pontos recalculados independentemente: 25/18/15/12/10/8/6/4/2/1 por etapa. **808 pontos** para pilotos e **808 pontos** para construtores.
- Liderança de pilotos: Fernando Alonso, 149; Sebastian Vettel, 144; Lewis Hamilton, 120.
- Construtores: Red Bull Racing Renault, 246; Ferrari, 212; McLaren Mercedes, 209.
- Save final: oito resultados, etapa seguinte **GBR**, temporada ainda em andamento.
- Saldo final Ferrari: **R$ 8.910.000**; Motor 2, Asa 2, Chassi 1; Agilidade da equipe de box 1 e Engenheiro 1.

## Etapas

| Etapa | GP | Voltas | Ticks | Tempo simulado (s) | Vencedor | Pontos Ferrari acumulados | Saldo após GP (R$) |
|---|---|---:|---:|---:|---|---:|---:|
| 1 | AUS | 58 | 26286 | 5257.2 | Fernando Alonso | 35 | 9300000 |
| 2 | MAL | 56 | 30537 | 6107.4 | Mark Webber | 65 | 10430000 |
| 3 | CHN | 56 | 29745 | 5949.0 | Sebastian Vettel | 98 | 10370000 |
| 4 | BHR | 57 | 28011 | 5602.2 | Sebastian Vettel | 119 | 11430000 |
| 5 | ESP | 66 | 29416 | 5883.2 | Sebastian Vettel | 138 | 8310000 |
| 6 | MON | 78 | 30624 | 6124.8 | Lewis Hamilton | 156 | 9440000 |
| 7 | CAN | 70 | 26922 | 5384.4 | Fernando Alonso | 196 | 7920000 |
| 8 | EUR | 57 | 29476 | 5895.2 | Sebastian Vettel | 212 | 8910000 |

## Saves, pontuação e prêmios

O teste verifica a continuidade de todos os campos do campeonato e da oficina após reiniciar o processo. Em cada etapa, novas instâncias dos módulos também leem os arquivos gravados e têm seus estados comparados. Antes de registrar o resultado, o save do campeonato permanece igual ao anterior: a corrida não pontua antecipadamente.

Foram executadas tentativas duplicadas de commit e de reconciliação dos prêmios; não aumentaram pontos, dinheiro, níveis ou históricos. O registro direto de uma etapa antiga foi rejeitado. Os prêmios foram conferidos pela posição do melhor Ferrari, e o orçamento foi refeito desde os R$ 12.000.000 iniciais, abatendo cada despesa e somando cada prêmio exatamente uma vez. Há oito entradas de prêmio no save final.

A conferência cobre saves **entre GPs**, não gravação/retomada no meio de uma corrida, falha de energia ou disco cheio.

## Oficina

As ações são feitas pelos mesmos callbacks usados pela interface:

1. Antes do GP1: Motor nível 1, treinamento Agilidade nível 1, contratação Engenheiro nível 1 e pesquisa de Asa.
2. Antes do GP2: tentativas de comprar a peça já reservada e de iniciar um segundo P&D foram bloqueadas sem alterar orçamento. A Asa foi entregue após o GP2.
3. Antes do GP3: início do Chassi, entregue após o GP4.
4. Antes do GP5: início e cancelamento de Motor nível 2. Reembolso exato de 75%; nova pesquisa paga corretamente e entregue após o GP6.
5. Antes do GP7: início da Asa nível 2, entregue após o GP8.

Resultado: **quatro entregas**, nas etapas 2, 4, 6 e 8; **um cancelamento**, nenhum projeto pendente ao final. As peças não ficam disponíveis antes do prazo. Os níveis salvos foram comparados com os parâmetros efetivamente recebidos pelo motor na etapa seguinte.

## Equipes rivais

As 11 rivais mantiveram histórico, caixa, investimento acumulado e níveis após cada restart. Foram auditados **88 registros** (11 × 8), sem avanço duplicado, saldo negativo ou nível acima de 3. A receita foi recalculada a partir dos pontos, etapa e rating; cada compra foi confrontada com o custo da peça e nível anterior. Não houve melhoria sem o débito correspondente.

Ao final, as rivais acumularam **50 upgrades pagos**. O estado da rodada anterior foi aplicado a `race.rival_upgrades` no início de cada corrida; o teste compara esse mapa com os níveis do campeonato salvo. O jogador não foi incluído entre as rivais.

## Ocorrência corrigida no teste

A primeira tentativa marcou divergência no roundtrip dos saves por comparar o texto JSON de números em memória com o texto de números recarregados: o Godot transforma `9300000` em `9300000.0`. A inspeção independente dos snapshots confirmou valores e estruturas iguais, sem perda de dados.

O comparador do teste foi corrigido para normalizar a representação JSON. A carreira inteira foi então **reiniciada do zero** e as oito etapas acima foram concluídas na mesma execução sequencial, sem reutilizar resultados da tentativa anterior. A tentativa inicial está em `qa/0645/career_native_020/initial_comparison_attempt/` para rastreabilidade.

**Nenhuma falha no código do jogo foi encontrada nesta bateria.** Scripts de produção, dados e cenas permanecem idênticos à entrega anterior da v0.6.4.5. Foram adicionados o worker e o executor de carreira, e o executor completo agora inclui essa validação.

## Arquivos e reprodução

- `RESULTADOS_CARREIRA_8_GP_0645.csv`: resultados, pontos, despesas, prêmios, orçamento e níveis por etapa.
- `qa/0645/career_native_020/round_1.log` a `round_8.log`: andamento, marcadores PASS e códigos de saída `.exit`.
- `round_01.json` a `round_08.json`: estados antes/depois, classificação e histórico de boxes.
- `championship_after_01.json` a `championship_after_08.json` e `garage_after_01.json` a `garage_after_08.json`: snapshots recarregados dos saves.
- `audit.json`: consolidação e hashes dos arquivos de teste/produção relevantes.

```sh
GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_carreira_0645.sh
```

O script usa saves isolados e encerra na primeira falha. `linux/validar_0645.sh` executa também esta bateria depois das regressões e dos oito GPs independentes. O manifesto e o SHA-256 do ZIP são regenerados; CRC e hashes de todos os arquivos do pacote são conferidos.

Os oito GPs independentes nativos da etapa anterior permanecem válidos e estão documentados separadamente no relatório geral. Esta bateria testa a continuidade de uma carreira específica; não representa todas as equipes, seeds ou falhas possíveis de armazenamento.
