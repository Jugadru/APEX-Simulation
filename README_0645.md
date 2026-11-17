# Apex Motorsport Manager v0.6.4.5
## Race Intelligence & Driver Soul — HUD UI03

Projeto Godot completo, baseado na v0.6.4.4. Abra `project.godot` com **Godot 4.7.2** e execute a cena principal (F6 na cena ou F5 no projeto).

No Linux, pode usar:

```sh
GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/run_apex.sh
```

Durante o GP, abra **ENG.** para ver estratégia, alternativas, confiança, previsão de retorno e Soul de cada piloto. **RÁDIO** mantém perguntas, discussão do stint e alinhamento com piloto/engenheiro, com leitura emocional adicional. Manual continua exigindo comandos; Assistido delega ritmo/KERS; Automático habilita decisões automáticas. Paradas agendadas permanecem protegidas.

Consulte `CHANGELOG_0645.md` e `RELATORIO_TESTES_0645.md`. Os documentos de versões antigas e `qa/` fora de `qa/0645/` são histórico herdado, não resultados desta entrega.

A bateria de oito GPs agora usa `step(0.20)` do motor de produção, com validação de cada incremento do relógio. Evidências completas ficam em `qa/0645/native_020/`; a execução anterior com passos de 8s é apenas histórica.

Para repetir os testes sem afetar seus saves:

```sh
GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_0645.sh
```

`BUILD_MANIFEST_0645.json` contém SHA-256 dos arquivos entregues (exceto o próprio manifesto). O arquivo SHA-256 ao lado do ZIP verifica o pacote. Projeto-fonte completo; executáveis Godot/Blender e caches de importação não estão incluídos. O Godot importa os recursos na primeira abertura.

## Validação de carreira

`linux/validar_carreira_0645.sh` executa as oito primeiras etapas consecutivas de uma mesma temporada, reiniciando o Godot entre elas e mantendo os saves em um diretório temporário isolado. Usa a cena principal e seus callbacks reais de carreira, oficina, controle automático e registro de resultados. Cada corrida avança por `step(0.20)`.

```sh
GODOT_BIN=/caminho/Godot_v4.7.2-stable_linux.x86_64 sh linux/validar_carreira_0645.sh
```

As evidências ficam em `qa/0645/career_native_020/`; cada etapa inclui cópias do campeonato e da oficina após salvar. Isso valida continuidade **entre GPs**, não um recurso de salvar e retomar uma corrida no meio da volta. O executor completo `linux/validar_0645.sh` também inclui essa bateria de carreira.
