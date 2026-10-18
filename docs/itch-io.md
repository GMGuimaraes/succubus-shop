# Kit de publicação — itch.io

Copy, avisos honestos e o passo a passo para subir o **Succubus Shop** na itch.io.
Os números abaixo não são chutes: foram medidos em 2026-10-18 com
`tools/probes/publicar.gd` (60 conferências, 0 quebras), `tools/probes/idioma.gd`
(215/215 chaves nas cinco tabelas traduzidas), `tools/probes/menu.gd` (100 definições
de conquista) e uma varredura PNG da árvore `assets/`.

---

## 1. Estado real — o que ainda bloqueia o botão de publicar

| Item | Estado | O que falta |
|---|---|---|
| Presets de export (`Windows Desktop`, `Linux`, `Web`) | prontos e conferidos por sonda | — |
| Ícone do build (`icon.svg`, 128×128, 1127 bytes) | pronto | — |
| Guarda de plataforma (sem janela de arquivo no navegador) | pronta e medida | — |
| **Templates de export do Godot 4.7.2** | **NÃO instalados** (`%APPDATA%\Godot\export_templates\` vazio) | Editor → *Manage Export Templates* → *Download* (~1 GB). Ninguém baixou por você: é grande demais para ser efeito colateral de um script. |
| Build web real | não gerado | depende dos templates acima |
| Descrição "About" do repositório GitHub | não alterada | sem `gh` CLI neste ambiente — edição manual na web |

Sem os templates, `tools/build_itch.sh` **para na porta** com a instrução de instalação
em vez de baixar sozinho. Instale uma vez no editor e o script passa a funcionar.

---

## 2. Ficha técnica (o que a página pode prometer)

| Campo | Valor medido |
|---|---|
| Motor | Godot 4.7.2.stable |
| Versão | `0.1.0-alpha.5` (núcleo `0.1.0`) |
| Janela | 1280×720, escala `canvas_items` |
| Renderizador | `gl_compatibility` — escolhida de propósito: é a que roda em navegador e em GPU antiga |
| Threads no build web | **desligadas** (`variant/thread_support=false`) → não exige `SharedArrayBuffer`, então roda em qualquer hospedagem, inclusive a da itch.io, sem cabeçalho cruzado |
| Idiomas | português, inglês, espanhol, francês, italiano, alemão (catálogo com as mesmas 215 chaves nas cinco tabelas traduzidas) |
| Conquistas | 100 definições. Na itch.io elas **não** aparecem: só a integração opcional com a Steam as entrega — na vitrine elas contam como conteúdo, não como sistema |
| Conteúdo | fantasia sombria adulta, **tom sugestivo atrás de um botão**; nenhuma nudez explícita em nenhum modo |
| Save | arquivo em mesa; no navegador mora no armazenamento do site (IndexedDB) |
| Massa de arte | **667 PNG**, 258 MB na árvore, **161,75 Mpx** de textura. O preset web manda comprimir para desktop **e** mobile, então o `.pck` carrega os dois conjuntos: ~0,5 B/px cada → **entre 80 MB (um conjunto só) e 160 MB (como está agora)**. O número real só sai do primeiro export de verdade |

Regra da itch.io que aperta aqui: cada arquivo **descompactado** tem de caber em 200 MB.
O `.pck` cabe nos dois cenários, mas o de 160 MB é pesado para jogar no navegador.
Ver §6.

---

## 3. Título, tagline, descrição curta

**Título:** `Succubus Shop`

**Tagline (a linha curta embaixo do título — 116 e 110 caracteres, cabe no campo):**

- PT: `Gerencie uma loja de relíquias no submundo: forja, fiado, invasões e sete finais — com uma succubus atrás do balcão.`
- EN: `Run an infernal relic shop: forging, credit, invasions and seven endings — with a succubus behind the counter.`

**Short description (o parágrafo nos cards da itch.io):**

- PT: `Simulador de gestão em fantasia sombria. Você é a succubus que herdou uma loja de relíquias e precisa fazer ela pagar: fabricar, vender, fiar, expedir, se defender da rua e escolher em quem gastar cada ponto de talento. Sete capítulos, sete desfechos, reencarnação do império e uma clientela que lembra do seu nome.`
- EN: `A management sim set in dark fantasy. You are the succubus who inherited a relic shop and has to make it pay: forge, sell, extend credit, send expeditions, defend the door and choose where every talent point goes. Seven chapters, seven endings, a dynasty you can reincarnate, and regulars who remember your name.`

---

## 4. Descrição longa (markdown, cole direto)

### PT-BR

```markdown
Uma succubus herdou a loja de relíquias da família — e o buraco no caixa.

**Succubus Shop** é um simulador de gestão com campanha. Nada de clique infinito:
a casa tem um dia que vira, uma rua que acorda de um humor, e uma conta que cobra.

**O balcão.** Os clientes entram sozinhos, escolhem o que está na prateleira e
reclamam se não encontram. Preço, reputação e fila se mexem conforme o estoque
encalha ou some — o mercado reage ao seu movimento, não ao contrário.

**A forja.** Seis ingredientes, seis níveis de qualidade, e o topo do espectro
tem porta: Lendário só entra no rolo depois de seis degraus somados entre
Alquimia, Biblioteca e vidas já reencarnadas.

**O prazo.** Mercadoria apodrece. Cada virada de dia derruba um degrau da peça
mais antiga da estante, e o Depósito de sal vende prazo em ouro.

**A rua.** Três rivais acendem placa em dias fixos e levam corpo da sua porta e
dinheiro do bolso de quem entra. A resposta é comprar a placa. Já a visita grande
bate com poder de 22 a 112, e só se resolve com as mãos que a casa já paga.

**A casa.** Custo diário, dívida com teto, livro de fiado que cobra, filiais fora
do salão, funcionários com salário na conta da manhã. E, quando o caixa aperta
mesmo, o desfecho de ruína.

**A vida longa.** Sete capítulos, sete desfechos (cinco de facção, o da casa e o da ruína),
pedidos escritos das cinco facções que pagam privilégio permanente, árvore de
talento com dois ofícios concorrentes por trilha — assinar um raspa o outro até a
próxima vida — e reencarnação do império com aura, dotes e placar por temporada.

**A mesa.** Seis idiomas na primeira abertura. Tutorial que não para o jogo.
Menu no ESC. Cena sensual é tom, não nudez: existe um botão, e ele muda a voz da
loja sem mover um número dela.

## Como jogar no navegador

O save no navegador mora no armazenamento do site: nada sai para arquivo, e
limpar os dados do navegador apaga a loja. Se você quer garantir o progresso,
jogue no build de mesa, que tem exportar e importar save.

## avisos de conteúdo

Fantasia sombria com temas adultos tratados em tom sugestivo: flerte, insinuação,
poses provocantes. **Nenhuma nudez explícita em nenhum modo.** Há um botão de
conteúdo sensual no menu, e desligá-lo não corta progressão, economia ou conquistas.

## ficha técnica

Godot 4.7 • 1280×720 • `gl_compatibility` (roda em GPU integrada e no navegador) •
seis idiomas • alpha jogável em desenvolvimento.
```

### English

```markdown
A succubus inherited the family's relic shop — and the hole in the till.

**Succubus Shop** is a management sim with a campaign. No infinite clicking: the
house has a day that turns, a street that wakes up in a mood, and a bill that comes.

**The counter.** Customers walk in on their own, buy what is on the shelf and
complain when it isn't. Price, reputation and the queue move as stock stalls or runs
out — the market reacts to you, not the other way round.

**The forge.** Six ingredients, six quality tiers, and the top of the spectrum has a
door: Legendary only enters the roll after six steps summed across Alchemy, the
Library and lives already reincarnated.

**The shelf life.** Goods rot. Each day turns one step down on the oldest item, and
the Salt Depot sells time for gold.

**The street.** Three rivals raise a sign on fixed days and take bodies from your
door and coin from your customers' purses. The answer is to buy the sign. The big
visit knocks with power 22 to 112, and only hands the house already pays can hold it.

**The house.** Daily upkeep, debt with a ceiling, a credit ledger that actually
collects, branches outside the hall, staff on the morning bill — and, when the box
squeezes for real, the ruin ending.

**The long game.** Seven chapters, seven endings (six by faction plus ruin), written
requests from all five factions that pay permanent privilege, a talent tree with two
rival trades per track — signing one erases the other until your next life — and a
dynasty you reincarnate with auras, permanent perks and a seasonal scoreboard.

**The table.** Six languages on first launch. A tutorial that never stops the game.
An ESC menu. Sensual content is tone, not nudity: one switch, and it changes the shop's
voice without moving a single number in it.

## Playing in the browser

In the browser the save lives in the site's storage: nothing goes out to a file, and
clearing browser data erases the shop. Want to keep progress for sure? Use the desktop
build, which exports and imports save files.

## content warnings

Dark fantasy with adult themes handled suggestively: flirting, innuendo, provocative
poses. **No explicit nudity in any mode.** There is a sensual-content switch in the
menu, and turning it off cuts no progression, economy or achievement.

## tech

Godot 4.7 • 1280×720 • `gl_compatibility` (runs on integrated GPUs and in the browser) •
six languages • playable alpha in development.
```

---

## 5. Campos da itch.io

| Campo | Valor |
|---|---|
| Classification | **Games** |
| Type | **Play in browser** (o zip web) **+ Downloadable** (Windows e Linux) |
| Genre / Tags | Simulation, Strategy, RPG, Indie; tags: `godot`, `management`, `shop-sim`, `dark-fantasy`, `incremental`, `female-protagonist`, `story-rich`, `portuguese` |
| Content warning | **Adults Only – Sexual Themes** (marque "sexual themes"; **não** marque nudez: o jogo não tem) |
| Status | **In Progress** |
| Multiplayer | nenhum |
| Inputs | mouse + teclado (ESC abre o menu) |
| Language | Portuguese, English, Spanish, French, Italian, German |
| Keyboard accessibility | o menu todo é clicável com mouse; ESC abre e fecha |
| Cover image | 625×322 — use `screenshots/gallery_reception.png` recortada; o selo do projeto é `icon.svg` |
| Banner | 690×415 (opcional, mesma arte) |
| Thumbnail | 16:9 |
| Screenshots / gallery | os sete `screenshots/gallery_*.png` + `screenshots/current-build.png` |
| Release name | `v0.1.0-alpha.5` — o número vai no nome do zip e, dentro do jogo, em `config/version` |
| Notes no arquivo | escreva "alpha em desenvolvimento; save no navegador fica no armazenamento do site" |
| Available platforms | Windows, Linux, HTML5 |
| Pricing | "Pay what you want" com mínimo 0 (ou o mínimo que você escolher) — a itch.io cobra 10% por padrão |

**Nome de arquivo** — o script gera:

```
Succubus-Shop-0.1.0-alpha.5-windows.zip
Succubus-Shop-0.1.0-alpha.5-linux.zip
Succubus-Shop-0.1.0-alpha.5-web.zip
```

---

## 6. O build web é grande: o que fazer com isso

Medido na árvore (`667` PNG, 258 MB, **161,75 Mpx** de textura): cada conjunto de
compressão VRAM custa ~0,5 byte por pixel, então **um** conjunto ≈ 81 MB e **dois** ≈
162 MB. O preset web de hoje (`for_desktop=true` **e** `for_mobile=true`) manda os dois.
Cabe nos 200 MB por arquivo da itch.io nos dois cenários, mas 160 MB é o que o
navegador baixa antes do primeiro quadro. A distribuição, em pixels:

| Dimensão | O que é | Mpx |
|---|---|---|
| 1792×1024 | as salas grandes de perto (`forge_close_scene`, `library_close_scene`, `reception_scene`…) | 38,5 |
| 1024×1536 | folhas de personagem em pé | 31,5 |
| 2560×1440 | salas em resolução de tela cheia | 24,6 |
| 1536×2304 | folhas de personagem grandes | 20,3 |
| 1280×720 | artes médias e impressos | 7,0 |

Quatro saídas, da mais barata para a mais trabalhosa:

0. **Um conjunto de compressão só** no preset web (`for_desktop=false`,
   `for_mobile=true`): corta o `.pck` pela metade sem tocar em pixel nenhum de arte.
   **Custo:** precisa do primeiro export real para conferir se o navegador visado aceita
   ETC2/ASTC — e isso é decisão de compatibilidade, não de economia.
1. **Publicar só mesa primeiro** (Windows + Linux) e deixar o HTML5 para quando a arte
   enxugar. A página não promete nada que não aconteça.
2. **Variantes de assets por export.** O Godot aceita filtro por recurso no preset; uma
   fatia "web" com as salas em 1280×720 em vez de 1792×1024 e as folhas em 768×1152 em
   vez de 1024×1536 derruba os 70 Mpx do topo da tabela para ~26 Mpx — `.pck` na casa dos
   **40–60 MB** com um conjunto só. **Custo:** exige re-verificar o recorte e a linha de
   chão de cada cenário (`tools/probes/recorte.gd`, `chao.gd`, `caminhos.gd`) — é trabalho
   de sonda, não de slider.
3. **Deixar como está e avisar.** A página diz "a versão web baixa até 160 MB".

Qualquer uma das quatro mexe em preset e às vezes em arte: **nenhuma foi decidida
aqui**. A escolha é sua, e a nº 2 é a que dá mais trabalho e o melhor jogo.

---

## 7. Passo a passo

```bash
# 1. uma vez só, no editor: Editor > Manage Export Templates > Download

# 2. gerar os três zips
GODOT="/c/Users/gmore/godot/godot" bash tools/build_itch.sh

# 3. só um alvo, se estiver depurando
GODOT="/c/Users/gmore/godot/godot" bash tools/build_itch.sh --only web
```

Antes de marcar *Publish*, confira:

- [ ] `bash tools/build_itch.sh` terminou com os três `.zip` listados
- [ ] o zip web tem `index.html` **na raiz** (o script confere e diz `✓` ou `QUEBRA`)
- [ ] nenhum arquivo descompactado passa de 200 MB
- [ ] o build web abre no navegador **sem** os botões de exportar/importar save, e com o
      aviso no lugar (isso é medido em `tools/probes/publicar.gd`, dos dois lados)
- [ ] o build de mesa **tem** os dois botões
- [ ] o seletor de idioma aparece na primeira abertura das três plataformas
- [ ] a tagline e a descrição longa estão na página, nas duas línguas
- [ ] o aviso de conteúdo diz "sexual themes", não "nudity"
- [ ] `README.md` e a página dizem a mesma versão

## 8. O que ainda não dá para prometer

- **Conquistas na itch.io.** As 100 conquistas existem no jogo e na Steam; a itch.io não
  tem achievements, então a página pode dizer "100 conquistas para caçar", não que elas
  desbloqueiam algo na vitrine.
- **Nuvem.** Save em nuvem é Steam Cloud. No navegador, o save é do site e limpar dados
  o apaga — o jogo avisa isso na própria tela de save.
- **Nota no mobile.** O build web usa `gl_compatibility` e roda, mas a UI foi desenhada
  para 1280×720 com mouse. Não marque "mobile friendly".
- **Data de "1.0".** Ainda falta balanceamento e a aprovação visual do chão, da oclusão
  e do timing de animação no editor, que só você pode dar.
