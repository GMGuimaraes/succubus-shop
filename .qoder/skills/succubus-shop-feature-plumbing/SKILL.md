---
name: succubus-shop-feature-plumbing
description: 'Fia um recurso novo no Succubus Shop (D:/Downloads/succubus-shop) sem quebrar o contrato medido: os onze pontos de edicao em main.gd (estado, constantes, UI, card do setor, logica, _refresh_ui, _save_game, _load_game com clamp e poda de lixo, _reset_run vida-vs-familia, _achievement_definitions e locales EN/ES no mesmo commit), mais a sonda em tools/probes e a clausula no README. Usar ao acrescentar contador, flag, lista, escada de degraus, escada de arte (faixa que troca o PNG da sala; engates _room_key e STAGE_ART_PROPS), painel novo ou mecanica sorteada ao jogo; ao acrescentar corpo de elenco (tres listas no mesmo indice, regua STAGE_BODY_HEIGHT, folha chroma-key); ao perceber que um numero sumiu no save, que o degrau 0 mexeu na conta, que a sala acordou sem chao, que a chefe foi engolida pelo recorte errado, que a sonda idioma reprovo chave orfa, ou que reencarnar nao limpou o estado novo. Nao usar para validar nem para commitar/push: isso e o skill godot-headless-probe-and-push-gate.'
---

# Fiação de recurso no Succubus Shop

## Overview

Em `D:/Downloads/succubus-shop` o `main.gd` é o único ponto onde um recurso vira estado
persistido, painel, conquista e texto traduzido. Cada engate é silencioso: esquecer um não
dá erro, dá um recurso que some do save, um degrau 0 que mexe na conta, uma sonda alheia
reprovada ou um card que não aparece. Este skill percorre os onze pontos na ordem e diz o
que quebra em cada omissão.

Validação, smoke e push ficam no skill `godot-headless-probe-and-push-gate`. Não duplicar:
aqui é onde editar; ali é como provar.

## Fixos

| Item | Valor |
|---|---|
| Projeto | `D:/Downloads/succubus-shop` (fora do workspace; nunca indexado aqui) |
| Script do jogo | `res://main.gd` (~12.300 linhas) — todos os engates passam por ele |
| Idiomas | `res://locales.gd` — a chave é o texto PT cru |
| Sondas | `res://tools/probes/<nome>.gd` (`extends SceneTree`) |
| Contrato público | `README.md`, seção `## Recursos atuais` |

**Âncora por símbolo com grep, nunca por número de linha.** O arquivo cresce e o número
obsoleta em menos de uma semana; os caminhos de grep abaixo são a fonte de verdade.

## Passo 0 — reconhecer a forma

A forma decide quais engates se aplicam e qual é a prova central.

| Forma | Exemplo no repo | Pontos que mudam |
|---|---|---|
| contador da vida | `vip_served`, `thief_blocked`, `queue_walkouts` | `maxi(0, …)` no load; limpa em `_reset_run` |
| flag booleana | `imp_hired`, `demonic_form_active` | `config.set_value` grava bool; reset explícito |
| lista / dicionário | `banned_regulars`, `credit_book`, `staff_hired`, `shelf_batches` | **poda de payload lixo** na carga; `.clear()` no reset |
| escada de degraus | `vip_rank` + `VIP_TIERS`, `credit_rank` + `CREDIT_TIERS`, `alchemy_rank` | degrau 0 = mecânica desligada; tabela com custo/exigência por nó |
| escada de arte | `PROGRESS_BAND_ART` (salão), `SECTOR_SCENERY_ART` (forja/biblioteca/santuário) | bandas de placar × degraus de luz/poeira; **não move número nenhum** — engates próprios na seção «Escada de arte» |
| painel só-leitura | cards de setor, `_progress_line()` | UI + `_refresh_ui`; nenhuma chave nova no save |
| mecânica sorteada | visita capa fina, furto, expedição | **cauda de RNG invariante** é a prova central |
| dados/regras próprios | `staff.gd`, `rivals.gd`, `commerce.gd` | novo `const X = preload("res://x.gd")`; **o estado persistível ainda mora no `main.gd`** |

Antes de escrever: confirmar que o recurso não tem fórmula paralelo. Toda regra nova entra
numa conta que o jogo já media (preço, fama, tique, chance) e a sonda mede essa conta.

## Corpo novo no elenco: o cordão de três listas por índice

