# APEX Motorsport Manager v0.5.6.0 — KERS, DRS e Disputas de 2012

## Novidade nesta versão

- **KERS regulamentar de 2012 (simplificado):** até 60 kW de potência e 400 kJ de energia liberada por volta. O impulso é aplicado por tempo limitado e sua influência sobre o tempo de volta é um coeficiente de jogo, não uma simulação física do conjunto eletromecânico.
- **Histórico 2012:** Marussia Cosworth e HRT Cosworth ficam sem KERS. Caterham já utiliza KERS.
- **Modos de KERS por piloto:** Economizar, Equilibrado e Atacar. Clique no botão de KERS do cartão inferior de cada piloto para alternar. A troca é autorizada apenas para sua equipe.
- **DRS de corrida:** exige duas voltas completas, distância até o carro à frente de no máximo 1 segundo no ponto de detecção, circuito com DRS e ausência de bloqueio por chuva. O ganho se aplica somente durante a ativação.
- **Zonas de DRS:** as frações de pista são **esquemáticas para o jogo**, não coordenadas históricas oficiais. Melbourne tem duas janelas com um ponto de detecção compartilhado; Spa e Mônaco recebem apenas uma aproximação para a simulação.
- **Disputas:** o ganho momentâneo de KERS e DRS entra no cálculo de ritmo que alimenta os estados de ataque e defesa existentes. Não implementamos trajetória física roda a roda.
- **Telemetria:** a exportação de posições acrescenta KERS disponível, usado, modo, atividade e DRS ativo.
- **HUD:** mantém o botão CHAMAR BOX e BOX rápido nos cartões inferiores. Adiciona um controle de KERS e indicador DRS, sem duplicar as decisões no Pit Wall.

## O que NÃO mudou

- Física de chuva e as curvas I/W corrigidas na 0.5.5.1.
- Correção da IA para repor pneus W e I desgastados da 0.5.5.2.
- Sistema de boxes, fila e double stack; danos, câmeras, cenário 3D e dados de 20 GPs.
- Core 2 continua como único motor; não reintroduzimos o motor Clássico.

## Limites e validação

Os testes offline foram executados. Um teste de integração próprio do Godot verifica 60kW/400kJ, DRS após duas voltas, bloqueio por chuva, elegibilidade no detector e repetibilidade com a mesma semente. Ele **não foi executado no ambiente de construção**, pois o Godot não está disponível aqui. Execute `bash linux/validar_core_0560.sh` no Linux Mint.

## Referências históricas

- FIA, artigo de contexto KERS: https://www.fia.com/news/f1s-10-year-race-towards-ultimate-energy-efficiency
- Regulamento técnico de 2012 da FIA: https://argent.fia.com/web/fia-public.nsf/13C06BF289E0E36FC12579C9003CB5B9/%24FILE/1-2012%20TECHNICAL%20REGULATIONS%2009-03-2012.pdf
- Marussia e HRT sem KERS: https://www.autosport.com/f1/news/marussia-to-use-williams-kers-in-2013-f1-season-4457839/4457839/
- Melbourne 2012, duas zonas de DRS com detecção compartilhada: https://www.skysports.com/f1/news/12433/7596189/double-drs-for-albert-park
