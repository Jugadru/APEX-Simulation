# Changelog — APEX v0.6.6.7.2.3

**High-Speed CPU Stabilization**

- Otimizador de stints: memoização mais barata e reutilização LRU exata de sufixos, com 28 contextos no máximo.
- Velocidades >=10x: limite de tempo de trabalho esportivo por quadro e dívida de simulação máxima em modo interativo.
- Indicador discreto `CPU` quando o fator solicitado não pode ser sustentado.
- Mantém simulação esportiva e arquivos de replay. Hashes históricos dos quatro GPs curtos preservados.
- Adicionados benchmarks reproduzíveis e relatório de desempenho.
- Picos pontuais de latência e limitação de aceleração real em 32x continuam documentados.
