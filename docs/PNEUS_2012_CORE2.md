> **Arquivo histórico:** descreve versões anteriores com motor Clássico. Na v0.5.4.3 o modo Clássico foi removido; consulte `README.md` e `docs/CORE2_COMBATE_0543.md` para instruções atuais.

# APEX 0.5.4.2 — Pneus e pistas de 2012 (Core 2)

Este documento separa **fatos históricos** de **coeficientes de simulação experimentais**.

## O que é histórico

Em 2012 a Pirelli fornecia quatro pneus slick: supermacio (vermelho), macio (amarelo), médio (branco) e duro (prata), além do intermediário (verde) e do pneu para chuva intensa (azul). A cada GP, eram indicados **dois** dos quatro slicks. O arquivo `data/tyres_2012.json` inclui as 20 indicações; por exemplo, Spa = médio/duro, Mônaco = supermacio/macio e Suzuka = macio/duro.

Referências históricas para conferir as nomeações:
- Pirelli, primeiras provas: https://press.pirelli.com/pirelli-announces-compound-choice-for-the-first-three-races/
- Pirelli, escolhas até Hungria: https://press.pirelli.com/pirelli-announces-compound-choices-up-to-hungary/
- Pirelli, apresentação da gama 2012: https://press.pirelli.com/pirelli-squarer-and-even-more-competitive-tyres-for-the-2012-formula-one-season/
- Compilação de 20 GPs em documento de 2012: https://www.motorsinside.com/f1/actualite/14392-f1-pirelli-choisit-ses-pneus-pour-abu-dhabi-les-etats-unis-et-le-bresil

## O que é apenas balanceamento experimental

Os campos `delta` (diferença de tempo por volta), `wear` (desgaste por volta idealizada), `cliff`, `ideal` e `severity` NÃO são extraídos de dados reais da Pirelli. São parâmetros editáveis para simulações preliminares. O desgaste é calculado com o ritmo do piloto, o calor simplificado do Core 2 e o fator do circuito; não há modelagem por superfície, roda ou zona individual.

| Composto | Código | Cor 2012 | Base de desgaste (ajustável) |
|---|---|---|---:|
| Supermacio | SS | Vermelha | 6,20 pontos por volta |
| Macio | S | Amarela | 4,65 |
| Médio | M | Branca | 3,25 |
| Duro | H | Prata | 2,52 |

Os compostos intermediário e chuva estão cadastrados para compatibilidade futura, mas **ainda não ficam disponíveis para seleção**, porque o clima não está conectado à física. Não seria correto oferecer pneu de chuva enquanto o asfalto não simula aderência molhada.

## Integração

- `scripts/core/race_tyres_2012.gd`: carrega, valida e consulta o catálogo.
- `scripts/core/race_performance.gd`: usa dados do catálogo apenas no perfil `core2`; perfil `classic` mantém os coeficientes anteriores.
- `scripts/core/race_strategy.gd`: IA limita as escolhas aos dois slicks do GP; prefere uma alternativa ainda não usada quando chega a hora da parada.
- `scripts/race_engine.gd`: expõe `available_pit_compounds()`, `tyre_spec()`, `tyre_code()` e `tyre_severity()`; aceita ordens válidas no box; guarda condições do circuito no estado.
- `scripts/main.gd`: atualiza opções do cartão, rótulos e cores; mostra os compostos previstos no menu antes de iniciar.

O jogador continua chamando o box na **HUD inferior do piloto**, incluindo o atalho BOX recolhido. O Pit Wall apenas informa e ajuda na decisão; não há comando duplicado.

## Limitações relevantes

- A obrigação regulamentar de utilizar ambos os slicks diferentes numa corrida seca **ainda não é aplicada como penalidade**. A IA dá preferência a compostos ainda não usados.
- Não existem estoques por fim de semana (11 jogos de slicks por piloto), pneus usados em treinos ou classificação.
- Não há temperaturas físicas individuais por eixo/roda; o calor é a aproximação que já existia no Core 2.
- Não há chuva com efeito no asfalto, no tempo de volta ou em acidentes. Isso pertence à etapa futura de clima.
- As pistas têm multiplicadores explícitos de demanda, **estimados**, e precisam de calibração com simulações repetidas.

## Verificação

**Offline (sem Godot):**

```bash
python3 tests/test_0542_static.py
python3 tests/test_0541_pit_extraction.py
python3 tests/test_0540_math.py
```

**No Godot 4.7.2 / Linux Mint:**

```bash
bash linux/validar_core_0542.sh
```

O script realiza as verificações offline, a paridade do modo Clássico e a verificação da lógica de pneus em 20 GPs, inclusive chamadas e paradas no box com semente fixa.

Para inspeção visual, abra o projeto, selecione **Core 2** no menu, escolha **Spa** ou **Mônaco**, confira a oferta e execute uma parada com o segundo composto. Depois repita com **Clássico** para confirmar que seu comportamento antigo foi preservado.
