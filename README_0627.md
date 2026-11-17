# APEX v0.6.2.7 — Como abrir e testar

1. Extraia `Apex_0627_DiretorTV_Cinematografico_Godot.zip` numa **pasta nova**, preservando `APEX_GODOT_0.6.2.7_TV_DIRECTOR`.
2. No Godot 4.7.2 do seu Linux Mint, importe `APEX_GODOT_0.6.2.7_TV_DIRECTOR/project.godot`.
3. Pressione **F5**, entre na temporada e inicie uma corrida. Em **Corrida → Visualização**, selecione **Diretor TV** (e câmera **Diretor** quando houver o seletor).
4. Compare as tomadas de duas disputas e observe pelo menos 30 segundos em 1× e 5×. O Diretor TV deve dar tempo para assistir a uma situação, não trocar a cada segundo.
5. Alterne **Seguir** e **Livre**. A câmera Livre deve continuar arrastando e navegando com WASD/setas; não deve mover a pista quando clicar num cartão.
6. Confira a estratégia de pneus e boxes de 2012; esta versão não muda o comportamento que foi aprovado na China.

### Teste no terminal

```bash
cd APEX_GODOT_0.6.2.7_TV_DIRECTOR
bash linux/validar_0627.sh
```

O script roda verificações Python. Com Godot instalado, executa também smoke tests headless do Diretor TV, da câmera Livre, da câmera anterior e da estratégia seca. **Renderização visual deve ser avaliada no editor**, pois não pode ser validada apenas no headless.

### Observações

- Tomadas **Battle/Corner/Trackside** são mais próximas da pista, mas continuam utilizando os gráficos simples atuais.
- Transições entre locais afastados são cortes intencionais, como numa transmissão. Transições dentro da tomada são suaves.
- Se houver erros vermelhos no Godot, capture a **primeira mensagem completa** e a linha correspondente do script.
