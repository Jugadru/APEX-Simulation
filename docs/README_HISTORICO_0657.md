# APEX Motorsport Manager v0.6.5.7 — Performance Profiler 1.0

Abra `project.godot` no **Godot 4.7.2** e pressione F5. No Linux, `linux/run_apex.sh` usa o Godot instalado; também aceita `GODOT_BIN=/caminho/do/Godot`. A alternativa Compatibility continua disponível.

## Diagnóstico
- **F8**, ou Configurações → Performance Profiler 1.0, abre o painel.
- A coleta começa **desligada**. Ative “Coletar medições” e execute uma corrida.
- Desative para congelar agregados; “Limpar amostras” reinicia os dados.
- “Exportar JSON” grava `user://apex_performance_0657.json` e informa o caminho. Exportações substituem esse arquivo.
- Fechar o painel mantém o estado de coleta escolhido. Reiniciar o jogo desliga o profiler.

Tempos são CPU inclusivos; não some pais e filhos. FPS/memória são monitores Godot, não medição GPU ou RSS. O profiler não melhora desempenho automaticamente nem altera regras de corrida. Limpe os dados entre cenários.

## Documentação
- [Relatório técnico](RELATORIO_TECNICO_APEX_v0.6.5.7.md)
- [Medições e reprodução](docs/BASELINE_PERFORMANCE_0657.md)
- [Plano futuro](docs/PLANO_ENGENHARIA_FUTURO_0658_067x.md)
- [Pesquisa técnica](docs/PESQUISA_TECNICA_0657.md)
- [Auditoria](docs/AUDITORIA_0657.md)
- [README anterior preservado](docs/README_HISTORICO_0656.md)

Living Factory 2.0, Staff/Soul, Pit Wall, estratégia, simulação e apresentação 3D anteriores permanecem incluídos. Saves usam o mesmo diretório. Consulte o relatório para as limitações herdadas e o teste histórico de double stack que exige uma ordem de pneu válida.
