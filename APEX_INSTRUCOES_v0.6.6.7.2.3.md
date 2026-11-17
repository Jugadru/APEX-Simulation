# Instalação — v0.6.6.7.2.3

1. Descompacte o ZIP completo em um diretório **novo**, sem mesclar arquivos com versões antigas.
2. Abra o `project.godot` no Godot 4.7.2 Linux e execute a corrida.
3. No modo **Auto**, 1x–5x continuam no 3D; 10x, 16x e 32x usam o mapa 2D.
4. Observe a indicação `CPU` junto ao cronômetro: informa que a velocidade efetiva é inferior à solicitada, por limitação de processamento. O jogo não descarta resultados esportivos nem pula ticks.
5. Para medir seu computador, use **F8 → Coletar medições → Exportar JSON**. Compare 10x / 16x / 32x após 5+ voltas em Monza e Spa. Jogue fora do editor se ocorrer `BadWindow` na janela embutida.
6. **Rollback:** mantenha o ZIP integral da v0.6.6.7.2.2 em pasta separada. Saves antigos não são modificados pelo hotfix.

## Limites

- A aceleração efetiva em 32x pode ser menor do que a solicitada; evitar engasgos não significa alcançar 32x reais na CPU disponível.
- Ainda podem ocorrer picos de quadro ao recalcular estratégias ou atualizar HUD; estes requerem perfil em hardware real.
- As regras de disputa, física e código do motor de corrida não foram alterados.