Acrescentar alguém ao elenco **não passa pelos onze pontos**: passa pelo MESMO índice `i` em
três listas, e o pareamento é silencioso — corpo sem retrato no mesmo índice não dá exceção,
dá bárbaro entrando pela porta com o rosto do bardo.

1. `grep -n "const STAGE_CROWD_BODIES" main.gd` — acrescentar o nome do corpo **no fim**.
   **Nunca inserir no meio**: a ordem é o par retrato↔corpo; inserir renumera os recorrentes
   `0..N` e troca o rosto de quem já existe.
2. `grep -n "var customer_portrait_paths" main.gd` — acrescentar o retrato na **mesma
   posição `i`**. O comentário acima dela declara "ordem fixa" porque o `portrait: i` de
   `CUSTOMER_PROFILES` e de `regulars.gd` aponta para aqui.
3. `grep -n "const CUSTOMER_PROFILES" main.gd` — perfil novo com `"portrait": i` no índice
   recém-nascido do par.
4. Corpo fora de escala (raça baixa ou alta) **só existe** com entrada em
   `grep -n "const STAGE_BODY_HEIGHT" main.gd`: a folha de poses normaliza todo mundo pela
   altura do palco, então sem a régua a fada, o diabrete, o órc e o necromante chegariam do
   tamanho de um elfo. A régua é de ficção, não de medida: quem é pequeno na loja é pequeno
   na tela.

### Arte do elenco

