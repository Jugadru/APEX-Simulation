# APEX v0.6.6.9.17.2 — Largada Competitiva

**Estado:** candidata até provar impacto real em pista e segurança no Godot 4.7.2.

## Problema medido
Na v9.17.1, A/B contra o mesmo build com start20 desligado não encontrou uma única mudança de posição em 8 cenários até 120 segundos. A física de congestionamento só adicionou custo de tempo.

## Implementação
- Grid 2012 de duas colunas escalonadas, quando o solver RaceSpace confirma dois corredores inteiros. Pistas estreitas mantêm a formação linear antiga.
- A primeira curva permite preparar ataques baseados em ritmo, habilidade, charge e espaço livre. RaceSpace continua com a autoridade de progressão e não cria posições, impulsos ou teletransporte.
- O corredor inicial é mantido no período de largada, e retornos para a linha são mediados pelo solver de colisões e tráfego.

## Compatibilidade
- Revisão esportiva nova: 025_competitive_grid_start_v1.
- Replays 024 mantêm grade original e algoritmo 9.17 sem esta regra; 023 e anteriores preservam os demais contratos históricos.
- Flag de sessão competitive_start_enabled não entra no save/hash; checkpoints preservam os valores oficiais de progresso e corredor.

## Homologação obrigatória
- Teste real 24 carros × GBR/MON/ITA/BEL × Seco/Chuva intensa × mesma seed, modo novo versus 9.17.1.
- Verificar classificação aos 18/60/120 segundos, tentativas e ultrapassagens verdadeiras, pelo menos uma alteração de posição em cenários seguros.
- Replay novo 025 e histórico 024 devem reproduzir todos hashes; BOX V21 deve permanecer protegido.
- Antigos testes de segurança visual (Monaco/Silverstone/Spa/Singapura) precisam seguir com zero sobreposições e no máximo dois quadros estacionários consecutivos.

## Limites
A simulação é esquemática e não tenta recriar telemetria real da FIA. Testes headless não são benchmark de GPU/FPS nem substituem a inspeção visual jogável.
