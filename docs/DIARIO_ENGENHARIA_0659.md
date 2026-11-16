# Diário — 0.6.5.9

1. Base extraída do ZIP 0658, SHA256 47397b549c85639792e302e5c896ee4cfa0dc0c1137677b69dc1f9c6fc167840, CRC e 1855 entradas do manifesto conferidos. Release anterior preservada.
2. Plano mestre unificado e plano técnico 0659 adotados; motor esportivo e HUD fora do escopo de alteração.
3. Investigação repetiu 0657 versus 0658 em fullscreen 1920×1080, três pares alternados. Nesta série, 0658 ficou mais rápida; a queda anterior não se reproduziu. Não se determinou uma causa física/ambiental definitiva. A evidência anterior continua válida como observação, não como prova de regressão sistemática do código.
4. Perfil localizou aproximadamente 4 ms/frame em projeção 3D. Cada carro buscava segmento em toda a rota a cada frame. Optou-se por índice exato por blocos, sem heurística que pudesse escolher ramo incorreto em cruzamento.
5. Teste de equivalência escrito antes dos novos módulos; 6000 consultas nos 20 circuitos, emenda, progressões negativas/múltiplas voltas, deslocamento lateral aleatório, segmentos degenerados e empates. 400400 candidatos contra 4056000 da varredura completa, com mesmo segmento e posição longitudinal.
6. Cache preserva acumulados Float32 e direção por diferença central. Não se substituiu direção por tangente de um único segmento. Correção de invalidação inclui trocar a pista enquanto a apresentação está pausada.
7. Argumentos default de get avaliavam consultas 3D desnecessárias; substituídos por seleção condicional. Sem alterar mesh, física ou efeitos.
8. Regressões incluem ocupação contínua em 1×/16×, transição de sessões/vistas, gerenciamento, oficina, saves e profiler. Benchmarks nativos sequenciais só começaram após terminar essas regressões, para não concorrer por CPU.
9. Investigação de artefato visual usa ablações temporárias de sombras somente no script diagnóstico. Alterações de diagnóstico não são aplicadas ao jogo por padrão; conclusão registrada no relatório final.

## 14/11/2026 — Encerramento
28 scripts selecionados e importação aprovados; sete paridades idênticas; GP de 52 voltas aprovado. Compatibility nativo aprovado, com artefato herdado ainda visível. Ablação de sombras em trecho diferente é inconclusiva. Relatório e benchmark consolidados; próxima etapa é manifestar, extrair e testar o ZIP, com resultado em verificação externa.