Uma folha com as poses do MESMO personagem sobre **verde puro (#00FF00)** →
`godot --headless --path . -s res://tools/split_poses.gd -- <folha> <prefixo> <poses>` corta
por chroma key, apara cada quadro na caixa de pixels vivos, ancora pelo pé e normaliza a
altura (`STAGE_HEIGHT`); o corte cai nos vales da curva de ocupação, não em painéis de
largura fixa. Gerar uma folha custa uma imagem e entrega poses idênticas em rosto, roupa e
escala; gerar N imagens separadas quase nunca bate. Convenção de nomes:
`stage_<corpo>.png` (pernas juntas), `stage_<corpo>_walkN.png`,
`stage_<corpo>_<emoção>.png` — o arquivo parado em `assets/` já aumenta o ciclo, sem tocar
em tabela nenhuma. Gerar **primeiro as seis que a partida realmente dispara** (aceno,
aponta, felicidade, aprovação, desconfiança, tédio); o resto de `STAGE_EMOTION_POSES` só
decora quem tem arte — personagem sem arte de emoção simplesmente não a usa.

### Prova

O molde é `tools/probes/elenco.gd`: (1) pareamento por índice — corpo `i` entra em cena
andando com o retrato `i`; (2) ciclo de marcha sem buraco no meio (buraco é gente
escorregando no lugar); (3) a escada de altura desenhada fecha com a régua de raça;
(4) rodízio sem repetir rosto em cena; (5) os arquétipos novos chegam ao balcão, não só à
lista (cobertura de tiradas); (6) a corrida de 200 tiques com a mesma semente **IDÊNTICA**
— elenco maior não pode introduzir sorteio escondido. Armadilha medida na própria pele: a
sonda que abre duas lojas sem apagar o save descartável entre elas faz a segunda ler o que a
primeira escreveu — placar e vínculos são da família e passam pelo `_reset_run()`, então a
mesma semente rende duas lojas diferentes por culpa da sonda, não do jogo.

Os números desta seção (tetos de corpos e perfis, as seis poses iniciais, `STAGE_HEIGHT`)
são do estado atual do repo; re-medir antes de citar em README ou asserção de sonda.

## Escada de arte: os dois engates próprios

A escada de arte é a variante da escada de degraus que pinta a sala em vez de mover
número: as bandas do placar trocam o PNG da sala e, dentro de cada arte, os degraus só
afinam luz e poeira. No salão a régua é o `business_score` (`PROGRESS_BAND_ART`, cinco
faixas); nos ofícios é o trabalho do banco (`SECTOR_SCENERY_STEPS` = 30 degraus: seis
artes × cinco afinos, portas em `SECTOR_SCENERY_BANDS`, artes por sala em
`SECTOR_SCENERY_ART`). Degrau zero é a sala crua e não move caixa, fama nem sorteio — a
prova é a cauda de `randi()` idêntica ao controle ao avaliar os estados da escada, mais
«pintar a sala não move número» (molde: `tools/probes/cenario.gd`).

Esquecer os dois engates abaixo não dá erro de parse. Dá sala sem chão e corpo cortado
no lugar errado:

1. **Arte nova fora do `_room_key()` acorda a sala sem chão.** `grep -n "func _room_key"
   main.gd` normaliza toda arte da escada pela geometria da sala cheia — as faixas do
   salão por `SALON_GEOMETRY_KEY`, as dos ofícios por `SECTOR_SCENERY_ROOM`. Arte nova
   precisa entrar na tabela da escada a que pertence; esquecida ali, o `_stage_room` cai
   no caminho do PNG e as dez tabelas de sala (chão, porta, fila, vitrine, ponto de
   encontro, luzes) não acham a chave. O comentário do repo é literal: «uma banda
   esquecida ali viraria sala sem chão, sem porta e sem fila». A sonda confere a
   geometria lida (a da sala cheia) contra a arte pintada (a da faixa).
2. **Arte pintada sem recorte em `STAGE_ART_PROPS` engole a chefe.** Cada faixa desenha
   o próprio móvel numa altura diferente, então o contorno de oclusão vem da **arte**
   (`grep -n "const STAGE_ART_PROPS" main.gd`), não da sala. Herdar o polígono do salão
   cheio cortava a chefe até **0,035 de tela antes** do móvel realmente pintado (casa em
   obras corta em 0,525; o herdado era 0,49). `tools/probes/recorte.gd` mede o corte na
   coluna da chefe por faixa e reprova qualquer arte da escada sem recorte próprio.

PNG faltando não abre fundo preto: `_salon_art()` e `grep -n "func _scenery_art" main.gd`
degradam para a arte cheia da sala (fatia de arte não importada, teste em máquina limpa).
Sala que não é escada (close-up de cena, guilda) não entra nas tabelas e continua
intocada quando a faixa vira.

## Os onze pontos de engate

### 1. Estado

`grep -n "^var vip_\|^var credit_" main.gd` — bloco de `var` na seção de estado. Regra do
repo: comentário `##` acima do bloco dizendo o que o recurso faz **no degrau/guarda zero**
(molde: `## recepção: com ele guardado na gaveta (\`vip_rank == 0\`) nenhuma visita é sorteada
como …`). Sem essa frase, o próximo leitor não sabe se desligar é comprar.

### 2. Tabela de constantes

`grep -n "^const VIP_TIERS\|^const CREDIT_TIERS" main.gd` — Array de dicionários com chaves
fixas (`rank`, `cost`, `rep`, `standard`, `tip`). Toda chave é lida por string: um nó sem a
chave quebra em runtime, não no parse. O load referencia `TABELA.size() - 1` como teto.

### 3. Vars de UI

`grep -n "^var vip_label\|^var vip_button" main.gd` — `Label`/`Button` declarados com o
resto dos nós. Não `@onready`: a UI é montada em código.

### 4. Card no setor

`grep -n "func _make_sector_card" main.gd` devolve o molde (PanelContainer + StyleBoxFlat +
margens). `grep -n "sector_stack.add_child\|reception_box\|forge_box\|library_box\|sanctum_box\|expedition_box" main.gd`
mostra os setores. Molde do card: `_make_sector_card(bg, borda)` → `HBoxContainer` com
`Label` (`autowrap_mode`, `size_flags_horizontal = SIZE_EXPAND_FILL`, fonte 13) + `Button`
(`custom_minimum_size = Vector2(190, 44)`, fonte 14, `pressed.connect(_buy_x)`). Título do
card entra em CAIXA ALTA para o `register()` do idioma traduzir sozinho.

### 5. Funções de lógica

`grep -n "func _vip_row\|func _vip_next_row\|func _vip_standard" main.gd` — molde: lookup com
clamp interno (`VIP_TIERS[clampi(rank, 0, VIP_TIERS.size() - 1)]`), próximo nó devolvendo
`{}` no teto, `_buy_x()` que recusa sem mover ouro/fama e só então sobe o degrau. Nada de
conta dentro de `_ready` ou de `_refresh_ui`: toda fórmula vive em função nomeada que a
sonda possa chamar.

### 6. Bloco em `_refresh_ui`

`grep -n "is_instance_valid(vip_label)" main.gd`. **Toda linha de UI nova precisa de guarda
`is_instance_valid`.** Sem a guarda, qualquer sonda que instancie `main.tscn` antes de o
card existir cai com null access — e quebra a sonda do vizinho, não a sua.

### 7. `_save_game`

`grep -n "config.set_value(\"game\", \"vip_rank" main.gd` — uma linha por chave nova, no
formato do bloco (seção `"game"`; inteiros crus, listas e dicionários direto).

**Omissão aqui é a mais cara:** a carga aloca o estado de qualquer jeito, então chave
ausente lê 0 e o progresso do usuário desaparece na primeira escrita. Se o recurso é
preferência da pessoa e não da partida, ele **não** vai para o save do run: mora em arquivo
próprio (molde: `Locales.SETTINGS_PATH = "user://locale_settings.cfg"`), e o comentário diz
isso.

### 8. `_load_game`

`grep -n "vip_rank = clampi" main.gd`. Escalar: `clampi(int(config.get_value("game", k,
default)), 0, TABELA.size() - 1)` para degrau, `maxi(0, int(…))` para contagem — save
antigo acorda no default, save adulterado volta para o teto.

Lista/dicionário: reconstruir do zero e **podar payload lixo na entrada**, molde
`credit_book` (`grep -n "Payload lixo" main.gd`): quem o jogo não conhece, valor 0 ou
negativo, dia inexistente → `continue`, a nota some. Comentário do repo: "Payload lixo (id
fantasma, owed 0, prazo negativo) é riscado na entrada, não cobrado para sempre." Se a carga
popular um registro sem peça correspondente, ver `func _reconcile_batches` — a
reconciliação entre prateleira e registro evita que a virada reescreva o estoque e derrube
o nível de quem só estava guardado.

