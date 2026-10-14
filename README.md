# Succubus Shop

**Uma loja de fantasia, clientes excêntricos e decisões comerciais questionáveis.** Succubus Shop é um jogo de gerenciamento e RPG em desenvolvimento, feito em Godot 4.7.2. A ideia é começar com uma pequena loja e evoluir até um império mágico por meio de planejamento, especialização, exploração e decisões econômicas.

O projeto prioriza conteúdo original, opções de acessibilidade e desenvolvimento com orçamento zero.

## Estado do projeto

**Protótipo jogável em desenvolvimento.** Já há fabricação e venda de produtos, cadeia de produção com ingredientes e qualidade, economia reativa, clientes automáticos, expedições, santuário de relíquias, cartas colecionáveis, campanha em sete capítulos com tela final, conquistas, placar de pontuação, integração opcional com a Steam e progressão por nível, pontos de talento, contratos de loja e reputação por facção. Ainda não é um lançamento final; interface, balanceamento e conteúdo precisam de mais testes.

## Como jogar

1. Instale o Godot 4.7.2.
2. Baixe ou clone este repositório.
3. Importe a pasta do projeto no Godot e abra `project.godot`.
4. Execute a cena principal com **F6/F5** ou o botão de executar projeto.

## Recursos atuais

- **Doze produtos no catálogo atual**, com receitas presas ao nível que a biblioteca adianta por ouro.
- **Clientes com personalidade**, falas próprias e preferências por produtos.
- **Economia de loja** com ouro, reputação, estoque, custos de fabricação, propaganda e produção automática.
- **Eventos raros** com consequências positivas ou negativas.
- **Progressão de RPG**: vendas, fabricação e eventos rendem experiência; subir de nível concede ouro, reputação e pontos de talento.
- **Quatro trilhas de talentos**, cada uma com até cinco níveis: Alquimia reduz custos e melhora a qualidade, Comércio aumenta receita e barateia receitas, Carisma acelera a afinidade e salva visitas, Logística encurta expedições e abre a segunda vaga de batedor.
- **Contratos rotativos** para atender clientes, faturar, fabricar ou encontrar eventos raros. As recompensas aumentam conforme os dias de loja avançam.
- **Diabrete estagiário** que produz poções sozinho, mas gasta matéria-prima da despensa: sem ingrediente ele não inventa nada, para a contratação não transformar a forja e o mercado em enfeite.
- **Reações dos clientes**: cada visita termina com o cliente *encantado* (comprou o item favorito: +1 de reputação), *satisfeito* ou *decepcionado* (loja sem estoque: -1 de reputação). O retrato do cliente reage com animação, a chefe responde com falas próprias e o talento Carisma dá chance de salvar a visita no charme. Quando a prateleira está vazia, quem reclama é um dos fregueses conhecidos: cada um dos nove tem uma queixa escrita para esse momento, e ela aparece no registro da loja.
- **Fregueses recorrentes**: nove personagens nomeados podem voltar à loja; o progresso de amizade é salvo, há quatro níveis de vínculo, diálogos que mudam conforme a relação e falas especiais ao subir de nível. O painel lateral acompanha visitas, nível de vínculo e pedidos concluídos.
- **Pedidos pessoais**: fregueses conhecidos podem pedir seu produto favorito. Atender ao pedido rende bônus de ouro, experiência extra e mais amizade; o total de pedidos especiais concluídos por personagem fica salvo.
- **Missões de história dos fregueses**: ao alcançar 3 pontos de amizade, cada personagem inicia uma missão acompanhada por compras do item favorito. Três compras favoritas concluem o capítulo, concedem ouro escalável com o nível, +30 XP e +2 de reputação; progresso e capítulos concluídos são salvos.
- **Reputação por facção**: guildas, nobres, aventureiros, mercadores e o submundo lembram negócios concluídos. Cada venda aumenta o prestígio da facção do cliente; quatro níveis (Desconhecida, Notada, Respeitada, Lenda) dão bônus de preço de 0% a 20%, ouro ao subir de patamar e duas conquistas novas. Saves antigos começam com todas as facções em zero.
- **Polimento visual da loja**: cartões de mercadorias com bordas violeta mais legíveis, cantos arredondados e sombra sutil para separar melhor os itens do fundo gótico.
- **Afinidade com a protagonista**, diálogos sugestivos e momentos especiais desbloqueáveis.
- **Fúria com preço no balcão**: cada ponto de fúria derruba 5% do valor da etiqueta (até -25%) e, a partir de dois pontos, também corrói a paciência do cliente. O painel mostra a penalidade, e dissipar a fúria no santuário volta a valer alguma coisa.
- **Afeição que transborda em reputação**: com o coração da chefe cheio (100), o excedente de afinidade não é jogado fora — cada 5 pontos de sobra vira +1 de reputação. Momentos privados contam para a pontuação do império e rendem a conquista correspondente.
- **Cadeia de produção com qualidade**: seis ingredientes básicos com mercado próprio mais duas raridades que só saem de expedição. Cada peça fabricada recebe um de cinco níveis de qualidade (Comum, Boa, Refinada, Prima, Mítica) conforme talento, biblioteca e sorte, e a qualidade muda preço, reputação e o visual do cartão no balcão.
- **Economia dinâmica reativa**: o mercado acompanha o seu movimento. Estoque encalhado derruba preço, demanda alta empurra para cima, e o boletim diário da recepção mostra ofertas e produtos em alta antes de você decidir o que fabricar.
- **Expedições por raridades**: quatro rotas destravadas por dia de loja, com custo em ouro, duração, risco e botim variável. Raridades viram catalisadores de sorte na forja; contratempo no caminho traz perda de estoque, fúria ou reputação. Logística abre a segunda vaga e encurta a viagem.
- **Santuário de artefatos**: rituais que dão buffs temporários, aliviam penalidades (dissipam a fúria, recuperam item roubado) e harmonizam relíquias guardadas.
- **Cenário vivo**: o elenco é de corpo inteiro e anda pela própria arte de fundo — entra pela porta, cruza o salão em três planos de profundidade e para diante do balcão, com sombra de contato. Cada personagem tem seis quadros do mesmo corpo (perna junta e cinco meios de passo) que trocam na cadência do passo, e a velocidade de deslocamento é proporcional ao tamanho do sprite, então ninguém desliza nem corre parado. Fora a marcha, cada corpo conhece vinte e quatro situações — espanto, felicidade, ousadia, desconfiança, briga, beijo, tristeza, confusão, recusa, aprovação, tédio, medo, dor, vergonha, vitória, sono, nojo, curiosidade, aceno, apontar, risada, pensamento, aplauso e dança — e representa todas que a arte dele já tiver; um corpo sem o arquivo da pose simplesmente não a usa e continua marchando. Cada uma delas está presa a um momento que a partida já produz: o freguês acena ao chegar e aponta o item preferido, faz careta para peça torta e sai correndo quando é pego no furto, a chefe boceja na virada do dia, aplaude a obra-prima da forja, encara o evento raro pensando e sente a dor do contratempo na expedição. A pose segura por um instante e o quadro volta sozinho para o ciclo de caminhada, em vez de congelar no meio de um passo. O pé de cada faixa de profundidade pisa na linha de chão pintada daquela sala, e os móveis viram uma camada de oclusão recortada da própria arte: quem passa por trás do balcão some de cintura para baixo em vez de andar por cima dele. Onde o balcão ocupa o salão inteiro (recepção), o transeunte patrulha o piso visível, desacelera na ponta, fecha as pernas, vira e retoma a marcha, em vez de atravessar sumido atrás do móvel ou dar meia-volta de um quadro para o outro. O elenco trabalha em rodízio: os dez corpos se revezam, então nunca há dois iguais em cena nem um transeunte com o rosto do freguês do turno, e cada um escolhe sua própria profundidade contínua entre a parede do fundo e a linha da chefe, em vez de pisar todos na mesma faixa. A lista de corpos segue a mesma ordem dos retratos, de modo que o bárbaro que entra pela porta é o mesmo barbudo com machado nas costas que o painel mostra — o retrato e o corpo nunca são personagens diferentes. A protagonista respira, gira, troca para a pose inclinada e se debruça sobre o caixa quando alguém encosta nele. Cada setor tem sua sala pintada; onde só existe close de rosto, o elenco sai de cena com fade e a equipe da sala nova entra pelo fundo. O quadro lateral de interação é vidro fumê montado sobre o salão: ele toma um pedaço da faixa do palco para cima (a coluna do mercado devolve o mesmo respiro) para as duas retratos chegarem inteiros, continua rolando para mostrar o resto da conversa e deixa o fundo aparecer através dele.
- **Cartas colecionáveis**: dezesseis cards em três coleções (Fregueses, A Chefa, A Casa) com quatro raridades. Pacotes à venda na recepção, brinde a cada conquista nova, cartas repetidas viram ouro e completar coleção rende bônus. O arquivo fica na biblioteca.
- **Campanha em sete capítulos** (`campaign.gd`): a recepção mostra o objetivo atual com a lista do que falta, e cada capítulo concluído paga ouro, reputação, experiência e às vezes pacote de cartas. O último capítulo abre a tela final do império, que soma 1200 pontos na pontuação e libera a conquista correspondente; depois disso o balcão continua aberto em modo livre.
- **Integração opcional com a Steam** (`steam_bridge.gd`): conquistas, itens de card no inventário, placar de melhor negócio e save na nuvem pelo Auto-Cloud. Sem o plugin Steamworks instalado, cada chamada vira no-op e o jogo usa o placar local de `user://hall_of_fame.cfg` — nenhuma funcionalidade depende da loja.
- **Vinte e sete conquistas** com recompensas em ouro, reputação, pose especial da protagonista e pacote de cartas.
- **Salvamento local** de progresso, nível, XP, talentos, contratos, estoque, qualidade, mercado, expedições, coleção de cartas, capítulo da campanha, recorde de pontuação, melhorias, reputação por facção e opções.
- **Compatibilidade de estoque por nome de produto** para que saves antigos preservem os itens que continuam no catálogo.
- **Opção de desativar o conteúdo sensual**, sem bloquear a progressão normal.

