# Apex Motorsport Manager v0.5.8.0 — Comando de box, IA opcional e disputa lateral

Base: projeto Godot 0.5.7.0, mantida a temporada de 2012, 24 pilotos e 20 pistas.

## Implementado no jogo

1. **BOX AGENDADO POR VOLTA.** Cada cartão de piloto exibe um campo `VOLTA` e os botões `AGENDAR BOX` e `CANCELAR`. O composto escolhido é preservado. Agendar V21 **não** habilita a parada no pit de V4. O motor autoriza a entrada somente quando a posição real cruza a entrada do pit na volta agendada. A nova ordem pode ser cancelada ou substituída explicitamente pelo botão `CHAMAR BOX`.
2. **CONTROLE DE BOX: MANUAL / IA.** Cada piloto da equipe do jogador começa em **Manual**. Manual: o engenheiro apenas recomenda. IA: o planejador de stints existente pode chamar o piloto aos boxes quando identifica uma oportunidade ou desgaste crítico. Em ambos os modos, o agendamento manual tem prioridade: a IA não antecipa uma parada agendada. Essa escolha é configurável no cartão antes de iniciar a corrida, porque o grid começa pausado.
3. **TRILHA DE DECISÕES.** Rádio/eventos registram o agendamento, seu cancelamento, a substituição por ordem imediata e a execução na volta correta. O histórico de pits agora guarda `order_origin` (`agendamento_manual`, `ordem_imediata`, `ia_estrategia`, `ia_urgencia`).
4. **PRIMEIRA CAMADA DE DISPUTA LATERAL.** `scripts/core/race_battle_geometry.gd` introduz uma verificação determinística de espaço aproximado para dois carros no fim de uma disputa, considerando largura efetiva, afunilamento, defesa, percepção e tolerância a risco. Uma tentativa pode resultar em `clear` (ultrapassagem), `yield` (piloto desiste) ou `contact` (contato leve e perda de tempo). A perda de tempo é aplicada durante ticks posteriores, sem teletransportar carros para trás. Os eventos entram no rádio.
5. **PISTAS ESTREITAS.** Monaco, Singapura, Hungaroring, Valência e Suzuka recebem *coeficientes fictícios de espaço útil* para disputas. Esses valores **não** são a largura real, medida, desses circuitos. Os parâmetros podem ser substituídos por metadados `race_width_m` e `corner_convergence` no perfil da pista.

## O que ainda NÃO está implementado

- Não há colisão física real entre modelos 3D, dano por subsistema, acidentes múltiplos de largada ou intervenção de bandeira vermelha derivada de contato lateral. O contato `contact` afeta temporariamente ritmo e telemetria de eventos, não causa abandono nem penalidade.
- Não foi criado mercado de pilotos, contratação de chefes de departamento, personalidade histórica validada, engenheiro por voz ou trajetória lateral física contínua. Os novos parâmetros de percepção e risco são *valores neutros de gameplay* derivados do ID e skill, **não afirmações históricas sobre pilotos reais**.
- O prognóstico climático já existente continua sujeito a erro e deve ser tratado como recomendação.
- Nenhuma mudança foi feita na física de pneus, água, KERS, DRS, tempo de serviço nos boxes, geometria 3D ou regras históricas de 2012.

## Testes e execução

Testes offline executados neste ambiente: `python3 tests/test_0580_static.py`, mais 22 testes de regressão herdados da versão anterior. **Todos passaram.**

O ambiente de geração **não possui Godot instalado**. Portanto, não foi possível rodar/importar o projeto com o parser do Godot ou confirmar interações de UI em runtime. O jogo deve ser aberto e testado em uma instalação Godot 4.x do usuário.

No Linux, dentro da pasta do projeto:

```bash
python3 tests/test_0580_static.py
GODOT_BIN=godot bash linux/validar_core_0580.sh
```

Teste integrado diretamente:

```bash
godot --headless --path . --script res://tests/core_0580_pit_and_geometry_smoke_test.gd
```

Casos incluídos: V21 não executa em V4, executa ao entrar na V21, ordem inválida recusada, cancelamento, substituição explícita, manual não chama pit automaticamente, IA chama pit com desgaste crítico, IA respeita agendamento, largura livre, largura insuficiente, contato em caso de insistência e preservação de ultrapassagem normal.

Guarde o ZIP 0.5.7.0 como backup antes de experimentar a nova versão.