### 9. `_reset_run`

`grep -n "func _reset_run" main.gd`. Aqui o engate é uma **decisão escrita em comentário**,
não um `clear()` mecânico. Convenção do repo:

- **da vida** (morre ao reencarnar): caixa, reputação, fila, `staff_hired`, conserva/cela,
  ofícios assinados, `vip_*`. Molde: `# Filial é patrimônio da vida, não da família`.
- **da família** (atravessa a vida): vínculos (`servos`), XP de rota dos batedores, pedidos
  de facção entregues, dobradiça/sino/milícia da porta, preferência de idioma. Molde:
  `# vínculo é da família, não do CNPJ`.
- **só o reset total apaga**: escolha de terceiro que não é do CNPJ.

Escrever no comentário qual das três e por quê. Testar na sonda: reencarnar deve mover o que
foi declarado da vida e não mover nada do que foi declarado da família.

### 10. Conquistas

`grep -n "func _achievement_definitions" main.gd` — cada entrada
`{"id", "name", "condition", "gold", "rep", "pose"}`. O `name` diz a condição em PT com o
número da porta; a `pose` tem de existir no conjunto de poses do jogo. **Adicionar
conquistas muda o tamanho da lista**, que a sonda de menu/idioma asserta — rodar a bateria
vizinha.

### 11. Idiomas: EN e ES no mesmo commit

`locales.gd` tem `MESSAGES = {"en": {…}, "es": {…}}`; **a chave é o texto PT cru usado no
código**. Todo texto novo entra nas duas tabelas, no mesmo commit, uma linha por língua
(`grep -n "O LIVRO DE FIADO" locales.gd` mostra o molde: mesma chave, uma linha na tabela
`en` e outra na `es`).

- O motivo é determinístico: `tools/probes/idioma.gd`, func `_orfãos()`, cruza `en` × `es`
  e reprova qualquer chave sem irmã. Uma tabela sem a outra reprova a sonda de idioma
  alheia.
- PT não precisa de linha: a ausência da chave só faz o painel ler o original (migração em
  fatia é permitida). Falha é **apenas** a órfã EN/ES.
- Rótulo e botão fixos: o `register()` do motor traduz sozinho. Texto montado na hora
  (`"Ouro: %d"`) exige `tr()` no chamador — `grep -n "tr(\"🏆 Conquistas" main.gd`.
- Armadilha: `locale` **sobrevive ao `_reset_run()`**, porque a preferência mora fora do
  save. Fixar o idioma no helper da sonda antes de `_reset_run()` (detalhe no Passo 4 do
  skill do portão).

## Invariantes que valem para todo recurso

1. **Degrau zero / toggle desligado não move número nenhum.** Nem ouro, nem fama, nem
   contadores, nem sorteio. A prova é a **cauda de RNG idêntica ao controle**: rodar com a
   mecânica desligada e ligada na mesma semente e comparar os `randi()` consumidos (molde:
   40 sorteios depois de 200 carimbos IDÊNTICOS ao controle que nunca chamou a função). É o
   que separa escada de roleta.
2. **Filtro de tom (o toggle adulto) não corta progressão nem move número**: muda o texto,
   a porta é a mesma, os valores são os mesmos.
