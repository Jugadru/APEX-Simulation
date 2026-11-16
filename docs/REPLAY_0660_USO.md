# Replay v0.6.6.0 — uso e limites

Inicie uma corrida normalmente: a gravação começa no grid, depois de aplicar configuração e planos pré-corrida. Pressione **F9** durante a corrida para abrir o painel.

- **Ver gravação atual** abre uma cópia isolada do trecho já disputado. A sessão original fica preservada.
- **▶ / Ⅱ** reproduz/pausa. Feche a janela para usar as câmeras e a HUD normalmente. As velocidades existentes se aplicam à reprodução.
- **Ir ao tick** avança ou retrocede; são 5 ticks por segundo. O campo aceita apenas posições dentro do trecho gravado. Seek fica pausado ao concluir.
- **Exportar gravação** salva o replay no caminho indicado; o padrão é `user://apex_replay_0660.apexreplay`. O painel informa o caminho absoluto após salvar.
- **Abrir replay** valida o arquivo e só então troca a apresentação. Arquivo incompatível, inválido ou com checksum incorreto gera mensagem sem substituir a corrida ativa.
- **Voltar à corrida** restaura a sessão original. O replay não registra prêmios, salários, custos ou desgaste no inventário. Abrir gerenciamento também retorna à sessão original.

## Comandos e determinismo
Durante a corrida ao vivo, comandos esportivos entram na próxima fronteira de tick; em pausa ficam pendentes até continuar. A ordem de chegada decide o desempate entre comandos no mesmo tick. O motor revalida a ação no momento de executá-la: aceitação da fila não garante que uma parada continue possível se outra ordem a substituiu ou o carro entrou no box.

Autonomia, clima, decisões de pista e rádio periódico seguem o relógio da simulação. Autonomia é recalculada no replay a partir do estado gravado; não é duplicada por aplicação de um segundo log de decisões automáticas. A origem do comando de controle distingue Manual/Assistido/Automático.

Arquivos desta versão requerem a mesma versão do jogo e o mesmo runtime Godot. Não há garantia de identidade entre plataformas/arquiteturas nem conversão de replays de versões futuras. Saves de carreira anteriores continuam no diretório estável existente.

## Limites explícitos
- Checkpoint inicial e os oito mais recentes, a cada 60 s simulados. Para trechos mais antigos, seek pode reconstruir desde o início e demorar; a interface aguarda o processamento.
- Limite de 400000 ticks (aproximadamente 22,2 horas simuladas); gravação para com aviso ao atingir o limite.
- Importação até 256 MiB. O replay guarda estado completo, comandos e hashes, não vídeo.
- 32× é velocidade solicitada: se o computador não acompanhar, acumula atraso sem descartar tempo. Não é garantia de 32 segundos de corrida por segundo real.
- A normalização do passo modifica resultados em relação à 0659, que dependia do delta de cada frame. Igualdade é exigida entre execuções/replays da 0660 sob os mesmos inputs, não contra a física numérica variável anterior.
- Uma divergência detectada interrompe a reprodução e informa o primeiro tick divergente encontrado. Checkpoints também são conferidos ao restaurar.
