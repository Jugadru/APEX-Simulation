# APEX — HUD unificada

Abra `project.godot` no Godot 4.7.2 e execute a cena principal.

Interface escura com destaques laranja baseada nos esboços enviados. Equipe, pilotos, finanças, carreira, calendário, desempenho e contratos usam cartões com dados do jogo. Staff, menu, controles e HUD de corrida compartilham a paleta. P&D preserva pesquisa, compra, cancelamento e histórico.

Removidos os banners e logotipos em imagem. Retratos e downloads estão desativados, inclusive a leitura de imagens antigas do cache. Os arquivos pessoais já existentes não são apagados. Identificação por texto e iniciais; ícones genéricos de navegação permanecem. A pista e os carros 3D continuam funcionando.

Não foram adicionadas métricas fictícias: o orçamento usa R$, a pesquisa permite um projeto ativo, os pilotos têm elenco fixo e a tela financeira informa que não existe extrato mensal completo. Os esboços orientam a apresentação, não acrescentam automaticamente novas mecânicas.

Correções: recalcular tamanho dos painéis de staff e clima após a disposição do texto, evitando expansão fora da tela.

Validação: navegação, dados da equipe selecionada, ausência de fotos/logotipos visíveis, abertura da corrida, pesquisa/compra/reembolso/entrega, contratos e modelo Soul Staff. Capturas atuais em qa/unified. Motor e regras de simulação preservados.