3. **Carga idempotente**: salvar → carregar → salvar não perde chave nem acumula lixo. Medir
   com payload adulterado (degrau 9 vira o teto, negativo e texto viram 0, save sem a chave
   acorda desligado).
4. **Nada de fórmula paralelo**: se o recurso dá bônus, ele entra na fórmula que a loja já
   usava, e a sonda lê a saída dela.
5. **Conteúdo**: sugestão atrás do toggle, nunca explícito (limite do projeto).

## Sonda

`tools/probes/<nome>.gd`, `extends SceneTree`, reusando os ajudantes da sonda mais próxima
(loja montada, recarga de estoque, selagem de RNG, cirurgia de save) — `grep -n "^func "
tools/probes/fiado.gd`. Cabeçalho em prosa listando as seções medidas; o molde do `salao.gd`
tem 11 seções e cobre o catálogo esperado: desligado não sorteia nem move número, cada nó
cobra caixa e fama, recusa não move ouro, a fatia sorteada bate com a tabela, a servida sai
com o topo da barra e a gorjeta que a tabela anuncia, a recusa por exigência devolve a peça
(estoque e registro idênticos), o painel lê os quatro estados, ler e gravar não consome
sorteio, as chaves atravessam o arquivo com poda, reencarnar enrola, as conquistas acendem
nas portas certas e a lista fecha com N definições, e a corrida de 200 tiques com a mesma
semente nos três lados.

Armadilhas reais (cada uma custou uma rodada nesta sessão):

- **`%r` não existe** no formatador do GDScript (7 erros por uso). Usar `%s`/`%d`.
- **Estado vazio prova por ausência.** A corrida de 200 tiques com a prateleira vazia deu
  zero capa fina e pareceu aprovada: não provou o cordão, provou que não houve venda.
  Montar o chão do recurso nos dois lados antes de afirmar.
- **Piso numérico esconde a medição.** A gorjeta tem piso de 4 ouro; medir sobre a poção de
  15 faz os 15% do degrau 1 virarem piso em todo nó e a escada sumir. Escolher alvo caro o
  bastante para a diferença sobreviver ao arredondamento (o Pato de 24).
- **Faltou `await` na corrida** e a sonda leu antes de o tique acontecer.
- **Método chutado no dicionário** só aparece em runtime; conferir com `grep -n "func "
  main.gd` antes de chamar.
- **Instância não-tipada não infere tipo.** `var g = await _loja(...)` devolve `Variant`;
  `var ouro := g.foo()` reprova o parse com *Cannot infer the type*. Declarar o tipo
  (`var ouro: int = g.foo()`).
- **`Locales` não é global.** A sonda que traduz declara o próprio
  `const Locales = preload("res://locales.gd")`; ter no `main.gd` não vale — cada script
  declara os seus preloads.
- **Headless nasce 1280×1280.** Medida de oclusão ou linha de chão em fração de tela
  exige fixar a janela em 1280×720 (molde: `tools/probes/caminhos.gd`); o corpo tem
  altura fixa em pixels e, na tela quadrada, toda fração sai errada.

## Fechar

1. Portão completo no skill `godot-headless-probe-and-push-gate` (`--check-only` em todos os
   arquivos tocados, smoke com save descartável, gate de erro por grep, hash do save real
   intacto, bateria vizinha incluindo `tools/probes/idioma.gd`).
2. README, mesma rodada: `## Recursos atuais` é prosa com uma cláusula por recurso no molde
   `**Nome (#NN)**: … Medido na sonda \`tools/probes/x.gd\` com …`, frase de compatibilidade
   ("Save antigo não tem a chave `x` e acorda …") e as conquistas novas nomeadas. O README é
   contrato medido: mudança em rota de venda mexe nos números que outras cláusulas citam —
   re-rodar a bateria de tiques e reconciliar README e títulos no mesmo commit.

## Riscos

- Pular a guarda do `_refresh_ui` ou o `config.set_value` não quebra nada na hora: quebra o
  save do usuário ou a sonda do vizinho, no commit seguinte.
- Os números deste skill (11 seções, tetos de degrau, tamanho da lista de conquistas) são do
  estado atual do repo; re-medir antes de citar em README ou em asserção de sonda.
- O repo mantém uma cópia deste skill em `.qoder/skills/`. Ela é arquivo normal do repo
  (editar e commitar pelo fluxo git), não um skill ativo; a cópia viva é a do diretório de
  skills do usuário.
