# APEX Motorsport Manager — v0.6.2.7 — Diretor TV

**Base:** v0.6.2.6.1 (câmera Livre validada pelo usuário).

## Objetivo
Melhorar a variedade e o enquadramento das tomadas do Diretor TV sem alterar a HUD, a câmera Livre, o modo Seguir ou o motor de corrida.

## Alterações implementadas

1. **Ângulos de transmissão:** câmeras Battle, Corner e Trackside menos verticais, com distância e FOV adaptados à separação real entre os carros. Helicopter foi ajustada para fornecer contexto sem dominar a transmissão. A câmera Chase, usada pelo Seguir, manteve seus parâmetros geométricos.
2. **Dois carros no quadro:** no Diretor TV, a segunda posição só é usada se os pilotos estão próximos no progresso da corrida e não estão nos boxes; se não houver rival próximo, o modo Battle volta ao enquadramento do carro selecionado.
3. **Seleção do Diretor TV:** disputas e acontecimentos continuam prioritários. Adicionada checagem de proximidade por segmento de volta (quando disponível); rodízio de planos com mais tomadas baixas e uso ocasional da vista aérea.
4. **Ritmo dos cortes:** o Diretor TV utiliza um relógio de exibição (segundos reais com corrida em execução). Velocidades de 1×, 5× e 32× não encurtam os intervalos entre tomadas. Presets Ação e Transmissão mantêm as cenas por aproximadamente 9 e 13 segundos, respectivamente, salvo eventos de prioridade muito alta.
5. **Mudanças de setor:** se o foco muda para um carro muito distante, a câmera corta para o novo local em vez de voar sobre grama vazia. Dentro da mesma disputa, suaviza posição, alvo e campo de visão.
6. **Câmera Livre preservada:** movimento do mouse, arraste, WASD, bordas da tela e zoom permanecem exatamente com o tratamento anterior.

## Arquivos existentes alterados
- `scripts/tv_director.gd`
- `scripts/track_3d.gd`
- `scripts/apex_race_view_controller.gd` (somente ligação com o Diretor TV e validação do segundo piloto)
- `scripts/main.gd` (somente etiqueta de versão)
- `project.godot` (versão e descrição)

## Novos arquivos
- `tests/test_0627_broadcast_static.py` — verificações estáticas independentes, portáteis e geométricas
- `tests/core_0627_tv_director_smoke_test.gd` — teste nativo para Godot 4
- `tests/0627_base_preserved_sha256.json` — verificação portátil dos arquivos herdados
- `tests/0627_free_camera_functions_sha256.json` — assinaturas das funções de mouse/livre
- `linux/validar_0627.sh`
- `README_0627.md` e `RELATORIO_0627.md`

## Não incluído
- Novos modelos 3D, pista, arquibancadas, físicas ou animações.
- Alteração das decisões de box, regulamento de pneus, telemetria ou tempos.
- Falso evento de ultrapassagem: a câmera utiliza o progresso fornecido pelo motor, sem inventar acontecimentos.
