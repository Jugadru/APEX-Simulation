# APEX v0.6.3.6 — LEIA PRIMEIRO

## Como abrir no Godot 4.7.2 / Linux Mint

1. **Extraia o ZIP inteiro** em uma pasta nova. Não abra o ZIP diretamente no editor.
2. Abra Godot 4.7.2 > **Importar** > selecione `APEX_GODOT_0.6.3.6_SOUL_DRIVER/project.godot`.
3. Clique em **Importar e editar** e pressione **F5**.
4. Selecione uma equipe e um circuito, inicie o GP e abra **RÁDIO** (canto superior direito).
5. Escolha o piloto > **DISCUTIR STINT**. Depois selecione **APOIAR PILOTO** ou **PRIORIZAR DADOS**.
6. Observe o indicador ficcional de confiança e sensação de pneus; depois de uma evolução dos dados ou de 60 segundos simulados, faça nova discussão para ouvir uma resposta com memória.

**Importante**: apoiar o piloto ou priorizar dados é só uma **resposta no rádio**, não uma ordem de pit. Para mudar a corrida, use os controles de estratégia existentes.

## Conteúdo do pacote

O pacote contém **projeto inteiro**, incluindo cenas, scripts, assets, 20 circuitos, equipes/pilotos de 2012, motor, HUD, testes e relatórios. A versão 0.6.3.5 não precisa ser substituída: mantenha como backup.

## Teste opcional no terminal

Dentro da pasta do projeto, com o Godot no PATH:

```bash
godot --headless --path . --script res://tests/core_0636_soul_personality_smoke_test.gd
```

Em sucesso aparece `APEX 0636 PASS`.

**Ficção**: parâmetros Soul não são declarações sobre a personalidade real de Fernando Alonso, Felipe Massa ou qualquer piloto histórico.
