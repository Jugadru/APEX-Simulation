# Apex Motorsport Manager v0.6.4.4 — Track Dynamics & Tyre Physics

## Base / preservação

Integrado **diretamente sobre `APEX_0643_DYNAMIC_TRACK_WEATHER_GODOT(1).zip`**, v0.6.4.3. A estrutura de 2012, oficina e P&D, evolução e orçamento das onze rivais, Core 2, Race Engineer, controle de pit automático/manual, rádio, KERS/DRS, câmeras e a correção de cronometragem não foram reconstruídos. O manifesto contém hashes SHA-256 idênticos dos principais arquivos preservados.

## Física da pista

- Novo estado independente `race_track_dynamics.gd`: asfalto com inércia térmica, evolução pela temperatura do ar, tipo de céu, intensidade de chuva, vento e carros circulando.
- Borracha (`rubber_fraction`) depositada pela circulação e lavada pela chuva, respeitando aderência por circuito e umidade residual. Água/chuva real segue sendo calculada pelo integrador **0.6.4.3**.
- Aderência (`grip_factor`) calculada com textura do circuito, borracha, temperatura, água, umidade. Afeta ritmo no mesmo motor Core 2 e a HUD recebe os valores verdadeiros do motor.
- `data/track_physics_2012.json` acrescenta a **20 circuitos de 2012** fatores de abrasividade, carga lateral, tração, drenagem, aderência inicial e taxa de depósito de borracha.
- Estes fatores são **parâmetros fictícios e ajustáveis de balanceamento**, não dados medidos de 2012, telemetria de pneus ou informações oficiais de FIA/Pirelli. Calendário e geometria preexistentes não foram alterados.

## Física dos pneus

- Novo módulo `race_tyre_thermal.gd`: temperatura da superfície e carcaça por composto e estilo de pilotagem, janelas ótimas próprias, graining a frio, blistering por superaquecimento, recuperação e penalidade de ritmo/desgaste.
- Estado térmico reiniciado somente em nova corrida, nova largada sob clima configurado ou troca real de composto durante o serviço no pit lane.
- Slick/inter: penalidade térmica adicional para intermediários/full wet em linha excessivamente quente/seca; os cruzamentos por água em mm e a histerese de 0643 continuam ativos e autoritativos.
- O controle por engenheiro continua **consultivo** em Manual; nenhuma chamada de box automática foi acrescentada a este módulo.

## HUD

- Centro de Dados: asfalto, borracha, aderência relativa, abrasão, temperatura da superfície e do núcleo dos pneus, graining e blistering.
- Painel direito de pneus: temperaturas e estados térmicos do piloto em foco.

## Testes

Scripts nativos Godot 4.7.2 na pasta `tests/` cobrem física determinística (20 perfis, chuva, seis compostos, slick/inter), tick nativo de 0,20 s, abertura da cena/HUD, regressões da 0.6.4.3, oficina/rivais, Race Engineer e hotfix de cronometragem. Bateria automática de oito GPs completos com 24 pilotos foi executada no laboratório em passos maiores de 8 segundos para reduzir custo; `step()` mantém **0,20 s** por subpasso no jogo. Resultados e limitações no relatório `RELATORIO_TESTES_0644.md`.

## Limitações e próximos ajustes

Modelo térmico fenomenológico, não simulação de termodinâmica de contato real, ausência de sensores por roda/eixo, setores com temperatura espacial, replays físicos e montagem de pneu; circuitos calibrados artesanalmente. Indicadores de pit stop devem continuar sendo avaliados com corridas reais e feedback do jogador; um teste automático concluído não comprova estratégias historicamente precisas.
