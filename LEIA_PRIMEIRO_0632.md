# Apex Motorsport Manager v0.6.3.2 — Engenheiro Interativo

## Abrir no Godot 4.7.2

1. Extraia o ZIP inteiro para uma nova pasta (não sobrescreva sua versão 0.6.3.1).
2. No Godot 4.7.2, escolha **Importar** e selecione `project.godot` da pasta extraída.
3. Pressione **F5**, escolha sua equipe e circuito, comece a corrida.
4. Clique **RÁDIO** no canto superior direito.
5. Selecione um dos dois pilotos da equipe e use os quatro botões: **Pneus**, **Ritmo**, **Tráfego**, **Box**.
6. A resposta aparece no painel e a conversa CHEFE / ENGENHEIRO entra no histórico. O rádio é ficcional e baseado no estado da simulação.

## O que permanece igual

Câmeras Livre / Seguir / Diretor TV, HUD compacta, corrida 2D/3D, todos os 20 GPs da temporada de 2012, motor de simulação, lógica de pneus, clima e ordens de pit stop. Mods externos de Assetto Corsa não foram incorporados.

## Limites

- Perguntas são solicitações de informação, **não comandos**. Nenhuma ordem de box é criada, antecipada ou cancelada por uma resposta.
- Os quatro assuntos são pré-definidos; não há reconhecimento de fala, áudio ou texto livre nesta versão.
- Recomendações são estimativas do simulador, não telemetria oficial de 2012.
- A adaptação visual de carros/mods de Assetto Corsa permanece um laboratório separado.

## Testar no terminal

```bash
./Godot_v4.7.2-stable_linux.x86_64 --headless --path /caminho/para/APEX_GODOT_0.6.3.2_ENGENHEIRO_INTERATIVO --script res://tests/core_0632_engineer_interactive_smoke_test.gd
```

Leia também `RELATORIO_NATIVO_0632.md`.
