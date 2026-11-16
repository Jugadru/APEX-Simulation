# Testes e instruções — Apex 0.6.2.0 HUD

## Como abrir no Linux Mint / Godot 4

1. Descompacte o ZIP **inteiro** numa pasta nova, sem misturar com v0.6.1.1 ou v0.6.1.2.
2. Abra o Godot 4, selecione `Importar` e escolha `project.godot` na pasta `APEX_GODOT_0.6.2.0_HUD_REWORK`.
3. Abra a cena principal e pressione **F5**. Escolha equipe e corrida, e clique em Iniciar.
4. A pista deve abrir na visão aérea 3D. No rodapé, `MAPA 2D` muda para o traçado estratégico. `DIRETOR TV` retorna ao acompanhamento automático.
5. Nos cartões dos dois pilotos, clique nos botões **T, D, E, C**: os detalhes devem abrir **para cima**. Clique novamente ou no `×` para recolher. Cada piloto pode manter seu contexto individual aberto.
6. Nas setas da classificação, alterne entre **INTERVALO, LÍDER, PITS, MELHOR VOLTA, PNEUS**. `M 18` significa pneu Médio há 18 voltas (tempo de stint, não porcentagem de desgaste).
7. Teste `ESTRAT.` no topo: timeline com histórico real de stints e pit marcado; selecione pneu e agende volta. `BOX` no cartão é ordem imediata, não agendamento.
8. Teste pausa, velocidades `1×..32×`, clima e minimapa. Confira resoluções **1600×900** e **1920×1080**.

### Comandos úteis

- `Espaço`: pausa / retoma.
- `I`: alterna a métrica da classificação.
- `M`: alterna mapa 2D / aéreo 3D / diretor TV.
- `C`: abre/fecha central Corrida.
- `V`: recolhe os painéis de ambos os pilotos.
- `Tab`: esconde/mostra a HUD (modo cinema).

### Validação nativa via terminal (na pasta do projeto)

```bash
bash linux/validar_0620.sh
# Ou exclusivamente teste de carregamento do Godot:
godot --headless --path . --script res://tests/core_0620_hud_smoke_test.gd
```

Se Godot registrar **Parse Error**, copie a primeira linha com `res://...` e o número da linha, preferencialmente acompanhada de captura do painel de erros. O script estático não substitui o compilador do Godot.

## Resultados efetivamente verificados aqui

- 71 arquivos `.gd` verificados quanto à indentação: **PASS**.
- Teste estático novo da HUD: **PASS**.
- Delimitadores estruturais em `main.gd` e dois scripts novos: **PASS**.
- Conteúdo do motor de corrida, IA, pneus, previsão meteorológica, campeonato, garagem, circuito 2D e minimapa: **inalterado** em relação ao ZIP v0.6.1.2.
- `tests/run_all_static.py`: **24/33**. As nove falhas não demonstram, por si só, erros de parser ou física. Incluem hashes rígidos antigos de `track_map.gd` que já diferiam da v0.6.1.2, testes de strings de HUD substituídas e uma verificação que exige diretório absoluto indisponível. **Não ocultar essas falhas.**
- Importação, renderização 3D, eventos de clique, áudio e execução completa no Godot **NÃO TESTADOS** (binário Godot ausente no ambiente de criação).

## Pendências para revisão futura

- Sistema de danos de peças e telemetria profunda ainda não existe no motor e deve ser implementado antes de colocar números na aba Carro.
- Forecast de posição após pit, estratégia A/B/C editável e comparação precisa de tráfego dependem de cálculo real no motor.
- Verificação visual de clipping em diferentes resoluções e com os dois painéis expandidos depende do seu teste no Godot.
- Regressões conhecidas de IA de pits e pneus permanecem fora do escopo desta versão.
