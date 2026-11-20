# Alterações — v0.6.3.2 (07/11/2026)

Base: v0.6.3.1 — Rádio Inteligente, Godot 4.7.2.

## Funcionalidades

- Janela RÁDIO com seletor de um dos dois pilotos da equipe.
- Quatro perguntas rápidas: pneus, ritmo, tráfego e recomendação de box.
- Novo módulo `scripts/core/race_engineer_interactive.gd`, sem acesso mutável aos carros, retornando respostas baseadas no snapshot real e no plano de corrida do engenheiro.
- Nova identificação CHEFE no histórico, preservando ENGENHEIRO e o filtro TV (as conversas internas não são transmitidas).
- Histórico atualiza enquanto a janela permanece aberta.
- Analista: reanúncio da mesma mensagem de disputa limitado a uma janela de 210 s de simulação, além do intervalo global existente de 30 s. Eventos de ultrapassagem efetiva continuam disponíveis.

## Arquivos alterados

- `scripts/apex_race_hud_0622.gd`: somente janela/modal do rádio, seleção, botões e histórico.
- `scripts/apex_commentary.gd`: novos registros manuais CHEFE/ENGENHEIRO, filtro e controle de repetição por disputa.

## Arquivos novos

- `scripts/core/race_engineer_interactive.gd`
- `tests/core_0632_engineer_interactive_smoke_test.gd`
- `tests/native_capture_0632.gd`
- `LEIA_PRIMEIRO_0632.md`, `CHANGELOG_0632.md`, `RELATORIO_NATIVO_0632.md`

Os scripts do motor de corrida, 3D, câmeras, estratégias, circuitos e dados não foram modificados. Não foram incorporados modelos externos nem texturas de mods.
