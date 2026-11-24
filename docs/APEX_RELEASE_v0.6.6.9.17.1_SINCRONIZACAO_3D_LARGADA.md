# APEX Motorsport Manager — v0.6.6.9.17.1 — Sincronização 3D da Largada

**Escopo exclusivo:** corrigir a recuperação de poses atrasadas no 3D,
sem alterar o movimento esportivo, a classificação ou a estratégia.

## Regressão reproduzida

Na versão 9.17, o benchmark nativo de 24 carros, 125 atualizações visuais de
0,5 segundo por pista, detectou em **Mônaco, tick 34**, uma intersecção
entre carros ID 14 e 16. O carro 16 entrou em recuperação visual
(\`resynced=true\`) após dois bloqueios; o carro 14 precisou reter a
posição previamente aceita, gerando sobreposição na apresentação. O teste
também mediu três amostras consecutivas sem movimento visual em Mônaco.
Silverstone, Spa e Singapura não registraram sobreposição nessa fixture.

## Correção

- \`scripts/apex_racecraft_0654.gd\`: **apenas durante o resync**,
  a escolha da nova pose consulta tanto as novas poses já aceitas quanto as
  **poses anteriores dos carros ativos ainda não processados**.
  Estes últimos podem precisar congelar ou retornar à última pose válida
  no mesmo frame; não devem ser tratados como espaço livre.
- O solver calcula afastamento visual adicional quando a pose candidata
  invadir essas reservas, mantendo a mesma amostragem de pista, projeção e
  lógica preexistente de colisões.
- A verificação adicional só executa depois que um carro acumula dois
  bloqueios visuais; fora dessa recuperação, o algoritmo anterior permanece.
- Sem teleporte **esportivo**, sem alterar progresso, ritmo, combustível,
  pneus, posições, comandos, IA, RNG, replay, salvamentos ou box.
- O número de revisão esportiva de replay continua
  \`024_race_start_spatial_v1\`. Nenhum campo de save novo é adicionado.

## Validação obrigatória (não presumir aprovada)

1. \`tests/race_start_3d_sync_0669171_test.gd\`:
   quatro pistas reais (GBR, MON, BEL, SIN), 125 frames por pista,
   24 carros; zero sobreposições; no máximo duas amostras consecutivas sem
   deslocamento; todos visíveis; chamadas visuais não alteram hashes esportivos.
2. \`tests/visual_stutter_06672_benchmark.gd\`: regressão visual original
   que falhou no comparativo v9.9 × v9.17.
3. \`tests/racecraft_0654_test.gd\`: solver de segurança e trajetórias
   sintéticas, sem tunnelling.
4. FAST + Test Lab de Godot 4.7.2, replay e regressões dirigidas.
5. Exportação Linux e Windows e verificação do identificador 9.17.1 no PCK.

**Limites:** testes headless não provam FPS gráfico, desempenho de GPU ou
qualidade subjetiva da câmera e animação. A regressão visual deve ser
reavaliada no desktop, em especial em Mônaco e Silverstone.

**Rollback:** reverter apenas a mudança em
\`scripts/apex_racecraft_0654.gd\` e a identificação da release;
física e esquema de save não mudaram.
