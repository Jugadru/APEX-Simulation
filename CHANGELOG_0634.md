# Apex Motorsport Manager v0.6.3.4 — Rádio com memória e filtro por piloto

**Base preservada:** v0.6.3.3 no Godot 4.7.2. Desenvolvimento da HUD e da narrativa; sem alterações no motor físico da corrida.

## Implementações

- **Filtro individual:** botão `SÓ ESTE: NÃO/SIM` ao lado do piloto escolhido; aplica-se somente às categorias **Equipe** e **Pilotos**, permitindo escolher exatamente qual dos dois pilotos ouvir. Nas abas Todos/Transmissão, o filtro individual não é aplicado e fica desabilitado.
- **Identificação por carro no histórico:** mensagens do chefe, piloto, engenheiro e eventos da equipe mantêm `car_id` para seleção específica. Não expõe conversas de equipes adversárias.
- **Memória de contatos no rádio:** primeira consulta guarda somente a leitura anterior (tempo, temperatura, composto e desgaste). Nova consulta considera evolução desde a conversa anterior e reconhece troca de pneus ou perda objetiva de aderência; toques repetidos em até 30 segundos, sem mudança significativa, não criam novas mensagens.
- **Correção de resposta estratégica:** o engenheiro não informa uma volta de parada ultrapassada como janela futura. Mantém ordens de box explicitamente agendadas; responde com linguagem mais natural e indicação de incerteza.
- **Reinício seguro:** a memória de rádio e o filtro individual são reiniciados ao começar outro GP.

## Arquivos de código alterados

- `scripts/apex_commentary.gd`
- `scripts/apex_race_hud_0622.gd`
- `scripts/core/race_engineer_interactive.gd`
- `project.godot` (identificação da versão)
- Novo: `scripts/core/race_driver_memory_0634.gd`
- Novo: `tests/core_0634_radio_memory_smoke_test.gd` e `tests/native_capture_0634.gd`

## Invariantes

- Dados, pistas, motor 2012, estratégia de pneus, pit stops, IA, física, 3D, HUD compacta, câmeras Livre/Seguir/Diretor TV continuam com a mesma lógica de simulação.
- Não foi incorporado nenhum modelo externo de Assetto Corsa.
- Memória é **temporária e textual**, não um perfil psicológico factual de pilotos reais nem um sistema persistente de carreira.
- Nenhuma pergunta no rádio aciona pit stops, muda ordens ou altera desgaste.
