# Succubus Shop

**Uma loja de fantasia, clientes excêntricos e decisões comerciais questionáveis.** Succubus Shop é um jogo de gerenciamento e RPG em desenvolvimento, feito em Godot 4.7.2. A ideia é começar com uma pequena loja e evoluir até um império mágico por meio de planejamento, especialização, exploração e decisões econômicas.

O projeto prioriza conteúdo original, opções de acessibilidade e desenvolvimento com orçamento zero.

## Estado do projeto

**Protótipo jogável em desenvolvimento.** Já há fabricação e venda de produtos, clientes automáticos, ouro, reputação, melhorias, funcionários, eventos raros, conquistas, progressão por nível, pontos de talento e contratos de loja. A versão atual também inclui receitas desbloqueadas por nível. Ainda não é um lançamento final; interface, balanceamento e conteúdo precisam de mais testes.

## Como jogar

1. Instale o Godot 4.7.2.
2. Baixe ou clone este repositório.
3. Importe a pasta do projeto no Godot e abra `project.godot`.
4. Execute a cena principal com **F6/F5** ou o botão de executar projeto.

## Recursos atuais

- **Oito produtos no catálogo atual**, com três receitas desbloqueadas nos níveis 3, 5 e 8.
- **Clientes com personalidade**, falas próprias e preferências por produtos.
- **Economia de loja** com ouro, reputação, estoque, custos de fabricação, propaganda e produção automática.
- **Eventos raros** com consequências positivas ou negativas.
- **Progressão de RPG**: vendas, fabricação e eventos rendem experiência; subir de nível concede ouro, reputação e pontos de talento.
- **Três trilhas de talentos**, cada uma com até cinco níveis: Alquimia reduz custos, Comércio aumenta receita e Carisma acelera a afinidade.
- **Contratos rotativos** para atender clientes, faturar, fabricar ou encontrar eventos raros. As recompensas aumentam conforme os dias de loja avançam.
- **Diabrete estagiário** que produz poções automaticamente.
- **Reações dos clientes**: cada visita termina com o cliente *encantado* (comprou o item favorito: +1 de reputação), *satisfeito* ou *decepcionado* (loja sem estoque: -1 de reputação). O retrato do cliente reage com animação, a chefe responde com falas próprias e o talento Carisma dá chance de salvar a visita no charme.
- **Fregueses recorrentes**: cinco personagens nomeados podem voltar à loja; o progresso de amizade é salvo, há quatro níveis de vínculo, diálogos que mudam conforme a relação e falas especiais ao subir de nível. O painel lateral acompanha visitas, nível de vínculo e pedidos concluídos.
- **Pedidos pessoais**: fregueses conhecidos podem pedir seu produto favorito. Atender ao pedido rende bônus de ouro, experiência extra e mais amizade; o total de pedidos especiais concluídos por personagem fica salvo.
- **Missões de história dos fregueses**: ao alcançar 3 pontos de amizade, cada personagem inicia uma missão acompanhada por compras do item favorito. Três compras favoritas concluem o capítulo, concedem ouro escalável com o nível, +30 XP e +2 de reputação; progresso e capítulos concluídos são salvos.
- **Polimento visual da loja**: cartões de mercadorias com bordas violeta mais legíveis, cantos arredondados e sombra sutil para separar melhor os itens do fundo gótico.
- **Afinidade com a protagonista**, diálogos sugestivos e momentos especiais desbloqueáveis.
- **Sete conquistas** com recompensas.
- **Salvamento local** de progresso, nível, XP, talentos, contratos, estoque, melhorias e opções.
- **Compatibilidade de estoque por nome de produto** para que saves antigos preservem os itens que continuam no catálogo.
- **Opção de desativar o conteúdo sensual**, sem bloquear a progressão normal.

## Direção de longo prazo

A visão é construir uma experiência de longa duração, com sistemas que se alimentem entre si. Os itens abaixo são ideias para etapas futuras, não funcionalidades já concluídas:

1. **Capítulos e reputação por facção** — guildas, nobres, aventureiros, mercadores e criaturas do submundo.
2. **Árvore de talentos maior** — alquimia, negociação, encantamento, logística e relacionamento.
3. **Cadeias de produção** — ingredientes, receitas raras, qualidade, fornecedores e pesquisa.
4. **Clientes recorrentes e missões pessoais** — histórias, pedidos especiais e recompensas por relacionamento.
5. **Expansão comercial** — salas, funcionários, automação, filiais e investimentos.
6. **Economia dinâmica** — oferta e procura, eventos sazonais, reputação de marca e oportunidades de mercado.
7. **Exploração e aventura** — expedições para ingredientes e artefatos, com decisões e resultados variáveis.
8. **Campanha narrativa e finais** — alianças, segredos e escolhas comerciais.
9. **Prestígio opcional e desafios avançados** — objetivos de fim de jogo sem obrigar o jogador a recomeçar.
10. **Arte, áudio e animação originais** — retratos, expressões, efeitos e música com recursos gratuitos ou licenças verificadas.

A prioridade é implementar sistemas em etapas pequenas, testáveis e compatíveis com os saves anteriores.

## Conteúdo e direção criativa

A protagonista é uma personagem fictícia adulta. O protótipo usa humor e diálogos sugestivos, sem imagens explícitas. Futuras ilustrações serão originais ou terão licenças verificadas.

## Desenvolvimento

- Engine: Godot 4.7.2
- Linguagem: GDScript
- Objetivo: projeto gratuito, com conteúdo original e sem dependência de assets pagos.

O jogo está em desenvolvimento ativo; mecânicas, valores e interface podem mudar entre versões. Sugestões e contribuições são bem-vindas.