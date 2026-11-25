# APEX 9.20.1 — Driver Traffic Intelligence 2.0
Base 9.20, merge c552c9d9. Exceção explícita do responsável: uma única mega atualização antes de Driver Error & Recovery 9.21. Revisão 039; 038 e anteriores preservadas. Não altera regras globais de homologação.
## Escopo 1–13
1. Consciência espacial: leitura física de frente, traseira, lado e grupos, horizonte por awareness/foco.
2. Previsão: ritmo de volta observado / taxa real suavizada, tempo de alcance e preparação limitada vinculada ao alvo. Não usa desgaste oculto do rival.
3. Trens DRS: cadeia de >=3, >=2 com DRS elegível/ativo, pista permite; decisões de esperar e conservar energia para IA equilibrada. Sem rearmar DRS/KERS.
4. Tráfego: carros lentos por ritmo, companheiro, retardatário, entrada/saída de boxes observável, terceiros. Não há diagnóstico mecânico oculto; lentidão observada é tratada genericamente.
5. Multi-car: previsão de varredura para veto de novo ataque no grupo; não força ultrapassagem.
6. Ar limpo: alívio longitudinal até 2,5% de pace-denominador, sem nova direção; custo esportivo e pequena redução de desgaste/temperatura quando realmente aplicável. Ataque/defesa, pressão traseira, estreitamento, chuva intensa e modo Atacar protegem comportamento.
7. Bandeiras azuis: transferência de reserva recente para próximo líder após passagem física do anterior, mesmo lado, mantendo solver e veto de terceiros.
8. Estratégia: projeções agora/+1/+2, posição esportiva e densidade física separadas; qualidade do estrategista informa confiança consultiva; única extensão automática +1 em condições secas estritas e sem ordem manual/urgência/fila/última janela.
9. Personalidade: awareness, foco e tolerância de risco existentes; paciência derivada, não novos atributos arbitrários.
10. Rádio fictício do jogador ligado a grupo/DRS/temperatura/companheiro/retardatário, resfriamento de 2 voltas e prioridade de mensagens já existentes. Sem comandos implícitos.
11. Estados FREE_AIR, APPROACHING, ASSESSING, FOLLOWING, TRAIN, WAIT, PREPARE, COMMIT, CLEAN_AIR, CLEAR, PIT. Métricas de tempo livre/congestionamento, atraso estimado por alívio/solver, veto e passes confirmados em grupo, amostras de cessão/transferência; estado esportivo por carro, não schema novo.
12. Todas as submecânicas agrupadas na 9.20.1; 9.21 permanece para erros. Módulos de percepção/decisão e estratégia/radio, solver existente soberano.
13. FAST + Lab + regressões direcionadas, 12 A/B 038/039, fixture 24 carros com efeito longitudinal observado, grupo/DRS, pit, chuva, personalidade, reserva múltipla, rádio, histórico 038 e determinismo. Não declarar êxito antes da CI. Sem FULL obrigatório, teste GPU, imagens privadas ou binário. Coeficientes heurísticos; previsões não são garantia de posição. Sem comparação causal de GPs inteiros nem calibração FIA. Rollback c552c9d9.