## Direção de longo prazo

A visão é construir uma experiência de longa duração, com sistemas que se alimentem entre si. Os itens abaixo são ideias para etapas futuras, não funcionalidades já concluídas:

1. **Capítulos narrativos por facção** — pedidos de guilda, intriga da corte e contratos do submundo além da reputação já existente.
2. **Árvore de talentos maior** — mais ramos por trilha, pré-requisitos e builds concorrentes.
3. **Expansão comercial** — salas, funcionários, automação, filiais e investimentos.
4. **Finais ramificados** — a campanha já fecha em um final; faltam desfechos alternativos por facção, aliança e ruína.
5. **Prestígio opcional e desafios avançados** — objetivos de fim de jogo sem obrigar o jogador a recomeçar.
6. **Arte, áudio e animação originais** — retratos, expressões, efeitos e música com recursos gratuitos ou licenças verificadas.
7. **Publicação na Steam** — catálogo real de conquistas, itens de card e placar da comunidade no lugar do registro local.

A prioridade é implementar sistemas em etapas pequenas, testáveis e compatíveis com os saves anteriores.

## Conteúdo e direção criativa

A protagonista é uma personagem fictícia adulta. O protótipo usa humor e diálogos sugestivos, sem imagens explícitas. Futuras ilustrações serão originais ou terão licenças verificadas.

## Desenvolvimento

- Engine: Godot 4.7.2
- Linguagem: GDScript
- Objetivo: projeto gratuito, com conteúdo original e sem dependência de assets pagos.

O jogo está em desenvolvimento ativo; mecânicas, valores e interface podem mudar entre versões. Sugestões e contribuições são bem-vindas.