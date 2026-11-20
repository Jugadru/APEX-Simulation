# APEX Motorsport Manager v0.6.2.6 — Câmeras de corrida

**Base:** projeto completo v0.6.2.5 aprovado pelo usuário na corrida da China.
**Escopo:** câmera e direção de transmissão; sem alterações na física, IA estratégica, pneus, clima, regulamento ou campeonato.

## Mudanças

1. **Área 3D aérea dinâmica:** tomada adaptativa em `scripts/track_3d.gd`, com espaço à frente do carro e ajuste do enquadramento quando há outro piloto próximo na mesma parte da pista.
2. **Enquadramento de disputas:** nos ângulos Aérea, Battle, Chase, Corner, Trackside e Helicopter, a câmera usa o centro dos dois carros relevantes e amplia o campo conforme a distância entre eles. Corrige o caso em que o carro adversário era cortado pela câmera.
3. **Diretor TV:** `scripts/tv_director.gd` preserva prioridade para disputas e eventos. Nas voltas sem disputas relevantes, alterna ocasionalmente entre líder e pilotos da equipe do jogador, sem alterar nenhum comportamento da simulação.
4. **Câmera livre:** ao girar a roda do mouse ou arrastar para entrar em Livre, a câmera parte de onde estava olhando, sem saltar ao centro do circuito.
5. **Ajuste de zoom:** zoom manual durante acompanhamento permanece até o jogador alterá-lo, reiniciar a câmera ou mudar de visual; mudar a velocidade da corrida em modo fixo não deve reiniciar o zoom.
6. **Novas corridas:** iniciam com o Diretor TV disponível para encontrar atividade na pista, mesmo se a última sessão foi encerrada em modo Livre.
7. **HUD:** o layout, os cartões e a estratégia foram mantidos. A única alteração no script da HUD foi fazer a opção AÉREA 3D voltar ao acompanhamento automático, deixando a escolha Livre disponível separadamente.

## Arquivos modificados

- `scripts/track_3d.gd`
- `scripts/apex_race_view_controller.gd`
- `scripts/tv_director.gd`
- `scripts/apex_race_session_controller.gd`
- `scripts/apex_race_hud_0622.gd` — apenas seleção do modo de câmera
- `scripts/main.gd` — estado persistente de zoom e etiqueta de versão
- `project.godot` — identificação da versão

## Testes

- `python3 tests/test_0626_cameras_static.py`: **7/7** aprovados.
- `python3 tests/test_0612_indent_static.py`: inspeção de **97 scripts** aprovada.
- Testes numéricos de enquadramento: distância de 6 a 80 unidades entre carros na câmera aérea 16:9; ambas as posições projetadas ficam dentro da área segura em casos sintéticos.
- Arquivos de física, motor, IA de pneus, condições de pista e 2012: SHA-256 **idêntico** ao da v0.6.2.5.
- `tests/core_0626_camera_smoke_test.gd`: incluído para testar o seletor do diretor e a câmera na instalação do usuário.
- **Limitação:** não há executável Godot neste ambiente. Sem confirmação de parser nativo, de FPS ou renderização gráfica. A validação real acontece no Godot 4.7.2 do usuário.

## O que verificar no Godot

1. Abrir o projeto novo (sem misturar com pastas anteriores), pressionar F5 e iniciar China/Outra corrida.
2. Em **CORRIDA > AÉREA 3D**, acompanhar se a câmera mostra dois carros próximos em vez de ficar olhando áreas vazias.
3. Em **CORRIDA > DIRETOR TV**, observar alternância entre batalhas, aproximações, curvas e boxes. Disputas podem ter diferentes tomadas.
4. Em **CÂMERA > SEGUIR**, clicar num piloto na classificação e acompanhar seu carro.
5. Roda do mouse / arrastar a cena para Livre e verificar que não pula ao centro do circuito.
6. Pausa e velocidade 1×/5×/32×: a câmera não deve alterar a simulação.
7. Confirmar, por amostragem, que a IA mantém o comportamento corrigido em China e Melbourne.

**Não é atualização de gráficos/árvores/carros nem de HUD.** O objetivo é melhor fotografia virtual e seleção de cenas.
