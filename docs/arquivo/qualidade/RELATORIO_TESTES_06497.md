# RELATÓRIO TÉCNICO — APEX v0.6.4.9.7
## Coordenação automática preventiva dos dois pilotos — 09/11/2026

**Base:** v0.6.4.9.6 completa; **Godot:** 4.7.2.stable.official.ed1daf0bf (Linux).
**Regra do desenvolvimento:** uma funcionalidade principal por versão.

### 1. Defeito / limitação atacada
Antes, o sistema só reconhecia em muitos casos o double stack quando um companheiro já tinha pedido box, estava usando a garagem ou estava chegando à entrada. Duas paradas ainda previstas para a mesma volta nem sempre eram coordenadas antes da primeira chamada.

### 2. Implementação
`race_team_pit_coordination_06497.gd` compara janelas previstas pelo planejador de ambos os carros da mesma equipe. O piloto com melhor posição tem prioridade estável (ID desempata); o outro pode adiantar em uma volta ou, em uma janela segura, adiar em uma volta. Apenas em pista seca estável, com compostos válidos, desgaste e vida dos pneus suficientes, sem ordem em andamento, sem marca de adiamento e sem estratégia já alterada por outra camada no mesmo stint.

**Não é uma proibição geral de double stack:** uma chamada crítica, chuva, ordem manual e falta de margem de pneus continuam prevalecendo. Os módulos de pneus, física, calendário, cronômetro, motor de clima, Staff, Soul e a antiga IA por volta continuam intactos.

### 3. Comparação reproduzível da integração
Circuito **Silverstone**, seed 6403, pista seca, estado controlado com os dois Ferrari programados pelo planejador para **V16**:
- **v0.6.4.9.6:** nenhum box antecipado naquele instante.
- **v0.6.4.9.7:** Massa (prioridade menor no cenário) recebeu `pit_request` automático de **V15**; Alonso manteve sua janela V16.
- Pedido manual, V21, chuva intensa e nova ordem repetida foram rejeitados conforme as proteções. Ver `tests/team_pit_06497_before_after.gd` e `tests/team_pit_06497_integration_test.gd`.

O cenário controlado utilizou perfil de desgaste artificialmente configurado para testar o gatilho do sistema; **não** é prova de redução de filas num GP completo.

### 4. Testes realizados

- **13 testes direcionados/regressivos aprovados**, entre eles Pit Wall 06491, Double Stack 06492, pneus 06493, confiança 06494, Race Engineer 0646, Soul 0647, Staff 0648 e revisão por volta 06496. Logs: `qa/06497/`.
- Teste de coordenação: **16 verificações** sobre prioridade, antecipação, adiamento, vida útil, V21, modo Manual, chuva, ordem urgente, pureza e rearmamento após novo stint.
- Teste de integração com motor real: **PASS**, antecipação V16→V15 apenas para o piloto secundário.
- Interface gráfica real Xvfb/Mesa: **PASS**, 1600x900 e 1920x1080; leitura não envia pit.
- Importação/editor do Godot: **PASS**, saída 0, sem erros de parser.

### 5. GPs completos de validação

| GP | Clima | Voltas | Classificados | Pits | Filas de garagem | Vencedor | Novas alterações automáticas | Erros |
|---|---|---:|---:|---:|---:|---|---:|---:|
| Silverstone (GBR), seed 6403 | Variável | 52 | 24 | 78 | 3 | Fernando Alonso | 0 | 0 |
| Monza (ITA), seed 6503 | Seco | 53 | 24 | 24 | 0 | Sebastian Vettel | 0 | 0 |

Ambas foram completas com `sim.step(0.20)` e 24 pilotos. Os totais de paradas são iguais aos relatados na v0.6.4.9.6 nessas condições. **Nenhuma oportunidade elegível de nova antecipação/adiamento ocorreu nessas duas provas**, logo não há ganho esportivo comprovado em GP completo. A correção mantém comportamento conservador e atua quando a combinação de janelas e segurança permite.

**Problema ainda aberto em Silverstone:** três filas da garagem nas paradas da volta 14 (aprox. 6,42s, 6,70s e 6,80s). Podem estar ligadas a tempo crítico/chuva e não são declaradas resolvidas nesta versão.
Em Monza não houve espera de garagem detectada.

### 6. Limites
- Não houve três ou oito GPs completos nesta entrega: somente Silverstone e Monza.
- Previsão de janelas é uma estimativa da IA no estado presente, sem conhecimento perfeito de tráfego ou incidentes futuros.
- A screenshot de interface em `docs/APEX_06497_COORDENACAO_PITWALL_1600.png` usa uma **mensagem ilustrativa de cenário de teste** para conferir renderização, não um evento espontâneo capturado em GP.
- Renderização virtual/Mesa não mede FPS em GPU do usuário. Ambiente de áudio sem dispositivo ALSA recorreu ao driver dummy.
- Esta atualização não corrige a frequência de pit stops de Singapura nem muda a confiança estratégica.

### 7. Arquivos de produção alterados
- `scripts/race_engine.gd` — invoca coordenação ao montar ordem da IA.
- `scripts/core/race_team_pit_coordination_06497.gd` — novo algoritmo isolado.
- `scripts/apex_race_hud_0622.gd` — apresenta justificativa textual.
- `project.godot` — versão e saves separados.
- Demais fontes de produção preservadas.

### 8. Reexecutar
Na pasta extraída:

```sh
GODOT_BIN=/caminho/para/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_06497.sh
```

Para também repetir os GPs completos (pode demorar, CPU intensiva):

```sh
APEX_RUN_FULL_GP=1 GODOT_BIN=/caminho/para/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_06497.sh
```

Saves da v0.6.4.9.7 usam `APEX_06497_AUTO_TEAM_PIT`, evitando sobrescrever os da versão anterior.
