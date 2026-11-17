# Apex Motorsport Manager 0.5.9.0 — Comando de Equipe (experimental)

**Base confirmada:** `Apex_0580_Completo(2).zip`, Godot 4.x. O pacote de HUD 0.6.0 experimental **não foi usado** para esta atualização.

## Escopo de 0.5.9.0

- Opção **Manual / Automático** antes do GP e na barra inferior durante a corrida, para os **dois pilotos da equipe escolhida**.
- **Manual:** o jogador decide ritmo, uso do KERS e box. Se desejar, ainda pode habilitar IA de boxes individualmente, recurso herdado da 0.5.8.0.
- **Automático:** a IA de pit da 0.5.8.0 é ativada para ambos os carros. Uma nova camada determinística seleciona ritmo e modo KERS em função de pneus, intervalo para o carro à frente, água na pista, previsão e staff contratado. A decisão só é revista em mudança de volta, desgaste, composto ou faixa de água.
- **Controle do jogador:** pode voltar ao Manual durante a corrida. Chamadas de box e paradas agendadas pelo jogador permanecem disponíveis mesmo no Automático; agendamentos manuais não são antecipados pelo planejador. O modo de ritmo e KERS é bloqueado no cartão durante o Automático para não fingir que a ordem permanecerá manual.
- **STAFF inicial da equipe:** Estrategista e Engenheiro com níveis 0–3 na Oficina; contratação/treinamento gasta orçamento existente e é salva no mesmo arquivo antigo da oficina. Compras não são feitas durante o GP. Os dois papéis influenciam decisões do ritmo/KERS; a IA de pit continua usando seu planejador herdado.
- Mudanças de ritmo ou KERS escolhidas pelo STAFF geram evento de estratégia no rádio/histórico.
- Títulos e nome do projeto atualizados para 0.5.9.0; resolução **1600×900** herdada, sem redesenhar a HUD neste patch.

## Preservado e verificado

Os seguintes arquivos foram comparados **byte a byte** com o ZIP original 0.5.8.0: `scripts/race_engine.gd`, `scripts/track_map.gd`, `scripts/track_3d.gd`, `scripts/tv_director.gd` e `data/season_2012.json`. O fluxo do KERS, DRS, pneus, pits, contatos e câmeras continua no motor original.

## Ainda não implementado

Mercado com candidatos individuais, contratos salariais recorrentes, desenvolvimento de relações humanas dos pilotos, rádio com voz, campeonato/temporada persistente e integração da HUD Full HD experimental. Estão fora do escopo desta primeira 0.5.9.0.

## Testes e limites

`tests/test_0590_static.py` e `tests/test_0580_static.py`: **passaram**. São verificações **estáticas**.

A bateria completa de 27 scripts Python produziu 21 sucessos e 6 falhas. Quatro falhas já estão no ZIP original 0.5.8.0 (checagens antigas de versão e referência externa inexistente). As outras duas são verificações antigas de hash de `garage.gd`, que mudaram intencionalmente ao incluir STAFF; não indicam, por si, uma regressão de física. Consulte `RELATORIO_0590_TESTES.md`.

**O executável Godot não está instalado no ambiente de montagem.** Não foi possível executar o projeto no Godot, testar visualmente a interface, nem confirmar comportamento em corrida completa. O smoke teste de Godot está incluído, mas pendente.
