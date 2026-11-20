# APEX MOTORSPORT MANAGER — v0.6.3.7

## Rádio Reativo / Soul Driver
Base: v0.6.3.6, Godot 4.7.2 (07/11/2026).

- Pilotos da equipe do jogador podem iniciar comunicações **durante a corrida**, mesmo com a janela de rádio fechada.
- Mensagens originais em português motivadas por: eventos do motor (ultrapassagem/liderança, incidente, problema de pit), aumento do desgaste, mudança real de umidade da pista, dois giros com intervalo pequeno para o carro à frente, ou duas voltas com ritmo inferior à melhor marca registrada.
- Priorização por gravidade, cooldown por piloto e critérios de mudança/limiares para evitar spam e falas desconectadas do motor.
- Aviso compacto, clicável, perto do topo da HUD: abre a janela do rádio; expira após nove segundos reais. Mensagem continua no histórico depois que o aviso desaparece.
- Histórico separa PILOTO e ENGENHEIRO. Rádio interno nunca aparece no filtro de transmissão de TV. Alertas não criam dados inventados para adversários.
- Respostas do engenheiro são somente **consultivas**; nenhuma conversa executa box, muda pneu/ritmo ou cancela agendamentos.
- Perfis e memórias do diálogo v0.6.3.6 preservados; a memória de alertas é limpa entre GPs.
- Chuva, pneus, clima, geometria 2D/3D, motor, IA e regras de temporada 2012 **não foram alterados**.

## Arquivos
- NOVO: `scripts/core/race_soul_reactive_0637.gd` — lógica reativa determinística e sem acesso à referência mutável da corrida.
- EDITADO: `scripts/apex_race_hud_0622.gd` — ingestão de eventos, painel e aviso.
- EDITADO: `scripts/apex_commentary.gd` — histórico privado de rádio espontâneo.
- EDITADO: `scripts/main.gd` — título da janela.
- EDITADO: `project.godot` — versão, mantendo diretório de salvamentos fixo.
- NOVO: `tests/core_0637_reactive_radio_smoke_test.gd` e `tests/native_capture_0637.gd`.

## Limites
As falas e atributos da alma dos pilotos são ficcionais; **não** descrevem temperamentos reais. A reatividade usa eventos e médias por volta, não microfísica de cada curva ou síntese de voz. O motor de corrida e as ordens de box continuam independentes desta camada. Não há autonomia de STAFF nesta versão.
